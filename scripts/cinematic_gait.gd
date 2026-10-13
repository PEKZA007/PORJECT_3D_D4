extends RefCounted
## Distance-driven gait for the full-body cinematic rig (+Z faces forward).
## Solve legs after pose filtering so planted feet do not lag behind the body.
const STRIDE := .8
const STANCE := .6
var phase := 0.0
var weight := 0.0
var skeleton: Skeleton3D
var hips: int
var rest_hips: Vector3
var last_position := Vector3.ZERO
var initialized := false
var contact := false

func configure(model: Node3D) -> void:
	preload("res://scripts/anatomical_rig.gd").configure(model)
	skeleton = model.get_node("Skeleton3D")
	hips = skeleton.find_bone("Hips")
	rest_hips = skeleton.get_bone_rest(hips).origin

static func foot_path(cycle: float) -> Vector2:
	var p := fposmod(cycle, 1.0)
	var reach := STRIDE * STANCE * .5
	if p < STANCE:
		return Vector2(reach - STRIDE * p, .06)
	var u := (p - STANCE) / (1.0 - STANCE)
	# Hermite return matches the stance velocity at toe-off and contact.
	var travel := -reach + 2.0 * reach * (3.0 * u * u - 2.0 * u * u * u)
	travel -= STRIDE * (1.0 - STANCE) * (2.0 * u * u * u - 3.0 * u * u + u)
	return Vector2(travel, .06 + .085 * pow(sin(PI * u), 2))

func update(delta: float, model: Node3D, speed: float, seated: bool) -> void:
	contact = false
	if delta <= 0:
		return
	var distance := Vector2(model.position.x - last_position.x, model.position.z - last_position.z).length()
	if not initialized or distance > 2.0:
		distance = maxf(speed, 0.0) * delta
	last_position = model.position
	initialized = true
	if seated:
		weight = 0.0
		skeleton.set_bone_pose_position(hips, rest_hips)
		for suffix in ["L", "R"]:
			skeleton.set_bone_pose_rotation(skeleton.find_bone("Foot" + suffix), Quaternion.IDENTITY)
		return
	var old_phase := phase
	phase += distance / STRIDE
	contact = floori(phase * 2) != floori(old_phase * 2) and speed > .1
	var target := smoothstep(.02, .28, speed)
	weight = lerpf(weight, target, 1.0 - exp(-delta * 12.0))
	var cycle := fposmod(phase, 1.0)
	var wave := sin(cycle * TAU)
	# Lowest at double support, rising as the body passes over the support leg.
	var pelvis := rest_hips + Vector3(.012 * wave, -.05 + .012 * (1.0 - cos(cycle * TAU * 2)), 0)
	skeleton.set_bone_pose_position(hips, rest_hips.lerp(pelvis, weight))
	for bone in preload("res://scripts/body_anatomy.gd").BONES:
		blend_rotation(bone, preload("res://scripts/body_anatomy.gd").rotation(bone, cycle * TAU, true))
	for side in [1.0, -1.0]:
		var suffix := "L" if side > 0 else "R"
		var leg_phase := fposmod(cycle + (0.0 if side > 0 else .5), 1.0)
		var foot := foot_path(leg_phase)
		solve_leg(suffix, Vector3(.09 * side, foot.y, foot.x))

func blend_rotation(bone_name: String, euler: Vector3) -> void:
	var bone := skeleton.find_bone(bone_name)
	skeleton.set_bone_pose_rotation(bone, skeleton.get_bone_pose_rotation(bone).slerp(Quaternion.from_euler(euler), weight))

func solve_leg(suffix: String, target: Vector3) -> void:
	var thigh := skeleton.find_bone("Thigh" + suffix)
	var shin := skeleton.find_bone("Shin" + suffix)
	var parent := skeleton.get_bone_global_pose(hips)
	var hip := skeleton.get_bone_rest(thigh).origin
	var offset := parent.affine_inverse() * target - hip
	var upper := skeleton.get_bone_rest(shin).origin.length()
	var lower := .37 # Shin rest height .43, sole contact reference .06.
	var length := clampf(offset.length(), .001, upper + lower - .001)
	var direction := offset.normalized()
	var bend := (Vector3.BACK - direction * Vector3.BACK.dot(direction)).normalized()
	var cosine := clampf((upper * upper + length * length - lower * lower) / (2 * upper * length), -1, 1)
	var knee := (direction * cosine + bend * sqrt(maxf(0, 1 - cosine * cosine))) * upper
	var upper_rotation := Quaternion(Vector3.DOWN, knee.normalized())
	var lower_rotation := upper_rotation.inverse() * Quaternion(Vector3.DOWN, (direction * length - knee).normalized())
	skeleton.set_bone_pose_rotation(thigh, skeleton.get_bone_pose_rotation(thigh).slerp(upper_rotation, weight))
	skeleton.set_bone_pose_rotation(shin, skeleton.get_bone_pose_rotation(shin).slerp(lower_rotation, weight))
	var ankle := skeleton.find_bone("Foot" + suffix)
	var shin_basis := skeleton.get_bone_global_pose(shin).basis.get_rotation_quaternion()
	skeleton.set_bone_pose_rotation(ankle, Quaternion.IDENTITY.slerp(shin_basis.inverse(), weight))
