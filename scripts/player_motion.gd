extends RefCounted
## Coordinated motion for the extended player rig; source meshes stay intact.
static func configure(animator: AnimationPlayer) -> void:
	var library := AnimationLibrary.new()
	for state in ["Idle", "Walk", "Run"]:
		var animation := Animation.new()
		animation.length = 3.6 if state == "Idle" else (.95 if state == "Walk" else .58)
		animation.loop_mode = Animation.LOOP_LINEAR
		for bone in preload("res://scripts/body_anatomy.gd").BONES + ["ThighL", "ThighR", "ShinL", "ShinR", "FootL", "FootR"]:
			var track := animation.add_track(Animation.TYPE_ROTATION_3D)
			animation.track_set_path(track, NodePath("Skeleton3D:" + bone))
			for sample in 49:
				var phase := float(sample) / 48 * TAU
				var running: bool = state == "Run"
				var moving: bool = state != "Idle"
				var swing := sin(phase)
				var side := 1.0 if bone.ends_with("L") else -1.0
				var rotation := Vector3.ZERO
				match bone:
					"ThighL", "ThighR":
						rotation.x = -swing * side * (.52 if running else .29) if moving else 0.0
					"ShinL", "ShinR":
						# Knee flex only during the returning leg's swing, not its stance.
						rotation.x = pow(maxf(0, swing * side), 2) * (.85 if running else .42) if moving else 0.0
					"FootL", "FootR":
						rotation.x = swing * side * (.52 if running else .29) - pow(maxf(0, swing * side), 2) * (.85 if running else .42) if moving else 0.0
				if bone in preload("res://scripts/body_anatomy.gd").BONES:
					rotation = preload("res://scripts/body_anatomy.gd").rotation(bone, phase - PI / 2 if moving else phase, moving, running)
				animation.rotation_track_insert_key(track, float(sample) / 48 * animation.length, Quaternion.from_euler(rotation))
		library.add_animation(state, animation)
	animator.remove_animation_library("")
	animator.add_animation_library("", library)
