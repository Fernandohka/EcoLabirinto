extends TileMapLayer

@export_group("Configurações do TileSet (Chão)")
@export var chao_source_id: int = 0
@export var chao_atlas_coords: Vector2i = Vector2i(0, 0)

@export_group("Configurações do TileSet (Parede)")
@export var parede_source_id: int = 1
@export var parede_atlas_coords: Vector2i = Vector2i(0, 0)
@export var parede_scene_id: int = 1 # ID da cena no Scenes Collection

@export_group("Parâmetros do Labirinto")
@export var max_casas: int = 80
@export var tamanho_corredor_max: int = 3
@export_range(0.0, 1.0) var chance_ramificacao: float = 0.35
@export_range(0.0, 1.0) var densidade_pilares: float = 0.40 # Ajustado para não bloquear passagens

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
	gerar_pilares_internos()
	garantir_conectividade() # <--- Elimina qualquer área inacessível
	renderizar_chao()
	gerar_paredes()
	distribuir_estrategicamente()

# --- 1. GERAÇÃO DO MAPA ---
func gerar_labirinto_organico():
	chao_gerado.clear()
	clear()
	
	var pos_atual = Vector2i.ZERO
	chao_gerado.append(pos_atual)

	var direcoes = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	var tentativas = 0
	var max_tentativas = max_casas * 50

	while chao_gerado.size() < max_casas and tentativas < max_tentativas:
		tentativas += 1
		
		if randf() < chance_ramificacao and chao_gerado.size() > 1:
			pos_atual = chao_gerado.pick_random()

		var direcao_atual = direcoes.pick_random()
		var passos = randi_range(1, tamanho_corredor_max)
		
		for i in range(passos):
			if chao_gerado.size() >= max_casas:
				break
				
			pos_atual += direcao_atual
			
			if not chao_gerado.has(pos_atual):
				chao_gerado.append(pos_atual)

# --- 2. PILARES INTERNOS ---
func gerar_pilares_internos():
	var paredes_internas: Array[Vector2i] = []
	var direcoes_8 = [
		Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT,
		Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)
	]
	
	for pos in chao_gerado:
		if pos == Vector2i.ZERO:
			continue
			
		var vizinhos_chao = 0
		for dir in direcoes_8:
			if chao_gerado.has(pos + dir):
				vizinhos_chao += 1
				
		if vizinhos_chao == 8 and randf() < densidade_pilares:
			paredes_internas.append(pos)

	for pos in paredes_internas:
		chao_gerado.erase(pos)

# --- 3. FLOOD FILL (GARANTIA DE ACESSIBILIDADE 100%) ---
func garantir_conectividade():
	if chao_gerado.is_empty():
		return
		
	var inicio = Vector2i.ZERO
	if not chao_gerado.has(inicio):
		inicio = chao_gerado[0]
		
	var alcancaveis: Array[Vector2i] = []
	var fila: Array[Vector2i] = [inicio]
	var visitados = {inicio: true}
	alcancaveis.append(inicio)
	
	var direcoes_4 = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	
	# Navega por todas as casas interligadas a partir da origem
	while fila.size() > 0:
		var atual = fila.pop_front()
		for dir in direcoes_4:
			var vizinho = atual + dir
			if chao_gerado.has(vizinho) and not visitados.has(vizinho):
				visitados[vizinho] = true
				alcancaveis.append(vizinho)
				fila.append(vizinho)
				
	# Apaga do array qualquer bloco de chão que não seja alcançável a pé
	chao_gerado = alcancaveis

func renderizar_chao():
	for pos in chao_gerado:
		set_cell(pos, chao_source_id, chao_atlas_coords)

# --- 4. GERAÇÃO DE PAREDES ---
func gerar_paredes():
	var celulas_chao = get_used_cells()
	var direcoes = [
		Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT, 
		Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)
	]
	
	for chao in celulas_chao:
		for dir in direcoes:
			var vizinho = chao + dir
			if get_cell_source_id(vizinho) == -1: 
				set_cell(vizinho, parede_source_id, parede_atlas_coords, parede_scene_id)

# --- 5. DISTRIBUIÇÃO DAS ENTIDADES ---
func distribuir_estrategicamente():
	var posicoes_livres = chao_gerado.duplicate()
	
	var pos_inicial = Vector2i.ZERO
	if not posicoes_livres.has(pos_inicial):
		pos_inicial = posicoes_livres[0]
		
	instanciar_objeto(cena_jogador, pos_inicial)
	posicoes_livres.erase(pos_inicial)
	
	var pos_saida = encontrar_ponto_mais_distante(pos_inicial, posicoes_livres)
	instanciar_objeto(cena_saida, pos_saida)
	posicoes_livres.erase(pos_saida)
	
	posicoes_livres.shuffle()
	
	for i in range(4):
		if posicoes_livres.size() > 0: 
			instanciar_objeto(cena_animal, posicoes_livres.pop_back())
			
	for i in range(3): 
		if posicoes_livres.size() > 0: instanciar_objeto(cena_chama, posicoes_livres.pop_back())
	for i in range(2): 
		if posicoes_livres.size() > 0: instanciar_objeto(cena_cacador, posicoes_livres.pop_back())
	for i in range(2): 
		if posicoes_livres.size() > 0: instanciar_objeto(cena_nevoa, posicoes_livres.pop_back())
	if posicoes_livres.size() > 0: 
		instanciar_objeto(cena_trator, posicoes_livres.pop_back())
		
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
		novo_obj.position = map_to_local(coord_grid) 
		add_child(novo_obj)
