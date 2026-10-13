extends SceneTree
func _initialize() -> void:
	var model = load("res://assets/models/npc.glb").instantiate()
	root.add_child(model)
	for player in model.find_children("*", "AnimationPlayer", true, false):
		for name in player.get_animation_list():
			var clip: Animation = player.get_animation(name)
			print(name, " length=", clip.length, " tracks=", clip.get_track_count())
			for i in mini(12, clip.get_track_count()):
				print("  ", clip.track_get_path(i))
	model.queue_free()
	quit()
