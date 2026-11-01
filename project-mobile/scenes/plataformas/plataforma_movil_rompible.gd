extends AnimatableBody2D

@export_group("Movimiento")
@export var velocidad: float = 100.0
@export var distancia: float = 300.0   # Recorrido hacia la derecha desde la posición inicial

@export_group("Rotura")
@export var tiempo_antes_de_romper: float = 0.5
@export var respawn: bool = true
@export var tiempo_respawn: float = 3.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var colision: CollisionShape2D = $CollisionShape2D
@onready var detector: Area2D = $Detector

var direccion: int = 1
var x_izquierda: float
var x_derecha: float
var pos_sprite: Vector2
var moviendose: bool = true
var rompiendose: bool = false

func _ready() -> void:
	x_izquierda = position.x
	x_derecha = position.x + distancia
	pos_sprite = sprite.position
	detector.body_entered.connect(_on_detector_body_entered)

func _physics_process(delta: float) -> void:
	if not moviendose:
		return

	position.x += direccion * velocidad * delta

	if position.x >= x_derecha:
		position.x = x_derecha
		direccion = -1
	elif position.x <= x_izquierda:
		position.x = x_izquierda
		direccion = 1

func _on_detector_body_entered(body: Node2D) -> void:
	if rompiendose:
		return
	if body.is_in_group("player"):
		romper()

func romper() -> void:
	rompiendose = true

	# 1. Vibrar (la plataforma sigue moviéndose mientras vibra)
	var pasos := 8
	var duracion_paso := tiempo_antes_de_romper / pasos
	var vibracion := create_tween()
	for i in pasos:
		var offset := 3.0 if i % 2 == 0 else -3.0
		vibracion.tween_property(sprite, "position:x", pos_sprite.x + offset, duracion_paso)
	vibracion.tween_property(sprite, "position:x", pos_sprite.x, 0.02)
	await vibracion.finished

	# 2. Se detiene y pierde la colisión: el jugador cae
	moviendose = false
	colision.set_deferred("disabled", true)

	# 3. Cae y se desvanece
	var caida := create_tween().set_parallel()
	caida.tween_property(sprite, "position:y", pos_sprite.y + 80.0, 0.5)
	caida.tween_property(sprite, "modulate:a", 0.0, 0.5)
	await caida.finished

	if not respawn:
		queue_free()
		return

	# 4. Reaparece en el punto de inicio del recorrido
	await get_tree().create_timer(tiempo_respawn).timeout
	position.x = x_izquierda
	direccion = 1
	sprite.position = pos_sprite
	sprite.modulate.a = 0.0

	var aparecer := create_tween()
	aparecer.tween_property(sprite, "modulate:a", 1.0, 0.3)
	await aparecer.finished

	colision.set_deferred("disabled", false)
	moviendose = true
	rompiendose = false
