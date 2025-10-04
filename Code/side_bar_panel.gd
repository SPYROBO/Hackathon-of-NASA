# SidebarPanel.gd
extends Control

@onready var btn_tienda = $"MainVBox/Button"
@onready var btn_manual = $"MainVBox/Button2"
@onready var money_label_sidebar = $MainVBox/MarginContainer2/PanelContainer/HBoxContainer/IU_price
@onready var btn_water = $MainVBox/MarginContainer/ActionButtonsHBox/BTNwater
@onready var btn_harvest = $MainVBox/MarginContainer/ActionButtonsHBox/BTNharvest
@onready var btn_fumigate = $MainVBox/MarginContainer/ActionButtonsHBox/BTNfumigate

const SHOP_SCENE = preload("res://Scenes/tienda.tscn")
const MANUAL_SCENE = preload("res://Scenes/manual.tscn")

var shop_instance = null
var manual_instance = null
var plata_jugador = 100

# Referencia al GameManager (Autoload)
@onready var game_manager = get_tree().get_first_node_in_group("game_manager") # Asumiendo un grupo
# Asegúrate que el Autoload se llame "GameManager" o ajústalo aquí.


func _ready() -> void:
	btn_tienda.pressed.connect(on_shop_button_pressed)
	btn_manual.pressed.connect(on_manual_button_pressed)
	
	update_money_display(GameManager.money)
	GameManager.money_changed.connect(update_money_display)
	
	# CONECTAR EL BOTÓN DE AGUA
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
	
func update_money_display(new_money):
	money_label_sidebar.text = "$" + str(new_money)

# --- NUEVA FUNCIÓN PARA EL BOTÓN DE AGUA ---
func _on_action_button_pressed(action_mode):
	print("Botón de acción presionado: ", action_mode)
	# Notificar al GameManager qué modo activar
	game_manager.set_action_mode(action_mode)
