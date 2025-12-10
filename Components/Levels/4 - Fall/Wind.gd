extends Node2D

class_name Wind

@export var blow_direction : Vector2 = Vector2.LEFT

@onready var timer_blow_wind_interval: Timer = $TimerBlowWindInterval

# Bewegliche Objekte: Creatures, Blätterhaufen

var level_tile_width : int = 9   # Falls anders, von Level-Skript aus ändern
var level_tile_height : int = 9  # Falls anders, von Level-Skript aus ändern
var all_level_tile_positions : Array[Vector2]= []
var is_blowing := false

func _ready() -> void:
	set_level_tile_positions()
	timer_blow_wind_interval.start()

func set_level_tile_positions():
	for x in level_tile_width:
		for y in level_tile_height:
			all_level_tile_positions.append(Vector2(96+(x*64), 96+(y*64)))
	
	#for tile in all_level_tile_positions:
		#print(tile)

# Wird von Level aufgerufen
func blow():
	# TODO: Visuals für Wind abspielen
	get_all_blowable_objects_in_level()
	pass

func get_all_blowable_objects_in_level() -> Dictionary:
	var result : Dictionary[Vector2, Array] = {
		
	}
	
	for tile in all_level_tile_positions:
		var result_creatures = Helper.get_collision_on_tile(tile, (1 << Constants.LAYER_BIT_CREATURE), get_world_2d())
		var result_pile_of_leaves = Helper.get_collision_on_tile(tile, (1 << Constants.LAYER_BIT_PILE_OF_LEAVES), get_world_2d())
		
		if not result_creatures.is_empty():
			result[tile] = []
			for c in result_creatures:
				result[tile].append(c.collider)
		
		if not result_pile_of_leaves.is_empty():
			result[tile] = []
			for p in result_creatures:
				result[tile].append(p.collider)
	
	#print(result)
	#print()
	
	get_objects_getting_hit_by_wind(result)
	#print()
	return result

func get_objects_getting_hit_by_wind(blowable_objects: Dictionary) -> Dictionary:
	var result = {}
	
	for object in blowable_objects:
		match blow_direction:
			Vector2.UP:
				pass
			Vector2.DOWN:
				pass
			Vector2.LEFT:
				var pos_obj_x
				var pos_obj_y
				
				###for tile in all_level_tile_positions:
					#print(tile[0], " ##")
					###if blowable_objects.get(Vector2(tile[0], tile[1])) != null:
						#if tile[0] > 
						###print("blowable_objects.get_key(): ", blowable_objects.get_key(blowable_objects.get(Vector2(tile[0], tile[1]))))
						###print("tile[0]: ", tile[0])
						###print(blowable_objects.get(Vector2(tile[0], tile[1])), "++")
					#if tile[0] > blowable_objects.find_key(object)[0] and tile[1] == blowable_objects.find_key(object)[1]:
						#print(tile)
			Vector2.RIGHT:
				pass
		
	
	return result

func _on_timer_blow_wind_interval_timeout() -> void:
	blow()
