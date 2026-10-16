# Apptya Kingdom

Apptya Kingdom is a mobile-first fantasy kingdom strategy game prototype.

## Engine status

Two project folders are currently retained so the new engine can be tested before the old source is retired:

- `UnityProject/` — original Unity prototype. Its Android cloud build requires Unity licensing credentials, which are not configured.
- `GodotProject/` — new free/open-source Godot reimplementation of the current prototype mechanics, designed for Android APK builds through GitHub Actions without Unity credentials.

The Godot version is a **reimplementation, not an automatic conversion** of Unity scenes or C# code. Current work includes a procedural 3D valley with a stone perimeter wall, four watchtowers, a southern gate, ten sequential enemy outposts, visible troop classes and a Royal Captain hero model; touch orbit/pinch zoom and graphics presets; a four-resource economy; timed upgrades and queued troop training; research, quest rewards, hero progression, battle effects, backup-save recovery and offline production. Authored production art, a deeper campaign, full troop animations, audio, multiplayer and physical-device validation remain future work.

## Build an Android test APK

A GitHub Actions workflow is defined at `.github/workflows/godot-android-apk.yml`.

1. Open the repository's **Actions** tab.
2. Select **Godot Android APK**.
3. Select **Run workflow** only after the user explicitly approves an APK build. Ordinary source changes run source validation only.
4. When the run finishes, download the `apptya-kingdom-godot-apk` artifact from that run.

The workflow uses Godot 4.5.1, Godot's Android export templates, and Android build tools. It does not need Unity licence secrets. **The first workflow run must still pass before an APK can be claimed as built.** A debug APK is for testing, not a Play Store-ready release.

See [`PROJECT_STATUS.md`](PROJECT_STATUS.md) for the detailed pre-APK checklist and current verification gates.

## Verification status

The Godot project files and GitHub Actions workflows have been committed. The latest headless Godot source, runtime, gameplay, save-recovery, campaign progression, hero/quest, graphics settings, and touch-control checks passed ([workflow run](https://github.com/pawanroyindia/Apptya-Kingdom/actions/runs/38852128706)). The APK workflow is manual-only and has not been run. APK export, installation, gameplay regression, and physical-device tests are not yet verified. The original Unity project remains in the repository as a fallback until the Godot port is validated.
