extends TileMapLayer

@export var max_casas: int = 70
@export var tamanho_corredor_max: int = 5
@export var tamanho_tile: int = 16

# --- CENAS (Arraste no Inspector) ---
@export_group("Heróis e Objetivos")
@export var cena_jogador: PackedScene
@export var cena_saida: PackedScene
@export var cena_animal: PackedScene
@export var cena_checkpoint: PackedScene

@export_group("Adversários ODS 15")
@export var cena_chama: PackedScene     
@export var cena_cacador: PackedScene   
@export var cena_trator: PackedScene    
@export var cena_nevoa: PackedScene     

var chao_gerado: Array[Vector2i] = []

func _ready():
	randomize()
	gerar_labirinto_organico()
	gerar_paredes()
	distribuir_estrategicamente()

# --- 1. GERAÇÃO DO MAPA ---
func gerar_labirinto_organico():
	var pos_atual = Vector2i.ZERO
	chao_gerado.append(pos_atual)
	
	# Como o script já está no próprio TileMapLayer, chamamos set_cell direto
	set_cell(pos_atual, 0, Vector2i(0, 0))

	var direcoes = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	
	while chao_gerado.size() < max_casas:
		var direcao_atual = direcoes.pick_random()
		var passos_nesta_direcao = randi_range(2, tamanho_corredor_max)
		
		for i in range(passos_nesta_direcao):
			if chao_gerado.size() >= max_casas:
				break
				
			pos_atual += direcao_atual
			
			if not chao_gerado.has(pos_atual):
				chao_gerado.append(pos_atual)
				
				# Chama direto
				set_cell(pos_atual, 0, Vector2i(0, 0))

# --- 2. DISTRIBUIÇÃO DAS ENTIDADES ---
func distribuir_estrategicamente():
	var posicoes_livres = chao_gerado.duplicate()
	
	# Jogador no início
	var pos_inicial = posicoes_livres[0]
	instanciar_objeto(cena_jogador, pos_inicial)
	posicoes_livres.erase(pos_inicial)
	
	# Saída no ponto mais distante
	var pos_saida = encontrar_ponto_mais_distante(pos_inicial, posicoes_livres)
	instanciar_objeto(cena_saida, pos_saida)
	posicoes_livres.erase(pos_saida)
	
	# Embaralha as casas restantes para o resto
	posicoes_livres.shuffle()
	
	# Spawn Animais (4x)
	for i in range(4):
		if posicoes_livres.size() > 0: instanciar_objeto(cena_animal, posicoes_livres.pop_back())
			
	# Spawn Ameaças (Adversários)
	for i in range(3): # 3 Queimadas
		if posicoes_livres.size() > 0: instanciar_objeto(cena_chama, posicoes_livres.pop_back())
	for i in range(2): # 2 Caçadores
		if posicoes_livres.size() > 0: instanciar_objeto(cena_cacador, posicoes_livres.pop_back())
	for i in range(2): # 2 Névoas Tóxicas
		if posicoes_livres.size() > 0: instanciar_objeto(cena_nevoa, posicoes_livres.pop_back())
	if posicoes_livres.size() > 0: # 1 Trator Bloqueador
		instanciar_objeto(cena_trator, posicoes_livres.pop_back())
			
	# Spawn Santuário / Checkpoint (1x)
	if posicoes_livres.size() > 0:
		instanciar_objeto(cena_checkpoint, posicoes_livres.pop_back())

func encontrar_ponto_mais_distante(inicio: Vector2i, lista_posicoes: Array[Vector2i]) -> Vector2i:
	var casa_mais_longe = lista_posicoes[0]
	var maior_distancia = 0.0
	
	for casa in lista_posicoes:
		var distancia = Vector2(inicio).distance_to(Vector2(casa))
		if distancia > maior_distancia:
			maior_distancia = distancia
			casa_mais_longe = casa
			
	return casa_mais_longe

func instanciar_objeto(cena: PackedScene, coord_grid: Vector2i):
	if cena != null:
		var novo_obj = cena.instantiate()
		# Chamamos map_to_local direto também
		novo_obj.position = map_to_local(coord_grid) 
		add_child(novo_obj)

# --- 3. GERAÇÃO DE PAREDES ---
func gerar_paredes():
	var celulas_chao = get_used_cells()
	var direcoes = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT, 
					Vector2i(1,1), Vector2i(1,-1), Vector2i(-1,1), Vector2i(-1,-1)]
					
	for chao in celulas_chao:
		for dir in direcoes:
			var vizinho = chao + dir
			# Se a casa vizinha estiver vazia, coloca uma parede
			if get_cell_source_id(vizinho) == -1: 
				set_cell(vizinho, 1, Vector2i(0, 0)) # Assumindo que a parede é a segunda imagem no seu TileSet
