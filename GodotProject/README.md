# Apptya Kingdom — Godot port prototype

This is a new, licence-free Godot implementation of the current mobile kingdom-management prototype. The original `UnityProject/` is intentionally retained as a fallback until this port has been built and tested.

## Current implemented prototype

- Portrait, touch-friendly interface
- Gold, wood, food and stone resource counters with direct gathering actions
- Procedural 3D valley with a river, bridge, roads, trees, a castle keep, farms, mines, barracks, five enemy outposts and visible guard markers
- Touch drag to orbit the camera and two-finger pinch to zoom
- Nine selectable kingdom tiles
- Farm, mine and barracks construction
- Timed Keep and resource-building upgrades, with timers restored after app suspension
- Queued infantry, archer and cavalry training with Barracks capacity limits
- Combat, economy and scouting research; troop practice; region exploration; claimable campaign rewards
- Scouting and targeted outpost battles with troop losses, rewards and visible battle/exploration animations; outposts unlock in campaign order
- Timed production and bounded eight-hour offline production with research bonuses
- Periodic autosave, backup recovery, save-data normalization and persisted upgrade/training timers
- Local save/load on the device, including graphics preferences; save recovery enforces a unique Keep and Barracks troop capacity

This is a reimplementation of the prototype mechanics, not an automatic conversion of Unity scenes or C# scripts. It does not yet contain production art, 3D assets, full campaign content, multiplayer, or release signing.

## Android APK from GitHub

The workflow `.github/workflows/godot-android-apk.yml` builds a debug APK using Godot and GitHub Actions. Godot is free/open-source; no Unity licence or Unity secrets are needed.

1. Open the repository's **Actions** tab.
2. Select **Godot Android APK**.
3. Run **Run workflow** only after explicit approval to build an APK. Source changes do not trigger APK builds.
4. Open the completed run and download the `apptya-kingdom-godot-apk` artifact.

The headless Godot source, runtime, gameplay, save recovery, legacy-save migration, troop training, research, five-outpost campaign, escalating enemy army battles, touch-control and mesh-budget checks passed in CI ([workflow run](https://github.com/pawanroyindia/Apptya-Kingdom/actions/runs/38851194005)). The saved-graphics startup regression also passed ([workflow run](https://github.com/pawanroyindia/Apptya-Kingdom/actions/runs/38851218827)). The APK workflow remains manual-only and has not been run. The first approved APK workflow run is still required to verify the export setup. The APK is for testing, not a Play Store release.

## Validation

Source validation runs through `.github/workflows/godot-source-check.yml` and does not export an APK. A successful source check is not a substitute for Android export, installation, or device testing.

## Open locally

Open this `GodotProject/` folder with Godot 4.5 or compatible Godot 4.x editor.
