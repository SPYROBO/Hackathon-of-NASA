extends Control

func _on_timer_timeout() -> void:
	print("senaltimer")
	get_tree().change_scene_to_file("res://Scenes/menu_ganaste.tscn")
