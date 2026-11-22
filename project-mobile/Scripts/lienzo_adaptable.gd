extends Control

# escala el lienzo de diseno para que entre entero en cualquier pantalla
const TAMANO := Vector2(768, 1366)

func _ready() -> void:
	get_viewport().size_changed.connect(_ajustar)
	_ajustar()

func _ajustar() -> void:
	var pantalla := get_viewport_rect().size
	if pantalla.x <= 0.0 or pantalla.y <= 0.0:
		return

	var escala := minf(pantalla.x / TAMANO.x, pantalla.y / TAMANO.y)
	scale = Vector2(escala, escala)
	position = (pantalla - TAMANO * escala) * 0.5
