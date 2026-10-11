extends Node2D

@export var escena_enemigo: PackedScene     # arrastra enemy.tscn aquí
@export var intervalo: float = 3.0          # segundos entre spawns
@export var max_enemigos: int = 5           # máximo vivos a la vez
@export var area_spawn: Vector2 = Vector2(600, 200)   # ancho y alto de la zona

@onready var timer: Timer = $Timer

func _ready() -> void:
	timer.wait_time = intervalo
	timer.one_shot = false
	timer.timeout.connect(_on_timer_timeout)
	timer.start()

func _on_timer_timeout() -> void:
	if escena_enemigo == null:
		push_warning("Falta asignar escena_enemigo en el spawner")
		return
	if get_tree().get_nodes_in_group("enemigos").size() >= max_enemigos:
		return

	var enemigo = escena_enemigo.instantiate()
	get_tree().current_scene.add_child(enemigo)

	var offset = Vector2(
		randf_range(-area_spawn.x / 2.0, area_spawn.x / 2.0),
		randf_range(-area_spawn.y / 2.0, area_spawn.y / 2.0))
	enemigo.global_position = global_position + offset
	enemigo.home = enemigo.global_position   # su zona de vagar empieza donde nace
