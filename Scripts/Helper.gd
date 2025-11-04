extends Node

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
		#if result[0].collider is Stone and is_pushing_stone_on_ice:
			#if result[0].collider.is_sliding:
				#return false
	return not result.is_empty()

func get_collision_on_tile(_position, layer_mask, world : World2D):
	var space = world.direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = _position
	query.collision_mask = layer_mask
	return space.intersect_point(query, 1)
