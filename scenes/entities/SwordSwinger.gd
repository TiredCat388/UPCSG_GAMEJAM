extends Node2D  # The socket node, child of the player

@export var sword_scene: PackedScene
@export var swing_duration: float = 0.3
@export var swing_angle: float = 180.0  # Total arc in degrees

var current_sword: Node = null

# You need to update this every frame in your player code
var facing_direction: Vector2 = Vector2.RIGHT

func swing_sword() -> void:
	if not sword_scene:
		push_warning("No sword scene assigned!")
		return

	if current_sword:
		current_sword.queue_free()

	current_sword = sword_scene.instantiate()
	current_sword.position = Vector2.ZERO  # Socket local position
	add_child(current_sword)

	# Make sure facing_direction is set from parent
	if get_parent().has_method("get_facing_direction"):
		facing_direction = get_parent().get_facing_direction()

	# Calculate swing rotation relative to facing
	var half_swing = deg_to_rad(swing_angle) / 2
	var base_angle = facing_direction.angle()  # Facing vector angle in radians

	current_sword.rotation = base_angle - half_swing  # Start of swing

	# Tween swing
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)

	var swing_offset_factor = 0.7  # 1.0 = full half_swing, 0.5 = start closer
	current_sword.rotation = base_angle - half_swing * swing_offset_factor

	# Tween to the other side
	tween.tween_property(
		current_sword,
		"rotation",
		base_angle + half_swing * swing_offset_factor,
		swing_duration
	)


	# Destroy sword after swing
	tween.tween_callback(current_sword.queue_free)
