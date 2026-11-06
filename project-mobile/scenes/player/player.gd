extends CharacterBody2D


@onready var tilemap: TileMapLayer = $"../TileMapLayer"

@export var pantalla_muerte: CanvasLayer

@export var speed: float = 300.0
@export var jump_velocity_front: float = -500.0
@export var jump_velocity_side: float = -450.0
@export var gravity: float = 980.0
@export var vida_maxima: int = 100
@export var sacudidas_necesarias: int = 3
@export var ventana_sacudida: float = 0.6   # segundos máximos entre saltos

var sanguijuelas: Array[Node2D] = []
var sacudidas: int = 0
var tiempo_sacudida: float = 0.0

signal vida_cambiada(actual: int, maxima: int)

var vida_actual: int

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
	vida_actual = vida_maxima
	var f := animated_sprite.sprite_frames
	print("SpriteFrames: ", f.resource_path, " | idle speed: ", f.get_animation_speed(&"idle"))

func recibir_daño(cantidad: int) -> void:
	vida_actual = max(vida_actual - cantidad, 0)
	vida_cambiada.emit(vida_actual, vida_maxima)

	animated_sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	if not is_inside_tree():
		return
	animated_sprite.modulate = Color.WHITE

	if vida_actual <= 0:
		morir()

func _physics_process(delta: float) -> void:
	
	velocity.y += gravity * delta

	var input_dir := Input.get_axis("ui_left", "ui_right")
	velocity.x = input_dir * speed

	var is_aiming_up := Input.is_action_pressed("ui_up")

	if Input.is_action_pressed("saltar") and is_on_floor():
		jump_type = "side" if input_dir != 0 else "front"
		velocity.y = jump_velocity_side if jump_type == "side" else jump_velocity_front
	if tiempo_sacudida > 0.0:
		tiempo_sacudida -= delta
		if tiempo_sacudida <= 0.0:
			sacudidas = 0

	if Input.is_action_just_pressed("ui_accept"):
		intentar_sacudir()

	move_and_slide()
	update_animations(input_dir, is_aiming_up)

func registrar_sanguijuela(s: Node2D) -> void:
	if s not in sanguijuelas:
		sanguijuelas.append(s)

func quitar_sanguijuela(s: Node2D) -> void:
	sanguijuelas.erase(s)

func intentar_sacudir() -> void:
	sanguijuelas = sanguijuelas.filter(func(s): return is_instance_valid(s))
	if sanguijuelas.is_empty():
		sacudidas = 0
		return

	sacudidas += 1
	tiempo_sacudida = ventana_sacudida

	if sacudidas >= sacudidas_necesarias:
		sacudidas = 0
		for s in sanguijuelas.duplicate():
			var dir = (s.global_position - global_position).normalized() + Vector2.UP * 0.5
			s.sacudir(dir.normalized())

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

func recibir_dano() -> void:
	vida -= 50
	print("Vida restante: ", vida)

	var tween := create_tween()
	tween.tween_property(animated_sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.1)

	if vida <= 0:
		morir()

var muerto: bool = false

func morir() -> void:
	if muerto:
		return
	muerto = true
	set_physics_process(false)
	velocity = Vector2.ZERO

	# Pequeña pausa para que se vea el golpe antes de mostrar los botones
	await get_tree().create_timer(0.5).timeout
	pantalla_muerte.mostrar()
