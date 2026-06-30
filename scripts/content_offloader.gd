extends Node

## Frees heavy mesh nodes while keeping a stable world anchor so reloaded
## content appears in the exact same place. Supports view-aware offloading so
## props stay loaded when in front of the camera or on screen.

signal content_offloaded
signal content_restored

@export var content_root: NodePath
@export var reload_scene: PackedScene
@export var replace_entire_root := true
@export var offload_process_mode := true
@export var auto_offload_distance := 0.0
@export var auto_restore_distance := 0.0
@export var view_aware_offload := true
@export var behind_dot_threshold := -0.12
@export var keep_visible_margin := 140.0
@export var player_group := &"player"
@export var camera_group := &"player_camera"

var is_offloaded := false

var _host: Node3D
var _root: Node3D
var _anchor: Node3D
var _saved_local_transform: Transform3D
var _restored_node_name := "Content"
var _player: Node3D
var _camera: Camera3D


func _ready() -> void:
	_host = get_parent() as Node3D
	if _host == null:
		push_warning("ContentOffloader must be a child of a Node3D.")
		return

	if content_root.is_empty():
		push_warning("ContentOffloader needs content_root set on %s." % _host.name)
		return

	_root = _host.get_node_or_null(content_root) as Node3D
	if _root == null:
		push_warning("ContentOffloader could not resolve content_root on %s." % _host.name)
		return

	_anchor = Node3D.new()
	_anchor.name = "OffloadAnchor"
	_host.add_child(_anchor)
	_sync_anchor()


func _process(_delta: float) -> void:
	if auto_offload_distance <= 0.0:
		return

	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(player_group) as Node3D
		if _player == null:
			return

	if _camera == null or not is_instance_valid(_camera):
		_camera = _find_active_camera()

	var distance := _anchor.global_position.distance_to(_player.global_position)
	var behind_player := _is_behind_player()
	var on_screen := _is_on_screen()

	if not is_offloaded:
		if distance > auto_offload_distance and (not view_aware_offload or (behind_player and not on_screen)):
			offload()
	elif auto_restore_distance > 0.0:
		if distance < auto_restore_distance or on_screen or not behind_player:
			restore()


func offload() -> void:
	if is_offloaded:
		return
	if _root == null and not replace_entire_root:
		_root = _host.get_node_or_null(content_root) as Node3D
	if _root == null and replace_entire_root:
		return

	_sync_anchor()
	if _root != null:
		_saved_local_transform = _root.transform
		_restored_node_name = _root.name

	if replace_entire_root:
		_root.queue_free()
		_root = null
	else:
		for child: Node in _root.get_children():
			child.queue_free()
		if offload_process_mode:
			_root.process_mode = Node.PROCESS_MODE_DISABLED
		_root.visible = false

	is_offloaded = true
	content_offloaded.emit()


func restore() -> void:
	if not is_offloaded:
		return

	if reload_scene:
		var instance := reload_scene.instantiate() as Node3D
		if instance == null:
			push_warning("ContentOffloader reload_scene must instantiate a Node3D.")
			return

		_host.add_child(instance)
		instance.name = _restored_node_name
		instance.transform = _saved_local_transform
		_root = instance

		if not replace_entire_root:
			if offload_process_mode:
				_root.process_mode = Node.PROCESS_MODE_INHERIT
			_root.visible = true
	else:
		_root = _host.get_node_or_null(content_root) as Node3D
		if _root != null:
			if offload_process_mode:
				_root.process_mode = Node.PROCESS_MODE_INHERIT
			_root.visible = true

	is_offloaded = false
	content_restored.emit()


func get_content_root() -> Node3D:
	if _root != null and is_instance_valid(_root):
		return _root
	return _host.get_node_or_null(content_root) as Node3D


func _is_behind_player() -> bool:
	if _camera == null:
		return _is_behind_using_player_facing()
	return _flat_forward_dot() < behind_dot_threshold


func _is_behind_using_player_facing() -> bool:
	var to_prop := _flat_direction_to_prop()
	if to_prop == Vector3.ZERO:
		return false
	var forward := Vector3(
		_player.global_transform.basis.z.x,
		0.0,
		_player.global_transform.basis.z.z
	).normalized()
	return to_prop.dot(forward) < behind_dot_threshold


func _flat_forward_dot() -> float:
	var to_prop := _flat_direction_to_prop()
	if to_prop == Vector3.ZERO:
		return 1.0
	var forward := Vector3(-_camera.global_transform.basis.z.x, 0.0, -_camera.global_transform.basis.z.z)
	if forward.length_squared() < 0.0001:
		return 1.0
	return to_prop.dot(forward.normalized())


func _flat_direction_to_prop() -> Vector3:
	var offset := _anchor.global_position - _player.global_position
	offset.y = 0.0
	if offset.length_squared() < 0.0001:
		return Vector3.ZERO
	return offset.normalized()


func _is_on_screen() -> bool:
	if _camera == null:
		return false

	var viewport := get_viewport()
	if viewport == null:
		return false

	var screen_pos := _camera.unproject_position(_anchor.global_position)
	var visible_rect := viewport.get_visible_rect().grow(keep_visible_margin)
	if not visible_rect.has_point(screen_pos):
		return false

	var to_prop := (_anchor.global_position - _camera.global_position).normalized()
	return to_prop.dot(-_camera.global_transform.basis.z) > 0.02


func _find_active_camera() -> Camera3D:
	var grouped := get_tree().get_first_node_in_group(camera_group)
	if grouped is Camera3D:
		return grouped as Camera3D

	var player := get_tree().get_first_node_in_group(player_group)
	if player:
		var found := player.find_child("Camera3D", true, false) as Camera3D
		if found:
			return found

	return get_viewport().get_camera_3d()


func _sync_anchor() -> void:
	if _anchor == null:
		return
	if _root != null and is_instance_valid(_root):
		_anchor.global_transform = _root.global_transform
	else:
		_anchor.transform = _saved_local_transform
