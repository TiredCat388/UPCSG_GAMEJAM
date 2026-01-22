extends Node
class_name PlayerDash

var player_body: CharacterBody2D
var player_movement: Node

@export var dash_speed: float = 800.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 0.5

var is_dashing: bool = false
var can_dash: bool = true
var dash_direction: Vector2 = Vector2.ZERO


func _ready() -> void:
	player_body = get_parent() as CharacterBody2D
	player_movement = get_parent() as Node

	assert(player_body != null, "body")
	assert(player_movement != null, "movement")


func _start_dash() -> void:
	player_body.velocity = dash_direction.normalized() * dash_speed
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
		dash_direction = player_movement.facing_direction

	is_dashing = true
	can_dash = false

	_start_dash()
