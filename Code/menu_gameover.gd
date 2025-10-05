extends Control
@export var c=0

func money_update() -> void:
	$Label/Money.text(str(GameManager.money))


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/menu_inicio.tscn")


func _on_salir_pressed() -> void:
	get_tree().quit()
