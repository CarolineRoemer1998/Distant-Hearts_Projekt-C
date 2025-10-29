extends CharacterBody2D

class_name MergedCreature

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var gpu_particles_2d: GPUParticles2D = $GPUParticles2D
@onready var audio_win: AudioStreamPlayer2D = $AudioWin

func appear():
	animation_player.play("Appear")

func emit_hearts():
	gpu_particles_2d.emitting = true
	
func emit_win_screen():
	Globals.SHOW_WIN_SCREEN.emit()

func play_win_sound():
	audio_win.play()
