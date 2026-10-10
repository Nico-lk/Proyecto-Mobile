extends CharacterBody2D

@export var vida_maxima: int = 30
var vida_actual: int

func _ready() -> void:
	vida_actual = vida_maxima

# Esta es la función que el aliado llamará automáticamente al atacar
func recibir_daño(cantidad: int) -> void:
	vida_actual -= cantidad
	print(name, " recibió ", cantidad, " de daño. Vida restante: ", vida_actual)
	
	# Efecto visual simple: parpadeo rojo al recibir daño
	modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE
	
	if vida_actual <= 0:
		morir()

func morir() -> void:
	print(name, " ha sido derrotado.")
	queue_free() # Elimina al enemigo del mapa de forma segura
