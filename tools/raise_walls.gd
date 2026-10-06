extends SceneTree
func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/school_level.tscn")
	var level = scene.instantiate()
	for body in level.get_node("RouteBarriers").get_children():
		for child in body.get_children():
			if child is CollisionShape3D and child.shape is BoxShape3D:
				child.shape = child.shape.duplicate()
				child.shape.size.y = 4.4
				child.position.y = 2.2 - body.position.y
			elif child is MeshInstance3D and child.name == "ConcreteWall":
				child.mesh = child.mesh.duplicate()
				child.mesh.size.y = 4.4
				child.position.y = 2.2 - body.position.y
	var windows = level.get_node("RouteBarriers/WindowBoundary")
	if not windows.has_node("UpperWall"):
		var upper := MeshInstance3D.new()
		upper.name = "UpperWall"
		upper.mesh = BoxMesh.new()
		upper.mesh.size = Vector3(.12,1.4,58.8)
		upper.position.y = 3.7 - windows.position.y
		upper.material_override = windows.get_node("WindowSillWall").material_override
		windows.add_child(upper)
		upper.owner = level
	var packed := PackedScene.new()
	packed.pack(level)
	var result := ResourceSaver.save(packed,"res://scenes/school_level.tscn")
	assert(result == OK)
	for body in level.get_node("RouteBarriers").get_children():
		for child in body.get_children():
			if child is CollisionShape3D:
				assert(is_equal_approx(body.position.y + child.position.y - child.shape.size.y / 2, 0))
				assert(is_equal_approx(body.position.y + child.position.y + child.shape.size.y / 2, 4.4))
	print("Walls and collision verified: floor 0 to height 4.4 metres")
	level.free()
	quit()
