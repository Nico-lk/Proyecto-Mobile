extends Node2D

const EscenaBoss := preload("res://Scenes/boss/boss.tscn")

var boss_spawned: bool = false

@onready var trigger: Area2D = $Trigger

func _ready() -> void:
	if trigger:
		trigger.body_entered.connect(_on_trigger_body_entered)

func _on_trigger_body_entered(body: Node2D) -> void:
	if boss_spawned:
		return
	if body.is_in_group("player"):
		boss_spawned = true
		_activar_jefe(body)

func _activar_jefe(player: Node2D) -> void:
	# 1. Instanciar el Boss arriba en la arena
	var boss = EscenaBoss.instantiate()
	boss.global_position = Vector2(390, -2550) # Cima / centro superior
	add_child(boss)
	
	# 2. Hacer Tween en la camara del jugador para enfocar la arena
	var cam: Camera2D = player.get_node_or_null("Camera2D")
	if cam:
		# Desbloquear limites momentaneamente o ajustarlos para el jefe
		var tween = create_tween().set_parallel(true)
		tween.tween_property(cam, "limit_top", -2700, 1.0)
		tween.tween_property(cam, "limit_bottom", -2300, 1.0)
