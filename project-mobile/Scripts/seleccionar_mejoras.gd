extends Control

# id de mejora -> nombre del nodo botón dentro de $Lienzo
# AJUSTÁ los nombres de la derecha a los de tu escena
const BOTONES := {
	"vida":          "Button vida",
	"armadura":      "Button armadura",
	"velocidad":     "Button velocidad",
	"salto":         "Button salto", 
	"cadencia": "Button cadencia", #cadencia disparo dron
	"dano":     "Button dano", #dano del dron
	"crit":     "Button critico", #dano critico del dron
	"doble":    "Button doble", #disparo doble
}

func _ready() -> void:
	_actualizar_ui()

func _comprar(id: String) -> void:
	print("Toque en: ", id)
	if Progreso.comprar(id):
		print("Comprado: ", id, " nivel ", Progreso.niveles[id])
		var audio := get_node_or_null("Lienzo/" + BOTONES[id] + "/AudioStreamPlayer")
		if audio:
			audio.play()
	else:
		print("No se pudo comprar ", id)
	_actualizar_ui()

func _actualizar_ui() -> void:
	var texto := ""
	for p in Progreso.partes:
		texto += "%s: %d   " % [Progreso.NOMBRES_PARTES[p], Progreso.partes[p]]
	var label := get_node_or_null("Lienzo/LabelMonedas") as Label
	if label:
		label.text = texto
	else:
		push_warning("Falta el Label 'LabelMonedas' en Lienzo")
	

	for id in BOTONES:
		var nombre_label := get_node_or_null("Lienzo/" + BOTONES[id] + "/Nombre") as Label
		if nombre_label:
			nombre_label.text = Progreso.MEJORAS[id].nombre

		var costo_label := get_node_or_null("Lienzo/" + BOTONES[id] + "/Costo") as Label
		if costo_label == null:
			continue
		if Progreso.es_maximo(id):
			costo_label.text = "MAX"
		else:
			costo_label.text = "%d %s  (%d/%d)" % [
				Progreso.costo(id),
				Progreso.NOMBRES_PARTES[Progreso.parte_de(id)],
				Progreso.niveles[id],
				Progreso.MEJORAS[id].max]

func _on_volver_pressed() -> void:
	$Lienzo/Volver/AudioStreamPlayer.play()
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/menu/interfaz_nave.tscn")


func _on_button_critico_pressed() -> void:
	_comprar("crit")
	pass # Replace with function body.

func _on_button_2_vida_pressed() -> void:
	_comprar("vida")
	pass # Replace with function body.

func _on_button_3_armadura_pressed() -> void:
	_comprar("armadura")
	pass # Replace with function body.

func _on_button_velocidad_pressed() -> void:
	_comprar("velocidad")
	pass # Replace with function body.

func _on_button_salto_pressed() -> void:
	_comprar("salto")
	pass # Replace with function body.

func _on_button_cadencia_pressed() -> void:
	_comprar("cadencia")
	pass # Replace with function body.

func _on_button_dano_pressed() -> void:
	_comprar("dano")
	pass # Replace with function body.

func _on_button_doble_pressed() -> void:
	_comprar("doble")
	pass # Replace with function body.
