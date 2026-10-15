# Vertical Slice Implementation Status

This is a source-level status report. It is not evidence of a successful Unity compile or device test.

## Implemented in repository source
- Procedural 3D valley blockout with Keep, four resource/military buildings, river, bridge, roads, trees and enemy outpost.
- Orbit-style camera, touch drag, pinch zoom and editor mouse controls.
- Scrollable action HUD with resources, production, army stats, tutorial objective, battle report and achievements.
- Local PlayerPrefs save/load for kingdom progression.
- Resource gathering, building upgrades, guard training, scouting, exploration and enemy battle calculations.
- Tap-to-inspect for Keep, Lumber Camp, Farmstead, Barracks, Quarry and enemy outpost.
- Gold-tint feedback for the selected building.
- World-visible guard squad that updates when guards are trained or lost in battle/expeditions (up to ten individual markers).
- Selected-building upgrade and resource collection actions; selected enemy outpost can be attacked through a dedicated action.
- Legacy save normalization for levels, troop count, day, progression counters and resource values.
- Timed Keep and village-building upgrades: costs are charged at start, levels increase on completion, HUD displays remaining seconds, and active timers are periodically persisted to PlayerPrefs.
- Upgrade timers that reach zero while the app is suspended are completed during save normalization on next load rather than silently cancelled.
- Upgrade countdowns account for elapsed wall-clock time between saves, so timers can progress while the app is closed; recovered state is saved immediately after loading.
- Passive resource production is granted for offline time, capped at eight hours per return, using saved building levels.
- Two-finger camera zoom checks whether either touch is over the HUD, preventing pinch gestures on UI controls from moving the world camera.

## Still needed before calling the vertical slice complete
- Compile and run in the pinned Unity editor; resolve any compiler/runtime issues.
- Replace the notice-line inspection with a proper contextual building panel.
- Compile and test timed upgrade completion, save/reload countdown continuity, and edge cases in Unity.
- Add troop training queue or squad presentation, and a visible practice/combat target in the world.
- Add bounded camera movement and test touch gestures against UI interactions.
- Improve authored art, animations, audio, lighting, terrain and mobile UI polish.
- Test save/reload, screen scaling, performance and heat on real Android devices.

## Release policy
Do not build an APK until the user explicitly authorizes it. Never describe source-only checks as Unity compilation, gameplay testing or device validation.
