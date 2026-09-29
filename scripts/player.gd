extends CharacterBody3D

@export var speed: float = 4.2
@export var mouse_sensitivity: float = 0.0022

var camera: Camera3D
var pitch: float = 0.0
var mouse_captured: bool = true

func _ready() -> void:
	camera = $Camera3D
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and mouse_captured:
		rotate_y(-event.relative.x * mouse_sensitivity)
		pitch = clamp(pitch - event.relative.y * mouse_sensitivity, -1.3, 1.3)
		camera.rotation.x = pitch
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		mouse_captured = not mouse_captured
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if mouse_captured else Input.MOUSE_MODE_VISIBLE)

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
	global_position.x = clamp(global_position.x, -11.5, 11.5)
	global_position.z = clamp(global_position.z, -8.7, 8.7)
	global_position.y = 1.75
