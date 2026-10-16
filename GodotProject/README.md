# Apptya Kingdom — Godot port prototype

This is a new, licence-free Godot implementation of the current mobile kingdom-management prototype. The original `UnityProject/` is intentionally retained as a fallback until this port has been built and tested.

## Current implemented prototype

- Portrait, touch-friendly interface
- Gold, wood, food and stone resource counters with direct gathering actions
- Procedural 3D valley with a river, bridge, roads, stone perimeter wall, four watchtowers, a southern gate, trees, a castle keep, farms, mines, barracks, ten enemy outposts, visible guard markers, and a gold-armored Royal Captain hero model with a level label
- Touch drag to orbit the camera and two-finger pinch to zoom
- Nine selectable kingdom tiles
- Farm, mine, Lumber Camp, Quarry, Academy and barracks construction; Academy levels discount research costs up to 25%
- Timed Keep and resource-building upgrades, with timers restored after app suspension
- Queued infantry, archer and cavalry training with Barracks capacity limits
- Combat, economy and scouting research; troop practice; region exploration; claimable campaign rewards and a persistent quest board
- Royal Captain hero with XP/levels, skill upgrades, battle/exploration progression, and an army-power bonus
- Scouting and targeted outpost battles with troop losses, rewards and visible battle/exploration animations; outposts unlock in campaign order and the HUD shows campaign progress through completion
- Timed production and bounded eight-hour offline production with research bonuses
- Periodic autosave, backup recovery, save-data normalization and persisted upgrade/training timers
- Procedural WAV sound effects for gathering, upgrades, training and battle outcomes, with a persistent mute toggle
- Seven-day daily reward streak, resource payouts, day-seven bonus, duplicate-claim protection, live reset countdown and saved progress
- Persistent Low / Balanced / High graphics presets and camera reset
- Local save/load on the device, including graphics preferences; save recovery enforces a unique Keep and Barracks troop capacity

This is a reimplementation of the prototype mechanics, not an automatic conversion of Unity scenes or C# scripts. It uses procedural low-poly models rather than authored production art, and does not yet contain production-quality art/animations, a soundtrack, multiplayer, or release signing.

## Android APK from GitHub

The workflow `.github/workflows/godot-android-apk.yml` builds a debug APK using Godot and GitHub Actions. Godot is free/open-source; no Unity licence or Unity secrets are needed.

1. Open the repository's **Actions** tab.
2. Select **Godot Android APK**.
3. Run **Run workflow** only after explicit approval to build an APK. Source changes do not trigger APK builds.
4. Open the completed run and download the `apptya-kingdom-godot-apk` artifact.

The latest headless Godot integration run passed ([workflow run](https://github.com/pawanroyindia/Apptya-Kingdom/actions/runs/38853475729)), including project parsing/startup, gameplay and save recovery, touch controls, quest and hero progression, generated sound effects, daily rewards, Academy construction/3D model/research discount, sequential campaign unlocks, and the 256-mesh budget/stable-refresh checks. The APK workflow remains manual-only and has not been run. The first approved APK workflow run is still required to verify the export setup. The APK is for testing, not a Play Store release.

## Validation

Source validation runs through `.github/workflows/godot-source-check.yml` and does not export an APK. A successful source check is not a substitute for Android export, installation, or device testing.

## Open locally

Open this `GodotProject/` folder with Godot 4.5 or compatible Godot 4.x editor.
