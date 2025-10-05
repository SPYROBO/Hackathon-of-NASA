# Manual.gd
extends Control

# Cargar el script de datos
const ManualData = preload("res://Code/ManualData.gd")

# Nodos de Salida (Ajusta las rutas según tu escena)
@onready var tab_container = $MainPanel/VBoxContainer/ManualTabContainer
@onready var how_to_play_tab = tab_container.get_node("HowToPlayTab")
@onready var manual_controls_container = how_to_play_tab.get_node("HBoxContainer/ControlsContainer") 
@onready var close_button = $MainPanel/VBoxContainer/HBoxContainer/CloseButton


# Controles de la columna derecha (ControlsContainer)
@onready var manual_report_image = how_to_play_tab.get_node("HBoxContainer/ControlsContainer/ImageAspectContainers/ReportImage")
@onready var alert_label = how_to_play_tab.get_node("HBoxContainer/ControlsContainer/AlertLabel")
@onready var key_concepts_container = how_to_play_tab.get_node("KeyConceptsContainer")

# Botones de la columna izquierda (MissionContainer)
@onready var mission_button = how_to_play_tab.get_node("HBoxContainer/MissionContainer/mission_btn") 
@onready var tablet = how_to_play_tab.get_node("HBoxContainer/MissionContainer/tablet_btn") 
@onready var shop = how_to_play_tab.get_node("HBoxContainer/MissionContainer/shop_btn") 
@onready var modo = how_to_play_tab.get_node("HBoxContainer/MissionContainer/modo_btn") 
# Agrega más botones aquí si los tienes...

signal manual_closed

func _ready():
	# Pausar el juego
	get_tree().paused = true
	
	close_button.pressed.connect(hide_manual)
	
	# Conectar todos los botones a la misma función de manejo
	mission_button.pressed.connect(func(): _update_content("mission"))
	tablet.pressed.connect(func(): _update_content("tablet"))
	shop.pressed.connect(func(): _update_content("shop"))
	modo.pressed.connect(func(): _update_content("modo"))
	# Conecta aquí los demás botones...
	
	# Mostrar el contenido por defecto al abrir el manual
	_update_content("mission")
	
func show_manual():
	self.show() # Mostrar el nodo de la tienda
	self.visible = true
	# Opcional: Pausar el juego principal si es un pop-up modal
	get_tree().paused = true

func hide_manual():
	self.visible = false
	manual_closed.emit() 
	get_tree().paused = false # Reanudar el juego


# Función que actualiza la columna derecha con la información de la misión.
func _update_content(mission_key: String):
	if not ManualData.MISSION_DATA.has(mission_key):
		push_error("Misión no encontrada en ManualData: " + mission_key)
		return
		
	var data = ManualData.MISSION_DATA[mission_key]
	
	# 1. Actualizar Imagen
	manual_report_image.texture = data.image
	manual_report_image.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	
	# 2. Actualizar Etiqueta de Alerta/Título
	alert_label.text = data.alert_text
	
	# 3. Actualizar Conceptos Clave (Simplified implementation)
	# Suponemos que KeyConceptsContainer tiene un Label para el texto principal
	var main_concept_label = key_concepts_container.get_node("MainConceptLabel") 
	main_concept_label.text = data.concept_text
	
	# 4. Opcional: Actualizar el color del círculo del Key Concept (si aplica)
	# var circle_node = key_concepts_container.get_node("Circle1/ColorRect")
	# circle_node.modulate = data.key_color_1


# --- Lógica de Cierre ---
