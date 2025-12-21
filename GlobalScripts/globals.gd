extends Node

var current_level := 1

var fullscreen := true

var is_undo_timer_buffer_running := false

var is_level_finished := false

var is_teleporting := false


func _ready() -> void:
	Signals.level_loaded.connect(reset_global_level_variables)

func reset_global_level_variables(_season: Constants.SEASON):
	is_teleporting = false
