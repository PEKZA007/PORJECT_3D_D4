extends SceneTree
## One-time authoring helper. The saved scene is editable normally in Godot.
## Re-running overwrites scenes/school_level.tscn.
var level: Node3D
var props: Node3D

func _initialize() -> void:
	call_deferred("build")

func attach(node: Node, parent: Node, node_name: String) -> Node:
	node.name = node_name
	parent.add_child(node)
	node.owner = level
	return node

func material(color: Color, emission: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.8
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	return m

func box(parent: Node, node_name: String, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	mesh.mesh.size = size
	mesh.material_override = material(color)
	attach(mesh, parent, node_name)
	mesh.position = pos
	return mesh

func sphere(parent: Node, node_name: String, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.mesh = SphereMesh.new()
	mesh.material_override = material(color)
	attach(mesh, parent, node_name)
	mesh.position = pos
	mesh.scale = size
	return mesh

func label(parent: Node, node_name: String, content: String, pos: Vector3, yaw: float = 180, font_size: int = 38, pixel: float = 0.006) -> Label3D:
	var l := Label3D.new()
	attach(l, parent, node_name)
	l.text = content
	l.position = pos
	l.rotation_degrees.y = yaw
	l.font_size = font_size
	l.pixel_size = pixel
	l.modulate = Color("ede7cd")
	l.outline_size = 2
	l.no_depth_test = false
	return l

func group(node_name: String, pos := Vector3.ZERO) -> Node3D:
	var node := Node3D.new()
	attach(node, props, node_name)
	node.position = pos
	return node

func collision(node_name: String, pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	attach(body, level, node_name)
	body.position = pos
	var c := CollisionShape3D.new()
	c.shape = BoxShape3D.new()
	c.shape.size = size
	attach(c, body, "Shape")

func person(parent: Node, node_name: String, pos: Vector3) -> Node3D:
	var actor := Node3D.new()
	attach(actor, parent, node_name)
	actor.position = pos
	box(actor, "Body", Vector3(0, 1.03, 0), Vector3(0.4, 0.64, 0.22), Color("222e31"))
	box(actor, "Collar", Vector3(0, 1.3, -0.12), Vector3(0.29, 0.055, 0.028), Color("d2cbb7"))
	sphere(actor, "Head", Vector3(0, 1.58, 0), Vector3(0.3, 0.34, 0.28), Color("ada893"))
	box(actor, "Hair", Vector3(0, 1.72, 0.015), Vector3(0.31, 0.095, 0.27), Color("1b2020"))
	box(actor, "LeftEye", Vector3(-0.065, 1.6, -0.139), Vector3(0.036, 0.018, 0.013), Color("131918"))
	box(actor, "RightEye", Vector3(0.065, 1.6, -0.139), Vector3(0.036, 0.018, 0.013), Color("131918"))
	box(actor, "LeftLeg", Vector3(-0.115, 0.36, 0), Vector3(0.15, 0.73, 0.18), Color("192326"))
	box(actor, "RightLeg", Vector3(0.115, 0.36, 0), Vector3(0.15, 0.73, 0.18), Color("192326"))
	box(actor, "LeftArm", Vector3(-0.27, 1, 0), Vector3(0.12, 0.61, 0.15), Color("263136"))
	box(actor, "RightArm", Vector3(0.27, 1, 0), Vector3(0.12, 0.61, 0.15), Color("263136"))
	var offer := box(actor, "Offer", Vector3(0.25, 1.05, -0.43), Vector3(0.18, 0.1, 0.22), Color("bc9d73"))
	offer.hide()
	actor.set_script(load("res://scripts/actor_visual.gd"))
	return actor

func poster(parent: Node, node_name: String, pos: Vector3, content: String) -> Node3D:
	var p := Node3D.new()
	attach(p, parent, node_name)
	p.position = pos
	box(p, "Paper", Vector3.ZERO, Vector3(0.013, 0.48, 0.34), Color("b9b7a2"))
	label(p, "Text", content, Vector3(-0.009, 0, 0), -90, 23, 0.0025).modulate = Color("293e3c")
	return p

func build() -> void:
	level = Node3D.new()
	level.name = "SchoolLevel"
	root.add_child(level)
	var model = load("res://assets/models/school.glb").instantiate()
	attach(model, level, "SchoolModel")
	model.position.x = 58.45
	props = attach(Node3D.new(), level, "Props")
	var lights := attach(Node3D.new(), level, "Lights")
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("14242c")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("869b9b")
	environment.environment.ambient_light_energy = 0.24
	environment.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	attach(environment, level, "WorldEnvironment")
	for z in [-3, 2, 7, 12, 17, 22, 27]:
		var light := OmniLight3D.new()
		attach(light, lights, "CeilingLight_%d" % (z + 3))
		light.position = Vector3(0, 2.65, z)
		light.light_color = Color("dbe2c5")
		light.light_energy = 1.2
		light.omni_range = 6.5
		light.omni_attenuation = 1.5
	collision("FloorCollision", Vector3(0, -0.095, 12), Vector3(2.1, 0.2, 40))
	collision("ClassroomBoundary", Vector3(1.17, 1.5, 12), Vector3(0.24, 3, 40))
	collision("WindowBoundary", Vector3(-1.15, 1.5, 12), Vector3(0.24, 3, 40))
	var spawn := Marker3D.new()
	attach(spawn, level, "Spawn")
	spawn.position = Vector3(0, 0.05, 0)
	spawn.rotation.y = PI
	for spec in [["ForwardExit", 26.0], ["BackExit", -3.0]]:
		var m := Marker3D.new()
		attach(m, level, spec[0])
		m.position.z = spec[1]
		box(props, spec[0] + "Darkness", Vector3(0, 1.5, spec[1] + (0.6 if spec[1] > 0 else -0.6)), Vector3(2.15, 3.2, 0.08), Color("0a1113"))
	label(props, "RoomNumber", "01", Vector3(0, 2.45, 2.5), 180, 96, 0.007)
	box(props, "RoomSignBacking", Vector3(0, 2.45, 2.55), Vector3(1.12, 0.83, 0.06), Color("173337"))
	label(props, "RoomCaption", "JUBUTSU  /  EAST WING", Vector3(0, 2.04, 2.5), 180, 22, 0.003)
	label(props, "NextNumber", "ROOM / 02", Vector3(0, 2.45, 25.8), 180, 44, 0.004)
	label(props, "ReturnLabel", "RETURN", Vector3(0, 2.4, -2.8), 0, 36, 0.005)
	label(props, "ExitSign", "ROOFTOP  →", Vector3(0.9, 2.3, 21), -90, 32, 0.004)
	var note := group("Note", Vector3(0.3, 0.026, 1.2))
	box(note, "Paper", Vector3.ZERO, Vector3(0.3, 0.007, 0.42), Color("e5d8b3"))
	for i in 7:
		box(note, "Line%d" % i, Vector3(0, 0.006, -0.15 + i * 0.045), Vector3(0.23, 0.002, 0.007), Color("45493b"))
	var bell := group("Bell", Vector3(0.89, 1.25, 3.7))
	box(bell, "Mount", Vector3(0.02, 0, 0), Vector3(0.08, 0.24, 0.24), Color("3e4a42"))
	sphere(bell, "BellMetal", Vector3(-0.11, 0, 0), Vector3(0.23, 0.23, 0.23), Color("bc9f61"))
	label(props, "BellCaption", "BELL", Vector3(0.94, 1.65, 3.7), -90, 24, 0.003)
	var posters := group("Posters")
	for i in 3:
		poster(posters, "Poster%d" % i, Vector3(0.96, 1.6, 5.5 + i * 0.48), ["SCHOOL\nNOTICE\n────────\n08 : 00", "EAST WING\n────────\nKEEP\nQUIET", "CLEANING\nDUTY\n────────\nFRIDAY"][i])
	var extra := group("ExtraPosters")
	for i in 18:
		poster(extra, "Paper%d" % i, Vector3(0.96, 0.7 + (i % 3) * 0.62, 4.8 + (i / 3) * 0.46), "DO NOT\nLOOK\nBACK")
	extra.hide()
	var door := group("Door", Vector3(1.11, 0, 8.57))
	box(door, "Panel", Vector3(0, 0.43, 0.69), Vector3(0.055, 0.86, 1.38), Color("697a70"))
	box(door, "Top", Vector3(0, 1.99, 0.69), Vector3(0.055, 0.16, 1.38), Color("697a70"))
	for z in [0.04, 0.69, 1.34]:
		box(door, "Frame_%s" % z, Vector3(0, 1.39, z), Vector3(0.055, 1.05, 0.07), Color("697a70"))
	var glass := box(door, "Glass", Vector3(0, 1.38, 0.69), Vector3(0.02, 1.02, 1.27), Color(0.42, 0.55, 0.53, 0.12))
	glass.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	box(door, "Handle", Vector3(-0.06, 1.05, 1.16), Vector3(0.07, 0.2, 0.025), Color("bdc4b8"))
	var classroom := group("ClassroomInterior")
	box(classroom, "Floor", Vector3(2.65, -0.04, 9.26), Vector3(3.2, 0.08, 3.3), Color("58655f"))
	box(classroom, "BackWall", Vector3(4.22, 1.5, 9.26), Vector3(0.08, 3, 3.3), Color("707e73"))
	box(classroom, "Ceiling", Vector3(2.65, 3.05, 9.26), Vector3(3.2, 0.08, 3.3), Color("707e73"))
	for z in [7.64, 10.88]:
		box(classroom, "Side_%s" % z, Vector3(2.65, 1.5, z), Vector3(3.2, 3, 0.08), Color("707e73"))
	for z in [8.3, 10.2]:
		box(classroom, "Desk_%s" % z, Vector3(2.8, 0.74, z), Vector3(0.65, 0.08, 0.9), Color("918265"))
		for x in [2.55, 3.05]:
			box(classroom, "Leg_%s_%s" % [x, z], Vector3(x, 0.36, z), Vector3(0.04, 0.7, 0.7), Color("414b49"))
	var class_light := OmniLight3D.new()
	attach(class_light, lights, "ClassroomLight")
	class_light.position = Vector3(2.8, 2.5, 9.26)
	class_light.omni_range = 4.0
	class_light.light_energy = 1.2
	label(props, "ClassroomLabel", "CLASS  2–B", Vector3(0.96, 2.35, 9.2), -90, 28, 0.004)
	var blood := group("Blood", Vector3(0.52, 0.022, 9.2))
	for i in 5:
		sphere(blood, "Pool%d" % i, Vector3(-i * 0.13, 0, (i % 2) * 0.14), Vector3(0.7, 0.018, 0.5), Color("621c25"))
	blood.hide()
	var board := group("Blackboard", Vector3(4.16, 1.65, 9.26))
	box(board, "Wood", Vector3.ZERO, Vector3(0.035, 1.05, 1.6), Color("6a624e"))
	box(board, "Slate", Vector3(-0.025, 0, 0), Vector3(0.02, 0.92, 1.47), Color("213e35"))
	label(board, "Writing", "TODAY\n────────────\nCLASS ENDS AT 17:00\nPLEASE GO HOME", Vector3(-0.04, 0, 0), -90, 28, 0.003)
	var speaker := group("Speaker", Vector3(0.91, 2.62, 13.9))
	box(speaker, "Cabinet", Vector3.ZERO, Vector3(0.14, 0.3, 0.43), Color("64716c"))
	for i in 6:
		box(speaker, "Grille%d" % i, Vector3(-0.076, -0.1 + i * 0.04, 0), Vector3(0.01, 0.013, 0.31), Color("172724"))
	var mirror := group("Mirror", Vector3(0.91, 1.45, 16.6))
	box(mirror, "Frame", Vector3.ZERO, Vector3(0.06, 1.46, 0.78), Color("79877c"))
	box(mirror, "Surface", Vector3(-0.04, 0, 0), Vector3(0.018, 1.34, 0.66), Color("304449"))
	# The runtime creates a planar reflection viewport on this surface.
	label(props, "MirrorCaption", "CHECK YOUR UNIFORM", Vector3(0.94, 2.3, 16.6), -90, 19, 0.0027)
	var toilet := group("ToiletDoor", Vector3(0.94, 0, 19.5))
	box(toilet, "Panel", Vector3(0, 1, 0), Vector3(0.06, 2, 0.7), Color("526966"))
	label(toilet, "Label", "WC\nMEN", Vector3(-0.04, 1.65, 0), -90, 28, 0.004)
	var peeper := person(props, "Peeper", Vector3(0.93, 0, 19.86))
	peeper.rotation_degrees.y = 90
	peeper.hide()
	var extinguisher := group("Extinguisher", Vector3(0.85, 0.5, 20.7))
	sphere(extinguisher, "Tank", Vector3.ZERO, Vector3(0.22, 0.6, 0.22), Color("a13e35"))
	box(extinguisher, "Handle", Vector3(0, 0.35, 0), Vector3(0.12, 0.09, 0.18), Color("262e2c"))
	label(props, "FireLabel", "FIRE", Vector3(0.95, 1.12, 20.7), -90, 25, 0.003)
	var bin := group("Bin", Vector3(-0.77, 0, 18))
	box(bin, "Container", Vector3(0, 0.32, 0), Vector3(0.34, 0.62, 0.4), Color("3d554d"))
	box(bin, "Opening", Vector3(0, 0.635, 0), Vector3(0.3, 0.012, 0.35), Color("0c1716"))
	var hand := group("Hand", Vector3(-0.77, 0.66, 18))
	box(hand, "Forearm", Vector3(0, 0.1, 0), Vector3(0.1, 0.4, 0.1), Color("b4ac93"))
	box(hand, "Palm", Vector3(0, 0.32, 0), Vector3(0.2, 0.19, 0.07), Color("b4ac93"))
	for i in 5:
		box(hand, "Finger%d" % i, Vector3(-0.085 + i * 0.043, 0.45, 0), Vector3(0.028, 0.15, 0.06), Color("b4ac93"))
	hand.hide()
	var sink := group("Sink", Vector3(0.78, 0, 22.8))
	box(sink, "Basin", Vector3(0, 0.84, 0), Vector3(0.36, 0.14, 0.55), Color("9da89e"))
	box(sink, "Tap", Vector3(0.05, 1.05, 0), Vector3(0.055, 0.27, 0.055), Color("7c9796"))
	box(sink, "Spout", Vector3(-0.04, 1.17, 0), Vector3(0.2, 0.05, 0.06), Color("7c9796"))
	box(sink, "BloodStream", Vector3(-0.12, 1, 0), Vector3(0.022, 0.28, 0.022), Color("8c1728")).hide()
	person(props, "Walker", Vector3(-0.38, 0, 15))
	var watcher := person(props, "WindowWatcher", Vector3(-1.85, 0.2, 11.5))
	watcher.rotation_degrees.y = -90
	watcher.hide()
	var pursuer := person(props, "Pursuer", Vector3(0, 0, 20))
	pursuer.hide()
	var ghost := group("PosterGhost", Vector3(0.925, 1.6, 6))
	sphere(ghost, "Face", Vector3.ZERO, Vector3(0.01, 0.33, 0.25), Color("777e6a"))
	for z in [-0.06, 0.06]:
		box(ghost, "Eye%s" % z, Vector3(-0.013, 0.04, z), Vector3(0.013, 0.048, 0.04), Color("070f0d"))
	ghost.hide()
	var symbol := group("PosterSymbol", Vector3(0.925, 1.6, 6))
	for i in 5:
		var stroke := box(symbol, "Stroke%d" % i, Vector3(-i * 0.001, 0, 0), Vector3(0.014, 0.34, 0.024), Color("632a2c"))
		stroke.rotation.x = i * PI / 5
	symbol.hide()
	level.set_script(load("res://scripts/school_level.gd"))
	var packed := PackedScene.new()
	var result := packed.pack(level)
	assert(result == OK)
	assert(ResourceSaver.save(packed, "res://scenes/school_level.tscn") == OK)
	print("School level saved: editable props, lighting, boundaries and source model instance.")
	quit()
