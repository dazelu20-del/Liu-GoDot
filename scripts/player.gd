extends CharacterBody3D

const WALK_SPEED := 5.0
const EXHAUSTED_WALK_SPEED := 1.75
const SPRINT_SPEED := 8.5
const JUMP_VELOCITY := 4.5
const MOUSE_SENSITIVITY := 0.002

const WALK_BOB_SPEED := 5.0
const WALK_BOB_SWAY := 0.018
const WALK_BOB_VERT := 0.035
const WALK_BOB_ROLL := 0.012

const SPRINT_BOB_SPEED := 9.0
const SPRINT_BOB_SWAY := 0.03
const SPRINT_BOB_ROLL := 0.018

@onready var head: Node3D = $Head
@onready var camera_bob: Node3D = $Head/CameraBob
@onready var camera: Camera3D = $Head/CameraBob/Camera3D

var _bob_time := 0.0
var can_control := false


func enable_control() -> void:
	can_control = true
	camera.current = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func disable_control() -> void:
	can_control = false
	SurvivalStats.set_sprinting(false)


func _input(event: InputEvent) -> void:
	if not can_control:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		head.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		head.rotation.x = clampf(head.rotation.x, deg_to_rad(-90.0), deg_to_rad(90.0))


func _physics_process(delta: float) -> void:
	if not can_control:
		SurvivalStats.set_sprinting(false)
		velocity = Vector3.ZERO
		camera_bob.position = camera_bob.position.lerp(Vector3.ZERO, delta * 12.0)
		camera_bob.rotation = camera_bob.rotation.lerp(Vector3.ZERO, delta * 12.0)
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var wants_sprint := Input.is_action_pressed("sprint") and direction.length_squared() > 0.0
	var sprinting := wants_sprint and SurvivalStats.can_sprint()
	SurvivalStats.set_sprinting(sprinting)
	var speed: float = SPRINT_SPEED if sprinting else (
		EXHAUSTED_WALK_SPEED if SurvivalStats.exhausted else WALK_SPEED
	)
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()
	_update_camera_bob(delta)


func _update_camera_bob(delta: float) -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var is_moving := is_on_floor() and horizontal_speed > 0.4
	var sprinting := (
		is_moving
		and Input.is_action_pressed("sprint")
		and SurvivalStats.can_sprint()
	)

	if is_moving:
		var bob_speed: float = SPRINT_BOB_SPEED if sprinting else WALK_BOB_SPEED
		var sway_amount: float = SPRINT_BOB_SWAY if sprinting else WALK_BOB_SWAY
		var roll_amount: float = SPRINT_BOB_ROLL if sprinting else WALK_BOB_ROLL

		_bob_time += delta * bob_speed

		var bounce: float = absf(sin(_bob_time))
		var sway: float = sin(_bob_time * 0.5)

		var offset := Vector3(
			sway * sway_amount,
			0.0 if sprinting else bounce * WALK_BOB_VERT,
			0.0
		)
		var tilt := Vector3(0.0, 0.0, sway * roll_amount)

		camera_bob.position = offset
		camera_bob.rotation = tilt
	else:
		_bob_time = 0.0
		camera_bob.position = camera_bob.position.lerp(Vector3.ZERO, delta * 12.0)
		camera_bob.rotation = camera_bob.rotation.lerp(Vector3.ZERO, delta * 12.0)
