extends AnimatedSprite2D

@onready var parent = get_parent()
@onready var health_bar = parent.get_node('HealthBar')
@onready var timer = $Timer

func stun(time, armor_pierce := 0.0):
	var new_time = time*(armor_pierce if health_bar.armor > 0 else 1.0)
	if timer.time_left < new_time: 
		timer.wait_time = new_time
		parent.stunned = true
		show()
		timer.start()

func _on_timer_timeout() -> void:
	parent.stunned = false
	hide()
