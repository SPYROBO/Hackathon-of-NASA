extends Control
@onready var game_manager = get_tree().get_first_node_in_group("game_manager") 
@onready var label_dia = $LabelDia
@onready var label_semana = $LabelSemana

# La lógica ahora usa las variables del GameManager
func _on_logica_dia_actualizado(_dia_actual: Variant) -> void:
	if game_manager.dia_index == 6:
		print("Semana terminada")
		game_manager.dia_index = 0
		label_dia.set_text(game_manager.DIAS_DE_LA_SEMANA[game_manager.dia_index])
		
		if game_manager.semana_index == 3: # Índice 3 es Semana 4
			print("Juego terminado")
		else:
			game_manager.semana_index += 1
			label_semana.set_text(game_manager.SEMANAS[game_manager.semana_index])
			
			# 🚨 NOTIFICAR AL GAME MANAGER (y al ClimaManager)
			game_manager.notificar_nueva_semana() 
			
	else:
		game_manager.dia_index += 1
		label_dia.set_text(game_manager.DIAS_DE_LA_SEMANA[game_manager.dia_index])
