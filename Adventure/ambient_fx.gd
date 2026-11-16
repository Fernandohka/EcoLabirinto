extends Node2D
## Efeitos leves, desenhados em uma camada independente do terreno e do mapa procedural.
var biome: int = 0
var reduced_motion: bool = false
var night: bool = false
var clock: float = 0.0
var refresh: float = 0.0

func _process(delta: float) -> void:
	if not visible or reduced_motion:
		return
	clock += delta
	refresh -= delta
	if refresh <= 0.0:
		refresh = 0.09
		queue_redraw()

func _draw() -> void:
	if reduced_motion:
		return
	var green: Color = Color("#a3b18a")
	var amber: Color = Color("#dda15e")
	var sage: Color = green if biome != 4 else amber
	# Movimentos sutis; as partículas não possuem colisões nem dependem da seed.
	for i in range(18):
		var t: float = float(i)
		var x: float = sin(clock * (0.27 + float(i % 4) * 0.06) + t * 1.83) * 240.0
		var y: float = cos(clock * 0.19 + t * 1.29) * 175.0 - sin(clock * 0.62 + t) * 13.0
		var c: Color = (amber if night and i % 4 == 0 else sage)
		c.a = 0.16 + 0.10 * (sin(clock + t) + 1.0)
		draw_rect(Rect2(Vector2(x, y), Vector2(2.0, 2.0)), c, true)
