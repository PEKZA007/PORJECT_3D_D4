extends SceneTree
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var model: Node3D = load("res://assets/models/player_animated.tscn").instantiate()
	root.add_child(model)
	var skeleton: Skeleton3D = model.get_node("Skeleton3D")
	var bind_poses: Array[Transform3D] = []
	for bone in skeleton.get_bone_count():
		bind_poses.append(skeleton.get_bone_global_rest(bone))
	preload("res://scripts/anatomical_rig.gd").configure(model)
	preload("res://scripts/anatomical_rig.gd").configure(model)
	assert(skeleton.get_bone_count() == 19, "Rig setup is idempotent")
	for bone in bind_poses.size():
		assert(bind_poses[bone].is_equal_approx(skeleton.get_bone_global_rest(bone)), "Original bind positions remain intact")
	var influences: Dictionary = {}
	for mesh in skeleton.find_children("*", "MeshInstance3D", true, false):
		for surface in mesh.mesh.get_surface_count():
			var arrays: Array = mesh.mesh.surface_get_arrays(surface)
			var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			for index in range(0, weights.size(), 4):
				var total := 0.0
				for slot in 4:
					assert(weights[index + slot] >= 0 and weights[index + slot] <= 1)
					total += weights[index + slot]
					if weights[index + slot] > .01:
						influences[skeleton.get_bone_name(bones[index + slot])] = true
				assert(absf(total - 1) < .0001)
	for bone in preload("res://scripts/body_anatomy.gd").BONES:
		assert(influences.has(bone), "Joint must actually deform the mesh: " + bone)
	var animator: AnimationPlayer = model.get_node("AnimationPlayer")
	preload("res://scripts/player_motion.gd").configure(animator)
	for state in ["Idle", "Walk", "Run"]:
		var clip := animator.get_animation(state)
		for track in clip.get_track_count():
			var start := clip.rotation_track_interpolate(track, 0)
			var end := clip.rotation_track_interpolate(track, clip.length)
			assert(absf(start.normalized().dot(end.normalized())) > .999999, "Loop seam stays continuous")
		for bone in ["Spine", "Chest", "Neck", "ShoulderL", "ForearmL", "HandL"]:
			var track := clip.find_track(NodePath("Skeleton3D:" + bone), Animation.TYPE_ROTATION_3D)
			assert(track >= 0)
			var a := clip.rotation_track_interpolate(track, clip.length * .25)
			var b := clip.rotation_track_interpolate(track, clip.length * .75)
			if state != "Idle":
				b = clip.rotation_track_interpolate(track, clip.length * .05)
			assert(a.angle_to(b) > .0005, "Upper body joint moves: " + bone)
	for sample in 120:
		var phase := sample / 120.0 * TAU
		for running in [false, true]:
			var elbow := preload("res://scripts/body_anatomy.gd").rotation("ForearmL", phase, true, running)
			assert(elbow.x <= -.1 and elbow.x >= -1.1, "Elbow flexion never reverses")
			var head := Vector3.ZERO
			for bone in ["Hips", "Spine", "Chest", "Neck", "Head"]:
				head += preload("res://scripts/body_anatomy.gd").rotation(bone, phase, true, running)
			assert(absf(head.y) < .001, "Neck counter-rotation stabilizes gaze")
	var original: Node3D = load("res://assets/models/player_animated.tscn").instantiate()
	assert(original.get_node("Skeleton3D").get_bone_count() == 9, "Source scene is not mutated")
	original.free()
	if DisplayServer.get_name() != "headless":
		animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		var camera := Camera3D.new()
		root.add_child(camera)
		camera.position = Vector3(1.6, 1.2, 2.2)
		camera.look_at(Vector3(0, .86, 0))
		camera.current = true
		var light := DirectionalLight3D.new()
		root.add_child(light)
		light.rotation_degrees = Vector3(-30, -20, 0)
		light.light_energy = 1.4
		var ground := MeshInstance3D.new()
		ground.mesh = PlaneMesh.new()
		root.add_child(ground)
		for state in ["Idle", "Walk", "Run"]:
			animator.play(state)
			animator.advance(0)
			for tick in 90:
				animator.advance(1.0 / 60)
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://docs/anatomy_%s.png" % state.to_lower())
	model.queue_free()
	await process_frame
	print("BODY ANATOMY: PASS (19 joints, bind poses, skin weights, joint motion, loop seams, elbow limits, gaze, source isolation)")
	quit()
