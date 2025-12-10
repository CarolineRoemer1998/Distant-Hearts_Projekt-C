extends Node

enum TILE_CONTENT {
	empty, 
	wall,
	creature, 
	pushable,
	stone, 
	button, 
	door,
	teleporter,
	soil, 
	seed, 
	flower,
	bees,
	water,
	lilypad,
	stone_platform,
	ice
}

func get_tile_states(pos: Vector2, world: World2D, is_physical_body: bool):
	var tile_states = {}
	
	var result_pushables = get_collision_on_tile(pos, (1 << Constants.LAYER_BIT_PUSHABLE), world)
	var result_bees = get_collision_on_tile(pos, (1 << Constants.LAYER_BIT_BEES), world)
	var result_doors = get_collision_on_tile(pos, (1 << Constants.LAYER_BIT_DOOR), world)
	var result_wall_outside = get_collision_on_tile(pos, (1 << Constants.LAYER_BIT_LEVEL_WALL), world)
	var result_wall_inside = get_collision_on_tile(pos, (1 << Constants.LAYER_BIT_WALL_AND_PLAYER), world)
	var result_water = get_collision_on_tile(pos, (1 << Constants.LAYER_BIT_WATER), world)
	var result_water_platform = get_collision_on_tile(pos, (1 << Constants.LAYER_BIT_WATER_PLATFORM), world)
	var result_lily_pads = get_collision_on_tile(pos, (1 << Constants.LAYER_BIT_LILY_PAD), world)
	
	if not result_wall_outside.is_empty():
		tile_states[TILE_CONTENT.wall] = result_wall_outside
		
	if is_physical_body:
		if not result_bees.is_empty(): 
			tile_states[TILE_CONTENT.bees] = get_tile_contents_of_collider(result_bees)
		if not result_doors.is_empty(): 
			tile_states[TILE_CONTENT.door] = get_tile_contents_of_collider(result_doors)
		if not result_wall_inside.is_empty(): 
			tile_states[TILE_CONTENT.wall] = get_tile_contents_of_collider(result_wall_inside)
		if not result_water.is_empty(): 
			tile_states[TILE_CONTENT.water] = get_tile_contents_of_collider(result_water)
		if not result_lily_pads.is_empty(): 
			tile_states[TILE_CONTENT.lilypad] = get_tile_contents_of_collider(result_lily_pads)
		if not result_water_platform.is_empty(): 
			tile_states[TILE_CONTENT.stone_platform] = get_tile_contents_of_collider(result_water_platform)
		if not result_pushables.is_empty(): 
			tile_states[TILE_CONTENT.pushable] = get_tile_contents_of_collider(result_pushables)
	
	return tile_states

## Checks if instance (and the possessed creature) is allowed to move
## in the given direction. Considers walls, doors and stones.
## On success, sets pushable_stone_in_direction if a stone can be pushed.

## TODO: ÄNDERN ZU: get_tile_states() und dann basierend darauf handeln
func can_move_in_direction(_position: Vector2, _direction, world : World2D, is_physical_body : bool, player: Player) -> bool:
	if _direction == null:
		return false
	
	var new_pos = _position + _direction * Constants.GRID_SIZE
	var tile_states = get_tile_states(new_pos, world, is_physical_body)
	var can_move_in_dir : bool = false
	
	# State: NICHTS
	if tile_states.is_empty():
		tile_states[TILE_CONTENT.empty] = null
		can_move_in_dir = true
	
	# State: WAND
	elif tile_states.has(TILE_CONTENT.wall):
		can_move_in_dir = false
	
	# State: BIENEN
	elif tile_states.has(TILE_CONTENT.bees):
		var result_bees = get_collision_on_tile(new_pos, (1 << Constants.LAYER_BIT_BEES), world)[0].collider
		Signals.tried_walking_on_bee_area.emit(result_bees)
		can_move_in_dir = false
	
	# State: PUSHABLE
	elif tile_states.has(TILE_CONTENT.pushable):
		if tile_states[TILE_CONTENT.pushable][0].get_can_be_pushed(new_pos, _direction):
			tile_states[TILE_CONTENT.pushable][0].push() # TODO: Später push() erst nachdem diese funktion aufgerufen wurde
			can_move_in_dir = true
		else:
			can_move_in_dir = false
	
	# State: WASSER
	elif tile_states.has(TILE_CONTENT.water):
		# State: LILY PAD
		if tile_states.has(TILE_CONTENT.lilypad) or tile_states.has(TILE_CONTENT.stone_platform):
			can_move_in_dir = true
		# State: KEIN LILY PAD
		else:
			can_move_in_dir = false
	
	# State: TÜR
	elif tile_states.has(TILE_CONTENT.door):
		# State: TÜR GESCHLOSSEN
		if tile_states[TILE_CONTENT.door][0].door_is_closed:
			can_move_in_dir = false
		# State: TÜR OFFEN
		else:
			can_move_in_dir = true
	
	if not can_move_in_dir and player.currently_possessed_creature != null:
		player.currently_possessed_creature.play_failed_step_in_direction_animation()
	return can_move_in_dir

func get_tile_contents_of_collider(arr: Array):
	var result = []
	for i in arr:
		result.append(i.collider)
	return result


func check_for_bee_area(target_pos, world):
	var result_bee_area = Helper.get_collision_on_area(target_pos, 1 << Constants.LAYER_BIT_BEE_AREA,world)
	return result_bee_area.is_empty()

func get_slide_end(block_mask, _direction : Vector2, starting_position: Vector2, _is_pushing_stone_one_ice: bool, world: World2D) -> Vector2:
	var slide_end = starting_position
	
	while true:
		var next_pos = slide_end + _direction * Constants.GRID_SIZE
		
		# Trifft auf Blockade
		if FieldReservation.is_reserved(next_pos) or Helper.check_if_collides(next_pos, block_mask, world): break
		
		# Von Eis auf normalen Boden rutschen
		if not Helper.check_is_ice(next_pos, world):
			slide_end = next_pos
			break
		
		slide_end = next_pos
	
	if FieldReservation.is_reserved(slide_end):
		slide_end = slide_end - _direction * Constants.GRID_SIZE
	
	return slide_end

func check_is_ice(pos: Vector2, world : World2D) -> bool:
	var space_state = world.direct_space_state
	var ice_query = PhysicsPointQueryParameters2D.new()
	ice_query.position = pos
	ice_query.collision_mask = 1 << Constants.LAYER_BIT_ICE
	ice_query.collide_with_bodies = true
	ice_query.collide_with_areas  = true
	return not space_state.intersect_point(ice_query, 1).is_empty()

func check_if_collides(_position, layer_mask, world : World2D) -> bool:
	var space = world.direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = _position
	query.collision_mask = layer_mask
	var result = space.intersect_point(query, 1)
	if not result.is_empty():
		if result[0].collider is Door:
			if not result[0].collider.door_is_closed:
				return false
	return not result.is_empty()

func get_collision_on_tile(_position, layer_mask, world : World2D) -> Array[Dictionary]:
	var space = world.direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = _position
	query.collision_mask = layer_mask
	return space.intersect_point(query, 5)

func get_collision_on_area(_position, layer_mask, world : World2D) -> Array[Dictionary]:
	var space = world.direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = _position
	query.collision_mask = layer_mask
	query.collide_with_areas = true
	return space.intersect_point(query, 1)

func sort_out_water_with_stones(_platforms: Array[Dictionary], _stones: Array[Dictionary]) -> Array[Dictionary]:
	var result : Array[Dictionary] = _stones
	for p in _platforms:
		for s in result:
			if p.collider.name == s.collider.name:
				result.erase(s)
	return result

func get_distance_between_two_vectors(v1 : Vector2, v2 : Vector2) -> float:
	var result = abs(v1-v2)
	result = sqrt(pow(result[0],2)+pow(result[1], 2))
	return result
