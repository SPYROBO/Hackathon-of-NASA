extends Control
@onready var game_manager = get_tree().get_first_node_in_group("game_manager") 
@onready var label_dia = $LabelDia
@onready var label_semana = $LabelSemana
const DIAS_DE_LA_SEMANA: Array[String] = [
	"Lunes",
	"Martes",
	"Miércoles",
	"Jueves",
	"Viernes",
	"Sábado",
    "Domingo"
]
const Semana: Array[String] = [
	"Semana 1",
	"Semana 2",
	"Semana 3",
	"Semana 4"
]
@export var i=0
@export var m=0
signal fin_de_juego(fin, dinero)


# La lógica ahora usa las variables del GameManager
func _on_logica_dia_actualizado(_dia_actual: Variant) -> void:
	if game_manager.dia_index == 6:
		print("Semana terminada")
		game_manager.dia_index = 0
		label_dia.set_text(game_manager.DIAS_DE_LA_SEMANA[game_manager.dia_index])
		
		if game_manager.semana_index == 3: # Índice 3 es Semana 4
			print("Juego terminado")
			var final_money = game_manager.money
			fin_de_juego.emit(fin_de_juego, final_money)
		else:
			game_manager.semana_index += 1
			label_semana.set_text(game_manager.SEMANAS[game_manager.semana_index])
			
			# 🚨 NOTIFICAR AL GAME MANAGER (y al ClimaManager)
			game_manager.notificar_nueva_semana() 
			
	else:
		game_manager.dia_index += 1
		label_dia.set_text(game_manager.DIAS_DE_LA_SEMANA[game_manager.dia_index])
