extends CharacterBody2D

class_name Stone

const MOVE_SPEED := 500.0

var target_position: Vector2
var is_moving := false
var is_sliding := false

var buffer_target_position := Vector2.ZERO
var buffer_direction := Vector2.ZERO
#var buffer_world : World2D = null


func _ready():
	add_to_group(str(Constants.GROUP_NAME_STONES))
	activate_layer()
	target_position = position.snapped(Constants.GRID_SIZE / 2)
	position = target_position

func get_info() -> Dictionary:
	return {
		"global_position": global_position,
		"target_position": target_position
	}

func set_info(info : Dictionary):
	global_position = info.get("global_position")
	target_position = global_position
	is_moving = false
	is_sliding = false

func slide(goal_position: Vector2) -> bool:
	if not is_sliding:
		FieldReservation.reserve(self, [goal_position])
		is_sliding = true
		target_position = goal_position
		return true
	else:
		return false

func get_can_be_pushed(new_pos : Vector2, _direction : Vector2) -> bool:
	if new_pos != null and _direction != null:
		var world = get_world_2d()
		buffer_target_position = new_pos
		buffer_direction = _direction
		
		if not is_moving and not is_sliding:
			# Überprüfe auf Hindernisse hinter Stein
			var push_collision = Helper.get_collision_on_tile(buffer_target_position + buffer_direction * Constants.GRID_SIZE, Constants.LAYER_MASK_BLOCKING_OBJECTS, world)
			# Falls Tür hinter Stein, checken ob sie offen ist
			for i in push_collision:
				if i.collider is Door and not i.collider.door_is_closed:
					return true
			# Keine Hindernisse hinterm Stein
			if push_collision.is_empty():
				return true
		
	buffer_target_position = Vector2.ZERO
	buffer_direction = Vector2.ZERO
	return false

func push():
	if get_can_be_pushed(buffer_target_position, buffer_direction):
		target_position = buffer_target_position + (buffer_direction * Constants.GRID_SIZE)
		is_moving = true
		
	buffer_target_position = Vector2.ZERO
	buffer_direction = Vector2.ZERO

func activate_layer():
	set_collision_layer_value(Constants.LAYER_BIT_STONE, true)

func deactivate_layer():
	set_collision_layer_value(Constants.LAYER_BIT_STONE, false)

func _process(delta):
	if is_moving or is_sliding:
		position = position.move_toward(target_position, MOVE_SPEED * delta)
		if position == target_position:
			is_moving = false
			is_sliding = false
			FieldReservation.release(self)
			Signals.stone_reached_target.emit()
