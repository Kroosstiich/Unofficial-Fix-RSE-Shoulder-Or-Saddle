#Requires -Version 5.1
<#
Compile les scripts Papyrus modifiés du patch (jamais dans le dossier du mod d'origine).
  Source\             -> out\Scripts\           (scripts du mod principal)
  AddonFemale\Source\ -> out-addon\Scripts\     (variante de rshPickUpScript de l'add-on Female)
  Options\<option>\Source\ -> out-options\<option>\Scripts\  (variantes FOMOD)
Ordre des imports : sources du patch, sources d'origine du mod, SKSE, vanilla.
#>
$ErrorActionPreference = "Stop"
$Root = $PSScriptRoot
# Chemins locaux : variables d'environnement SKYRIM_PATH (dossier du jeu, avec le Creation Kit) et
# RSE_MODS_PATH (dossier « mods » de Mod Organizer 2), SKYUI_SDK_PATH (sources complètes de SkyUI, pour le MCM),
# ou fichier local.paths.ps1 à la racine du projet.
$localPaths = Join-Path (Split-Path $Root) "local.paths.ps1"
if (Test-Path $localPaths) { . $localPaths }
if (-not $env:SKYRIM_PATH -or -not $env:RSE_MODS_PATH -or -not $env:SKYUI_SDK_PATH) { throw "Définir SKYRIM_PATH, RSE_MODS_PATH et SKYUI_SDK_PATH (ou local.paths.ps1)." }
$Game = $env:SKYRIM_PATH
$Mods = $env:RSE_MODS_PATH
$Compiler = Join-Path $Game "Papyrus Compiler\PapyrusCompiler.exe"
$Flags = Join-Path $Game "Data\Source\Scripts\TESV_Papyrus_Flags.flg"
$RseSource = Join-Path $Mods "RSE - Shoulder Or Saddle\Source\scripts"
$SkseSource = Join-Path $Mods "Skyrim Script Extender (SKSE64) DATA\Scripts\Source"
$VanillaSource = Join-Path $Game "Data\Source\Scripts"
$SkyPromptSource = Join-Path $Mods "SkyPrompt\Scripts\Source"   # API SkyPrompt 2.4.1 (scripts rshSkyPrompt*)
$SkyUISource = $env:SKYUI_SDK_PATH                                 # SKI_ConfigBase… (script rshConfigMenu)

function Invoke-Compile([string]$SourceDir, [string]$OutDir) {
    New-Item -ItemType Directory -Force $OutDir | Out-Null
    # Le compilateur résout chaque script par son NOM dans les imports : un même nom présent dans deux dossiers
    # d'import fait compiler la mauvaise variante. Seul le dossier compilé est donc ajouté aux imports d'origine.
    $imports = @($SourceDir, $RseSource, $SkyPromptSource, $SkyUISource, $SkseSource, $VanillaSource) -join ";"
    # Le compilateur cherche aussi dans le dossier COURANT avant les imports : on se place dans le dossier compilé,
    # sinon une variante homonyme du dossier courant est compilée à la place.
    Push-Location $SourceDir
    try {
    foreach ($psc in Get-ChildItem $SourceDir -Filter *.psc) {
        $ErrorActionPreference = "Continue"
        # Passer le NOM du script (pas son chemin) : avec un chemin complet, le compilateur peut prendre une autre variante.
        $out = & $Compiler $psc.BaseName "-f=$Flags" "-i=$imports" "-o=$OutDir" "-op" 2>&1
        $code = $LASTEXITCODE
        $ErrorActionPreference = "Stop"
        $out | Where-Object { $_ -match "error|warning|Compilation|Assembly" } | ForEach-Object { Write-Host "  $_" }
        if ($code -ne 0) { throw "Échec de compilation : $($psc.Name)" }
        Write-Host "OK : $($psc.Name)"
    }
    } finally { Pop-Location }
}

Invoke-Compile (Join-Path $Root "Source") (Join-Path $Root "out\Scripts")
Invoke-Compile (Join-Path $Root "AddonFemale\Source") (Join-Path $Root "out-addon\Scripts")
foreach ($option in Get-ChildItem (Join-Path $Root "Options") -Directory) {
    Invoke-Compile (Join-Path $option.FullName "Source") (Join-Path $Root "out-options\$($option.Name)\Scripts")
}

# Les .pex publiés ne doivent pas contenir le nom d'utilisateur ni le nom de la machine de compilation.
& py -3.12 (Join-Path $Root "anonymize_pex.py") (Join-Path $Root "out") (Join-Path $Root "out-addon") (Join-Path $Root "out-options")
if ($LASTEXITCODE -ne 0) { throw "Échec de l'anonymisation des .pex" }
