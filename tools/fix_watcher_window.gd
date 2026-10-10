extends SceneTree
func _initialize() -> void:
	var level = load("res://scenes/school_level.tscn").instantiate()
	var boundary: Node3D = level.get_node("RouteBarriers/WindowBoundary")
	var original: MeshInstance3D = boundary.get_node("SolidWindowWall")
	var material: Material = original.material_override
	# Keep the continuous collision barrier; cut only the visual wall behind one pane.
	for child in boundary.get_children():
		if child is MeshInstance3D: child.free()
	var pieces = [
		["SolidWindowWall", Vector3(-1.67,2.2,(-12.7+10.82)/2),Vector3(.18,4.4,23.52)],
		["WallAfterWatcher",Vector3(-1.67,2.2,(12.16+46.1)/2),Vector3(.18,4.4,33.94)],
		["WatcherSill",Vector3(-1.67,.5,11.49),Vector3(.18,1.0,1.34)],
		["WatcherLintel",Vector3(-1.67,3.575,11.49),Vector3(.18,1.65,1.34)]
	]
	for p in pieces:
		var mesh := MeshInstance3D.new()
		mesh.name = p[0]
		mesh.mesh = BoxMesh.new()
		mesh.mesh.size = p[2]
		mesh.position = p[1] - boundary.position
		mesh.material_override = material
		boundary.add_child(mesh)
		mesh.owner = level
	var watcher: Node3D = level.get_node("Props/WindowWatcher")
	watcher.position = Vector3(-1.95,.18,11.48)
	watcher.rotation.y = -PI/2
	if watcher.has_node("FaceLight"): watcher.get_node("FaceLight").free()
	var light := OmniLight3D.new()
	light.name = "FaceLight"
	light.position = Vector3(0,1.6,-.4)
	light.light_color = Color(.8,.9,.83)
	light.light_energy = .8
	light.omni_range = 1.4
	watcher.add_child(light)
	light.owner = level
	var scene := PackedScene.new()
	assert(scene.pack(level) == OK)
	assert(ResourceSaver.save(scene,"res://scenes/school_level.tscn") == OK)
	level.free()
	quit()
