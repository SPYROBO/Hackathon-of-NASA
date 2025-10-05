extends Node

enum Action {
	NONE,       # Modo por defecto
	WATER,      # Botón de regar presionado
	HARVEST,    # Botón de cosechar presionado
	FUMIGATE    # Botón de fumigar presionado
}
var ACTION_TEXTURES = {
	Action.WATER: load("res://icons/gota.png"),
	Action.HARVEST: load("res://icons/azada.png"),
	Action.FUMIGATE: load("res://icons/fumigate.png")
}
var PLANT_REWARDS = {
	"morron": {"money": 8, "item": "morron"},
	"cebolla": {"money": 4, "item": "cebolla"}, 
	"cereza": {"money": 4, "item": "cereza"},      # Fruta rara - más valor
	"mango": {"money": 8, "item": "mango"},        # Fruta tropical - alto valor
	"manzana": {"money": 2, "item": "manzana"},    # Fruta común
	"tomate": {"money": 4, "item": "tomate"},      # Vegetal común
	"zanahoria1": {"money": 8, "item": "zanahoria1"}, # Vegetal básico
	"berenjena": {"money": 4, "item": "berenjena"},   # Vegetal especial
	"lechuga": {"money": 4, "item": "lechuga"},    # Vegetal rápido crecimiento
	"rabanos": {"money": 2, "item": "rabanos"},    # Vegetal pequeño
	"gizantes": {"money": 8, "item": "gizantes"},  # Legumbre
	"zanahoria2": {"money": 4, "item": "zanahoria2"}  # Variante de zanahoria
}

var farm_plot_states: Dictionary = {}

var current_action_mode: Action = Action.NONE
var money: int = 100

# m es el índice de la semana actual (0 a 3)
var semana_index: int = 0 
# i es el índice del día actual (0 a 6)
var dia_index: int = 0 

var dia_cero_unix: float = 0.0

const DIAS_DE_LA_SEMANA: Array[String] = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"]
const SEMANAS: Array[String] = ["Semana 1", "Semana 2", "Semana 3", "Semana 4"]


func _ready():
	# Asegúrate de añadir el GameManager a un grupo para fácil referencia
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("game_manager")
	var fixed_date_dict = {
		"year": 2024,
		"month": 8,
		"day": 1,
		"hour": 0,
		"minute": 0,
		"second": 0
	}
	# 🚨 LÍNEA CORREGIDA: Agregamos `true` como segundo argumento (UTC)
	# y usamos la clase Time correctamente para evitar el error de Parseo.
	dia_cero_unix = Time.get_unix_time_from_datetime_dict(fixed_date_dict)
		
func notificar_nueva_semana():
	# Solo si el ClimaManager existe, busca nuevos datos.
	var clima_manager = get_tree().get_first_node_in_group("clima_manager") 
	if is_instance_valid(clima_manager):
		# Le pasamos el índice de la semana (0, 1, 2, 3)
		clima_manager.fetch_clima_por_semana(semana_index) 

func set_action_mode(mode: Action):
	# Si se intenta cambiar a un modo que ya está activo, o a NONE, desactiva el modo actual
	if current_action_mode == mode and mode != Action.NONE:
		current_action_mode = Action.NONE
		print("Modo ", mode, " desactivado.")
	else:
		current_action_mode = mode
		print("Modo de acción establecido a: ", mode)
		
	# Desactivar el arrastre de semillas si se activa cualquier otro modo
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	Input.set_custom_mouse_cursor(null) 
	
	if current_action_mode != Action.NONE and ACTION_TEXTURES.has(current_action_mode):
		if drag_icon_node == null:
			drag_icon_node = TextureRect.new()
			drag_icon_node.mouse_filter = Control.MOUSE_FILTER_IGNORE # Ignorar clics para no interferir
			drag_icon_node.z_index = 100
			var canvas_layer = CanvasLayer.new()
			canvas_layer.add_child(drag_icon_node)
			get_tree().get_root().add_child(canvas_layer) # Añadirlo a la raíz para que esté por encima de todo
		
		drag_icon_node.texture = ACTION_TEXTURES[current_action_mode]
		drag_icon_node.expand_mode = TextureRect.EXPAND_FIT_HEIGHT 
		drag_icon_node.custom_minimum_size = ICON_SIZE
		drag_icon_node.size = Vector2(20, 20)
		drag_icon_node.clip_contents = true 
		drag_icon_node.visible = true
		drag_icon_node.modulate = Color(1.0, 1.0, 1.0, 0.839) # Un poco transparente
	else:
		# Si es modo NONE, ocultar el icono
		if drag_icon_node:
			drag_icon_node.visible = false
	
	# Desactivar el arrastre si se activa cualquier otro modo
	if current_action_mode != Action.NONE:
		stop_dragging_seed() # Esto desactiva is_dragging_seed
	
	print("Modo de acción establecido a: ", current_action_mode)
	return current_action_mode

signal money_changed(new_money)

func add_money(amount: int):
	money += amount
	emit_signal("money_changed", money)

func spend_money(amount: int) -> bool:
	if money >= amount:
		money -= amount
		emit_signal("money_changed", money)
		return true
	return false
# --- Propiedades de Arrastre ---
var is_dragging_seed = false
var current_seed_id_to_plant = ""
var seed_data: Dictionary ={}

const ICON_SIZE = Vector2(10, 10) 


# --- Nodo de Icono de Arrastre (Sprite2D o TextureRect) ---
# Este será el nodo que se moverá con el mouse
var drag_icon_node: TextureRect = null



func _process(_delta):
	if is_dragging_seed and drag_icon_node:
		# Asegúrate de que el icono esté visible mientras arrastras
		drag_icon_node.visible = true 
		
		# 1. Obtener la posición global del ratón
		var mouse_pos = get_viewport().get_mouse_position()
		
		# 2. Centrar el icono: Restar la mitad del tamaño del nodo (ahora que el tamaño está correcto)
		drag_icon_node.global_position = mouse_pos - drag_icon_node.size / 2 
	elif drag_icon_node and current_action_mode != Action.NONE:
		# Ocultar si el arrastre no está activo
		drag_icon_node.visible = true 
		
		# 1. Obtener la posición global del ratón
		var mouse_pos = get_viewport().get_mouse_position()
		
		# 2. Centrar el icono: Restar la mitad del tamaño del nodo (ahora que el tamaño está correcto)
		drag_icon_node.global_position = mouse_pos - drag_icon_node.size / 2 
	elif drag_icon_node and drag_icon_node.visible:
		# Ocultar si el arrastre no está activo
		drag_icon_node.visible = false 



# --- Manejo de la señal de la Tienda ---
func _on_seed_picked_up(seed_d: Dictionary):
	set_action_mode(Action.NONE) 
	is_dragging_seed = true
	current_seed_id_to_plant = seed_d.id
	seed_data = seed_d

	# Crear el nodo que sigue al mouse
	if drag_icon_node == null:
		drag_icon_node = TextureRect.new()
		drag_icon_node.mouse_filter = Control.MOUSE_FILTER_IGNORE # Ignorar clics para no interferir
		drag_icon_node.z_index = 100
		var canvas_layer = CanvasLayer.new()
		canvas_layer.add_child(drag_icon_node)
		get_tree().get_root().add_child(canvas_layer) # Añadirlo a la raíz para que esté por encima de todo
	
	drag_icon_node.texture = load(seed_data.icon_path)
	drag_icon_node.expand_mode = TextureRect.EXPAND_FIT_HEIGHT 
	drag_icon_node.custom_minimum_size = ICON_SIZE
	drag_icon_node.size = Vector2(20, 20)
	drag_icon_node.clip_contents = true 
	

	drag_icon_node.visible = true
	drag_icon_node.modulate = Color(1.0, 1.0, 1.0, 0.839) # Un poco transparente
	

func stop_dragging_seed():
	is_dragging_seed = false
	current_seed_id_to_plant = ""
	seed_data = {}
	if drag_icon_node:
		drag_icon_node.visible = false
		# drag_icon_node.queue_free() # Si prefieres que se destruya y recree

# --- Función para cuando el jugador realmente planta la semilla ---
func plant_seed_at_position(grid_position: Vector2, planted_seed_id: String):
	print("Plantando ", planted_seed_id, " en ", grid_position)
	# Lógica de plantado:
	# 1. Actualizar el estado de la parcela en esa posición (ej. grid_data[grid_position] = planted_seed_id)
	# 2. Instanciar la planta visualmente en la parcela
	# 3. Llamar a stop_dragging_seed()
	#stop_dragging_seed()
signal plant_harvested(plant_id, money_earned, item_gained)


func harvest_plant(parcela_id: int, plant_id: String, porcentaje_vida) -> Dictionary:
	if PLANT_REWARDS.has(plant_id):
		farm_plot_states.erase(parcela_id)
		var reward = PLANT_REWARDS[plant_id]
		add_money(round((porcentaje_vida)*0.01*reward.money)+10)
		print("Monto por cosechar: ,",plant_id," es: $",round((porcentaje_vida)*0.01*reward.money), " y el costo de compra fue: $", reward.money)
		emit_signal("plant_harvested", plant_id, reward.money, reward.item)
		return reward
	else:
		print("ERROR: Planta ", plant_id, " no tiene recompensa definida")
		return {}
	
func register_plant_creation(parcela_id: int, seed_d: Dictionary):
	# Inicializa el estado de la planta en el registro central
	farm_plot_states[parcela_id] = {
		"plant_data": seed_d,
		"nivel_agua": 100.0, # Nivel inicial de agua
		"edad_dias": 0,
		"estado": "Recién plantada"
	}
	print("GameManager: Registrada nueva planta ", seed_d.id, " en Parcela ", parcela_id)

func update_plot_water(parcela_id: int, new_water_level: float):
	if farm_plot_states.has(parcela_id):
		farm_plot_states[parcela_id]["nivel_agua"] = new_water_level

# --- FUNCIÓN LLAMADA POR LA TABLET PARA OBTENER DATOS ---
func get_all_plot_states() -> Dictionary:
	return farm_plot_states
