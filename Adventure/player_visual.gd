extends Node2D
## Guardiões em sprites autorais, com animação de respiração e caminhada.
const HERO_TEXTURES = [
	preload("res://Assets/Characters/Leo/guardiao.png"),
	preload("res://Assets/Characters/Helena/guardiao.png"),
	preload("res://Assets/Characters/Rafael/guardiao.png"),
	preload("res://Assets/Characters/Clara/guardiao.png")
]
var hero: int = 0
var direction: Vector2 = Vector2.DOWN
var moving: bool = false
var powered: bool = false
var clock: float = 0.0
var damage_glow: float = 0.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(delta: float) -> void:
	clock += delta
	damage_glow = maxf(0.0, damage_glow - delta)
	queue_redraw()

func hit_flash() -> void:
	damage_glow = 0.14
	queue_redraw()

func _draw() -> void:
	var shift: float = sin(clock * 12.0) * 2.0 if moving else sin(clock * 2.5) * 0.5
	draw_ellipse_shadow()
	if powered:
		draw_arc(Vector2(0, -3), 22.0 + sin(clock * 8.0) * 2.0, 0.0, TAU, 24, Color("#d6f48d"), 2.4)
	var texture: Texture2D = HERO_TEXTURES[clampi(hero, 0, 3)]
	draw_texture_rect(texture, Rect2(-23, -32 + shift, 46, 46), false)
	if damage_glow > 0.0:
		# Silhueta branca breve, legível sem flash de tela excessivo.
		draw_circle(Vector2(0, -9 + shift), 19.0, Color(1.0, 1.0, 0.93, minf(0.42, damage_glow * 3.0)))
	# Pequena direção no chão; não compete com o personagem.
	if moving:
		draw_circle(direction.normalized() * 17 + Vector2(0, 4), 2.4, Color("#dbdfb7"))

func draw_ellipse_shadow() -> void:
	draw_circle(Vector2(0, 12), 11.0, Color(0.03, 0.11, 0.08, 0.4))
