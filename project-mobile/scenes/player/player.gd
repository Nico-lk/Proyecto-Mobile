extends CharacterBody2D

@export var speed: float = 300.0
@export var jump_velocity: float = -400.0
@export var gravity: float = 980.0
@export var vida_maxima: int = 100
@export var sacudidas_necesarias: int = 3
@export var ventana_sacudida: float = 0.6   # segundos máximos entre saltos

var sanguijuelas: Array[Node2D] = []
var sacudidas: int = 0
var tiempo_sacudida: float = 0.0

signal vida_cambiada(actual: int, maxima: int)

var vida_actual: int

# Nombres de animaciones
const ANIM_IDLE := "idle"
const ANIM_RUN := "correr"
const ANIM_JUMP := "salto"

@onready var animated_sprite: AnimatedSprite2D = $Player_animation

func _ready() -> void:
	vida_actual = vida_maxima

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

func morir() -> void:
	get_tree().reload_current_scene()   # provisional, luego lo cambiamos por Game Over

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	var input_dir = Input.get_axis("ui_left", "ui_right")
	velocity.x = input_dir * speed

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	if tiempo_sacudida > 0.0:
		tiempo_sacudida -= delta
		if tiempo_sacudida <= 0.0:
			sacudidas = 0

	if Input.is_action_just_pressed("ui_accept"):
		intentar_sacudir()

	update_animations(input_dir)

	move_and_slide()

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

func update_animations(input_dir: float) -> void:
	if input_dir > 0:
		animated_sprite.flip_h = false
	elif input_dir < 0:
		animated_sprite.flip_h = true

	var next_anim: StringName
	if not is_on_floor():
		next_anim = ANIM_JUMP
	elif input_dir != 0.0:
		next_anim = ANIM_RUN
	else:
		next_anim = ANIM_IDLE
	if animated_sprite.sprite_frames.has_animation(next_anim):
		animated_sprite.play(next_anim)
	else:
		animated_sprite.stop()
		animated_sprite.frame = 0
