extends CharacterBody2D

class_name Creature

enum CREATURE_COLOR {Red, Blue, Yellow, Green, Purple, Turquois, Orange, Pink}

@export var init_direction := Vector2.DOWN
@export var own_color : CREATURE_COLOR = CREATURE_COLOR.Red
@export var desired_color : CREATURE_COLOR = CREATURE_COLOR.Green

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var border: AnimatedSprite2D = $AnimatedSpriteBorder
@onready var area_2d_right: Area2D = $Area2D_Right
@onready var area_2d_bottom: Area2D = $Area2D_Bottom
@onready var area_2d_left: Area2D = $Area2D_Left
@onready var area_2d_top: Area2D = $Area2D_Top
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var init_position : Vector2

var current_direction := init_direction
var target_position: Vector2

var neighbor_right : Creature = null
var neighbor_bottom : Creature = null
var neighbor_left : Creature = null
var neighbor_top : Creature = null

var has_not_moved := true


func _ready():
	self.add_to_group(Constants.GROUP_NAME_CREATURE)
	target_position = position.snapped(Constants.GRID_SIZE / 2)
	init_position = global_position
	position = target_position
	animation_tree.get("parameters/playback").travel("Idle")
	animation_tree.set("parameters/Idle/BlendSpace2D/blend_position", init_direction)

func _process(delta: float) -> void:
	pass
	#if self.name=="CreatureBlue":
		#print("current_direction: ", current_direction, "\ntarget_position: ", target_position, "\n\n")

func get_info() -> Dictionary:
	return {
		"global_position": global_position,
		"current_direction": current_direction,
		"target_position": target_position,
		
		"neighbor_right": neighbor_right,
		"neighbor_bottom": neighbor_bottom,
		"neighbor_left": neighbor_left,
		"neighbor_top": neighbor_top,
		
		"has_not_moved": has_not_moved
	}

func set_info(info : Dictionary):
	global_position = info.get("global_position")
	current_direction = info.get("current_direction")
	target_position = global_position
	
	neighbor_right = info.get("neighbor_right")
	neighbor_bottom = info.get("neighbor_bottom")
	neighbor_left = info.get("neighbor_left")
	neighbor_top = info.get("neighbor_top")
	
	if info.get("has_not_moved"):
		set_animation_direction_by_val(init_direction)
	has_not_moved = info.get("has_not_moved")


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
