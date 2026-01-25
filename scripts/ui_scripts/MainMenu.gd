extends Control


func _on_settings_button_pressed() -> void:
	get_tree().change_scene_to_packed(preload("res://scenes/ui/Settings.tscn"))
