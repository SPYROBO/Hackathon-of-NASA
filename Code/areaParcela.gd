extends Area2D

# --- Propiedades de la Parcela ---
# Necesitas una forma de identificar esta parcela. Configúralo en el Inspector.
@export var parcela_id: int = 1 
var is_planted: bool = false
var current_plant_id: String = ""

# --- Referencia al Singleton (GameManager) ---
@onready var game_manager = get_tree().get_first_node_in_group("game_manager") # Asumiendo un grupo
# Asegúrate que el Autoload se llame "GameManager" o ajústalo aquí.

# --- Nodos Visuales ---
# Ya que no usas Health Indicator, necesitamos un nodo para la planta en sí.
# Puedes añadir un Sprite2D o TextureRect como hijo de tu Parcela para esto.
@onready var plant_visual = $PlantVisualSprite2D # Asume que añadiste este nodo

func _ready():
	# Inicialmente, la parcela está vacía
	plant_visual.visible = false
	
	# Conectamos la señal de interacción del Area2D
	# El Area2D tiene un nodo CollisionShape2D hijo para definir el área.
	# Usaremos la señal 'input_event' para capturar clics.
	input_event.connect(_on_input_event)

# --- Manejo del Evento de Entrada ---
# Esta función se llama cuando hay un evento de entrada DENTRO del CollisionShape2D
func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	# Solo nos interesa el clic izquierdo del ratón
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		handle_plot_click()


# --- Lógica de Plantación ---

func handle_plot_click():
	# 1. VERIFICAR si el GameManager está en modo de arrastre
	if game_manager.is_dragging_seed:
		
		# 2. VERIFICAR si la parcela está vacía 
		if not is_planted:
			
			var seed_id = game_manager.current_seed_id_to_plant
			
			# 3. Ejecutar plantación
			plant_seed(seed_id)
			
			# 4. Detener el modo de arrastre del GameManager
			game_manager.stop_dragging_seed()
			
			# Opcional: Mostrar mensaje para confirmar plantación
			print("Plantada semilla ", seed_id, " en Parcela ", parcela_id)

		else:
			# Opción: Mostrar un mensaje "Parcela ocupada"
			print("Error: Parcela ", parcela_id, " ya está ocupada por ", current_plant_id)
	
	# Si no estás arrastrando una semilla, el clic podría abrir información, cosechar, etc.
	elif is_planted:
		# Lógica de interacción normal (ej. cosechar, regar, ver info)
		pass

# --- Método principal de plantación ---
func plant_seed(seed_id: String):
	is_planted = true
	current_plant_id = seed_id
	
	# Obtener la textura de la semilla que el GameManager tiene lista
	var seed_texture = game_manager.seed_drag_icon_texture 
	
	# Configurar y hacer visible el nodo visual
	plant_visual.texture = seed_texture
	plant_visual.modulate = Color(1.0, 1.0, 1.0, 1.0)
	plant_visual.visible = true
	
