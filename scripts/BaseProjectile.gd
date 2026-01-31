extends Area2D

@export var SPEED: float = 10000.0
@export var ACCELERATION: float = 0.0 # Pixels per second², defaults to 0

var direction: Vector2 = Vector2.RIGHT
var radius: float = 4.0

func _ready():
	# If there's a CollisionShape2D child with a CircleShape2D, use its radius
	var collision_shape = $CollisionShape2D.shape
	if collision_shape is CircleShape2D:
		radius = collision_shape.radius

func _physics_process(delta):
	# Increase SPEED by acceleration
	SPEED += ACCELERATION * delta

	# Move the bullet
	global_position += direction * SPEED * delta

	# Get the current viewport rectangle
	var viewport_rect = get_viewport().get_visible_rect()

	# If bullet is outside, remove it
	if not viewport_rect.has_point(global_position):
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(10)
		queue_free()  # destroy bullet after hit
	
