extends CharacterBody2D

@export var vida_maxima: int = 30
@export var velocidad_vagar: float = 50.0
@export var velocidad_persecucion: float = 160.0
@export var aceleracion: float = 400.0
@export var radio_vagar: float = 150.0
@export var espera_min: float = 0.5
@export var espera_max: float = 2.0
@export var deriva: float = 25.0
@export var deriva_vertical: float = 1.5
@export var tiempo_aturdido: float = 1.5
@export var fuerza_sacudida: float = 300.0
@export var tiempo_alejado: float = 5.0   # tiempo total sin poder pegarse tras ser sacudido (incluye el aturdimiento)


# Sanguijuela
@export var dano_pegado: int = 5            # daño por tick
@export var intervalo_dano: float = 1.0     # segundos entre ticks

var vida_actual: int
var jugador: Node2D = null                  # jugador detectado (persecución)
var jugador_global: Node2D = null           # referencia siempre disponible (deriva)
var home: Vector2
var destino: Vector2
var espera: float = 0.0
var esperando: bool = false
var aturdido: float = 0.0
var pegado: bool = false
var offset_pegado: Vector2 = Vector2.ZERO
var tiempo_dano: float = 0.0
var alejado: float = 0.0

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
	# --- PEGADO: sigue al jugador y le drena vida ---
	if pegado:
		if jugador == null or not is_instance_valid(jugador):
			despegar()
			return
		global_position = jugador.global_position + offset_pegado
		sprite.flip_h = jugador.global_position.x < global_position.x

		tiempo_dano += delta
		if tiempo_dano >= intervalo_dano:
			tiempo_dano = 0.0
			if jugador.has_method("recibir_daño"):
				jugador.recibir_daño(dano_pegado)
			if jugador.get("vida_actual") != null and jugador.vida_actual <= 0:
				despegar()
		return

	# --- Temporizadores (SIEMPRE, no solo pegado) ---
	if aturdido > 0.0:
		aturdido -= delta
		
	if alejado > 0.0:
		alejado -= delta
		if alejado <= 0.0:
			alejado = 0.0
			quitar_excepciones()
			redetectar()

	# --- ATURDIDO: sale despedido, no puede pegarse ---
	if aturdido > 0.0:
		var huida := Vector2.ZERO
		if jugador_global and is_instance_valid(jugador_global):
			huida = (global_position - jugador_global.global_position).normalized() * velocidad_persecucion
		velocity = velocity.move_toward(huida, aceleracion * delta)
		move_and_slide()
		if absf(velocity.x) > 5.0:
			sprite.flip_h = velocity.x < 0.0
		if aturdido <= 0.0:
			home = global_position
			elegir_destino()
		return

	var velocidad_objetivo := Vector2.ZERO

	if jugador and is_instance_valid(jugador) and alejado <= 0.0:
		# PERSEGUIR
		esperando = false
		velocidad_objetivo = (jugador.global_position - global_position).normalized() * velocidad_persecucion
	else:
		# VAGAR + deriva hacia el jugador
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

	# ¿Tocó al jugador mientras lo persigue? -> se pega
	if jugador and alejado <= 0.0:
		for i in get_slide_collision_count():
			if get_slide_collision(i).get_collider() == jugador:
				pegarse()
				return
	elif get_slide_collision_count() > 0:
		elegir_destino()

	if absf(velocity.x) > 5.0:
		sprite.flip_h = velocity.x < 0.0

func pegarse() -> void:
	pegado = true
	velocity = Vector2.ZERO
	offset_pegado = global_position - jugador.global_position
	tiempo_dano = 0.0
	add_collision_exception_with(jugador)
	if jugador is PhysicsBody2D:
		jugador.add_collision_exception_with(self)
	if jugador.has_method("registrar_sanguijuela"):
		jugador.registrar_sanguijuela(self)
	print(name, " se pegó al jugador")

func despegar() -> void:
	pegado = false
	if jugador_global and is_instance_valid(jugador_global):
		if jugador_global.has_method("quitar_sanguijuela"):
			jugador_global.quitar_sanguijuela(self)
	quitar_excepciones()

func sacudir(direccion: Vector2) -> void:
	pegado = false
	aturdido = tiempo_aturdido
	alejado = tiempo_alejado
	velocity = direccion * fuerza_sacudida
	if jugador_global and is_instance_valid(jugador_global):
		if jugador_global.has_method("quitar_sanguijuela"):
			jugador_global.quitar_sanguijuela(self)

func quitar_excepciones() -> void:
	if jugador_global and is_instance_valid(jugador_global):
		remove_collision_exception_with(jugador_global)
		if jugador_global is PhysicsBody2D:
			jugador_global.remove_collision_exception_with(self)
			
func redetectar() -> void:
	for b in area_deteccion.get_overlapping_bodies():
		if b.is_in_group("player"):
			jugador = b
			return

func elegir_destino() -> void:
	var angulo = randf() * TAU
	var distancia = randf_range(radio_vagar * 0.3, radio_vagar)
	destino = home + Vector2(cos(angulo), sin(angulo)) * distancia

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		jugador = body

func _on_body_exited(body: Node2D) -> void:
	if pegado:
		return                       # pegado no pierde al jugador
	if body == jugador:
		jugador = null
		home = global_position
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
	despegar()
	queue_free()
