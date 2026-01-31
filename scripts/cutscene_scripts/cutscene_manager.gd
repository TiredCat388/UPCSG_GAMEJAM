extends Node

signal cutscene_started
signal cutscene_finished

var active_cutscene: Node = null
var gameplay_root: Node = null
var gameplay_camera: Camera2D = null
var is_playing := false

func play_cutscene(cutscene_scene: PackedScene, gameplay_node: Node, player_camera: Camera2D) -> void:
	if is_playing:
		push_warning("Cutscene already playing")
		return

	is_playing = true
	gameplay_root = gameplay_node
	gameplay_camera = player_camera

	emit_signal("cutscene_started")

	_pause_gameplay()

	active_cutscene = cutscene_scene.instantiate()
	get_tree().current_scene.add_child(active_cutscene)

	# Take camera control
	if active_cutscene.has_node("Camera2D"):
		active_cutscene.get_node("Camera2D").make_current()

	if active_cutscene.has_signal("finished"):
		active_cutscene.finished.connect(_on_cutscene_finished)
	else:
		push_error("Cutscene scene must have a 'finished' signal")


func _pause_gameplay():
	gameplay_root.process_mode = Node.PROCESS_MODE_DISABLED


func _resume_gameplay():
	gameplay_root.process_mode = Node.PROCESS_MODE_INHERIT


func _on_cutscene_finished():
	if active_cutscene:
		active_cutscene.queue_free()
		active_cutscene = null

	# Return camera control to player
	if gameplay_camera:
		gameplay_camera.make_current()

	_resume_gameplay()
	is_playing = false
	emit_signal("cutscene_finished")
