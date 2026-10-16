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
- [x] Farm, mine, Lumber Camp, Quarry, Academy, Barracks and Keep construction/collection/upgrades; Academy levels discount research costs.
- [x] Queued infantry, archer and cavalry training; scouting, exploration, ten enemy outposts, battle outcomes, rewards and achievements.
- [x] Tactical campaign combat: troop composition, enemy doctrines, scouting intelligence, probability-based outcomes, bounded casualty calculations, and rewards; enemy army formations adapt across Shield Wall, Bow Line and Cavalry Wing encounters.
- [x] Four-step tutorial, combat/economy/scouting research, troop practice, three claimable campaign rewards and a persistent three-objective quest board.
- [x] Royal Captain hero progression: XP from battle/scouting/exploration, level cap 20, skill upgrades to level 5, army-power bonus, save/load persistence, and a distinct gold-armored 3D model with a live level label.
- [x] Local save/load, backup recovery, save-data normalization, timed upgrade restoration, and periodic autosave.
- [x] Procedural 3D valley, castle, buildings, stone perimeter wall with four watchtowers and a southern gate, river/bridge, hills, boulders, lanterns, ten enemy outposts, and distinct infantry/archer/cavalry silhouettes.
- [x] Dynamic four-minute day/night lighting cycle with changing sky, ambient light, sun warmth and energy; integrated with the Low graphics preset.
- [x] Touch camera orbit, two-finger pinch zoom, tile selection, and camera reset.
- [x] Persistent Low / Balanced / High 3D render-quality presets; Low disables shadows and lowers 3D render scale for weaker phones.
- [x] Procedurally generated WAV sound effects for gathering, building upgrades, troop training, and battle wins/losses, with a persistent on/off control.
- [x] A 16-second looping procedural ambient soundtrack with an independent music toggle and persisted preference (prototype audio, not a professionally authored soundtrack).
- [x] Daily reward system with real-world daily reset, a seven-day streak, resource rewards, a seventh-day bonus, duplicate-claim protection, visible reset countdown, and save/load persistence.
- [x] Sequential campaign progression: each outpost unlocks only after the previous outpost is captured; locked attacks do not consume troops, and the HUD reports progress through the final campaign-complete state.
- [x] Distinct procedural outpost structures for fortified, archer and cavalry enemy doctrines; visual silhouettes align with the combat rules.
- [x] Save normalization removes duplicate Keeps/Academies, enforces Barracks and queued-training capacity, clamps resources/hero/reward values, validates timed-operation targets, and repairs impossible sequential campaign progress.
- [x] Visible construction/outpost reveal effects, finite tree-sway and staggered guard-idle animations, water ripples, exploration scout journey, marching guard squad, and expanding battle impact rings.
- [x] Improved procedural model details: Keep windows, farmhouse doors, Barracks facade, Academy stained glass, troop helmets/shields, and Royal Captain level-up feedback.
- [x] Added LAN-only co-op for one host and one guest: host/join by local IP, validated host-authoritative gameplay actions, shared kingdom snapshots, and client-side prevention of independent production/timer completion. Same Wi-Fi and UDP port 24567 are required; no internet matchmaking or remote server is part of the scope.
- [x] Academy can be upgraded through the normal timed building system; duplicate Academies are rejected and sanitized from malformed saves.
- [x] Sequential campaign gates now apply to scouting as well as attacks; repeated scouting cannot farm rewards or consume guards.

## Verification
- [ ] Confirm a successful source-check workflow after the latest tactical combat, enemy doctrine visuals, LAN snapshot validation, and save-normalization changes. Do not treat these newest changes as validated until that run passes.
- [x] Headless Godot editor parsing, project startup, economy, training, research, exploration, save recovery and touch tests passed ([run details](https://github.com/pawanroyindia/Apptya-Kingdom/actions/runs/38848762730)).
- [x] The central 3D tile-picking test has passed in a prior workflow run.
- [x] Re-run the expanded gameplay/save/touch/troop/research/quest/hero test suite after the campaign and save-normalization changes ([successful run](https://github.com/pawanroyindia/Apptya-Kingdom/actions/runs/38852128706)).
- [x] Validate generated sound streams, mute/unmute UI behavior, and sound-preference save/load ([successful run](https://github.com/pawanroyindia/Apptya-Kingdom/actions/runs/38853048014)).
- [x] Validate daily reward streak progression, exact resource payout, same-day claim blocking, countdown/claimed UI, and save recovery ([successful run](https://github.com/pawanroyindia/Apptya-Kingdom/actions/runs/38853165597)).
- [x] Verify Academy construction, 3D model parsing, tile inspection, and level-2 research discount ([successful run](https://github.com/pawanroyindia/Apptya-Kingdom/actions/runs/38853359637)).
- [x] Verify Academy level-5 research discount cap at 25% ([successful run](https://github.com/pawanroyindia/Apptya-Kingdom/actions/runs/38853406776)).
- [x] Verify Academy construction, 3D model structure, tile inspection, level-2 discount, and the level-5 25% discount cap ([successful integration run](https://github.com/pawanroyindia/Apptya-Kingdom/actions/runs/38853475729)).
- [x] Verify Academy timed upgrade costs/completion, duplicate-Academy prevention/save normalization, locked-outpost scouting, and duplicate-scout reward prevention ([latest successful Godot source check](https://github.com/pawanroyindia/Apptya-Kingdom/actions/runs/38854283305)).
- [x] Recheck hero level-up feedback, 3D hero model/label synchronization, and the updated test suite ([successful run](https://github.com/pawanroyindia/Apptya-Kingdom/actions/runs/38851624870)).
- [x] Verify a saved Low-quality preset is applied when the scene starts, including render scale and shadow state ([successful run](https://github.com/pawanroyindia/Apptya-Kingdom/actions/runs/38851624870)).
- [x] Statically review Android export preset and workflow configuration; the action inputs, preset output path, Android SDK, Java 17, APK integrity/signature checks, and Android INTERNET permission for LAN co-op are configured. CI asserts the networking permission remains enabled. Actual export remains untested until approved.
- [x] Add a CI mesh-node budget and refresh-stability check: 256 mesh nodes at startup, with no mesh growth after repeated UI refreshes, below the 400-node guardrail; physical-device FPS remains unverified.
- [ ] Physical-device installation, touch testing, and performance validation are post-export gates and cannot be claimed before an APK exists.

## Remaining non-blocking prototype scope
- The world still uses procedural low-poly meshes and a custom SVG app icon, not final production art assets. Sound effects and ambient music are synthesized prototypes, not authored production audio.
- LAN co-op is intentionally local-network-only. Live two-phone networking has not been verified; reconnect/session recovery and robust handling of router isolation remain outstanding. Authored music/audio, production art/animation, and physical Android device profiling remain outstanding.
- Campaign depth currently includes ten sequential outposts, tactical enemy doctrines, composition-aware battles and escalating enemy-army encounters. More campaign chapters, authored soundtrack, and production-quality sound design are still future work. Internet matchmaking is intentionally out of scope.
- A successful headless check does not prove Android export, APK installation, LAN connectivity between physical phones, or device compatibility.
- The APK workflow has not been run and no APK has been generated. This is intentional. Do not run the manual APK workflow unless the user explicitly asks after reviewing this checklist.
