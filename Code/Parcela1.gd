extends Node # Hereda del nodo Parcela1 (que es un Node)

# --- PROPIEDADES DE AGUA Y MAPA ---
@export var max_nivel_agua: float = 100.0
@export var reduccion_por_segundo: float = 1.0 # Tasa de evaporación
@export var celda_de_mapa: Vector2i # Almacenará la posición (x, y) en el TileMap
@onready var indicador_agua: = $Barradeagua

var nivel_agua_actual: float = 100.0 # Nivel inicial

# ---PROPIEDADES DE COSECHA ---
@export var growth_time: float = 60.0  # Tiempo total para crecer (segundos)
@export var current_growth: float = 0.0  # Progreso actual de crecimiento
@export var is_ready_to_harvest: bool = false
var growth_stages: Array = [0.0, 0.33, 0.66, 1.0]  # Etapas de crecimiento
var current_stage: int = 0


# --- PROPIEDADES DE PLANTACIÓN ---
@export var parcela_id: int = 1  # Para identificar esta parcela
var is_planted: bool = false
var current_plant_id: String = ""

# --- Timer para oportunidad de plaga ---
var timer_active = false
var tiempo_transcurrido = 0.0
var intervalo_plaga = 8.0  # Cada 8 segundos

# --- REFERENCIAS A NODOS HIJOS ---
@onready var area_interaccion: Area2D = $Area2D # Referencia al Area2D hijo
@onready var plant_visual = $PlantVisualSprite2D # Asume que añadiste este nodo
@onready var indicador_vida = $Vida
@onready var plaga = $Plaga

# --- Vida del la parcela ---
var nivel_vida_actual: float = 100.0

# --- CONSTANTES CLIMÁTICAS (DEFINIR UMBRALES) ---
# Temperaturas en Grados Celsius (°C)
const TEMP_UMBRAL_FRIO: float = 10.0  # Menos de 10°C es Frío
const TEMP_UMBRAL_CALIDO: float = 25.0 # Más de 25°C es Cálido

# Humedad Relativa (RH2M) en porcentaje (%)
const HUMEDAD_UMBRAL_BAJA: float = 40.0 # Menos de 40% es Poca Humedad

# --- REFERENCIA AL SINGLETON (GameManager) ---
@onready var game_manager = get_tree().get_first_node_in_group("game_manager")
@onready var clima_manager = get_tree().get_first_node_in_group("clima_manager") 
# Asegúrate que el Autoload se llame "GameManager"

func _ready():
	# Inicialización de la lógica de Agua
	indicador_agua.max_value = max_nivel_agua
	actualizar_visual_agua()

	# Inicialización de la lógica de Plantación
	plant_visual.visible = false
	indicador_agua.visible = false
	indicador_vida.visible = false
	plaga.visible = false
	
	# CONECTAR LA SEÑAL DEL NODO HIJO Area2D
	# Conectamos la señal 'input_event' emitida por el nodo Area2D hijo
	area_interaccion.input_event.connect(_on_area_input_event)
	
	add_to_group("map")



func _process(delta: float):
	var clima_data = clima_manager.get_clima_data()
	var temp_avg = null
	var hum_avg = null
	# Asegúrate de que los datos de clima sean válidos antes de usarlos
	if clima_data.is_empty() or clima_data.has("error"):
		temp_avg = 20.0
		hum_avg = 50.0
	else:
		temp_avg = clima_data.get("temperatura_avg", 20.0) # Valor por defecto
		hum_avg = clima_data.get("humedad_avg", 50.0)      # Valor por defecto

	# Obtener los multiplicadores
	var growth_multiplier = get_growth_multiplier(temp_avg)
	var evaporation_multiplier = get_evaporation_multiplier(hum_avg)
	
	
	if is_planted and not is_ready_to_harvest:
		# LÓGICA DE CRECIMIENTO (APLICANDO MULTIPLICADOR DE TEMPERATURA)
		if nivel_agua_actual > 0:
			# 🚨 MODIFICACIÓN CLAVE: Multiplicar delta por el factor de crecimiento
			current_growth += delta * growth_multiplier 
			check_growth_stage()
			
			if current_growth >= growth_time:
				is_ready_to_harvest = true
				on_plant_ready()
		
		# LÓGICA DE PÉRDIDA DE AGUA (APLICANDO MULTIPLICADOR DE HUMEDAD)
		if nivel_agua_actual > 0:
			# 🚨 MODIFICACIÓN CLAVE: Multiplicar la reducción por el factor de evaporación
			nivel_agua_actual -= 10 * delta * evaporation_multiplier
			nivel_agua_actual = max(0.0, nivel_agua_actual)
			actualizar_visual_agua()
		else:
			print("PLANTA MUERTA")
			efecto_muerte_parcela()
	else:
		indicador_agua.visible = false
	# Aquí puedes añadir la lógica de crecimiento/marchitamiento de la semilla
	if is_planted and not is_ready_to_harvest:
		tiempo_transcurrido += delta
		if plaga.visible:
			tiempo_transcurrido = 0.0
		if tiempo_transcurrido >= intervalo_plaga:
			tiempo_transcurrido = 0.0
			generate_oportunity()
	else:
		indicador_vida.visible = false
		tiempo_transcurrido = 0.0
		
# --- Comprobar si la plaga es visible y así saber si eliminar vida o no ---
	if plaga.visible:
		nivel_vida_actual -= reduccion_por_segundo * delta * 2
		nivel_vida_actual = max(0.0, nivel_vida_actual)
		indicador_vida.value = nivel_vida_actual
		# Comprobar si la vida de la planta es 0 (si no tiene vida)
		if nivel_vida_actual == 0:
			print("PLANTA MUERTA")
			efecto_muerte_parcela()
			nivel_vida_actual= -1


func get_growth_multiplier(temp_avg: float) -> float:
	# Por defecto, el crecimiento es normal (1.0)
	var multiplier = 1.0 
	
	var plant_data = game_manager.farm_plot_states.get(parcela_id, {}).get("plant_data", {})
	var sun_tolerance = plant_data.get("sun_tolerance", "MEDIUM") # Usamos la tolerancia de la semilla
	
	# 1. Clasificar la temperatura (Frío, Templado, Cálido)
	var temp_type: String
	if temp_avg < TEMP_UMBRAL_FRIO:
		temp_type = "FRIO"
	elif temp_avg > TEMP_UMBRAL_CALIDO:
		temp_type = "CALIDO"
	else:
		temp_type = "TEMPLADO"
		
	# 2. Aplicar el multiplicador basado en la tolerancia de la planta
	match temp_type:
		"CALIDO":
			if sun_tolerance == "HIGH":
				multiplier = 1.2 # Crece 20% más rápido
			elif sun_tolerance == "LOW":
				multiplier = 0.8 # Crece 20% más lento
			else: # MEDIUM
				multiplier = 1.0
				
		"FRIO":
			if sun_tolerance == "LOW":
				multiplier = 1.2 # Las plantas que AMAN el frío crecen más rápido
			elif sun_tolerance == "HIGH":
				multiplier = 0.6 # Las plantas que odian el frío crecen 40% más lento
			else: # MEDIUM
				multiplier = 0.8 # Ligeramente más lento en frío

		"TEMPLADO":
			multiplier = 1.0 # Crecimiento estándar
			
	return multiplier

func get_evaporation_multiplier(hum_avg: float) -> float:
	# Multiplicador base por defecto (1.0 = tasa normal de pérdida de agua)
	var multiplier = 1.0
	
	# Obtener los datos de la planta
	var plant_data = game_manager.farm_plot_states.get(parcela_id, {}).get("plant_data", {})
	# Usamos la necesidad de agua de la semilla (LOW, MEDIUM, HIGH)
	var water_need = plant_data.get("water_need", "MEDIUM") 
	var hum_type: String
	
	# --- 1. AJUSTE BASADO EN EL CLIMA (HUMEDAD AMBIENTAL) ---
	# Esto afecta la EVAPORACIÓN del suelo
	if hum_avg < HUMEDAD_UMBRAL_BAJA:
		# Poca humedad en el aire = El agua se evapora más rápido del suelo
		multiplier *= 1.5 # 50% más rápido
		hum_type = "BAJA_HUMEDAD"
	else:
		# Mucha humedad en el aire = Evaporación más lenta
		multiplier *= 0.75 # 25% más lento
		hum_type = "ALTA_HUMEDAD"
		
	# --- 2. AJUSTE BASADO EN LA PLANTA (TRANSPIRACIÓN) ---
	# Esto afecta la TRANSPLANTACIÓN de la planta (cuánto bebe)
	match water_need:
		"HIGH":
			# Una planta que necesita mucha agua, la consumirá más rápido
			if hum_type == "ALTA_HUMEDAD":
				multiplier *= 1.0 # 30% más rápido
			else:
				multiplier *= 1.8
		"LOW":
			# Una planta que necesita poca agua, la conservará mejor
			if hum_type == "ALTA_HUMEDAD":
				multiplier *= 1.2 
			else:
				multiplier *= 0.8 # 20% más lento
		"MEDIUM":
			# Consumo normal
			multiplier *= 1.0 
			
	return multiplier
# --- MANEJO DE LA SEÑAL DEL AREA2D HIJO ---
# Esta función es el "slot" que recibe la señal del Area2D.
func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	# Solo nos interesa el clic izquierdo del ratón
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		handle_plot_click()


# --- LÓGICA DE PLANTACIÓN (USADA AL HACER CLIC) ---

# Parcela1.gd (Fragmento handle_plot_click)

func handle_plot_click():
	
	# 1. LÓGICA DE PLANTACIÓN (Prioridad alta y siempre posible con arrastre)
	if game_manager.is_dragging_seed:
		if not is_planted:
			var seed_id = game_manager.current_seed_id_to_plant
			plant_seed(seed_id)
			game_manager.stop_dragging_seed() # Finaliza el arrastre
			print("Plantada semilla ", seed_id, " en Parcela ", parcela_id)
		else:
			print("Error: Parcela ", parcela_id, " ya está ocupada. No se puede plantar.")
		# El clic se consume aquí, no pasa a la siguiente lógica
		return 
		
	
	# 2. LÓGICA DE ACCIONES DE BARRA LATERAL (Si no estamos arrastrando)
	
	match game_manager.current_action_mode:
		
		GameManager.Action.WATER:
			if is_planted:
				regar(30.0) 
				print("Regada planta en Parcela ", parcela_id, ". Nivel de agua: ", nivel_agua_actual)
				game_manager.set_action_mode(GameManager.Action.NONE) # Desactivar modo
			else:
				print("No hay planta para regar en Parcela ", parcela_id)
		
		GameManager.Action.HARVEST:
			if is_planted:
				if is_ready_to_harvest:
					var reward = harvest()
					if reward:
						print("Cosecha exitosa +$", reward.money)
						game_manager.set_action_mode(GameManager.Action.NONE)
				else:
					var progress_percent = int((current_growth / growth_time) * 100)
					print("Planta no lista para cosechar (", progress_percent, "%)")
					game_manager.set_action_mode(GameManager.Action.NONE)
			else:
				print("No hay planta para cosechar en Parcela ", parcela_id)
				
		GameManager.Action.FUMIGATE:
			if is_planted:
				# Lógica de fumigación
				if plaga.visible:
					plaga.visible = false
					print("Fumigando planta en Parcela ", parcela_id)
					game_manager.set_action_mode(GameManager.Action.NONE) # Desactivar modo
				else:
					print("No hay ninguna plaga en la parcela")
					game_manager.set_action_mode(GameManager.Action.NONE)
			else:
				print("No hay planta para fumigar en Parcela ", parcela_id)

		GameManager.Action.NONE:
			# Clic normal sin acción activa (ej. mostrar información)
			if is_planted:
				pass


# --- MÉTODO PRINCIPAL DE PLANTACIÓN ---
func plant_seed(seed_id: String):
	is_planted = true
	current_plant_id = seed_id
	
	var seed_data = game_manager.seed_data 
	game_manager.register_plant_creation(parcela_id, seed_data) # Usa la ID de la parcela
	
	# Configurar y hacer visible el nodo visual
	plant_visual.texture = load(seed_data.icon_path)
	plant_visual.modulate = Color(1.0, 1.0, 1.0, 1.0)
	plant_visual.visible = true
	indicador_agua.visible = true
	indicador_vida.visible = true


# --- FUNCIONES DE AGUA (RIEGO Y VISUAL) ---
func regar(cantidad: float = 30.0):
	nivel_agua_actual += cantidad
	nivel_agua_actual = min(max_nivel_agua, nivel_agua_actual)
	actualizar_visual_agua()
	
func actualizar_visual_agua():
	indicador_agua.value = nivel_agua_actual
	game_manager.update_plot_water(parcela_id, nivel_agua_actual) 
	# Opcional: Ocultar si está lleno o vacío
	
#Función de cosecha de planta
func harvest():
	if is_planted and is_ready_to_harvest:
		# Obtener recompensa del GameManager
		var reward = game_manager.harvest_plant(parcela_id, current_plant_id, indicador_vida.value)
		
		if reward:
			print("El porcentaje de vida de la planta es: ", indicador_vida.value)
			print("Cosechada ", current_plant_id, " en parcela ", parcela_id)
			  # Efecto visual
			show_harvest_effect()
			
		else:
			if is_planted and not is_ready_to_harvest:
				print("Planta no está lista para cosechar")
			else:
				print("No hay planta para cosechar")
			return {}
		return reward
		
func check_growth_stage():
	# Cambiar etapa visual según progreso
	var progress = current_growth / growth_time
	
	for i in range(growth_stages.size()):
		if progress >= growth_stages[i] and i > current_stage:
			current_stage = i
			update_plant_visual()

func update_plant_visual():
	# Cambiar la apariencia según la etapa
	match current_stage:
		0:
			plant_visual.modulate = Color(0.5, 0.5, 1.0)  # Azulado - semilla
		1:
			plant_visual.modulate = Color(0.7, 1.0, 0.7)  # Verde claro - brote
		2:
			plant_visual.modulate = Color(0.9, 1.0, 0.9)  # Verde - crecimiento
		3:
			plant_visual.modulate = Color(1.0, 1.0, 1.0)  # Normal - maduro

func on_plant_ready():
	# Cuando la planta está lista para cosechar
	plant_visual.modulate = Color(1.0, 1.0, 0.5)  # Amarillo - listo para cosechar
	indicador_vida.visible = false
	plaga.visible = false
	tiempo_transcurrido = 0.0
	print("Planta lista para cosechar en parcela ", parcela_id)
	
# Añade esta función para feedback visual al cosechar
func show_harvest_effect():
	print("Iniciando animación de cosecha")
	
	# Crear partículas simples o animación
	var harvest_tween = create_tween()
	plant_visual.scale = Vector2(1.2, 1.2)
	harvest_tween.tween_property(plant_visual, "scale", Vector2(1.0, 1.0), 0.3)
	
	#ESPERAR a que termine la animación antes de resetear
	await harvest_tween.finished
	
	print("Animación de cosecha terminada")
	
	# Resetea parcela LUEGO de hacer la animación
	reset_plot()

func efecto_muerte_parcela():
	print("Iniciando animación de muerte para parcela ", parcela_id)
	
	var death_tween = create_tween()
	
	# Animación cambio de color de la planta
	death_tween.tween_property(plant_visual, "modulate", Color(1.0, 0.3, 0.3, 0.3), 0.1)  # Rojo semi-transparente
	death_tween.tween_property(plant_visual, "modulate", Color(0.516, 0.085, 0.067, 1.0), 0.1)  # Normal
	death_tween.tween_property(plant_visual, "modulate", Color(1.0, 0.3, 0.3, 0.5), 0.1)  # Rojo más visible
	death_tween.tween_property(plant_visual, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1)  # Normal
	death_tween.tween_property(plant_visual, "modulate", Color(0.71, 0.0, 0.035, 0.8), 0.15) # Rojo casi opaco
	death_tween.tween_property(plant_visual, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1)  # Normal

	# Finalmente desaparecer con efecto de desvanecimiento
	death_tween.tween_property(plant_visual, "modulate", Color(1.0, 0.1, 0.1, 0.0), 0.3)  # Desvanecer a rojo transparente
	
	# Cuando termine la animación, resetear la parcela
	death_tween.tween_callback(reset_plot)

func reset_plot():
	print("Parcela ", parcela_id, " reseteada")
	
	# CLAVE: Resetear TODAS las variables de estado
	is_planted = false
	current_plant_id = ""
	is_ready_to_harvest = false
	current_growth = 0.0
	current_stage = 0
	nivel_agua_actual = 100.0
	nivel_vida_actual = 100.0  # IMPORTANTE: Resetear la vida
	indicador_vida.value = 100.0
	plaga.visible = false      # IMPORTANTE: Ocultar la plaga
	tiempo_transcurrido = 0.0  # Resetear el timer de plaga
	
	# Resetear visuales
	plant_visual.visible = false
	plant_visual.modulate = Color(1.0, 1.0, 1.0, 1.0)  # Resetear alpha también
	plant_visual.scale = Vector2(1.0, 1.0)
	indicador_agua.visible = false
	indicador_vida.visible = false
	actualizar_visual_agua()
	
	print("Parcela ", parcela_id, " completamente reseteada después de muerte")

# --- Temporizador para oportunidad de plaga ---

	
# --- Mostrar a la plaga ---
func generate_oportunity():
	var oportunity = randi_range(1, 20)
	print(oportunity)
	if oportunity >= 10:
		plaga.visible = true
