extends CanvasLayer

@onready var rect: ColorRect = $ColorRect
var tween: Tween = null

func fade(duration: float = 1.0) -> void:
	if tween:
		tween.kill()

	self.visible = true
	rect.modulate.a = 0.0

	tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(rect, "modulate:a", 1.0, duration * 0.5)
	tween.chain().tween_property(rect, "modulate:a", 0.0, duration * 0.5)
	tween.chain().tween_callback(Callable(self, "_on_fade_finished"))

func _on_fade_finished() -> void:
	self.visible = false
	tween = null
