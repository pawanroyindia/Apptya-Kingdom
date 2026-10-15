# Apptya Kingdom

An original mobile-first fantasy kingdom strategy prototype.

## What is implemented in the current prototype
- Fantasy-themed, responsive kingdom screen
- Gather wood and food
- Upgrade the Royal Keep using resources
- Train guards and send a scouting expedition
- Local save using browser/device storage
- Android debug APK workflow using GitHub Actions

## Build an Android debug APK
This is an early 2D web prototype packaged with Capacitor. It is not yet the planned high-quality 3D game.

1. Open the repository's **Actions** tab.
2. Select **Build Apptya Kingdom APK**.
3. Tap **Run workflow**, then confirm.
4. Wait for the workflow to finish. Open the completed run.
5. Under **Artifacts**, download `apptya-kingdom-debug-apk`.
6. Extract the downloaded ZIP and install the APK on an Android device. Android may ask you to allow installation from that source.

If the run fails, open the run and inspect the failed step; do not assume an APK was produced.

## Project direction
The intended next milestones are a proper 3D Unity vertical slice, original environment/building assets, polished HUD, troop animations, gameplay progression, performance testing, and a signed release build. Those are not implemented yet.

## Current limitations
No successful APK build or on-device test has been verified yet. The current prototype does not contain a real 3D world, multiplayer, or production-grade art assets.