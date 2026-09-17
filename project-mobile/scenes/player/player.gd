extends CharacterBody2D

@export var speed: float = 300.0
@export var jump_velocity: float = -400.0
@export var gravity: float = 980.0

# Nombres de animaciones
const ANIM_IDLE := "idle"
const ANIM_RUN := "correr"
const ANIM_JUMP := "salto"

@onready var animated_sprite: AnimatedSprite2D = $Player_animation

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	var input_dir = Input.get_axis("ui_left", "ui_right")
	velocity.x = input_dir * speed

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	update_animations(input_dir)

	move_and_slide()

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
