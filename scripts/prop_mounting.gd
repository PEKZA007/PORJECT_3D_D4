extends RefCounted
## Corridor wall faces measured against SchoolArchitectureCollision.
const RIGHT_WALL := 1.07599
const LEFT_WALL := -1.42404
const CLEARANCE := .005

static func mesh_bounds(node: Node3D) -> AABB:
	var boxes: Array[AABB] = []
	collect_bounds(node, Transform3D.IDENTITY, boxes)
	assert(not boxes.is_empty(), "No mesh for wall mounting: " + str(node.name))
	var result: AABB = boxes[0]
	for i in range(1, boxes.size()):
		result = result.merge(boxes[i])
	return result

static func collect_bounds(node: Node, parent_transform: Transform3D, boxes: Array[AABB]) -> void:
	var pose := parent_transform
	if node is Node3D:
		pose = parent_transform * node.transform
	if node is MeshInstance3D and node.mesh:
		boxes.append(pose * node.get_aabb())
	for child in node.get_children():
		collect_bounds(child, pose, boxes)

static func mount_right(node: Node3D, wall: float = RIGHT_WALL) -> void:
	if node.has_node("ArtRoot"):
		# Keep the interaction anchor centered on its artwork, in front of the wall.
		node.get_node("ArtRoot").position.x = 0
	node.position.x += wall - CLEARANCE - mesh_bounds(node).end.x

static func mount_level(level: Node3D) -> void:
	var props := level.get_node("Props")
	for key in ["Bell", "Speaker", "Extinguisher", "Mirror", "Sink"]:
		mount_right(props.get_node(key))
	for group in ["Posters", "ExtraPosters"]:
		for poster in props.get_node(group).get_children():
			mount_right(poster)
	# Overlays sit in front of the mounted paper, not inside it.
	for key in ["PosterGhost", "PosterSymbol"]:
		mount_right(props.get_node(key), RIGHT_WALL - .025)
	var bin: Node3D = props.get_node("Bin")
	var shift := LEFT_WALL + .015 - mesh_bounds(bin).position.x
	bin.position.x += shift
	props.get_node("Hand").position.x += shift
