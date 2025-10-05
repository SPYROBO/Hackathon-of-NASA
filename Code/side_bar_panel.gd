# SidebarPanel.gd
extends Control

@onready var btn_tienda = $"MainVBox/Button"
@onready var btn_tablet = $"MainVBox/TabletPanel"
@onready var btn_manual = $"MainVBox/Button2"
@onready var money_label_sidebar = $MainVBox/MarginContainer2/PanelContainer/HBoxContainer/IU_price
@onready var btn_water = $MainVBox/MarginContainer/ActionButtonsHBox/BTNwater
@onready var btn_harvest = $MainVBox/MarginContainer/ActionButtonsHBox/BTNharvest
@onready var btn_fumigate = $MainVBox/MarginContainer/ActionButtonsHBox/BTNfumigate

const SHOP_SCENE = preload("res://Scenes/tienda.tscn")
const TABLET_SCENE = preload("res://Scenes/tablet.tscn")

var shop_instance = null
var tablet_instance = null
const MANUAL_SCENE = preload("res://Scenes/manual.tscn")

var manual_instance = null
var plata_jugador = 100

# Referencia al GameManager (Autoload)
@onready var game_manager = get_tree().get_first_node_in_group("game_manager") # Asumiendo un grupo
# Asegúrate que el Autoload se llame "GameManager" o ajústalo aquí.


func _ready() -> void:
	btn_tienda.pressed.connect(on_shop_button_pressed)
	btn_tablet.pressed.connect(on_tablet_button_pressed)
	btn_manual.pressed.connect(on_manual_button_pressed)
	
	update_money_display(GameManager.money)
	GameManager.money_changed.connect(update_money_display)
	
	# CONECTAR BOTONES
	btn_water.pressed.connect(_on_action_button_pressed.bind(GameManager.Action.WATER))
	btn_harvest.pressed.connect(_on_action_button_pressed.bind(GameManager.Action.HARVEST))
	btn_fumigate.pressed.connect(_on_action_button_pressed.bind(GameManager.Action.FUMIGATE))

func on_manual_button_pressed():
	if manual_instance == null:
		manual_instance = MANUAL_SCENE.instantiate()
		add_child(manual_instance)
		manual_instance.manual_closed.connect(_on_manual_closed)
		
	manual_instance.show_manual()
	get_tree().paused = true

func on_shop_button_pressed():
	if shop_instance == null:
		shop_instance = SHOP_SCENE.instantiate()
		add_child(shop_instance)
		shop_instance.shop_closed.connect(_on_shop_closed)
		
	shop_instance.show_shop()
	get_tree().paused = true
	shop_instance.player_money = plata_jugador
	shop_instance.update_money_display()
	
func on_tablet_button_pressed():
	if tablet_instance == null:
		tablet_instance = TABLET_SCENE.instantiate()
		add_child(tablet_instance)
		tablet_instance.tablet_closed.connect(_on_tablet_closed)
		
	tablet_instance.show_tablet()
	get_tree().paused = true

func _on_shop_closed():
	shop_instance = null
	get_tree().paused = false
	# CLAVE: Si la tienda se cierra, aseguramos que ningún modo de acción esté activo
	game_manager.set_action_mode(GameManager.Action.NONE) 

func _on_manual_closed():
	manual_instance = null
	get_tree().paused = false
	# CLAVE: Si la tienda se cierra, aseguramos que ningún modo de acción esté activo
	game_manager.set_action_mode(GameManager.Action.NONE) 
	
func _on_tablet_closed():
	tablet_instance = null
	get_tree().paused = false
	
func update_money_display(new_money):
	money_label_sidebar.text = "$" + str(new_money)

# --- NUEVA FUNCIÓN PARA EL BOTÓN DE AGUA ---
func _on_action_button_pressed(action_mode):
	print("Botón de acción presionado: ", action_mode)
	# Notificar al GameManager qué modo activar
	match action_mode:
		1:
			if game_manager.set_action_mode(action_mode) != 0:
				if game_manager.spend_money(3):
					print("Se compró agua a $3")
				else: 
					game_manager.set_action_mode(0)
					print("No se pudo realizar la acción debido a que no tiene dinero suficiente ($3)")
		2:
			game_manager.set_action_mode(action_mode)
		3:
			if game_manager.set_action_mode(action_mode) != 0:
				if game_manager.spend_money(6):
					print("Se compró fumicación a $6")
				else:
					game_manager.set_action_mode(0)
					print("No se pudo realizar debido a que no tiene suficiente dinero ($6)")
