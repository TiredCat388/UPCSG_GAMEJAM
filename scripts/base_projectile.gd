extends Area2D

@export var speed: float = 10000.0
@export var acceleration: float = 0.0 # Pixels per second², defaults to 0
@export var color: Color = Color(1, 1, 0) # Yellow

var direction: Vector2 = Vector2.RIGHT
var radius: float = 4.0

func _ready():
	# If there's a CollisionShape2D child with a CircleShape2D, use its radius
	var collision_shape = $CollisionShape2D.shape
	if collision_shape is CircleShape2D:
		radius = collision_shape.radius

func _physics_process(delta):
	# Increase speed by acceleration
	speed += acceleration * delta

	# Move the bullet
	global_position += direction * speed * delta

	# Get the current viewport rectangle
	var viewport_rect = get_viewport().get_visible_rect()

	# If bullet is outside, remove it
	if not viewport_rect.has_point(global_position):
		queue_free()
