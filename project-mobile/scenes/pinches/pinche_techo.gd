extends Area2D

@export var gravedad: float = 980.0
@export var velocidad_max: float = 800.0
@export var activado_por_jugador: bool = true

var velocidad: float = 0.0
var cayendo: bool = true
var roto: bool = false

func _ready() -> void:
	print("Pinche listo en: ", global_position)
	body_entered.connect(_on_body_entered)
	set_physics_process(not activado_por_jugador)
	
func activar() -> void:
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if roto:
		return
	velocidad = min(velocidad + gravedad * delta, velocidad_max)
	position.y += velocidad * delta

func _on_body_entered(body: Node2D) -> void:
	if roto:
		return

	# Si toca al jugador, le hace daño
	if body.is_in_group("player"):
		if body.has_method("recibir_dano"):
			body.recibir_dano()
	romper()

func romper() -> void:
	roto = true
	set_deferred("monitoring", false)
	
	# Efecto simple: se desvanece rápido
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)

func _on_detector_body_entered(body: Node2D) -> void:
	print("Pinche chocó con: ", body.name)
	if body.is_in_group("player"):
		activar()
