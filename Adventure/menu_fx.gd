extends Control
## Fundo de floresta em pixel art original, com vaga-lumes suaves.
const BACKDROP = preload("res://Assets/UI/Panels/menu_forest.png")
var time_passed: float = 0.0
var reduced_motion: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(delta: float) -> void:
	if not reduced_motion:
		time_passed += delta
	queue_redraw()

func _draw() -> void:
	if size.x < 10.0 or size.y < 10.0:
		return
	draw_texture_rect(BACKDROP, Rect2(Vector2.ZERO, size), false)
	if reduced_motion:
		return
	for i in range(27):
		var x: float = fposmod(float(i * 173) + sin(time_passed * (0.38 + float(i % 4) * 0.08) + float(i)) * 34.0, size.x)
		var y: float = fposmod(float(i * 263) - time_passed * (6.0 + float(i % 5)), size.y * 0.88)
		var alpha: float = 0.25 + (sin(time_passed * 2.3 + float(i) * 1.4) + 1.0) * 0.22
		draw_rect(Rect2(x, y, 3.0, 3.0), Color(0.91, 0.97, 0.62, alpha), true)
