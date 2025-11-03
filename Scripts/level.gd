extends Node2D

@export var undo_particles: PackedScene 
@export var final_level: bool = false
@export var level_number: int = 0

@onready var win_animation: AnimationPlayer = $UI/WinScreen/WinAnimation
@onready var game_completed_animation: AnimationPlayer = $UI/GameCompleted/WinAnimation

@onready var undo_timer_init: Timer = $UI/UndoMechanic/UndoTimerInit
@onready var undo_timer_continious: Timer = $UI/UndoMechanic/UndoTimerContinious
@onready var undo_sound: AudioStreamPlayer2D = $UI/UndoMechanic/UndoSound

var can_undo := true
var is_undo_pressed := false

func _ready() -> void:
	SceneSwitcher.set_curent_level(level_number)
	if level_number >= 6:
		AudioManager.play_music("res://Sounds/Music/BGM-Winter.mp3")
	else:
		AudioManager.play_music("res://Sounds/Music/BGM-Summer.mp3")
	
	if level_number == SceneSwitcher.current_level:
		Signals.undo_timer_init_timeout.connect(_on_undo_timer_init_timeout)
		Signals.undo_timer_continuous_timeout.connect(_on_undo_timer_continious_timeout)
		
	Signals.state_changed.connect(save_level_state)
	Globals.SHOW_WIN_SCREEN.connect(show_win_screen)


@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	if Input.is_action_pressed("Undo"):
		is_undo_pressed = true
		undo()
	elif Input.is_action_just_released("Undo"):
		is_undo_pressed = false
		undo_timer_init.stop()
		undo_timer_continious.stop()
		_set_can_undo(true)


func show_win_screen():
	if final_level:
		game_completed_animation.play("You win")
		return
	win_animation.play("You win")

func save_level_state(player_info : Dictionary):
	if level_number == SceneSwitcher.current_level:
		var state = {
		}
		
		#var portal : Portal = null
		#var bee_swarm : BeeSwarm = null
		#var seeds : Array[Seed] = []
		#var water_lilies : Array[WaterLily] = []
		#var pile_of_leaves : Array[PileOfLeaves] = []
		#var icicles : Icicle = null
		
		# Player speichern
		var player : Player = get_tree().get_first_node_in_group(str(Constants.GROUP_NAME_PLAYER))
		if player != null:
			state[Constants.GROUP_NAME_PLAYER] = [player_info]
		
		# Creatures speichern
		for creature in get_tree().get_nodes_in_group(str(Constants.GROUP_NAME_CREATURE)):
			if creature != null:
				if not state.has(Constants.GROUP_NAME_CREATURE): 
					state[Constants.GROUP_NAME_CREATURE] = []
				
				state[Constants.GROUP_NAME_CREATURE].append(creature.get_info())
		
		# Doors speichern
		for door in get_tree().get_nodes_in_group(str(Constants.GROUP_NAME_DOORS)):
			if door != null:
				if not state.has(Constants.GROUP_NAME_DOORS): 
					state[Constants.GROUP_NAME_DOORS] = []
				
				state[Constants.GROUP_NAME_DOORS].append(door.get_info())
		
		# Buttons speichern
		for button in get_tree().get_nodes_in_group(str(Constants.GROUP_NAME_BUTTONS)):
			if button != null:
				if not state.has(Constants.GROUP_NAME_BUTTONS): 
					state[Constants.GROUP_NAME_BUTTONS] = []
				
				state[Constants.GROUP_NAME_BUTTONS].append(button.get_info())
		
		# Stones speichern
		for stone in get_tree().get_nodes_in_group(str(Constants.GROUP_NAME_STONES)):
			if stone != null:
				if not state.has(Constants.GROUP_NAME_STONES): 
					state[Constants.GROUP_NAME_STONES] = []
				
				state[Constants.GROUP_NAME_STONES].append(stone.get_info())
		
		StateSaver.saved_states.append(state)

func _set_can_undo(value : bool):
	can_undo = value

func _on_undo_timer_init_timeout() -> void:
	_set_can_undo(true)
	undo_timer_continious.start()

func _on_undo_timer_continious_timeout() -> void:
	_set_can_undo(true)
	undo_timer_continious.start()

func play_undo_particles(pos : Vector2):
	var particles = undo_particles.instantiate()
	get_tree().current_scene.add_child(particles)
	particles.global_position = pos
	particles.restart()

func undo():
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

		StateSaver.remove_last_state()

func set_state_of_component(component_name : String):
	if StateSaver.get_last_state().has(component_name):
		var component_states : Array = StateSaver.get_last_state()[component_name]
		
		for component in get_tree().get_nodes_in_group(component_name):
			if component != null:
				if StateSaver.saved_states.size() > 0:
					if component is Player: 
						play_undo_particles(component.global_position)
					
					component.set_info(component_states[0])
					component_states.remove_at(0)
