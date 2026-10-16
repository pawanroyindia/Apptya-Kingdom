# Apptya Kingdom asset provenance and production notes

## Runtime models and materials
- Royal Captain and guard: Quaternius RPG Character Pack models from the pinned CC0 asset snapshot in Hakhyun-Kim/constellation-defense at commit 8ad1c93e382e2a6a5755882c1b9b2922877fab6e; the source UVs, skeletal rigs and animation clips are retained.
- Watchtower: Quaternius Medieval Village MegaKit gate-tower model. Keep and Barracks are assembled from the kit's textured wall/roof modules; source PBR textures are resized to 512px for mobile.
- The Blender asset pipeline also generates original UV-mapped PBR materials and articulated character variants in `source_models/`. The runtime hero/guard/tower remain the external CC0-authored meshes, so this is not represented as bespoke AAA sculpting or motion-capture animation.

## Runtime audio
- The runtime kingdom theme is an original, procedurally composed 36-second stereo score rendered by `tools/asset_pipeline/generate_audio.py`; it uses synthesized layered pads, plucked strings, a lead line, bass pulse and percussion. It is original generated audio, not a commissioned orchestral recording.
- Runtime gather/build/train/victory/defeat/scout effects combine original generated layers with selected Kenney RPG Audio / Impact Sounds samples under CC0 1.0 Universal. Source OGG files are retained in `source_sfx/`.
- The CC0 track "Once Upon a Time (loop)" by TAD is retained under `source_music/` as an optional source/reference asset and is **not** the runtime score.

## Sources and licenses
- https://quaternius.com/packs/rpgcharacters.html
- https://quaternius.com/packs/medievalvillagemegakit.html
- https://kenney.nl/assets/rpg-audio
- https://kenney.nl/assets/impact-sounds
- https://opengameart.org/content/once-upon-a-time-loop
