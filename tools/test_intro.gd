extends SceneTree
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.progress.path = "res://intro_test_progress.cfg"
	game.get_node("HUD").settings_path = "res://intro_test_settings.cfg"
	root.add_child(game)
	await process_frame
	game.start_run()
	assert(game.cutscene.kind == "intro" and game.transitioning and not game.running)
	game.cutscene.set_process(false)
	for time in [1, 4, 8, 12]:
		game.cutscene.clock_time = time
		game.cutscene.update_shot(.25)
		if DisplayServer.get_name() != "headless":
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://docs/intro_%02d.png" % time)
	game.cutscene.finish()
	assert(game.running and game.player.enabled and game.room == 1)
	assert(game.level.prop("Walker").visible)
	game.pause_game()
	game.hud.open_collection(game.progress, game.director.definitions)
	assert(game.hud.collection_list.has_node("Replay_intro"))
	var position: Vector3 = game.player.position
	game.replay_ending("intro")
	assert(game.cutscene.kind == "intro")
	game.cutscene.finish()
	assert(game.hud.mode == "collection" and not game.running)
	assert(game.player.position == position and game.room == 1)
	game.hud.close_collection()
	game.start_run()
	assert(game.cutscene.kind == "intro", "Restart plays intro again")
	game.cutscene.finish()
	game.queue_free()
	await process_frame
	print("INTRO: PASS (new run, restart, replay, state preservation)")
	quit()
