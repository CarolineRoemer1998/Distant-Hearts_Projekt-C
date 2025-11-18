extends Node2D

class_name BeeSwarm


func _on_bee_area_body_entered(player: Node2D) -> void:
	if player is Player and player.currently_possessed_creature != null:
		player.direction = -player.direction
		player.set_is_moving(true)
		player.step_timer.start(Constants.TIMER_STEP*2)
		StateSaver.remove_last_state()
		StateSaver.remove_last_state()
