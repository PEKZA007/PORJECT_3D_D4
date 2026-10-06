extends SceneTree
# Rebuild only the derived player rig; source GLB stays untouched.
var model: Node3D
var skeleton: Skeleton3D
var centers := [Vector3(0,.83,0),Vector3(0,1.1,0),Vector3(0,1.4,0),Vector3(.18,1.3,0),Vector3(-.18,1.3,0),Vector3(.09,.81,0),Vector3(-.09,.81,0),Vector3(.09,.43,0),Vector3(-.09,.43,0)]
var names := ["Hips","Chest","Head","ArmL","ArmR","ThighL","ThighR","ShinL","ShinR"]
var parents := [-1,0,1,1,1,0,0,5,6]
func _initialize() -> void:
	call_deferred("run")
func own(node: Node) -> void:
	for child in node.get_children():
		child.owner = model
		own(child)
func run() -> void:
	model = Node3D.new()
	model.name = "PlayerArt"
	root.add_child(model)
	skeleton = Skeleton3D.new()
	skeleton.name = "Skeleton3D"
	model.add_child(skeleton)
	for i in names.size():
		skeleton.add_bone(names[i])
		skeleton.set_bone_parent(i, parents[i])
		var offset: Vector3 = centers[i] - (centers[parents[i]] if parents[i] >= 0 else Vector3.ZERO)
		skeleton.set_bone_rest(i, Transform3D(Basis.IDENTITY, offset))
		skeleton.set_bone_pose_position(i, offset)
	var skin := skeleton.create_skin_from_rest_transforms()
	var source = load("res://assets/models/player.glb").instantiate()
	root.add_child(source)
	for original in source.find_children("*", "MeshInstance3D", true, false):
		var mesh := ArrayMesh.new()
		for surface in original.mesh.get_surface_count():
			var arrays: Array = original.mesh.surface_get_arrays(surface)
			for custom in [Mesh.ARRAY_CUSTOM0, Mesh.ARRAY_CUSTOM1, Mesh.ARRAY_CUSTOM2, Mesh.ARRAY_CUSTOM3]:
				arrays[custom] = null
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var bones := PackedInt32Array()
			var weights := PackedFloat32Array()
			for v in vertices:
				var bone := 1
				var other := 1
				var blend := 0.0
				if v.y > 1.36:
					bone = 2
				elif absf(v.x) > .18 and v.y > 1.38 - 1.5 * absf(v.x):
					bone = 3 if v.x > 0 else 4
					blend = 1.0 - smoothstep(.18,.28,absf(v.x))
				elif v.y < .55:
					bone = 5 if v.x > 0 else 6
					other = 7 if v.x > 0 else 8
					blend = 1.0 - smoothstep(.36,.5,v.y)
				elif v.y < 1.0:
					bone = 0
				bones.append_array(PackedInt32Array([bone,other,0,0]))
				weights.append_array(PackedFloat32Array([1.0-blend,blend,0,0]))
			arrays[Mesh.ARRAY_BONES] = bones
			arrays[Mesh.ARRAY_WEIGHTS] = weights
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			var material: StandardMaterial3D = original.mesh.surface_get_material(surface).duplicate()
			material.metallic = 0
			material.normal_enabled = false
			mesh.surface_set_material(surface, material)
		var instance := MeshInstance3D.new()
		instance.name = original.name
		skeleton.add_child(instance)
		instance.mesh = mesh
		instance.skin = skin
		instance.skeleton = NodePath("..")
	var animator := AnimationPlayer.new()
	animator.name = "AnimationPlayer"
	model.add_child(animator)
	var library := AnimationLibrary.new()
	for state in ["Idle", "Walk", "Run"]:
		var animation := Animation.new()
		animation.length = 2.8 if state == "Idle" else (.95 if state == "Walk" else .58)
		animation.loop_mode = Animation.LOOP_LINEAR
		for bone in range(1,names.size()):
			var track := animation.add_track(Animation.TYPE_ROTATION_3D)
			animation.track_set_path(track, NodePath("Skeleton3D:" + names[bone]))
			for frame in 25:
				var phase := float(frame) / 24.0 * TAU
				var amplitude := 0.025 if state == "Idle" else (.3 if state == "Walk" else .5)
				var angle := sin(phase) * amplitude
				var rotation := Vector3.ZERO
				if bone in [3,4]:
					rotation.z = -.52 if bone == 3 else .52
					rotation.x = angle * (1 if bone == 3 else -1)
				elif bone in [5,6]:
					rotation.x = angle * (-1 if bone == 5 else 1)
				elif bone in [7,8]:
					rotation.x = maxf(0, angle * (1 if bone == 7 else -1)) * 1.5
				else:
					rotation.z = sin(phase) * .015
				animation.rotation_track_insert_key(track, float(frame)/24.0*animation.length, Quaternion.from_euler(rotation))
		library.add_animation(state, animation)
	animator.add_animation_library("",library)
	own(model)
	var packed := PackedScene.new()
	packed.pack(model)
	ResourceSaver.save(packed,"res://assets/models/player_animated.tscn")
	source.queue_free()
	print("Generated player rig and Idle / Walk / Run animations")
	quit()

