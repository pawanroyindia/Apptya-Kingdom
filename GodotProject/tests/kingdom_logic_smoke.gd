extends SceneTree

func _initialize() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	_remove_save("user://apptya_kingdom_save.cfg")
	_remove_save("user://apptya_kingdom_save_backup.cfg")
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	await physics_frame
	await physics_frame

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

	game._train_guard()
	if game.guards != 11 or game.tutorial_step != 3:
		_fail("Guard training or tutorial progression failed.")
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
	game._select_tile(6)
	var barracks_gold_before: int = game.gold
	var barracks_wood_before: int = game.wood
	game._build_barracks()
	if game.tiles[6] != "Barracks" or game.gold != barracks_gold_before - 80 or game.wood != barracks_wood_before - 30:
		_fail("Barracks construction or resource costs failed.")
		return
	var guards_before_training: int = game.guards
	var training_gold_before: int = game.gold
	var training_food_before: int = game.food
	game._train_guard()
	if game.guards != guards_before_training + 1 or game.gold != training_gold_before - 20 or game.food != training_food_before - 10:
		_fail("Guard training resource costs failed.")
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

	# Production must award resources and preserve the capped-offline economy.
	var gold_before_tick: int = game.gold
	var wood_before_tick: int = game.wood
	var food_before_tick: int = game.food
	game._on_production_tick()
	if game.gold <= gold_before_tick or game.wood <= wood_before_tick or game.food <= food_before_tick:
		_fail("Active production tick did not generate resources from built economy.")
		return
	var gold_before_offline: int = game.gold
	game.last_saved_unix = int(Time.get_unix_time_from_system()) - 36000
	game._apply_offline_production(false)
	if game.gold <= gold_before_offline:
		_fail("Offline production did not award resources.")
		return
	if game.gold > gold_before_offline + 2 * game.keep_level * 99 * 2880:
		_fail("Offline production exceeded the configured eight-hour cap.")
		return

	game._persist_game()
	var saved_gold: int = game.gold
	game.gold = 0
	game._load_game()
	if game.gold <= 0 or saved_gold <= 0:
		_fail("Kingdom save/load round trip failed.")
		return

	var absolute_save := ProjectSettings.globalize_path("user://apptya_kingdom_save.cfg")
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
	game.keep_level = 0
	game.selected_tile = 99
	game.tiles[0] = "UnknownBuilding"
	game.tiles[4] = "Farm"
	game.tile_levels[0] = 1000
	game.outpost_defeated[0] = 9
	game.region_scouted[0] = -2
	game._normalize_save_data()
	if game.gold != 0 or game.wood != 0 or game.food != 0 or game.guards != 0:
		_fail("Save normalization did not clamp negative resource and guard values.")
		return
	if game.keep_level != 1 or game.selected_tile != 8 or game.tiles[0] != "Empty" or game.tiles[4] != "Keep" or game.tile_levels[0] != 99:
		_fail("Save normalization did not restore valid kingdom limits.")
		return
	if game.outpost_defeated[0] != 1 or game.region_scouted[0] != 0:
		_fail("Save normalization did not sanitize outpost progress.")
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
