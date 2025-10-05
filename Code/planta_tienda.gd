extends Control
@onready var seed_icon = $"Panel/BoxContainer/Panel/TextureRect" 

# --- Precio y Nombre ---
# (El PanelContainer parece agrupar el precio)
@onready var price_label = $"Panel/PanelContainer/Price" 
# NOTA: Necesitarás añadir un Label (etiqueta) para el nombre de la planta, 
# ya que no está explícitamente en tu estructura actual. 
# Si el nombre es parte del PanelContainer, el path sería similar.

# --- Atributos de la Semilla (HBoxContainer2) ---
# Los nodos 'Sol', 'Agua' y 'Tiempo' son TextureRects o Labels que muestran los valores.
# Si solo son TextureRects (los íconos), necesitarás Labels para los valores.
@onready var sun_icon = $"Panel/HBoxContainer2/Sol"     # Icono del Sol
@onready var water_icon = $"Panel/HBoxContainer2/Agua"   # Icono de la Gota de Agua
@onready var time_value = $"Panel/HBoxContainer2/Tiempo/Label" # Icono del Reloj/Calendario

# --- Botón de Compra ---
@onready var buy_button = $"Panel/Buy" # El botón 'Buy'

var seed_data: Dictionary = {}

signal seed_selected(seed_id) # Para notificar a la tienda que se seleccionó una semilla

signal seed_picked_up_for_planting(seed_id, seed_icon_texture)

func _ready():
	buy_button.pressed.connect(_on_buy_button_pressed)
	

func setup_seed_card(data: Dictionary):
	seed_data = data
	price_label.text = "$" + str(seed_data.price)
	#name_label.text = seed_data.name
	# Cargar la textura del ícono de la semilla
	seed_icon.texture = load(seed_data.icon_path)
	
	# Actualizar atributos (simples por ahora)
	if str(seed_data.sun_tolerance) == "HIGH":
		sun_icon.texture = load("res://icons/sol.png")
	elif str(seed_data.sun_tolerance) == "MEDIUM":
		sun_icon.texture = load("res://icons/templado.png")
	elif str(seed_data.sun_tolerance) == "LOW":
		sun_icon.texture = load("res://icons/frio.png")
	
	if str(seed_data.water_need) == "HIGH":
		water_icon.texture = load("res://icons/mucha_agua.png")
	elif str(seed_data.water_need) == "LOW":
		water_icon.texture = load("res://icons/poca_agua.png")
	time_value.text = str(seed_data.growth_days)
	print("Emitting signal with ID:", seed_data.id)

func _on_buy_button_pressed():
	# Emitir una señal para que la tienda principal sepa qué semilla se seleccionó/compró
	seed_selected.emit(seed_data.id)
	# También puedes cambiar el texto del botón a "Selected" o deshabilitarlo si solo se compra una vez
	
	seed_picked_up_for_planting.emit(seed_data)
	
	buy_button.disabled = true
	self.modulate = Color(0.7, 0.7, 0.7) # Atenuar la tarjeta
