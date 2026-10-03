# Unofficial Fix - RSE - Shoulder Or Saddle (1.7.104)

Source code of an **unofficial patch** for [RSE - Shoulder Or Saddle](https://www.nexusmods.com/skyrimspecialedition/mods/170232)
by **Hunk92** (original source: [Hunk92/RSE-Shoulder-Or-Saddle](https://github.com/Hunk92/RSE-Shoulder-Or-Saddle)).

The patch makes RSE - Shoulder Or Saddle 1.4 work on Skyrim 1.7.104 and fixes many bugs of the original mod.
It requires the original mod: it only replaces its three SKSE DLLs and some of its Papyrus scripts.

This repository exists so that anyone can check exactly what was changed.
**Hunk92: feel free to take any of these fixes and include them in your own mod.**

## AI disclosure

This patch was made with generative AI (**Claude**, by Anthropic):

- **Code**: the analysis of the original mod and the changes to the C++ and Papyrus sources in this repository were written
  by the AI, as well as the build and packaging scripts.
- **Text**: this README, the installer texts and the Nexus Mods description were written with the AI.
- **Human part (Kroosstii)**: defining the goals, deciding what to fix or keep, testing every change in game on
  Skyrim 1.7.104, and reporting the results and logs that guided each fix.

The Nexus Mods page is tagged *AI-Generated Content* and *AI Media*, as required by the Nexus Mods file submission guidelines.

## What is in this repository

Only the files touched by the patch. The original mod's other files (plugin, animations, untouched scripts, interface)
are not included: get them from the original mod page.

| Path | Content |
|---|---|
| `RSE Player/`, `RSE Follower/`, `RSE Horse/` | C++ sources of the three SKSE plugins (CommonLibSSE-NG), with fixes |
| `Papyrus/Source/` | Modified Papyrus scripts of the original mod, plus `rshFixOptions` (camera option) |
| `Papyrus/AddonFemale/Source/` | Modified `rshPickUpScript` for the "ShoulderCarryState - female" add-on |
| `Papyrus/Options/` | Script variants installed by the FOMOD |
| `Translation/French/` | Repaired copy of the original French DSD translation file (JSON syntax error fixed) |
| `fomod/` | FOMOD installer |
| `build.ps1`, `Papyrus/compile.ps1`, `package.ps1` | Build, Papyrus compilation and packaging scripts |

Every change in the sources is marked with a `FIX patch` comment (comments are in French).

## Main changes

**SKSE plugins (C++)**
- Rebuilt against CommonLibSSE-NG v10.1.0 (Address Library format 5, Skyrim 1.7.x runtime detection).
- `Stop*Attachment` natives now take the `Actor` parameter declared in the `.psc` files. Without it, the Papyrus VM
  refused to bind them and the collision was never restored.
- The `ApplyMovementDelta` hook always runs the original function. It no longer skips the movement of unrelated actors,
  no longer wraps engine code in SEH and no longer logs on every frame.
- Attachment data uses actor handles and reference-counted nodes, is reset on `kPreLoadGame` / `kNewGame`,
  is protected by a mutex, and uses the third-person skeleton.

**Papyrus scripts**
- Deferred initialisation (`rshUpdateManagerScript`): spells, perks and MCM are available on a new game.
- None guards across the scripts (dozens of errors per session removed).
- Dropped or released NPCs can be activated again; add-on cuffs are removed; the player's crime faction is restored
  after the captive's alarm; the horse stops fighting the captive on its back.
- SkyPrompt made truly optional, with far fewer native calls per crosshair change.
- Built-in compatibility with Nether's Follower Framework (`nwsFF_NoHorseFac`, only factions added by the patch
  are removed).
- Optional switch to third person when picking someone up.

## Building

Requirements: Visual Studio with the C++ tools (MSVC 14.44), vcpkg, 7-Zip, Python 3, and the Skyrim Creation Kit
(Papyrus compiler and script sources).

1. Create `local.paths.ps1` at the root (ignored by Git):
   ```powershell
   $env:VCPKG_ROOT = "<path to vcpkg>"
   $env:SKYRIM_PATH = "<Skyrim Special Edition folder>"
   $env:RSE_MODS_PATH = "<Mod Organizer 2 mods folder>"
   ```
   `RSE_MODS_PATH` must contain the original mod (`RSE - Shoulder Or Saddle`), `Skyrim Script Extender (SKSE64) DATA`
   and `SkyPrompt` (Papyrus sources used as imports).
2. `./build.ps1` builds the three DLLs.
3. `./Papyrus/compile.ps1` compiles the scripts.
4. `./package.ps1` builds the FOMOD archive in `release/`.

## Credits

- **Hunk92** (uploaded by slevin92): RSE - Shoulder Or Saddle.
- Original credits of the mod: Musjes (Ride Sharing), shadowman2777 and Elsawirr (animations).
- giamel: ShoulderCarryState - female.
- alandtse and the CommonLibSSE-NG contributors.

Patch by Kroosstii. See [LICENSE](LICENSE).
