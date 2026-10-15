# Vertical Slice Implementation Status

This is a source-level status report. It is not evidence of a successful Unity compile or device test.

## Implemented in repository source
- Procedural 3D valley blockout with Keep, four resource/military buildings, river, bridge, roads, trees and enemy outpost.
- Warm directional lighting, soft shadows and tuned sky/equator/ground ambient colors in the procedural scene.
- Decorative prop colliders are removed while building interaction colliders are preserved; tree canopies do not cast shadows to reduce mobile rendering cost.
- Orbit-style camera, touch drag, pinch zoom and editor mouse controls.
- Scrollable action HUD with resources, production, army stats, tutorial objective, battle report and achievements.
- Building status distinguishes active upgrade countdowns, idle buildings and maximum-level buildings.
- Local PlayerPrefs save/load for kingdom progression.
- Redundant PlayerPrefs backup snapshot with fallback loading if the primary save cannot be parsed.
- Resource gathering, building upgrades, guard training, scouting, exploration and enemy battle calculations.
- Tap-to-inspect for Keep, Lumber Camp, Farmstead, Barracks, Quarry and enemy outpost.
- Multiple visible parts of each building (including roof sections and doors) share the same interaction target, while decorative colliders are removed.
- Gold-tint feedback for the selected building.
- Keep and village-building roof ridges turn gold while their timed upgrades are running.
- World-visible guard squad that updates when guards are trained or lost in battle/expeditions (up to ten individual markers).
- Selected-building upgrade and resource collection actions; selected enemy outpost can be attacked through a dedicated action.
- Legacy save normalization for levels, troop count, day, progression counters and resource values.
- Timed Keep and village-building upgrades: costs are charged at start, levels increase on completion, HUD displays remaining seconds, and active timers are periodically persisted to PlayerPrefs.
- Upgrade timers that reach zero while the app is suspended are completed during save normalization on next load rather than silently cancelled.
- Upgrade countdowns account for elapsed wall-clock time between saves, so timers can progress while the app is closed; recovered state is saved immediately after loading.
- App background/resume also reconciles elapsed time, then immediately saves the recovered state to avoid duplicate offline rewards.
- Passive resource production is granted for offline time, capped at eight hours per return, using saved building levels.
- The HUD reports the exact offline wood, food, stone and gold granted on return.
- The return summary also lists any Keep or village-building upgrades completed while away.
- Two-finger camera zoom checks whether either touch is over the HUD, preventing pinch gestures on UI controls from moving the world camera.
- Editor menu preflight checks required scripts, starter-scene presence, Build Settings inclusion and player orientation, and reports render-pipeline configuration warnings.
- HUD panels and the battle report overlay use device safe-area insets and recalculate when screen size or insets change, helping avoid Android cutouts and system navigation bars.
- Top and bottom HUD panels use edge-aligned RectTransform pivots so their fixed heights extend into the safe area rather than clipping beyond its top or bottom.
- Editor preflight also checks that the starter-scene setup script exists.
- Procedural building materials select shaders according to the active render pipeline, avoiding unconditional use of URP/Lit when the project is running the built-in pipeline.
- Passive-production timer resets on app pause/resume so a partially elapsed 30-second production interval cannot immediately pay out again after offline rewards are reconciled.

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
