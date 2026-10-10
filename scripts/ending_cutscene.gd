extends Node3D
## Dedicated cinematic camera and actor; gameplay stays frozen throughout.
signal finished
var game: Node3D
var kind: String
var clock_time := 0.0
var actor: Node3D
var animator: AnimationPlayer
var camera: Camera3D
var daylight: Node3D
var caption: Label
var completed := false
var home_shown := false
var stage: Node3D

func begin(owner_game: Node3D, ending_kind: String, cinematic_stage: Node3D = null) -> void:
	game = owner_game
	stage = cinematic_stage if cinematic_stage != null else game.level
	kind = ending_kind
	actor = preload("res://assets/models/player_animated.tscn").instantiate()
	add_child(actor)
	animator = actor.get_node("AnimationPlayer")
	animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	animator.play("Walk")
	camera = Camera3D.new()
	add_child(camera)
	camera.fov = 48
	camera.current = true
	game.player.hide()
	game.hud.hide_menu()
	game.hud.crosshair.hide()
	game.hud.stamina_panel.hide()
	game.hud.hint_label.hide()
	game.hud.endless_status.hide()
	game.hud.room_label.hide()
	game.hud.bell_label.hide()
	game.hud.mode = "cutscene"
	game.hud.prompt.text = preload("res://scripts/localization.gd").t("[E / ESC] ข้ามคัทซีน")
	caption = game.hud.text(game.hud.screen, "", 26)
	caption.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	caption.grow_horizontal = Control.GROW_DIRECTION_BOTH
	caption.position = Vector2(-480, -125)
	caption.size = Vector2(960, 70)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if kind == "normal":
		stage.prop("Walker").hide()
		actor.position = Vector3(0, 0, stage.walker_patrol_z.x)
		caption.text = preload("res://scripts/localization.gd").t("ทางออกไม่ได้ปล่อยคุณไป\nมันเพียงเลือกคนเฝ้าทางเดินคนใหม่")
	else:
		build_daylight()
		caption.text = preload("res://scripts/localization.gd").t("คุณก้าวพ้นโรงเรียน…\nครั้งนี้ ไม่มีเสียงฝีเท้าตามมา")
	update_shot(0.0)

func block(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = .85
	mesh.material_override = material
	parent.add_child(mesh)
	mesh.position = pos

func build_daylight() -> void:
	daylight = Node3D.new()
	add_child(daylight)
	daylight.position = Vector3(200, 0, 0)
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("adcfe0")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("ffe6bd")
	env.ambient_light_energy = .8
	world.environment = env
	# Only one active environment in the viewport.
	stage.remove_child(stage.environment)
	daylight.add_child(world)
	var sun := DirectionalLight3D.new()
	daylight.add_child(sun)
	sun.rotation_degrees = Vector3(-48, -30, 0)
	sun.light_color = Color("fff1d6")
	sun.light_energy = 1.2
	block(daylight, Vector3(32, .2, 32), Vector3(0, -.1, 0), Color("809c70"))
	block(daylight, Vector3(4, .03, 24), Vector3(0, .02, 0), Color("cabca6"))
	block(daylight, Vector3(12, 5, .5), Vector3(0, 2.5, 6), Color("b4b0a1"))
	block(daylight, Vector3(2, 3.5, .55), Vector3(0, 1.75, 5.7), Color("313a3d"))
	for x in [-8, 8]:
		block(daylight, Vector3(.3, 3, .3), Vector3(x, 1.5, -3), Color("745b40"))
		block(daylight, Vector3(3, 3, 3), Vector3(x, 3.5, -3), Color("628759"))

func show_home() -> void:
	home_shown = true
	for child in daylight.get_children():
		if child is MeshInstance3D:
			child.hide()
	block(daylight, Vector3(10, .2, 10), Vector3(0, -.1, 0), Color("c6ac87"))
	block(daylight, Vector3(10, 4, .2), Vector3(0, 2, 4), Color("f2e4cf"))
	block(daylight, Vector3(.2, 4, 10), Vector3(-5, 2, 0), Color("e7d6bb"))
	block(daylight, Vector3(3, 1.8, .06), Vector3(0, 2.3, 3.85), Color("a9dcec"))
	block(daylight, Vector3(2.2, .15, 1.1), Vector3(0, .85, 1.8), Color("886344"))
	for x in [-.85, .85]:
		block(daylight, Vector3(.12, .8, .8), Vector3(x, .4, 1.8), Color("886344"))
	block(daylight, Vector3(.8, .5, .8), Vector3(0, .25, .6), Color("657e83"))
	block(daylight, Vector3(.8, .8, .12), Vector3(0, .8, .25), Color("657e83"))
	block(daylight, Vector3(.16, .22, .16), Vector3(.6, 1.03, 1.8), Color("fff5de"))
	block(daylight, Vector3(.5, .04, .35), Vector3(-.35, .96, 1.8), Color("ddd5bd"))
	caption.text = preload("res://scripts/localization.gd").t("เช้าวันธรรมดาได้กลับมาอีกครั้ง\nคุณกลับบ้าน และใช้ชีวิตของตัวเองต่อไป")

func _process(delta: float) -> void:
	if completed or not game:
		return
	clock_time += delta
	update_shot(delta)
	if clock_time >= (18.0 if kind == "normal" else 22.0):
		finish()

func update_shot(delta: float) -> void:
	if kind == "normal":
		var patrol: Vector2 = stage.walker_patrol_z
		var distance := minf(4.0, patrol.y - patrol.x)
		var phase := fmod(clock_time * .85, distance * 2)
		actor.position.z = patrol.x + (phase if phase < distance else distance * 2 - phase)
		actor.rotation.y = 0 if phase < distance else PI
		camera.position = Vector3(1.5, 1.65, patrol.x - 3.0)
		camera.look_at(actor.position + Vector3.UP * 1.1)
		if clock_time > 9:
			caption.text = preload("res://scripts/localization.gd").t("ใบหน้าของคนที่เดินวนอยู่ตรงนี้…\nกลายเป็นใบหน้าของคุณ")
	else:
		if clock_time >= 10 and not home_shown:
			show_home()
		if not home_shown:
			actor.position = Vector3(200, 0, 4 - clock_time * .7)
			actor.rotation.y = PI
			camera.position = Vector3(204.5, 2.1, -5)
		else:
			actor.position = Vector3(200, 0, minf(.8, -2.5 + (clock_time - 10) * .6))
			actor.rotation.y = 0
			if actor.position.z >= .8 and animator.current_animation != "Idle":
				animator.play("Idle")
			camera.position = Vector3(203.5, 2.2, -3.5)
		camera.look_at(actor.position + Vector3.UP * 1.0)
	animator.advance(delta)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("pause_game"):
		get_viewport().set_input_as_handled()
		finish()

func finish() -> void:
	if completed:
		return
	completed = true
	game.player.show()
	game.player.camera.current = true
	if kind == "true":
		stage.add_child(stage.environment)
	game.hud.room_label.show()
	game.hud.bell_label.show()
	game.hud.prompt.text = ""
	caption.queue_free()
	finished.emit()
	queue_free()

