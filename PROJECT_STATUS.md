# Apptya Kingdom — Work Checklist

This checklist tracks development before the first APK export. **Do not run the APK workflow until the pre-export checklist is reviewed and approved.**

## Engine and build path
- [x] Keep the original Unity project in the repository as a fallback.
- [x] Add a Godot 4.5 project that does not require Unity licensing credentials.
- [x] Configure a manual-only Android APK workflow; ordinary source changes must not export an APK.
- [x] Configure a separate headless source/runtime/gameplay validation workflow.

## Gameplay and mobile controls
- [x] Mobile portrait UI and scrollable control layout.
- [x] Gold, wood, food and stone economy with direct gathering, active and capped offline production.
- [x] Farm, mine, Lumber Camp, Quarry, Barracks and Keep construction/collection/upgrades.
- [x] Queued infantry, archer and cavalry training; scouting, exploration, five enemy outposts, battle outcomes, rewards and achievements.
- [x] Four-step tutorial, combat/economy/scouting research, troop practice and three claimable campaign rewards.
- [x] Local save/load, backup recovery, save-data normalization, timed upgrade restoration, and periodic autosave.
- [x] Procedural 3D valley, castle, buildings, river/bridge, hills, boulders, lanterns, five enemy outposts, and distinct infantry/archer/cavalry silhouettes.
- [x] Touch camera orbit, two-finger pinch zoom, tile selection, and camera reset.
- [x] Persistent Low / Balanced / High 3D render-quality presets; Low disables shadows and lowers 3D render scale for weaker phones.
- [x] Sequential campaign progression: each outpost unlocks only after the previous outpost is captured; locked attacks do not consume troops.
- [x] Save normalization removes duplicate Keeps and enforces Barracks troop capacity, including queued-training capacity.
- [x] Visible construction/outpost reveal effects, water ripples, exploration scout journey and marching guard squad during attacks.

## Verification
- [x] Headless Godot editor parsing, project startup, economy, training, research, exploration, save recovery and touch tests passed ([run details](https://github.com/pawanroyindia/Apptya-Kingdom/actions/runs/38848762730)).
- [x] The central 3D tile-picking test has passed in a prior workflow run.
- [x] Re-run the expanded gameplay/save/touch/troop/research test suite after the campaign and save-normalization changes ([successful run](https://github.com/pawanroyindia/Apptya-Kingdom/actions/runs/38851194005)).
- [ ] Confirm the newest regression that loads a saved Low-quality preset applies at startup ([run pending](https://github.com/pawanroyindia/Apptya-Kingdom/actions/runs/38851218827)).
- [x] Statically review Android export preset and workflow configuration; the action inputs, preset output path, Android SDK, Java 17, APK integrity and signature checks align. Actual export remains untested until approved.
- [x] Add a CI mesh-node budget and refresh-stability check: 193 mesh nodes at startup, below the 400-node guardrail; physical-device FPS remains unverified.
- [ ] Physical-device installation, touch testing, and performance validation are post-export gates and cannot be claimed before an APK exists.

## Remaining non-blocking prototype scope
- The world uses procedural low-poly meshes and a custom SVG app icon, not final production art assets.
- Campaign depth is currently limited to five outposts, escalating enemy army encounters and the implemented prototype economy; there is no multiplayer or audio system.
- A successful headless check does not prove Android export, APK installation, or device compatibility.
- The APK workflow has not been run and no APK has been generated. This is intentional. Do not run the manual APK workflow unless the user explicitly asks after reviewing this checklist.
