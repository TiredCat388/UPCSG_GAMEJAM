extends CharacterBody2D

# =========================================================
# NODES
# =========================================================
@onready var bullet_hell_spawner := $BulletHellSpawner 
@onready var sword_swinger := $SwordSwinger 
@onready var floating_weapon := $FloatingWeaponSocket
@export var lightning_scene: PackedScene

# =========================================================
# EXPORT VARIABLES
# =========================================================
@export var projectile_scene: PackedScene
@export var speed: float = 100.0
@export var stop_time_min: float = 1.0
@export var stop_time_max: float = 3.0
@export var target_distance_threshold: float = 10.0
@export var map_edge_padding: float = 50.0  # distance from viewport edges

# Dash properties
@export var dash_distance: float = 400.0
@export var dash_duration: float = 1.0

# =========================================================
# INTERNAL STATE
# =========================================================
var target_position: Vector2
var stopping: bool = false
var stop_timer: float = 0.0
# Spell casting state
var is_casting_spell: bool = false
var cast_timer: float = 0.0
@export var cast_delay: float = 0.4
var cast_target: Vector2

var movement_locked: bool = false


# Dash state
var is_dashing: bool = false
var dash_direction: Vector2 = Vector2.ZERO
var dash_timer: float = 0.0
var dash_start_pos: Vector2 = Vector2.ZERO

# Root/freeze state after dash
var dash_rooting: bool = false
var root_timer: float = 0.0
var root_duration: float = 0.0

func dash_and_stop(freeze_time: float = 1.0) -> void:
	# Start the dash using the existing dash() function
	dash()  # Uses default facing direction, distance, and duration
	
	# Prepare the root/freeze timer
	dash_rooting = false  # Will be set true after dash finishes
	root_timer = 0.0
	root_duration = freeze_time

# =========================================================
# READY
# =========================================================
func _ready():
	pick_new_target()
	show()

# =========================================================
# PHYSICS PROCESS
# =========================================================
func _physics_process(delta):
	if movement_locked:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if is_casting_spell:
		cast_timer += delta
		velocity = Vector2.ZERO  # hard stop

		if cast_timer >= cast_delay:
			# Cast the spell
			floating_weapon.fourth_attack(cast_target)
			is_casting_spell = false
			stopping = true  # remain stopped until attack finishes

		return

	if is_dashing:
		# Let the normal dash logic run (your existing dash handles movement)
		dash_timer += delta
		var dash_speed = dash_distance / dash_duration
		velocity = dash_direction * dash_speed
		move_and_slide()

		if is_on_wall() or dash_timer >= dash_duration:
			is_dashing = false
			velocity = Vector2.ZERO
			dash_rooting = true  # start freeze
			root_timer = 0.0

	elif dash_rooting:
		# Freeze character
		root_timer += delta
		velocity = Vector2.ZERO

		if root_timer >= root_duration:
			dash_rooting = false
			pick_new_target()  # resume normal behavior

	else:
		# Normal movement
		if stopping:
			if not bullet_hell_spawner.bullet_hell_is_on:
				stopping = false
				pick_new_target()
		else:
			move_towards_target(delta)

# =========================================================
# MOVEMENT / TARGETING
# =========================================================
func get_facing_direction() -> Vector2:
	if stopping:
		# Face target when attacking
		return (target_position - global_position).normalized()
	elif velocity.length() > 0:
		return velocity.normalized()
	else:
		return Vector2.RIGHT

func pick_new_target():
	var rect = get_viewport().get_visible_rect()
	target_position = Vector2(
		randf_range(rect.position.x + map_edge_padding, rect.position.x + rect.size.x - map_edge_padding),
		randf_range(rect.position.y + map_edge_padding, rect.position.y + rect.size.y - map_edge_padding)
	)

func move_towards_target(delta):
	var dir = (target_position - global_position).normalized()
	velocity = dir * speed
	move_and_slide()
	if global_position.distance_to(target_position) < target_distance_threshold:
		stop_and_attack()

# =========================================================
# STOP AND ATTACK
# =========================================================
func stop_and_attack():
	stopping = true
	velocity = Vector2.ZERO

	var attack := randi() % 4
	var dir := get_facing_direction()
	
	var targ :=  Vector2(200, 200)
	match attack:
		0:
			floating_weapon.first_attack()
		1:
			floating_weapon.second_attack(dir)
		2:
			floating_weapon.third_attack(1.0, dir)
		3:
			floating_weapon.fourth_attack(targ)
			

	print("attack:", attack)


# =========================================================
# PROJECTILE ATTACK
# =========================================================
func throw_sword_slash():
	if not projectile_scene:
		return

	var sword_slash = projectile_scene.instantiate()
	sword_slash.top_level = true
	sword_slash.SPEED = 600
	sword_slash.direction = (target_position - global_position).normalized()
	get_tree().current_scene.add_child(sword_slash)
	sword_slash.global_position = global_position

# =========================================================
# DASH FUNCTION
# =========================================================
func dash(direction: Vector2 = Vector2.ZERO, distance: float = -1.0, duration: float = -1.0) -> void:
	if is_dashing:
		return

	if direction == Vector2.ZERO:
		direction = get_facing_direction()

	is_dashing = true
	dash_direction = direction.normalized()
	dash_timer = 0.0

	# Default speed instead of distance
	dash_distance = distance if distance > 0 else 200.0
	dash_duration = duration if duration > 0 else 0.2

	velocity = Vector2.ZERO


func cast_lightning(target_pos: Vector2):
	var strike = lightning_scene.instantiate()
	strike.global_position = target_pos
	get_tree().current_scene.add_child(strike)

# =============================
# EXTERNAL CONTROL (BY WEAPON)
# =============================
func lock_movement():
	stopping = true
	movement_locked = true   # ADD THIS FLAG
	velocity = Vector2.ZERO

func unlock_movement():
	stopping = false
	movement_locked = false
	pick_new_target()
