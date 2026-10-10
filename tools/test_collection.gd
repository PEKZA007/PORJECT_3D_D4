extends SceneTree
var checks := 0
var failures := 0
var game: Node3D
const SAVE := "res://test_collection_progress.cfg"

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func run() -> void:
	if FileAccess.file_exists(SAVE):
		DirAccess.remove_absolute(SAVE)
	game = load("res://scenes/main.tscn").instantiate()
	game.progress.path = SAVE
	root.add_child(game)
	await process_frame
	game.hud.open_collection(game.progress, game.director.definitions)
	check(game.hud.mode == "collection" and game.hud.collection_summary.text.contains("0 / 26"), "Fresh album includes only enabled anomalies")
	check(game.hud.collection_list.get_child(1).text.contains("???"), "Ending spoilers hidden")
	check(game.hud.collection_list.get_node("Replay_normal").disabled, "Locked ending cannot replay")
	check(game.hud.collection_list.get_node("Anomaly_08/Picture").texture == null, "Locked anomaly image hidden")
	game.hud.close_collection()
	check(game.hud.mode == "title", "Album returns to title")
	game.start_run()
	game.load_room(2, 8)
	game.rings = 1
	game.choose_exit(true)
	check(game.progress.anomalies.has(8), "Successful encounter collected")
	await create_timer(1.15).timeout
	game.load_room(2, 25)
	game.fail_run("test")
	check(game.progress.anomalies.has(25), "Failed encounter collected")
	await create_timer(1.15).timeout
	check(game.progress.anomalies.size() == 2, "Failure preserves collection")
	game.load_room(2, 8)
	game.collect_encounter()
	check(game.progress.anomalies.size() == 2, "Duplicate encounter counted once")
	game.pause_game()
	game.hud.open_collection(game.progress, game.director.definitions)
	check(not game.running and not game.player.enabled, "Album keeps gameplay paused")
	check(game.hud.collection_list.get_node("Anomaly_08/Picture").texture != null, "Discovered anomaly shows game screenshot")
	check(game.hud.collection_list.get_child(1).text.contains("???"), "Unseen ending stays hidden")
	game.hud.close_collection()
	check(game.hud.mode == "pause", "Album returns to pause")
	game.resume_game()
	game.load_room(7, 0)
	game.choose_exit(false)
	check(game.progress.endings.has("normal"), "Normal ending collected")
	game.cutscene.finish()
	game.hud.open_collection(game.progress, game.director.definitions)
	check(game.hud.collection_list.get_child(1).text.contains("NORMAL END"), "Unlocked ending shown")
	game.hud.close_collection()
	check(game.hud.mode == "win" and game.hud.menu_subtitle.text == "NORMAL ENDING", "Return preserves ending result")
	game.start_run()
	game.charm_collected = true
	game.load_room(7, 0)
	game.choose_exit(false)
	game.cutscene.finish()
	check(game.progress.endings.size() == 2, "Both endings collected separately")
	game.return_to_title()
	game.start_run()
	game.load_room(2, 8)
	game.rings = 1
	game.player.position.z = 20
	game.pause_game()
	game.hud.open_collection(game.progress, game.director.definitions)
	var original_position: Vector3 = game.player.position
	var original_actor_position: Vector3 = game.level.prop("Walker").position
	var original_ambient: float = game.level.environment.environment.ambient_light_energy
	game.hud.collection_list.get_node("Replay_normal").pressed.emit()
	check(game.hud.mode == "cutscene" and game.transitioning, "Album button starts normal replay")
	game.cutscene.finish()
	check(game.hud.mode == "collection" and game.hud.collection_origin == "pause", "Replay returns to paused album")
	check(game.room == 2 and game.rings == 1 and game.player.position == original_position and game.level.prop("Walker").position == original_actor_position, "Replay preserves active room and inventory")
	game.hud.collection_list.get_node("Replay_true").pressed.emit()
	check(game.cutscene.kind == "true", "Each button plays its own ending")
	game.cutscene.clock_time = 22
	game.cutscene._process(.1)
	check(game.hud.mode == "collection" and game.level.environment.get_parent() == game.level, "Automatic replay finish restores original environment")
	check(game.progress.endings.size() == 2, "Replay does not change collection")
	check(game.level.environment.environment.ambient_light_energy == original_ambient, "Replay lighting does not change original room")
	game.hud.close_collection()
	game.resume_game()
	check(game.running and game.player.enabled, "Gameplay resumes after replay")
	var saved = preload("res://scripts/mode_progress.gd").new()
	saved.path = SAVE
	saved.load_progress()
	check(saved.anomalies.size() == 2 and saved.endings.size() == 2 and saved.unlocked, "Collection and unlock persist together")
	game.return_to_title()
	game.start_run()
	game.ranked_run = false
	game.load_room(2, 26)
	game.collect_encounter()
	check(not game.progress.anomalies.has(26), "Event lab cannot collect")
	game.return_to_title()
	game.hud.mode_picker.select(2)
	game.start_run()
	game.load_room(8, 26)
	game.fail_run("test")
	check(game.progress.anomalies.has(26) and game.progress.endings.size() == 2, "Endless collects events but no story endings")
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute(SAVE)
	print("COLLECTION: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
