extends SceneTree
var game: Node3D
var failed: bool = false

func _initialize() -> void:
	call_deferred("run")

func walk_to(destination: Vector3, name_hint: String, timeout: float = 14.0) -> bool:
	var remaining := timeout
	Input.action_press("move_forward")
	Input.action_press("sprint")
	while remaining > 0.0:
		var delta_pos: Vector3 = destination - game.player.position
		if Vector2(delta_pos.x, delta_pos.z).length() < 0.17 and absf(delta_pos.y) < 0.45:
			Input.action_release("move_forward")
			Input.action_release("sprint")
			print("REACHED ", name_hint, " at ", game.player.position)
			return true
		if Vector2(delta_pos.x, delta_pos.z).length() > 0.02:
			game.player.look_at(game.player.position + Vector3(delta_pos.x, 0, delta_pos.z))
		await physics_frame
		remaining -= 1.0 / Engine.physics_ticks_per_second
	Input.action_release("move_forward")
	Input.action_release("sprint")
	push_error("MAP ROUTE BLOCKED: %s, position=%s destination=%s" % [name_hint, game.player.position, destination])
	failed = true
	return false

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	game.start_run()
	game.running = false
	game.player.enabled = true
	if "--annex-only" in OS.get_cmdline_user_args():
		game.player.position = Vector3(0, 0.055, -14.4)
		var branch := [Vector3(-1.9, 0, -14.4), Vector3(-1.9, -2.2, -19.85), Vector3(0, -2.2, -19.85), Vector3(0, -4.4, -14.4)]
		for point in branch:
			if not await walk_to(point, "basement"):
				break
		branch.reverse()
		for point in branch:
			if failed or not await walk_to(point, "basement-return"):
				break
		if not failed:
			await walk_to(Vector3(0, 0, -14.4), "hallway")
			await walk_to(Vector3(0, 0, 9.26), "classroom-door")
			game.level.toggle_classroom_door()
			await walk_to(Vector3(2, 0, 9.26), "inside-classroom")
			await walk_to(Vector3(0, 0, 9.26), "outside-classroom")
		game.queue_free()
		await process_frame
		await create_timer(0.2).timeout
		print("ANNEX RESULT: ", "FAIL" if failed else "PASS")
		quit(1 if failed else 0)
		return
	var waypoints: Array[Node] = game.level.get_node("MapExpansion/RouteWaypoints").get_children()
	var roof_only := "--roof-only" in OS.get_cmdline_user_args()
	if roof_only:
		game.player.position = Vector3(-1.9, 8.83, -13.9)
		waypoints = waypoints.slice(11)
	for point in waypoints:
		if not await walk_to(point.global_position, point.name):
			break
	if not failed and not roof_only:
		print("PASS: continuous hallway-to-rooftop route without teleportation.")
		# The return route validates walking down both switchback staircases.
		waypoints.reverse()
		for point in waypoints:
			if not await walk_to(point.global_position, "return-" + point.name):
				break
	if not failed and not roof_only:
		if not await walk_to(game.level.get_node("BackExit").global_position, "return-gate"):
			failed = true
		elif game.level.exit_at(game.player.global_position) != -1:
			failed = true
		else:
			print("PASS: return gate reached on foot.")
	game.player.enabled = false
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("MAP RESULT: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
