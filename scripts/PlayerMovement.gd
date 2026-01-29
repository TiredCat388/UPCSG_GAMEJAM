extends CharacterBody2D

# Reference the child node
@onready var sword_swinger: Node = $SwordSwinger  # Change Node to whatever type SwordSwinger is

@export var MAX_SPEED: float = 400.0
@export var ACCELERATION: float = 1600.0
@export var DECELERATION: float = 2000.0
@export var animation_tree: AnimationTree

var facing_direction: Vector2 = Vector2.RIGHT

#region PlayerDash
@export var dash_speed: float = 800.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 0.5

var is_dashing: bool = false
var can_dash: bool = true
var dash_direction: Vector2 = Vector2.ZERO


func _start_dash() -> void:
	velocity = dash_direction.normalized() * dash_speed
	await get_tree().create_timer(dash_duration).timeout
	is_dashing = false

	# Starts dash cooldown timer
	await get_tree().create_timer(dash_cooldown).timeout
	
	can_dash = true


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

func _physics_process(delta: float) -> void:
	# Normalizes player input to handle diagonal movement properly
	var input_direction: Vector2 = Input.get_vector("left", "right", "up", "down")
	animation_tree.set("parameters/goblin_movement/blend_position", velocity.normalized())
	if input_direction != Vector2.ZERO:
		facing_direction = input_direction.normalized()

	if Input.is_action_just_pressed("dash"):
		try_dash(input_direction)

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
	
func _process(delta: float) -> void:
	# Swing sword when Q is pressed
	if Input.is_action_just_pressed("swing_sword"):  # map "q" to this input action
		sword_swinger.swing_sword()
