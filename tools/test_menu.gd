extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func shot(path: String) -> void:
	await create_timer(0.3).timeout
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png(path)
func run() -> void:
	root.size = Vector2i(1440, 900)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await create_timer(1).timeout
	await shot("res://docs/title-screen.png")
	game.hud.open_settings()
	assert(not game.running and game.hud.mode == "settings")
	await shot("res://docs/settings.png")
	game.hud.close_settings()
	assert(game.hud.mode == "title" and not game.running)
	game.start_run()
	game.pause_game()
	var before: Vector3 = game.player.position
	var time: float = game.elapsed
	await create_timer(0.3).timeout
	assert(game.player.position == before and game.elapsed == time)
	await shot("res://docs/pause.png")
	game.hud.open_settings()
	game.hud.close_settings()
	assert(game.hud.mode == "pause" and not game.running)
	game.resume_game()
	assert(game.running and game.player.enabled)
	game.return_to_title()
	assert(not game.started and not game.running and game.hud.mode == "title")
	game.start_run()
	game.load_room(1, 0)
	game.player.position = Vector3(0, 0.05, -10.8)
	game.player.rotation.y = 0
	Input.action_press("move_forward")
	await create_timer(2).timeout
	Input.action_release("move_forward")
	assert(game.room == 2)
	game.pause_game("note")
	await shot("res://docs/note-ui.png")
	assert(game.hud.note_page.visible and not game.hud.menu_content.visible)
	assert(game.hud.note_text.text == game.hud.note_rules)
	var close_note := InputEventAction.new()
	close_note.action = "interact"
	close_note.pressed = true
	game._unhandled_input(close_note)
	assert(game.running and not game.hud.overlay.visible)
	game.pause_game("note")
	close_note.action = "pause_game"
	game._unhandled_input(close_note)
	assert(game.running and not game.hud.overlay.visible)
	game.pause_game("note")
	game.hud.note_close.pressed.emit()
	assert(game.running and not game.hud.overlay.visible)
	game.hud.show_menu("win", "คุณผ่านทางเดินทั้ง 13 ห้องแล้ว")
	game.hud.open_settings()
	game.hud.close_settings()
	assert(game.hud.menu_body.text == "คุณผ่านทางเดินทั้ง 13 ห้องแล้ว")
	await shot("res://docs/win-ui.png")
	print("MENU AND HALLWAY: PASS")
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit()
