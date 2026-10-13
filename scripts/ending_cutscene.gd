extends Node3D
## Dedicated cinematic camera and actor; gameplay stays frozen throughout.
signal finished
var game: Node3D
var kind: String
var clock_time := 0.0
var actor: Node3D
var animator: AnimationPlayer
var pose_smoother := preload("res://scripts/pose_smoother.gd").new()
var cinematic_gait := preload("res://scripts/cinematic_gait.gd").new()
var camera: Camera3D
var daylight: Node3D
var caption: Label
var completed := false
var home_shown := false
var stage: Node3D
var fill_light: OmniLight3D
var outdoor: Node3D
var cup: Node3D
var saved_fade := 0.0
var saved_music_pause := false
var foot_voice: AudioStreamPlayer3D
var framing: Control
var dissolve: ColorRect
var shot_index := -1
var home: Node3D
var motion_rate := 1.0
var actor_speed := 0.0
var intro_notice: Node3D
var intro_walker_visible := false

func begin(owner_game: Node3D, ending_kind: String, cinematic_stage: Node3D = null) -> void:
	game = owner_game
	stage = cinematic_stage if cinematic_stage != null else game.level
	kind = ending_kind
	actor = preload("res://assets/models/player_animated.tscn").instantiate()
	add_child(actor)
	animator = actor.get_node("AnimationPlayer")
	pose_smoother.configure(actor)
	cinematic_gait.configure(actor)
	preload("res://scripts/player_motion.gd").configure(animator)
	animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	animator.play("Walk")
	animator.advance(0)
	foot_voice = AudioStreamPlayer3D.new()
	add_child(foot_voice)
	foot_voice.stream = game.sound.clips.step
	foot_voice.volume_db = -18
	camera = Camera3D.new()
	add_child(camera)
	camera.fov = 48
	camera.near = .05
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
	saved_fade = game.hud.fade.color.a
	game.hud.fade.color.a = 0.0
	game.hud.prompt.text = preload("res://scripts/localization.gd").t("[E / ESC] ข้ามคัทซีน")
	caption = game.hud.text(game.hud.screen, "", 26)
	caption.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	caption.grow_horizontal = Control.GROW_DIRECTION_BOTH
	caption.offset_left = -520
	caption.offset_right = 520
	caption.offset_top = -185
	caption.offset_bottom = -110
	caption.add_theme_color_override("font_outline_color", Color.BLACK)
	caption.add_theme_constant_override("outline_size", 6)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	framing = Control.new()
	game.hud.screen.add_child(framing)
	framing.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	framing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for bottom in [false, true]:
		var bar := ColorRect.new()
		framing.add_child(bar)
		bar.color = Color.BLACK
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.anchor_left = 0
		bar.anchor_right = 1
		bar.anchor_top = .90 if bottom else 0.0
		bar.anchor_bottom = 1.0 if bottom else .10
	dissolve = ColorRect.new()
	framing.add_child(dissolve)
	dissolve.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dissolve.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dissolve.color = Color(0, 0, 0, 0)
	# Subtitles stay above the lower matte, rather than on top of faces.
	game.hud.screen.move_child(caption, -1)
	if kind in ["normal", "intro"]:
		fill_light = OmniLight3D.new()
		add_child(fill_light)
		fill_light.light_color = Color("b8c8b3")
		fill_light.light_energy = .55
		fill_light.omni_range = 7
		intro_walker_visible = stage.prop("Walker").visible
		stage.prop("Walker").hide()
		actor.position = Vector3(0, 0, stage.walker_patrol_z.x)
		caption.text = preload("res://scripts/localization.gd").t("ทางออกไม่ได้ปล่อยคุณไป\nมันเพียงเลือกคนเฝ้าทางเดินคนใหม่")
		if kind == "intro":
			build_intro_notice()
	else:
		build_morning_audio()
		build_daylight()
		caption.text = preload("res://scripts/localization.gd").t("คุณก้าวพ้นโรงเรียน…\nครั้งนี้ ไม่มีเสียงฝีเท้าตามมา")
	update_shot(0.0)

func build_morning_audio() -> void:
	saved_music_pause = game.sound.music.stream_paused
	game.sound.music.stream_paused = true
	var rate := 22050
	var bytes := PackedByteArray()
	bytes.resize(rate * 8 * 2)
	for index in rate * 8:
		var time := float(index) / rate
		var sample := 0.0
		for start in [1.0, 2.6, 5.4]:
			var chirp: float = time - start
			if chirp >= 0 and chirp < .5:
				var phase := fmod(chirp, .17) / .17
				sample += sin(TAU * (2200 * chirp + 300 * chirp * chirp)) * sin(phase * PI) * .12
		bytes.encode_s16(index * 2, int(sample * 32767))
	var audio := AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate = rate
	audio.data = bytes
	audio.loop_mode = AudioStreamWAV.LOOP_FORWARD
	audio.loop_end = rate * 8
	var voice := AudioStreamPlayer.new()
	add_child(voice)
	voice.stream = audio
	voice.bus = "Music"
	voice.volume_db = -12
	voice.play()

func block(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = .85
	mesh.material_override = material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
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
	env.ambient_light_color = Color("d8e1e8")
	env.ambient_light_energy = .55
	world.environment = env
	# Only one active environment in the viewport.
	stage.remove_child(stage.environment)
	daylight.add_child(world)
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("679eca")
	sky_material.sky_horizon_color = Color("f2dec0")
	sky.sky_material = sky_material
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	var sun := DirectionalLight3D.new()
	daylight.add_child(sun)
	sun.rotation_degrees = Vector3(-48, -30, 0)
	sun.light_color = Color("fff1d6")
	sun.light_energy = .65
	sun.shadow_enabled = true
	outdoor = Node3D.new()
	daylight.add_child(outdoor)
	# A quiet school forecourt: measured architecture, no duplicate protagonists.
	block(outdoor, Vector3(180, .2, 180), Vector3(0, -.13, 0), Color("73796a"))
	block(outdoor, Vector3(14, .08, 22), Vector3(0, -.02, -2), Color("a5a49a"))
	for x in [-7.1, 7.1]:
		block(outdoor, Vector3(.2, .16, 22), Vector3(x, .04, -2), Color("c2c0b6"))
	block(outdoor, Vector3(18, 5, .35), Vector3(0, 2.5, 6), Color("b8b4a6"))
	block(outdoor, Vector3(18.4, .16, .9), Vector3(0, 5, 5.8), Color("646c6b"))
	block(outdoor, Vector3(2.4, 3.2, .38), Vector3(0, 1.6, 5.77), Color("333c3d"))
	for x in [-.65, .65]:
		block(outdoor, Vector3(1.16, 2.9, .06), Vector3(x, 1.53, 5.53), Color("718381"))
		block(outdoor, Vector3(.025, .32, .035), Vector3(x * .17, 1.3, 5.48), Color("b1afa5"))
	for x in [-6, -3.7, 3.7, 6]:
		block(outdoor, Vector3(1.65, 1.65, .12), Vector3(x, 2.6, 5.73), Color("545f61"))
		block(outdoor, Vector3(1.5, 1.5, .04), Vector3(x, 2.6, 5.64), Color("8a9fa5"))
		block(outdoor, Vector3(.045, 1.5, .06), Vector3(x, 2.6, 5.60), Color("c6c6ba"))
		block(outdoor, Vector3(1.5, .045, .06), Vector3(x, 2.6, 5.60), Color("c6c6ba"))
	for z in range(-10, 6, 2):
		block(outdoor, Vector3(14, .004, .015), Vector3(0, .024, z), Color("85867e"))
	for x in [-8, 8]:
		block(outdoor, Vector3(.22, 2.4, .22), Vector3(x, 1.2, -8), Color("606867"))
		block(outdoor, Vector3(.65, .15, .5), Vector3(x, 2.4, -8), Color("878c83"))
	# Slatted bench, with actual legs and a back, away from the walking route.
	for index in 5:
		block(outdoor, Vector3(2.1, .05, .075), Vector3(5, .48, -1.2 + index * .10), Color("776957"))
	for y in [.75, .92, 1.09]:
		block(outdoor, Vector3(2.1, .10, .055), Vector3(5, y, -.65), Color("776957"))
	for x in [4.2, 5.8]:
		block(outdoor, Vector3(.06, .5, .45), Vector3(x, .25, -.95), Color("464e4e"))
	# Low boundary walls keep the horizon grounded in a real location.
	for x in [-10, 10]:
		block(outdoor, Vector3(.25, 1.4, 30), Vector3(x, .7, -4), Color("969c91"))

func orb(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> Node3D:
	var mesh := MeshInstance3D.new()
	mesh.mesh = SphereMesh.new()
	mesh.scale = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = .9
	mesh.material_override = material
	parent.add_child(mesh)
	mesh.position = pos
	return mesh

func show_home() -> void:
	home_shown = true
	outdoor.hide()
	home = Node3D.new()
	daylight.add_child(home)
	block(home, Vector3(8, .12, 8), Vector3(0, -.06, 0), Color("9e8972"))
	for index in 24:
		block(home, Vector3(.012, .003, 8), Vector3(-4 + index * .34, .002, 0), Color("7e705f"))
	block(home, Vector3(8, 3.2, .12), Vector3(0, 1.6, -4), Color("dedbd1"))
	block(home, Vector3(8, .08, 8), Vector3(0, 3.22, 0), Color("dedbd1"))
	(home.get_child(home.get_child_count() - 1) as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# A visible neighboring building replaces the empty horizon beyond the window.
	block(home, Vector3(30, .15, 30), Vector3(0, -.15, 15), Color("7c8572"))
	block(home, Vector3(12, 5, .3), Vector3(0, 1.5, 12), Color("b8b5a7"))
	for x in [-4, -1.5, 1.5, 4]:
		block(home, Vector3(1.2, 1.4, .06), Vector3(x, 2.1, 11.8), Color("7f8f92"))
	block(home, Vector3(.12, 3.2, 8), Vector3(-4, 1.6, 0), Color("d0cec4"))
	block(home, Vector3(.12, 3.2, 8), Vector3(4, 1.6, 0), Color("dedbd1"))
	# Back wall is built around the window opening; light can enter it.
	block(home, Vector3(8, 1, .12), Vector3(0, .5, 4), Color("dedbd1"))
	block(home, Vector3(8, .45, .12), Vector3(0, 2.98, 4), Color("dedbd1"))
	for x in [-2.65, 2.65]:
		block(home, Vector3(2.7, 1.8, .12), Vector3(x, 1.9, 4), Color("dedbd1"))
	for x in [-1.35, 0, 1.35]:
		block(home, Vector3(.055, 1.8, .14), Vector3(x, 1.9, 4), Color("ede9de"))
	for y in [1, 1.9, 2.8]:
		block(home, Vector3(2.75, .055, .14), Vector3(0, y, 4), Color("ede9de"))
	block(home, Vector3(2.95, .06, .35), Vector3(0, .98, 3.9), Color("b8ac98"))
	for x in [-1.6, 1.6]:
		for fold in 6:
			block(home, Vector3(.075, 1.95, .09), Vector3(x + fold * .045, 1.83, 3.75), Color("c5ba9f"))
	for x in [-3.91, 3.91]:
		block(home, Vector3(.035, .1, 8), Vector3(x, .05, 0), Color("968675"))
	block(home, Vector3(8, .1, .035), Vector3(0, .05, -3.91), Color("968675"))
	block(home, Vector3(1.65, .065, .8), Vector3(0, .75, 1.7), Color("8b745b"))
	for x in [-.68, .68]:
		for z in [1.4, 2.0]:
			block(home, Vector3(.055, .72, .055), Vector3(x, .36, z), Color("73604e"))
	# Chair proportions match a seated person, rather than a solid cube.
	block(home, Vector3(.50, .05, .48), Vector3(0, .44, .65), Color("8a7965"))
	for x in [-.21, .21]:
		for z in [.45, .85]:
			block(home, Vector3(.04, .44, .04), Vector3(x, .22, z), Color("73604e"))
		block(home, Vector3(.035, .60, .035), Vector3(x, .69, .43), Color("73604e"))
	for y in [.75, .95]:
		block(home, Vector3(.46, .10, .035), Vector3(0, y, .43), Color("8a7965"))
	cup = Node3D.new()
	daylight.add_child(cup)
	cup.position = Vector3(.48, .84, 1.65)
	var mug := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = .055
	cylinder.bottom_radius = .05
	cylinder.height = .12
	mug.mesh = cylinder
	var ceramic := StandardMaterial3D.new()
	ceramic.albedo_color = Color("fff5de")
	mug.material_override = ceramic
	cup.add_child(mug)
	var handle := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = .018
	ring.outer_radius = .03
	handle.mesh = ring
	handle.material_override = ceramic
	handle.rotation.x = PI / 2
	handle.position.x = .06
	cup.add_child(handle)
	var tea := MeshInstance3D.new()
	var surface := CylinderMesh.new()
	surface.top_radius = .048
	surface.bottom_radius = .048
	surface.height = .003
	tea.mesh = surface
	tea.position.y = .061
	var tea_material := StandardMaterial3D.new()
	tea_material.albedo_color = Color("57402b")
	tea_material.roughness = .25
	tea.material_override = tea_material
	cup.add_child(tea)
	# Open exercise book, ruled pages, pencil and a saucer: everyday details.
	block(home, Vector3(.52, .018, .34), Vector3(-.15, .79, 1.65), Color("495c64"))
	block(home, Vector3(.49, .006, .32), Vector3(-.15, .802, 1.65), Color("e6dfc8"))
	block(home, Vector3(.008, .008, .32), Vector3(-.15, .808, 1.65), Color("a69e87"))
	for line in 7:
		for x in [-.285, -.025]:
			block(home, Vector3(.20, .001, .002), Vector3(x, .807, 1.53 + line * .037), Color("a9b6b4"))
	block(home, Vector3(.008, .008, .18), Vector3(.19, .797, 1.67), Color("b09d64"))
	block(home, Vector3(2.4, .012, 1.9), Vector3(0, .01, .85), Color("9c9b8d"))
	# Slim shelves with restrained book colors; all objects sit on their support.
	for y in [.5, 1, 1.5]:
		block(home, Vector3(.95, .04, .28), Vector3(-2.7, y, 3.7), Color("a79680"))
	for x in [-3.15, -2.25]:
		block(home, Vector3(.045, 1.6, .28), Vector3(x, .8, 3.7), Color("a79680"))
	for index in 6:
		block(home, Vector3(.06, .22 + index % 2 * .05, .19), Vector3(-3.05 + index * .075, 1.15, 3.69), Color("788681") if index % 2 else Color("a38e73"))
	var window_fill := OmniLight3D.new()
	home.add_child(window_fill)
	window_fill.position = Vector3(0, 2.3, 3.2)
	window_fill.light_color = Color("f3e6cf")
	window_fill.light_energy = .6
	window_fill.omni_range = 7
	caption.text = preload("res://scripts/localization.gd").t("เช้าวันธรรมดาได้กลับมาอีกครั้ง\nคุณกลับบ้าน และใช้ชีวิตของตัวเองต่อไป")

func _process(delta: float) -> void:
	if completed or not game:
		return
	clock_time += delta
	update_shot(delta)
	if clock_time >= (14.0 if kind == "intro" else (18.0 if kind == "normal" else 22.0)):
		finish()

func update_shot(delta: float) -> void:
	# Deliberate cuts. Each shot keeps movement on the same screen axis.
	var end_time := 14.0 if kind == "intro" else (18.0 if kind == "normal" else 22.0)
	dissolve.color.a = maxf(clampf(1.0 - clock_time / .6, 0, 1), clampf((clock_time - end_time + .7) / .7, 0, 1))
	if kind == "intro":
		update_intro()
	elif kind == "normal":
		var patrol: Vector2 = stage.walker_patrol_z
		var distance := minf(4.0, patrol.y - patrol.x)
		var pose := normal_pose(clock_time, distance)
		actor.position.z = patrol.x + pose.x
		actor.rotation.y = pose.y
		actor_speed = absf(normal_pose(clock_time + .01, distance).x - pose.x) / .01
		set_actor_motion("Walk" if actor_speed > .05 else "Idle")
		fill_light.position = actor.position + Vector3(0, 1.7, -1.3)
		if clock_time < 4:
			shot_index = 0
			frame(Vector3(-.58, 1.5, patrol.x - 4.5), Vector3(0, 1.05, actor.position.z), 43)
		elif clock_time < 7:
			shot_index = 1
			frame(actor.position + Vector3(-.48, .33, -1.4), actor.position + Vector3(0, .28, 0), 48)
		elif clock_time < 12:
			shot_index = 2
			var face_side := 1.0 if actor.rotation.y < 1 else -1.0
			frame(actor.position + Vector3(-.4, 1.53, face_side * 1.65), actor.position + Vector3(0, 1.48, 0), 38)
		else:
			shot_index = 3
			frame(Vector3(.58, 1.65, patrol.x + 7.0), Vector3(0, 1.05, actor.position.z), 46)
		if clock_time > 9:
			caption.text = preload("res://scripts/localization.gd").t("ใบหน้าของคนที่เดินวนอยู่ตรงนี้…\nกลายเป็นใบหน้าของคุณ")
	else:
		if clock_time >= 10 and not home_shown:
			show_home()
		if not home_shown:
			actor.position = Vector3(200, .024, 4 - clock_time * .7)
			actor.rotation.y = PI
			actor_speed = .7
			set_actor_motion("Walk")
			if clock_time < 3.5:
				shot_index = 0
				frame(Vector3(205.3, 2.0, -4.3), Vector3(200, 1.2, 3), 48)
			elif clock_time < 6.5:
				shot_index = 1
				frame(actor.position + Vector3(1.0, .4, -1.9), actor.position + Vector3(0, .35, 0), 45)
			else:
				shot_index = 2
				frame(actor.position + Vector3(.9, 1.65, -2.4), actor.position + Vector3(0, 1.43, 0), 40)
		else:
			# A clean time cut to a settled morning, avoiding a mismatched sit animation.
			actor.position = Vector3(200, -.35, .65)
			actor.rotation.y = 0
			actor_speed = 0
			set_actor_motion("Idle")
			if clock_time < 14:
				shot_index = 3
				frame(Vector3(202.8, 1.65, -1.4), Vector3(199.7, 1.05, 1.5), 48)
			elif clock_time < 17:
				shot_index = 4
				frame(Vector3(201.05, 1.45, 2.6), Vector3(200.1, .80, 1.65), 40)
			else:
				shot_index = 5
				frame(Vector3(201.1 - (clock_time - 17) * .015, 1.3, 2.25), actor.position + Vector3(0, 1.43, 0), 38)
	var target_rate := 1.0 if animator.current_animation == "Idle" else clampf(actor_speed / .8, .15, 1.8)
	motion_rate = lerpf(motion_rate, target_rate, 1 - exp(-delta * 10))
	pose_smoother.capture()
	animator.advance(delta * motion_rate)
	if kind == "true" and home_shown:
		if home_shown:
			var skeleton: Skeleton3D = actor.get_node("Skeleton3D")
			for bone in ["ThighL", "ThighR"]:
				skeleton.set_bone_pose_rotation(skeleton.find_bone(bone), Quaternion(Vector3.RIGHT, -PI / 2))
			for bone in ["ShinL", "ShinR"]:
				skeleton.set_bone_pose_rotation(skeleton.find_bone(bone), Quaternion(Vector3.RIGHT, PI / 2))
			var breath := sin((clock_time - 10) * TAU / 3.6) * .008
			skeleton.set_bone_pose_rotation(skeleton.find_bone("Spine"), Quaternion(Vector3.RIGHT, .025 + breath * .5))
			skeleton.set_bone_pose_rotation(skeleton.find_bone("Chest"), Quaternion.from_euler(Vector3(.035 + breath, 0, 0)))
			var look_down := .14 * (1 - smoothstep(17, 19, clock_time))
			skeleton.set_bone_pose_rotation(skeleton.find_bone("Neck"), Quaternion(Vector3.RIGHT, look_down * .6 - breath * .5))
			skeleton.set_bone_pose_rotation(skeleton.find_bone("Head"), Quaternion.from_euler(Vector3(look_down * .4 - breath, 0, 0)))
			for arm in ["ArmL", "ArmR"]:
				var side := 1.0 if arm == "ArmL" else -1.0
				skeleton.set_bone_pose_rotation(skeleton.find_bone(arm), Quaternion.from_euler(Vector3(-.12 + breath, 0, -.35 * side)))
				var suffix := "L" if side > 0 else "R"
				skeleton.set_bone_pose_rotation(skeleton.find_bone("Forearm" + suffix), Quaternion(Vector3.RIGHT, -.35 + breath))
				skeleton.set_bone_pose_rotation(skeleton.find_bone("Hand" + suffix), Quaternion(Vector3.RIGHT, .04))
	pose_smoother.apply(delta)
	cinematic_gait.update(delta, actor, actor_speed, kind == "true" and home_shown)
	if cinematic_gait.contact:
		foot_voice.global_position = actor.global_position
		foot_voice.play()

func set_actor_motion(motion: String) -> void:
	if animator.current_animation != motion:
		animator.play(motion, .25)

func build_intro_notice() -> void:
	intro_notice = Node3D.new()
	add_child(intro_notice)
	intro_notice.position = Vector3(.83, 1.4, 28)
	intro_notice.rotation.y = -PI / 2
	block(intro_notice, Vector3(.65, .85, .02), Vector3.ZERO, Color("c8c1a5"))
	var writing := Label3D.new()
	intro_notice.add_child(writing)
	writing.position.z = .013
	writing.font_size = 40
	writing.pixel_size = .0012
	writing.outline_size = 0
	writing.modulate = Color("343b36")
	writing.text = "AFTER CLASS\n\nRETURN YOUR BOOKS\nROOM 01\n\nBEFORE GOING HOME"

func update_intro() -> void:
	var english: bool = preload("res://scripts/localization.gd").language == "en"
	if clock_time < 6:
		actor.position = Vector3(0, 0, lerpf(34, 28, smoothstep(0, 6, clock_time)))
		actor.rotation.y = PI
		actor_speed = absf(-6 * (6 * (clock_time / 6) * (1 - clock_time / 6)) / 6)
		set_actor_motion("Walk" if actor_speed > .05 else "Idle")
		shot_index = 0 if clock_time < 3 else 1
		if shot_index == 0:
			frame(Vector3(-.55, 1.55, 25), actor.position + Vector3.UP, 45)
		else:
			frame(actor.position + Vector3(-.5, .4, -1.8), actor.position + Vector3.UP * .35, 45)
		caption.text = "I only came back to return a book..." if english else "แค่กลับมาเอาหนังสือไปคืน… แล้วก็กลับบ้าน"
	elif clock_time < 10:
		actor.position = Vector3(0, 0, 28)
		actor.rotation.y = lerpf(PI, PI / 2, smoothstep(6, 7, clock_time))
		actor_speed = 0
		set_actor_motion("Idle")
		shot_index = 2
		frame(Vector3(-.6, 1.6, 26.65), Vector3(.5, 1.4, 28), 42)
		caption.text = "Room 01. It should be just down this hallway." if english else "ห้อง 01… เดินไปอีกหน่อยก็น่าจะถึง"
	else:
		actor.position = Vector3(0, 0, lerpf(28, 25, smoothstep(10, 14, clock_time)))
		actor.rotation.y = lerpf(PI / 2, PI, smoothstep(10, 11, clock_time))
		var progress := clampf((clock_time - 10) / 4, 0, 1)
		actor_speed = 4.5 * progress * (1 - progress)
		set_actor_motion("Walk" if actor_speed > .05 else "Idle")
		shot_index = 3
		frame(Vector3(.5, 1.55, 31), actor.position + Vector3.UP, 44)
		caption.text = "Why is it so quiet today?" if english else "ทำไมวันนี้… เงียบจัง"
	fill_light.position = actor.position + Vector3(0, 1.7, -1)

func normal_pose(time: float, distance: float) -> Vector2:
	# Walk, plant the feet, turn, then walk back. Absolute timing keeps replays
	# and camera cuts consistent without snapping the actor's heading.
	if time < 4:
		return Vector2(distance * smoothstep(0, 4, time), 0)
	if time < 5:
		return Vector2(distance, PI * smoothstep(4, 5, time))
	if time < 7:
		return Vector2(lerpf(distance, distance * .5, smoothstep(5, 7, time)), PI)
	if time < 12:
		return Vector2(distance * .5, PI)
	if time < 16:
		return Vector2(distance * .5 * (1 - smoothstep(12, 16, time)), PI)
	if time < 17:
		return Vector2(0, PI + PI * smoothstep(16, 17, time))
	return Vector2(distance * .3 * smoothstep(17, 19, time), TAU)

func frame(position: Vector3, target: Vector3, lens: float) -> void:
	camera.position = position
	camera.fov = lens
	camera.look_at(target)

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
	if kind == "intro":
		stage.prop("Walker").visible = intro_walker_visible
	game.player.show()
	game.player.camera.current = true
	if kind == "true":
		stage.add_child(stage.environment)
		game.sound.music.stream_paused = saved_music_pause
	game.hud.room_label.show()
	game.hud.bell_label.show()
	game.hud.prompt.text = ""
	game.hud.fade.color.a = saved_fade
	caption.queue_free()
	if is_instance_valid(intro_notice):
		intro_notice.queue_free()
	framing.queue_free()
	finished.emit()
	queue_free()

