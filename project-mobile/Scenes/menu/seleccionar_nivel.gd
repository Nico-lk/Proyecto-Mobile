extends Control

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_volver_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/menu/interfaz_nave.tscn")


func _on_uram_nivel_1_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/levels/level_1.tscn")
