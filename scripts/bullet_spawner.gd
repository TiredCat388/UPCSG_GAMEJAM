extends Node2D

# --- Configurable Variables ---
@export var bullet_scene: PackedScene
@export var fire_times: int = 50
@export var fire_interval: float = 0.8
@export var bullet_speed: float = 10000.0
@export var spin_per_shot: float = 10.0   # degrees per fire

var can_shoot := true

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

func shoot() -> void:
	if not can_shoot:
		return

	can_shoot = false

	for _i in range(fire_times):

		# Fire in all 8 directions
		for dir in base_directions:
			var bullet = bullet_scene.instantiate()
			bullet.top_level = true

			# Rotate direction by spawner's current rotation
			bullet.direction = dir.rotated(global_rotation)
			bullet.speed = bullet_speed

			get_tree().current_scene.add_child(bullet)
			bullet.global_position = global_position

		# Rotate the spawner itself
		rotation += deg_to_rad(spin_per_shot)

		await get_tree().create_timer(fire_interval).timeout

	can_shoot = true
