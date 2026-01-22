extends CharacterBody2D

@export var MAX_SPEED: float = 400.0
@export var ACCELERATION: float = 1600.0
@export var DECELERATION: float = 2000.0

func _physics_process(delta: float) -> void:
	
	# Normalizes player input to handle diagonal movement properly 
	var input_direction: Vector2 = Input.get_vector("left", "right", "up", "down")

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
