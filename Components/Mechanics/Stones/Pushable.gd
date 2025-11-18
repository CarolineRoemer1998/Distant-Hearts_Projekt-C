extends CharacterBody2D

class_name Stone

const MOVE_SPEED := 500.0

var target_position: Vector2
var is_moving := false
var is_sliding := false

# Zwischengespeicherte Push-Infos, werden von get_can_be_pushed gesetzt
var pending_target_position: Vector2 = Vector2.ZERO
var pending_direction: Vector2 = Vector2.ZERO


func _ready():
	add_to_group(str(Constants.GROUP_NAME_STONES))
	enable_collision_layer()
	target_position = position.snapped(Constants.GRID_SIZE / 2)
	position = target_position


# -----------------------------------------------------------
# State (z. B. für Undo)
# -----------------------------------------------------------

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
	
	pending_target_position = Vector2.ZERO
	pending_direction = Vector2.ZERO


# -----------------------------------------------------------
# Movement / Push / Slide
# -----------------------------------------------------------

func slide(slide_target: Vector2) -> bool:
	if is_sliding:
		return false
	
	FieldReservation.reserve(self, [slide_target])
	is_sliding = true
	target_position = slide_target
	return true


func get_can_be_pushed(new_pos : Vector2, direction : Vector2) -> bool:
	# Bereits in Bewegung → kann gerade nicht weiter gepusht werden
	if is_moving or is_sliding:
		_reset_pending_push()
		return false
	
	var world = get_world_2d()
	
	# Feld direkt hinter dem Stein (in Push-Richtung)
	var behind_stone_pos = new_pos + direction * Constants.GRID_SIZE
	var push_collision = Helper.get_collision_on_tile(
		behind_stone_pos,
		Constants.LAYER_MASK_BLOCKING_OBJECTS,
		world
	)
	
	# Falls eine Tür hinter dem Stein steht, checken ob sie offen ist
	for hit in push_collision:
		if hit.collider is Door:
			if not hit.collider.door_is_closed:
				_set_pending_push(new_pos, direction)
				return true
			else:
				_reset_pending_push()
				return false
	
	# Wenn gar nichts dahinter steht, kann geschoben werden
	if push_collision.is_empty():
		_set_pending_push(new_pos, direction)
		return true
	
	# Ansonsten blockiert
	_reset_pending_push()
	return false


func push():
	# Erwartet, dass get_can_be_pushed vorher erfolgreich aufgerufen wurde
	if pending_target_position == Vector2.ZERO and pending_direction == Vector2.ZERO:
		return
	
	target_position = pending_target_position + (pending_direction * Constants.GRID_SIZE)
	is_moving = true
	
	# Auf Eis → direkt Slide-Ziel berechnen
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


func _set_pending_push(new_pos: Vector2, direction: Vector2) -> void:
	pending_target_position = new_pos
	pending_direction = direction


func _reset_pending_push() -> void:
	pending_target_position = Vector2.ZERO
	pending_direction = Vector2.ZERO


# -----------------------------------------------------------
# Collision Layer
# -----------------------------------------------------------

func enable_collision_layer():
	set_collision_layer_value(Constants.LAYER_BIT_STONE, true)


func disable_collision_layer():
	set_collision_layer_value(Constants.LAYER_BIT_STONE, false)


# -----------------------------------------------------------
# Update Loop
# -----------------------------------------------------------

func _process(delta):
	if not (is_moving or is_sliding):
		return
	
	position = position.move_toward(target_position, MOVE_SPEED * delta)
	
	if position == target_position:
		_finish_move_step()


func _finish_move_step():
	is_moving = false
	is_sliding = false
	
	FieldReservation.release(self)
	Signals.stone_reached_target.emit()
