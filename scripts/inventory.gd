extends Node

## Hotbar + optional 6x5 backpack storage.

signal slot_selected(index: int)
signal inventory_changed()
signal backpack_changed()
signal backpack_unlocked()

const SLOT_COUNT := 5
const BACKPACK_COLUMNS := 6
const BACKPACK_ROWS := 5
const BACKPACK_SLOT_COUNT := BACKPACK_COLUMNS * BACKPACK_ROWS

const ITEM_DEFS := {
	"emergency_axe": {
		"id": "emergency_axe",
		"name": "Axe",
		"held_scene": preload("res://assets/Starter axe/tactical_axe.glb"),
	},
}

var slots: Array = []
var backpack_slots: Array = []
var selected_slot := 0
var has_backpack := false


func reset() -> void:
	slots.clear()
	slots.resize(SLOT_COUNT)
	for i in range(SLOT_COUNT):
		slots[i] = null
	backpack_slots.clear()
	has_backpack = false
	selected_slot = 0
	inventory_changed.emit()
	backpack_changed.emit()
	slot_selected.emit(selected_slot)


func unlock_backpack() -> void:
	if has_backpack:
		return
	has_backpack = true
	backpack_slots.resize(BACKPACK_SLOT_COUNT)
	for i in range(BACKPACK_SLOT_COUNT):
		backpack_slots[i] = null
	backpack_unlocked.emit()
	backpack_changed.emit()


func try_add_to_backpack(item_id: String) -> bool:
	if not has_backpack:
		return false
	var item := make_item(item_id)
	for i in range(BACKPACK_SLOT_COUNT):
		if backpack_slots[i] == null:
			backpack_slots[i] = item
			backpack_changed.emit()
			inventory_changed.emit()
			return true
	return false


func unlock_backpack_with_starter_loot() -> void:
	unlock_backpack()
	try_add_to_backpack("emergency_axe")


func make_item(item_id: String) -> Dictionary:
	var def: Dictionary = ITEM_DEFS[item_id]
	return {
		"id": def.id,
		"name": def.name,
	}


func try_add_to_hotbar(item_id: String) -> bool:
	var item := make_item(item_id)
	for i in range(SLOT_COUNT):
		if slots[i] == null:
			slots[i] = item
			inventory_changed.emit()
			return true
	return false


func get_equipped_item_id() -> String:
	var item = get_slot("hotbar", selected_slot)
	if item is Dictionary:
		return str(item.get("id", ""))
	return ""


func get_slot(kind: String, index: int) -> Variant:
	var arr := _slots_for_kind(kind)
	if index < 0 or index >= arr.size():
		return null
	return arr[index]


func swap_slots(from_kind: String, from_index: int, to_kind: String, to_index: int) -> void:
	var from_arr := _slots_for_kind(from_kind)
	var to_arr := _slots_for_kind(to_kind)
	if from_index < 0 or from_index >= from_arr.size():
		return
	if to_index < 0 or to_index >= to_arr.size():
		return

	var temp = from_arr[from_index]
	from_arr[from_index] = to_arr[to_index]
	to_arr[to_index] = temp
	inventory_changed.emit()
	if from_kind == "backpack" or to_kind == "backpack":
		backpack_changed.emit()


func select_slot(index: int) -> void:
	var next := clampi(index, 0, SLOT_COUNT - 1)
	if next == selected_slot:
		return
	selected_slot = next
	slot_selected.emit(selected_slot)


func select_next() -> void:
	select_slot((selected_slot + 1) % SLOT_COUNT)


func select_previous() -> void:
	select_slot((selected_slot - 1 + SLOT_COUNT) % SLOT_COUNT)


func _slots_for_kind(kind: String) -> Array:
	if kind == "backpack":
		return backpack_slots
	return slots
