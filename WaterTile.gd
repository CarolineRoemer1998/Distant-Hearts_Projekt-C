extends Node2D

class_name WaterTile

var object_under_water_tile : Node2D = null
var layer_bit_mask_objects_under_water = (1 << Constants.LAYER_BIT_STONES) | (1 << Constants.LAYER_BIT_LILY_PAD)

func _ready() -> void:
	Signals.stone_reached_target.connect(set_object_as_under_water_tile)
	Signals.set_lily_pad_on_water_tile.connect(set_object_as_under_water_tile)
	add_to_group(Constants.GROUP_NAME_WATER_TILE)

func get_info():
	return {
		"object_under_water_tile": object_under_water_tile
	}

func set_info(info: Dictionary):
	object_under_water_tile = info.get("object_under_water_tile")
	if object_under_water_tile != null:
		print(self.name, "\nobject_under_water_tile: ", object_under_water_tile, "\n")

func set_object_as_under_water_tile(object: Node2D):
	var collisions = Helper.get_collision_on_tile(global_position, layer_bit_mask_objects_under_water , get_world_2d())
	
	if object_under_water_tile == null:
	
		for col in collisions:
			if col.collider == object:
				if object is Stone and object_under_water_tile == null:
					var target_is_water = Helper.check_if_collides(object.target_position, (1 << Constants.LAYER_BIT_WATER), get_world_2d())
					if target_is_water and object.target_position == global_position:
						object_under_water_tile = object
						object.is_in_water = true
						object.turn_into_platform_in_water()
				if object is LilyPad:
					object_under_water_tile = object
	
	if object_under_water_tile is LilyPad:
		for col in collisions:
			if col.collider == object:
				if object is Stone:
					var target_is_water = Helper.check_if_collides(object.target_position, (1 << Constants.LAYER_BIT_WATER), get_world_2d())
					if target_is_water and object.target_position == global_position:
						# LilyPad geht unter
						object_under_water_tile.sink(true)
						# Stein wird zu Plattform
						object_under_water_tile = object
						object.is_in_water = true
						object.turn_into_platform_in_water()
