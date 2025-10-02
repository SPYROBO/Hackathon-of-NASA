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
@export var i=0



func _on_logica_dia_actualizado(_dia_actual: Variant) -> void:
	if i==6:
		print("tiempo termindo")
	else:
		i=i+1
		$LabelDia.set_text(DIAS_DE_LA_SEMANA[i])
 
