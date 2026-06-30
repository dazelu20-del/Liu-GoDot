extends Node3D

@onready var player: CharacterBody3D = $GameWorld/Player
@onready var game_world: Node3D = $GameWorld
@onready var wilderness_scatter: Node3D = $GameWorld/WildernessScatter
@onready var main_menu: CanvasLayer = $MainMenu
@onready var pause_menu: CanvasLayer = $PauseMenu
@onready var intro_cutscene: Node3D = $IntroCutscene
@onready var survival_hud: CanvasLayer = $SurvivalHUD
@onready var inventory_hud: CanvasLayer = $InventoryHUD
@onready var stamina_hud: CanvasLayer = $StaminaHUD
@onready var backpack_ui: CanvasLayer = $BackpackUI

var _game_started := false
var _is_paused := false


func _ready() -> void:
	add_to_group("main_controller")
	main_menu.game_started.connect(_on_game_started)
	pause_menu.resume_pressed.connect(_on_resume_game)
	pause_menu.return_to_menu_pressed.connect(_on_return_to_menu)
	intro_cutscene.intro_finished.connect(_on_intro_finished)
	intro_cutscene.hide()
	game_world.hide()
	SurvivalStats.reset()
	PlayerInventory.reset()
	survival_hud.hide_hud()
	inventory_hud.hide_hud()
	stamina_hud.hide_hud()
	backpack_ui.setup(player)


func _unhandled_input(event: InputEvent) -> void:
	if backpack_ui.is_open():
		return

	if not _game_started:
		return

	if _is_paused:
		if event.is_action_pressed("ui_cancel"):
			_on_resume_game()
			get_viewport().set_input_as_handled()
		return

	if backpack_ui.is_open():
		return

	if event.is_action_pressed("open_backpack") and PlayerInventory.has_backpack:
		backpack_ui.open()
		inventory_hud.set_input_enabled(false)
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_cancel"):
		_pause_game()
		get_viewport().set_input_as_handled()


func should_player_have_control() -> bool:
	return _game_started and not _is_paused and not backpack_ui.is_open()


func on_backpack_closed() -> void:
	if should_player_have_control():
		player.enable_control()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		inventory_hud.set_input_enabled(true)


func _on_game_started() -> void:
	game_world.hide()
	survival_hud.hide_hud()
	inventory_hud.hide_hud()
	stamina_hud.hide_hud()
	backpack_ui.close()
	SurvivalStats.reset()
	PlayerInventory.reset()
	intro_cutscene.start_intro()


func _on_intro_finished() -> void:
	intro_cutscene.hide()
	game_world.show()
	if wilderness_scatter.has_method("scatter"):
		wilderness_scatter.scatter()
	_game_started = true
	player.enable_control()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	SurvivalStats.start()
	survival_hud.show_hud()
	inventory_hud.show_hud()


func _pause_game() -> void:
	_is_paused = true
	player.disable_control()
	pause_menu.show()
	SurvivalStats.stop()
	inventory_hud.set_input_enabled(false)
	stamina_hud.hide_hud()
	backpack_ui.close()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_resume_game() -> void:
	if not _is_paused:
		return

	_is_paused = false
	pause_menu.hide()
	player.enable_control()
	SurvivalStats.resume()
	inventory_hud.set_input_enabled(true)


func _on_return_to_menu() -> void:
	get_tree().reload_current_scene()
