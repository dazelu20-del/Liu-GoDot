extends CanvasLayer

@onready var _panel: PanelContainer = $MarginContainer/Panel
@onready var _health_bar: ProgressBar = $MarginContainer/Panel/VBox/HealthRow/Bar
@onready var _hunger_bar: ProgressBar = $MarginContainer/Panel/VBox/HungerRow/Bar
@onready var _thirst_bar: ProgressBar = $MarginContainer/Panel/VBox/ThirstRow/Bar
@onready var _health_label: Label = $MarginContainer/Panel/VBox/HealthRow/Label
@onready var _hunger_label: Label = $MarginContainer/Panel/VBox/HungerRow/Label
@onready var _thirst_label: Label = $MarginContainer/Panel/VBox/ThirstRow/Label


func _ready() -> void:
	hide()
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.92, 0.92)
	SurvivalStats.stats_changed.connect(_on_stats_changed)


func show_hud() -> void:
	show()
	_on_stats_changed(SurvivalStats.health, SurvivalStats.hunger, SurvivalStats.thirst)
	_panel.scale = Vector2(0.92, 0.92)
	_panel.modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.45)
	tween.tween_property(_panel, "scale", Vector2.ONE, 0.45)


func hide_hud() -> void:
	hide()
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.92, 0.92)


func _on_stats_changed(health: float, hunger: float, thirst: float) -> void:
	_set_bar(_health_bar, _health_label, "Health", health)
	_set_bar(_hunger_bar, _hunger_label, "Hunger", hunger)
	_set_bar(_thirst_bar, _thirst_label, "Thirst", thirst)


func _set_bar(bar: ProgressBar, label: Label, stat_name: String, value: float) -> void:
	bar.value = value
	label.text = "%s  %d" % [stat_name, int(roundf(value))]
