extends SceneTree
func _initialize() -> void:
	var level = load("res://scenes/school_level.tscn").instantiate()
	var removed := 0
	for path in ["Props/RoomCaption", "Props/ReturnLabel", "Props/BellCaption", "Props/ClassroomLabel", "Props/MirrorCaption", "Props/FireLabel", "Props/ToiletDoor/Label", "MapExpansion/BasementLabel", "MapExpansion/GroundFloorLabel", "MapExpansion/LandingLabel", "MapExpansion/RoofLabel"]:
		var node = level.get_node_or_null(path)
		if node:
			node.free()
			removed += 1
	for path in ["Props/RoomNumber", "Props/NextNumber", "Props/ExitSign", "Props/Blackboard/Writing", "Props/Posters", "Props/ExtraPosters", "Props/Note"]:
		assert(level.has_node(path), "Required gameplay sign missing: " + path)
	var packed := PackedScene.new()
	assert(packed.pack(level) == OK)
	assert(ResourceSaver.save(packed,"res://scenes/school_level.tscn") == OK)
	print("Removed ", removed, " decorative labels; gameplay signs preserved.")
	level.free()
	quit()
