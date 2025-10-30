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

func save_level_state():
	if level_number == SceneSwitcher.current_level:
		var state = {
		}
		
		#var player : Player = null
		#var creatures : Array[Creature] = []
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
		
		for p in get_children():
			if p is Player:
				state["player"] = p.duplicate()
		
		
		StateSaver.saved_states.append(state)
		
		for i in StateSaver.saved_states:
			print(i["player"].global_position)
			print("Saved Direction: ", i["player"].state_direction)
		

func undo():
	for p in get_children():
		if p is Player:
			if StateSaver.saved_states.size() > 0:
				p.global_position = StateSaver.get_last_state()["player"].global_position
				
				p.direction = StateSaver.get_last_state()["player"].direction
				p.set_animation_direction(StateSaver.get_last_state()["player"].direction)
				
				p.target_position = p.global_position
				p.is_moving = false
				p.is_sliding = false
				p.current_direction = p.direction
				p.buffered_direction = Vector2.ZERO
				p.can_take_next_step = true
				p.step_timer.stop()
				
			
	StateSaver.remove_last_state()
