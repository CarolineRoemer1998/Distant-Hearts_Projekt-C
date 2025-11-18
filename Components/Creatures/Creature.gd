extends CharacterBody2D
class_name Creature

enum COLOR {
	Blue, ## First color option
	Yellow ## Second color option
}

@export var color : COLOR = COLOR.Blue ## Color of the Creature.
@export var init_direction := Vector2.DOWN ## Direction the Creature looks at in the beginning of the level it is in.

@onready var init_position : Vector2
@onready var merged_creature: MergedCreature = $MergedCreature

@onready var animated_sprite_creature: AnimatedSprite2D = $Visuals/AnimatedSpriteCreature
@onready var animation_player: AnimationPlayer = $Visuals/AnimationPlayer
@onready var border: AnimatedSprite2D = $Visuals/AnimatedSpriteBorder
@onready var animation_tree: AnimationTree = $Visuals/AnimationTree

var current_direction := init_direction
var target_position: Vector2

var neighbor_right : Creature = null
var neighbor_bottom : Creature = null
var neighbor_left : Creature = null
var neighbor_top : Creature = null

var is_active := true
var has_not_moved := true

var is_merging := false

var is_teleporting := false
var just_teleported := false


func _ready():
	Signals.level_done.connect(deactivate)
	Signals.teleporter_activated.connect(start_teleport)
	
	animated_sprite_creature.frame = 0
	border.frame = 0
	
	add_to_group(Constants.GROUP_NAME_CREATURE)
	
	target_position = position.snapped(Constants.GRID_SIZE / 2)
	init_position = global_position
	position = target_position
	
	animation_tree.get("parameters/playback").travel("Idle")
	set_animation_direction(init_direction)


# -----------------------------------------------------------
# State Serialisation (Undo)
# -----------------------------------------------------------

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
		set_animation_direction(init_direction)
	has_not_moved = info.get("has_not_moved")


# -----------------------------------------------------------
# Animation
# -----------------------------------------------------------

func set_animation_direction(direction: Vector2 = current_direction) -> void:
	current_direction = direction
	animation_tree.set("parameters/Idle/BlendSpace2D/blend_position", direction)


# -----------------------------------------------------------
# Aktivität / Merge
# -----------------------------------------------------------

func deactivate():
	is_active = false


func get_neighbor_in_direction_is_mergable(direction : Vector2) -> Creature:
	match direction:
		Vector2.RIGHT: return neighbor_right
		Vector2.DOWN:  return neighbor_bottom
		Vector2.LEFT:  return neighbor_left
		Vector2.UP:    return neighbor_top
	return null


func merge(creature_to_merge_with : Creature) -> bool:
	if creature_to_merge_with == null:
		return false
	
	if not is_active or is_merging:
		return false
	
	is_merging = true
	creature_to_merge_with.is_merging = true
	
	# MergedCreature in die gleiche Ebene wie die normalen Creatures ziehen
	merged_creature.reparent(get_parent())
	merged_creature.position = creature_to_merge_with.position
	
	# Creatures kurz anzeigen, dann "zusammenschrumpfen"
	await get_tree().create_timer(0.1).timeout
	
	shrink()
	creature_to_merge_with.shrink()
	
	merged_creature.visible = true
	merged_creature.appear()
	
	Signals.level_done.emit()
	return true


# -----------------------------------------------------------
# Teleport
# -----------------------------------------------------------

func start_teleport(teleporter: Teleporter):
	var current_teleporter := get_current_teleporter()
	if current_teleporter != null and not is_merging and not just_teleported:
		Signals.creature_started_teleporting.emit()
		is_teleporting = true
		target_position = teleporter.global_position
		animation_player.play("Shrink_Teleport")


func teleport():
	if is_teleporting:
		position = target_position
		visible = true
		appear()


func get_current_teleporter() -> Teleporter:
	var teleporters = get_tree().get_nodes_in_group(Constants.GROUP_NAME_TELEPORTER)
	for t in teleporters:
		if t.global_position == global_position and t.is_activated:
			return t
	return null


func set_not_teleporting():
	# Beibehaltung des alten Namens für Animation/Signals, aber klarere Logik hier bündeln
	finish_teleport()


func finish_teleport():
	Signals.creature_finished_teleporting.emit()
	is_teleporting = false


# -----------------------------------------------------------
# Simple Animation Wrappers
# -----------------------------------------------------------

func shrink():
	animation_player.play("Shrink")


func appear():
	animation_player.play("Appear_Teleport")


func disappear():
	queue_free()


# -----------------------------------------------------------
# Neighbor Detection
# -----------------------------------------------------------

func _set_neighbor_for_direction(direction: Vector2, creature: Creature) -> void:
	match direction:
		Vector2.RIGHT:
			neighbor_right = creature
		Vector2.DOWN:
			neighbor_bottom = creature
		Vector2.LEFT:
			neighbor_left = creature
		Vector2.UP:
			neighbor_top = creature


# Creature steht neben einer anderen
func on_creature_to_right(body: Node2D) -> void:
	if body is Creature and body.name != name:
		_set_neighbor_for_direction(Vector2.RIGHT, body)


func on_creature_to_bottom(body: Node2D) -> void:
	if body is Creature and body.name != name:
		_set_neighbor_for_direction(Vector2.DOWN, body)


func on_creature_to_left(body: Node2D) -> void:
	if body is Creature and body.name != name:
		_set_neighbor_for_direction(Vector2.LEFT, body)


func on_creature_to_top(body: Node2D) -> void:
	if body is Creature and body.name != name:
		_set_neighbor_for_direction(Vector2.UP, body)


# Creature steht nicht mehr neben einer anderen
func _on_creature_right_gone(body: Node2D) -> void:
	if body is Creature:
		_set_neighbor_for_direction(Vector2.RIGHT, null)


func _on_creature_bottom_gone(body: Node2D) -> void:
	if body is Creature:
		_set_neighbor_for_direction(Vector2.DOWN, null)


func _on_creature_left_gone(body: Node2D) -> void:
	if body is Creature:
		_set_neighbor_for_direction(Vector2.LEFT, null)


func _on_creature_top_gone(body: Node2D) -> void:
	if body is Creature:
		_set_neighbor_for_direction(Vector2.UP, null)


# -----------------------------------------------------------
# Collision für direktes Mergen bei Überlappung
# -----------------------------------------------------------

func _on_area_2d_self_body_entered(body: Node2D) -> void:
	if body == self:
		return
	
	if body is Creature:
		merge(body)
