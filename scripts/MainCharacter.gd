extends CharacterBody2D

@onready var bullet_hell_spawner := $BulletHellSpawner 

@export var speed: float = 100.0
@export var stop_time_min: float = 1.0
@export var stop_time_max: float = 3.0
@export var target_distance_threshold: float = 10.0
@export var map_edge_padding: float = 50.0  # distance from viewport edges

var target_position: Vector2
var stopping: bool = false
var stop_timer: float = 0.0

func _ready():
	pick_new_target()

func _physics_process(delta):
	if stopping:
		if not bullet_hell_spawner.bullet_hell_is_on:
			stopping = false
			pick_new_target()
	else:
		move_towards_target(delta)


func pick_new_target():
	var rect = get_viewport().get_visible_rect()
	target_position = Vector2(
		randf_range(rect.position.x + map_edge_padding, rect.position.x + rect.size.x - map_edge_padding),
		randf_range(rect.position.y + map_edge_padding, rect.position.y + rect.size.y - map_edge_padding)
	)

func move_towards_target(delta):
	var dir = (target_position - global_position).normalized()
	velocity = dir * speed
	move_and_slide()
	if global_position.distance_to(target_position) < target_distance_threshold:
		stop_and_attack()

func stop_and_attack():
	stopping = true
	velocity = Vector2.ZERO
	move_and_slide()
	bullet_hell_spawner.bullet_hell()
