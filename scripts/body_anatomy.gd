extends RefCounted
## Shared, bounded joint angles in radians. Pelvis leads, spine and shoulders
## counter-rotate, elbows trail the upper arms, and the neck stabilizes the head.
const BONES := ["Hips", "Spine", "Chest", "Neck", "Head", "ShoulderL", "ShoulderR", "ArmL", "ArmR", "ForearmL", "ForearmR", "HandL", "HandR"]

static func rotation(bone: String, phase: float, moving: bool, running: bool = false) -> Vector3:
	var wave := cos(phase)
	var sway := sin(phase)
	var breath := sin(phase) * .006
	var side := 1.0 if bone.ends_with("L") else -1.0
	var vigor := 1.4 if running else 1.0
	match bone:
		"Hips": return Vector3(.02 if running else 0.0, -.045 * wave * vigor, .018 * sway) if moving else Vector3(0, 0, breath * .25)
		"Spine": return Vector3(.035 if running else .012, .04 * wave * vigor, -.01 * sway) if moving else Vector3(breath, 0, -breath * .15)
		"Chest": return Vector3(.035 if running else .008, .04 * wave * vigor, -.014 * sway) if moving else Vector3(breath * .7, 0, 0)
		"Neck": return Vector3(-.025 if running else -.01, -.02 * wave * vigor, .003 * sway) if moving else Vector3(-breath * .7, 0, 0)
		"Head": return Vector3(-.025 if running else -.01, -.015 * wave * vigor, .003 * sway) if moving else Vector3(-breath, 0, 0)
	if bone.begins_with("Shoulder"):
		return Vector3(.025 * wave * side * vigor, -.015 * wave, -.015 * side * sway) if moving else Vector3(breath * .4, 0, breath * side * .3)
	if bone.begins_with("Arm"):
		return Vector3((.36 if running else .23) * cos(phase - .12) * side if moving else breath * side, .015 * side, -.52 * side)
	if bone.begins_with("Forearm"):
		# Flex toward the chest; never bend the elbow backwards.
		return Vector3(-(.85 if running else .18) - (.18 if running else .10) * (1 - cos(phase - .35) * side) * .5 if moving else -.14 + breath, 0, 0)
	if bone.begins_with("Hand"):
		return Vector3(.025 * sin(phase - .55) * side if moving else breath * .5, 0, .025 * side)
	return Vector3.ZERO
