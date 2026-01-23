class_name UserPreferences extends Resource

const SAVE_PATH := "user://user_prefs.tres"

@export_range (0.0,1.0,0.05) var music_audio_level: float = 1.0
@export_range (0.0,1.0,0.05) var sfx_audio_level: float = 1.0
@export var window_height: int = 648
@export var window_width: int = 1152

func _init():
	resource_local_to_scene = true

func save() -> void:
	var err := ResourceSaver.save(self, SAVE_PATH)
	if err != OK:
		push_error("Failed to save user preferences: %s" % err)
	
static func load_or_create() -> UserPreferences:
	var res := load(SAVE_PATH)
	if res is UserPreferences:
		return res
	return UserPreferences.new()
