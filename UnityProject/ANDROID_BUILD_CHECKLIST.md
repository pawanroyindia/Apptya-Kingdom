# Android build and validation checklist

## Project setup
- Open the UnityProject folder with Unity 6.0.46f1 or a compatible Unity 6 editor.
- In Unity Hub, include Android Build Support, Android SDK & NDK Tools, and OpenJDK.
- Wait for Package Manager and script compilation to finish. Resolve all Console errors before continuing.
- Use Apptya Kingdom → Setup Starter Scene to create the starter scene.

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
- Upgrade countdown continues while the app is closed; an upgrade that expires offline completes exactly once after reopening.
- Offline resource production is granted once per return and never exceeds the eight-hour cap.
- Two-finger gestures over HUD controls do not zoom the world camera.
- No clipped UI on 720p and 1080p portrait displays.
- Test frame rate, heat, battery, memory and load time on a physical Android device.

## Honest status
The repository source has not yet been compiled in Unity or built/tested on a physical Android device. Do not treat this checklist as evidence of a successful build.