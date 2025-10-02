
extends Node
@export var max_nivel_agua: float = 100.0
@export var reduccion_por_segundo: float = 1.0 # Tasa de evaporación
@export var celda_de_mapa: Vector2i # Almacenará la posición (x, y) en el TileMap

@onready var indicador_agua: = $Barradeagua

var nivel_agua_actual: float = 100.0 # Nivel inicial

func _ready():
	indicador_agua.max_value = max_nivel_agua
	actualizar_visual_agua()

func _process(delta: float):
	# Lógica de Reducción (Evaporación)
	if nivel_agua_actual > 0:
		nivel_agua_actual -= reduccion_por_segundo * delta
		nivel_agua_actual = max(0.0, nivel_agua_actual)
		actualizar_visual_agua()
	
	# Aquí puedes añadir la lógica de crecimiento/marchitamiento de la semilla
	# if nivel_agua_actual == 0: ...

# FUNCIÓN PARA AUMENTAR EL NIVEL DE AGUA (RIEGO)
func regar(cantidad: float = 30.0):
	nivel_agua_actual += cantidad
	nivel_agua_actual = min(max_nivel_agua, nivel_agua_actual)
	actualizar_visual_agua()
	
func actualizar_visual_agua():
	indicador_agua.value = nivel_agua_actual
	# Opcional: Ocultar si está lleno o vacío
	# indicador_agua.visible = nivel_agua_actual > 0 and nivel_agua_actual < max_nivel_agua
