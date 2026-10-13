extends RefCounted
## Bake bounded secondary motion into private copies of the imported clips.
## Rotation offsets use each joint's local frame (Y runs along the bone).
## Sampling the original first prevents accumulation on repeated playback.
static func configure(animator: AnimationPlayer, offering: bool) -> void:
	var animation_root := animator.get_node(animator.root_node)
	for clip_name in animator.get_animation_list():
		if clip_name == "RESET":
			continue
		var clip: Animation = animator.get_animation(clip_name)
		# Imported clips omit constant bones, including the spine and shoulders.
		# Add their bind rotations explicitly so breathing and counter-motion
		# reach those joints too, rather than only modifying existing arm tracks.
		for skeleton in animation_root.find_children("*", "Skeleton3D", true, false):
			for bone_index in skeleton.get_bone_count():
				var label: String = skeleton.get_bone_name(bone_index)
				if offset(label, PI / 2, false, offering).is_zero_approx() and offset(label, 0, false, offering).is_zero_approx():
					continue
				var path := NodePath(str(animation_root.get_path_to(skeleton)) + ":" + label)
				if clip.find_track(path, Animation.TYPE_ROTATION_3D) < 0:
					var track := clip.add_track(Animation.TYPE_ROTATION_3D)
					clip.track_set_path(track, path)
					clip.rotation_track_insert_key(track, 0, skeleton.get_bone_rest(bone_index).basis.get_rotation_quaternion())
		for track in clip.get_track_count():
			if clip.track_get_type(track) != Animation.TYPE_ROTATION_3D:
				continue
			var bone := String(clip.track_get_path(track).get_concatenated_subnames())
			if not bone.begins_with("DEF-"):
				continue
			var keys: Array[Quaternion] = []
			for sample in 65:
				var time := float(sample) / 64 * clip.length
				var base := clip.rotation_track_interpolate(track, time)
				keys.append((base * Quaternion.from_euler(offset(bone, float(sample) / 64 * TAU, clip_name == "Idle", offering))).normalized())
			for key in range(clip.track_get_key_count(track) - 1, -1, -1):
				clip.track_remove_key(track, key)
			for sample in 65:
				clip.rotation_track_insert_key(track, float(sample) / 64 * clip.length, keys[sample])

static func offset(bone: String, phase: float, idle: bool, offering: bool) -> Vector3:
	var wave := sin(phase)
	var side := 1.0 if ".L" in bone else -1.0
	var arm_scale := .12 if offering and ".R" in bone else 1.0
	if bone.begins_with("DEF-spine_"):
		return Vector3(0, .012 * wave, .006 * cos(phase)) if not idle else Vector3.ZERO
	if bone.begins_with("DEF-spine.001") or bone.begins_with("DEF-spine.002"):
		return Vector3(.004 * wave, -.012 * wave if not idle else 0.0, 0)
	if bone.begins_with("DEF-spine.003"):
		return Vector3(.007 * wave, -.015 * wave if not idle else 0.0, 0)
	if bone.begins_with("DEF-spine.004") or bone.begins_with("DEF-spine.005"):
		return Vector3(-.003 * wave, .006 * wave if not idle else 0.0, 0)
	if bone.begins_with("DEF-spine.006"):
		return Vector3(-.004 * wave, .012 * wave if not idle else 0.0, 0)
	if bone.begins_with("DEF-shoulder"):
		return Vector3(.005 * wave if idle else .025 * wave * side, 0, 0) * arm_scale
	if bone.begins_with("DEF-upper_arm") and not ".001" in bone:
		return Vector3(.006 * wave if idle else .075 * sin(phase - .12) * side, 0, 0) * arm_scale
	if bone.begins_with("DEF-forearm") and not ".001" in bone:
		return Vector3(.004 * wave if idle else .04 * sin(phase - .35) * side, 0, 0) * arm_scale
	if bone.begins_with("DEF-hand"):
		return Vector3(.003 * wave if idle else .018 * sin(phase - .55) * side, 0, 0) * arm_scale
	return Vector3.ZERO
