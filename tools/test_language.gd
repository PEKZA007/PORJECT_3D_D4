extends SceneTree
var checks := 0
var failures := 0
const SETTINGS := "res://test_language_settings.cfg"
const PROGRESS := "res://test_language_progress.cfg"

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func make_game() -> Node3D:
	var game = load("res://scenes/main.tscn").instantiate()
	game.get_node("HUD").settings_path = SETTINGS
	game.progress.path = PROGRESS
	root.add_child(game)
	return game

func run() -> void:
	if FileAccess.file_exists(SETTINGS):
		DirAccess.remove_absolute(SETTINGS)
	var game := make_game()
	await process_frame
	game.hud.open_settings()
	game.hud.language_picker.select(1)
	game.hud.language_picker.item_selected.emit(1)
	await process_frame
	await process_frame
	check(game.hud.mode == "settings" and game.hud.settings_button.text == "Settings", "Language changes immediately in settings")
	game.hud.close_settings()
	check(game.hud.primary.text == "Enter the corridor     →", "Main menu translated")
	game.hud.mode_picker.select(0)
	game.start_run()
	check(game.hud.hint_label.text.contains("Remember this corridor"), "Easy dialogue translated")
	game.pause_game("note")
	check(game.hud.note_text.text.contains("Trust no one"), "Gameplay rules translated")
	game.resume_game()
	game.load_room(2, 27)
	check(game.level.prop("NoRunningSign").text == "NO RUNNING\nKeep walking forward", "World sign translated")
	check(game.director.title(26) == "Blood flowing from the tap", "Anomaly names translated")
	game.pause_game()
	game.hud.open_collection(game.progress, game.director.definitions)
	check(game.hud.collection_summary.text.begins_with("Anomalies"), "Collection translated")
	game.hud.close_collection()
	game.hud.open_credits()
	var labels: Array = game.hud.credits_page.find_children("*", "RichTextLabel", true, false)
	check(labels.size() == 1 and labels[0].text.contains("Sousinho") and labels[0].text.contains("Carniceer") and labels[0].text.contains("naxete") and labels[0].text.contains("JotC") and labels[0].text.contains("Fundamental 3D"), "Full asset credits visible in game")
	check(labels[0].text.contains("sketchfab.com/licenses") and labels[0].text.contains("Author and license were not supplied"), "Source links and license information retained")
	game.hud.close_credits()
	game.hud.open_settings()
	var position_before: Vector3 = game.player.position
	game.hud.language_picker.select(0)
	game.hud.language_picker.item_selected.emit(0)
	await process_frame
	await process_frame
	check(game.hud.settings_origin == "pause" and game.player.position == position_before and not game.running, "Changing language preserves paused run")
	check(game.hud.settings_button.text == "ตั้งค่า", "Can switch back to Thai")
	game.hud.language_picker.select(1)
	game.hud.language_picker.item_selected.emit(1)
	await process_frame
	game.queue_free()
	await process_frame
	game = make_game()
	await process_frame
	check(game.hud.language_picker.selected == 1 and game.hud.primary.text == "Enter the corridor     →", "English persists after reopening game")
	game.start_run()
	game.load_room(7, 0)
	game.choose_exit(false)
	check(game.cutscene.caption.text.contains("corridor keeper"), "Ending subtitles translated")
	game.cutscene.finish()
	check(game.hud.menu_body.text.contains("Time") and game.hud.menu_body.text.contains("You never left"), "Ending result translated")
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute(SETTINGS)
	if FileAccess.file_exists(PROGRESS):
		DirAccess.remove_absolute(PROGRESS)
	print("LANGUAGE: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
