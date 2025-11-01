extends Node2D

@export var final_level: bool = false
@export var level_number: int = 0

@onready var win_animation: AnimationPlayer = $UI/WinScreen/WinAnimation
@onready var game_completed_animation: AnimationPlayer = $UI/GameCompleted/WinAnimation
@onready var undo_timer_init: Timer = $UI/UndoMechanic/UndoTimerInit
@onready var undo_timer_continious: Timer = $UI/UndoMechanic/UndoTimerContinious

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
		
		#var buttons_toggle : Array[GameButton] = []
		#var buttons_sticky : Array[GameButton] = []
		#var buttons_switch : Array[GameButton] = []
		#var doors : Array[Door] = []
		#var portal : Portal = null
		#var bee_swarm : BeeSwarm = null
		#var seeds : Array[Seed] = []
		#var water_lilies : Array[WaterLily] = []
		#var pile_of_leaves : Array[PileOfLeaves] = []
		#var icicles : Icicle = null
		
		# Player speichern
		var player : Player = get_tree().get_first_node_in_group(str(Constants.GROUP_NAME_PLAYER))
		if player != null:
			state["player"] = player_info
		
		
		# Creatures speichern
		for creature in get_tree().get_nodes_in_group(str(Constants.GROUP_NAME_CREATURE)):
			if creature != null:
				if not state.has("creatures"): 
					state["creatures"] = []
				
				state["creatures"].append(creature.get_creature_info())
		
		# Doors speichern
		for door in get_tree().get_nodes_in_group(str(Constants.GROUP_NAME_DOORS)):
			if door != null:
				if not state.has("doors"): 
					state["doors"] = []
				
				state["doors"].append(door.get_door_info())
		
		
		# Buttons speichern
		for button in get_tree().get_nodes_in_group(str(Constants.GROUP_NAME_BUTTONS)):
			if button != null:
				if not state.has("buttons"): 
					state["buttons"] = []
				
				state["buttons"].append(button.get_button_info())
		
		# Stones speichern
		for stone in get_tree().get_nodes_in_group(str(Constants.GROUP_NAME_STONES)):
			if stone != null:
				if not state.has("stones"): 
					state["stones"] = []
				
				state["stones"].append(stone.get_stone_info())
		
		StateSaver.saved_states.append(state)

func _set_can_undo(value : bool):
	can_undo = value

func _on_undo_timer_init_timeout() -> void:
	print("Init")
	_set_can_undo(true)
	undo_timer_continious.start()

func _on_undo_timer_continious_timeout() -> void:
	print("Continuous")
	_set_can_undo(true)
	undo_timer_continious.start()

func undo():
	if can_undo:
		_set_can_undo(false)
		undo_timer_init.start()
		
		set_state_player()
		set_state_creatures()
		set_state_doors()
		set_state_buttons()
		set_state_stones()
		StateSaver.remove_last_state()


func set_state_player():
	if StateSaver.get_last_state().has("player"):
		var player_state = StateSaver.get_last_state()["player"]
	
		var player : Player = get_tree().get_first_node_in_group(str(Constants.GROUP_NAME_PLAYER))
		if player != null:
			if StateSaver.saved_states.size() > 0:
				player.set_player_info(player_state)

func set_state_creatures():
	if StateSaver.get_last_state().has("creatures"):
		var creatures_states : Array = StateSaver.get_last_state()["creatures"]
		
		for creature in get_tree().get_nodes_in_group(str(Constants.GROUP_NAME_CREATURE)):
			if creature != null:
				if StateSaver.saved_states.size() > 0:
					creature.set_creature_info(creatures_states[0])
					
					creatures_states.remove_at(0)
					
					if creature.global_position == creature.init_position:
						creature.set_animation_direction_by_val(creature.init_direction)

func set_state_doors():
	if StateSaver.get_last_state().has("doors"):
		var doors_states : Array = StateSaver.get_last_state()["doors"]
		
		for door in get_tree().get_nodes_in_group(str(Constants.GROUP_NAME_DOORS)):
			if door != null:
				if StateSaver.saved_states.size() > 0:
					door.set_door_info(doors_states[0])
					
					doors_states.remove_at(0)

func set_state_buttons():
	if StateSaver.get_last_state().has("buttons"):
		var buttons_states : Array = StateSaver.get_last_state()["buttons"]
		
		for button in get_tree().get_nodes_in_group(str(Constants.GROUP_NAME_BUTTONS)):
			if button != null:
				if StateSaver.saved_states.size() > 0:
					button.set_button_info(buttons_states[0])
					
					buttons_states.remove_at(0)

func set_state_stones():
	if StateSaver.get_last_state().has("stones"):
		var stones_states : Array = StateSaver.get_last_state()["stones"]
		
		for stone in get_tree().get_nodes_in_group(str(Constants.GROUP_NAME_STONES)):
			if stone != null:
				if StateSaver.saved_states.size() > 0:
					stone.set_stone_info(stones_states[0])
					
					stones_states.remove_at(0)
