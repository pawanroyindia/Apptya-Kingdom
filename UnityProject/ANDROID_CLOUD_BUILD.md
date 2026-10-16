# Android APK build workflow

A cloud Android APK workflow is available in GitHub Actions: **Android APK Build**.

## Required repository secrets

The workflow uses Unity GameCI licensing. Configure these repository Actions secrets before a build:
- `UNITY_LICENSE`
- `UNITY_EMAIL`
- `UNITY_PASSWORD`
- `UNITY_SERIAL` (alternative activation method if no license file is available)

The workflow cannot create a valid Unity build if the required Unity license credentials are missing or invalid.

## Build configuration

- Unity Editor: 6000.0.46f1
- Artifact type: Android APK (not AAB)
- Application ID: com.apptya.kingdom
- Orientation: Portrait
- Architecture: ARM64
- Target SDK: Android API 36
- Build output: `UnityProject/Build/Android/ApptyaKingdom.apk`
- Build report: `UnityProject/Build/android-build-report.txt`

The editor build entry point creates the starter scene if it is absent and preserves other Build Settings scene entries. The APK is a development/debug build and is **not release-signed**. It must not be treated as Play Store-ready.

## Verification boundaries

A successful source-preflight workflow only validates repository structure; it is not a Unity compile or APK build. A successful Android build still requires inspection of the actual APK and gameplay tests. Physical-device testing remains separate.
