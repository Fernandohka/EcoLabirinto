extends SceneTree
## 50 seeds × 5 biomas = 250 cenários, com três dificuldades distribuídas.
## godot --headless --path Eco --script res://Adventure/qa_seeds_v7.gd
const WorldScript = preload("res://Adventure/world.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var runs: int = 0
	var world = WorldScript.new()
	get_root().add_child(world)
	for seed_index in range(50):
		for stage in range(5):
			var difficulty: int = (seed_index + stage) % 3
			var seed: String = "ECO-SEED-%04d" % seed_index
			world.setup(stage, difficulty, seed)
			var start: Vector2i = world.world_cell(world.player_spawn)
			var exit_cell: Vector2i = world.world_cell(world.exit_position)
			assert(world.floor_at(start), "Jogador nasceu em parede")
			assert(world.floor_at(exit_cell), "Portal nasceu em parede")
			assert(not world.astar.get_id_path(start, exit_cell).is_empty(), "Portal inacessível")
			var saved_grid: Array = world.grid.duplicate(true)
			var saved_animals: Array = world.animals.duplicate(true)
			var saved_fires: Array = world.fires.duplicate(true)
			for group in [world.animals, world.rubbish, world.fires, world.fountains, world.enemies]:
				for item in group:
					var target: Vector2i = world.world_cell(Vector2(item["pos"]))
					assert(not world.astar.get_id_path(start, target).is_empty(), "Objeto inalcançável")
			world.setup(stage, difficulty, seed)
			assert(world.grid == saved_grid, "Seed não repetiu geometria")
			assert(world.animals == saved_animals, "Seed não repetiu animais")
			assert(world.fires == saved_fires, "Seed não repetiu incêndios")
			runs += 1
	print("QA V7 seeds: %d mundos válidos e determinísticos" % runs)
	world.queue_free()
	quit(0)
