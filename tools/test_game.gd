extends SceneTree
const Rules = preload("res://scripts/run_rules.gd")
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("TEST FAILED: " + message)

func run() -> void:
	var bell_rooms: Array[int] = [2, 3, 5]
	for room in range(1, 7):
		for anomaly in [false, true]:
			for back in [false, true]:
				for rings in [0, 1, 2]:
					var result := Rules.evaluate(room, 7, anomaly, back, rings, bell_rooms)
					var expected: bool = (anomaly == back) and (not bell_rooms.has(room) or rings == 1)
					check(result.ok == expected, "Progression room=%d, anomaly=%s, back=%s, rings=%d" % [room, anomaly, back, rings])
	check(Rules.evaluate(7, 7, false, false, 0, bell_rooms).won, "Final forward exit wins")
	check(not Rules.evaluate(7, 7, false, true, 0, bell_rooms).won, "Final backward exit does not win")
	check(not Rules.evaluate(6, 7, false, false, 0, bell_rooms).won, "Room 8 is no longer the exit")
	var game = load("res://scenes/main.tscn").instantiate()
	game.progress.path = "res://test_game_progress.cfg"
	root.add_child(game)
	await process_frame
	check(not game.running and not game.player.enabled, "Title freezes player")
	game.start_run()
	game.running = false
	game.player.enabled = false
	check(game.director.active_id == 0, "First room is safe")
	check(game.config.final_room == 7, "Default goal is room 7")
	check(not game.config.explain_failures and not game.config.debug_enabled, "No spoiler feedback or event lab by default")
	check(game.hud.notice.text.is_empty(), "No startup hint")
	check(not game.hud.rules_label.text.contains("กระดิ่ง"), "Menu does not disclose the note rules")
	game.pause_game("note")
	check(not game.hud.rules_label.text.contains("EXIT") and game.hud.rules_label.text.contains("2, 3, 5"), "Physical note contains correct rules")
	game.pause_game()
	check(not game.hud.rules_label.text.contains("กระดิ่ง"), "Pause does not repeat the note rules")
	check(game.director.definitions.size() == 27, "Brief has 27 registered events")
	var expected_visible := {1: "Note", 2: "Blood", 4: "ExtraPosters", 5: "Walker/Offer", 6: "PosterGhost", 7: "PosterSymbol", 10: "Peeper", 18: "WindowWatcher", 23: "ExtraPosters", 25: "Hand", 26: "Sink/BloodStream"}
	for id in range(1, 28):
		game.director.reset_room(2, id)
		game.director.tick(0.016)
		if expected_visible.has(id):
			check(game.level.prop(expected_visible[id]).is_visible_in_tree(), "Visible effect %d" % id)
		game.director.reset_room(2, 0)
		check(not game.level.prop("Blood").visible and not game.level.prop("ExtraPosters").visible and not game.level.prop("PosterGhost").visible and not game.level.prop("Hand").visible, "No effects leak after event %d" % id)
		check(game.level.prop("Speaker").visible and game.level.prop("Door").visible and game.level.prop("Mirror/Frame").visible and game.level.prop("Extinguisher").visible, "Missing props restored after event %d" % id)
		check(game.level.prop("Walker").scale.is_equal_approx(Vector3.ONE), "Actor restored after event %d" % id)
		check(game.level.prop("Door").position.is_equal_approx(Vector3(1.11, 0, 8.57)), "Door transform restored after event %d" % id)
	game.load_room(2, 0)
	game.target = "Bell"
	game.player.position = Vector3(0, 0.02, game.level.prop("Bell").position.z)
	game.player.camera.look_at(game.level.prop("Bell").global_position)
	game.update_interaction()
	check(game.target == "Bell", "Looking at the nearby bell offers interaction")
	game.interact()
	check(game.rings == 1, "Bell interaction counts once")
	game.interact()
	check(game.rings == 2, "Second bell ring cannot be ignored")
	check(game.hud.prompt.text == "[E]" and not game.hud.bell_label.text.contains("กระดิ่ง"), "Bell has no counter or reminder")
	check(game.hud.notice.text.is_empty(), "Ringing produces audio without hints")
	game.load_room(3, 0)
	check(game.rings == 0, "Bell resets every passage")
	game.player.enabled = true
	var start_z: float = game.player.position.z
	Input.action_press("move_forward")
	await create_timer(0.5).timeout
	Input.action_release("move_forward")
	check(game.player.position.z < start_z - 0.7, "W moves along the expanded route")
	check(game.player.position.y > -0.1, "Floor supports player")
	Input.action_press("move_left")
	await create_timer(0.7).timeout
	Input.action_release("move_left")
	check(absf(game.player.position.x) < 1.8, "Actual school walls prevent leaving corridor")
	game.pause_game()
	var paused_position: Vector3 = game.player.position
	Input.action_press("move_forward")
	await create_timer(0.1).timeout
	Input.action_release("move_forward")
	check(game.player.position.is_equal_approx(paused_position), "Pause freezes movement")
	game.running = true
	game.load_room(2, 1)
	game.rings = 1
	game.choose_exit(true)
	await create_timer(1.2).timeout
	check(game.room == 3 and not game.transitioning, "Correct anomaly decision transitions to next room")
	game.load_room(2, 0)
	game.rings = 0
	game.choose_exit(false)
	await create_timer(1.2).timeout
	check(game.room == 1, "Missing bell resets run")
	check(game.hud.notice.text.is_empty(), "Failure does not reveal the missed rule")
	game.running = false
	game.player.enabled = false
	game.director.reset_room(2, 11)
	game.player.position.z = game.level.footsteps_trigger_z - 0.1
	game.director.tick(0.016)
	check(game.director.chase_active, "Footsteps activate chase")
	game.director.reset_room(2, 0)
	check(not game.director.chase_active and not game.level.prop("Pursuer").visible, "Chase fully resets")
	# Real-time movement must let both chase types finish before a boundary.
	for id in [11, 21]:
		game.load_room(2, id)
		game.running = true
		game.player.enabled = true
		game.player.position.z = game.level.footsteps_trigger_z - 0.1 if id == 11 else game.level.attacker_trigger_z - 0.1
		game.player.rotation.y = 0.0 if id == 11 else PI
		game.player.camera.rotation.x = -0.5
		Input.action_press("move_forward")
		Input.action_press("sprint")
		await create_timer(3.2).timeout
		Input.action_release("move_forward")
		Input.action_release("sprint")
		check(game.director.chase_finished and not game.transitioning, "Chase %d can be survived by sprinting" % id)
		check(game.room == 2, "Chase %d does not force an early boundary reset" % id)
		game.running = false
		game.player.enabled = false
	game.load_room(2, 0)
	game.running = true
	game.player.enabled = false
	var walker: Node3D = game.level.prop("Walker")
	walker.position.z = 22.0
	game.player.position = Vector3(-0.38, 0.02, 20.0)
	game.player.camera.look_at(walker.get_node("Head").global_position)
	await create_timer(2.1).timeout
	check(game.transitioning or game.room == 1, "Sustained eye contact triggers failure")
	await create_timer(1.1).timeout
	# Walk all twelve passage decisions and the thirteenth-room exit.
	game.config.forced_anomaly = 0
	game.start_run()
	for expected_room in range(1, 7):
		check(game.room == expected_room, "Complete route reaches room %d" % expected_room)
		if bell_rooms.has(expected_room):
			game.target = "Bell"
			game.interact()
		game.choose_exit(false)
		await create_timer(1.1).timeout
	check(game.room == 7, "Complete route reaches final room")
	game.load_room(7, 0)
	check(not game.level.has_node("Props/NextNumber") and not game.level.has_node("Props/ExitSign"), "Removed rooftop and next-room signs stay absent")
	game.running = true
	game.choose_exit(false)
	game.cutscene.finish()
	check(not game.running and game.hud.mode == "win", "Final-room game integration wins")
	check(game.hud.menu_title.text == "07 / EXIT", "Victory title uses room 7")
	var roof_exit: Vector3 = game.level.get_node("ForwardExit").global_position
	check(game.level.exit_at(roof_exit) == 1, "Hallway end is the forward exit")
	check(game.level.exit_at(Vector3(roof_exit.x, 8.8, roof_exit.z)) == 0, "Upper floor cannot trigger the hallway exit")
	check(game.level.exit_at(game.level.get_node("BackExit").global_position) == -1, "Far-wing gate is the return exit")
	game.load_room(2, 17)
	check(game.level.prop("Door/Collision").collision_layer == 0, "Missing door opens physical passage")
	game.load_room(2, 0)
	check(game.level.prop("Door/Collision").collision_layer == 1, "Normal door collision restores")
	game.level.toggle_classroom_door()
	check(game.level.door_opened_by_player, "Classroom door can be opened to explore")
	game.load_room(2, 0)
	check(not game.level.door_opened_by_player, "Manual classroom opening resets each round")
	game.start_run()
	check(game.hud.mode == "playing" and game.running, "Restart after victory restores gameplay mode")
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	DirAccess.remove_absolute("res://test_game_progress.cfg")
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


