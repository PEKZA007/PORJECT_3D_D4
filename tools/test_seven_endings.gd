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

func shot(name_hint: String) -> void:
	await process_frame
	await process_frame
	if DisplayServer.get_name() != "headless":
		root.get_texture().get_image().save_png("res://docs/seven_%s.png" % name_hint)

func run() -> void:
	root.size = Vector2i(1280, 800)
	game = load("res://scenes/main.tscn").instantiate()
	game.progress.path = "res://test_seven_progress.cfg"
	root.add_child(game)
	await process_frame
	game.start_run()
	game.running = false
	game.player.enabled = false
	check(game.config.final_room == 7, "Seven-room default")
	game.config.forced_anomaly = 27
	check(game.director.select_anomaly(2) == 27, "Event 27 is selectable")
	check(game.director.select_anomaly(1) == 0 and game.director.select_anomaly(7) == 0, "First and final room stay safe")
	game.config.forced_anomaly = -1
	for i in 40:
		game.reset_charm()
		check(game.charm_room >= 1 and game.charm_room <= 7, "Charm roll stays within seven rooms")
		check(game.charm_position.x >= -.45 and game.charm_position.x <= .15 and game.charm_position.z >= 2 and game.charm_position.z <= 32, "Charm stays on central corridor floor")
	# Every possible charm room, including the safe first room and final exit.
	for chosen_room in range(1, 8):
		game.charm_collected = false
		game.charm_room = chosen_room
		for room in range(1, 8):
			game.load_room(room, 0)
			check(game.level.prop("CharmPickup").visible == (room == chosen_room), "Exactly one charm room")
		game.load_room(chosen_room, 0)
		game.player.position = game.level.prop("CharmPickup").position + Vector3(0, 0, 1.2)
		game.player.camera.look_at(game.level.prop("CharmPickup").global_position)
		await physics_frame
		var charm_pos: Vector3 = game.level.prop("CharmPickup").global_position
		var floor_hit := game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(charm_pos + Vector3.UP * .3, charm_pos - Vector3.UP, 1))
		check(not floor_hit.is_empty() and floor_hit.normal.y > .7 and absf(floor_hit.position.y - charm_pos.y) < .06, "Random charm rests above reachable corridor floor")
		game.update_interaction()
		check(game.target == "CharmPickup", "Charm reachable through normal interaction")
		check(game.hud.prompt.text.is_empty() and game.level.prop("CharmPickup").find_children("*", "Label3D", true, false).is_empty(), "Charm has no text labels or prompt")
		game.interact()
		check(game.charm_collected and not game.level.prop("CharmPickup").visible, "Charm pickup")
		game.load_room(7, 0)
		check(game.charm_collected and not game.level.prop("CharmPickup").visible, "Inventory persists without respawn")
	game.running = true
	game.choose_exit(false)
	check(game.hud.mode == "cutscene" and game.transitioning, "True cinematic starts")
	game.cutscene.clock_time = 16.0
	game.cutscene.update_shot(.1)
	check(game.cutscene.home_shown and game.cutscene.animator.current_animation == "Idle", "True ending reaches normal life at home")
	game.cutscene.finish()
	check(game.ending == "true" and game.hud.menu_subtitle.text == "TRUE ENDING", "Collected charm yields true ending")
	game.hud.open_settings()
	game.hud.close_settings()
	check(game.hud.menu_subtitle.text == "TRUE ENDING", "Ending label survives settings")
	await shot("true_ending")
	game.start_run()
	check(not game.charm_collected and game.ending.is_empty(), "New game clears inventory and ending")
	game.load_room(7, 0)
	game.choose_exit(false)
	check(game.hud.mode == "cutscene" and not game.level.prop("Walker").visible, "Player replaces NPC in cinematic")
	game.cutscene.clock_time = 6.0
	game.cutscene.update_shot(.1)
	check(game.cutscene.actor.rotation.y > 3.0, "Replacement player turns back on patrol")
	game.cutscene.finish()
	check(game.ending == "normal" and game.hud.menu_subtitle.text == "NORMAL ENDING", "No charm yields normal ending")
	await shot("normal_ending")
	game.start_run()
	game.running = false
	game.player.enabled = false
	game.load_room(2, 8)
	var walker = game.level.prop("Walker")
	check(walker.variant_name == "masked", "Event 8 uses masked variant")
	check(walker.art.find_children("GeishaMask", "Node3D", true, false).size() == 1, "Mask exists on head")
	walker.position = Vector3(0, 0, 29)
	walker.rotation.y = PI
	walker.animate(.1, "Walk")
	game.player.position = Vector3(0, .02, 30.7)
	game.player.camera.look_at(Vector3(0, 1.6, 29))
	await shot("masked_walker")
	game.load_room(2, 0)
	check(walker.art.find_children("GeishaMask", "Node3D", true, false).is_empty(), "Mask clears on next room")
	game.load_room(2, 27)
	check(not game.player.sprint_allowed and game.level.prop("NoRunningSign").visible, "No-running sign and sprint lock")
	game.player.position = Vector3(0, .02, 32.8)
	game.director.tick(.016)
	check(game.director.follower_active and game.level.prop("Pursuer").visible, "Man appears behind player")
	check(game.level.prop("Pursuer").position.z > game.player.position.z, "Follower starts behind forward route")
	game.player.look_at(Vector3(.82, .02, 34))
	game.player.camera.look_at(Vector3(.82, 1.65, 34))
	await shot("no_running")
	game.player.rotation.y = 0
	game.player.camera.rotation = Vector3.ZERO
	game.player.enabled = true
	Input.action_press("move_forward")
	Input.action_press("sprint")
	await create_timer(.5).timeout
	check(not game.player.sprinting, "Shift cannot activate sprint")
	check(Vector2(game.player.velocity.x, game.player.velocity.z).length() <= game.config.walk_speed + .1, "Walking speed enforced")
	Input.action_release("move_forward")
	Input.action_release("sprint")
	game.player.enabled = false
	# Simulate continuous forward walking through the full encounter.
	for i in 160:
		game.player.position.z -= game.config.walk_speed * .1
		game.director.tick(.1)
	check(game.level.prop("Pursuer").position.distance_to(game.player.position) > .6, "Continuous walking survives")
	var bells: Array[int] = [2, 3, 5]
	check(game.Rules.evaluate(2, 7, true, false, 1, bells, 27).ok, "Event 27 requires forward exit")
	check(not game.Rules.evaluate(2, 7, true, true, 1, bells, 27).ok, "Event 27 rejects back exit")
	check(not game.Rules.evaluate(2, 7, true, false, 0, bells, 27).ok, "Bell still required before event 27")
	var dangers: Array[String] = []
	game.director.danger.connect(func(reason: String): dangers.append(reason))
	game.load_room(2, 27)
	game.player.position = Vector3(0, .02, 32.8)
	game.director.tick(.016)
	game.player.position.z += 1.1
	game.director.tick(.016)
	check(not dangers.is_empty(), "Walking backwards triggers failure")
	game.load_room(2, 27)
	game.player.position = Vector3(0, .02, 32.8)
	game.running = true
	game.charm_collected = true
	game.director.tick(.016)
	game.director.tick(2.0)
	check(game.transitioning and not game.charm_collected, "Standing still fails and clears charm")
	await create_timer(1.15).timeout
	check(game.room == 1 and game.player.sprint_allowed, "Failure restores safe room and sprint")
	game.running = false
	game.player.enabled = false
	game.load_room(2, 27)
	game.player.position = Vector3(0, .02, 32.8)
	game.director.tick(.016)
	game.pause_game()
	var before: Vector3 = game.level.prop("Pursuer").position
	await create_timer(.15).timeout
	check(game.level.prop("Pursuer").position == before, "Follower freezes while paused")
	game.load_room(3, 0)
	check(game.player.sprint_allowed and not game.level.prop("NoRunningSign").visible and not game.level.prop("Pursuer").visible, "Event cleanup")
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute("res://test_seven_progress.cfg")
	print("SEVEN ENDINGS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

