extends Node2D

@onready var gameplay_root = $GameplayRoot
@onready var player_camera = $GameplayRoot/Player/Camera2D
var intro_cutscene := preload("res://scenes/cutscene/Floor1Intro.tscn")

func _ready():
	gameplay_root.process_mode = Node.PROCESS_MODE_DISABLED
	gameplay_root.visible = false
	CutsceneManager.play_cutscene(intro_cutscene, gameplay_root, player_camera)
	CutsceneManager.cutscene_finished.connect(_on_intro_finished, CONNECT_ONE_SHOT)
	
func _on_intro_finished():
	gameplay_root.visible = true
	DialogueSystem.start_dialogue(2)
