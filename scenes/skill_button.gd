extends Button

@onready var world := get_tree().root.get_node('world')

func _on_pressed() -> void:
	world.press(get_index())
