extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	await physics_frame
	for key in ["Bell", "Speaker", "Extinguisher", "Bin", "PosterGhost", "CharmPickup", "NoRunningSign", "Note", "Mirror", "Sink", "Posters", "ExtraPosters", "PosterSymbol"]:
		var prop: Node3D = game.level.prop(key)
		var origin := Vector3(0, prop.global_position.y, prop.global_position.z)
		if key == "Bin": origin.y = .32
		var hit = game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(origin, origin + Vector3(-3 if key == "Bin" else 3, 0, 0), 1))
		print(key, " anchor ", prop.position, " hit ", hit.get("position"), " collider ", hit.get("collider"))
		for mesh in prop.find_children("*", "MeshInstance3D", true, false):
			if mesh.mesh: print("  ", mesh.name, " ", mesh.global_transform * mesh.get_aabb())
	game.free()
	quit()
