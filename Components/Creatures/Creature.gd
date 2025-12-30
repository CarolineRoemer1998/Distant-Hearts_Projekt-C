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
@onready var visuals: Node2D = $Visuals

@onready var sweat_particles: GPUParticles2D = $SweatParticles
@onready var audio_teleport: AudioStreamPlayer2D = $AudioTeleport

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

var steps_to_walk_back : Array[Vector2] = []
var is_blown_by_wind := false:
	set(val):
		is_blown_by_wind = val
		Signals.creature_is_blown_by_wind.emit(val)

var parent_node : Node = null

# -----------------------------------------------------------
# Init
# -----------------------------------------------------------

func _ready():
	Signals.level_done.connect(deactivate)
	Signals.bees_stop_flying.connect(walk_to_free_tile_if_bees_nearby)
	Signals.teleporter_entered.connect(start_teleport)
	Signals.wind_blows.connect(get_blown_by_wind)

	animated_sprite_creature.modulate = Constants.CREATURE_MODULATE_UNPOSSESSED
	animated_sprite_creature.frame = 0
	border.frame = 0
	parent_node = get_parent()

	add_to_group(Constants.GROUP_NAME_CREATURE)

	target_position = position.snapped(Constants.GRID_SIZE / 2)
	init_position = global_position
	position = target_position

	animation_tree.get("parameters/playback").travel("Idle")
	set_animation_direction(init_direction)

func _process(delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group(Constants.GROUP_NAME_PLAYER)
		
	if steps_to_walk_back.size() > 0:
		position = position.move_toward(steps_to_walk_back[0], delta*Constants.MOVE_SPEED)
		if abs(global_position[0]-steps_to_walk_back[0][0]) < 0.01 and abs(global_position[1]-steps_to_walk_back[0][1]) < 0.01:
			global_position = steps_to_walk_back[0]
			steps_to_walk_back.erase(steps_to_walk_back[0])
	
	if is_blown_by_wind:
		position = position.move_toward(target_position, delta*Constants.MOVE_BY_WIND_SPEED)
		if global_position.distance_to(target_position) < 0.01:
			global_position = target_position
			is_blown_by_wind = false


# -----------------------------------------------------------
# Undo State
# -----------------------------------------------------------

func get_info() -> Dictionary:
	return {
		"name": name,
		"global_position": global_position,
		"current_direction": current_direction,
		"target_position": target_position,

		"neighbor_right": neighbor_right,
		"neighbor_bottom": neighbor_bottom,
		"neighbor_left": neighbor_left,
		"neighbor_top": neighbor_top,

		"has_not_moved": has_not_moved,
		"just_teleported": just_teleported
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
	just_teleported = info.get("just_teleported")

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
	
	#var parent = get_parent()
	#merged_creature.call_deferred("reparent", [parent])
	merged_creature.reparent(parent_node)
	
	merged_creature.position = creature_to_merge_with.position
	Globals.is_level_finished = true

	await get_tree().create_timer(0.025).timeout

	creature_to_merge_with.shrink()
	shrink()

	merged_creature.visible = true
	merged_creature.appear()

	Signals.level_done.emit()
	return true


# -----------------------------------------------------------
# Teleport
# -----------------------------------------------------------

func start_teleport(teleporter_manager: TeleporterManager, body: Node2D):
	if body != self:
		return
	
	var creatures_on_tile = get_tree().get_nodes_in_group(Constants.GROUP_NAME_CREATURE)
	for c in creatures_on_tile.duplicate():
		if c.name == self.name:
			creatures_on_tile.erase(c)
		elif c.target_position != global_position.snapped(Constants.GRID_SIZE / 2):
			creatures_on_tile.erase(c)
	
	if not creatures_on_tile.is_empty():
		player.deactivate()
		return
	
	if not is_merging and creatures_on_tile.is_empty():# and not just_teleported:
		Globals.is_teleporting = true
		just_teleported = true
		audio_teleport.play()
		Signals.creature_started_teleporting.emit()
		is_teleporting = true
		
		var distance_to_flower_1 = global_position.distance_to(teleporter_manager.flower_1.global_position)
		var distance_to_flower_2 = global_position.distance_to(teleporter_manager.flower_2.global_position)
		
		if distance_to_flower_1 > distance_to_flower_2:
			target_position = teleporter_manager.flower_1.global_position
		else:
			target_position = teleporter_manager.flower_2.global_position
			
		#var transport_pos = min(target_position.distance_to(teleporter_manager.flower_1.global_position),target_position.distance_to(teleporter_manager.flower_2.global_position))
		#match global_position.snapped(Constants.GRID_SIZE / 2):
			#teleporter_manager.flower_1.global_position:
				#target_position = teleporter_manager.flower_2.global_position
			#teleporter_manager.flower_2.global_position:
				#target_position = teleporter_manager.flower_1.global_position
		animation_player.play("Shrink_Teleport")

func teleport():
	if is_teleporting:
		position = target_position
		visible = true
		appear()

func get_current_teleporter() -> Teleporter:
	for t in get_tree().get_nodes_in_group(Constants.GROUP_NAME_TELEPORTERS):
		if t.global_position == global_position and t.is_activated:
			return t
	return null

func set_not_teleporting():
	finish_teleport()

func finish_teleport():
	Globals.is_teleporting = false
	Signals.creature_finished_teleporting.emit(self)
	is_teleporting = false
	var wind = get_tree().get_first_node_in_group(Constants.GROUP_NAME_WIND) as Wind
	if wind:
		wind.request_shadow_update()
		wind.check_for_objects_to_blow({})


# -----------------------------------------------------------
# Simple Animation Wrappers
# -----------------------------------------------------------

func shrink():
	animation_player.play("Shrink")

func appear():
	animation_player.play("Appear_Teleport")

func disappear():
	queue_free()

func tremble():
	sweat_particles.emitting = true

func stop_tremble():
	sweat_particles.emitting = false

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


## -----------------------------------------------------------
## Bee Detection / Avoidance
## -----------------------------------------------------------

func play_failed_step_in_direction_animation():
	match current_direction:
		Vector2.UP:
			animation_player.play("failed_step_up")
			player.audio_bump_into_wall.play()
		Vector2.RIGHT:
			animation_player.play("failed_step_right")
			player.audio_bump_into_wall.play()
		Vector2.DOWN:
			animation_player.play("failed_step_down")
			player.audio_bump_into_wall.play()
		Vector2.LEFT:
			animation_player.play("failed_step_left")
			player.audio_bump_into_wall.play()

func walk_to_free_tile_if_bees_nearby():
	if is_possessed or Helper.get_collision_on_tile(global_position, (1 << Constants.LAYER_BIT_BEES), get_world_2d()).is_empty():
		return
	var i = 0
	var result_bees = Helper.get_collision_on_tile(StateSaver.get_creature_pos_in_state_from_back(i, self), (1 << Constants.LAYER_BIT_BEES), get_world_2d())
	var steps_back : Array[Vector2] = []
	while not result_bees.is_empty():
		if StateSaver.get_creature_pos_in_state_from_back(i, self) != global_position and (steps_back.size() == 0 or StateSaver.get_creature_pos_in_state_from_back(i, self) != steps_back[steps_back.size()-1]):
			steps_back.append(StateSaver.get_creature_pos_in_state_from_back(i, self))
		i += 1
		result_bees = Helper.get_collision_on_tile(StateSaver.get_creature_pos_in_state_from_back(i, self), (1 << Constants.LAYER_BIT_BEES), get_world_2d())
	if StateSaver.get_creature_pos_in_state_from_back(i, self) != global_position and (steps_back.size() == 0 or StateSaver.get_creature_pos_in_state_from_back(i, self) != steps_back[steps_back.size()-1]):
		steps_back.append(StateSaver.get_creature_pos_in_state_from_back(i, self))
	steps_to_walk_back = steps_back
	if steps_to_walk_back.size() > 0:
		tremble()

func get_blown_by_wind(list_of_blown_objects: Dictionary, blow_direction: Vector2, _wind_particles: GPUParticles2D):
	if is_possessed:
		pass
	else:
		for obj in list_of_blown_objects:
			if list_of_blown_objects[obj]["Object"].name == name:
				target_position = global_position + (Constants.GRID_SIZE*blow_direction*list_of_blown_objects[obj]["travel_distance"]).snapped(Constants.GRID_SIZE / 2)
				is_blown_by_wind = true
				
