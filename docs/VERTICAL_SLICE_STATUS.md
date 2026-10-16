# Vertical Slice Implementation Status

This is a source-level status report. It is not evidence of a successful Unity compile or device test.

## Implemented in repository source
- Procedural 3D valley blockout with Keep, four resource/military buildings, river, bridge, roads, trees and enemy outpost.
- Warm directional lighting, soft shadows and tuned sky/equator/ground ambient colors in the procedural scene.
- Decorative prop colliders are removed while building interaction colliders are preserved; tree canopies do not cast shadows to reduce mobile rendering cost.
- Bounded ground-plane camera panning, pinch zoom and editor mouse controls; panning is constrained to the playable valley.
- Scrollable action HUD with resources, production, army stats, tutorial objective, battle report and achievements.
- Building status distinguishes active upgrade countdowns, idle buildings and maximum-level buildings.
- Local PlayerPrefs save/load for kingdom progression.
- Redundant PlayerPrefs backup snapshot with fallback loading if the primary save cannot be parsed.
- Resource gathering, building upgrades, guard training, scouting, exploration and enemy battle calculations.
- Three persistent research branches (Combat Drills, Efficient Production and Cartography), each capped at level 5; combat improves army power, economy improves active/offline passive production, and cartography improves both wood and stone exploration rewards. Save schema version 6 normalizes research levels and practice progress before offline calculations, and offline return summaries include the economy research bonus.
- A dedicated runtime Research Center overlay lists all three branches, current levels, next-level costs, prerequisites, locked/available state and branch effects; research actions refresh the overlay and HUD.\n- Research progression now has building prerequisites: each next research level requires the Keep to reach that level, and Combat Drills also requires the Barracks to reach that level. The source preflight checks these progression gates.
- Tap-to-inspect for Keep, Lumber Camp, Farmstead, Barracks, Quarry and enemy outpost.
- Multiple visible parts of each building (including roof sections and doors) share the same interaction target, while decorative colliders are removed.
- Gold-tint feedback across all separately tappable mesh parts of the selected building.
- Keep and village-building roof ridges turn gold while their timed upgrades are running.
- World-visible guard squad that updates when guards are trained or lost in battle/expeditions (up to 25 individual markers, matching barracks capacity).\n- Selectable valley Practice Target with persistent practice progression: each drill requires at least one troop, is capped at 20 drills, and adds +1 permanent army power without spending troops or resources.
- Three troop classes are tracked separately (infantry, archers and cavalry), with class-specific food/gold costs and different army-power values. Barracks has a single-slot timed training queue with a live countdown, capacity checks, save persistence and completion recovery after app suspension. The HUD offers separate queue actions and reports class counts/queue state; world squad markers are tinted by troop class and now have subtle procedural idle motion. Battle reports include the troop-class composition.
- Enemy outpost roof threat scaling is capped visually so high gameplay levels cannot create enormous meshes.
- Selected-building upgrade and resource collection actions; selected enemy outpost can be attacked through a dedicated action.
- Persistent contextual building details panel with level, upgrade costs, active countdowns, max-level state and enemy power; Barracks inspection also shows guard capacity/training costs, while resource buildings show passive output rates. Details refresh after game-state changes without overwriting action feedback.
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
- Procedural building materials select shaders according to the active render pipeline, avoiding unconditional use of URP/Lit when the project is running the built-in pipeline. The material factory now also tries a UI-compatible fallback and safely skips a material if no shader can be found, rather than constructing a Material with a potentially null shader.
- Passive-production timer resets on app pause/resume so a partially elapsed 30-second production interval cannot immediately pay out again after offline rewards are reconciled.

## Still needed before calling the vertical slice complete
- Compile and run in the pinned Unity editor; resolve any compiler/runtime issues.
- Compile and test timed upgrade completion, save/reload countdown continuity, and edge cases in Unity.
- Replace capsule blockout markers with authored class-specific troop models and attack/march animations; replace the capsule dummy with an authored target model and add authored class-specific attack/march animations. Current motion is a subtle procedural idle sway, not a full animation system.
- Add research-specific icon artwork and a more complete visual presentation to the Research Center; the functional overlay, costs, branch effects and prerequisite states are now implemented.
- Test bounded camera pan/zoom gestures against HUD interactions in Unity Play Mode and on Android.
- Improve authored art, animations, audio, lighting, terrain and mobile UI polish.
- Test save/reload, screen scaling, performance and heat on real Android devices.

## Release policy
Do not build an APK until the user explicitly authorizes it. Never describe source-only checks as Unity compilation, gameplay testing or device validation.
