extends Area2D

var tipo: String = "ala"
var cantidad: int = 1
var velocidad: Vector2 = Vector2.ZERO

@export var gravedad: float = 700.0
@export var radio_iman: float = 140.0
@export var vel_iman: float = 420.0
@export var vida: float = 12.0   # desaparece si nadie la recoge

var _jugador: Node2D = null
var _iman: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_jugador = get_tree().get_first_node_in_group("player")
	velocidad = Vector2(randf_range(-120.0, 120.0), randf_range(-260.0, -140.0))

func _physics_process(delta: float) -> void:
	vida -= delta
	if vida <= 0.0:
		queue_free()
		return

	if _jugador and is_instance_valid(_jugador):
		if global_position.distance_to(_jugador.global_position) < radio_iman:
			_iman = true

	if _iman and _jugador and is_instance_valid(_jugador):
		var dir := (_jugador.global_position - global_position).normalized()
		global_position += dir * vel_iman * delta
	else:
		velocidad.y += gravedad * delta
		velocidad.x = move_toward(velocidad.x, 0.0, 200.0 * delta)
		global_position += velocidad * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		Progreso.agregar_parte(tipo, cantidad)
		queue_free()
