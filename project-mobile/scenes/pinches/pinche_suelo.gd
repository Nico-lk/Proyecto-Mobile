extends Area2D

@export var tiempo_entre_danos: float = 1.0

var cooldown: float = 0.0

func _physics_process(delta: float) -> void:
	# Bajar el cooldown
	if cooldown > 0.0:
		cooldown -= delta
		return

	# Si el cooldown terminó, revisar si hay un jugador encima
	for body in get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("recibir_dano"):
			body.recibir_dano()
			cooldown = tiempo_entre_danos
			break
