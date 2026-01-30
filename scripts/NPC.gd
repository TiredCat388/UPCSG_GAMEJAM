extends CharacterBody2D

@export var dialogue_system: CanvasLayer 
@export var dialogue_id: int = 1

@onready var label = $Label  # The "E" text
var player_in_range = false

func _ready():
	var zone = $ChatZone
	zone.body_entered.connect(_on_body_entered)
	zone.body_exited.connect(_on_body_exited)
	label.hide()

func _on_body_entered(body):
	if body.name == "Player":
		player_in_range = true
		label.show()

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false
		label.hide() # Hide "E"

func _process(_delta):
	# This checks every frame if the button was JUST pressed
	if player_in_range and Input.is_action_just_pressed("interact"):
		
		# Check if we have a system linked and the box is closed
		if dialogue_system and not dialogue_system.dialogue_panel.visible:
			dialogue_system.start_dialogue(dialogue_id)
			label.hide()
