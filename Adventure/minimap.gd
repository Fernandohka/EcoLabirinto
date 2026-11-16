extends Control
## Minimap simples, alimentado pelo estado do mundo atual.
var world
var player_pos := Vector2.ZERO
var night := false

func set_data(new_world: Node2D, new_pos: Vector2, new_night: bool) -> void:
	world = new_world
	player_pos = new_pos
	night = new_night
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#111816"), true)
	if not is_instance_valid(world) or world.width <= 0:
		return
	var scale_x: float = (size.x - 12.0) / float(world.width)
	var scale_y: float = (size.y - 12.0) / float(world.height)
	var tile := Vector2(scale_x, scale_y)
	for y in range(world.height):
		for x in range(world.width):
			if world.grid[y][x] == 1:
				draw_rect(Rect2(Vector2(6 + x * scale_x, 6 + y * scale_y), tile + Vector2(0.3, 0.3)), Color("#3a5a40") if not night else Color("#344b49"), true)
	_draw_point(world.exit_position, Color("#dda15e"), scale_x, scale_y, 3.6)
	for animal in world.animals:
		_draw_point(animal["pos"], Color("#a3b18a"), scale_x, scale_y, 2.4)
	for fire in world.fires:
		_draw_point(fire["pos"], Color("#bc6c25"), scale_x, scale_y, 2.3)
	for waste in world.rubbish:
		_draw_point(waste["pos"], Color("#dad7cd"), scale_x, scale_y, 2.2)
	for fountain in world.fountains:
		_draw_point(fountain["pos"], Color("#8ae9ef"), scale_x, scale_y, 2.5)
	for medicinal in world.heal_items:
		_draw_point(medicinal["pos"], Color("#aeff69"), scale_x, scale_y, 3.4)
	if world.level == 4 and world.boss_health > 0:
		_draw_point(world.boss_position, Color("#ff5647"), scale_x, scale_y, 4.8)
	_draw_point(player_pos, Color.WHITE, scale_x, scale_y, 3.8)

func _draw_point(pos: Vector2, color: Color, sx: float, sy: float, radius: float) -> void:
	var c := Vector2(6.0 + pos.x / float(40) * sx, 6.0 + pos.y / float(40) * sy)
	draw_circle(c, radius, color)
