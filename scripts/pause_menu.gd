extends CanvasLayer

signal resume_pressed
signal return_to_menu_pressed


func _on_resume_pressed() -> void:
	resume_pressed.emit()


func _on_return_to_menu_pressed() -> void:
	return_to_menu_pressed.emit()
