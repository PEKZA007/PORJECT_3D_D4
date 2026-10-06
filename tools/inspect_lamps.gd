extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var level = load("res://scenes/school_level.tscn").instantiate()
	root.add_child(level)
	for mesh in level.get_node("SchoolModel").find_children("*","MeshInstance3D",true,false):
		for i in mesh.mesh.get_surface_count():
			var mat = mesh.mesh.surface_get_material(i)
			if mat and ("Emissive" in mat.resource_name or mat.emission_enabled):
				print(mesh.name," surface=",i," material=",mat.resource_name," center=",mesh.global_transform * mesh.get_aabb().get_center()," size=",mesh.get_aabb().size * mesh.global_basis.get_scale())
	quit()
