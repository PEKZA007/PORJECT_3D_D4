extends SceneTree
var level: Node3D
var barriers: Node3D
func _initialize() -> void:
	call_deferred("run")
func block(title: String, pos: Vector3, size: Vector3, visible_panel: bool) -> void:
	var body := StaticBody3D.new()
	body.name = title
	barriers.add_child(body)
	body.owner = level
	body.position = pos
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = size
	body.add_child(shape)
	shape.owner = level
	if visible_panel:
		var mesh := MeshInstance3D.new()
		mesh.mesh = BoxMesh.new()
		mesh.mesh.size = size
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("313e3c")
		material.roughness = .9
		mesh.material_override = material
		body.add_child(mesh)
		mesh.owner = level
func run() -> void:
	level = load("res://scenes/school_level.tscn").instantiate()
	var original_script = level.get_script()
	level.set_script(null)
	root.add_child(level)
	if level.has_node("RouteBarriers"):
		level.get_node("RouteBarriers").free()
	barriers = Node3D.new()
	barriers.name = "RouteBarriers"
	level.add_child(barriers)
	barriers.owner = level
	block("StairwellClosed",Vector3(-.5,1.5,-12.65),Vector3(4,3,.25),true)
	block("FarEndClosed",Vector3(-.2,1.5,46.15),Vector3(3.2,3,.25),true)
	block("WindowBoundary",Vector3(-1.53,1.5,16.7),Vector3(.12,3,58.8),false)
	# Keep the anomaly classroom doorway open; all other side doors are scenery.
	block("ClassroomSideSouth",Vector3(1.21,1.5,-2.1),Vector3(.12,3,21),false)
	block("ClassroomSideNorth",Vector3(1.21,1.5,28.2),Vector3(.12,3,36.2),false)
	level.set_script(original_script)
	level.walker_patrol_z = Vector2(14, 33)
	level.footsteps_trigger_z = 28.0
	level.attacker_trigger_z = 7.0
	level.door_trigger_z = 14.0
	var packed := PackedScene.new()
	packed.pack(level)
	ResourceSaver.save(packed,"res://scenes/school_level.tscn")
	print("Route barriers saved")
	quit()

