extends CanvasLayer

const MAX_AVISOS := 5
const ANCHO := 360.0
const MARGEN := 20.0
const ALTO_SUPERIOR := 70.0   # distancia desde arriba

var _caja: VBoxContainer

func _ready() -> void:
	layer = 10
	_caja = VBoxContainer.new()
	_caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caja.alignment = BoxContainer.ALIGNMENT_BEGIN
	add_child(_caja)

	get_viewport().size_changed.connect(_reubicar)
	_reubicar()

func _reubicar() -> void:
	var pantalla := get_viewport().get_visible_rect().size
	_caja.size = Vector2(ANCHO, 0.0)
	_caja.position = Vector2(pantalla.x - ANCHO - MARGEN, ALTO_SUPERIOR)

func mostrar(texto: String, color: Color = Color.WHITE) -> void:
	var l := Label.new()
	l.text = texto
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", 28)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	_caja.add_child(l)

	# si hay demasiados avisos, saca el más viejo
	if _caja.get_child_count() > MAX_AVISOS:
		var viejo := _caja.get_child(0)
		_caja.remove_child(viejo)
		viejo.queue_free()

	var t := l.create_tween()
	t.tween_interval(1.5)
	t.tween_property(l, "modulate:a", 0.0, 0.5)
	t.tween_callback(l.queue_free)
