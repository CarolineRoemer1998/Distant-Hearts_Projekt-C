extends HSlider

@export var bus_name: String = "Master"
var bus_index: int
@export var step_size: float = 0.05  # Tweak for controller responsiveness

func _ready() -> void:
	bus_index = AudioServer.get_bus_index(bus_name.to_lower())
	step = step_size
	value = db_to_linear(AudioServer.get_bus_volume_db(bus_index))
	value_changed.connect(_on_value_changed)

func _on_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))
	if bus_name == "sfx":
		AudioManager.play_sfx(Constants.SFX_PATH_STEP)
