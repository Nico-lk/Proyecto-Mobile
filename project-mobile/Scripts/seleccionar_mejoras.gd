extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	MusicaDeInerfaz.reproducir()



func _on_volver_pressed() -> void:
	$Lienzo/Volver/AudioStreamPlayer.play()
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/menu/interfaz_nave.tscn")
