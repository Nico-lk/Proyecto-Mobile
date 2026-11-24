extends CharacterBody2D

const EscenaVomito := preload("res://scenes/boss/vomito.tscn")
const EscenaGota := preload("res://scenes/boss/gota.tscn")

const ATAQUES_POR_DESCANSO: int = 10
const DURACION_DESCANSO: float = 2.0

@export var velocidad: float = 120.0
@export var vida_maxima: int = 500
@export var dano_vomito: int = 15
@export var vomitos_rafaga: int = 5
@export var pausa_rafaga: float = 0.2
@export var prob_rafaga: float = 0.3
@export_range(0.0, 90.0) var abanico_grados: float = 50.0   
@export_range(0.0, 20.0) var ruido_grados: float = 6.0 
@export_range(0.0, 1.0) var umbral_furia: float = 0.3
@export var prob_rafaga_furia: float = 0.7
@export var multiplicador_furia: float = 1.6 
@export var vomitos_rafaga_furia: int = 7

var vida_actual: int
var jugador: Node2D = null
var atacando: bool = false
var brillando: bool = false
var _muriendo: bool = false
var _descansando: bool = false
var _ataques: int = 0
var _tween_descanso: Tween = null
var _furia: bool = false
var _espera_base: float

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var punto_vomito: Marker2D = $PuntoVomito
@onready var timer_ataque: Timer = $TimerAtaque
@onready var sonido_grito: AudioStreamPlayer2D = $SonidoGrito
@onready var sonido_escupitajo: AudioStreamPlayer2D = $SonidoEscupitajo
@onready var sonido_aleteo: AudioStreamPlayer2D = $SonidoAleteo
@onready var sonido_explosion: AudioStreamPlayer2D = $SonidoExplosion

func _ready() -> void:
	vida_actual = vida_maxima
	add_to_group("enemigos")

	var jugadores = get_tree().get_nodes_in_group("player")
	if not jugadores.is_empty():
		jugador = jugadores[0]

	timer_ataque.timeout.connect(_on_timer_ataque_timeout)
	_espera_base = timer_ataque.wait_time

	_aleteo(true)
	_brillar_aparicion()

# sonidos
func _sonar(reproductor: AudioStreamPlayer2D) -> void:
	if reproductor and reproductor.stream:
		reproductor.play()

func _aleteo(encender: bool) -> void:
	if sonido_aleteo == null or sonido_aleteo.stream == null:
		return
	if encender:
		if not sonido_aleteo.playing:
			sonido_aleteo.play()
	elif sonido_aleteo.playing:
		sonido_aleteo.stop()

# suena aunque esta parte desaparezca
func _sonar_aparte(reproductor: AudioStreamPlayer2D) -> void:
	if reproductor == null or reproductor.stream == null:
		return
	reproductor.reparent(get_tree().current_scene, true)
	reproductor.play()
	reproductor.finished.connect(reproductor.queue_free)

func _brillar_aparicion() -> void:
	brillando = true
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(5, 5, 5, 1), 0.2)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.3)
	tween.tween_callback(_gritar)

# grito de inicio de pelea
func _gritar() -> void:
	sprite.speed_scale = 1.0
	_cambiar_animacion(&"ataque")
	_sonar(sonido_grito)
	await get_tree().create_timer(2.0).timeout
	if _muriendo or not is_inside_tree():
		return
	sprite.speed_scale = 1.0
	_cambiar_animacion(&"vuelo")
	_ataques = 0
	brillando = false

func _physics_process(delta: float) -> void:
	if not jugador or not is_instance_valid(jugador):
		return
		
	# movimiento suave flotando hacia el jugador en x
	var target_x = jugador.global_position.x
	global_position.x = move_toward(global_position.x, target_x, velocidad * delta)
	
	# mirar hacia el jugador
	if jugador.global_position.x < global_position.x:
		sprite.flip_h = true
		punto_vomito.position.x = -abs(punto_vomito.position.x)
	else:
		sprite.flip_h = false
		punto_vomito.position.x = abs(punto_vomito.position.x)

func _on_timer_ataque_timeout() -> void:
	if atacando or brillando or _muriendo or _descansando:
		return
	if _ataques >= ATAQUES_POR_DESCANSO:
		_descansar()
		return

	var prob := prob_rafaga_furia if _furia else prob_rafaga
	if randf() < prob:
		_atacar_rafaga()
	else:
		_atacar()

func _atacar() -> void:
	atacando = true
	_ataques += 1
	sprite.speed_scale = 2.5
	_cambiar_animacion(&"ataque")

	await get_tree().create_timer(0.45).timeout
	if _muriendo or not is_inside_tree():
		return
	_lanzar_vomito()

	await get_tree().create_timer(0.55).timeout
	if _muriendo or not is_inside_tree():
		return
	sprite.speed_scale = 1.0
	_cambiar_animacion(&"vuelo")
	atacando = false
	
func _lanzar_vomito(desvio: float = 0.0, seguir: bool = true) -> void:
	if not jugador or not is_instance_valid(jugador):
		return
	var vomito = EscenaVomito.instantiate()
	vomito.dano = dano_vomito
	var dir := (jugador.global_position - punto_vomito.global_position).normalized()
	vomito.direccion = dir.rotated(desvio)
	if not seguir:
		vomito.tiempo_seguimiento = 0.0
	get_tree().current_scene.add_child(vomito)
	vomito.global_position = punto_vomito.global_position
	_sonar(sonido_escupitajo)

func _atacar_rafaga() -> void:
	atacando = true
	_ataques += 1
	sprite.speed_scale = 2.5
	_cambiar_animacion(&"ataque")

	await get_tree().create_timer(0.45).timeout

	var abanico := deg_to_rad(abanico_grados)
	var ruido := deg_to_rad(ruido_grados)
	var cantidad := vomitos_rafaga_furia if _furia else vomitos_rafaga
	for i in cantidad:
		if _muriendo or not is_inside_tree():
			return
		var t := 0.5 if cantidad == 1 else float(i) / (cantidad - 1)
		var desvio := lerpf(-abanico * 0.5, abanico * 0.5, t) + randf_range(-ruido, ruido)
		_lanzar_vomito(desvio, false)
		await get_tree().create_timer(pausa_rafaga).timeout

	if _muriendo or not is_inside_tree():
		return
	sprite.speed_scale = 1.0
	_cambiar_animacion(&"vuelo")
	atacando = false
	
func _entrar_en_furia() -> void:
	_furia = true
	timer_ataque.wait_time = _espera_base / multiplicador_furia
	# destello para avisar al jugador
	var t := create_tween()
	t.tween_property(sprite, "modulate", Color(0.0, 0.687, 0.0, 1.0), 0.15)
	t.tween_property(sprite, "modulate", Color(0.009, 0.585, 0.329, 1.0), 0.3)
	_sonar(sonido_grito)


# descanso cada cierta cantidad de ataques, se pone rojo y no ataca
func _descansar() -> void:
	_descansando = true
	_ataques = 0
	sprite.speed_scale = 1.0
	_cambiar_animacion(&"vuelo")

	#_tween_descanso = create_tween().set_loops()
	#_tween_descanso.tween_property(sprite, "modulate", Color(1, 0.12, 0.12, 1), 0.3)
	#_tween_descanso.tween_property(sprite, "modulate", Color(1, 0.45, 0.4, 1), 0.3)

	await get_tree().create_timer(DURACION_DESCANSO).timeout
	if _muriendo:
		return
	if _tween_descanso and _tween_descanso.is_valid():
		_tween_descanso.kill()
	sprite.modulate = Color(1, 1, 1, 1)
	_descansando = false

# cambia de animacion con un fundido
func _cambiar_animacion(anim: StringName) -> void:
	if not sprite.sprite_frames.has_animation(anim):
		return
	_aleteo(anim == &"vuelo")
	var t := create_tween()
	t.tween_property(sprite, "modulate:a", 0.5, 0.07)
	t.tween_callback(func() -> void: sprite.play(anim))
	t.tween_property(sprite, "modulate:a", 1.0, 0.13)

func recibir_daño(cant: int) -> void:
	if _muriendo:
		return
	vida_actual -= cant
	if vida_actual <= 0:
		_morir()
		return
	if not _furia and vida_actual <= vida_maxima * umbral_furia:
		_entrar_en_furia()
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 0.2, 0.2), 0.1)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.1)


func _morir() -> void:
	if _muriendo:
		return
	_muriendo = true
	timer_ataque.stop()
	set_physics_process(false)
	_aleteo(false)
	$CollisionShape2D.set_deferred("disabled", true)
	call_deferred("remove_from_group", "enemigos")
	if _tween_descanso and _tween_descanso.is_valid():
		_tween_descanso.kill()
	_sonar_aparte(sonido_explosion)
	Progreso.agregar_parte("nucleo", 3)
	Progreso.guardar()

	var escena := get_tree().current_scene

	# explosion de gotas que salen despedidas desde todo el cuerpo
	for i in 30:
		var gota := EscenaGota.instantiate()
		var dir := Vector2.from_angle(randf_range(0.0, TAU))
		gota.duracion = randf_range(0.7, 1.4)
		gota.escala_inicial = randf_range(0.06, 0.22)
		gota.velocidad = dir * randf_range(180.0, 620.0)
		gota.gravedad = 600.0
		escena.add_child(gota)
		gota.global_position = global_position + dir * randf_range(30.0, 220.0)

	# gotas gigantes en el centro de la explosion
	for i in 3:
		var gota := EscenaGota.instantiate()
		gota.duracion = randf_range(0.5, 0.9)
		gota.escala_inicial = randf_range(0.35, 0.6)
		gota.velocidad = Vector2.ZERO
		gota.gravedad = 0.0
		escena.add_child(gota)
		gota.global_position = global_position \
				+ Vector2(randf_range(-60.0, 60.0), randf_range(-60.0, 60.0))

	# flash del cuerpo
	var t := create_tween()
	t.tween_property(sprite, "modulate", Color(2.5, 3.0, 1.6, 1.0), 0.12)
	t.parallel().tween_property(sprite, "scale", sprite.scale * 1.12, 0.12)
	t.tween_property(sprite, "modulate:a", 0.0, 0.9)
	t.parallel().tween_property(sprite, "scale", sprite.scale * 1.45, 0.9)

	await get_tree().create_timer(2.0).timeout
	queue_free()
