extends Node2D

class_name Wind

@export var blow_direction : Vector2 = Vector2.LEFT

@onready var timer_blow_wind_interval: Timer = $TimerBlowWindInterval
@onready var timer_blow_duration: Timer = $TimerBlowDuration

# Bewegliche Objekte: Creatures, Blätterhaufen

var layer_mask_blowable_objects :=    (1 << Constants.LAYER_BIT_CREATURE) \
									| (1 << Constants.LAYER_BIT_PILE_OF_LEAVES) \
									| (1 << Constants.LAYER_BIT_PLAYER) 

var layer_mask_wind_blocking_objects :=   (1 << Constants.LAYER_BIT_DOOR) \
										| (1 << Constants.LAYER_BIT_STONES) \
										| (1 << Constants.LAYER_BIT_LEVEL_WALL)

var layer_mask_creature_blocking_objects := (1 << Constants.LAYER_BIT_BEES) \
										| (1 << Constants.LAYER_BIT_DOOR) \
										| (1 << Constants.LAYER_BIT_FLOWER) \
										| (1 << Constants.LAYER_BIT_STONES) \
										| (1 << Constants.LAYER_BIT_WATER) \
										| (1 << Constants.LAYER_BIT_WALL_AND_PLAYER)


var tile_size : float = 64.0
var level_width_in_tiles : float = 9.0   # Falls anders, von Level-Skript aus ändern
var level_height_in_tiles : float = 9.0  # Falls anders, von Level-Skript aus ändern
var all_level_tile_positions : Array[Vector2]= []
var is_blowing := false

var wind_strength := 4

func _ready() -> void:
	set_level_tile_positions()
	timer_blow_wind_interval.start()

## Füllt all_level_tile_positions Array mit Vectoren aller Positionen in diesem Level
## -> [ Vector2(96, 96), Vector2(96, 160), Vector2(96, 224), ... )
func set_level_tile_positions():
	for x in level_width_in_tiles:
		for y in level_height_in_tiles:
			all_level_tile_positions.append(Vector2((tile_size/2)+(tile_size)+(x*64), 96+(y*64)))

# Wird von Level aufgerufen
func blow():
	# TODO: Visuals für Wind abspielen
	
	var objects_to_blow = get_all_blowable_objects()
	#print(objects_to_blow, blow_direction)
	print("--WIND BLOWS--")
	Signals.wind_blows.emit(objects_to_blow, blow_direction)

func get_all_blowable_objects() -> Dictionary:
	var blowable_objects_in_level : Dictionary[Vector2, Dictionary] = {}
	
	for tile in all_level_tile_positions:
		var result_blowable_objects = Helper.get_collision_on_tile(tile, layer_mask_blowable_objects, get_world_2d())
		#print(result_blowable_objects)
		if not result_blowable_objects.is_empty():
			blowable_objects_in_level[tile] = {"Object": null, "is_affected_by_wind": true, "amount_of_tiles_to_travel": 1}
			for obj in result_blowable_objects:
				blowable_objects_in_level[tile]["Object"] = obj.collider
	
	return get_all_objects_actually_hit_by_wind(blowable_objects_in_level)

func get_all_objects_actually_hit_by_wind(blowable_objects: Dictionary) -> Dictionary:
	var result = {}
	
	for tile_with_object in blowable_objects:
		match blow_direction:
			Vector2.UP:
				if get_single_object_actually_hit_by_wind(tile_with_object, blowable_objects, Vector2.DOWN):
					var travel_distance = get_travel_distance(tile_with_object)
					result[tile_with_object] = blowable_objects[tile_with_object]["Object"]
					
					print(get_travel_distance(tile_with_object))
			Vector2.DOWN:
				if get_single_object_actually_hit_by_wind(tile_with_object, blowable_objects, Vector2.UP):
					var travel_distance = get_travel_distance(tile_with_object)
					result[tile_with_object] = blowable_objects[tile_with_object]["Object"]
					print(get_travel_distance(tile_with_object))
			Vector2.LEFT:
				if get_single_object_actually_hit_by_wind(tile_with_object, blowable_objects, Vector2.RIGHT):
					var travel_distance = get_travel_distance(tile_with_object)
					result[tile_with_object] = {
						"Object": blowable_objects[tile_with_object]["Object"],
						"travel_distance": travel_distance
					}
					print(get_travel_distance(tile_with_object))
			Vector2.RIGHT:
				if get_single_object_actually_hit_by_wind(tile_with_object, blowable_objects, Vector2.LEFT):
					var travel_distance = get_travel_distance(tile_with_object)
					result[tile_with_object] = blowable_objects[tile_with_object]["Object"]
					print(get_travel_distance(tile_with_object))
	
	return result

func get_single_object_actually_hit_by_wind(tile_with_object: Vector2, blowable_objects: Dictionary, direction_wind_is_coming_from: Vector2):
	var check_tile = tile_with_object
	var amount_tiles_to_check = get_amount_tiles_in_direction(tile_with_object, direction_wind_is_coming_from)
	for i in amount_tiles_to_check:
		if get_is_wind_blocking_object_on_tile(get_tile_in_direction(check_tile, direction_wind_is_coming_from)) or not get_is_tile_next_to_object_empty(tile_with_object):
			return false
		else:
			check_tile = get_tile_in_direction(check_tile, direction_wind_is_coming_from)
	return true

func get_amount_tiles_in_direction(from_tile: Vector2, direction: Vector2) -> int:
	match direction:
		Vector2.UP:
			return level_width_in_tiles - 1 - (level_width_in_tiles - ((from_tile[1]-(tile_size/2.0))/64.0))
		Vector2.DOWN:
			return level_width_in_tiles - ((from_tile[1]-(tile_size/2.0))/64.0)
		Vector2.LEFT:
			return level_width_in_tiles - 1 - (level_width_in_tiles - ((from_tile[0]-(tile_size/2.0))/64.0))
		Vector2.RIGHT:
			return level_width_in_tiles - ((from_tile[0]-(tile_size/2.0))/64.0)
	return 0

func get_tile_in_direction(tile: Vector2, direction: Vector2) -> Vector2:
	return tile + (direction*tile_size)

func get_is_wind_blocking_object_on_tile(tile: Vector2) -> bool:
	var wind_blocking_object_results = Helper.get_collision_on_tile(tile, layer_mask_wind_blocking_objects, get_world_2d())
	for obj in wind_blocking_object_results:
		if obj.collider is Door and obj.collider.is_open:
			wind_blocking_object_results.erase(obj)
	return not wind_blocking_object_results.is_empty()

func get_is_tile_next_to_object_empty(obj_tile: Vector2):
	var result_blocking_objects = Helper.get_collision_on_tile(obj_tile+(tile_size*blow_direction), layer_mask_creature_blocking_objects, get_world_2d())
	#print("Blocker: ", result_blocking_objects)
	if result_blocking_objects.is_empty():
		return true
	else:
		return false

func get_travel_distance(tile_with_object: Vector2) -> int:
	var travel_distance = 0
	var tile_to_check = tile_with_object
	for i in wind_strength:
		if get_is_tile_next_to_object_empty(tile_to_check):
			tile_to_check += blow_direction*tile_size
			travel_distance += 1
	return travel_distance

func _on_timer_blow_wind_interval_timeout() -> void:
	timer_blow_duration.start()
	blow()


func _on_timer_blow_duration_timeout() -> void:
	Signals.wind_stopped_blowing.emit()
