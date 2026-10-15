# Android build and validation checklist

## Project setup
- Open the UnityProject folder with Unity 6.0.46f1 or a compatible Unity 6 editor.
- In Unity Hub, include Android Build Support, Android SDK & NDK Tools, and OpenJDK.
- Wait for Package Manager and script compilation to finish. Resolve all Console errors before continuing.
- Use **Apptya Kingdom → Setup Starter Scene** to create the starter scene.
- Run **Apptya Kingdom → Validate Project** and resolve reported errors; review warnings before gameplay testing.

## Android player settings
- Switch Build Profile / Build Settings to Android.
- Set a unique application identifier before publishing.
- Set portrait orientation for the current HUD prototype.
- Set minimum API level based on target devices; for Google Play submissions, verify the current target API policy at build time.
- Start with conservative URP shadows and render scale; profile on the actual target phone.

## Acceptance checks
- Scene opens without compile errors.
- Gather / harvest buttons update resource counts.
- Upgrade button spends resources and increases Keep level only when affordable.
- Train Guard spends food and gold only when affordable.
- Training guards visibly adds squad markers near the Barracks; battle losses and expeditions remove the corresponding markers.
- Scout action grants its reward once per button press.
- Save survives app restart.
- Primary save corruption falls back to the backup snapshot without duplicating offline rewards.
- Upgrade countdown continues while the app is closed; an upgrade that expires offline completes exactly once after reopening.
- Send the app to the background and resume it without killing the process; offline timers and capped resource production must reconcile once.
- Offline resource production is granted once per return and never exceeds the eight-hour cap.
- The HUD reports the actual offline resource amounts and does not repeat the same reward after another reload.
- One-finger drags pan the kingdom within map bounds; pinch zoom works without hijacking HUD gestures.
- Selected building details update level, upgrade cost, countdown and max-level state after gameplay changes.
- Two-finger gestures over HUD controls do not zoom the world camera.
- Tapping building walls, doors and rooftops selects the correct building; trees and decorative props do not intercept taps.
- Soft shadows and ambient lighting remain performant on the target phone; tree canopies do not cast shadows.
- No clipped UI on 720p and 1080p portrait displays, including camera cutouts/notches and system navigation areas (safe-area layout).
- Test frame rate, heat, battery, memory and load time on a physical Android device.

## Honest status
The repository source has not yet been compiled in Unity or built/tested on a physical Android device. Do not treat this checklist as evidence of a successful build.