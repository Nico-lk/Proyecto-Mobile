extends Sprite2D

## gotas para el rastro y la salpicadura

var duracion: float = 0.45
var escala_inicial: float = 0.05
var velocidad: Vector2 = Vector2.ZERO
var gravedad: float = 0.0

var _tiempo: float = 0.0


func _ready() -> void:
	# Cada gota necesita su propio material para animar su disolucion
	if material:
		material = material.duplicate()
	rotation = randf_range(0.0, TAU)
	scale = Vector2.ONE * escala_inicial


func _physics_process(delta: float) -> void:
	_tiempo += delta
	var t := clampf(_tiempo / (duracion if duracion > 0.01 else 0.01), 0.0, 1.0)

	velocidad.y += gravedad * delta
	global_position += velocidad * delta
	scale = Vector2.ONE * escala_inicial * (1.0 - 0.45 * t)

	if material:
		material.set_shader_parameter("progreso", t)

	if t >= 1.0:
		queue_free()
