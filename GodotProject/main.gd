extends Control

const SAVE_PATH := "user://apptya_kingdom_save.cfg"
const BACKUP_SAVE_PATH := "user://apptya_kingdom_save_backup.cfg"
const MAX_OFFLINE_SECONDS := 28800
const TICK_SECONDS := 10.0
const COMBAT_DIRECTOR = preload("res://combat_director.gd")

var gold := 300
var wood := 150
var food := 120
var stone := 80
var guards := 4
var infantry := 4
var archers := 0
var cavalry := 0
var queued_troop_type := ""
var queued_troop_count := 0
var troop_training_finish_unix := 0
var keep_level := 1
var day := 1
var daily_reward_claim_day := -1
var daily_reward_streak := 0
var enemy_level := 1
var explored_regions := 0
var victories := 0
var defeats := 0
var combat_research := 0
var economy_research := 0
var scouting_research := 0
var practice_drills := 0
var reward_first_victory_claimed := false
var reward_explorer_claimed := false
var reward_keep_claimed := false
var quest_builder_claimed := false
var quest_stronghold_claimed := false
var quest_conqueror_claimed := false
var hero_level := 1
var hero_xp := 0
var hero_skill_level := 1
var selected_tile := 4
var selected_outpost := 0
var last_saved_unix := 0
var keep_upgrade_finish_unix := 0
var building_upgrade_finish_unix := 0
var building_upgrade_tile := -1
var tutorial_step := 0
var tiles: Array[String] = ["Empty", "Farm", "Empty", "Mine", "Keep", "Empty", "Lumber Camp", "Barracks", "Quarry"]
var tile_levels := PackedInt32Array([1, 1, 1, 1, 1, 1, 1, 1, 1])
var outpost_threat := PackedInt32Array([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
var outpost_defeated := PackedInt32Array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
var region_scouted := PackedInt32Array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
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
var campaign_label: Label
var quest_label: Label
var daily_reward_label: Label
var daily_reward_buttons: Array[Button] = []
var hero_label: Label
var tick_timer: Timer
var autosave_timer: Timer
var upgrade_timer: Timer
var building_upgrade_timer: Timer
var troop_training_timer: Timer
var world_view: Node3D
var world_viewport: SubViewport
var graphics_quality := "Balanced"
var sound_enabled := true
var music_enabled := true
var sound_player: AudioStreamPlayer
var music_player: AudioStreamPlayer
var music_stream: AudioStreamWAV
var sound_streams: Dictionary = {}
var settings_buttons: Array[Button] = []
var music_settings_buttons: Array[Button] = []
var network_session: Node
var network_address_input: LineEdit
var network_status_label: Label
var network_controls: Array[Button] = []

func _ready() -> void:
	_load_game()
	_setup_audio()
	network_session = preload("res://network_session.gd").new()
	network_session.name = "NetworkSession"
	add_child(network_session)
	network_session.configure(self)
	network_session.status_changed.connect(_on_network_status_changed)
	_build_ui()
	_refresh_ui()
	tick_timer = Timer.new()
	tick_timer.wait_time = TICK_SECONDS
	tick_timer.one_shot = false
	tick_timer.timeout.connect(_on_production_tick)
	add_child(tick_timer)
	tick_timer.start()
	autosave_timer = Timer.new()
	autosave_timer.wait_time = 60.0
	autosave_timer.one_shot = false
	autosave_timer.timeout.connect(_on_autosave_tick)
	add_child(autosave_timer)
	autosave_timer.start()
	upgrade_timer = Timer.new()
	upgrade_timer.one_shot = true
	upgrade_timer.timeout.connect(_finish_keep_upgrade)
	add_child(upgrade_timer)
	building_upgrade_timer = Timer.new()
	building_upgrade_timer.one_shot = true
	building_upgrade_timer.timeout.connect(_finish_building_upgrade)
	add_child(building_upgrade_timer)
	troop_training_timer = Timer.new()
	troop_training_timer.one_shot = true
	troop_training_timer.timeout.connect(_finish_troop_training)
	add_child(troop_training_timer)
	_resume_timed_upgrades()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		_persist_game()
		if is_instance_valid(music_player):
			music_player.stop()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		if not (is_instance_valid(network_session) and network_session.is_client_connected()):
			_apply_offline_production(true)
		_resume_timed_upgrades()
		if music_enabled and is_instance_valid(music_player):
			music_player.play()

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
	world_viewport = SubViewport.new()
	world_viewport.size = Vector2i(640, 360)
	world_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	world_viewport.gui_disable_input = true
	world_container.add_child(world_viewport)
	world_view = load("res://kingdom_world.tscn").instantiate() as Node3D
	world_viewport.add_child(world_view)
	world_view.connect("tile_selected", Callable(self, "_select_tile"))
	_apply_graphics_quality()
	_add_button_row(column, [
		{"text": "Cycle Graphics Quality", "action": _cycle_graphics_quality},
		{"text": "Reset Camera", "action": _reset_camera},
		{"text": "Sound: ON", "action": _toggle_sound}
	], settings_buttons)
	_add_button_row(column, [
		{"text": "Music: ON", "action": _toggle_music}
	], music_settings_buttons)

	var network_header := Label.new()
	network_header.text = "LAN CO-OP • SAME WI-FI"
	network_header.add_theme_font_size_override("font_size", 18)
	network_header.add_theme_color_override("font_color", Color("#f1d38a"))
	column.add_child(network_header)
	network_address_input = LineEdit.new()
	network_address_input.placeholder_text = "Host local IP (example: 192.168.1.10)"
	network_address_input.clear_button_enabled = true
	network_address_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(network_address_input)
	_add_button_row(column, [
		{"text": "Host LAN Game", "action": _host_lan_game},
		{"text": "Join Host IP", "action": _join_lan_game},
		{"text": "Disconnect", "action": _disconnect_lan_game}
	], network_controls)
	network_status_label = Label.new()
	network_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	network_status_label.add_theme_color_override("font_color", Color("#c3d2c7"))
	network_status_label.text = "Offline. Host and guest must be on the same Wi-Fi; UDP port 24567 must be reachable."
	column.add_child(network_status_label)

	var resource_panel := PanelContainer.new()
	resource_panel.add_theme_stylebox_override("panel", _panel_style("#243a30"))
	column.add_child(resource_panel)
	var resource_box := VBoxContainer.new()
	resource_box.add_theme_constant_override("separation", 5)
	resource_panel.add_child(resource_box)
	for key in ["gold", "wood", "food", "stone"]:
		var label := Label.new()
		label.add_theme_font_size_override("font_size", 17)
		label.add_theme_color_override("font_color", Color("#fff2d2"))
		resource_box.add_child(label)
		resource_labels[key] = label

	_add_button_row(column, [
		{"text": "Gather Wood +25", "action": _gather_resource.bind("wood", 25)},
		{"text": "Harvest Food +30", "action": _gather_resource.bind("food", 30)}
	])
	_add_button_row(column, [
		{"text": "Mine Stone +15", "action": _gather_resource.bind("stone", 15)},
		{"text": "Collect Gold +20", "action": _gather_resource.bind("gold", 20)}
	])

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
		{"text": "Collect Selected", "action": _collect_selected_building}
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
		{"text": "Upgrade Keep\n100 gold, 50 wood, 45 stone", "action": _upgrade_keep}
	])
	_add_button_row(column, [
		{"text": "Build Lumber Camp\n60 gold, 15 wood", "action": _build_lumber_camp},
		{"text": "Build Quarry\n70 gold, 25 wood", "action": _build_quarry}
	])
	_add_button_row(column, [
		{"text": "Build Academy\n120 gold, 45 wood", "action": _build_academy}
	])

	var outpost_title := Label.new()
	outpost_title.text = "ENEMY OUTPOSTS"
	outpost_title.add_theme_font_size_override("font_size", 18)
	outpost_title.add_theme_color_override("font_color", Color("#f1d38a"))
	column.add_child(outpost_title)
	outpost_label = Label.new()
	outpost_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(outpost_label)
	for row_start in range(0, outpost_threat.size(), 3):
		var outpost_definitions: Array = []
		for i in range(row_start, mini(row_start + 3, outpost_threat.size())):
			outpost_definitions.append({"text": "Outpost %d\nThreat %d" % [i + 1, outpost_threat[i]], "action": _select_outpost.bind(i)})
		_add_button_row(column, outpost_definitions, outpost_buttons)

	var army_title := Label.new()
	army_title.text = "ARMY & EXPLORATION"
	army_title.add_theme_font_size_override("font_size", 18)
	army_title.add_theme_color_override("font_color", Color("#f1d38a"))
	column.add_child(army_title)
	_add_button_row(column, [
		{"text": "Queue Infantry\n10 gold, 25 food", "action": _train_guard},
		{"text": "Queue Archers\n15 gold, 35 food", "action": _queue_archers}
	])
	_add_button_row(column, [
		{"text": "Queue Cavalry\n25 gold, 45 food", "action": _queue_cavalry},
		{"text": "Scout Region\n1 guard", "action": _scout}
	])
	_add_button_row(column, [
		{"text": "Attack Selected Outpost\n3+ guards", "action": _attack_outpost},
		{"text": "Save Kingdom", "action": _save_game}
	])

	var campaign_title := Label.new()
	campaign_title.text = "RESEARCH & CAMPAIGN"
	campaign_title.add_theme_font_size_override("font_size", 18)
	campaign_title.add_theme_color_override("font_color", Color("#f1d38a"))
	column.add_child(campaign_title)
	campaign_label = Label.new()
	campaign_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	campaign_label.add_theme_color_override("font_color", Color("#c3d2c7"))
	column.add_child(campaign_label)
	_add_button_row(column, [
		{"text": "Research Combat", "action": _research.bind("combat")},
		{"text": "Research Economy", "action": _research.bind("economy")},
		{"text": "Research Scouting", "action": _research.bind("scouting")}
	])
	_add_button_row(column, [
		{"text": "Explore Region\n1 guard", "action": _explore_region},
		{"text": "Practice Troops", "action": _practice_troops}
	])
	_add_button_row(column, [
		{"text": "Attack Enemy Army\nPower vs power", "action": _attack_enemy_army},
		{"text": "Claim Victory Reward", "action": _claim_reward.bind("first_victory")}
	])
	_add_button_row(column, [
		{"text": "Claim Explorer Reward", "action": _claim_reward.bind("explorer")},
		{"text": "Claim Keep Reward", "action": _claim_reward.bind("keep_builder")}
	])

	var hero_title := Label.new()
	hero_title.text = "ROYAL HERO"
	hero_title.add_theme_font_size_override("font_size", 18)
	hero_title.add_theme_color_override("font_color", Color("#f1d38a"))
	column.add_child(hero_title)
	hero_label = Label.new()
	hero_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hero_label.add_theme_color_override("font_color", Color("#c3d2c7"))
	column.add_child(hero_label)
	_add_button_row(column, [
		{"text": "Train Hero\n25 gold, 25 food", "action": _train_hero},
		{"text": "Upgrade Hero Skill\nGold + stone", "action": _upgrade_hero_skill}
	])

	var quest_title := Label.new()
	quest_title.text = "QUEST BOARD"
	quest_title.add_theme_font_size_override("font_size", 18)
	quest_title.add_theme_color_override("font_color", Color("#f1d38a"))
	column.add_child(quest_title)
	quest_label = Label.new()
	quest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quest_label.add_theme_color_override("font_color", Color("#c3d2c7"))
	column.add_child(quest_label)
	_add_button_row(column, [
		{"text": "Claim Builder Quest", "action": _claim_quest.bind("builder")},
		{"text": "Claim Stronghold Quest", "action": _claim_quest.bind("stronghold")}
	])
	_add_button_row(column, [
		{"text": "Claim Conqueror Quest", "action": _claim_quest.bind("conqueror")}
	])
	var daily_title := Label.new()
	daily_title.text = "DAILY KINGDOM REWARD"
	daily_title.add_theme_font_size_override("font_size", 18)
	daily_title.add_theme_color_override("font_color", Color("#f1d38a"))
	column.add_child(daily_title)
	var daily_description := Label.new()
	daily_description.text = "Claim once per real-world day. Consecutive days build a 7-day reward streak."
	daily_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(daily_description)
	daily_reward_label = Label.new()
	daily_reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	daily_reward_label.add_theme_color_override("font_color", Color("#c3d2c7"))
	column.add_child(daily_reward_label)
	_add_button_row(column, [
		{"text": "Claim Daily Reward", "action": _claim_daily_reward}
	], daily_reward_buttons)

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
		resource_labels["stone"].text = "🪨 Stone: %d" % stone
		var upgrade_text := ""
		if keep_upgrade_finish_unix > int(Time.get_unix_time_from_system()):
			upgrade_text = "   •   Keep upgrade: %ds" % (keep_upgrade_finish_unix - int(Time.get_unix_time_from_system()))
		keep_label.text = "Day %d   •   Keep level: %d   •   Selected tile: %d%s" % [day, keep_level, selected_tile + 1, upgrade_text]
		var training_status := "Training queue idle" if queued_troop_count <= 0 else "%d %s in training • %ds" % [queued_troop_count, queued_troop_type, maxi(0, troop_training_finish_unix - int(Time.get_unix_time_from_system()))]
		guard_label.text = "Guards: %d (I:%d A:%d C:%d) • %s • Wins: %d / Losses: %d" % [guards, infantry, archers, cavalry, training_status, victories, defeats]
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
			elif tiles[selected_tile] == "Lumber Camp":
				production = "Wood production: %d per tick" % (2 * keep_level * tile_levels[selected_tile])
			elif tiles[selected_tile] == "Quarry":
				production = "Stone production: %d per tick" % (2 * keep_level * tile_levels[selected_tile])
			elif tiles[selected_tile] == "Keep":
				production = "Keep produces %d gold and 1 wood per tick" % keep_level
			elif tiles[selected_tile] == "Academy":
				production = "Research discount: %d%% on all research costs" % int(minf(0.25, float(tile_levels[selected_tile]) * 0.05) * 100.0)
			var upgrade_note := ""
			if building_upgrade_finish_unix > int(Time.get_unix_time_from_system()) and building_upgrade_tile == selected_tile:
				upgrade_note = " Building upgrade completes in %ds." % (building_upgrade_finish_unix - int(Time.get_unix_time_from_system()))
			tile_detail_label.text = "Selected: %s (Level %d) on tile %d. %s%s" % [tiles[selected_tile], tile_levels[selected_tile], selected_tile + 1, production, upgrade_note]
		for i in range(outpost_buttons.size()):
			var region_status := " • Captured" if outpost_defeated[i] == 1 else (" • Locked" if i > 0 and outpost_defeated[i - 1] != 1 else (" • Scouted" if region_scouted[i] == 1 else " • Unknown"))
			outpost_buttons[i].text = "%sOutpost %d%s" % ["▶ " if i == selected_outpost else "", i + 1, region_status]
		outpost_label.text = _get_outpost_description()
		tutorial_label.text = _get_tutorial_text()
		achievements_label.text = "Achievements: %d/8 — %s" % [achievements.size(), ", ".join(achievements) if not achievements.is_empty() else "none yet"]
		var captured_outposts := 0
		for defeated in outpost_defeated:
			captured_outposts += 1 if defeated == 1 else 0
		var campaign_progress := "CAMPAIGN COMPLETE" if captured_outposts >= outpost_defeated.size() else "Outposts captured: %d/%d" % [captured_outposts, outpost_defeated.size()]
		campaign_label.text = "%s\nArmy power %d • Enemy power %d (Lv %d)\nExplored: %d regions • Combat %d/5 • Economy %d/5 • Scouting %d/5 • Drills %d/20\nGraphics: %s • Sound: %s • Music: %s" % [campaign_progress, _army_power(), _enemy_power(), enemy_level, explored_regions, combat_research, economy_research, scouting_research, practice_drills, graphics_quality, "ON" if sound_enabled else "OFF", "ON" if music_enabled else "OFF"]
		if not settings_buttons.is_empty():
			settings_buttons[2].text = "Sound: ON" if sound_enabled else "Sound: OFF"
		if not music_settings_buttons.is_empty():
			music_settings_buttons[0].text = "Music: ON" if music_enabled else "Music: OFF"
		var current_utc_day := int(floor(float(Time.get_unix_time_from_system()) / 86400.0))
		var claimed_today := daily_reward_claim_day == current_utc_day
		var seconds_to_reset := 86400 - int(Time.get_unix_time_from_system()) % 86400
		daily_reward_label.text = "Streak: %d/7 • %s • Next reset in %02d:%02d:%02d" % [daily_reward_streak, "CLAIMED TODAY" if claimed_today else "READY TO CLAIM", seconds_to_reset / 3600, (seconds_to_reset % 3600) / 60, seconds_to_reset % 60]
		if not daily_reward_buttons.is_empty():
			daily_reward_buttons[0].text = "Reward Claimed Today" if claimed_today else "Claim Daily Reward"
		var highest_building_level := 1
		for i in range(tiles.size()):
			if tiles[i] in ["Farm", "Mine", "Lumber Camp", "Quarry", "Barracks", "Academy"]:
				highest_building_level = maxi(highest_building_level, tile_levels[i])
		quest_label.text = "1. Builder's Mark: upgrade a building to level 2 (%s)\n2. Royal Stronghold: upgrade Keep to level 3 (%s)\n3. Frontier Conqueror: capture 3 outposts (%d/3)\nRewards are one-time and persist with your save." % ["CLAIMED" if quest_builder_claimed else ("READY" if highest_building_level >= 2 else "LOCKED"), "CLAIMED" if quest_stronghold_claimed else ("READY" if keep_level >= 3 else "LOCKED"), captured_outposts]
		var hero_progress := "MAX XP" if hero_level >= 20 else "XP %d/%d" % [hero_xp, hero_level * 100]
		hero_label.text = "Royal Captain • Level %d/20 • %s • Skill %d/5 • Hero power %d" % [hero_level, hero_progress, hero_skill_level, _hero_power()]
		if is_instance_valid(world_view):
			world_view.set_kingdom_state(tiles, tile_levels, keep_level, guards, infantry, archers, cavalry, outpost_defeated, region_scouted, selected_outpost, selected_tile)
			world_view.set_hero_level(hero_level)
		status_label.text = status_message
	if is_instance_valid(network_session) and network_session.is_network_active() and multiplayer.is_server():
		network_session.publish_snapshot()

func _on_network_status_changed(message: String) -> void:
	if is_instance_valid(network_status_label):
		network_status_label.text = message
	if is_instance_valid(status_label):
		status_label.text = message

func _host_lan_game() -> void:
	if is_instance_valid(network_session):
		network_session.host_game()

func _join_lan_game() -> void:
	if is_instance_valid(network_session):
		network_session.join_game(network_address_input.text if is_instance_valid(network_address_input) else "")

func _disconnect_lan_game() -> void:
	if is_instance_valid(network_session):
		network_session.disconnect_game()

func _route_network_action(action: String, payload: Dictionary = {}) -> bool:
	if is_instance_valid(network_session) and network_session.is_client_connected():
		var request := payload.duplicate(true)
		if not request.has("tile"):
			request["tile"] = selected_tile
		if not request.has("outpost"):
			request["outpost"] = selected_outpost
		network_session.request_host_action(action, request)
		status_message = "Sent %s request to the host." % action.replace("_", " ")
		_refresh_ui()
		return true
	return false

func _setup_audio() -> void:
	sound_player = AudioStreamPlayer.new()
	sound_player.bus = "Master"
	add_child(sound_player)
	sound_streams = {
		"gather": _make_tone(660.0, 0.09),
		"build": _make_tone(440.0, 0.14),
		"victory": _make_tone(880.0, 0.22),
		"defeat": _make_tone(180.0, 0.20),
		"train": _make_tone(520.0, 0.11)
	}
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	music_player.volume_db = -20.0
	add_child(music_player)
	music_stream = _make_ambient_music()
	music_player.stream = music_stream
	if music_enabled:
		music_player.play()

func _make_tone(frequency: float, duration: float) -> AudioStreamWAV:
	const SAMPLE_RATE := 22050
	var sample_count := int(SAMPLE_RATE * duration)
	var pcm := PackedByteArray()
	pcm.resize(sample_count * 2)
	for i in range(sample_count):
		var t := float(i) / SAMPLE_RATE
		var envelope := maxf(0.0, minf(minf(1.0, t * 50.0), minf(1.0, (duration - t) * 18.0)))
		var sample := sin(TAU * frequency * t) * envelope * 0.22
		pcm.encode_s16(i * 2, int(sample * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = pcm
	return stream

func _make_ambient_music() -> AudioStreamWAV:
	const SAMPLE_RATE := 11025
	const LOOP_SECONDS := 16.0
	var sample_count := int(SAMPLE_RATE * LOOP_SECONDS)
	var pcm := PackedByteArray()
	pcm.resize(sample_count * 2)
	var chord_roots := [110.0, 87.31, 98.0, 73.42]
	var chord_fifths := [164.81, 130.81, 146.83, 110.0]
	var chord_octaves := [220.0, 174.61, 196.0, 146.83]
	var melody := [440.0, 0.0, 392.0, 0.0, 329.63, 0.0, 392.0, 0.0, 349.23, 0.0, 293.66, 0.0, 329.63, 0.0, 261.63, 0.0, 392.0, 0.0, 349.23, 0.0, 293.66, 0.0, 329.63, 0.0, 440.0, 0.0, 392.0, 0.0, 329.63, 0.0, 293.66, 0.0]
	for i in range(sample_count):
		var t := float(i) / SAMPLE_RATE
		var chord_index := mini(int(t / 4.0), 3)
		var pad := sin(TAU * chord_roots[chord_index] * t) * 0.075
		pad += sin(TAU * chord_fifths[chord_index] * t) * 0.045
		pad += sin(TAU * chord_octaves[chord_index] * t) * 0.035
		var beat_position := fposmod(t, 0.5)
		var melody_index := mini(int(t / 0.5), melody.size() - 1)
		var melody_frequency: float = melody[melody_index]
		var envelope := minf(1.0, beat_position * 10.0) * minf(1.0, (0.5 - beat_position) * 5.0)
		var lead := sin(TAU * melody_frequency * t) * envelope * 0.045 if melody_frequency > 0.0 else 0.0
		var sample := clampf(pad + lead, -0.8, 0.8)
		pcm.encode_s16(i * 2, int(sample * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = pcm
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	return stream

func _toggle_music() -> void:
	music_enabled = not music_enabled
	if is_instance_valid(music_player):
		if music_enabled:
			music_player.play()
		else:
			music_player.stop()
	status_message = "Ambient music enabled." if music_enabled else "Ambient music muted."
	_persist_game()
	_refresh_ui()

func _play_sound(sound_id: String) -> void:
	if not sound_enabled or not is_instance_valid(sound_player) or not sound_streams.has(sound_id):
		return
	sound_player.stream = sound_streams[sound_id]
	sound_player.play()

func _toggle_sound() -> void:
	sound_enabled = not sound_enabled
	status_message = "Sound effects enabled." if sound_enabled else "Sound effects muted."
	_persist_game()
	_refresh_ui()
	if sound_enabled:
		_play_sound("gather")

func _cycle_graphics_quality() -> void:
	match graphics_quality:
		"Low":
			graphics_quality = "Balanced"
		"Balanced":
			graphics_quality = "High"
		_:
			graphics_quality = "Low"
	_apply_graphics_quality()
	status_message = "Graphics quality set to %s." % graphics_quality
	_persist_game()
	_refresh_ui()

func _apply_graphics_quality() -> void:
	if is_instance_valid(world_viewport):
		# Keep the SubViewportContainer stretched to the phone layout; scale only its 3D render resolution.
		match graphics_quality:
			"Low":
				world_viewport.scaling_3d_scale = 0.75
			"High":
				world_viewport.scaling_3d_scale = 1.25
			_:
				world_viewport.scaling_3d_scale = 1.0
	if is_instance_valid(world_view) and world_view.has_method("set_quality_preset"):
		world_view.set_quality_preset(graphics_quality)

func _reset_camera() -> void:
	if is_instance_valid(world_view) and world_view.has_method("reset_camera"):
		world_view.reset_camera()
		status_message = "Camera view reset."
	else:
		status_message = "Camera is not ready yet."
	_refresh_ui()

func _gather_resource(resource_type: String, amount: int) -> void:
	if _route_network_action("gather", {"resource": resource_type, "amount": amount}):
		return
	if amount <= 0:
		status_message = "Gathering amount must be positive."
		_refresh_ui()
		return
	match resource_type:
		"wood":
			wood += amount
			status_message = "Lumber crew gathered %d wood." % amount
		"food":
			food += amount
			status_message = "Harvest crew gathered %d food." % amount
		"stone":
			stone += amount
			status_message = "Quarry crew gathered %d stone." % amount
		"gold":
			gold += amount
			status_message = "Treasury collected %d gold." % amount
		_:
			status_message = "Unknown resource type."
			_refresh_ui()
			return
	_play_sound("gather")
	_persist_game()
	_refresh_ui()

func _select_tile(index: int) -> void:
	if _route_network_action("select_tile", {"tile": index}):
		return
	if index < 0 or index >= tiles.size():
		status_message = "That kingdom tile is outside the map."
		_refresh_ui()
		return
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
	if selected_outpost > 0 and outpost_defeated[selected_outpost - 1] != 1:
		return "Outpost %d is locked. Capture Outpost %d first to advance the campaign." % [selected_outpost + 1, selected_outpost]
	if region_scouted[selected_outpost] != 1:
		return "Target: Outpost %d. This region is unexplored. Scout it to reveal enemy threat before attacking." % (selected_outpost + 1)
	var battle: Dictionary = COMBAT_DIRECTOR.resolve_outpost(infantry, archers, cavalry, _hero_power(), combat_research, practice_drills, keep_level, _get_barracks_level(), threat, selected_outpost, true)
	return "Scouted target: Outpost %d • %s • Enemy power %d • Estimated success chance %d%% • Guards required: %d" % [selected_outpost + 1, battle["trait"], battle["enemy_power"], battle["chance"], 3 + threat]

func _select_outpost(index: int) -> void:
	if _route_network_action("select_outpost", {"outpost": index}):
		return
	selected_outpost = clampi(index, 0, outpost_threat.size() - 1)
	status_message = "Targeting enemy outpost %d." % (selected_outpost + 1)
	_refresh_ui()

func _build_farm() -> void:
	if _route_network_action("build_farm"):
		return
	if not _can_build("Farm", 50, 10):
		return
	tiles[selected_tile] = "Farm"
	gold -= 50
	wood -= 10
	status_message = "Farm built. It produces food over time."
	_award_achievement("farm", "First Farm", 20)
	if tutorial_step == 0:
		_advance_tutorial(1)
	_persist_game()
	_refresh_ui()

func _build_mine() -> void:
	if _route_network_action("build_mine"):
		return
	if not _can_build("Mine", 70, 20):
		return
	tiles[selected_tile] = "Mine"
	gold -= 70
	wood -= 20
	status_message = "Mine built. It produces gold over time."
	_award_achievement("mine", "First Mine", 20)
	if tutorial_step == 1:
		_advance_tutorial(2)
	_persist_game()
	_refresh_ui()

func _build_lumber_camp() -> void:
	if _route_network_action("build_lumber_camp"):
		return
	if not _can_build("Lumber Camp", 60, 15):
		return
	tiles[selected_tile] = "Lumber Camp"
	gold -= 60
	wood -= 15
	status_message = "Lumber Camp built. It produces wood over time."
	_persist_game()
	_refresh_ui()

func _build_quarry() -> void:
	if _route_network_action("build_quarry"):
		return
	if not _can_build("Quarry", 70, 25):
		return
	tiles[selected_tile] = "Quarry"
	gold -= 70
	wood -= 25
	status_message = "Quarry built. It produces stone over time."
	_persist_game()
	_refresh_ui()

func _build_academy() -> void:
	if _route_network_action("build_academy"):
		return
	if not _can_build("Academy", 120, 45):
		return
	tiles[selected_tile] = "Academy"
	gold -= 120
	wood -= 45
	status_message = "Academy built. Each Academy level reduces research costs by 5%, up to 25%."
	_play_sound("build")
	_persist_game()
	_refresh_ui()

func _get_academy_level() -> int:
	var level := 0
	for i in range(tiles.size()):
		if tiles[i] == "Academy":
			level = maxi(level, tile_levels[i])
	return level

func _build_barracks() -> void:
	if _route_network_action("build_barracks"):
		return
	if not _can_build("Barracks", 80, 30):
		return
	tiles[selected_tile] = "Barracks"
	gold -= 80
	wood -= 30
	status_message = "Barracks built. Train guards to protect your realm."
	_persist_game()
	_refresh_ui()

func _can_build(building: String, gold_cost: int, wood_cost: int) -> bool:
	if building == "Academy" and tiles.has("Academy"):
		status_message = "Your kingdom can have one Academy. Select it and use Upgrade Selected to improve its research discount."
		_refresh_ui()
		return false
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
	if _route_network_action("upgrade_keep"):
		return
	if keep_upgrade_finish_unix > int(Time.get_unix_time_from_system()):
		status_message = "Keep upgrade is already in progress."
		_refresh_ui()
		return
	var gold_cost := 100 * keep_level
	var wood_cost := 50 * keep_level
	var stone_cost := 45 * keep_level
	if keep_level >= 10:
		status_message = "Keep has reached the maximum level 10."
		_refresh_ui()
		return
	if gold < gold_cost or wood < wood_cost or stone < stone_cost:
		status_message = "Keep upgrade needs %d gold, %d wood and %d stone." % [gold_cost, wood_cost, stone_cost]
		_refresh_ui()
		return
	gold -= gold_cost
	wood -= wood_cost
	stone -= stone_cost
	keep_upgrade_finish_unix = int(Time.get_unix_time_from_system()) + 15
	upgrade_timer.start(15.0)
	status_message = "Keep upgrade started. It will finish in 15 seconds."
	_persist_game()
	_refresh_ui()

func _finish_keep_upgrade() -> void:
	if is_instance_valid(network_session) and network_session.is_client_connected():
		return
	if keep_upgrade_finish_unix <= 0:
		return
	keep_upgrade_finish_unix = 0
	keep_level = mini(keep_level + 1, 10)
	day = mini(day + 1, 1000000)
	_award_achievement("keep_upgrade", "Keep Upgraded", 50)
	status_message = "Keep upgrade complete! Keep level is now %d." % keep_level
	_play_sound("build")
	_persist_game()
	_refresh_ui()

func _collect_selected_building() -> void:
	if _route_network_action("collect"):
		return
	match tiles[selected_tile]:
		"Farm":
			var food_gain := 10 * tile_levels[selected_tile] * keep_level
			food += food_gain
			status_message = "Collected %d food from the Farm." % food_gain
		"Mine":
			var mine_gold_gain := 10 * tile_levels[selected_tile] * keep_level
			gold += mine_gold_gain
			status_message = "Collected %d gold from the Mine." % mine_gold_gain
		"Keep":
			var keep_gold_gain := 5 * keep_level
			gold += keep_gold_gain
			wood += keep_level
			status_message = "Collected %d gold and %d wood from the Keep." % [keep_gold_gain, keep_level]
		"Barracks":
			food += 5 * tile_levels[selected_tile]
			status_message = "Collected army supplies from the Barracks."
		"Lumber Camp":
			var wood_gain := 10 * tile_levels[selected_tile] * keep_level
			wood += wood_gain
			status_message = "Collected %d wood from the Lumber Camp." % wood_gain
		"Quarry":
			var stone_gain := 10 * tile_levels[selected_tile] * keep_level
			stone += stone_gain
			status_message = "Collected %d stone from the Quarry." % stone_gain
		_:
			status_message = "Select a working building before collecting."
	_persist_game()
	_refresh_ui()

func _upgrade_selected_building() -> void:
	if _route_network_action("upgrade_building"):
		return
	if building_upgrade_finish_unix > int(Time.get_unix_time_from_system()):
		status_message = "Another building upgrade is already in progress."
		_refresh_ui()
		return
	var building := tiles[selected_tile]
	if building != "Farm" and building != "Mine" and building != "Barracks" and building != "Lumber Camp" and building != "Quarry" and building != "Academy":
		status_message = "Select a Farm, Mine, Barracks, Lumber Camp, Quarry, or Academy to upgrade it."
		_refresh_ui()
		return
	var level := tile_levels[selected_tile]
	var gold_cost := 40 * level
	var wood_cost := 20 * level
	var stone_cost := 10 * level
	if level >= 5:
		status_message = "This building has reached the maximum level 5."
		_refresh_ui()
		return
	if gold < gold_cost or wood < wood_cost or stone < stone_cost:
		status_message = "Upgrade needs %d gold, %d wood and %d stone." % [gold_cost, wood_cost, stone_cost]
		_refresh_ui()
		return
	gold -= gold_cost
	wood -= wood_cost
	stone -= stone_cost
	building_upgrade_tile = selected_tile
	building_upgrade_finish_unix = int(Time.get_unix_time_from_system()) + maxi(5, level * 5)
	building_upgrade_timer.start(float(building_upgrade_finish_unix - int(Time.get_unix_time_from_system())))
	status_message = "%s upgrade started. It will finish in %d seconds." % [building, maxi(5, level * 5)]
	_persist_game()
	_refresh_ui()

func _finish_building_upgrade() -> void:
	if is_instance_valid(network_session) and network_session.is_client_connected():
		return
	if building_upgrade_finish_unix <= 0:
		return
	if building_upgrade_tile >= 0 and building_upgrade_tile < tiles.size():
		var building := tiles[building_upgrade_tile]
		if building == "Farm" or building == "Mine" or building == "Barracks" or building == "Lumber Camp" or building == "Quarry" or building == "Academy":
			tile_levels[building_upgrade_tile] = clampi(tile_levels[building_upgrade_tile] + 1, 1, 5)
			day = mini(day + 1, 1000000)
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
	if queued_troop_count > 0:
		var training_remaining := troop_training_finish_unix - now
		if training_remaining > 0:
			troop_training_timer.start(float(training_remaining))
		else:
			_finish_troop_training()

func _train_guard() -> void:
	_queue_troop("infantry", 1)

func _queue_archers() -> void:
	_queue_troop("archer", 1)

func _queue_cavalry() -> void:
	_queue_troop("cavalry", 1)

func _get_barracks_level() -> int:
	var level := 0
	for i in range(tiles.size()):
		if tiles[i] == "Barracks":
			level = maxi(level, tile_levels[i])
	return level

func _queue_troop(troop_type: String, count: int = 1) -> void:
	var network_action := "train_infantry" if troop_type == "infantry" else ("train_archers" if troop_type == "archer" else "train_cavalry")
	if _route_network_action(network_action):
		return
	var food_cost := 0
	var gold_cost := 0
	var duration := 0
	match troop_type:
		"infantry":
			food_cost = 25
			gold_cost = 10
			duration = 8
		"archer":
			food_cost = 35
			gold_cost = 15
			duration = 12
		"cavalry":
			food_cost = 45
			gold_cost = 25
			duration = 16
		_:
			status_message = "Unknown troop type."
			_refresh_ui()
			return
	if queued_troop_count > 0:
		status_message = "Finish the current troop training queue first."
	elif count < 1 or count > 5:
		status_message = "Queue between 1 and 5 troops at a time."
	elif _get_barracks_level() <= 0:
		status_message = "Build a Barracks before training troops."
	elif guards + count > _get_barracks_level() * 5:
		status_message = "Barracks capacity is %d guards. Upgrade the Barracks to train more." % (_get_barracks_level() * 5)
	elif gold < gold_cost * count or food < food_cost * count:
		status_message = "Training needs %d gold and %d food." % [gold_cost * count, food_cost * count]
	else:
		gold -= gold_cost * count
		food -= food_cost * count
		queued_troop_type = troop_type
		queued_troop_count = count
		troop_training_finish_unix = int(Time.get_unix_time_from_system()) + duration * count
		troop_training_timer.start(float(duration * count))
		status_message = "Training %d %s. Completion in %d seconds." % [count, troop_type, duration * count]
		_persist_game()
	_refresh_ui()

func _finish_troop_training() -> void:
	if is_instance_valid(network_session) and network_session.is_client_connected():
		return
	if queued_troop_count <= 0:
		return
	match queued_troop_type:
		"infantry":
			infantry += queued_troop_count
		"archer":
			archers += queued_troop_count
		"cavalry":
			cavalry += queued_troop_count
	guards = infantry + archers + cavalry
	queued_troop_type = ""
	queued_troop_count = 0
	troop_training_finish_unix = 0
	if guards >= 5:
		_award_achievement("five_guards", "Five Guards", 35)
	if tutorial_step == 2:
		_advance_tutorial(3)
	status_message = "Troop training complete. Army strength increased."
	_play_sound("train")
	_persist_game()
	_refresh_ui()

func _scout() -> void:
	if _route_network_action("scout"):
		return
	if guards < 1:
		status_message = "You need at least 1 guard to scout safely."
	elif outpost_defeated[selected_outpost] == 1:
		status_message = "This outpost is already captured. Select another region to explore."
	elif selected_outpost > 0 and outpost_defeated[selected_outpost - 1] != 1:
		status_message = "Outpost %d is locked. Capture Outpost %d before scouting it." % [selected_outpost + 1, selected_outpost]
	elif region_scouted[selected_outpost] == 1:
		status_message = "This region is already scouted. Choose the next unlocked outpost."
	else:
		_remove_troops(1)
		_award_hero_xp(10)
		var reward := randi_range(35, 90) * keep_level + scouting_research * 10
		gold += reward
		wood += randi_range(5, 18) + scouting_research * 3
		day = mini(day + 1, 1000000)
		region_scouted[selected_outpost] = 1
		status_message = "Scouting revealed Threat %d at Outpost %d. Found %d gold and supplies." % [outpost_threat[selected_outpost], selected_outpost + 1, reward]
		_award_achievement("scout", "First Scout", 25)
		_persist_game()
	_refresh_ui()

func _attack_outpost() -> void:
	if _route_network_action("attack"):
		return
	var threat := outpost_threat[selected_outpost]
	if outpost_defeated[selected_outpost] == 1:
		status_message = "This outpost is already captured. Select another target."
		_refresh_ui()
		return
	if selected_outpost > 0 and outpost_defeated[selected_outpost - 1] != 1:
		status_message = "Outpost %d is locked. Capture Outpost %d first." % [selected_outpost + 1, selected_outpost]
		_refresh_ui()
		return
	var required_guards := 3 + threat
	if guards < required_guards:
		status_message = "Outpost %d requires at least %d guards." % [selected_outpost + 1, required_guards]
		_refresh_ui()
		return
	var battle: Dictionary = COMBAT_DIRECTOR.resolve_outpost(infantry, archers, cavalry, _hero_power(), combat_research, practice_drills, keep_level, _get_barracks_level(), threat, selected_outpost, region_scouted[selected_outpost] == 1)
	var chance := int(battle["chance"])
	var won_attack := randi_range(1, 100) <= chance
	var casualties := int(battle["win_losses"] if won_attack else battle["loss_losses"])
	_remove_troops(casualties)
	if is_instance_valid(world_view):
		world_view.play_attack(selected_outpost, won_attack)
	_play_sound("victory" if won_attack else "defeat")
	day = mini(day + 1, 1000000)
	if won_attack:
		_award_hero_xp(25)
		victories = mini(victories + 1, 1000000)
		outpost_defeated[selected_outpost] = 1
		var reward := 100 * threat + keep_level * 25
		gold += reward
		food += 20 * threat
		status_message = "Victory at Outpost %d! %s defeated at %d%% odds. Lost %d troops; reward: %d gold and %d food." % [selected_outpost + 1, battle["trait"], chance, casualties, reward, 20 * threat]
		_award_achievement("outpost", "First Outpost", 50, 10)
		var campaign_won := _all_outposts_captured()
		if campaign_won:
			_award_achievement("all_outposts", "Realm Conqueror", 250, 100)
		if tutorial_step == 3:
			_advance_tutorial(4)
		if campaign_won:
			status_message = "CAMPAIGN COMPLETE! All ten enemy outposts are secured. The kingdom is united."
	else:
		_award_hero_xp(10)
		defeats = mini(defeats + 1, 1000000)
		status_message = "Attack failed at Outpost %d vs %s (%d%% odds). Lost %d troops; regroup, research, or improve troop composition." % [selected_outpost + 1, battle["trait"], chance, casualties]
	_persist_game()
	_refresh_ui()

func _hero_power() -> int:
	return hero_level * 5 + hero_skill_level * 3

func _award_hero_xp(amount: int) -> void:
	if amount <= 0 or hero_level >= 20:
		return
	hero_xp += amount
	while hero_level < 20 and hero_xp >= hero_level * 100:
		hero_xp -= hero_level * 100
		hero_level += 1
		status_message = "Royal Captain reached hero level %d! Army power increased." % hero_level
	if hero_level >= 20:
		hero_xp = 0

func _train_hero() -> void:
	if _route_network_action("train_hero"):
		return
	if hero_level >= 20:
		status_message = "Royal Captain has reached the maximum hero level 20."
	elif gold < 25 or food < 25:
		status_message = "Hero training needs 25 gold and 25 food."
	else:
		gold -= 25
		food -= 25
		var previous_hero_level := hero_level
		_award_hero_xp(25)
		if hero_level > previous_hero_level:
			status_message = "Royal Captain reached hero level %d!" % hero_level
		else:
			status_message = "Royal Captain gained 25 XP (%d/%d)." % [hero_xp, hero_level * 100]
		_persist_game()
	_refresh_ui()

func _upgrade_hero_skill() -> void:
	if _route_network_action("upgrade_hero_skill"):
		return
	if hero_skill_level >= 5:
		status_message = "Royal Captain's skill has reached level 5."
		_refresh_ui()
		return
	var gold_cost := 100 * hero_skill_level
	var stone_cost := 50 * hero_skill_level
	if gold < gold_cost or stone < stone_cost:
		status_message = "Hero skill upgrade needs %d gold and %d stone." % [gold_cost, stone_cost]
		_refresh_ui()
		return
	gold -= gold_cost
	stone -= stone_cost
	hero_skill_level += 1
	status_message = "Royal Captain skill upgraded to level %d. Army power increased." % hero_skill_level
	_persist_game()
	_refresh_ui()

func _army_power() -> int:
	return infantry * (10 + combat_research * 2) + archers * (14 + combat_research * 2) + cavalry * (18 + combat_research * 2) + _get_barracks_level() * 4 + keep_level * 3 + practice_drills + _hero_power()

func _enemy_power() -> int:
	return 35 + clampi(enemy_level, 1, 100000) * 18

func _attack_enemy_army() -> void:
	if _route_network_action("army_battle"):
		return
	if guards < 1:
		status_message = "Train guards before attacking the enemy army."
		_refresh_ui()
		return
	var battle: Dictionary = COMBAT_DIRECTOR.resolve_enemy_army(infantry, archers, cavalry, _hero_power(), combat_research, practice_drills, keep_level, _get_barracks_level(), enemy_level)
	var army := int(battle["kingdom_power"])
	var enemy := int(battle["enemy_power"])
	var chance := int(battle["chance"])
	var won_battle := chance >= 100 or randi_range(1, 100) <= chance
	var lost := int(battle["win_losses"] if won_battle else battle["loss_losses"])
	_remove_troops(lost)
	day = mini(day + 1, 1000000)
	if won_battle:
		_award_hero_xp(40)
		var wood_reward := 35 + enemy_level * 10
		var stone_reward := 20 + enemy_level * 5
		var gold_reward := 25 + enemy_level * 8
		wood += wood_reward
		stone += stone_reward
		gold += gold_reward
		victories = mini(victories + 1, 1000000)
		enemy_level = mini(enemy_level + 1, 100000)
		status_message = "VICTORY vs %s! Power %d vs %d (%d%% odds). Lost %d troops; loot: %d wood, %d stone, %d gold." % [battle["trait"], army, enemy, chance, lost, wood_reward, stone_reward, gold_reward]
		if tutorial_step == 3:
			_advance_tutorial(4)
	else:
		_award_hero_xp(15)
		var food_lost := mini(food, 15 * lost)
		food -= food_lost
		defeats = mini(defeats + 1, 1000000)
		status_message = "DEFEAT vs %s. Power %d vs %d (%d%% odds). Lost %d troops and %d food. Improve your army before retrying." % [battle["trait"], army, enemy, chance, lost, food_lost]
	_persist_game()
	_refresh_ui()

func _research(research_type: String) -> void:
	if _route_network_action("research", {"type": research_type}):
		return
	var level := combat_research if research_type == "combat" else (economy_research if research_type == "economy" else scouting_research)
	var research_name := "Combat Drills" if research_type == "combat" else ("Efficient Production" if research_type == "economy" else "Cartography")
	if level >= 5:
		status_message = "%s has reached maximum level 5." % research_name
		_refresh_ui()
		return
	var required_level := level + 1
	if keep_level < required_level:
		status_message = "%s level %d requires Keep level %d." % [research_name, required_level, required_level]
		_refresh_ui()
		return
	if research_type == "combat":
		var barracks_level := 0
		for i in range(tiles.size()):
			if tiles[i] == "Barracks":
				barracks_level = tile_levels[i]
		if barracks_level < required_level:
			status_message = "Combat research level %d requires Barracks level %d." % [required_level, required_level]
			_refresh_ui()
			return
	var academy_discount := minf(0.25, float(_get_academy_level()) * 0.05)
	var wood_cost := ceili(60 * required_level * (1.0 - academy_discount))
	var stone_cost := ceili(40 * required_level * (1.0 - academy_discount))
	var gold_cost := ceili(25 * required_level * (1.0 - academy_discount))
	if wood < wood_cost or stone < stone_cost or gold < gold_cost:
		status_message = "Research needs %d wood, %d stone and %d gold." % [wood_cost, stone_cost, gold_cost]
		_refresh_ui()
		return
	wood -= wood_cost
	stone -= stone_cost
	gold -= gold_cost
	match research_type:
		"combat":
			combat_research += 1
		"economy":
			economy_research += 1
		"scouting":
			scouting_research += 1
	status_message = "%s researched to level %d with %d%% Academy discount." % [research_name, required_level, int(academy_discount * 100.0)]
	_persist_game()
	_refresh_ui()

func _explore_region() -> void:
	if _route_network_action("explore"):
		return
	if guards < 1:
		status_message = "Train at least one guard before exploring."
		_refresh_ui()
		return
	_remove_troops(1)
	_award_hero_xp(10)
	explored_regions = mini(explored_regions + 1, 1000000)
	day = mini(day + 1, 1000000)
	var wood_reward := 20 + explored_regions * 5 + scouting_research * 10
	var stone_reward := 10 + explored_regions * 2 + scouting_research * 3
	wood += wood_reward
	stone += stone_reward
	if is_instance_valid(world_view):
		world_view.play_exploration()
	status_message = "Region explored! Found %d wood and %d stone. One guard was assigned to the expedition." % [wood_reward, stone_reward]
	_persist_game()
	_refresh_ui()

func _remove_troops(count: int) -> void:
	var remaining := clampi(count, 0, guards)
	var take := mini(remaining, cavalry)
	cavalry -= take
	remaining -= take
	take = mini(remaining, archers)
	archers -= take
	remaining -= take
	infantry = maxi(0, infantry - remaining)
	guards = infantry + archers + cavalry

func _practice_troops() -> void:
	if _route_network_action("practice"):
		return
	if guards < 1:
		status_message = "Train at least one guard before practice."
	elif practice_drills >= 20:
		status_message = "Troops reached the practice limit (20/20)."
	else:
		practice_drills += 1
		status_message = "Practice complete! Drill %d/20. Army power increased." % practice_drills
		_persist_game()
	_refresh_ui()

func _claim_daily_reward() -> void:
	if _route_network_action("claim_daily"):
		return
	var today := int(floor(float(Time.get_unix_time_from_system()) / 86400.0))
	if daily_reward_claim_day == today:
		status_message = "Daily reward already claimed. Return after the next daily reset."
		_refresh_ui()
		return
	if daily_reward_claim_day == today - 1:
		daily_reward_streak = mini(daily_reward_streak + 1, 7)
	else:
		daily_reward_streak = 1
	daily_reward_claim_day = today
	var gold_reward := 100 + daily_reward_streak * 25
	var food_reward := 50 + daily_reward_streak * 15
	var wood_reward := 25 + daily_reward_streak * 10
	var stone_reward := 10 + daily_reward_streak * 5
	gold += gold_reward
	food += food_reward
	wood += wood_reward
	stone += stone_reward
	if daily_reward_streak == 7:
		gold += 250
		status_message = "7-DAY STREAK! Daily reward: +%d gold, +%d food, +%d wood, +%d stone, plus 250 bonus gold." % [gold_reward, food_reward, wood_reward, stone_reward]
	else:
		status_message = "Day %d/7 daily reward: +%d gold, +%d food, +%d wood, +%d stone." % [daily_reward_streak, gold_reward, food_reward, wood_reward, stone_reward]
	_play_sound("victory")
	_persist_game()
	_refresh_ui()

func _claim_quest(quest_id: String) -> void:
	if _route_network_action("claim_quest", {"quest_id": quest_id}):
		return
	var captured_outposts := 0
	for defeated in outpost_defeated:
		captured_outposts += 1 if defeated == 1 else 0
	var highest_building_level := 1
	for i in range(tiles.size()):
		if tiles[i] in ["Farm", "Mine", "Lumber Camp", "Quarry", "Barracks", "Academy"]:
			highest_building_level = maxi(highest_building_level, tile_levels[i])
	match quest_id:
		"builder":
			if quest_builder_claimed:
				status_message = "Builder's Mark quest reward already claimed."
			elif highest_building_level < 2:
				status_message = "Builder's Mark requires any resource or military building at level 2."
			else:
				quest_builder_claimed = true
				gold += 75
				wood += 50
				status_message = "Quest complete: Builder's Mark. +75 gold, +50 wood."
		"stronghold":
			if quest_stronghold_claimed:
				status_message = "Royal Stronghold quest reward already claimed."
			elif keep_level < 3:
				status_message = "Royal Stronghold requires Keep level 3."
			else:
				quest_stronghold_claimed = true
				stone += 100
				food += 100
				status_message = "Quest complete: Royal Stronghold. +100 stone, +100 food."
		"conqueror":
			if quest_conqueror_claimed:
				status_message = "Frontier Conqueror quest reward already claimed."
			elif captured_outposts < 3:
				status_message = "Frontier Conqueror requires 3 captured outposts (%d/3)." % captured_outposts
			else:
				quest_conqueror_claimed = true
				gold += 150
				stone += 150
				status_message = "Quest complete: Frontier Conqueror. +150 gold, +150 stone."
		_:
			status_message = "Unknown quest."
	_persist_game()
	_refresh_ui()

func _claim_reward(reward_id: String) -> void:
	if _route_network_action("claim_reward", {"reward_id": reward_id}):
		return
	match reward_id:
		"first_victory":
			if victories < 1:
				status_message = "Win your first battle to unlock this reward."
			elif reward_first_victory_claimed:
				status_message = "First Victory reward already claimed."
			else:
				reward_first_victory_claimed = true
				gold += 100
				wood += 75
				status_message = "First Victory claimed: +100 gold and +75 wood."
		"explorer":
			if explored_regions < 3:
				status_message = "Explore 3 regions to unlock this reward (%d/3)." % explored_regions
			elif reward_explorer_claimed:
				status_message = "Explorer reward already claimed."
			else:
				reward_explorer_claimed = true
				stone += 100
				food += 100
				status_message = "Explorer claimed: +100 stone and +100 food."
		"keep_builder":
			if keep_level < 3:
				status_message = "Upgrade the Keep to level 3 to unlock this reward."
			elif reward_keep_claimed:
				status_message = "Keep Builder reward already claimed."
			else:
				reward_keep_claimed = true
				wood += 150
				gold += 75
				status_message = "Keep Builder claimed: +150 wood and +75 gold."
	_persist_game()
	_refresh_ui()

func _all_outposts_captured() -> bool:
	for defeated in outpost_defeated:
		if defeated != 1:
			return false
	return true

func _on_autosave_tick() -> void:
	_persist_game()

func _on_production_tick() -> void:
	if is_instance_valid(network_session) and network_session.is_client_connected():
		return
	for i in range(tiles.size()):
		match tiles[i]:
			"Farm":
				food += 2 * keep_level * tile_levels[i]
			"Mine":
				gold += 2 * keep_level * tile_levels[i]
			"Lumber Camp":
				wood += 2 * keep_level * tile_levels[i]
			"Quarry":
				stone += 2 * keep_level * tile_levels[i]
			"Keep":
				gold += keep_level
				wood += 1
	if economy_research > 0:
		wood += economy_research
		food += economy_research
		stone += economy_research
	_refresh_ui()

func _save_game() -> void:
	var error := _persist_game()
	status_message = "Kingdom saved on this device." if error == OK else "Save failed: %s" % error
	_refresh_ui()

func _export_multiplayer_snapshot() -> Dictionary:
	return {
		"gold": gold, "wood": wood, "food": food, "stone": stone,
		"guards": guards, "infantry": infantry, "archers": archers, "cavalry": cavalry,
		"queued_troop_type": queued_troop_type, "queued_troop_count": queued_troop_count, "troop_training_finish_unix": troop_training_finish_unix,
		"keep_level": keep_level, "day": day, "daily_reward_claim_day": daily_reward_claim_day, "daily_reward_streak": daily_reward_streak,
		"enemy_level": enemy_level, "explored_regions": explored_regions, "victories": victories, "defeats": defeats,
		"combat_research": combat_research, "economy_research": economy_research, "scouting_research": scouting_research, "practice_drills": practice_drills,
		"reward_first_victory_claimed": reward_first_victory_claimed, "reward_explorer_claimed": reward_explorer_claimed, "reward_keep_claimed": reward_keep_claimed,
		"quest_builder_claimed": quest_builder_claimed, "quest_stronghold_claimed": quest_stronghold_claimed, "quest_conqueror_claimed": quest_conqueror_claimed,
		"hero_level": hero_level, "hero_xp": hero_xp, "hero_skill_level": hero_skill_level,
		"selected_tile": selected_tile, "selected_outpost": selected_outpost, "keep_upgrade_finish_unix": keep_upgrade_finish_unix,
		"building_upgrade_finish_unix": building_upgrade_finish_unix, "building_upgrade_tile": building_upgrade_tile, "tutorial_step": tutorial_step,
		"tiles": tiles.duplicate(), "tile_levels": Array(tile_levels), "outpost_defeated": Array(outpost_defeated), "region_scouted": Array(region_scouted), "achievements": Array(achievements)
	}

func _apply_multiplayer_snapshot(snapshot: Dictionary) -> void:
	if not is_instance_valid(network_session) or not network_session._valid_snapshot(snapshot):
		return
	for key in ["gold", "wood", "food", "stone", "guards", "infantry", "archers", "cavalry", "queued_troop_count", "troop_training_finish_unix", "keep_level", "day", "daily_reward_claim_day", "daily_reward_streak", "enemy_level", "explored_regions", "victories", "defeats", "combat_research", "economy_research", "scouting_research", "practice_drills", "hero_level", "hero_xp", "hero_skill_level", "selected_tile", "selected_outpost", "keep_upgrade_finish_unix", "building_upgrade_finish_unix", "building_upgrade_tile", "tutorial_step"]:
		if snapshot.has(key):
			set(key, int(snapshot[key]))
	queued_troop_type = str(snapshot.get("queued_troop_type", ""))
	for key in ["reward_first_victory_claimed", "reward_explorer_claimed", "reward_keep_claimed", "quest_builder_claimed", "quest_stronghold_claimed", "quest_conqueror_claimed"]:
		if snapshot.has(key):
			set(key, bool(snapshot[key]))
	tiles.clear()
	for value in snapshot["tiles"]:
		tiles.append(str(value))
	tile_levels = PackedInt32Array(snapshot["tile_levels"])
	outpost_defeated = PackedInt32Array(snapshot["outpost_defeated"])
	region_scouted = PackedInt32Array(snapshot["region_scouted"])
	achievements = PackedStringArray(snapshot.get("achievements", []))
	status_message = "Shared kingdom updated by the host."
	_resume_timed_upgrades()
	_refresh_ui()
	_persist_game()

func _apply_network_action(action: String, payload: Dictionary) -> void:
	selected_tile = clampi(int(payload.get("tile", selected_tile)), 0, 8)
	selected_outpost = clampi(int(payload.get("outpost", selected_outpost)), 0, 9)
	match action:
		"gather": _gather_resource(str(payload.get("resource", "")), int(payload.get("amount", 0)))
		"select_tile": _select_tile(int(payload.get("tile", selected_tile)))
		"select_outpost": _select_outpost(int(payload.get("outpost", selected_outpost)))
		"build_farm": _build_farm()
		"build_mine": _build_mine()
		"build_lumber_camp": _build_lumber_camp()
		"build_quarry": _build_quarry()
		"build_academy": _build_academy()
		"build_barracks": _build_barracks()
		"upgrade_keep": _upgrade_keep()
		"collect": _collect_selected_building()
		"upgrade_building": _upgrade_selected_building()
		"train_infantry": _queue_troop("infantry")
		"train_archers": _queue_troop("archer")
		"train_cavalry": _queue_troop("cavalry")
		"scout": _scout()
		"attack": _attack_outpost()
		"explore": _explore_region()
		"practice": _practice_troops()
		"research": _research(str(payload.get("type", "")))
		"train_hero": _train_hero()
		"upgrade_hero_skill": _upgrade_hero_skill()
		"claim_daily": _claim_daily_reward()
		"army_battle": _attack_enemy_army()
		"claim_reward": _claim_reward(str(payload.get("reward_id", "")))
		"claim_quest": _claim_quest(str(payload.get("quest_id", "")))

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
	config.set_value("kingdom", "stone", stone)
	config.set_value("kingdom", "graphics_quality", graphics_quality)
	config.set_value("kingdom", "sound_enabled", sound_enabled)
	config.set_value("kingdom", "music_enabled", music_enabled)
	config.set_value("kingdom", "day", day)
	config.set_value("kingdom", "daily_reward_claim_day", daily_reward_claim_day)
	config.set_value("kingdom", "daily_reward_streak", daily_reward_streak)
	config.set_value("kingdom", "enemy_level", enemy_level)
	config.set_value("kingdom", "explored_regions", explored_regions)
	config.set_value("kingdom", "victories", victories)
	config.set_value("kingdom", "defeats", defeats)
	config.set_value("kingdom", "combat_research", combat_research)
	config.set_value("kingdom", "economy_research", economy_research)
	config.set_value("kingdom", "scouting_research", scouting_research)
	config.set_value("kingdom", "practice_drills", practice_drills)
	config.set_value("kingdom", "reward_first_victory_claimed", reward_first_victory_claimed)
	config.set_value("kingdom", "reward_explorer_claimed", reward_explorer_claimed)
	config.set_value("kingdom", "reward_keep_claimed", reward_keep_claimed)
	config.set_value("kingdom", "quest_builder_claimed", quest_builder_claimed)
	config.set_value("kingdom", "quest_stronghold_claimed", quest_stronghold_claimed)
	config.set_value("kingdom", "quest_conqueror_claimed", quest_conqueror_claimed)
	config.set_value("kingdom", "hero_level", hero_level)
	config.set_value("kingdom", "hero_xp", hero_xp)
	config.set_value("kingdom", "hero_skill_level", hero_skill_level)
	config.set_value("kingdom", "guards", guards)
	config.set_value("kingdom", "infantry", infantry)
	config.set_value("kingdom", "archers", archers)
	config.set_value("kingdom", "cavalry", cavalry)
	config.set_value("kingdom", "queued_troop_type", queued_troop_type)
	config.set_value("kingdom", "queued_troop_count", queued_troop_count)
	config.set_value("kingdom", "troop_training_finish_unix", troop_training_finish_unix)
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
	stone = int(config.get_value("kingdom", "stone", stone))
	graphics_quality = str(config.get_value("kingdom", "graphics_quality", graphics_quality))
	sound_enabled = bool(config.get_value("kingdom", "sound_enabled", sound_enabled))
	music_enabled = bool(config.get_value("kingdom", "music_enabled", music_enabled))
	day = int(config.get_value("kingdom", "day", day))
	daily_reward_claim_day = int(config.get_value("kingdom", "daily_reward_claim_day", daily_reward_claim_day))
	daily_reward_streak = int(config.get_value("kingdom", "daily_reward_streak", daily_reward_streak))
	enemy_level = int(config.get_value("kingdom", "enemy_level", enemy_level))
	explored_regions = int(config.get_value("kingdom", "explored_regions", explored_regions))
	victories = int(config.get_value("kingdom", "victories", victories))
	defeats = int(config.get_value("kingdom", "defeats", defeats))
	combat_research = int(config.get_value("kingdom", "combat_research", combat_research))
	economy_research = int(config.get_value("kingdom", "economy_research", economy_research))
	scouting_research = int(config.get_value("kingdom", "scouting_research", scouting_research))
	practice_drills = int(config.get_value("kingdom", "practice_drills", practice_drills))
	reward_first_victory_claimed = bool(config.get_value("kingdom", "reward_first_victory_claimed", reward_first_victory_claimed))
	reward_explorer_claimed = bool(config.get_value("kingdom", "reward_explorer_claimed", reward_explorer_claimed))
	reward_keep_claimed = bool(config.get_value("kingdom", "reward_keep_claimed", reward_keep_claimed))
	quest_builder_claimed = bool(config.get_value("kingdom", "quest_builder_claimed", quest_builder_claimed))
	quest_stronghold_claimed = bool(config.get_value("kingdom", "quest_stronghold_claimed", quest_stronghold_claimed))
	quest_conqueror_claimed = bool(config.get_value("kingdom", "quest_conqueror_claimed", quest_conqueror_claimed))
	hero_level = int(config.get_value("kingdom", "hero_level", hero_level))
	hero_xp = int(config.get_value("kingdom", "hero_xp", hero_xp))
	hero_skill_level = int(config.get_value("kingdom", "hero_skill_level", hero_skill_level))
	guards = int(config.get_value("kingdom", "guards", guards))
	infantry = int(config.get_value("kingdom", "infantry", guards))
	archers = int(config.get_value("kingdom", "archers", archers))
	cavalry = int(config.get_value("kingdom", "cavalry", cavalry))
	queued_troop_type = str(config.get_value("kingdom", "queued_troop_type", queued_troop_type))
	queued_troop_count = int(config.get_value("kingdom", "queued_troop_count", queued_troop_count))
	troop_training_finish_unix = int(config.get_value("kingdom", "troop_training_finish_unix", troop_training_finish_unix))
	keep_level = int(config.get_value("kingdom", "keep_level", keep_level))
	selected_tile = clampi(int(config.get_value("kingdom", "selected_tile", selected_tile)), 0, tiles.size() - 1)
	tiles = ["Empty", "Farm", "Empty", "Mine", "Keep", "Empty", "Lumber Camp", "Barracks", "Quarry"]
	tile_levels = PackedInt32Array([1, 1, 1, 1, 1, 1, 1, 1, 1])
	outpost_defeated = PackedInt32Array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
	region_scouted = PackedInt32Array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
	var loaded_tiles = config.get_value("kingdom", "tiles", tiles.duplicate())
	if loaded_tiles is Array and loaded_tiles.size() == 9:
		var normalized_tiles: Array[String] = []
		for building in loaded_tiles:
			normalized_tiles.append(str(building))
		tiles = normalized_tiles
	var loaded_levels = config.get_value("kingdom", "tile_levels", tile_levels)
	if (loaded_levels is PackedInt32Array or loaded_levels is Array) and loaded_levels.size() == tile_levels.size():
		for i in range(tile_levels.size()):
			tile_levels[i] = clampi(int(loaded_levels[i]), 1, 5)
	var loaded_outposts = config.get_value("kingdom", "outpost_defeated", outpost_defeated)
	if (loaded_outposts is PackedInt32Array or loaded_outposts is Array) and loaded_outposts.size() > 0:
		for i in range(mini(outpost_defeated.size(), loaded_outposts.size())):
			outpost_defeated[i] = 1 if int(loaded_outposts[i]) == 1 else 0
	var loaded_scouted = config.get_value("kingdom", "region_scouted", region_scouted)
	if (loaded_scouted is PackedInt32Array or loaded_scouted is Array) and loaded_scouted.size() > 0:
		for i in range(mini(region_scouted.size(), loaded_scouted.size())):
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
	_apply_graphics_quality()
	_apply_offline_production(false)

func _normalize_save_data() -> void:
	const MAX_RESOURCE := 2000000000
	gold = clampi(gold, 0, MAX_RESOURCE)
	wood = clampi(wood, 0, MAX_RESOURCE)
	food = clampi(food, 0, MAX_RESOURCE)
	stone = clampi(stone, 0, MAX_RESOURCE)
	if graphics_quality not in ["Low", "Balanced", "High"]:
		graphics_quality = "Balanced"
	hero_level = clampi(hero_level, 1, 20)
	hero_skill_level = clampi(hero_skill_level, 1, 5)
	hero_xp = clampi(hero_xp, 0, 1000000)
	while hero_level < 20 and hero_xp >= hero_level * 100:
		hero_xp -= hero_level * 100
		hero_level += 1
	if hero_level >= 20:
		hero_xp = 0
	day = clampi(day, 1, 1000000)
	var current_utc_day := int(floor(float(Time.get_unix_time_from_system()) / 86400.0))
	daily_reward_claim_day = clampi(daily_reward_claim_day, -1, current_utc_day)
	daily_reward_streak = clampi(daily_reward_streak, 0, 7)
	enemy_level = clampi(enemy_level, 1, 100000)
	explored_regions = clampi(explored_regions, 0, 1000000)
	victories = clampi(victories, 0, 1000000)
	defeats = clampi(defeats, 0, 1000000)
	combat_research = clampi(combat_research, 0, 5)
	economy_research = clampi(economy_research, 0, 5)
	scouting_research = clampi(scouting_research, 0, 5)
	practice_drills = clampi(practice_drills, 0, 20)
	infantry = clampi(infantry, 0, 100000)
	archers = clampi(archers, 0, 100000)
	cavalry = clampi(cavalry, 0, 100000)
	queued_troop_count = clampi(queued_troop_count, 0, 5)
	if queued_troop_type not in ["", "infantry", "archer", "cavalry"] or queued_troop_count == 0:
		queued_troop_type = ""
		queued_troop_count = 0
		troop_training_finish_unix = 0
	keep_level = clampi(keep_level, 1, 10)
	selected_tile = clampi(selected_tile, 0, tiles.size() - 1)
	selected_outpost = clampi(selected_outpost, 0, outpost_threat.size() - 1)
	tutorial_step = clampi(tutorial_step, 0, 4)
	if tiles.size() != 9:
		tiles = ["Empty", "Farm", "Empty", "Mine", "Keep", "Empty", "Lumber Camp", "Barracks", "Quarry"]
	var valid_buildings := ["Empty", "Farm", "Mine", "Keep", "Barracks", "Lumber Camp", "Quarry", "Academy"]
	for i in range(tiles.size()):
		if not valid_buildings.has(tiles[i]):
			tiles[i] = "Empty"
		tile_levels[i] = clampi(tile_levels[i], 1, 5)
	# The Keep is fixed to the centre tile; never restore duplicate Keeps from malformed saves.
	for i in range(tiles.size()):
		if i != 4 and tiles[i] == "Keep":
			tiles[i] = "Empty"
	tiles[4] = "Keep"
	# A single Academy provides one predictable discount path; sanitize duplicate legacy/corrupt entries.
	var academy_found := false
	for i in range(tiles.size()):
		if tiles[i] == "Academy":
			if academy_found:
				tiles[i] = "Empty"
			else:
				academy_found = true
	# Keep the saved army within Barracks capacity, even if a save was edited or partially corrupted.
	var barracks_capacity := 0
	for i in range(tiles.size()):
		if tiles[i] == "Barracks":
			barracks_capacity = maxi(barracks_capacity, tile_levels[i] * 5)
	var excess_troops := maxi(0, infantry + archers + cavalry - barracks_capacity)
	var remove_count := mini(excess_troops, cavalry)
	cavalry -= remove_count
	excess_troops -= remove_count
	remove_count = mini(excess_troops, archers)
	archers -= remove_count
	excess_troops -= remove_count
	infantry = maxi(0, infantry - excess_troops)
	guards = infantry + archers + cavalry
	# Queued training reserves capacity; trim or cancel queues that would overflow it.
	queued_troop_count = mini(queued_troop_count, maxi(0, barracks_capacity - guards))
	if queued_troop_count == 0:
		queued_troop_type = ""
		troop_training_finish_unix = 0
	for i in range(outpost_defeated.size()):
		outpost_defeated[i] = 1 if outpost_defeated[i] == 1 else 0
		region_scouted[i] = 1 if region_scouted[i] == 1 else 0
	# Repair impossible campaign states: later regions cannot remain captured/scouted through a corrupt save.
	for i in range(1, outpost_defeated.size()):
		if outpost_defeated[i - 1] != 1:
			outpost_defeated[i] = 0
			region_scouted[i] = 0
	# Keep all persisted timers tied to a valid operation and supported building.
	if keep_upgrade_finish_unix <= 0 or keep_level >= 10:
		keep_upgrade_finish_unix = 0
	if building_upgrade_finish_unix <= 0 or building_upgrade_tile < 0 or building_upgrade_tile >= tiles.size():
		building_upgrade_finish_unix = 0
		building_upgrade_tile = -1
	elif tiles[building_upgrade_tile] not in ["Farm", "Mine", "Barracks", "Lumber Camp", "Quarry", "Academy"] or tile_levels[building_upgrade_tile] >= 5:
		building_upgrade_finish_unix = 0
		building_upgrade_tile = -1
	if queued_troop_count <= 0:
		troop_training_finish_unix = 0
		queued_troop_type = ""
	elif troop_training_finish_unix <= 0:
		queued_troop_type = ""
		queued_troop_count = 0
		troop_training_finish_unix = 0

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
			"Lumber Camp":
				wood += 2 * keep_level * tile_levels[i] * ticks
			"Quarry":
				stone += 2 * keep_level * tile_levels[i] * ticks
			"Keep":
				gold += keep_level * ticks
				wood += ticks
	if economy_research > 0:
		wood += economy_research * ticks
		food += economy_research * ticks
		stone += economy_research * ticks
	if elapsed >= 10:
		status_message = "Welcome back. Offline production was capped at 8 hours."
	_persist_game()
	if refresh_after:
		_refresh_ui()
