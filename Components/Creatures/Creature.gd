extends CharacterBody2D
class_name Creature

enum COLOR {
	Blue,
	Yellow
}

@export var color : COLOR = COLOR.Blue
@export var init_direction := Vector2.DOWN

@onready var init_position : Vector2
@onready var merged_creature: MergedCreature = $MergedCreature

@onready var animated_sprite_creature: AnimatedSprite2D = $Visuals/AnimatedSpriteCreature
@onready var animation_player: AnimationPlayer = $Visuals/AnimationPlayer
@onready var border: AnimatedSprite2D = $Visuals/AnimatedSpriteBorder
@onready var animation_tree: AnimationTree = $Visuals/AnimationTree

var current_direction := init_direction

var target_position: Vector2 :
	set(val):
		target_position = val.snapped(Constants.GRID_SIZE / 2)

var neighbor_right : Creature = null
var neighbor_bottom : Creature = null
var neighbor_left : Creature = null
var neighbor_top : Creature = null

var is_possessed := false
var player : Player = null

var is_active := true
var has_not_moved := true
var is_merging := false

var is_teleporting := false
var just_teleported := false

var is_avoiding_bees := false
var last_escape_direction := Vector2.ZERO
var hard_escape_lock := false


# -----------------------------------------------------------
# Init
# -----------------------------------------------------------

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
# Process (Bee Avoidance)
# -----------------------------------------------------------

func _process(delta: float) -> void:
	var bee_dir = get_bee_position_if_nearby(global_position)
	
	if bee_dir != null:
		Signals.bees_near_creature.emit()
	elif bee_dir == null:
		Signals.bees_not_near_creature.emit()
	
	# Reset escape state when bees are gone
	if bee_dir == null:
		last_escape_direction = Vector2.ZERO
		hard_escape_lock = false

	# Bees nearby: decide avoidance (possessed vs. unpossessed)
	if bee_dir != null and not is_avoiding_bees:

		if is_possessed:
			var opposite = -player.input_direction
			player.handle_movement_input(avoid_bees(bee_dir, opposite))
		else:
			var dir = avoid_bees(bee_dir, Vector2.ZERO)
			target_position = global_position + dir * Constants.GRID_SIZE
			is_avoiding_bees = true

	# Move while avoiding
	if is_avoiding_bees and target_position != global_position:
		global_position = position.move_toward(target_position, Constants.MOVE_SPEED * delta)

	# Reached tile → stop avoiding
	if is_avoiding_bees and position.distance_to(target_position) < 0.1:
		position = target_position
		is_avoiding_bees = false
		last_escape_direction = Vector2.ZERO
		hard_escape_lock = false


# -----------------------------------------------------------
# Undo State
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
# Activity / Merge
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

	merged_creature.reparent(get_parent())
	merged_creature.position = creature_to_merge_with.position

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
	var t := get_current_teleporter()
	if t != null and not is_merging and not just_teleported:
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
	for t in get_tree().get_nodes_in_group(Constants.GROUP_NAME_TELEPORTER):
		if t.global_position == global_position and t.is_activated:
			return t
	return null

func set_not_teleporting():
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
		Vector2.RIGHT: neighbor_right = creature
		Vector2.DOWN:  neighbor_bottom = creature
		Vector2.LEFT:  neighbor_left = creature
		Vector2.UP:    neighbor_top = creature

func on_body_to_right_entered(body: Node2D):    if body is Creature and body != self: _set_neighbor_for_direction(Vector2.RIGHT, body)
func on_body_to_bottom_entered(body: Node2D):   if body is Creature and body != self: _set_neighbor_for_direction(Vector2.DOWN, body)
func on_body_to_left_entered(body: Node2D):     if body is Creature and body != self: _set_neighbor_for_direction(Vector2.LEFT, body)
func on_body_to_top_entered(body: Node2D):      if body is Creature and body != self: _set_neighbor_for_direction(Vector2.UP, body)

func _on_creature_right_gone(body: Node2D):     if body is Creature: _set_neighbor_for_direction(Vector2.RIGHT, null)
func _on_creature_bottom_gone(body: Node2D):    if body is Creature: _set_neighbor_for_direction(Vector2.DOWN, null)
func _on_creature_left_gone(body: Node2D):      if body is Creature: _set_neighbor_for_direction(Vector2.LEFT, null)
func _on_creature_top_gone(body: Node2D):       if body is Creature: _set_neighbor_for_direction(Vector2.UP, null)


# -----------------------------------------------------------
# Merge on Overlap
# -----------------------------------------------------------

func _on_area_2d_self_body_entered(body: Node2D) -> void:
	if body != self and body is Creature:
		merge(body)


# -----------------------------------------------------------
# Bee Detection / Avoidance
# -----------------------------------------------------------

func get_bee_position_if_nearby(check_pos: Vector2):
	var positions = [
		Constants.UP_LEFT, Constants.UP, Constants.UP_RIGHT,
		Constants.LEFT,    Constants.MIDDLE, Constants.RIGHT,
		Constants.DOWN_LEFT, Constants.DOWN, Constants.DOWN_RIGHT
	]

	for p in positions:
		if Helper.check_if_collides(check_pos + p * Constants.GRID_SIZE, Constants.LAYER_MASK_BEES, get_world_2d()):
			return p

	return null

func avoid_bees(bee_direction: Vector2, try_direction) -> Vector2:
	var order: Array[Vector2]

	match bee_direction:
		Constants.UP:
			order = [try_direction, Constants.DOWN, Constants.LEFT, Constants.RIGHT]
		Constants.UP_RIGHT:
			order = [try_direction, Constants.DOWN, Constants.LEFT]
		Constants.RIGHT:
			order = [try_direction, Constants.LEFT, Constants.DOWN, Constants.UP]
		Constants.DOWN_RIGHT:
			order = [try_direction, Constants.LEFT, Constants.UP]
		Constants.DOWN:
			order = [try_direction, Constants.LEFT, Constants.DOWN, Constants.UP]
		Constants.DOWN_LEFT:
			order = [try_direction, Constants.UP, Constants.RIGHT]
		Constants.LEFT:
			order = [try_direction, Constants.RIGHT, Constants.DOWN, Constants.UP]
		Constants.UP_LEFT:
			order = [try_direction, Constants.RIGHT, Constants.DOWN]
		Constants.MIDDLE:
			order = [Constants.RIGHT, Constants.DOWN, Constants.LEFT, Constants.UP]
		_:
			order = []

	return try_directions(order)


func try_directions(directions : Array[Vector2]) -> Vector2:
	if hard_escape_lock and last_escape_direction != Vector2.ZERO:
		if Helper.can_move_in_direction(position, last_escape_direction, get_world_2d(), true, true):
			return last_escape_direction
		hard_escape_lock = false
		last_escape_direction = Vector2.ZERO

	for d in directions:
		if d != Vector2.ZERO and Helper.can_move_in_direction(position, d, get_world_2d(), true, true):
			last_escape_direction = d
			hard_escape_lock = true
			return d

	last_escape_direction = Vector2.ZERO
	hard_escape_lock = false
	return Vector2.ZERO
