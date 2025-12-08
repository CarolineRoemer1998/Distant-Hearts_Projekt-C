extends Node2D
class_name Teleporter

@export var buttons: Array[NodePath] = []
@export var wooshes: Array[AnimatedSprite2D] = []
@export var other_teleporter : Teleporter

@onready var init_spinning_speed: float = 1.0
@onready var max_spinning_speed: float = 5.0

# feste Zeiten: UP 0.5s, DOWN 0.05s
@onready var up_duration: float = 0.35
@onready var down_duration: float = 0.35

# Boosts: +30% für Value/Alpha, +20% für Scale
@onready var value_alpha_boost_max: float = 0.3
@onready var scale_boost_max: float = 0.2

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var animated_sprite_2d_flower: AnimatedSprite2D = $AnimatedSprites/AnimatedSprite2D_Flower
@onready var animated_sprite_2d_bounce_light: AnimatedSprite2D = $AnimatedSprites/AnimatedSprite2D_BounceLight
@onready var effects: Node2D = $Effects

var is_teleporting: bool = false
enum Phase { IDLE, UP, DOWN }
var phase: int = Phase.IDLE
var phase_time: float = 0.0
var phase_len: float = 0.0
var logged_phase: int = -1

# Basiswerte pro Sprite
var _base_hsv: Array[Vector3] = []     # (h,s,v)
var _base_alpha: Array[float] = []
var _base_scales: Array[Vector2] = []

var is_activated := false

var button_refs: Array = []

func _ready() -> void:
	add_to_group(Constants.GROUP_NAME_TELEPORTERS)
	var teleporters_in_scene = get_tree().get_nodes_in_group(Constants.GROUP_NAME_TELEPORTERS)
	for teleporter in teleporters_in_scene:
		if teleporter != self:
			other_teleporter = teleporter
	
	activate(false)
	
	for path in buttons:
		var button = get_node_or_null(path)
		if button:
			button_refs.append(button)
			button.button_activated.connect(_check_buttons)
			button.button_deactivated.connect(_check_buttons)
			
	_base_hsv.clear()
	_base_alpha.clear()
	_base_scales.clear()
	for w in wooshes:
		var hsv: Vector3 = _rgb_to_hsv(w.modulate)
		_base_hsv.append(hsv)
		_base_alpha.append(w.modulate.a)
		_base_scales.append(w.scale)
	_set_all_to_level(0.0) # sicherstellen, dass Startzustand sauber ist

func _check_buttons():
	#if is_activated and other_teleporter.is_activated:
		#return
	var all_pressed := true
	for button in button_refs:
		if not button.is_pressed():
			all_pressed = false
			break
	activate(all_pressed)

func activate(_activate_val: bool):
	if other_teleporter.is_activated and is_activated and _activate_val==true:
		return
	is_activated = _activate_val
	effects.visible = _activate_val
	animated_sprite_2d_bounce_light.visible = _activate_val
	
	if _activate_val == true:
		Globals.is_teleporting = true
		animated_sprite_2d_flower.modulate = Constants.TELEPORTER_MODULATE_ACTIVE
		Signals.teleporter_activated.emit(self)
	else:
		animated_sprite_2d_flower.modulate = Constants.TELEPORTER_MODULATE_INACTIVE
		Signals.teleporter_deactivated.emit(self)

#func deactivate()

func _process(delta: float) -> void:
	if phase == Phase.IDLE:
		return

	phase_time += delta
	var t: float = 1.0
	if phase_len > 0.0:
		t = clamp(phase_time / phase_len, 0.0, 1.0)

	# "Level" beschreibt, wie weit wir zwischen init(0) und max(1) sind
	var level: float = 0.0
	match phase:
		Phase.UP:
			_log_once()
			level = t                               # 0 -> 1 in up_duration
			_set_all_to_level(level)
			if t >= 1.0:
				# direkt in DOWN, ohne Hold
				phase = Phase.DOWN
				phase_time = 0.0
				phase_len = down_duration
		Phase.DOWN:
			_log_once()
			level = 1.0 - t                         # 1 -> 0 in down_duration
			_set_all_to_level(level)
			if t >= 1.0:
				end_teleport()

func start_teleport() -> void:
	is_teleporting = true
	phase = Phase.UP
	phase_time = 0.0
	phase_len = up_duration
	logged_phase = -1
	_set_all_to_level(0.0)
	animation_player.play("Teleport")

func end_teleport() -> void:
	is_teleporting = false
	phase = Phase.IDLE
	phase_time = 0.0
	phase_len = 0.0
	logged_phase = -1
	_set_all_to_level(0.0)

# ---------- Kern: wendet Level [0..1] auf Speed, Modulate (I/A) und Scale an ----------
func _set_all_to_level(level: float) -> void:
	level = clamp(level, 0.0, 1.0)

	# Speed linear zwischen init und max
	var speed: float = lerp(init_spinning_speed, max_spinning_speed, level)

	# Boosts skaliert mit Level
	var va_boost: float = 1.0 + value_alpha_boost_max * level
	var sc_boost: float = 1.0 + scale_boost_max * level

	for i in range(wooshes.size()):
		var w: AnimatedSprite2D = wooshes[i]
		w.speed_scale = speed

		# HSV/Alpha
		var base_h: float = _base_hsv[i].x
		var base_s: float = _base_hsv[i].y
		var base_v: float = _base_hsv[i].z
		var base_a: float = _base_alpha[i]
		var v: float = base_v * va_boost
		var a: float = clamp(base_a * va_boost, 0.0, 1.0)
		w.modulate = _hsv_to_rgb(base_h, base_s, v, a)

		# individueller Scale pro Sprite
		w.scale = _base_scales[i] * sc_boost

func _log_once() -> void:
	var p: int = int(phase)
	if logged_phase != p:
		logged_phase = p

# ---------- HSV-Helper ----------
func _rgb_to_hsv(c: Color) -> Vector3:
	var r: float = c.r
	var g: float = c.g
	var b: float = c.b
	var maxc: float = max(r, max(g, b))
	var minc: float = min(r, min(g, b))
	var v: float = maxc
	var d: float = maxc - minc
	var s: float = 0.0 if maxc <= 0.0 else (d / maxc)
	var h: float = 0.0
	if d > 0.0:
		if maxc == r:
			h = (g - b) / d
			if g < b: h += 6.0
		elif maxc == g:
			h = (b - r) / d + 2.0
		else:
			h = (r - g) / d + 4.0
		h /= 6.0
	return Vector3(h, s, v)

func _hsv_to_rgb(h: float, s: float, v: float, a: float) -> Color:
	var i: int = int(floor(h * 6.0)) % 6
	var f: float = h * 6.0 - floor(h * 6.0)
	var p: float = v * (1.0 - s)
	var q: float = v * (1.0 - f * s)
	var t: float = v * (1.0 - (1.0 - f) * s)
	match i:
		0: return Color(v, t, p, a)
		1: return Color(q, v, p, a)
		2: return Color(p, v, t, a)
		3: return Color(p, q, v, a)
		4: return Color(t, p, v, a)
		_: return Color(v, p, q, a)
