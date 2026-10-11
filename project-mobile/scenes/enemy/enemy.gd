extends CharacterBody2D

@export var vida_maxima: int = 30
@export var velocidad: float = 80.0
@export var gravedad: float = 980.0

var vida_actual: int
var jugador: Node2D = null

@onready var area_deteccion: Area2D = $Area2D

func _ready() -> void:
	vida_actual = vida_maxima
	add_to_group("enemigos")
	area_deteccion.body_entered.connect(_on_body_entered)
	area_deteccion.body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravedad * delta

	if jugador and is_instance_valid(jugador):
		velocity.x = signf(jugador.global_position.x - global_position.x) * velocidad
	else:
		velocity.x = move_toward(velocity.x, 0.0, velocidad)

	move_and_slide()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		jugador = body

func _on_body_exited(body: Node2D) -> void:
	if body == jugador:
		jugador = null

func recibir_daño(cantidad: int) -> void:
	vida_actual -= cantidad
	print(name, " recibió ", cantidad, " de daño. Vida restante: ", vida_actual)
	modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	if not is_inside_tree():
		return
	modulate = Color.WHITE
	if vida_actual <= 0:
		morir()

func morir() -> void:
	print(name, " ha sido derrotado.")
	queue_free()
