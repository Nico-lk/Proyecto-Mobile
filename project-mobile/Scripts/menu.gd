extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func _on_jugar_pressed() -> void:
	$Jugar/AudioStreamPlayer.play()
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://Scenes/levels/level_1.tscn")

func _on_salir_pressed() -> void:
	$Salir/AudioStreamPlayer.play()
	await get_tree().create_timer(0.5).timeout
	get_tree().quit()
