extends CanvasLayer

@onready var barra_vida: ProgressBar = $Control/MarginContainer/VBoxContainer/BarraVida
@onready var barra_stamina: ProgressBar = $Control/MarginContainer/VBoxContainer/BarraStamina
@onready var lista_inventario: ItemList = $Control/MarginContainer/VBoxContainer/ListaInventario
@onready var menu_pause: Control = $MenuPause

func _ready():
	add_to_group("HUD")
	menu_pause.hide()
	
	# Conecta os botões do Pause
	$MenuPause/VBoxContainer/BotaoContinuar.pressed.connect(_on_continuar_pressed)
	$MenuPause/VBoxContainer/BotaoReiniciar.pressed.connect(_on_reiniciar_pressed)
	$MenuPause/VBoxContainer/BotaoSair.pressed.connect(_on_sair_pressed)

func _unhandled_input(event):
	# Tecla ESC ou P para pausar
	if event.is_action_pressed("ui_cancel"):
		alternar_pause()

func atualizar_vida(atual: float, maximo: float):
	barra_vida.max_value = maximo
	barra_vida.value = atual

func atualizar_stamina(atual: float, maximo: float):
	barra_stamina.max_value = maximo
	barra_stamina.value = atual

func atualizar_inventario(itens: Array[String]):
	lista_inventario.clear()
	for item in itens:
		lista_inventario.add_item(item)

func alternar_pause():
	var estado_pause = !get_tree().paused
	get_tree().paused = estado_pause
	menu_pause.visible = estado_pause

func _on_continuar_pressed():
	alternar_pause()

func _on_reiniciar_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_sair_pressed():
	get_tree().quit()
