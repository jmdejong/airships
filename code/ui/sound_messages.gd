extends VBoxContainer

const max_simultaneous_messages: int = 6

func hear_message(message_text: String) -> void:
	prints("heard:", message_text)
	add_child(SoundMessage.create(message_text))
	clear_overflow()

func clear_overflow() -> void:
	if get_child_count() > max_simultaneous_messages:
		for i: int in get_child_count() - max_simultaneous_messages:
			var child: SoundMessage = get_child(i)
			child.start_fade()

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("start_chat"):
		hear_message("The quick brown fox jumps over the lazy dog. Lorem ipsum dolor sit amet.")
		print(get_children())
