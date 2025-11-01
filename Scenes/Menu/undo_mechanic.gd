extends Node



func _on_undo_timer_init_timeout() -> void:
	Signals.undo_timer_init_timeout.emit()


func _on_undo_timer_continious_timeout() -> void:
	Signals.undo_timer_continuous_timeout.emit()
