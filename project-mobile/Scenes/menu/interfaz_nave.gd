extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _on_panel_niveles_pressed() -> void:
	$Panel_Niveles/AudioStreamPlayer.play()
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://Scenes/menu/seleccionar_nivel.tscn")


func _on_impresora_pressed() -> void:
	$Impresora/AudioStreamPlayer.play()
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://Scenes/menu/seleccionar_mejoras.tscn")


func _on_salir_al_menu_pressed() -> void:
	$Salir_Al_Menu/AudioStreamPlayer.play()
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://Scenes/menu/menu.tscn")


func _on_compras_pressed() -> void:
	$Compras/AudioStreamPlayer.play()
