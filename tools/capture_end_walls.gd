extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_run()
	game.running = false
	game.player.enabled = false
	game.player.position = Vector3(0,.02,42)
	game.player.rotation.y = PI
	await process_frame
	await process_frame
	await create_timer(.5).timeout
	root.get_texture().get_image().save_png("res://docs/end-wall-back.png")
	game.player.position = Vector3(0,.02,-9)
	game.player.rotation.y = 0
	await process_frame
	await process_frame
	await create_timer(.5).timeout
	root.get_texture().get_image().save_png("res://docs/end-wall-front.png")
	game.queue_free()
	await process_frame
	await create_timer(.2).timeout
	quit()
