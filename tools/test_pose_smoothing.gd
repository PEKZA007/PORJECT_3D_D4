extends SceneTree

func _initialize() -> void:
	var model := Node3D.new()
	var skeleton := Skeleton3D.new()
	model.add_child(skeleton)
	skeleton.add_bone("Joint")
	var smoother := preload("res://scripts/pose_smoother.gd").new()
	smoother.configure(model)
	var results: Array[Quaternion] = []
	for fps in [30, 60, 120]:
		skeleton.reset_bone_poses()
		for frame in fps / 10:
			smoother.capture()
			skeleton.set_bone_pose_rotation(0, Quaternion(Vector3.RIGHT, 1.0))
			skeleton.set_bone_pose_position(0, Vector3.UP)
			smoother.apply(1.0 / fps)
		results.append(skeleton.get_bone_pose_rotation(0))
		assert(skeleton.get_bone_pose_position(0).y > .94 and skeleton.get_bone_pose_position(0).y < 1.0)
		assert(skeleton.get_bone_pose_rotation(0).is_normalized())
	assert(results[0].angle_to(results[1]) < .001)
	assert(results[1].angle_to(results[2]) < .001, "Smoothing response is independent of frame rate")
	var before := skeleton.get_bone_pose_rotation(0)
	smoother.capture()
	skeleton.set_bone_pose_rotation(0, Quaternion(Vector3.RIGHT, -1.0))
	smoother.apply(1.0 / 60)
	assert(before.angle_to(skeleton.get_bone_pose_rotation(0)) < .8, "Abrupt pose changes are softened")
	model.free()
	print("POSE SMOOTHING: PASS (30/60/120 fps, normalized rotation, bounded transition)")
	quit()
