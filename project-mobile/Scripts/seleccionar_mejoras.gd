extends Control

# id de mejora -> nombre del nodo botón dentro de $Lienzo
# AJUSTÁ los nombres de la derecha a los de tu escena
const BOTONES := {
	"vida":          "BtnVida",
	"armadura":      "BtnArmadura",
	"velocidad":     "BtnVelocidad",
	"salto":         "BtnSalto",
	"sacudida":      "BtnSacudida",
	"dron_cadencia": "BtnDronCadencia",
	"dron_dano":     "BtnDronDano",
	"dron_crit":     "BtnDronCrit",
	"dron_doble":    "BtnDronDoble",
}

func _ready() -> void:
	MusicaDeInerfaz.reproducir()
	for id in BOTONES:
		var boton := get_node_or_null("Lienzo/" + BOTONES[id]) as BaseButton
		if boton == null:
			push_warning("No existe el botón: " + BOTONES[id])
			continue
		boton.pressed.connect(_comprar.bind(id))
	_actualizar_ui()

func _comprar(id: String) -> void:
	if Progreso.comprar(id):
		$Lienzo/AudioStreamPlayer.play()
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
