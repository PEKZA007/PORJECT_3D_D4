extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.progress.path = "res://ending_revision_progress.cfg"
	game.get_node("HUD").settings_path = "res://ending_revision_settings.cfg"
	root.add_child(game)
	await process_frame
	game.progress.endings.assign(["normal", "true"])
	game.hud.open_collection(game.progress, game.director.definitions)
	for id in ["normal", "true"]:
		game.replay_ending(id)
		game.cutscene.set_process(false)
		if id == "normal":
			var previous: Vector2 = game.cutscene.normal_pose(0, 4)
			for tick in range(1, 1081):
				var pose: Vector2 = game.cutscene.normal_pose(tick / 60.0, 4)
				assert(absf(pose.x - previous.x) < .06, "Patrol position stays continuous")
				assert(absf(pose.y - previous.y) < .09, "Heading turns continuously")
				assert(pose.x >= 0 and pose.x <= 4)
				previous = pose
		var shots: Array[int] = []
		for time in ([1, 5, 9, 14] if id == "normal" else [1, 5, 8, 12, 15, 20]):
			game.cutscene.clock_time = time
			game.cutscene.update_shot(.2)
			assert(not shots.has(game.cutscene.shot_index), "Each timestamp must show a distinct camera shot")
			shots.append(game.cutscene.shot_index)
			assert(game.cutscene.camera.position.is_finite())
			if id == "true" and time >= 10:
				assert(game.cutscene.animator.current_animation == "Idle")
				assert(is_zero_approx(game.cutscene.actor_speed))
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://docs/ending_%s_%02d.png" % [id, time])
		game.cutscene.finish()
		await process_frame
	game.queue_free()
	await process_frame
	print("ENDING CAPTURE: PASS")
	quit()
