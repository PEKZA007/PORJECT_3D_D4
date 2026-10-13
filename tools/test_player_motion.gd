extends SceneTree
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.progress.path = "res://player_motion_test_progress.cfg"
	game.get_node("HUD").settings_path = "res://player_motion_test_settings.cfg"
	root.add_child(game)
	await process_frame
	var player = game.player
	game.running = false
	player.enabled = false
	player.velocity = Vector3(0, 0, -player.walk_speed)
	player.update_body(.4, player.walk_speed)
	assert(player.body_motion == "Walk")
	var fast: float = absf(player.body_playback_rate)
	player.update_body(.4, player.walk_speed * .4)
	assert(absf(player.body_playback_rate) < fast)
	player.update_body(.3, 0)
	assert(player.body_motion == "Idle", "Blocked movement rests instead of walking in place")
	player.velocity = Vector3(0, 0, player.walk_speed)
	player.update_body(.5, player.walk_speed)
	assert(player.body_playback_rate < 0, "Backwards gait reverses")
	player.velocity = Vector3(player.walk_speed, 0, 0)
	player.update_body(.4, player.walk_speed)
	assert(absf(wrapf(player.get_node("BodyVisual").rotation.y - PI, -PI, PI)) > .1)
	assert(absf(wrapf(player.get_node("BodyVisual").rotation.y - PI, -PI, PI)) <= .501)
	player.sprinting = true
	var gait_phase: float = player.body_animator.current_animation_position / player.body_animator.current_animation_length
	player.update_body(.00001, player.sprint_speed)
	var run_phase: float = player.body_animator.current_animation_position / player.body_animator.current_animation_length
	assert(absf(wrapf(run_phase - gait_phase, -.5, .5)) < .001, "Walk to Run preserves the supporting leg")
	player.update_body(.3, player.sprint_speed)
	assert(player.body_motion == "Run")
	player.reset_at(Transform3D.IDENTITY)
	assert(player.body_motion == "Idle" and is_equal_approx(player.body_playback_rate, 1))
	var frozen: float = player.body_animator.current_animation_position
	await create_timer(.1).timeout
	assert(is_equal_approx(frozen, player.body_animator.current_animation_position))
	if DisplayServer.get_name() != "headless":
		game.load_room(2, 0)
		game.hud.hide_menu()
		game.hud.fade.color.a = 0
		game.level.set_lighting(1.8)
		game.level.prop("Walker").hide()
		player.position = Vector3(0, 0, 29)
		var camera := Camera3D.new()
		game.add_child(camera)
		camera.cull_mask = 1 | 8
		camera.position = Vector3(-.6, 1.2, 26)
		camera.look_at(player.position + Vector3.UP * .9)
		camera.current = true
		for state in ["Idle", "Walk", "Run"]:
			player.sprinting = state == "Run"
			player.velocity = Vector3.ZERO if state == "Idle" else Vector3(0, 0, -player.walk_speed)
			player.update_body(.25, 0 if state == "Idle" else (player.sprint_speed if state == "Run" else player.walk_speed))
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://docs/player_motion_%s.png" % state.to_lower())
	game.queue_free()
	await process_frame
	print("PLAYER MOTION: PASS (cadence, blocked movement, backward, strafe, reset, pause)")
	quit()
