# Apptya Kingdom — Unity starter project

This folder contains a starter Unity 6 project structure, a URP package manifest, gameplay C# scripts, and an Editor utility that creates the starter scene.

## Create the starter scene
1. Open this folder in Unity Hub using Unity 6.0.46f1 or a compatible Unity 6 release.
2. Install Android Build Support, Android SDK & NDK Tools, and OpenJDK through Unity Hub if Android builds are needed.
3. Wait until packages finish resolving and scripts compile.
4. In the Unity menu, select **Apptya Kingdom → Setup Starter Scene**.
5. Select **Apptya Kingdom → Validate Project** to run the source/scene preflight and review warnings.
6. Press Play and inspect the Console.

## Current gameplay slice
- Procedural valley with river, bridge, roads, village decoration and enemy outpost.
- Keep and four resource/military buildings with visual level markers.
- World-visible guard squad markers that respond to training and combat losses.
- Warm soft-shadow lighting with tree-canopy shadow cost reduced for mobile.
- Gather, passive production, timed upgrades, guard training, scouting, exploration, battles and achievements.
- Selected-building inspection, upgrade/collect actions, and dedicated enemy targeting.
- Taps on building walls, doors, roof sections and castle pieces map back to the same building; decorative colliders are removed.
- PlayerPrefs persistence, upgrade timer recovery across app suspension, and capped eight-hour offline resource production. Backup snapshot recovery is included for unreadable primary save data.
- Touch drag/orbit and pinch zoom, with HUD gestures protected from camera input.
- Scrollable mobile HUD with resource, army, production, tutorial and battle information.

## Important limitations
The environment and buildings are primitive blockout geometry, not final-quality 3D art. The project has not been compiled in Unity or tested on an Android device in this workflow. No APK has been built or verified. The generated scene and HUD require testing, UI refinement, and original art/animation work before release.

## Android release
Configure the application identifier, orientation, icon, signing, target API and graphics settings in Unity. Confirm Google's current Play policy and profile performance on actual target devices before publishing.
