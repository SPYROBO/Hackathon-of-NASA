extends Node2D

signal dia_actualizado(dia_actual)

var dinero_min = 500

func _on_timer_timeout() -> void:
	dia_actualizado.emit(dia_actualizado)


func _on_barrasemanal_fin_de_juego(_fin: Variant, _dinero: int) -> void:
	var map = get_tree().get_first_node_in_group("map")
	if map:
		map.reset_plot()
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		game_manager.money = 100
	if _dinero >= dinero_min:
		get_tree().change_scene_to_file("res://Scenes/menu_ganaste.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/menu_gameover.tscn")
