extends SceneTree
func _initialize() -> void:
	var level = load("res://scenes/school_level.tscn").instantiate()
	var wall: Node3D = level.get_node("RouteBarriers/WindowBoundary")
	var old_x := wall.position.x
	wall.position.x -= 0.20
	var packed := PackedScene.new()
	assert(packed.pack(level) == OK)
	assert(ResourceSaver.save(packed, "res://scenes/school_level.tscn") == OK)
	print("Window wall and child collision moved outward: ", old_x, " -> ", wall.position.x)
	level.free()
	quit()
