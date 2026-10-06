extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var level = load("res://scenes/school_level.tscn").instantiate()
	root.add_child(level)
	for node in level.find_children("*","MeshInstance3D",true,false):
		if "RouteBarriers" in str(node.get_path()) or "Darkness" in node.name or "Boundary" in node.name:
			print(node.get_path(), " position=",node.global_position," scale=",node.global_basis.get_scale()," bounds=",node.get_aabb()," visible=",node.visible)
	quit()
