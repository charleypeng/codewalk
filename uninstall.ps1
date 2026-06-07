Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# CodeWalk uninstaller (Windows)
# Usage: irm https://raw.githubusercontent.com/<owner>/<repo>/main/uninstall.ps1 | iex

$InstallDir = Join-Path $env:LOCALAPPDATA "CodeWalk"
$StartMenuShortcutPath = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\CodeWalk.lnk"

function Info([string]$Message) {
  Write-Host ":: $Message" -ForegroundColor Cyan
}

function Warn([string]$Message) {
  Write-Host ":: $Message" -ForegroundColor Yellow
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

function Register-RebootDelete([string]$Path) {
  try {
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

function Remove-InstallDir {
  if (-not (Test-Path $InstallDir)) { return $true }

  try {
    Remove-Item -Recurse -Force -Path $InstallDir -ErrorAction Stop
    Info "Removed install directory: $InstallDir"
    return $true
  } catch {}

  Stop-CodeWalkProcess
  try {
    Remove-Item -Recurse -Force -Path $InstallDir -ErrorAction Stop
    Info "Removed install directory: $InstallDir"
    return $true
  } catch {}

  $oldDir = "${InstallDir}.old"
  if (Test-Path $oldDir) {
    try {
      Remove-Item -Recurse -Force -Path $oldDir -ErrorAction SilentlyContinue
    } catch {
      Register-RebootDelete -Path $oldDir
    }
  }

  try {
    Rename-Item -Path $InstallDir -NewName 'CodeWalk.old' -ErrorAction Stop
    Info "Renamed locked directory to $oldDir"
    Register-RebootDelete -Path $oldDir
    Info "Install directory will be removed on next reboot."
    return $true
  } catch {
    Warn "Cannot remove or rename $InstallDir. Close CodeWalk and retry uninstall."
    return $false
  }
}

function Remove-FromUserPath([string]$PathEntry) {
  $current = [Environment]::GetEnvironmentVariable("Path", "User")
  if (-not $current) {
    return
  }

  $normalizedTarget = $PathEntry.Trim().TrimEnd('\').ToLowerInvariant()
  $parts = $current.Split(";") | Where-Object {
    $candidate = $_.Trim()
    if (-not $candidate) {
      return $false
    }
    $candidate.TrimEnd('\').ToLowerInvariant() -ne $normalizedTarget
  }

  $updated = $parts -join ";"
  [Environment]::SetEnvironmentVariable("Path", $updated, "User")
}

$removedAny = $false

if (Test-Path $StartMenuShortcutPath) {
  Remove-Item -Force -Path $StartMenuShortcutPath
  Info "Removed Start Menu shortcut: $StartMenuShortcutPath"
  $removedAny = $true
}

if (Test-Path $InstallDir) {
  if (Remove-InstallDir) {
    $removedAny = $true
  } else {
    Write-Host "" -ForegroundColor Yellow
    Write-Host "CodeWalk uninstall finished with errors." -ForegroundColor Yellow
    exit 1
  }
}

Remove-FromUserPath -PathEntry $InstallDir
Info "Removed CodeWalk install path from user PATH (if present)."

if (-not $removedAny) {
  Warn "No CodeWalk installation artifacts found."
}

Write-Host ""
Write-Host "CodeWalk uninstall finished." -ForegroundColor Green
