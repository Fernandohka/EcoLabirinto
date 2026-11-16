extends Node2D
## EcoLabirinto - mundo procedural com células conectadas, perigos e perseguição.
## Toda a geometria é desenhada via código: não depende de sprites externos.

signal enemy_contact(kind: String)
signal fire_contact()
signal forest_decay(points: int)
signal fire_spread()
signal boss_warning()
signal boss_phase_changed(phase: int)

const ArtCatalog = preload("res://Adventure/art_catalog.gd")
const Palette = preload("res://Adventure/theme_palette.gd")
const TerrainLayer = preload("res://Adventure/terrain_layer.gd")
const TILE = 40
const GENERATOR_VERSION: String = "7.0"
const SPECIES = [
	["arara", "preguica", "macaco", "sapo"],
	["tatu", "tamandua", "lobo_guara", "sapo"],
	["capivara", "jacare", "tuiuiu", "onca"],
	["mico", "tucano", "quati", "preguica"],
	["capivara", "onca", "arara", "mico"]
]
const BIOME_FOLDERS = ["Amazonia", "Cerrado", "Pantanal", "MataAtlantica", "Boss"]
const SECRET_NAMES = ["sapo_chapeu", "capivara_oculos", "tatu_dourado", "sapo_azul"]
const DIRECTIONS = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const BIOMES = ["AMAZÔNIA", "CERRADO", "PANTANAL", "MATA ATLÂNTICA"]
const PALETTES = Palette.BIOME_COLORS

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var terrain_layer: Node2D
var grid: Array = []
var width := 0
var height := 0
var level := 0
var difficulty := 1
var player_spawn := Vector2.ZERO
var exit_position := Vector2.ZERO
var animals: Array[Dictionary] = []
var extras: Array[Dictionary] = []
var extras_enabled: bool = true
var texture_cache: Dictionary = {}
var rubbish: Array[Dictionary] = []
var fires: Array[Dictionary] = []
var fountains: Array[Dictionary] = []
var heal_items: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var animal_target := 0
var trash_target := 0
var fire_target := 0
var astar: AStarGrid2D
var damage_clock := 0.0
var decay_clock := 0.0
var spread_clock := 0.0
var phase_clock := 0.0
var render_clock: float = 0.0
var seed_code: String = ""
var wave_number: int = 0
var boss_position: Vector2 = Vector2.ZERO
var boss_health: int = 0
var boss_max_health: int = 100
var boss_chase_clock: float = 0.0
var boss_fire_clock: float = 0.0
var boss_contact_clock: float = 0.0
var boss_path: Array[Vector2i] = []
var boss_step: int = 0
var boss_stun_time: float = 0.0
var boss_warning_time: float = 0.0
var boss_phase: int = 1
var boss_target_position: Vector2 = Vector2.ZERO

func setup(stage: int, mode: int, wanted_seed: String = "ECO-2026", wave: int = 0) -> void:
	# O mesmo código, bioma, dificuldade e onda geram o mesmo mapa inicial.
	seed_code = wanted_seed
	wave_number = wave
	rng.seed = int(wanted_seed.hash()) + (stage + 3) * 104729 + mode * 7919 + wave * 131071
	boss_position = Vector2.ZERO
	boss_health = 0
	boss_chase_clock = 0.0
	boss_fire_clock = 0.0
	boss_contact_clock = 0.0
	boss_stun_time = 0.0
	boss_warning_time = 0.0
	boss_phase = 1
	boss_target_position = Vector2.ZERO
	boss_max_health = 75 + clampi(mode, 0, 2) * 15
	boss_path.clear()
	boss_step = 0
	level = stage
	difficulty = mode
	animals.clear()
	extras.clear()
	rubbish.clear()
	fires.clear()
	fountains.clear()
	heal_items.clear()
	enemies.clear()
	damage_clock = 0.0
	decay_clock = 0.0
	spread_clock = 0.0
	phase_clock = 0.0
	if level == -1:
		_generate_tutorial()
	else:
		_generate_maze()
	_prepare_navigation()
	if level == -1:
		_spawn_tutorial()
	else:
		_spawn_stage()
	if level >= 0:
		_spawn_secrets()
	if level == 4:
		boss_position = cell_center(_random_walkable())
		if boss_position.distance_to(player_spawn) < TILE * 8.0:
			boss_position = exit_position
		boss_health = boss_max_health
	if terrain_layer != null:
		terrain_layer.call("rebuild", self)
	queue_redraw()

func _empty_grid(w: int, h: int) -> void:
	width = w
	height = h
	grid.clear()
	for y in range(height):
		var row := PackedInt32Array()
		row.resize(width)
		grid.append(row)

func _set_floor(c: Vector2i) -> void:
	if c.x > 0 and c.y > 0 and c.x < width - 1 and c.y < height - 1:
		var row: PackedInt32Array = grid[c.y]
		row[c.x] = 1
		grid[c.y] = row

func floor_at(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < width and c.y < height and grid[c.y][c.x] == 1

func cell_center(c: Vector2i) -> Vector2:
	return Vector2((float(c.x) + 0.5) * TILE, (float(c.y) + 0.5) * TILE)

func world_cell(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / TILE), floori(p.y / TILE))

func _generate_maze() -> void:
	var w := 25 + level * 2 + difficulty * 2
	var h := 19 + level * 2 + difficulty * 2
	_empty_grid(w, h)
	var start := Vector2i(1, 1)
	_set_floor(start)
	var stack: Array[Vector2i] = [start]
	# Depth-first backtracker: todas as passagens nascem conectadas.
	while not stack.is_empty():
		var current: Vector2i = stack.back()
		var choices: Array[Vector2i] = []
		for direction in DIRECTIONS:
			var next: Vector2i = current + direction * 2
			if next.x > 0 and next.y > 0 and next.x < width - 1 and next.y < height - 1 and not floor_at(next):
				choices.append(direction)
		if choices.is_empty():
			stack.pop_back()
		else:
			var direction: Vector2i = choices[rng.randi_range(0, choices.size() - 1)]
			_set_floor(current + direction)
			var next: Vector2i = current + direction * 2
			_set_floor(next)
			stack.append(next)
	# Retira algumas divisórias para caminhos alternativos, sem bifurcações forçadas.
	for trial in range(55 + level * 18):
		var c := Vector2i(rng.randi_range(2, width - 3), rng.randi_range(2, height - 3))
		if not floor_at(c):
			if (floor_at(c + Vector2i.UP) and floor_at(c + Vector2i.DOWN)) or (floor_at(c + Vector2i.LEFT) and floor_at(c + Vector2i.RIGHT)):
				_set_floor(c)
	# Clareiras abertas a partir de pisos existentes: não criam ilhas isoladas.
	for room in range(7 + level * 2):
		var anchor := _random_walkable()
		if anchor.x >= 3 and anchor.y >= 3 and anchor.x < width - 3 and anchor.y < height - 3:
			for offset_y in range(-1, 2):
				for offset_x in range(-1, 2):
					_set_floor(anchor + Vector2i(offset_x, offset_y))
	player_spawn = cell_center(start)
	exit_position = cell_center(_furthest_from(start))

func _generate_tutorial() -> void:
	var layout := [
		"###################",
		"#...#.............#",
		"#...#..#####......#",
		"#.................#",
		"#.......#.........#",
		"#..##...#..###....#",
		"#.................#",
		"#.............#...#",
		"#....##.......#...#",
		"#.................#",
		"#......####.......#",
		"#.................#",
		"###################"
	]
	_empty_grid(19, 13)
	for y in range(layout.size()):
		for x in range(layout[y].length()):
			if layout[y].substr(x, 1) == ".":
				_set_floor(Vector2i(x, y))
	player_spawn = cell_center(Vector2i(2, 2))
	exit_position = cell_center(Vector2i(16, 11))

func _prepare_navigation() -> void:
	astar = AStarGrid2D.new()
	astar.region = Rect2i(0, 0, width, height)
	astar.cell_size = Vector2(TILE, TILE)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	for y in range(height):
		for x in range(width):
			if grid[y][x] != 1:
				astar.set_point_solid(Vector2i(x, y), true)

func _furthest_from(start: Vector2i) -> Vector2i:
	var queue: Array[Vector2i] = [start]
	var distances: Dictionary = {}
	distances[start] = 0
	var farthest := start
	var index := 0
	while index < queue.size():
		var c: Vector2i = queue[index]
		index += 1
		if distances[c] > distances[farthest]:
			farthest = c
		for d in DIRECTIONS:
			var neighbor: Vector2i = c + d
			if floor_at(neighbor) and not distances.has(neighbor):
				distances[neighbor] = distances[c] + 1
				queue.append(neighbor)
	return farthest

func _random_walkable() -> Vector2i:
	for attempt in range(200):
		var c := Vector2i(rng.randi_range(1, width - 2), rng.randi_range(1, height - 2))
		if floor_at(c):
			return c
	return Vector2i(1, 1)

func _pick_spawn(used: Dictionary, min_start: int = 5, min_exit: int = 3) -> Vector2:
	var start := world_cell(player_spawn)
	var finish := world_cell(exit_position)
	for attempt in range(650):
		var c := _random_walkable()
		if used.has(c) or abs(c.x - start.x) + abs(c.y - start.y) < min_start:
			continue
		if abs(c.x - finish.x) + abs(c.y - finish.y) < min_exit:
			continue
		used[c] = true
		return cell_center(c)
	# Fallback com critérios relaxados se o labirinto tiver pouco espaço.
	for y in range(1, height - 1):
		for x in range(1, width - 1):
			var c := Vector2i(x, y)
			if floor_at(c) and not used.has(c) and c != start and c != finish:
				used[c] = true
				return cell_center(c)
	return player_spawn

func _spawn_tutorial() -> void:
	animals.append({"pos": cell_center(Vector2i(5, 3)), "kind": 0})
	rubbish.append({"pos": cell_center(Vector2i(9, 6))})
	fires.append({"pos": cell_center(Vector2i(13, 8))})
	fountains.append({"pos": cell_center(Vector2i(5, 9))})
	animal_target = 1
	trash_target = 1
	fire_target = 1

func _spawn_stage() -> void:
	var used: Dictionary = {}
	used[world_cell(player_spawn)] = true
	used[world_cell(exit_position)] = true
	animal_target = 2 + int(level >= 2) + int(difficulty == 2)
	trash_target = 2 + int(level >= 1) + int(difficulty == 2)
	fire_target = 2 + int(level >= 1) + int(difficulty >= 1)
	if level == 4:
		# Arena final compacta, com objetivos alcançáveis em todas as dificuldades.
		animal_target = 2
		trash_target = 2
		fire_target = 2 + difficulty
	for i in range(animal_target):
		animals.append({"pos": _pick_spawn(used), "kind": (i + level) % 4})
	for i in range(trash_target):
		rubbish.append({"pos": _pick_spawn(used)})
	for i in range(fire_target):
		fires.append({"pos": _pick_spawn(used)})
	for i in range(2 + int(level >= 2)):
		fountains.append({"pos": _pick_spawn(used, 4, 2)})
	var hunter_count := 1 + difficulty + int(level >= 2)
	var logger_count := 1 + int(level >= 1) + int(difficulty == 2)
	if level == 4:
		hunter_count = 1 + int(difficulty == 2)
		logger_count = 0
	for i in range(hunter_count + logger_count):
		enemies.append({"pos": _pick_spawn(used, 7, 4), "kind": 0 if i < hunter_count else 1,
			"path": [], "step": 0, "path_time": 0.0, "contact_time": 0.0, "roam": Vector2.ZERO})

func animal_species(kind: int) -> String:
	var index: int = clampi(level, 0, 4)
	return str(SPECIES[index][posmod(kind, 4)])

func _spawn_secrets() -> void:
	# RNG separado da jogabilidade: mesmas posições de objetivos com/sem memes.
	var secret_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	secret_rng.seed = int((seed_code + "|EXTRAS|" + str(level) + "|" + str(difficulty)).hash()) & 0x7fffffff
	var slots: Array[Vector2i] = []
	for y in range(1, height - 1):
		for x in range(1, width - 1):
			var cell: Vector2i = Vector2i(x, y)
			if not floor_at(cell):
				continue
			var pos: Vector2 = cell_center(cell)
			if pos.distance_to(player_spawn) < 160.0 or pos.distance_to(exit_position) < 90.0:
				continue
			var occupied: bool = false
			for group in [animals, rubbish, fires, fountains, enemies]:
				for item in group:
					if item["pos"].distance_to(pos) < TILE * 0.9:
						occupied = true
				if occupied:
					break
			if not occupied:
				slots.append(cell)
	if slots.is_empty():
		return
	# Raro brasileiro, visível mesmo com a opção de memes desativada.
	if level == 0 and secret_rng.randf() < 0.65:
		var pos_rare: Vector2i = slots[secret_rng.randi_range(0, slots.size() - 1)]
		extras.append({"pos": cell_center(pos_rare), "species": "peixe_boi", "secret": false})
	if not extras_enabled:
		return
	var choices: Array[String] = ArtCatalog.meme_names()
	if choices.is_empty():
		return
	var count: int = 1 + int(secret_rng.randf() < 0.40)
	for i in range(count):
		var pos: Vector2i = slots[secret_rng.randi_range(0, slots.size() - 1)]
		var species: String = choices[secret_rng.randi_range(0, choices.size() - 1)]
		var good: bool = true
		for item in extras:
			if Vector2(item["pos"]).distance_to(cell_center(pos)) < 140.0:
				good = false
		if good:
			extras.append({"pos": cell_center(pos), "species": species, "secret": true})

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	terrain_layer = TerrainLayer.new()
	terrain_layer.name = "TerrenoEstatico"
	add_child(terrain_layer)

func _texture(relative_path: String) -> Texture2D:
	if not texture_cache.has(relative_path):
		texture_cache[relative_path] = load("res://Assets/" + relative_path)
	return texture_cache[relative_path] as Texture2D

func _pixel_sprite(relative_path: String, center: Vector2, draw_size: float) -> void:
	var image_texture: Texture2D = _texture(relative_path)
	if image_texture != null:
		draw_texture_rect(image_texture, Rect2(center - Vector2.ONE * draw_size / 2.0, Vector2.ONE * draw_size), false)

func can_occupy(pos: Vector2, radius: float = 11.0) -> bool:
	var corners := [Vector2(-radius, -radius), Vector2(radius, -radius), Vector2(-radius, radius), Vector2(radius, radius)]
	for offset in corners:
		if not floor_at(world_cell(pos + offset)):
			return false
	return true

func move_with_walls(pos: Vector2, change: Vector2, radius: float = 11.0) -> Vector2:
	var result := pos
	var next := result + Vector2(change.x, 0)
	if can_occupy(next, radius):
		result.x = next.x
	next = result + Vector2(0, change.y)
	if can_occupy(next, radius):
		result.y = next.y
	return result

func nearest_interaction(pos: Vector2, max_range: float = 48.0) -> Dictionary:
	var best := {"kind": "", "index": -1, "distance": max_range}
	for i in range(animals.size()):
		_consider(best, pos, animals[i]["pos"], "animal", i)
	for i in range(extras.size()):
		if not extras_enabled and bool(extras[i].get("secret", true)):
			continue
		_consider(best, pos, extras[i]["pos"], "extra", i)
	for i in range(rubbish.size()):
		_consider(best, pos, rubbish[i]["pos"], "trash", i)
	for i in range(fires.size()):
		_consider(best, pos, fires[i]["pos"], "fire", i)
	for i in range(fountains.size()):
		_consider(best, pos, fountains[i]["pos"], "water", i)
	for i in range(heal_items.size()):
		_consider(best, pos, heal_items[i]["pos"], "heal", i)
	_consider(best, pos, exit_position, "exit", -1)
	return best

func _consider(best: Dictionary, from: Vector2, to: Vector2, kind: String, index: int) -> void:
	var dist := from.distance_to(to)
	if dist <= best["distance"]:
		best["kind"] = kind
		best["index"] = index
		best["distance"] = dist

func remove_interaction(kind: String, index: int) -> void:
	if kind == "animal" and index >= 0 and index < animals.size():
		animals.remove_at(index)
	elif kind == "extra" and index >= 0 and index < extras.size():
		extras.remove_at(index)
	elif kind == "trash" and index >= 0 and index < rubbish.size():
		rubbish.remove_at(index)
	elif kind == "fire" and index >= 0 and index < fires.size():
		fires.remove_at(index)
	elif kind == "heal" and index >= 0 and index < heal_items.size():
		heal_items.remove_at(index)
	queue_redraw()

func douse_around(pos: Vector2, radius: float, limit: int) -> int:
	var extinguished := 0
	for i in range(fires.size() - 1, -1, -1):
		if extinguished >= limit:
			break
		if pos.distance_to(fires[i]["pos"]) <= radius:
			fires.remove_at(i)
			extinguished += 1
	if extinguished > 0:
		queue_redraw()
	return extinguished

func update_threats(delta: float, player_pos: Vector2, night: bool) -> void:
	if level == -1:
		return
	phase_clock += delta
	render_clock += delta
	damage_clock = maxf(0.0, damage_clock - delta)
	decay_clock += delta
	spread_clock += delta
	if decay_clock >= 10.0:
		decay_clock = 0.0
		if not fires.is_empty():
			var loss: int = maxi(1, int(ceil(float(fires.size()) / 2.0)) + difficulty)
			if level == 4:
				loss = maxi(1, loss - 1)
			forest_decay.emit(loss)
	if level != 4 and difficulty >= 1 and spread_clock >= (22.0 if difficulty == 1 else 14.0):
		spread_clock = 0.0
		if not fires.is_empty() and fires.size() < fire_target + 2 + difficulty:
			if _spread_one_fire():
				fire_spread.emit()
	for i in range(enemies.size()):
		var e: Dictionary = enemies[i]
		e["path_time"] -= delta
		e["contact_time"] = maxf(0.0, e["contact_time"] - delta)
		var current_pos: Vector2 = e["pos"]
		var dist := current_pos.distance_to(player_pos)
		var chasing := dist <= TILE * (7.0 + difficulty * 1.5)
		if e["path_time"] <= 0.0:
			e["path_time"] = 0.55 + rng.randf_range(0.0, 0.18)
			var goal: Vector2i
			if chasing:
				goal = world_cell(player_pos)
			else:
				var roam: Vector2 = e["roam"]
				if roam == Vector2.ZERO or current_pos.distance_to(roam) < TILE * 0.6:
					roam = cell_center(_random_walkable())
					e["roam"] = roam
				goal = world_cell(roam)
			var source := world_cell(current_pos)
			if floor_at(source) and floor_at(goal):
				e["path"] = astar.get_id_path(source, goal)
				e["step"] = 1
		var path: Array = e["path"]
		var cursor: int = e["step"]
		if cursor < path.size():
			var waypoint := cell_center(path[cursor])
			if current_pos.distance_to(waypoint) < 4.5:
				cursor += 1
				e["step"] = cursor
			if cursor < path.size():
				waypoint = cell_center(path[cursor])
				var speed := (76.0 if int(e["kind"]) == 0 else 57.0) * (0.88 + difficulty * 0.15)
				if night:
					speed *= 1.16
				var step: Vector2 = (waypoint - current_pos).normalized() * speed * delta
				e["pos"] = move_with_walls(current_pos, step, 8.5)
		if e["pos"].distance_to(player_pos) <= 22.0 and e["contact_time"] <= 0.0:
			e["contact_time"] = 1.3
			enemy_contact.emit("Caçador" if int(e["kind"]) == 0 else "Madeireiro")
		enemies[i] = e
	if level == 4 and boss_health > 0:
		_update_fire_wolf(delta, player_pos, night)
	if damage_clock <= 0.0:
		for fire in fires:
			if fire["pos"].distance_to(player_pos) <= 25.0:
				damage_clock = 1.35
				fire_contact.emit()
				break
	if render_clock >= 0.033:
		render_clock = 0.0
		queue_redraw()

func _spread_one_fire() -> bool:
	var attempts := 0
	while attempts < 30:
		attempts += 1
		var source: Vector2i = world_cell(fires[rng.randi_range(0, fires.size() - 1)]["pos"])
		var goal: Vector2i = source + DIRECTIONS[rng.randi_range(0, 3)]
		if not floor_at(goal):
			continue
		var pos := cell_center(goal)
		var busy := false
		for existing in fires:
			if existing["pos"].distance_to(pos) < TILE * 0.85:
				busy = true
				break
		if not busy and pos.distance_to(player_spawn) > TILE * 2.0:
			fires.append({"pos": pos})
			queue_redraw()
			return true
	return false

func _draw() -> void:
	if grid.is_empty():
		return
	# A geometria estática pertence ao TerrainLayer: nada de desenhar toda a mata a cada frame.
	_draw_exit(exit_position)
	for fountain in fountains:
		_draw_water(fountain["pos"])
	for medkit in heal_items:
		_draw_healing_plant(medkit["pos"])
	for trash in rubbish:
		_draw_trash(trash["pos"])
	for animal in animals:
		_draw_animal(animal["pos"], int(animal["kind"]))
	for item in extras:
		if not extras_enabled and bool(item.get("secret", true)):
			continue
		var center: Vector2 = item["pos"]
		var folder: String = "Memes" if bool(item.get("secret", true)) else "Mission"
		_pixel_sprite("Animals/%s/%s.png" % [folder, str(item["species"])], center, 36.0)
		draw_arc(center, 19.0, 0.0, TAU, 20, Color("#e9d478"), 1.8)
	for fire in fires:
		_draw_fire(fire["pos"])
	for enemy in enemies:
		_draw_enemy(enemy["pos"], int(enemy["kind"]))
	if level == 4 and boss_health > 0:
		_draw_fire_wolf(boss_position)

func _draw_exit(p: Vector2) -> void:
	draw_circle(p, 17.5, Color("#152d2b"))
	draw_arc(p, 16.0, 0.0, TAU, 32, Color("#d6e881"), 2.5)
	draw_rect(Rect2(p + Vector2(-10, -10), Vector2(5, 21)), Color("#eadca5"), true)
	draw_rect(Rect2(p + Vector2(5, -10), Vector2(5, 21)), Color("#eadca5"), true)
	draw_rect(Rect2(p + Vector2(-12, -13), Vector2(24, 5)), Color("#eadca5"), true)
	draw_circle(p + Vector2(0, -7), 3.3, Color("#b4e6b1"))

func _draw_water(p: Vector2) -> void:
	draw_circle(p + Vector2(0, 2), 15.0, Color("#122e38"))
	draw_circle(p, 12.0, Color("#67c8d9"))
	draw_arc(p, 7.5, 0.1, 3.0, 16, Color("#d1f7f2"), 2.3)
	draw_circle(p + Vector2(3, -4), 2.0, Color("#e4ffff"))

func _draw_healing_plant(p: Vector2) -> void:
	# Flor de cura original: cores contrastantes + leve pulso, sem luz invasiva.
	var glow: float = 12.0 + sin(phase_clock * 3.0) * 1.8
	draw_circle(p, glow + 4.0, Color(0.65, 0.99, 0.48, 0.19))
	_pixel_sprite("UI/Icons/heal.png", p - Vector2(0, 4), 33.0)
	draw_arc(p, 16.5, 0.0, TAU, 22, Color("#e7f4af"), 1.3)

func _heal_spot_is_safe(center: Vector2, player: Vector2) -> bool:
	if not can_occupy(center, 10.0):
		return false
	if center.distance_to(player) > TILE * 9.0:
		return false
	for fire: Dictionary in fires:
		if center.distance_to(Vector2(fire["pos"])) < 87.0:
			return false
	for enemy: Dictionary in enemies:
		if center.distance_to(Vector2(enemy["pos"])) < 96.0:
			return false
	if level == 4 and boss_health > 0 and center.distance_to(boss_position) < 115.0:
		return false
	for item: Dictionary in heal_items:
		if center.distance_to(Vector2(item["pos"])) < 36.0:
			return false
	return true

func spawn_emergency_heal(player: Vector2) -> bool:
	# BFS = apenas casas alcançáveis por caminhos reais, nunca atrás de uma parede.
	if heal_items.size() >= 1:
		return false
	var start: Vector2i = world_cell(player)
	if not floor_at(start):
		return false
	var open: Array[Vector2i] = [start]
	var seen: Dictionary = {}
	seen[start] = 0
	var cursor: int = 0
	var best: Vector2 = Vector2.ZERO
	var best_score: float = 1000000.0
	while cursor < open.size() and cursor < 240:
		var cell: Vector2i = open[cursor]
		cursor += 1
		var path_steps: int = int(seen[cell])
		if path_steps >= 2 and path_steps <= 9:
			var center: Vector2 = cell_center(cell)
			if _heal_spot_is_safe(center, player):
				var score: float = absf(float(path_steps) - 3.0) * 8.0 + center.distance_to(player) * 0.1
				if score < best_score:
					best = center
					best_score = score
		if path_steps >= 9:
			continue
		for direction: Vector2i in DIRECTIONS:
			var neighbor: Vector2i = cell + direction
			if floor_at(neighbor) and not seen.has(neighbor):
				seen[neighbor] = path_steps + 1
				open.append(neighbor)
	if best == Vector2.ZERO:
		return false
	heal_items.append({"pos": best})
	queue_redraw()
	return true

func _draw_trash(p: Vector2) -> void:
	draw_circle(p, 14, Color("#18272b"))
	draw_rect(Rect2(p + Vector2(-8, -7), Vector2(16, 18)), Color("#bbc1b1"), true)
	draw_rect(Rect2(p + Vector2(-10, -10), Vector2(20, 4)), Color("#e6e6c6"), true)
	draw_line(p + Vector2(-3, -3), p + Vector2(-3, 8), Color("#687f76"), 2.0)
	draw_line(p + Vector2(3, -3), p + Vector2(3, 8), Color("#687f76"), 2.0)

func _draw_animal(p: Vector2, kind: int) -> void:
	var species: String = animal_species(kind)
	_pixel_sprite("Animals/Mission/%s.png" % species, p + Vector2(0, -2), 38.0)
	draw_arc(p + Vector2(0, 0), 18.5, 0.0, TAU, 24, Color("#dfd78c"), 1.2)

func _draw_fire(p: Vector2) -> void:
	draw_circle(p, 17.5, Color(0.7, 0.25, 0.08, 0.22))
	var flame_sway: float = sin(phase_clock * 7.0 + p.x * 0.03) * 3.0
	var outer := PackedVector2Array([p + Vector2(-12, 13), p + Vector2(-11, -2), p + Vector2(-4 + flame_sway, -12), p + Vector2(1, -3), p + Vector2(5 - flame_sway, -18), p + Vector2(13, -1), p + Vector2(10, 13)])
	draw_colored_polygon(outer, Color("#f36f36"))
	var inner := PackedVector2Array([p + Vector2(-6, 12), p + Vector2(-5, -3), p + Vector2(0, 1), p + Vector2(4, -10), p + Vector2(7, 12)])
	draw_colored_polygon(inner, Color("#ffe17b"))

func _draw_enemy(p: Vector2, kind: int) -> void:
	_pixel_sprite("Enemies/%s/sprite.png" % ("hunter" if kind == 0 else "logger"), p + Vector2(0, -3), 39.0)

# Boss e ondas: permanecem no mesmo grafo AStar do labirinto.
func add_enemy_wave(amount: int) -> void:
	var used: Dictionary = {}
	for enemy in enemies:
		used[world_cell(enemy["pos"])] = true
	for i in range(amount):
		enemies.append({"pos": _pick_spawn(used, 6, 2), "kind": i % 2,
			"path": [], "step": 0, "path_time": 0.0, "contact_time": 0.0, "roam": Vector2.ZERO})
	queue_redraw()

func damage_fire_wolf(amount: int) -> bool:
	if boss_health <= 0:
		return false
	boss_health = maxi(0, boss_health - amount)
	var next_phase: int = 1
	if boss_health <= boss_max_health / 3:
		next_phase = 3
	elif boss_health <= boss_max_health * 2 / 3:
		next_phase = 2
	if next_phase != boss_phase and boss_health > 0:
		boss_phase = next_phase
		boss_stun_time = maxf(boss_stun_time, 2.5)
		boss_phase_changed.emit(boss_phase)
	queue_redraw()
	return boss_health == 0

func stun_fire_wolf(seconds: float = 2.6) -> void:
	if boss_health <= 0:
		return
	boss_stun_time = maxf(boss_stun_time, seconds)
	boss_warning_time = 0.0
	boss_fire_clock = 0.0
	boss_target_position = Vector2.ZERO
	queue_redraw()

func _boss_spawn_fire() -> void:
	var fire_limit: int = 3 + clampi(difficulty, 0, 2)
	if fires.size() >= fire_limit:
		return
	var candidates: Array[Vector2i] = []
	if boss_target_position != Vector2.ZERO:
		candidates.append(world_cell(boss_target_position))
	for direction: Vector2i in DIRECTIONS:
		candidates.append(world_cell(boss_position) + direction * 2)
	for candidate: Vector2i in candidates:
		if not floor_at(candidate):
			continue
		var place: Vector2 = cell_center(candidate)
		if place.distance_to(player_spawn) < TILE * 3.0:
			continue
		var safe: bool = true
		for fire: Dictionary in fires:
			if Vector2(fire["pos"]).distance_to(place) < TILE * 1.3:
				safe = false
				break
		if safe:
			fires.append({"pos": place})
			fire_spread.emit()
			queue_redraw()
			return

func _update_fire_wolf(delta: float, player: Vector2, at_night: bool) -> void:
	boss_contact_clock = maxf(0.0, boss_contact_clock - delta)
	if boss_stun_time > 0.0:
		boss_stun_time = maxf(0.0, boss_stun_time - delta)
		boss_fire_clock = 0.0
		return
	if boss_warning_time > 0.0:
		boss_warning_time = maxf(0.0, boss_warning_time - delta)
		if boss_warning_time == 0.0:
			_boss_spawn_fire()
			boss_target_position = Vector2.ZERO
		return
	boss_chase_clock -= delta
	boss_fire_clock += delta
	if boss_chase_clock <= 0.0:
		boss_chase_clock = 0.8 if boss_phase == 3 else 1.0
		var source: Vector2i = world_cell(boss_position)
		var target: Vector2i = world_cell(player)
		if floor_at(source) and floor_at(target):
			boss_path = astar.get_id_path(source, target)
			boss_step = 1
	if boss_step < boss_path.size():
		var waypoint: Vector2 = cell_center(boss_path[boss_step])
		if boss_position.distance_to(waypoint) < 6.0:
			boss_step += 1
		if boss_step < boss_path.size():
			waypoint = cell_center(boss_path[boss_step])
			var wolf_speed: float = (40.0 + float(boss_phase - 1) * 5.0 + difficulty * 5.0)
			boss_position = move_with_walls(boss_position, (waypoint - boss_position).normalized() * wolf_speed * delta, 9.0)
	if boss_contact_clock <= 0.0 and boss_position.distance_to(player) < 29.0:
		boss_contact_clock = 2.1
		enemy_contact.emit("Lobo de Fogo")
	var interval: float = 17.0 - float(boss_phase - 1) * 2.0 - float(difficulty) * 1.2
	if at_night:
		interval *= 0.94
	if boss_fire_clock >= interval:
		boss_fire_clock = 0.0
		boss_warning_time = maxf(1.8, 2.8 - float(difficulty) * 0.3)
		boss_target_position = cell_center(world_cell(player))
		boss_warning.emit()
func _draw_fire_wolf(p: Vector2) -> void:
	var pulse: float = sin(phase_clock * 5.0) * 3.0
	var stunned: bool = boss_stun_time > 0.0
	draw_circle(p, 31.0 + pulse, Color(0.28, 0.85, 0.72, 0.28) if stunned else Color(1.0, 0.26, 0.08, 0.27))
	if boss_warning_time > 0.0 and boss_target_position != Vector2.ZERO:
		# Aviso no chão por quase 3 s: o jogador vê a zona de impacto e pode escapar.
		draw_circle(boss_target_position, 21.0, Color(0.82, 0.36, 0.14, 0.13))
		draw_arc(boss_target_position, 23.0, 0.0, TAU, 32, Color("#dda15e"), 2.5)
	if boss_warning_time > 0.0:
		draw_arc(p, 37.0 + sin(phase_clock * 11.0) * 3.0, 0.0, TAU, 36, Color("#ffcd76"), 3.0)
	if stunned:
		draw_arc(p, 35.0, 0.0, TAU, 32, Color("#86efdb"), 2.4)
	_pixel_sprite("Enemies/FireWolf/lobo_de_fogo.png", p + Vector2(0, -8), 71.0)
