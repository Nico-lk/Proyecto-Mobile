extends Area2D

var direccion: Vector2 = Vector2.RIGHT
var velocidad: float = 500.0
var daño: int = 10
var vida: float = 2.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	rotation = direccion.angle()

func _physics_process(delta: float) -> void:
	global_position += direccion * velocidad * delta
	vida -= delta
	if vida <= 0.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemigos") and body.has_method("recibir_daño"):
		body.recibir_daño(daño)
		print(daño)
		queue_free()
	elif not body.is_in_group("player"):
		queue_free()
