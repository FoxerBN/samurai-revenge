extends AudioStreamPlayer

var current_music_path := ""

func play_music(music: AudioStream, music_path: String = "") -> void:
	if music == null:
		return
	if playing and music_path != "" and current_music_path == music_path:
		return
	if playing and music_path == "" and stream == music:
		return

	stream = music
	current_music_path = music_path
	play()

func stop_music() -> void:
	stop()
	current_music_path = ""
