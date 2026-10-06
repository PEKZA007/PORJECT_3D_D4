extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func save_frame(path: String) -> void:
	await process_frame
	await process_frame
	await create_timer(0.25).timeout
	root.get_texture().get_image().save_png(path)

func run() -> void:
	root.size = Vector2i(1440, 900)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await create_timer(1.5).timeout
	await save_frame("res://docs/title-screen.png")
	game.start_run()
	game.running = false
	game.player.enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await save_frame("res://docs/gameplay.png")
	game.player.position = Vector3(-0.25, 0.02, 32.0)
	game.player.camera.look_at(game.level.prop("PosterGhost").global_position)
	game.room = 2
	game.director.reset_room(2, 6)
	game.update_hud()
	game.hud.notice.text = ""
	await save_frame("res://docs/anomaly-poster.png")
	game.player.position = Vector3(-0.75, 0.02, 24.5)
	game.player.camera.look_at(Vector3(0.90, 1.4, 24.5))
	game.director.reset_room(2, 9)
	await save_frame("res://docs/anomaly-mirror.png")
	game.director.reset_room(2, 17)
	game.player.position = Vector3(-0.45, 0.02, 8.1)
	game.player.camera.look_at(Vector3(1.11, 1.0, 9.26))
	await save_frame("res://docs/anomaly-door.png")
	game.director.reset_room(2, 18)
	game.player.position = Vector3(0.4, 0.02, 10.2)
	game.player.camera.look_at(Vector3(-1.85, 1.8, 11.5))
	await save_frame("res://docs/anomaly-window.png")
	game.director.reset_room(2, 20)
	game.player.reset_at(game.level.get_node("Spawn").global_transform)
	game.player.position.z = 29
	await save_frame("res://docs/anomaly-blackout.png")
	game.director.reset_room(2, 13)
	game.player.position = Vector3(-0.1, 0.02, 9.26)
	game.player.camera.look_at(Vector3(4.16, 1.65, 9.26))
	await save_frame("res://docs/anomaly-blackboard.png")
	game.director.reset_room(2, 0)
	game.player.position = Vector3(0, 0.02, -14.6)
	game.player.camera.look_at(Vector3(0, 3, -19.5))
	await save_frame("res://docs/expanded-stairwell.png")
	game.player.position = Vector3(-6.1, 8.82, -14.8)
	game.player.camera.look_at(Vector3(-10.15, 10.2, -19.25))
	await save_frame("res://docs/expanded-rooftop.png")
	game.player.position = Vector3(0, -4.38, -15.0)
	game.player.camera.look_at(Vector3(-2.35, -3.5, -14.8))
	await save_frame("res://docs/expanded-basement.png")
	game.level.toggle_classroom_door()
	game.player.position = Vector3(2.5, 0.02, 9.3)
	game.player.camera.look_at(Vector3(4.16, 1.65, 9.26))
	await save_frame("res://docs/expanded-classroom.png")
	game.queue_free()
	await process_frame
	quit()
