extends CharacterBody2D

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

func _ready() -> void:
	var f := animated_sprite.sprite_frames
	print("SpriteFrames: ", f.resource_path, " | idle speed: ", f.get_animation_speed(&"idle"))

func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta

	var input_dir := Input.get_axis("ui_left", "ui_right")
	velocity.x = input_dir * speed

	var is_aiming_up := Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)

	if Input.is_key_pressed(KEY_SPACE) and is_on_floor():
		jump_type = "side" if input_dir != 0 else "front"
		velocity.y = jump_velocity_side if jump_type == "side" else jump_velocity_front

	move_and_slide()
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
