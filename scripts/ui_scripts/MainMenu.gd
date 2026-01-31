extends CanvasLayer


func _on_settings_button_pressed() -> void:
	get_tree().change_scene_to_packed(preload("res://scenes/ui/Settings.tscn"))


func _on_quit_button_pressed() -> void:
	get_tree().quit()
	
	

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/floors/Floor1.tscn")
