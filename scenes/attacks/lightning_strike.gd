extends Node2D

# --- Configurable properties ---
@export var damage: int = 30
@export var radius: float = 64.0
@export var oval_scale: Vector2 = Vector2(1.5, 1.0)
@export var lightning_speed: float = 2.0
@export var damage_frame: int = 4  # Frame at which damage applies

func _ready():
	# --- Setup AoE hitbox ---
	if $Hitbox/CollisionShape2D.shape is CircleShape2D:
		$Hitbox/CollisionShape2D.shape.radius = radius
		$Hitbox/CollisionShape2D.scale = oval_scale

	$Hitbox/CollisionShape2D.disabled = true  # Initially disabled

	# --- Play Lightning animation ---
	$Lightning.speed_scale = lightning_speed
	$Lightning.play("lightning")

	# Connect signal to detect frame changes
	$Lightning.frame_changed.connect(_on_lightning_frame_changed)

	# Wait until the animation finishes, then delete the node
	await $Lightning.animation_finished
	queue_free()


func _on_lightning_frame_changed():
	# Apply damage exactly on the desired frame
	if $Lightning.frame == damage_frame:
		$Hitbox/CollisionShape2D.disabled = false
		_apply_damage()
		$Hitbox/CollisionShape2D.disabled = true

		# Disconnect signal so it only happens once
		$Lightning.frame_changed.disconnect(_on_lightning_frame_changed)


func _apply_damage():
	for body in $Hitbox.get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage(damage)
