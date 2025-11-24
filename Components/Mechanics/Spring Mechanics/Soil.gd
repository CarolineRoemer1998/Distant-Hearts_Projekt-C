extends Node2D


func _on_seed_entered(flower_seed: FlowerSeed) -> void:
	flower_seed.grow()
