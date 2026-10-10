extends CharacterBody3D
@export var walk_speed: float = 2.7
@export var sprint_speed: float = 5.5
@export var sensitivity: float = 0.0022
@export var eye_height: float = 1.49
@export var eye_forward_offset: float = 0.40
@export var step_height: float = 0.26
var enabled: bool = false
var sprinting: bool = false
var sprint_allowed: bool = true
var stamina_enabled := false
var stamina_capacity := 6.0
var stamina := 6.0
var stamina_recovery := .8
var stamina_delay := 1.5
var stamina_rest := 0.0
var exhausted := false
var step_clock: float = 0.0
signal footstep(sprinting: bool)
@onready var camera: Camera3D = $Camera3D

func _unhandled_input(event: InputEvent) -> void:
	if enabled and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and event is InputEventMouseMotion:
		rotate_y(-event.relative.x * sensitivity)
		camera.rotation.x = clampf(camera.rotation.x - event.relative.y * sensitivity, -1.52, 1.35)

func _physics_process(delta: float) -> void:
	if not enabled:
		velocity = Vector3.ZERO
		return
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input.x, 0, input.y)).normalized()
	update_stamina(delta, sprint_allowed and Input.is_action_pressed("sprint") and input.length() > .1)
	var speed := sprint_speed if sprinting else walk_speed
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = -0.2
	try_step_up(Vector3(velocity.x, 0, velocity.z) * delta)
	move_and_slide()
	update_body(delta)
	update_eye_position()
	camera.position.y = move_toward(camera.position.y, eye_height, delta * 1.8)
	if Vector2(velocity.x, velocity.z).length() > 0.5:
		step_clock += delta
		if step_clock > (0.3 if sprinting else 0.52):
			step_clock = 0.0
			footstep.emit(sprinting)
	camera.fov = lerpf(camera.fov, 79.0 if sprinting else 74.0, delta * 5.0)

func reset_at(spawn: Transform3D) -> void:
	if body_animator:
		body_motion = "Idle"
		body_animator.play("Idle")
		body_animator.advance(0)
	global_transform = spawn
	velocity = Vector3.ZERO
	camera.rotation = Vector3.ZERO
	camera.position = Vector3(0, eye_height, -eye_forward_offset)
	step_clock = 0.0
	reset_stamina()

func reset_stamina() -> void:
	stamina = stamina_capacity
	stamina_rest = 0.0
	exhausted = false
	sprinting = false

func update_stamina(delta: float, wants_sprint: bool) -> void:
	if not enabled:
		return
	if not stamina_enabled:
		sprinting = wants_sprint
		return
	if exhausted and stamina >= stamina_capacity * .25:
		exhausted = false
	sprinting = wants_sprint and sprint_allowed and not exhausted and stamina > 0.0
	if sprinting:
		stamina = maxf(0.0, stamina - delta)
		stamina_rest = 0.0
		if stamina <= 0.0:
			exhausted = true
			sprinting = false
	else:
		var previous_rest := stamina_rest
		stamina_rest += delta
		var recovery_time := maxf(0.0, stamina_rest - maxf(previous_rest, stamina_delay))
		stamina = minf(stamina_capacity, stamina + recovery_time * stamina_recovery)

func try_step_up(motion: Vector3) -> void:
	if motion.length_squared() < 0.000001 or not is_on_floor():
		return
	if not test_move(global_transform, motion):
		return
	var raised := global_transform
	raised.origin.y += step_height
	if test_move(global_transform, Vector3.UP * step_height) or test_move(raised, motion):
		return
	var probe := global_position + motion.normalized() * (0.27 + motion.length())
	var query := PhysicsRayQueryParameters3D.create(probe + Vector3.UP * (step_height + 0.04), probe - Vector3.UP * 0.03, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or hit.normal.y < 0.7:
		return
	var rise: float = hit.position.y - global_position.y + 0.012
	if rise < 0.02 or rise > step_height:
		return
	global_position.y += rise
	camera.position.y -= rise

var body_animator: AnimationPlayer
var body_motion: String = "Idle"
func _ready() -> void:
	body_animator = $BodyVisual/AnimationPlayer
	body_animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for mesh in $BodyVisual.find_children("*", "MeshInstance3D", true, false):
		mesh.layers = 8
		var body_mesh := MeshInstance3D.new()
		body_mesh.name = "FirstPerson" + mesh.name
		body_mesh.mesh = load("res://assets/models/first_person_%s.res" % mesh.name)
		body_mesh.skin = mesh.skin
		body_mesh.skeleton = mesh.skeleton
		body_mesh.layers = 16
		body_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh.get_parent().add_child(body_mesh)
	camera.position = Vector3(0, eye_height, -eye_forward_offset)
	camera.cull_mask = 1 | 2 | 16
	body_animator.play("Idle")
	body_animator.advance(0)

func update_body(delta: float) -> void:
	var next := "Idle" if Vector2(velocity.x, velocity.z).length() < .1 else ("Run" if sprinting else "Walk")
	if next != body_motion:
		body_motion = next
		body_animator.play(next, .18)
	body_animator.advance(delta)

func update_eye_position() -> void:
	var origin := global_position + Vector3.UP * camera.position.y
	var desired := origin - global_basis.z * eye_forward_offset
	var query := PhysicsRayQueryParameters3D.create(origin, desired, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	camera.position.z = -eye_forward_offset
	if not hit.is_empty():
		camera.position.z = -maxf(0.0, origin.distance_to(hit.position) - .055)

