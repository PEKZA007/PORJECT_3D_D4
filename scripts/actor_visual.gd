extends Node3D
## Drag GLB/PackedScenes here. Keep the named proxy nodes as gameplay anchors.
@export var normal_model: PackedScene
@export var masked_model: PackedScene
@export var offering_model: PackedScene
@export var ghost_model: PackedScene
@export var attacker_model: PackedScene
@export var model_scale: float = 1.0
@export var model_rotation_degrees := Vector3.ZERO
@export var walk_animation: String = ""
@export var default_motion: String = "Idle"
@export var authored_walk_speed := .7
var playback_rate := 1.0
var animator: AnimationPlayer
var motion: String = "Idle"
var variant_name: String = "normal"
var art: Node3D
var offer_skeleton: Skeleton3D
var offer_hand: int = -1
var pose_smoother := preload("res://scripts/pose_smoother.gd").new()

func _ready() -> void:
	apply_variant("normal")

func apply_variant(variant: String) -> void:
	variant_name = variant
	offer_skeleton = null
	offer_hand = -1
	animator = null
	playback_rate = 1.0
	var selected: PackedScene = normal_model
	match variant:
		"masked": selected = masked_model if masked_model else normal_model
		"offering": selected = offering_model if offering_model else normal_model
		"ghost": selected = ghost_model if ghost_model else normal_model
		"attacker": selected = attacker_model if attacker_model else normal_model
	if is_instance_valid(art):
		remove_child(art)
		art.queue_free()
	for child in get_children():
		if child is MeshInstance3D and child.name != "Offer":
			child.visible = selected == null
	if selected:
		art = selected.instantiate()
		art.name = "ArtRoot"
		add_child(art)
		art.scale = Vector3.ONE * model_scale
		art.rotation_degrees = model_rotation_degrees
		pose_smoother.configure(art)
		var animations := art.find_children("*", "AnimationPlayer", true, false)
		if not animations.is_empty():
			animator = animations[0]
			animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
			create_rest_motion()
			# Own the clips before changing loop settings on imported resources.
			for library_name in animator.get_animation_library_list():
				var library: AnimationLibrary = animator.get_animation_library(library_name).duplicate(true)
				animator.remove_animation_library(library_name)
				animator.add_animation_library(library_name, library)
			for clip in animator.get_animation_list():
				if clip != "RESET":
					animator.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
			preload("res://scripts/npc_anatomy.gd").configure(animator, variant == "offering")
		motion = ""
		set_motion(default_motion)
		if animator:
			animator.advance(0)
		if variant == "offering":
			for skeleton in art.find_children("*", "Skeleton3D", true, false):
				for bone in skeleton.get_bone_count():
					if skeleton.get_bone_name(bone).begins_with("DEF-hand.R"):
						offer_skeleton = skeleton
						offer_hand = bone
			update_offer_position()
		if variant in ["ghost", "attacker"]:
			for mesh in art.find_children("*", "MeshInstance3D", true, false):
				for i in mesh.mesh.get_surface_count():
					var material: StandardMaterial3D = mesh.mesh.surface_get_material(i).duplicate()
					material.albedo_color = Color(.7,.85,.72) if variant == "ghost" else Color(.45,.5,.44)
					mesh.set_surface_override_material(i, material)
		if variant == "masked":
			var skeleton: Skeleton3D = art.find_children("*", "Skeleton3D", true, false)[0]
			for bone in skeleton.get_bone_count():
				if skeleton.get_bone_name(bone).begins_with("DEF-spine.006"):
					var attachment := BoneAttachment3D.new()
					skeleton.add_child(attachment)
					attachment.bone_idx = bone
					var mask = preload("res://assets/models/props/ghost_in_the_shell_geisha_mask.scn").instantiate()
					mask.name = "GeishaMask"
					attachment.add_child(mask)
					mask.transform = skeleton.get_bone_global_rest(bone).affine_inverse() * Transform3D(Basis(Vector3.UP, PI / 2).scaled(Vector3.ONE * .5), Vector3(0, 1.595, .13))
					break

func set_motion(state: String) -> void:
	if not animator or motion == state:
		return
	motion = state
	var clip := state if animator.has_animation(state) else walk_animation
	if not animator.has_animation(clip):
		return
	# Run may use Walk at a faster cadence; do not restart the same clip.
	if animator.current_animation != clip:
		animator.play(clip, .28)
	if state == "Idle" and clip != "Idle":
		animator.seek(0.0, true)

func animate(delta: float, state: String, speed: float = -1.0) -> void:
	if delta <= 0:
		return
	set_motion(state)
	if animator and is_visible_in_tree():
		pose_smoother.capture()
		if state != "Idle" or animator.has_animation("Idle"):
			var target_rate := 1.0
			if state != "Idle":
				target_rate = (1.75 if state == "Run" else 1.0) if speed < 0 else clampf(speed / maxf(.05, authored_walk_speed * absf(scale.x)), .12, 3.2)
			playback_rate = lerpf(playback_rate, target_rate, 1.0 - exp(-delta * 10))
			animator.advance(delta * playback_rate)
		pose_smoother.apply(delta)
	update_offer_position()

func create_rest_motion() -> void:
	if animator.has_animation("Idle") or not animator.has_animation(walk_animation):
		return
	# Average the supplied rig's walk poses for a relaxed stance, keeping its
	# own rig and arm posture. Never reset the imported model to a T-pose.
	var walk: Animation = animator.get_animation(walk_animation)
	var idle := Animation.new()
	idle.length = 3.6
	idle.loop_mode = Animation.LOOP_LINEAR
	for track in walk.get_track_count():
		var type := walk.track_get_type(track)
		var count := walk.track_get_key_count(track)
		if count == 0 or type not in [Animation.TYPE_POSITION_3D, Animation.TYPE_ROTATION_3D, Animation.TYPE_SCALE_3D]:
			continue
		var value = walk.track_get_key_value(track, 0)
		for key in range(1, count):
			var next = walk.track_get_key_value(track, key)
			value = value.slerp(next, 1.0 / (key + 1)) if type == Animation.TYPE_ROTATION_3D else value.lerp(next, 1.0 / (key + 1))
		var destination := idle.add_track(type)
		idle.track_set_path(destination, walk.track_get_path(track))
		for key in 49:
			var pose = value
			if type == Animation.TYPE_ROTATION_3D and "DEF-spine.003" in str(walk.track_get_path(track)):
				pose = value * Quaternion(Vector3.RIGHT, sin(float(key) / 48 * TAU) * .008)
			idle.track_insert_key(destination, float(key) / 48 * idle.length, pose)
	# Walk is in the unnamed imported library. Duplicate before adding a clip
	# so one NPC cannot change the shared animations of another variant.
	var existing: AnimationLibrary = animator.get_animation_library("").duplicate()
	existing.add_animation("Idle", idle)
	animator.remove_animation_library("")
	animator.add_animation_library("", existing)

func face_toward(target: Vector3, delta: float) -> void:
	var offset := target - position
	if Vector2(offset.x, offset.z).length_squared() > .0001:
		var facing := atan2(-offset.x, -offset.z)
		rotation.y += clampf(wrapf(facing - rotation.y, -PI, PI), -4.5 * delta, 4.5 * delta)

func update_offer_position() -> void:
	if is_instance_valid(offer_skeleton) and offer_hand >= 0:
		# Keep the interaction anchor and charm together as the animated hand moves.
		var hand: Vector3 = offer_skeleton.to_global(offer_skeleton.get_bone_global_pose(offer_hand).origin)
		get_node("Offer").global_position = hand + Vector3(0, -.11, 0)


