extends Node2D

class_name Flower

func _ready() -> void:
	Signals.flower_grows.emit(self)
