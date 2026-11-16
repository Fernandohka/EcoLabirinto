extends SceneTree
## Verificação de geração, conectividade e repetibilidade da seed.
## godot --headless --path Eco --script res://Adventure/smoke_test.gd
const WorldScript = preload("res://Adventure/world.gd")

func _initialize() -> void:
	call_deferred("_run_checks")

func _run_checks() -> void:
	var checked: int = 0
	for stage in [-1, 0, 1, 2, 3, 4]:
		for difficulty in [0, 1, 2]:
			var world = WorldScript.new()
			get_root().add_child(world)
			world.setup(stage, difficulty, "TESTE-ARVORE-42")
			var spawn: Vector2i = world.world_cell(world.player_spawn)
			var exit_tile: Vector2i = world.world_cell(world.exit_position)
			assert(world.floor_at(spawn), "Jogador nasceu na parede")
			assert(world.floor_at(exit_tile), "Portal nasceu na parede")
			assert(not world.astar.get_id_path(spawn, exit_tile).is_empty(), "Portal inacessível")
			assert(world.animals.size() == world.animal_target, "Contagem de animais incorreta")
			assert(world.rubbish.size() == world.trash_target, "Contagem de lixo incorreta")
			assert(world.fires.size() == world.fire_target, "Contagem de incêndios incorreta")
			var snapshot: Array = world.grid.duplicate(true)
			var animals: Array = world.animals.duplicate(true)
			var fires: Array = world.fires.duplicate(true)
			var boss_initial: Vector2 = world.boss_position
			for collection in [world.animals, world.rubbish, world.fires, world.fountains, world.enemies]:
				for entity in collection:
					var pos: Vector2i = world.world_cell(entity["pos"])
					assert(world.floor_at(pos), "Entidade nasceu sobre parede")
					assert(not world.astar.get_id_path(spawn, pos).is_empty(), "Entidade inacessível")
			if stage == 4:
				assert(world.boss_health == world.boss_max_health, "Chefe nasceu sem vida")
				assert(world.boss_health == 75 + difficulty * 15, "Dificuldade do chefe incorreta")
				assert(world.fires.size() <= 3 + difficulty, "Incêndios iniciais ultrapassam limite")
				assert(world.floor_at(world.world_cell(world.boss_position)), "Chefe nasceu sobre parede")
			world.setup(stage, difficulty, "TESTE-ARVORE-42")
			assert(world.grid == snapshot, "Mesmo código gerou outro mapa")
			assert(world.animals == animals, "Mesmo código gerou outros animais")
			assert(world.fires == fires, "Mesmo código gerou outros incêndios")
			if stage == 4:
				assert(world.boss_position == boss_initial, "Seed do chefe não reproduzida")
			if stage >= 0:
				world.add_enemy_wave(3)
				assert(world.enemies.size() >= 3, "Onda de inimigos não nasceu")
			world.queue_free()
			checked += 1
	print("18 CENARIOS DE GERACAO VERIFICADOS: %d / 18" % checked)
	quit(0)
