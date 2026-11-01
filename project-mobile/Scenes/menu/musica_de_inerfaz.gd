extends AudioStreamPlayer

@export var musica: AudioStream

func reproducir() -> void:
	if playing:
		return
	stream = musica
	play()

func detener() -> void:
	stop()
