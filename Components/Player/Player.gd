extends CharacterBody2D
class_name Player

@export var trail_scene: PackedScene
@export var hearts: Array[Sprite2D]
@export var undo_particles: PackedScene

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_tree: AnimationTree = $AnimationTree

@onready var label_press_f_to_control: Label = $LabelPressFToControl
@onready var label_press_f_to_stop_control: Label = $LabelPressFToStopControl

@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var audio_control: AudioStreamPlayer2D = $AudioControl
@onready var audio_uncontrol: AudioStreamPlayer2D = $AudioUncontrol

@onready var step_timer: Timer = $StepTimer
@onready var avoid_timer: Timer = $AvoidTimer

var is_active := true

var direction := Vector2.ZERO
var input_direction := Vector2.ZERO
var current_direction := Vector2.ZERO
var buffered_direction: Vector2 = Vector2.ZERO

var last_position: Vector2 = Vector2.ZERO
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

var bees_are_flying := false
var is_avoiding := false
var planted_flower_last_step := false

var is_level_finished := false
## TODO: Deaktivieren während Bienen fliegen


# ------------------------------------------------
# READY
# ------------------------------------------------

## Initializes the player, connects signals, aligns to grid.
func _ready():
	add_to_group(Constants.GROUP_NAME_PLAYER)
	animated_sprite_2d.modulate = Constants.PLAYER_MODULATE_VISIBLE
	Signals.stone_reached_target.connect(reset_stone_push_state)
	Signals.level_done.connect(set_level_finished)
	Signals.player_move_finished.connect(on_move_step_finished)
	Signals.creature_started_teleporting.connect(deactivate)
	Signals.creature_finished_teleporting.connect(activate)
	Signals.bees_start_flying.connect(handle_bees_start_flying)
	Signals.bees_stop_flying.connect(handle_bees_stop_flying)

	target_position = position.snapped(Constants.GRID_SIZE / 2)
	position = target_position

	animation_tree.get("parameters/playback").travel("Idle")

## Main update loop: movement, UI, input.
func _process(delta):
	update_movement(delta)
	update_heart_icons()
	handle_input()


# ------------------------------------------------
# INPUT
# ------------------------------------------------

## Handles cancel, movement, interaction and level switching.
func handle_input():
	if Input.is_action_just_pressed("ui_cancel"):
		SceneSwitcher.go_to_settings()
		return
	
	if is_level_finished:
		if Input.is_action_just_pressed("ui_accept"):
			SceneSwitcher.go_to_next_level()
	elif bees_are_flying or is_avoiding:
		return
	elif is_active and not is_avoiding:
		handle_movement_input(Vector2.ZERO)
		handle_interaction_input()
	elif is_level_finished:
		if Input.is_action_just_pressed("ui_accept"):
			SceneSwitcher.go_to_next_level()

## Returns raw directional input from arrow/WASD keys.
func _read_input_direction() -> Vector2:
	if Input.is_action_pressed("Player_Up"):
		return Vector2.UP
	if Input.is_action_pressed("Player_Down"):
		return Vector2.DOWN
	if Input.is_action_pressed("Player_Left"):
		return Vector2.LEFT
	if Input.is_action_pressed("Player_Right"):
		return Vector2.RIGHT
	return Vector2.ZERO

## Handles movement requests, buffering and move validation.
func handle_movement_input(_input_direction: Vector2, step_timer_time := Constants.TIMER_STEP):
	if currently_possessed_creature:
		var bee_area = Helper.get_collision_on_area(
			currently_possessed_creature.global_position,
			1 << Constants.LAYER_BIT_BEE_AREA,
			get_world_2d()
		)
		if not bee_area.is_empty():
			return
		
	if is_avoiding or bees_are_flying:
		return
	
	if not can_move or is_avoiding:
		return

	input_direction = _input_direction
	var read_dir = _read_input_direction()
	if read_dir != Vector2.ZERO and _input_direction == Vector2.ZERO:
		input_direction = read_dir

	if input_direction == Vector2.ZERO:
		return

	direction = input_direction
	if input_direction == _input_direction:
		input_direction = Vector2.ZERO
	
	prepare_movement(direction, direction, step_timer_time)

## Prepares a normal (input-based) movement step.
func prepare_movement(_direction: Vector2, animation_direction: Vector2, step_timer_time := Constants.TIMER_STEP):
	last_position = global_position
	direction = _direction
	set_animation_direction(animation_direction)
	can_move = false
	pushable_stone_in_direction = null
	step_timer.start(step_timer_time)

	if is_moving:
		buffered_direction = _direction
	else:
		if Helper.can_move_in_direction(position, _direction, get_world_2d(), currently_possessed_creature!=null, self):
			set_is_moving(true)

## Handles switching possession of creatures.
func handle_interaction_input():
	if Input.is_action_just_pressed("Interact") and not is_moving:
		Signals.state_changed.emit(get_info())
		if currently_possessed_creature:
			unpossess()
		else:
			possess()


# ------------------------------------------------
# STATE (UNDO)
# ------------------------------------------------

## Creates a snapshot of the player state for undo.
func get_info() -> Dictionary:
	return {
		"global_position": global_position,
		"is_active": is_active,
		"last_position": last_position,

		"direction": direction,
		"current_direction": current_direction,
		"buffered_direction": buffered_direction,
		"is_on_ice": is_on_ice,

		"hovering_over": hovering_over,
		"currently_possessed_creature": currently_possessed_creature,
		
		#"can_move": can_move,
		"bees_are_flying": bees_are_flying,
		"is_avoiding": is_avoiding,
		"planted_flower_last_step": planted_flower_last_step
	}

## Restores a previous player state from undo.
func set_info(info : Dictionary):
	if global_position != info.get("global_position"):
		spawn_undo_particles(global_position)

	global_position = info["global_position"]
	target_position = global_position
	last_position = info["last_position"]
	is_active = info["is_active"]

	direction = info["direction"]
	current_direction = info["current_direction"]
	buffered_direction = info["buffered_direction"]

	# Bewegung komplett stoppen
	set_is_moving(false)
	is_on_ice = info["is_on_ice"]
	is_sliding = false
	reset_stone_push_state()

	bees_are_flying = info["bees_are_flying"]
	is_avoiding = info["is_avoiding"]
	
	planted_flower_last_step = info["planted_flower_last_step"]
	can_move = true

	step_timer.stop()
	avoid_timer.stop()

	set_animation_direction(direction)

	var info_creature = info["currently_possessed_creature"]
	if info_creature and currently_possessed_creature == null:
		possess()
	elif currently_possessed_creature and info_creature == null:
		unpossess()

func get_sprites() -> Array[Node2D]:
	var result : Array[Node2D]= []
	result.append(animated_sprite_2d)
	if currently_possessed_creature != null:
		result.append(currently_possessed_creature.visuals)
	return result

## Spawns undo particles at the given position.
func spawn_undo_particles(world_pos: Vector2):
	var particles = undo_particles.instantiate()
	add_child(particles)
	particles.z_index = 1000
	particles.top_level = true
	particles.global_position = world_pos
	particles.restart()
	particles.emitting = true
	particles.finished.connect(particles.queue_free)


# ------------------------------------------------
# ANIMATION
# ------------------------------------------------

## Updates direction for player and possessed creature animation.
func set_animation_direction(_direction: Vector2):
	if _direction != Vector2.ZERO:
		animation_tree.set("parameters/Idle/BlendSpace2D/blend_position", _direction)

	if currently_possessed_creature:
		currently_possessed_creature.current_direction = direction
		if _direction != Vector2.ZERO:
			currently_possessed_creature.animation_tree.set(
				"parameters/Idle/BlendSpace2D/blend_position", _direction
			)


# ------------------------------------------------
# MOVEMENT
# ------------------------------------------------

## Handles movement each frame, including bees and teleportation.
func update_movement(delta):
	if currently_possessed_creature and currently_possessed_creature.is_teleporting:
		return
		
	if not is_moving:
		if not bees_are_flying:
			activate()
		return

	if is_on_ice and currently_possessed_creature and not is_moving_on_ice:
		update_ice_slide_target()

	position = position.move_toward(target_position, Constants.PLAYER_MOVE_SPEED * delta)

	if currently_possessed_creature:
		currently_possessed_creature.position = currently_possessed_creature.position.move_toward(
			target_position, Constants.PLAYER_MOVE_SPEED * delta
		)

	if position == target_position:
		if currently_possessed_creature and currently_possessed_creature.just_teleported:
			currently_possessed_creature.just_teleported = false
		
		if currently_possessed_creature:
			var result_bee_area = Helper.get_collision_on_area(
				currently_possessed_creature.global_position,
				1 << Constants.LAYER_BIT_BEE_AREA,
				get_world_2d()
			)
			if not result_bee_area.is_empty():
				handle_bees_near_creature(currently_possessed_creature)
				return
			
		Signals.player_move_finished.emit()

## Called when a movement step ends; handles buffering.
func on_move_step_finished():
	set_is_moving(false)
	is_sliding = false
	is_pushing_stone_on_ice = false
	is_moving_on_ice = false

	if buffered_direction != Vector2.ZERO:
		set_is_moving(
			Helper.can_move_in_direction(
				position,
				direction,
				get_world_2d(),
				currently_possessed_creature!=null,
				self
			)
		)
		buffered_direction = Vector2.ZERO
	
	if is_avoiding:
		is_avoiding = false
		can_move = false
		avoid_timer.start(Constants.TIMER_STEP_AFTER_AVOIDING)

## Computes slide target and updates ice-related flags.
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

## Resets stone push state after stone finishes moving.
func reset_stone_push_state(_stone: Stone = null):
	is_pushing_stone_on_ice = false

## Disables player input.
func deactivate():
	is_active = false

## Enables player input.
func activate():
	is_active = true

func set_level_finished():
	deactivate()
	is_level_finished = true


# ------------------------------------------------
# BEES
# ------------------------------------------------

func handle_bees_start_flying():
	buffered_direction = Vector2.ZERO
	can_move = false
	bees_are_flying = true

func handle_bees_stop_flying():
	bees_are_flying = false
	planted_flower_last_step = true
	
	if currently_possessed_creature:
		var result_bee_area = Helper.get_collision_on_area(
			currently_possessed_creature.global_position,
			1 << Constants.LAYER_BIT_BEE_AREA,
			get_world_2d()
		)
		if not result_bee_area.is_empty():
			handle_bees_near_creature(currently_possessed_creature)

## Wird ausgelöst, wenn Bienen in der Nähe einer Creature sind (nur noch Player-intern).
func handle_bees_near_creature(creature: Creature):
	if creature == null:
		return
	if creature != currently_possessed_creature:
		return
		
	is_avoiding = true
	buffered_direction = Vector2.ZERO
	can_move = false
	_start_bee_avoid_step()

## Startet einen einzelnen Ausweichschritt rückwärts von den Bienen weg.
func _start_bee_avoid_step():	
	# Vorwärtsrichtung (zur Biene) merken
	var forward_dir = direction
	if forward_dir == Vector2.ZERO:
		forward_dir = current_direction
	
	if forward_dir == Vector2.ZERO:
		is_avoiding = false
		can_move = true
		return
	
	var move_dir = -forward_dir  # Bewegung weg von den Bienen
	
	# Animation: zur Biene hin schauen (rückwärts wegspringen)
	set_animation_direction(forward_dir)
	
	# Bewegung: tatsächlich rückwärts gehen
	direction = move_dir
	pushable_stone_in_direction = null
	buffered_direction = Vector2.ZERO
	
	if Helper.can_move_in_direction(
		position,
		move_dir,
		get_world_2d(),
		currently_possessed_creature != null,
		self,
		true
	):
		set_is_moving(true)
	else:
		# Kein Platz zum Ausweichen
		is_avoiding = false
		can_move = true


# ------------------------------------------------
# MOVE START
# ------------------------------------------------

## Enables movement and starts a new move step.
func set_is_moving(v: bool):
	is_moving = v
	if is_moving:
		begin_move_step()

## Calculates the next tile, handles merge/push/FX, and sends undo snapshot.
func begin_move_step():
	target_position += direction * Constants.GRID_SIZE
	current_direction = direction

	is_on_ice = Helper.check_is_ice(target_position, get_world_2d())

	if currently_possessed_creature:
		var merge_target = currently_possessed_creature.get_neighbor_in_direction_is_mergable(direction)
		if merge_target:
			var merged = await currently_possessed_creature.merge(merge_target)
			if merged:
				deactivate()

		if pushable_stone_in_direction:
			pushable_stone_in_direction.push()

	spawn_trail(position)
	play_step_sound()
	if not is_avoiding:
		Signals.state_changed.emit(get_info())
		
		var collider_lily_pads = Helper.get_collision_on_tile(last_position, (1 << Constants.LAYER_BIT_LILY_PAD), get_world_2d())
		if not collider_lily_pads.is_empty():
			Signals.player_left_lily_pad.emit(last_position)

## Plays randomised movement step sound.
func play_step_sound():
	audio_stream_player_2d.pitch_scale = Constants.STEP_SOUND_PITCH_SCALES.pick_random()
	audio_stream_player_2d.volume_db = Constants.STEP_SOUND_VOLUME_CHANGE.pick_random()
	audio_stream_player_2d.stop()
	audio_stream_player_2d.play()


# ------------------------------------------------
# HOVER / POSSESSION
# ------------------------------------------------

## Updates which creature the player is hovering over.
func update_hovered_creature(is_hovering: bool, creature: Creature):
	if is_hovering:
		hovering_over = creature
		if not currently_possessed_creature:
			label_press_f_to_control.visible = true
	else:
		hovering_over = null
		label_press_f_to_control.visible = false

## Releases control of the currently possessed creature.
func unpossess():
	if currently_possessed_creature and is_instance_valid(currently_possessed_creature):
		update_hovered_creature(true, currently_possessed_creature)
		update_visibility(true)

		currently_possessed_creature.border.visible = false
		currently_possessed_creature.set_animation_direction()
		currently_possessed_creature.is_possessed = false
		currently_possessed_creature.animated_sprite_creature.modulate = Constants.CREATURE_MODULATE_UNPOSSESSED
		currently_possessed_creature.player = null
		currently_possessed_creature = null

		audio_uncontrol.play()

## Takes control of a hovered creature.
func possess():
	if hovering_over and hovering_over is Creature:
		currently_possessed_creature = hovering_over
		currently_possessed_creature.is_possessed = true
		currently_possessed_creature.animated_sprite_creature.modulate = Constants.CREATURE_MODULATE_POSSESSED
		currently_possessed_creature.player = self
		currently_possessed_creature.has_not_moved = false
		currently_possessed_creature.border.visible = true

		update_visibility(false)
		audio_control.play()

		direction = currently_possessed_creature.current_direction
		set_animation_direction(direction)

		currently_possessed_creature.position = target_position
		currently_possessed_creature.target_position = target_position


# ------------------------------------------------
# TELEPORTER
# ------------------------------------------------

## Connects or disconnects from teleporter-entered events.
func set_is_standing_on_teleporter(val: bool):
	if val:
		Signals.teleporter_entered.connect(on_teleporter_entered)
	elif Signals.teleporter_entered.is_connected(on_teleporter_entered):
		Signals.teleporter_entered.disconnect(on_teleporter_entered)

## Teleports player and possessed creature when triggered.
func on_teleporter_entered(teleporter: Teleporter):
	if currently_possessed_creature:
		currently_possessed_creature.start_teleport(teleporter)
		global_position = teleporter.global_position
		target_position = global_position


# ------------------------------------------------
# VISIBILITY
# ------------------------------------------------

## Updates player visibility and UI hint visibility.
func update_visibility(make_visible : bool):
	animated_sprite_2d.modulate = (
		Constants.PLAYER_MODULATE_VISIBLE if make_visible
		else Constants.PLAYER_MODULATE_INVISIBLE
	)

	if hovering_over:
		label_press_f_to_control.visible = make_visible
		label_press_f_to_stop_control.visible = not make_visible

## Triggered when entering a creature detection area.
func _on_creature_detected(body: Node):
	if body is Creature:
		update_hovered_creature(true, body)

## Triggered when leaving a creature detection area.
func _on_creature_undetected(body: Node):
	if body is Creature and hovering_over == body:
		update_hovered_creature(false, body)


# ------------------------------------------------
# VFX
# ------------------------------------------------

## Spawns a movement trail particle at the given position.
func spawn_trail(input_position: Vector2):
	var trail : GPUParticles2D = trail_scene.instantiate()
	get_tree().current_scene.add_child(trail)
	trail.global_position = input_position
	trail.texture = load(Constants.trails.pick_random()) as Texture2D
	trail.restart()


# ------------------------------------------------
# HEARTS
# ------------------------------------------------

## Updates visibility and positions of heart indicators.
func update_heart_icons():
	if not currently_possessed_creature or currently_possessed_creature.is_teleporting:
		for h in hearts:
			h.visible = false
		return

	var c = currently_possessed_creature

	hearts[3].visible = c.neighbor_right != null
	hearts[3].position = position + Constants.FIELD_POSITION_RIGHT

	hearts[1].visible = c.neighbor_bottom != null
	hearts[1].position = position + Constants.FIELD_POSITION_BOTTOM

	hearts[2].visible = c.neighbor_left != null
	hearts[2].position = position + Constants.FIELD_POSITION_LEFT

	hearts[0].visible = c.neighbor_top != null
	hearts[0].position = position + Constants.FIELD_POSITION_TOP

## Re-enables movement after step timer finishes.
func _on_step_timer_timeout():
	if is_avoiding or bees_are_flying:
		return
	can_move = true


func _on_avoid_timer_timeout() -> void:
	if not planted_flower_last_step:
		StateSaver.remove_last_state()
	can_move = true
	planted_flower_last_step = false
