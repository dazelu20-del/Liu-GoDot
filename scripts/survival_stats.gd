extends Node

## Tracks health, hunger, thirst, and sprint stamina.

signal stats_changed(health: float, hunger: float, thirst: float)
signal stamina_changed(stamina: float, sprinting: bool)

const MAX_STAT := 100.0
# ~14 min from full to empty (matches the old sprint thirst rate)
const SURVIVAL_DRAIN_PER_SEC := 0.121
# Extra thirst drain while sprinting (~8 min if you never stop running)
const THIRST_SPRINT_BONUS_PER_SEC := 0.085
# ~17 sec of continuous sprint; ~10 sec to recover from empty
const STAMINA_DRAIN_SPRINT := 6.0
const STAMINA_REGEN_PER_SEC := 10.0
const STAMINA_COST_JUMP := 12.0
const EXHAUSTION_DURATION := 5.0
const STAMINA_ACTIVITY_FLASH := 1.2

var health := MAX_STAT
var hunger := MAX_STAT
var thirst := MAX_STAT
var stamina := MAX_STAT
var active := false
var exhausted := false

var _sprinting := false
var _exhaustion_time_left := 0.0
var _activity_flash_left := 0.0


func reset() -> void:
	health = MAX_STAT
	hunger = MAX_STAT
	thirst = MAX_STAT
	stamina = MAX_STAT
	active = false
	_sprinting = false
	exhausted = false
	_exhaustion_time_left = 0.0
	_activity_flash_left = 0.0
	stats_changed.emit(health, hunger, thirst)
	stamina_changed.emit(stamina, false)


func start() -> void:
	health = MAX_STAT
	hunger = MAX_STAT
	thirst = MAX_STAT
	stamina = MAX_STAT
	active = true
	_sprinting = false
	exhausted = false
	_exhaustion_time_left = 0.0
	_activity_flash_left = 0.0
	stats_changed.emit(health, hunger, thirst)
	stamina_changed.emit(stamina, false)


func stop() -> void:
	active = false
	_sprinting = false


func can_sprint() -> bool:
	return not exhausted and stamina > 0.0


func can_jump() -> bool:
	return not exhausted


func spend_stamina_on_jump() -> void:
	if not active or exhausted:
		return

	var prev_stamina := stamina
	stamina = maxf(stamina - STAMINA_COST_JUMP, 0.0)
	_activity_flash_left = STAMINA_ACTIVITY_FLASH
	if stamina <= 0.0 and prev_stamina > 0.0:
		_begin_exhaustion()
	stamina_changed.emit(stamina, _sprinting)


func is_stamina_active() -> bool:
	return _activity_flash_left > 0.0


func set_sprinting(sprinting: bool) -> void:
	if sprinting and not can_sprint():
		_sprinting = false
		return
	_sprinting = sprinting


func _begin_exhaustion() -> void:
	exhausted = true
	_exhaustion_time_left = EXHAUSTION_DURATION
	_sprinting = false
	stamina = 0.0


func _process(delta: float) -> void:
	if not active:
		return

	if _activity_flash_left > 0.0:
		_activity_flash_left = maxf(_activity_flash_left - delta, 0.0)

	var thirst_drain := SURVIVAL_DRAIN_PER_SEC
	if _sprinting:
		thirst_drain += THIRST_SPRINT_BONUS_PER_SEC
	thirst = maxf(thirst - thirst_drain * delta, 0.0)
	hunger = maxf(hunger - SURVIVAL_DRAIN_PER_SEC * delta, 0.0)

	if _sprinting:
		var prev_stamina := stamina
		stamina = maxf(stamina - STAMINA_DRAIN_SPRINT * delta, 0.0)
		if stamina <= 0.0 and prev_stamina > 0.0:
			_begin_exhaustion()
	elif exhausted:
		_exhaustion_time_left = maxf(_exhaustion_time_left - delta, 0.0)
		if _exhaustion_time_left <= 0.0:
			exhausted = false
	elif not _sprinting:
		stamina = minf(stamina + STAMINA_REGEN_PER_SEC * delta, MAX_STAT)

	stats_changed.emit(health, hunger, thirst)
	stamina_changed.emit(stamina, _sprinting)


func resume() -> void:
	active = true
	stats_changed.emit(health, hunger, thirst)
	stamina_changed.emit(stamina, _sprinting)
