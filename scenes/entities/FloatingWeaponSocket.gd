extends Node2D

# --- Editor-exposed properties ---
@export var weapon_scene: PackedScene
@export var circle_duration: float = 0.25
@export var revolutions: int = 10
@export var ease_in_fraction: float = 0.1
@export var ease_out_fraction: float = 0.2
@export var spin_multiplier: float = 1.0
@export var target_radius: float = 300.0
@export var target_scale: Vector2 = Vector2.ONE
@export var scale_ease_in_fraction: float = 0.1
@export var scale_ease_out_fraction: float = 0.2
@export var float_amplitude: float = 20.0   # How much it floats up/down
@export var float_speed: float = 2.0       # How fast it floats
@export var first_attack_cooldown: float = 5.0

var last_attack_time: float = -9999.0

# --- Idle floating variables ---
var float_time: float = 0.0


# --- Internal variables ---
var weapon_instance: Node2D = null
var default_position: Vector2 = Vector2.ZERO
var initial_rotation: float = 0.0
var initial_scale: Vector2 = Vector2.ONE
var is_attacking: bool = false

# --- Circle attack variables ---
var attack_angle: float = 0.0
var attack_revolutions_done: int = 0
var offset_from_parent: Vector2 = Vector2.ZERO
var start_radius: float = 0.0
var end_radius: float = 0.0

func _ready():
	default_position = position
	initial_rotation = rotation
	initial_scale = scale

	if weapon_scene:
		weapon_instance = weapon_scene.instantiate()
		add_child(weapon_instance)
		weapon_instance.position = Vector2.ZERO

func _process(delta):
	if weapon_instance == null:
		return

	if not is_attacking:
		# Idle floating effect for the weapon only
		float_time += delta
		var float_offset = Vector2(0, sin(float_time * float_speed) * float_amplitude)
		weapon_instance.position = float_offset
		weapon_instance.rotation = 0
		weapon_instance.scale = initial_scale
		return

	# --- Attacking logic ---
	var parent_center = get_parent().global_position
	var progress = compute_progress()

	var current_speed = compute_orbit_speed(progress)
	update_attack_angle(current_speed, delta)
	
	var radius = compute_radius(progress)
	weapon_instance.scale = compute_scale(progress)

	# Update weapon_instance relative to parent center
	weapon_instance.global_position = parent_center + (offset_from_parent.normalized() * radius).rotated(attack_angle)
	weapon_instance.rotation = initial_rotation + attack_angle * spin_multiplier

	debug_print(progress, radius)


# --- Helper functions grouped by function ---

func reset_weapon():
	position = default_position
	rotation = initial_rotation
	scale = initial_scale

func compute_progress() -> float:
	var progress = float(attack_revolutions_done) + attack_angle / TAU
	return progress / revolutions

func compute_orbit_speed(progress: float) -> float:
	var base_speed = TAU / circle_duration       # Full orbit speed
	var min_speed = base_speed * 0.1            # e.g., 20% of base speed at start
	var speed_multiplier = 1.0

	if progress < ease_in_fraction and ease_in_fraction > 0.0:
		var t = clamp(progress / ease_in_fraction, 0.0, 1.0)
		speed_multiplier = ease_in_out(t)
		# Map from min_speed..1.0
		speed_multiplier = min_speed / base_speed + (1.0 - min_speed / base_speed) * speed_multiplier
	elif progress > 1.0 - ease_out_fraction and ease_out_fraction > 0.0:
		var t = clamp((progress - (1.0 - ease_out_fraction)) / ease_out_fraction, 0.0, 1.0)
		speed_multiplier = ease_in_out(1.0 - t)
		speed_multiplier = min_speed / base_speed + (1.0 - min_speed / base_speed) * speed_multiplier

	return base_speed * speed_multiplier


func update_attack_angle(current_speed: float, delta: float):
	attack_angle += current_speed * delta
	if attack_angle >= TAU:
		attack_angle -= TAU
		attack_revolutions_done += 1
		if attack_revolutions_done >= revolutions:
			_end_attack()

func compute_radius(progress: float) -> float:
	if progress < ease_in_fraction and ease_in_fraction > 0.0:
		var t = clamp(progress / ease_in_fraction, 0, 1)
		return lerp(start_radius, target_radius, ease_in_out(t))
	elif progress > 1.0 - ease_out_fraction and ease_out_fraction > 0.0:
		var t = clamp((progress - (1 - ease_out_fraction)) / ease_out_fraction, 0, 1)
		return lerp(target_radius, end_radius, ease_in_out(t))
	else:
		return target_radius

func compute_scale(progress: float) -> Vector2:
	if progress < scale_ease_in_fraction and scale_ease_in_fraction > 0.0:
		var t = clamp(progress / scale_ease_in_fraction, 0, 1)
		return initial_scale.lerp(target_scale, ease_in_out(t))
	elif progress > 1.0 - scale_ease_out_fraction and scale_ease_out_fraction > 0.0:
		var t = clamp((progress - (1 - scale_ease_out_fraction)) / scale_ease_out_fraction, 0, 1)
		return target_scale.lerp(initial_scale, ease_in_out(t))
	else:
		return target_scale

func update_position_and_rotation(parent_center: Vector2, radius: float):
	global_position = parent_center + (offset_from_parent.normalized() * radius).rotated(attack_angle)
	rotation = initial_rotation + attack_angle * spin_multiplier

func debug_print(progress: float, radius: float):
	print("Progress:", progress, " Radius:", radius, " Scale:", scale, " Rotation:", rotation)

# --- Smoothstep easing ---
func ease_in_out(t: float) -> float:
	t = clamp(t, 0, 1)
	return 3 * t * t - 2 * t * t * t

func first_attack():
	var now: float = Time.get_ticks_msec() * 0.001

	if weapon_instance == null \
	or is_attacking \
	or now - last_attack_time < first_attack_cooldown:
		return

	last_attack_time = now
	is_attacking = true

	attack_angle = 0.0
	attack_revolutions_done = 0

	offset_from_parent = global_position - get_parent().global_position
	start_radius = offset_from_parent.length()
	end_radius = start_radius


# --- End attack ---
func _end_attack():
	is_attacking = false
	attack_angle = 0
	attack_revolutions_done = 0
	reset_weapon()
