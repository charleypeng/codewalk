Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# CodeWalk installer (Windows)
# Usage: irm https://raw.githubusercontent.com/<owner>/<repo>/main/install.ps1 | iex

$Repo = if ($env:CODEWALK_REPO) { $env:CODEWALK_REPO } else { "verseles/codewalk" }
$InstallDir = Join-Path $env:LOCALAPPDATA "CodeWalk"
$BinaryPath = Join-Path $InstallDir "codewalk.exe"
$VersionFile = Join-Path $InstallDir ".installed-version"
$StartMenuShortcutPath = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\CodeWalk.lnk"

function Info([string]$Message) {
  Write-Host ":: $Message" -ForegroundColor Cyan
}

function Fail([string]$Message) {
  throw $Message
}

function Warn([string]$Message) {
  Write-Host ":: $Message" -ForegroundColor Yellow
}

function Get-WindowsArchitecture {
  $runtimeInfoType = [Type]::GetType("System.Runtime.InteropServices.RuntimeInformation", $false)
  if ($runtimeInfoType) {
    $osArchitectureProperty = $runtimeInfoType.GetProperty("OSArchitecture", [System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Static)
    if ($osArchitectureProperty) {
      try {
        $osArchitecture = $osArchitectureProperty.GetValue($null, $null)
        if ($osArchitecture) {
          return $osArchitecture.ToString().ToUpperInvariant()
        }
      }
      catch {
        # Ignore and use compatibility fallbacks below.
      }
    }
  }

  $processArchitecture = ""
  $wow64Architecture = ""
  if ($env:PROCESSOR_ARCHITECTURE) {
    $processArchitecture = $env:PROCESSOR_ARCHITECTURE.ToUpperInvariant()
  }
  if ($env:PROCESSOR_ARCHITEW6432) {
    $wow64Architecture = $env:PROCESSOR_ARCHITEW6432.ToUpperInvariant()
  }

  if ($processArchitecture -eq "ARM64" -or $wow64Architecture -eq "ARM64") {
    return "ARM64"
  }

  if ([Environment]::Is64BitOperatingSystem) {
    return "X64"
  }

  return "X86"
}

function Get-WindowsAssetCandidates {
  $arch = Get-WindowsArchitecture
  switch ($arch) {
    "X64" { return @("codewalk-windows-x64.zip") }
    "ARM64" {
      return @("codewalk-windows-arm64.zip", "codewalk-windows-x64.zip")
    }
    default { Fail "Unsupported architecture: $arch" }
  }
}

function Add-ToUserPath([string]$PathEntry) {
  $current = [Environment]::GetEnvironmentVariable("Path", "User")
  $parts = @()
  if ($current) {
    $parts = $current.Split(";") | Where-Object { $_ -and $_.Trim() -ne "" }
  }
  if ($parts -contains $PathEntry) {
    return
  }
  $updated = if ($parts.Count -eq 0) { $PathEntry } else { ($parts + $PathEntry) -join ";" }
  [Environment]::SetEnvironmentVariable("Path", $updated, "User")
}

function New-StartMenuShortcut([string]$TargetExePath) {
  $shortcutDir = Split-Path -Parent $StartMenuShortcutPath
  New-Item -ItemType Directory -Force -Path $shortcutDir | Out-Null

  $shell = New-Object -ComObject WScript.Shell
  $shortcut = $shell.CreateShortcut($StartMenuShortcutPath)
  $shortcut.TargetPath = $TargetExePath
  $shortcut.WorkingDirectory = Split-Path -Parent $TargetExePath
  $shortcut.IconLocation = "$TargetExePath,0"
  $shortcut.Description = "CodeWalk"
  $shortcut.Save()
}

function Stop-CodeWalkProcess {
  $procs = @()
  try {
    $found = Get-Process -Name 'codewalk' -ErrorAction Stop
    if ($found -is [array]) { $procs = $found } else { $procs = @($found) }
  } catch { return }
  if ($procs.Count -eq 0) { return }

  Info "Stopping $($procs.Count) running CodeWalk process(es)"
  foreach ($proc in $procs) {
    try {
      Stop-Process -Id $proc.Id -Force -ErrorAction Stop
    } catch {
      Warn "Could not stop CodeWalk process (PID $($proc.Id)): $($_.Exception.Message)"
    }
  }
  foreach ($proc in $procs) {
    $proc | Wait-Process -Timeout 10 -ErrorAction SilentlyContinue
  }
  # Brief pause to let the OS release file handles after process exit.
  Start-Sleep -Milliseconds 500

  $survivors = Get-Process -Name 'codewalk' -ErrorAction SilentlyContinue
  if ($survivors) {
    Warn "CodeWalk process(es) still running after stop attempt"
  }
}

# Schedule a directory for deletion on the next reboot using MoveFileEx.
# Requires the MoveFileEx Win32 API via P/Invoke (usually works without admin).
# Falls back to a warning if P/Invoke is unavailable.
function Register-RebootDelete([string]$Path) {
  try {
    # Guard against duplicate Add-Type when called more than once.
    if (-not ([System.Management.Automation.PSTypeName]'FileOps').Type) {
      $code = '
        using System;
        using System.Runtime.InteropServices;
        public class FileOps {
          [DllImport("kernel32.dll", SetLastError=true, CharSet=CharSet.Unicode)]
          public static extern bool MoveFileEx(string lpExistingFileName, string lpNewFileName, int dwFlags);
        }
      '
      Add-Type -TypeDefinition $code -ErrorAction Stop
    }
    $MOVEFILE_DELAY_UNTIL_REBOOT = 0x00000004
    $result = [FileOps]::MoveFileEx($Path, $null, $MOVEFILE_DELAY_UNTIL_REBOOT)
    if ($result) {
      Info "Scheduled locked directory for deletion on next reboot: $Path"
    } else {
      Warn "MoveFileEx failed for $Path (error $([System.Runtime.InteropServices.Marshal]::GetLastWin32Error()))"
    }
  } catch {
    Warn "Could not schedule reboot deletion for $Path. Delete it manually after restart."
  }
}

# Remove the install directory, handling in-use locks from a running process.
# Tries: stop process → direct remove → rename to .old → schedule reboot delete.
function Remove-InstallDir {
  if (-not (Test-Path $InstallDir)) { return $true }

  # Attempt 1: direct removal (works when no process is locking files).
  try {
    Remove-Item -Recurse -Force -Path $InstallDir -ErrorAction Stop
    return $true
  } catch {
    # Directory is locked — continue to rename strategy.
  }

  # Attempt 2: stop the running process and retry removal.
  Stop-CodeWalkProcess
  try {
    Remove-Item -Recurse -Force -Path $InstallDir -ErrorAction Stop
    return $true
  } catch {
    # Still locked — continue to rename strategy.
  }

  # Attempt 3: rename the locked directory out of the way and schedule it
  # for deletion on reboot. Windows allows renaming a directory that
  # contains a running executable (but not deleting it).
  $oldDir = "${InstallDir}.old"
  if (Test-Path $oldDir) {
    try {
      Remove-Item -Recurse -Force -Path $oldDir -ErrorAction SilentlyContinue
    } catch {
      # If .old is also locked, schedule it for reboot deletion too.
      Register-RebootDelete -Path $oldDir
    }
  }

  try {
    Rename-Item -Path $InstallDir -NewName 'CodeWalk.old' -ErrorAction Stop
    Info "Renamed locked directory to $oldDir"
    Register-RebootDelete -Path $oldDir
    return $true
  } catch {
    Fail "Cannot remove or rename $InstallDir. Close CodeWalk and retry."
  }
}

function Get-InstalledVersion {
  if (-not (Test-Path $VersionFile)) {
    return ""
  }

  try {
    return (Get-Content -Path $VersionFile -Raw).Trim()
  }
  catch {
    return ""
  }
}

$assetCandidates = Get-WindowsAssetCandidates

Info "Fetching latest release from $Repo"
$release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest" -Headers @{ "User-Agent" = "codewalk-install" }
if (-not $release.tag_name) {
  Fail "Could not determine latest release tag."
}

$installedVersion = Get-InstalledVersion
if ($installedVersion) {
  if ($installedVersion -eq $release.tag_name) {
    Info "Reinstalling CodeWalk $installedVersion"
  }
  else {
    Info "Updating CodeWalk from $installedVersion to $($release.tag_name)"
  }
}
elseif (Test-Path $InstallDir) {
  Info "Existing installation detected. Installing latest release $($release.tag_name)"
}
else {
  Info "Installing CodeWalk $($release.tag_name)"
}

$match = $null
$asset = $null
foreach ($candidate in $assetCandidates) {
  $found = $release.assets | Where-Object { $_.name -eq $candidate } | Select-Object -First 1
  if ($found) {
    $match = $found
    $asset = $candidate
    break
  }
}

if (-not $match) {
  $available = ($release.assets | ForEach-Object { $_.name }) -join ", "
  $requested = $assetCandidates -join ", "
  Fail "None of the expected assets were found ($requested). Available: $available"
}

$tmpRoot = Join-Path $env:TEMP ("codewalk-install-" + [Guid]::NewGuid().ToString("N"))
$zipPath = Join-Path $tmpRoot $asset

try {
  New-Item -ItemType Directory -Force -Path $tmpRoot | Out-Null

  Info "Downloading $asset"
  Invoke-WebRequest -Uri $match.browser_download_url -OutFile $zipPath

  Remove-InstallDir
  New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

  Info "Extracting package"
  Expand-Archive -Path $zipPath -DestinationPath $InstallDir -Force
  # Remove Zone.Identifier ADS so SmartScreen does not warn on first run.
  Get-ChildItem -Path $InstallDir -Recurse | Unblock-File -ErrorAction SilentlyContinue

  if (-not (Test-Path $BinaryPath)) {
    $nested = Join-Path $InstallDir "bin\codewalk.exe"
    if (Test-Path $nested) {
      Copy-Item -Force $nested $BinaryPath
    } else {
      Fail "codewalk.exe not found in archive."
    }
  }

  Add-ToUserPath -PathEntry $InstallDir

  try {
    New-StartMenuShortcut -TargetExePath $BinaryPath
    Info "Start Menu shortcut created at $StartMenuShortcutPath"
  }
  catch {
    Warn "Could not create Start Menu shortcut: $($_.Exception.Message)"
  }

  Set-Content -Path $VersionFile -Value $release.tag_name -NoNewline

  Write-Host ""
  Write-Host "CodeWalk installed successfully at $InstallDir ($($release.tag_name))" -ForegroundColor Green
  Write-Host "Open a new terminal and run: codewalk"
}
finally {
  if (Test-Path $tmpRoot) {
    Remove-Item -Recurse -Force -Path $tmpRoot -ErrorAction SilentlyContinue
  }
}
