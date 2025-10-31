extends CharacterBody2D

class_name Stone

const GRID_SIZE := Vector2(64, 64)
const MOVE_SPEED := 500.0

var target_position: Vector2
var is_moving := false
var is_sliding := false

func _ready():
	add_to_group(str(Constants.GROUP_NAME_STONES))
	target_position = position.snapped(GRID_SIZE / 2)
	position = target_position

func get_stone_info() -> Dictionary:
	return {
		"global_position": global_position,
		"target_position": target_position
	}

func set_stone_info(info : Dictionary):
	global_position = info.get("global_position")
	target_position = global_position
	is_moving = false
	is_sliding = false

func slide(goal_position: Vector2) -> bool:
	if is_sliding:
		target_position = goal_position
		return true
	else:
		return false

func push(goal_position: Vector2) -> bool:
	if not is_moving and not is_sliding:
		target_position += goal_position
		is_moving = true
		return true
	else:
		return false

func _process(delta):
	if is_moving or is_sliding:
		position = position.move_toward(target_position, MOVE_SPEED * delta)
		if position == target_position:
			is_moving = false
			is_sliding = false
