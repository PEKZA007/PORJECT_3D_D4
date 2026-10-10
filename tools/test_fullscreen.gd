extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var preferences := ConfigFile.new()
	preferences.set_value("display", "fullscreen", false)
	preferences.save("res://test_fullscreen_settings.cfg")
	var game = load("res://scenes/main.tscn").instantiate()
	game.get_node("HUD").settings_path = "res://test_fullscreen_settings.cfg"
	game.progress.path = "res://test_fullscreen_progress.cfg"
	root.add_child(game)
	await create_timer(.3).timeout
	var mode_ok := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	var size_ok := DisplayServer.window_get_size() == DisplayServer.screen_get_size()
	print("FULLSCREEN mode=", DisplayServer.window_get_mode(), " size=", DisplayServer.window_get_size(), " screen=", DisplayServer.screen_get_size())
	var passed: bool = mode_ok and size_ok and game.hud.fullscreen.button_pressed and root.content_scale_aspect == Window.CONTENT_SCALE_ASPECT_EXPAND
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute("res://test_fullscreen_settings.cfg")
	print("FULLSCREEN: ", "PASS" if passed else "FAIL")
	quit(0 if passed else 1)
