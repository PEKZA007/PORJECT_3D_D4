extends Node3D

const PLAYER_SCRIPT: Script = preload("res://scripts/player.gd")
const SCENE_OFFSET: Vector3 = Vector3(70.484, 4.971335, 20.99261)

var school_scene: Node3D
var player: CharacterBody3D

func _ready() -> void:
	school_scene = $SchoolHallway
	school_scene.position = SCENE_OFFSET
	_prepare_scene_materials()
	_setup_environment()
	_setup_scene_collision()
	_build_player()

func _prepare_scene_materials() -> void:
	var mesh_nodes: Array[Node] = school_scene.find_children("*", "MeshInstance3D", true, false)
	for node: Node in mesh_nodes:
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		for surface: int in mesh_instance.mesh.get_surface_count():
			var material: Material = mesh_instance.mesh.surface_get_material(surface)
			if material is StandardMaterial3D:
				var imported_material: StandardMaterial3D = material as StandardMaterial3D
				var visible_material: StandardMaterial3D = imported_material.duplicate() as StandardMaterial3D
				visible_material.cull_mode = BaseMaterial3D.CULL_DISABLED
				visible_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
				visible_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
				visible_material.metallic = 0.0
				visible_material.roughness = 0.82
				if visible_material.albedo_texture != null:
					visible_material.albedo_color = Color.WHITE
				mesh_instance.set_surface_override_material(surface, visible_material)

func _setup_environment() -> void:
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	world_environment.name = "HallwayEnvironment"
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#202630")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#ffffff")
	environment.ambient_light_energy = 1.1
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.adjustment_enabled = true
	environment.adjustment_brightness = 1.12
	environment.adjustment_contrast = 0.98
	environment.adjustment_saturation = 1.0
	world_environment.environment = environment
	add_child(world_environment)

	var fill_light: DirectionalLight3D = DirectionalLight3D.new()
	fill_light.name = "HallwayFillLight"
	fill_light.rotation_degrees = Vector3(-52.0, -28.0, 0.0)
	fill_light.light_color = Color("#ffffff")
	fill_light.light_energy = 1.0
	fill_light.shadow_enabled = true
	add_child(fill_light)

func _setup_scene_collision() -> void:
	var mesh_nodes: Array[Node] = school_scene.find_children("*", "MeshInstance3D", true, false)
	for node: Node in mesh_nodes:
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		if mesh_instance != null and mesh_instance.mesh != null:
			mesh_instance.create_trimesh_collision()

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(6.8, 10.8, 33.0)
	player.rotation_degrees.y = 180.0
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
	flashlight.spot_range = 18.0
	flashlight.spot_angle = 42.0
	flashlight.light_energy = 2.8
	flashlight.light_color = Color("#e3edff")
	flashlight.shadow_enabled = true
	camera.add_child(flashlight)
	add_child(player)
