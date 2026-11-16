extends Node2D
## Camada estática: chão, árvores, bordas e rochas desenhados só quando o mapa é gerado.
## Inimigos, incêndios e animações pertencem a world.gd e não invalidam esta camada.
const Art = preload("res://Adventure/theme_palette.gd")
const TILE: int = 40
const BIOME_FOLDERS: Array[String] = ["Amazonia", "Cerrado", "Pantanal", "MataAtlantica", "Boss"]
var grid: Array = []
var map_width: int = 0
var map_height: int = 0
var biome_index: int = 0
var seed_hash: int = 0
var textures: Dictionary = {}
var rebuild_count: int = 0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = -2

func rebuild(source: Node2D) -> void:
	grid = source.get("grid").duplicate(true)
	map_width = int(source.get("width"))
	map_height = int(source.get("height"))
	biome_index = clampi(int(source.get("level")), 0, 4)
	seed_hash = str(source.get("seed_code")).hash()
	rebuild_count += 1
	queue_redraw()

func _sprite(relative_path: String, center: Vector2, size: float) -> void:
	if not textures.has(relative_path):
		textures[relative_path] = load("res://Assets/" + relative_path)
	var texture: Texture2D = textures[relative_path] as Texture2D
	if texture != null:
		draw_texture_rect(texture, Rect2(center - Vector2.ONE * size * 0.5, Vector2.ONE * size), false)

func _draw() -> void:
	if grid.is_empty():
		return
	var colors: Array = Art.BIOME_COLORS[biome_index]
	var biome: String = BIOME_FOLDERS[biome_index]
	draw_rect(Rect2(-400.0, -400.0, map_width * TILE + 800.0, map_height * TILE + 800.0), colors[3], true)
	for y in range(-8, map_height + 8):
		for x in range(-8, map_width + 8):
			if x >= 0 and x < map_width and y >= 0 and y < map_height:
				continue
			var p: Vector2 = Vector2(float(x * TILE + 20), float(y * TILE + 20))
			var kind: int = posmod(x * 13 + y * 7 + seed_hash, 3) + 1
			_sprite("Biomes/%s/Trees/arvore_%d.png" % [biome, kind], p, 45.0)
	for y in range(map_height):
		for x in range(map_width):
			var center: Vector2 = Vector2(float(x * TILE + 20), float(y * TILE + 20))
			var rect: Rect2 = Rect2(float(x * TILE), float(y * TILE), TILE, TILE)
			var variation: int = posmod(x * 13 + y * 41 + x * y * 7 + seed_hash, 9)
			if grid[y][x] == 1:
				draw_rect(rect, colors[0] if variation < 4 else colors[1], true)
				if variation <= 3:
					_sprite("Biomes/%s/Ground/detalhe_%d.png" % [biome, variation % 3 + 1], center, 38.0)
				if biome_index == 2 and variation == 5:
					draw_rect(Rect2(rect.position + Vector2(4.0, 6.0), Vector2(30.0, 24.0)), Color("#4d817b"), true)
			else:
				draw_rect(rect, colors[3], true)
				_sprite("Biomes/%s/Trees/arvore_%d.png" % [biome, variation % 3 + 1], center, 44.0)
