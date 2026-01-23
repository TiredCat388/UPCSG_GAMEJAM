extends Control

var user_prefs: UserPreferences

@onready var ResolutionButton = $SttngsBttnVBoxContainer/ResolutionHBoxContainer/ResolutionButton
@onready var sfx_slider = $SttngsBttnVBoxContainer/SFXVolumeHBoxContainer/SFXVolumeSlider
@onready var music_slider = $SttngsBttnVBoxContainer/MusicVolumeHBoxContainer/MusicVolumeSlider

func _ready() -> void:
	user_prefs = UserPreferences.load_or_create()
	initial_button_text()
	ResolutionButton.get_popup().id_pressed.connect(_change_resolution)
	if sfx_slider:
		sfx_slider.value = user_prefs.sfx_audio_level
	if music_slider:
		music_slider.value = user_prefs.music_audio_level
	if ResolutionButton:
		set_resolution(user_prefs.window_width,user_prefs.window_height)

#region Resolution
func initial_button_text() -> void:
	var window_width := DisplayServer.window_get_size().x
	var window_height := DisplayServer.window_get_size().y
	ResolutionButton.text = str(window_width) + "x" + str(window_height)

func _change_resolution(id: int) -> void:
	match id:
		0:
			set_resolution(720,480)
		1: 
			set_resolution(1280,720)
		2:
			set_resolution(1920,1080)
	
			
func set_resolution(width: int, height: int) -> void:
	DisplayServer.window_set_size(Vector2i(width, height))
	ResolutionButton.text = "%d x %d" % [width, height]
	if user_prefs:
		user_prefs.window_height = height
		user_prefs.window_width = width
		user_prefs.save()
#endregion

#region Audio
func _on_music_volume_slider_value_changed(value: float) -> void:
	#AudioServer.set_bus_volumedb(MUSIC_BUS_ID, linear_to_db(value))
	#AudioServer.set_bus_mute(MUSIC_BUS_ID, value < 0.05)
	if user_prefs:
		user_prefs.music_audio_level = value
		user_prefs.save()

func _on_sfx_volume_slider_value_changed(value: float) -> void:
	if user_prefs:
		user_prefs.sfx_audio_level = value
		user_prefs.save()
#endregion
