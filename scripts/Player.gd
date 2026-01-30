extends CharacterBody2D

@onready var shield := $Shield

@export var MAX_SPEED: float = 400.0
@export var ACCELERATION: float = 1600.0
@export var DECELERATION: float = 2000.0
@export var animation_tree: AnimationTree
var facing_direction: Vector2 = Vector2.RIGHT

@export var health: float = 100.0
var dead: bool = false

#region Player dash
@export var dash_speed: float = 800.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 0.5

var is_dashing: bool = false
var can_dash: bool = true
var dash_direction: Vector2 = Vector2.ZERO

@export var parry_frame_window: int = 15
var is_parrying: bool = false
var parry_frame_count: int = 0
var parry_cooldown_timer: float = 0.0
var parry_cooldown: float = 1


func _start_dash() -> void:
	velocity = dash_direction.normalized() * dash_speed
	await get_tree().create_timer(dash_duration).timeout
	is_dashing = false

	# Starts dash cooldown timer
	await get_tree().create_timer(dash_cooldown).timeout
	
	can_dash = true

func take_damage(amount: float) -> String:
	if is_parrying:
		print("Parried the attack!")
		return "parried"

	health -= amount
	print("Player Health: %d" % health)

	if health <= 0:
		print("Player defeated!")
		dead = true
		return "defeated"

	return "damaged"

func update_parry() -> void:
	parry_frame_count += 1
	if parry_frame_count >= parry_frame_window:
		is_parrying = false
		parry_frame_count = 0
		shield.hide()

func try_dash(input_direction: Vector2) -> void:
	# Prevents dashing while on cooldown or while currently dashing
	if not can_dash or is_dashing:
		return

	dash_direction = input_direction
	if dash_direction == Vector2.ZERO:
		dash_direction = facing_direction

	is_dashing = true
	can_dash = false

	_start_dash()
#endregion

func _ready() -> void:
	if shield: 
		shield.hide()

func _physics_process(delta: float) -> void:
	if dead: 
		return

	# Normalizes player input to handle diagonal movement properly
	var input_direction: Vector2 = Input.get_vector("left", "right", "up", "down")
	animation_tree.set("parameters/goblin_movement/blend_position", velocity.normalized())
	if input_direction != Vector2.ZERO:
		facing_direction = input_direction.normalized()

	if Input.is_action_just_pressed("dash"):
		try_dash(input_direction)

	if Input.is_action_just_pressed("parry"):
		if parry_cooldown_timer <= 0.0:
			shield.show()
			is_parrying = true
			parry_cooldown_timer = parry_cooldown
		else:
			print("Parry is on cooldown: %.2f seconds remaining" % parry_cooldown_timer)

	parry_cooldown_timer = max(0.0, parry_cooldown_timer - delta)

	if is_parrying:
		update_parry()

	if is_dashing:
		velocity = dash_direction * dash_speed
	else:
		# Separates target from current velocity to allow acceleration and deceleration
		var target_velocity: Vector2 = input_direction * MAX_SPEED

		if input_direction != Vector2.ZERO:
			velocity = velocity.move_toward(
				target_velocity, 
				ACCELERATION * delta
			)

		else:
			velocity = velocity.move_toward(
				Vector2.ZERO, 
				DECELERATION * delta
			)

	move_and_slide()