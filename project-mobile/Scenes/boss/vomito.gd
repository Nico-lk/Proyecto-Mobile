extends Area2D

const EscenaGota := preload("res://Scenes/boss/gota.tscn")

@export var velocidad: float = 520.0
@export var dano: int = 15
@export var vida: float = 4.0
@export var intervalo_gotas: float = 0.025
@export var gotas_salpicadura: int = 14
@export var seguimiento: float = 0.65
@export var tiempo_seguimiento: float = 0.6

var direccion: Vector2 = Vector2.DOWN

@onready var sprite: Sprite2D = $Sprite2D
@onready var sonido_impacto: AudioStreamPlayer2D = $SonidoImpacto

var _tiempo_gota: float = 0.0
var _edad: float = 0.0
var _jugador: Node2D = null
var _explotando: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_jugador = get_tree().get_first_node_in_group("player")
	if sprite.material:
		sprite.material = sprite.material.duplicate()


func _physics_process(delta: float) -> void:
	_edad += delta
	_seguir_jugador(delta)

	global_position += direccion * velocidad * delta
	sprite.rotation += delta * 4.0

	# va dejando gotitas de baba que se disuelven con el shader
	_tiempo_gota += delta
	if _tiempo_gota >= intervalo_gotas:
		_tiempo_gota = 0.0
		_soltar_gota_estela()

	vida -= delta
	if vida <= 0.0:
		queue_free()


func _seguir_jugador(delta: float) -> void:
	if _edad > tiempo_seguimiento:
		return
	if _jugador == null or not is_instance_valid(_jugador):
		return
	var objetivo := (_jugador.global_position - global_position).angle()
	var angulo := rotate_toward(direccion.angle(), objetivo, seguimiento * delta)
	direccion = Vector2.from_angle(angulo)


func _soltar_gota_estela() -> void:
	var gota := EscenaGota.instantiate()
	gota.duracion = randf_range(0.25, 0.5)
	gota.escala_inicial = randf_range(0.02, 0.05)
	gota.velocidad = -direccion * randf_range(10.0, 40.0) \
			+ Vector2(randf_range(-25.0, 25.0), randf_range(-25.0, 25.0))
	gota.gravedad = 300.0
	get_tree().current_scene.add_child(gota)
	gota.global_position = global_position \
			+ Vector2(randf_range(-8.0, 8.0), randf_range(-8.0, 8.0))


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("recibir_daño"):
		body.recibir_daño(dano)
	_explotar()


func _explotar() -> void:
	if _explotando:
		return
	_explotando = true

	# el sonido suena aunque el vomito desaparezca
	if sonido_impacto and sonido_impacto.stream:
		sonido_impacto.reparent(get_tree().current_scene, true)
		sonido_impacto.play()
		sonido_impacto.finished.connect(sonido_impacto.queue_free)

	var escena := get_tree().current_scene

	# gotas que salen en todas direcciones y caen
	for i in gotas_salpicadura:
		var gota := EscenaGota.instantiate()
		var dir := Vector2.from_angle(randf_range(0.0, TAU))
		gota.duracion = randf_range(0.3, 0.55)
		gota.escala_inicial = randf_range(0.04, 0.11)
		gota.velocidad = dir * randf_range(90.0, 280.0) + Vector2(0.0, -80.0)
		gota.gravedad = 900.0
		escena.add_child(gota)
		gota.global_position = global_position + dir * randf_range(0.0, 14.0)

	# Un par de gotas grandes que revientan en el lugar del impacto
	for i in 2:
		var gota := EscenaGota.instantiate()
		gota.duracion = randf_range(0.2, 0.3)
		gota.escala_inicial = randf_range(0.12, 0.18)
		gota.velocidad = Vector2.ZERO
		gota.gravedad = 0.0
		escena.add_child(gota)
		gota.global_position = global_position

	queue_free()
