extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func shot(path: String) -> void:
	await process_frame
	await process_frame
	await create_timer(.3).timeout
	root.get_texture().get_image().save_png(path)
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_run()
	game.running = false
	game.player.enabled = false
	await shot("res://docs/horror-hallway.png")
	game.player.get_node("Camera3D/Flashlight").hide()
	await shot("res://docs/horror-no-flashlight.png")
	game.player.get_node("Camera3D/Flashlight").show()
	game.player.position = Vector3(0,.02,-9)
	await shot("res://docs/horror-wall.png")
	game.player.position = Vector3(0,.02,32)
	game.player.camera.look_at(game.level.prop("Posters").global_position+Vector3(0,1.3,0))
	await shot("res://docs/horror-observation.png")
	game.queue_free()
	await process_frame
	await create_timer(.2).timeout
	quit()
