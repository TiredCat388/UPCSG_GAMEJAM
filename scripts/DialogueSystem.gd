extends CanvasLayer

# --- CONFIGURATION ---
const JSON_PATH = "res://resources/json/dialogue_data.json"

# --- UI REFERENCES ---
@onready var dialogue_panel = $Control/DialoguePanel
@onready var name_label = $Control/DialoguePanel/MarginContainer/MainHBox/TextVBox/NameLabel
@onready var text_label = $Control/DialoguePanel/MarginContainer/MainHBox/TextVBox/DialogueText
@onready var portrait_rect = $Control/DialoguePanel/MarginContainer/MainHBox/PortraitRect

# --- STATE VARIABLES ---
var dialogue_lookup = {} 
var current_queue = []
var is_typing = false
var is_active = false
var on_cooldown = false 

func _ready():
	# Allow this to run always (though we aren't pausing anymore, this is safe to keep)
	process_mode = Node.PROCESS_MODE_ALWAYS 
	
	# Force UI Visibility
	show() 
	if has_node("Control"):
		$Control.show()
	
	dialogue_panel.hide()
	load_json()

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
	else:
		print("JSON Parse Error: ", json.get_error_message())

func start_dialogue(id):
	if on_cooldown: return
	
	var id_str = str(id)
	if id_str in dialogue_lookup:
		var scene_data = dialogue_lookup[id_str]
		if scene_data.has("dialogue"):
			current_queue = scene_data["dialogue"].duplicate()
			
			# --- 1. DISABLE MOVEMENT (Without Freezing Screen) ---
			# This finds the "player" group and turns off their _physics_process function.
			# Animations still play, but WASD movement stops.
			get_tree().call_group("player", "set_physics_process", false)
			
			is_active = true
			dialogue_panel.show()
			show_next_line()

func show_next_line():
	if current_queue.is_empty():
		end_dialogue()
		return

	var line = current_queue.pop_front()
	name_label.text = line["speaker"] 
	text_label.text = line["text"]
	
	if line["speaker"] == "Narrator" or line["speaker"] == "System":
		portrait_rect.hide()
	else:
		portrait_rect.show()
	
	text_label.visible_ratio = 0.0
	# Create the typing tween
	is_typing = true
	var tween = create_tween()
	var duration = line["text"].length() * 0.03
	tween.tween_property(text_label, "visible_ratio", 1.0, duration)
	tween.finished.connect(func(): is_typing = false)

func end_dialogue():
	dialogue_panel.hide()
	is_active = false
	
	# --- 2. RE-ENABLE MOVEMENT ---
	get_tree().call_group("player", "set_physics_process", true)
	
	on_cooldown = true
	await get_tree().create_timer(0.5).timeout
	on_cooldown = false

func _input(event):
	if not is_active: return
	
	# --- 3. HANDLE SPEED UP (E or SPACE) ---
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_E or event.keycode == KEY_SPACE:
			
			get_viewport().set_input_as_handled()
			
			if is_typing:
				# INSTANTLY FINISH TYPING
				# We kill the slow animation and set text to 100% visible
				var tweens = get_tree().get_processed_tweens()
				for t in tweens: t.kill()
				text_label.visible_ratio = 1.0
				is_typing = false
			else:
				# GO TO NEXT LINE
				show_next_line()
