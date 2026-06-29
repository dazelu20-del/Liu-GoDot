extends CanvasLayer

const SLOT_SCENE := preload("res://scenes/inventory_slot_ui.tscn")

@onready var _panel: PanelContainer = $Center/Panel
@onready var _backpack_grid: GridContainer = $Center/Panel/VBox/BackpackSection/BackpackGrid
@onready var _hotbar_row: HBoxContainer = $Center/Panel/VBox/HotbarSection/HotbarRow

var _open := false
var _player: CharacterBody3D
var _hotbar_slots: Array[PanelContainer] = []
var _backpack_slots: Array[PanelContainer] = []


func _ready() -> void:
	add_to_group("backpack_ui")
	hide()
	_build_slots()
	PlayerInventory.inventory_changed.connect(_refresh_all)
	PlayerInventory.backpack_changed.connect(_refresh_all)


func setup(player: CharacterBody3D) -> void:
	_player = player


func is_open() -> bool:
	return _open


func toggle() -> void:
	if _open:
		close()
	elif PlayerInventory.has_backpack:
		open()


func open() -> void:
	if not PlayerInventory.has_backpack or _open:
		return
	_open = true
	show()
	_refresh_all()
	if _player:
		_player.disable_control()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	if not _open:
		return
	_open = false
	hide()
	var main := get_tree().get_first_node_in_group("main_controller")
	if main and main.has_method("on_backpack_closed"):
		main.on_backpack_closed()


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("open_backpack") or event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _build_slots() -> void:
	for i in range(PlayerInventory.BACKPACK_SLOT_COUNT):
		var slot: PanelContainer = SLOT_SCENE.instantiate()
		_backpack_grid.add_child(slot)
		slot.configure("backpack", i)
		_backpack_slots.append(slot)

	for i in range(PlayerInventory.SLOT_COUNT):
		var slot: PanelContainer = SLOT_SCENE.instantiate()
		_hotbar_row.add_child(slot)
		slot.configure("hotbar", i, true)
		_hotbar_slots.append(slot)


func _refresh_all() -> void:
	for slot: PanelContainer in _backpack_slots:
		slot.refresh()
	for slot: PanelContainer in _hotbar_slots:
		slot.refresh()
