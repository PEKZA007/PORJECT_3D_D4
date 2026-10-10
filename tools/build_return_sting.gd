extends SceneTree
## Short layered impact, deterministic and synthesized for this game.
func _initialize() -> void:
	var rate := 44100
	var duration := .85
	var bytes := PackedByteArray()
	bytes.resize(int(rate * duration) * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 71011
	var phase := 0.0
	var filtered_noise := 0.0
	for index in int(rate * duration):
		var time := float(index) / rate
		phase += TAU * (45.0 + 180.0 * exp(-time * 13.0)) / rate
		filtered_noise = lerpf(filtered_noise, rng.randf_range(-1, 1), .38)
		var attack := minf(1.0, time / .003)
		var tail := clampf((duration - time) / .1, 0, 1)
		var impact := sin(phase) * .55 * exp(-time * 7)
		var noise := filtered_noise * .8 * exp(-time * 10)
		var metal := (sin(TAU * 731 * time) + sin(TAU * 1139 * time)) * .12 * exp(-time * 5)
		var sample := clampf((impact + noise + metal) * attack * tail * .7, -.9, .9)
		bytes.encode_s16(index * 2, int(sample * 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = bytes
	var result := stream.save_to_wav("res://assets/audio/return_sting.wav")
	quit(0 if result == OK else 1)
