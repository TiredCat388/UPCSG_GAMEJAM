extends CanvasLayer

# --- CONFIGURATION ---
const JSON_PATH = "res://assets/json/dialogue_data.json"

# --- UI REFERENCES ---
@onready var dialogue_panel = $Control/DialoguePanel
@onready var name_label = $Control/DialoguePanel/MarginContainer/MainHBox/TextVBox/NameLabel
@onready var text_label = $Control/DialoguePanel/MarginContainer/MainHBox/TextVBox/DialogueText
@onready var portrait_rect = $Control/DialoguePanel/MarginContainer/MainHBox/PortraitRect

# --- STATE VARIABLES ---
var dialogue_lookup = {} # We will convert the JSON array into this dictionary
var current_queue = []
var is_typing = false

func _ready():
	# 1. Hide the box initially
	dialogue_panel.hide()
	
	# 2. Load the database
	load_json()
	
	# --- TEST ZONE ---
	# We wait 1 second, then test Scene 1 (Narration)
	await get_tree().create_timer(1.0).timeout
	start_dialogue(1) 

func load_json():
	if not FileAccess.file_exists(JSON_PATH):
		print("ERROR: JSON file not found at " + JSON_PATH)
		return
		
	var file = FileAccess.open(JSON_PATH, FileAccess.READ)
	var content = file.get_as_text()
	var json = JSON.new()
	
	if json.parse(content) == OK:
		var data_array = json.data
		
		for scene in data_array:
			var id = str(int(scene["scene_id"]))
			dialogue_lookup[id] = scene
			
		print("JSON Loaded Successfully! Scenes found: ", dialogue_lookup.keys())
	else:
		print("JSON Parse Error: ", json.get_error_message())

func start_dialogue(id):
	var id_str = str(id)
	
	if id_str in dialogue_lookup:
		var scene_data = dialogue_lookup[id_str]
		
		if scene_data.has("dialogue"):
			current_queue = scene_data["dialogue"].duplicate()
			dialogue_panel.show()
			show_next_line()
		else:
			print("Error: Scene ID " + id_str + " has no 'dialogue' array.")
	else:
		print("Error: Scene ID '" + id_str + "' not found in data.")

func show_next_line():
	if current_queue.is_empty():
		dialogue_panel.hide()
		return

	var line = current_queue.pop_front()
	
	name_label.text = line["speaker"] 
	text_label.text = line["text"]
	
	if line["speaker"] == "Narrator" or line["speaker"] == "System":
		portrait_rect.hide()
	else:
		portrait_rect.show()
	
	# Typewriter Animation
	text_label.visible_ratio = 0.0
	is_typing = true
	
	var tween = create_tween()
	var duration = line["text"].length() * 0.03
	tween.tween_property(text_label, "visible_ratio", 1.0, duration)
	tween.finished.connect(func(): is_typing = false)

func _input(event):
	if not dialogue_panel.visible: return
	
	# Check for Spacebar, Enter, OR Left Mouse Click
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		if is_typing:
			# If typing, skip to the end instantly
			var tweens = get_tree().get_processed_tweens()
			for t in tweens: t.kill()
			text_label.visible_ratio = 1.0
			is_typing = false
		else:
			# If done typing, show next line
			show_next_line()
