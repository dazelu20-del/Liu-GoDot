extends CanvasLayer

signal game_started


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_start_pressed() -> void:
	hide()
	game_started.emit()


func _on_quit_pressed() -> void:
	get_tree().quit()
