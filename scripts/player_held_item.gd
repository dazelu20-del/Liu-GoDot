extends Node3D

## First-person view model for the equipped hotbar item.

signal swing_started()
signal swing_finished()

const HELD_POSITION := Vector3(0.38, -0.24, -0.46)
const HELD_ROTATION_DEG := Vector3(-22.0, -38.0, 6.0)
const HELD_LENGTH := 0.36

const SWING_WINDUP_OFFSET_DEG := Vector3(-28.0, 6.0, -18.0)
const SWING_STRIKE_OFFSET_DEG := Vector3(62.0, -12.0, 22.0)
const SWING_WINDUP_TIME := 0.09
const SWING_STRIKE_TIME := 0.11
const SWING_RECOVER_TIME := 0.2

var _swing_pivot: Node3D
var _held_model: Node3D
var _held_item_id := ""
var _swinging := false
var _swing_elapsed := 0.0
var _swing_duration := SWING_WINDUP_TIME + SWING_STRIKE_TIME + SWING_RECOVER_TIME


func _ready() -> void:
	PlayerInventory.inventory_changed.connect(_refresh_held_item)
	PlayerInventory.slot_selected.connect(_refresh_held_item)
	call_deferred("_refresh_held_item")


func _process(delta: float) -> void:
	_update_visibility()
	_update_swing(delta)


func _input(event: InputEvent) -> void:
	if not _can_swing():
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_start_swing()
		get_viewport().set_input_as_handled()


func _refresh_held_item(_slot_index: int = -1) -> void:
	var item_id := PlayerInventory.get_equipped_item_id()
	if item_id == _held_item_id:
		_update_visibility()
		return

	_clear_held_model()
	_held_item_id = item_id
	if item_id.is_empty():
		return

	var def: Dictionary = PlayerInventory.ITEM_DEFS.get(item_id, {})
	if not def.has("held_scene"):
		return

	_swing_pivot = Node3D.new()
	_swing_pivot.name = "SwingPivot"
	add_child(_swing_pivot)
	_reset_swing_pose()

	_held_model = def.held_scene.instantiate()
	_swing_pivot.add_child(_held_model)
	_fit_held_model(_held_model)
	_update_visibility()


func _start_swing() -> void:
	if _swinging or _swing_pivot == null:
		return

	_swinging = true
	_swing_elapsed = 0.0
	_reset_swing_pose()
	swing_started.emit()


func _update_swing(delta: float) -> void:
	if not _swinging or _swing_pivot == null:
		return

	_swing_elapsed += delta
	if _swing_elapsed >= _swing_duration:
		_reset_swing_pose()
		_on_swing_finished()
		return

	_apply_swing_rotation(_swing_elapsed)


func _apply_swing_rotation(time: float) -> void:
	var idle := HELD_ROTATION_DEG
	var windup := idle + SWING_WINDUP_OFFSET_DEG
	var strike := idle + SWING_STRIKE_OFFSET_DEG

	if time <= SWING_WINDUP_TIME:
		var t := time / SWING_WINDUP_TIME
		_swing_pivot.rotation_degrees = idle.lerp(windup, t)
	elif time <= SWING_WINDUP_TIME + SWING_STRIKE_TIME:
		var t := (time - SWING_WINDUP_TIME) / SWING_STRIKE_TIME
		t = 1.0 - (1.0 - t) * (1.0 - t)
		_swing_pivot.rotation_degrees = windup.lerp(strike, t)
	else:
		var t := (time - SWING_WINDUP_TIME - SWING_STRIKE_TIME) / SWING_RECOVER_TIME
		t = sin(t * PI * 0.5)
		_swing_pivot.rotation_degrees = strike.lerp(idle, t)


func _reset_swing_pose() -> void:
	if _swing_pivot == null:
		return
	_swing_pivot.position = HELD_POSITION
	_swing_pivot.rotation_degrees = HELD_ROTATION_DEG


func _on_swing_finished() -> void:
	_swinging = false
	swing_finished.emit()


func _can_swing() -> bool:
	if _swinging or _held_model == null or _held_item_id.is_empty():
		return false
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return false
	if PlayerInventory.get_equipped_item_id() != _held_item_id:
		return false

	var player := get_tree().get_first_node_in_group("player") as CharacterBody3D
	if player and not player.can_control:
		return false

	return true


func _update_visibility() -> void:
	if _swing_pivot == null:
		return
	var show := (
		Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
		and _held_item_id == PlayerInventory.get_equipped_item_id()
		and not _held_item_id.is_empty()
	)
	_swing_pivot.visible = show


func _fit_held_model(model: Node3D) -> void:
	model.scale = Vector3.ONE
	model.rotation = Vector3.ZERO
	model.position = Vector3.ZERO

	var aabb := _get_mesh_aabb(model)
	var length := maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	if length < 0.001:
		return

	model.scale = Vector3.ONE * (HELD_LENGTH / length)


func _clear_held_model() -> void:
	_swinging = false
	_swing_elapsed = 0.0

	if _swing_pivot:
		_swing_pivot.queue_free()
		_swing_pivot = null
	_held_model = null


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
