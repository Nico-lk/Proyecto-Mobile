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
	laser.direccion = calcular_direccion_predictiva(objetivo, laser.velocidad)
	laser.daño = dano_laser
	get_tree().current_scene.add_child(laser)
	laser.global_position = global_position
	
	#probabilidad de fallar
	var dir = calcular_direccion_predictiva(objetivo, laser.velocidad) 
	laser.direccion = dir.rotated(randf_range(-0.05, 0.05))
	
func calcular_direccion_predictiva(objetivo: Node2D, vel_laser: float) -> Vector2:
	var pos_rel: Vector2 = objetivo.global_position - global_position
	var vel_obj: Vector2 = Vector2.ZERO
	if "velocity" in objetivo:
		vel_obj = objetivo.velocity

	# Resolver |pos_rel + vel_obj * t| = vel_laser * t
	var a: float = vel_obj.dot(vel_obj) - vel_laser * vel_laser
	var b: float = 2.0 * pos_rel.dot(vel_obj)
	var c: float = pos_rel.dot(pos_rel)

	var t: float = -1.0
	if absf(a) < 0.0001:
		# Velocidades casi iguales: ecuación lineal
		if absf(b) > 0.0001:
			t = -c / b
	else:
		var disc: float = b * b - 4.0 * a * c
		if disc >= 0.0:
			var raiz: float = sqrt(disc)
			var t1: float = (-b - raiz) / (2.0 * a)
			var t2: float = (-b + raiz) / (2.0 * a)
			# Elegir el menor tiempo positivo
			if t1 > 0.0 and t2 > 0.0:
				t = min(t1, t2)
			elif t1 > 0.0:
				t = t1
			elif t2 > 0.0:
				t = t2

	# Sin solución (el enemigo es más rápido y se aleja): apuntar directo
	if t <= 0.0:
		return pos_rel.normalized()

	# Limitar el tiempo para no predecir demasiado lejos
	t = min(t, 1.5)
	return (pos_rel + vel_obj * t).normalized()
