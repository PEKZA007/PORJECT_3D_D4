extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1280, 800)
	var game = load("res://scenes/main.tscn").instantiate()
	game.progress.path = "res://capture_collection_progress.cfg"
	root.add_child(game)
	await process_frame
	# Preview only; do not persist synthetic unlocks.
	game.progress.endings.assign(["normal", "true"])
	game.progress.anomalies.assign([1, 8, 26])
	game.hud.open_collection(game.progress, game.director.definitions)
	await create_timer(.4).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/collection_gallery.png")
	game.hud.collection_list.get_parent().scroll_vertical = 2100
	await create_timer(.2).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/collection_images.png")
	game.queue_free()
	await process_frame
	quit()
