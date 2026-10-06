extends SceneTree
## Bake selected source meshes into editable, metre-scaled props. Sources stay intact.
var level: Node3D

func _initialize() -> void:
	call_deferred("run")

func make_art(file: String, height: float, yaw: float = 0, selection: String = "") -> Node3D:
	DirAccess.make_dir_recursive_absolute("res://assets/models/props")
	var source = load("res://assets/models/%s.glb" % file).instantiate()
	root.add_child(source)
	var art := Node3D.new()
	art.name = "ArtRoot"
	var bounds := AABB()
	var first := true
	for original in source.find_children("*", "MeshInstance3D", true, false):
		var path := str(original.get_path())
		if file == "plastic_round_bin" and ("lid" in path or "Sphere" in path):
			continue # Keep the opening clear for the hand anomaly.
		if file == "tf2_hd_fire_extinguisher" and "/Armature/" in path:
			continue # The source includes a detached animated hose far behind the cabinet.
		if selection == "desk" and original.name not in ["Object_133", "Object_134", "Object_135"]:
			continue
		var part := MeshInstance3D.new()
		part.name = original.name
		var mesh: ArrayMesh = crop_desk(original) if selection == "desk" else original.mesh.duplicate()
		var mesh_path := "res://assets/models/props/%s_%s.res" % [selection if selection != "" else file, original.name]
		assert(ResourceSaver.save(mesh, mesh_path, ResourceSaver.FLAG_COMPRESS) == OK)
		mesh.take_over_path(mesh_path)
		part.mesh = mesh
		art.add_child(part)
		part.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)), Vector3.ZERO) * original.global_transform
		var box: AABB = part.transform * part.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	assert(not first)
	var factor := height / bounds.size.y
	var center := bounds.get_center()
	for part in art.get_children():
		part.transform = Transform3D(Basis.from_scale(Vector3.ONE * factor), -center * factor) * part.transform
		part.owner = art
	art.set_meta("source_asset", "res://assets/models/%s.glb" % file)
	var packed := PackedScene.new()
	assert(packed.pack(art) == OK)
	DirAccess.make_dir_recursive_absolute("res://assets/models/props")
	assert(ResourceSaver.save(packed, "res://assets/models/props/%s.scn" % (selection if selection != "" else file)) == OK)
	source.free()
	return art

func crop_desk(original: MeshInstance3D) -> ArrayMesh:
	# The supplied classroom batches a row of four desks into each mesh.
	var result := ArrayMesh.new()
	for surface in original.mesh.get_surface_count():
		var data := MeshDataTool.new()
		data.create_from_surface(original.mesh, surface)
		var builder := SurfaceTool.new()
		builder.begin(Mesh.PRIMITIVE_TRIANGLES)
		for face in data.get_face_count():
			var center := Vector3.ZERO
			for corner in 3:
				center += original.global_transform * data.get_vertex(data.get_face_vertex(face, corner)) / 3.0
			if center.z > 12.4:
				continue
			for corner in 3:
				var index := data.get_face_vertex(face, corner)
				builder.set_normal(data.get_vertex_normal(index))
				builder.set_uv(data.get_vertex_uv(index))
				builder.add_vertex(data.get_vertex(index))
		builder.set_material(original.mesh.surface_get_material(surface))
		builder.generate_tangents()
		builder.commit(result)
	return result

func replace_prop(path: String, art: Node3D, offset := Vector3.ZERO) -> void:
	var anchor := level.get_node("Props/" + path)
	if anchor is MeshInstance3D:
		anchor.mesh = null
	for child in anchor.get_children():
		if child is MeshInstance3D or child.name == "ArtRoot":
			child.free()
	anchor.add_child(art)
	art.position = offset
	own(art)

func own(node: Node) -> void:
	node.owner = level
	for child in node.get_children():
		own(child)

func run() -> void:
	level = load("res://scenes/school_level.tscn").instantiate()
	# Work outside the tree so gameplay _ready does not modify the saved scene.
	replace_prop("Bell", make_art("school_electric_bell", .32, -90), Vector3(-.06, 0, 0))
	replace_prop("Speaker", make_art("loudspeakers__horn__speaker_9_mb", .36, -90), Vector3(-.15, 0, 0))
	replace_prop("Extinguisher", make_art("tf2_hd_fire_extinguisher", .8, -90), Vector3(-.03, 0, 0))
	replace_prop("Bin", make_art("plastic_round_bin", .64), Vector3(0, .32, 0))
	replace_prop("Walker/Offer", make_art("omamori", .22, 180))
	# Use the geisha face for the existing ghost-poster anomaly.
	replace_prop("PosterGhost", make_art("ghost_in_the_shell_geisha_mask", .52, -90), Vector3(-.12, 0, 0))
	var furniture := level.get_node("Props/ClassroomInterior")
	for child in furniture.get_children():
		if str(child.name).begins_with("Desk_") or str(child.name).begins_with("Leg_") or str(child.name).begins_with("ImportedDesk"):
			child.free()
	var desk := make_art("school_class_room_light_ver", .78, -90, "desk")
	for i in 2:
		var item := desk.duplicate()
		item.name = "ImportedDesk%d" % i
		furniture.add_child(item)
		item.position = Vector3(2.85, .39, 8.25 + i * 1.9)
		for mesh in item.get_children():
			mesh.create_trimesh_collision()
		own(item)
	desk.free()
	preload("res://scripts/prop_mounting.gd").mount_level(level)
	var packed := PackedScene.new()
	assert(packed.pack(level) == OK)
	assert(ResourceSaver.save(packed, "res://scenes/school_level.tscn") == OK)
	level.free()
	print("Supplied props and classroom furniture installed")
	quit()
