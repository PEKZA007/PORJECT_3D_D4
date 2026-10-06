extends Node
## Supplied music and school bell, with positional prototype effects.
var clips: Dictionary = {}
var event_players: Array[AudioStreamPlayer3D] = []
var ambient: AudioStreamPlayer
var music: AudioStreamPlayer
var bell_voice: AudioStreamPlayer3D

func _ready() -> void:
	for key in ["bell", "step", "knock", "water", "fail", "success", "hum"]:
		clips[key] = load("res://assets/audio/%s.wav" % key)
	clips.bell = load("res://assets/audio/japanese school bell Sound Effect HD.mp3")
	music = AudioStreamPlayer.new()
	music.name = "BackgroundMusic"
	add_child(music)
	var soundtrack: AudioStreamMP3 = load("res://assets/audio/The Surreal Truth.mp3").duplicate()
	soundtrack.loop = true
	music.stream = soundtrack
	music.volume_db = -23.0
	music.play()
	ambient = AudioStreamPlayer.new()
	add_child(ambient)
	var loop: AudioStreamWAV = clips.hum.duplicate()
	loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
	loop.loop_end = loop.data.size() / 2
	ambient.stream = loop
	ambient.volume_db = -27.0
	ambient.play()

func play_ui(key: String) -> void:
	var voice := AudioStreamPlayer.new()
	add_child(voice)
	voice.stream = clips[key]
	voice.volume_db = -12.0
	voice.finished.connect(voice.queue_free)
	voice.play()

func play_at(key: String, position: Vector3, volume: float = -7.0, pitch: float = 1.0) -> void:
	# Repeated interaction still counts in game rules, but must not stack long chimes.
	if key == "bell" and is_instance_valid(bell_voice):
		event_players.erase(bell_voice)
		bell_voice.stop()
		bell_voice.queue_free()
	var voice := AudioStreamPlayer3D.new()
	add_child(voice)
	voice.stream = clips[key]
	voice.global_position = position
	voice.volume_db = volume
	voice.pitch_scale = pitch
	voice.max_distance = 24.0
	voice.unit_size = 3.0
	event_players.append(voice)
	if key == "bell":
		bell_voice = voice
	voice.finished.connect(func():
		event_players.erase(voice)
		voice.queue_free())
	voice.play()

func stop_events() -> void:
	for voice in event_players:
		if is_instance_valid(voice):
			voice.stop()
			voice.queue_free()
	event_players.clear()
	bell_voice = null

func _exit_tree() -> void:
	for voice in get_children():
		if voice is AudioStreamPlayer or voice is AudioStreamPlayer3D:
			voice.stop()
			voice.stream = null
	clips.clear()

func set_paused(paused: bool) -> void:
	for voice in get_children():
		if voice is AudioStreamPlayer or voice is AudioStreamPlayer3D:
			voice.stream_paused = paused
