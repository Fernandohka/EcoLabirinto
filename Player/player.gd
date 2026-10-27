extends CharacterBody2D

# Enumeração das Classes no Inspector
@export_enum("Léo (Explorador)", "Helena (Guarda-Florestal)", "Rafael (Veterinário)", "Clara (Bióloga)") var classe_atual: int = 0

@export var tamanho_bloco: int = 100 # Ajuste para o tamanho do seu Tile/Sprite
var pode_mover: bool = true

# Inventário / Status ODS 15
var animais_resgatados: int = 0
var especies_registradas: Array[String] = []
var ameacas_impedidas: int = 0

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
	# O test_move simula o passo. Se não bater em nada (falso), ele anda.
	if not test_move(transform, direcao * tamanho_bloco):
		position += direcao * tamanho_bloco
		disparar_habilidade_passiva()

func disparar_habilidade_passiva():
	# Estrutura preparada para ativar a habilidade especial ao pisar nos blocos
	match classe_atual:
		0:
			# Léo
			pass 
		1:
			# Helena
			pass 
		2:
			# Rafael
			pass 
		3:
			# Clara
			pass

# Função a ser chamada pelas cenas dos animais (Coletavel.tscn)
func interagir_com_animal(especie: String, raro: bool):
	animais_resgatados += 1
	
	if classe_atual == 3: # Se for a Clara (Bióloga)
		if not especies_registradas.has(especie):
			especies_registradas.append(especie)
			print("Clara registrou uma nova espécie: ", especie)
			
	elif classe_atual == 2: # Se for o Rafael (Veterinário)
		print("Rafael resgatou o animal de forma imediata!")
		
	# Destroi o animal do mapa após coletar (isso deve estar no script do animal também)
