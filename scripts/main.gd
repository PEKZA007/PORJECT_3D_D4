extends Node3D

const PLAYER_SCRIPT: Script = preload("res://scripts/player.gd")

var player: CharacterBody3D
var warehouse_light: OmniLight3D
var red_light: OmniLight3D

func _ready() -> void:
	_build_scene()
	_build_player()

func _process(_delta: float) -> void:
	if warehouse_light != null:
		var flicker: float = 0.94 + sin(Time.get_ticks_msec() * 0.017) * 0.035
		warehouse_light.light_energy = flicker
	if red_light != null:
		red_light.light_energy = 0.4 + sin(Time.get_ticks_msec() * 0.003) * 0.12

func _build_scene() -> void:
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	world_environment.name = "NightEnvironment"
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#05060a")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#4d5870")
	environment.ambient_light_energy = 0.22
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_light_color = Color("#151925")
	environment.fog_light_energy = 0.45
	environment.fog_density = 0.018
	world_environment.environment = environment
	add_child(world_environment)

	var moon: DirectionalLight3D = DirectionalLight3D.new()
	moon.name = "Moonlight"
	moon.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
	moon.light_color = Color("#8592ba")
	moon.light_energy = 0.28
	moon.shadow_enabled = true
	add_child(moon)

	warehouse_light = OmniLight3D.new()
	warehouse_light.name = "WarehouseFlicker"
	warehouse_light.position = Vector3(0.0, 5.4, 0.0)
	warehouse_light.omni_range = 17.0
	warehouse_light.light_color = Color("#ffd7a0")
	warehouse_light.light_energy = 0.95
	warehouse_light.shadow_enabled = true
	add_child(warehouse_light)

	red_light = OmniLight3D.new()
	red_light.name = "RedWarningLight"
	red_light.position = Vector3(0.0, 3.2, -8.0)
	red_light.omni_range = 8.0
	red_light.light_color = Color("#d11f38")
	red_light.light_energy = 0.4
	add_child(red_light)

	_add_box("Floor", Vector3(28.0, 0.25, 21.0), Vector3(0.0, -0.25, 0.0), _material(Color("#17151a"), 0.9))
	_add_box("BackWall", Vector3(28.0, 6.5, 0.35), Vector3(0.0, 3.0, -10.35), _material(Color("#20202a"), 0.9))
	_add_box("LeftWall", Vector3(0.35, 6.5, 21.0), Vector3(-13.8, 3.0, 0.0), _material(Color("#1b1c26"), 0.95))
	_add_box("RightWall", Vector3(0.35, 6.5, 21.0), Vector3(13.8, 3.0, 0.0), _material(Color("#1b1c26"), 0.95))
	_add_box("Roof", Vector3(28.0, 0.25, 21.0), Vector3(0.0, 6.25, 0.0), _material(Color("#101117"), 1.0))

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0.0, 1.75, 8.0)
	player.set_script(PLAYER_SCRIPT)
	var capsule: CollisionShape3D = CollisionShape3D.new()
	var capsule_shape: CapsuleShape3D = CapsuleShape3D.new()
	capsule_shape.radius = 0.38
	capsule_shape.height = 1.7
	capsule.shape = capsule_shape
	player.add_child(capsule)

	var camera: Camera3D = Camera3D.new()
	camera.name = "Camera3D"
	camera.fov = 72.0
	camera.current = true
	player.add_child(camera)
	var flashlight: SpotLight3D = SpotLight3D.new()
	flashlight.name = "Flashlight"
	flashlight.position = Vector3(0.0, -0.05, -0.15)
	flashlight.rotation_degrees = Vector3(-3.0, 0.0, 0.0)
	flashlight.spot_range = 14.0
	flashlight.spot_angle = 42.0
	flashlight.light_energy = 3.0
	flashlight.light_color = Color("#d9e4ff")
	flashlight.shadow_enabled = true
	camera.add_child(flashlight)
	add_child(player)

func _add_box(node_name: String, size: Vector3, position: Vector3, material: Material) -> MeshInstance3D:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	return _add_mesh(node_name, mesh, position, Vector3.ONE, material)

func _add_mesh(node_name: String, mesh: Mesh, position: Vector3, scale: Vector3, material: Material) -> MeshInstance3D:
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = position
	instance.scale = scale
	instance.material_override = material
	add_child(instance)
	return instance

func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material
