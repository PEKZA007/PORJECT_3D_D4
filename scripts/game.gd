extends Node3D
const Rules = preload("res://scripts/run_rules.gd")
@export var config: Resource = preload("res://data/game_config.tres")
@onready var level: Node3D = $SchoolLevel
@onready var player: CharacterBody3D = $Player
@onready var director: Node = $AnomalyDirector
@onready var hud: CanvasLayer = $HUD
@onready var sound: Node = $Audio
var room: int = 1
var rings: int = 0
var failures: int = 0
var rounds: int = 0
var elapsed: float = 0.0
var running: bool = false
var transitioning: bool = false
var started: bool = false
var target: String = ""
var found: Dictionary = {}
var charm_room: int = 0
var charm_collected: bool = false
var ending: String = ""

func reset_charm() -> void:
	charm_room = randi_range(1, config.final_room)
	charm_collected = false
	ending = ""

func _ready() -> void:
	configure_input()
	player.walk_speed = config.walk_speed
	player.sprint_speed = config.sprint_speed
	player.sensitivity = config.mouse_sensitivity
	level.setup_mirror(player)
	director.setup(level, player, sound, config)
	director.danger.connect(fail_run)
	hud.configure_rules(config.final_room, config.bell_rooms)
	player.footstep.connect(func(sprint: bool): sound.play_at("step", player.global_position, -14.0 if sprint else -19.0))
	hud.primary_pressed.connect(primary_action)
	hud.restart_pressed.connect(start_run)
	hud.title_requested.connect(return_to_title)
	hud.debug_requested.connect(debug_load)
	hud.volume_changed.connect(func(value: float): AudioServer.set_bus_volume_db(0, linear_to_db(maxf(value, 0.0001))))
	hud.sensitivity_changed.connect(func(value: float): player.sensitivity = config.mouse_sensitivity * value)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(hud.volume_slider.value / 100.0, 0.0001)))
	player.sensitivity = config.mouse_sensitivity * hud.sensitivity_slider.value
	load_room(1, 0)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func configure_input() -> void:
	var mappings := {"move_forward": KEY_W, "move_back": KEY_S, "move_left": KEY_A, "move_right": KEY_D, "sprint": KEY_SHIFT, "interact": KEY_E, "flashlight": KEY_F, "pause_game": KEY_ESCAPE, "debug_lab": KEY_F3}
	for action in mappings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var event := InputEventKey.new()
			event.physical_keycode = mappings[action]
			InputMap.action_add_event(action, event)

func start_run() -> void:
	if transitioning:
		return
	started = true
	failures = 0
	rounds = 0
	elapsed = 0.0
	found.clear()
	reset_charm()
	director.recent.clear()
	load_room(1, director.select_anomaly(1))
	resume_game()

func primary_action() -> void:
	if hud.mode == "title" or hud.mode == "win":
		start_run()
	else:
		resume_game()

func return_to_title() -> void:
	if transitioning:
		return
	started = false
	charm_room = 0
	charm_collected = false
	ending = ""
	running = false
	player.enabled = false
	sound.stop_events()
	sound.set_paused(false)
	load_room(1, 0)
	hud.show_menu("title")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func resume_game() -> void:
	if transitioning:
		return
	sound.set_paused(false)
	hud.hide_menu()
	hud.mode = "playing"
	hud.debug_panel.hide()
	running = true
	player.enabled = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func pause_game(mode: String = "pause") -> void:
	running = false
	player.enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	sound.set_paused(true)
	hud.show_menu(mode)

func load_room(number: int, anomaly: int = -1) -> void:
	room = number
	rings = 0
	target = ""
	hud.prompt.text = ""
	hud.toast("", 0.0)
	director.reset_room(room, director.select_anomaly(room) if anomaly < 0 else anomaly)
	level.prop("CharmPickup").visible = room == charm_room and not charm_collected
	player.reset_at(level.get_node("Spawn").global_transform)
	update_hud()

func update_hud() -> void:
	hud.update_status(room, config.final_room, rings, config.bell_rooms.has(room))

func _unhandled_input(event: InputEvent) -> void:
	if transitioning or (event is InputEventKey and event.echo):
		return
	if event.is_action_pressed("debug_lab") and config.debug_enabled:
		if hud.debug_panel.visible:
			hud.debug_panel.hide()
			if started:
				resume_game()
		else:
			running = false
			player.enabled = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			hud.debug_panel.show()
		return
	if event.is_action_pressed("pause_game") and hud.mode == "settings":
		hud.close_settings()
		return
	if event.is_action_pressed("interact") and hud.mode == "note" and not running:
		resume_game()
		return
	if event.is_action_pressed("pause_game") and started and hud.mode != "win":
		if hud.debug_panel.visible or not running:
			resume_game()
		else:
			pause_game()
	if not running:
		return
	if event.is_action_pressed("interact"):
		interact()
	elif event.is_action_pressed("flashlight"):
		player.get_node("Camera3D/Flashlight").visible = not player.get_node("Camera3D/Flashlight").visible

func _process(delta: float) -> void:
	if not running or transitioning:
		return
	elapsed += delta
	director.tick(delta)
	if transitioning:
		return
	update_interaction()
	if player.position.y < level.fall_reset_height:
		fail_run("คุณหลุดออกจากทางเดิน")
	else:
		var exit_side: int = level.exit_at(player.global_position)
		if exit_side != 0:
			choose_exit(exit_side < 0)

func update_interaction() -> void:
	target = ""
	var closest: float = 3.0
	for name in ["Bell", "Note", "Walker/Offer", "Door/Handle", "CharmPickup"]:
		var item: Node3D = level.prop(name)
		if not item.is_visible_in_tree():
			continue
		var difference: Vector3 = item.global_position - player.camera.global_position
		var distance := difference.length()
		if distance < closest and (-player.camera.global_basis.z).dot(difference.normalized()) > 0.87:
			var query := PhysicsRayQueryParameters3D.create(player.camera.global_position, item.global_position, 1)
			var hit := get_world_3d().direct_space_state.intersect_ray(query)
			if not hit.is_empty() and hit.position.distance_to(item.global_position) > 0.12:
				continue
			target = name
			closest = distance
	hud.prompt.text = "[E]" if not target.is_empty() else ""

func interact() -> void:
	match target:
		"CharmPickup":
			if level.prop("CharmPickup").visible and not charm_collected:
				charm_collected = true
				level.prop("CharmPickup").hide()
				sound.play_ui("success")
				hud.toast("เก็บเครื่องรางแล้ว", 2.5)
		"Bell":
			rings += 1
			sound.play_at("bell", level.prop("Bell").global_position, -4.0)
			update_hud()
		"Note": pause_game("note")
		"Door/Handle":
			if director.active_id != 3:
				level.toggle_classroom_door()
		"Walker/Offer": fail_run("คุณรับของจากคนแปลกหน้า — อย่าไว้ใจใครในทางเดิน")

func choose_exit(turned_back: bool) -> void:
	if transitioning or not running:
		return
	if director.chase_active:
		# A boundary never bypasses the survival timer.
		fail_run("ยังหนีไม่พ้น — วิ่งในทางเดินจนกว่าผู้ไล่ตามจะหายไป")
		return
	var verdict := Rules.evaluate(room, config.final_room, director.active_id != 0, turned_back, rings, config.bell_rooms, director.active_id)
	if verdict.won:
		win_run()
	elif verdict.ok:
		if director.active_id != 0:
			found[director.active_id] = true
		rounds += 1
		transition_to(int(verdict.next), "", false)
	else:
		fail_run(verdict.reason)

func fail_run(reason: String) -> void:
	if transitioning or not running:
		return
	failures += 1
	reset_charm()
	transition_to(1, reason if config.explain_failures else "", true)

func transition_to(next_room: int, message: String, _failed: bool) -> void:
	transitioning = true
	player.enabled = false
	hud.prompt.text = ""
	var tween := create_tween()
	tween.tween_property(hud.fade, "color:a", 1.0, 0.2)
	await tween.finished
	load_room(next_room)
	if not message.is_empty():
		hud.toast(message, 4.0)
	await get_tree().create_timer(0.3).timeout
	var reveal := create_tween()
	reveal.tween_property(hud.fade, "color:a", 0.0, 0.5)
	await reveal.finished
	transitioning = false
	player.enabled = running

func win_run() -> void:
	running = false
	player.enabled = false
	sound.stop_events()
	sound.play_ui("success")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	ending = "true" if charm_collected else "normal"
	var ending_title := "TRUE ENDING" if charm_collected else "NORMAL ENDING"
	var ending_story := "เครื่องรางส่องแสงในมือ\nเสียงฝีเท้าเงียบลง และคำสาปของโรงเรียนสลายไป\nครั้งนี้… คุณเป็นอิสระแล้ว" if charm_collected else "คุณเดินพ้นประตูโรงเรียน\nแต่เสียงฝีเท้ายังดังอยู่ข้างหลัง\nบางสิ่งยังรอให้คุณกลับมา"
	hud.show_menu("win", "%s\n\n%s\n\nเวลา  %02d:%02d\nเริ่มใหม่  %d ครั้ง\nสังเกตพบความผิดปกติ  %d แบบ" % [ending_title, ending_story, int(elapsed) / 60, int(elapsed) % 60, failures, found.size()])
	hud.menu_subtitle.text = ending_title

func debug_load(id: int) -> void:
	if transitioning or not config.debug_enabled:
		return
	started = true
	load_room(2, id)
	resume_game()
	hud.toast("ทดสอบ %02d: %s" % [id, director.title(id)], 5.0)

