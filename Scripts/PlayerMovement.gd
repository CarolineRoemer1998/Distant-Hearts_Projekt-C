extends CharacterBody2D
class_name Player

@export var trail_scene: PackedScene 

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_tree: AnimationTree = $AnimationTree

@onready var label_press_f_to_control: Label = $LabelPressFToControl
@onready var label_press_f_to_stop_control: Label = $LabelPressFToStopControl
@onready var heart: Sprite2D = $Heart

@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var audio_control: AudioStreamPlayer2D = $AudioControl
@onready var audio_uncontrol: AudioStreamPlayer2D = $AudioUncontrol

@onready var step_timer: Timer = $StepTimer

const GRID_SIZE := Vector2(64, 64)
const MOVE_SPEED := 500.0
const ICE_MOVE_SPEED := 400.0

# LAYER BITS
const WALL_AND_PLAYER_LAYER_BIT := 0
const CREATURE_LAYER_BIT 	:= 1
const STONE_LAYER_BIT 	:= 2
const DOOR_LAYER_BIT    	:= 3
const ICE_LAYER_BIT     	:= 5
const LEVEL_WALL_LAYER_BIT  := 6

const STEP_SOUND_PITCH_SCALES := [0.95, 0.96, 0.97, 0.98, 0.99, 1, 1.01, 1.02, 1.03, 1.04, 1.05]
const STEP_SOUND_VOLUME_CHANGE := [6.0, 6.5, 7.0, 7.5, 8.0]

const HEART_POSITION_RIGHT := Vector2(32,0)
const HEART_POSITION_BOTTOM := Vector2(0,32)
const HEART_POSITION_LEFT := Vector2(-32,0)
const HEART_POSITION_TOP := Vector2(0,-32)

var is_active := true

var direction := Vector2.ZERO
var current_direction := Vector2.ZERO
var buffered_direction: Vector2 = Vector2.ZERO

var target_position: Vector2

var is_moving := false
var is_on_ice := false
var is_sliding := false
var can_move := true

var hovering_over: Creature = null
var currently_possessed_creature: Creature = null
var possessed_creature_until_next_tile: Creature = null


func _ready():
	# Spieler korrekt auf Grid ausrichten
	target_position = position.snapped(GRID_SIZE / 2)
	position = target_position
	animation_tree.get("parameters/playback").travel("Idle")
	self.add_to_group(Constants.GROUP_NAME_PLAYER)


func _process(delta):
	move(delta)
	update_heart_visibility()
	handle_input()
	
	print("hovering_over: ", hovering_over, "\ncurrently_possessed_creature: ", currently_possessed_creature, "\npossessed_creature_until_next_tile: ", possessed_creature_until_next_tile, "\n\n")

func handle_input():
	if Input.is_action_just_pressed("ui_cancel"):
		SceneSwitcher.go_to_settings()
	
	if is_active:
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
			step_timer.start()
			if is_moving:
				buffered_direction = direction
			else:
				try_move(direction)
		
		# Interaktionsbutton
		elif Input.is_action_just_pressed("Interact"):
			if not is_moving:
				if hovering_over and hovering_over is Creature:
					Signals.state_changed.emit(get_info())
					if currently_possessed_creature:
						unpossess()
					else:
						possess()
		
		set_player_animation_direction(direction)
		set_creature_animation_direction(direction)

	else:
		# Szenewechsel durch Tastatur, Maus oder Gamepad
		if Input.is_action_just_pressed("ui_accept"):
			SceneSwitcher.go_to_next_level()

func get_info() -> Dictionary:
	return {
		# variables
		"global_position": global_position,
		"is_active": is_active,
		
		"direction": direction,
		"current_direction": current_direction,
		"buffered_direction": buffered_direction,
		
		"target_position": target_position,
		
		"is_moving": is_moving,
		"is_on_ice": is_on_ice,
		"is_sliding": is_sliding,
		"can_move": can_move,
		
		"hovering_over": hovering_over,
		"currently_possessed_creature": currently_possessed_creature,
		"possessed_creature_until_next_tile": possessed_creature_until_next_tile
	}

func set_info(info : Dictionary, delta: float):
	# variables
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
	
	if info.get("currently_possessed_creature") and currently_possessed_creature == null:
		possess()
	elif currently_possessed_creature and info.get("currently_possessed_creature") == null:
		unpossess()
	
	#change_visibility(currently_possessed_creature==null)
	
	#hovering_over = info.get("hovering_over")
	#currently_possessed_creature = info.get("currently_possessed_creature")
	#possessed_creature_until_next_tile = info.get("possessed_creature_until_next_tile")
	#set_hovering_creature(hovering_over)
	#
	
	#if hovering_over and not currently_possessed_creature:
		#hovering_over.border.visible = false
	#if not hovering_over:
		#label_press_f_to_control.visible = false
		#label_press_f_to_stop_control.visible = false


func set_player_animation_direction(_direction : Vector2):
	if _direction != Vector2.ZERO:
		animation_tree.set("parameters/Idle/BlendSpace2D/blend_position", _direction)

func set_creature_animation_direction(_direction : Vector2):
	if currently_possessed_creature:
		currently_possessed_creature.current_direction = direction
		if _direction != Vector2.ZERO:
			currently_possessed_creature.animation_tree.set("parameters/Idle/BlendSpace2D/blend_position", _direction)


func move(delta):
	if is_moving:
		if is_on_ice and currently_possessed_creature:
			move_on_ice()
			if target_position == position:
				is_sliding = false
				
		position = position.move_toward(target_position, MOVE_SPEED * delta)
		if target_position == position:
			is_sliding = false
		
		if possessed_creature_until_next_tile:
			# Besessene Kreatur mitziehen
			possessed_creature_until_next_tile.position = possessed_creature_until_next_tile.position.move_toward(
				target_position, MOVE_SPEED * delta
			)

			# Bewegung abgeschlossen → Entkoppeln
			if possessed_creature_until_next_tile.position == target_position:
				possessed_creature_until_next_tile = null

		if position == target_position:
			set_is_moving(false)

			# Pufferbewegung ausführen
			if buffered_direction != Vector2.ZERO:
				try_move(buffered_direction)
				buffered_direction = Vector2.ZERO


func move_on_ice():
	var block_mask = (1 << WALL_AND_PLAYER_LAYER_BIT) | (1 << DOOR_LAYER_BIT) | (1 << CREATURE_LAYER_BIT) | (1 << STONE_LAYER_BIT)
	var slide_end = target_position
	
	set_is_on_ice(target_position + current_direction * GRID_SIZE)
	
	var next_collision = get_collision_on_tile(slide_end, 1 << STONE_LAYER_BIT)
	if not is_sliding and next_collision.size() > 0:
		if next_collision[0].collider is Stone:
			is_sliding = true
			slide_end = slide_end - (current_direction * GRID_SIZE)
			slide_end += current_direction * GRID_SIZE
	
	while true:
		var next_pos = slide_end + current_direction * GRID_SIZE
		
		if check_if_collides(next_pos, block_mask):
			break
		if not check_is_ice(next_pos) and not is_sliding:
			slide_end = next_pos
			break
			
		slide_end = next_pos
	
	if is_sliding and next_collision.size() > 0 and not next_collision[0].collider.is_sliding:
		if next_collision[0].collider.is_sliding == false:
			next_collision[0].collider.is_sliding = true
			next_collision[0].collider.slide(slide_end)
			
	if not is_sliding and slide_end != target_position: 
		target_position = slide_end

func check_is_ice(pos: Vector2) -> bool:
	var space = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collision_mask = 1 << ICE_LAYER_BIT
	var result = space.intersect_point(query, 1)
	return not result.is_empty()

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
	return not result.is_empty()

func get_collision_on_tile(_position, layer_mask):
	var space = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = _position
	query.collision_mask = layer_mask
	return space.intersect_point(query, 1)


func try_move(_direction: Vector2):
	var new_pos = target_position + _direction * GRID_SIZE
	current_direction = _direction
	var space_state = get_world_2d().direct_space_state
	
	set_is_on_ice(new_pos)
	
	merge_if_possible(direction)
	
	# Prüfen ob ein Objekt am Zielort ist
	var query := PhysicsPointQueryParameters2D.new()
	query.position = new_pos
	
	
	
	# Query für Stones
	query.collision_mask = (1 << STONE_LAYER_BIT)
	var result_stones = space_state.intersect_point(query, 1)
	
	# Query für Türen
	query.collision_mask = (1 << DOOR_LAYER_BIT)
	var result_doors = space_state.intersect_point(query, 1)
	
	# Query für Blockaden
	var result_wall = []
	if currently_possessed_creature != null:
		query.collision_mask = (1 << WALL_AND_PLAYER_LAYER_BIT)
		result_wall = space_state.intersect_point(query, 1)
	
	# Query für Außenwand
	var result_level_wall = []
	query.collision_mask = (1 << LEVEL_WALL_LAYER_BIT)
	result_level_wall = space_state.intersect_point(query, 1)
	
	if not result_level_wall.is_empty():
		return
	
	# Kein Objekt: Bewegung frei
	if (result_stones.is_empty() or currently_possessed_creature == null) and (result_doors.is_empty() or currently_possessed_creature == null) and result_wall.is_empty():
		spawn_trail(position)
		target_position = new_pos
		set_is_moving(true)
		Signals.state_changed.emit(get_info())
		return
	
	try_push_and_move(result_stones, result_doors, result_wall, new_pos, direction, space_state)

func set_is_on_ice(new_pos) -> bool:
	var space_state = get_world_2d().direct_space_state
	var ice_query = PhysicsPointQueryParameters2D.new()
	ice_query.position = new_pos
	ice_query.collision_mask = 1 << ICE_LAYER_BIT
	ice_query.collide_with_bodies = true
	ice_query.collide_with_areas  = true
	is_on_ice = not space_state.intersect_point(ice_query, 1).is_empty()
	return is_on_ice

func merge_if_possible(_direction : Vector2) -> bool:
	if currently_possessed_creature != null:
		match _direction:
			Vector2(1.0, 0.0): # right
				return await _merge(Vector2(64,0), currently_possessed_creature.neighbor_right)
			Vector2(0.0, 1.0): # bottom
				return await _merge(Vector2(0,64), currently_possessed_creature.neighbor_bottom)
			Vector2(-1.0, 0.0): # left
				return await _merge(Vector2(-64,0), currently_possessed_creature.neighbor_left)
			Vector2(0.0, -1.0): # top
				return await _merge(Vector2(0,-64), currently_possessed_creature.neighbor_top)
	return false

func _merge(_direction : Vector2, neighbor : Creature):
	if neighbor != null:
		if currently_possessed_creature.can_merge_with(neighbor):
			var spawn_position = currently_possessed_creature.position + _direction
			var merged_creature = get_tree().get_first_node_in_group("MergedCreature")
			if merged_creature and merged_creature is MergedCreature:
				merged_creature.position = spawn_position
				merged_creature.visible = false  # ← erst mal verstecken
				await get_tree().create_timer(0.1).timeout # creatures verschwinden und merged_creature taucht erst nach 0.1 sekunden
				currently_possessed_creature.shrink()
				neighbor.shrink()
				merged_creature.visible = true
				merged_creature.appear()
			is_active = false
			return true
	return false

func try_push_and_move(stone, door, wall, new_pos, _direction, space_state):
	
	# Wand vor Spieler, keine Bewegung
	if stone.is_empty() and door.is_empty() and not wall.is_empty():
		return
	
	# Spieler ist Geist und kann sich durch restliche Objekte durch bewegen
	if currently_possessed_creature == null:
		spawn_trail(position)
		target_position = new_pos
		set_is_moving(true)
		Signals.state_changed.emit(get_info())
		return
	
	# Tür vor Spieler
	if not door.is_empty():
		# Tür verschlossen, keine Bewegung
		if door[0].collider.door_is_closed:
			return
			
		# Tür offen
		elif not door[0].collider.door_is_closed:
			spawn_trail(position)
			target_position = new_pos
			set_is_moving(true)
			# Wenn Spieler kein Stone durch die Tür schiebt, Funktion hier beenden
			if stone.is_empty():
				return
	
	# Ziel hinter dem stone prüfen
	var push_target = new_pos + _direction * GRID_SIZE
	var push_query := PhysicsPointQueryParameters2D.new()
	push_query.position = push_target
	push_query.collision_mask = (1 << STONE_LAYER_BIT) | (1 << DOOR_LAYER_BIT) | (1 << WALL_AND_PLAYER_LAYER_BIT) | (1 << CREATURE_LAYER_BIT)
	var push_result = space_state.intersect_point(push_query, 1)
	
	for i in push_result:
		if i.collider is Door and not i.collider.door_is_closed:
			if stone[0].collider.push(_direction * GRID_SIZE):
				target_position = new_pos
				Signals.state_changed.emit(get_info())
				set_is_moving(true)
				return
		
	# Falls frei oder Tür die offen ist, push ausführen
	if push_result.is_empty():
		if stone[0].collider.push(_direction * GRID_SIZE):
			target_position = new_pos
			set_is_moving(true)
			Signals.state_changed.emit(get_info())
	else:
		buffered_direction = Vector2.ZERO


func set_is_moving(value: bool):
	is_moving = value

	if value:
		# Sound NUR EINMAL pro Tile-Bewegung abspielen
		audio_stream_player_2d.stop()
		audio_stream_player_2d.play()
		
		audio_stream_player_2d.pitch_scale = STEP_SOUND_PITCH_SCALES.pick_random()
		audio_stream_player_2d.volume_db = STEP_SOUND_VOLUME_CHANGE.pick_random()

		# Besessene Kreatur mitziehen lassen
		if currently_possessed_creature:
			possessed_creature_until_next_tile = currently_possessed_creature
	else:
		possessed_creature_until_next_tile = null

func set_hovering_creature(creature: Creature):
	hovering_over = creature
	if currently_possessed_creature == null:
		label_press_f_to_control.visible = true

func unpossess():
	if currently_possessed_creature and is_instance_valid(currently_possessed_creature):
		currently_possessed_creature.border.visible = false
		set_hovering_creature(currently_possessed_creature)
		
		currently_possessed_creature.set_animation_direction()

		currently_possessed_creature = null
		change_visibility(true)
		audio_uncontrol.play()
		possessed_creature_until_next_tile = null

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
		
		possessed_creature_until_next_tile = currently_possessed_creature

func change_visibility(make_visible : bool):
	if make_visible:
		animated_sprite_2d.modulate = Color(1, 1, 1, 0.8)
		if hovering_over:
			label_press_f_to_control.visible = true
			label_press_f_to_stop_control.visible = false
	else:
		animated_sprite_2d.modulate = Color(1, 1, 1, 0)
		if hovering_over:
			label_press_f_to_control.visible = false
			label_press_f_to_stop_control.visible = true

func _on_creature_detected(body: Node) -> void:
	if body is Creature:
		set_hovering_creature(body)
		


func _on_creature_undetected(body: Node) -> void:
	if body is Creature and hovering_over == body:
		hovering_over = null
		label_press_f_to_control.visible = false


func spawn_trail(input_position: Vector2):
	var trail = trail_scene.instantiate()
	get_tree().current_scene.add_child(trail)
	trail.global_position = input_position
	trail.restart()


func update_heart_visibility():
	# Wenn keine Kreatur gerade besessen ist → Herz aus
	if currently_possessed_creature == null:
		heart.visible = false
		return

	# Checke alle 4 Richtungen
	var c := currently_possessed_creature

	if c.neighbor_right and c.can_merge_with(c.neighbor_right):
		heart.position = self.position + HEART_POSITION_RIGHT
		heart.visible = true
		return

	if c.neighbor_bottom and c.can_merge_with(c.neighbor_bottom):
		heart.position = self.position + HEART_POSITION_BOTTOM
		heart.visible = true
		return

	if c.neighbor_left and c.can_merge_with(c.neighbor_left):
		heart.position = self.position + HEART_POSITION_LEFT
		heart.visible = true
		return

	if c.neighbor_top and c.can_merge_with(c.neighbor_top):
		heart.position = self.position + HEART_POSITION_TOP
		heart.visible = true
		return

	# Kein passender Nachbar gefunden → Herz aus
	heart.visible = false


func _on_step_timer_timeout() -> void:
	can_move = true
