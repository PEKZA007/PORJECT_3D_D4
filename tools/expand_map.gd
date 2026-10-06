extends SceneTree
## One-time migration of the existing editable scene; never regenerates its props.
var level: Node3D
var expansion: Node3D
const SOURCE_OPENINGS := ["Object_130", "Object_132", "Object_253", "Object_255", "Object_364", "Object_366", "Object_241", "Object_243", "Object_245", "Object_360"]

func _initialize() -> void:
	call_deferred("run")

func add(node: Node, parent: Node, node_name: String) -> Node:
	node.name = node_name
	parent.add_child(node)
	node.owner = level
	return node

func box(parent: Node, node_name: String, pos: Vector3, size: Vector3, color: Color, solid: bool = false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	mesh.mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	mesh.material_override = material
	add(mesh, parent, node_name)
	mesh.position = pos
	if solid:
		collider(mesh, "Collision", Vector3.ZERO, size)
	return mesh

func collider(parent: Node, node_name: String, pos: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	add(body, parent, node_name)
	body.position = pos
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = size
	add(shape, body, "Shape")
	return body

func label(node_name: String, content: String, pos: Vector3, yaw: float = 0) -> void:
	var text := Label3D.new()
	add(text, expansion, node_name)
	text.text = content
	text.position = pos
	text.rotation_degrees.y = yaw
	text.font_size = 40
	text.pixel_size = 0.004
	text.modulate = Color("c3ccb5")
	text.outline_size = 1

func collect_faces(node: Node, faces: PackedVector3Array) -> PackedVector3Array:
	if node is MeshInstance3D and not node.name in SOURCE_OPENINGS:
		var vertices: PackedVector3Array = node.mesh.get_faces()
		for vertex in vertices:
			faces.append(node.global_transform * vertex)
	for child in node.get_children():
		faces = collect_faces(child, faces)
	return faces

func lamp(node_name: String, pos: Vector3, color: Color = Color("b8c7b3"), radius: float = 7.0) -> void:
	var light := OmniLight3D.new()
	add(light, level.get_node("Lights"), node_name)
	light.position = pos
	light.light_color = color
	light.light_energy = 1.2
	light.omni_range = radius
	light.omni_attenuation = 1.4

func move_prop(node_name: String, pos: Vector3) -> void:
	level.get_node("Props/" + node_name).position = pos

func run() -> void:
	level = load("res://scenes/school_level.tscn").instantiate()
	if level.has_node("MapExpansion"):
		print("Already expanded; scene preserved. Edit school_level.tscn directly.")
		level.free()
		quit()
		return
	var script: Script = level.get_script()
	level.set_script(null)
	root.add_child(level)
	expansion = add(Node3D.new(), level, "MapExpansion")
	# Replace restrictive invisible corridor boxes with the real asset's architecture.
	for node_name in ["FloorCollision", "ClassroomBoundary", "WindowBoundary"]:
		level.get_node(node_name).free()
	var architecture: Node = level.get_node("SchoolModel").find_child("Architecture*", true, false)
	assert(architecture != null)
	var faces := collect_faces(architecture, PackedVector3Array())
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(faces)
	DirAccess.make_dir_recursive_absolute("res://assets/collision")
	assert(ResourceSaver.save(shape, "res://assets/collision/school_architecture.res") == OK)
	var body := StaticBody3D.new()
	add(body, expansion, "SchoolArchitectureCollision")
	var collision := CollisionShape3D.new()
	collision.shape = load("res://assets/collision/school_architecture.res")
	add(collision, body, "Shape")
	# Solid perimeter protects the rooftop without colliding against 1.3M rail triangles.
	collider(expansion, "RoofWestFence", Vector3(-11.43, 9.5, -15.5), Vector3(0.15, 1.8, 10.1))
	collider(expansion, "RoofNorthFence", Vector3(-7.25, 9.5, -20.3), Vector3(8.5, 1.8, 0.15))
	collider(expansion, "RoofSouthFence", Vector3(-7.25, 9.5, -10.7), Vector3(8.5, 1.8, 0.15))
	# Classroom shell already existed as a visual prototype; now it can be entered.
	for mesh in level.get_node("Props/ClassroomInterior").get_children():
		if mesh is MeshInstance3D:
			collider(mesh, "Collision", Vector3.ZERO, mesh.mesh.size)
	collider(level.get_node("Props/Door"), "Collision", Vector3(0, 1.035, 0.69), Vector3(0.07, 2.07, 1.38))
	level.get_node("Spawn").position = Vector3(0, 0.055, 39)
	level.get_node("Spawn").rotation = Vector3.ZERO
	level.get_node("ForwardExit").position = Vector3(-10.15, 8.85, -19.25)
	level.get_node("BackExit").position = Vector3(0, 0.05, 45.3)
	move_prop("ForwardExitDarkness", Vector3(-10.15, 10.25, -19.92))
	move_prop("BackExitDarkness", Vector3(0, 1.5, 46.0))
	move_prop("NextNumber", Vector3(-10.15, 11.08, -19.79))
	level.get_node("Props/NextNumber").rotation_degrees.y = 0
	move_prop("ReturnLabel", Vector3(0, 2.4, 45.65))
	level.get_node("Props/ReturnLabel").rotation_degrees.y = 180
	move_prop("RoomNumber", Vector3(0, 2.45, 36.5))
	move_prop("RoomSignBacking", Vector3(0, 2.45, 36.45))
	move_prop("RoomCaption", Vector3(0, 2.04, 36.5))
	level.get_node("Props/RoomNumber").rotation_degrees.y = 0
	level.get_node("Props/RoomCaption").rotation_degrees.y = 0
	move_prop("Note", Vector3(0.3, 0.026, 37.7))
	move_prop("Bell", Vector3(0.89, 1.25, 35.6))
	move_prop("BellCaption", Vector3(0.94, 1.65, 35.6))
	move_prop("Posters", Vector3(0, 0, 24))
	move_prop("PosterGhost", Vector3(0.925, 1.6, 30))
	move_prop("PosterSymbol", Vector3(0.925, 1.6, 30))
	move_prop("ExtraPosters", Vector3(0, 0, 24))
	move_prop("Mirror", Vector3(0.91, 1.45, 24.5))
	move_prop("MirrorCaption", Vector3(0.94, 2.3, 24.5))
	move_prop("ToiletDoor", Vector3(0.94, 0, 3.0))
	move_prop("Peeper", Vector3(0.93, 0, 3.36))
	move_prop("Extinguisher", Vector3(0.85, 4.9, -14.6))
	move_prop("FireLabel", Vector3(0.95, 5.52, -14.6))
	move_prop("Bin", Vector3(-0.77, 0, 17.5))
	move_prop("Hand", Vector3(-0.77, 0.66, 17.5))
	move_prop("Sink", Vector3(-3.48, 8.81, -17))
	move_prop("ExitSign", Vector3(0.91, 2.3, -7.0))
	move_prop("Walker", Vector3(-0.38, 0, 21))
	# Landmark furniture gives the newly opened far wing, landings and basement identity.
	for z in [41.5, 43.0]:
		box(expansion, "Bench%s" % z, Vector3(0.74, 0.46, z), Vector3(0.38, 0.12, 1.2), Color("5b6554"), true)
		box(expansion, "BenchBack%s" % z, Vector3(0.93, 0.84, z), Vector3(0.08, 0.72, 1.2), Color("5b6554"), true)
	for i in 3:
		box(expansion, "BasementStorage%d" % i, Vector3(-2.35, -3.85, -13.5 - i * 0.7), Vector3(0.65, 1.05, 0.55), Color("394b48"), true)
	label("BasementLabel", "STORAGE / B1", Vector3(0.94, -2.6, -14.2), -90)
	label("GroundFloorLabel", "EAST WING / 1F", Vector3(0.94, 2.3, -14.5), -90)
	label("LandingLabel", "2F", Vector3(0.94, 6.7, -14.3), -90)
	label("RoofLabel", "ROOFTOP", Vector3(-3.12, 11.05, -13.9), 90)
	for z in [32, 37, 42]:
		lamp("FarWingLight%s" % z, Vector3(0, 2.65, z))
	for point in [Vector3(0, 2.6, -10), Vector3(0, 2.6, -15), Vector3(-1, 4.6, -20), Vector3(-1.8, 6.9, -14.5), Vector3(-1, 9, -20), Vector3(-1.8, 11.1, -14.3), Vector3(-1, -1.7, -14.5), Vector3(-1, 0.2, -20)]:
		lamp("StairLight%d" % level.get_node("Lights").get_child_count(), point, Color("adbdc3"), 5.8)
	lamp("RoofLampWest", Vector3(-9.7, 11.2, -17.5), Color("b6c9d3"), 10)
	lamp("RoofLampDoor", Vector3(-4.0, 10.9, -13.9), Color("d2c5a0"), 8)
	box(expansion, "GateLeft", Vector3(-11.04, 10.18, -19.82), Vector3(0.12, 2.75, 0.16), Color("64766f"))
	box(expansion, "GateRight", Vector3(-9.26, 10.18, -19.82), Vector3(0.12, 2.75, 0.16), Color("64766f"))
	box(expansion, "GateLintel", Vector3(-10.15, 11.54, -19.82), Vector3(1.9, 0.12, 0.16), Color("64766f"))
	# Walkable route markers double as editable QA destinations.
	var route := add(Node3D.new(), expansion, "RouteWaypoints")
	var points: Array[Vector3] = [Vector3(0, 0, 32), Vector3(0, 0, 15), Vector3(0, 0, -14.5), Vector3(0, 0, -16.0), Vector3(0, 2.2, -19.85), Vector3(-1.9, 2.2, -19.85), Vector3(-1.9, 4.4, -14.4), Vector3(0, 4.4, -14.4), Vector3(0, 6.6, -19.85), Vector3(-1.9, 6.6, -19.85), Vector3(-1.9, 8.8, -13.9), Vector3(-3.8, 8.8, -13.9), Vector3(-6.0, 8.8, -16), Vector3(-10.15, 8.8, -18.5)]
	for i in points.size():
		var marker := Marker3D.new()
		add(marker, route, "Point%02d" % i)
		marker.position = points[i]
	level.set_script(script)
	level.walker_patrol_z = Vector2(14, 33)
	level.footsteps_trigger_z = 28.0
	level.attacker_trigger_z = 7.0
	level.door_trigger_z = 14.0
	var packed := PackedScene.new()
	assert(packed.pack(level) == OK)
	assert(ResourceSaver.save(packed, "res://scenes/school_level.tscn") == OK)
	print("Expanded scene saved. Architectural collision triangles: ", faces.size() / 3)
	level.queue_free()
	await process_frame
	quit()
