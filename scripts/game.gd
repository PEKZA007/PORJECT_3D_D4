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
var charm_position := Vector3(0, .02, 20)
var ending: String = ""
var cutscene: Node3D
var play_mode := "normal"
var progress = preload("res://scripts/mode_progress.gd").new()
var ranked_run := true
var replay_stage: Node3D

func reset_charm() -> void:
	charm_room = randi_range(1, config.final_room)
	charm_position = Vector3(randf_range(-.45, .15), .02, randf_range(2.0, 32.0))
	charm_collected = false
	ending = ""

func _ready() -> void:
	progress.load_progress()
	configure_input()
	player.walk_speed = config.walk_speed
	player.sprint_speed = config.sprint_speed
	player.stamina_capacity = config.stamina_seconds
	player.stamina_recovery = config.stamina_recovery
	player.stamina_delay = config.stamina_recovery_delay
	player.sensitivity = config.mouse_sensitivity
	level.setup_mirror(player)
	director.setup(level, player, sound, config)
	director.danger.connect(fail_run)
	hud.configure_rules(config.final_room, config.bell_rooms)
	hud.configure_modes(progress.unlocked, progress.best_rooms, progress.best_seconds)
	hud.collection_requested.connect(func(): hud.open_collection(progress, director.definitions))
	hud.ending_replay_requested.connect(replay_ending)
	hud.language_changed.connect(refresh_language)
	hud.mode_picker.item_selected.connect(func(_index: int): hud.update_mode_description())
	player.footstep.connect(func(sprint: bool): sound.play_at("step", player.global_position, -14.0 if sprint else -19.0))
	hud.primary_pressed.connect(primary_action)
	hud.restart_pressed.connect(start_run)
	hud.title_requested.connect(return_to_title)
	hud.debug_requested.connect(debug_load)
	hud.volume_changed.connect(set_volume)
	hud.music_volume_changed.connect(sound.set_music_volume)
	hud.sensitivity_changed.connect(func(value: float): player.sensitivity = config.mouse_sensitivity * value)
	set_volume(hud.volume_slider.value / 100.0)
	sound.set_music_volume(hud.music_volume_slider.value / 100.0)
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

func set_volume(value: float) -> void:
	AudioServer.set_bus_mute(0, value <= 0.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(value, 0.0001)))

func refresh_language() -> void:
	hud.configure_rules(config.final_room, config.bell_rooms)
	hud.configure_modes(progress.unlocked, progress.best_rooms, progress.best_seconds)
	update_hud()
	hud.hint_label.text = progress.hint(room) if play_mode == "easy" and started else ""
	level.prop("NoRunningSign").text = preload("res://scripts/localization.gd").t("ห้ามวิ่ง\nNO RUNNING\nเดินไปข้างหน้าต่อไป")
	if hud.settings_origin == "win":
		if not ending.is_empty():
			show_ending_result()
		elif play_mode == "endless":
			finish_endless()

func start_run() -> void:
	if transitioning:
		return
	if hud.mode == "title":
		play_mode = ["easy", "normal", "endless"][hud.mode_picker.selected]
	if play_mode == "endless" and not progress.unlocked:
		return
	director.endless_mode = play_mode == "endless"
	player.stamina_enabled = play_mode == "normal"
	ranked_run = config.forced_anomaly < 0
	hud.share_text = ""
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
	if running or hud.mode == "pause":
		collect_encounter()
	if play_mode == "endless":
		store_endless_record()
	director.endless_mode = false
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
	hud.hint_label.text = ""
	hud.endless_status.text = ""
	hud.configure_modes(progress.unlocked, progress.best_rooms, progress.best_seconds)
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
	level.prop("CharmPickup").visible = play_mode != "endless" and room == charm_room and not charm_collected
	level.prop("CharmPickup").position = charm_position
	player.reset_at(level.get_node("Spawn").global_transform)
	update_hud()
	hud.hint_label.text = progress.hint(room) if play_mode == "easy" and started else ""
	hud.hint_label.visible = running and not hud.hint_label.text.is_empty()

func update_hud() -> void:
	hud.update_stamina(player.stamina_enabled and started, player.stamina / player.stamina_capacity, player.exhausted)
	hud.update_status(room, config.final_room, rings, config.bell_rooms.has(room))
	hud.endless_status.text = preload("res://scripts/localization.gd").t("ไร้สิ้นสุด  |  ชั้น %d  |  ผ่าน %d ชั้น  |  สถิติ %d") % [room, rounds, progress.best_rooms] if play_mode == "endless" and started else ""
	hud.endless_status.visible = running and not hud.endless_status.text.is_empty()

func _unhandled_input(event: InputEvent) -> void:
	if transitioning or hud.mode == "cutscene" or (event is InputEventKey and event.echo):
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
	if hud.mode == "collection":
		if event.is_action_pressed("pause_game"):
			hud.close_collection()
		return
	if hud.mode == "credits":
		if event.is_action_pressed("pause_game"):
			hud.close_credits()
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
	hud.update_stamina(player.stamina_enabled and started, player.stamina / player.stamina_capacity, player.exhausted)
	if transitioning:
		return
	update_interaction()
	if player.position.y < level.fall_reset_height:
		fail_run(preload("res://scripts/localization.gd").t("คุณหลุดออกจากทางเดิน"))
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
	hud.prompt.text = "[E]" if not target.is_empty() and target != "CharmPickup" else ""

func interact() -> void:
	match target:
		"CharmPickup":
			if level.prop("CharmPickup").visible and not charm_collected:
				charm_collected = true
				level.prop("CharmPickup").hide()
				sound.play_ui("success")
		"Bell":
			rings += 1
			sound.play_at("bell", level.prop("Bell").global_position, -4.0)
			update_hud()
		"Note": pause_game("note")
		"Door/Handle":
			if director.active_id != 3:
				level.toggle_classroom_door()
		"Walker/Offer": fail_run(preload("res://scripts/localization.gd").t("คุณรับของจากคนแปลกหน้า — อย่าไว้ใจใครในทางเดิน"))

func choose_exit(turned_back: bool) -> void:
	if transitioning or not running:
		return
	collect_encounter()
	if director.chase_active:
		# A boundary never bypasses the survival timer.
		fail_run(preload("res://scripts/localization.gd").t("ยังหนีไม่พ้น — วิ่งในทางเดินจนกว่าผู้ไล่ตามจะหายไป"))
		return
	var rule_room: int = ((room - 1) % config.final_room) + 1 if play_mode == "endless" else room
	var rule_final: int = config.final_room + 1 if play_mode == "endless" else config.final_room
	var verdict := Rules.evaluate(rule_room, rule_final, director.active_id != 0, turned_back, rings, config.bell_rooms, director.active_id)
	if verdict.won:
		win_run()
	elif verdict.ok:
		if director.active_id != 0:
			found[director.active_id] = true
		rounds += 1
		if play_mode == "endless":
			store_endless_record()
		transition_to(room + 1 if play_mode == "endless" else int(verdict.next), "", false)
	else:
		fail_run(verdict.reason)

func fail_run(reason: String) -> void:
	if transitioning or not running:
		return
	collect_encounter()
	failures += 1
	if play_mode == "endless":
		finish_endless()
		return
	reset_charm()
	transition_to(1, reason if config.explain_failures else "", true)

func transition_to(next_room: int, message: String, failed: bool) -> void:
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
	if failed and next_room == 1:
		sound.play_ui("return_sting", -4.0)
	var reveal := create_tween()
	reveal.tween_property(hud.fade, "color:a", 0.0, 0.5)
	await reveal.finished
	transitioning = false
	player.enabled = running

func win_run() -> void:
	if transitioning or not ending.is_empty():
		return
	running = false
	player.enabled = false
	sound.stop_events()
	sound.play_ui("success")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	ending = "true" if charm_collected else "normal"
	if ranked_run:
		progress.unlocked = true
		progress.collect_ending(ending)
		progress.save_progress()
		hud.configure_modes(progress.unlocked, progress.best_rooms, progress.best_seconds)
	transitioning = true
	cutscene = preload("res://scripts/ending_cutscene.gd").new()
	add_child(cutscene)
	cutscene.finished.connect(show_ending_result)
	cutscene.begin(self, ending)

func show_ending_result() -> void:
	transitioning = false
	var ending_title := "TRUE ENDING" if ending == "true" else "NORMAL ENDING"
	var ending_story := preload("res://scripts/localization.gd").t("คุณออกจากโรงเรียนได้แล้ว\nกลับบ้าน และใช้ชีวิตปกติอีกครั้ง\nครั้งนี้… คุณเป็นอิสระแล้ว") if ending == "true" else preload("res://scripts/localization.gd").t("คุณไม่ได้ออกไปจากที่นี่\nคุณกลายเป็นคนที่เดินวนอยู่ในทางเดิน\nแทนที่คนแปลกหน้าที่คุณเคยพบ")
	hud.show_menu("win", preload("res://scripts/localization.gd").t("%s\n\n%s\n\nเวลา  %02d:%02d\nเริ่มใหม่  %d ครั้ง\nสังเกตพบความผิดปกติ  %d แบบ") % [ending_title, ending_story, int(elapsed) / 60, int(elapsed) % 60, failures, found.size()])
	hud.menu_subtitle.text = ending_title

func debug_load(id: int) -> void:
	if transitioning or not config.debug_enabled:
		return
	started = true
	ranked_run = false
	load_room(2, id)
	resume_game()
	hud.toast(preload("res://scripts/localization.gd").t("ทดสอบ %02d: %s") % [id, director.title(id)], 5.0)

func store_endless_record() -> void:
	if ranked_run:
		progress.record(rounds, elapsed, found.size())
		hud.configure_modes(progress.unlocked, progress.best_rooms, progress.best_seconds)

func finish_endless() -> void:
	running = false
	player.enabled = false
	sound.stop_events()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	store_endless_record()
	hud.share_text = preload("res://scripts/localization.gd").t("JUBUTSU — โหมดไร้สิ้นสุด\nผ่าน %d ชั้น | เวลา %02d:%02d | พบความผิดปกติ %d แบบ\nสถิติส่วนตัว: %d ชั้น") % [rounds, int(elapsed) / 60, int(elapsed) % 60, found.size(), progress.best_rooms]
	if not ranked_run:
		hud.share_text += preload("res://scripts/localization.gd").t("\nรอบทดสอบ — ไม่นับสถิติ")
	hud.show_menu("win", "ENDLESS RUN\n\n" + hud.share_text)
	hud.menu_title.text = "ENDLESS"

func collect_encounter() -> void:
	if ranked_run and started:
		progress.discover(director.active_id)

func replay_ending(id: String) -> void:
	if transitioning or hud.mode != "collection" or not progress.endings.has(id):
		return
	transitioning = true
	running = false
	player.enabled = false
	replay_stage = preload("res://scenes/school_level.tscn").instantiate()
	var replay_environment: WorldEnvironment = replay_stage.get_node("WorldEnvironment")
	replay_environment.environment = replay_environment.environment.duplicate()
	if replay_stage.has_node("ClassroomLuminaire"):
		var luminaire: MeshInstance3D = replay_stage.get_node("ClassroomLuminaire")
		luminaire.material_override = luminaire.material_override.duplicate()
	level.hide()
	# Keep the original room, actor positions, and run inventory intact.
	level.remove_child(level.environment)
	add_child(replay_stage)
	replay_stage.set_room(config.final_room)
	replay_stage.set_lighting(1.8)
	sound.set_paused(false)
	cutscene = preload("res://scripts/ending_cutscene.gd").new()
	add_child(cutscene)
	cutscene.finished.connect(finish_ending_replay)
	cutscene.begin(self, id, replay_stage)

func finish_ending_replay() -> void:
	remove_child(replay_stage)
	replay_stage.queue_free()
	replay_stage = null
	level.add_child(level.environment)
	level.show()
	transitioning = false
	sound.set_paused(hud.collection_origin == "pause")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var origin: String = hud.collection_origin
	hud.show_menu(origin)
	hud.open_collection(progress, director.definitions)



