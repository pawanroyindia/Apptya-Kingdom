# Apptya Kingdom — Research and Technical Plan
Updated 2026-10-16

## Research findings
- The official Kingshot page describes a mobile strategy/simulation loop: grow a town center, provide food and shelter, train soldiers, fight beasts, repel invasions, gather resources and compete. The Play listing adds worker roles and laws. These are genre references, not assets or content to copy. Apptya Kingdom needs original characters, models, names, art, sound, UI and level design.
  - https://www.centurygames.com/games/kingshot/
  - https://play.google.com/store/apps/details?id=com.run.tower.defense
- Unity is the chosen engine for the intended 3D Android game. Unity Android requirements cover Android Build Support, SDK, NDK and JDK; use Unity Hub's compatible modules.
  - https://docs.unity.com/en-us/engine/6000.0/manual/platform-specific/android/introducing/requirements-and-compatibility
  - https://docs.unity.com/en-us/engine/6000.6/manual/platform-specific/android/getting-started/sdksetup
- Use Unity 6 + URP, but profile real devices. Unity recommends tuning shadow distance/quality, additional lights, render scale, post-processing and draw calls based on measured bottlenecks.
  - https://docs.unity.com/en-us/engine/6000.0/manual/analysis/graphics-performance-profiling/in-urp
  - https://docs.unity.com/en-us/engine/6000.0/manual/analysis/graphics-performance-profiling/in-urp/optimize-for-better-performance
  - https://docs.unity.com/en-us/engine/6000.0/manual/analysis/graphics-performance-profiling/reduce-draw-calls
- Google Play policy says starting Aug 31, 2026 new apps and updates generally must target Android 16 / API 36. A debug APK is not a store-ready release.
  - https://support.google.com/googleplay/android-developer/answer/11926878?hl=en-EN

## Direction
- Android-first, original fantasy frontier strategy game.
- Engine: Unity 6, Universal Render Pipeline; pin exact editor and package versions when a real project is created.
- Visual target: elevated three-quarter camera, detailed stone-and-timber keep, lush valley, river/bridge, farms, lumber camp, quarry, barracks, readable royal-navy/gold HUD, touch-first controls.
- Performance target: stable 30 FPS on a defined mid-range Android device first; 60 FPS on capable devices only after profiling. These are targets, not measured claims.
- First local-save vertical slice: gather resources, upgrade building, train guard, scout encounter, collect rewards and persist progress.

## Milestones and acceptance gates
1. **Foundation:** scene opens with no compile errors; Android build launches.
2. **Gameplay slice:** resource economy, building actions, guard training/scouting and save/load all work on-device.
3. **Art pass:** replace primitives with original/appropriately licensed meshes, textures, foliage, animation, VFX and sound; record asset provenance.
4. **Optimization:** measure CPU/GPU/memory and frame time on physical Android hardware; tune URP, LOD, instancing and texture compression.
5. **Delivery:** reproducible build, install smoke test, signing and Play policy review; only then claim an APK is ready.

## Truthful current status
The existing `prototype/index.html` is a basic 2D browser prototype. The new `UnityProject/Assets/Scripts` files are a starter implementation, not a complete Unity project or tested APK. Procedural primitive meshes are blockout scaffolding, not final graphics. No compile, physical-device test, multiplayer, signed release or production art is claimed.
