# Unity license requirement for cloud APK builds

The Android APK workflow is configured, but GitHub Actions currently stops before Unity compilation because no Unity license secret or serial is configured.

## What is required

GameCI's current activation documentation requires an already activated Unity license for cloud builds. The legacy request-activation action was attempted and returned: **“This action is no longer supported.”** It has been removed rather than leaving a workflow that cannot work.

For the Android build workflow, add the secrets that match your license type:

### Unity Personal
- `UNITY_LICENSE` — contents of a valid Unity `.ulf` license file
- `UNITY_EMAIL` — Unity account email
- `UNITY_PASSWORD` — Unity account password

Current GameCI documentation says manual activation of Personal licenses is no longer supported in the general flow. The `.ulf` file normally comes from activating Unity Hub on a computer. If you have access to a computer with Unity Hub, activate your Personal license there and retrieve the license file. Do not put license contents or credentials in chat, issues, commits, or public files.

### Unity Pro/Plus
- `UNITY_SERIAL` — valid subscription serial
- `UNITY_EMAIL` — Unity account email
- `UNITY_PASSWORD` — Unity account password

## Add secrets using GitHub on mobile

1. Open https://github.com/pawanroyindia/Apptya-Kingdom
2. Open **Settings → Secrets and variables → Actions**.
3. Tap **New repository secret**.
4. Add each required secret using the exact name above and save it.
5. Open **Actions → Android APK Build** and run the workflow again.

Do not paste a password, serial, or license into a repository file.

## Build configuration and output

- Unity Editor: 6000.0.46f1
- Android APK (not AAB)
- Application ID: `com.apptya.kingdom`
- Portrait orientation; ARM64; Android API 36
- Expected artifact: `apptya-kingdom-android-build`
- Expected files: `ApptyaKingdom.apk` and `android-build-report.txt`

The intended APK is a debug build, not release-signed. It must be inspected and tested before distribution.

## Verified status (2026-10-16)

- Source-preflight workflow: **PASS**.
- Android build workflow: **FAILED before Unity compilation** because license secrets are empty.
- APK: **NOT PRODUCED**.
- Unity C# compilation, gameplay regression tests, APK inspection, and physical-device testing: **NOT VERIFIED**.

Reference: [GameCI activation documentation](https://game.ci/docs/github/activation/).
