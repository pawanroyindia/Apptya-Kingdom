extends Control

const SAVE_PATH := "user://apptya_kingdom_save.cfg"
const BACKUP_SAVE_PATH := "user://apptya_kingdom_save_backup.cfg"
const MAX_OFFLINE_SECONDS := 28800
const TICK_SECONDS := 10.0

var gold := 300
var wood := 150
var food := 120
var guards := 10
var keep_level := 1
var selected_tile := 4
var selected_outpost := 0
var last_saved_unix := 0
var keep_upgrade_finish_unix := 0
var building_upgrade_finish_unix := 0
var building_upgrade_tile := -1
var tutorial_step := 0
var tiles: Array[String] = ["Empty", "Farm", "Empty", "Mine", "Keep", "Empty", "Empty", "Barracks", "Empty"]
var tile_levels := PackedInt32Array([1, 1, 1, 1, 1, 1, 1, 1, 1])
var outpost_threat := PackedInt32Array([1, 2, 3])
var outpost_defeated := PackedInt32Array([0, 0, 0])
var region_scouted := PackedInt32Array([0, 0, 0])
var achievements := PackedStringArray()
var status_message := "Your kingdom awaits your command."
var resource_labels: Dictionary = {}
var tile_buttons: Array[Button] = []
var outpost_buttons: Array[Button] = []
var keep_label: Label
var guard_label: Label
var status_label: Label
var tile_detail_label: Label
var tutorial_label: Label
var outpost_label: Label
var achievements_label: Label
var tick_timer: Timer
var upgrade_timer: Timer
var building_upgrade_timer: Timer
var world_view: Node3D

func _ready() -> void:
	_load_game()
	_build_ui()
	_refresh_ui()
	tick_timer = Timer.new()
	tick_timer.wait_time = TICK_SECONDS
	tick_timer.one_shot = false
	tick_timer.timeout.connect(_on_production_tick)
	add_child(tick_timer)
	tick_timer.start()
	upgrade_timer = Timer.new()
	upgrade_timer.one_shot = true
	upgrade_timer.timeout.connect(_finish_keep_upgrade)
	add_child(upgrade_timer)
	building_upgrade_timer = Timer.new()
	building_upgrade_timer.one_shot = true
	building_upgrade_timer.timeout.connect(_finish_building_upgrade)
	add_child(building_upgrade_timer)
	_resume_timed_upgrades()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		_persist_game()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		_apply_offline_production(true)
		_resume_timed_upgrades()

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("#14251f")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var margins := MarginContainer.new()
	margins.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margins.add_theme_constant_override("margin_left", 14)
	margins.add_theme_constant_override("margin_right", 14)
	margins.add_theme_constant_override("margin_top", 16)
	margins.add_theme_constant_override("margin_bottom", 22)
	scroll.add_child(margins)

	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 10)
	margins.add_child(column)

	var title := Label.new()
	title.text = "APPTYA KINGDOM"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", Color("#f1d38a"))
	column.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Build • Gather • Train • Explore"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color("#c3d2c7"))
	column.add_child(subtitle)

	var world_container := SubViewportContainer.new()
	world_container.custom_minimum_size = Vector2(0, 260)
	world_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	world_container.stretch = true
	column.add_child(world_container)
	var world_viewport := SubViewport.new()
	world_viewport.size = Vector2i(640, 360)
	world_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	world_viewport.gui_disable_input = true
	world_container.add_child(world_viewport)
	world_view = load("res://kingdom_world.tscn").instantiate() as Node3D
	world_viewport.add_child(world_view)
	world_view.connect("tile_selected", Callable(self, "_select_tile"))

	var resource_panel := PanelContainer.new()
	resource_panel.add_theme_stylebox_override("panel", _panel_style("#243a30"))
	column.add_child(resource_panel)
	var resource_box := VBoxContainer.new()
	resource_box.add_theme_constant_override("separation", 5)
	resource_panel.add_child(resource_box)
	for key in ["gold", "wood", "food"]:
		var label := Label.new()
		label.add_theme_font_size_override("font_size", 17)
		label.add_theme_color_override("font_color", Color("#fff2d2"))
		resource_box.add_child(label)
		resource_labels[key] = label

	var realm_header := Label.new()
	realm_header.text = "YOUR REALM"
	realm_header.add_theme_font_size_override("font_size", 20)
	realm_header.add_theme_color_override("font_color", Color("#f1d38a"))
	column.add_child(realm_header)

	var realm_panel := PanelContainer.new()
	realm_panel.add_theme_stylebox_override("panel", _panel_style("#20362d"))
	column.add_child(realm_panel)
	var realm_box := VBoxContainer.new()
	realm_box.add_theme_constant_override("separation", 6)
	realm_panel.add_child(realm_box)
	keep_label = Label.new()
	realm_box.add_child(keep_label)
	guard_label = Label.new()
	realm_box.add_child(guard_label)

	var map_title := Label.new()
	map_title.text = "KINGDOM MAP  •  Select a tile"
	map_title.add_theme_font_size_override("font_size", 18)
	map_title.add_theme_color_override("font_color", Color("#f1d38a"))
	column.add_child(map_title)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 7)
	grid.add_theme_constant_override("v_separation", 7)
	column.add_child(grid)
	for i in range(tiles.size()):
		var tile_button := Button.new()
		tile_button.custom_minimum_size = Vector2(0, 76)
		tile_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile_button.add_theme_font_size_override("font_size", 14)
		tile_button.pressed.connect(_select_tile.bind(i))
		grid.add_child(tile_button)
		tile_buttons.append(tile_button)

	tile_detail_label = Label.new()
	tile_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tile_detail_label.add_theme_color_override("font_color", Color("#d8e6d9"))
	column.add_child(tile_detail_label)
	_add_button_row(column, [
		{"text": "Upgrade Selected\nTimed, cost scales by level", "action": _upgrade_selected_building},
		{"text": "Refresh / Save", "action": _save_game}
	])

	var build_title := Label.new()
	build_title.text = "BUILD & IMPROVE"
	build_title.add_theme_font_size_override("font_size", 18)
	build_title.add_theme_color_override("font_color", Color("#f1d38a"))
	column.add_child(build_title)
	_add_button_row(column, [
		{"text": "Build Farm\n50 gold, 10 wood", "action": _build_farm},
		{"text": "Build Mine\n70 gold, 20 wood", "action": _build_mine}
	])
	_add_button_row(column, [
		{"text": "Build Barracks\n80 gold, 30 wood", "action": _build_barracks},
		{"text": "Upgrade Keep\n100 gold, 50 wood", "action": _upgrade_keep}
	])

	var outpost_title := Label.new()
	outpost_title.text = "ENEMY OUTPOSTS"
	outpost_title.add_theme_font_size_override("font_size", 18)
	outpost_title.add_theme_color_override("font_color", Color("#f1d38a"))
	column.add_child(outpost_title)
	outpost_label = Label.new()
	outpost_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(outpost_label)
	_add_button_row(column, [
		{"text": "Outpost 1\nThreat 1", "action": _select_outpost.bind(0)},
		{"text": "Outpost 2\nThreat 2", "action": _select_outpost.bind(1)},
		{"text": "Outpost 3\nThreat 3", "action": _select_outpost.bind(2)}
	], outpost_buttons)

	var army_title := Label.new()
	army_title.text = "ARMY & EXPLORATION"
	army_title.add_theme_font_size_override("font_size", 18)
	army_title.add_theme_color_override("font_color", Color("#f1d38a"))
	column.add_child(army_title)
	_add_button_row(column, [
		{"text": "Train Guard\n20 gold, 10 food", "action": _train_guard},
		{"text": "Scout Region\n5 guards", "action": _scout}
	])
	_add_button_row(column, [
		{"text": "Attack Selected Outpost\n3+ guards", "action": _attack_outpost},
		{"text": "Save Kingdom", "action": _save_game}
	])

	tutorial_label = Label.new()
	tutorial_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_label.add_theme_color_override("font_color", Color("#f1d38a"))
	column.add_child(tutorial_label)
	achievements_label = Label.new()
	achievements_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	achievements_label.add_theme_color_override("font_color", Color("#c3d2c7"))
	column.add_child(achievements_label)

	var status_panel := PanelContainer.new()
	status_panel.add_theme_stylebox_override("panel", _panel_style("#26392f"))
	column.add_child(status_panel)
	status_label = Label.new()
	status_label.text = status_message
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size = Vector2(0, 44)
	status_panel.add_child(status_label)

func _add_button_row(parent: VBoxContainer, definitions: Array, button_store: Array[Button] = []) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	for definition in definitions:
		var button := Button.new()
		button.text = definition["text"]
		button.custom_minimum_size = Vector2(0, 62)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 13)
		button.pressed.connect(definition["action"])
		row.add_child(button)
		if button_store != null:
			button_store.append(button)

func _panel_style(color_value: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color_value)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func _refresh_ui() -> void:
	if resource_labels.has("gold"):
		resource_labels["gold"].text = "🪙 Gold: %d" % gold
		resource_labels["wood"].text = "🪵 Wood: %d" % wood
		resource_labels["food"].text = "🌾 Food: %d" % food
		var upgrade_text := ""
		if keep_upgrade_finish_unix > int(Time.get_unix_time_from_system()):
			upgrade_text = "   •   Keep upgrade: %ds" % (keep_upgrade_finish_unix - int(Time.get_unix_time_from_system()))
		keep_label.text = "Keep level: %d   •   Selected tile: %d%s" % [keep_level, selected_tile + 1, upgrade_text]
		guard_label.text = "Trained guards: %d" % guards
		for i in range(tile_buttons.size()):
			var prefix := "▶ " if i == selected_tile else ""
			tile_buttons[i].text = "%s%s Lv.%d\nTile %d" % [prefix, tiles[i], tile_levels[i], i + 1]
			tile_buttons[i].modulate = Color("#f4d994") if i == selected_tile else Color("#ffffff")
		if tiles[selected_tile] == "Empty":
			tile_detail_label.text = "Tile %d is empty. Build a Farm, Mine, or Barracks here." % (selected_tile + 1)
		else:
			var production := "No direct resource production"
			if tiles[selected_tile] == "Farm":
				production = "Food production: %d per tick" % (2 * keep_level * tile_levels[selected_tile])
			elif tiles[selected_tile] == "Mine":
				production = "Gold production: %d per tick" % (2 * keep_level * tile_levels[selected_tile])
			elif tiles[selected_tile] == "Keep":
				production = "Keep produces %d gold and 1 wood per tick" % keep_level
			var upgrade_note := ""
			if building_upgrade_finish_unix > int(Time.get_unix_time_from_system()) and building_upgrade_tile == selected_tile:
				upgrade_note = " Building upgrade completes in %ds." % (building_upgrade_finish_unix - int(Time.get_unix_time_from_system()))
			tile_detail_label.text = "Selected: %s (Level %d) on tile %d. %s%s" % [tiles[selected_tile], tile_levels[selected_tile], selected_tile + 1, production, upgrade_note]
		for i in range(outpost_buttons.size()):
			var region_status := " • Captured" if outpost_defeated[i] == 1 else (" • Scouted" if region_scouted[i] == 1 else " • Unknown")
			outpost_buttons[i].text = "%sOutpost %d%s" % ["▶ " if i == selected_outpost else "", i + 1, region_status]
		outpost_label.text = _get_outpost_description()
		tutorial_label.text = _get_tutorial_text()
		achievements_label.text = "Achievements: %d/8 — %s" % [achievements.size(), ", ".join(achievements) if not achievements.is_empty() else "none yet"]
		if is_instance_valid(world_view):
			world_view.set_kingdom_state(tiles, tile_levels, keep_level, guards, outpost_defeated, region_scouted, selected_outpost, selected_tile)
		status_label.text = status_message

func _select_tile(index: int) -> void:
	selected_tile = index
	status_message = "Selected tile %d: %s." % [index + 1, tiles[index]]
	_refresh_ui()

func _get_tutorial_text() -> String:
	match tutorial_step:
		0:
			return "TUTORIAL 1/4: Build a Farm on an empty tile."
		1:
			return "TUTORIAL 2/4: Build a Mine to increase gold income."
		2:
			return "TUTORIAL 3/4: Train guards for your army."
		3:
			return "TUTORIAL 4/4: Select an enemy outpost and win an attack."
		_:
			return "TUTORIAL COMPLETE: Keep upgrading, expand your economy, and defeat all outposts."

func _advance_tutorial(target_step: int) -> void:
	if target_step > tutorial_step:
		tutorial_step = min(target_step, 4)
		var reward := tutorial_step * 25
		gold += reward
		status_message = "Tutorial step completed! Reward: %d gold." % reward

func _award_achievement(achievement_id: String, title: String, gold_reward: int, food_reward: int = 0) -> void:
	if achievements.has(achievement_id):
		return
	achievements.append(achievement_id)
	gold += gold_reward
	food += food_reward
	status_message = "Achievement unlocked: %s (+%d gold%s)." % [title, gold_reward, ", +%d food" % food_reward if food_reward > 0 else ""]

func _get_outpost_description() -> String:
	var threat := outpost_threat[selected_outpost]
	if outpost_defeated[selected_outpost] == 1:
		return "Outpost %d captured. It is secured and cannot be attacked again." % (selected_outpost + 1)
	if region_scouted[selected_outpost] != 1:
		return "Target: Outpost %d. This region is unexplored. Scout it to reveal enemy threat before attacking." % (selected_outpost + 1)
	return "Scouted target: Outpost %d • Threat %d • Estimated success chance %d%% • Guards required: %d" % [selected_outpost + 1, threat, clampi(65 - threat * 12 + keep_level * 6 + guards / 2, 10, 90), 3 + threat]

func _select_outpost(index: int) -> void:
	selected_outpost = clampi(index, 0, outpost_threat.size() - 1)
	status_message = "Targeting enemy outpost %d." % (selected_outpost + 1)
	_refresh_ui()

func _build_farm() -> void:
	if not _can_build("Farm", 50, 10):
		return
	tiles[selected_tile] = "Farm"
	gold -= 50
	wood -= 10
	status_message = "Farm built. It produces food over time."
	_award_achievement("farm", "First Farm", 20)
	if tutorial_step == 0:
		_advance_tutorial(1)
	_refresh_ui()

func _build_mine() -> void:
	if not _can_build("Mine", 70, 20):
		return
	tiles[selected_tile] = "Mine"
	gold -= 70
	wood -= 20
	status_message = "Mine built. It produces gold over time."
	_award_achievement("mine", "First Mine", 20)
	if tutorial_step == 1:
		_advance_tutorial(2)
	_refresh_ui()

func _build_barracks() -> void:
	if not _can_build("Barracks", 80, 30):
		return
	tiles[selected_tile] = "Barracks"
	gold -= 80
	wood -= 30
	status_message = "Barracks built. Train guards to protect your realm."
	_refresh_ui()

func _can_build(building: String, gold_cost: int, wood_cost: int) -> bool:
	if tiles[selected_tile] != "Empty":
		status_message = "Choose an empty tile before building."
		_refresh_ui()
		return false
	if gold < gold_cost or wood < wood_cost:
		status_message = "Not enough resources for %s." % building
		_refresh_ui()
		return false
	return true

func _upgrade_keep() -> void:
	if keep_upgrade_finish_unix > int(Time.get_unix_time_from_system()):
		status_message = "Keep upgrade is already in progress."
		_refresh_ui()
		return
	var gold_cost := 100 * keep_level
	var wood_cost := 50 * keep_level
	if gold < gold_cost or wood < wood_cost:
		status_message = "Keep upgrade needs %d gold and %d wood." % [gold_cost, wood_cost]
		_refresh_ui()
		return
	gold -= gold_cost
	wood -= wood_cost
	keep_upgrade_finish_unix = int(Time.get_unix_time_from_system()) + 15
	upgrade_timer.start(15.0)
	status_message = "Keep upgrade started. It will finish in 15 seconds."
	_persist_game()
	_refresh_ui()

func _finish_keep_upgrade() -> void:
	if keep_upgrade_finish_unix <= 0:
		return
	keep_upgrade_finish_unix = 0
	keep_level += 1
	_award_achievement("keep_upgrade", "Keep Upgraded", 50)
	status_message = "Keep upgrade complete! Keep level is now %d." % keep_level
	_persist_game()
	_refresh_ui()

func _upgrade_selected_building() -> void:
	if building_upgrade_finish_unix > int(Time.get_unix_time_from_system()):
		status_message = "Another building upgrade is already in progress."
		_refresh_ui()
		return
	var building := tiles[selected_tile]
	if building != "Farm" and building != "Mine" and building != "Barracks":
		status_message = "Select a Farm, Mine, or Barracks to upgrade it."
		_refresh_ui()
		return
	var level := tile_levels[selected_tile]
	var gold_cost := 40 * level
	var wood_cost := 20 * level
	if gold < gold_cost or wood < wood_cost:
		status_message = "Upgrade needs %d gold and %d wood." % [gold_cost, wood_cost]
		_refresh_ui()
		return
	gold -= gold_cost
	wood -= wood_cost
	building_upgrade_tile = selected_tile
	building_upgrade_finish_unix = int(Time.get_unix_time_from_system()) + maxi(5, level * 5)
	building_upgrade_timer.start(float(building_upgrade_finish_unix - int(Time.get_unix_time_from_system())))
	status_message = "%s upgrade started. It will finish in %d seconds." % [building, maxi(5, level * 5)]
	_persist_game()
	_refresh_ui()

func _finish_building_upgrade() -> void:
	if building_upgrade_finish_unix <= 0:
		return
	if building_upgrade_tile >= 0 and building_upgrade_tile < tiles.size():
		var building := tiles[building_upgrade_tile]
		if building == "Farm" or building == "Mine" or building == "Barracks":
			tile_levels[building_upgrade_tile] = clampi(tile_levels[building_upgrade_tile] + 1, 1, 99)
			_award_achievement("building_upgrade", "Master Builder", 40)
			status_message = "%s upgrade complete at level %d." % [building, tile_levels[building_upgrade_tile]]
	building_upgrade_finish_unix = 0
	building_upgrade_tile = -1
	_persist_game()
	_refresh_ui()

func _resume_timed_upgrades() -> void:
	var now := int(Time.get_unix_time_from_system())
	if keep_upgrade_finish_unix > 0:
		var keep_remaining := keep_upgrade_finish_unix - now
		if keep_remaining > 0:
			upgrade_timer.start(float(keep_remaining))
		else:
			_finish_keep_upgrade()
	if building_upgrade_finish_unix > 0:
		var building_remaining := building_upgrade_finish_unix - now
		if building_remaining > 0:
			building_upgrade_timer.start(float(building_remaining))
		else:
			_finish_building_upgrade()

func _train_guard() -> void:
	if gold < 20 or food < 10:
		status_message = "Training needs 20 gold and 10 food."
	else:
		gold -= 20
		food -= 10
		guards += 1
		status_message = "A new guard joined your army."
		if guards >= 5:
			_award_achievement("five_guards", "Five Guards", 35)
		if tutorial_step == 2:
			_advance_tutorial(3)
	_refresh_ui()

func _scout() -> void:
	if guards < 5:
		status_message = "You need at least 5 guards to scout safely."
	elif outpost_defeated[selected_outpost] == 1:
		status_message = "This outpost is already captured. Select another region to explore."
	else:
		guards -= 1
		var reward := randi_range(35, 90) * keep_level
		gold += reward
		wood += randi_range(5, 18)
		if region_scouted[selected_outpost] == 0:
			region_scouted[selected_outpost] = 1
			status_message = "Scouting revealed Threat %d at Outpost %d. Found %d gold and supplies." % [outpost_threat[selected_outpost], selected_outpost + 1, reward]
		else:
			status_message = "The region is already mapped. Scouting party returned with %d gold and supplies." % reward
		_award_achievement("scout", "First Scout", 25)
	_refresh_ui()

func _attack_outpost() -> void:
	var threat := outpost_threat[selected_outpost]
	if outpost_defeated[selected_outpost] == 1:
		status_message = "This outpost is already captured. Select another target."
		_refresh_ui()
		return
	var required_guards := 3 + threat
	if guards < required_guards:
		status_message = "Outpost %d requires at least %d guards." % [selected_outpost + 1, required_guards]
		_refresh_ui()
		return
	guards -= required_guards
	var chance := clampi(65 - threat * 12 + keep_level * 6 + guards / 2 - (0 if region_scouted[selected_outpost] == 1 else 15), 10, 90)
	var won_attack := randi_range(1, 100) <= chance
	if is_instance_valid(world_view):
		world_view.play_attack(selected_outpost, won_attack)
	if won_attack:
		outpost_defeated[selected_outpost] = 1
		var reward := 100 * threat + keep_level * 25
		gold += reward
		food += 20 * threat
		status_message = "Victory at Outpost %d! Reward: %d gold and %d food." % [selected_outpost + 1, reward, 20 * threat]
		_award_achievement("outpost", "First Outpost", 50, 10)
		if outpost_defeated.count(1) == outpost_defeated.size():
			_award_achievement("all_outposts", "Realm Conqueror", 250, 100)
		if tutorial_step == 3:
			_advance_tutorial(4)
	else:
		status_message = "Attack failed at Outpost %d. Your guards lost the battle." % (selected_outpost + 1)
		if randi_range(0, 1) == 1:
			guards = max(0, guards - 1)
	_refresh_ui()

func _on_production_tick() -> void:
	for i in range(tiles.size()):
		match tiles[i]:
			"Farm":
				food += 2 * keep_level * tile_levels[i]
			"Mine":
				gold += 2 * keep_level * tile_levels[i]
			"Keep":
				gold += keep_level
				wood += 1
	_refresh_ui()

func _save_game() -> void:
	var error := _persist_game()
	status_message = "Kingdom saved on this device." if error == OK else "Save failed: %s" % error
	_refresh_ui()

func _persist_game() -> int:
	last_saved_unix = int(Time.get_unix_time_from_system())
	if FileAccess.file_exists(SAVE_PATH):
		var previous_save := ConfigFile.new()
		if previous_save.load(SAVE_PATH) == OK:
			DirAccess.copy_absolute(ProjectSettings.globalize_path(SAVE_PATH), ProjectSettings.globalize_path(BACKUP_SAVE_PATH))
	var config := ConfigFile.new()
	config.set_value("kingdom", "gold", gold)
	config.set_value("kingdom", "wood", wood)
	config.set_value("kingdom", "food", food)
	config.set_value("kingdom", "guards", guards)
	config.set_value("kingdom", "keep_level", keep_level)
	config.set_value("kingdom", "selected_tile", selected_tile)
	config.set_value("kingdom", "tiles", tiles)
	config.set_value("kingdom", "tile_levels", tile_levels)
	config.set_value("kingdom", "outpost_threat", outpost_threat)
	config.set_value("kingdom", "outpost_defeated", outpost_defeated)
	config.set_value("kingdom", "region_scouted", region_scouted)
	config.set_value("kingdom", "selected_outpost", selected_outpost)
	config.set_value("kingdom", "tutorial_step", tutorial_step)
	config.set_value("kingdom", "achievements", achievements)
	config.set_value("kingdom", "keep_upgrade_finish_unix", keep_upgrade_finish_unix)
	config.set_value("kingdom", "building_upgrade_finish_unix", building_upgrade_finish_unix)
	config.set_value("kingdom", "building_upgrade_tile", building_upgrade_tile)
	config.set_value("kingdom", "saved_at", last_saved_unix)
	return config.save(SAVE_PATH)

func _load_game() -> void:
	var config := ConfigFile.new()
	var load_error := config.load(SAVE_PATH)
	if load_error != OK:
		load_error = config.load(BACKUP_SAVE_PATH)
		if load_error != OK:
			last_saved_unix = int(Time.get_unix_time_from_system())
			return
		status_message = "Recovered your kingdom from the backup save."
	gold = int(config.get_value("kingdom", "gold", gold))
	wood = int(config.get_value("kingdom", "wood", wood))
	food = int(config.get_value("kingdom", "food", food))
	guards = int(config.get_value("kingdom", "guards", guards))
	keep_level = int(config.get_value("kingdom", "keep_level", keep_level))
	selected_tile = clampi(int(config.get_value("kingdom", "selected_tile", selected_tile)), 0, tiles.size() - 1)
	var loaded_tiles = config.get_value("kingdom", "tiles", tiles)
	if loaded_tiles is Array and loaded_tiles.size() == tiles.size():
		tiles.clear()
		for building in loaded_tiles:
			tiles.append(str(building))
	var loaded_levels = config.get_value("kingdom", "tile_levels", tile_levels)
	if (loaded_levels is PackedInt32Array or loaded_levels is Array) and loaded_levels.size() == tile_levels.size():
		for i in range(tile_levels.size()):
			tile_levels[i] = clampi(int(loaded_levels[i]), 1, 99)
	var loaded_outposts = config.get_value("kingdom", "outpost_defeated", outpost_defeated)
	if (loaded_outposts is PackedInt32Array or loaded_outposts is Array) and loaded_outposts.size() == outpost_defeated.size():
		for i in range(outpost_defeated.size()):
			outpost_defeated[i] = 1 if int(loaded_outposts[i]) == 1 else 0
	var loaded_scouted = config.get_value("kingdom", "region_scouted", region_scouted)
	if (loaded_scouted is PackedInt32Array or loaded_scouted is Array) and loaded_scouted.size() == region_scouted.size():
		for i in range(region_scouted.size()):
			region_scouted[i] = 1 if int(loaded_scouted[i]) == 1 else 0
	selected_outpost = clampi(int(config.get_value("kingdom", "selected_outpost", selected_outpost)), 0, outpost_threat.size() - 1)
	tutorial_step = clampi(int(config.get_value("kingdom", "tutorial_step", tutorial_step)), 0, 4)
	var loaded_achievements = config.get_value("kingdom", "achievements", achievements)
	if loaded_achievements is PackedStringArray or loaded_achievements is Array:
		achievements.clear()
		for achievement in loaded_achievements:
			var achievement_id := str(achievement)
			if achievement_id in ["farm", "mine", "keep_upgrade", "building_upgrade", "five_guards", "scout", "outpost", "all_outposts"] and not achievements.has(achievement_id):
				achievements.append(achievement_id)
	keep_upgrade_finish_unix = int(config.get_value("kingdom", "keep_upgrade_finish_unix", 0))
	building_upgrade_finish_unix = int(config.get_value("kingdom", "building_upgrade_finish_unix", 0))
	building_upgrade_tile = int(config.get_value("kingdom", "building_upgrade_tile", -1))
	last_saved_unix = int(config.get_value("kingdom", "saved_at", Time.get_unix_time_from_system()))
	_normalize_save_data()
	_apply_offline_production(false)

func _normalize_save_data() -> void:
	gold = maxi(gold, 0)
	wood = maxi(wood, 0)
	food = maxi(food, 0)
	guards = clampi(guards, 0, 100000)
	keep_level = clampi(keep_level, 1, 99)
	selected_tile = clampi(selected_tile, 0, tiles.size() - 1)
	selected_outpost = clampi(selected_outpost, 0, outpost_threat.size() - 1)
	tutorial_step = clampi(tutorial_step, 0, 4)
	var valid_buildings := ["Empty", "Farm", "Mine", "Keep", "Barracks"]
	for i in range(tiles.size()):
		if not valid_buildings.has(tiles[i]):
			tiles[i] = "Empty"
		tile_levels[i] = clampi(tile_levels[i], 1, 99)
	tiles[4] = "Keep"
	for i in range(outpost_defeated.size()):
		outpost_defeated[i] = 1 if outpost_defeated[i] == 1 else 0
		region_scouted[i] = 1 if region_scouted[i] == 1 else 0
	if keep_upgrade_finish_unix < 0:
		keep_upgrade_finish_unix = 0
	if building_upgrade_finish_unix < 0:
		building_upgrade_finish_unix = 0
	if building_upgrade_tile < -1 or building_upgrade_tile >= tiles.size():
		building_upgrade_tile = -1

func _apply_offline_production(refresh_after: bool) -> void:
	var now := int(Time.get_unix_time_from_system())
	var elapsed := clampi(now - last_saved_unix, 0, MAX_OFFLINE_SECONDS)
	var ticks := int(elapsed / int(TICK_SECONDS))
	for i in range(tiles.size()):
		match tiles[i]:
			"Farm":
				food += 2 * keep_level * tile_levels[i] * ticks
			"Mine":
				gold += 2 * keep_level * tile_levels[i] * ticks
			"Keep":
				gold += keep_level * ticks
				wood += ticks
	if elapsed >= 10:
		status_message = "Welcome back. Offline production was capped at 8 hours."
	_persist_game()
	if refresh_after:
		_refresh_ui()
