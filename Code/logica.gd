extends Node2D
signal dia_actualizado(dia_actual)

func _on_timer_timeout() -> void:
	dia_actualizado.emit(dia_actualizado)
