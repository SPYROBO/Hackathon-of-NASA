extends Node

var money: int = 100

func _ready():
	# Asegúrate de añadir el GameManager a un grupo para fácil referencia
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("game_manager")

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
var seed_drag_icon_texture: Texture2D = null

const ICON_SIZE = Vector2(3, 3) 


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
	elif drag_icon_node and drag_icon_node.visible:
		# Ocultar si el arrastre no está activo
		drag_icon_node.visible = false 



# --- Manejo de la señal de la Tienda ---
func _on_seed_picked_up(seed_id: String, icon_texture: Texture2D):

	is_dragging_seed = true
	current_seed_id_to_plant = seed_id
	seed_drag_icon_texture = icon_texture

	# Crear el nodo que sigue al mouse
	if drag_icon_node == null:
		drag_icon_node = TextureRect.new()
		drag_icon_node.mouse_filter = Control.MOUSE_FILTER_IGNORE # Ignorar clics para no interferir
		drag_icon_node.z_index = 100
		var canvas_layer = CanvasLayer.new()
		canvas_layer.add_child(drag_icon_node)
		get_tree().get_root().add_child(canvas_layer) # Añadirlo a la raíz para que esté por encima de todo
	
	drag_icon_node.texture = seed_drag_icon_texture
	drag_icon_node.expand_mode = TextureRect.EXPAND_FIT_HEIGHT 
	drag_icon_node.custom_minimum_size = ICON_SIZE
	drag_icon_node.size = Vector2(20, 20)
	drag_icon_node.clip_contents = true 
	

	drag_icon_node.visible = true
	drag_icon_node.modulate = Color(1.0, 1.0, 1.0, 0.839) # Un poco transparente
	

func stop_dragging_seed():
	is_dragging_seed = false
	current_seed_id_to_plant = ""
	seed_drag_icon_texture = null
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
