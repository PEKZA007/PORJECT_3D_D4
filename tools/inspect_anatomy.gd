extends SceneTree
func _initialize() -> void:
	var model = load("res://assets/models/npc.glb").instantiate()
	root.add_child(model)
	for animator in model.find_children("*", "AnimationPlayer", true, false):
		var clip: Animation = animator.get_animation("Walk")
		for track in clip.get_track_count():
			if clip.track_get_type(track) == Animation.TYPE_ROTATION_3D:
				print("TRACK ", clip.track_get_path(track))
	for skeleton in model.find_children("*", "Skeleton3D", true, false):
		for bone in skeleton.get_bone_count():
			var label: String = skeleton.get_bone_name(bone)
			if label.begins_with("DEF-") and ("spine" in label or "arm" in label or "hand" in label or "shoulder" in label):
				print(label, " parent=", skeleton.get_bone_name(skeleton.get_bone_parent(bone)), " rest=", skeleton.get_bone_rest(bone))
	model.free()
	var player = load("res://assets/models/player_animated.tscn").instantiate()
	for mesh in player.find_children("*", "MeshInstance3D", true, false):
		var minimum := Vector3.ONE * 100
		var maximum := Vector3.ONE * -100
		for surface in mesh.mesh.get_surface_count():
			var arrays: Array = mesh.mesh.surface_get_arrays(surface)
			for index in arrays[Mesh.ARRAY_VERTEX].size():
				if arrays[Mesh.ARRAY_BONES][index * 4] == 3 and arrays[Mesh.ARRAY_WEIGHTS][index * 4] > .5:
					minimum = minimum.min(arrays[Mesh.ARRAY_VERTEX][index])
					maximum = maximum.max(arrays[Mesh.ARRAY_VERTEX][index])
		print("ARM VERTICES ", mesh.name, " ", minimum, " to ", maximum)
	player.free()
	quit()
