extends CharacterBody2D
class_name Player

@export var trail_scene: PackedScene 
@export var hearts: Array[Sprite2D]
@export var undo_particles: PackedScene 

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_tree: AnimationTree = $AnimationTree

@onready var label_press_f_to_control: Label = $LabelPressFToControl
@onready var label_press_f_to_stop_control: Label = $LabelPressFToStopControl
#@onready var heart_TOP: Sprite2D = $Heart
#@onready var heart_BOTTOM: Sprite2D = $Heart2
#@onready var heart_LEFT: Sprite2D = $Heart3
#@onready var heart_RIGHT: Sprite2D = $Heart4

@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var audio_control: AudioStreamPlayer2D = $AudioControl
@onready var audio_uncontrol: AudioStreamPlayer2D = $AudioUncontrol

@onready var step_timer: Timer = $StepTimer

var is_active := true

var direction := Vector2.ZERO
var current_direction := Vector2.ZERO
var buffered_direction: Vector2 = Vector2.ZERO

var target_position: Vector2

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
	
	Signals.stone_reached_target.connect(set_is_not_pushing_stone_on_ice)
	Signals.level_done.connect(set_not_is_active)
	Signals.player_move_finished.connect(arrive_at_target_position)
	Signals.teleporter_entered.connect(teleport_to)
	
	# Spieler korrekt auf Grid ausrichten
	target_position = position.snapped(Constants.GRID_SIZE / 2)
	position = target_position
	animation_tree.get("parameters/playback").travel("Idle")

func _process(delta):
	move(delta)
	update_heart_visibility()
	handle_input()

func handle_input():
	if Input.is_action_just_pressed("ui_cancel"):
		SceneSwitcher.go_to_settings()
	
	elif is_active and (!currently_possessed_creature or (currently_possessed_creature and not currently_possessed_creature.is_teleporting)):
		# Wenn Input Bewegung ist
		if can_move and (Input.is_action_pressed("Player_Up") or Input.is_action_pressed("Player_Down") or Input.is_action_pressed("Player_Left") or Input.is_action_pressed("Player_Right")):
			# Bewegungsrichtungen
			if Input.is_action_pressed("Player_Up"):
				direction = Vector2.UP
			elif Input.is_action_pressed("Player_Down"):
				direction = Vector2.DOWN
			elif Input.is_action_pressed("Player_Left"):
				direction = Vector2.LEFT
			elif Input.is_action_pressed("Player_Right"):
				direction = Vector2.RIGHT
			
			can_move = false
			pushable_stone_in_direction = null
			step_timer.start()
			
			if is_moving:
				buffered_direction = direction
			else:
				if evaluate_can_move_in_direction(position, direction):
					set_is_moving(true)
			
			set_animation_direction(direction)
		
		# Interaktionsbutton
		elif Input.is_action_just_pressed("Interact"):
			if not is_moving:
				if hovering_over and hovering_over is Creature:
					Signals.state_changed.emit(get_info())
					if currently_possessed_creature:
						unpossess()
					else:
						possess()
	else:
		# Szenewechsel durch Tastatur, Maus oder Gamepad
		if Input.is_action_just_pressed("ui_accept"):
			SceneSwitcher.go_to_next_level()

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

func set_info(info : Dictionary):
	if global_position != info.get("global_position"):
		play_undo_particles(global_position)
	
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
	set_is_not_pushing_stone_on_ice()
	
	set_animation_direction(direction)
	
	if info.get("currently_possessed_creature") and currently_possessed_creature == null:
		possess()
	elif currently_possessed_creature and info.get("currently_possessed_creature") == null:
		unpossess()

func play_undo_particles(_pos: Vector2):
	var particles = undo_particles.instantiate()
	add_child(particles) #get_tree().current_scene.add_child(particles)
	particles.z_index = 1000               # über Tiles/UI der Welt
	particles.top_level = true            # erbt den Canvas-Kontext des Levels
	particles.global_position = _pos
	particles.restart()
	particles.emitting = true
	particles.finished.connect(particles.queue_free)

func set_animation_direction(_direction: Vector2):
	if _direction != Vector2.ZERO:
		animation_tree.set("parameters/Idle/BlendSpace2D/blend_position", _direction)
	if currently_possessed_creature:
		currently_possessed_creature.current_direction = direction
		if _direction != Vector2.ZERO:
			currently_possessed_creature.animation_tree.set("parameters/Idle/BlendSpace2D/blend_position", _direction)

func move(delta):
	if is_moving and (currently_possessed_creature == null or not currently_possessed_creature.is_teleporting):
		if is_on_ice and currently_possessed_creature and not is_moving_on_ice:
			move_on_ice()
			
		position = position.move_toward(target_position, Constants.PLAYER_MOVE_SPEED * delta)

		if currently_possessed_creature:
			currently_possessed_creature.position = currently_possessed_creature.position.move_toward(
				target_position, Constants.PLAYER_MOVE_SPEED * delta)
		
		if position == target_position:
			Signals.player_move_finished.emit()

func arrive_at_target_position():
	set_is_moving(false)
	is_sliding = false
	is_pushing_stone_on_ice = false
	is_moving_on_ice = false
	if buffered_direction != Vector2.ZERO:
		set_is_moving(evaluate_can_move_in_direction(position, direction))
		buffered_direction = Vector2.ZERO

func evaluate_can_move_in_direction(_position: Vector2, _direction: Vector2) -> bool:
	var new_pos = _position + _direction * Constants.GRID_SIZE
	var world = get_world_2d()
	
	# Queries für alle relevanten Bit Layers
	var result_stones = Helper.get_collision_on_tile(new_pos, (1 << Constants.LAYER_BIT_STONE), world)
	var result_doors = Helper.get_collision_on_tile(new_pos, (1 << Constants.LAYER_BIT_DOOR), world)
	var result_wall_outside = Helper.get_collision_on_tile(new_pos, (1 << Constants.LAYER_BIT_LEVEL_WALL), world)
	var result_wall_inside = Helper.get_collision_on_tile(new_pos, (1 << Constants.LAYER_BIT_WALL_AND_PLAYER), world)
	
	if (result_stones.is_empty() and result_doors.is_empty() and result_wall_outside.is_empty() and result_wall_inside.is_empty()) or (currently_possessed_creature == null and result_wall_outside.is_empty()):
		return true
	
	if not result_wall_outside.is_empty() or (currently_possessed_creature != null and (not result_wall_inside.is_empty() and not result_stones.is_empty() and not result_doors.is_empty())):
		return false
	
	if not result_doors.is_empty() and not result_doors[0].collider.door_is_closed and result_stones.is_empty():
		return true
	
	if not result_stones.is_empty() and result_stones[0].collider.get_can_be_pushed(new_pos, _direction):
		pushable_stone_in_direction = result_stones[0].collider
		return true
	
	buffered_direction = Vector2.ZERO
	return false

func move_on_ice():
	target_position = Helper.get_slide_end(Constants.LAYER_MASK_BLOCKING_OBJECTS, current_direction, target_position, is_pushing_stone_on_ice, get_world_2d())
	
	if FieldReservation.is_reserved(target_position):
		target_position -= current_direction * Constants.GRID_SIZE
	
	if not Helper.check_is_ice(target_position, get_world_2d()): 
		is_on_ice = false
	
	is_moving_on_ice = true

func set_is_not_pushing_stone_on_ice():
	is_pushing_stone_on_ice = false

func set_not_is_active():
	is_active = false

func set_is_moving(_is_moving: bool):
	is_moving = _is_moving

	if is_moving:
		target_position = target_position + direction * Constants.GRID_SIZE
		current_direction = direction
		
		is_on_ice = Helper.check_is_ice(target_position, get_world_2d())
		
		if currently_possessed_creature:
			if currently_possessed_creature.get_neighbor_in_direction_is_mergable(direction) != null:
				await currently_possessed_creature.merge(direction*Constants.GRID_SIZE, currently_possessed_creature.get_neighbor_in_direction_is_mergable(direction))
			if pushable_stone_in_direction != null:
				pushable_stone_in_direction.push()
		
		spawn_trail(position)
		
		play_sound_step()
		
		Signals.state_changed.emit(get_info())

func play_sound_step():
	audio_stream_player_2d.pitch_scale = Constants.STEP_SOUND_PITCH_SCALES.pick_random()
	audio_stream_player_2d.volume_db = Constants.STEP_SOUND_VOLUME_CHANGE.pick_random()
	audio_stream_player_2d.stop()
	audio_stream_player_2d.play()

func set_hovering_creature(is_hovering: bool, creature: Creature):
	if is_hovering:
		hovering_over = creature
		if currently_possessed_creature == null:
			label_press_f_to_control.visible = true
	else:
		hovering_over = null
		label_press_f_to_control.visible = false

func unpossess():
	if currently_possessed_creature and is_instance_valid(currently_possessed_creature):
		set_hovering_creature(true, currently_possessed_creature)
		change_visibility(true)
		currently_possessed_creature.border.visible = false
		currently_possessed_creature.set_animation_direction()
		currently_possessed_creature = null
		audio_uncontrol.play()

func possess():
	if hovering_over and hovering_over is Creature:
		currently_possessed_creature = hovering_over
		currently_possessed_creature.has_not_moved = false
		currently_possessed_creature.border.visible = true
		change_visibility(false)
		audio_control.play()
		
		# direction an Creature anpassen
		direction = currently_possessed_creature.current_direction
		set_animation_direction(direction)
		
		# Position sofort synchronisieren
		currently_possessed_creature.position = target_position
		currently_possessed_creature.target_position = target_position

func teleport_to(pos: Vector2):
	if currently_possessed_creature:
		currently_possessed_creature.start_teleport(pos)
		global_position = pos
		target_position = global_position
		

func change_visibility(make_visible : bool):
	if make_visible:
		animated_sprite_2d.modulate = Constants.PLAYER_MODULATE_VISIBLE
	else:
		animated_sprite_2d.modulate = Constants.PLAYER_MODULATE_INVISIBLE
		
	if hovering_over:
		label_press_f_to_control.visible = make_visible
		label_press_f_to_stop_control.visible = !make_visible

func _on_creature_detected(body: Node) -> void:
	if body is Creature:
		set_hovering_creature(true, body)

func _on_creature_undetected(body: Node) -> void:
	if body is Creature and hovering_over == body:
		set_hovering_creature(false, body)

func spawn_trail(input_position: Vector2):
	var trail : GPUParticles2D = trail_scene.instantiate()
	get_tree().current_scene.add_child(trail)
	trail.global_position = input_position
	trail.texture = load(Constants.trails.pick_random()) as Texture2D
	trail.restart()

func update_heart_visibility():
	# Wenn keine Kreatur gerade besessen ist → Herz aus
	if currently_possessed_creature == null:
		for heart in hearts:
			heart.visible = false
		return

	# Checke alle 4 Richtungen
	var c := currently_possessed_creature

	if c.neighbor_right:
		hearts[3].position = self.position + Constants.FIELD_POSITION_RIGHT
		hearts[3].visible = true
	else: hearts[3].visible = false

	if c.neighbor_bottom != null:
		hearts[1].position = self.position + Constants.FIELD_POSITION_BOTTOM
		hearts[1].visible = true
	else: hearts[1].visible = false

	if c.neighbor_left:
		hearts[2].position = self.position + Constants.FIELD_POSITION_LEFT
		hearts[2].visible = true
	else: hearts[2].visible = false

	if c.neighbor_top:
		hearts[0].position = self.position + Constants.FIELD_POSITION_TOP
		hearts[0].visible = true
	else: hearts[0].visible = false

func _on_step_timer_timeout() -> void:
	can_move = true
