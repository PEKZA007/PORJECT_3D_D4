extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.progress.path = "res://npc_motion_test_progress.cfg"
	game.get_node("HUD").settings_path = "res://npc_motion_test_settings.cfg"
	root.add_child(game)
	await process_frame
	game.running = false
	game.player.enabled = false
	game.load_room(2, 0)
	var walker = game.level.prop("Walker")
	assert(walker.animator.has_animation("Idle"))
	walker.position.z = game.level.walker_patrol_z.x + .02
	walker.rotation.y = 0
	var saw_turn := false
	var saw_walk := false
	for tick in 120:
		var before: float = walker.rotation.y
		game.director.tick(1.0 / 60)
		assert(absf(wrapf(walker.rotation.y - before, -PI, PI)) <= .076, "Turn speed is bounded")
		assert(walker.position.z >= game.level.walker_patrol_z.x and walker.position.z <= game.level.walker_patrol_z.y, "Patrol never overshoots")
		if game.director.walker_turn_time > 0:
			saw_turn = true
			assert(walker.motion == "Idle" and is_zero_approx(game.director.walker_speed))
		if game.director.walker_speed > .1:
			saw_walk = true
	assert(saw_turn and saw_walk, "NPC pauses, turns, then resumes walking")
	for variant in ["normal", "masked", "offering", "ghost", "attacker"]:
		walker.apply_variant(variant)
		assert(walker.animator.has_animation("Idle"))
		for clip_name in ["Idle", "Walk"]:
			var clip: Animation = walker.animator.get_animation(clip_name)
			var moving_groups: Dictionary = {}
			for track in clip.get_track_count():
				if clip.track_get_type(track) != Animation.TYPE_ROTATION_3D:
					continue
				var path := str(clip.track_get_path(track))
				for group in ["DEF-spine.003", "DEF-upper_arm.L_", "DEF-forearm.L_", "DEF-hand.L_"]:
					if group in path:
						var a := clip.rotation_track_interpolate(track, clip.length * .25)
						var b := clip.rotation_track_interpolate(track, clip.length * .75)
						assert(a.angle_to(b) > .0005, "NPC upper-body motion: " + group)
						moving_groups[group] = true
			assert(moving_groups.size() == 4, "NPC spine, upper arm, elbow and wrist all animate")
		walker.animate(.2, "Walk", .35)
		var slower: float = walker.playback_rate
		var phase_before: float = walker.animator.current_animation_position
		walker.animate(.2, "Run", 2.0)
		assert(walker.playback_rate > slower)
		var expected_phase := fposmod(phase_before + .2 * walker.playback_rate, walker.animator.current_animation_length)
		assert(is_equal_approx(walker.animator.current_animation_position, expected_phase), "Walk to Run retains imported gait phase")
		walker.animate(.2, "Idle")
		assert(walker.animator.current_animation == "Idle")
	var stopped: float = walker.animator.current_animation_position
	await create_timer(.1).timeout
	assert(is_equal_approx(stopped, walker.animator.current_animation_position), "Animations do not advance outside gameplay ticks")
	# Native runs also provide a close view of the new idle stance.
	if DisplayServer.get_name() != "headless":
		game.hud.hide_menu()
		game.hud.fade.color.a = 0
		game.level.set_lighting(1.8)
		walker.apply_variant("normal")
		walker.position = Vector3(0, 0, 29)
		walker.rotation.y = PI
		walker.animate(.5, "Idle")
		game.player.position = Vector3(0, .05, 32)
		game.player.camera.look_at(Vector3(0, 1.1, 29))
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/npc-natural-idle.png")
	game.queue_free()
	await process_frame
	print("NPC MOTION: PASS (turns, bounds, variants, cadence, pause)")
	quit()
