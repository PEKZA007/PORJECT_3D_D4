extends SceneTree
func _initialize() -> void:
	var mist := Node3D.new()
	mist.name = "ExitMist"
	var noise := FastNoiseLite.new()
	noise.frequency = .035
	var texture := NoiseTexture2D.new()
	texture.width = 256
	texture.height = 256
	texture.seamless = true
	texture.noise = noise
	for i in 7:
		var veil := MeshInstance3D.new()
		veil.name = "Layer%02d" % i
		veil.mesh = QuadMesh.new()
		veil.mesh.size = Vector2(5.8,6.0)
		veil.position = Vector3(-.15,1.6,-.90 + i*.26)
		veil.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var material := ShaderMaterial.new()
		material.shader = load("res://shaders/exit_mist.gdshader")
		material.set_shader_parameter("density", .75)
		material.set_shader_parameter("cloud_texture", texture)
		material.set_shader_parameter("mist_color", Color(.30,.36,.34,1))
		material.set_shader_parameter("layer_seed",float(i)*7.13)
		veil.material_override = material
		mist.add_child(veil)
		veil.owner = mist
	var packed := PackedScene.new()
	packed.pack(mist)
	assert(ResourceSaver.save(packed,"res://scenes/exit_mist.tscn") == OK)
	mist.free()
	var level = load("res://scenes/school_level.tscn").instantiate()
	for title in ["EntranceMist","ForwardMist"]:
		if level.has_node(title):
			level.get_node(title).free()
		var effect = load("res://scenes/exit_mist.tscn").instantiate()
		effect.name = title
		level.add_child(effect)
		effect.owner = level
		effect.position = level.get_node("BackExit" if title == "EntranceMist" else "ForwardExit").position
		effect.position.y = 0
		# First layers face the approaching player; thickest layers hide the boundary.
		if title == "ForwardMist":
			effect.rotation.y = PI
	for title in ["StairwellClosed","FarEndClosed"]:
		for child in level.get_node("RouteBarriers/"+title).get_children():
			if child is MeshInstance3D:
				child.hide()
	for title in ["GateLeft","GateRight","GateLintel"]:
		if level.has_node("MapExpansion/"+title):
			level.get_node("MapExpansion/"+title).hide()
	packed = PackedScene.new()
	packed.pack(level)
	assert(ResourceSaver.save(packed,"res://scenes/school_level.tscn") == OK)
	print("Entrance and exit mist saved; transition markers and safety collision retained.")
	level.free()
	quit()

