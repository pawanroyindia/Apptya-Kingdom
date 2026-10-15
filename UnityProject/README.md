# Apptya Kingdom — Unity starter project

This folder contains a starter Unity 6 project structure, a URP package manifest, gameplay C# scripts, and an Editor utility that creates the starter scene.

## Create the starter scene
1. Open this folder in Unity Hub using Unity 6.0.46f1 or a compatible Unity 6 release.
2. Install Android Build Support, Android SDK & NDK Tools, and OpenJDK through Unity Hub if Android builds are needed.
3. Wait until packages finish resolving and scripts compile.
4. In the Unity menu, select **Apptya Kingdom → Setup Starter Scene**.
5. Press Play and inspect the Console.

## Current gameplay slice
- Procedural valley with river and bridge.
- Keep and four placeholder resource buildings.
- Gather wood, harvest food, train guards, upgrade the keep, and scout for rewards.
- Local save through PlayerPrefs.

## Important limitations
The environment and buildings are primitive blockout geometry, not final-quality 3D art. The project has not been compiled in Unity or tested on an Android device in this workflow. No APK has been built or verified. The generated scene and HUD require testing, UI refinement, and original art/animation work before release.

## Android release
Configure the application identifier, orientation, icon, signing, target API and graphics settings in Unity. Confirm Google's current Play policy and profile performance on actual target devices before publishing.
