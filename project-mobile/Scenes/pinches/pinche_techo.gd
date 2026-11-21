extends Area2D

@export var gravedad: float = 980.0
@export var velocidad_max: float = 800.0
@export var activado_por_jugador: bool = true
@export var danio: int = 10

@export_group("Respawn")
@export var respawn: bool = false
@export var tiempo_respawn: float = 3.0

var velocidad: float = 0.0
var cayendo: bool = false
var roto: bool = false
var pos_inicial: Vector2


func _ready() -> void:
	pos_inicial = position
	body_entered.connect(_on_body_entered)
	_preparar()

# Deja el pinche en su estado inicial (sirve al nacer y al reaparecer)
func _preparar() -> void:
	position = pos_inicial
	velocidad = 0.0
	cayendo = false
	roto = false
	modulate.a = 1.0
	monitoring = false
	set_physics_process(false)
	if not activado_por_jugador:
		activar()
	else:
		_revisar_detector()

func activar() -> void:
	if cayendo or roto:
		return
	cayendo = true
	set_physics_process(true)
	# Espera un poco para separarse de la plataforma antes de detectar choques
	await get_tree().create_timer(0.15).timeout
	if not roto:
		monitoring = true

func _physics_process(delta: float) -> void:
	if roto:
		return
	velocidad = min(velocidad + gravedad * delta, velocidad_max)
	position.y += velocidad * delta

func _on_body_entered(body: Node2D) -> void:
	if roto:
		return
	if body.is_in_group("player") and body.has_method("recibir_daño"):
		body.recibir_daño(danio)
	romper()

func romper() -> void:
	roto = true
	set_physics_process(false)
	set_deferred("monitoring", false)

	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished

	if not respawn:
		queue_free()
		return

	await get_tree().create_timer(tiempo_respawn).timeout
	_preparar()
	
func _revisar_detector() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	for body in $Detector.get_overlapping_bodies():
		if body.is_in_group("player"):
			activar()
			return

func _on_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		activar()
