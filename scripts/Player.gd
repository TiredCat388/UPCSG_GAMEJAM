extends CharacterBody2D


@onready var shield := $Shield

@export var MAX_SPEED: float = 400.0
@export var ACCELERATION: float = 1600.0
@export var DECELERATION: float = 2000.0
@export var animation_tree: AnimationTree
var facing_direction: Vector2 = Vector2.RIGHT

@export var player_health: float = 100.0
var is_dead: bool = false
var can_block: bool = false

#region Player dash
@export var dash_speed: float = 800.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 0.5

var is_dashing: bool = false
var can_dash: bool = true
var dash_direction: Vector2 = Vector2.ZERO

@export var parry_duration: float = 0.5
var parry_timer: float = 0.0
var is_parrying: bool = false
var parry_cooldown_timer: float = 0.0
var parry_cooldown: float = 1

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


#region Banana
@export var banana_spawn_cooldown: float = 1.0
var banana_spawn_cooldown_timer: float = 0.0

var bananas : Array = []

func throw_banana() -> void:
	for banana in bananas:
		if not banana.is_visible():
			banana.global_position = global_position
			await get_tree().create_timer(0.1).timeout
			banana.start_expire()
			banana.show()
			return
		
	print("No available bananas to throw.")
#endregion

func take_damage(amount: float) -> String:
	if is_parrying:
		print("Parried the attack!")
		return "parried"

	player_health -= amount
	print("Player Health: %d" % player_health)

	if player_health <= 0:
		print("Player defeated!")
		is_dead = true
		return "defeated"

	return "damaged"

func update_parry(delta) -> void:
	parry_timer += delta
	if parry_timer >= parry_duration:
		is_parrying = false
		parry_timer = 0.0

func _physics_process(delta: float) -> void:
	if is_dead: 
		return

	var input_direction: Vector2 = Input.get_vector("left", "right", "up", "down")
	animation_tree.set("parameters/goblin_movement/blend_position", velocity.normalized())
	if input_direction != Vector2.ZERO:
		facing_direction = input_direction.normalized()


	if Input.is_action_just_pressed("parry"):
		if parry_cooldown_timer <= 0.0 && can_block:
			animation_tree.set("parameters/goblin_block/blend_position", velocity.normalized())
			is_parrying = true
			parry_cooldown_timer = parry_cooldown
	elif (
		Input.is_action_just_pressed("dash")
		and not is_dashing
	):
		try_dash(input_direction)
	elif (
		Input.is_action_just_pressed("banana")
		and not is_dashing
		and not is_parrying
	):
		if banana_spawn_cooldown_timer <= 0.0:
			throw_banana()
			banana_spawn_cooldown_timer = banana_spawn_cooldown

	# Always update parry cooldown timer
	parry_cooldown_timer = max(0.0, parry_cooldown_timer - delta)
	
	# Always update banana spawn cooldown timer
	banana_spawn_cooldown_timer = max(0.0, banana_spawn_cooldown_timer - delta)
	
	if is_parrying:
		update_parry(delta)
	elif is_dashing:
		velocity = dash_direction * dash_speed
	else:
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

#region Spawn
func respawn():
	if is_dead:
		var target_floor = max(GameManager.current_floor - 1, 1)
		GameManager.current_floor = target_floor
		
		var path := "res://scenes/floors/Floor%d.tscn" % target_floor
		get_tree().change_scence_to_file(path)

#endregion
