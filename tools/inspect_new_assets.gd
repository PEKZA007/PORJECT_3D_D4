extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for file in ["plastic_round_bin", "loudspeakers__horn__speaker_9_mb", "omamori", "school_class_room_light_ver", "school_electric_bell", "ghost_in_the_shell_geisha_mask", "tf2_hd_fire_extinguisher"]:
		var model = load("res://assets/models/%s.glb" % file).instantiate()
		root.add_child(model)
		var total := AABB()
		var first := true
		for mesh in model.find_children("*", "MeshInstance3D", true, false):
			var bounds: AABB = mesh.global_transform * mesh.get_aabb()
			total = bounds if first else total.merge(bounds)
			first = false
			print(file, " MESH ", mesh.get_path(), " ", bounds)
		print("TOTAL ", file, " ", total)
		model.free()
	quit()
