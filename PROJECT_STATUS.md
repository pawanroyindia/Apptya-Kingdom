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
- [x] Queued infantry, archer and cavalry training; scouting, exploration, ten enemy outposts, battle outcomes, rewards and achievements.
- [x] Four-step tutorial, combat/economy/scouting research, troop practice, three claimable campaign rewards and a persistent three-objective quest board.
- [x] Royal Captain hero progression: XP from battle/scouting/exploration, level cap 20, skill upgrades to level 5, army-power bonus, save/load persistence, and a distinct gold-armored 3D model with a live level label.
- [x] Local save/load, backup recovery, save-data normalization, timed upgrade restoration, and periodic autosave.
- [x] Procedural 3D valley, castle, buildings, stone perimeter wall with four watchtowers and a southern gate, river/bridge, hills, boulders, lanterns, ten enemy outposts, and distinct infantry/archer/cavalry silhouettes.
- [x] Touch camera orbit, two-finger pinch zoom, tile selection, and camera reset.
- [x] Persistent Low / Balanced / High 3D render-quality presets; Low disables shadows and lowers 3D render scale for weaker phones.
- [x] Procedurally generated WAV sound effects for gathering, building upgrades, troop training, and battle wins/losses, with a persistent on/off control.
- [x] Daily reward system with real-world daily reset, a seven-day streak, resource rewards, a seventh-day bonus, duplicate-claim protection, visible reset countdown, and save/load persistence.
- [x] Sequential campaign progression: each outpost unlocks only after the previous outpost is captured; locked attacks do not consume troops, and the HUD reports progress through the final campaign-complete state.
- [x] Save normalization removes duplicate Keeps and enforces Barracks troop capacity, including queued-training capacity.
- [x] Visible construction/outpost reveal effects, water ripples, exploration scout journey and marching guard squad during attacks.

## Verification
- [x] Headless Godot editor parsing, project startup, economy, training, research, exploration, save recovery and touch tests passed ([run details](https://github.com/pawanroyindia/Apptya-Kingdom/actions/runs/38848762730)).
- [x] The central 3D tile-picking test has passed in a prior workflow run.
- [x] Re-run the expanded gameplay/save/touch/troop/research/quest/hero test suite after the campaign and save-normalization changes ([successful run](https://github.com/pawanroyindia/Apptya-Kingdom/actions/runs/38852128706)).
- [x] Validate generated sound streams, mute/unmute UI behavior, and sound-preference save/load ([successful run](https://github.com/pawanroyindia/Apptya-Kingdom/actions/runs/38853048014)).
- [x] Validate daily reward streak progression, exact resource payout, same-day claim blocking, countdown/claimed UI, and save recovery ([latest successful run](https://github.com/pawanroyindia/Apptya-Kingdom/actions/runs/38853165597)).
- [x] Recheck hero level-up feedback, 3D hero model/label synchronization, and the updated test suite ([successful run](https://github.com/pawanroyindia/Apptya-Kingdom/actions/runs/38851624870)).
- [x] Verify a saved Low-quality preset is applied when the scene starts, including render scale and shadow state ([successful run](https://github.com/pawanroyindia/Apptya-Kingdom/actions/runs/38851624870)).
- [x] Statically review Android export preset and workflow configuration; the action inputs, preset output path, Android SDK, Java 17, APK integrity and signature checks align. Actual export remains untested until approved.
- [x] Add a CI mesh-node budget and refresh-stability check: 256 mesh nodes at startup, with no mesh growth after repeated UI refreshes, below the 400-node guardrail; physical-device FPS remains unverified.
- [ ] Physical-device installation, touch testing, and performance validation are post-export gates and cannot be claimed before an APK exists.

## Remaining non-blocking prototype scope
- The world uses procedural low-poly meshes and a custom SVG app icon, not final production art assets. Sound effects are synthesized prototypes, not authored production audio.
- The project remains a single-player prototype; multiplayer, authored music/audio, production art/animation, and physical Android device profiling are not implemented/verified.
- Campaign depth is currently limited to ten outposts, escalating enemy army encounters and the implemented prototype economy; there is no multiplayer or audio system.
- A successful headless check does not prove Android export, APK installation, or device compatibility.
- The APK workflow has not been run and no APK has been generated. This is intentional. Do not run the manual APK workflow unless the user explicitly asks after reviewing this checklist.
