extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.get_node("HUD").settings_path = "res://capture_settings.cfg"
	game.progress.path = "res://capture_settings_progress.cfg"
	root.add_child(game)
	await process_frame
	game.hud.open_settings()
	await create_timer(.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/settings_display.png")
	game.hud.brightness_slider.value = 140
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/settings_bright.png")
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute("res://capture_settings.cfg")
	quit()
