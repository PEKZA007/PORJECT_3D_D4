extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var level = load("res://scenes/school_level.tscn").instantiate()
	var script = level.get_script()
	var values := {}
	for property in level.get_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and property.usage & PROPERTY_USAGE_STORAGE:
			values[property.name] = level.get(property.name)
	level.set_script(null)
	root.add_child(level)
	var lights: Node3D = level.get_node("Lights")
	for light in lights.get_children():
		light.free()
	var count := 0
	for mesh in level.get_node("SchoolModel").find_children("*","MeshInstance3D",true,false):
		var is_tube := false
		for surface in mesh.mesh.get_surface_count():
			var material = mesh.mesh.surface_get_material(surface)
			if material and "Emissive" in material.resource_name:
				is_tube = true
		if not is_tube:
			continue
		var center: Vector3 = mesh.global_transform * mesh.get_aabb().get_center()
		var light := OmniLight3D.new()
		light.name = "Tube_" + mesh.name
		lights.add_child(light)
		light.owner = level
		light.global_position = center + Vector3(0,-.045,0)
		light.light_color = Color("a8b6a1")
		light.light_energy = .58
		light.omni_range = 5.3
		light.omni_attenuation = 1.6
		light.shadow_enabled = true
		light.shadow_bias = .025
		light.set_meta("source_fixture",str(level.get_path_to(mesh)))
		assert(absf(light.global_position.x-center.x)<.001 and absf(light.global_position.z-center.z)<.001)
		count += 1
	# The added classroom gets a visible luminaire for its own light.
	if level.has_node("ClassroomLuminaire"):
		level.get_node("ClassroomLuminaire").free()
	var fixture := MeshInstance3D.new()
	fixture.name = "ClassroomLuminaire"
	fixture.mesh = BoxMesh.new()
	fixture.mesh.size = Vector3(.8,.045,.16)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("ccd2b7")
	material.emission_enabled = true
	material.emission = Color("a8b6a1")
	fixture.material_override = material
	level.add_child(fixture)
	fixture.owner = level
	fixture.position = Vector3(2.8,2.85,9.26)
	var classroom := OmniLight3D.new()
	classroom.name = "ClassroomLight"
	lights.add_child(classroom)
	classroom.owner = level
	classroom.position = fixture.position + Vector3(0,-.055,0)
	classroom.light_color = Color("a8b6a1")
	classroom.light_energy = .5
	classroom.omni_range = 4.0
	classroom.shadow_enabled = true
	classroom.set_meta("source_fixture","ClassroomLuminaire")
	level.set_script(script)
	for key in values:
		level.set(key,values[key])
	level.tube_emission_per_power = .65
	var packed := PackedScene.new()
	assert(packed.pack(level) == OK)
	assert(ResourceSaver.save(packed,"res://scenes/school_level.tscn") == OK)
	print("Aligned ",count," hallway lights with source tubes; added matching classroom fixture.")
	quit()
