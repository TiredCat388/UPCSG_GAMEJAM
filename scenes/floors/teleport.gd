extends Area2D

@export_file("*.tscn") var next_level_file

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		# Check if a level file is assigned
		if next_level_file:
			# This function unloads the current level and loads the new one
			get_tree().change_scene_to_file(next_level_file)
		else:
			print("ERROR: No level file assigned to this door!")
