extends SceneTree
var game: Node3D

func _initialize() -> void:
	call_deferred("run")

func shot(label: String, position: Vector3, target: Vector3) -> void:
	game.player.position = position
	game.player.camera.look_at(target)
	await process_frame
	await process_frame
	await create_timer(.2).timeout
	if DisplayServer.get_name() != "headless":
		root.get_texture().get_image().save_png("res://docs/assets_%s.png" % label)

func run() -> void:
	root.size = Vector2i(1280, 800)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_run()
	game.running = false
	game.player.enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	for path in ["Bell", "Speaker", "Bin", "Extinguisher", "Walker/Offer", "PosterGhost"]:
		assert(game.level.prop(path).has_node("ArtRoot"), path)
	assert(game.sound.music.stream is AudioStreamMP3 and game.sound.music.stream.loop)
	assert(game.sound.clips.bell is AudioStreamMP3)
	print("Music length: ", game.sound.music.stream.get_length(), "; bell length: ", game.sound.clips.bell.get_length())
	game.sound.play_at("bell", game.level.prop("Bell").global_position)
	game.sound.play_at("bell", game.level.prop("Bell").global_position)
	assert(game.sound.event_players.size() == 1)
	await physics_frame
	await process_frame
	game.sound.set_paused(true)
	assert(game.sound.music.stream_paused and game.sound.bell_voice.stream_paused)
	game.sound.set_paused(false)
	assert(not game.sound.music.stream_paused)
	game.sound.stop_events()
	assert(game.sound.event_players.is_empty() and game.sound.bell_voice == null)
	await shot("bell", Vector3(-.5, .02, 36.3), game.level.prop("Bell").global_position)
	game.director.reset_room(2, 25)
	await shot("bin", Vector3(.2, .02, 18.8), Vector3(-.77, .6, 17.5))
	await shot("speaker", Vector3(-.5, .02, 15), game.level.prop("Speaker").global_position)
	await shot("extinguisher", Vector3(-.5, .02, -4.5), game.level.prop("Extinguisher").global_position)
	game.director.reset_room(2, 6)
	await shot("mask", Vector3(-.5, .02, 30.7), game.level.prop("PosterGhost").global_position)
	game.director.reset_room(2, 5)
	var walker = game.level.prop("Walker")
	walker.position = Vector3(0, 0, 29)
	walker.rotation.y = PI
	walker.animate(.1, "Walk")
	assert(walker.offer_hand >= 0)
	var hand: Vector3 = walker.offer_skeleton.to_global(walker.offer_skeleton.get_bone_global_pose(walker.offer_hand).origin)
	assert(walker.get_node("Offer").global_position.distance_to(hand) < .15)
	await shot("omamori", Vector3(.2, .02, 30.3), walker.get_node("Offer").global_position)
	game.director.reset_room(2, 0)
	game.level.toggle_classroom_door()
	await shot("classroom", Vector3(1.65, .02, 9.3), Vector3(3.3, .7, 8.7))
	# Walk through the open doorway and back after replacing furniture/collisions.
	game.player.position = Vector3(0, .02, 9.26)
	game.player.rotation.y = -PI / 2
	game.player.enabled = true
	Input.action_press("move_forward")
	await create_timer(.7).timeout
	Input.action_release("move_forward")
	assert(game.player.position.x > 1.65, "Classroom entrance blocked")
	game.player.rotation.y = PI / 2
	Input.action_press("move_forward")
	await create_timer(.7).timeout
	Input.action_release("move_forward")
	assert(game.player.position.x < .8, "Classroom return blocked")
	game.queue_free()
	await process_frame
	print("SUPPLIED ASSETS: PASS (models, music loop, bell, overlap, pause/resume, reset)")
	quit()
