extends Area2D


var hero: Node2D = null


@export var banana_slip_speed: float = 600.0
@export var banana_object_duration: float = 3.0


func start_expire() -> void:
	await get_tree().create_timer(banana_object_duration).timeout
	self.hide()


func _ready() -> void:
	if get_tree().get_first_node_in_group("hero"):
		hero = get_tree().get_first_node_in_group("hero")

	connect("body_entered", Callable(self, "_on_body_entered"))


func _process(_delta: float) -> void:
	pass


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("hero"):
		hero.slip()
		self.hide()
	
