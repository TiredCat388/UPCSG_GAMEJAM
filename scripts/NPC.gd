extends CharacterBody2D

# 1. Drag your DialogueSystem node from the Scene Tree into this variable in the Inspector!
@export var dialogue_system: CanvasLayer 
@export var dialogue_id: int = 1  # Which conversation to play (Scene 1)

@onready var label = $Label  # The "E" text
var player_in_range = false

func _ready():
	# Connect the signals from the ChatZone
	var zone = $ChatZone
	zone.body_entered.connect(_on_body_entered)
	zone.body_exited.connect(_on_body_exited)
	label.hide() # Make sure label is hidden at start

func _on_body_entered(body):
	if body.name == "Player":  # Make sure it's the player, not a wall
		player_in_range = true
		label.show() # Show "E"

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
