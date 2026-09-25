extends AnimatedSprite2D

@onready var parent = get_parent()
@onready var health_bar = parent.get_node('HealthBar')
@onready var timer = $Timer

func stun(time):
	if timer.time_left < time: 
		timer.wait_time = time
		parent.stunned = true
		show()
		timer.start()

func _on_timer_timeout() -> void:
	parent.stunned = false
	hide()
