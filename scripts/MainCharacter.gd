extends CharacterBody2D

@onready var bullet_hell_spawner := $BulletHellSpawner 
@onready var sword_swinger := $SwordSwinger 
@onready var floating_weapon := $FloatingWeaponSocket

@export var projectile_scene: PackedScene
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
	show()

func _physics_process(delta):
	if stopping:
		if not bullet_hell_spawner.bullet_hell_is_on:
			stopping = false
			pick_new_target()
	else:
		move_towards_target(delta)

func get_facing_direction() -> Vector2:
	if stopping:
		# Face target when attacking
		return (target_position - global_position).normalized()
	elif velocity.length() > 0:
		return velocity.normalized()
	else:
		return Vector2.RIGHT

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
	# bullet_hell_spawner.bullet_hell()
	# throw_sword_slash()
	# sword_swinger.swing_sword()
	floating_weapon.first_attack()
	# floating_weapon.second_attack(get_facing_direction())
	print("attaks")

func throw_sword_slash():
	# check if op sword is equiped
	if not projectile_scene:
		return

	var sword_slash = projectile_scene.instantiate()
	sword_slash.top_level = true
	sword_slash.SPEED = 600

	sword_slash.direction = (target_position - global_position).normalized()

	# sword_slash.RANGE = 800
	
	get_tree().current_scene.add_child(sword_slash)
	sword_slash.global_position = global_position
