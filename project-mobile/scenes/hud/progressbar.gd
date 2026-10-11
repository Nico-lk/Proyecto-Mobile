extends ProgressBar

func _ready() -> void:
	await get_tree().process_frame
	var p = get_tree().get_first_node_in_group("player")
	if p == null:
		return
	p.vida_cambiada.connect(_on_vida_cambiada)
	max_value = p.vida_maxima
	value = p.vida_actual

func _on_vida_cambiada(actual: int, maxima: int) -> void:
	max_value = maxima
	value = actual
