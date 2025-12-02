extends Node2D

class_name WaterTile

var stone_inside : Stone = null

func _ready() -> void:
	Signals.stone_reached_target.connect(handle_stone_in_water)
	add_to_group(Constants.GROUP_NAME_WATER_TILE)

func get_info():
	return {
		"stone_inside": stone_inside
	}

func set_info(info: Dictionary):
	stone_inside = info.get("stone_inside")

func handle_stone_in_water(stone: Stone):
	var collisions = Helper.get_collision_on_tile(global_position, (1 << Constants.LAYER_BIT_STONES), get_world_2d())
	
	for col in collisions:
		if col.collider is Stone and col.collider.name == stone.name and stone_inside == null:
			var target_is_water = Helper.check_if_collides(col.collider.target_position, (1 << Constants.LAYER_BIT_WATER), get_world_2d())
			if target_is_water:
				print("Stone in water!")
				stone_inside = stone
				stone.is_in_water = true
				stone.turn_into_platform_in_water()
