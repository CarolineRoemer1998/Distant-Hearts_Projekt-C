extends Node2D

class_name Soil

func _on_seed_entered(flower_seed: FlowerSeed) -> void:
	if flower_seed.current_state == flower_seed.STATE.Seed:
		flower_seed.grow()
