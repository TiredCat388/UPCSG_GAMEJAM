extends Sprite2D


var player: Node2D = null
var hero: Node2D = null


@export var warning_distance: float = 50.0


func _ready() -> void:
	if get_tree().get_first_node_in_group("player"):
		player = get_tree().get_first_node_in_group("player")

	if get_tree().get_first_node_in_group("hero"):
		hero = get_tree().get_first_node_in_group("hero")


func _process(_delta: float) -> void:
	if not player or not hero: 
		print( "No player or hero found" )

	var dir: Vector2 = hero.global_position - player.global_position
	if dir == Vector2.ZERO:
		return

	global_position = player.global_position + dir.normalized() * warning_distance
