extends Node2D

@onready var flower_1: Node2D = $Flower1
@onready var flower_2: Node2D = $Flower2

var is_active := true

func _on_flower_1_entered(body: Node2D) -> void:
	if body is Player and is_active:
		Signals.teleporter_entered.emit(flower_2.global_position)
		is_active = false
		


func _on_flower_2_entered(body: Node2D) -> void:
	if body is Player and is_active:
		Signals.teleporter_entered.emit(flower_1.global_position)
		is_active = false


func _on_flower_1_exited(body: Node2D) -> void:
	if body is Player and not is_active:
		is_active = true

func _on_flower_2_exited(body: Node2D) -> void:
	if body is Player and not is_active:
		is_active = true
