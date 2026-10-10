extends SceneTree
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.get_node("HUD").settings_path = "res://test_window_settings.cfg"
	game.progress.path = "res://test_window_progress.cfg"
	root.add_child(game)
	await process_frame
	game.hud.open_settings()
	game.hud.fullscreen.button_pressed = false
	for index in [0, 2, 3, 4, 5]:
		game.hud.resolution_picker.select(index)
		game.hud.resolution_picker.item_selected.emit(index)
		await create_timer(.3).timeout
		print("RESIZE index=", index, " requested=", game.hud.RESOLUTIONS[index], " actual=", DisplayServer.window_get_size(), " root=", root.size, " mode=", DisplayServer.window_get_mode(), " embedded=", root.is_embedded())
		var requested: Vector2i = game.hud.RESOLUTIONS[index]
		var available := DisplayServer.screen_get_usable_rect().size
		var expected := Vector2i(mini(requested.x, available.x), mini(requested.y, available.y))
		if DisplayServer.window_get_size() != expected:
			failures += 1
	game.hud.editor_embedded = true
	game.hud.resolution_picker.select(0)
	var before := DisplayServer.window_get_size()
	game.hud.apply_window_size()
	if DisplayServer.window_get_size() != before:
		failures += 1
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute("res://test_window_settings.cfg")
	print("WINDOW RESIZE: 6 checks, %d failures" % failures)
	quit(1 if failures else 0)
