extends CharacterBody2D


# Fight types
enum FightType {BULLET_HELL, SHIELD, PARRY}
@export var fight_type: FightType = FightType.BULLET_HELL


# References to other nodes
var player: Node2D = null
var warning: Node2D = null
@onready var bullet_hell_spawner := $BulletHellSpawner 
@onready var shield := $Shield


# General variables
@export var speed: float = 100.0
@export var health: float = 100.0
var dead: bool = false


# Stun variables
var stunned: bool = false
@export var stun_time: float = 1.5


#region Shield bash
@export var shield_speed: float = 75.0
@export var bash_speed: float = 600.0
@export var bash_acceleration: float = 1800.0
@export var bash_duration: float = 0.25
@export var bash_cooldown: float = 1.0
@export var bash_trigger_distance: float = 120.0


var _bash_start_position: Vector2 = Vector2.ZERO
var is_bashing: bool = false
var bash_timer: float = 0.0
var bash_cooldown_timer: float = 0.0
var _bash_dir: Vector2 = Vector2.ZERO
var _current_bash_speed: float = 0.0
var bash_damage: float = 20.0


func start_shield_bash():
	if is_bashing or bash_cooldown_timer > 0.0:
		return
	is_bashing = true
	bash_timer = 0.0
	_bash_dir = (player.global_position - global_position).normalized()
	_current_bash_speed = min(bash_speed * 0.5, bash_speed)
	velocity = _bash_dir * _current_bash_speed
	_bash_start_position = global_position


func update_shield_bash(delta):
	bash_timer += delta
	_current_bash_speed = min(bash_speed, _current_bash_speed + bash_acceleration * delta)
	velocity = _bash_dir * _current_bash_speed
	move_and_slide()
	
	var seen := []
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collision and not seen.has(collider):
			seen.append(collider)
			if collider.is_in_group("player"):
				end_shield_bash(collider)
			elif collider.is_in_group("obstacle"):
				on_obstacle_collision(collider)
				collider.queue_free()
			
	if bash_timer >= bash_duration:
		end_shield_bash(null)
		return


func end_shield_bash(collider):
	is_bashing = false
	bash_cooldown_timer = bash_cooldown

	if collider and collider.is_in_group("player"):
		collider.take_damage(bash_damage)  
#endregion


#region Bullet hell
@export var bullet_hell_speed: float = 100.0
@export var stop_time_min: float = 1.0
@export var stop_time_max: float = 3.0
@export var target_distance_threshold: float = 10.0
@export var map_edge_padding: float = 50.0
var target_position: Vector2
var stopping: bool = false
var stop_timer: float = 0.0


func pick_new_target():
	var rect = get_viewport().get_visible_rect()
	target_position = Vector2(
		randf_range(rect.position.x + map_edge_padding, rect.position.x + rect.size.x - map_edge_padding),
		randf_range(rect.position.y + map_edge_padding, rect.position.y + rect.size.y - map_edge_padding)
	)


func move_towards_target_random(_delta):
	var dir = (target_position - global_position).normalized()
	velocity = dir * speed
	move_and_slide()
	if global_position.distance_to(target_position) < target_distance_threshold:
		stop_and_attack()


func stop_and_attack():
	stopping = true
	velocity = Vector2.ZERO
	move_and_slide()
	bullet_hell_spawner.bullet_hell()
#endregion


#region Timed parry
@export var parry_stage_speed: float = 130.0
@export var charge_speed: float = 1200.0
@export var charge_acceleration: float = 2000.0
@export var charge_duration: float = 0.5
@export var charge_cooldown: float = 3.0
@export var charge_trigger_distance: float = 200.0
@export var pause_duration: float = 0.5


var _charge_start_position: Vector2 = Vector2.ZERO
var is_charging: bool = false
var charge_timer: float = 0.0
var charge_cooldown_timer: float = 0.0
var _charge_dir: Vector2 = Vector2.ZERO
var _current_charge_speed: float = 0.0
var charge_damage: float = 30.0
var paused: bool = false


func start_charge():
	if is_charging or charge_cooldown_timer > 0.0:
		return
	is_charging = true
	charge_timer = 0.0
	_charge_dir = (player.global_position - global_position).normalized()
	_current_charge_speed = min(charge_speed * 0.5, charge_speed)
	velocity = _charge_dir * _current_charge_speed
	_charge_start_position = global_position


func update_charge(delta):
	charge_timer += delta
	_current_charge_speed = min(charge_speed, _current_charge_speed + charge_acceleration * delta)
	velocity = _charge_dir * _current_charge_speed
	move_and_slide()
	
	var seen := []
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collision and not seen.has(collider):
			seen.append(collider)
			if collider.is_in_group("player"):
				end_charge(collider)
			elif collider.is_in_group("obstacle"):
				on_obstacle_collision(collider)
				collider.queue_free()
			
	if charge_timer >= charge_duration:
		end_charge(null)
		return


func end_charge(collider):
	is_charging = false
	charge_cooldown_timer = charge_cooldown

	if collider and collider.is_in_group("player"):
		var res: String = collider.take_damage(charge_damage)
		if res == "parried":
			stunned = true
			velocity = Vector2.ZERO
			await get_tree().create_timer(stun_time).timeout
			stunned = false


func pause():
	paused = true
	velocity = Vector2.ZERO
	await get_tree().create_timer(pause_duration).timeout
	paused = false
#endregion


func _ready():
	# Find the player to follow
	if get_tree().get_first_node_in_group("player"):
		player = get_tree().get_first_node_in_group("player")

	if get_tree().get_first_node_in_group("warning"):
		warning = get_tree().get_first_node_in_group("warning")

		shield.hide()
		warning.hide()

	match fight_type:
		FightType.BULLET_HELL:
			speed = bullet_hell_speed
			pick_new_target() 
			show()
			
		FightType.SHIELD:
			speed = shield_speed
			assert(player, "Cannot find Player! Make sure Player is in the 'player' group.")
			shield.show()

		FightType.PARRY:
			speed = parry_stage_speed


func _physics_process(delta):
	if dead or stunned:
		return

	match fight_type:
		FightType.BULLET_HELL:
			if stopping:
				if not bullet_hell_spawner.bullet_hell_is_on:
					stopping = false
					pick_new_target()
			else:
				move_towards_target_random(delta)

		FightType.SHIELD:
			if not player: 
				return 

			if bash_cooldown_timer > 0.0:
				bash_cooldown_timer = max(0.0, bash_cooldown_timer - delta)

			if is_bashing: 
				update_shield_bash(delta)
			else:
				if (
					bash_cooldown_timer <= 0.0 
					and global_position.distance_to(player.global_position) <= bash_trigger_distance 
					and not player.dead
				):
					start_shield_bash()
				else:
					var dir = (player.global_position - global_position).normalized()

					if global_position.distance_to(player.global_position) < bash_trigger_distance:
						dir = (global_position - player.global_position).normalized()

					velocity = dir * speed
					move_and_slide()
					check_slide_collisions()

		FightType.PARRY:
			if not player or not warning: 
				print( "No player or warning found" )
				return 

			if paused: 
				return

			if charge_cooldown_timer > 0.0:
				charge_cooldown_timer = max(0.0, charge_cooldown_timer - delta)

			if is_charging: 
				update_charge(delta)
			else:
				if (
					charge_cooldown_timer <= 0.0 
					and global_position.distance_to(player.global_position) <= charge_trigger_distance 
					and not player.dead
				):
					warning.show()
					await pause()
					warning.hide()
					start_charge()
				else:
					var dir = (player.global_position - global_position).normalized()

					if global_position.distance_to(player.global_position) < charge_trigger_distance:
						dir = (global_position - player.global_position).normalized()

					velocity = dir * speed
					move_and_slide()
					check_slide_collisions()


#region Collision methods
func check_slide_collisions():
	var seen := []
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collision and collider.is_in_group("obstacle") and not seen.has(collider):
			seen.append(collider)
			collider.queue_free()
			on_obstacle_collision(collider)


func on_obstacle_collision(collider):
	stunned = true
	is_bashing = false

	bash_cooldown_timer = bash_cooldown
	velocity = Vector2.ZERO

	shield.hide()

	take_damage(collider.inflicted_damage)
	await get_tree().create_timer(stun_time).timeout
	stunned = false

	shield.show()
#endregion


func take_damage(amount: float):
	health -= amount
	print("Main Character Health: %d" % health)
	if health <= 0:
		print("Main Character defeated!")
		dead = true
