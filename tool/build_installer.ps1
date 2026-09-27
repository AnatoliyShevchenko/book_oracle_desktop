<#
.SYNOPSIS
    Builds Book Oracle and packages it into a Windows installer.

.DESCRIPTION
    Compiles the release build, locates the Visual C++ runtime that has to be
    shipped alongside it, and runs the Inno Setup compiler. The finished
    installer lands in dist\.

.PARAMETER SkipBuild
    Package whatever is already in build\windows\x64\runner\Release.

.EXAMPLE
    pwsh -File tool\build_installer.ps1
#>
[CmdletBinding()]
param(
    [switch]$SkipBuild
)

$ErrorActionPreference = 'Stop'

$projectDir = Split-Path -Parent $PSScriptRoot
$buildDir = Join-Path $projectDir 'build\windows\x64\runner\Release'
$issFile = Join-Path $projectDir 'installer\book_oracle.iss'
$distDir = Join-Path $projectDir 'dist'

function Find-Iscc {
    $candidates = @(
        "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe",
        "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
        "$env:ProgramFiles\Inno Setup 6\ISCC.exe"
    )
    foreach ($c in $candidates) { if (Test-Path $c) { return $c } }
    $cmd = Get-Command ISCC.exe -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    throw "Inno Setup not found. Install it with: winget install JRSoftware.InnoSetup"
}

# The app links against the MSVC runtime, which is not part of a clean Windows
# install. Shipping these DLLs next to the exe keeps the installer admin-free.
function Find-CrtDir {
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (-not (Test-Path $vswhere)) { throw 'vswhere.exe not found — is Visual Studio installed?' }
    $vsPath = & $vswhere -latest -products * -property installationPath
    if (-not $vsPath) { throw 'No Visual Studio installation found.' }

    $redistRoot = Join-Path $vsPath 'VC\Redist\MSVC'
    if (-not (Test-Path $redistRoot)) { throw "No VC redist under $redistRoot" }

    $crt = Get-ChildItem $redistRoot -Directory |
        Where-Object { $_.Name -match '^\d+\.' } |
        Sort-Object { [version]($_.Name) } -Descending |
        ForEach-Object { Get-ChildItem (Join-Path $_.FullName 'x64') -Directory -Filter '*.CRT' -ErrorAction SilentlyContinue } |
        Select-Object -First 1
    if (-not $crt) { throw "No Microsoft.VC*.CRT folder under $redistRoot" }
    return $crt.FullName
}

function Get-AppVersion {
    $line = Select-String -Path (Join-Path $projectDir 'pubspec.yaml') -Pattern '^version:\s*(.+)$'
    if (-not $line) { throw 'No version: line in pubspec.yaml' }
    # "1.0.0+1" -> "1.0.0"; Inno wants a plain dotted version.
    return ($line.Matches[0].Groups[1].Value.Trim() -split '\+')[0]
}

$version = Get-AppVersion
Write-Host "Book Oracle $version" -ForegroundColor Cyan

if (-not $SkipBuild) {
    Write-Host 'Building the release…' -ForegroundColor Cyan
    Push-Location $projectDir
    try {
        $flutter = if (Get-Command fvm -ErrorAction SilentlyContinue) { 'fvm' } else { $null }
        if ($flutter) { & fvm flutter build windows --release }
        else { & flutter build windows --release }
        if ($LASTEXITCODE -ne 0) { throw "flutter build failed with exit code $LASTEXITCODE" }
    }
    finally { Pop-Location }
}

if (-not (Test-Path (Join-Path $buildDir 'book_oracle.exe'))) {
    throw "No build found in $buildDir — run without -SkipBuild."
}

$iscc = Find-Iscc
$crtDir = Find-CrtDir
Write-Host "Inno Setup : $iscc"
Write-Host "VC runtime : $crtDir"

New-Item -ItemType Directory -Force $distDir | Out-Null

& $iscc `
    "/DAppVersion=$version" `
    "/DProjectDir=$projectDir" `
    "/DBuildDir=$buildDir" `
    "/DCrtDir=$crtDir" `
    $issFile
if ($LASTEXITCODE -ne 0) { throw "ISCC failed with exit code $LASTEXITCODE" }

$setup = Join-Path $distDir "BookOracleSetup-$version.exe"
$size = '{0:N1} MB' -f ((Get-Item $setup).Length / 1MB)
Write-Host ''
Write-Host "Installer: $setup ($size)" -ForegroundColor Green
