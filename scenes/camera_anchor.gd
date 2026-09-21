@tool
extends Marker2D

@export var rect_size: Vector2 = Vector2(1920, 1080)
const normal_color = Color(0,0,1,0.5)
const selected_color = Color(1,0,0)

func _ready() -> void:
	if Engine.is_editor_hint():
		EditorInterface.get_selection().selection_changed.connect(queue_redraw)

func _draw() -> void:
	if not Engine.is_editor_hint(): return
	global_rotation = 0
	var is_selected := self in EditorInterface.get_selection().get_selected_nodes()
	var color := selected_color if is_selected else normal_color
	draw_rect(Rect2(-rect_size/2, rect_size), color, false, 8.0)
