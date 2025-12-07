extends Node2D

class_name Soil

var current_flower : FlowerSeed = null

func _on_body_entered(flower_seed: FlowerSeed) -> void:
	if flower_seed.current_state == flower_seed.STATE.Seed and current_flower == null:
		flower_seed.grow()
		current_flower = flower_seed

func _on_body_exited(body: Node2D) -> void:
	if Helper.get_collision_on_tile(global_position, (1 << Constants.LAYER_BIT_FLOWER), get_world_2d()).is_empty():
		current_flower = null
