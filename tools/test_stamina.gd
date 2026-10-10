extends SceneTree
var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.progress.path = "res://test_stamina_progress.cfg"
	game.get_node("HUD").settings_path = "res://test_stamina_settings.cfg"
	root.add_child(game)
	await process_frame
	game.start_run()
	var player = game.player
	check(player.stamina_enabled and game.hud.stamina_panel.visible, "Normal uses stamina meter")
	player.update_stamina(3.0, true)
	check(player.sprinting and player.stamina == 3.0, "Three-second chase can be sprinted from full stamina")
	player.update_stamina(3.0, true)
	check(player.exhausted and not player.sprinting and player.stamina == 0, "Six-second sprint exhausts player")
	player.update_stamina(1.0, true)
	check(player.stamina == 0 and not player.sprinting, "Holding sprint cannot bypass recovery delay")
	player.update_stamina(1.0, false)
	check(is_equal_approx(player.stamina, .4), "Regeneration uses only time after rest delay")
	player.update_stamina(1.0, true)
	check(not player.sprinting, "Exhausted player waits until quarter capacity")
	player.update_stamina(.5, false)
	player.update_stamina(.1, true)
	check(player.sprinting and not player.exhausted, "Recovered player can sprint again")
	game.pause_game()
	var before: float = player.stamina
	player.update_stamina(10, false)
	check(player.stamina == before and not game.hud.stamina_panel.visible, "Pause freezes stamina and hides meter")
	game.resume_game()
	check(game.hud.stamina_panel.visible, "Resume restores meter")
	game.load_room(2, 27)
	player.update_stamina(.1, true)
	check(not player.sprinting and player.stamina == player.stamina_capacity, "No-running sign still prevents sprint")
	game.load_room(2, 0)
	check(player.stamina == player.stamina_capacity and not player.exhausted, "New room restores stamina")
	game.return_to_title()
	game.hud.mode_picker.select(0)
	game.start_run()
	player.update_stamina(100, true)
	check(not player.stamina_enabled and player.sprinting and not game.hud.stamina_panel.visible, "Easy keeps unlimited sprint")
	game.return_to_title()
	game.progress.unlocked = true
	game.hud.mode_picker.select(2)
	game.start_run()
	player.update_stamina(100, true)
	check(not player.stamina_enabled and player.sprinting, "Endless keeps unlimited sprint")
	game.queue_free()
	await process_frame
	print("STAMINA: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
