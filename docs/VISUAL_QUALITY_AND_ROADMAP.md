# Apptya Kingdom — Visual Quality & Production Plan

## Non-negotiable quality bar
Apptya Kingdom must not ship as a generic HTML game or a static mock-up. The target is a polished mobile kingdom strategy game with a strong visual identity, readable touch UI, responsive performance, and meaningful gameplay feedback.

## Recommended production direction
- **Engine:** Unity with URP for a practical Android-first 3D pipeline. Unreal Engine remains an option if the project later prioritizes high-end visuals over mobile build complexity.
- **Target device:** Android phones; design for touch-first interaction and scalable layouts.
- **Art direction:** Original fantasy-medieval kingdom; warm stone, deep forest greens, royal gold accents, atmospheric skies, readable silhouettes, and detailed but performance-aware environments.
- **Originality:** Kingshot may inform the genre and feature expectations, but Apptya Kingdom must use its own art, UI, characters, maps, and branding.

## Graphics acceptance criteria
1. A 3D kingdom scene with a readable castle focal point, terrain height, roads, trees, rocks, and distant scenery.
2. Consistent lighting, real-time or baked shadows as appropriate, ambient occlusion where supported, and restrained atmospheric effects.
3. Animated building and troop feedback; upgrades must visibly change the world.
4. Scalable quality settings so lower-end Android devices remain playable.
5. No placeholder assets presented as finished art. Every temporary asset must be clearly labelled as a prototype.

## UI acceptance criteria
1. A clear hierarchy for resources, player status, missions, construction, research, and army controls.
2. Custom-designed panels, icons, typography, button states, loading feedback, and transition motion.
3. Touch targets sized for phones, safe-area awareness, and layouts tested in portrait and landscape where relevant.
4. Consistent visual language across kingdom, building details, troop training, battle, and settings screens.
5. No clipped text, overlapping controls, or unreadable contrast at common phone sizes.

## Build milestones
1. **Visual target:** approve a mood board and UI direction before production content is locked.
2. **Vertical slice:** one polished kingdom scene, one upgradeable building, resource collection, and one troop interaction.
3. **Gameplay systems:** progression, economy, combat loop, save/load, and tutorial.
4. **Optimization:** frame-time profiling, memory budgets, device testing, and UI scale validation.
5. **Android release build:** reproducible signed/unsigned build pipeline, versioning, and APK validation on-device.

## Build honesty
A repository commit or successful CI job is not proof that the game is visually complete or device-tested. Do not call a build release-ready until the APK exists, its build result is verified, and the app has been tested on Android hardware.

## Current status
This document records the quality bar and intended production direction. It is not a claim that the 3D game or APK has already been built.
