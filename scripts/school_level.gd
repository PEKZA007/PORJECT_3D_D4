extends Node3D
## The imported asset stays intact; runtime overrides fix glTF metallic defaults.
@export var normalize_imported_materials: bool = true
@export_group("Event Positions")
@export var walker_patrol_z := Vector2(7.0, 22.0)
@export var footsteps_trigger_z: float = 6.0
@export var attacker_trigger_z: float = 18.0
@export var door_trigger_z: float = 3.0
@export var door_slide_distance: float = 1.5
@export_group("Route")
@export var forward_exit_half_size := Vector3(0.8, 1.25, 0.5)
@export var back_exit_half_size := Vector3(0.9, 1.25, 0.4)
@export var fall_reset_height: float = -7.0
@onready var props: Node3D = $Props
@onready var lights: Node3D = $Lights
@onready var environment: WorldEnvironment = $WorldEnvironment
@export_group("Atmosphere")
@export var ambient_floor: float = 0.012
@export var ambient_per_power: float = 0.035
@export var tube_emission_per_power: float = 0.08
var authored_light_energy: Dictionary = {}
var fluorescent_materials: Array[StandardMaterial3D] = []
var mirror_view: SubViewport
var mirror_camera: Camera3D
var reflection_avatar: Node3D
var mirror_player: CharacterBody3D
var ghost_reflection: bool = false
var door_closed_position := Vector3.ZERO
var door_opened_by_player: bool = false

func _ready() -> void:
	setup_new_props()
	for light in lights.get_children():
		if light is OmniLight3D:
			authored_light_energy[light] = light.light_energy
	door_closed_position = prop("Door").position
	if normalize_imported_materials:
		prepare_model($SchoolModel)
	if has_node("ClassroomLuminaire"):
		fluorescent_materials.append($ClassroomLuminaire.material_override)

func setup_new_props() -> void:
	var charm := Node3D.new()
	charm.name = "CharmPickup"
	props.add_child(charm)
	charm.position = Vector3(.65, 1.1, 38.5)
	var art = preload("res://assets/models/props/omamori.scn").instantiate()
	charm.add_child(art)
	art.rotation_degrees.y = 90
	preload("res://scripts/prop_mounting.gd").mount_right(charm)
	var label := Label3D.new()
	label.text = "เครื่องราง\n[E] เก็บ"
	label.font_size = 40
	label.pixel_size = .002
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position.y = .28
	charm.add_child(label)
	charm.hide()
	var sign := Label3D.new()
	sign.name = "NoRunningSign"
	sign.text = "ห้ามวิ่ง\nNO RUNNING\nเดินไปข้างหน้าต่อไป"
	sign.font_size = 64
	sign.pixel_size = .002
	sign.modulate = Color(.65, .04, .025)
	sign.outline_size = 0
	sign.position = Vector3(.82, 1.65, 34)
	sign.rotation_degrees.y = -90
	props.add_child(sign)
	var board := MeshInstance3D.new()
	board.name = "Board"
	var panel := QuadMesh.new()
	panel.size = Vector2(1.25, .55)
	board.mesh = panel
	var paper := StandardMaterial3D.new()
	paper.albedo_color = Color(.88, .83, .69)
	paper.roughness = .9
	board.material_override = paper
	board.position.z = -.012
	sign.add_child(board)
	preload("res://scripts/prop_mounting.gd").mount_right(sign)
	sign.hide()

func prepare_model(node: Node) -> void:
	if node is MeshInstance3D:
		for i in node.mesh.get_surface_count():
			var original = node.mesh.surface_get_material(i)
			if original is StandardMaterial3D:
				var material: StandardMaterial3D = original.duplicate()
				material.metallic = 0.0
				material.roughness = 0.82
				if "Emissive" in material.resource_name:
					material.emission_enabled = true
					material.emission = Color(0.58, 0.67, 0.57)
					material.emission_energy_multiplier = 0.5
					fluorescent_materials.append(material)
				node.set_surface_override_material(i, material)
		if node.name in ["Object_130", "Object_132", "Object_253", "Object_255", "Object_364", "Object_366", "Object_241", "Object_243", "Object_245", "Object_360", "Object_87", "Object_106"]:
			node.hide()
	for child in node.get_children():
		prepare_model(child)

func prop(path: String) -> Node3D:
	return props.get_node(path)

func set_lighting(power: float) -> void:
	for light in lights.get_children():
		if light is OmniLight3D:
			light.light_energy = float(authored_light_energy.get(light, 0.5)) * power / 1.2
	environment.environment.ambient_light_energy = ambient_floor + power * ambient_per_power
	for m in fluorescent_materials:
		m.emission_energy_multiplier = power * tube_emission_per_power

func set_room(number: int) -> void:
	door_opened_by_player = false
	prop("RoomNumber").text = "%02d" % number
	prop("Note").visible = number == 1

func exit_at(world_position: Vector3) -> int:
	# Separate 3D volumes: a matching Z on another floor must never end a round.
	var forward: Vector3 = $ForwardExit.to_local(world_position).abs()
	if forward.x < forward_exit_half_size.x and forward.y < forward_exit_half_size.y and forward.z < forward_exit_half_size.z:
		return 1
	var back: Vector3 = $BackExit.to_local(world_position).abs()
	if back.x < back_exit_half_size.x and back.y < back_exit_half_size.y and back.z < back_exit_half_size.z:
		return -1
	return 0

func passed_ground_trigger(z: float) -> bool:
	return mirror_player.position.z < z and mirror_player.position.z > -10.0 and absf(mirror_player.position.y) < 0.5

func update_door_collision() -> void:
	if prop("Door").has_node("Collision"):
		prop("Door").get_node("Collision").collision_layer = 1 if prop("Door").visible else 0

func toggle_classroom_door() -> void:
	door_opened_by_player = not door_opened_by_player
	prop("Door").position = door_closed_position + Vector3(0, 0, door_slide_distance if door_opened_by_player else 0.0)

func setup_mirror(actor: CharacterBody3D) -> void:
	mirror_player = actor
	mirror_view = SubViewport.new()
	mirror_view.name = "MirrorViewport"
	mirror_view.size = Vector2i(384, 780)
	mirror_view.world_3d = get_world_3d()
	mirror_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(mirror_view)
	mirror_camera = Camera3D.new()
	mirror_view.add_child(mirror_camera)
	mirror_camera.cull_mask = 1 | 8
	mirror_camera.current = true
	# Layer 2 is the mirror surface. Layer 4 is a body visible only in reflection.
	var surface: MeshInstance3D = prop("Mirror/Surface")
	surface.mesh = QuadMesh.new()
	surface.mesh.size = Vector2(0.66, 1.34)
	surface.rotation_degrees.y = -90
	surface.position.x = -0.043
	surface.layers = 2
	var reflected_material := StandardMaterial3D.new()
	reflected_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	reflected_material.albedo_texture = mirror_view.get_texture()
	reflected_material.uv1_scale.x = -1.0
	reflected_material.uv1_offset.x = 1.0
	surface.material_override = reflected_material
	reflection_avatar = prop("Walker").duplicate()
	reflection_avatar.name = "ReflectionAvatar"
	add_child(reflection_avatar)
	set_layers_recursive(reflection_avatar, 4)
	mirror_player.camera.cull_mask = 1 | 2 | 16

func set_layers_recursive(node: Node, layer: int) -> void:
	if node is VisualInstance3D:
		node.layers = layer
	for child in node.get_children():
		set_layers_recursive(child, layer)

func set_ghost_reflection(ghost: bool) -> void:
	ghost_reflection = ghost
	mirror_camera.cull_mask = (1 | 4) if ghost else (1 | 8)
	if not is_instance_valid(reflection_avatar):
		return
	reflection_avatar.visible = ghost
	reflection_avatar.apply_variant("ghost" if ghost else "normal")
	set_layers_recursive(reflection_avatar, 4)
	for part_name in ["Head", "Body", "LeftEye", "RightEye"]:
		var part: MeshInstance3D = reflection_avatar.get_node(part_name)
		var source: MeshInstance3D = prop("Walker").get_node(part_name)
		var m: StandardMaterial3D = source.material_override.duplicate()
		if ghost:
			m.albedo_color = Color("912638") if "Eye" in part_name else Color("d1d7c2")
		part.material_override = m

func _process(_delta: float) -> void:
	if not is_instance_valid(mirror_player):
		return
	var surface: Node3D = prop("Mirror/Surface")
	var eye: Vector3 = mirror_player.camera.global_position
	var center: Vector3 = surface.global_position
	if absf(eye.z - center.z) > 8.0:
		mirror_view.render_target_update_mode = SubViewport.UPDATE_DISABLED
		return
	mirror_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	# Off-axis projection clips the classroom wall between the reflected eye and glass.
	var reflected_eye := Vector3(2.0 * center.x - eye.x, eye.y, eye.z)
	mirror_camera.global_position = reflected_eye
	mirror_camera.look_at(reflected_eye + Vector3.LEFT)
	var near_plane := maxf(0.05, reflected_eye.x - center.x + 0.015)
	mirror_camera.set_frustum(1.34, Vector2(eye.z - center.z, center.y - eye.y), near_plane, 70.0)
	reflection_avatar.global_transform = mirror_player.global_transform
	reflection_avatar.rotation.y = mirror_player.camera.global_rotation.y
	reflection_avatar.get_node("Head").rotation.x = mirror_player.camera.rotation.x

func _exit_tree() -> void:
	if is_instance_valid(mirror_view):
		var surface: MeshInstance3D = get_node("Props/Mirror/Surface")
		if surface.material_override is StandardMaterial3D:
			surface.material_override.albedo_texture = null
		mirror_view.world_3d = null

