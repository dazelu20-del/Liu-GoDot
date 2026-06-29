extends CanvasLayer

const FADE_DELAY := 2.0
const FADE_DURATION := 0.35
const SLOT_SIZE := Vector2(72, 72)

@onready var _panel: PanelContainer = $BottomMargin/CenterContainer/Panel
@onready var _slots_row: HBoxContainer = $BottomMargin/CenterContainer/Panel/SlotsRow

var _slot_panels: Array[PanelContainer] = []
var _active := false
var _input_enabled := false
var _fade_timer := 0.0
var _fade_tween: Tween


func _ready() -> void:
	hide()
	_panel.modulate.a = 0.0
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_slots()
	PlayerInventory.slot_selected.connect(_on_slot_selected)
	PlayerInventory.inventory_changed.connect(_on_inventory_changed)


func show_hud() -> void:
	show()
	_active = true
	_input_enabled = true
	_fade_timer = 0.0
	_panel.modulate.a = 1.0
	_refresh_slots()


func hide_hud() -> void:
	_active = false
	_input_enabled = false
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	hide()
	_panel.modulate.a = 0.0


func set_input_enabled(enabled: bool) -> void:
	_input_enabled = enabled


func _process(delta: float) -> void:
	if not _active or not _input_enabled:
		return

	_fade_timer += delta
	if _fade_timer >= FADE_DELAY and _panel.modulate.a > 0.01:
		_fade_to(0.0)


func _unhandled_input(event: InputEvent) -> void:
	if not _active or not _input_enabled:
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_on_scroll(-1)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_on_scroll(1)
			get_viewport().set_input_as_handled()


func _on_scroll(direction: int) -> void:
	_fade_timer = 0.0
	_fade_to(1.0)
	if direction > 0:
		PlayerInventory.select_next()
	else:
		PlayerInventory.select_previous()
	_refresh_slots()


func _fade_to(target_alpha: float) -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_panel, "modulate:a", target_alpha, FADE_DURATION)


func _build_slots() -> void:
	var slot_bg := _make_slot_style(Color(0.1, 0.1, 0.12, 0.95), Color(0.3, 0.3, 0.35, 1.0))
	var slot_selected_bg := _make_slot_style(Color(0.14, 0.13, 0.1, 0.98), Color(0.82, 0.68, 0.28, 1.0), 2)

	for i: int in PlayerInventory.SLOT_COUNT:
		var slot := PanelContainer.new()
		slot.name = "Slot%d" % i
		slot.custom_minimum_size = SLOT_SIZE
		slot.add_theme_stylebox_override("panel", slot_bg.duplicate())

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 6)
		margin.add_theme_constant_override("margin_top", 6)
		margin.add_theme_constant_override("margin_right", 6)
		margin.add_theme_constant_override("margin_bottom", 6)
		slot.add_child(margin)

		var vbox := VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		margin.add_child(vbox)

		var number := Label.new()
		number.name = "Number"
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		number.add_theme_color_override("font_color", Color(0.55, 0.53, 0.5, 1))
		number.add_theme_font_size_override("font_size", 12)
		number.text = str(i + 1)
		vbox.add_child(number)

		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.custom_minimum_size = Vector2(40, 40)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		vbox.add_child(icon)

		var item_name := Label.new()
		item_name.name = "ItemName"
		item_name.visible = false
		item_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		item_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		item_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		item_name.add_theme_color_override("font_color", Color(0.92, 0.9, 0.86, 1))
		item_name.add_theme_font_size_override("font_size", 12)
		vbox.add_child(item_name)

		slot.set_meta("selected_style", slot_selected_bg.duplicate())
		slot.set_meta("normal_style", slot_bg.duplicate())
		_slots_row.add_child(slot)
		_slot_panels.append(slot)


func _make_slot_style(bg: Color, border: Color, border_width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(4)
	style.content_margin_left = 4
	style.content_margin_top = 4
	style.content_margin_right = 4
	style.content_margin_bottom = 4
	return style


func _on_slot_selected(_index: int) -> void:
	_refresh_slots()


func _on_inventory_changed() -> void:
	_refresh_slots()


func _refresh_slots() -> void:
	for i: int in _slot_panels.size():
		var slot: PanelContainer = _slot_panels[i]
		var is_selected: bool = i == PlayerInventory.selected_slot
		var style: StyleBoxFlat = slot.get_meta("selected_style") if is_selected else slot.get_meta("normal_style")
		slot.add_theme_stylebox_override("panel", style)

		var margin: MarginContainer = slot.get_child(0) as MarginContainer
		var vbox: VBoxContainer = margin.get_child(0) as VBoxContainer
		var icon: TextureRect = vbox.get_node("Icon") as TextureRect
		var item_name: Label = vbox.get_node("ItemName") as Label
		var item = PlayerInventory.slots[i] if i < PlayerInventory.slots.size() else null
		if item is Dictionary and item.get("icon") is Texture2D:
			icon.texture = item.icon
			icon.show()
			item_name.hide()
		elif item is Dictionary and not str(item.get("name", "")).is_empty():
			icon.texture = null
			icon.hide()
			item_name.text = str(item.name)
			item_name.show()
		else:
			icon.texture = null
			icon.show()
			item_name.hide()
