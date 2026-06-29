extends Node3D

@onready var _model: Node3D = $Model


func _ready() -> void:
	add_to_group("interactable")
	await get_tree().process_frame
	_snap_to_ground()
	_orient_on_ground()


func is_available() -> bool:
	return true


func get_prompt() -> String:
	return "Press E to interact"


func interact(_player: Node) -> void:
	if not PlayerInventory.try_add_to_hotbar("emergency_axe"):
		_show_notification("Inventory full!")
		return
	queue_free()


func _snap_to_ground() -> void:
	var aabb := _get_local_mesh_aabb(_model)
	if aabb.size == Vector3.ZERO:
		return
	_model.position.y -= aabb.position.y


func _orient_on_ground() -> void:
	_model.rotation_degrees = Vector3(0, randf_range(0.0, 360.0), 90.0)


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


func _show_notification(text: String, duration: float = 4.0) -> void:
	var hud := get_tree().get_first_node_in_group("notification_hud")
	if hud and hud.has_method("show_message"):
		hud.show_message(text, duration)
