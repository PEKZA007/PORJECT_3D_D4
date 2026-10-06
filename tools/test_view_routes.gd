extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_run()
	game.running = false
	game.player.enabled = false
	game.player.camera.rotation.x = -1.48
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("res://docs/first-person-feet.png")
	game.player.camera.rotation.x = 0
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("res://docs/first-person-forward.png")
	check(game.player.camera.position.z < -.1,"Camera must be in front of face")
	check((game.player.camera.cull_mask & 16) != 0,"First-person body visible")
	check((game.level.mirror_camera.cull_mask & 8) != 0,"Mirror retains full player")
	game.player.position = Vector3(0,.05,-11.5)
	game.player.enabled = true
	Input.action_press("move_forward")
	await create_timer(1).timeout
	Input.action_release("move_forward")
	check(game.player.position.z > -12.4,"Closed stairwell must block movement")
	game.player.position = Vector3(0,.05,44.8)
	game.player.rotation.y = PI
	Input.action_press("move_forward")
	await create_timer(1).timeout
	Input.action_release("move_forward")
	check(game.player.position.z < 46,"Far boundary must block movement")
	game.player.position = Vector3(0,.05,20)
	game.player.rotation.y = PI/2
	Input.action_press("move_forward")
	await create_timer(1).timeout
	Input.action_release("move_forward")
	check(game.player.position.x > -1.5,"Window side must block movement")
	game.player.enabled = false
	game.running = true
	game.player.position = game.level.get_node("ForwardExit").position
	game.choose_exit(false)
	await create_timer(1.2).timeout
	check(game.room == 2,"Exit remains reachable before barrier")
	print("VIEW AND BOUNDARIES: ", "PASS" if failures == 0 else "FAIL")
	game.queue_free()
	await process_frame
	await create_timer(.2).timeout
	quit(failures)
