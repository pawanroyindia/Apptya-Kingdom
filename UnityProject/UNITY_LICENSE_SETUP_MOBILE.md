# Mobile-friendly Unity license setup for cloud APK builds

The Android build workflow currently stops before Unity compilation because this repository has no Unity license secret configured. No APK has been produced.

## Step 1 — Generate the activation request

1. Open the repository on GitHub.
2. Open **Actions → Request Unity License File**.
3. Tap **Run workflow** if the workflow has not already run automatically.
4. Open the successful run and download the **Unity-Activation-Request** artifact ZIP.
5. Extract the file named `Unity_v6000.0.46f1.alf`.

## Step 2 — Get the Unity license file

1. Open Unity's official manual activation page: https://license.unity3d.com/manual
2. Upload the `.alf` activation request and follow the Unity website instructions.
3. Download the resulting Unity license file (`.ulf`).

The exact options available depend on the Unity account and license eligibility. Do not share the license file publicly.

## Step 3 — Add the secret from a phone

1. Open the GitHub repository and go to **Settings**.
2. Open **Secrets and variables → Actions**.
3. Tap **New repository secret**.
4. Name it exactly `UNITY_LICENSE`.
5. Open the downloaded `.ulf` file in a text editor, copy its complete contents, and paste those contents into the secret value. Save it.
6. Return to **Actions → Android APK Build** and run the workflow again.

If you use a Unity serial-based license instead, add the applicable `UNITY_SERIAL`, `UNITY_EMAIL`, and `UNITY_PASSWORD` secrets as required by GameCI. Never put license contents or account passwords in chat, issues, commits, or public files.

## What the build will produce

On a successful run, download the `apptya-kingdom-android-build` artifact. It should contain:
- `ApptyaKingdom.apk` — Android ARM64 debug APK, not Play Store release-signed.
- `android-build-report.txt` — Unity build result and output verification.

## Current verified status

- Source-preflight workflow: passed.
- Android APK build: attempted; blocked before Unity compilation because no license file or serial secret was available.
- APK artifact: not produced.
- Unity compilation, gameplay regression, APK contents inspection, and physical-device testing: not verified yet.
