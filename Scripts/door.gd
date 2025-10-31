extends Node2D

class_name Door

@export var buttons: Array[NodePath] = [] # Set this from the editor
@export var single_activation: bool = false

@onready var button_refs: Array = []
@onready var sprite: Sprite2D = $Sprite2D
@onready var collider: CollisionShape2D = $CollisionShape2D

var opened_door_sprite := preload("res://Sprites/fence-gate-open.png")
var closed_door_sprite := preload("res://Sprites/fence-gate-closed.png")

var door_is_closed := true

func _ready():
	add_to_group(str(Constants.GROUP_NAME_DOORS))
	# Resolve NodePaths to actual button nodes
	for path in buttons:
		var button = get_node(path)
		if button:
			button_refs.append(button)
			button.activated.connect(_on_button_state_changed)
			button.deactivated.connect(_on_button_state_changed)
	
	_check_buttons()

func get_door_info() -> Dictionary:
	return {
		"door_is_closed": door_is_closed
	}

func set_door_info(info : Dictionary):
	door_is_closed = info.get("door_is_closed")
	
	if door_is_closed:
		_close_door()
	else:
		_open_door()

func _on_button_state_changed():
	_check_buttons()

func _check_buttons():
	for button in button_refs:
		if not button.is_pressed():
			_close_door()
			return
	_open_door()

func _open_door():
	if door_is_closed:
		door_is_closed = false
		collider.disabled = true
		sprite.texture = opened_door_sprite
	if single_activation:
		for button in button_refs:
			button.set_door_is_permanently_opened()

func _close_door():
	if not door_is_closed:
		door_is_closed = true
		collider.disabled = false
		sprite.texture = closed_door_sprite
