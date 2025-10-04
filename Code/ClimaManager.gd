# ClimaManager.gd
extends Node

# URL base de la API NASA POWER (ajusta el nombre del archivo si es necesario)
const NASA_POWER_URL = "https://power.larc.nasa.gov/api/temporal/daily/point?parameters=T2M,PRECTOTCORR,ALLSKY_SFC_SW_DWN,RH2M,WS2M&community=AG&longitude=%s&latitude=%s&start=%s&end=%s&format=JSON"

# Variables para almacenar los datos (asumiendo una única ubicación de granja)
var granja_latitud: float = 34.0522  # Ejemplo: Los Ángeles, CÁMBIALO a tu ubicación
var granja_longitud: float = -118.2437 # Ejemplo: Los Ángeles, CÁMBIALO a tu ubicación
var clima_datos: Dictionary = {} # Almacena los datos procesados

# Necesitas un nodo HTTPRequest para hacer la solicitud
var http_request: HTTPRequest

signal clima_data_updated(success: bool) # Emite TRUE si fue exitoso, FALSE si falló

func _ready():
	# Asegúrate de que este nodo sea un hijo del ClimaManager
	add_to_group("clima_manager")
	# 🚨 VERIFICACIÓN CRÍTICA 1: Asegurar que el nodo HTTPRequest exista
	if http_request == null or not is_instance_valid(http_request):
		http_request = HTTPRequest.new()
		add_child(http_request)
		
	http_request.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# 🚨 VERIFICACIÓN CRÍTICA 2: Asegurar que la señal esté conectada.
	# Usamos connect.is_connected() para evitar duplicados si _ready se llama dos veces.
	if not http_request.request_completed.is_connected(_on_request_completed):
		http_request.request_completed.connect(_on_request_completed)
	
	print("DEBUG: HTTPRequest está listo y conectado.")

# --- FUNCIÓN PRINCIPAL PARA SOLICITAR DATOS ---
# Llama a esta función para actualizar los datos del clima
func fetch_nasa_data(dias_atras: int = 30):
	
	var end_time_unix: float = Time.get_unix_time_from_system()
	
	# 2. Calcular la fecha de inicio Unix
	var seconds_in_day: float = 24.0 * 60.0 * 60.0
	
	# 🚨 CLAVE: Aseguramos que la resta se haga con float
	var seconds_to_subtract: float = float(dias_atras) * seconds_in_day
	var start_time_unix: float = end_time_unix - seconds_to_subtract 

	# 3. Conversión a Diccionarios
	var end_datetime_dict = Time.get_datetime_dict_from_unix_time(end_time_unix)
	var start_datetime_dict = Time.get_datetime_dict_from_unix_time(start_time_unix)

	# 4. Formato YYYYMMDD
	var end_date_formatted = "%04d%02d%02d" % [
		end_datetime_dict.year, 
		end_datetime_dict.month, 
		end_datetime_dict.day
	]
	var start_date_formatted = "%04d%02d%02d" % [
		start_datetime_dict.year, 
		start_datetime_dict.month, 
		start_datetime_dict.day
	]
	
	# 5. Mantenemos la verificación de rango de la NASA
	if start_datetime_dict.year < 1981:
		start_date_formatted = "19810101"
		push_warning("La fecha de inicio calculada era muy antigua y se ajustó a 1981/01/01 (Mínimo de NASA).")

	# Crear la URL completa
	var url = NASA_POWER_URL % [
		str(granja_longitud), 
		str(granja_latitud), 
		start_date_formatted,  
		end_date_formatted     
	]
	
	print("Solicitando datos de NASA a: ", url)
	var error = http_request.request(url)
	if error != OK:
		push_error("Error al iniciar la solicitud HTTP: ", error)

# --- FUNCIÓN LLAMADA AL RECIBIR DATOS ---
func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	print("Resultado HTTP: ", result, ", Código de Respuesta: ", response_code)
	
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var json_string = body.get_string_from_utf8()
		
		# 🚨 PASO DE DEPURACIÓN 1: Intenta parsear el JSON
		var json = JSON.parse_string(json_string) 
		
		# 🚨 PASO DE DEPURACIÓN 2: ¿El parseo fue exitoso y el resultado es un diccionario?
		if json is Dictionary:
			print("DEBUG: JSON PARSEADO con ÉXITO. Procesando datos...")
			
			# --- Lógica de procesamiento ---
			clima_datos = process_nasa_json(json)
			
			# 🚨 PASO DE DEPURACIÓN 3: ¿El diccionario final contiene un error?
			if clima_datos.has("error"):
				push_error("Error al procesar el JSON: ", clima_datos["error"])
				emit_signal("clima_data_updated", false)
			else:
				print("DEBUG: Datos procesados y listos. Emitiendo señal...")
				emit_signal("clima_data_updated", true) # ÉXITO
				
		else:
			# Esto puede ocurrir si el string JSON está vacío o malformado
			push_error("Error: La respuesta de NASA no pudo ser parseada a un diccionario (JSON.parse_string falló).")
			emit_signal("clima_data_updated", false)
	else:
		push_error("Error en la solicitud HTTP. Fallo o código inesperado.")
		emit_signal("clima_data_updated", false)

# --- FUNCIÓN PARA PROCESAR EL JSON DE LA NASA ---
# ClimaManager.gd (Función process_nasa_json corregida)

# Definimos el valor de relleno de la NASA
const NASA_FILL_VALUE = -999.0

func process_nasa_json(json_data: Dictionary) -> Dictionary:
	var properties = json_data.get("properties", {})
	var parameter = properties.get("parameter", {})
	
	# Inicialización de contadores y sumas para calcular promedios
	var temp_sum = 0.0
	var solar_sum = 0.0
	var precip_sum = 0.0
	var rh_sum = 0.0
	var wind_sum = 0.0
	var count = 0

	# CLAVE: Usamos el diccionario de T2M para iterar sobre todas las fechas disponibles
	var t2m_data = parameter.get("T2M", {})
	
	for date_str in t2m_data.keys():
		var t2m = parameter.get("T2M", {})[date_str]
		var solar = parameter.get("ALLSKY_SFC_SW_DWN", {})[date_str]
		var precip = parameter.get("PRECTOTCORR", {})[date_str]
		var rh = parameter.get("RH2M", {})[date_str]
		var wind = parameter.get("WS2M", {})[date_str]

		# 🚨 FILTRAR DATOS INVÁLIDOS 🚨
		if t2m > NASA_FILL_VALUE: # Usamos T2M como filtro principal
			temp_sum += t2m
			
			# Asegurarse de que los demás valores también sean válidos antes de sumar
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
			"dias_validos": count, # <- Nuevo
			"temperatura_avg": temp_sum / count,
			"radiacion_solar_avg": solar_sum / count,
			"precipitacion_total": precip_sum,   # <- Lluvias
			"humedad_avg": rh_sum / count,       # <- Humedad
			"viento_avg": wind_sum / count,      # <- Vientos
			"ultima_actualizacion": Time.get_datetime_string_from_system(true)
		}
	
	# Si todos los días devuelven -999.0 (ej. todos los datos son futuros), devuelve un error.
	return {"error": "No se encontraron datos utilizables en el rango de fechas (posiblemente todos los datos son futuros)."}


# --- FUNCIÓN ACCEDIDA POR LA TABLET ---
func get_clima_data() -> Dictionary:
	return clima_datos
