extends CanvasLayer

@onready var boton_reintentar: Button = $CenterContainer/VBoxContainer/botonReintentar
@onready var boton_salir: Button = $CenterContainer/VBoxContainer/botonSalir
@onready var contenedor: CenterContainer = $CenterContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	boton_reintentar.pressed.connect(_on_reintentar)
	boton_salir.pressed.connect(_on_salir)

func mostrar() -> void:
	show()
	get_tree().paused = true

func _on_reintentar() -> void:
	if ad_scene == null:
		push_warning("res://scenes/anuncio/ad.tscn")
		return
	boton_reintentar.disabled = true
	contenedor.hide()  # oculta Reintentar y Volver mientras se ve el anuncio

	var ad = ad_scene.instantiate()
	add_child(ad)
	var completado: bool = await ad.ad_finished

	if completado:
		hide()
		contenedor.show()  # listo para la próxima muerte
		get_tree().paused = false
		revivir.emit()
	else:
		contenedor.show()  # lo saltó: vuelven los botones

	if completado:
		hide()
		get_tree().paused = false
		revivir.emit()

func _on_salir() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu/menu.tscn")
