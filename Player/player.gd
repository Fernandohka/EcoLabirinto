extends CharacterBody2D

# --- ATRIBUTOS ---
@export var tamanho_bloco: int = 64
@export var pode_mover: bool = true

@export_group("Status do Jogador")
@export var vida_max: float = 100.0
var vida_atual: float = 100.0

@export var stamina_max: float = 100.0
var stamina_atual: float = 100.0
@export var custo_stamina_passo: float = 1.0
@export var regen_stamina_taxa: float = 2.0 # Por segundo

var inventario: Array[String] = []
var hud = null

func _ready():
	vida_atual = vida_max
	stamina_atual = stamina_max
	
	# Busca o HUD no grupo
	hud = get_tree().get_first_node_in_group("HUD")
	if hud:
		hud.atualizar_vida(vida_atual, vida_max)
		hud.atualizar_stamina(stamina_atual, stamina_max)

func _process(delta):
	# Regeneração de Stamina
	if stamina_atual < stamina_max:
		stamina_atual = min(stamina_max, stamina_atual + regen_stamina_taxa * delta)
		if hud:
			hud.atualizar_stamina(stamina_atual, stamina_max)

func _input(event):
	if not pode_mover:
		return

	var direcao = Vector2.ZERO
	
	if event.is_action_pressed("D"):
		direcao = Vector2.RIGHT
	elif event.is_action_pressed("A"):
		direcao = Vector2.LEFT
	elif event.is_action_pressed("S"):
		direcao = Vector2.DOWN
	elif event.is_action_pressed("W"):
		direcao = Vector2.UP

	if direcao != Vector2.ZERO:
		mover_jogador(direcao)

func mover_jogador(direcao: Vector2):
	# Verifica se tem stamina suficiente para dar o passo
	if stamina_atual < custo_stamina_passo:
		print("Exausto! Espere a stamina regenerar.")
		return

	if not test_move(transform, direcao * tamanho_bloco):
		position += direcao * tamanho_bloco
		
		# Consome Stamina
		stamina_atual -= custo_stamina_passo
		if hud:
			hud.atualizar_stamina(stamina_atual, stamina_max)

func receber_dano(quantidade: float):
	vida_atual = max(0, vida_atual - quantidade)
	if hud:
		hud.atualizar_vida(vida_atual, vida_max)
		
	if vida_atual <= 0:
		morrer()

func adicionar_ao_inventario(nome_item: String):
	inventario.append(nome_item)
	if hud:
		hud.atualizar_inventario(inventario)

func morrer():
	print("Você perdeu a missão!")
	get_tree().reload_current_scene()
