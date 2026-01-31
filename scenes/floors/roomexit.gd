extends Area2D

@export var floor_number: int = 1   # Set this per floor in the Inspector

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	var next_floor := floor_number + 1
	var path := "res://scenes/floors/Floor%d.tscn" % next_floor
	get_tree().change_scene_to_file(path)
