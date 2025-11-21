extends CharacterBody2D
class_name Player

@export var trail_scene: PackedScene ## Takes a GPUParticles2D Node which displays the trails the player leaves behind when moving.
@export var hearts: Array[Sprite2D] ## Takes 4 Sprite2Ds, to show a heart when a creature is nearby another creature.
@export var undo_particles: PackedScene  ## GPUParticles2D shown where the player was before pressing undo-button.

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_tree: AnimationTree = $AnimationTree

@onready var label_press_f_to_control: Label = $LabelPressFToControl
@onready var label_press_f_to_stop_control: Label = $LabelPressFToStopControl

@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var audio_control: AudioStreamPlayer2D = $AudioControl
@onready var audio_uncontrol: AudioStreamPlayer2D = $AudioUncontrol

@onready var step_timer: Timer = $StepTimer

var is_active := true

var direction := Vector2.ZERO
var current_direction := Vector2.ZERO
var buffered_direction: Vector2 = Vector2.ZERO

var target_position: Vector2:
	set(val):
		target_position = val.snapped(Constants.GRID_SIZE / 2)

var is_moving := false
var is_moving_on_ice := false
var is_on_ice := false
var is_sliding := false
var is_pushing_stone_on_ice := false
var can_move := true

var hovering_over: Creature = null
var currently_possessed_creature: Creature = null
var pushable_stone_in_direction : Stone = null


func _ready():
	self.add_to_group(Constants.GROUP_NAME_PLAYER)
	
	Signals.stone_reached_target.connect(reset_stone_push_state)
	Signals.level_done.connect(deactivate)
	Signals.player_move_finished.connect(on_move_step_finished)
	Signals.creature_started_teleporting.connect(deactivate)
	Signals.creature_finished_teleporting.connect(activate)
	#Signals.creature_avoided_bees.connect(set_moving_direction)
	
	# Spieler korrekt auf Grid ausrichten
	target_position = position.snapped(Constants.GRID_SIZE / 2)
	position = target_position
	animation_tree.get("parameters/playback").travel("Idle")


func _process(delta):
	update_movement(delta)
	update_heart_icons()
	handle_input()


# ------------------------------------------------
# Input
# ------------------------------------------------
## Handles input: escape/cancel for the settings menu,
## movement and interaction while the player is active.
func handle_input():
	if Input.is_action_just_pressed("ui_cancel"):
		SceneSwitcher.go_to_settings()
		return
	
	if is_active:
		handle_movement_input()
		handle_interaction_input()
	else:
		# Szenewechsel durch Tastatur, Maus oder Gamepad
		if Input.is_action_just_pressed("ui_accept"):
			SceneSwitcher.go_to_next_level()

## Reads movement input (up/down/left/right), sets the direction
## and optionally starts a new move step (including buffering for held input).
func handle_movement_input():
	if not can_move:
		return
	
	var input_direction := Vector2.ZERO
	if Input.is_action_pressed("Player_Up"):
		input_direction = Vector2.UP
	elif Input.is_action_pressed("Player_Down"):
		input_direction = Vector2.DOWN
	elif Input.is_action_pressed("Player_Left"):
		input_direction = Vector2.LEFT
	elif Input.is_action_pressed("Player_Right"):
		input_direction = Vector2.RIGHT
	
	if input_direction == Vector2.ZERO:
		return
	
	#set_moving_direction(input_direction, currently_possessed_creature)
	direction = input_direction
	set_animation_direction(direction)
	
	can_move = false
	pushable_stone_in_direction = null
	step_timer.start(Constants.TIMER_STEP)
	
	if is_moving:
		buffered_direction = direction
	else:
		if can_move_in_direction(position, direction):
			#if currently_possessed_creature:
				#var bee_dir = currently_possessed_creature.get_bee_position_if_nearby()
				#if bee_dir != null:
					#currently_possessed_creature.avoid_bees(bee_dir)
					## Player soll der Creature folgen:
					#target_position = currently_possessed_creature.target_position
					#global_position = target_position
					#position = target_position
					#return
			set_is_moving(true)

#func set_moving_direction(_pos: Vector2, creature: Creature):
	#if currently_possessed_creature == creature:
		#global_position = _pos
		#target_position = global_position
		#print("Player Pos: ", global_position)
	#
##a	direction = dir
	##set_animation_direction(direction)
	#
	##can_move = false
	##pushable_stone_in_direction = null
	##step_timer.start(Constants.TIMER_STEP)
	##
	##if is_moving:
		##buffered_direction = direction
	##else:
		##if can_move_in_direction(position, direction):
			##set_is_moving(true)

## Starts or stops controlling a Creature
## when the player is not currently moving.
func handle_interaction_input():
	if Input.is_action_just_pressed("Interact") and not is_moving:
		if hovering_over and hovering_over is Creature:
			Signals.state_changed.emit(get_info())
			if currently_possessed_creature:
				unpossess()
			else:
				possess()


# ------------------------------------------------
# State serialisation (Undo)
# ------------------------------------------------
## Returns a Dictionary snapshot of the current player state
## used for Undo/Redo.
func get_info() -> Dictionary:
	return {
		"global_position": global_position,
		"is_active": is_active,
		
		"direction": direction,
		"current_direction": current_direction,
		"buffered_direction": buffered_direction,
		
		"is_on_ice": is_on_ice,
		
		"hovering_over": hovering_over,
		"currently_possessed_creature": currently_possessed_creature
	}

## Restores the player state from a Dictionary snapshot.
## Used for Undo, including undo particles and possession state.
func set_info(info : Dictionary):
	if global_position != info.get("global_position"):
		spawn_undo_particles(global_position)
	
	global_position = info.get("global_position")
	is_active = info.get("is_active")
	
	direction = info.get("direction")
	current_direction = info.get("current_direction")
	buffered_direction = info.get("buffered_direction")
	
	target_position = global_position
	
	set_is_moving(false)
	is_on_ice = info.get("is_on_ice")
	is_sliding = false
	can_move = true
	reset_stone_push_state()
	
	set_animation_direction(direction)
	
	if info.get("currently_possessed_creature") and currently_possessed_creature == null:
		possess()
	elif currently_possessed_creature and info.get("currently_possessed_creature") == null:
		unpossess()

## Spawns undo particles at world_pos, plays them once
## and automatically frees them when finished.
func spawn_undo_particles(world_pos: Vector2):
	var particles = undo_particles.instantiate()
	add_child(particles)
	particles.z_index = 1000               # über Tiles/UI der Welt
	particles.top_level = true             # erbt den Canvas-Kontext des Levels
	particles.global_position = world_pos
	particles.restart()
	particles.emitting = true
	particles.finished.connect(particles.queue_free)


# ------------------------------------------------
# Animation
# ------------------------------------------------
## Updates the facing direction in the player's animation (and in the
## possessed creature if present). Ignores Vector2.ZERO.
func set_animation_direction(_direction: Vector2):
	if _direction != Vector2.ZERO:
		animation_tree.set("parameters/Idle/BlendSpace2D/blend_position", _direction)
	if currently_possessed_creature:
		currently_possessed_creature.current_direction = direction
		if _direction != Vector2.ZERO:
			currently_possessed_creature.animation_tree.set("parameters/Idle/BlendSpace2D/blend_position", _direction)


# ------------------------------------------------
# Movement
# ------------------------------------------------
## Updates the position of the player (and the possessed creature) each frame,
## including ice sliding and teleport-related edge cases.
func update_movement(delta):
	if currently_possessed_creature and currently_possessed_creature.is_avoiding_bees:
		# Player folgt nur, bewegt aber weder sich noch die Creature aktiv
		global_position = currently_possessed_creature.global_position
		position = global_position
		target_position = global_position
		is_moving = false  # optional, aber aufgeräumter
		return
	
	if not is_moving:
		return
	
	if currently_possessed_creature and currently_possessed_creature.is_teleporting:
		return
	
	if is_on_ice and currently_possessed_creature and not is_moving_on_ice:
		update_ice_slide_target()
	
	position = position.move_toward(target_position, Constants.PLAYER_MOVE_SPEED * delta)

	if currently_possessed_creature:
		currently_possessed_creature.position = currently_possessed_creature.position.move_toward(
			target_position, Constants.PLAYER_MOVE_SPEED * delta)
	
	if position == target_position:
		if currently_possessed_creature:
			var bee_dir = currently_possessed_creature.get_bee_position_if_nearby()
			if bee_dir != null:
				currently_possessed_creature.avoid_bees(bee_dir)
				# Player soll der Creature folgen:
				target_position = currently_possessed_creature.target_position
				global_position = target_position
				position = target_position
				return
		if currently_possessed_creature and currently_possessed_creature.just_teleported:
			currently_possessed_creature.just_teleported = false
		Signals.player_move_finished.emit()

## Called when a single move step (one tile) has finished.
## Resets movement flags and processes buffered movement input.
func on_move_step_finished():
	set_is_moving(false)
	is_sliding = false
	is_pushing_stone_on_ice = false
	is_moving_on_ice = false
	
	if buffered_direction != Vector2.ZERO:
		set_is_moving(can_move_in_direction(position, direction))
		buffered_direction = Vector2.ZERO

## Checks if the player (and the possessed creature) is allowed to move
## in the given direction. Considers walls, doors and stones.
## On success, sets pushable_stone_in_direction if a stone can be pushed.
func can_move_in_direction(_position: Vector2, _direction: Vector2) -> bool:
	var new_pos = _position + _direction * Constants.GRID_SIZE
	var world = get_world_2d()
	
	# Queries für alle relevanten Bit Layers
	var result_stones = Helper.get_collision_on_tile(new_pos, (1 << Constants.LAYER_BIT_STONE), world)
	var result_doors = Helper.get_collision_on_tile(new_pos, (1 << Constants.LAYER_BIT_DOOR), world)
	var result_wall_outside = Helper.get_collision_on_tile(new_pos, (1 << Constants.LAYER_BIT_LEVEL_WALL), world)
	var result_wall_inside = Helper.get_collision_on_tile(new_pos, (1 << Constants.LAYER_BIT_WALL_AND_PLAYER), world)
	
	if (result_stones.is_empty() and result_doors.is_empty() and result_wall_outside.is_empty() and result_wall_inside.is_empty()) \
	or (currently_possessed_creature == null and result_wall_outside.is_empty()):
		return true
	
	if not result_wall_outside.is_empty() \
	or (currently_possessed_creature != null and (not result_wall_inside.is_empty() and not result_stones.is_empty() and not result_doors.is_empty())):
		return false
	
	if not result_doors.is_empty() and not result_doors[0].collider.door_is_closed and result_stones.is_empty():
		return true
	
	if not result_stones.is_empty() and result_stones[0].collider.get_can_be_pushed(new_pos, _direction):
		pushable_stone_in_direction = result_stones[0].collider
		return true
	
	buffered_direction = Vector2.ZERO
	return false

## Calculates the slide target on ice, updates target_position and sets
## flags related to ice movement. Also respects reserved tiles.
func update_ice_slide_target():
	target_position = Helper.get_slide_end(
		Constants.LAYER_MASK_BLOCKING_OBJECTS,
		current_direction,
		target_position,
		is_pushing_stone_on_ice,
		get_world_2d()
	)
	
	if FieldReservation.is_reserved(target_position):
		target_position -= current_direction * Constants.GRID_SIZE
	
	if not Helper.check_is_ice(target_position, get_world_2d()):
		is_on_ice = false
	
	is_moving_on_ice = true

## Resets the state that tracks whether a stone is currently being pushed
## on ice by the player.
func reset_stone_push_state():
	is_pushing_stone_on_ice = false

## Deactivates the player so that no input is processed.
func deactivate():
	is_active = false

## Reactivates the player (for example after teleporting).
func activate():
	is_active = true

## Sets is_moving and, if true, immediately starts a new move step,
## including merge, push, trail and sound logic.
func set_is_moving(_is_moving: bool):
	is_moving = _is_moving
	if is_moving:
		begin_move_step()

## Initializes a new move step: computes the next target tile,
## checks ice, tries to merge and pushes a prepared stone if present.
## Also emits state_changed and spawns visual/audio feedback.
func begin_move_step() -> void:
	target_position = target_position + direction * Constants.GRID_SIZE
	current_direction = direction
	
	is_on_ice = Helper.check_is_ice(target_position, get_world_2d())
	
	if currently_possessed_creature:
		var merge_target = currently_possessed_creature.get_neighbor_in_direction_is_mergable(direction)
		if merge_target != null:
			var merged = await currently_possessed_creature.merge(merge_target)
			if merged:
				deactivate()
		if pushable_stone_in_direction != null:
			pushable_stone_in_direction.push()
	
	spawn_trail(position)
	play_step_sound()
	
	Signals.state_changed.emit(get_info())

## Plays a step sound with random pitch and volume when the player
## moves by one tile.
func play_step_sound():
	audio_stream_player_2d.pitch_scale = Constants.STEP_SOUND_PITCH_SCALES.pick_random()
	audio_stream_player_2d.volume_db = Constants.STEP_SOUND_VOLUME_CHANGE.pick_random()
	audio_stream_player_2d.stop()
	audio_stream_player_2d.play()


# ------------------------------------------------
# Hover / Possession
# ------------------------------------------------
## Updates whether the player is currently hovering over a creature
## and controls the "Press F to control" label visibility.
func update_hovered_creature(is_hovering: bool, creature: Creature):
	if is_hovering:
		hovering_over = creature
		if currently_possessed_creature == null:
			label_press_f_to_control.visible = true
	else:
		hovering_over = null
		label_press_f_to_control.visible = false

## Stops possessing the current creature: restores player visibility,
## updates creature animation and plays the uncontrol sound.
func unpossess():
	if currently_possessed_creature and is_instance_valid(currently_possessed_creature):
		update_hovered_creature(true, currently_possessed_creature)
		update_visibility(true)
		currently_possessed_creature.border.visible = false
		currently_possessed_creature.set_animation_direction()
		currently_possessed_creature.is_possessed = false
		currently_possessed_creature = null
		audio_uncontrol.play()

## Starts possessing the currently hovered creature: shows its border,
## hides the player, syncs direction and position, and plays the control sound.
func possess():
	if hovering_over and hovering_over is Creature:
		currently_possessed_creature = hovering_over
		currently_possessed_creature.is_possessed = true
		currently_possessed_creature.has_not_moved = false
		currently_possessed_creature.border.visible = true
		update_visibility(false)
		audio_control.play()
		
		# direction an Creature anpassen
		direction = currently_possessed_creature.current_direction
		set_animation_direction(direction)
		
		# Position sofort synchronisieren
		currently_possessed_creature.position = target_position
		currently_possessed_creature.target_position = target_position


# ------------------------------------------------
# Teleporter
# ------------------------------------------------
## Registers or unregisters the player for teleporter events.
## val = true: player reacts to teleporter_entered signal.
func set_is_standing_on_teleporter(val: bool):
	if val:
		Signals.teleporter_entered.connect(on_teleporter_entered)
	elif Signals.teleporter_entered.is_connected(on_teleporter_entered):
		Signals.teleporter_entered.disconnect(on_teleporter_entered)

## Callback when a teleporter is triggered: starts teleporting
## the possessed creature and moves the player to the new position.
func on_teleporter_entered(teleporter: Teleporter):
	if currently_possessed_creature and is_active:
		currently_possessed_creature.start_teleport(teleporter)
		global_position = teleporter.global_position
		target_position = global_position


# ------------------------------------------------
# Sichtbarkeit / UI
# ------------------------------------------------
## Sets whether the player sprite is visible and updates the interaction
## labels depending on hover state.
func update_visibility(make_visible : bool):
	if make_visible:
		animated_sprite_2d.modulate = Constants.PLAYER_MODULATE_VISIBLE
	else:
		animated_sprite_2d.modulate = Constants.PLAYER_MODULATE_INVISIBLE
		
	if hovering_over:
		label_press_f_to_control.visible = make_visible
		label_press_f_to_stop_control.visible = !make_visible

## Called when the player enters a Creature's detection area.
## Marks that creature as currently hovered.
func _on_creature_detected(body: Node) -> void:
	if body is Creature:
		update_hovered_creature(true, body)

## Called when the player exits a Creature's detection area.
## Removes the hover state if it was the currently hovered Creature.
func _on_creature_undetected(body: Node) -> void:
	if body is Creature and hovering_over == body:
		update_hovered_creature(false, body)


# ------------------------------------------------
# VFX
# ------------------------------------------------
## Spawns a trail particle instance at input_position and plays it once.
## Typically called when starting a move step.
func spawn_trail(input_position: Vector2):
	var trail : GPUParticles2D = trail_scene.instantiate()
	get_tree().current_scene.add_child(trail)
	trail.global_position = input_position
	trail.texture = load(Constants.trails.pick_random()) as Texture2D
	trail.restart()


# ------------------------------------------------
# Herz-Anzeige
# ------------------------------------------------
## Updates the heart sprites around the player depending on whether
## the possessed Creature has neighbors in the four cardinal directions.
func update_heart_icons():
	# Wenn keine Kreatur gerade besessen ist → Herz aus
	if currently_possessed_creature == null or currently_possessed_creature.is_teleporting:
		for heart in hearts:
			heart.visible = false
		return

	var c := currently_possessed_creature

	if c.neighbor_right:
		hearts[3].position = self.position + Constants.FIELD_POSITION_RIGHT
		hearts[3].visible = true
	else:
		hearts[3].visible = false

	if c.neighbor_bottom != null:
		hearts[1].position = self.position + Constants.FIELD_POSITION_BOTTOM
		hearts[1].visible = true
	else:
		hearts[1].visible = false

	if c.neighbor_left:
		hearts[2].position = self.position + Constants.FIELD_POSITION_LEFT
		hearts[2].visible = true
	else:
		hearts[2].visible = false

	if c.neighbor_top:
		hearts[0].position = self.position + Constants.FIELD_POSITION_TOP
		hearts[0].visible = true
	else:
		hearts[0].visible = false

## Timer callback that re-enables movement input
## by setting can_move to true after a short delay.
func _on_step_timer_timeout() -> void:
	can_move = true
