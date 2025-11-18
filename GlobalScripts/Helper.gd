extends Node

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
	return space.intersect_point(query, 1)
