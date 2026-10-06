extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size = Vector2i(1280, 800)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_run()
	game.running = false
	game.player.enabled = false
	game.player.position = Vector3(-.55, .02, -7.8)
	game.player.camera.look_at(game.level.prop("Sink").global_position + Vector3(0, .7, 0))
	for id in [0,26,0]:
		game.director.reset_room(2,id)
		assert(game.level.prop("Sink/BloodStream").visible == (id == 26))
		await create_timer(.3).timeout
		await process_frame
		await process_frame
		root.get_texture().get_image().save_png("res://docs/sink_%s.png" % ("blood" if id == 26 else "normal"))
	game.free()
	print("SINK: model rendered; event 26 and reset passed")
	quit()
