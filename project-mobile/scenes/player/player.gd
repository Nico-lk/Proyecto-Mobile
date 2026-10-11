extends CharacterBody2D


@onready var tilemap: TileMapLayer = $"../TileMapLayer"

@export var speed: float = 300.0
@export var jump_velocity_front: float = -500.0
@export var jump_velocity_side: float = -450.0
@export var gravity: float = 980.0

# 0 = usar la velocidad guardada en el SpriteFrames. >0 = sobrescribirla.
@export_group("Animation FPS override")
@export_range(0.0, 60.0, 0.5) var idle_fps: float = 0.0
@export_range(0.0, 60.0, 0.5) var walk_fps: float = 0.0
@export_range(0.0, 60.0, 0.5) var salto_frente_fps: float = 0.0
@export_range(0.0, 60.0, 0.5) var salto_lateral_fps: float = 0.0
@export_range(0.0, 60.0, 0.5) var aiming_up_fps: float = 0.0
@export_range(0.0, 60.0, 0.5) var aim_up_fps: float = 0.0

@onready var animated_sprite: AnimatedSprite2D = $Player_animation

var jump_type: String = "front"
var celdas_rompiendose: Dictionary = {}  # Evita activar la misma celda dos veces
var vida: int = 100

func _ready() -> void:
	var f := animated_sprite.sprite_frames
	print("SpriteFrames: ", f.resource_path, " | idle speed: ", f.get_animation_speed(&"idle"))

func _physics_process(delta: float) -> void:
	
	if vida <= 0:
		#Agregar muerte
		pass

	velocity.y += gravity * delta

	var input_dir := Input.get_axis("ui_left", "ui_right")
	velocity.x = input_dir * speed

	var is_aiming_up := Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)

	if Input.is_key_pressed(KEY_SPACE) and is_on_floor():
		jump_type = "side" if input_dir != 0 else "front"
		velocity.y = jump_velocity_side if jump_type == "side" else jump_velocity_front

	move_and_slide()
	detectar_tile()
	update_animations(input_dir, is_aiming_up)

func update_animations(input_dir: float, is_aiming_up: bool) -> void:
	if input_dir > 0:
		animated_sprite.flip_h = true
	elif input_dir < 0:
		animated_sprite.flip_h = false

	if not is_on_floor():
		if jump_type == "side":
			_play(&"salto_lateral", salto_lateral_fps)
		else:
			_play(&"salto_frente", salto_frente_fps)
	elif is_aiming_up:
		if input_dir != 0:
			_play(&"aiming_up", aiming_up_fps)
		else:
			_play(&"aim_up", aim_up_fps)
	elif input_dir != 0:
		_play(&"walk", walk_fps)
	else:
		_play(&"idle", idle_fps)

func _play(anim: StringName, fps: float) -> void:
	var frames := animated_sprite.sprite_frames
	if not frames.has_animation(anim):
		push_warning("No existe la animación: " + str(anim))
		return
	if fps > 0.0:
		frames.set_animation_speed(anim, fps)
	if animated_sprite.animation != anim:
		animated_sprite.play(anim)

func detectar_tile():
	for i in get_slide_collision_count():
		var choque := get_slide_collision(i)
		if choque.get_collider() != tilemap:
			continue
		
		var celda := tilemap.local_to_map(tilemap.to_local(choque.get_position() - choque.get_normal() * 2.0))
		
		# Si ya se está rompiendo, ignorar
		if celdas_rompiendose.has(celda):
			continue
		
		var datos := tilemap.get_cell_tile_data(celda)
		if datos and datos.get_custom_data("quiebre_tile") == "rompible":
			romper_tile(celda)

func romper_tile(celda_inicial: Vector2i) -> void:
	celdas_rompiendose[celda_inicial] = true
	print("¡Plataforma rompiéndose!")
	await get_tree().create_timer(0.4).timeout
	
	# Buscar todas las celdas conectadas del mismo tipo
	var celdas_a_borrar: Array[Vector2i] = []
	var celdas_revisadas: Dictionary = {}
	var cola: Array[Vector2i] = [celda_inicial]
	
	while cola.size() > 0:
		var actual: Vector2i = cola.pop_back()
		
		if celdas_revisadas.has(actual):
			continue
		celdas_revisadas[actual] = true
		
		var datos := tilemap.get_cell_tile_data(actual)
		if datos == null:
			continue
		if datos.get_custom_data("quiebre_tile") != "rompible":
			continue
		
		celdas_a_borrar.append(actual)
		
		# Añadir vecinos (arriba, abajo, izquierda, derecha)
		cola.append(actual + Vector2i(1, 0))
		cola.append(actual + Vector2i(-1, 0))
		cola.append(actual + Vector2i(0, 1))
		cola.append(actual + Vector2i(0, -1))
	
	# Borrar todas las celdas encontradas
	for c in celdas_a_borrar:
		tilemap.erase_cell(c)
	
	celdas_rompiendose.erase(celda_inicial)
	
func recibir_dano() -> void:
	vida-=5
	print("Vida restante: ", vida)
	# Pequeño feedback visual: parpadeo rojo
	var tween := create_tween()
	tween.tween_property(animated_sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.1)
	
	if vida <= 0:
		get_tree().reload_current_scene()
