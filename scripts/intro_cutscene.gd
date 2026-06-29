extends Node3D

signal intro_finished

const MOUSE_SENSITIVITY := 0.002
const MAX_YAW := 1.05
const MAX_PITCH := 0.62
const LOOK_WAIT := 10.0
const FADE_DURATION := 2.5
const EPILOGUE_LINE_DURATION := 2.8
## Seated forward in cabin is -Z; PI yaw faces into the cabin (away from the seat back ahead).
const BASE_YAW := PI
const EYE_FORWARD := -0.14

const DIALOGUES: Array[String] = [
	"Ladies and gentlemen, this is your captain speaking.",
	"We have lost engine power. The aircraft is going down.",
	"Brace for impact!",
]

const EPILOGUE_LINES: Array[String] = [
	"You are the only survivor.",
	"Due to the lack of abundant survivors, the scavenger team will come in a week.",
	"Gather materials and survive.",
	"Maybe you can even sue the airline for making you fight for your life after the initial crash.",
]

@onready var cabin: Node3D = $AirplaneCabin
@onready var seat_pivot: Node3D = $SeatPivot
@onready var head: Node3D = $SeatPivot/Head
@onready var shake_pivot: Node3D = $SeatPivot/Head/ShakePivot
@onready var camera: Camera3D = $SeatPivot/Head/ShakePivot/IntroCamera
@onready var dialogue_ui: CanvasLayer = $DialogueUI
@onready var dialogue_panel: PanelContainer = $DialogueUI/DialoguePanel
@onready var dialogue_label: Label = $DialogueUI/DialoguePanel/MarginContainer/DialogueLabel
@onready var epilogue_label: Label = $DialogueUI/EpilogueLabel
@onready var fade_rect: ColorRect = $DialogueUI/FadeRect
@onready var skip_hint: PanelContainer = $DialogueUI/SkipHint

var _sun: DirectionalLight3D
var _sun_shadows_enabled := true

var _playing := false
var _yaw := BASE_YAW - 0.25
var _pitch := -0.03
var _shake_strength := 0.0
var _shaking := false


func _ready() -> void:
	_sun = get_parent().get_node_or_null("Sun") as DirectionalLight3D


func start_intro() -> void:
	_playing = true
	_yaw = BASE_YAW - 0.25
	_pitch = -0.03
	_shake_strength = 0.0
	_shaking = false
	if _sun:
		_sun_shadows_enabled = _sun.shadow_enabled
		_sun.shadow_enabled = false
	seat_pivot.position = cabin.get_player_seat_position()
	head.position = cabin.get_player_eye_offset()
	show()
	dialogue_ui.show()
	camera.current = true
	_clear_dialogue()
	fade_rect.color = Color(0, 0, 0, 1)
	epilogue_label.visible = false
	epilogue_label.modulate.a = 0.0
	fade_rect.modulate = Color(1, 1, 1, 0)
	head.rotation = Vector3(_pitch, _yaw, 0.0)
	shake_pivot.position = Vector3.ZERO
	shake_pivot.rotation = Vector3.ZERO
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	skip_hint.show()
	_run_intro()


func _input(event: InputEvent) -> void:
	if not _playing:
		return

	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_G:
		_skip_intro()
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * MOUSE_SENSITIVITY
		_pitch -= event.relative.y * MOUSE_SENSITIVITY
		_yaw = clampf(_yaw, BASE_YAW - MAX_YAW, BASE_YAW + MAX_YAW)
		_pitch = clampf(_pitch, -MAX_PITCH, MAX_PITCH)
		head.rotation = Vector3(_pitch, _yaw, 0.0)


func _process(_delta: float) -> void:
	if not _shaking:
		if _playing and shake_pivot.position != Vector3.ZERO:
			shake_pivot.position = Vector3.ZERO
		return

	shake_pivot.position = Vector3(
		randf_range(-1.0, 1.0) * _shake_strength,
		randf_range(-1.0, 1.0) * _shake_strength,
		randf_range(-1.0, 1.0) * _shake_strength * 0.35
	)


func _run_intro() -> void:
	await get_tree().create_timer(LOOK_WAIT).timeout
	if not _playing:
		return

	await _play_announcement()
	if not _playing:
		return

	_start_violent_shake()
	await _fade_to_black()
	if not _playing:
		return

	_stop_shake()
	await _play_epilogue()
	if _playing:
		_finish_intro()


func _play_announcement() -> void:
	dialogue_panel.visible = true
	var fade_in := create_tween()
	fade_in.tween_property(dialogue_panel, "modulate:a", 1.0, 0.5)

	for line: String in DIALOGUES:
		if not _playing:
			return
		dialogue_label.text = line
		await get_tree().create_timer(1.8).timeout


func _start_violent_shake() -> void:
	_shake_strength = 0.26
	_shaking = true


func _stop_shake() -> void:
	_shaking = false
	shake_pivot.position = Vector3.ZERO


func _fade_to_black() -> void:
	_clear_dialogue()
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, FADE_DURATION)
	await tween.finished


func _play_epilogue() -> void:
	epilogue_label.visible = true
	epilogue_label.modulate.a = 0.0

	for line: String in EPILOGUE_LINES:
		if not _playing:
			return
		epilogue_label.text = line
		var fade_in := create_tween()
		fade_in.tween_property(epilogue_label, "modulate:a", 1.0, 0.7)
		await fade_in.finished
		await get_tree().create_timer(EPILOGUE_LINE_DURATION).timeout
		if not _playing:
			return
		var fade_out := create_tween()
		fade_out.tween_property(epilogue_label, "modulate:a", 0.0, 0.5)
		await fade_out.finished

	epilogue_label.visible = false
	epilogue_label.text = ""


func _skip_intro() -> void:
	if not _playing:
		return
	_stop_shake()
	_finish_intro()


func _clear_dialogue() -> void:
	dialogue_label.text = ""
	dialogue_panel.visible = false
	dialogue_panel.modulate.a = 0.0


func _finish_intro() -> void:
	if not _playing:
		return
	_playing = false
	skip_hint.hide()
	camera.current = false
	if _sun:
		_sun.shadow_enabled = _sun_shadows_enabled
	_clear_dialogue()
	epilogue_label.visible = false
	epilogue_label.text = ""
	dialogue_ui.hide()
	hide()
	fade_rect.modulate = Color(1, 1, 1, 0)
	fade_rect.color = Color(0, 0, 0, 0)
	intro_finished.emit()
