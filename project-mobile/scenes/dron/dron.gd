extends CharacterBody2D

@export var velocidad: float = 150.0
@export var distancia_minima: float = 0.0  # Distancia para no empujar al jugador
@export var suavizado_pegado: float = 0.1  # Qué tan rápido se pega al jugador (entre 0.0 y 1.0
@export var radio_orbita: float = 60.0    # Distancia en píxeles a la que flotará del jugador
@export var velocidad_giro: float = 2.0    # Qué tan rápido da vueltas (números más altos = más rápido)
var tiempo_transcurrido: float = 0.0

# El signo '?' permite que la variable sea Node2D o null sin dar error
var jugador: Node2D = null
var enemigos_en_rango: Array[Node2D] = []
var objetivo_actual: Node2D = null 

@onready var area_deteccion: Area2D = $AreaDeteccion
@onready var timer_ataque: Timer = $TimerAtaque



func _ready() -> void:
	# Buscamos al jugador en el grupo "jugador"
	var jugadores = get_tree().get_nodes_in_group("player")
	if jugadores.size() > 0:
		jugador = jugadores[0] # <-- ASEGÚRATE DE QUE TENGA EL [0] AL FINAL
	
	# Conectamos las señales del Area2D desde el código
	area_deteccion.body_entered.connect(_on_enemigo_entrado)
	area_deteccion.body_exited.connect(_on_enemigo_salido)
	timer_ataque.timeout.connect(_on_timer_ataque_timeout)

func _physics_process(_delta: float) -> void:
	actualizar_objetivo()
	
	# COMPORTAMIENTO 1: Si hay un enemigo cerca, se enfoca en atacar
	if objetivo_actual and is_instance_valid(objetivo_actual):
		velocity = Vector2.ZERO
		if timer_ataque.is_stopped():
			timer_ataque.start()
	
	# COMPORTAMIENTO 2: Si NO hay enemigos, flota del lado izquierdo del jugador
	elif jugador and is_instance_valid(jugador):
		timer_ataque.stop()
		
		# Usamos el tiempo solo para un balanceo sutil hacia arriba y abajo
		tiempo_transcurrido += _delta * 3.0
		var flotacion_y = sin(tiempo_transcurrido) * 6.0 # Flota 6 píxeles arriba y abajo
		
		# Posición ideal: 'radio_orbita' a la izquierda (-X) y ligeramente arriba con el balanceo
		var posicion_objetivo = jugador.global_position + Vector2(-radio_orbita, -100 + flotacion_y)
		
		# Suavizamos el movimiento para que te siga de forma fluida
		global_position = global_position.lerp(posicion_objetivo, suavizado_pegado)
	else:
		velocity = Vector2.ZERO

	move_and_slide()

# Limpiamos esta función para garantizar que jamás elija al jugador como objetivo
func actualizar_objetivo() -> void:
	# Si la lista está vacía, no hay objetivo
	if enemigos_en_rango.is_empty():
		objetivo_actual = null
		return
		
	var enemigo_mas_cercano: Node2D = null
	var menor_distancia: float = INF
	
	for enemigo in enemigos_en_rango:
		# Filtro de seguridad: que exista, que no sea el jugador y que sea del grupo correcto
		if is_instance_valid(enemigo) and enemigo != jugador and enemigo.is_in_group("enemigos"):
			var dist = global_position.distance_to(enemigo.global_position)
			if dist < menor_distancia:
				menor_distancia = dist
				enemigo_mas_cercano = enemigo
				
	objetivo_actual = enemigo_mas_cercano

# --- GESTIÓN DE SEÑALES ---

func _on_enemigo_entrado(body: Node2D) -> void:
	# Condición estricta: Debe estar en el grupo enemigos y NO ser el jugador actual
	if body.is_in_group("enemigos") and body != jugador:
		if body not in enemigos_en_rango:
			enemigos_en_rango.append(body)

func _on_enemigo_salido(body: Node2D) -> void:
	if body in enemigos_en_rango:
		enemigos_en_rango.erase(body)

func _on_timer_ataque_timeout() -> void:
	if objetivo_actual and is_instance_valid(objetivo_actual):
		atacar(objetivo_actual)

# --- LÓGICA DE ATAQUE ---

func atacar(objetivo: Node2D) -> void:
	print("Atacando a: ", objetivo.name)
	# Aquí ejecutas tu lógica de daño o disparos. Por ejemplo:
	if objetivo.has_method("recibir_daño"):
		objetivo.recibir_daño(10) # Aplica 10 de daño
