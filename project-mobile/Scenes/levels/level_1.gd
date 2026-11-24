extends Node2D

const EscenaBoss := preload("res://scenes/boss/boss.tscn")

var boss_spawned: bool = false

@onready var trigger: Area2D = $Trigger


func _on_trigger_body_entered(body: Node2D) -> void:
	if boss_spawned:
		return
	if body.is_in_group("player"):
		boss_spawned = true
		_activar_jefe.call_deferred(body)

func _activar_jefe(player: Node2D) -> void:
	print("ACTIVAR JEFE llamado")
	# Frena el spawn y limpia los bichos que quedaron abajo
	get_tree().call_group("spawners", "detener")
	for e in get_tree().get_nodes_in_group("enemigos"):
		if e.has_method("desvanecer") and e.global_position.y > player.global_position.y + 200.0:
			e.desvanecer()

	# Instanciar el Boss en la arena
	var boss = EscenaBoss.instantiate()
	boss.position = Vector2(390, -3300) # centro de la arena del boss
	add_child(boss)

	# Tween en la camara del jugador para enfocar la arena
	var cam: Camera2D = player.get_node_or_null("Camera2D")
	if cam:
		var tween = create_tween().set_parallel(true)
		tween.tween_property(cam, "limit_top", -3900.0, 1.0)
		tween.tween_property(cam, "limit_bottom", -2380.0, 1.0)
