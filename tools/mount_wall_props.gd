extends SceneTree
func _initialize() -> void:
	var level = load("res://scenes/school_level.tscn").instantiate()
	preload("res://scripts/prop_mounting.gd").mount_level(level)
	var packed := PackedScene.new()
	assert(packed.pack(level) == OK)
	assert(ResourceSaver.save(packed, "res://scenes/school_level.tscn") == OK)
	level.free()
	print("Wall props mounted; bin and hand aligned")
	quit()
