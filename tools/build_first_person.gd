extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var source = load("res://assets/models/player_animated.tscn").instantiate()
	root.add_child(source)
	for original in source.find_children("*", "MeshInstance3D", true, false):
		var mesh := ArrayMesh.new()
		for surface in original.mesh.get_surface_count():
			var arrays: Array = original.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			if indices.is_empty():
				for i in vertices.size():
					indices.append(i)
			var kept := PackedInt32Array()
			for i in range(0, indices.size(), 3):
				if maxf(vertices[indices[i]].y, maxf(vertices[indices[i+1]].y,vertices[indices[i+2]].y)) < 1.29:
					kept.append_array(PackedInt32Array([indices[i],indices[i+1],indices[i+2]]))
			arrays[Mesh.ARRAY_INDEX] = kept
			for custom in [Mesh.ARRAY_CUSTOM0,Mesh.ARRAY_CUSTOM1,Mesh.ARRAY_CUSTOM2,Mesh.ARRAY_CUSTOM3]:
				arrays[custom] = null
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
			mesh.surface_set_material(surface,original.mesh.surface_get_material(surface))
		ResourceSaver.save(mesh,"res://assets/models/first_person_%s.res" % original.name)
	print("First-person body meshes saved")
	quit()
