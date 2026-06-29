extends Node3D

## Imported DC-3 wreckage placed at the crash site beside the player spawn.

@export var target_length := 42.0
@export var ground_height := 0.25
@export var ground_clearance := 0.55

@onready var model: Node3D = $Model


func _ready() -> void:
	await get_tree().process_frame
	_normalize_scale()
	_snap_to_ground()
	position.y = ground_height + ground_clearance
	_build_collision()


func _build_collision() -> void:
	var body := StaticBody3D.new()
	body.name = "CollisionBody"
	add_child(body)

	for mesh_inst: MeshInstance3D in _find_mesh_instances(model):
		var mesh: Mesh = mesh_inst.mesh
		if mesh == null:
			continue
		var shape: Shape3D = mesh.create_trimesh_shape()
		if shape == null:
			continue
		var col := CollisionShape3D.new()
		col.shape = shape
		col.transform = body.global_transform.affine_inverse() * mesh_inst.global_transform
		body.add_child(col)


func _normalize_scale() -> void:
	var aabb := _get_local_mesh_aabb(model)
	var length := maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	if length < 0.01:
		return
	var factor := target_length / length
	model.scale = Vector3.ONE * factor


func _snap_to_ground() -> void:
	var aabb := _get_local_mesh_aabb(model)
	if aabb.size == Vector3.ZERO:
		return
	model.position.y -= aabb.position.y


func _get_local_mesh_aabb(root: Node3D) -> AABB:
	var merged := AABB()
	var first := true
	for mesh_inst: MeshInstance3D in _find_mesh_instances(root):
		var mesh_aabb: AABB = (
			root.global_transform.affine_inverse()
			* mesh_inst.global_transform
			* mesh_inst.get_aabb()
		)
		if first:
			merged = mesh_aabb
			first = false
		else:
			merged = merged.merge(mesh_aabb)
	return merged


func _find_mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		result.append(node)
	for child: Node in node.get_children():
		result.append_array(_find_mesh_instances(child))
	return result
