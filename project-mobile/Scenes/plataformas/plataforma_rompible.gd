extends StaticBody2D

@export var tiempo_antes_de_romper: float = 0.5   # Cuánto vibra antes de caer
@export var tiempo_respawn: float = 3.0           # 0 = no reaparece nunca

@onready var sprite: Sprite2D = $Sprite2D
@onready var colision: CollisionShape2D = $CollisionShape2D
@onready var detector: Area2D = $Detector

var rompiendose: bool = false
var pos_sprite: Vector2

func _ready() -> void:
	pos_sprite = sprite.position
	detector.body_entered.connect(_on_detector_body_entered)

func _on_detector_body_entered(body: Node2D) -> void:
	if rompiendose:
		return
	if body.is_in_group("player"):
		romper()

func romper() -> void:
	rompiendose = true

	# 1. Vibrar
	var pasos := 8
	var duracion_paso := tiempo_antes_de_romper / pasos
	var vibracion := create_tween()
	for i in pasos:
		var offset := 3.0 if i % 2 == 0 else -3.0
		vibracion.tween_property(sprite, "position:x", pos_sprite.x + offset, duracion_paso)
	vibracion.tween_property(sprite, "position:x", pos_sprite.x, 0.02)
	await vibracion.finished

	# 2. Quitar la colisión: el jugador cae
	colision.set_deferred("disabled", true)

	# 3. Caer y desvanecerse
	var caida := create_tween().set_parallel()
	caida.tween_property(sprite, "position:y", pos_sprite.y + 80.0, 0.5)
	caida.tween_property(sprite, "modulate:a", 0.0, 0.5)
	await caida.finished

	# 4. Reaparecer o eliminar
	if tiempo_respawn <= 0.0:
		queue_free()
		return

	await get_tree().create_timer(tiempo_respawn).timeout
	sprite.position = pos_sprite
	sprite.modulate.a = 1.0
	colision.set_deferred("disabled", false)
	rompiendose = false
