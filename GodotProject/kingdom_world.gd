extends Node3D

signal tile_selected(index: int)

var building_nodes: Array[Node3D] = []
var outpost_nodes: Array[Node3D] = []
var guard_nodes: Array[Node3D] = []
var selected_outpost := 0
var selected_tile_index := 4
var tile_highlight: Node3D
var world_camera: Camera3D
var camera_distance := 24.0
var camera_yaw := 0.0
var camera_elevation := 0.65
var active_touches: Dictionary = {}
var touch_can_pick: Dictionary = {}
var touch_moved: Dictionary = {}
var previous_pinch_distance := 0.0
var mouse_orbiting := false
var mouse_moved := false
var current_tiles: Array[String] = ["Empty", "Farm", "Empty", "Mine", "Keep", "Empty", "Empty", "Barracks", "Empty"]
var current_levels := PackedInt32Array([1, 1, 1, 1, 1, 1, 1, 1, 1])
var current_keep_level := 1
var current_guards := 4
var current_infantry := 4
var current_archers := 0
var current_cavalry := 0
var current_outposts := PackedInt32Array([0, 0, 0])
var current_scouted := PackedInt32Array([0, 0, 0])

func _ready() -> void:
	_build_environment()
	_build_terrain()
	_build_landmarks()
	_rebuild_buildings()
	_rebuild_outposts()
	_rebuild_guards()

func set_kingdom_state(tile_data: Array, level_data: PackedInt32Array, keep_level: int, guards: int, infantry: int, archers: int, cavalry: int, defeated: PackedInt32Array, scouted: PackedInt32Array, target: int, selected_tile: int) -> void:
	var next_tiles: Array[String] = []
	for tile in tile_data:
		next_tiles.append(str(tile))
	if next_tiles.size() != 9:
		next_tiles = ["Empty", "Farm", "Empty", "Mine", "Keep", "Empty", "Empty", "Barracks", "Empty"]
	var next_levels := level_data.duplicate()
	if next_levels.size() != 9:
		next_levels = PackedInt32Array([1, 1, 1, 1, 1, 1, 1, 1, 1])
	var next_outposts := defeated.duplicate()
	if next_outposts.size() != 3:
		next_outposts = PackedInt32Array([0, 0, 0])
	var next_scouted := scouted.duplicate()
	if next_scouted.size() != 3:
		next_scouted = PackedInt32Array([0, 0, 0])
	var next_keep_level := clampi(keep_level, 1, 99)
	var next_guards := maxi(guards, 0)
	var next_infantry := maxi(infantry, 0)
	var next_archers := maxi(archers, 0)
	var next_cavalry := maxi(cavalry, 0)
	var next_target := clampi(target, 0, 2)
	var next_selected_tile := clampi(selected_tile, 0, 8)
	var buildings_changed := current_tiles != next_tiles or current_levels != next_levels or current_keep_level != next_keep_level
	var outposts_changed := current_outposts != next_outposts or current_scouted != next_scouted or selected_outpost != next_target
	var guards_changed := current_guards != next_guards or current_infantry != next_infantry or current_archers != next_archers or current_cavalry != next_cavalry
	var tile_selection_changed := selected_tile_index != next_selected_tile
	current_tiles = next_tiles
	current_levels = next_levels
	current_keep_level = next_keep_level
	current_guards = next_guards
	current_infantry = next_infantry
	current_archers = next_archers
	current_cavalry = next_cavalry
	current_outposts = next_outposts
	current_scouted = next_scouted
	selected_outpost = next_target
	selected_tile_index = next_selected_tile
	if buildings_changed:
		_rebuild_buildings()
	if outposts_changed:
		_rebuild_outposts()
	if guards_changed:
		_rebuild_guards()
	if tile_selection_changed:
		_update_tile_highlight()

func _build_environment() -> void:
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#a9c6d0")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#d8e6d7")
	environment.ambient_light_energy = 0.75
	environment_node.environment = environment
	add_child(environment_node)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_color = Color("#fff0d4")
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	add_child(sun)

	world_camera = Camera3D.new()
	world_camera.fov = 42
	add_child(world_camera)
	_update_camera()
	world_camera.current = true

func _update_camera() -> void:
	if not is_instance_valid(world_camera):
		return
	var horizontal := camera_distance * cos(camera_elevation)
	world_camera.position = Vector3(sin(camera_yaw) * horizontal, camera_distance * sin(camera_elevation), cos(camera_yaw) * horizontal)
	world_camera.look_at(Vector3(0, 0, -1), Vector3.UP)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_can_pick[event.index] = active_touches.is_empty()
			touch_moved[event.index] = false
			active_touches[event.index] = event.position
			if active_touches.size() == 2:
				var points := active_touches.values()
				var first_point: Vector2 = points[0]
				var second_point: Vector2 = points[1]
				previous_pinch_distance = first_point.distance_to(second_point)
		else:
			var can_pick := bool(touch_can_pick.get(event.index, false)) and not bool(touch_moved.get(event.index, false))
			active_touches.erase(event.index)
			touch_can_pick.erase(event.index)
			touch_moved.erase(event.index)
			if active_touches.size() < 2:
				previous_pinch_distance = 0.0
			if can_pick:
				_pick_tile(event.position)
	elif event is InputEventScreenDrag:
		touch_moved[event.index] = true
		if active_touches.size() >= 2:
			active_touches[event.index] = event.position
			var points := active_touches.values()
			var first_point: Vector2 = points[0]
			var second_point: Vector2 = points[1]
			var pinch_distance: float = first_point.distance_to(second_point)
			if previous_pinch_distance > 0.0:
				camera_distance = clampf(camera_distance + (previous_pinch_distance - pinch_distance) * 0.035, 15.0, 34.0)
				_update_camera()
			previous_pinch_distance = pinch_distance
			get_viewport().set_input_as_handled()
		else:
			camera_yaw -= event.relative.x * 0.005
			camera_elevation = clampf(camera_elevation + event.relative.y * 0.003, 0.32, 1.05)
			_update_camera()
			get_viewport().set_input_as_handled()
	elif event is InputEventMagnifyGesture:
		camera_distance = clampf(camera_distance / maxf(event.factor, 0.1), 15.0, 34.0)
		_update_camera()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				mouse_orbiting = true
				mouse_moved = false
			else:
				if mouse_orbiting and not mouse_moved:
					_pick_tile(event.position)
				mouse_orbiting = false
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_distance = maxf(15.0, camera_distance - 1.5)
			_update_camera()
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_distance = minf(34.0, camera_distance + 1.5)
			_update_camera()
	elif event is InputEventMouseMotion and mouse_orbiting:
		if event.relative.length() > 2.0:
			mouse_moved = true
		camera_yaw -= event.relative.x * 0.005
		camera_elevation = clampf(camera_elevation + event.relative.y * 0.003, 0.32, 1.05)
		_update_camera()

func _pick_tile(screen_position: Vector2) -> int:
	if not is_instance_valid(world_camera):
		return -1
	var ray_origin := world_camera.project_ray_origin(screen_position)
	var ray_direction := world_camera.project_ray_normal(screen_position)
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_direction * 100.0)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.has("collider"):
		var collider = hit["collider"]
		if collider is Node and collider.has_meta("tile_index"):
			var tile_index := int(collider.get_meta("tile_index"))
			tile_selected.emit(tile_index)
			get_viewport().set_input_as_handled()
			return tile_index
	return -1

func _build_terrain() -> void:
	_add_box(self, Vector3(30, 0.35, 30), Vector3(0, -0.28, -1), "#668b52")
	var tile_colors := ["#759b5c", "#80a760", "#729654", "#80a760", "#86a966", "#729654", "#759b5c", "#80a760", "#759b5c"]
	for i in range(9):
		var x := float(i % 3 - 1) * 3.7
		var z := float(int(i / 3) - 1) * 3.7
		_add_box(self, Vector3(3.45, 0.08, 3.45), Vector3(x, -0.055, z), tile_colors[i])
		_add_box(self, Vector3(0.055, 0.025, 3.45), Vector3(x + 1.72, 0.01, z), "#b6a77a")
		_add_box(self, Vector3(3.45, 0.025, 0.055), Vector3(x, 0.01, z + 1.72), "#b6a77a")
		var tile_body := StaticBody3D.new()
		tile_body.position = Vector3(x, 0.6, z)
		tile_body.set_meta("tile_index", i)
		var tile_shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = Vector3(3.35, 1.2, 3.35)
		tile_shape.shape = box_shape
		tile_body.add_child(tile_shape)
		add_child(tile_body)
	tile_highlight = Node3D.new()
	add_child(tile_highlight)
	_add_box(tile_highlight, Vector3(3.45, 0.035, 0.07), Vector3(0, 0.03, -1.69), "#f1d38a")
	_add_box(tile_highlight, Vector3(3.45, 0.035, 0.07), Vector3(0, 0.03, 1.69), "#f1d38a")
	_add_box(tile_highlight, Vector3(0.07, 0.035, 3.45), Vector3(-1.69, 0.03, 0), "#f1d38a")
	_add_box(tile_highlight, Vector3(0.07, 0.035, 3.45), Vector3(1.69, 0.03, 0), "#f1d38a")
	_update_tile_highlight()

	# A river and crossing make the valley readable as a place, not only a menu.
	_add_box(self, Vector3(1.45, 0.035, 29), Vector3(7.25, -0.04, -1), "#4c9eb5")
	_add_box(self, Vector3(2.5, 0.22, 1.2), Vector3(7.25, 0.12, 2.1), "#8a6547")
	for i in range(9):
		var z := -12.0 + float(i) * 2.7
		_add_cylinder(self, 0.16, 1.1, Vector3(-11.5, 0.42, z), "#6b4b35")
		_add_sphere(self, Vector3(-11.5, 1.55, z), Vector3(1.05, 1.25, 1.05), "#3e7547")
		_add_sphere(self, Vector3(-10.95, 1.85, z + 0.18), Vector3(0.72, 0.8, 0.72), "#4f8a50")
	# Layered hills and boulders give the valley a deeper horizon and more readable edges.
	for i in range(7):
		var hill_x := -16.0 + float(i) * 5.3
		var hill_z := -16.0 + float(i % 2) * 2.8
		_add_sphere(self, Vector3(hill_x, -0.25, hill_z), Vector3(3.8, 1.65, 2.8), "#56794f")
	for i in range(10):
		var rock_x := 8.8 + float(i % 3) * 0.65
		var rock_z := -10.0 + float(i) * 1.9
		var rock := _add_sphere(self, Vector3(rock_x, 0.05, rock_z), Vector3(0.42, 0.32, 0.38), "#7b8880")
		rock.rotation_degrees = Vector3(float(i * 9), float(i * 17), float(i * 5))

func _build_landmarks() -> void:
	# Roads connect the central keep to the river crossing and outer regions.
	_add_box(self, Vector3(0.6, 0.035, 11.5), Vector3(0, 0.03, 0), "#c2ae7b")
	_add_box(self, Vector3(7.8, 0.035, 0.6), Vector3(3.5, 0.035, 2.1), "#c2ae7b")
	_add_box(self, Vector3(0.55, 0.035, 8.0), Vector3(7.25, 0.035, -4.0), "#c2ae7b")
	# Warm lantern posts mark the central road and make the Keep entrance stand out.
	for side in [-1.0, 1.0]:
		_add_cylinder(self, 0.07, 1.25, Vector3(side * 2.0, 0.62, 2.8), "#5c3f2d")
		_add_box(self, Vector3(0.22, 0.28, 0.22), Vector3(side * 2.0, 1.34, 2.8), "#e7ad52")
	# Pale water streaks animate briefly when the scene starts.
	for i in range(4):
		var ripple_z := -12.0 + float(i) * 7.0
		var ripple := _add_box(self, Vector3(0.75, 0.018, 0.07), Vector3(7.25, 0.005, ripple_z), "#8bd1d7")
		var ripple_tween := create_tween().set_loops(3)
		ripple_tween.tween_property(ripple, "position", Vector3(7.75, 0.005, ripple_z), 1.1).set_trans(Tween.TRANS_SINE)
		ripple_tween.tween_property(ripple, "position", Vector3(6.75, 0.005, ripple_z), 1.1).set_trans(Tween.TRANS_SINE)

func _update_tile_highlight() -> void:
	if is_instance_valid(tile_highlight):
		var x := float(selected_tile_index % 3 - 1) * 3.7
		var z := float(int(selected_tile_index / 3) - 1) * 3.7
		tile_highlight.position = Vector3(x, 0.09, z)

func _rebuild_buildings() -> void:
	for node in building_nodes:
		if is_instance_valid(node):
			node.queue_free()
	building_nodes.clear()
	for i in range(9):
		var x := float(i % 3 - 1) * 3.7
		var z := float(int(i / 3) - 1) * 3.7
		var building := _make_building(current_tiles[i], current_levels[i], Vector3(x, 0.04, z), i == 4)
		building.scale = Vector3(0.92, 0.92, 0.92)
		add_child(building)
		building_nodes.append(building)
		create_tween().tween_property(building, "scale", Vector3.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _make_building(kind: String, level: int, position_value: Vector3, is_keep: bool) -> Node3D:
	var root := Node3D.new()
	root.position = position_value
	if kind == "Empty":
		_add_box(root, Vector3(1.1, 0.05, 1.1), Vector3(0, 0.04, 0), "#b9b48b")
		_add_sphere(root, Vector3(0, 0.17, 0), Vector3(0.22, 0.12, 0.22), "#e1d5a1")
		return root

	if kind == "Keep" or is_keep:
		_add_box(root, Vector3(1.35, 1.15, 1.25), Vector3(0, 0.62, 0), "#b7b1a3")
		_add_box(root, Vector3(0.55, 1.65, 0.55), Vector3(0, 1.85, -0.08), "#d0c6b2")
		_add_box(root, Vector3(0.45, 1.35, 0.45), Vector3(-0.62, 1.25, -0.42), "#a7a091")
		_add_box(root, Vector3(0.45, 1.35, 0.45), Vector3(0.62, 1.25, -0.42), "#a7a091")
		_add_cone(root, 0.43, 0.8, Vector3(0, 3.05, -0.08), "#8d4d3e")
		_add_cone(root, 0.34, 0.6, Vector3(-0.62, 2.23, -0.42), "#8d4d3e")
		_add_cone(root, 0.34, 0.6, Vector3(0.62, 2.23, -0.42), "#8d4d3e")
		_add_box(root, Vector3(0.3, 0.62, 0.07), Vector3(0, 0.35, 0.65), "#5d4432")
		_add_box(root, Vector3(0.08, 0.95, 0.08), Vector3(0.2, 2.6, 0), "#634a35")
		_add_box(root, Vector3(0.65, 0.42, 0.06), Vector3(0.48, 2.8, 0), "#f1d38a")
		_add_textured_level_marker(root, level, Vector3(0, 3.55, 0), "#f1d38a")
	elif kind == "Farm":
		_add_box(root, Vector3(1.35, 0.16, 1.25), Vector3(0, 0.12, 0), "#8d714a")
		for row in range(3):
			for col in range(4):
				_add_box(root, Vector3(0.13, 0.24 + 0.025 * level, 0.2), Vector3(-0.48 + col * 0.32, 0.28, -0.38 + row * 0.34), "#4b8d45")
		_add_box(root, Vector3(0.55, 0.55, 0.5), Vector3(-0.3, 0.46, 0.2), "#d6c08b")
		_add_cone(root, 0.42, 0.42, Vector3(-0.3, 0.93, 0.2), "#9a5540")
		_add_textured_level_marker(root, level, Vector3(0.5, 0.75, -0.45), "#f5d779")
	elif kind == "Mine":
		_add_box(root, Vector3(1.15, 0.22, 1.0), Vector3(0, 0.12, 0), "#625f58")
		_add_box(root, Vector3(0.85, 0.72, 0.18), Vector3(0, 0.52, -0.34), "#5e5044")
		_add_box(root, Vector3(0.12, 0.75, 0.1), Vector3(-0.34, 0.53, -0.22), "#d4b46c")
		_add_box(root, Vector3(0.12, 0.75, 0.1), Vector3(0.34, 0.53, -0.22), "#d4b46c")
		_add_cone(root, 0.34, 0.55, Vector3(0.25, 0.82, 0.25), "#6c7c82")
		_add_cone(root, 0.27, 0.44, Vector3(-0.28, 0.69, 0.22), "#8d9ba0")
		_add_textured_level_marker(root, level, Vector3(0.5, 0.9, -0.4), "#f5d779")
	elif kind == "Barracks":
		_add_box(root, Vector3(1.15, 0.78, 1.0), Vector3(0, 0.42, 0), "#8a6242")
		_add_cone(root, 0.82, 0.72, Vector3(0, 1.12, 0), "#9b4d3d")
		_add_box(root, Vector3(0.23, 0.5, 0.08), Vector3(0, 0.34, 0.54), "#e2c88a")
		_add_textured_level_marker(root, level, Vector3(0.42, 1.25, -0.3), "#f5d779")
	elif kind == "Lumber Camp":
		_add_box(root, Vector3(1.2, 0.8, 1.0), Vector3(0, 0.42, 0), "#8a6242")
		_add_cone(root, 0.86, 0.68, Vector3(0, 1.12, 0), "#5d6b4c")
		for i in range(3):
			var log := _add_cylinder(root, 0.13, 0.85, Vector3(-0.2 + float(i) * 0.22, 0.18, 0.78), "#67462f")
			log.rotation_degrees.x = 90
		_add_textured_level_marker(root, level, Vector3(0.48, 1.25, -0.3), "#f5d779")
	elif kind == "Quarry":
		_add_box(root, Vector3(1.25, 0.18, 1.1), Vector3(0, 0.12, 0), "#6a6e6a")
		_add_sphere(root, Vector3(-0.28, 0.48, -0.1), Vector3(0.45, 0.38, 0.42), "#a3aaa7")
		_add_sphere(root, Vector3(0.24, 0.4, 0.2), Vector3(0.34, 0.3, 0.32), "#858c89")
		_add_box(root, Vector3(0.12, 0.72, 0.12), Vector3(0.48, 0.55, -0.3), "#75563c")
		_add_box(root, Vector3(0.58, 0.14, 0.18), Vector3(0.48, 0.88, -0.3), "#c0c5c2")
		_add_textured_level_marker(root, level, Vector3(0.48, 1.15, -0.3), "#f5d779")
	else:
		_add_box(root, Vector3(0.8, 0.55, 0.8), Vector3(0, 0.32, 0), "#8a6242")
	return root

func play_attack(target_index: int, victory: bool) -> void:
	var safe_target := clampi(target_index, 0, 2)
	var positions := [Vector3(-8.0, 0.1, -9.0), Vector3(0.0, 0.1, -11.0), Vector3(8.0, 0.1, -9.0)]
	var target_position: Vector3 = positions[safe_target]
	var squad_size := mini(5, maxi(3, current_guards))
	for i in range(squad_size):
		var soldier := Node3D.new()
		var lane := float(i % 3) - 1.0
		soldier.position = Vector3(lane * 0.48, 0.08, 1.0 + float(int(i / 3)) * 0.45)
		_add_capsule(soldier, Vector3(0, 0.55, 0), "#526e9c")
		_add_sphere(soldier, Vector3(0, 1.2, 0), Vector3(0.22, 0.22, 0.22), "#d9b18c")
		_add_box(soldier, Vector3(0.12, 0.58, 0.12), Vector3(0.2, 0.58, 0), "#bca46e")
		add_child(soldier)
		var destination := target_position + Vector3(lane * 0.55, 0.0, 1.1 + float(int(i / 3)) * 0.4)
		var march := create_tween()
		march.tween_property(soldier, "position", destination, 0.68 + float(i) * 0.055).set_delay(float(i) * 0.045).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		march.tween_callback(soldier.queue_free)

	var projectile := _add_sphere(self, Vector3(0, 1.25, 1.0), Vector3(0.25, 0.25, 0.25), "#f1d38a")
	var tween := create_tween()
	tween.tween_property(projectile, "position", target_position + Vector3(0, 1.2, 0), 0.72).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_callback(projectile.queue_free)
	tween.tween_callback(_show_battle_flash.bind(target_position + Vector3(0, 1.0, 0), victory))

func play_exploration() -> void:
	var scout := Node3D.new()
	scout.position = Vector3(0.0, 0.08, 1.2)
	_add_capsule(scout, Vector3(0, 0.55, 0), "#6c8dbe")
	_add_sphere(scout, Vector3(0, 1.2, 0), Vector3(0.22, 0.22, 0.22), "#d9b18c")
	_add_box(scout, Vector3(0.12, 0.58, 0.12), Vector3(0.2, 0.58, 0), "#bca46e")
	add_child(scout)
	var destination := Vector3(-10.5, 0.08, -11.5)
	var journey := create_tween()
	journey.tween_property(scout, "position", destination, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	journey.tween_callback(_show_battle_flash.bind(destination + Vector3(0, 1.0, 0), true))
	journey.tween_callback(scout.queue_free)

func _show_battle_flash(position_value: Vector3, victory: bool) -> void:
	var flash_color := "#e4d17e" if victory else "#b53d36"
	var flash := _add_sphere(self, position_value, Vector3(0.2, 0.2, 0.2), flash_color)
	var tween := create_tween()
	tween.tween_property(flash, "scale", Vector3(1.8, 1.8, 1.8), 0.28)
	tween.tween_callback(flash.queue_free)

func _rebuild_outposts() -> void:
	for node in outpost_nodes:
		if is_instance_valid(node):
			node.queue_free()
	outpost_nodes.clear()
	var positions := [Vector3(-8.0, 0.0, -9.0), Vector3(0.0, 0.0, -11.0), Vector3(8.0, 0.0, -9.0)]
	for i in range(3):
		var root := Node3D.new()
		root.position = positions[i]
		var defeated := current_outposts[i] == 1
		var scouted := current_scouted[i] == 1
		var wall_color := "#858a83" if defeated else "#744d48"
		var banner_color := "#7d9c78" if defeated else ("#d0a35a" if scouted else "#b53d36")
		_add_box(root, Vector3(1.55, 0.75, 1.45), Vector3(0, 0.38, 0), wall_color)
		for side in [-1.0, 1.0]:
			_add_box(root, Vector3(0.28, 1.45, 0.28), Vector3(side * 0.55, 0.72, -0.48), wall_color)
			_add_cone(root, 0.22, 0.36, Vector3(side * 0.55, 1.62, -0.48), "#504b46")
		_add_box(root, Vector3(0.07, 1.1, 0.07), Vector3(0.25, 1.45, 0.3), "#5e4935")
		_add_box(root, Vector3(0.55, 0.38, 0.06), Vector3(0.52, 1.63, 0.3), banner_color)
		if i == selected_outpost:
			var target_ring := _add_cylinder(root, 1.45, 0.045, Vector3(0, 0.08, 0), "#f1d38a")
			var pulse := create_tween().set_loops(3)
			pulse.tween_property(target_ring, "scale", Vector3(1.12, 1.0, 1.12), 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			pulse.tween_property(target_ring, "scale", Vector3.ONE, 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		root.scale = Vector3(0.82, 0.82, 0.82)
		var label := Label3D.new()
		var outpost_status := " • SECURED" if defeated else (" • SCOUTED" if scouted else "")
		label.text = "OUTPOST %d%s" % [i + 1, outpost_status]
		label.position = Vector3(0, 2.15, 0)
		label.font_size = 32
		label.modulate = Color("#fff0c9")
		root.add_child(label)
		add_child(root)
		create_tween().tween_property(root, "scale", Vector3.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		outpost_nodes.append(root)

func _rebuild_guards() -> void:
	for node in guard_nodes:
		if is_instance_valid(node):
			node.queue_free()
	guard_nodes.clear()
	var visible_count := mini(current_guards, 7)
	for i in range(visible_count):
		var guard := Node3D.new()
		guard.position = Vector3(-0.95 + float(i % 4) * 0.55, 0.08, 1.0 + float(int(i / 4)) * 0.55)
		_add_capsule(guard, Vector3(0, 0.55, 0), "#526e9c")
		_add_sphere(guard, Vector3(0, 1.2, 0), Vector3(0.24, 0.24, 0.24), "#d9b18c")
		_add_box(guard, Vector3(0.12, 0.58, 0.12), Vector3(0.18, 0.58, 0), "#bca46e")
		add_child(guard)
		guard_nodes.append(guard)

func _add_textured_level_marker(parent: Node3D, level: int, pos: Vector3, color_value: String) -> void:
	for i in range(mini(level, 4)):
		_add_sphere(parent, pos + Vector3(float(i) * 0.16, 0, 0), Vector3(0.075, 0.075, 0.075), color_value)

func _add_box(parent: Node3D, dimensions: Vector3, pos: Vector3, color_value: String) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	mesh_instance.mesh = mesh
	mesh_instance.position = pos
	mesh_instance.material_override = _material(color_value)
	parent.add_child(mesh_instance)
	return mesh_instance

func _add_cylinder(parent: Node3D, radius: float, height: float, pos: Vector3, color_value: String) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh_instance.mesh = mesh
	mesh_instance.position = pos
	mesh_instance.material_override = _material(color_value)
	parent.add_child(mesh_instance)
	return mesh_instance

func _add_cone(parent: Node3D, radius: float, height: float, pos: Vector3, color_value: String) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.025
	mesh.bottom_radius = radius
	mesh.height = height
	mesh_instance.mesh = mesh
	mesh_instance.position = pos
	mesh_instance.material_override = _material(color_value)
	parent.add_child(mesh_instance)
	return mesh_instance

func _add_sphere(parent: Node3D, pos: Vector3, scale_value: Vector3, color_value: String) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh_instance.mesh = mesh
	mesh_instance.position = pos
	mesh_instance.scale = scale_value
	mesh_instance.material_override = _material(color_value)
	parent.add_child(mesh_instance)
	return mesh_instance

func _add_capsule(parent: Node3D, pos: Vector3, color_value: String) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh_instance.mesh = mesh
	mesh_instance.position = pos
	mesh_instance.material_override = _material(color_value)
	parent.add_child(mesh_instance)
	return mesh_instance

func _material(color_value: String) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color_value)
	material.roughness = 0.86
	return material
