extends CharacterBody2D

var player_body: CharacterBody2D
var player_dash: PlayerDash

@export var MAX_SPEED: float = 400.0
@export var ACCELERATION: float = 1600.0
@export var DECELERATION: float = 2000.0

var facing_direction: Vector2 = Vector2.RIGHT


func _ready() -> void:
	player_dash = $PlayerDash
	assert(player_dash != null, "PlayerDash node not found")


func _physics_process(delta: float) -> void:
	# Normalizes player input to handle diagonal movement properly
	var input_direction: Vector2 = Input.get_vector("left", "right", "up", "down")
	if input_direction != Vector2.ZERO:
		facing_direction = input_direction.normalized()

	if Input.is_action_just_pressed("dash"):
		player_dash.try_dash(input_direction)

	if player_dash.is_dashing:
		velocity = player_dash.dash_direction * player_dash.dash_speed
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
