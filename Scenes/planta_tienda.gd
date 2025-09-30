extends Control
@onready var price_label = $"PanelContainer/Price"
@onready var seed_icon = $"BoxContainer/Panel/TextureRect"
#@onready var name_label = $"VBoxContainer/Seed Name"
@onready var sun_value = $"HBoxContainer2/Sol" # Ajustar path
@onready var water_value = $"HBoxContainer2/Agua" # Ajustar path
#@onready var days_label = $"VBoxContainer/HBoxContainer2/Days to Grow" # Ajustar path
@onready var buy_button = $"Buy/Select"

var seed_data: Dictionary # Un diccionario que contendrá los datos de esta semilla

signal seed_selected(seed_id) # Para notificar a la tienda que se seleccionó una semilla

func _ready():
	#buy_button.pressed.connect(_on_buy_button_pressed)
	

func setup_seed_card(data: Dictionary):
	seed_data = data
	price_label.text = "$" + str(seed_data.price)
	#name_label.text = seed_data.name
	# Cargar la textura del ícono de la semilla
	seed_icon.texture = load(seed_data.icon_path)
	
	# Actualizar atributos (simples por ahora)
	if str(seed_data.sun_tolerance) == "HIGH":
		sun_value.texture = load("res://icons/sol.png")
	elif str(seed_data.sun_tolerance) == "MEDIUM":
		sun_value.texture = load("res://icons/sol.png")
	elif str(seed_data.sun_tolerance) == "LOW":
		sun_value.texture = load("res://icons/sol.png")
	
	if str(seed_data.water_need) == "HIGH":
		water_value.texture = load("res://icons/gota.png")
	elif str(seed_data.water_need) == "MEDIUM":
		water_value.texture = load("res://icons/gota.png")
	elif str(seed_data.water_need) == "LOW":
		water_value.texture = load("res://icons/gota.png")
	#days_label.text = str(seed_data.growth_days) + " Days"

func _on_buy_button_pressed():
	# Emitir una señal para que la tienda principal sepa qué semilla se seleccionó/compró
	seed_selected.emit(seed_data.id)
	# También puedes cambiar el texto del botón a "Selected" o deshabilitarlo si solo se compra una vez
