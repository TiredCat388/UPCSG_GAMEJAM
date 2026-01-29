extends CharacterBody2D

# Phase switch
enum FightType {BULLET_HELL, SHIELD}
@export var fight_type: FightType = FightType.BULLET_HELL

@onready var bullet_hell_spawner := $BulletHellSpawner 
@onready var shield: Node2D = $Shield

var player: Node2D = null

@export var speed: float = 100.0
var health: float = 100.0
var dead: bool = false

var player_health: float = 100.0

var stunned: bool = false
@export var stun_time: float = 1

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

@export var stop_time_min: float = 1.0
@export var stop_time_max: float = 3.0
@export var target_distance_threshold: float = 10.0
@export var map_edge_padding: float = 50.0
var target_position: Vector2
var stopping: bool = false
var stop_timer: float = 0.0


func _ready():
	# Find the player to follow
	if get_tree().get_first_node_in_group("player"):
		player = get_tree().get_first_node_in_group("player")

	match fight_type:
		FightType.BULLET_HELL:
			shield.hide() # Hide shield
			shield.get_node("CollisionShape2D").disabled = true # Disable shield collision
			pick_new_target() 
			show()
			
		FightType.SHIELD:
			speed = 75
			assert(player, "ERROR: Shield Boss cannot find Player! Make sure Player is in the 'player' group.")
			shield.show()
			shield.get_node("CollisionShape2D").disabled = true

func _physics_process(delta):
	match fight_type:
		FightType.BULLET_HELL:
			if stopping:
				if not bullet_hell_spawner.bullet_hell_is_on:
					stopping = false
					pick_new_target()
			else:
				move_towards_target_random(delta)

		FightType.SHIELD:
			if not player: return 

			if bash_cooldown_timer > 0.0:
				bash_cooldown_timer = max(0.0, bash_cooldown_timer - delta)

			if is_bashing: 
				_update_shield_bash(delta)
			elif not dead and not stunned:
				
				if bash_cooldown_timer <= 0.0 and global_position.distance_to(player.global_position) > bash_trigger_distance - 5 and global_position.distance_to(player.global_position) < bash_trigger_distance + 5:
					start_shield_bash()
				else:
					var dir = (player.global_position - global_position).normalized()

					if global_position.distance_to(player.global_position) < bash_trigger_distance:
						dir = (global_position - player.global_position).normalized()

					velocity = dir * speed
					move_and_slide()
					check_slide_collisions()

func pick_new_target():
	var rect = get_viewport().get_visible_rect()
	target_position = Vector2(
		randf_range(rect.position.x + map_edge_padding, rect.position.x + rect.size.x - map_edge_padding),
		randf_range(rect.position.y + map_edge_padding, rect.position.y + rect.size.y - map_edge_padding)
	)

func move_towards_target_random(delta):
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

func check_slide_collisions():
	var seen := []
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collision and collider.is_in_group("obstacle") and not seen.has(collider):
			seen.append(collider)
			collider.queue_free()
			on_collision()

func on_collision():
	stunned = true
	is_bashing = false
	bash_cooldown_timer = bash_cooldown
	velocity = Vector2.ZERO
	shield.hide()
	
	health -= 40
	print("Main Character Health: %d" % health)
	if health <= 0:
		print("Main Character defeated!")
		dead = true

	await get_tree().create_timer(stun_time).timeout
	stunned = false
	shield.show()

func start_shield_bash():
	if is_bashing or bash_cooldown_timer > 0.0:
		return
	is_bashing = true
	bash_timer = 0.0
	_bash_dir = (player.global_position - global_position).normalized()
	_current_bash_speed = min(bash_speed * 0.5, bash_speed)
	velocity = _bash_dir * _current_bash_speed
	_bash_start_position = global_position

func _update_shield_bash(delta):
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
				_end_bash(collider)
			elif collider.is_in_group("obstacle"):
				on_collision()
				collider.queue_free()
			
	if bash_timer >= bash_duration:
		_end_bash(null)
		return

func _end_bash(hit_collider):
	is_bashing = false
	bash_cooldown_timer = bash_cooldown

	if hit_collider.is_in_group("player"):
		player_health -= 10
		print("Player Health: %d" % player_health)
		if player_health <= 0:
			print("Player defeated!")

		
