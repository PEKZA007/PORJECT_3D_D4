extends RefCounted
## Small, real-time pose filter shared by imported rigs and the player.
## Snapshot before evaluating animation, then smooth the final pose (including
## procedural overrides). Never use playback time: it can slow down or reverse.
const RESPONSE := 30.0
var skeletons: Array[Skeleton3D] = []
var poses: Array = []

func configure(model: Node) -> void:
	skeletons.clear()
	poses.clear()
	for skeleton in model.find_children("*", "Skeleton3D", true, false):
		skeletons.append(skeleton)
		poses.append([])

func capture() -> void:
	for index in skeletons.size():
		var skeleton := skeletons[index]
		poses[index].resize(skeleton.get_bone_count())
		for bone in skeleton.get_bone_count():
			poses[index][bone] = skeleton.get_bone_pose(bone)

func apply(delta: float) -> void:
	var weight := 1.0 - exp(-maxf(delta, 0.0) * RESPONSE)
	for index in skeletons.size():
		var skeleton := skeletons[index]
		for bone in skeleton.get_bone_count():
			var previous: Transform3D = poses[index][bone]
			skeleton.set_bone_pose_position(bone, previous.origin.lerp(skeleton.get_bone_pose_position(bone), weight))
			skeleton.set_bone_pose_rotation(bone, previous.basis.get_rotation_quaternion().slerp(skeleton.get_bone_pose_rotation(bone), weight).normalized())
			skeleton.set_bone_pose_scale(bone, previous.basis.get_scale().lerp(skeleton.get_bone_pose_scale(bone), weight))
