#Requires -Version 5.1
<#
Assemble l'archive FOMOD du patch « RSE - Shoulder Or Saddle - 1.7.104 Fix » à partir des sorties de build.
Prérequis : build.ps1 (DLL) et Papyrus\compile.ps1 (scripts) déjà exécutés.
Sortie : release\RSE - Shoulder Or Saddle - 1.7.104 Fix-<version>.7z
#>
param([string]$Version = "1.0.0")
$ErrorActionPreference = "Stop"
$Root = $PSScriptRoot
$Stage = Join-Path $Root "release\fomod-build"
$Papyrus = Join-Path $Root "Papyrus"
$SevenZip = Join-Path $env:ProgramFiles "7-Zip\7z.exe"

if (Test-Path $Stage) { Remove-Item -Recurse -Force $Stage }
function Copy-To([string]$Source, [string]$Destination) {
    New-Item -ItemType Directory -Force (Split-Path $Destination) | Out-Null
    Copy-Item $Source $Destination -Force
}

# fomod
Copy-To (Join-Path $Root "fomod\info.xml") (Join-Path $Stage "fomod\info.xml")
Copy-To (Join-Path $Root "fomod\ModuleConfig.xml") (Join-Path $Stage "fomod\ModuleConfig.xml")

# Core : DLL + scripts corrigés (sauf les variantes gérées par le FOMOD) + leurs sources
foreach ($plugin in "Player", "Follower", "Horse") {
    Copy-To (Join-Path $Root "build\release\RSE $plugin\RSE${plugin}SKSE.dll") (Join-Path $Stage "Core\SKSE\Plugins\RSE${plugin}SKSE.dll")
}
$variants = @("rshPickUpScript", "rshFixOptions")
foreach ($pex in Get-ChildItem (Join-Path $Papyrus "out\Scripts") -Filter *.pex) {
    if ($variants -contains $pex.BaseName) { continue }
    Copy-To $pex.FullName (Join-Path $Stage "Core\Scripts\$($pex.Name)")
    Copy-To (Join-Path $Papyrus "Source\$($pex.BaseName).psc") (Join-Path $Stage "Core\Source\scripts\$($pex.BaseName).psc")
}

# Variantes du script de portage (choix automatique selon la présence de l'add-on Female)
Copy-To (Join-Path $Papyrus "out\Scripts\rshPickUpScript.pex") (Join-Path $Stage "PickUp\Original\Scripts\rshPickUpScript.pex")
Copy-To (Join-Path $Papyrus "Source\rshPickUpScript.psc") (Join-Path $Stage "PickUp\Original\Source\scripts\rshPickUpScript.psc")
Copy-To (Join-Path $Papyrus "out-addon\Scripts\rshPickUpScript.pex") (Join-Path $Stage "PickUp\FemaleAddon\Scripts\rshPickUpScript.pex")
Copy-To (Join-Path $Papyrus "AddonFemale\Source\rshPickUpScript.psc") (Join-Path $Stage "PickUp\FemaleAddon\Source\scripts\rshPickUpScript.psc")

# Option caméra
Copy-To (Join-Path $Papyrus "out\Scripts\rshFixOptions.pex") (Join-Path $Stage "Camera\ThirdPerson\Scripts\rshFixOptions.pex")
Copy-To (Join-Path $Papyrus "Source\rshFixOptions.psc") (Join-Path $Stage "Camera\ThirdPerson\Source\scripts\rshFixOptions.psc")
Copy-To (Join-Path $Papyrus "out-options\KeepFirstPerson\Scripts\rshFixOptions.pex") (Join-Path $Stage "Camera\FirstPerson\Scripts\rshFixOptions.pex")
Copy-To (Join-Path $Papyrus "Options\KeepFirstPerson\Source\rshFixOptions.psc") (Join-Path $Stage "Camera\FirstPerson\Source\scripts\rshFixOptions.psc")

# Traduction française corrigée
$json = "SKSE\Plugins\DynamicStringDistributor\RSE-ShoulderOrSaddle.esp\french.dsd.json"
Copy-To (Join-Path $Root "Translation\French\$json") (Join-Path $Stage "French\$json")

# Archive
$archive = Join-Path $Root "release\RSE - Shoulder Or Saddle - 1.7.104 Fix-$Version.7z"
if (Test-Path $archive) { Remove-Item -Force $archive }
& $SevenZip a -t7z -mx=9 $archive "$Stage\*" | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Échec de la création de l'archive ($LASTEXITCODE)." }
Write-Host "Archive : $archive"
Get-ChildItem $Stage -Recurse -File | ForEach-Object { $_.FullName.Substring($Stage.Length + 1) }
