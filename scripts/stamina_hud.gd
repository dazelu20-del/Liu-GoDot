extends CanvasLayer

const FADE_DURATION := 0.35
const FULL_THRESHOLD := 99.5

@onready var _panel: PanelContainer = $TopMargin/CenterContainer/Panel
@onready var _bar: ProgressBar = $TopMargin/CenterContainer/Panel/Row/Bar
@onready var _label: Label = $TopMargin/CenterContainer/Panel/Row/Label

var _fade_tween: Tween
var _fading_out := false


func _ready() -> void:
	hide()
	_panel.modulate.a = 0.0
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	SurvivalStats.stamina_changed.connect(_on_stamina_changed)


func hide_hud() -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	_fading_out = false
	hide()
	_panel.modulate.a = 0.0


func _on_stamina_changed(stamina: float, sprinting: bool) -> void:
	_bar.value = stamina
	_label.text = "Stamina  %d" % int(roundf(stamina))

	var should_show := (
		sprinting
		or stamina < FULL_THRESHOLD
		or SurvivalStats.exhausted
		or SurvivalStats.is_stamina_active()
	)
	if should_show:
		if not is_visible() or _panel.modulate.a < 0.99:
			_fading_out = false
			_fade_to(1.0)
	elif is_visible() and _panel.modulate.a > 0.01 and not _fading_out:
		_fade_out()


func _fade_to(target_alpha: float) -> void:
	show()
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_panel, "modulate:a", target_alpha, FADE_DURATION)


func _fade_out() -> void:
	_fading_out = true
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_panel, "modulate:a", 0.0, FADE_DURATION)
	_fade_tween.finished.connect(_on_fade_out_finished, CONNECT_ONE_SHOT)


func _on_fade_out_finished() -> void:
	_fading_out = false
	hide()
