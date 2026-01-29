extends CharacterBody2D
class_name InteractableBase

@export var interaction_prompt: String = "Interact"

var player_in_range: bool = false

@onready var interaction_area: Area2D = $InteractionArea

func _ready() -> void:
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		if body.has_method("set_interactable"):
			body.set_interactable(self)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		if body.has_method("clear_interactable"):
			body.clear_interactable(self)

func interact(player: Node) -> void:
	# Override this in child scenes
	print("Interacted with base interactable")
