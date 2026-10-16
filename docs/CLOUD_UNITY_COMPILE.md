# Cloud Unity compile check (mobile-friendly)

This repository has a source-only Python preflight. The **Unity Editor Compile Check** workflow adds a real Unity Editor import/compile pass using the project's pinned Unity version, **6000.0.46f1**. It does not build an APK.

## One-time setup

Unity's Editor must be licensed in the GitHub Actions runner. From a browser on your phone:

1. Open the repository on GitHub.
2. Go to **Settings → Secrets and variables → Actions → New repository secret**.
3. Configure the Unity activation secrets required by the current GameCI licensing method:
   - `UNITY_LICENSE` — license file contents, stored as a secret.
   - `UNITY_EMAIL` — Unity account email, if required by the selected activation route.
   - `UNITY_PASSWORD` — Unity account password, only if required by the selected activation route.
4. Never put license contents or account credentials into a committed file or chat.

GameCI licensing options can change. Follow the current GameCI Unity activation instructions for your actual license type; do not assume that creating these secret names alone activates Unity. If you do not have a usable Unity license activation method, the Editor compile step cannot run yet.

## Run it from a phone

1. Open **Actions → Unity Editor Compile Check**.
2. Tap **Run workflow** and select `main`.
3. Open the new run and inspect the **Import and compile in Unity Editor** job.
4. If it fails, open the failed step logs and locate the first relevant error. C# compiler errors usually look like `CS####`. Fix the underlying error before retrying.

The workflow also runs automatically when files under `UnityProject/` change on `main` or in a pull request.

## What the result means

- A successful run means Unity opened the project and the Editor test-runner process completed for that revision; the game's scripts were imported and compiled as part of that process.
- A failed run can be caused by licensing, package resolution, runner limits, or actual C# compilation errors. Read the first relevant error in the logs.
- The included smoke test only verifies that the EditMode test runner starts. It does not validate game mechanics.
- This is not a Play Mode, Android-device, performance, or release test.
- This workflow does not produce an APK or any installable game artifact.
