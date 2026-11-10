extends Area2D

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if not body.has_method("receber_dano"):
		return

	# Checa pelos Grupos em vez do Nome
	if is_in_group("chama"):
		body.receber_dano(25)
		print("Dano por Queimada!")
	
	elif is_in_group("cacador"):
		body.receber_dano(35)
		print("Dano por Caçador!")
	
	elif is_in_group("nevoa"):
		body.receber_dano(15)
		print("Dano por Névoa Tóxica!")
	
	elif is_in_group("trator"):
		body.receber_dano(40)
		print("Dano por Trator!")
	
	elif is_in_group("animal"):
		body.adicionar_ao_inventario("Animal Resgatado")
		print("Animal salvo!")
	
	elif is_in_group("saida"):
		print("VOCÊ COMPLETOU A FASE!")
	
	queue_free()
