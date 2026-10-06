extends SceneTree
func _initialize() -> void:
	var level = load("res://scenes/school_level.tscn").instantiate()
	var material = level.get_node("RouteBarriers/FarEndClosed/ConcreteWall").material_override
	for title in ["StairwellClosed","FarEndClosed"]:
		var body = level.get_node("RouteBarriers/"+title)
		for child in body.get_children():
			if child is CollisionShape3D:
				child.shape = child.shape.duplicate()
				child.shape.size.y = 1.0
				child.position.y = .5 - body.position.y
			elif child is MeshInstance3D:
				if child.name == "ConcreteWall":
					child.mesh = child.mesh.duplicate()
					child.mesh.size.y = 1.0
					child.position.y = .5 - body.position.y
				elif child.name != "Skirting":
					child.free()
	var windows = level.get_node("RouteBarriers/WindowBoundary")
	for child in windows.get_children():
		if child is MeshInstance3D:
			child.free()
		elif child is CollisionShape3D:
			child.shape = child.shape.duplicate()
			child.shape.size = Vector3(.18,4.4,58.8)
			child.position = Vector3(.06,2.2-windows.position.y,0)
	var wall := MeshInstance3D.new()
	wall.name = "SolidWindowWall"
	wall.mesh = BoxMesh.new()
	wall.mesh.size = Vector3(.18,4.4,58.8)
	wall.position = Vector3(.06,2.2-windows.position.y,0)
	wall.material_override = material
	windows.add_child(wall)
	wall.owner = level
	var packed := PackedScene.new()
	packed.pack(level)
	assert(ResourceSaver.save(packed,"res://scenes/school_level.tscn") == OK)
	print("End barriers: 1 m. Solid window-side wall: 4.4 m. Scene saved.")
	level.free()
	quit()
