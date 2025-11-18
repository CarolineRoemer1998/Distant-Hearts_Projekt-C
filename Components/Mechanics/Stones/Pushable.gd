extends CharacterBody2D

class_name Stone

const MOVE_SPEED := 500.0

var target_position: Vector2
var is_moving := false
var is_sliding := false

# Cached push data, set by get_can_be_pushed
var pending_target_position: Vector2 = Vector2.ZERO
var pending_direction: Vector2 = Vector2.ZERO


## Initializes the stone when the scene starts:
## adds it to the stone group, enables collision and snaps to the grid.
func _ready():
	add_to_group(str(Constants.GROUP_NAME_STONES))
	enable_collision_layer()
	target_position = position.snapped(Constants.GRID_SIZE / 2)
	position = target_position


# -----------------------------------------------------------
# State (e.g. for Undo)
# -----------------------------------------------------------

## Returns a Dictionary snapshot of the stone state
## used for Undo/Redo (position + target position).
func get_info() -> Dictionary:
	return {
		"global_position": global_position,
		"target_position": target_position
	}


## Restores the stone state from a Dictionary snapshot.
## Resets movement and pending push data.
func set_info(info : Dictionary):
	global_position = info.get("global_position")
	target_position = global_position
	
	is_moving = false
	is_sliding = false
	
	pending_target_position = Vector2.ZERO
	pending_direction = Vector2.ZERO


# -----------------------------------------------------------
# Movement / Push / Slide
# -----------------------------------------------------------

## Starts a slide movement towards slide_target if the stone is not already sliding.
## Reserves the target tile and returns true on success.
func slide(slide_target: Vector2) -> bool:
	if is_sliding:
		return false
	
	FieldReservation.reserve(self, [slide_target])
	is_sliding = true
	target_position = slide_target
	return true


## Checks if the stone can be pushed from new_pos in the given direction.
## Respects blocking objects and doors behind the stone and sets pending push data.
## Returns true if a push is possible and false otherwise.
func get_can_be_pushed(new_pos : Vector2, direction : Vector2) -> bool:
	# Already moving → cannot be pushed right now
	if is_moving or is_sliding:
		_reset_pending_push()
		return false
	
	var world = get_world_2d()
	
	# Tile directly behind the stone (in push direction)
	var behind_stone_pos = new_pos + direction * Constants.GRID_SIZE
	var push_collision = Helper.get_collision_on_tile(
		behind_stone_pos,
		Constants.LAYER_MASK_BLOCKING_OBJECTS,
		world
	)
	
	# If there is a door behind the stone, check if it is open
	for hit in push_collision:
		if hit.collider is Door:
			if not hit.collider.door_is_closed:
				_set_pending_push(new_pos, direction)
				return true
			else:
				_reset_pending_push()
				return false
	
	# If nothing is behind the stone, it can be pushed
	if push_collision.is_empty():
		_set_pending_push(new_pos, direction)
		return true
	
	# Otherwise the stone is blocked
	_reset_pending_push()
	return false


## Executes a push using the previously cached pending push data.
## Expects get_can_be_pushed to have been called successfully before.
## Also starts a slide if the new position is on ice.
func push():
	# Expects get_can_be_pushed to have been called successfully before
	if pending_target_position == Vector2.ZERO and pending_direction == Vector2.ZERO:
		return
	
	target_position = pending_target_position + (pending_direction * Constants.GRID_SIZE)
	is_moving = true
	
	# On ice → calculate slide end position directly
	if Helper.check_is_ice(target_position, get_world_2d()):
		var slide_end = Helper.get_slide_end(
			Constants.LAYER_MASK_BLOCKING_OBJECTS,
			pending_direction,
			target_position,
			false,
			get_world_2d()
		)
		slide(slide_end)
	
	_reset_pending_push()


## Stores the given push target and direction in the pending push buffer.
func _set_pending_push(new_pos: Vector2, direction: Vector2) -> void:
	pending_target_position = new_pos
	pending_direction = direction


## Clears the pending push buffer, indicating that no push is currently prepared.
func _reset_pending_push() -> void:
	pending_target_position = Vector2.ZERO
	pending_direction = Vector2.ZERO


# -----------------------------------------------------------
# Collision Layer
# -----------------------------------------------------------

## Enables the collision layer for stones so this stone participates
## in collisions as a stone.
func enable_collision_layer():
	set_collision_layer_value(Constants.LAYER_BIT_STONE, true)


## Disables the collision layer for stones so this stone no longer
## participates in collisions as a stone.
func disable_collision_layer():
	set_collision_layer_value(Constants.LAYER_BIT_STONE, false)


# -----------------------------------------------------------
# Update Loop
# -----------------------------------------------------------

## Per-frame update: moves the stone towards its target_position if
## it is moving or sliding and finishes the move step when arriving.
func _process(delta):
	if not (is_moving or is_sliding):
		return
	
	position = position.move_toward(target_position, MOVE_SPEED * delta)
	
	if position == target_position:
		_finish_move_step()


## Finalizes a move or slide step: clears movement flags,
## releases the reserved tile and emits stone_reached_target.
func _finish_move_step():
	is_moving = false
	is_sliding = false
	
	FieldReservation.release(self)
	Signals.stone_reached_target.emit()
