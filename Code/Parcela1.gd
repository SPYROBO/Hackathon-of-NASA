extends Node # Hereda del nodo Parcela1 (que es un Node)

# --- PROPIEDADES DE AGUA Y MAPA ---
@export var max_nivel_agua: float = 100.0
@export var reduccion_por_segundo: float = 1.0 # Tasa de evaporación
@export var celda_de_mapa: Vector2i # Almacenará la posición (x, y) en el TileMap
@onready var indicador_agua: = $Barradeagua
var nivel_agua_actual: float = 100.0 # Nivel inicial


# --- PROPIEDADES DE PLANTACIÓN ---
@export var parcela_id: int = 1  # Para identificar esta parcela
var is_planted: bool = false
var current_plant_id: String = ""


# --- REFERENCIAS A NODOS HIJOS ---
@onready var area_interaccion: Area2D = $Area2D # Referencia al Area2D hijo
@onready var plant_visual = $PlantVisualSprite2D # Asume que añadiste este nodo

# --- REFERENCIA AL SINGLETON (GameManager) ---
@onready var game_manager = get_tree().get_first_node_in_group("game_manager") # Asumiendo un grupo
# Asegúrate que el Autoload se llame "GameManager"


func _ready():
	# Inicialización de la lógica de Agua
	indicador_agua.max_value = max_nivel_agua
	actualizar_visual_agua()

	# Inicialización de la lógica de Plantación
	plant_visual.visible = false
	indicador_agua.visible = false
	
	# CONECTAR LA SEÑAL DEL NODO HIJO Area2D
	# Conectamos la señal 'input_event' emitida por el nodo Area2D hijo
	area_interaccion.input_event.connect(_on_area_input_event)


func _process(delta: float):
	# Lógica de Reducción (Evaporación)
	if is_planted:
		if nivel_agua_actual > 0:
			nivel_agua_actual -= reduccion_por_segundo * delta
			nivel_agua_actual = max(0.0, nivel_agua_actual)
			actualizar_visual_agua()
	else:
		indicador_agua.visible = false
	# Aquí puedes añadir la lógica de crecimiento/marchitamiento de la semilla


# --- MANEJO DE LA SEÑAL DEL AREA2D HIJO ---

# Esta función es el "slot" que recibe la señal del Area2D.
func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	# Solo nos interesa el clic izquierdo del ratón
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		handle_plot_click()


# --- LÓGICA DE PLANTACIÓN (USADA AL HACER CLIC) ---

# Parcela1.gd (Fragmento handle_plot_click)

func handle_plot_click():
	
	# 1. LÓGICA DE PLANTACIÓN (Prioridad alta y siempre posible con arrastre)
	if game_manager.is_dragging_seed:
		if not is_planted:
			var seed_id = game_manager.current_seed_id_to_plant
			plant_seed(seed_id)
			game_manager.stop_dragging_seed() # Finaliza el arrastre
			print("Plantada semilla ", seed_id, " en Parcela ", parcela_id)
		else:
			print("Error: Parcela ", parcela_id, " ya está ocupada. No se puede plantar.")
		# El clic se consume aquí, no pasa a la siguiente lógica
		return 
		
	
	# 2. LÓGICA DE ACCIONES DE BARRA LATERAL (Si no estamos arrastrando)
	
	match game_manager.current_action_mode:
		
		GameManager.Action.WATER:
			if is_planted:
				regar(30.0) 
				print("Regada planta en Parcela ", parcela_id, ". Nivel de agua: ", nivel_agua_actual)
				game_manager.set_action_mode(GameManager.Action.NONE) # Desactivar modo
			else:
				print("No hay planta para regar en Parcela ", parcela_id)
		
		GameManager.Action.HARVEST:
			if is_planted:
				# Lógica de cosecha
				print("Cosechando planta en Parcela ", parcela_id)
				game_manager.set_action_mode(GameManager.Action.NONE) # Desactivar modo
			else:
				print("No hay planta para cosechar en Parcela ", parcela_id)
				
		GameManager.Action.FUMIGATE:
			if is_planted:
				# Lógica de fumigación
				print("Fumigando planta en Parcela ", parcela_id)
				game_manager.set_action_mode(GameManager.Action.NONE) # Desactivar modo
			else:
				print("No hay planta para fumigar en Parcela ", parcela_id)

		GameManager.Action.NONE:
			# Clic normal sin acción activa (ej. mostrar información)
			if is_planted:
				pass


# --- MÉTODO PRINCIPAL DE PLANTACIÓN ---
func plant_seed(seed_id: String):
	is_planted = true
	current_plant_id = seed_id
	
	game_manager.register_plant_creation(parcela_id, current_plant_id) # Usa la ID de la parcela
	var seed_texture = game_manager.seed_drag_icon_texture 
	
	# Configurar y hacer visible el nodo visual
	plant_visual.texture = seed_texture
	plant_visual.modulate = Color(1.0, 1.0, 1.0, 1.0)
	plant_visual.visible = true
	indicador_agua.visible = true


# --- FUNCIONES DE AGUA (RIEGO Y VISUAL) ---
func regar(cantidad: float = 30.0):
	nivel_agua_actual += cantidad
	nivel_agua_actual = min(max_nivel_agua, nivel_agua_actual)
	actualizar_visual_agua()
	
func actualizar_visual_agua():
	indicador_agua.value = nivel_agua_actual
	game_manager.update_plot_water(parcela_id, nivel_agua_actual) 
	# Opcional: Ocultar si está lleno o vacío
