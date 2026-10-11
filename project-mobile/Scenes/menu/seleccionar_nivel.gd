extends Control



func _on_volver_pressed() -> void:
	$Volver/AudioStreamPlayer.play()
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://Scenes/menu/interfaz_nave.tscn")


func _on_uram_nivel_1_pressed() -> void:
	$UramLevel1/AudioStreamPlayer.play()
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://Scenes/levels/level_1.tscn")
