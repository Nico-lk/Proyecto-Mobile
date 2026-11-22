extends CanvasLayer

@onready var boton_reintentar: Button = $CenterContainer/VBoxContainer/botonReintentar
@onready var boton_salir: Button = $CenterContainer/VBoxContainer/botonSalir

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	boton_reintentar.pressed.connect(_on_reintentar)
	boton_salir.pressed.connect(_on_salir)

func mostrar() -> void:
	show()
	get_tree().paused = true

func _on_reintentar() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_salir() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu/menu.tscn")
