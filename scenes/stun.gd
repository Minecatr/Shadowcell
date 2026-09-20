extends AnimatedSprite2D

@onready var parent = get_parent()

func _on_timer_timeout() -> void:
	parent.stunned = false
	hide()
