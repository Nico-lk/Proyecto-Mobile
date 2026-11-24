extends CanvasLayer

signal revivir

@export var ad_scene: PackedScene
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
		return

	contenedor.hide()

	var ad = ad_scene.instantiate()
	ad.ad_finished.connect(_on_ad_finished)
	add_child(ad)

func _on_ad_finished(completado: bool) -> void:
	contenedor.show()
	if completado:
		hide()
		get_tree().paused = false
		revivir.emit()

func _on_salir() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu/menu.tscn")
