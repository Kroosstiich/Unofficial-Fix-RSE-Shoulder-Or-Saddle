#Requires -Version 5.1
<#
Compile les 3 plugins SKSE de RSE - Shoulder Or Saddle (patch 1.7.104 Fix).
Ne touche ni au jeu ni à MO2, sauf si -OutputFolder est fourni.
VCPKG_ROOT : dépôt vcpkg bootstrappé (variable d'environnement, ou local.paths.ps1). VS_PATH optionnel.
#>
param(
    [ValidateSet("Release", "Debug")][string]$Config = "Release",
    [string]$OutputFolder = "",
    [ValidateRange(1, 32)][int]$Jobs = 4
)
$ErrorActionPreference = "Stop"
$ProjectRoot = $PSScriptRoot
$localPaths = Join-Path $ProjectRoot "local.paths.ps1"
if (Test-Path $localPaths) { . $localPaths }
if (-not $env:VCPKG_ROOT -or -not (Test-Path (Join-Path $env:VCPKG_ROOT "vcpkg.exe"))) {
    throw "vcpkg introuvable : définir VCPKG_ROOT (variable d'environnement ou local.paths.ps1)."
}
$VsPath = $env:VS_PATH
if (-not $VsPath) {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer\vswhere.exe"
    $VsPath = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
}
if (-not $VsPath) { throw "Outils C++ de Visual Studio introuvables ; définir VS_PATH." }
$vcvars = Join-Path $VsPath "VC\Auxiliary\Build\vcvarsall.bat"
$cmake = Join-Path $VsPath "Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe"
$ninjaDir = Join-Path $VsPath "Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja"
$installerDir = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer"
$env:PATH = "$installerDir;$ninjaDir;$env:PATH"
$toolset = "14.44"
# Importe l'environnement du compilateur sans écrire de fichier.
$compilerEnv = & cmd.exe /d /s /c "call `"$vcvars`" x64 -vcvars_ver=$toolset >nul && set"
if ($LASTEXITCODE -ne 0) { throw "vcvarsall a échoué." }
foreach ($line in $compilerEnv) {
    if ($line -match '^([^=]+)=(.*)$') { [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process") }
}
$env:VCPKG_MAX_CONCURRENCY = "$Jobs"
$env:CXXFLAGS = "/permissive- /Zc:preprocessor /EHsc /MP -DWIN32_LEAN_AND_MEAN -DNOMINMAX -DUNICODE -D_UNICODE"
$binaryDir = Join-Path $ProjectRoot "build\$($Config.ToLower())"
# Git pour Windows explicite : le git msys2 de devkitPro, présent dans le PATH, échoue sur les clones de FetchContent.
$gitExe = Join-Path $env:ProgramFiles "Git\cmd\git.exe"
if (-not (Test-Path $gitExe)) { $gitExe = (Get-Command git.exe).Source }
# CMake/CommonLib écrivent des messages d'information sur stderr : seul le code de retour fait foi.
$ErrorActionPreference = "Continue"
& $cmake -S $ProjectRoot -B $binaryDir -G Ninja "-DCMAKE_BUILD_TYPE=$Config" `
    "-DCMAKE_TOOLCHAIN_FILE=$env:VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake" `
    "-DVCPKG_TARGET_TRIPLET=x64-windows-skse" "-DVCPKG_HOST_TRIPLET=x64-windows-skse" `
    "-DVCPKG_OVERLAY_TRIPLETS=$ProjectRoot/cmake" `
    "-DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded`$<`$<CONFIG:Debug>:Debug>DLL" `
    "-DRSE_OUTPUT_FOLDER=$OutputFolder" `
    "-DGIT_EXECUTABLE=$gitExe"
if ($LASTEXITCODE -ne 0) { throw "Échec de la configuration CMake ($LASTEXITCODE)." }
& $cmake --build $binaryDir --parallel $Jobs
if ($LASTEXITCODE -ne 0) { throw "Échec de la compilation ($LASTEXITCODE)." }
Get-ChildItem $binaryDir -Recurse -Filter "RSE*SKSE.dll" | ForEach-Object { Write-Host "Compilé : $($_.FullName)" }
