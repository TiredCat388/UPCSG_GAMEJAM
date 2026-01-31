extends Node2D

# TODO: Bullet pooling

# --- Configurable Variables ---
@export var PROJECTILE_SCENE: PackedScene
@export var FIRE_TIMES: int = 50
@export var FIRE_INTERVAL: float = 0.05
@export var BULLET_SPEED: float = 200.0
@export var SPIN_PER_SHOT: float = 10.0
@export var BULLET_ACCELERATION: float = 100.0

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

	for _i in range(FIRE_TIMES):

		# Fire in all 8 directions
		for dir in base_directions:
			var bullet = PROJECTILE_SCENE.instantiate()
			bullet.top_level = true

			# Rotate direction by spawner's current rotation
			bullet.direction = dir.rotated(global_rotation)
			bullet.SPEED = BULLET_SPEED
			bullet.ACCELERATION = BULLET_ACCELERATION

			get_tree().current_scene.add_child(bullet)
			bullet.global_position = global_position

		# Rotate the spawner itself
		rotation += deg_to_rad(SPIN_PER_SHOT)

		await get_tree().create_timer(FIRE_INTERVAL).timeout

	bullet_hell_is_on = false
