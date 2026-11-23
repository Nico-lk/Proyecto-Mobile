extends CharacterBody2D

@export var velocidad: float = 120.0
@export var vida_maxima: int = 50
@export var dano_vomito: int = 15

var vida_actual: int
var jugador: Node2D = null
var atacando: bool = false
var brillando: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var punto_vomito: Marker2D = $PuntoVomito
@onready var timer_ataque: Timer = $TimerAtaque

func _ready() -> void:
	vida_actual = vida_maxima
	add_to_group("enemigos")
	
	var jugadores = get_tree().get_nodes_in_group("player")
	if not jugadores.is_empty():
		jugador = jugadores[0]
		
	timer_ataque.timeout.connect(_on_timer_ataque_timeout)
	
	# Efecto de brillo inicial al aparecer
	_brillar_aparicion()

func _brillar_aparicion() -> void:
	brillando = true
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(5, 5, 5, 1), 0.2)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.3)
	tween.tween_callback(func(): brillando = false)

func _physics_process(delta: float) -> void:
	if not jugador or not is_instance_valid(jugador):
		return
		
	# Movimiento suave flotando hacia el jugador en X, manteniendo altura superior
	var target_x = jugador.global_position.x
	global_position.x = move_toward(global_position.x, target_x, velocidad * delta)
	
	# Mirar hacia el jugador
	if jugador.global_position.x < global_position.x:
		sprite.flip_h = true
		punto_vomito.position.x = -abs(punto_vomito.position.x)
	else:
		sprite.flip_h = false
		punto_vomito.position.x = abs(punto_vomito.position.x)

func _on_timer_ataque_timeout() -> void:
	if atacando or brillando:
		return
	_atacar()

func _atacar() -> void:
	atacando = true
	# Cambiar a animacion de ataque si existe, o pausar movimiento
	if sprite.sprite_frames.has_animation("ataque"):
		sprite.play("ataque")
		
	# Esperar un momento y disparar proyectil de vomito
	await get_tree().create_timer(0.4).timeout
	
	var proye = preload("res://Scenes/Laser/Laser.tscn").instantiate() # O proyectil dedicado si creamos uno
	get_tree().current_scene.add_child(proye)
	proye.global_position = punto_vomito.global_position
	if jugador and is_instance_valid(jugador):
		var dir = (jugador.global_position - punto_vomito.global_position).normalized()
		proye.rotation = dir.angle()
		# Si el laser usa velocity o similar, ajustar aca
		
	await get_tree().create_timer(0.6).timeout
	if sprite.sprite_frames.has_animation("volar"):
		sprite.play("volar")
	atacando = false

func recibir_dano(cant: int) -> void:
	vida_actual -= cant
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 0.2, 0.2), 0.1)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.1)
	if vida_actual <= 0:
		queue_free()
