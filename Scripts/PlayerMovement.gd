extends CharacterBody2D
class_name Player

@export var trail_scene: PackedScene 
@export var hearts: Array[Sprite2D]

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_tree: AnimationTree = $AnimationTree

@onready var label_press_f_to_control: Label = $LabelPressFToControl
@onready var label_press_f_to_stop_control: Label = $LabelPressFToStopControl
@onready var heart_TOP: Sprite2D = $Heart
@onready var heart_BOTTOM: Sprite2D = $Heart2
@onready var heart_LEFT: Sprite2D = $Heart3
@onready var heart_RIGHT: Sprite2D = $Heart4

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

func _ready():
	self.add_to_group(Constants.GROUP_NAME_PLAYER)
	
	Signals.stone_reached_target.connect(set_is_not_pushing_stone_on_ice)
	
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
	
	elif is_active:
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
			if not is_pushing_stone_on_ice:
				step_timer.start()
			
			if is_moving:
				buffered_direction = direction
			else:
				if evaluate_can_move_in_direction():
					set_is_moving(true)
					
					
			
			set_player_animation_direction(direction)
			set_creature_animation_direction(direction)
		
		
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
	global_position = info.get("global_position")
	is_active = info.get("is_active")
	
	direction = info.get("direction")
	current_direction = info.get("current_direction")
	buffered_direction = info.get("buffered_direction")
	
	target_position = global_position
	
	is_moving = false
	is_on_ice = info.get("is_on_ice")
	is_sliding = false
	can_move = true
	set_is_not_pushing_stone_on_ice()
	
	set_player_animation_direction(direction)
	set_creature_animation_direction(direction)
	
	if info.get("currently_possessed_creature") and currently_possessed_creature == null:
		possess()
	elif currently_possessed_creature and info.get("currently_possessed_creature") == null:
		unpossess()


func set_player_animation_direction(_direction: Vector2):
	if _direction != Vector2.ZERO:
		animation_tree.set("parameters/Idle/BlendSpace2D/blend_position", _direction)

func set_creature_animation_direction(_direction: Vector2):
	if currently_possessed_creature:
		currently_possessed_creature.current_direction = direction
		if _direction != Vector2.ZERO:
			currently_possessed_creature.animation_tree.set("parameters/Idle/BlendSpace2D/blend_position", _direction)


func move(delta):
	if is_moving:
		if is_on_ice and currently_possessed_creature and not is_moving_on_ice:
			_move_on_ice()
			
		position = position.move_toward(target_position, Constants.PLAYER_MOVE_SPEED * delta)

		if currently_possessed_creature:
			currently_possessed_creature.position = currently_possessed_creature.position.move_toward(
				target_position, Constants.PLAYER_MOVE_SPEED * delta
			)
		
		# Falls man beim Stein auf Eis schieben nochmal in die Richtung geht, vor Stein anhalten
		#var stone_collision = get_collision_on_tile(target_position, 1 << Constants.LAYER_BIT_STONE)
		#if stone_collision.size() > 0 and abs(target_position[0] - position[0]) > 64 and abs(target_position[1] - position[1]) > 64:
			#if stone_collision[0].collider is Stone:
				#target_position = target_position - (current_direction*Constants.GRID_SIZE)
				
		
		
		if position == target_position:
			is_sliding = false
			is_pushing_stone_on_ice = false
			set_is_moving(false)
			is_moving_on_ice = false
			if buffered_direction != Vector2.ZERO:
				set_is_moving(evaluate_can_move_in_direction())
				buffered_direction = Vector2.ZERO



func evaluate_can_move_in_direction() -> bool:
	var new_pos = target_position + direction * Constants.GRID_SIZE
	var space_state = get_world_2d().direct_space_state
	
	# Prüfen ob ein Objekt am Zielort ist
	var query := PhysicsPointQueryParameters2D.new()
	query.position = new_pos
	
	# Queries für alle relevanten Bit Layers
	query.collision_mask = (1 << Constants.LAYER_BIT_STONE)
	var result_stones = space_state.intersect_point(query, 1)
	
	query.collision_mask = (1 << Constants.LAYER_BIT_DOOR)
	var result_doors = space_state.intersect_point(query, 1)
	
	var result_wall_inside = []
	if currently_possessed_creature != null:
		query.collision_mask = (1 << Constants.LAYER_BIT_WALL_AND_PLAYER)
		result_wall_inside = space_state.intersect_point(query, 1)
	
	var result_wall_outside = []
	query.collision_mask = (1 << Constants.LAYER_BIT_LEVEL_WALL)
	result_wall_outside = space_state.intersect_point(query, 1)
	
	if not result_wall_outside.is_empty():
		return false
	
	# Kein Objekt: Bewegung frei
	if currently_possessed_creature == null or (result_stones.is_empty() and result_doors.is_empty() and result_wall_inside.is_empty()):
		return true
	
	return check_object_in_direction_is_walkable(direction, result_stones, result_doors, result_wall_inside, new_pos, space_state)

func check_object_in_direction_is_walkable(_direction, stone, door, wall, new_pos, space_state) -> bool:
	# Wand vor Spieler, keine Bewegung
	if not wall.is_empty():
		return false
	
	# Tür vor Spieler
	if not door.is_empty():
		# Tür verschlossen, keine Bewegung
		if door[0].collider.door_is_closed:
			return false
		# Tür offen
		elif not door[0].collider.door_is_closed and stone.is_empty():
			return true
	
	# Stein, checken ob Feld hinter Stein frei ist
	if not stone.is_empty():
		var push_target = new_pos + _direction * Constants.GRID_SIZE
		var push_query := PhysicsPointQueryParameters2D.new()
		push_query.position = push_target
		push_query.collision_mask = (1 << Constants.LAYER_BIT_STONE) | (1 << Constants.LAYER_BIT_DOOR) | (1 << Constants.LAYER_BIT_WALL_AND_PLAYER) | (1 << Constants.LAYER_BIT_CREATURE)
		var push_result = space_state.intersect_point(push_query, 1)
		
		# falls Tür hinter Stein, checken ob sie offen ist
		for i in push_result:
			if i.collider is Door and not i.collider.door_is_closed:
				if stone[0].collider.push(_direction * Constants.GRID_SIZE):
					return true
			
		# keine Tür oder Tür offen
		if push_result.is_empty():
			if stone[0].collider.push(_direction * Constants.GRID_SIZE):
				return true
	
	buffered_direction = Vector2.ZERO
	return false

func _move_on_ice():
	var block_mask = (1 << Constants.LAYER_BIT_WALL_AND_PLAYER) | (1 << Constants.LAYER_BIT_DOOR) | (1 << Constants.LAYER_BIT_CREATURE) | (1 << Constants.LAYER_BIT_STONE)
	var slide_end = target_position

	
	# Ist Feld vor Spieler Eis?
	var ice_in_front = check_is_ice(position + current_direction * Constants.GRID_SIZE)
	
	var next_collision = get_collision_on_tile(slide_end, 1 << Constants.LAYER_BIT_STONE)
	if  next_collision.size() > 0:
		if next_collision[0].collider is Stone:
			is_pushing_stone_on_ice = true

	if ice_in_front:
		while true:
			var next_pos = slide_end + current_direction * Constants.GRID_SIZE
			
			if FieldReservation.is_reserved(next_pos):
				break
			
			# wenn nächster step blockiert ist, bleibt slide_end wie bisher
			#if check_if_collides(next_pos, block_mask): 
				#print("Abbruch")
				#break
			
			var stone = get_collision_on_tile(next_pos, block_mask)
			if not stone.is_empty():
				#print(stone[0].collider is Stone)
				#print(stone[0].collider.is_sliding)
				#print()
				if stone[0].collider is Stone and stone[0].collider.is_sliding:
					#if FieldReservation.get_reserved_spot(stone[0].collider) != Vector2.ZERO:
					if FieldReservation.is_reserved(stone[0].collider.target_position):
						slide_end = stone[0].collider.target_position - current_direction * Constants.GRID_SIZE
						target_position = slide_end
						print(slide_end)
						break
				else:
					break
					
			
			# wenn man vom Eis auf normalen Boden rutscht
			if not is_pushing_stone_on_ice and not check_is_ice(next_pos):
				slide_end = next_pos
				break
			
			if not check_is_ice(next_pos):
				slide_end = next_pos
				break
			
			slide_end = next_pos

	# Stein sliden lassen
	if is_pushing_stone_on_ice and next_collision.size() > 0:
		if next_collision[0].collider is Stone:
			next_collision[0].collider.slide(slide_end)
			
	
	#if FieldReservation.is_reserved(slide_end):
		#slide_end -= current_direction * Constants.GRID_SIZE
	
	var tile_after_slide_end = slide_end + (current_direction * Constants.GRID_SIZE)
	
	if not is_pushing_stone_on_ice:
		# bewegt sich bis zum berechneten slide_end
		if check_if_collides(tile_after_slide_end, block_mask) or not check_is_ice(tile_after_slide_end):
			target_position = slide_end
		# bewegt sich nur ein Feld weiter, von Eis auf Boden
		if not check_is_ice(tile_after_slide_end): 
			is_on_ice = false
			
	is_moving_on_ice = true


func check_is_ice(pos: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	var ice_query = PhysicsPointQueryParameters2D.new()
	ice_query.position = pos
	ice_query.collision_mask = 1 << Constants.LAYER_BIT_ICE
	ice_query.collide_with_bodies = true
	ice_query.collide_with_areas  = true
	return not space_state.intersect_point(ice_query, 1).is_empty()

func set_is_on_ice(new_pos) -> bool:
	var space_state = get_world_2d().direct_space_state
	var ice_query = PhysicsPointQueryParameters2D.new()
	ice_query.position = new_pos
	ice_query.collision_mask = 1 << Constants.LAYER_BIT_ICE
	ice_query.collide_with_bodies = true
	ice_query.collide_with_areas  = true
	is_on_ice = not space_state.intersect_point(ice_query, 1).is_empty()
	return is_on_ice

func check_if_collides(_position, layer_mask) -> bool:
	var space = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = _position
	query.collision_mask = layer_mask
	var result = space.intersect_point(query, 1)
	if not result.is_empty():
		if result[0].collider is Door:
			if not result[0].collider.door_is_closed:
				return false
		#if result[0].collider is Stone and is_pushing_stone_on_ice:
			#if result[0].collider.is_sliding:
				#return false
	return not result.is_empty()

func get_collision_on_tile(_position, layer_mask):
	var space = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = _position
	query.collision_mask = layer_mask
	return space.intersect_point(query, 1)

func set_is_not_pushing_stone_on_ice():
	is_pushing_stone_on_ice = false

func get_neighbor_in_direction_is_mergable(_direction : Vector2) -> Creature:
	if currently_possessed_creature != null:
		match _direction:
			Vector2.RIGHT: return currently_possessed_creature.neighbor_right
			Vector2.DOWN: return currently_possessed_creature.neighbor_bottom
			Vector2.LEFT: return currently_possessed_creature.neighbor_left
			Vector2.UP: return currently_possessed_creature.neighbor_top
	return null

func merge(_direction : Vector2, neighbor : Creature) -> bool:
	if neighbor != null:
		var merged_creature = get_tree().get_first_node_in_group("MergedCreature")
		if merged_creature is MergedCreature:
			merged_creature.position = currently_possessed_creature.position + _direction
			await get_tree().create_timer(0.1).timeout # creatures verschwinden, merged_creature taucht nach 0.1 sec auf
			currently_possessed_creature.shrink()
			neighbor.shrink()
			merged_creature.visible = true
			merged_creature.appear()
			is_active = false
			return true
	return false


func set_is_moving(value: bool):
	is_moving = value

	if value:
		target_position = target_position + direction * Constants.GRID_SIZE
		current_direction = direction
		
		set_is_on_ice(target_position)
		if get_neighbor_in_direction_is_mergable(direction) != null:
			await merge(direction*Constants.GRID_SIZE, get_neighbor_in_direction_is_mergable(direction))
		
		spawn_trail(position)
		
		# Sound abspielen
		audio_stream_player_2d.pitch_scale = Constants.STEP_SOUND_PITCH_SCALES.pick_random()
		audio_stream_player_2d.volume_db = Constants.STEP_SOUND_VOLUME_CHANGE.pick_random()
		audio_stream_player_2d.stop()
		audio_stream_player_2d.play()
		
		Signals.state_changed.emit(get_info())



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
		set_player_animation_direction(direction)
		set_creature_animation_direction(direction)
		
		# Position sofort synchronisieren
		currently_possessed_creature.position = target_position
		currently_possessed_creature.target_position = target_position
		

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
	var trail = trail_scene.instantiate()
	get_tree().current_scene.add_child(trail)
	trail.global_position = input_position
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
