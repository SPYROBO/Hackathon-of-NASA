extends Control

@onready var close_button = $"PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/Button"
@onready var parcelas_container = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/Control
@onready var game_manager = get_tree().get_first_node_in_group("game_manager") 
@onready var clima_manager = get_tree().get_first_node_in_group("clima_manager") 
@onready var clima_label = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/Control2/Label
@onready var temp_promedio_label = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/Control2/Label3
@onready var vientos_label = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/Control2/Label5
@onready var humedad_label = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/Control2/Label2
@onready var lluvias_label = $PanelContainer/MarginContainer/VBoxContainer/TabContainer/Control2/Label4


const COLOR_VACIA = Color(0.14, 0.14, 0.14, 0.3)      # Gris/Neutro para parcelas vacías
const COLOR_SALUDABLE = Color(0.2, 0.6, 0.2, 1.0)  # Verde para buena salud y agua
const COLOR_ESTRES_AGUA = Color(0.8, 0.5, 0.1, 1.0) # Naranja/Amarillo para bajo riego

# Umbral de agua (0.0 a 100.0)
const UMBRAL_AGUA_BAJA = 50.0 

signal tablet_closed
# Called when the node enters the scene tree for the first time.
func _ready():
	close_button.pressed.connect(hide_tablet)
	clima_manager.clima_data_updated.connect(_on_clima_manager_data_updated)

func update_all_info():
	# ... (Actualiza información del clima) ...
	update_parcel_panel_visuals()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func show_tablet():
	self.show() # Mostrar el nodo de la tienda
	self.visible = true
	clima_label.text = "Obteniendo datos de NASA..."
	if is_instance_valid(game_manager):
		clima_manager.fetch_clima_por_semana(game_manager.semana_index)
	update_all_info() 

	# Opcional: Pausar el juego principal si es un pop-up modal

func hide_tablet():
	self.visible = false
	tablet_closed.emit()
	get_tree().paused = false # Reanudar el juego

# Tablet.gd (Continuación)

func update_parcel_panel_visuals():
	# Obtener el estado centralizado de todas las parcelas
	var plot_states: Dictionary = game_manager.get_all_plot_states() 
	
	# Iterar sobre las 8 parcelas esperadas
	# Asumimos que tus Parcelas van de 1 a 8
	for parcela_id in range(1, 9):

		var panel_name = "Panel_Parcela_" + str(parcela_id)
		
		# 1. Obtener el nodo Panel visual (Ajusta la ruta si es necesario)
		var plot_panel: Panel = parcelas_container.get_node_or_null(panel_name)
		
		if not is_instance_valid(plot_panel):
			push_error("Error: No se encontró el Panel visual: ", panel_name)
			continue
			
		# 2. Obtener los datos del GameManager
		# Si no hay datos, se asume que está vacía.
		var data: Dictionary = plot_states.get(parcela_id, {"plant_id": "", "nivel_agua": 100.0})
		
		var planted: bool = plot_states.has(parcela_id)
		var target_color: Color
		
		if not planted:
			# Opción 1: Parcela Vacía
			target_color = COLOR_VACIA
		else:
			var water_level: float = data.nivel_agua
			
			if water_level < UMBRAL_AGUA_BAJA:
				# Opción 2: Plantada, pero estresada por falta de agua
				target_color = COLOR_ESTRES_AGUA
			else:
				# Opción 3: Plantada y saludable
				target_color = COLOR_SALUDABLE
		
		# 3. Aplicar el color dinámicamente al Panel
		# La forma estándar es sobreescribir el StyleBox "panel" del tema.
		
		# Obtenemos el StyleBox actual y lo duplicamos para no modificar la fuente
		var style_box_base: StyleBoxFlat = plot_panel.get_theme_stylebox("panel").duplicate()
		
		# Modificamos la propiedad de color de fondo (bg_color)
		style_box_base.bg_color = target_color
		
		# Aplicamos el nuevo StyleBox modificado
		plot_panel.add_theme_stylebox_override("panel", style_box_base)

func _on_clima_manager_data_updated(success: bool):
	if success:
		update_clima_info()
	else:
		clima_label.text = "Error al conectar con NASA. Inténtalo de nuevo."


func update_clima_info():
	var data = clima_manager.get_clima_data()
	
	# 1. Manejo de Errores/Carga
	if data.is_empty() or data.has("error"):
		var error_text = "Clima: Error en los datos. Intente reabrir la Tablet."
		temp_promedio_label.text = error_text
		vientos_label.text = error_text
		humedad_label.text = error_text
		lluvias_label.text = error_text
		return

	# 2. Extracción de Datos
	var temp_avg = data.get("temperatura_avg", "N/A")
	var wind_avg = data.get("viento_avg", "N/A")
	var rh_avg = data.get("humedad_avg", "N/A")
	var precip_total = data.get("precipitacion_total", "N/A")
	var dias = data.get("dias_validos", "N/A")

	# 3. Asignación a Labels individuales con formato
	clima_label.text = "Información satelital"
	# Etiqueta 1: Temperatura
	temp_promedio_label.text = "Temp.Prom: %.1f °C" % temp_avg
	
	# Etiqueta 2: Vientos
	vientos_label.text = "Vientos: %.2f m/s" % wind_avg
	
	# Etiqueta 3: Humedad
	humedad_label.text = "Humedad.Prom: %.1f %%" % rh_avg
	
	# Etiqueta 4: Lluvias
	lluvias_label.text = "Precipitación: %.2f mm" % precip_total
