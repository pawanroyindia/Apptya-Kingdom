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
	if not is_instance_valid(game.world_view.hero_model) or not game.world_view.hero_level_label.text.contains("LV 1"):
		_fail("The 3D Royal Captain model or level label was not created.")
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
	if game._army_power() < game._enemy_power():
		_fail("Test army fixture should be stronger than the first enemy.")
		return
	game._attack_enemy_army()
	if game.enemy_level != enemy_level_before_battle + 1 or game.victories != victories_before_battle + 1:
		_fail("Power-based enemy battle did not award victory or scale enemy level.")
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
	game._select_outpost(0)
	game._scout()
	if game.region_scouted[0] != 1:
		_fail("Scouting did not reveal the selected region.")
		return

	var guards_before_attack: int = game.guards
	game._attack_outpost()
	if game.guards > guards_before_attack - 4:
		_fail("Targeted outpost attack did not consume the required guards.")
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
	game._persist_game()
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
	var saved_day: int = game.day
	var saved_enemy_level: int = game.enemy_level
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
	game.graphics_quality = "Low" if saved_graphics_quality != "Low" else "High"
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
	if game.graphics_quality != saved_graphics_quality:
		_fail("Kingdom save/load did not restore the graphics preset.")
		return
	if game.outpost_defeated != saved_defeated or game.achievements != saved_achievements:
		_fail("Kingdom save/load did not restore campaign and achievement progress.")
		return
	if game.day != saved_day or game.enemy_level != saved_enemy_level or game.explored_regions != saved_explored_regions:
		_fail("Kingdom save/load did not restore campaign day, enemy level and exploration progress.")
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
	if game.outpost_defeated.size() != 10 or game.outpost_defeated[0] != 1 or game.outpost_defeated[2] != 1 or game.outpost_defeated[3] != 0 or game.region_scouted[1] != 1:
		_fail("Legacy three-outpost save did not migrate to the ten-outpost campaign.")
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
	game.selected_tile = 99
	game.tiles[0] = "UnknownBuilding"
	game.tiles[3] = "Keep"
	game.tiles[4] = "Farm"
	game.tile_levels[0] = 1000
	game.outpost_defeated[0] = 9
	game.region_scouted[0] = -2
	game._normalize_save_data()
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
	if game.outpost_defeated[0] != 0 or game.region_scouted[0] != 0:
		_fail("Save normalization did not sanitize outpost progress.")
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

	print("APPTYA_GAMEPLAY_TESTS_PASSED")
	quit(0)

func _remove_save(path: String) -> void:
	var absolute_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(absolute_path)

func _fail(message: String) -> void:
	push_error("APPTYA_GAMEPLAY_TEST_FAILED: " + message)
	quit(1)
