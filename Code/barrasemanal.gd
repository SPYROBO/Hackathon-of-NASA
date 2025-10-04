extends Control
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
signal fin_de_juego(fin)


func _on_logica_dia_actualizado(_dia_actual: Variant) -> void:
	if i==6:
		print("Semana terminada")
		i=0
		$LabelDia.set_text(DIAS_DE_LA_SEMANA[i])
		if m==3:
			print("Juego terminado")
			fin_de_juego.emit(fin_de_juego)
		else:
			m=m+1
			$LabelSemana.set_text(Semana[m])
			
	else:
		i=i+1
		$LabelDia.set_text(DIAS_DE_LA_SEMANA[i])
 
