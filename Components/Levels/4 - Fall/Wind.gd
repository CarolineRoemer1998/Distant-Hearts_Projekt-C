extends Node2D

#class_name Wind

@export var blow_direction : Vector2 = Vector2.LEFT:
	set(val):
		blow_direction = val

@onready var timer_blow_wind_interval: Timer = $TimerBlowWindInterval
@onready var timer_blow_duration: Timer = $TimerBlowDuration

@onready var wind_particles: WindParticle = $WindParticles
var set_shadow_positions = []

var shadow := preload(Constants.SPRITE_2D_SHADOW)

var layer_mask_blowable_objects :=    (1 << Constants.LAYER_BIT_CREATURE) \
									| (1 << Constants.LAYER_BIT_PILE_OF_LEAVES) \
									| (1 << Constants.LAYER_BIT_PLAYER) 

var layer_mask_wind_blocking_objects :=   (1 << Constants.LAYER_BIT_DOOR) \
										| (1 << Constants.LAYER_BIT_STONES) \
										| (1 << Constants.LAYER_BIT_WALL_AND_PLAYER)

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
var wind_strength := 20
var init_blow_done = false
var is_active = false

func _ready() -> void:
	add_to_group(Constants.GROUP_NAME_WIND)
	_set_level_tile_positions()
	#set_wind_particle_direction(blow_direction)

func set_wind_particle_direction(dir: Vector2):
	if dir == Vector2.UP or dir == Vector2.DOWN or dir == Vector2.LEFT or dir == Vector2.RIGHT:
		wind_particles.set_scale_gravity_and_position(dir)

func _process(_delta: float) -> void:
	if is_active:
		if not init_blow_done:
			
			check_for_objects_to_blow({})
			init_blow_done = true

func check_for_objects_to_blow(_dict: Dictionary = {}):
	if is_active:
		var objects_to_blow = get_all_blowable_objects()
		#set_shadow_tiles()
		#await get_tree().create_timer(0.25).timeout
		Signals.wind_blows.emit(objects_to_blow, blow_direction, wind_particles)

func set_shadow_tiles():
	#if not is_active:
		#return
	await get_tree().create_timer(0.025).timeout
	var wind_blocking_objects = []
	for tile in all_level_tile_positions:
		var result_wind_blocking_obj = Helper.get_collision_on_tile(tile, layer_mask_wind_blocking_objects, get_world_2d())
		if not result_wind_blocking_obj.is_empty():
			if not result_wind_blocking_obj[0].collider is Door or result_wind_blocking_obj[0].collider.door_is_closed:
				wind_blocking_objects.append(tile)
	
	var shadows_to_delete = all_level_tile_positions
	
	await get_tree().create_timer(0.25).timeout
	
	var new_shadow_tiles = []
	
	for tile in wind_blocking_objects:
		var amount_tiles_to_check = get_amount_tiles_in_direction(tile, blow_direction)
		for i in amount_tiles_to_check:
			var shadow_position = tile+(blow_direction*tile_size*(i))+(blow_direction*tile_size)
			var result_tile_blocking_object = Helper.get_collision_on_tile(shadow_position, layer_mask_wind_blocking_objects, get_world_2d())
			if not set_shadow_positions.has(shadow_position):
				shadows_to_delete.erase(tile)
				
				var new_shadow = shadow.instantiate()
				add_child(new_shadow)
				new_shadow.global_position = shadow_position
				set_shadow_positions.append(shadow_position)
				new_shadow.appear()
	#for tile in shadows_to_delete:
	await get_tree().create_timer(0.25).timeout

	for tile in shadows_to_delete:
		var s = Helper.get_collision_on_tile(tile, (1<<Constants.LAYER_BIT_SHADOW), get_world_2d())
		if not s.is_empty() and s[0].collider is Shadow:
			s[0].collider.delete_self()

# Wird von Level aufgerufen
func blow():
	var objects_to_blow = get_all_blowable_objects()
	Signals.wind_blows.emit(objects_to_blow, blow_direction, wind_particles)

func get_all_blowable_objects() -> Dictionary:
	var blowable_objects_in_level : Dictionary[Vector2, Dictionary] = {}
	
	for tile in all_level_tile_positions:
		var result_blowable_objects = Helper.get_collision_on_tile(tile, layer_mask_blowable_objects, get_world_2d())
		if not result_blowable_objects.is_empty():
			blowable_objects_in_level[tile] = {"Object": null, "is_affected_by_wind": true, "amount_of_tiles_to_travel": 1}
			for obj in result_blowable_objects:
				blowable_objects_in_level[tile]["Object"] = obj.collider
	
	return get_all_objects_actually_hit_by_wind(blowable_objects_in_level)

func get_all_objects_actually_hit_by_wind(blowable_objects: Dictionary) -> Dictionary:
	var result := {}

	for tile_with_object in blowable_objects:
		var n = blowable_objects[tile_with_object].get("Object").name
		var incoming_dir := Vector2.ZERO
		match blow_direction:
			Vector2.UP:    incoming_dir = Vector2.DOWN
			Vector2.DOWN:  incoming_dir = Vector2.UP
			Vector2.LEFT:  incoming_dir = Vector2.RIGHT
			Vector2.RIGHT: incoming_dir = Vector2.LEFT
		if get_single_object_actually_hit_by_wind(tile_with_object, blowable_objects, incoming_dir):
			var travel_distance := get_travel_distance(tile_with_object)
			result[tile_with_object] = {
				"Object": blowable_objects[tile_with_object]["Object"],
				"travel_distance": travel_distance
			}
	return result

func get_single_object_actually_hit_by_wind(tile_with_object: Vector2, blowable_objects: Dictionary, direction_wind_is_coming_from: Vector2):
	var check_tile = tile_with_object
	var obj = Helper.get_collision_on_tile(check_tile, (1 << Constants.LAYER_BIT_PILE_OF_LEAVES), get_world_2d())
	if not obj.is_empty() and obj[0].collider.name == "PileOfLeaves7":
		print(obj[0].collider.name)
	var amount_tiles_to_check = get_amount_tiles_in_direction(tile_with_object, direction_wind_is_coming_from)
	for i in amount_tiles_to_check:
		if get_is_wind_blocking_object_on_tile(get_tile_in_direction(check_tile, direction_wind_is_coming_from)):# or not get_is_tile_next_to_object_empty(tile_with_object):
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
		if obj.collider is Door and not obj.collider.door_is_closed:
			print(obj.collider.name)
			wind_blocking_object_results.erase(obj)
	return not wind_blocking_object_results.is_empty()

func get_is_tile_next_to_object_empty(obj_tile: Vector2):
	var result_blocking_objects = Helper.get_collision_on_tile(obj_tile+(tile_size*blow_direction), layer_mask_creature_blocking_objects, get_world_2d())
	var ignore_open_door = false
	for obj in result_blocking_objects:
		if obj.collider is Stone:
			ignore_open_door = true
	if result_blocking_objects.is_empty() or (result_blocking_objects[0].collider is Door and not result_blocking_objects[0].collider.door_is_closed and not ignore_open_door):
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

## Füllt all_level_tile_positions Array mit Vectoren aller Positionen in diesem Level
## -> [ Vector2(96, 96), Vector2(96, 160), Vector2(96, 224), ... )
func _set_level_tile_positions():
	for x in level_width_in_tiles:
		for y in level_height_in_tiles:
			all_level_tile_positions.append(Vector2((tile_size/2)+(tile_size)+(x*64), 96+(y*64)))
