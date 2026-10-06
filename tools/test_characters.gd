extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func shot(path: String) -> void:
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png(path)
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_run()
	game.running = false
	game.player.enabled = false
	var walker = game.level.prop("Walker")
	assert(walker.art != null and walker.animator.has_animation("Walk"))
	walker.position = Vector3(0,0,29)
	walker.rotation.y = PI
	game.player.position = Vector3(0,.05,32)
	game.player.camera.look_at(Vector3(0,1.15,29))
	for i in 20:
		walker.animate(.025,"Walk")
	await shot("res://docs/npc-animated.png")
	var before: float = walker.animator.current_animation_position
	await create_timer(.2).timeout
	assert(is_equal_approx(walker.animator.current_animation_position,before))
	game.player.body_animator.play("Walk")
	game.player.body_animator.advance(.25)
	walker.hide()
	var camera := Camera3D.new()
	game.add_child(camera)
	camera.cull_mask = 1 | 8
	camera.position = game.player.position + Vector3(0,1.05,-3)
	camera.look_at(game.player.position + Vector3(0,.9,0))
	camera.make_current()
	await shot("res://docs/player-animated.png")
	assert(game.player.body_animator.has_animation("Run"))
	game.player.camera.make_current()
	game.player.position = Vector3(-.8,.02,24.5)
	game.player.camera.look_at(Vector3(.90,1.4,24.5))
	await shot("res://docs/player-mirror.png")
	game.director.reset_room(2,8)
	walker.position = Vector3(0,0,29)
	walker.rotation.y = PI
	game.player.position = Vector3(0,.05,32)
	game.player.camera.look_at(Vector3(0,1.4,29))
	walker.animate(.2,"Walk")
	await shot("res://docs/npc-faceless.png")
	game.resume_game()
	Input.action_press("move_forward")
	Input.action_press("sprint")
	await create_timer(.15).timeout
	assert(game.player.body_motion == "Run")
	Input.action_release("sprint")
	await create_timer(.15).timeout
	assert(game.player.body_motion == "Walk")
	Input.action_release("move_forward")
	await create_timer(.15).timeout
	assert(game.player.body_motion == "Idle")
	game.pause_game()
	var animation_time: float = game.player.body_animator.current_animation_position
	await create_timer(.15).timeout
	assert(is_equal_approx(game.player.body_animator.current_animation_position, animation_time))
	print("CHARACTER CHECKS: PASS")
	game.queue_free()
	await process_frame
	await create_timer(.2).timeout
	quit()
