extends Node
signal finished

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var cutscene_camera: Camera2D = $Camera2D

func _ready():
	cutscene_camera.enabled = true
	cutscene_camera.make_current()
	animation_player.play("intro")

func pause_for_dialogue(dialogue_id: int = 1):
	animation_player.pause()
	
	DialogueSystem.start_dialogue(dialogue_id)
	DialogueSystem.dialogue_finished.connect(_resume_animation, CONNECT_ONE_SHOT)

func _resume_animation():
	animation_player.play()

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "intro":
		emit_signal("finished")
