extends Control

@onready var btn_tienda = $"MainVBox/Button"
const SHOP_SCENE = preload("res://Scenes/tienda.tscn")

var shop_instance = null
var plata_jugador = 100
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	btn_tienda.pressed.connect(on_shop_button_pressed)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.

func on_shop_button_pressed():
	if shop_instance == null:
		# 1. Instanciar la escena de la tienda
		shop_instance = SHOP_SCENE.instantiate()
		
		add_child(shop_instance)
		
		
		# 3. Conectar la señal de cierre de la tienda (si tu tienda tiene una)
		# Por ejemplo, si tu Shop.gd tiene una señal 'shop_closed':
		shop_instance.shop_closed.connect(_on_shop_closed)
		
	# 4. Mostrar la tienda y pausar el juego (si es una ventana modal)
	shop_instance.show_shop() # Llama a un método en tu script Shop.gd para manejar la visibilidad
	get_tree().paused = true
	
	# Opcional: Actualizar el dinero del jugador en la tienda
	shop_instance.player_money = plata_jugador
	shop_instance.update_money_display()

func _on_shop_closed():
	shop_instance = null
	get_tree().paused = false
