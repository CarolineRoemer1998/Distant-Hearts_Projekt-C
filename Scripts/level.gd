extends Node2D

@onready var win_animation: AnimationPlayer = $UI/WinScreen/WinAnimation
@onready var game_completed_animation: AnimationPlayer = $UI/GameCompleted/WinAnimation


@export var final_level: bool = false
@export var level_number: int = 0


func _ready() -> void:
	Signals.state_changed.connect(save_level_state)
	
	Globals.SHOW_WIN_SCREEN.connect(show_win_screen)
	SceneSwitcher.set_curent_level(level_number)
	if level_number >= 6:
		AudioManager.play_music("res://Sounds/Music/BGM-Winter.mp3")
	else:
		AudioManager.play_music("res://Sounds/Music/BGM-Summer.mp3")

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Undo"):
		undo()
		

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
		for c in get_tree().get_nodes_in_group(str(Constants.GROUP_NAME_CREATURE)):
			if c is Creature:
				if not state.has("creatures"): 
					state["creatures"] = []
				
				state["creatures"].append(c.get_creature_info())
				
		
		StateSaver.saved_states.append(state)


func undo():
	set_state_player()
	set_state_creatures()
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
