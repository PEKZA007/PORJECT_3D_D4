extends CharacterBody3D

signal interact_requested(collider: Node)
signal look_target_changed(target_id: String)
signal quest_requested
signal seal_requested

@export var speed: float = 4.6
@export var mouse_sensitivity: float = 0.0022
@export var interaction_mask: int = 2

var camera: Camera3D
var pitch: float = 0.0
var mouse_captured: bool = true
var last_target_id: String = ""

func _ready() -> void:
	camera = $Camera3D
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and mouse_captured:
		rotate_y(-event.relative.x * mouse_sensitivity)
		pitch = clamp(pitch - event.relative.y * mouse_sensitivity, -1.3, 1.3)
		camera.rotation.x = pitch
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			mouse_captured = not mouse_captured
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if mouse_captured else Input.MOUSE_MODE_VISIBLE)
		elif event.keycode == KEY_E and mouse_captured:
			_try_interact()
		elif event.keycode == KEY_1:
			quest_requested.emit()
		elif event.keycode == KEY_2:
			seal_requested.emit()

func _physics_process(_delta: float) -> void:
	var input_vector: Vector2 = Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_vector.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_vector.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_vector.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_vector.y += 1.0
	input_vector = input_vector.normalized()
	var direction: Vector3 = (transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)).normalized()
	velocity = direction * speed
	move_and_slide()
	global_position.x = clamp(global_position.x, 0.8, 12.8)
	global_position.z = clamp(global_position.z, 0.8, 44.0)
	global_position.y = clamp(global_position.y, 0.9, 17.5)

	var current_target_id: String = _get_look_target()
	if current_target_id != last_target_id:
		last_target_id = current_target_id
		look_target_changed.emit(current_target_id)

func _get_look_target() -> String:
	if camera == null:
		return ""
	var origin: Vector3 = camera.global_position
	var end: Vector3 = origin + -camera.global_transform.basis.z * 3.6
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin, end, interaction_mask)
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit and hit.collider is Node and hit.collider.has_meta("interact_id"):
		return str(hit.collider.get_meta("interact_id"))
	return ""

func _try_interact() -> void:
	if camera == null:
		return
	var origin: Vector3 = camera.global_position
	var end: Vector3 = origin + -camera.global_transform.basis.z * 3.6
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin, end, interaction_mask)
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit and hit.collider is Node and hit.collider.has_meta("interact_id"):
		interact_requested.emit(hit.collider)
