extends SceneTree
## Preview unlocks exist only in memory and never modify the player's save.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.progress.path = "res://ending_preview_progress.cfg"
	game.get_node("HUD").settings_path = "res://ending_preview_settings.cfg"
	root.add_child(game)
	await process_frame
	game.progress.endings.assign(["normal", "true"])
	game.hud.open_collection(game.progress, game.director.definitions)
	for id in ["normal", "true"]:
		game.replay_ending(id)
		await game.cutscene.finished
		await create_timer(.6).timeout
	# Keep the collection open so either ending can be watched again.
