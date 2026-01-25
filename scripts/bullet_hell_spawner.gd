extends Node2D

# TODO: Bullet pooling

# --- Configurable Variables ---
@export var bullet_scene: PackedScene
@export var fire_times: int = 50
@export var fire_interval: float = 0.05
@export var bullet_speed: float = 200.0
@export var spin_per_shot: float = 10.0
@export var bullet_acceleration: float = 100.0

var bullet_hell_is_on := false

# Base 8 directions (local space)
var base_directions := [
	Vector2.UP,
	Vector2.DOWN,
	Vector2.LEFT,
	Vector2.RIGHT,
	Vector2.UP + Vector2.LEFT,
	Vector2.UP + Vector2.RIGHT,
	Vector2.DOWN + Vector2.LEFT,
	Vector2.DOWN + Vector2.RIGHT
]

func _ready():
	for i in range(base_directions.size()):
		base_directions[i] = base_directions[i].normalized()

func bullet_hell() -> void:
	if bullet_hell_is_on:
		return

	bullet_hell_is_on = true

	for _i in range(fire_times):

		# Fire in all 8 directions
		for dir in base_directions:
			var bullet = bullet_scene.instantiate()
			bullet.top_level = true

			# Rotate direction by spawner's current rotation
			bullet.direction = dir.rotated(global_rotation)
			bullet.speed = bullet_speed
			bullet.acceleration = bullet_acceleration

			get_tree().current_scene.add_child(bullet)
			bullet.global_position = global_position

		# Rotate the spawner itself
		rotation += deg_to_rad(spin_per_shot)

		await get_tree().create_timer(fire_interval).timeout

	bullet_hell_is_on = false
