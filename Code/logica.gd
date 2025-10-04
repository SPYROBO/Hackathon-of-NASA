extends Node2D
signal dia_actualizado(dia_actual)

func _on_timer_timeout() -> void:
	dia_actualizado.emit(dia_actualizado)


func _on_barrasemanal_fin_de_juego(_fin: Variant) -> void:
	get_tree().change_scene_to_file("res://Scenes/menu_ganaste.tscn")
