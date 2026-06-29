extends PanelContainer

const SLOT_SIZE := Vector2(64, 64)

var slot_kind := "hotbar"
var slot_index := 0

@onready var _icon: TextureRect = $Margin/Icon
@onready var _name_label: Label = $Margin/ItemName
@onready var _number: Label = $Margin/Number


func _ready() -> void:
	custom_minimum_size = SLOT_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	refresh()


func configure(kind: String, index: int, show_number: bool = false) -> void:
	slot_kind = kind
	slot_index = index
	if has_node("Margin/Number"):
		$Margin/Number.visible = show_number
		if show_number:
			$Margin/Number.text = str(index + 1)
	if has_node("Margin/Icon"):
		refresh()


func refresh() -> void:
	var item = PlayerInventory.get_slot(slot_kind, slot_index)
	if item is Dictionary and item.get("icon") is Texture2D:
		_icon.texture = item.icon
		_icon.show()
		_name_label.hide()
	elif item is Dictionary and not str(item.get("name", "")).is_empty():
		_icon.texture = null
		_icon.hide()
		_name_label.text = str(item.name)
		_name_label.show()
	else:
		_icon.texture = null
		_icon.show()
		_name_label.hide()


func _get_drag_data(_at_position: Vector2) -> Variant:
	var item = PlayerInventory.get_slot(slot_kind, slot_index)
	if item == null:
		return null

	if item.get("icon") is Texture2D:
		var preview := TextureRect.new()
		preview.texture = item.icon
		preview.custom_minimum_size = Vector2(48, 48)
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		set_drag_preview(preview)
	else:
		var preview := Label.new()
		preview.text = str(item.get("name", ""))
		preview.add_theme_font_size_override("font_size", 14)
		set_drag_preview(preview)

	return {"kind": slot_kind, "index": slot_index}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("kind") and data.has("index")


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	PlayerInventory.swap_slots(data.kind, data.index, slot_kind, slot_index)
