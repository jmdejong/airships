class_name SoundMessage
extends RichTextLabel

var fade_start: float = 5
var fade_duration: float = 2
var is_fading := false

static func create(text_) -> SoundMessage:
	var sm: SoundMessage = preload("res://scenes/ui/sound_message.tscn").instantiate()
	sm.text = text_
	return sm

func _ready() -> void:
	await get_tree().create_timer(fade_start).timeout
	start_fade()

func start_fade():
	if is_fading:
		return
	is_fading = true
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, fade_duration)
	await tween.finished
	queue_free()
