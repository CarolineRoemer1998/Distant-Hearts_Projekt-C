extends Node2D
class_name Door

enum Mode {
	ALL_PRESSED_OPENS,   # normale Tür
	ALL_PRESSED_CLOSES,  # invertierte Tür
}

@export var mode: Mode = Mode.ALL_PRESSED_OPENS
@export var starts_closed := true
@export var single_activation_open := false
@export var single_activation_close := false
@export var buttons: Array[NodePath] = []

@onready var sprite: Sprite2D = $Sprite2D
@onready var collider: CollisionShape2D = $CollisionShape2D

var opened_door_sprite := preload(Constants.SPRITE_PATH_DOOR_OPEN)
var closed_door_sprite := preload(Constants.SPRITE_PATH_DOOR_CLOSED)

var button_refs: Array = []
var door_is_closed := true

func _ready():
	add_to_group(str(Constants.GROUP_NAME_DOORS))

	for path in buttons:
		var button = get_node_or_null(path)
		if button:
			button_refs.append(button)
			button.activated.connect(_check_buttons)
			button.deactivated.connect(_check_buttons)

	door_is_closed = starts_closed
	_apply_visual_state()
	_check_buttons()

func get_info() -> Dictionary:
	return {
		"door_is_closed": door_is_closed
	}

func set_info(info : Dictionary):
	door_is_closed = info.get("door_is_closed")
	_check_buttons()

func _check_buttons():
	var all_pressed := true
	for button in button_refs:
		if not button.is_pressed():
			all_pressed = false
			break

	var should_be_closed := false
	if mode == Mode.ALL_PRESSED_OPENS:
		# wie bisher bei Door: alle gedrückt -> offen
		should_be_closed = not all_pressed
	else:
		# wie bei Inverted_Door: alle gedrückt -> zu
		should_be_closed = all_pressed

	if should_be_closed:
		_close_door()
	else:
		_open_door()

func _open_door():
	if door_is_closed:
		door_is_closed = false
		collider.disabled = true
		sprite.texture = opened_door_sprite

		if single_activation_open:
			for b in button_refs:
				b.set_door_is_permanently_opened()

func _close_door():
	if not door_is_closed:
		door_is_closed = true
		collider.set_deferred("disabled", false)
		sprite.texture = closed_door_sprite

		if single_activation_close:
			for b in button_refs:
				b.set_door_is_permanently_opened()

func _apply_visual_state():
	# Collider an/aus
	collider.disabled = not door_is_closed

	# Sprite wechseln
	if door_is_closed:
		sprite.texture = closed_door_sprite
	else:
		sprite.texture = opened_door_sprite
