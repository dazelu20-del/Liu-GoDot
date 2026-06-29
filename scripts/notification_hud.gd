extends CanvasLayer

const FADE_DURATION := 0.3

@onready var _label: Label = $CenterContainer/Panel/Label

var _tween: Tween


func _ready() -> void:
	add_to_group("notification_hud")
	hide()
	$CenterContainer/Panel.modulate.a = 0.0


func show_message(text: String, duration: float = 4.0) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_label.text = text
	show()
	$CenterContainer/Panel.modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property($CenterContainer/Panel, "modulate:a", 1.0, FADE_DURATION)
	_tween.tween_interval(duration)
	_tween.tween_property($CenterContainer/Panel, "modulate:a", 0.0, FADE_DURATION)
	_tween.finished.connect(_on_finished, CONNECT_ONE_SHOT)


func _on_finished() -> void:
	hide()
