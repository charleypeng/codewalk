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

$windowsBuildDir = Join-Path $repoRoot 'build\windows\x64'
$buildNugetConfig = Join-Path $windowsBuildDir 'NuGet.Config'
New-Item -ItemType Directory -Force -Path $windowsBuildDir | Out-Null
$nugetConfigText = @'
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <clear />
    <add key="nuget.org" value="https://api.nuget.org/v3/index.json" protocolVersion="3" />
  </packageSources>
</configuration>
'@
Set-Content -LiteralPath $buildNugetConfig -Value $nugetConfigText -Encoding utf8
Write-Host "NuGet config: $buildNugetConfig"

$pathNuget = Get-Command 'nuget.exe' -ErrorAction SilentlyContinue
$nugetDir = Join-Path $repoRoot 'build\tools\nuget'
$nugetExe = Join-Path $nugetDir 'nuget.exe'

if ($pathNuget) {
  $nugetExe = $pathNuget.Source
  $nugetDir = Split-Path -Parent $nugetExe
}
else {
  New-Item -ItemType Directory -Force -Path $nugetDir | Out-Null
  if (-not (Test-Path -LiteralPath $nugetExe)) {
    $existingNuget = Get-ChildItem -Path $windowsBuildDir -Recurse -Filter 'nuget.exe' -ErrorAction SilentlyContinue |
      Select-Object -First 1

    if ($existingNuget) {
      Copy-Item -LiteralPath $existingNuget.FullName -Destination $nugetExe -Force
    }
    else {
      $nugetUrl = 'https://dist.nuget.org/win-x86-commandline/v6.5.0/nuget.exe'
      Write-Host "Downloading NuGet: $nugetUrl"
      [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
      Invoke-WebRequest -Uri $nugetUrl -OutFile $nugetExe
    }
  }

  $env:PATH = "$nugetDir;$env:PATH"
}

Write-Host "NuGet executable: $nugetExe"

if ($args -contains '--dry-run') {
  Write-Host ''
  Write-Host 'Dry run only. Command that would be executed:'
  Write-Host "`"$flutter`" build windows --release --build-name `"$buildName`" --build-number `"$buildNumber`""
  exit 0
}

$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
$vsInstallPath = $null
if (Test-Path -LiteralPath $vswhere) {
  $vsInstallPath = (& $vswhere -products * -latest -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath).Trim()
}

if (-not $vsInstallPath) {
  Write-Host ''
  Write-Host 'Visual Studio Build Tools with C++ support was not found.'
  Write-Host 'Install Visual Studio 2022 Build Tools with the Desktop development with C++ workload, then run this script again.'
  exit 1
}

$msvcToolsRoot = Join-Path $vsInstallPath 'VC\Tools\MSVC'
$hasAtlHeaders = $false
if (Test-Path -LiteralPath $msvcToolsRoot) {
  Get-ChildItem -LiteralPath $msvcToolsRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $atlBase = Join-Path $_.FullName 'atlmfc\include\atlbase.h'
    $atlStr = Join-Path $_.FullName 'atlmfc\include\atlstr.h'
    if ((Test-Path -LiteralPath $atlBase) -and (Test-Path -LiteralPath $atlStr)) {
      $hasAtlHeaders = $true
    }
  }
}

if (-not $hasAtlHeaders) {
  $vsInstaller = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vs_installer.exe'
  if (-not (Test-Path -LiteralPath $vsInstaller)) {
    $vsInstaller = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\setup.exe'
  }

  Write-Host ''
  Write-Host 'Visual Studio Build Tools is missing ATL headers required by Windows plugins.'
  Write-Host 'Missing headers: atlbase.h, atlstr.h'
  Write-Host 'Install the "C++ ATL for latest v143 build tools" component, then run this script again.'
  Write-Host ''
  Write-Host 'Elevated PowerShell/CMD command:'
  Write-Host "`"$vsInstaller`" modify --installPath `"$vsInstallPath`" --add Microsoft.VisualStudio.Component.VC.ATL --passive --norestart"
  exit 1
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
