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
var animator: AnimationPlayer
var motion: String = "Idle"
var variant_name: String = "normal"
var art: Node3D
var offer_skeleton: Skeleton3D
var offer_hand: int = -1

func _ready() -> void:
	apply_variant("normal")

func apply_variant(variant: String) -> void:
	variant_name = variant
	offer_skeleton = null
	offer_hand = -1
	animator = null
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
		var animations := art.find_children("*", "AnimationPlayer", true, false)
		if not animations.is_empty():
			animator = animations[0]
			animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
			for clip in animator.get_animation_list():
				animator.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
		motion = ""
		set_motion(default_motion)
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
	animator.play(clip, .15)
	if state == "Idle" and clip != "Idle":
		animator.seek(0.0, true)

func animate(delta: float, state: String) -> void:
	set_motion(state)
	if animator and is_visible_in_tree():
		if state != "Idle" or animator.has_animation("Idle"):
			animator.advance(delta * (1.75 if state == "Run" and not animator.has_animation("Run") else 1.0))
	update_offer_position()

func update_offer_position() -> void:
	if is_instance_valid(offer_skeleton) and offer_hand >= 0:
		# Keep the interaction anchor and charm together as the animated hand moves.
		var hand: Vector3 = offer_skeleton.to_global(offer_skeleton.get_bone_global_pose(offer_hand).origin)
		get_node("Offer").global_position = hand + Vector3(0, -.11, 0)

