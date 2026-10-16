extends Node3D

var building_nodes: Array[Node3D] = []
var outpost_nodes: Array[Node3D] = []
var guard_nodes: Array[Node3D] = []
var selected_outpost := 0
var selected_tile_index := 4
var tile_highlight: Node3D
var current_tiles: Array[String] = ["Empty", "Farm", "Empty", "Mine", "Keep", "Empty", "Empty", "Barracks", "Empty"]
var current_levels := PackedInt32Array([1, 1, 1, 1, 1, 1, 1, 1, 1])
var current_keep_level := 1
var current_guards := 10
var current_outposts := PackedInt32Array([0, 0, 0])

func _ready() -> void:
	_build_environment()
	_build_terrain()
	_build_landmarks()
	_rebuild_buildings()
	_rebuild_outposts()
	_rebuild_guards()

func set_kingdom_state(tile_data: Array, level_data: PackedInt32Array, keep_level: int, guards: int, defeated: PackedInt32Array, target: int, selected_tile: int) -> void:
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
	var next_keep_level := clampi(keep_level, 1, 99)
	var next_guards := maxi(guards, 0)
	var next_target := clampi(target, 0, 2)
	var next_selected_tile := clampi(selected_tile, 0, 8)
	var buildings_changed := current_tiles != next_tiles or current_levels != next_levels or current_keep_level != next_keep_level
	var outposts_changed := current_outposts != next_outposts or selected_outpost != next_target
	var guards_changed := current_guards != next_guards
	var tile_selection_changed := selected_tile_index != next_selected_tile
	current_tiles = next_tiles
	current_levels = next_levels
	current_keep_level = next_keep_level
	current_guards = next_guards
	current_outposts = next_outposts
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

	var camera := Camera3D.new()
	camera.position = Vector3(0, 14.5, 19)
	camera.fov = 42
	add_child(camera)
	camera.look_at(Vector3(0, 0, -0.5), Vector3.UP)
	camera.current = true

func _build_terrain() -> void:
	_add_box(self, Vector3(30, 0.35, 30), Vector3(0, -0.28, -1), "#668b52")
	var tile_colors := ["#759b5c", "#80a760", "#729654", "#80a760", "#86a966", "#729654", "#759b5c", "#80a760", "#759b5c"]
	for i in range(9):
		var x := float(i % 3 - 1) * 3.7
		var z := float(int(i / 3) - 1) * 3.7
		_add_box(self, Vector3(3.45, 0.08, 3.45), Vector3(x, -0.055, z), tile_colors[i])
		_add_box(self, Vector3(0.055, 0.025, 3.45), Vector3(x + 1.72, 0.01, z), "#b6a77a")
		_add_box(self, Vector3(3.45, 0.025, 0.055), Vector3(x, 0.01, z + 1.72), "#b6a77a")
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

func _build_landmarks() -> void:
	# Roads connect the central keep to the river crossing and outer regions.
	_add_box(self, Vector3(0.6, 0.035, 11.5), Vector3(0, 0.03, 0), "#c2ae7b")
	_add_box(self, Vector3(7.8, 0.035, 0.6), Vector3(3.5, 0.035, 2.1), "#c2ae7b")
	_add_box(self, Vector3(0.55, 0.035, 8.0), Vector3(7.25, 0.035, -4.0), "#c2ae7b")

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
	else:
		_add_box(root, Vector3(0.8, 0.55, 0.8), Vector3(0, 0.32, 0), "#8a6242")
	return root

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
		var wall_color := "#858a83" if defeated else "#744d48"
		var banner_color := "#7d9c78" if defeated else "#b53d36"
		_add_box(root, Vector3(1.55, 0.75, 1.45), Vector3(0, 0.38, 0), wall_color)
		for side in [-1.0, 1.0]:
			_add_box(root, Vector3(0.28, 1.45, 0.28), Vector3(side * 0.55, 0.72, -0.48), wall_color)
			_add_cone(root, 0.22, 0.36, Vector3(side * 0.55, 1.62, -0.48), "#504b46")
		_add_box(root, Vector3(0.07, 1.1, 0.07), Vector3(0.25, 1.45, 0.3), "#5e4935")
		_add_box(root, Vector3(0.55, 0.38, 0.06), Vector3(0.52, 1.63, 0.3), banner_color)
		if i == selected_outpost:
			_add_cylinder(root, 1.45, 0.045, Vector3(0, 0.08, 0), "#f1d38a")
		var label := Label3D.new()
		label.text = "OUTPOST %d%s" % [i + 1, " • SECURED" if defeated else ""]
		label.position = Vector3(0, 2.15, 0)
		label.font_size = 32
		label.modulate = Color("#fff0c9")
		root.add_child(label)
		add_child(root)
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
