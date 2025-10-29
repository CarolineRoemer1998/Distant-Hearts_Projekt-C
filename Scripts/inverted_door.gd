extends Node2D

class_name Inverted_Door

@export var buttons: Array[NodePath] = [] # Set this from the editor
@export var single_activation: bool = false

@onready var button_refs: Array = []
@onready var sprite: Sprite2D = $Sprite2D
@onready var collider: CollisionShape2D = $CollisionShape2D

var opened_door_sprite := preload("res://Sprites/fence-gate-open.png")
var closed_door_sprite := preload("res://Sprites/fence-gate-closed.png")

var door_is_closed := true



func _ready():
	# Resolve NodePaths to actual button nodes
	_open_door()
	for path in buttons:
		var button = get_node(path)
		if button:
			button_refs.append(button)
			button.activated.connect(_on_button_state_changed)
			button.deactivated.connect(_on_button_state_changed)
	
	_check_buttons()

func _on_button_state_changed():
	_check_buttons()

func _check_buttons():
	for button in button_refs:
		if not button.is_pressed():
			_open_door()
			return
	_close_door()

func _open_door():
	if door_is_closed:
		door_is_closed = false
		collider.set_deferred("disabled", true)
		sprite.texture = opened_door_sprite


func _close_door():
	if not door_is_closed:
		door_is_closed = true
		collider.set_deferred("disabled", false)
		sprite.texture = closed_door_sprite
	if single_activation:
		for button in button_refs:
			button.set_door_is_permanently_opened()
