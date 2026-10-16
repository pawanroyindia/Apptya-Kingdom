# Apptya Kingdom

Apptya Kingdom is a mobile-first fantasy kingdom strategy game prototype.

## Engine status

Two project folders are currently retained so the new engine can be tested before the old source is retired:

- `UnityProject/` — original Unity prototype. Its Android cloud build requires Unity licensing credentials, which are not configured.
- `GodotProject/` — new free/open-source Godot reimplementation of the current prototype mechanics, designed for Android APK builds through GitHub Actions without Unity credentials.

The Godot version is a **reimplementation, not an automatic conversion** of Unity scenes or C# code. It currently includes a touch-friendly kingdom UI, resource economy, tile building, keep upgrades, guard training, scouting, battles, timed production, and local save/offline progress. Production-quality art, deeper campaign content, multiplayer, release signing, and device validation remain future work.

## Build an Android test APK

A GitHub Actions workflow is defined at `.github/workflows/godot-android-apk.yml`.

1. Open the repository's **Actions** tab.
2. Select **Godot Android APK**.
3. Select **Run workflow** (or push a change under `GodotProject/`).
4. When the run finishes, download the `apptya-kingdom-godot-apk` artifact from that run.

The workflow uses Godot 4.5.1, Godot's Android export templates, and Android build tools. It does not need Unity licence secrets. **The first workflow run must still pass before an APK can be claimed as built.** A debug APK is for testing, not a Play Store-ready release.

## Verification status

The Godot project files and GitHub Actions workflow have been committed. The workflow's real build, APK integrity/signature checks, and physical-device gameplay tests are not yet verified. The original Unity project remains in the repository as a fallback until the Godot port is validated.
