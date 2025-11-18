extends Node

var fields : = {} # { Object : Vector2 }

func _ready() -> void:
	Signals.level_switched.connect(clear_all)

func reserve(object, tiles: Array[Vector2]) -> void:
	object.disable_collision_layer()
	fields[object] = tiles.duplicate()
	

func release(object) -> void:
	object.enable_collision_layer()
	fields.erase(object)

func clear_all() -> void:
	fields.clear()

func is_reserved(pos: Vector2) -> bool:
	for tiles in fields.values():
		if pos in tiles:
			return true
	return false

func get_reserved_spot(object) -> Vector2:
	if fields.has(object):
		return fields.get(object)
	else:
		return Vector2.ZERO
