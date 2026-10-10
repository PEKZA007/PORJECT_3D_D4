extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.get_node("HUD").settings_path = "res://credits_preview_settings.cfg"
	game.progress.path = "res://credits_preview_progress.cfg"
	root.add_child(game)
	await process_frame
	if "--english" in OS.get_cmdline_user_args():
		game.hud.open_settings()
		game.hud.language_picker.select(1)
		game.hud.language_picker.item_selected.emit(1)
		await process_frame
		await process_frame
		game.hud.close_settings()
	game.hud.credits_button.pressed.emit()
	assert(game.hud.mode == "credits" and not game.running)
	if DisplayServer.get_name() != "headless":
		await create_timer(.4).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/team_credits.png")
	game.hud.close_credits()
	assert(game.hud.mode == "title")
	game.start_run()
	game.pause_game()
	game.hud.open_credits()
	var escape := InputEventAction.new()
	escape.action = "pause_game"
	escape.pressed = true
	game._unhandled_input(escape)
	assert(game.hud.mode == "pause" and not game.running and not game.player.enabled)
	game.hud.show_menu("win", "NORMAL ENDING\nผลการเล่น")
	game.hud.open_credits()
	game.hud.close_credits()
	assert(game.hud.mode == "win" and game.hud.menu_subtitle.text == "NORMAL ENDING")
	game.queue_free()
	await process_frame
	if FileAccess.file_exists("res://credits_preview_settings.cfg"):
		DirAccess.remove_absolute("res://credits_preview_settings.cfg")
	print("CREDITS: PASS")
	quit()
