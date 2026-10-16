extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var models := {
		"royal_captain": "res://assets/production/royal_captain.glb",
		"kingdom_guard": "res://assets/production/kingdom_guard.glb",
		"keep": "res://assets/production/keep.glb",
		"barracks": "res://assets/production/barracks.glb",
		"watchtower": "res://assets/production/watchtower.glb"
	}
	for model_name in models:
		var path: String = models[model_name]
		if not ResourceLoader.exists(path):
			_fail("Missing generated model: " + path)
			return
		var packed := load(path) as PackedScene
		if packed == null:
			_fail("Generated GLB did not import as a PackedScene: " + path)
			return
		var instance := packed.instantiate()
		root.add_child(instance)
		if model_name in ["royal_captain", "kingdom_guard"]:
			var players := instance.find_children("*", "AnimationPlayer", true, false)
			if players.is_empty():
				_fail("Rigged character has no AnimationPlayer: " + model_name)
				return
			var player := players[0] as AnimationPlayer
			var skeletons := instance.find_children("*", "Skeleton3D", true, false)
			if skeletons.is_empty():
				_fail("Rigged character has no Skeleton3D: " + model_name)
				return
			var skeleton := skeletons[0] as Skeleton3D
			if skeleton.get_bone_count() < 8:
				_fail("Character skeleton has too few bones for articulated motion: " + model_name)
				return
			var required_clips := {
				"Idle": ["idle", "stand", "breath"],
				"Walk": ["walk", "run", "jog", "move"],
				"Attack": ["attack", "slash", "combat", "sword", "hit"]
			}
			for clip in required_clips:
				var found := false
				for clip_name in player.get_animation_list():
					var normalized := clip_name.to_lower()
					for alias in required_clips[clip]:
						if normalized.contains(alias):
							var animation := player.get_animation(clip_name)
							if animation != null and animation.track_count > 0 and animation.length >= 0.25:
								found = true
				if not found:
					_fail("Character GLB is missing a usable " + clip + " motion clip: " + model_name)
					return
		instance.queue_free()
	for texture_name in ["gold", "steel", "cloth", "red", "skin", "leather", "stone", "wood", "roof", "linen"]:
		for map_name in ["albedo", "normal", "roughness"]:
			var texture_path := "res://assets/production/textures/%s_%s.png" % [texture_name, map_name]
			if not ResourceLoader.exists(texture_path) or load(texture_path) == null:
				_fail("Missing imported PBR texture map: " + texture_path)
				return
	for sound_name in ["kingdom_theme", "gather", "build", "train", "victory", "defeat", "scout"]:
		var audio_path := "res://assets/production/audio/%s.wav" % sound_name
		if not ResourceLoader.exists(audio_path):
			_fail("Missing rendered audio file: " + audio_path)
			return
		var audio := load(audio_path) as AudioStreamWAV
		if audio == null or audio.data.is_empty() or audio.mix_rate < 11025:
			_fail("Rendered audio failed to import: " + audio_path)
			return
	print("APPTYA_PRODUCTION_ASSET_TESTS_PASSED")
	quit(0)

func _fail(message: String) -> void:
	push_error("APPTYA_PRODUCTION_ASSET_TEST_FAILED: " + message)
	quit(1)
