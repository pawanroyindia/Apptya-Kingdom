# Apptya Kingdom — Godot port prototype

This is a new, licence-free Godot implementation of the current mobile kingdom-management prototype. The original `UnityProject/` is intentionally retained as a fallback until this port has been built and tested.

## Current implemented prototype

- Portrait, touch-friendly interface
- Gold, wood and food resource counters
- Procedural 3D valley scene with a river, bridge, paths, trees, buildings, outposts and visible guard markers
- Nine selectable kingdom tiles
- Farm, mine and barracks construction
- Timed Keep upgrades and levelled resource-building upgrades
- Guard training, scouting and raider battles
- Timed production and bounded offline production
- Local save/load on the device

This is a reimplementation of the prototype mechanics, not an automatic conversion of Unity scenes or C# scripts. It does not yet contain production art, 3D assets, full campaign content, multiplayer, or release signing.

## Android APK from GitHub

The workflow `.github/workflows/godot-android-apk.yml` builds a debug APK using Godot and GitHub Actions. Godot is free/open-source; no Unity licence or Unity secrets are needed.

1. Open the repository's **Actions** tab.
2. Select **Godot Android APK**.
3. Run **Run workflow** only after explicit approval to build an APK. Source changes do not trigger APK builds.
4. Open the completed run and download the `apptya-kingdom-godot-apk` artifact.

A separate headless Godot source-check workflow validates scripts without building an APK. The APK workflow remains manual-only until approval. The first approved APK workflow run is still required to verify the export setup. The APK is for testing, not a Play Store release.

## Validation

Source validation runs through `.github/workflows/godot-source-check.yml` and does not export an APK. A successful source check is not a substitute for Android export, installation, or device testing.

## Open locally

Open this `GodotProject/` folder with Godot 4.5 or compatible Godot 4.x editor.
