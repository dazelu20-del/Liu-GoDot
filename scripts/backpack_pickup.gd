extends Node3D

const AXE_TARGET_LENGTH := 0.16

@onready var _model: Node3D = $Model
@onready var _axe: Node3D = $AxeModel


func _ready() -> void:
	add_to_group("interactable")
	_model.rotation_degrees = Vector3(0, randf_range(-30.0, 30.0), 0)
	call_deferred("_layout_axe")


func is_available() -> bool:
	return not PlayerInventory.has_backpack


func get_prompt() -> String:
	return "Press E to interact"


func interact(_player: Node) -> void:
	if PlayerInventory.has_backpack:
		return
	PlayerInventory.unlock_backpack_with_starter_loot()
	_show_notification("Press B to access backpack", 5.0)
	queue_free()


func _layout_axe() -> void:
	_axe.scale = Vector3.ONE
	_axe.rotation = Vector3.ZERO
	_axe.position = Vector3.ZERO

	var aabb := _get_mesh_aabb(_axe)
	var length := maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	if length < 0.001:
		return

	var uniform_scale := AXE_TARGET_LENGTH / length
	_axe.scale = Vector3.ONE * uniform_scale
	_axe.rotation_degrees = Vector3(10, 40, 82)
	_axe.position = Vector3(0.34, 0.06, 0.02)


func _get_mesh_aabb(root: Node3D) -> AABB:
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
