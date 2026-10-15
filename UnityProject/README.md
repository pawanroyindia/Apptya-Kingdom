# Apptya Kingdom — Unity starter

This is an initial C# starter slice, not a complete Unity project export or tested APK.

## Setup
1. Install a supported Unity 6 editor through Unity Hub with Android Build Support, SDK/NDK tools and OpenJDK.
2. Create a new 3D URP project.
3. Copy `Assets/Scripts` from this folder into that project's `Assets/Scripts`.
4. Create a scene and an empty GameObject called `Apptya Kingdom Bootstrap`; attach `ProceduralKingdomBootstrap.cs`.
5. Press Play to generate a rough 3D blockout, game state and runtime touch HUD.
6. Resolve any editor-version warnings/errors and test on a physical Android device before calling it built.

## Limitations
Procedural primitive geometry is temporary blockout, not production art. This repository does not yet contain Unity-generated project settings, a URP asset, authored 3D art, signing keys or a verified build. The HUD is functional scaffolding and requires a visual polish pass.