extends AnimatableBody2D

@export var velocidad: float = 100.0
@export var distancia: float = 300.0

var direccion: int = 1
var x_izquierda: float
var x_derecha: float

func _ready() -> void:
	x_izquierda = position.x
	x_derecha = position.x + distancia
	
func _physics_process(delta: float) -> void:
	position.x += direccion * velocidad * delta

	if position.x >= x_derecha:
		position.x = x_derecha
		direccion = -1
	elif position.x <= x_izquierda:
		position.x = x_izquierda
		direccion = 1
