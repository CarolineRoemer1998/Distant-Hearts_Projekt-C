extends Node2D

class_name Level

@export var season : Constants.SEASON = Constants.SEASON.Intro
@export var undo_particles: PackedScene 
@export var final_level: bool = false
@export var level_number: int = 0
@export var wind_direction_if_fall: Vector2 = Vector2.ZERO

@onready var win_animation: AnimationPlayer = $LevelUI/WinScreen/WinAnimation
@onready var game_completed_animation: AnimationPlayer = $LevelUI/GameCompleted/WinAnimation

@onready var undo_timer_init: Timer = $LevelUI/UndoMechanic/UndoTimerInit
@onready var undo_timer_continious: Timer = $LevelUI/UndoMechanic/UndoTimerContinious
@onready var undo_timer_buffer: Timer = $LevelUI/UndoMechanic/UndoTimerBuffer
@onready var undo_sound: AudioStreamPlayer2D = $LevelUI/UndoMechanic/UndoSound

@onready var player: Player = $Player/Player

var has_first_wind_blown := false

var groups_to_save := [
	Constants.GROUP_NAME_PLAYER,
	Constants.GROUP_NAME_CREATURE, 
	Constants.GROUP_NAME_DOORS, 
	Constants.GROUP_NAME_BUTTONS, 
	Constants.GROUP_NAME_STONES, 
	Constants.GROUP_NAME_FLOWER_SEEDS,
	Constants.GROUP_NAME_BEES,
	Constants.GROUP_NAME_WATER_TILE,
	Constants.GROUP_NAME_LILY_PAD,
	Constants.GROUP_NAME_PILE_OF_LEAVES
	]

var can_undo := true
var is_undo_pressed := false

func _ready() -> void:
	Signals.level_loaded.emit(season)
	Wind.is_active = false
	
	set_wind()
	SceneSwitcher.set_curent_level(level_number)
	if level_number >= 6:
		AudioManager.play_music(Constants.BGM_PATH_WINTER_THEME)
	else:
		AudioManager.play_music(Constants.BGM_PATH_SUMMER_THEME)
	
	if level_number == SceneSwitcher.current_level:
		Signals.undo_timer_init_timeout.connect(_on_undo_timer_init_timeout)
		Signals.undo_timer_continuous_timeout.connect(_on_undo_timer_continious_timeout)
		Signals.undo_timer_buffer_timeout.connect(_on_undo_timer_buffer_timeout)
	
	var level_has_water_tiles = get_tree().get_first_node_in_group(Constants.GROUP_NAME_WATER_TILE) != null
	
	if level_has_water_tiles:
		var audio_player = get_tree().get_first_node_in_group("AudioWaterFlowPlayer") as AudioStreamPlayer2D
		audio_player.play()
	
	
	Signals.state_changed.connect(save_level_state)
	Signals.SHOW_WIN_SCREEN.connect(show_win_screen)


func _process(_delta: float) -> void:
	if not has_first_wind_blown and Wind.is_active:
		Wind.check_for_objects_to_blow({})
		has_first_wind_blown = true
	if Input.is_action_pressed("Undo") and not Globals.is_level_finished:
		is_undo_pressed = true
		undo()
	elif Input.is_action_just_released("Undo"):
		is_undo_pressed = false
		undo_timer_init.stop()
		undo_timer_continious.stop()
		_set_can_undo(true)
	elif Input.is_action_just_pressed("Load Last Level"):
		var load_level = max(level_number-1, 1)
		SceneSwitcher.switch_to_level(load_level)
	elif Input.is_action_just_pressed("Load Next Level"):
		var load_level = min(level_number+1, Constants.LEVELS.size())
		SceneSwitcher.switch_to_level(load_level)

func set_wind():
	if season == Constants.SEASON.Fall:
		Wind.is_active = true
		Wind.blow_direction = wind_direction_if_fall
		var wind = Wind.duplicate()
		add_child(wind)
		wind.set_wind_particle_direction(Wind.blow_direction)
		print("Blow Direction: ", Wind.blow_direction)
		wind.visible = true

func show_win_screen():
	if final_level:
		game_completed_animation.play("You win")
		return
	win_animation.play("You win")

func save_level_state(_player_info : Dictionary):
	if level_number == SceneSwitcher.current_level:
		var state = {}
		for group_name in groups_to_save:
			for object in get_tree().get_nodes_in_group(str(group_name)):
				if object != null:
					if not state.has(group_name): 
						state[group_name] = []
					
					state[group_name].append(object.get_info())
		
		StateSaver.add(state)

func _set_can_undo(value : bool):
	can_undo = value

func _on_undo_timer_init_timeout() -> void:
	_set_can_undo(true)
	undo_timer_continious.start()

func _on_undo_timer_continious_timeout() -> void:
	_set_can_undo(true)
	undo_timer_continious.start()

func _on_undo_timer_buffer_timeout():
	Globals.is_undo_timer_buffer_running = false

func undo():
	Globals.is_undo_timer_buffer_running = true
	undo_timer_buffer.start()
	
	if can_undo and StateSaver.saved_states.size() > 0:
		undo_sound.stop()
		undo_sound.play()
		
		_set_can_undo(false)
		undo_timer_init.start()
		
		set_state_of_component(Constants.GROUP_NAME_PLAYER)
		set_state_of_component(Constants.GROUP_NAME_CREATURE)
		set_state_of_component(Constants.GROUP_NAME_DOORS)
		set_state_of_component(Constants.GROUP_NAME_BUTTONS)
		set_state_of_component(Constants.GROUP_NAME_STONES)
		set_state_of_component(Constants.GROUP_NAME_FLOWER_SEEDS)
		set_state_of_component(Constants.GROUP_NAME_BEES)
		set_state_of_component(Constants.GROUP_NAME_WATER_TILE)
		set_state_of_component(Constants.GROUP_NAME_LILY_PAD)
		set_state_of_component(Constants.GROUP_NAME_PILE_OF_LEAVES)
		
		FieldReservation.clear_all()
		StateSaver.remove_last_state()

func set_state_of_component(component_name : String):
	if StateSaver.get_last_state().has(component_name):
		var component_states : Array = StateSaver.get_last_state()[component_name]
		
		for component in get_tree().get_nodes_in_group(component_name):
			if component != null:
				if StateSaver.saved_states.size() > 0:
					component.set_info(component_states[0])
					component_states.remove_at(0)
