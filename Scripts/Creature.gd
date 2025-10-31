extends CharacterBody2D

class_name Creature

enum CREATURE_COLOR {Red, Blue, Yellow, Green, Purple, Turquois, Orange, Pink}

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var border: AnimatedSprite2D = $AnimatedSpriteBorder

@onready var area_2d_right: Area2D = $Area2D_Right
@onready var area_2d_bottom: Area2D = $Area2D_Bottom
@onready var area_2d_left: Area2D = $Area2D_Left
@onready var area_2d_top: Area2D = $Area2D_Top
@onready var animation_tree: AnimationTree = $AnimationTree

@export var init_direction := Vector2.DOWN
@export var own_color : CREATURE_COLOR = CREATURE_COLOR.Red
@export var desired_color : CREATURE_COLOR = CREATURE_COLOR.Green

const GRID_SIZE := Vector2(64, 64)
var target_position: Vector2

var neighbor_right : Creature = null
var neighbor_bottom : Creature = null
var neighbor_left : Creature = null
var neighbor_top : Creature = null
var current_direction := init_direction

@onready var init_position : Vector2

func _ready():
	target_position = position.snapped(GRID_SIZE / 2)
	init_position = global_position
	position = target_position
	animation_tree.get("parameters/playback").travel("Idle")
	animation_tree.set("parameters/Idle/BlendSpace2D/blend_position", init_direction)

func set_animation_direction():
	animation_tree.set("parameters/Idle/BlendSpace2D/blend_position", current_direction)

func set_animation_direction_by_val(direction):
	animation_tree.set("parameters/Idle/BlendSpace2D/blend_position", direction)

func can_merge_with(creature : Creature) -> bool:
	if self.desired_color == creature.own_color:
		return true
	else:
		return false

func shrink():
	animation_player.play("Shrink")

func disappear():
	queue_free()

# -----------------------------------------------------------
# Check if creature stands next to other creature
# -----------------------------------------------------------

func on_creature_to_right(body: Node2D) -> void:
	if body is Creature:
		neighbor_right = body


func on_creature_to_bottom(body: Node2D) -> void:
	if body is Creature:
		neighbor_bottom = body


func on_creature_to_left(body: Node2D) -> void:
	if body is Creature:
		neighbor_left = body


func on_creature_to_top(body: Node2D) -> void:
	if body is Creature:
		neighbor_top = body

# -----------------------------------------------------------
# Check if creature no longer stands next to other creature
# -----------------------------------------------------------

func _on_creature_right_gone(body: Node2D) -> void:
	if body is Creature:
		neighbor_right = null


func _on_creature_bottom_gone(body: Node2D) -> void:
	if body is Creature:
		neighbor_bottom = null


func _on_creature_left_gone(body: Node2D) -> void:
	if body is Creature:
		neighbor_left = null


func _on_creature_top_gone(body: Node2D) -> void:
	if body is Creature:
		neighbor_top = null
