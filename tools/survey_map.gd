extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size = Vector2i(1200, 760)
	var level = load("res://scenes/school_level.tscn").instantiate()
	root.add_child(level)
	level.get_node("Props").hide()
	level.environment.environment.ambient_light_energy = 0.8
	var sun := DirectionalLight3D.new()
	level.add_child(sun)
	sun.rotation_degrees = Vector3(-50, -30, 0)
	var camera := Camera3D.new()
	level.add_child(camera)
	for shot in [
		["overview", Vector3(-24, 32, 38), Vector3(-4, 0, 9)],
		["stair-entry", Vector3(0, 1.65, -10), Vector3(-1, 1.65, -16)],
		["stair-base", Vector3(0, 1.65, -15), Vector3(0, 3, -19)],
		["stair-middle", Vector3(-1.8, 6, -19), Vector3(0, 5.5, -15)],
		["rooftop", Vector3(-6, 10.45, -12), Vector3(-4, 10.45, -18)],
		["roof-inside", Vector3(-1.9, 10.43, -13.9), Vector3(-4, 10.43, -13.9)],
		["far-hall", Vector3(0, 1.65, 33), Vector3(0, 1.65, 45)]]:
		camera.position = shot[1]
		camera.look_at(shot[2])
		await process_frame
		await process_frame
		await create_timer(0.2).timeout
		root.get_texture().get_image().save_png("res://docs/survey-%s.png" % shot[0])
	level.queue_free()
	await process_frame
	quit()
