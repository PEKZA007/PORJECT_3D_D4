extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var scene := Node3D.new()
	root.add_child(scene)
	for i in 2:
		var model = load("res://assets/models/%s.glb" % ("npc" if i == 0 else "player")).instantiate()
		scene.add_child(model)
		model.position.x = -0.8 if i == 0 else 0.8
		for a in model.find_children("*", "AnimationPlayer", true, false):
			print("ANIMATOR ", model.get_path_to(a), " ", a.get_animation_list())
		for sk in model.find_children("*", "Skeleton3D", true, false):
			print("SKELETON ", model.get_path_to(sk))
		for mesh in model.find_children("*", "MeshInstance3D", true, false):
			print("MESH ", model.get_path_to(mesh), " TRANSFORM ", model.global_transform.affine_inverse() * mesh.global_transform)
	var camera := Camera3D.new()
	scene.add_child(camera)
	camera.position = Vector3(0,1,4)
	camera.look_at(Vector3(0,.85,0))
	var light := DirectionalLight3D.new()
	scene.add_child(light)
	light.rotation_degrees = Vector3(-25,-25,0)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(.2,.23,.25)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = .6
	scene.add_child(env)
	await create_timer(1).timeout
	root.get_texture().get_image().save_png("res://docs/character-source.png")
	quit()
