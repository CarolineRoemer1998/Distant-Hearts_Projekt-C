extends Node

@onready var sfx_player = $SFXAudioPlayer
@onready var music_player = $MusicAudioPlayer

var curently_playing_song: String = ""
var is_music_playing = false

func play_sfx(path: String):
	sfx_player.stream = load(path)
	sfx_player.play()

func play_music(path: String):
	if curently_playing_song == path:
		return
	music_player.stream = load(path)
	curently_playing_song = path
	is_music_playing = true
	
	## TODO: Wieder einschalten
	music_player.play() 

func stop_music():
	music_player.stop()
	is_music_playing = false

func _replay() -> void:
	AudioManager.music_player.stream = load(AudioManager.curently_playing_song)
	is_music_playing = true
	music_player.play()
