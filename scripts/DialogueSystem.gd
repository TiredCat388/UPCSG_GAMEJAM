extends CanvasLayer

# --- ADD THIS LINE ---
signal dialogue_finished

# --- CONFIGURATION ---
const JSON_PATH = "res://resources/json/dialogue_data.json"

# --- UI REFERENCES ---
@onready var dialogue_panel = $Control/DialoguePanel
@onready var name_label = $Control/DialoguePanel/MarginContainer/MainHBox/TextVBox/NameLabel
@onready var text_label = $Control/DialoguePanel/MarginContainer/MainHBox/TextVBox/DialogueText
@onready var portrait_rect = $Control/DialoguePanel/MarginContainer/MainHBox/PortraitRect

const SPEAKER_PORTRAITS := {
	"The Hero": "res://assets/portraits/hero.png",
	"Traumatized Goblin": "res://assets/portraits/goblin_trauma.png",
	"Armor Smith": "res://assets/portraits/armor_smith.png",
	"Merchant": "res://assets/portraits/merchant.png",
	"Monkey": "res://assets/portraits/monkey.png",
	"????": "res://assets/portraits/hero.png"
}

# --- STATE VARIABLES ---
var dialogue_lookup = {} 
var current_queue = []
var is_typing = false
var is_active = false
var on_cooldown = false 

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS 
	
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
			
			# --- NEW: DISABLE MOVEMENT WITHOUT FREEZING GAME ---
			# This tells any node in the "player" group to stop running its physics code.
			# Animations and NPCs will keep moving!
			get_tree().call_group("player", "set_physics_process", false)
			
			is_active = true
			dialogue_panel.show()
			show_next_line()

func show_next_line():
	if current_queue.is_empty():
		end_dialogue() 
		emit_signal("dialogue_finished")
		return

	var line = current_queue.pop_front()
	
	name_label.text = line["speaker"] 
	text_label.text = line["text"]
	
	var speaker = line["speaker"]

	if speaker in SPEAKER_PORTRAITS:
		portrait_rect.texture = load(SPEAKER_PORTRAITS[speaker])
		portrait_rect.show()
	else:
		portrait_rect.hide()
	
	# Typewriter Animation
	text_label.visible_ratio = 0.0
	is_typing = true
	
	var tween = create_tween()
	var duration = line["text"].length() * 0.03
	tween.tween_property(text_label, "visible_ratio", 1.0, duration)
	tween.finished.connect(func(): is_typing = false)

func end_dialogue():
	dialogue_panel.hide()
	is_active = false
	
	# --- NEW: RE-ENABLE MOVEMENT ---
	get_tree().call_group("player", "set_physics_process", true)
	
	on_cooldown = true
	await get_tree().create_timer(0.5).timeout
	on_cooldown = false

func _input(event):
	if not is_active: return
	
	# --- NEW: ONLY LISTEN FOR E OR SPACE ---
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_E or event.keycode == KEY_SPACE:
			
			get_viewport().set_input_as_handled()
			
			if is_typing:
				# SPEED UP: Kill the animation and show full text instantly
				var tweens = get_tree().get_processed_tweens()
				for t in tweens: t.kill()
				text_label.visible_ratio = 1.0
				is_typing = false
			else:
				# NEXT LINE
				show_next_line()
