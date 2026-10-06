extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_run()
	game.player.position = Vector3(0,.05,-10.5)
	Input.action_press("move_forward")
	await create_timer(.7).timeout
	Input.action_release("move_forward")
	await create_timer(1.2).timeout
	assert(game.room == 2, "Forward mist must allow room transition")
	game.load_room(2,4)
	game.rings = 1
	game.player.position = Vector3(0,.05,44)
	game.player.rotation.y = PI
	Input.action_press("move_forward")
	await create_timer(.7).timeout
	Input.action_release("move_forward")
	await create_timer(1.2).timeout
	assert(game.room == 3, "Return mist must allow anomaly return")
	print("MIST PASSAGES: PASS — walked through both endpoints")
	game.queue_free()
	await process_frame
	await create_timer(.2).timeout
	quit()
