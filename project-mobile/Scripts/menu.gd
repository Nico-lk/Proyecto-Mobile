extends Control

var cambiando_escena := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func _on_jugar_pressed() -> void:
	if cambiando_escena: return # Si ya se está cambiando, ignoramos el clic
	cambiando_escena = true     # Cerramos el candado
	$Jugar/AudioStreamPlayer.play()
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/menu/interfaz_nave.tscn")

func _on_salir_pressed() -> void:
	$Salir/AudioStreamPlayer.play()
	await get_tree().create_timer(0.5).timeout
	get_tree().quit()
