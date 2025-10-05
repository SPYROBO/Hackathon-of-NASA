# ClimaManager.gd
extends Node

# NOTE: La referencia al GameManager debe ser @onready para asegurar que el nodo exista.
# Usar get_first_node_in_group es correcto si GameManager está en el grupo "game_manager".
@onready var game_manager = get_tree().get_first_node_in_group("game_manager") 

const NASA_POWER_URL = "https://power.larc.nasa.gov/api/temporal/daily/point?parameters=T2M,PRECTOTCORR,ALLSKY_SFC_SW_DWN,RH2M,WS2M&community=AG&longitude=%s&latitude=%s&start=%s&end=%s&format=JSON"
const NASA_FILL_VALUE = -999.0

var granja_latitud: float = 34.0522
var granja_longitud: float = -118.2437
var clima_datos: Dictionary = {} 
var http_request: HTTPRequest

signal clima_data_updated(success: bool)

func _ready():
	add_to_group("clima_manager")
	
	if http_request == null or not is_instance_valid(http_request):
		http_request = HTTPRequest.new()
		add_child(http_request)
		
	http_request.process_mode = Node.PROCESS_MODE_ALWAYS
	
	if not http_request.request_completed.is_connected(_on_request_completed):
		http_request.request_completed.connect(_on_request_completed)
	
	print("DEBUG: HTTPRequest está listo y conectado.")
	
	# 🚨 Inicialización de Día Cero en GameManager (si no lo hace el propio GameManager)
	# Si el GameManager es el que maneja la persistencia, esta lógica debe estar ahí.
	# Asumiendo que el GameManager tiene la variable:
	if is_instance_valid(game_manager) and game_manager.get("dia_cero_unix") == 0.0:
		game_manager.dia_cero_unix = Time.get_unix_time_from_system() 


# --- NUEVA FUNCIÓN: Busca datos para la semana de juego ---
# Es la función que llamará la Tablet al abrirse o el GameManager al avanzar la semana.
func fetch_clima_por_semana(semana_index: int):
	# Verificar acceso al GameManager y al ancla fija
	if not is_instance_valid(game_manager) or game_manager.dia_cero_unix == 0.0:
		push_error("ClimaManager no puede acceder al GameManager o al día cero fijo (1 de Ago. 2024).")
		clima_datos = {"error": "Error de inicialización del tiempo de juego."}
		emit_signal("clima_data_updated", false)
		return
		
	var seconds_in_day: float = 24.0 * 60.0 * 60.0
	var seconds_in_week: float = 7.0 * seconds_in_day
	
	# 1. Calcular el punto de inicio de la semana actual
	# semana_index * 7 días (0, 7, 14, 21 días de desfase desde el Día Cero)
	var dias_offset: float = float(semana_index) * 7.0 
	
	# Usamos el dia_cero_unix FIJO de Agosto de 2024
	var start_time_unix: float = game_manager.dia_cero_unix + (dias_offset * seconds_in_day)
	var end_time_unix: float = start_time_unix + seconds_in_week
	
	# 2. Convertir Unix Time a formato YYYYMMDD
	
	var start_dict = Time.get_datetime_dict_from_unix_time(start_time_unix)
	# Restamos un día al end_time para que la API no incluya el primer día de la siguiente semana
	# Además, Godot tiene un bug con Time.get_datetime_dict_from_unix_time que puede causar errores de formato si se usa con fechas futuras.
	var end_dict = Time.get_datetime_dict_from_unix_time(end_time_unix - seconds_in_day) 
	
	var start_date_formatted = "%04d%02d%02d" % [
		start_dict.year, start_dict.month, start_dict.day
	]
	var end_date_formatted = "%04d%02d%02d" % [
		end_dict.year, end_dict.month, end_dict.day
	]
	
	# 3. Llamar a la función de solicitud
	fetch_nasa_data_with_range(start_date_formatted, end_date_formatted)


# --- FUNCIÓN AUXILIAR PARA HACER LA SOLICITUD HTTP ---
func fetch_nasa_data_with_range(start_date_formatted: String, end_date_formatted: String):
	
	# Mantenemos la verificación de rango de la NASA (aunque el cálculo basado en Dia Cero es más robusto)
	var start_year = start_date_formatted.left(4).to_int()
	if start_year < 1981:
		start_date_formatted = "19810101"
		push_warning("La fecha de inicio calculada era muy antigua y se ajustó a 1981/01/01 (Mínimo de NASA).")

	var url = NASA_POWER_URL % [
		str(granja_longitud), 
		str(granja_latitud), 
		start_date_formatted,  
		end_date_formatted     
	]
	
	print("Solicitando datos de NASA para la semana: ", start_date_formatted, " a ", end_date_formatted)
	var error = http_request.request(url)
	if error != OK:
		push_error("Error al iniciar la solicitud HTTP: ", error)


# --- FUNCIÓN LLAMADA AL RECIBIR DATOS (Se mantiene igual) ---
func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	print("Resultado HTTP: ", result, ", Código de Respuesta: ", response_code)
	
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var json_string = body.get_string_from_utf8()
		var json = JSON.parse_string(json_string) 
		
		if json is Dictionary:
			clima_datos = process_nasa_json(json)
			
			if clima_datos.has("error"):
				push_error("Error al procesar el JSON: ", clima_datos["error"])
				emit_signal("clima_data_updated", false)
			else:
				emit_signal("clima_data_updated", true)
		else:
			push_error("Error: La respuesta de NASA no pudo ser parseada a un diccionario.")
			emit_signal("clima_data_updated", false)
	else:
		push_error("Error en la solicitud HTTP. Fallo o código inesperado.")
		emit_signal("clima_data_updated", false)

# --- FUNCIÓN PARA PROCESAR EL JSON DE LA NASA (Se mantiene igual) ---
func process_nasa_json(json_data: Dictionary) -> Dictionary:
	var properties = json_data.get("properties", {})
	var parameter = properties.get("parameter", {})
	
	var temp_sum = 0.0
	var solar_sum = 0.0
	var precip_sum = 0.0
	var rh_sum = 0.0
	var wind_sum = 0.0
	var count = 0

	var t2m_data = parameter.get("T2M", {})
	
	for date_str in t2m_data.keys():
		var t2m = parameter.get("T2M", {})[date_str]
		var solar = parameter.get("ALLSKY_SFC_SW_DWN", {})[date_str]
		var precip = parameter.get("PRECTOTCORR", {})[date_str]
		var rh = parameter.get("RH2M", {})[date_str]
		var wind = parameter.get("WS2M", {})[date_str]

		if t2m > NASA_FILL_VALUE:
			temp_sum += t2m
			
			if solar > NASA_FILL_VALUE:
				solar_sum += solar
			if precip > NASA_FILL_VALUE:
				precip_sum += precip
			if rh > NASA_FILL_VALUE:
				rh_sum += rh
			if wind > NASA_FILL_VALUE:
				wind_sum += wind
				
			count += 1
		
	if count > 0:
		return {
			"dias_validos": count,
			"temperatura_avg": temp_sum / count,
			"radiacion_solar_avg": solar_sum / count,
			"precipitacion_total": precip_sum,
			"humedad_avg": rh_sum / count,
			"viento_avg": wind_sum / count,
			"ultima_actualizacion": Time.get_datetime_string_from_system(true)
		}
	
	return {"error": "No se encontraron datos utilizables en el rango de fechas."}


# --- FUNCIÓN ACCEDIDA POR LA TABLET ---
func get_clima_data() -> Dictionary:
	return clima_datos
