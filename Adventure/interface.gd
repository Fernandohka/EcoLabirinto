extends CanvasLayer
## Interface de apresentação, menus, HUD, avisos cinematográficos e placar.
signal selected(action: String, value: int)

const MiniMapScript = preload("res://Adventure/minimap.gd")
const ForestFX = preload("res://Adventure/menu_fx.gd")
const FinaleFX = preload("res://Adventure/finale_fx.gd")
const ScoreStore = preload("res://Adventure/score_store.gd")
const CollectionStore = preload("res://Adventure/collection_store.gd")
const ArtCatalog = preload("res://Adventure/art_catalog.gd")
const Palette = preload("res://Adventure/theme_palette.gd")
const DARK = Palette.SHADOW
const PANEL = Palette.MOSS
const WHITE = Palette.IVORY
const MUTED = Palette.SAGE
const LIME = Palette.SAGE
const MINT = Palette.LEAF
const RED = Color("#d77964")
const GOLD = Palette.OCHRE
const HERO_NAMES = ["LÉO", "HELENA", "RAFAEL", "CLARA"]
const DIFF_NAMES = ["FÁCIL", "MÉDIO", "DIFÍCIL"]
const MODE_NAMES = ["CAMPANHA", "CONTRA O RELÓGIO", "SOBREVIVÊNCIA"]
const BIOMES = ["AMAZÔNIA", "CERRADO", "PANTANAL", "MATA ATLÂNTICA", "LOBO DE FOGO"]
const ANIMAL_NAMES = ["arara", "preguica", "macaco", "sapo", "tatu", "tamandua", "lobo_guara", "capivara", "jacare", "tuiuiu", "onca", "mico", "tucano", "quati", "peixe_boi"]
const SECRET_NAMES = ["sapo_chapeu", "capivara_oculos", "tatu_dourado", "sapo_azul"]
const PORTRAITS = ["Leo", "Helena", "Rafael", "Clara"]

var menu_panel: PanelContainer
var showcase_panel: PanelContainer
var hud_side: PanelContainer
var overlay: Control
var menu_art: Control
var showcase_title: Label
var showcase_subtitle: Label
var showcase_portraits: HBoxContainer
var showcase_boss: TextureRect
var menu_box: VBoxContainer
var menu_scroll: ScrollContainer
var hud_root: Control
var portrait: TextureRect
var health_bar: ProgressBar
var energy_bar: ProgressBar
var forest_bar: ProgressBar
var water_label: Label
var hero_label: Label
var collection_label: Label
var collection_filter: int = 0
var total_collection_entries: int = 19
var memes_enabled: bool = true
var reduced_motion: bool = false
var sound_enabled: bool = true
var prefs: ConfigFile = ConfigFile.new()
var stage_label: Label
var vita_label: Label
var forest_label: Label
var missions_label: Label
var map
var power_bar: ProgressBar
var power_label: Label
var power_hint: Label
var context_label: Label
var notice_label: Label
var tutorial_label: Label
var clock_label: Label
var seed_label: Label
var boss_bar: ProgressBar
var boss_label: Label
var hit_rect: ColorRect
var scene_announcement: Label
var announcement_back: ColorRect
var scene_subtitle: Label
var notice_panel: PanelContainer
var mission_trash_label: Label
var mission_fire_label: Label
var attempts_label: Label
var detail_panel: PanelContainer
var detail_text: Label
var campaign_attempts_remaining: int = 4
var cinematic_overlay: Control
var cinematic_label: Label
var cinematic_subtitle: Label
var score_filter_mode: int = 0
var score_filter_diff: int = 1
var score_filter_stage: int = -1
var current_mode: int = 0
var current_diff: int = 1
var current_stage: int = 0
var seed_entry: LineEdit
var requested_seed: String = "ECO-2026"
var last_notice: float = 0.0
var announcement_tween: Tween

func _ready() -> void:
	prefs.load("user://ecolabirinto_opcoes.cfg")
	memes_enabled = bool(prefs.get_value("visual", "memes", true))
	total_collection_entries = ANIMAL_NAMES.size() + ArtCatalog.meme_names().size()
	reduced_motion = bool(prefs.get_value("visual", "reduced_motion", false))
	sound_enabled = bool(prefs.get_value("audio", "enabled", true))
	layer = 10
	_build_overlay()
	_build_hud()
	_build_effects()
	get_viewport().size_changed.connect(_reflow_ui)
	_reflow_ui()
	show_screen("main")

func _reflow_ui() -> void:
	if not is_instance_valid(menu_panel) or not is_instance_valid(hud_side):
		return
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var available_width: float = maxf(700.0, viewport_size.x)
	var available_height: float = maxf(560.0, viewport_size.y)
	var menu_width: float = minf(580.0, maxf(430.0, available_width * 0.46))
	# Menus longos podem rolar; os curtos ficam agrupados sem um painel gigante.
	# A interface usa 1280x720 como referência, mas se adapta às janelas menores.
	var menu_height: float = minf(available_height - 36.0, 620.0)
	menu_panel.position = Vector2(24.0, maxf(16.0, (available_height - menu_height) * 0.5))
	menu_panel.custom_minimum_size = Vector2.ZERO
	menu_panel.size = Vector2(menu_width, menu_height)
	showcase_panel.visible = available_width >= 1090.0
	if showcase_panel.visible:
		showcase_panel.position = Vector2(menu_width + 45.0, available_height - 214.0)
		showcase_panel.custom_minimum_size = Vector2.ZERO
		showcase_panel.size = Vector2(maxf(270.0, available_width - menu_width - 75.0), 167.0)
	hud_side.offset_left = -252.0
	hud_side.offset_right = 0.0
	# Menus podem rolar; a HUD de jogo jamais cria ScrollContainer.

func _process(delta: float) -> void:
	if last_notice > 0.0:
		last_notice -= delta
		if last_notice <= 0.0:
			notice_label.text = ""
			if is_instance_valid(notice_panel):
				notice_panel.visible = false

func _style(bg: Color, edge: Color = Color("#588157"), pad: int = 11, radius: int = 10) -> StyleBoxFlat:
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = edge
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	s.content_margin_left = pad
	s.content_margin_right = pad
	s.content_margin_top = pad
	s.content_margin_bottom = pad
	return s

func _label(txt: String, sz: int, tint: Color = WHITE, center: bool = true) -> Label:
	var l: Label = Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", tint)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if center else HORIZONTAL_ALIGNMENT_LEFT
	# IMPORTANT: do not trim every Label globally. In Godot 4.7 this can
	# collapse text in ScrollContainer / Container before the first layout pass.
	# Short HUD labels are clipped deliberately in _hud_text instead.
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func _spacer(height: float = 10.0) -> Control:
	var s: Control = Control.new()
	s.custom_minimum_size = Vector2(0.0, height)
	return s

func _button(txt: String, action: String, value: int = -1, strong: bool = false) -> Button:
	var b: Button = Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(0, 43)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 16)
	b.clip_text = true
	b.add_theme_color_override("font_color", DARK if strong else WHITE)
	b.add_theme_color_override("font_hover_color", DARK)
	b.add_theme_stylebox_override("normal", _style(LIME if strong else Color("#304b39"), LIME if strong else Color("#588157"), 9, 11))
	b.add_theme_stylebox_override("hover", _style(Color("#dad7cd"), MINT, 9, 11))
	b.add_theme_stylebox_override("pressed", _style(Color("#a3b18a"), LIME, 9, 11))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.pressed.connect(_forward_action.bind(action, value))
	return b

func _forward_action(action: String, value: int) -> void:
	if action == "collection_filter":
		collection_filter = value
		show_screen("collection")
		return
	if action == "toggle_memes":
		memes_enabled = not memes_enabled
		_save_prefs()
		if is_instance_valid(menu_art):
			menu_art.set("reduced_motion", reduced_motion)
		show_screen("settings")
		return
	if action == "toggle_sound":
		sound_enabled = not sound_enabled
		_save_prefs()
		show_screen("settings")
		return
	if action == "toggle_motion":
		reduced_motion = not reduced_motion
		_save_prefs()
		if is_instance_valid(menu_art):
			menu_art.set("reduced_motion", reduced_motion)
		show_screen("settings")
		return
	if action == "toggle_fullscreen":
		var fullscreen: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN)
		show_screen("settings")
		return
	if action == "score_filter_mode":
		score_filter_mode = value
		score_filter_stage = -1
		show_screen("scores")
		return
	if action == "score_filter_diff":
		score_filter_diff = value
		show_screen("scores")
		return
	if action == "score_filter_stage":
		score_filter_stage = value
		show_screen("scores")
		return
	if action == "new_seed":
		requested_seed = "ECO-%06d" % (randi() % 1000000)
		if is_instance_valid(seed_entry):
			seed_entry.text = requested_seed
		return
	if action == "seed_confirm" and is_instance_valid(seed_entry):
		requested_seed = seed_entry.text.strip_edges()
		if requested_seed == "":
			requested_seed = "ECO-2026"
	selected.emit(action, value)

func _save_prefs() -> void:
	prefs.set_value("visual", "memes", memes_enabled)
	prefs.set_value("visual", "reduced_motion", reduced_motion)
	prefs.set_value("audio", "enabled", sound_enabled)
	prefs.save("user://ecolabirinto_opcoes.cfg")

func set_configuration(mode: int, diff: int, stage: int) -> void:
	current_mode = mode
	current_diff = diff
	current_stage = stage

func get_seed() -> String:
	return requested_seed

func _sprite_box(path: String, side: float = 48.0) -> TextureRect:
	var image: TextureRect = TextureRect.new()
	image.texture = load(path) as Texture2D
	image.custom_minimum_size = Vector2(side, side)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return image

func _build_overlay() -> void:
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	menu_art = ForestFX.new()
	menu_art.set("reduced_motion", reduced_motion)
	overlay.add_child(menu_art)
	var tint: ColorRect = ColorRect.new()
	tint.color = Color(0.04, 0.07, 0.055, 0.29)
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(tint)
	# Menu fixo à esquerda; floresta com arte própria fica visível ao lado.
	var panel: PanelContainer = PanelContainer.new()
	menu_panel = panel
	panel.position = Vector2(28, 28)
	panel.custom_minimum_size = Vector2(565, 650)
	panel.add_theme_stylebox_override("panel", _style(Color(0.07, 0.12, 0.10, 0.96), Color("#a3b18a"), 15, 11))
	overlay.add_child(panel)
	menu_scroll = ScrollContainer.new()
	menu_scroll.custom_minimum_size = Vector2.ZERO
	menu_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	menu_scroll.follow_focus = true
	panel.add_child(menu_scroll)
	menu_box = VBoxContainer.new()
	menu_box.custom_minimum_size = Vector2.ZERO
	menu_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_box.add_theme_constant_override("separation", 9)
	menu_scroll.add_child(menu_box)
	# Cartão de identidade da floresta, junto da arte e fora do menu clicável.
	var aside: PanelContainer = PanelContainer.new()
	showcase_panel = aside
	aside.position = Vector2(694, 479)
	aside.custom_minimum_size = Vector2(515, 160)
	aside.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aside.add_theme_stylebox_override("panel", _style(Color(0.035, 0.13, 0.13, 0.81), Color("#628c6b"), 12, 9))
	overlay.add_child(aside)
	var inside: VBoxContainer = VBoxContainer.new()
	inside.add_theme_constant_override("separation", 5)
	aside.add_child(inside)
	showcase_title = _label("UMA AVENTURA 100% BRASILEIRA", 19, LIME)
	showcase_title.custom_minimum_size.y = 27.0
	showcase_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	showcase_subtitle = _label("AMAZÔNIA   •   CERRADO   •   PANTANAL   •   MATA ATLÂNTICA", 13, WHITE)
	showcase_subtitle.custom_minimum_size.y = 20.0
	showcase_subtitle.autowrap_mode = TextServer.AUTOWRAP_OFF
	inside.add_child(showcase_title)
	inside.add_child(showcase_subtitle)
	showcase_portraits = HBoxContainer.new()
	showcase_portraits.alignment = BoxContainer.ALIGNMENT_CENTER
	showcase_portraits.add_theme_constant_override("separation", 19)
	inside.add_child(showcase_portraits)
	for person in PORTRAITS:
		showcase_portraits.add_child(_sprite_box("res://Assets/Characters/%s/guardiao.png" % person, 65.0))
	showcase_boss = _sprite_box("res://Assets/Enemies/FireWolf/lobo_de_fogo.png", 90.0)
	showcase_boss.visible = false
	inside.add_child(showcase_boss)

func _clear_menu() -> void:
	seed_entry = null
	for child in menu_box.get_children():
		menu_box.remove_child(child)
		child.queue_free()
	menu_scroll.scroll_vertical = 0

func _add_title(kicker: String, header: String, body: String) -> void:
	# Reserve explicit heights; short menu labels must never collapse to zero.
	var eyebrow: Label = _label("✦  " + kicker + "  ✦", 14, MINT)
	eyebrow.autowrap_mode = TextServer.AUTOWRAP_OFF
	eyebrow.custom_minimum_size.y = 23.0
	menu_box.add_child(eyebrow)
	var heading: Label = _label(header, 30, LIME)
	heading.autowrap_mode = TextServer.AUTOWRAP_OFF
	heading.custom_minimum_size.y = 46.0
	menu_box.add_child(heading)
	var subtitle: Label = _label(body, 15, MUTED)
	subtitle.custom_minimum_size.y = 27.0
	menu_box.add_child(subtitle)
	menu_box.add_child(_spacer(4.0))

func _add_note(txt: String, tone: Color = MUTED) -> void:
	var box: PanelContainer = PanelContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_stylebox_override("panel", _style(Color("#263d32"), Color("#588157"), 10, 10))
	var text_label: Label = _label(txt, 14, tone)
	text_label.custom_minimum_size.y = float(txt.count("\n") + 1) * 21.0
	box.add_child(text_label)
	menu_box.add_child(box)

func _add_section(txt: String) -> void:
	var sep: HSeparator = HSeparator.new()
	menu_box.add_child(sep)
	menu_box.add_child(_label(txt, 15, LIME, false))

func show_screen(screen: String, detail: String = "") -> void:
	_clear_menu()
	overlay.visible = screen != "playing"
	hud_root.visible = screen == "playing" or screen == "pause"
	if is_instance_valid(detail_panel):
		detail_panel.visible = false
	_update_showcase(screen)
	match screen:
		"main":
			_add_title("ODS 15  •  VIDA TERRESTRE", "ECO LABIRINTO", "GUARDIÕES DA FLORESTA")
			_add_note("Uma aventura 2D por quatro biomas brasileiros.\nProteja a vida, enfrente as ameaças e sobreviva ao Lobo de Fogo.", WHITE)
			menu_box.add_child(_spacer(7.0))
			menu_box.add_child(_button("▶  COMEÇAR AVENTURA", "play", -1, true))
			menu_box.add_child(_button("◇  COMO JOGAR", "help"))
			menu_box.add_child(_button("▣  BESTIÁRIO E SEGREDOS", "collection"))
			menu_box.add_child(_button("★  PLACAR DE RECORDES", "scores"))
			menu_box.add_child(_button("⚙  CONFIGURAÇÕES", "settings"))
			menu_box.add_child(_button("×  SAIR", "quit"))
		"help":
			_add_title("GUIA DO GUARDIÃO", "COMO JOGAR", "Um guia rápido, sem textos escondidos")
			_add_note("W A S D / SETAS   •   MOVIMENTAR\nSHIFT   •   CORRER (gasta energia)\nE   •   INTERAGIR COM O OBJETO PRÓXIMO\nESPAÇO   •   PODER ESPECIAL\nESC   •   PAUSAR A AVENTURA", WHITE)
			_add_section("OBJETIVOS")
			_add_note("● ANIMAIS: aproxime-se e resgate.\n◆ LIXO: recolha para recuperar a floresta.\n▲ FOGO: apague com água.\n◉ FONTE AZUL: encha seu cantil.\n✦ PORTAL: conclua a fase após cumprir a missão.", WHITE)
			_add_section("ALERTAS E PONTUAÇÃO")
			_add_note("Se a vida ficar crítica, surge uma flor medicinal próxima: aproxime-se e toque nela para recuperar HP. TAB abre detalhes sem continuar o tempo. Na campanha, são 4 tentativas no total. Ações ambientais enfraquecem o Lobo de Fogo.")
			menu_box.add_child(_button("←  VOLTAR", "back_pause" if detail == "pause" else "back_main", -1, true))
		"modes":
			_add_title("ESCOLHA A EXPERIÊNCIA", "MODOS DE JOGO", "Três jeitos de viver a floresta")
			menu_box.add_child(_button("▶  CAMPANHA  •  4 BIOMAS + LOBO DE FOGO", "mode", 0, true))
			_add_note("Quatro tentativas para toda a campanha. Recomeçar custa uma vida. O tempo segue contando entre as tentativas.")
			menu_box.add_child(_button("◷  CONTRA O RELÓGIO  •  ESCOLHA UMA FASE", "mode", 1))
			_add_note("Melhor tempo em um bioma, com seed para repetir exatamente o mapa inicial.")
			menu_box.add_child(_button("∞  SOBREVIVÊNCIA  •  ONDAS SEM FIM", "mode", 2))
			_add_note("Novos inimigos aparecem; sobreviva o máximo possível para bater seu recorde.")
			menu_box.add_child(_button("←  VOLTAR", "back_main"))
		"difficulty":
			_add_title("AJUSTE O DESAFIO", "DIFICULDADE", MODE_NAMES[current_mode])
			menu_box.add_child(_button("○  FÁCIL  •  Menos inimigos, fogo controlado", "difficulty", 0, true))
			menu_box.add_child(_button("◐  MÉDIO  •  Perigos equilibrados", "difficulty", 1))
			menu_box.add_child(_button("●  DIFÍCIL  •  Ameaças mais intensas", "difficulty", 2))
			menu_box.add_child(_button("←  VOLTAR", "back_modes"))
		"stage_select":
			_add_title("DESAFIO CONTRA O TEMPO", "ESCOLHA O BIOMA", "Um mapa procedural diferente para cada seed")
			for i in range(5):
				var prefix: String = "♠" if i == 4 else "◇"
				menu_box.add_child(_button("%s  FASE %d  •  %s" % [prefix, i + 1, BIOMES[i]], "stage", i, i == 0))
			menu_box.add_child(_button("←  VOLTAR", "back_difficulty"))
		"characters":
			_add_title("QUATRO GUARDIÕES", "ESCOLHA SEU HERÓI", "Poder especial com recarga • ESPAÇO")
			var heroes: GridContainer = GridContainer.new()
			heroes.columns = 2
			heroes.add_theme_constant_override("h_separation", 9)
			heroes.add_theme_constant_override("v_separation", 9)
			menu_box.add_child(heroes)
			for hero_id in range(4):
				var tile: PanelContainer = PanelContainer.new()
				tile.custom_minimum_size = Vector2(0, 150)
				tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				tile.add_theme_stylebox_override("panel", _style(Color("#285047"), Color("#7f9c79"), 6, 8))
				heroes.add_child(tile)
				var contents: VBoxContainer = VBoxContainer.new()
				contents.add_theme_constant_override("separation", 3)
				tile.add_child(contents)
				var image_row: HBoxContainer = HBoxContainer.new()
				image_row.alignment = BoxContainer.ALIGNMENT_CENTER
				contents.add_child(image_row)
				image_row.add_child(_sprite_box("res://Assets/Characters/%s/guardiao.png" % PORTRAITS[hero_id], 65.0))
				contents.add_child(_label(["⚡ CORRIDA", "✦ APAGAR FOGO", "✚ CURAR VIDA", "◉ MAIS ÁGUA"][hero_id], 12, MINT))
				var choose: Button = _button("▶ " + HERO_NAMES[hero_id], "hero", hero_id, hero_id == 0)
				choose.custom_minimum_size = Vector2(0, 37)
				choose.add_theme_font_size_override("font_size", 15)
				contents.add_child(choose)
			_add_note("A seed determina o mundo; trocar de guardião não altera o mapa.")
			menu_box.add_child(_button("←  VOLTAR", "back_characters"))
		"seed":
			_add_title("SEU MUNDO, SUAS REGRAS", "CÓDIGO DA SEED", "Digite um código ou gere um automaticamente")
			_add_note("Mesma seed + mesma dificuldade + mesma fase = mesmo mapa, animais e perigos iniciais. Os inimigos reagem aos seus movimentos.", WHITE)
			seed_entry = LineEdit.new()
			seed_entry.text = requested_seed
			seed_entry.max_length = 24
			seed_entry.placeholder_text = "Ex.: FLORESTA-42"
			seed_entry.custom_minimum_size = Vector2(0, 50)
			seed_entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			seed_entry.add_theme_font_size_override("font_size", 19)
			seed_entry.add_theme_color_override("font_color", WHITE)
			seed_entry.add_theme_stylebox_override("normal", _style(Color("#263d32"), MINT, 10))
			menu_box.add_child(seed_entry)
			menu_box.add_child(_button("↻  GERAR OUTRA SEED", "new_seed"))
			menu_box.add_child(_button("▶  CONTINUAR", "seed_confirm", -1, true))
			menu_box.add_child(_button("←  VOLTAR", "back_seed"))
		"tutorial_offer":
			_add_title("PRONTO PARA COMEÇAR?", "TREINAMENTO", "Você decide: aprender ou entrar direto")
			_add_note("O tutorial é um mapa fixo e seguro, sem caçadores. Você aprende a coletar, resgatar e apagar incêndios. O tempo do tutorial não conta para os recordes.")
			menu_box.add_child(_button("▶  JOGAR TUTORIAL", "tutorial", -1, true))
			menu_box.add_child(_button("➜  PULAR E COMEÇAR", "skip_tutorial"))
			menu_box.add_child(_button("←  VOLTAR", "back_tutorial"))
		"pause":
			_add_title("JOGO PAUSADO", "DESCANSE UM POUCO", "O cronômetro está parado")
			menu_box.add_child(_button("▶  CONTINUAR", "resume", -1, true))
			if current_mode != 0 or campaign_attempts_remaining > 1:
				menu_box.add_child(_button("↻  RECOMEÇAR FASE" + (" (-1 TENTATIVA)" if current_mode == 0 else ""), "restart"))
			if detail == "tutorial":
				menu_box.add_child(_button("➜  PULAR TUTORIAL", "skip_tutorial"))
			if detail == "endless":
				menu_box.add_child(_button("★  ENCERRAR E SALVAR RECORDE", "finish_endless"))
			menu_box.add_child(_button("▣  BESTIÁRIO", "collection"))
			menu_box.add_child(_button("⚙  CONFIGURAÇÕES", "settings"))
			menu_box.add_child(_button("◇  CONTROLES", "help_pause"))
			menu_box.add_child(_button("⌂  MENU INICIAL", "back_main"))
		"stage_clear":
			_add_title("MISSÃO CUMPRIDA", "BIOMA PROTEGIDO!", detail)
			menu_box.add_child(_button("▶  PRÓXIMA FASE", "next_stage", -1, true))
			menu_box.add_child(_button("⌂  MENU INICIAL", "back_main"))
		"victory":
			_add_title("TODOS OS GUARDIÕES UNIDOS", "A FLORESTA RESISTIU!", "Lobo de Fogo derrotado. A vida voltou.")
			_add_note(detail, LIME)
			menu_box.add_child(_button("★  VER PLACAR", "scores", -1, true))
			menu_box.add_child(_button("↻  NOVA PARTIDA", "new_run"))
			menu_box.add_child(_button("⌂  MENU INICIAL", "back_main"))
		"defeat":
			_add_title("A FLORESTA PRECISA DE VOCÊ", "FIM DE JOGO", "Sua aventura não acabou aqui")
			_add_note(detail, RED)
			if current_mode != 0 or campaign_attempts_remaining > 0:
				menu_box.add_child(_button("↻  TENTAR DE NOVO", "restart", -1, true))
			else:
				_add_note("AS 4 TENTATIVAS DA CAMPANHA TERMINARAM. INICIE UMA NOVA AVENTURA.", GOLD)
			menu_box.add_child(_button("★  VER PLACAR", "scores"))
			menu_box.add_child(_button("⌂  MENU INICIAL", "back_main"))
		"scores":
			_render_scores()
		"collection":
			_render_collection()
		"settings":
			_render_settings()

func _update_showcase(screen: String) -> void:
	if not is_instance_valid(showcase_title):
		return
	showcase_portraits.visible = true
	showcase_boss.visible = false
	match screen:
		"defeat":
			showcase_title.text = "A FLORESTA AINDA PRECISA DE VOCÊ"
			showcase_title.add_theme_color_override("font_color", RED)
			showcase_subtitle.text = "RESPAWN • MESMA SEED • NOVA CHANCE"
			showcase_portraits.visible = false
			showcase_boss.visible = true
		"victory":
			showcase_title.text = "MISSÃO CUMPRIDA • FLORESTA PRESERVADA"
			showcase_title.add_theme_color_override("font_color", GOLD)
			showcase_subtitle.text = "OS QUATRO GUARDIÕES VENCERAM JUNTOS"
		"collection":
			showcase_title.text = "CADA ESPÉCIE CONTA UMA HISTÓRIA"
			showcase_title.add_theme_color_override("font_color", LIME)
			showcase_subtitle.text = "EXPLORE NOVAS SEEDS • ENCONTRE SEGREDOS"
		"characters":
			showcase_title.text = "QUATRO HERÓIS • UM MESMO PROPÓSITO"
			showcase_title.add_theme_color_override("font_color", LIME)
			showcase_subtitle.text = "EXPLORE • PROTEJA • RESGATE • PRESERVE"
		_:
			showcase_title.text = "UMA AVENTURA 100% BRASILEIRA"
			showcase_title.add_theme_color_override("font_color", LIME)
			showcase_subtitle.text = "AMAZÔNIA   •   CERRADO   •   PANTANAL   •   MATA ATLÂNTICA"

func _render_settings() -> void:
	_add_title("CONFORTO E ACESSIBILIDADE", "CONFIGURAÇÕES", "Suas escolhas ficam salvas neste computador")
	var fullscreen: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	menu_box.add_child(_button("▣  TELA CHEIA: %s" % ("LIGADA" if fullscreen else "DESLIGADA"), "toggle_fullscreen", -1, true))
	_add_note("Alternar entre tela cheia e janela. O jogo mantém proporção 16:9.")
	menu_box.add_child(_button("♪  EFEITOS SONOROS: %s" % ("ATIVOS" if sound_enabled else "SILENCIADOS"), "toggle_sound"))
	menu_box.add_child(_button("✧  ANIMAÇÕES REDUZIDAS: %s" % ("SIM" if reduced_motion else "NÃO"), "toggle_motion"))
	_add_note("Desativa a movimentação decorativa do fundo e reduz as transições.")
	menu_box.add_child(_button("♣  ANIMAIS SECRETOS: %s" % ("ATIVOS" if memes_enabled else "DESATIVADOS"), "toggle_memes"))
	_add_note("Memes são opcionais e não mudam a missão nem a seed do mapa.")
	menu_box.add_child(_button("←  VOLTAR", "back_panel"))

func _render_collection() -> void:
	_add_title("FAUNA BRASILEIRA", "BESTIÁRIO", "Espécies que você já encontrou")
	var found: Dictionary = CollectionStore.load_collection()
	var all_species: int = ANIMAL_NAMES.size() + ArtCatalog.meme_names().size()
	_add_note("DESCOBERTAS: %d / %d    •    OS SEGREDOS NÃO TRAVAM AS MISSÕES" % [found.size(), all_species], LIME)
	var tabs: HBoxContainer = HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	menu_box.add_child(tabs)
	for i in range(3):
		var btn: Button = _button(["TODOS", "FAUNA", "SECRETOS"][i], "collection_filter", i, i == collection_filter)
		btn.custom_minimum_size = Vector2(0, 38)
		btn.add_theme_font_size_override("font_size", 14)
		tabs.add_child(btn)
	var grid: VBoxContainer = VBoxContainer.new()
	grid.custom_minimum_size = Vector2.ZERO
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("separation", 7)
	menu_box.add_child(grid)
	var species_list: Array[String] = []
	if collection_filter != 2:
		species_list.append_array(ANIMAL_NAMES)
	if collection_filter != 1:
		species_list.append_array(ArtCatalog.meme_names())
	for species in species_list:
		var is_secret: bool = ArtCatalog.meme_names().has(species)
		var revealed: bool = found.has(species)
		var card: PanelContainer = PanelContainer.new()
		card.custom_minimum_size = Vector2(0, 60)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", _style(Color("#24463e") if revealed else Color("#1a302e"), Color("#758d65") if revealed else Color("#355047"), 6, 7))
		grid.add_child(card)
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 5)
		card.add_child(row)
		var path: String = "res://Assets/Animals/%s/%s.png" % ["Memes" if is_secret else "Mission", species]
		var thumb: TextureRect = _sprite_box(path, 45.0)
		if not revealed:
			thumb.modulate = Color(0.14, 0.20, 0.18, 1.0)
		row.add_child(thumb)
		var texts: VBoxContainer = VBoxContainer.new()
		texts.add_theme_constant_override("separation", 1)
		texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(texts)
		var name_label: Label = _label(species.replace("_", " ").capitalize() if revealed else "ANIMAL DESCONHECIDO", 14, WHITE, false)
		name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		name_label.clip_text = true
		name_label.custom_minimum_size = Vector2(0, 18)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		texts.add_child(name_label)
		var category_label: Label = _label("SECRETO" if is_secret else "FAUNA BRASILEIRA", 11, GOLD if revealed else MUTED, false)
		category_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		texts.add_child(category_label)
		if revealed:
			var entry: Dictionary = found[species]
			texts.add_child(_label(str(entry.get("biome", "")), 10, MUTED, false))
	_add_note("Cada animal é registrado quando você o resgata. A coleção é salva neste computador e vale para todas as partidas.")
	menu_box.add_child(_button("←  VOLTAR AO MENU", "back_main", -1, true))

func _render_scores() -> void:
	_add_title("RECORDES DO COMPUTADOR", "PLACAR", "Classificado por dificuldade, modo e fase")
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	menu_box.add_child(row)
	for mode_id in range(3):
		var b: Button = _button(["CAMPANHA", "SPRINT", "INFINITO"][mode_id], "score_filter_mode", mode_id, mode_id == score_filter_mode)
		b.custom_minimum_size = Vector2(0, 42)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 13)
		row.add_child(b)
	var diff_row: HBoxContainer = HBoxContainer.new()
	diff_row.add_theme_constant_override("separation", 7)
	menu_box.add_child(diff_row)
	for diff_id in range(3):
		var b: Button = _button(DIFF_NAMES[diff_id], "score_filter_diff", diff_id, diff_id == score_filter_diff)
		b.custom_minimum_size = Vector2(0, 38)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 13)
		diff_row.add_child(b)
	if score_filter_mode != 2:
		var stage_row: HBoxContainer = HBoxContainer.new()
		stage_row.add_theme_constant_override("separation", 5)
		menu_box.add_child(stage_row)
		for phase in range(-1, 5):
			var label_text: String = "GERAL" if phase == -1 else str(phase + 1)
			var b: Button = _button(label_text, "score_filter_stage", phase, score_filter_stage == phase)
			b.custom_minimum_size = Vector2(0, 35)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.add_theme_font_size_override("font_size", 12)
			stage_row.add_child(b)
	var records: Array = ScoreStore.load_records()
	var subset: Array = []
	for item in records:
		if not (item is Dictionary):
			continue
		var r: Dictionary = item
		if int(r.get("mode", 0)) != score_filter_mode or int(r.get("difficulty", 1)) != score_filter_diff:
			continue
		if score_filter_mode != 2:
			if score_filter_stage == -1 and str(r.get("category", "")) != "run":
				continue
			if score_filter_stage >= 0 and (str(r.get("category", "")) != "stage" or int(r.get("stage", -1)) != score_filter_stage):
				continue
		subset.append(r)
	subset.sort_custom(_record_before)
	_add_section("RESULTADOS  •  %d ENCONTRADO(S)" % subset.size())
	if subset.is_empty():
		_add_note("Nenhum recorde salvo aqui ainda.\nConclua uma fase ou sobreviva às ondas para aparecer no placar.")
	else:
		for i in range(mini(8, subset.size())):
			var item: Dictionary = subset[i]
			var time_text: String = ScoreStore.format_time(float(item.get("time", 0.0)))
			var line: String = "%dº   %s   |   %s   |   %d PTS" % [i + 1, time_text, str(item.get("hero", "?")), int(item.get("points", 0))]
			if score_filter_mode == 2:
				line = "%dº   ONDA %d   |   %d PTS   |   %s" % [i + 1, int(item.get("wave", 1)), int(item.get("points", 0)), time_text]
			_add_note(line + "\nSEED  " + str(item.get("seed", "?")), WHITE if i == 0 else MUTED)
	menu_box.add_child(_button("←  MENU INICIAL", "back_main", -1, true))

func _record_before(a: Dictionary, b: Dictionary) -> bool:
	if score_filter_mode == 2:
		if int(a.get("wave", 0)) != int(b.get("wave", 0)):
			return int(a.get("wave", 0)) > int(b.get("wave", 0))
		return int(a.get("points", 0)) > int(b.get("points", 0))
	var aa: float = float(a.get("time", 1000000.0))
	var bb: float = float(b.get("time", 1000000.0))
	if not is_equal_approx(aa, bb):
		return aa < bb
	return int(a.get("points", 0)) > int(b.get("points", 0))

func _hud_panel(parent: Control, pos: Vector2, minimum: Vector2) -> VBoxContainer:
	var p: PanelContainer = PanelContainer.new()
	p.position = pos
	p.custom_minimum_size = minimum
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", _style(Color(0.07, 0.12, 0.10, 0.70), Color("#588157"), 8, 9))
	parent.add_child(p)
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 5)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(v)
	return v

func _bar(tint: Color, w: float = 300.0) -> ProgressBar:
	var bar: ProgressBar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(w, 11)
	bar.max_value = 100.0
	bar.value = 100.0
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("background", _style(Color("#111816"), Color("#382b22"), 0, 5))
	bar.add_theme_stylebox_override("fill", _style(tint, tint, 0, 5))
	return bar

func _icon_line(parent: VBoxContainer, icon_name: String, label_text: String = "") -> Label:
	var line_box: HBoxContainer = HBoxContainer.new()
	line_box.add_theme_constant_override("separation", 6)
	parent.add_child(line_box)
	line_box.add_child(_sprite_box("res://Assets/UI/Icons/%s.png" % icon_name, 22.0))
	var label_widget: Label = _label(label_text, 13, WHITE, false)
	label_widget.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_box.add_child(label_widget)
	return label_widget

func _hud_text(txt: String, sz: int = 12, tint: Color = WHITE) -> Label:
	var label_widget: Label = _label(txt, sz, tint, false)
	label_widget.autowrap_mode = TextServer.AUTOWRAP_OFF
	label_widget.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label_widget.clip_text = true
	label_widget.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label_widget

func _hud_line(parent: VBoxContainer, icon_name: String, text_value: String = "") -> Label:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(row)
	row.add_child(_sprite_box("res://Assets/UI/Icons/%s.png" % icon_name, 17.0))
	var text_label: Label = _hud_text(text_value, 12, WHITE)
	row.add_child(text_label)
	return text_label

func _hud_metric(parent: VBoxContainer, icon_name: String, metric_name: String, tint: Color) -> ProgressBar:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	parent.add_child(row)
	row.add_child(_sprite_box("res://Assets/UI/Icons/%s.png" % icon_name, 16.0))
	var title: Label = _hud_text(metric_name, 10, MUTED)
	title.custom_minimum_size.x = 53.0
	row.add_child(title)
	var bar: ProgressBar = _bar(tint, 112.0)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.custom_minimum_size.y = 11.0
	row.add_child(bar)
	return bar

func _side_section(parent: VBoxContainer, header: String) -> VBoxContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _style(Color(0.16, 0.25, 0.18, 0.67), Color(0.52, 0.66, 0.42, 0.45), 5, 6))
	parent.add_child(panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	panel.add_child(column)
	var heading: Label = _hud_text(header, 12, GOLD)
	column.add_child(heading)
	return column

func _build_hud() -> void:
	hud_root = Control.new()
	hud_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud_root)
	# Barra fixa: SEM rolagem. Largura proporcional à composição 1280×720.
	var side: PanelContainer = PanelContainer.new()
	hud_side = side
	side.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	side.offset_left = -252.0
	side.offset_right = 0.0
	side.offset_top = 0.0
	side.offset_bottom = 0.0
	side.mouse_filter = Control.MOUSE_FILTER_IGNORE
	side.add_theme_stylebox_override("panel", _style(Color(0.06, 0.10, 0.08, 0.88), Color(0.64, 0.69, 0.53, 0.62), 6, 0))
	hud_root.add_child(side)
	var column: VBoxContainer = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 3)
	side.add_child(column)
	var title: Label = _hud_text("ECO LABIRINTO  ·  ODS 15", 13, LIME)
	column.add_child(title)
	stage_label = _hud_text("", 11, MINT)
	column.add_child(stage_label)
	var person_box: VBoxContainer = _side_section(column, "GUARDIÃO")
	var person_row: HBoxContainer = HBoxContainer.new()
	person_row.add_theme_constant_override("separation", 8)
	person_box.add_child(person_row)
	portrait = _sprite_box("res://Assets/Characters/Leo/guardiao.png", 38.0)
	person_row.add_child(portrait)
	hero_label = _hud_text("LÉO", 13, WHITE)
	person_row.add_child(hero_label)
	var bars: VBoxContainer = _side_section(column, "STATUS")
	health_bar = _hud_metric(bars, "health", "VIDA", RED)
	energy_bar = _hud_metric(bars, "power", "ENERGIA", GOLD)
	forest_bar = _hud_metric(bars, "forest", "FLORESTA", MINT)
	vita_label = _hud_text("", 10, WHITE)
	vita_label.visible = false
	water_label = _hud_line(bars, "water", "ÁGUA  5/5")
	var objectives: VBoxContainer = _side_section(column, "MISSÕES")
	missions_label = _hud_line(objectives, "animal", "ANIMAIS  0/3")
	mission_trash_label = _hud_line(objectives, "garbage", "LIXO  0/3")
	mission_fire_label = _hud_line(objectives, "fire", "FOCOS DE FOGO  2")
	var ability: VBoxContainer = _side_section(column, "PODER  ·  ESPAÇO")
	power_label = _hud_line(ability, "power", "HABILIDADE PRONTA")
	power_bar = _bar(LIME, 207.0)
	power_bar.custom_minimum_size.y = 11.0
	power_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ability.add_child(power_bar)
	power_hint = _hud_text("PRONTO", 10, MUTED)
	power_hint.visible = false
	var stats: VBoxContainer = _side_section(column, "PARTIDA")
	clock_label = _hud_line(stats, "clock", "00:00  ·  0 PTS")
	attempts_label = _hud_line(stats, "health", "TENTATIVAS 4/4")
	collection_label = _hud_line(stats, "animal", "BESTIÁRIO 0/19")
	collection_label.visible = false  # Detalhes da coleção ficam no TAB, não na HUD.
	seed_label = _hud_line(stats, "seed", "SEED ECO-2026")
	var mini: VBoxContainer = _side_section(column, "MAPA")
	map = MiniMapScript.new()
	map.custom_minimum_size = Vector2(210, 91)
	map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mini.add_child(map)
	column.add_child(_hud_text("TAB CADERNO  ·  ESC PAUSA", 9, MUTED))
	# Toasts sobre o mapa: curtos, transparentes, não obstruem a visão.
	var msg: VBoxContainer = _hud_panel(hud_root, Vector2(22, 608), Vector2(690, 30))
	notice_label = _hud_text("", 14, GOLD)
	notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.add_child(notice_label)
	notice_panel = msg.get_parent() as PanelContainer
	notice_panel.visible = false
	notice_panel.add_theme_stylebox_override("panel", _style(Color(0.06, 0.13, 0.10, 0.48), Color(0.42, 0.65, 0.53, 0.54), 5, 8))
	var actions: VBoxContainer = _hud_panel(hud_root, Vector2(22, 656), Vector2(690, 30))
	context_label = _hud_text("WASD MOVER  ·  E INTERAGIR  ·  ESPAÇO PODER", 12, WHITE)
	context_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	actions.add_child(context_label)
	(actions.get_parent() as PanelContainer).add_theme_stylebox_override("panel", _style(Color(0.06, 0.13, 0.10, 0.33), Color(0.42, 0.65, 0.53, 0.35), 5, 8))
	tutorial_label = _hud_text("", 11, LIME)
	# Boss compacto, sobre o cenário, somente na última fase.
	var boss: VBoxContainer = _hud_panel(hud_root, Vector2(318, 18), Vector2(356, 54))
	boss_label = _hud_text("LOBO DE FOGO", 14, RED)
	boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_bar = _bar(RED, 320.0)
	boss_bar.custom_minimum_size.y = 12.0
	boss.add_child(boss_label)
	boss.add_child(boss_bar)
	(boss.get_parent() as PanelContainer).add_theme_stylebox_override("panel", _style(Color(0.15, 0.05, 0.04, 0.72), Color(0.85, 0.36, 0.21, 0.64), 6, 9))
	boss.get_parent().visible = false
	# Detalhes da partida acessíveis pelo TAB; jogo pausa durante leitura.
	detail_panel = PanelContainer.new()
	detail_panel.position = Vector2(25, 92)
	detail_panel.custom_minimum_size = Vector2(360, 310)
	detail_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_panel.add_theme_stylebox_override("panel", _style(Color(0.045, 0.14, 0.11, 0.91), Color("#9cc477"), 14, 10))
	hud_root.add_child(detail_panel)
	var detail_column: VBoxContainer = VBoxContainer.new()
	detail_column.add_theme_constant_override("separation", 12)
	detail_panel.add_child(detail_column)
	var detail_title: Label = _hud_text("CADERNO DO GUARDIÃO  ·  TAB PARA VOLTAR", 16, LIME)
	detail_column.add_child(detail_title)
	detail_text = _label("", 15, WHITE, false)
	detail_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_column.add_child(detail_text)
	detail_panel.visible = false

func show_details(visible_now: bool) -> void:
	if is_instance_valid(detail_panel):
		detail_panel.visible = visible_now

func set_campaign_attempts(left: int) -> void:
	campaign_attempts_remaining = maxi(0, left)

func _build_effects() -> void:
	announcement_back = ColorRect.new()
	announcement_back.color = Color(0, 0, 0, 0)
	announcement_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	announcement_back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(announcement_back)
	scene_announcement = _label("", 52, LIME)
	scene_announcement.position = Vector2(90, 281)
	scene_announcement.size = Vector2(820, 72)
	scene_announcement.autowrap_mode = TextServer.AUTOWRAP_OFF
	scene_announcement.clip_text = true
	scene_announcement.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	scene_announcement.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene_announcement.modulate.a = 0.0
	add_child(scene_announcement)
	scene_subtitle = _label("", 19, WHITE)
	scene_subtitle.position = Vector2(91, 352)
	scene_subtitle.size = Vector2(820, 42)
	scene_subtitle.autowrap_mode = TextServer.AUTOWRAP_OFF
	scene_subtitle.clip_text = true
	scene_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene_subtitle.modulate.a = 0.0
	add_child(scene_subtitle)
	hit_rect = ColorRect.new()
	hit_rect.color = Color(0.9, 0.08, 0.08, 0.0)
	hit_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hit_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(hit_rect)
	cinematic_overlay = Control.new()
	cinematic_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cinematic_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cinematic_overlay)
	var shade: ColorRect = ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.035, 0.18, 0.13, 0.78)
	cinematic_overlay.add_child(shade)
	var fireworks: Control = FinaleFX.new()
	cinematic_overlay.add_child(fireworks)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cinematic_overlay.add_child(center)
	var stack: VBoxContainer = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 19)
	center.add_child(stack)
	stack.add_child(_label("✦  ✦  ✦  ✦", 50, GOLD))
	var guardian_line: HBoxContainer = HBoxContainer.new()
	guardian_line.alignment = BoxContainer.ALIGNMENT_CENTER
	guardian_line.add_theme_constant_override("separation", 32)
	stack.add_child(guardian_line)
	for guardian in PORTRAITS:
		guardian_line.add_child(_sprite_box("res://Assets/Characters/%s/guardiao.png" % guardian, 112.0))
	cinematic_label = _label("A FLORESTA RENASCE", 49, LIME)
	cinematic_subtitle = _label("LÉO    •    HELENA    •    RAFAEL    •    CLARA", 24, WHITE)
	stack.add_child(cinematic_label)
	stack.add_child(cinematic_subtitle)
	stack.add_child(_label("TODOS UNIDOS CONTRA O MEGAINCÊNDIO", 19, MINT))
	cinematic_overlay.visible = false

func update_hud(data: Dictionary, world: Node2D) -> void:
	stage_label.text = str(data.get("stage", ""))
	var hero_index: int = clampi(int(data.get("hero_index", 0)), 0, 3)
	hero_label.text = str(data.get("hero", ""))
	portrait.texture = load("res://Assets/Characters/%s/guardiao.png" % PORTRAITS[hero_index]) as Texture2D
	var hp: int = int(data.get("health", 100))
	var energy: int = int(data.get("stamina", 100))
	var forest: int = int(data.get("forest", 100))
	health_bar.value = hp
	energy_bar.value = energy
	forest_bar.value = forest
	vita_label.text = "%d HP   ·   %d EN   ·   %d FLORESTA" % [hp, energy, forest]
	water_label.text = "CANTIL  %d/5" % int(data.get("water", 5))
	missions_label.text = "RESGATES  %d/%d" % [int(data.get("rescued", 0)), int(data.get("animals", 0))]
	mission_trash_label.text = "LIXO  %d/%d" % [int(data.get("cleaned", 0)), int(data.get("trash", 0))]
	mission_fire_label.text = "FOCOS DE FOGO  %d" % int(data.get("fires", 0))
	clock_label.text = "%s   ·   %d PTS   ·   %s" % [str(data.get("time", "00:00")), int(data.get("points", 0)), "NOITE" if data.get("night", false) else "DIA"]
	collection_label.text = "BESTIÁRIO  %d/%d" % [int(data.get("collection_count", 0)), total_collection_entries]
	seed_label.text = "SEED  " + str(data.get("seed", ""))
	seed_label.tooltip_text = str(data.get("seed", ""))
	attempts_label.visible = int(data.get("mode_index", 0)) == 0 and int(data.get("stage_index", -1)) >= 0
	attempts_label.text = "TENTATIVAS  %d/4" % int(data.get("attempts_left", 4))
	var charge: float = float(data.get("charge", 1.0))
	power_bar.value = clampf(charge * 100.0, 0.0, 100.0)
	power_label.text = str(data.get("power", "")) + ("  ·  PRONTO" if charge >= 1.0 else "")
	power_hint.text = "ESPAÇO PARA ATIVAR" if charge >= 1.0 else "RECARGA  %.1f s" % float(data.get("cooldown", 0.0))
	context_label.text = str(data.get("hint", ""))
	var prompt_panel: Control = context_label.get_parent().get_parent() as Control
	if prompt_panel != null:
		prompt_panel.visible = not context_label.text.is_empty()
	var boss_hp: int = int(data.get("boss_health", 0))
	var max_boss_hp: int = maxi(1, int(data.get("boss_max_health", 100)))
	var stunned: bool = float(data.get("boss_stun_time", 0.0)) > 0.0
	boss_label.text = "LOBO DE FOGO  ·  %d/%d  ·  FASE %d/3" % [boss_hp, max_boss_hp, int(data.get("boss_phase", 1))]
	if stunned:
		boss_label.text = "LOBO ATORDOADO  ·  %ds" % ceili(float(data.get("boss_stun_time", 0.0)))
	boss_bar.max_value = max_boss_hp
	boss_bar.value = boss_hp
	boss_bar.get_parent().visible = int(data.get("stage_index", -1)) == 4
	var more: String = "GUARDIÃO: %s\nBIOMA: %s\n\nMISSÃO PRINCIPAL\n  •  Resgatar: %d/%d animais\n  •  Recolher: %d/%d lixos\n  •  Focos ativos: %d\n\nSEED: %s\nPONTUAÇÃO: %d\nBESTIÁRIO: %d/%d\nTENTATIVAS: %d/4\n\nWASD mover · E interagir\nSHIFT correr · ESPAÇO poder\nTAB fechar · ESC pausar" % [
		str(data.get("hero", "")), str(data.get("stage", "")),
		int(data.get("rescued", 0)), int(data.get("animals", 0)), int(data.get("cleaned", 0)),
		int(data.get("trash", 0)), int(data.get("fires", 0)), str(data.get("seed", "")),
		int(data.get("points", 0)), int(data.get("collection_count", 0)), total_collection_entries,
		int(data.get("attempts_left", 4))]
	detail_text.text = more
	map.set_data(world, data.get("player_pos", Vector2.ZERO), bool(data.get("night", false)))

func flash(message: String, duration: float = 2.5) -> void:
	notice_label.text = message
	if is_instance_valid(notice_panel):
		notice_panel.visible = true
	last_notice = duration

func damage_flash() -> void:
	hit_rect.color = Color(0.94, 0.05, 0.05, 0.31)
	var t: Tween = create_tween()
	t.tween_property(hit_rect, "color", Color(0.94, 0.05, 0.05, 0.0), 0.2 if reduced_motion else 0.55)

func announce(title: String, subtitle: String, is_danger: bool = false) -> void:
	if is_instance_valid(announcement_tween):
		announcement_tween.kill()
	scene_announcement.text = title
	scene_subtitle.text = subtitle
	scene_announcement.add_theme_color_override("font_color", RED if is_danger else LIME)
	scene_announcement.modulate.a = 0.0
	scene_subtitle.modulate.a = 0.0
	announcement_back.color = Color(0.28, 0.15, 0.08, 0.0) if is_danger else Color(0.06, 0.12, 0.08, 0.0)
	announcement_tween = create_tween()
	announcement_tween.set_parallel(true)
	announcement_tween.tween_property(scene_announcement, "modulate:a", 1.0, 0.18 if reduced_motion else 0.48)
	announcement_tween.tween_property(scene_subtitle, "modulate:a", 1.0, 0.18 if reduced_motion else 0.48)
	announcement_tween.tween_property(announcement_back, "color:a", 0.11 if reduced_motion else 0.18, 0.18 if reduced_motion else 0.4)
	announcement_tween.set_parallel(false)
	announcement_tween.tween_interval(0.9 if reduced_motion else 2.2)
	announcement_tween.set_parallel(true)
	announcement_tween.tween_property(scene_announcement, "modulate:a", 0.0, 0.3 if reduced_motion else 0.7)
	announcement_tween.tween_property(scene_subtitle, "modulate:a", 0.0, 0.3 if reduced_motion else 0.7)
	announcement_tween.tween_property(announcement_back, "color:a", 0.0, 0.3 if reduced_motion else 0.7)

func show_finale() -> void:
	overlay.visible = false
	hud_root.visible = false
	cinematic_overlay.visible = true
	cinematic_overlay.modulate.a = 0.0
	var t: Tween = create_tween()
	t.tween_property(cinematic_overlay, "modulate:a", 1.0, 0.25 if reduced_motion else 1.4)

func hide_finale() -> void:
	cinematic_overlay.visible = false
