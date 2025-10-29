extends Control

@onready var reset_progress_bar: TextureProgressBar = $TextureProgressBar

const RESET_HOLD_TIME := 1.0 # 1 second hold time for reset
const RESET_INPUT_ACTION := "Reload_Level" # name of input action

var is_reset_input_held := false
var reset_hold_timer := 0.0

func _ready():
	_reset_progress_bar_state()
	reset_progress_bar.value = 0

func _process(delta):
	# Check if the reset input action is currently pressed
	if Input.is_action_pressed(RESET_INPUT_ACTION):
		if not is_reset_input_held:
			is_reset_input_held = true
			reset_hold_timer = 0.0 # Show the progress bar
		
		reset_hold_timer += delta
		
		if reset_progress_bar:
			reset_progress_bar.value = reset_hold_timer
		
		if reset_hold_timer >= RESET_HOLD_TIME:
			SceneSwitcher.reload_level() 
			_reset_progress_bar_state() 
	else:
		# If the input action is not pressed, or was just released
		if is_reset_input_held:
			is_reset_input_held = false
			_reset_progress_bar_state() # Reset state immediately
		
		# If input is not held, gradually decrease progress bar
		if reset_progress_bar.value > 0:
			reset_progress_bar.value = max(0, reset_progress_bar.value - delta * 2) # Decrease faster


func _reset_progress_bar_state():
	reset_hold_timer = 0.0
	reset_progress_bar.value = 0
