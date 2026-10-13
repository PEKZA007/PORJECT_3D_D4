extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var model: Node3D = load("res://assets/models/player_animated.tscn").instantiate()
	root.add_child(model)
	var gait := preload("res://scripts/cinematic_gait.gd").new()
	gait.configure(model)
	var skeleton: Skeleton3D = model.get_node("Skeleton3D")
	assert(skeleton.get_bone_count() == 19, "Cinematic rig has spine, neck, shoulders, elbows, wrists and ankles")
	for instance in skeleton.find_children("*", "MeshInstance3D", true, false):
		for surface in instance.mesh.get_surface_count():
			var arrays: Array = instance.mesh.surface_get_arrays(surface)
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			for index in range(0, weights.size(), 4):
				assert(absf(weights[index] + weights[index + 1] + weights[index + 2] + weights[index + 3] - 1.0) < .0001)
	var max_slide := 0.0
	for fps in [30, 60, 120]:
		gait.phase = 0
		gait.weight = 1
		gait.initialized = false
		model.position = Vector3.ZERO
		var previous := Vector3.ZERO
		var previous_phase := 1.0
		for tick in fps * 3:
			model.position.z += .7 / fps
			gait.update(1.0 / fps, model, .7, false)
			var phase := fposmod(gait.phase, 1.0)
			var ankle := model.position + skeleton.get_bone_global_pose(skeleton.find_bone("ShinL")) * Vector3(0, -.37, 0)
			assert(ankle.is_finite())
			if phase < .6:
				var sole := skeleton.get_bone_global_pose(skeleton.find_bone("FootL"))
				assert(sole.basis.get_rotation_quaternion().angle_to(Quaternion.IDENTITY) < .001, "Support sole stays level")
				assert(absf(ankle.y - .06) < .002, "Support foot stays on the floor")
				if previous_phase < phase and previous_phase < .6:
					max_slide = maxf(max_slide, ankle.distance_to(previous))
			else:
				assert(ankle.y >= .059, "Swing foot clears the floor")
			previous = ankle
			previous_phase = phase
	assert(max_slide < .002, "Support foot must not slide as the actor moves")
	for tick in 120:
		gait.update(1.0 / 60, model, 0, false)
	assert(gait.weight < .001, "Gait settles when stopped")
	gait.update(1.0 / 60, model, 0, true)
	assert(skeleton.get_bone_pose_position(gait.hips).is_equal_approx(gait.rest_hips), "Seated cut restores pelvis height")
	# Inspect a full stride with the actual skinned model in native runs.
	if DisplayServer.get_name() != "headless":
		model.position = Vector3.ZERO
		var camera := Camera3D.new()
		root.add_child(camera)
		camera.position = Vector3(2.3, 1.1, 2.8)
		camera.look_at(Vector3(0, .8, 0))
		camera.current = true
		var light := DirectionalLight3D.new()
		root.add_child(light)
		light.rotation_degrees = Vector3(-35, -25, 0)
		var floor_mesh := MeshInstance3D.new()
		floor_mesh.mesh = PlaneMesh.new()
		root.add_child(floor_mesh)
		for index in 4:
			gait.phase = index * .25
			gait.weight = 1
			gait.initialized = true
			gait.last_position = model.position
			gait.update(1.0 / 60, model, .7, false)
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://docs/cinematic_stride_%s.png" % index)
	model.queue_free()
	await process_frame
	print("CINEMATIC GAIT: PASS (30/60/120 fps, support foot drift=", max_slide, ", clearance, stop, seated reset)")
	quit()
