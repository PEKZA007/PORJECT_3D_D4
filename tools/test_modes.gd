extends SceneTree
var failures := 0
var checks := 0
var game: Node3D

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.progress.path = "res://test_modes_progress.cfg"
	if FileAccess.file_exists(game.progress.path):
		DirAccess.remove_absolute(game.progress.path)
	root.add_child(game)
	await process_frame
	check(game.hud.mode_picker.is_item_disabled(2), "Endless starts locked")
	game.hud.mode_picker.select(0)
	game.start_run()
	check(game.play_mode == "easy" and game.hud.hint_label.visible, "Easy mode shows dialogue")
	game.load_room(2, 4)
	var hint: String = game.hud.hint_label.text
	game.load_room(2, 0)
	check(game.hud.hint_label.text == hint, "Hint does not reveal current event")
	game.pause_game()
	check(not game.hud.hint_label.visible, "Dialogue hides on pause")
	game.resume_game()
	check(game.hud.hint_label.visible, "Dialogue returns on resume")
	game.load_room(7, 0)
	game.choose_exit(false)
	check(game.progress.unlocked and not game.hud.mode_picker.is_item_disabled(2), "Story clear unlocks endless")
	game.cutscene.finish()
	var saved = preload("res://scripts/mode_progress.gd").new()
	saved.path = game.progress.path
	saved.load_progress()
	check(saved.unlocked, "Unlock persists on disk")
	game.return_to_title()
	game.hud.mode_picker.select(1)
	game.start_run()
	check(game.play_mode == "normal" and game.hud.hint_label.text.is_empty(), "Normal has no hints")
	game.return_to_title()
	game.hud.mode_picker.select(2)
	game.start_run()
	check(game.director.endless_mode and not game.level.prop("CharmPickup").visible, "Endless starts without story pickup")
	game.load_room(7, 0)
	game.choose_exit(false)
	await create_timer(1.15).timeout
	check(game.room == 8 and game.running and game.ending.is_empty(), "Endless passes seventh room without ending")
	game.load_room(9, 0)
	game.choose_exit(false)
	check(game.hud.mode == "win" and not game.running, "Cyclic room 2 requires bell and failure ends run")
	check(game.progress.best_rooms == 1 and not game.hud.share_text.is_empty(), "Record saved and share text generated")
	saved.load_progress()
	check(saved.best_rooms == 1, "Personal record persists")
	game.start_run()
	game.load_room(9, 0)
	game.rings = 1
	game.choose_exit(false)
	await create_timer(1.15).timeout
	check(game.room == 10 and game.running, "Cyclic bell succeeds")
	game.load_room(14, 27)
	game.choose_exit(false)
	await create_timer(1.15).timeout
	check(game.room == 15, "No-running special rule still works beyond seventh room")
	game.return_to_title()
	check(not game.director.endless_mode, "Title restores story event selection")
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute(saved.path)
	print("MODES: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
