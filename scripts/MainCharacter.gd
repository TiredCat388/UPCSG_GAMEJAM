extends CharacterBody2D

# Phase switch
enum FightType {BULLET_HELL, SHIELD}
@export var fight_type: FightType = FightType.BULLET_HELL

@onready var bullet_hell_spawner := $BulletHellSpawner 
@onready var shield: Node2D = $Shield
var player: Node2D = null
@export var speed: float = 100.0

@export var shield_proximity: float = 200
@export var shield_delay: float = 0.25 
var _player_in_proximity_timer: float = 0.0

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
			assert(player, "ERROR: Shield Boss cannot find Player! Make sure Player is in the 'player' group.")
			shield.hide()
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

			# Decide to follow or shield based on distance to player
			if player.global_position.distance_to(global_position) < shield_proximity: 
				_player_in_proximity_timer += delta
				if _player_in_proximity_timer >= shield_delay:
					velocity = Vector2.ZERO
					# move_and_slide()
					shield.show()
					shield.get_node("CollisionShape2D").disabled = false
			else:
				_player_in_proximity_timer = 0.0
				if shield.visible:
					shield.hide()
					shield.get_node("CollisionShape2D").disabled = true
				
				var dir = (player.global_position - global_position).normalized()
				velocity = dir * speed
				move_and_slide()


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
