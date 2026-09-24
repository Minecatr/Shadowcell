extends Button

func _on_pressed() -> void:
	GLOBALS.world.press(get_index())
