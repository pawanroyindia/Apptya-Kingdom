extends Node3D

signal tile_selected(index: int)

var building_nodes: Array[Node3D] = []
var outpost_nodes: Array[Node3D] = []
var guard_nodes: Array[Node3D] = []
var hero_model: Node3D
var hero_level_label: Label3D
var current_hero_level := 1
var selected_outpost := 0
var selected_tile_index := 4
var tile_highlight: Node3D
var world_camera: Camera3D
var sun_light: DirectionalLight3D
var world_environment: Environment
var day_phase := 0.25
var quality_preset := "Balanced"
var camera_distance := 24.0
var camera_yaw := 0.0
var camera_elevation := 0.65
var active_touches: Dictionary = {}
var touch_can_pick: Dictionary = {}
var touch_moved: Dictionary = {}
var previous_pinch_distance := 0.0
var mouse_orbiting := false
var mouse_moved := false
var current_tiles: Array[String] = ["Empty", "Farm", "Empty", "Mine", "Keep", "Empty", "Lumber Camp", "Barracks", "Quarry"]
var current_levels := PackedInt32Array([1, 1, 1, 1, 1, 1, 1, 1, 1])
var current_keep_level := 1
var current_guards := 4
var current_infantry := 4
var current_archers := 0
var current_cavalry := 0
var current_outposts := PackedInt32Array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
var current_scouted := PackedInt32Array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
var material_cache: Dictionary = {}
var material_textures: Dictionary = {}
var surface_noise: NoiseTexture2D
var animated_flags: Array[MeshInstance3D] = []
var animated_trees: Array[Node3D] = []
var animated_guards: Array[Node3D] = []
var articulated_rigs: Array[Dictionary] = []
var hero_rig_data: Dictionary = {}
var animation_clock := 0.0

func _ready() -> void:
	_build_environment()
	_build_terrain()
	_build_landmarks()
	_rebuild_buildings()
	_rebuild_outposts()
	_rebuild_guards()
	_build_hero_model()

func _process(delta: float) -> void:
	day_phase = fposmod(day_phase + delta / 240.0, 1.0)
	animation_clock += delta
	_update_daylight()
	for i in range(animated_trees.size()):
		if is_instance_valid(animated_trees[i]):
			animated_trees[i].rotation_degrees.z = sin(animation_clock * 0.65 + float(i) * 0.47) * 2.0
	for i in range(animated_guards.size()):
		if is_instance_valid(animated_guards[i]):
			animated_guards[i].position.y = 0.08 + sin(animation_clock * 1.8 + float(i) * 0.8) * 0.025
	var all_rigs: Array[Dictionary] = [hero_rig_data]
	all_rigs.append_array(articulated_rigs)
	for rig_index in range(all_rigs.size()):
		var rig: Dictionary = all_rigs[rig_index]
		var offset: float = float(rig.get("offset", 0.0))
		var phase: float = animation_clock * float(rig.get("speed", 5.2)) + offset
		var gait: float = sin(phase) * float(rig.get("walk", 0.0))
		var idle: float = sin(animation_clock * 1.45 + offset)
		var moving := float(rig.get("walk", 0.0)) > 0.2
		var combat := bool(rig.get("combat", false))
		if combat:
			rig["combat_elapsed"] = float(rig.get("combat_elapsed", 0.0)) + delta
		var attack_pose := _combat_swing_curve(float(rig.get("combat_elapsed", 0.0))) if combat else 0.0
		var left_leg: Node3D = rig.get("left_leg")
		var right_leg: Node3D = rig.get("right_leg")
		var left_arm: Node3D = rig.get("left_arm")
		var right_arm: Node3D = rig.get("right_arm")
		var torso: Node3D = rig.get("torso")
		var head: Node3D = rig.get("head")
		if is_instance_valid(left_leg):
			left_leg.rotation.x = gait
			left_leg.position.y = float(rig.get("left_leg_y", 0.46)) + (maxf(0.0, sin(phase)) * 0.045 if moving else 0.0)
		if is_instance_valid(right_leg):
			right_leg.rotation.x = -gait
			right_leg.position.y = float(rig.get("right_leg_y", 0.46)) + (maxf(0.0, -sin(phase)) * 0.045 if moving else 0.0)
		if is_instance_valid(left_arm):
			left_arm.rotation.x = -gait * 0.72 + idle * 0.035 - attack_pose * 0.22
			left_arm.rotation.z = -0.04 + (attack_pose * 0.12)
		if is_instance_valid(right_arm):
			right_arm.rotation.x = attack_pose if combat else (gait * 0.72 + idle * 0.035)
			right_arm.rotation.z = (-0.08 - attack_pose * 0.12) if combat else 0.025
		if is_instance_valid(torso):
			var torso_sway := sin(phase * 2.0) * 0.018 if moving else idle * 0.012
			torso.rotation.z = torso_sway + (attack_pose * 0.085 if combat else 0.0)
			torso.rotation.x = (-0.08 - attack_pose * 0.10) if combat else (sin(phase) * 0.025 if moving else idle * 0.012)
		if is_instance_valid(head):
			head.rotation.x = (-0.06 + attack_pose * 0.08) if combat else (sin(animation_clock * 0.8 + offset) * 0.018)
	if is_instance_valid(hero_model):
		hero_model.position.y = 0.08 + sin(animation_clock * 1.6) * 0.025
		hero_model.rotation_degrees.y = sin(animation_clock * 0.42) * 2.0
	for i in range(animated_flags.size() - 1, -1, -1):
		var flag := animated_flags[i]
		if not is_instance_valid(flag):
			animated_flags.remove_at(i)
			continue
		flag.rotation_degrees.z = sin(animation_clock * 2.1 + float(i) * 0.7) * 3.0

func _update_daylight() -> void:
	if not is_instance_valid(world_environment) or not is_instance_valid(sun_light):
		return
	var daylight := clampf(sin(day_phase * TAU), 0.08, 1.0)
	world_environment.background_color = Color("#17253b").lerp(Color("#a9c6d0"), daylight)
	world_environment.ambient_light_color = Color("#37425e").lerp(Color("#d8e6d7"), daylight)
	world_environment.ambient_light_energy = 0.15 + daylight * 0.6
	sun_light.light_color = Color("#e29a60").lerp(Color("#fff0d4"), daylight)
	sun_light.light_energy = (0.15 + daylight * 1.1) * (0.88 if quality_preset == "Low" else 1.0)
	sun_light.rotation_degrees.x = -15.0 - daylight * 42.0

func set_hero_level(level: int) -> void:
	var previous_level := current_hero_level
	current_hero_level = clampi(level, 1, 20)
	if is_instance_valid(hero_level_label):
		hero_level_label.text = "ROYAL CAPTAIN • LV %d" % current_hero_level
	if is_instance_valid(hero_model) and current_hero_level != previous_level:
		var level_flash := create_tween()
		level_flash.tween_property(hero_model, "scale", Vector3(1.16, 1.16, 1.16), 0.12).set_trans(Tween.TRANS_BACK)
		level_flash.tween_property(hero_model, "scale", Vector3.ONE, 0.2).set_trans(Tween.TRANS_BOUNCE)

func _build_hero_model() -> void:
	hero_model = Node3D.new()
	hero_model.name = "RoyalCaptain"
	hero_model.position = Vector3(-1.55, 0.08, 1.8)
	var rig := _create_articulated_character("#c9a84f", "#b48b38", "#8f3936", true, 1.0)
	for child in rig.get_children():
		rig.remove_child(child)
		hero_model.add_child(child)
	hero_rig_data = rig.get_meta("rig_data")
	rig.free()
	hero_level_label = Label3D.new()
	hero_level_label.text = "ROYAL CAPTAIN • LV %d" % current_hero_level
	hero_level_label.position = Vector3(0, 2.05, 0)
	hero_level_label.font_size = 24
	hero_level_label.modulate = Color("#ffe3a0")
	hero_model.add_child(hero_level_label)
	add_child(hero_model)

func _create_articulated_character(uniform_color: String, armor_color: String, cloth_color: String, royal: bool, size_scale: float = 1.0) -> Node3D:
	var character := Node3D.new()
	character.scale = Vector3.ONE * size_scale
	var torso := Node3D.new()
	torso.name = "TorsoPivot"
	torso.position = Vector3(0, 0.83, 0)
	character.add_child(torso)
	_add_capsule(torso, Vector3(0, 0.0, 0), uniform_color)
	_add_box(torso, Vector3(0.43, 0.48, 0.3), Vector3(0, 0.0, 0), armor_color)
	_add_box(torso, Vector3(0.46, 0.09, 0.32), Vector3(0, -0.21, 0), "#5b392b")
	_add_box(torso, Vector3(0.48, 0.065, 0.34), Vector3(0, -0.17, 0), "#e4c77f" if royal else "#bca46e")

	var left_arm := Node3D.new()
	left_arm.name = "LeftArmJoint"
	left_arm.position = Vector3(-0.29, 0.15, 0)
	torso.add_child(left_arm)
	_add_capsule(left_arm, Vector3(0, -0.2, 0), armor_color)

	var right_arm := Node3D.new()
	right_arm.name = "RightArmJoint"
	right_arm.position = Vector3(0.29, 0.15, 0)
	torso.add_child(right_arm)
	_add_capsule(right_arm, Vector3(0, -0.2, 0), armor_color)

	_add_box(right_arm, Vector3(0.07, 0.25, 0.07), Vector3(0.0, -0.45, 0.0), "#bca46e")
	_add_box(right_arm, Vector3(0.055, 0.5, 0.055), Vector3(0.0, -0.67, 0.0), "#cbd2d5")

	_add_box(torso, Vector3(0.52, 0.4, 0.055), Vector3(0, -0.02, 0.2), cloth_color)
	var head := Node3D.new()
	head.name = "HeadPivot"
	head.position = Vector3(0, 0.38, 0)
	torso.add_child(head)
	_add_sphere(head, Vector3(0, 0.0, 0), Vector3(0.205, 0.235, 0.19), "#d9b18c")

	_add_cone(head, 0.245, 0.22, Vector3(0, 0.19, 0), "#e3bd59" if royal else "#b8bfc4")


	var left_leg := Node3D.new()
	left_leg.name = "LeftLegJoint"
	left_leg.position = Vector3(-0.12, 0.46, 0)
	character.add_child(left_leg)
	_add_capsule(left_leg, Vector3(0, -0.16, 0), armor_color)
	_add_box(left_leg, Vector3(0.15, 0.1, 0.25), Vector3(0, -0.32, 0.055), "#49352b")
	var right_leg := Node3D.new()
	right_leg.name = "RightLegJoint"
	right_leg.position = Vector3(0.12, 0.46, 0)
	character.add_child(right_leg)
	_add_capsule(right_leg, Vector3(0, -0.16, 0), armor_color)
	_add_box(right_leg, Vector3(0.15, 0.1, 0.25), Vector3(0, -0.32, 0.055), "#49352b")
	var rig_data := {"left_leg": left_leg, "right_leg": right_leg, "left_arm": left_arm, "right_arm": right_arm, "torso": torso, "head": head, "left_leg_y": left_leg.position.y, "right_leg_y": right_leg.position.y, "walk": 0.12 if royal else 0.42, "speed": 3.2 if royal else 5.2, "offset": randf_range(0.0, TAU), "combat_elapsed": 0.0}
	character.set_meta("rig_data", rig_data)
	return character
func set_kingdom_state(tile_data: Array, level_data: PackedInt32Array, keep_level: int, guards: int, infantry: int, archers: int, cavalry: int, defeated: PackedInt32Array, scouted: PackedInt32Array, target: int, selected_tile: int) -> void:
	var next_tiles: Array[String] = []
	for tile in tile_data:
		next_tiles.append(str(tile))
	if next_tiles.size() != 9:
		next_tiles = ["Empty", "Farm", "Empty", "Mine", "Keep", "Empty", "Lumber Camp", "Barracks", "Quarry"]
	var next_levels := level_data.duplicate()
	if next_levels.size() != 9:
		next_levels = PackedInt32Array([1, 1, 1, 1, 1, 1, 1, 1, 1])
	var next_outposts := defeated.duplicate()
	if next_outposts.size() != 10:
		next_outposts = PackedInt32Array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
	var next_scouted := scouted.duplicate()
	if next_scouted.size() != 10:
		next_scouted = PackedInt32Array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
	var next_keep_level := clampi(keep_level, 1, 10)
	var next_guards := maxi(guards, 0)
	var next_infantry := maxi(infantry, 0)
	var next_archers := maxi(archers, 0)
	var next_cavalry := maxi(cavalry, 0)
	var next_target := clampi(target, 0, 4)
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
	# Shared seamless noise adds subtle surface breakup without shipping large texture files.
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.055
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 3
	noise.fractal_lacunarity = 2.0
	surface_noise = NoiseTexture2D.new()
	surface_noise.width = 128
	surface_noise.height = 128
	surface_noise.seamless = true
	surface_noise.noise = noise
	material_textures = {
		"stone": load("res://art/textures/stone_masonry.svg"),
		"wood": load("res://art/textures/wood_grain.svg"),
		"cloth": load("res://art/textures/woven_banner.svg"),
		"grass": load("res://art/textures/grass_detail.svg")
	}

	var environment_node := WorldEnvironment.new()
	world_environment = Environment.new()
	world_environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_environment.background_mode = Environment.BG_COLOR
	world_environment.background_color = Color("#a9c6d0")
	world_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world_environment.ambient_light_color = Color("#d8e6d7")
	world_environment.ambient_light_energy = 0.75
	environment_node.environment = world_environment
	add_child(environment_node)

	sun_light = DirectionalLight3D.new()
	sun_light.rotation_degrees = Vector3(-48, -32, 0)
	sun_light.light_color = Color("#fff0d4")
	sun_light.light_energy = 1.25
	sun_light.shadow_enabled = true
	add_child(sun_light)

	world_camera = Camera3D.new()
	world_camera.fov = 42
	add_child(world_camera)
	_update_camera()
	world_camera.current = true


func set_quality_preset(preset: String) -> void:
	quality_preset = preset if preset in ["Low", "Balanced", "High"] else "Balanced"
	if is_instance_valid(sun_light):
		sun_light.shadow_enabled = quality_preset != "Low"
		_update_daylight()

func reset_camera() -> void:
	camera_distance = 24.0
	camera_yaw = 0.0
	camera_elevation = 0.65
	_update_camera()

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
		var tree := Node3D.new()
		tree.position = Vector3(-11.5, 0.0, z)
		add_child(tree)
		animated_trees.append(tree)
		_add_cylinder(tree, 0.16, 1.1, Vector3(0, 0.42, 0), "#6b4b35")
		_add_sphere(tree, Vector3(0, 1.55, 0), Vector3(1.05, 1.25, 1.05), "#3e7547")
		_add_sphere(tree, Vector3(0.55, 1.85, 0.18), Vector3(0.72, 0.8, 0.72), "#4f8a50")

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
	# A low stone perimeter wall frames the village while leaving a clear southern gate.
	var wall_color := "#9b9b8c"
	_add_box(self, Vector3(11.8, 0.85, 0.28), Vector3(0, 0.43, -5.9), wall_color)
	_add_box(self, Vector3(0.28, 0.85, 11.8), Vector3(-5.9, 0.43, 0), wall_color)
	_add_box(self, Vector3(0.28, 0.85, 11.8), Vector3(5.9, 0.43, 0), wall_color)
	_add_box(self, Vector3(4.4, 0.85, 0.28), Vector3(-3.7, 0.43, 5.9), wall_color)
	_add_box(self, Vector3(4.4, 0.85, 0.28), Vector3(3.7, 0.43, 5.9), wall_color)
	for corner_x in [-5.9, 5.9]:
		for corner_z in [-5.9, 5.9]:
			_add_cylinder(self, 0.42, 1.45, Vector3(corner_x, 0.73, corner_z), "#b9b9a9")
			_add_cone(self, 0.5, 0.72, Vector3(corner_x, 1.82, corner_z), "#6b5545")
			_add_box(self, Vector3(0.58, 0.12, 0.58), Vector3(corner_x, 1.35, corner_z), "#d1c9ac")
	for gate_x in [-1.5, 1.5]:
		_add_box(self, Vector3(0.34, 1.25, 0.34), Vector3(gate_x, 0.63, 5.9), "#b9b9a9")
		_add_box(self, Vector3(0.22, 0.72, 0.07), Vector3(gate_x, 1.35, 6.12), "#a94f43")
	_add_box(self, Vector3(3.3, 0.18, 0.35), Vector3(0, 1.25, 5.9), "#8b6a49")
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
			node.free()
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
		_add_box(root, Vector3(0.13, 0.22, 0.045), Vector3(-0.28, 0.78, 0.64), "#e4c77f")
		_add_box(root, Vector3(0.13, 0.22, 0.045), Vector3(0.28, 0.78, 0.64), "#e4c77f")
		_add_box(root, Vector3(0.08, 0.95, 0.08), Vector3(0.2, 2.6, 0), "#634a35")
		var royal_banner := _add_box(root, Vector3(0.65, 0.42, 0.06), Vector3(0.48, 2.8, 0), "#f1d38a")
		animated_flags.append(royal_banner)
		_add_textured_level_marker(root, level, Vector3(0, 3.55, 0), "#f1d38a")
	elif kind == "Farm":
		_add_box(root, Vector3(1.35, 0.16, 1.25), Vector3(0, 0.12, 0), "#8d714a")
		for row in range(3):
			for col in range(4):
				_add_box(root, Vector3(0.13, 0.24 + 0.025 * level, 0.2), Vector3(-0.48 + col * 0.32, 0.28, -0.38 + row * 0.34), "#4b8d45")
		_add_box(root, Vector3(0.55, 0.55, 0.5), Vector3(-0.3, 0.46, 0.2), "#d6c08b")
		_add_box(root, Vector3(0.08, 0.4, 0.06), Vector3(-0.3, 0.45, 0.47), "#513b2d")
		_add_cone(root, 0.42, 0.42, Vector3(-0.3, 0.93, 0.2), "#9a5540")
		_add_box(root, Vector3(0.14, 0.38, 0.06), Vector3(0.45, 0.28, 0.5), "#e0c77f")
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
		_add_box(root, Vector3(0.12, 0.28, 0.045), Vector3(-0.36, 0.48, 0.52), "#e5c37a")
		_add_box(root, Vector3(0.12, 0.28, 0.045), Vector3(0.36, 0.48, 0.52), "#e5c37a")
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
	elif kind == "Academy":
		_add_box(root, Vector3(1.2, 0.9, 1.05), Vector3(0, 0.48, 0), "#d1c6a6")
		_add_box(root, Vector3(0.42, 1.25, 0.42), Vector3(0, 1.35, -0.12), "#b8ad91")
		_add_cone(root, 0.58, 0.52, Vector3(0, 2.18, -0.12), "#496c60")
		_add_box(root, Vector3(0.3, 0.48, 0.07), Vector3(0, 0.37, 0.56), "#4c3527")
		_add_box(root, Vector3(0.12, 0.5, 0.06), Vector3(-0.42, 0.56, 0.54), "#d6a84f")
		_add_box(root, Vector3(0.12, 0.5, 0.06), Vector3(0.42, 0.56, 0.54), "#d6a84f")
		_add_box(root, Vector3(0.16, 0.2, 0.045), Vector3(0, 1.12, 0.44), "#77a6a0")
		_add_box(root, Vector3(0.055, 0.22, 0.035), Vector3(0, 1.12, 0.41), "#e5d8b7")
		_add_textured_level_marker(root, level, Vector3(0.48, 1.35, -0.34), "#f5d779")
	else:
		_add_box(root, Vector3(0.8, 0.55, 0.8), Vector3(0, 0.32, 0), "#8a6242")
	_add_architectural_finish(root, kind, level)
	return root

func _add_architectural_finish(root: Node3D, kind: String, level: int) -> void:
	# Small silhouette and material accents improve readability without heavy imported assets.
	match kind:
		"Keep":
			for row in range(2):
				var y := 0.48 + float(row) * 0.48
				_add_box(root, Vector3(1.38, 0.055, 1.28), Vector3(0, y, 0), "#d0c6b2")
			_add_box(root, Vector3(0.18, 0.2, 0.06), Vector3(0, 1.0, 0.66), "#e7ad52")
			_add_box(root, Vector3(0.055, 0.18, 0.04), Vector3(0, 1.0, 0.62), "#fff0c9")
		"Farm":
			for row in range(3):
				_add_box(root, Vector3(1.08, 0.035, 0.035), Vector3(0, 0.2, -0.42 + float(row) * 0.34), "#c2a16a")
			for crop in range(4):
				_add_sphere(root, Vector3(-0.42 + float(crop) * 0.28, 0.43 + 0.025 * level, 0.54), Vector3(0.055, 0.07, 0.055), "#d5b957")
		"Mine":
			_add_cone(root, 0.16, 0.3, Vector3(0.48, 0.44, 0.34), "#91b8c0")
			_add_cone(root, 0.12, 0.24, Vector3(-0.46, 0.4, 0.34), "#d4b46c")
		"Barracks", "Lumber Camp", "Academy":
			var timber := "#5c3d2d"
			for side in [-1.0, 1.0]:
				_add_box(root, Vector3(0.07, 0.66, 0.07), Vector3(side * 0.49, 0.43, 0.53), timber)
			_add_box(root, Vector3(0.42, 0.07, 0.06), Vector3(0, 0.73, 0.55), "#d6b675")
			_add_box(root, Vector3(0.12, 0.18, 0.035), Vector3(0.32, 0.56, 0.57), "#e7ad52")
		"Quarry":
			for mark in range(3):
				_add_box(root, Vector3(0.25, 0.025, 0.025), Vector3(-0.25 + float(mark) * 0.22, 0.66, 0.38), "#d0d4cf")
	# Higher levels receive visible gold studs as an upgrade cue.
	for i in range(mini(level, 4)):
		_add_sphere(root, Vector3(-0.52 + float(i) * 0.34, 0.12, 0.58), Vector3(0.045, 0.045, 0.045), "#e4c77f")

func play_attack(target_index: int, victory: bool) -> void:
	var safe_target := clampi(target_index, 0, 9)
	var positions := [
		Vector3(-12.0, 0.1, -9.0), Vector3(-8.0, 0.1, -13.0), Vector3(-3.0, 0.1, -14.0),
		Vector3(3.0, 0.1, -14.0), Vector3(8.0, 0.1, -13.0), Vector3(12.0, 0.1, -8.0),
		Vector3(12.0, 0.1, 1.0), Vector3(9.0, 0.1, 10.0), Vector3(2.0, 0.1, 13.0), Vector3(-9.0, 0.1, 10.0)
	]
	var target_position: Vector3 = positions[safe_target]
	var squad_size := mini(5, maxi(3, current_guards))
	for i in range(squad_size):
		var soldier := Node3D.new()
		soldier.name = "AttackUnit_%02d" % i
		var lane := float(i % 3) - 1.0
		soldier.position = Vector3(lane * 0.48, 0.08, 1.0 + float(int(i / 3)) * 0.45)
		var troop_type := "infantry"
		if i >= current_infantry and i < current_infantry + current_archers:
			troop_type = "archer"
		elif i >= current_infantry + current_archers:
			troop_type = "cavalry"
		var rig_data: Dictionary = {}
		if troop_type == "cavalry":
			_add_box(soldier, Vector3(0.55, 0.38, 0.85), Vector3(0, 0.48, 0), "#8c6845")
			_add_sphere(soldier, Vector3(0, 0.72, -0.38), Vector3(0.26, 0.22, 0.3), "#8c6845")
			for leg_x in [-0.18, 0.18]:
				for leg_z in [-0.25, 0.25]:
					_add_box(soldier, Vector3(0.09, 0.32, 0.09), Vector3(leg_x, 0.2, leg_z), "#6b4b35")
			var rider := _create_articulated_character("#8c6845", "#b58b49", "#6b4b35", false, 0.66)
			rider.position = Vector3(0, 0.75, -0.05)
			soldier.add_child(rider)
			rig_data = rider.get_meta("rig_data")
		else:
			var uniform_color := "#526e9c" if troop_type == "infantry" else "#648d55"
			var soldier_model := _create_articulated_character(uniform_color, "#bca46e" if troop_type == "infantry" else "#648d55", "#8f3936" if troop_type == "infantry" else "#435c3a", false, 0.82)
			soldier.add_child(soldier_model)
			rig_data = soldier_model.get_meta("rig_data")
			if troop_type == "infantry":
				_add_box(soldier_model, Vector3(0.16, 0.56, 0.07), Vector3(0.35, 0.45, 0), "#cbd2d5")
				_add_box(soldier_model, Vector3(0.34, 0.42, 0.1), Vector3(-0.3, 0.55, 0.09), "#8c6845")
			else:
				_add_cylinder(soldier_model, 0.035, 0.82, Vector3(0.37, 0.55, 0), "#8a6748")
				_add_cone(soldier_model, 0.065, 0.2, Vector3(0.37, 1.02, 0), "#cbd2d5")
		add_child(soldier)
		articulated_rigs.append(rig_data)
		var destination := target_position + Vector3(lane * 0.55, 0.0, 1.1 + float(int(i / 3)) * 0.4)
		var march := create_tween()
		march.tween_property(soldier, "position", destination, 0.68 + float(i) * 0.055).set_delay(float(i) * 0.045).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		march.tween_callback(_set_rig_combat.bind(rig_data, true))
		march.tween_interval(0.48)
		march.tween_callback(_set_rig_combat.bind(rig_data, false))
		march.tween_callback(_remove_temporary_rig.bind(soldier, rig_data))
	var projectile := _add_sphere(self, Vector3(0, 1.25, 1.0), Vector3(0.25, 0.25, 0.25), "#f1d38a")
	var tween := create_tween()
	tween.tween_property(projectile, "position", target_position + Vector3(0, 1.2, 0), 0.72).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_callback(projectile.queue_free)
	tween.tween_callback(_show_battle_flash.bind(target_position + Vector3(0, 1.0, 0), victory))

func _set_rig_combat(rig_data: Dictionary, enabled: bool) -> void:
	rig_data["combat"] = enabled
	if enabled:
		rig_data["combat_elapsed"] = 0.0

func _combat_swing_curve(elapsed: float) -> float:
	# A single anticipation / strike / follow-through / recovery cycle, not a looping arm flap.
	var t := clampf(elapsed / 0.48, 0.0, 1.0)
	if t < 0.20:
		return lerpf(0.0, -0.42, t / 0.20)
	if t < 0.48:
		return lerpf(-0.42, -1.62, (t - 0.20) / 0.28)
	if t < 0.68:
		return lerpf(-1.62, -1.18, (t - 0.48) / 0.20)
	return lerpf(-1.18, 0.0, (t - 0.68) / 0.32)

func _remove_temporary_rig(character: Node3D, rig_data: Dictionary) -> void:
	articulated_rigs.erase(rig_data)
	if is_instance_valid(character):
		character.queue_free()
func play_exploration() -> void:
	var scout := Node3D.new()
	scout.name = "ExplorationScout"
	scout.position = Vector3(0.0, 0.08, 1.2)
	var scout_model := _create_articulated_character("#6c8dbe", "#bca46e", "#8f3936", false, 0.78)
	scout.add_child(scout_model)
	var rig_data: Dictionary = scout_model.get_meta("rig_data")
	articulated_rigs.append(rig_data)
	add_child(scout)
	var destination := Vector3(-10.5, 0.08, -11.5)
	var journey := create_tween()
	journey.tween_property(scout, "position", destination, 1.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	journey.tween_callback(_show_battle_flash.bind(destination + Vector3(0, 1.0, 0), true))
	journey.tween_callback(_remove_temporary_rig.bind(scout, rig_data))

func _show_battle_flash(position_value: Vector3, victory: bool) -> void:
	var flash_color := "#e4d17e" if victory else "#b53d36"
	var flash := _add_sphere(self, position_value, Vector3(0.2, 0.2, 0.2), flash_color)
	var impact_ring := _add_cylinder(self, 0.65, 0.035, position_value - Vector3(0, 0.75, 0), flash_color)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash, "scale", Vector3(1.8, 1.8, 1.8), 0.28)
	tween.tween_property(impact_ring, "scale", Vector3(1.8, 1.0, 1.8), 0.28)
	tween.tween_property(impact_ring, "transparency", 1.0, 0.28)
	tween.chain().tween_callback(flash.queue_free)
	tween.tween_callback(impact_ring.queue_free)

func _rebuild_outposts() -> void:
	for node in outpost_nodes:
		if is_instance_valid(node):
			node.free()
	outpost_nodes.clear()
	var positions := [
		Vector3(-12.0, 0.0, -9.0), Vector3(-8.0, 0.0, -13.0), Vector3(-3.0, 0.0, -14.0),
		Vector3(3.0, 0.0, -14.0), Vector3(8.0, 0.0, -13.0), Vector3(12.0, 0.0, -8.0),
		Vector3(12.0, 0.0, 1.0), Vector3(9.0, 0.0, 10.0), Vector3(2.0, 0.0, 13.0), Vector3(-9.0, 0.0, 10.0)
	]
	for i in range(positions.size()):
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
		var outpost_flag := _add_box(root, Vector3(0.55, 0.38, 0.06), Vector3(0.52, 1.63, 0.3), banner_color)
		animated_flags.append(outpost_flag)
		# Each campaign region has a distinct enemy doctrine silhouette, so scouting identifies the threat visually.
		match posmod(i, 3):
			0:
				_add_box(root, Vector3(1.9, 0.16, 0.22), Vector3(0, 0.9, -0.78), "#625f58")
				_add_box(root, Vector3(0.22, 1.05, 0.22), Vector3(-0.78, 0.88, 0.42), "#a49c89")
				_add_box(root, Vector3(0.22, 1.05, 0.22), Vector3(0.78, 0.88, 0.42), "#a49c89")
			1:
				_add_box(root, Vector3(1.05, 0.16, 0.9), Vector3(0, 1.0, -0.15), "#8b6a49")
				_add_box(root, Vector3(0.12, 1.35, 0.12), Vector3(-0.36, 1.0, -0.15), "#5e4935")
				_add_box(root, Vector3(0.12, 1.35, 0.12), Vector3(0.36, 1.0, -0.15), "#5e4935")
				_add_cylinder(root, 0.035, 0.8, Vector3(0.0, 1.6, 0.35), "#bca46e")
			2:
				_add_cone(root, 0.62, 0.78, Vector3(-0.48, 0.62, 0.62), "#8d5540")
				_add_cone(root, 0.48, 0.62, Vector3(0.48, 0.52, 0.62), "#7c4838")
				_add_box(root, Vector3(0.72, 0.12, 0.12), Vector3(0, 0.18, 0.88), "#67462f")
		if i == 9:
			# Final boss citadel gets a larger gold crown and war banner to signal the campaign climax.
			_add_cone(root, 0.72, 0.68, Vector3(0, 1.82, -0.35), "#d7b354")
			_add_cone(root, 0.18, 0.42, Vector3(-0.58, 1.45, 0.18), "#e4c77f")
			_add_cone(root, 0.18, 0.42, Vector3(0.58, 1.45, 0.18), "#e4c77f")
			_add_box(root, Vector3(0.1, 1.65, 0.1), Vector3(-0.72, 1.0, 0.48), "#4c3527")
			_add_box(root, Vector3(0.62, 0.46, 0.07), Vector3(-0.4, 1.45, 0.48), "#d7b354")
			_add_box(root, Vector3(0.08, 0.28, 0.04), Vector3(-0.4, 1.45, 0.43), "#6c2f2a")
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
			node.free()
	guard_nodes.clear()
	animated_guards.clear()
	articulated_rigs.clear()
	var visible_count := mini(current_guards, 7)
	for i in range(visible_count):
		var guard := Node3D.new()
		guard.name = "Guard_%02d" % i
		guard.position = Vector3(-0.95 + float(i % 4) * 0.55, 0.08, 1.0 + float(int(i / 4)) * 0.55)
		var troop_type := "infantry"
		if i >= current_infantry and i < current_infantry + current_archers:
			troop_type = "archer"
		elif i >= current_infantry + current_archers:
			troop_type = "cavalry"
		if troop_type == "cavalry":
			# A distinct mount silhouette with an articulated rider keeps cavalry readable at gameplay zoom.
			_add_box(guard, Vector3(0.55, 0.38, 0.85), Vector3(0, 0.48, 0), "#8c6845")
			_add_sphere(guard, Vector3(0, 0.72, -0.38), Vector3(0.26, 0.22, 0.3), "#8c6845")
			_add_sphere(guard, Vector3(0, 0.76, 0.43), Vector3(0.2, 0.19, 0.28), "#9b7650")
			for leg_x in [-0.18, 0.18]:
				for leg_z in [-0.25, 0.25]:
					var horse_leg := _add_box(guard, Vector3(0.09, 0.32, 0.09), Vector3(leg_x, 0.2, leg_z), "#6b4b35")
					horse_leg.name = "MountLeg"
			var rider := _create_articulated_character("#8c6845", "#b58b49", "#6b4b35", false, 0.66)
			rider.position = Vector3(0, 0.75, -0.05)
			guard.add_child(rider)
			articulated_rigs.append(rider.get_meta("rig_data"))
		else:
			var uniform_color := "#526e9c" if troop_type == "infantry" else "#648d55"
			var armor_color := "#bca46e" if troop_type == "infantry" else "#648d55"
			var soldier := _create_articulated_character(uniform_color, armor_color, "#8f3936" if troop_type == "infantry" else "#435c3a", false, 0.82)
			guard.add_child(soldier)
			articulated_rigs.append(soldier.get_meta("rig_data"))
			if troop_type == "infantry":
				_add_box(soldier, Vector3(0.16, 0.56, 0.07), Vector3(0.35, 0.45, 0), "#cbd2d5")
				_add_box(soldier, Vector3(0.34, 0.42, 0.1), Vector3(-0.3, 0.55, 0.09), "#8c6845")
			else:
				_add_cylinder(soldier, 0.035, 0.82, Vector3(0.37, 0.55, 0), "#8a6748")
				_add_cone(soldier, 0.065, 0.2, Vector3(0.37, 1.02, 0), "#cbd2d5")
		add_child(guard)
		guard_nodes.append(guard)
		animated_guards.append(guard)
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
	if material_cache.has(color_value):
		return material_cache[color_value] as StandardMaterial3D
	var material := StandardMaterial3D.new()
	var base_color := Color(color_value)
	material.albedo_color = base_color
	var texture_key := "noise"
	if color_value in ["#b7b1a3", "#d0c6b2", "#a7a091", "#9b9b8c", "#b9b9a9", "#858a83", "#625f58", "#a49c89", "#d0d4cf", "#a3aaa7", "#858c89"]:
		texture_key = "stone"
	elif color_value in ["#8a6242", "#5c3d2d", "#67462f", "#513b2d", "#5d4432", "#75563c", "#6b4b35", "#8b6a49", "#67462f", "#5e4935", "#4c3527"]:
		texture_key = "wood"
	elif color_value in ["#b53d36", "#7d9c78", "#d0a35a", "#f1d38a", "#d7b354", "#8f3936"]:
		texture_key = "cloth"
	elif base_color.g > base_color.r * 1.08 and base_color.g > base_color.b * 1.05:
		texture_key = "grass"
	material.albedo_texture = material_textures.get(texture_key, surface_noise) as Texture2D
	material.uv1_scale = Vector3(2.0, 2.0, 2.0)
	material.roughness = 0.78
	# Reflective accents are polished; stone, earth and cloth remain matte.
	if base_color.r > 0.68 and base_color.g > 0.42 and base_color.b < 0.72:
		material.metallic = 0.22
		material.roughness = 0.48
	elif base_color.r > 0.55 and base_color.g > 0.58 and base_color.b > 0.58:
		material.metallic = 0.12
		material.roughness = 0.62
	if color_value in ["#e7ad52", "#e4c77f", "#f1d38a", "#d7b354"]:
		material.emission_enabled = true
		material.emission = base_color * 0.24
	material_cache[color_value] = material
	return material
