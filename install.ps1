Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# CodeWalk installer (Windows)
# Usage: irm https://raw.githubusercontent.com/<owner>/<repo>/main/install.ps1 | iex

$Repo = if ($env:CODEWALK_REPO) { $env:CODEWALK_REPO } else { "verseles/codewalk" }
$InstallDir = Join-Path $env:LOCALAPPDATA "CodeWalk"
$BinaryPath = Join-Path $InstallDir "codewalk.exe"
$VersionFile = Join-Path $InstallDir ".installed-version"
$StartMenuShortcutPath = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\CodeWalk.lnk"
$StageRoot = Join-Path $env:LOCALAPPDATA "CodeWalk.update"
$StagePayloadDir = Join-Path $StageRoot "payload"
$PendingVersionFile = Join-Path $StageRoot ".pending-version"
$InstallMode = if ($env:CODEWALK_INSTALL_MODE) { $env:CODEWALK_INSTALL_MODE.ToLowerInvariant() } else { "install" }

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

function Get-PendingVersion {
  if (-not (Test-Path $PendingVersionFile)) {
    return ""
  }

  try {
    return (Get-Content -Path $PendingVersionFile -Raw).Trim()
  }
  catch {
    return ""
  }
}

function Test-CodeWalkRunning {
  $proc = Get-Process -Name 'codewalk' -ErrorAction SilentlyContinue
  return $null -ne $proc
}

function Stop-CodeWalkProcess {
  $procs = @()
  try {
    $found = Get-Process -Name 'codewalk' -ErrorAction Stop
    if ($found -is [array]) { $procs = $found } else { $procs = @($found) }
  } catch { return }
  if ($procs.Count -eq 0) { return }

  Info "Stopping $($procs.Count) running CodeWalk process(es) before applying update"
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
  Start-Sleep -Milliseconds 500

  $survivors = Get-Process -Name 'codewalk' -ErrorAction SilentlyContinue
  if ($survivors) {
    Warn "CodeWalk process(es) still running after first stop attempt; retrying"
    foreach ($proc in @($survivors)) {
      try {
        Stop-Process -Id $proc.Id -Force -ErrorAction Stop
      } catch {
        Warn "Could not stop CodeWalk process (PID $($proc.Id)): $($_.Exception.Message)"
      }
    }
    Start-Sleep -Seconds 2
  }
}

function Get-ParentProcessId {
  try {
    $proc = Get-CimInstance Win32_Process -Filter "ProcessId = $PID" -ErrorAction Stop
    if ($proc.ParentProcessId) { return [int]$proc.ParentProcessId }
  } catch {
    try {
      $proc = Get-WmiObject Win32_Process -Filter "ProcessId = $PID" -ErrorAction Stop
      if ($proc.ParentProcessId) { return [int]$proc.ParentProcessId }
    } catch {}
  }

  return 0
}

function Get-CodeWalkParentProcessId {
  $parentPid = Get-ParentProcessId
  if ($parentPid -le 0) { return 0 }

  try {
    $parent = Get-Process -Id $parentPid -ErrorAction Stop
    if ($parent.ProcessName -eq 'codewalk') {
      return $parentPid
    }
  } catch {}

  return 0
}

function Wait-ForParentExit([int]$ProcessId) {
  if ($ProcessId -le 0) { return }

  try {
    Info "Waiting for CodeWalk process $ProcessId to exit before applying update"
    Wait-Process -Id $ProcessId -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 500
  } catch {}
}

function Complete-InstallIntegration([string]$Version) {
  Get-ChildItem -Path $InstallDir -Recurse | Unblock-File -ErrorAction SilentlyContinue

  if (-not (Test-Path $BinaryPath)) {
    $nested = Join-Path $InstallDir "bin\codewalk.exe"
    if (Test-Path $nested) {
      Copy-Item -Force $nested $BinaryPath
    } else {
      Fail "codewalk.exe not found in staged package."
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

  Set-Content -Path $VersionFile -Value $Version -NoNewline
}

function Save-StagedPackage([string]$ZipPath, [string]$Version) {
  if (Test-Path $StageRoot) {
    Remove-Item -Recurse -Force -Path $StageRoot -ErrorAction Stop
  }
  New-Item -ItemType Directory -Force -Path $StagePayloadDir | Out-Null

  Info "Extracting package to staging directory"
  Expand-Archive -Path $ZipPath -DestinationPath $StagePayloadDir -Force

  $stagedBinary = Join-Path $StagePayloadDir "codewalk.exe"
  $nestedBinary = Join-Path $StagePayloadDir "bin\codewalk.exe"
  if (-not (Test-Path $stagedBinary) -and -not (Test-Path $nestedBinary)) {
    Fail "codewalk.exe not found in archive."
  }

  Set-Content -Path $PendingVersionFile -Value $Version -NoNewline
}

function Apply-StagedInstall {
  $pendingVersion = Get-PendingVersion
  if (-not $pendingVersion) {
    Fail "No staged CodeWalk update found."
  }
  if (-not (Test-Path $StagePayloadDir)) {
    Fail "Staged CodeWalk payload not found."
  }

  Stop-CodeWalkProcess

  if (Test-Path $InstallDir) {
    $removed = $false
    for ($attempt = 1; $attempt -le 3; $attempt++) {
      try {
        Remove-Item -Recurse -Force -Path $InstallDir -ErrorAction Stop
        $removed = $true
        break
      } catch {
        if ($attempt -lt 3) {
          Warn "Install directory is still locked; retrying removal ($attempt/3)"
          Start-Sleep -Seconds 2
        }
      }
    }
    if (-not $removed) {
      Fail "Cannot remove $InstallDir after closing CodeWalk. Staged update remains at $StageRoot."
    }
  }
  New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

  Get-ChildItem -Path $StagePayloadDir -Force | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $InstallDir -Recurse -Force
  }

  Complete-InstallIntegration -Version $pendingVersion
  Remove-Item -Recurse -Force -Path $StageRoot -ErrorAction SilentlyContinue
  Info "CodeWalk update applied at $InstallDir ($pendingVersion)"
}

function Start-ApplyHelper([int]$ParentPid, [bool]$Relaunch) {
  $repoValue = $Repo.Replace("'", "''")
  $relaunchValue = if ($Relaunch) { "1" } else { "0" }
  $command = "`$env:CODEWALK_REPO='$repoValue'; `$env:CODEWALK_INSTALL_MODE='apply'; `$env:CODEWALK_PARENT_PID='$ParentPid'; `$env:CODEWALK_RELAUNCH='$relaunchValue'; irm install.cat/$repoValue | iex"
  $encoded = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($command))
  Start-Process -FilePath "powershell" -ArgumentList @("-NoProfile", "-ExecutionPolicy", "Bypass", "-EncodedCommand", $encoded) -WindowStyle Hidden
}

if ($InstallMode -eq "apply") {
  $parentPid = 0
  if ($env:CODEWALK_PARENT_PID) {
    try { $parentPid = [int]$env:CODEWALK_PARENT_PID } catch { $parentPid = 0 }
  }
  try {
    Wait-ForParentExit -ProcessId $parentPid
    Apply-StagedInstall
    if ($env:CODEWALK_RELAUNCH -eq "1" -and (Test-Path $BinaryPath)) {
      Start-Process -FilePath $BinaryPath -WorkingDirectory $InstallDir
    }
  } catch {
    Warn "CodeWalk update apply failed: $($_.Exception.Message)"
    $canRelaunch = (Test-Path $BinaryPath) -and (Test-Path $VersionFile)
    if ($env:CODEWALK_RELAUNCH -eq "1" -and $canRelaunch) {
      Start-Process -FilePath $BinaryPath -WorkingDirectory $InstallDir
    } elseif ($env:CODEWALK_RELAUNCH -eq "1") {
      Warn "CodeWalk was not relaunched because the install directory is incomplete. Staged update remains at $StageRoot."
    }
    exit 1
  }
  exit 0
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

  Save-StagedPackage -ZipPath $zipPath -Version $release.tag_name

  if ($InstallMode -eq "stage") {
    Write-Host ""
    Write-Host "CodeWalk update staged at $StageRoot ($($release.tag_name))" -ForegroundColor Green
    Write-Host "Restart CodeWalk to apply the update."
    exit 0
  }

  if (Test-CodeWalkRunning) {
    $parentPid = Get-CodeWalkParentProcessId
    Start-ApplyHelper -ParentPid $parentPid -Relaunch $true
    Write-Host ""
    Write-Host "CodeWalk update staged at $StageRoot ($($release.tag_name))" -ForegroundColor Green
    Write-Host "Restart CodeWalk to apply the update."
    exit 0
  }

  Apply-StagedInstall

  Write-Host ""
  Write-Host "CodeWalk installed successfully at $InstallDir ($($release.tag_name))" -ForegroundColor Green
  Write-Host "Open a new terminal and run: codewalk"
}
finally {
  if (Test-Path $tmpRoot) {
    Remove-Item -Recurse -Force -Path $tmpRoot -ErrorAction SilentlyContinue
  }
}
