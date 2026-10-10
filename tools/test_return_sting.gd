extends SceneTree
var game: Node3D
var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func count_stings() -> int:
	var count := 0
	for voice in game.sound.get_children():
		if voice is AudioStreamPlayer and voice.stream == game.sound.clips.return_sting and voice.playing:
			count += 1
	return count

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.progress.path = "res://test_return_progress.cfg"
	game.get_node("HUD").settings_path = "res://test_return_settings.cfg"
	root.add_child(game)
	await process_frame
	game.start_run()
	check(count_stings() == 0, "Starting game does not play scare")
	game.load_room(2, 0)
	game.choose_exit(false)
	game.fail_run("duplicate")
	await create_timer(.65).timeout
	check(game.room == 1 and count_stings() == 1, "Failure return plays one sting during reveal")
	game.set_volume(0)
	check(AudioServer.is_bus_mute(0), "Sting follows master mute")
	game.set_volume(.75)
	await create_timer(1).timeout
	game.return_to_title()
	game.start_run()
	check(count_stings() == 0, "Menu and restart do not play scare")
	game.load_room(2, 0)
	game.rings = 1
	game.choose_exit(false)
	await create_timer(.65).timeout
	check(game.room == 3 and count_stings() == 0, "Successful room transition stays quiet")
	await create_timer(.5).timeout
	game.return_to_title()
	game.progress.unlocked = true
	game.hud.mode_picker.select(2)
	game.start_run()
	game.fail_run("endless")
	check(game.hud.mode == "win" and count_stings() == 0, "Endless result is not a return-to-room-one scare")
	game.queue_free()
	await process_frame
	if FileAccess.file_exists("res://test_return_progress.cfg"):
		DirAccess.remove_absolute("res://test_return_progress.cfg")
	print("RETURN STING: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
