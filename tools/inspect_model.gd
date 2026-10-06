extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var model = load("res://assets/models/school.glb").instantiate()
	world.add_child(model)
	model.position.x = 58.45
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("80949e")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.8
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	world.add_child(sun)
	sun.rotation_degrees = Vector3(-40, 30, 0)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.position = Vector3(0, 1.65, 0)
	camera.look_at(Vector3(0, 1.65, 20))
	root.size = Vector2i(1280, 720)
	await process_frame
	await process_frame
	await create_timer(2).timeout
	root.get_texture().get_image().save_png("res://docs/model-inspection.png")
	quit()
