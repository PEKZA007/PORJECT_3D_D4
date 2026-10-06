extends SceneTree
var level: Node3D
func _initialize() -> void:
	call_deferred("run")
func panel(parent: Node3D, title: String, size: Vector3, pos: Vector3, material: Material) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = title
	mesh.mesh = BoxMesh.new()
	mesh.mesh.size = size
	mesh.position = pos
	mesh.material_override = material
	parent.add_child(mesh)
	mesh.owner = level
func run() -> void:
	level = load("res://scenes/school_level.tscn").instantiate()
	var original_script = level.get_script()
	var values := {}
	for property in level.get_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and property.usage & PROPERTY_USAGE_STORAGE:
			values[property.name] = level.get(property.name)
	level.set_script(null)
	root.add_child(level)
	var concrete := StandardMaterial3D.new()
	concrete.albedo_color = Color("505d59")
	concrete.roughness = .97
	var noise := FastNoiseLite.new()
	noise.frequency = .09
	var texture := NoiseTexture2D.new()
	texture.width = 256
	texture.height = 256
	texture.noise = noise
	concrete.albedo_texture = texture
	concrete.uv1_triplanar = true
	concrete.uv1_scale = Vector3(2,2,2)
	var trim := StandardMaterial3D.new()
	trim.albedo_color = Color("273633")
	trim.roughness = .95
	for name in ["StairwellClosed","FarEndClosed","ClassroomSideSouth","ClassroomSideNorth"]:
		var body: StaticBody3D = level.get_node("RouteBarriers/"+name)
		for child in body.get_children():
			if child is MeshInstance3D:
				child.free()
		var shape: BoxShape3D = body.get_child(0).shape
		panel(body,"ConcreteWall",shape.size,Vector3.ZERO,concrete)
		panel(body,"Skirting",Vector3(shape.size.x+.015,.20,shape.size.z+.015),Vector3(0,-1.4,0),trim)
		if name in ["StairwellClosed","FarEndClosed"]:
			for height in [-.75,0,.75]:
				panel(body,"Joint",Vector3(shape.size.x,.018,shape.size.z+.008),Vector3(0,height,0),trim)
	# Windows keep the outside-watcher sight line: a low wall plus visible glass.
	var windows: Node3D = level.get_node("RouteBarriers/WindowBoundary")
	for child in windows.get_children():
		if child is MeshInstance3D:
			child.free()
	panel(windows,"WindowSillWall",Vector3(.12,.7,58.8),Vector3(0,-1.15,0),concrete)
	var glass := StandardMaterial3D.new()
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color = Color(.13,.23,.24,.08)
	glass.roughness = .25
	panel(windows,"ClosedGlass",Vector3(.06,2.3,58.8),Vector3(0,.35,0),glass)
	level.get_node("Props/ForwardExitDarkness").hide()
	level.get_node("Props/BackExitDarkness").hide()
	var environment: Environment = level.get_node("WorldEnvironment").environment
	environment.background_color = Color("030809")
	environment.ambient_light_color = Color("687c80")
	environment.ambient_light_energy = .055
	environment.fog_enabled = true
	environment.fog_light_color = Color("0a1519")
	environment.fog_light_energy = .25
	environment.fog_density = .016
	var index := 0
	for light in level.get_node("Lights").get_children():
		if light is OmniLight3D:
			light.light_color = Color("8caaa1") if index % 3 else Color("afb08d")
			light.light_energy = .55 if index % 3 else .28
			light.omni_range = minf(light.omni_range,4.8)
			light.omni_attenuation = 1.8
			light.shadow_enabled = light.position.y < 3 and light.position.z > -12
			index += 1
	level.set_script(original_script)
	for key in values:
		level.set(key,values[key])
	var packed := PackedScene.new()
	packed.pack(level)
	ResourceSaver.save(packed,"res://scenes/school_level.tscn")
	print("Visible walls and horror lighting saved")
	quit()
