extends SceneTree
func _initialize() -> void:
	var level = load("res://scenes/school_level.tscn").instantiate()
	for title in ["StairwellClosed", "FarEndClosed"]:
		var body = level.get_node("RouteBarriers/" + title)
		for child in body.get_children():
			if child is CollisionShape3D:
				child.shape = child.shape.duplicate()
				child.shape.size.y = 4.4
				child.position.y = 2.2 - body.position.y
			elif child is MeshInstance3D and child.name == "ConcreteWall":
				child.mesh = child.mesh.duplicate()
				child.mesh.size.y = 4.4
				child.position.y = 2.2 - body.position.y
		var wall = body.get_node("ConcreteWall")
		assert(is_equal_approx(body.position.y + wall.position.y - wall.mesh.size.y / 2, 0.0))
		assert(is_equal_approx(body.position.y + wall.position.y + wall.mesh.size.y / 2, 4.4))
	var packed := PackedScene.new()
	packed.pack(level)
	assert(ResourceSaver.save(packed, "res://scenes/school_level.tscn") == OK)
	print("Both end walls and collision: 4.4 metres, verified.")
	level.free()
	quit()
