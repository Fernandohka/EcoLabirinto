extends Area2D

func _ready():
	# Liga o sinal de colisão automaticamente
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Verifica se quem pisou foi o jogador
	if body.name == "Player":
		print("Você interagiu com: ", self.name)
		
		# Aqui você pode adicionar lógica! Ex: se for a saída, muda de fase.
		if self.name.begins_with("Saida"):
			print("VOCÊ VENCEU O LABIRINTO!")
		elif self.name.begins_with("Chama") or self.name.begins_with("Cacador"):
			print("Você sofreu dano da ameaça!")
		elif self.name.begins_with("Animal"):
			print("Animal resgatado!")
			
		queue_free() # Destrói o objeto do mapa (some da tela)
