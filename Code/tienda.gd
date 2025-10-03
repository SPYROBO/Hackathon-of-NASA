extends Node2D

@onready var seed_display_grid = $"Panel/VBoxContainer/Plantas/GridContainer"
@onready var money_label = $"Panel/VBoxContainer/HBoxContainer2/MoneyLabel" # Asegúrate de que el path sea correcto
@onready var close_button = $"Panel/VBoxContainer/HBoxContainer/CloseButton"
@onready var game_manager = get_tree().get_first_node_in_group("game_manager") # Asumiendo un grupo
#@onready var cancel_button = $"Panel/VBoxContainer/HBoxContainer2/CancelButton"

var player_money = 100 # Esto debería venir del GameManager o un Singleton
var available_seeds = [] # Aquí se cargarán los datos de todas las semillas
var selected_seed_id = "" # Si solo se puede seleccionar una por vez

signal shop_closed

func _ready():
	close_button.pressed.connect(hide_shop)
	#cancel_button.pressed.connect(hide_shop)
	
	update_money_display()
	load_seed_data()
	populate_seed_cards()
	
	var seed_card_template = load("res://Scenes/planta_tienda.tscn") # Cargar la escena de la tarjeta
	
	for seed_data in available_seeds:
		var seed_card_instance = seed_card_template.instantiate()
		seed_display_grid.add_child(seed_card_instance)
		seed_card_instance.setup_seed_card(seed_data)
		seed_card_instance.seed_selected.connect(_on_seed_selected) # Conectar la señalu
		
		if game_manager:
			seed_card_instance.seed_picked_up_for_planting.connect(game_manager._on_seed_picked_up)
		else:
			print("WARNING: GameManager not found for seed_picked_up_for_planting signal.")



func load_seed_data():
	# En una hackathon, un JSON file o un Array hardcodeado está bien
	# En un juego real, lo cargarías desde un archivo JSON
	available_seeds = [
		{"id": "morron", "name": "Morron", "price": 8, "icon_path": "res://Images/plantas/morron.png", "sun_tolerance": "HIGH", "water_need": "LOW", "growth_days": 5},
		{"id": "cebolla", "name": "Cebolla", "price": 4, "icon_path": "res://Images/plantas/cebolla.png", "sun_tolerance": "MEDIUM", "water_need": "LOW", "growth_days": 3},
		{"id": "cereza", "name": "Cereza", "price": 4, "icon_path": "res://Images/plantas/cereza.png", "sun_tolerance": "MEDIUM", "water_need": "LOW", "growth_days": 4},
		{"id": "mango", "name": "Mango", "price": 8, "icon_path": "res://Images/plantas/mango.png", "sun_tolerance": "HIGH", "water_need": "HIGH", "growth_days": 5},
		{"id": "manzana", "name": "Manzana", "price": 4, "icon_path": "res://Images/plantas/manzana.png", "sun_tolerance": "MEDIUM", "water_need": "LOW", "growth_days": 3},
		{"id": "tomate", "name": "Tomate", "price": 4, "icon_path": "res://Images/plantas/tomate.png", "sun_tolerance": "HIGH", "water_need": "HIGH", "growth_days": 4},
		{"id": "zanahoria1", "name": "Zanahoria", "price": 8, "icon_path": "res://Images/plantas/zanahoria.png", "sun_tolerance": "MEDIUM", "water_need": "HIGH", "growth_days": 5},
		{"id": "berenjena", "name": "Berenjena", "price": 4, "icon_path": "res://Images/plantas/berenjena.png", "sun_tolerance": "HIGH", "water_need": "LOW", "growth_days": 3},
		{"id": "lechuga", "name": "Lechuga", "price": 4, "icon_path": "res://Images/plantas/lechuga.png", "sun_tolerance": "LOW", "water_need": "HIGH", "growth_days": 4},
		{"id": "rabanos", "name": "Rabanos", "price": 8, "icon_path": "res://Images/plantas/rabanos.png", "sun_tolerance": "LOW", "water_need": "HIGH", "growth_days": 5},
		{"id": "gizantes", "name": "Gizantes", "price": 4, "icon_path": "res://Images/plantas/gizantes.png", "sun_tolerance": "LOW", "water_need": "LOW", "growth_days": 3},
		{"id": "zanahoria2", "name": "Zanahorias", "price": 4, "icon_path": "res://Images/plantas/zanahoria.png", "sun_tolerance": "LOW", "water_need": "LOW", "growth_days": 4},
		# ... añade todas tus semillas aquí con sus paths a los íconos
	]

func populate_seed_cards():
	# Eliminar cualquier tarjeta existente si se recarga la tienda
	for child in seed_display_grid.get_children():
		child.queue_free()


func _on_seed_selected(seed_id: String):
	var selected_seed_info = get_seed_info(seed_id)
	if selected_seed_info:
		if GameManager.spend_money(selected_seed_info.price):
			update_money_display()
			print("Comprada semilla: ", selected_seed_info.name)
			# Aquí deberías añadir la semilla al inventario del jugador
			# GameManager.add_seed_to_inventory(selected_seed_info)
			
			# Opcional: Deshabilitar el botón de compra o cambiar su texto
			# Si solo se pueden comprar un número limitado o una vez
		else:
			print("No tienes suficiente dinero para comprar: ", selected_seed_info.name)
			# Mostrar un mensaje de "dinero insuficiente" al jugador
			
func get_seed_info(seed_id: String) -> Dictionary:
	for s in available_seeds:
		if s.id == seed_id:
			return s
	return {}

func update_money_display():
	money_label.text = "$" + str(GameManager.money)

func show_shop():
	self.show() # Mostrar el nodo de la tienda
	self.visible = true
	# Opcional: Pausar el juego principal si es un pop-up modal
	get_tree().paused = true

func hide_shop():
	self.visible = false
	shop_closed.emit()
	get_tree().paused = false # Reanudar el juego
