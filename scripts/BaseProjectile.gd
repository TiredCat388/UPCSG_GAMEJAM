extends Area2D
"""
Projectile behavior:
- Moves in a given direction with optional acceleration.
- If RANGE < 0: projectile is destroyed when it leaves the screen.
- If RANGE >= 0: projectile is destroyed after traveling the given distance (in pixels).
- Distance traveled is accumulated per frame for accuracy.
- Collision radius is read from a CircleShape2D if present.

Recommended RANGE values (pixels):
- < 0        : Screen-based cleanup (default for most bullets)
- 120–250    : Short range (slash waves, shotgun pellets, melee-like projectiles)
- 350–700    : Medium range (standard enemy or player projectiles)
- 900–1500   : Long range (snipers, boss attacks)
- 1800+      : Extreme range (lasers, railgun-style shots, large/zoomed-out maps)

Rule of thumb:
- Good range ≈ 0.5× to 1.2× camera width
"""

@export var SPEED: float = 1000.0
@export var ACCELERATION: float = 0.0
@export var RANGE: float = -1.0

var direction: Vector2 = Vector2.RIGHT
var radius: float = 4.0

var traveled: float = 0.0
var last_position: Vector2

func _ready():
	var collision_shape = $CollisionShape2D.shape
	if collision_shape is CircleShape2D:
		radius = collision_shape.radius
	last_position = global_position

func _physics_process(delta):
	SPEED += ACCELERATION * delta
	global_position += direction * SPEED * delta

	# -------------------------
	# Make the projectile face its direction
	if direction.length() > 0:
		rotation = direction.angle()
	# -------------------------
	traveled += global_position.distance_to(last_position)
	last_position = global_position

	if RANGE >= 0.0:
		if traveled >= RANGE:
			queue_free()
		return

	var viewport_rect = get_viewport().get_visible_rect().grow(radius)
	if not viewport_rect.has_point(global_position):
		queue_free()
