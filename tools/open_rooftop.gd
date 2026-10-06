extends SceneTree
## Non-destructive doorway cut: derived wall meshes, source GLB left unchanged.
const OPENINGS := ["Object_130", "Object_132", "Object_253", "Object_255", "Object_364", "Object_366", "Object_241", "Object_243", "Object_245", "Object_360", "Object_87", "Object_106"]
var level: Node3D

func _initialize() -> void:
	call_deferred("run")

func interpolate(a: Dictionary, b: Dictionary, t: float) -> Dictionary:
	return {"p": a.p.lerp(b.p, t), "n": a.n.lerp(b.n, t).normalized(), "uv": a.uv.lerp(b.uv, t)}

func clip(poly: Array, axis: int, boundary: float, greater: bool) -> Array:
	var result: Array = []
	if poly.is_empty():
		return result
	for i in poly.size():
		var a: Dictionary = poly[i]
		var b: Dictionary = poly[(i + 1) % poly.size()]
		var a_inside: bool = a.p[axis] >= boundary if greater else a.p[axis] <= boundary
		var b_inside: bool = b.p[axis] >= boundary if greater else b.p[axis] <= boundary
		if a_inside:
			result.append(a)
		if a_inside != b_inside:
			result.append(interpolate(a, b, (boundary - a.p[axis]) / (b.p[axis] - a.p[axis])))
	return result

func emit_polygon(builder: SurfaceTool, poly: Array) -> void:
	for i in range(1, poly.size() - 1):
		for v in [poly[0], poly[i], poly[i + 1]]:
			builder.set_normal(v.n)
			builder.set_uv(v.uv)
			builder.add_vertex(v.p)

func cut_wall(node: MeshInstance3D) -> ArrayMesh:
	var result := ArrayMesh.new()
	var planes := [[0, -3.4, true], [0, -2.7, false], [1, 8.77, true], [1, 10.98, false], [2, -14.33, true], [2, -13.48, false]]
	for surface in node.mesh.get_surface_count():
		var arrays: Array = node.mesh.surface_get_arrays(surface)
		var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var builder := SurfaceTool.new()
		builder.begin(Mesh.PRIMITIVE_TRIANGLES)
		var source_material: StandardMaterial3D = node.mesh.surface_get_material(surface).duplicate()
		source_material.metallic = 0.0
		source_material.roughness = 0.82
		builder.set_material(source_material)
		for i in range(0, indices.size(), 3):
			var poly: Array = []
			for k in range(i, i + 3):
				var index: int = indices[k]
				poly.append({"p": node.global_transform * positions[index], "n": (node.global_basis.inverse().transposed() * normals[index]).normalized(), "uv": uv[index] if not uv.is_empty() else Vector2.ZERO})
			for plane in planes:
				emit_polygon(builder, clip(poly, plane[0], plane[1], not plane[2]))
				poly = clip(poly, plane[0], plane[1], plane[2])
				if poly.is_empty():
					break
		builder.index()
		builder.commit(result)
	return result

func faces_of(node: Node, faces: PackedVector3Array) -> PackedVector3Array:
	if node is MeshInstance3D and not node.name in OPENINGS:
		for v in node.mesh.get_faces():
			faces.append(node.global_transform * v)
	for child in node.get_children():
		faces = faces_of(child, faces)
	return faces

func run() -> void:
	level = load("res://scenes/school_level.tscn").instantiate()
	if level.has_node("MapExpansion/CarvedWalls"):
		level.free()
		quit()
		return
	var script: Script = level.get_script()
	var exported: Dictionary = {}
	for key in ["walker_patrol_z", "footsteps_trigger_z", "attacker_trigger_z", "door_trigger_z"]:
		exported[key] = level.get(key)
	level.set_script(null)
	root.add_child(level)
	var holder := Node3D.new()
	holder.name = "CarvedWalls"
	level.get_node("MapExpansion").add_child(holder)
	holder.owner = level
	for source_name in ["Object_87", "Object_106"]:
		var original: MeshInstance3D = level.get_node("SchoolModel").find_child(source_name, true, false)
		var mesh := cut_wall(original)
		var path := "res://assets/models/roof_door_%s.res" % source_name
		assert(ResourceSaver.save(mesh, path) == OK)
		var visual := MeshInstance3D.new()
		visual.name = source_name + "_Open"
		visual.mesh = load(path)
		holder.add_child(visual)
		visual.owner = level
	var faces := faces_of(level.get_node("SchoolModel").find_child("Architecture*", true, false), PackedVector3Array())
	faces = faces_of(holder, faces)
	var collision := ConcavePolygonShape3D.new()
	collision.backface_collision = true
	collision.set_faces(faces)
	assert(ResourceSaver.save(collision, "res://assets/collision/school_architecture.res") == OK)
	level.get_node("MapExpansion/SchoolArchitectureCollision/Shape").shape = collision
	var threshold := StaticBody3D.new()
	threshold.name = "RoofDoorThreshold"
	level.get_node("MapExpansion").add_child(threshold)
	threshold.owner = level
	threshold.position = Vector3(-3.2, 8.875, -13.905)
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = Vector3(0.85, 0.16, 0.85)
	threshold.add_child(shape)
	shape.owner = level
	var visual := MeshInstance3D.new()
	visual.mesh = BoxMesh.new()
	visual.mesh.size = shape.shape.size
	threshold.add_child(visual)
	visual.owner = level
	level.set_script(script)
	for key in exported:
		level.set(key, exported[key])
	var packed := PackedScene.new()
	assert(packed.pack(level) == OK)
	assert(ResourceSaver.save(packed, "res://scenes/school_level.tscn") == OK)
	print("Rooftop doorway cut through inner and outer walls; source model untouched.")
	level.queue_free()
	await process_frame
	quit()
