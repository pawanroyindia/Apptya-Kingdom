# Apptya Kingdom — Godot port prototype

This is a new, licence-free Godot implementation of the current mobile kingdom-management prototype. The original `UnityProject/` is intentionally retained as a fallback until this port has been built and tested.

## Current implemented prototype

- Portrait, touch-friendly interface
- Gold, wood, food and stone resource counters with direct gathering actions
- Procedural 3D valley with a river, bridge, roads, stone perimeter wall, four watchtowers, a southern gate, trees, a castle keep, farms, mines, barracks, ten enemy outposts, visible guard markers, and a gold-armored Royal Captain hero model with a level label
- Dynamic day/night lighting cycle that changes the sky, ambient light and sun warmth; Low graphics mode keeps reduced lighting and disables shadows
- Touch drag to orbit the camera and two-finger pinch to zoom
- Nine selectable kingdom tiles
- Farm, mine, Lumber Camp, Quarry, Academy and barracks construction; Academy levels discount research costs up to 25%
- Timed Keep and resource-building upgrades, with timers restored after app suspension
- Queued infantry, archer and cavalry training with Barracks capacity limits
- Combat, economy and scouting research; troop practice; region exploration; claimable campaign rewards and a persistent quest board
- Royal Captain hero with XP/levels, skill upgrades, battle/exploration progression, and an army-power bonus
- Scouting and targeted outpost battles with troop losses, rewards and visible battle/exploration animations; outposts unlock in campaign order and the HUD shows campaign progress through completion
- Timed production and bounded eight-hour offline production with research bonuses
- Periodic autosave, backup recovery, save-data normalization and persisted upgrade/training timers
- Procedural WAV sound effects for gathering, upgrades, training and battle outcomes, with a persistent mute toggle
- A looping procedural ambient music bed with its own on/off control and saved preference
- Short finite ambient animations for tree sway and guard idle motion, building reveal/upgrade feedback, hero level-up feedback, marching/exploration squads and battle impact rings
- LAN co-op for one host and one guest on the same Wi-Fi: host-authoritative resource/build/training/research/scouting/attack/claim actions, shared kingdom snapshots and validation of client requests
- Seven-day daily reward streak, resource payouts, day-seven bonus, duplicate-claim protection, live reset countdown and saved progress
- Upgradeable single Academy with timed upgrades, research discounts up to 25%, and save-data duplicate cleanup
- Sequential outpost scouting/attack unlocks; scouting a region repeatedly cannot generate duplicate rewards
- Persistent Low / Balanced / High graphics presets and camera reset
- Local save/load on the device, including graphics preferences; save recovery enforces a unique Keep and Barracks troop capacity

This is a reimplementation of the prototype mechanics, not an automatic conversion of Unity scenes or C# scripts. It uses procedural low-poly models, not final production art, and synthesized prototype audio rather than an authored soundtrack. LAN co-op is source-implemented but not yet verified between physical phones; it is limited to one host and one guest on the same Wi-Fi network, uses UDP port 24567, and does not provide public-internet matchmaking or dedicated servers.

## LAN co-op quick start

1. Put both phones on the same Wi-Fi network.
2. On the host phone, tap **Host LAN Game**.
3. Find the host phone's local IPv4 address in Android Wi-Fi network details and enter it on the guest phone.
4. Tap **Join Host IP**. The host is authoritative for shared resource, building, training, research, scouting, battle and claim actions.
5. If connection fails, check Wi-Fi client isolation and whether UDP port `24567` is allowed. The feature is LAN-only; mobile data or different networks will not work without additional networking infrastructure.

The LAN co-op code has automated snapshot/action validation, but live two-phone connectivity and reconnect behavior still need device testing.

## Android APK from GitHub

The workflow `.github/workflows/godot-android-apk.yml` builds a debug APK using Godot and GitHub Actions. Godot is free/open-source; no Unity licence or Unity secrets are needed.

1. Open the repository's **Actions** tab.
2. Select **Godot Android APK**.
3. Run **Run workflow** only after explicit approval to build an APK. Source changes do not trigger APK builds.
4. Open the completed run and download the `apptya-kingdom-godot-apk` artifact.

The latest headless Godot integration run passed ([workflow run](https://github.com/pawanroyindia/Apptya-Kingdom/actions/runs/38855710165)), including project parsing/startup, gameplay and save recovery, touch controls, quest and hero progression, generated sound effects and looping ambient music, audio preference persistence and pause/resume behavior, daily rewards, Academy timed upgrades and duplicate-save recovery, sequential campaign scouting/attack gates, duplicate-scout prevention, LAN snapshot/action validation, ENet host/disconnect lifecycle, and the procedural-world mesh budget/stable-refresh checks. The APK workflow remains manual-only and has not been run. The first approved APK workflow run is still required to verify the export setup. The APK is for testing, not a Play Store release.

## Validation

Source validation runs through `.github/workflows/godot-source-check.yml` and does not export an APK. A successful source check is not a substitute for Android export, installation, or device testing.

## Open locally

Open this `GodotProject/` folder with Godot 4.5 or compatible Godot 4.x editor.
