extends SceneTree
var checks := 0
var failures := 0
const SETTINGS := "res://test_settings.cfg"

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
	game.progress.path = "res://test_settings_progress.cfg"
	root.add_child(game)
	return game

func run() -> void:
	if FileAccess.file_exists(SETTINGS):
		DirAccess.remove_absolute(SETTINGS)
	var game := make_game()
	await process_frame
	var hud = game.hud
	check(hud.resolution_picker.selected == 2 and hud.brightness_slider.value == 100, "Default window and brightness")
	hud.open_settings()
	check(game.sound.music.playing and game.sound.music.stream.loop, "Supplied music plays on loop")
	hud.music_volume_slider.value = 0
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")) and not AudioServer.is_bus_mute(0), "Music mute leaves effects enabled")
	hud.music_volume_slider.value = 40
	check(not AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "Music slider unmutes music")
	check(hud.mode == "settings" and not game.running, "Settings opens without starting game")
	hud.volume_slider.value = 0
	check(AudioServer.is_bus_mute(0), "Zero volume fully mutes all audio")
	hud.volume_slider.value = 50
	check(not AudioServer.is_bus_mute(0) and absf(AudioServer.get_bus_volume_db(0) - linear_to_db(.5)) < .01, "Volume applies live")
	hud.brightness_slider.value = 140
	check(hud.brightness_filter.visible and is_equal_approx(hud.brightness_material.get_shader_parameter("brightness"), 1.4), "Brightness applies live")
	hud.resolution_picker.select(4)
	hud.resolution_picker.item_selected.emit(4)
	hud.fullscreen.button_pressed = true
	check(hud.resolution_picker.disabled, "Window size disabled while fullscreen")
	hud.fullscreen.button_pressed = false
	check(not hud.resolution_picker.disabled, "Window size returns after leaving fullscreen")
	game.queue_free()
	await process_frame
	game = make_game()
	await process_frame
	hud = game.hud
	check(hud.brightness_slider.value == 140 and hud.resolution_picker.selected == 4 and hud.volume_slider.value == 50, "Settings restored after reload")
	check(hud.music_volume_slider.value == 40, "Music volume persists after reload")
	check(hud.brightness_filter.visible, "Restored brightness is active")
	hud.open_settings()
	hud.settings_page.get_node("ResetDefaults").pressed.emit()
	check(hud.brightness_slider.value == 100 and hud.volume_slider.value == 75 and hud.resolution_picker.selected == 2 and not hud.fullscreen.button_pressed, "Reset restores all defaults")
	check(not hud.brightness_filter.visible, "Default brightness disables correction")
	check(hud.music_volume_slider.value == 75, "Reset restores music default")
	hud.close_settings()
	game.start_run()
	game.pause_game()
	check(not game.sound.music.stream_paused and game.sound.ambient.stream_paused, "Music continues for settings preview while gameplay audio pauses")
	hud.open_settings()
	hud.brightness_slider.value = 60
	var original: Vector3 = game.player.position
	await create_timer(.2).timeout
	check(game.player.position == original and not game.running, "Adjusting display keeps gameplay paused")
	hud.close_settings()
	check(hud.mode == "pause", "Settings returns to pause menu")
	game.resume_game()
	check(game.running and hud.brightness_filter.visible, "Brightness stays applied during gameplay")
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute(SETTINGS)
	if FileAccess.file_exists("res://test_settings_progress.cfg"):
		DirAccess.remove_absolute("res://test_settings_progress.cfg")
	print("SETTINGS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
