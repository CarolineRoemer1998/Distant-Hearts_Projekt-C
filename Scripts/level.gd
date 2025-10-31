extends Node2D

@onready var win_animation: AnimationPlayer = $WinScreen/WinAnimation

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
		$GameCompleted/WinAnimation.play("You win")
		return
	win_animation.play("You win")

func save_level_state(direction : Vector2, possessed_creature : Creature):
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
		for p in get_children():
			if p is Player:
				state["player"] = p.duplicate()
				state["player"].direction = direction
				state["player"].currently_possessed_creature = possessed_creature
		
		# Creatures speichern
		for c in get_children():
			if c is Creature:
				if not state.has("creatures"): 
					state["creatures"] = []
				state["creatures"].append(c.duplicate())
		
		StateSaver.saved_states.append(state)
		
		#for i in StateSaver.saved_states:
			#for j in i:
				#if j == "player":
					#print(i["player"].direction)
					#print(i["player"].currently_possessed_creature)
					#print(i["player"].direction)
					#print(i["player"].direction)
				#print(j)
		
		#for i in StateSaver.saved_states:
			#print(i["player"].global_position)
			#print("Saved Direction: ", i["player"].state_direction)
		

func undo():
	set_state_player()
	set_state_creatures()
	StateSaver.remove_last_state()

func set_state_player():
	if StateSaver.get_last_state().has("player"):
		var player_state = StateSaver.get_last_state()["player"]
	
		for player in get_children():
			if player is Player:
				if StateSaver.saved_states.size() > 0:
					player.global_position = player_state.global_position
					
					player.direction = player_state.direction
					player.set_animation_direction(player_state.direction)
					
					player.target_position = player.global_position
					player.is_moving = false
					player.is_sliding = false
					player.current_direction = player.direction
					player.buffered_direction = Vector2.ZERO
					player.can_take_next_step = true
					player.step_timer.stop()
					
					print(player.currently_possessed_creature)
					print(player_state.currently_possessed_creature)
					
					if player.currently_possessed_creature != player_state.currently_possessed_creature:
						player.possess_or_unpossess_creature()
					
					player.hovering_over = player_state.hovering_over
					player.currently_possessed_creature = player_state.currently_possessed_creature
					player.possessed_creature_until_next_tile = player_state.possessed_creature_until_next_tile
					
					#var hovering_over: Creature = null
					#var currently_possessed_creature: Creature = null
					#var possessed_creature_until_next_tile: Creature = null

func set_state_creatures():
	if StateSaver.get_last_state().has("creatures"):
		var creatures_states : Array = StateSaver.get_last_state()["creatures"]
		
		for creature in get_children():
			if creature is Creature:
				if StateSaver.saved_states.size() > 0:
					creature.global_position = creatures_states[0].global_position
					creature.target_position = creature.global_position
					
					creature.neighbor_right = creatures_states[0].neighbor_right
					creature.neighbor_bottom = creatures_states[0].neighbor_bottom
					creature.neighbor_left = creatures_states[0].neighbor_left
					creature.neighbor_top = creatures_states[0].neighbor_top
					
					creatures_states.remove_at(0)
