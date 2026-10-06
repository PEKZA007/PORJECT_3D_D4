extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var level = load("res://scenes/school_level.tscn").instantiate()
	var anchor: Node3D = level.get_node("Props/Sink")
	for child in anchor.get_children():
		if child.name != "BloodStream": child.free()
	var source = load("res://assets/models/sink.glb").instantiate()
	root.add_child(source)
	var art := Node3D.new()
	art.name = "ArtRoot"
	anchor.add_child(art)
	art.owner = level
	art.set_meta("source_asset", "res://assets/models/sink.glb")
	for original in source.find_children("*", "MeshInstance3D", true, false):
		var part := MeshInstance3D.new()
		part.name = original.name
		var mesh: ArrayMesh = original.mesh.duplicate()
		var path := "res://assets/models/props/sink_%s.res" % original.name
		assert(ResourceSaver.save(mesh, path, ResourceSaver.FLAG_COMPRESS) == OK)
		mesh.take_over_path(path)
		part.mesh = mesh
		art.add_child(part)
		part.owner = level
		part.transform = Transform3D(Basis(Vector3.UP, -PI/2).scaled(Vector3.ONE * .525), Vector3(0, .525, 0)) * original.global_transform
	anchor.position.y = 0
	preload("res://scripts/prop_mounting.gd").mount_right(anchor)
	var stream: MeshInstance3D = anchor.get_node("BloodStream")
	# Outlet measured on the supplied faucet: bottom lip at (0.137, 0.970, -0.002).
	stream.position = Vector3(.137, .84, -.002)
	stream.mesh = CylinderMesh.new()
	stream.mesh.top_radius = .006
	stream.mesh.bottom_radius = .009
	stream.mesh.height = .26
	stream.visible = false
	source.free()
	var scene := PackedScene.new()
	assert(scene.pack(level) == OK)
	assert(ResourceSaver.save(scene, "res://scenes/school_level.tscn") == OK)
	level.free()
	print("Sink model installed")
	quit()
