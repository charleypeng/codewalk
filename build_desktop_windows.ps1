Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $repoRoot

$pubspecPath = Join-Path $repoRoot 'pubspec.yaml'
if (-not (Test-Path -LiteralPath $pubspecPath)) {
  throw "Could not find pubspec.yaml next to build_desktop_windows.ps1. Keep this script in the CodeWalk repository root."
}

$versionLine = Get-Content -LiteralPath $pubspecPath |
  Where-Object { $_ -match '^\s*version\s*:\s*([^\s#]+)' } |
  Select-Object -First 1

if (-not $versionLine) {
  throw 'Unable to parse version from pubspec.yaml. Expected: version: name+build'
}

$version = [regex]::Match($versionLine, '^\s*version\s*:\s*([^\s#]+)').Groups[1].Value
$versionParts = $version -split '\+', 2
if ($versionParts.Count -ne 2 -or -not $versionParts[0] -or -not $versionParts[1]) {
  throw "Unable to parse version from pubspec.yaml. Expected name+build, got: $version"
}

$buildName = $versionParts[0]
$buildNumber = $versionParts[1]
$flutter = 'C:\Users\helio\flutter\bin\flutter.bat'
if (-not (Test-Path -LiteralPath $flutter)) {
  $flutter = 'flutter'
}

Write-Host 'Detected Windows host. Building Windows desktop app...'
Write-Host "Version: $buildName+$buildNumber"
Write-Host "Flutter: $flutter"

if ($args -contains '--dry-run') {
  Write-Host ''
  Write-Host 'Dry run only. Command that would be executed:'
  Write-Host "`"$flutter`" build windows --release --build-name `"$buildName`" --build-number `"$buildNumber`""
  exit 0
}

& $flutter build windows --release --build-name $buildName --build-number $buildNumber
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

$generatedConfig = Join-Path $repoRoot 'windows\flutter\ephemeral\generated_config.cmake'
if (-not (Test-Path -LiteralPath $generatedConfig)) {
  throw "Desktop build version mismatch: $generatedConfig was not generated."
}

$expectedVersion = "$buildName+$buildNumber"
$configText = Get-Content -LiteralPath $generatedConfig -Raw
if (-not $configText.Contains($expectedVersion)) {
  throw "Desktop build version mismatch: $generatedConfig does not reflect $expectedVersion"
}

Write-Host 'Desktop build ready: build\windows\x64\runner\Release\'
