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

var is_avoiding_bees := false

## Initializes the creature when the scene starts:
## connects signals, aligns to the grid, sets initial animation and direction.
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

func _process(delta: float) -> void:
	print(position)
	if target_position != global_position and is_avoiding_bees:
		global_position = position.move_toward(target_position, Constants.MOVE_SPEED * delta)
	if abs(position - target_position)[0] < 0.1 and abs(position - target_position)[1] < 0.1:
		position = target_position
		is_avoiding_bees = false

# -----------------------------------------------------------
# State Serialisation (Undo)
# -----------------------------------------------------------

## Returns a Dictionary snapshot of the creature state
## used for Undo/Redo (position, direction, neighbors, etc.).
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

## Restores the creature state from a Dictionary snapshot.
## Used for Undo, including direction and neighbor references.
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

## Updates the current direction and applies it to the creature's
## BlendSpace animation. Defaults to the current_direction.
func set_animation_direction(direction: Vector2 = current_direction) -> void:
	current_direction = direction
	animation_tree.set("parameters/Idle/BlendSpace2D/blend_position", direction)

# -----------------------------------------------------------
# Activity / Merge
# -----------------------------------------------------------
## Deactivates the creature so it no longer reacts to merge or teleport logic.
func deactivate():
	is_active = false

## Returns the neighboring creature in the given direction
## that is eligible to be merged with, or null if none exists.
func get_neighbor_in_direction_is_mergable(direction : Vector2) -> Creature:
	match direction:
		Vector2.RIGHT: return neighbor_right
		Vector2.DOWN:  return neighbor_bottom
		Vector2.LEFT:  return neighbor_left
		Vector2.UP:    return neighbor_top
	return null

## Tries to merge this creature with the given creature.
## Returns true if the merge successfully started and completed (level_done emitted).
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

## Starts the teleport process if the creature is standing on an active teleporter
## and is not currently merging or just teleported. Plays the shrink animation.
func start_teleport(teleporter: Teleporter):
	var current_teleporter := get_current_teleporter()
	if current_teleporter != null and not is_merging and not just_teleported:
		Signals.creature_started_teleporting.emit()
		is_teleporting = true
		target_position = teleporter.global_position
		animation_player.play("Shrink_Teleport")

## Finishes the visual teleport move: places the creature at the target_position,
## makes it visible and plays the appear animation if teleporting is active.
func teleport():
	if is_teleporting:
		position = target_position
		visible = true
		appear()

## Finds and returns the active teleporter the creature is currently standing on,
## or null if none is found or not activated.
func get_current_teleporter() -> Teleporter:
	var teleporters = get_tree().get_nodes_in_group(Constants.GROUP_NAME_TELEPORTER)
	for t in teleporters:
		if t.global_position == global_position and t.is_activated:
			return t
	return null

## Keeps the old method name for compatibility and forwards to finish_teleport
## to centralize teleport ending logic.
func set_not_teleporting():
	# Beibehaltung des alten Namens für Animation/Signals, aber klarere Logik hier bündeln
	finish_teleport()

## Ends the teleport state: emits creature_finished_teleporting and
## clears the is_teleporting flag.
func finish_teleport():
	Signals.creature_finished_teleporting.emit()
	is_teleporting = false

# -----------------------------------------------------------
# Simple Animation Wrappers
# -----------------------------------------------------------

## Plays the "Shrink" animation for this creature.
func shrink():
	animation_player.play("Shrink")

## Plays the "Appear_Teleport" animation for this creature.
func appear():
	animation_player.play("Appear_Teleport")

## Removes this creature from the scene tree permanently.
func disappear():
	queue_free()

# -----------------------------------------------------------
# Neighbor Detection
# -----------------------------------------------------------

## Helper that assigns a neighbor reference for the given direction
## (right, down, left, up) to the provided creature (or null to clear).
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

## Called when another creature is detected to the right.
## Sets neighbor_right if the body is a different creature instance.
func on_body_to_right_entered(body: Node2D) -> void:
	if body is Creature and body.name != name:
		_set_neighbor_for_direction(Vector2.RIGHT, body)

## Called when another creature is detected below.
## Sets neighbor_bottom if the body is a different creature instance.
func on_body_to_bottom_entered(body: Node2D) -> void:
	if body is Creature and body.name != name:
		_set_neighbor_for_direction(Vector2.DOWN, body)


## Called when another creature is detected to the left.
## Sets neighbor_left if the body is a different creature instance.
func on_body_to_left_entered(body: Node2D) -> void:
	if body is Creature and body.name != name:
		_set_neighbor_for_direction(Vector2.LEFT, body)


## Called when another creature is detected above.
## Sets neighbor_top if the body is a different creature instance.
func on_body_to_top_entered(body: Node2D) -> void:
	if body is Creature and body.name != name:
		_set_neighbor_for_direction(Vector2.UP, body)

func on_bees_to_top_entered(area: Area2D) -> void:
	if area.get_parent() is BeeSwarm:
		is_avoiding_bees = true
		# TODO: Checken, ob die richtung überhaupt frei ist (wand), sonst andere richtung gehen oder nicht ausweichen
		target_position = position + (Vector2.DOWN * Constants.GRID_SIZE)

func on_bees_to_left_entered(area: Area2D) -> void:
	if area.get_parent() is BeeSwarm:
		is_avoiding_bees = true
		# TODO: Checken, ob die richtung überhaupt frei ist (wand), sonst andere richtung gehen oder nicht ausweichen
		target_position = position + (Vector2.RIGHT * Constants.GRID_SIZE)

func on_bees_to_bottom_entered(area: Area2D) -> void:
	if area.get_parent() is BeeSwarm:
		is_avoiding_bees = true
		# TODO: Checken, ob die richtung überhaupt frei ist (wand), sonst andere richtung gehen oder nicht ausweichen
		target_position = position + (Vector2.UP * Constants.GRID_SIZE)

func on_bees_to_right_entered(area: Area2D) -> void:
	if area.get_parent() is BeeSwarm:
		is_avoiding_bees = true
		# TODO: Checken, ob die richtung überhaupt frei ist (wand), sonst andere richtung gehen oder nicht ausweichen
		target_position = position + (Vector2.LEFT * Constants.GRID_SIZE)

## Called when the creature on the right side is no longer detected.
## Clears neighbor_right if the body was a creature.
func _on_creature_right_gone(body: Node2D) -> void:
	if body is Creature:
		_set_neighbor_for_direction(Vector2.RIGHT, null)

## Called when the creature below is no longer detected.
## Clears neighbor_bottom if the body was a creature.
func _on_creature_bottom_gone(body: Node2D) -> void:
	if body is Creature:
		_set_neighbor_for_direction(Vector2.DOWN, null)

## Called when the creature on the left side is no longer detected.
## Clears neighbor_left if the body was a creature.
func _on_creature_left_gone(body: Node2D) -> void:
	if body is Creature:
		_set_neighbor_for_direction(Vector2.LEFT, null)

## Called when the creature above is no longer detected.
## Clears neighbor_top if the body was a creature.
func _on_creature_top_gone(body: Node2D) -> void:
	if body is Creature:
		_set_neighbor_for_direction(Vector2.UP, null)

# -----------------------------------------------------------
# Collision for direct merging on overlap
# -----------------------------------------------------------

## Called when another body enters this creature's Area2D used for overlap checks.
## If the body is a different creature, attempts to merge with it.
func _on_area_2d_self_body_entered(body: Node2D) -> void:
	if body == self:
		return
	
	if body is Creature:
		merge(body)
