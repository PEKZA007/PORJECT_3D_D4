extends Node
## Data selects events; this adapter owns effects on named editable scene nodes.
signal danger(reason: String)
signal warning(message: String)
var definitions: Array = []
var snapshots: Array[Dictionary] = []
var active_id: int = 0
var elapsed: float = 0.0
var last_sound: float = 0.0
var chase_elapsed: float = 0.0
var chase_active: bool = false
var chase_finished: bool = false
var eye_timer: float = 0.0
var walker_direction: float = -1.0
var door_progress: float = 0.0
var level: Node3D
var player: CharacterBody3D
var sound: Node
var config: Resource
var rng := RandomNumberGenerator.new()
var recent: Array[int] = []
var door_closed_position := Vector3.ZERO
var follower_active: bool = false
var endless_mode := false
var forward_progress: float = 0.0

func setup(school: Node3D, actor: CharacterBody3D, audio: Node, settings: Resource) -> void:
	level = school
	player = actor
	sound = audio
	config = settings
	rng.randomize()
	definitions = JSON.parse_string(FileAccess.get_file_as_string("res://data/anomalies.json"))
	remember(level.props)
	door_closed_position = level.prop("Door").position

func remember(node: Node) -> void:
	if node.name == "ArtRoot":
		return
	if node is Node3D:
		var state := {"node": node, "transform": node.transform, "visible": node.visible}
		if node is MeshInstance3D:
			state["material"] = node.material_override
		if node is Label3D:
			state["text"] = node.text
			state["modulate"] = node.modulate
		snapshots.append(state)
	for child in node.get_children():
		remember(child)

func select_anomaly(room: int) -> int:
	if (not endless_mode and room >= config.final_room) or (room == 1 and config.first_room_safe):
		return 0
	if config.forced_anomaly >= 0:
		return config.forced_anomaly
	if rng.randf() > config.anomaly_chance:
		return 0
	var candidates: Array = []
	for entry in definitions:
		if entry.enabled and room >= int(entry.min_room) and not recent.has(int(entry.id)):
			candidates.append(entry)
	if candidates.is_empty():
		recent.clear()
		for entry in definitions:
			if entry.enabled and room >= int(entry.min_room):
				candidates.append(entry)
	if candidates.is_empty():
		return 0
	var total: float = 0.0
	for entry in candidates:
		total += maxf(0.0, float(entry.weight))
	if total <= 0.0:
		return 0
	var draw: float = rng.randf() * total
	for entry in candidates:
		draw -= maxf(0.0, float(entry.weight))
		if draw <= 0.0:
			recent.append(int(entry.id))
			return int(entry.id)
	return 0

func title(id: int) -> String:
	for entry in definitions:
		if int(entry.id) == id:
			return preload("res://scripts/localization.gd").anomaly(id, entry.title)
	return preload("res://scripts/localization.gd").t("ทางเดินปกติ")

func reset_room(room: int, id: int) -> void:
	for state in snapshots:
		var n: Node3D = state.node
		n.transform = state.transform
		n.visible = state.visible
		if n is MeshInstance3D:
			n.material_override = state.material
		if n is Label3D:
			n.text = state.text
			n.modulate = state.modulate
	level.set_room(room)
	level.prop("NoRunningSign").text = preload("res://scripts/localization.gd").t("ห้ามวิ่ง\nNO RUNNING\nเดินไปข้างหน้าต่อไป")
	level.set_lighting(1.2)
	sound.stop_events()
	active_id = id
	elapsed = 0.0
	last_sound = 0.0
	chase_elapsed = 0.0
	chase_active = false
	chase_finished = false
	follower_active = false
	forward_progress = 0.0
	player.sprint_allowed = id != 27
	player.sprinting = false
	eye_timer = 0.0
	walker_direction = -1.0
	door_progress = 0.0
	for actor_name in ["Walker", "Peeper", "WindowWatcher", "Pursuer"]:
		level.prop(actor_name).apply_variant("masked" if id == 8 and actor_name == "Walker" else ("offering" if id == 5 and actor_name == "Walker" else ("attacker" if actor_name == "Pursuer" and id != 27 else "normal")))
	level.set_ghost_reflection(id == 9)
	match id:
		1: level.prop("Note").show()
		2: level.prop("Blood").show()
		3: pass # Opens as the player approaches, several metres before reaching the door.
		4: level.prop("ExtraPosters").show()
		5:
			level.prop("Walker/Offer").show()
			level.prop("Walker/RightArm").rotation.x = -PI / 2
		6: level.prop("PosterGhost").show()
		7: level.prop("PosterSymbol").show()
		8: pass # The actor wears the supplied geisha mask, attached to its head bone.
		9: pass # A real planar reflection swaps the reflected body to a ghost variant.
		10:
			level.prop("ToiletDoor").rotation.y = -0.3
			level.prop("Peeper").show()
		13:
			level.prop("Blackboard/Writing").text = "YOU WERE HERE\nYOU WERE HERE\nYOU WERE HERE"
			level.prop("Blackboard/Writing").modulate = Color("ba3f42")
		14: level.prop("Speaker").hide()
		15: pass # Legacy event disabled: next-room sign removed.
		16: level.prop("Mirror/Frame").hide()
		17: level.prop("Door").hide()
		18:
			level.prop("WindowWatcher").show()
			level.prop("WindowWatcher").animate(.25, "Walk")
		19: level.prop("Walker").scale = Vector3.ONE * 0.48
		20: level.set_lighting(0.0)
		23:
			level.prop("ExtraPosters").show()
			# Spread from the existing cluster instead of assuming a fixed corridor origin.
			for paper in level.prop("ExtraPosters").get_children():
				paper.position.z = 4.8 + (paper.position.z - 4.8) * 3.0
		24: level.prop("Extinguisher").hide()
		25: level.prop("Hand").show()
		26: level.prop("Sink/BloodStream").show()
		27:
			level.prop("NoRunningSign").show()
			level.prop("Walker").hide()
	level.update_door_collision()
	if not endless_mode and room >= config.final_room:
		level.prop("Walker").hide()
		level.set_lighting(1.8)

func paint(node: MeshInstance3D, color: Color) -> void:
	var m: StandardMaterial3D = node.material_override.duplicate()
	m.albedo_color = color
	node.material_override = m

func tick(delta: float) -> void:
	elapsed += delta
	var walker: Node3D = level.prop("Walker")
	walker.animate(delta, "Walk" if not chase_active else "Idle")
	if walker.visible and not chase_active:
		walker.position.z += walker_direction * delta * 0.7
		if walker.position.z < level.walker_patrol_z.x:
			walker_direction = 1.0
		if walker.position.z > level.walker_patrol_z.y:
			walker_direction = -1.0
		walker.rotation.y = 0.0 if walker_direction < 0 else PI
		walker.get_node("LeftLeg").rotation.x = sin(elapsed * 3) * 0.16
		walker.get_node("RightLeg").rotation.x = -sin(elapsed * 3) * 0.16
	if active_id != 27:
		check_eyes(delta)
	match active_id:
		27: tick_no_running(delta)
		3:
			if level.passed_ground_trigger(level.door_trigger_z):
				door_progress = minf(1.0, door_progress + delta)
				level.prop("Door").position = door_closed_position + Vector3(0, 0, door_progress * level.door_slide_distance)
		11, 21:
			var trigger_z: float = level.footsteps_trigger_z if active_id == 11 else level.attacker_trigger_z
			if not chase_active and not chase_finished and level.passed_ground_trigger(trigger_z):
				chase_active = true
				chase_elapsed = 0.0
				var pursuer: Node3D = level.prop("Pursuer")
				pursuer.position = player.position + Vector3(0, 0, 4.0 if active_id == 11 else -3.0)
				pursuer.position.x = 0.85 if active_id == 21 else 0.0
				pursuer.show()
				if active_id == 21:
					for part in pursuer.get_children():
						if part is MeshInstance3D:
							paint(part, Color("8c998b"))
				warning.emit(preload("res://scripts/localization.gd").t("วิ่งหนีจนกว่าเสียงฝีเท้าจะหยุด!  [SHIFT]"))
			if chase_active:
				chase_elapsed += delta
				var pursuer: Node3D = level.prop("Pursuer")
				var target: Vector3 = player.position
				target.y = 0.0
				pursuer.animate(delta, "Run")
				pursuer.position = pursuer.position.move_toward(target, config.chase_speed * delta)
				if pursuer.position.distance_to(target) > 0.01:
					pursuer.look_at(target + Vector3(0, 0.001, 0))
				if elapsed - last_sound > 0.32:
					sound.play_at("step", pursuer.global_position, 3.0, 0.7)
					last_sound = elapsed
				if pursuer.position.distance_to(target) < 0.48:
					danger.emit(preload("res://scripts/localization.gd").t("คุณถูกตามทัน — กด SHIFT ค้างเพื่อวิ่งหนี"))
					return
				if chase_elapsed >= config.chase_seconds:
					chase_active = false
					chase_finished = true
					pursuer.hide()
					warning.emit(preload("res://scripts/localization.gd").t("เสียงฝีเท้าหายไปแล้ว… จำกฎเรื่องความผิดปกติไว้"))
		12: level.set_lighting(0.08 if fmod(elapsed, 1.5) < 0.23 else 1.2)
		22:
			if elapsed - last_sound > 2.2:
				sound.play_at("knock", level.prop("Door").global_position)
				last_sound = elapsed
		25: level.prop("Hand").rotation.z = sin(elapsed * 2.2) * 0.13
		26:
			if elapsed - last_sound > 1.2:
				sound.play_at("water", level.prop("Sink").global_position, -8.0)
				last_sound = elapsed

func tick_no_running(delta: float) -> void:
	if not follower_active and level.passed_ground_trigger(33.0):
		follower_active = true
		forward_progress = player.position.z
		level.prop("Pursuer").position = player.position + Vector3(0, 0, 3.5)
		level.prop("Pursuer").show()
	if not follower_active:
		return
	# Allow small corrections, but walking back against the sign fails the encounter.
	forward_progress = minf(forward_progress, player.position.z)
	if player.position.z > forward_progress + 1.0:
		danger.emit(preload("res://scripts/localization.gd").t("ป้ายบอกให้เดินไปข้างหน้าต่อไป"))
		return
	var follower: Node3D = level.prop("Pursuer")
	var destination := Vector3(player.position.x, 0, player.position.z)
	follower.position = follower.position.move_toward(destination, config.walk_speed * .9 * delta)
	if follower.position.distance_to(destination) < .6:
		danger.emit(preload("res://scripts/localization.gd").t("คุณหยุดเดินจนชายข้างหลังตามทัน"))
		return
	follower.look_at(destination + Vector3(0, .001, 0))
	follower.animate(delta, "Walk")
	if elapsed - last_sound > .55:
		sound.play_at("step", follower.global_position, -5.0)
		last_sound = elapsed

func check_eyes(delta: float) -> void:
	var walker: Node3D = level.prop("Walker")
	var head: Node3D = walker.get_node("Head")
	var to_head: Vector3 = head.global_position - player.camera.global_position
	var toward_player: Vector3 = player.global_position - walker.global_position
	var facing := (-walker.global_basis.z).dot(toward_player.normalized()) > 0.45
	var looking: bool = (-player.camera.global_basis.z).dot(to_head.normalized()) > 0.993
	if looking and to_head.length() < 4.0:
		var query := PhysicsRayQueryParameters3D.create(player.camera.global_position, head.global_position, 1)
		looking = player.get_world_3d().direct_space_state.intersect_ray(query).is_empty()
	if walker.visible and facing and looking and to_head.length() < 4.0 and active_id != 8:
		eye_timer += delta
		if eye_timer > 0.35:
			warning.emit(preload("res://scripts/localization.gd").t("อย่าสบตา — หันหน้าหนี"))
		if eye_timer >= config.eye_contact_seconds:
			eye_timer = 0.0
			danger.emit(preload("res://scripts/localization.gd").t("คุณสบตากับคนในทางเดินนานเกินไป"))
	else:
		eye_timer = maxf(0.0, eye_timer - delta * 2.0)

