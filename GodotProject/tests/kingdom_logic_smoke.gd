extends SceneTree

func _initialize() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	_remove_save("user://apptya_kingdom_save.cfg")
	_remove_save("user://apptya_kingdom_save_backup.cfg")
	var initial_settings := ConfigFile.new()
	initial_settings.set_value("kingdom", "graphics_quality", "Low")
	initial_settings.set_value("kingdom", "saved_at", int(Time.get_unix_time_from_system()))
	if initial_settings.save("user://apptya_kingdom_save.cfg") != OK:
		_fail("Could not create the saved graphics preset startup fixture.")
		return
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	await physics_frame
	await physics_frame
	if game.graphics_quality != "Low" or not is_equal_approx(game.world_viewport.scaling_3d_scale, 0.75) or game.world_view.sun_light.shadow_enabled:
		_fail("Saved graphics quality was not applied when the kingdom scene started.")
		return
	var daytime_background: Color = game.world_view.world_environment.background_color
	game.world_view.day_phase = 0.75
	game.world_view._update_daylight()
	if is_equal_approx(game.world_view.world_environment.background_color.r, daytime_background.r) or game.world_view.sun_light.light_energy >= 0.5:
		_fail("Night lighting did not darken the sky and reduce sun energy.")
		return
	game.world_view.day_phase = 0.25
	game.world_view._update_daylight()
	if not is_equal_approx(game.world_view.world_environment.background_color.r, daytime_background.r):
		_fail("Day lighting did not restore the daytime sky color.")
		return
	if not is_instance_valid(game.world_view.hero_model) or not game.world_view.hero_level_label.text.contains("LV 1"):
		_fail("The 3D Royal Captain model or level label was not created.")
		return
	if not game.world_view.hero_rig_data.has("left_leg") or not game.world_view.hero_rig_data.has("right_leg") or not game.world_view.hero_rig_data.has("left_arm") or not game.world_view.hero_rig_data.has("right_arm"):
		_fail("The Royal Captain articulated limb rig was not initialized.")
		return
	if not game.world_view.hero_rig_data.has("head") or not game.world_view.hero_rig_data.has("left_leg_y") or not game.world_view.hero_rig_data.has("right_leg_y"):
		_fail("The Royal Captain rig is missing head articulation or stable foot-lift baselines.")
		return
	var anticipation: float = game.world_view._combat_swing_curve(0.08)
	var strike: float = game.world_view._combat_swing_curve(0.24)
	var recovery: float = game.world_view._combat_swing_curve(0.48)
	if not (anticipation < 0.0 and strike < anticipation and absf(recovery) < 0.001):
		_fail("Combat animation must sequence anticipation, a stronger strike, and a clean recovery.")
		return
	for rig in game.world_view.articulated_rigs:
		if not rig.has("left_leg") or not rig.has("right_leg") or not rig.has("left_arm") or not rig.has("right_arm"):
			_fail("A visible troop is missing articulated limb joints.")
			return
	if game.sound_streams.size() != 5 or game.sound_streams["victory"].data.is_empty() or game.sound_player.bus != "Master":
		_fail("Procedural sound effect streams or the audio player were not initialized.")
		return
	game.sound_enabled = true
	game._toggle_sound()
	if game.sound_enabled or game.settings_buttons[2].text != "Sound: OFF":
		_fail("Sound toggle did not mute effects or update its button.")
		return
	game._toggle_sound()
	if not game.sound_enabled or game.settings_buttons[2].text != "Sound: ON":
		_fail("Sound toggle did not re-enable effects or update its button.")
		return
	if game.music_stream.data.is_empty() or game.music_stream.loop_mode != AudioStreamWAV.LOOP_FORWARD or game.music_stream.loop_end != game.music_stream.data.size() / 2 or game.music_stream.mix_rate != 11025 or game.music_stream.data.size() != 11025 * 32 * 2:
		_fail("Original 32-second ambient score did not initialize as a valid looping WAV stream.")
		return
	var effect_lengths: Dictionary = {}
	for effect_name in game.sound_streams:
		var effect_stream: AudioStreamWAV = game.sound_streams[effect_name]
		if effect_stream.data.is_empty():
			_fail("The %s sound effect has no audio samples." % effect_name)
			return
		effect_lengths[effect_stream.data.size()] = true
	if effect_lengths.size() < 4:
		_fail("Gather/build/victory/defeat/train effects are not differentiated by duration.")
		return
	game._toggle_music()
	if game.music_enabled or game.music_settings_buttons[0].text != "Music: OFF" or game.music_player.playing:
		_fail("Music toggle did not stop playback or update its button.")
		return
	game._toggle_music()
	if not game.music_enabled or game.music_settings_buttons[0].text != "Music: ON" or not game.music_player.playing:
		_fail("Music toggle did not resume playback or update its button.")
		return
	game._notification(Control.NOTIFICATION_APPLICATION_PAUSED)
	if game.music_player.playing:
		_fail("Ambient music continued playing after the app was paused.")
		return
	game._notification(Control.NOTIFICATION_APPLICATION_RESUMED)
	if not game.music_player.playing:
		_fail("Ambient music did not resume when the app returned to the foreground.")
		return

	var initial_yaw: float = game.world_view.camera_yaw
	var drag_event := InputEventScreenDrag.new()
	drag_event.relative = Vector2(12, 0)
	game.world_view._input(drag_event)
	if is_equal_approx(initial_yaw, game.world_view.camera_yaw):
		_fail("Touch orbit control did not rotate the camera.")
		return
	var initial_distance: float = game.world_view.camera_distance
	var pinch_event := InputEventMagnifyGesture.new()
	pinch_event.factor = 1.2
	game.world_view._input(pinch_event)
	if game.world_view.camera_distance >= initial_distance:
		_fail("Pinch zoom control did not zoom the camera.")
		return
	game.world_view.active_touches = {0: Vector2(100, 100), 1: Vector2(200, 100)}
	game.world_view.touch_moved = {0: false, 1: false}
	game.world_view.previous_pinch_distance = 100.0
	var before_two_finger_zoom: float = game.world_view.camera_distance
	var two_finger_drag := InputEventScreenDrag.new()
	two_finger_drag.index = 1
	two_finger_drag.position = Vector2(220, 100)
	two_finger_drag.relative = Vector2(20, 0)
	game.world_view._input(two_finger_drag)
	if game.world_view.camera_distance >= before_two_finger_zoom:
		_fail("Two-finger touch pinch did not zoom the 3D camera.")
		return
	game.graphics_quality = "Balanced"
	game._apply_graphics_quality()
	game._cycle_graphics_quality()
	if game.graphics_quality != "High" or !is_equal_approx(game.world_viewport.scaling_3d_scale, 1.25) or not game.world_view.sun_light.shadow_enabled:
		_fail("High graphics preset did not enable the expected render quality.")
		return
	game._cycle_graphics_quality()
	if game.graphics_quality != "Low" or !is_equal_approx(game.world_viewport.scaling_3d_scale, 0.75) or game.world_view.sun_light.shadow_enabled:
		_fail("Low graphics preset did not reduce resolution and disable shadows.")
		return
	game._cycle_graphics_quality()
	if game.graphics_quality != "Balanced" or !is_equal_approx(game.world_viewport.scaling_3d_scale, 1.0) or not game.world_view.sun_light.shadow_enabled:
		_fail("Balanced graphics preset did not restore its render settings.")
		return
	game.world_view.reset_camera()
	if not is_equal_approx(game.world_view.camera_distance, 24.0) or not is_equal_approx(game.world_view.camera_yaw, 0.0):
		_fail("Reset Camera did not restore the default camera view.")
		return
	game.world_view.active_touches.clear()
	game.world_view.touch_moved.clear()
	game.world_view.previous_pinch_distance = 0.0
	game._select_tile(0)
	var world_view_size: Vector2 = game.world_view.get_viewport().get_visible_rect().size
	var picked_tile: int = game.world_view._pick_tile(world_view_size * 0.5)
	print("APPTYA_TILE_PICK_RESULT=", picked_tile, " SELECTED=", game.selected_tile, " VIEWPORT=", world_view_size)
	if picked_tile != 4 or game.selected_tile != 4:
		_fail("Tapping the 3D world did not select the central Keep tile.")
		return
	game._select_tile(0)

	if game.gold != 300 or game.tiles.size() != 9:
		_fail("Initial kingdom state is incorrect.")
		return
	var coop_snapshot: Dictionary = game._export_multiplayer_snapshot()
	if not game.network_session._valid_snapshot(coop_snapshot):
		_fail("The LAN co-op snapshot did not pass its own schema validation.")
		return
	var invalid_day_snapshot := coop_snapshot.duplicate(true)
	invalid_day_snapshot["day"] = -1
	if game.network_session._valid_snapshot(invalid_day_snapshot):
		_fail("LAN co-op accepted a snapshot with an invalid campaign day.")
		return
	var invalid_timer_snapshot := coop_snapshot.duplicate(true)
	invalid_timer_snapshot["building_upgrade_finish_unix"] = int(Time.get_unix_time_from_system()) + 3600
	if game.network_session._valid_snapshot(invalid_timer_snapshot):
		_fail("LAN co-op accepted a far-future building timer.")
		return
	var invalid_flags_snapshot := coop_snapshot.duplicate(true)
	invalid_flags_snapshot["quest_builder_claimed"] = "yes"
	if game.network_session._valid_snapshot(invalid_flags_snapshot):
		_fail("LAN co-op accepted a non-boolean quest claim flag.")
		return
	if not game.network_session._is_allowed_action("gather", {"resource": "gold", "amount": 20, "tile": 4, "outpost": 0}) or game.network_session._is_allowed_action("gather", {"resource": "gold", "amount": 999, "tile": 4, "outpost": 0}) or game.network_session._is_allowed_action("execute_script", {"tile": 4, "outpost": 0}):
		_fail("LAN co-op accepted an invalid or unsupported client action.")
		return
	if not game.network_session._is_allowed_action("claim_reward", {"reward_id": "first_victory", "tile": 4, "outpost": 0}) or game.network_session._is_allowed_action("claim_reward", {"reward_id": "admin", "tile": 4, "outpost": 0}) or not game.network_session._is_allowed_action("claim_quest", {"quest_id": "stronghold", "tile": 4, "outpost": 0}):
		_fail("LAN co-op did not enforce the campaign reward/quest action allowlist.")
		return
	var altered_snapshot := coop_snapshot.duplicate(true)
	altered_snapshot["gold"] = 311
	game._apply_multiplayer_snapshot(altered_snapshot)
	if game.gold != 311:
		_fail("Applying the host snapshot did not update the shared kingdom state.")
		return
	game.gold = 300
	game._refresh_ui()
	game._persist_game()
	var invalid_stance_snapshot := coop_snapshot.duplicate(true)
	invalid_stance_snapshot["battle_stance"] = "GodMode"
	if game.network_session._valid_snapshot(invalid_stance_snapshot):
		_fail("LAN co-op accepted an invalid tactical battle stance.")
		return
	var malformed_snapshot := coop_snapshot.duplicate(true)
	malformed_snapshot["tiles"] = ["Keep"]
	if game.network_session._valid_snapshot(malformed_snapshot):
		_fail("LAN co-op accepted a malformed kingdom snapshot.")
		return
	var duplicate_keep_snapshot := coop_snapshot.duplicate(true)
	duplicate_keep_snapshot["tiles"][0] = "Keep"
	if game.network_session._valid_snapshot(duplicate_keep_snapshot):
		_fail("LAN co-op accepted a snapshot with duplicate Keeps.")
		return
	var invalid_level_snapshot := coop_snapshot.duplicate(true)
	invalid_level_snapshot["tile_levels"][0] = 6
	if game.network_session._valid_snapshot(invalid_level_snapshot):
		_fail("LAN co-op accepted a building level outside the supported range.")
		return
	var mismatched_army_snapshot := coop_snapshot.duplicate(true)
	mismatched_army_snapshot["guards"] = 999
	if game.network_session._valid_snapshot(mismatched_army_snapshot):
		_fail("LAN co-op accepted troop totals that do not match the army roster.")
		return
	var impossible_campaign_snapshot := coop_snapshot.duplicate(true)
	impossible_campaign_snapshot["outpost_defeated"][2] = 1
	if game.network_session._valid_snapshot(impossible_campaign_snapshot):
		_fail("LAN co-op accepted a captured outpost behind locked campaign gates.")
		return
	var off_center_keep_snapshot := coop_snapshot.duplicate(true)
	off_center_keep_snapshot["tiles"][0] = "Keep"
	off_center_keep_snapshot["tiles"][4] = "Farm"
	if game.network_session._valid_snapshot(off_center_keep_snapshot):
		_fail("LAN co-op accepted a Keep outside the required centre tile.")
		return
	var oversized_army_snapshot := coop_snapshot.duplicate(true)
	oversized_army_snapshot["infantry"] = 100001
	oversized_army_snapshot["guards"] = 100001
	if game.network_session._valid_snapshot(oversized_army_snapshot):
		_fail("LAN co-op accepted troop counts beyond the save-data safety limit.")
		return
	var invalid_queue_snapshot := coop_snapshot.duplicate(true)
	invalid_queue_snapshot["queued_troop_type"] = "infantry"
	invalid_queue_snapshot["queued_troop_count"] = 6
	if game.network_session._valid_snapshot(invalid_queue_snapshot):
		_fail("LAN co-op accepted a troop queue larger than the supported maximum.")
		return
	var invalid_research_snapshot := coop_snapshot.duplicate(true)
	invalid_research_snapshot["combat_research"] = 6
	if game.network_session._valid_snapshot(invalid_research_snapshot):
		_fail("LAN co-op accepted a research level beyond the supported maximum.")
		return
	var host_start_result: int = game.network_session.host_game()
	if host_start_result != OK or not game.network_session.is_network_active() or not game.multiplayer.is_server():
		_fail("LAN co-op host could not start its ENet server.")
		return
	game.network_session.disconnect_game()
	if game.network_session.is_network_active():
		_fail("LAN co-op disconnect did not return to offline mode.")
		return
	if game.outpost_threat.size() != 10 or game.world_view.current_outposts.size() != 10:
		_fail("Ten-outpost campaign map was not initialized.")
		return
	game.outpost_defeated[0] = 1
	game.region_scouted[1] = 1
	game._refresh_ui()
	if game.world_view.current_outposts[0] != 1 or game.world_view.current_scouted[1] != 1:
		_fail("Ten-outpost campaign state did not synchronize to the 3D world.")
		return
	game.outpost_defeated[0] = 0
	game.region_scouted[1] = 0
	game._refresh_ui()
	var initial_mesh_count: int = game.world_view.find_children("*", "MeshInstance3D", true, false).size()
	print("APPTYA_WORLD_MESH_COUNT=%d" % initial_mesh_count)
	if initial_mesh_count > 400:
		_fail("Procedural world exceeded the mobile mesh-node budget.")
		return
	game._select_outpost(4)
	if game.selected_outpost != 4 or game.world_view.selected_outpost != 4:
		_fail("Fifth outpost could not be selected in the campaign UI/world.")
		return
	game._select_outpost(0)
	await create_timer(0.1).timeout
	var stable_mesh_count: int = game.world_view.find_children("*", "MeshInstance3D", true, false).size()
	for refresh_index in range(3):
		game._refresh_ui()
	await create_timer(0.1).timeout
	var refreshed_mesh_count: int = game.world_view.find_children("*", "MeshInstance3D", true, false).size()
	if refreshed_mesh_count > stable_mesh_count + 10:
		_fail("Repeated UI refreshes caused procedural world node growth.")
		return
	if refreshed_mesh_count != stable_mesh_count:
		_fail("Repeated UI refreshes changed the stable 3D mesh count.")
		return
	var wood_before_gather: int = game.wood
	game._gather_resource("wood", 25)
	if game.wood != wood_before_gather + 25:
		_fail("Direct resource gathering did not award the requested wood.")
		return

	game._select_tile(0)
	game._build_farm()
	if game.tiles[0] != "Farm" or game.tutorial_step != 1 or not game.achievements.has("farm"):
		_fail("Farm construction, tutorial, or first-farm achievement failed.")
		return

	game._select_tile(2)
	game._build_mine()
	if game.tiles[2] != "Mine" or game.tutorial_step != 2 or not game.achievements.has("mine"):
		_fail("Mine construction, tutorial, or first-mine achievement failed.")
		return

	var training_gold_before_initial: int = game.gold
	var training_food_before_initial: int = game.food
	game._train_guard()
	if game.queued_troop_count != 1 or game.queued_troop_type != "infantry" or game.guards != 4:
		_fail("Infantry training did not enter the queue or incorrectly changed guard count.")
		return
	if game.gold != training_gold_before_initial - 10 or game.food != training_food_before_initial - 25:
		_fail("Infantry training did not charge the correct resources.")
		return
	game.troop_training_finish_unix = int(Time.get_unix_time_from_system()) - 1
	game._finish_troop_training()
	if game.guards != 5 or game.tutorial_step != 3 or game.infantry != 5:
		_fail("Queued infantry completion or tutorial progression failed.")
		return

	# Resource collection must award the correct resource for the selected building.
	game._select_tile(0)
	var food_before_collection: int = game.food
	game._collect_selected_building()
	if game.food <= food_before_collection:
		_fail("Farm collection did not increase food.")
		return

	# A building cannot be placed on an occupied tile, and failed actions must not charge resources.
	var gold_before_invalid_build: int = game.gold
	var wood_before_invalid_build: int = game.wood
	game._build_mine()
	if game.tiles[0] != "Farm" or game.gold != gold_before_invalid_build or game.wood != wood_before_invalid_build:
		_fail("Building on an occupied tile changed the kingdom state.")
		return

	# Barracks construction and guard training resource costs must be applied exactly.
	game._select_tile(5)
	var barracks_gold_before: int = game.gold
	var barracks_wood_before: int = game.wood
	game._build_barracks()
	if game.tiles[5] != "Barracks" or game.gold != barracks_gold_before - 80 or game.wood != barracks_wood_before - 30:
		_fail("Barracks construction or resource costs failed.")
		return
	game._select_tile(0)
	var original_level: int = game.tile_levels[0]
	game._upgrade_selected_building()
	if game.building_upgrade_tile != 0 or game.building_upgrade_finish_unix <= int(Time.get_unix_time_from_system()):
		_fail("Building upgrade timer did not start.")
		return
	game.building_upgrade_finish_unix = int(Time.get_unix_time_from_system()) - 1
	game._finish_building_upgrade()
	if game.tile_levels[0] != original_level + 1 or not game.achievements.has("building_upgrade"):
		_fail("Building upgrade completion or achievement failed.")
		return
	var builder_gold_before: int = game.gold
	var builder_wood_before: int = game.wood
	game._claim_quest("builder")
	if not game.quest_builder_claimed or game.gold != builder_gold_before + 75 or game.wood != builder_wood_before + 50:
		_fail("Builder's Mark quest did not unlock or grant its exact reward.")
		return
	var claimed_builder_gold: int = game.gold
	game._claim_quest("builder")
	if game.gold != claimed_builder_gold:
		_fail("Builder's Mark quest reward could be claimed more than once.")
		return

	var original_keep_level: int = game.keep_level
	game._upgrade_keep()
	if game.keep_upgrade_finish_unix <= int(Time.get_unix_time_from_system()):
		_fail("Keep upgrade timer did not start.")
		return
	game.keep_upgrade_finish_unix = int(Time.get_unix_time_from_system()) - 1
	game._finish_keep_upgrade()
	if game.keep_level != original_keep_level + 1 or not game.achievements.has("keep_upgrade"):
		_fail("Keep upgrade completion or achievement failed.")
		return

	# Barracks upgrades increase capacity enough to train ranged and mounted troops.
	game._select_tile(7)
	game._upgrade_selected_building()
	if game.building_upgrade_tile != 7 or game.building_upgrade_finish_unix <= int(Time.get_unix_time_from_system()):
		_fail("Barracks upgrade did not start.")
		return
	game.building_upgrade_finish_unix = int(Time.get_unix_time_from_system()) - 1
	game._finish_building_upgrade()
	game._queue_archers()
	if game.queued_troop_type != "archer" or game.queued_troop_count != 1:
		_fail("Archer training did not enter the queue.")
		return
	game.troop_training_finish_unix = int(Time.get_unix_time_from_system()) - 1
	game._finish_troop_training()
	game._queue_cavalry()
	if game.queued_troop_type != "cavalry" or game.queued_troop_count != 1:
		_fail("Cavalry training did not enter the queue.")
		return
	game.troop_training_finish_unix = int(Time.get_unix_time_from_system()) - 1
	game._finish_troop_training()
	if game.archers != 1 or game.cavalry != 1 or game.guards != 7:
		_fail("Archer/cavalry training completion did not update troop composition.")
		return
	if game.world_view.current_infantry != game.infantry or game.world_view.current_archers != game.archers or game.world_view.current_cavalry != game.cavalry:
		_fail("3D troop models did not synchronize with trained troop types.")
		return

	# Research levels consume the correct resources and persist their bonuses.
	game.gold += 500
	game.wood += 500
	game.stone += 500
	game._research("combat")
	game._research("economy")
	game._research("scouting")
	if game.combat_research != 1 or game.economy_research != 1 or game.scouting_research != 1:
		_fail("Combat, economy, or scouting research did not advance.")
		return
	var hero_power_before_xp: int = game._army_power()
	game._award_hero_xp(100)
	game._refresh_ui()
	if game.hero_level != 2 or game.hero_xp != 0 or game._army_power() <= hero_power_before_xp:
		_fail("Royal Captain did not level up or increase army power after earning XP.")
		return
	if not game.world_view.hero_level_label.text.contains("LV 2"):
		_fail("The 3D Royal Captain label did not update after leveling up.")
		return
	var hero_xp_before_training: int = game.hero_xp
	game._train_hero()
	if game.hero_xp != hero_xp_before_training + 25:
		_fail("Hero training did not consume resources and award 25 XP.")
		return
	var hero_skill_before: int = game.hero_skill_level
	game._upgrade_hero_skill()
	if game.hero_skill_level != hero_skill_before + 1:
		_fail("Hero skill upgrade did not increase the skill level.")
		return
	var enemy_level_before_battle: int = game.enemy_level
	var victories_before_battle: int = game.victories
	# Use an overwhelming, valid test force so this test checks victory progression rather than RNG.
	game.infantry = 100
	game.archers = 0
	game.cavalry = 0
	game.guards = 100
	game._attack_enemy_army()
	if game.enemy_level != enemy_level_before_battle + 1 or game.victories != victories_before_battle + 1:
		_fail("A clearly overwhelming test army should win the enemy battle and scale enemy level.")
		return
	var drill_level_before: int = game.practice_drills
	game._practice_troops()
	if game.practice_drills != drill_level_before + 1:
		_fail("Troop practice did not increase army drills.")
		return

	# Campaign outposts must be captured in order; a locked attack must not consume troops.
	game._select_outpost(1)
	var guards_before_locked_attack: int = game.guards
	game._attack_outpost()
	if game.outpost_defeated[1] != 0 or game.guards != guards_before_locked_attack or not game.status_message.contains("locked"):
		_fail("Locked outpost attack changed the army or failed to explain the campaign gate.")
		return
	game._scout()
	if game.region_scouted[1] != 0 or game.guards != guards_before_locked_attack or not game.status_message.contains("locked"):
		_fail("Scouting bypassed sequential campaign unlocks or consumed troops at a locked outpost.")
		return
	game._select_outpost(0)
	game._scout()
	if game.region_scouted[0] != 1:
		_fail("Scouting did not reveal the selected region.")
		return
	var guards_after_first_scout: int = game.guards
	var gold_after_first_scout: int = game.gold
	var wood_after_first_scout: int = game.wood
	game._scout()
	if game.guards != guards_after_first_scout or game.gold != gold_after_first_scout or game.wood != wood_after_first_scout or not game.status_message.contains("already scouted"):
		_fail("Repeat scouting consumed troops or generated duplicate scouting rewards.")
		return

	var guards_before_attack: int = game.guards
	game._attack_outpost()
	if game.guards >= guards_before_attack or game.guards < 0:
		_fail("Tactical outpost combat did not apply bounded troop casualties.")
		return
	await create_timer(0.9).timeout
	game.victories = maxi(game.victories, 1)
	game._claim_reward("first_victory")
	if not game.reward_first_victory_claimed:
		_fail("First Victory reward could not be claimed after a victory.")
		return
	# Seed a small test army for the exploration loop after the battle consumed its force.
	game.infantry = 4
	game.archers = 0
	game.cavalry = 0
	game.guards = 4
	var guards_before_exploration: int = game.guards
	game._explore_region()
	game._explore_region()
	game._explore_region()
	if game.explored_regions != 3 or game.guards != guards_before_exploration - 3:
		_fail("Region exploration did not consume guards or advance campaign progress.")
		return
	game._claim_reward("explorer")
	if not game.reward_explorer_claimed:
		_fail("Explorer reward did not unlock after exploring three regions.")
		return
	game.keep_level = 3
	game._claim_reward("keep_builder")
	if not game.reward_keep_claimed:
		_fail("Keep Builder reward did not unlock at Keep level 3.")
		return
	game._claim_quest("stronghold")
	if not game.quest_stronghold_claimed:
		_fail("Royal Stronghold quest did not unlock at Keep level 3.")
		return
	game.outpost_defeated[0] = 1
	game.outpost_defeated[1] = 1
	game.outpost_defeated[2] = 1
	game._claim_quest("conqueror")
	if not game.quest_conqueror_claimed:
		_fail("Frontier Conqueror quest did not unlock after three outposts were captured.")
		return
	var reward_today := int(floor(float(Time.get_unix_time_from_system()) / 86400.0))
	game.daily_reward_claim_day = reward_today - 1
	game.daily_reward_streak = 2
	var daily_gold_before: int = game.gold
	var daily_food_before: int = game.food
	var daily_wood_before: int = game.wood
	var daily_stone_before: int = game.stone
	game._claim_daily_reward()
	if game.daily_reward_claim_day != reward_today or game.daily_reward_streak != 3:
		_fail("Daily reward did not advance a consecutive three-day streak.")
		return
	if not game.daily_reward_label.text.contains("CLAIMED TODAY") or game.daily_reward_buttons[0].text != "Reward Claimed Today":
		_fail("Daily reward HUD did not display the claimed state and streak countdown.")
		return
	if game.gold != daily_gold_before + 175 or game.food != daily_food_before + 95 or game.wood != daily_wood_before + 55 or game.stone != daily_stone_before + 25:
		_fail("Daily reward did not grant the expected streak-scaled resources.")
		return
	var claimed_daily_gold: int = game.gold
	game._claim_daily_reward()
	if game.gold != claimed_daily_gold or not game.status_message.contains("already claimed"):
		_fail("Daily reward could be claimed more than once in the same day.")
		return
	# The Academy is a real buildable structure and discounts subsequent research.
	game.gold += 500
	game.wood += 300
	game.stone += 300
	# Reuse a test-only plot so the Academy construction path starts from a legal empty tile.
	game.tiles[2] = "Empty"
	game.tile_levels[2] = 1
	game._refresh_ui()
	game._select_tile(2)
	var academy_gold_before: int = game.gold
	var academy_wood_before: int = game.wood
	game._build_academy()
	if game.tiles[2] != "Academy" or game.gold != academy_gold_before - 120 or game.wood != academy_wood_before - 45:
		_fail("Academy construction did not place the building or charge the correct resources.")
		return
	if game.world_view.building_nodes.size() != 9 or game.world_view.building_nodes[2].get_child_count() < 6:
		_fail("Academy construction did not create its 3D building model.")
		return
	var academy_gold_before_upgrade: int = game.gold
	var academy_wood_before_upgrade: int = game.wood
	var academy_stone_before_upgrade: int = game.stone
	game._upgrade_selected_building()
	if game.building_upgrade_tile != 2 or game.tile_levels[2] != 1 or game.gold != academy_gold_before_upgrade - 40 or game.wood != academy_wood_before_upgrade - 20 or game.stone != academy_stone_before_upgrade - 10:
		_fail("Academy upgrade did not start through the normal timed upgrade path or charge its exact costs.")
		return
	game.building_upgrade_finish_unix = int(Time.get_unix_time_from_system()) - 1
	game._finish_building_upgrade()
	if game.tile_levels[2] != 2 or not game.tile_detail_label.text.contains("Research discount: 10%"):
		_fail("Academy upgrade did not complete or apply its level-2 research discount.")
		return
	game.tiles[1] = "Empty"
	game._refresh_ui()
	game._select_tile(1)
	game._build_academy()
	if game.tiles[1] != "Empty" or not game.status_message.contains("one Academy"):
		_fail("A second Academy was allowed instead of directing the player to upgrade the existing one.")
		return
	game._select_tile(2)
	var research_gold_before: int = game.gold
	var research_wood_before: int = game.wood
	var research_stone_before: int = game.stone
	game._research("economy")
	if game.gold != research_gold_before - 45 or game.wood != research_wood_before - 108 or game.stone != research_stone_before - 72 or game.economy_research != 2:
		_fail("Level-2 Academy discount was not applied to research costs.")
		return
	game.tile_levels[2] = 5
	game._refresh_ui()
	if not game.tile_detail_label.text.contains("Research discount: 25%"):
		_fail("Maximum-level Academy did not respect the 25% research discount cap.")
		return
	for i in range(9):
		game.outpost_defeated[i] = 1
	game.outpost_defeated[9] = 0
	game._refresh_ui()
	if not game.campaign_label.text.contains("9/10") or game.campaign_label.text.contains("CAMPAIGN COMPLETE"):
		_fail("Campaign HUD did not show nine of ten outposts before the final victory.")
		return
	game.outpost_defeated[9] = 1
	game._refresh_ui()
	if not game.campaign_label.text.contains("CAMPAIGN COMPLETE"):
		_fail("Campaign HUD did not show completion after all ten outposts were secured.")
		return

	# Production must award resources and preserve the capped-offline economy.
	var gold_before_tick: int = game.gold
	var wood_before_tick: int = game.wood
	var food_before_tick: int = game.food
	var stone_before_tick: int = game.stone
	game._on_production_tick()
	if game.gold <= gold_before_tick or game.wood <= wood_before_tick or game.food <= food_before_tick or game.stone <= stone_before_tick:
		_fail("Active production tick did not generate all four resources.")
		return
	var expected_offline_gold := 0
	var expected_offline_wood := 0
	var expected_offline_food := 0
	var expected_offline_stone := 0
	for i in range(game.tiles.size()):
		match game.tiles[i]:
			"Farm":
				expected_offline_food += 2 * game.keep_level * game.tile_levels[i] * 2880
			"Mine":
				expected_offline_gold += 2 * game.keep_level * game.tile_levels[i] * 2880
			"Lumber Camp":
				expected_offline_wood += 2 * game.keep_level * game.tile_levels[i] * 2880
			"Quarry":
				expected_offline_stone += 2 * game.keep_level * game.tile_levels[i] * 2880
			"Keep":
				expected_offline_gold += game.keep_level * 2880
				expected_offline_wood += 2880
	expected_offline_wood += game.economy_research * 2880
	expected_offline_food += game.economy_research * 2880
	expected_offline_stone += game.economy_research * 2880
	var gold_before_offline: int = game.gold
	var wood_before_offline: int = game.wood
	var food_before_offline: int = game.food
	var stone_before_offline: int = game.stone
	game.last_saved_unix = int(Time.get_unix_time_from_system()) - 36000
	game._apply_offline_production(false)
	if game.gold != gold_before_offline + expected_offline_gold or game.wood != wood_before_offline + expected_offline_wood or game.food != food_before_offline + expected_offline_food or game.stone != stone_before_offline + expected_offline_stone:
		_fail("Offline production did not apply the exact eight-hour capped production.")
		return

	# A pending upgrade timer must survive a save/load cycle.
	# Give this isolated test fixture sufficient resources regardless of randomized scouting rewards.
	game.gold += 200
	game.wood += 200
	game._select_tile(0)
	game._upgrade_selected_building()
	if game.building_upgrade_finish_unix <= int(Time.get_unix_time_from_system()):
		_fail("Could not create a pending upgrade for save persistence.")
		return
	var pending_building_upgrade: int = game.building_upgrade_finish_unix
	game._queue_troop("archer", 1)
	if game.queued_troop_type != "archer" or game.queued_troop_count != 1:
		_fail("Archer training did not enter the queue for timer persistence.")
		return
	var pending_troop_training: int = game.troop_training_finish_unix
	if game._persist_game() != OK:
		_fail("Persisting the kingdom returned a save or backup error.")
		return
	var saved_gold: int = game.gold
	var saved_wood: int = game.wood
	var saved_food: int = game.food
	var saved_stone: int = game.stone
	var saved_guards: int = game.guards
	var saved_infantry: int = game.infantry
	var saved_archers: int = game.archers
	var saved_cavalry: int = game.cavalry
	var saved_queued_troop_type: String = game.queued_troop_type
	var saved_queued_troop_count: int = game.queued_troop_count
	var saved_troop_training_finish: int = game.troop_training_finish_unix
	var saved_tiles: Array = game.tiles.duplicate()
	var saved_levels: PackedInt32Array = game.tile_levels.duplicate()
	var saved_keep_level: int = game.keep_level
	var saved_graphics_quality: String = game.graphics_quality
	var saved_sound_enabled: bool = game.sound_enabled
	var saved_music_enabled: bool = game.music_enabled
	var saved_day: int = game.day
	var saved_daily_claim_day: int = game.daily_reward_claim_day
	var saved_daily_streak: int = game.daily_reward_streak
	var saved_enemy_level: int = game.enemy_level
	var saved_battle_stance: String = game.battle_stance
	var saved_explored_regions: int = game.explored_regions
	var saved_research: Array = [game.combat_research, game.economy_research, game.scouting_research, game.practice_drills]
	var saved_rewards: Array = [game.reward_first_victory_claimed, game.reward_explorer_claimed, game.reward_keep_claimed]
	var saved_quests: Array = [game.quest_builder_claimed, game.quest_stronghold_claimed, game.quest_conqueror_claimed]
	var saved_hero: Array = [game.hero_level, game.hero_xp, game.hero_skill_level]
	var saved_defeated: PackedInt32Array = game.outpost_defeated.duplicate()
	var saved_achievements: PackedStringArray = game.achievements.duplicate()
	game.gold = 0
	game.wood = 0
	game.food = 0
	game.stone = 0
	game.guards = 0
	game.infantry = 0
	game.archers = 0
	game.cavalry = 0
	game.queued_troop_type = ""
	game.queued_troop_count = 0
	game.troop_training_finish_unix = 0
	game.tiles[0] = "Empty"
	game.tile_levels[0] = 1
	game.keep_level = 1
	game.battle_stance = "Aggressive" if saved_battle_stance != "Aggressive" else "Defensive"
	game.daily_reward_claim_day = -1
	game.daily_reward_streak = 0
	game.graphics_quality = "Low" if saved_graphics_quality != "Low" else "High"
	game.sound_enabled = not saved_sound_enabled
	game.music_enabled = not saved_music_enabled
	game.outpost_defeated[0] = 0
	game.achievements.clear()
	game.quest_builder_claimed = false
	game.quest_stronghold_claimed = false
	game.quest_conqueror_claimed = false
	game.hero_level = 1
	game.hero_xp = 0
	game.hero_skill_level = 1
	game._load_game()
	if game.gold != saved_gold or game.wood != saved_wood or game.food != saved_food or game.stone != saved_stone or game.guards != saved_guards:
		_fail("Kingdom save/load did not restore resource and guard values.")
		return
	if game.infantry != saved_infantry or game.archers != saved_archers or game.cavalry != saved_cavalry:
		_fail("Kingdom save/load did not restore troop composition.")
		return
	if game.queued_troop_type != saved_queued_troop_type or game.queued_troop_count != saved_queued_troop_count or game.troop_training_finish_unix != saved_troop_training_finish:
		_fail("Kingdom save/load did not restore the troop training queue timer.")
		return
	if game.tiles != saved_tiles or game.tile_levels != saved_levels or game.keep_level != saved_keep_level:
		_fail("Kingdom save/load did not restore building levels.")
		return
	if game.battle_stance != saved_battle_stance:
		_fail("Kingdom save/load did not restore the tactical battle stance.")
		return
	if game.graphics_quality != saved_graphics_quality:
		_fail("Kingdom save/load did not restore the graphics preset.")
		return
	if game.sound_enabled != saved_sound_enabled:
		_fail("Kingdom save/load did not restore the sound preference.")
		return
	if game.music_enabled != saved_music_enabled:
		_fail("Kingdom save/load did not restore the music preference.")
		return
	if game.outpost_defeated != saved_defeated or game.achievements != saved_achievements:
		_fail("Kingdom save/load did not restore campaign and achievement progress.")
		return
	if game.day != saved_day or game.enemy_level != saved_enemy_level or game.explored_regions != saved_explored_regions:
		_fail("Kingdom save/load did not restore campaign day, enemy level and exploration progress.")
		return
	if game.daily_reward_claim_day != saved_daily_claim_day or game.daily_reward_streak != saved_daily_streak:
		_fail("Kingdom save/load did not restore daily reward streak progress.")
		return
	if [game.combat_research, game.economy_research, game.scouting_research, game.practice_drills] != saved_research:
		_fail("Kingdom save/load did not restore research and practice progress.")
		return
	if [game.reward_first_victory_claimed, game.reward_explorer_claimed, game.reward_keep_claimed] != saved_rewards:
		_fail("Kingdom save/load did not restore claimed campaign rewards.")
		return
	if [game.quest_builder_claimed, game.quest_stronghold_claimed, game.quest_conqueror_claimed] != saved_quests:
		_fail("Kingdom save/load did not restore quest claim progress.")
		return
	if [game.hero_level, game.hero_xp, game.hero_skill_level] != saved_hero:
		_fail("Kingdom save/load did not restore Royal Captain progression.")
		return
	if game.building_upgrade_finish_unix != pending_building_upgrade or game.building_upgrade_tile != 0:
		_fail("Kingdom save/load did not restore the pending building upgrade timer.")
		return
	var guards_before_resumed_training: int = game.guards
	game.troop_training_finish_unix = int(Time.get_unix_time_from_system()) - 1
	game._resume_timed_upgrades()
	if game.queued_troop_count != 0 or game.guards != guards_before_resumed_training + 1:
		_fail("An expired troop training queue did not complete when timers resumed.")
		return

	var absolute_save := ProjectSettings.globalize_path("user://apptya_kingdom_save.cfg")
	# Old Unity/Godot prototype saves had only three outposts; migrate those entries forward.
	game.outpost_defeated = PackedInt32Array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
	game.region_scouted = PackedInt32Array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
	var legacy_config := ConfigFile.new()
	legacy_config.set_value("kingdom", "outpost_defeated", PackedInt32Array([1, 0, 1]))
	legacy_config.set_value("kingdom", "region_scouted", PackedInt32Array([0, 1, 0]))
	if legacy_config.save(absolute_save) != OK:
		_fail("Could not create a legacy three-outpost save fixture.")
		return
	game._load_game()
	if game.outpost_defeated.size() != 10 or game.outpost_defeated[0] != 1 or game.outpost_defeated[2] != 0 or game.outpost_defeated[3] != 0 or game.region_scouted[1] != 1:
		_fail("Legacy save migration did not repair impossible sequential campaign states.")
		return
	var corrupt_file := FileAccess.open(absolute_save, FileAccess.WRITE)
	if corrupt_file == null:
		_fail("Could not create save-recovery test fixture.")
		return
	corrupt_file.store_string("invalid save content")
	corrupt_file.close()
	game._load_game()
	if game.gold <= 0:
		_fail("Backup save recovery failed.")
		return

	# Combat rules are deterministic for a given force and expose different enemy tactics.
	var combat_rules = load("res://combat_director.gd")
	var infantry_battle: Dictionary = combat_rules.resolve_outpost(8, 0, 0, 20, 2, 3, 3, 2, 2, 0, true)
	var cavalry_battle: Dictionary = combat_rules.resolve_outpost(0, 0, 8, 20, 2, 3, 3, 2, 2, 2, true)
	var archer_counter: Dictionary = combat_rules.resolve_outpost(0, 8, 0, 20, 2, 3, 3, 2, 2, 0, true)
	var cavalry_vs_fort: Dictionary = combat_rules.resolve_outpost(0, 0, 8, 20, 2, 3, 3, 2, 2, 0, true)
	if infantry_battle["trait"] == cavalry_battle["trait"] or infantry_battle["chance"] < 8 or infantry_battle["chance"] > 92 or infantry_battle["loss_losses"] > 8:
		_fail("Tactical combat director did not expose distinct enemy traits or bounded odds/casualties.")
		return
	if archer_counter["chance"] <= cavalry_vs_fort["chance"]:
		_fail("The Fortified Hold enemy doctrine did not reward the correct troop counter.")
		return
	var cavalry_counter_vs_bow: Dictionary = combat_rules.resolve_outpost(0, 0, 3, 0, 0, 0, 1, 1, 1, 1, true)
	var infantry_vs_bow: Dictionary = combat_rules.resolve_outpost(3, 0, 0, 0, 0, 0, 1, 1, 1, 1, true)
	if cavalry_counter_vs_bow["chance"] <= infantry_vs_bow["chance"]:
		_fail("The Longbow Nest enemy doctrine did not reward the correct troop counter.")
		return
	var infantry_counter_vs_mounted: Dictionary = combat_rules.resolve_outpost(3, 0, 0, 0, 0, 0, 1, 1, 1, 2, true)
	var archers_vs_mounted: Dictionary = combat_rules.resolve_outpost(0, 3, 0, 0, 0, 0, 1, 1, 1, 2, true)
	if infantry_counter_vs_mounted["chance"] <= archers_vs_mounted["chance"]:
		_fail("The Mounted Raiders enemy doctrine did not reward the correct troop counter.")
		return
	var army_battle: Dictionary = combat_rules.resolve_enemy_army(100, 0, 0, 100, 5, 20, 10, 5, 1)
	if army_battle["chance"] < 90 or army_battle["loss_losses"] > 100:
		_fail("Combat director did not scale an overwhelming army advantage or bound casualties.")
		return

	var penultimate_outpost: Dictionary = combat_rules.resolve_outpost(5, 3, 2, 10, 0, 0, 1, 1, 10, 8, true)
	var final_boss: Dictionary = combat_rules.resolve_outpost(5, 3, 2, 10, 0, 0, 1, 1, 10, 9, true)
	if final_boss["trait"] != "Warlord's Citadel" or final_boss["enemy_power"] <= penultimate_outpost["enemy_power"]:
		_fail("The final campaign outpost did not expose a distinct, stronger boss encounter.")
		return
	var balanced_stance: Dictionary = combat_rules.resolve_outpost(5, 3, 2, 10, 0, 0, 1, 1, 10, 9, false, "Balanced")
	var aggressive_stance: Dictionary = combat_rules.resolve_outpost(5, 3, 2, 10, 0, 0, 1, 1, 10, 9, false, "Aggressive")
	var defensive_stance: Dictionary = combat_rules.resolve_outpost(5, 3, 2, 10, 0, 0, 1, 1, 10, 9, false, "Defensive")
	if aggressive_stance["chance"] <= balanced_stance["chance"] or aggressive_stance["win_losses"] < balanced_stance["win_losses"] or aggressive_stance["loss_losses"] < balanced_stance["loss_losses"]:
		_fail("Aggressive stance must improve attack odds while increasing expected casualties.")
		return
	if defensive_stance["chance"] >= balanced_stance["chance"] or defensive_stance["win_losses"] > balanced_stance["win_losses"] or defensive_stance["loss_losses"] > balanced_stance["loss_losses"]:
		_fail("Defensive stance must trade lower odds for fewer expected casualties.")
		return
	var invalid_stance: Dictionary = combat_rules.resolve_outpost(5, 3, 2, 10, 0, 0, 1, 1, 10, 9, false, "invalid")
	if invalid_stance["stance"] != "Balanced":
		_fail("Combat director did not safely normalize an unknown battle stance.")
		return

	# Save data normalization must clamp invalid economy values and restore the Keep invariant.
	game.gold = -50
	game.wood = -10
	game.food = -1
	game.guards = -7
	game.infantry = -7
	game.archers = -2
	game.cavalry = -3
	game.queued_troop_type = ""
	game.queued_troop_count = 0
	game.troop_training_finish_unix = 0
	game.keep_level = 0
	game.battle_stance = "Corrupted Stance"
	game.selected_tile = 99
	game.tiles[0] = "UnknownBuilding"
	game.tiles[1] = "Academy"
	game.tiles[2] = "Academy"
	game.tiles[3] = "Keep"
	game.tiles[4] = "Farm"
	game.tile_levels[0] = 1000
	game.outpost_defeated[0] = 9
	game.region_scouted[0] = -2
	game.daily_reward_claim_day = int(floor(float(Time.get_unix_time_from_system()) / 86400.0)) + 99
	game.outpost_defeated[2] = 1
	game.region_scouted[2] = 1
	game._normalize_save_data()
	if game.battle_stance != "Balanced":
		_fail("Save normalization did not repair an invalid battle stance.")
		return
	if game.gold != 0 or game.wood != 0 or game.food != 0 or game.guards != 0:
		_fail("Save normalization did not clamp negative resource and guard values.")
		return
	if game.keep_level != 1 or game.selected_tile != 8 or game.tiles[0] != "Empty" or game.tiles[3] != "Empty" or game.tiles[4] != "Keep" or game.tile_levels[0] != 5:
		_fail("Save normalization did not restore valid kingdom limits or remove duplicate Keeps.")
		return
	var normalized_capacity := 0
	for i in range(game.tiles.size()):
		if game.tiles[i] == "Barracks":
			normalized_capacity = maxi(normalized_capacity, game.tile_levels[i] * 5)
	if game.guards != game.infantry + game.archers + game.cavalry or game.guards > normalized_capacity:
		_fail("Save normalization did not enforce the Barracks troop capacity.")
		return
	if game.queued_troop_count > normalized_capacity - game.guards or (game.queued_troop_count == 0 and game.queued_troop_type != ""):
		_fail("Save normalization did not safely trim the troop queue.")
		return
	var academy_count := 0
	for building in game.tiles:
		if building == "Academy":
			academy_count += 1
	if academy_count != 1 or game.tiles[1] != "Academy" or game.tiles[2] != "Empty":
		_fail("Save normalization did not enforce the single-Academy invariant.")
		return
	if game.outpost_defeated[0] != 0 or game.region_scouted[0] != 0:
		_fail("Save normalization did not sanitize outpost progress.")
		return
	var utc_day_now := int(floor(float(Time.get_unix_time_from_system()) / 86400.0))
	if game.daily_reward_claim_day > utc_day_now or game.outpost_defeated[2] != 0 or game.region_scouted[2] != 0:
		_fail("Save normalization did not clamp future reward claims or repair locked campaign progress.")
		return
	game.gold = 3000000001
	game._normalize_save_data()
	if game.gold != 2000000000:
		_fail("Save normalization did not cap corrupt resource values safely.")
		return
	game.gold = 300
	game.outpost_defeated[0] = 1
	game.outpost_defeated[1] = 0
	game.outpost_defeated[2] = 1
	game.region_scouted[2] = 1
	game._normalize_save_data()
	if game.outpost_defeated[0] != 1 or game.outpost_defeated[2] != 0 or game.region_scouted[2] != 0:
		_fail("Save normalization did not preserve valid campaign progress while clearing impossible later captures.")
		return

	# Independently verify recovery from a save whose troop roster exceeds Barracks capacity.
	game.infantry = 20
	game.archers = 20
	game.cavalry = 20
	game.queued_troop_type = "archer"
	game.queued_troop_count = 5
	game.troop_training_finish_unix = int(Time.get_unix_time_from_system()) + 60
	game._normalize_save_data()
	var recovered_capacity := 0
	for i in range(game.tiles.size()):
		if game.tiles[i] == "Barracks":
			recovered_capacity = maxi(recovered_capacity, game.tile_levels[i] * 5)
	if game.guards != game.infantry + game.archers + game.cavalry or game.guards > recovered_capacity:
		_fail("Save normalization did not enforce the Barracks troop capacity.")
		return
	if game.queued_troop_count > recovered_capacity - game.guards or (game.queued_troop_count == 0 and game.queued_troop_type != ""):
		_fail("Save normalization did not safely trim the troop queue.")
		return

	# Far-future operation timestamps from a corrupt save must never stall progress.
	var timer_now := int(Time.get_unix_time_from_system())
	game.keep_level = 1
	game.keep_upgrade_finish_unix = timer_now + 100000
	game.building_upgrade_tile = 1
	game.tiles[1] = "Academy"
	game.tile_levels[1] = 1
	game.building_upgrade_finish_unix = timer_now + 100000
	game.infantry = 1
	game.archers = 0
	game.cavalry = 0
	game.guards = 1
	game.queued_troop_type = "archer"
	game.queued_troop_count = 1
	game.troop_training_finish_unix = timer_now + 100000
	game._normalize_save_data()
	if game.keep_upgrade_finish_unix > timer_now + 120 or game.building_upgrade_finish_unix > timer_now + 120 or game.troop_training_finish_unix > timer_now + 120:
		_fail("Save normalization left a corrupt operation timer far in the future.")
		return

	print("APPTYA_GAMEPLAY_TESTS_PASSED")
	quit(0)

func _remove_save(path: String) -> void:
	var absolute_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(absolute_path)

func _fail(message: String) -> void:
	push_error("APPTYA_GAMEPLAY_TEST_FAILED: " + message)
	quit(1)
