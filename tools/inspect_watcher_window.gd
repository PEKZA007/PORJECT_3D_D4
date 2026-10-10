extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var level = load("res://scenes/school_level.tscn").instantiate()
	root.add_child(level)
	var zone := AABB(Vector3(-2,1,10.5),Vector3(1,1.6,2))
	for m in level.get_node("SchoolModel").find_children("*","MeshInstance3D",true,false):
		var b: AABB = m.global_transform*m.get_aabb()
		if b.intersects(zone):
			print(m.name," ",b)
			for i in m.mesh.get_surface_count(): print("  ",m.mesh.surface_get_material(i).resource_name)
	level.free()
	quit()
