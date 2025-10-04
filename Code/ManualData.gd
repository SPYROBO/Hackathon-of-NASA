
extends RefCounted
# La clave (e.j., "analyze_data") debe coincidir con el nombre de tu botón en el código.
const MISSION_DATA = {
	"mission": {
		"title": "ANALYZE DATA",
		"image": preload("res://Images/manual/mission.png"),
		"alert_text": "mission ",
		"concept_text": "Tu mision en el juego es que al final de las 4 semanas tenes que tener por lo menos $1000, si no juntas esta cantidad perderas.",
		"key_color_1": Color.RED,
		"key_text_1": "Riesgo de Sequía"
	},
	"tablet": {
		"title": "MONITOR GROWTH",
		"image": preload("res://Images/manual/tablet.png"),
		"alert_text": "plant:",
		"concept_text": "La tablet tiene dos secciones: una superior que muestra el estado de tus parcelas con plantas y una inferior con datos climáticos satelitales. Debes usar estos datos de clima para decidir qué plantas comprar, ya que las afecta de distinta forma.",
		"key_color_1": Color.BLUE,
		"key_text_1": "Nivel de Riego",
	},
	"shop": {
		"title": "MONITOR GROWTH",
		"image": preload("res://Images/manual/shop.png"),
		"alert_text": "fumigation:",
		"concept_text": "Aca estan las semillas que podes plantar, para hacerlo solo tenes que presionar el boton de comprar y luego la parcelas donde quieras que este, en cada semilla esta su precio, el clima recomendado para esta y los dias que tarda en crecer.",
		"key_color_1": Color.BLUE,
		"key_text_1": "Nivel de Riego",
	},
	"modo": {
		"title": "MONITOR GROWTH",
		"image": preload("res://Images/manual/acciones.png"),
		"alert_text": "water:",
		"concept_text": "Ademas de plantar tenes tres habilidades principales en el juego que son las de regar, fumigar y cosechar. Para activar cualquiera de estas tienes que presionar los botones con su simbolo que estan abajo a la izquida",
		"key_color_1": Color.BLUE,
		"key_text_1": "Nivel de Riego",
	},
	# Agrega más misiones aquí (ej: 'manage_water', 'harvest')
	# "otra_mision": { ... } 
}
