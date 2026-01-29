extends Node2D

# =========================================================
# EDITOR PROPERTIES
# =========================================================
@export var weapon_scene: PackedScene

# First attack (orbit)
@export var circle_duration: float = 0.25
@export var revolutions: int = 10
@export var ease_in_fraction: float = 0.1
@export var ease_out_fraction: float = 0.2
@export var spin_multiplier: float = 1.0
@export var target_radius: float = 300.0
@export var target_scale: Vector2 = Vector2.ONE
@export var scale_ease_in_fraction: float = 0.1
@export var scale_ease_out_fraction: float = 0.2

# Idle floating
@export var float_amplitude: float = 20.0
@export var float_speed: float = 2.0

# Cooldowns
@export var first_attack_cooldown: float = 5.0

# Second attack (spin → throw → return)
@export var second_spin_revolutions: int = 10
@export var second_throw_distance: float = 1200.0
@export var second_throw_duration: float = 3
@export var second_return_duration: float = 0.35

# =========================================================
# INTERNAL STATE
# =========================================================
var last_attack_time: float = -9999.0
var float_time: float = 0.0

var weapon_instance: Node2D
var default_position: Vector2
var initial_rotation: float
var initial_scale: Vector2

# =========================================================
# ATTACK STATES
# =========================================================
enum AttackState { NONE, FIRST, SECOND_SPIN, SECOND_THROW, SECOND_RETURN }
var attack_state: AttackState = AttackState.NONE

# First attack variables
var attack_angle: float = 0.0
var attack_revolutions_done: int = 0
var offset_from_parent: Vector2 = Vector2.ZERO
var start_radius: float = 0.0
var end_radius: float = 0.0

# Second attack variables
var second_spin_angle: float = 0.0
var second_spin_target_rot: float = 0.0
var throw_dir: Vector2 = Vector2.ZERO
var second_origin_pos: Vector2
var second_origin_rot: float
var throw_timer: float = 0.0
var return_timer: float = 0.0

# =========================================================
# READY
# =========================================================
func _ready() -> void:
	default_position = position
	initial_rotation = rotation
	initial_scale = scale

	if weapon_scene:
		weapon_instance = weapon_scene.instantiate()
		add_child(weapon_instance)
		weapon_instance.position = Vector2.ZERO

# =========================================================
# PROCESS
# =========================================================
func _process(delta: float) -> void:
	if weapon_instance == null:
		return

	match attack_state:
		AttackState.FIRST:
			_first_attack_process(delta)
		AttackState.SECOND_SPIN, AttackState.SECOND_THROW, AttackState.SECOND_RETURN:
			_second_attack_process(delta)
		AttackState.NONE:
			_idle_process(delta)

# =========================================================
# IDLE FLOATING
# =========================================================
func _idle_process(delta: float) -> void:
	float_time += delta
	var float_offset: Vector2 = Vector2(0.0, sin(float_time * float_speed) * float_amplitude)
	weapon_instance.position = float_offset
	weapon_instance.rotation = initial_rotation
	weapon_instance.scale = initial_scale

# =========================================================
# FIRST ATTACK (unchanged)
# =========================================================
func first_attack() -> void:
	var now: float = Time.get_ticks_msec() * 0.001
	if attack_state != AttackState.NONE or now - last_attack_time < first_attack_cooldown:
		return

	last_attack_time = now
	attack_state = AttackState.FIRST

	attack_angle = 0.0
	attack_revolutions_done = 0
	offset_from_parent = global_position - get_parent().global_position
	start_radius = offset_from_parent.length()
	end_radius = start_radius

func _first_attack_process(delta: float) -> void:
	var parent_center: Vector2 = get_parent().global_position
	var progress: float = compute_progress()
	var speed: float = compute_orbit_speed(progress)

	update_attack_angle(speed, delta)

	var radius: float = compute_radius(progress)
	weapon_instance.scale = compute_scale(progress)
	weapon_instance.global_position = parent_center + offset_from_parent.normalized().rotated(attack_angle) * radius
	weapon_instance.rotation = initial_rotation + attack_angle * spin_multiplier

	print("FIRST ATTACK ROT:", weapon_instance.rotation)

func _end_attack() -> void:
	attack_state = AttackState.NONE
	attack_angle = 0.0
	attack_revolutions_done = 0
	reset_weapon()

# =========================================================
# SECOND ATTACK (spin → snap → throw → return)
# =========================================================
func second_attack(direction: Vector2) -> void:
	if attack_state != AttackState.NONE or weapon_instance == null:
		return

	attack_state = AttackState.SECOND_SPIN
	second_spin_angle = 0.0
	throw_dir = direction.normalized()
	second_origin_pos = weapon_instance.global_position
	second_origin_rot = weapon_instance.rotation
	second_spin_target_rot = throw_dir.angle() - PI/2  # snap top-facing

func _second_attack_process(delta: float) -> void:
	match attack_state:
		AttackState.SECOND_SPIN:
			_second_spin_process(delta)
		AttackState.SECOND_THROW:
			_second_throw_process(delta)
		AttackState.SECOND_RETURN:
			_second_return_process(delta)


func _second_spin_process(delta: float) -> void:
	var total_angle: float = TAU * float(second_spin_revolutions - 1)
	var spin_speed: float = TAU * 10.0  # adjust this to control how fast it spins (radians/sec)

	weapon_instance.rotation += spin_speed * delta
	second_spin_angle += spin_speed * delta

	print("SECOND SPIN ROT:", weapon_instance.rotation)

	# Stop instantly after N-1 spins
	if second_spin_angle >= total_angle:
		weapon_instance.rotation = second_spin_target_rot
		attack_state = AttackState.SECOND_THROW
		throw_timer = 0.0

func _second_throw_process(delta: float) -> void:
	throw_timer += delta
	var t: float = clamp(throw_timer / second_throw_duration, 0.0, 1.0)
	var eased: float = ease_in_out(t)

	# Start throw from spin's last position
	var throw_start_pos: Vector2 = weapon_instance.global_position
	var throw_end_pos: Vector2 = throw_start_pos + throw_dir * second_throw_distance

	# Interpolate position along throw path
	weapon_instance.global_position = throw_start_pos.lerp(throw_end_pos, t)
	weapon_instance.scale = initial_scale * 1.5

	# Keep weapon pointing head-first along throw
	weapon_instance.rotation = throw_dir.angle() + PI/2  # always head-first

	print("SECOND THROW POS:", weapon_instance.global_position)

	if t >= 1.0:
		attack_state = AttackState.SECOND_RETURN
		return_timer = 0.0

func _second_return_process(delta: float) -> void:
	return_timer += delta
	var t: float = clamp(return_timer / second_return_duration, 0.0, 1.0)

	# Smaller easing factor for quicker return
	var eased: float = ease_in_out(t) * 0.5 + 0.5  # tweak 0.5 for speed

	# Always return to the player's current position
	var player_pos: Vector2 = get_parent().global_position
	weapon_instance.global_position = weapon_instance.global_position.lerp(player_pos, eased)

	# Rotate weapon to face the parent “head first”
	var dir_to_center: Vector2 = player_pos - weapon_instance.global_position
	weapon_instance.rotation = dir_to_center.angle() + PI/2  # top-facing

	print("SECOND RETURN POS:", weapon_instance.global_position)

	if t >= 1.0:
		_end_second_attack()


func _end_second_attack() -> void:
	attack_state = AttackState.NONE
	weapon_instance.global_position = second_origin_pos
	weapon_instance.rotation = second_origin_rot

# =========================================================
# HELPERS
# =========================================================
func reset_weapon() -> void:
	position = default_position
	rotation = initial_rotation
	scale = initial_scale

func compute_progress() -> float:
	return (float(attack_revolutions_done) + attack_angle / TAU) / float(revolutions)

func compute_orbit_speed(progress: float) -> float:
	var base_speed: float = TAU / circle_duration
	var min_speed: float = base_speed * 0.1
	var speed_mul: float = 1.0

	if progress < ease_in_fraction:
		speed_mul = lerp(min_speed / base_speed, 1.0, ease_in_out(progress / ease_in_fraction))
	elif progress > 1.0 - ease_out_fraction:
		speed_mul = lerp(min_speed / base_speed, 1.0, ease_in_out((1.0 - progress) / ease_out_fraction))

	return base_speed * speed_mul

func update_attack_angle(speed: float, delta: float) -> void:
	attack_angle += speed * delta
	if attack_angle >= TAU:
		attack_angle -= TAU
		attack_revolutions_done += 1
		if attack_revolutions_done >= revolutions:
			_end_attack()

func compute_radius(progress: float) -> float:
	if progress < ease_in_fraction:
		return lerp(start_radius, target_radius, ease_in_out(progress / ease_in_fraction))
	elif progress > 1.0 - ease_out_fraction:
		return lerp(target_radius, end_radius, ease_in_out((progress - (1.0 - ease_out_fraction)) / ease_out_fraction))
	return target_radius

func compute_scale(progress: float) -> Vector2:
	if progress < scale_ease_in_fraction:
		return initial_scale.lerp(target_scale, ease_in_out(progress / scale_ease_in_fraction))
	elif progress > 1.0 - scale_ease_out_fraction:
		return target_scale.lerp(initial_scale, ease_in_out((progress - (1.0 - scale_ease_out_fraction)) / scale_ease_out_fraction))
	return target_scale

func ease_in_out(t: float) -> float:
	t = clamp(t, 0.0, 1.0)
	return 3.0 * t * t - 2.0 * t * t * t
