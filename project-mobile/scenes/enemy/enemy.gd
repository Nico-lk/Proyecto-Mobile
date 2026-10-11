extends CharacterBody2D

@export var vida_maxima: int = 30
@export var velocidad_vagar: float = 50.0
@export var velocidad_persecucion: float = 110.0
@export var aceleracion: float = 400.0     # qué tan rápido cambia de velocidad (más bajo = más suave)
@export var radio_vagar: float = 150.0     # distancia máxima a la que se aleja de su punto de origen
@export var espera_min: float = 0.5        # pausa al llegar a un destino
@export var espera_max: float = 2.0
@export var deriva: float = 25.0          # px/seg que el centro de vagar se acerca al jugador
@export var deriva_vertical: float = 1.5  # multiplicador: baja más rápido de lo que avanza en horizontal

var jugador_global: Node2D = null         # referencia al jugador aunque no lo haya detectado
var vida_actual: int
var jugador: Node2D = null
var home: Vector2                           # centro de su zona de vagar
var destino: Vector2
var espera: float = 0.0
var esperando: bool = false

@onready var area_deteccion: Area2D = $Area2D
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	vida_actual = vida_maxima
	add_to_group("enemigos")
	home = global_position
	elegir_destino()
	area_deteccion.body_entered.connect(_on_body_entered)
	area_deteccion.body_exited.connect(_on_body_exited)
	
	var jugadores = get_tree().get_nodes_in_group("player")
	if jugadores.size() > 0:
		jugador_global = jugadores[0]

func _physics_process(delta: float) -> void:
	var velocidad_objetivo := Vector2.ZERO

	if jugador and is_instance_valid(jugador):
		# PERSEGUIR
		esperando = false
		velocidad_objetivo = (jugador.global_position - global_position).normalized() * velocidad_persecucion
	else:
		# VAGAR + deriva indirecta hacia el jugador
		if jugador_global and is_instance_valid(jugador_global):
			var hacia_jugador = jugador_global.global_position - home
			var paso = hacia_jugador.normalized() * deriva * delta
			paso.y *= deriva_vertical
			home += paso

		if esperando:
			espera -= delta
			if espera <= 0.0:
				esperando = false
				elegir_destino()
		else:
			var hacia_destino = destino - global_position
			if hacia_destino.length() < 10.0:
				esperando = true
				espera = randf_range(espera_min, espera_max)
			else:
				velocidad_objetivo = hacia_destino.normalized() * velocidad_vagar

	velocity = velocity.move_toward(velocidad_objetivo, aceleracion * delta)
	move_and_slide()

	# Si choca con algo mientras vaga, elige otro destino
	if jugador == null and get_slide_collision_count() > 0:
		elegir_destino()

	if absf(velocity.x) > 5.0:
		sprite.flip_h = velocity.x < 0.0

	# Si choca con algo mientras vaga, elige otro destino
	if jugador == null and get_slide_collision_count() > 0:
		elegir_destino()

	if absf(velocity.x) > 5.0:
		sprite.flip_h = velocity.x < 0.0

func elegir_destino() -> void:
	var angulo = randf() * TAU
	var distancia = randf_range(radio_vagar * 0.3, radio_vagar)
	destino = home + Vector2(cos(angulo), sin(angulo)) * distancia

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		jugador = body

func _on_body_exited(body: Node2D) -> void:
	if body == jugador:
		jugador = null
		home = global_position      # vagará alrededor de donde perdió al jugador
		elegir_destino()

func recibir_daño(cantidad: int) -> void:
	vida_actual -= cantidad
	modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	if not is_inside_tree():
		return
	modulate = Color.WHITE
	if vida_actual <= 0:
		morir()

func morir() -> void:
	queue_free()
