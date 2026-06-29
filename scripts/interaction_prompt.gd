extends CanvasLayer

@onready var _label: Label = $CenterContainer/Label

var _target: Node = null


func _ready() -> void:
	add_to_group("interaction_prompt")
	hide()


func set_interactable(target: Node) -> void:
	if target == _target:
		return
	_target = target
	if _target:
		_label.text = _target.get_prompt() if _target.has_method("get_prompt") else "Press E to interact"
		show()
	else:
		hide()
