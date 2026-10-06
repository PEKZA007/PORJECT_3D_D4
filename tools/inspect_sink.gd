extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var model = load("res://assets/models/sink.glb").instantiate()
	root.add_child(model)
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		print(mesh.get_path(), " ", mesh.global_transform * mesh.get_aabb())
		for height in [.90,.92,.94,.96,.98,1.0]:
			var box := AABB()
			var first := true
			for i in mesh.mesh.get_surface_count():
				for v in mesh.mesh.surface_get_arrays(i)[Mesh.ARRAY_VERTEX]:
					var p: Vector3 = Basis(Vector3.UP,-PI/2) * (mesh.global_transform * v) * .525 + Vector3(0,.525,0)
					if absf(p.y-height) < .009:
						box = AABB(p, Vector3.ZERO) if first else box.expand(p)
						first = false
			print(height," ",box)
	model.free()
	quit()
