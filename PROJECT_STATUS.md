# Apptya Kingdom — Work Checklist

This checklist tracks development before the first APK export. **Do not run the APK workflow until the pre-export checklist is reviewed and approved.**

## Engine and build path
- [x] Keep the original Unity project in the repository as a fallback.
- [x] Add a Godot 4.5 project that does not require Unity licensing credentials.
- [x] Configure a manual-only Android APK workflow; ordinary source changes must not export an APK.
- [x] Configure a separate headless source/runtime/gameplay validation workflow.

## Gameplay and mobile controls
- [x] Mobile portrait UI and scrollable control layout.
- [x] Gold, wood, and food economy with active and capped offline production.
- [x] Farm, mine, Lumber Camp, Quarry, Barracks and Keep construction/collection/upgrades.
- [x] Queued infantry, archer and cavalry training; scouting, exploration, five enemy outposts, battle outcomes, rewards and achievements.
- [x] Four-step tutorial, combat/economy/scouting research, troop practice and three claimable campaign rewards.
- [x] Local save/load, backup recovery, save-data normalization, timed upgrade restoration, and periodic autosave.
- [x] Procedural 3D valley, castle, buildings, river/bridge, hills, boulders, lanterns, five enemy outposts, and distinct infantry/archer/cavalry silhouettes.
- [x] Touch camera orbit, two-finger pinch zoom, and tile selection.
- [x] Visible construction/outpost reveal effects, water ripples, exploration scout journey and marching guard squad during attacks.

## Verification
- [x] Headless Godot editor parsing, project startup, economy, training, research, exploration, save recovery and touch tests passed ([run details](https://github.com/pawanroyindia/Apptya-Kingdom/actions/runs/38848450743)).
- [x] The central 3D tile-picking test has passed in a prior workflow run.
- [x] Re-run the expanded gameplay/save/touch/troop/research test suite after the latest changes and fix every failure ([successful run](https://github.com/pawanroyindia/Apptya-Kingdom/actions/runs/38848450743)).
- [ ] Review Android export preset and workflow configuration before first export.
- [ ] Review performance and visual layout for low-end Android devices as far as CI can check without a device.
- [ ] Physical-device installation, touch testing, and performance validation are post-export gates and cannot be claimed before an APK exists.

## Known scope limits before export
- The world uses procedural low-poly meshes and a custom SVG app icon, not final production art assets.
- Campaign depth is currently limited to five outposts and the implemented prototype economy; there is no multiplayer or audio system.
- A successful headless check does not prove Android export, APK installation, or device compatibility.
- The APK workflow has not been run and no APK has been generated. Keep it that way until all pre-export work and checks are reviewed.
