extends RefCounted
## Extend only the derived player mesh. Preserve original bone indices and
## global bind positions so saved animations and first-person meshes still fit.
static var mesh_cache: Dictionary = {}

static func configure(model: Node3D) -> void:
	var skeleton: Skeleton3D = model.get_node("Skeleton3D")
	if skeleton.find_bone("Spine") >= 0:
		return
	insert_joint(skeleton, "Spine", "Hips", Vector3(0, .99, 0), "Chest")
	insert_joint(skeleton, "Neck", "Chest", Vector3(0, 1.35, 0), "Head")
	for side in [1.0, -1.0]:
		var suffix := "L" if side > 0 else "R"
		insert_joint(skeleton, "Shoulder" + suffix, "Chest", Vector3(.10 * side, 1.29, 0), "Arm" + suffix)
		insert_joint(skeleton, "Forearm" + suffix, "Arm" + suffix, Vector3(.29 * side, 1.10, 0))
		insert_joint(skeleton, "Hand" + suffix, "Forearm" + suffix, Vector3(.36 * side, .94, 0))
		insert_joint(skeleton, "Foot" + suffix, "Shin" + suffix, Vector3(.09 * side, .06, 0))
	var skin := skeleton.create_skin_from_rest_transforms()
	for instance in skeleton.find_children("*", "MeshInstance3D", true, false):
		var source: Mesh = instance.mesh
		var key := source.get_instance_id()
		if not mesh_cache.has(key):
			mesh_cache[key] = rebind(source, skeleton)
		instance.mesh = mesh_cache[key]
		instance.skin = skin

static func insert_joint(skeleton: Skeleton3D, label: String, parent_name: String, center: Vector3, child_name: String = "") -> void:
	var parent := skeleton.find_bone(parent_name)
	var bone := skeleton.get_bone_count()
	var rest := Transform3D(Basis.IDENTITY, center)
	skeleton.add_bone(label)
	skeleton.set_bone_parent(bone, parent)
	var local := skeleton.get_bone_global_rest(parent).affine_inverse() * rest
	skeleton.set_bone_rest(bone, local)
	skeleton.set_bone_pose_position(bone, local.origin)
	if not child_name.is_empty():
		var child := skeleton.find_bone(child_name)
		var child_rest := rest.affine_inverse() * skeleton.get_bone_global_rest(child)
		skeleton.set_bone_parent(child, bone)
		skeleton.set_bone_rest(child, child_rest)
		skeleton.set_bone_pose_position(child, child_rest.origin)

static func rebind(source: Mesh, skeleton: Skeleton3D) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	for surface in source.get_surface_count():
		var arrays: Array = source.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var old_bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var old_weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var bones := PackedInt32Array()
		var weights := PackedFloat32Array()
		for index in vertices.size():
			var v := vertices[index]
			var suffix := "L" if v.x > 0 else "R"
			var arm_weight := 0.0
			for slot in 4:
				if old_bones[index * 4 + slot] in [3, 4]:
					arm_weight += old_weights[index * 4 + slot]
			var a: String
			var b: String
			var blend: float
			if arm_weight > .001:
				if v.y > 1.17:
					a = "Shoulder" + suffix
					b = "Arm" + suffix
					blend = 1.0 - smoothstep(1.17, 1.29, v.y)
				elif v.y > 1.00:
					a = "Arm" + suffix
					b = "Forearm" + suffix
					blend = 1.0 - smoothstep(1.06, 1.15, v.y)
				else:
					a = "Forearm" + suffix
					b = "Hand" + suffix
					blend = 1.0 - smoothstep(.91, .99, v.y)
			elif v.y > 1.31:
				a = "Neck"
				b = "Head"
				blend = smoothstep(1.34, 1.40, v.y)
			elif v.y >= .99:
				a = "Spine"
				b = "Chest"
				blend = smoothstep(1.02, 1.19, v.y)
			elif v.y >= .55:
				a = "Hips"
				b = "Spine"
				blend = smoothstep(.87, 1.03, v.y)
			elif v.y >= .20:
				a = "Thigh" + suffix
				b = "Shin" + suffix
				blend = 1.0 - smoothstep(.36, .50, v.y)
			else:
				a = "Shin" + suffix
				b = "Foot" + suffix
				blend = 1.0 - smoothstep(.10, .20, v.y)
			# Keep the existing shoulder seam connected to the torso.
			var torso := (1.0 - arm_weight) if arm_weight > .001 else 0.0
			bones.append_array(PackedInt32Array([skeleton.find_bone(a), skeleton.find_bone(b), skeleton.find_bone("Chest"), 0]))
			weights.append_array(PackedFloat32Array([(1 - blend) * (1 - torso), blend * (1 - torso), torso, 0]))
		arrays[Mesh.ARRAY_BONES] = bones
		arrays[Mesh.ARRAY_WEIGHTS] = weights
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh.surface_set_material(surface, source.surface_get_material(surface))
	return mesh
