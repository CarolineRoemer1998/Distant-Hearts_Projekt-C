extends Node

## Checks if instance (and the possessed creature) is allowed to move
## in the given direction. Considers walls, doors and stones.
## On success, sets pushable_stone_in_direction if a stone can be pushed.
func can_move_in_direction(_position: Vector2, _direction, world : World2D, is_physical_body : bool, is_avoiding := false) -> bool:
	if _direction == null:
		return false
	
	var new_pos = _position + _direction * Constants.GRID_SIZE
	#var world = get_world_2d()
	
	# Queries für alle relevanten Bit Layers
	var result_stones = get_collision_on_tile(new_pos, (1 << Constants.LAYER_BIT_STONE), world)
	var result_flowers = get_collision_on_tile(new_pos, (1 << Constants.LAYER_BIT_FLOWER), world)
	var result_bees = get_collision_on_tile(new_pos, (1 << Constants.LAYER_BIT_BEES), world)
	var result_doors = get_collision_on_tile(new_pos, (1 << Constants.LAYER_BIT_DOOR), world)
	var result_buttons = get_collision_on_area(new_pos, (1 << Constants.LAYER_BIT_BUTTONS), world)
	var result_wall_outside = get_collision_on_tile(new_pos, (1 << Constants.LAYER_BIT_LEVEL_WALL), world)
	var result_wall_inside = get_collision_on_tile(new_pos, (1 << Constants.LAYER_BIT_WALL_AND_PLAYER), world)
	
	#print(result_flowers)
	print(is_avoiding)
	
	if is_avoiding and not result_buttons.is_empty():
		return false
	
	if (result_stones.is_empty() and result_flowers.is_empty() and result_doors.is_empty() and result_wall_outside.is_empty() and result_wall_inside.is_empty() and result_bees.is_empty()) \
	or (is_physical_body == false and result_wall_outside.is_empty()):
		return true
	
	if not result_wall_outside.is_empty() \
	or (is_physical_body != false and (not result_wall_inside.is_empty() and not result_stones.is_empty() and not result_flowers.is_empty() and not result_doors.is_empty() and result_bees.is_empty())):
		return false
	
	if not result_doors.is_empty() and result_doors[0].collider is Door and not result_doors[0].collider.door_is_closed and result_stones.is_empty() and result_flowers.is_empty():
		return true
	
	if not result_stones.is_empty() and result_stones[0].collider.get_can_be_pushed(new_pos, _direction):
		result_stones[0].collider.push()
		return true
	
	#buffered_direction = Vector2.ZERO
	return false

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
	#query.collide_with_areas = true
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
	#query.collide_with_areas = true
	return space.intersect_point(query, 1)

func get_collision_on_area(_position, layer_mask, world : World2D) -> Array[Dictionary]:
	var space = world.direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = _position
	query.collision_mask = layer_mask
	query.collide_with_areas = true
	return space.intersect_point(query, 1)
