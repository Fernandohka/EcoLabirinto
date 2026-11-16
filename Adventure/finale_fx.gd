extends Control
## Cena final: quatro guardiões lançam água; o incêndio diminui e a mata renasce.
var t: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _process(delta: float) -> void:
	t = minf(t + delta, 6.0)
	queue_redraw()

func _draw() -> void:
	var center: Vector2 = size * Vector2(0.5, 0.47)
	var progress: float = clampf(t / 4.5, 0.0, 1.0)
	var fire_radius: float = 95.0 * (1.0 - progress) + 9.0
	for i in range(20):
		var side: float = -1.0 if i % 2 == 0 else 1.0
		var x: float = center.x + sin(float(i) * 2.13) * fire_radius * 0.72
		var y: float = center.y - fire_radius * 0.6 + sin(float(i) * 3.17 + t * 5.0) * fire_radius * 0.4
		var flame_col: Color = Color(1.0, 0.25 + float(i % 3) * 0.2, 0.06, 0.72 * (1.0 - progress))
		draw_circle(Vector2(x + side * 4.0, y), 8.0 + float(i % 3) * 5.0, flame_col)
	# Água convergindo dos quatro cantos, enquanto o fogo cede.
	var sentries: Array[Vector2] = [
		Vector2(center.x - 290.0, center.y - 160.0),
		Vector2(center.x + 290.0, center.y - 160.0),
		Vector2(center.x - 290.0, center.y + 140.0),
		Vector2(center.x + 290.0, center.y + 140.0)
	]
	var colors: Array[Color] = [Color("#cfb67c"), Color("#8ed99b"), Color("#76cade"), Color("#e69eb7")]
	for j in range(4):
		var p: Vector2 = sentries[j]
		draw_circle(p, 24.0, colors[j].darkened(0.4))
		draw_circle(p, 15.0, colors[j])
		draw_circle(p + Vector2(-5, -3), 2, Color("#142526"))
		draw_circle(p + Vector2(5, -3), 2, Color("#142526"))
		var step: float = fposmod(t * 0.68 + float(j) * 0.18, 1.0)
		for k in range(8):
			var pos: Vector2 = p.lerp(center, fposmod(step + float(k) * 0.13, 1.0))
			draw_circle(pos, 4.0 + float(k % 2), Color(0.4, 0.86, 1.0, 0.80))
	if progress > 0.6:
		var growth: float = (progress - 0.6) / 0.4
		for k in range(12):
			var px: float = center.x - 190.0 + float(k) * 35.0
			var base_y: float = center.y + 110.0
			var ht: float = growth * (38.0 + float(k % 4) * 11.0)
			draw_line(Vector2(px, base_y), Vector2(px, base_y - ht), Color("#6fa866"), 4.0)
			draw_circle(Vector2(px, base_y - ht), 9.0 + growth * 8.0, Color("#7dca87"))
