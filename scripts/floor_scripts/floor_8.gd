extends Node2D

@onready var boss = $GameplayRoot/MainCharacter
@export var floor_number: int = 6

func _ready() -> void:
	GameManager.current_floor = floor_number
	GameManager.can_block = true
	print(GameManager.current_floor)

func _on_boss_spawner_body_entered(body: Node2D) -> void:
	if !body.is_in_group("player"):
		return
	
	boss.process_mode = Node.PROCESS_MODE_INHERIT
	DialogueSystem.start_dialogue(7)
	
	
