extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(1280,800)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_run()
	game.running = false
	game.player.enabled = false
	game.load_room(2,18)
	game.level.prop("WindowWatcher").animate(.25,"Walk")
	for i in 2:
		game.player.position = Vector3(.2,.02,10.3 if i == 0 else 11.48)
		var target := Vector3(-1.95,1.6,11.48)
		game.player.look_at(Vector3(target.x,.02,target.z))
		game.player.camera.look_at(target)
		game.player.get_node("Camera3D/Flashlight").visible = i == 0
		await create_timer(.4).timeout
		await process_frame
		root.get_texture().get_image().save_png("res://docs/watcher_%s.png" % ("approach" if i == 0 else "no_flashlight"))
	game.director.reset_room(2,0)
	assert(not game.level.prop("WindowWatcher").is_visible_in_tree())
	assert(not game.level.prop("WindowWatcher/FaceLight").is_visible_in_tree())
	game.player.position = Vector3(0,.02,11.48)
	game.player.rotation.y = PI/2
	game.player.enabled = true
	Input.action_press("move_forward")
	await create_timer(1).timeout
	Input.action_release("move_forward")
	assert(game.player.position.x > -1.6,"Window collision must still block the player")
	game.queue_free()
	await process_frame
	print("WATCHER PASS: normal/flashlight views, reset, window collision")
	quit()
