extends Node2D
class_name Wind

@export var blow_direction: Vector2 = Vector2.LEFT:
	set(val):
		blow_direction = val

@onready var timer_blow_wind_interval: Timer = $TimerBlowWindInterval
@onready var timer_blow_duration: Timer = $TimerBlowDuration
@onready var wind_particles: WindParticle = $WindParticles
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

# --- Shadow handling (NEW) ---
var shadow := preload(Constants.SPRITE_2D_SHADOW)
var shadow_by_pos: Dictionary = {}         # Vector2 -> Shadow instance
var _shadow_update_queued := false

# --- Existing wind logic ---
var layer_mask_blowable_objects := (1 << Constants.LAYER_BIT_CREATURE) \
								| (1 << Constants.LAYER_BIT_PILE_OF_LEAVES) \
								| (1 << Constants.LAYER_BIT_PLAYER)

# Blockers that CAST shadow (doors only if closed; walls inside; stones)
var layer_mask_wind_blocking_objects := (1 << Constants.LAYER_BIT_DOOR) \
									| (1 << Constants.LAYER_BIT_STONES) \
									| (1 << Constants.LAYER_BIT_WALL_AND_PLAYER)

# Used for travel distance (unchanged)
var layer_mask_creature_blocking_objects := (1 << Constants.LAYER_BIT_BEES) \
										| (1 << Constants.LAYER_BIT_DOOR) \
										| (1 << Constants.LAYER_BIT_FLOWER) \
										| (1 << Constants.LAYER_BIT_STONES) \
										| (1 << Constants.LAYER_BIT_WATER) \
										| (1 << Constants.LAYER_BIT_WALL_AND_PLAYER)

var tile_size: float = 64.0
var level_width_in_tiles: int = 9
var level_height_in_tiles: int = 9

# World-space position of tile (0,0) in the grid (top-left playable tile)
# Set to match your current layout. If your levels differ, set/override these from Level.
var grid_origin: Vector2 = Vector2(96, 96)

var all_level_tile_positions: Array[Vector2] = []
var is_blowing := false
var wind_strength := 20
var init_blow_done := false
var is_active := false

var wind_volume := 0.0
var wind_volume_quiet := -50.0
var wind_pitch_normal := 1.0
var wind_pitch_blowing := 1.5
var is_blowing_player := false
var is_blowing_creature

func _ready() -> void:
	Signals.player_is_blown_by_wind.connect(set_player_is_blown)
	Signals.creature_is_blown_by_wind.connect(set_creature_is_blown)
	add_to_group(Constants.GROUP_NAME_WIND)
	_set_level_tile_positions()
	audio_stream_player_2d.volume_db = -50.0

func set_player_is_blown(val: bool):
	is_blowing_player = val

func set_creature_is_blown(val: bool):
	is_blowing_creature = val

func set_wind_particle_direction(dir: Vector2) -> void:
	if dir == Vector2.UP or dir == Vector2.DOWN or dir == Vector2.LEFT or dir == Vector2.RIGHT:
		wind_particles.set_scale_gravity_and_position(dir)

func _process(_delta: float) -> void:
	audio_stream_player_2d.volume_db = lerp(audio_stream_player_2d.volume_db, wind_volume, _delta*4)
	
	if (is_blowing_creature or is_blowing_player) and audio_stream_player_2d.pitch_scale != wind_pitch_blowing:
		audio_stream_player_2d.pitch_scale = lerp(audio_stream_player_2d.pitch_scale, wind_pitch_blowing, _delta*5)
	elif (not is_blowing_creature and not is_blowing_player) and audio_stream_player_2d.pitch_scale != wind_pitch_normal:
		audio_stream_player_2d.pitch_scale = lerp(audio_stream_player_2d.pitch_scale, wind_pitch_normal, _delta*5)
	
	if is_active and not init_blow_done:
		#request_shadow_update()
		#check_for_objects_to_blow({})
		#check_for_objects_to_blow({})
		init_blow_done = true

# ------------------------------------------------------------
# Shadow API (NEW)
# ------------------------------------------------------------
func request_shadow_update() -> void:
	if _shadow_update_queued:
		return
	
	_shadow_update_queued = true
	call_deferred("_do_shadow_update")

func _do_shadow_update() -> void:
	_shadow_update_queued = false
	_refresh_shadow_tiles()

func _refresh_shadow_tiles() -> void:
	var desired := _compute_desired_shadow_positions() # Dictionary used as a Set

	# Remove shadows that are no longer desired
	for pos in shadow_by_pos.keys():
		if not desired.has(pos):
			var s: Shadow = shadow_by_pos[pos]
			shadow_by_pos.erase(pos)
			if is_instance_valid(s):
				s.disappear_and_free()

	# Add new shadows that are missing
	for pos in desired.keys():
		if not shadow_by_pos.has(pos):
			var s: Shadow = shadow.instantiate()
			add_child(s)
			s.global_position = pos
			shadow_by_pos[pos] = s
			s.appear()

func _compute_desired_shadow_positions() -> Dictionary:
	var desired := {}

	# Regel:
	# - Der ERSTE Blocker (upwind) erzeugt Schatten hinter sich, bekommt selbst aber keinen Schatten.
	# - ALLE Tiles die bereits im Schatten sind, bekommen Schatten – auch wenn dort ein weiterer Blocker steht.

	if blow_direction == Vector2.LEFT:
		for y in range(level_height_in_tiles):
			var blocked := false
			for x in range(level_width_in_tiles - 1, -1, -1):
				var pos := _pos_from_xy(x, y)

				# Wenn wir schon "im Schatten" sind, bekommt jedes Tile Schatten (auch Blocker)
				if blocked:
					desired[pos] = true

				# Blocker setzt/behält blocked=true (aber erst NACH dem evtl. desired oben)
				if _is_shadow_blocker_at(pos):
					blocked = true

	elif blow_direction == Vector2.RIGHT:
		for y in range(level_height_in_tiles):
			var blocked := false
			for x in range(level_width_in_tiles):
				var pos := _pos_from_xy(x, y)

				if blocked:
					desired[pos] = true

				if _is_shadow_blocker_at(pos):
					blocked = true

	elif blow_direction == Vector2.UP:
		for x in range(level_width_in_tiles):
			var blocked := false
			for y in range(level_height_in_tiles - 1, -1, -1):
				var pos := _pos_from_xy(x, y)

				if blocked:
					desired[pos] = true

				if _is_shadow_blocker_at(pos):
					blocked = true

	elif blow_direction == Vector2.DOWN:
		for x in range(level_width_in_tiles):
			var blocked := false
			for y in range(level_height_in_tiles):
				var pos := _pos_from_xy(x, y)

				if blocked:
					desired[pos] = true

				if _is_shadow_blocker_at(pos):
					blocked = true

	return desired


func _is_shadow_blocker_at(world_pos: Vector2) -> bool:
	var hits := Helper.get_collision_on_tile(world_pos, layer_mask_wind_blocking_objects, get_world_2d())
	if hits.is_empty():
		return false

	for h in hits:
		var c = h.collider

		# Player should NOT be a shadow blocker (you share WALL_AND_PLAYER layer)
		if c is Player:
			continue

		# Open doors do NOT block
		if c is Door and not c.door_is_closed:
			continue

		# Everything else in the mask blocks
		return true

	return false

func _pos_from_xy(x: int, y: int) -> Vector2:
	return Vector2(grid_origin.x + x * tile_size, grid_origin.y + y * tile_size)

# ------------------------------------------------------------
# Wind blowing logic (mostly unchanged)
# ------------------------------------------------------------
func check_for_objects_to_blow(_dict: Dictionary = {}) -> void:
	if not is_active:
		return
	
	request_shadow_update()
	
	if not init_blow_done:
		await get_tree().create_timer(0.005).timeout
	
	var objects_to_blow = get_all_blowable_objects()
	Signals.wind_blows.emit(objects_to_blow, blow_direction, wind_particles)


# Called from Level if you want manual trigger
func blow() -> void:
	var objects_to_blow = get_all_blowable_objects()
	Signals.wind_blows.emit(objects_to_blow, blow_direction, wind_particles)

func get_all_blowable_objects() -> Dictionary:
	var blowable_objects_in_level: Dictionary[Vector2, Dictionary] = {}

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

func get_single_object_actually_hit_by_wind(tile_with_object: Vector2, _blowable_objects: Dictionary, direction_wind_is_coming_from: Vector2) -> bool:
	var check_tile = tile_with_object
	var amount_tiles_to_check = get_amount_tiles_in_direction(tile_with_object, direction_wind_is_coming_from)
	
	if shadow_by_pos.has(tile_with_object):
		return false
	
	for i in amount_tiles_to_check:
		if get_is_wind_blocking_object_on_tile(get_tile_in_direction(check_tile, direction_wind_is_coming_from)):
			return false
		else:
			check_tile = get_tile_in_direction(check_tile, direction_wind_is_coming_from)

	return true

func get_amount_tiles_in_direction(from_tile: Vector2, direction: Vector2) -> int:
	# This is your original math; leaving as-is.
	match direction:
		Vector2.UP:
			return level_width_in_tiles - 1 - (level_width_in_tiles - ((from_tile[1] - (tile_size / 2.0)) / 64.0))
		Vector2.DOWN:
			return level_width_in_tiles - ((from_tile[1] - (tile_size / 2.0)) / 64.0)
		Vector2.LEFT:
			return level_width_in_tiles - 1 - (level_width_in_tiles - ((from_tile[0] - (tile_size / 2.0)) / 64.0))
		Vector2.RIGHT:
			return level_width_in_tiles - ((from_tile[0] - (tile_size / 2.0)) / 64.0)
	return 0

func get_tile_in_direction(tile: Vector2, direction: Vector2) -> Vector2:
	return tile + (direction * tile_size)

func get_is_wind_blocking_object_on_tile(tile: Vector2) -> bool:
	var results = Helper.get_collision_on_tile(tile, layer_mask_wind_blocking_objects, get_world_2d())
	if results.is_empty():
		return false

	# Filter open doors, ignore player-on-wall-layer
	for h in results:
		var c = h.collider
		if c is Player:
			results.erase(h)
		elif c is Door and not c.door_is_closed:
			results.erase(h)

	return not results.is_empty()

func get_is_tile_next_to_object_empty(obj_tile: Vector2) -> bool:
	var result_blocking_objects = Helper.get_collision_on_tile(obj_tile + (tile_size * blow_direction), layer_mask_creature_blocking_objects, get_world_2d())
	var ignore_open_door = false

	for obj in result_blocking_objects:
		if obj.collider is WaterTile:
			var water : WaterTile = obj.collider as WaterTile
			if water.object_under_water_tile != null:
				result_blocking_objects.erase(obj)
		if obj.collider is Stone:
			if obj.collider.is_in_water:
				result_blocking_objects.erase(obj)
			ignore_open_door = true

	if result_blocking_objects.is_empty() or (result_blocking_objects[0].collider is Door and not result_blocking_objects[0].collider.door_is_closed and not ignore_open_door):
		return true
	return false

func get_travel_distance(tile_with_object: Vector2) -> int:
	var travel_distance = 0
	var tile_to_check = tile_with_object

	for i in wind_strength:
		if get_is_tile_next_to_object_empty(tile_to_check):
			tile_to_check += blow_direction * tile_size
			travel_distance += 1

	return travel_distance

func _on_timer_blow_wind_interval_timeout() -> void:
	timer_blow_duration.start()
	blow()

func _on_timer_blow_duration_timeout() -> void:
	Signals.wind_stopped_blowing.emit()

# ------------------------------------------------------------
# Grid setup (unchanged but origin is centralized)
# ------------------------------------------------------------
func _set_level_tile_positions() -> void:
	all_level_tile_positions.clear()

	# Keep your old coordinate style but also define grid_origin consistently.
	# Your previous first tile was Vector2(96, 96). We'll use that as origin.
	grid_origin = Vector2(96, 96)

	for x in range(level_width_in_tiles):
		for y in range(level_height_in_tiles):
			all_level_tile_positions.append(_pos_from_xy(x, y))
