# Apptya Kingdom — Vertical Slice Specification

## Goal
Build the first playable, visually representative slice before expanding the game. This specification is the implementation target, not a claim that the game is already built.

## Camera and world
- 3D isometric/three-quarter camera with smooth pan, pinch zoom, and bounded camera movement.
- A compact valley map with a central royal castle, outer wall, a river/bridge, farms, lumber yard, stone quarry, barracks, and academy.
- Layered terrain, hand-authored points of interest, and distant mountains to create depth without overloading mobile GPUs.
- Clear interaction highlights when a building is selected.

## First interactive loop
1. Tap a resource building to collect a small amount of its resource.
2. Select the castle and inspect its level, prerequisites, and upgrade cost.
3. Start an upgrade only when resources are sufficient; show progress and completion feedback.
4. Open barracks and train a small troop squad.
5. Send troops to a nearby practice target and display a readable combat result.
6. Save progression locally and restore it on relaunch.

## Main UI surfaces
- Top strip: player level, food, wood, stone, gold, premium currency.
- Left navigation: Build, Research, Troops, Heroes.
- Context panel: selected building name, level, actions, cost, duration, upgrade requirements.
- Bottom navigation: Quests, Alliance, Mail, Inventory.
- Event and campaign entry points must not obstruct the central world.
- All buttons need pressed, disabled, loading, success, and error states where applicable.

## Visual language
- Deep navy and charcoal panels, restrained royal-gold borders, cream text, clear green positive-action indicators.
- Distinct silhouettes for buildings and troops; no reliance on tiny decorative details to communicate function.
- UI icon family must be consistent in stroke weight and rendering style.
- Use subtle motion for selection, progress, resource collection, and panel transitions; avoid gratuitous screen shake or excessive particle effects.

## Mobile performance budgets
- Target stable 30 FPS on baseline supported Android hardware; aim for 60 FPS on capable devices.
- Provide Low / Balanced / High quality settings.
- Use LODs, occlusion culling, texture compression, pooled effects, and capped particle counts.
- Profile on real Android devices before claiming performance is acceptable.
- Keep UI legible at common phone resolutions and display scaling settings.

## Test checklist
- [ ] Camera controls work with one and two fingers.
- [ ] Every tap target is reachable and visually responds.
- [ ] Resource amounts never become negative.
- [ ] Upgrade prerequisites and timers behave correctly.
- [ ] Training consumes the correct resources and produces units.
- [ ] Save/load survives app restart.
- [ ] UI does not overlap or clip on narrow screens.
- [ ] APK installs and launches on a real Android device.
- [ ] Visual performance is checked on at least one lower-end Android phone.

## Technical note
The preferred implementation path is Unity + URP for a mobile-first 3D slice. The repository now contains a Unity 6 project, procedural kingdom blockout, gameplay state, runtime HUD, camera controls, and source preflight checks. It remains an uncompiled/unverified vertical-slice source project: production art, Unity compile/Play Mode verification, and Android device validation are still required. Do not build an APK until the user explicitly authorizes it.
