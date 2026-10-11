extends CharacterBody2D

@export var escena_laser: PackedScene          # arrastra laser.tscn aquí en el Inspector
@export var radio_orbita: float = 60.0         # distancia horizontal al jugador
@export var altura: float = 100.0              # altura sobre el jugador
@export var suavizado_pegado: float = 0.1
@export var dano_laser: int = 10
@export var suavidad_lado: float = 2.0   # más bajo = cambio de lado más lento

var tiempo_transcurrido: float = 0.0
var jugador: Node2D = null
var enemigos_en_rango: Array[Node2D] = []
var objetivo_actual: Node2D = null
var lado_actual: float = 1.0


@onready var area_deteccion: Area2D = $AreaDeteccion
@onready var timer_ataque: Timer = $TimerAtaque

func _ready() -> void:
	var jugadores = get_tree().get_nodes_in_group("player")
	if jugadores.size() > 0:
		jugador = jugadores[0]

	area_deteccion.body_entered.connect(_on_enemigo_entrado)
	area_deteccion.body_exited.connect(_on_enemigo_salido)
	timer_ataque.timeout.connect(_on_timer_ataque_timeout)
	timer_ataque.start()   # dispara en bucle; solo lo hará si hay objetivo

func _physics_process(delta: float) -> void:
	actualizar_objetivo()

	# SIEMPRE se mantiene al lado del jugador, haya enemigos o no
	if jugador and is_instance_valid(jugador):
		tiempo_transcurrido += delta * 3.0
		var flotacion_y = sin(tiempo_transcurrido) * 6.0

		# Solo el lado se suaviza
		var lado_objetivo = -1.0 if jugador.animated_sprite.flip_h else 1.0
		lado_actual = lerp(lado_actual, lado_objetivo, 1.0 - exp(-suavidad_lado * delta))

		var posicion_objetivo = jugador.global_position + Vector2(-radio_orbita * lado_actual, -altura + flotacion_y)

		# Seguimiento rápido como antes
		global_position = global_position.lerp(posicion_objetivo, suavizado_pegado)

func actualizar_objetivo() -> void:
	# Limpia enemigos que ya murieron
	enemigos_en_rango = enemigos_en_rango.filter(func(e): return is_instance_valid(e))

	var mas_cercano: Node2D = null
	var menor: float = INF
	for enemigo in enemigos_en_rango:
		var d = global_position.distance_to(enemigo.global_position)
		if d < menor:
			menor = d
			mas_cercano = enemigo
	objetivo_actual = mas_cercano

func _on_enemigo_entrado(body: Node2D) -> void:
	if body.is_in_group("enemigos") and body not in enemigos_en_rango:
		enemigos_en_rango.append(body)

func _on_enemigo_salido(body: Node2D) -> void:
	enemigos_en_rango.erase(body)

func _on_timer_ataque_timeout() -> void:
	if objetivo_actual and is_instance_valid(objetivo_actual):
		disparar(objetivo_actual)
		print("Timer, objetivo: ", objetivo_actual)

func disparar(objetivo: Node2D) -> void:
	if escena_laser == null:
		push_warning("Falta asignar escena_laser en el dron")
		return
	var laser = escena_laser.instantiate()
	laser.direccion = (objetivo.global_position - global_position).normalized()
	laser.daño = dano_laser
	get_tree().current_scene.add_child(laser)
	laser.global_position = global_position
