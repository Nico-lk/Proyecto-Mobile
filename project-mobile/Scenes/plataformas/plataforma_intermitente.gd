extends StaticBody2D

@export var tiempo_visible: float = 2.0
@export var tiempo_oculta: float = 2.0
@export var tiempo_aviso: float = 0.5
@export var retraso_inicial: float = 0.0
@export var empieza_visible: bool = true

@onready var sprite: Sprite2D = $Sprite2D
@onready var colision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	var activa := empieza_visible
	_set_activa(activa)
	if retraso_inicial > 0.0:
		await get_tree().create_timer(retraso_inicial).timeout

	while true:
		if activa:
			await get_tree().create_timer(maxf(tiempo_visible - tiempo_aviso, 0.0)).timeout
			await _parpadear()
			activa = false
		else:
			await get_tree().create_timer(tiempo_oculta).timeout
			activa = true
		_set_activa(activa)

func _parpadear() -> void:
	if tiempo_aviso <= 0.0:
		return
	var pasos := 6
	var t := create_tween()
	for i in pasos:
		var alfa := 0.3 if i % 2 == 0 else 1.0
		t.tween_property(sprite, "modulate:a", alfa, tiempo_aviso / pasos)
	await t.finished

func _set_activa(activa: bool) -> void:
	colision.set_deferred("disabled", not activa)
	sprite.modulate.a = 1.0 if activa else 0.0
