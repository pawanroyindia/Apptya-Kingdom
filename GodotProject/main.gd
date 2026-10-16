extends Control

const SAVE_PATH := "user://apptya_kingdom_save.cfg"
const MAX_OFFLINE_SECONDS := 28800
const TICK_SECONDS := 10.0

var gold := 300
var wood := 150
var food := 120
var guards := 10
var keep_level := 1
var selected_tile := 4
var last_saved_unix := 0
var tiles: Array[String] = ["Empty", "Farm", "Empty", "Mine", "Keep", "Empty", "Empty", "Barracks", "Empty"]
var status_message := "Your kingdom awaits your command."
var resource_labels: Dictionary = {}
var tile_buttons: Array[Button] = []
var keep_label: Label
var guard_label: Label
var status_label: Label
var tick_timer: Timer

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
		{"text": "Battle Raiders\n5 guards", "action": _battle},
		{"text": "Save Kingdom", "action": _save_game}
	])

	var status_panel := PanelContainer.new()
	status_panel.add_theme_stylebox_override("panel", _panel_style("#26392f"))
	column.add_child(status_panel)
	status_label = Label.new()
	status_label.text = status_message
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size = Vector2(0, 44)
	status_panel.add_child(status_label)

func _add_button_row(parent: VBoxContainer, definitions: Array) -> void:
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
		keep_label.text = "Keep level: %d   •   Selected tile: %d" % [keep_level, selected_tile + 1]
		guard_label.text = "Trained guards: %d" % guards
		for i in range(tile_buttons.size()):
			var prefix := "▶ " if i == selected_tile else ""
			tile_buttons[i].text = "%s%s\nTile %d" % [prefix, tiles[i], i + 1]
			tile_buttons[i].modulate = Color("#f4d994") if i == selected_tile else Color("#ffffff")
		status_label.text = status_message

func _select_tile(index: int) -> void:
	selected_tile = index
	status_message = "Selected tile %d: %s." % [index + 1, tiles[index]]
	_refresh_ui()

func _build_farm() -> void:
	if not _can_build("Farm", 50, 10):
		return
	tiles[selected_tile] = "Farm"
	gold -= 50
	wood -= 10
	status_message = "Farm built. It produces food over time."

func _build_mine() -> void:
	if not _can_build("Mine", 70, 20):
		return
	tiles[selected_tile] = "Mine"
	gold -= 70
	wood -= 20
	status_message = "Mine built. It produces gold over time."

func _build_barracks() -> void:
	if not _can_build("Barracks", 80, 30):
		return
	tiles[selected_tile] = "Barracks"
	gold -= 80
	wood -= 30
	status_message = "Barracks built. Train guards to protect your realm."

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
	var gold_cost := 100 * keep_level
	var wood_cost := 50 * keep_level
	if gold < gold_cost or wood < wood_cost:
		status_message = "Keep upgrade needs %d gold and %d wood." % [gold_cost, wood_cost]
		_refresh_ui()
		return
	gold -= gold_cost
	wood -= wood_cost
	keep_level += 1
	status_message = "Keep upgraded to level %d. Production is stronger." % keep_level
	_refresh_ui()

func _train_guard() -> void:
	if gold < 20 or food < 10:
		status_message = "Training needs 20 gold and 10 food."
	else:
		gold -= 20
		food -= 10
		guards += 1
		status_message = "A new guard joined your army."
	_refresh_ui()

func _scout() -> void:
	if guards < 5:
		status_message = "You need at least 5 guards to scout safely."
	else:
		guards -= 1
		var reward := randi_range(35, 90) * keep_level
		gold += reward
		wood += randi_range(5, 18)
		status_message = "Scouting succeeded. Found %d gold and supplies." % reward
	_refresh_ui()

func _battle() -> void:
	if guards < 5:
		status_message = "You need at least 5 guards to challenge the raiders."
	else:
		guards -= 5
		if randi_range(0, 100) < min(85, 45 + keep_level * 5):
			var reward := 100 + keep_level * 25
			gold += reward
			food += 35
			status_message = "Victory! Raiders defeated; gained %d gold and 35 food." % reward
		else:
			gold = max(0, gold - 35)
			status_message = "The raiders escaped. Your army lost supplies."
	_refresh_ui()

func _on_production_tick() -> void:
	for building in tiles:
		match building:
			"Farm":
				food += 2 * keep_level
			"Mine":
				gold += 2 * keep_level
			"Keep":
				gold += keep_level
				wood += 1
	_refresh_ui()

func _save_game() -> void:
	var config := ConfigFile.new()
	config.set_value("kingdom", "gold", gold)
	config.set_value("kingdom", "wood", wood)
	config.set_value("kingdom", "food", food)
	config.set_value("kingdom", "guards", guards)
	config.set_value("kingdom", "keep_level", keep_level)
	config.set_value("kingdom", "selected_tile", selected_tile)
	config.set_value("kingdom", "tiles", tiles)
	config.set_value("kingdom", "saved_at", int(Time.get_unix_time_from_system()))
	var error := config.save(SAVE_PATH)
	status_message = "Kingdom saved on this device." if error == OK else "Save failed: %s" % error
	_refresh_ui()

func _load_game() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		last_saved_unix = int(Time.get_unix_time_from_system())
		return
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
	last_saved_unix = int(config.get_value("kingdom", "saved_at", Time.get_unix_time_from_system()))
	var elapsed := clampi(int(Time.get_unix_time_from_system()) - last_saved_unix, 0, MAX_OFFLINE_SECONDS)
	var ticks := int(elapsed / int(TICK_SECONDS))
	for building in tiles:
		match building:
			"Farm":
				food += 2 * keep_level * ticks
			"Mine":
				gold += 2 * keep_level * ticks
			"Keep":
				gold += keep_level * ticks
				wood += ticks
	if elapsed >= 10:
		status_message = "Welcome back. Offline production was capped at 8 hours."
