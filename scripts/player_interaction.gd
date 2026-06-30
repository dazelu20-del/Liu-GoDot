extends Node

const INTERACT_RANGE := 2.8

var _focused: Node = null
var _prompt: CanvasLayer


func _ready() -> void:
	_prompt = get_tree().get_first_node_in_group("interaction_prompt") as CanvasLayer


func _physics_process(_delta: float) -> void:
	if not _player_can_interact():
		_set_focus(null)
		return
	_set_focus(_find_focus())


func _unhandled_input(event: InputEvent) -> void:
	if not _player_can_interact():
		return
	if _is_backpack_open():
		return
	if event.is_action_pressed("interact") and _focused and _focused.has_method("interact"):
		_focused.interact(get_parent())
		get_viewport().set_input_as_handled()


func _player_can_interact() -> bool:
	var player := get_parent() as CharacterBody3D
	return player != null and player.can_control


func _is_backpack_open() -> bool:
	var ui := get_tree().get_first_node_in_group("backpack_ui")
	return ui != null and ui.has_method("is_open") and ui.is_open()


func _set_focus(target: Node) -> void:
	if target == _focused:
		return
	_focused = target
	if _prompt and _prompt.has_method("set_interactable"):
		_prompt.set_interactable(_focused)


func _find_focus() -> Node:
	var player := get_parent() as Node3D
	var best: Node = null
	var best_dist := INTERACT_RANGE
	for node: Node in get_tree().get_nodes_in_group("interactable"):
		if not node.has_method("is_available") or not node.is_available():
			continue
		var dist := player.global_position.distance_to(node.global_position)
		if dist < best_dist:
			best_dist = dist
			best = node
	return best
