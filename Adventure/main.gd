extends Node2D
## ECO LABIRINTO — AVENTURA PARA EXPOSIÇÃO (Godot 4.x)
## Campanha, contra o relógio e infinito; seed reproduzível e placar local.
const WorldScript = preload("res://Adventure/world.gd")
const UIScript = preload("res://Adventure/interface.gd")
const AvatarScript = preload("res://Adventure/player_visual.gd")
const AmbientScript = preload("res://Adventure/ambient_fx.gd")
const ScoreStore = preload("res://Adventure/score_store.gd")
const CollectionStore = preload("res://Adventure/collection_store.gd")
const HEROES = ["LÉO", "HELENA", "RAFAEL", "CLARA"]
const HERO_POWERS = ["CORRIDA", "CONTROLE DO FOGO", "PRIMEIROS SOCORROS", "CANTIL EXTRA"]
const COOLDOWNS = [13.0, 15.0, 17.0, 14.0]
const DIFFICULTIES = ["FÁCIL", "MÉDIO", "DIFÍCIL"]
const MODES = ["CAMPANHA", "SPRINT", "SOBREVIVÊNCIA"]
const BIOMES = ["AMAZÔNIA", "CERRADO", "PANTANAL", "MATA ATLÂNTICA", "CORAÇÃO EM CHAMAS"]

var world
var avatar
var ui
var camera: Camera2D
var lighting: CanvasModulate
var state: String = "main"
var run_mode: int = 0
var stage: int = 0
var sprint_stage: int = 0
var pending_start_stage: int = 0
var difficulty: int = 1
var hero: int = 0
var seed_code: String = "ECO-2026"
var player_pos: Vector2 = Vector2.ZERO
var health: int = 100
var stamina: float = 100.0
var water: int = 5
var forest_health: int = 100
var forest_checkpoint: int = 100
var rescued: int = 0
var cleaned: int = 0
var extinguished: int = 0
var total_rescues: int = 0
var points: int = 0
var score_checkpoint: int = 0
var elapsed: float = 0.0
var run_elapsed: float = 0.0
var stage_times: Array[float] = []
var cooldown: float = 0.0
var power_time: float = 0.0
var invulnerability: float = 0.0
var night: bool = false
var hud_clock: float = 0.0
var wave_number: int = 1
var wave_timer: float = 0.0
var endless_recorded: bool = false
var finale_started: bool = false
var panel_origin: String = "main"
var discovered_count: int = 0
var campaign_attempts_left: int = 4
var emergency_kits_spawned: int = 0
var emergency_rescue_used: bool = false
var player_velocity: Vector2 = Vector2.ZERO
var interaction_buffer: float = 0.0
var emergency_retry_clock: float = 0.0
var camera_shake: float = 0.0
var camera_offset_base: Vector2 = Vector2(112.0, 0.0)
var ambience: Variant
var player_light: PointLight2D
var boss_light: PointLight2D
var sound_players: Array[AudioStreamPlayer] = []
var sound_cursor: int = 0

func _ready() -> void:
	get_window().title = "EcoLabirinto • Guardiões da Floresta"
	discovered_count = CollectionStore.load_collection().size()
	world = WorldScript.new()
	world.name = "MundoProcedural"
	add_child(world)
	world.enemy_contact.connect(_enemy_contact)
	world.fire_contact.connect(_fire_contact)
	world.forest_decay.connect(_forest_decay)
	world.fire_spread.connect(_fire_spread)
	world.boss_warning.connect(_on_boss_warning)
	world.boss_phase_changed.connect(_on_boss_phase_changed)
	avatar = AvatarScript.new()
	avatar.name = "Guardiao"
	add_child(avatar)
	ambience = AmbientScript.new()
	ambience.name = "AtmosferaFolhas"
	ambience.z_index = 2
	add_child(ambience)
	ambience.visible = false
	camera = Camera2D.new()
	camera.name = "CameraJogador"
	camera.zoom = Vector2(1.18, 1.18)
	camera.offset = camera_offset_base # Desloca o foco da câmera para a direita e coloca o jogador no centro da área jogável.
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	add_child(camera)
	camera.make_current()
	lighting = CanvasModulate.new()
	lighting.color = Color.WHITE
	add_child(lighting)
	_configure_lights()
	for i in range(3):
		var speaker: AudioStreamPlayer = AudioStreamPlayer.new()
		speaker.volume_db = -8.0
		add_child(speaker)
		sound_players.append(speaker)
	ui = UIScript.new()
	add_child(ui)
	ui.selected.connect(_menu_action)
	ui.set_campaign_attempts(campaign_attempts_left)
	world.visible = false
	avatar.visible = false
	ui.show_screen("main")

func _menu_action(action: String, value: int) -> void:
	match action:
		"play":
			state = "modes"
			ui.show_screen("modes")
		"mode":
			run_mode = value
			ui.set_configuration(run_mode, difficulty, sprint_stage)
			state = "difficulty"
			ui.show_screen("difficulty")
		"difficulty":
			difficulty = value
			ui.set_configuration(run_mode, difficulty, sprint_stage)
			state = "stage_select" if run_mode == 1 else "characters"
			ui.show_screen(state)
		"stage":
			sprint_stage = value
			state = "characters"
			ui.show_screen("characters")
		"hero":
			hero = value
			state = "seed"
			ui.show_screen("seed")
		"seed_confirm":
			seed_code = ui.get_seed()
			state = "tutorial_offer"
			ui.show_screen("tutorial_offer")
		"tutorial":
			_new_run(true)
		"skip_tutorial":
			if state == "pause" and stage == -1:
				_start_level(pending_start_stage)
			else:
				_new_run(false)
		"back_modes":
			state = "modes"
			ui.show_screen("modes")
		"back_difficulty":
			state = "difficulty"
			ui.show_screen("difficulty")
		"back_characters":
			state = "stage_select" if run_mode == 1 else "difficulty"
			ui.show_screen(state)
		"back_seed":
			state = "characters"
			ui.show_screen("characters")
		"back_tutorial":
			state = "seed"
			ui.show_screen("seed")
		"back_panel":
			if panel_origin == "pause":
				state = "pause"
				ui.show_screen("pause", "tutorial" if stage == -1 else ("endless" if run_mode == 2 else ""))
			else:
				_back_to_main()
		"back_main":
			_back_to_main()
		"help":
			state = "help"
			ui.show_screen("help")
		"help_pause":
			state = "help_pause"
			ui.show_screen("help", "pause")
		"back_pause":
			state = "pause"
			ui.show_screen("pause", "tutorial" if stage == -1 else ("endless" if run_mode == 2 else ""))
		"scores":
			state = "scores"
			ui.show_screen("scores")
		"collection":
			panel_origin = "pause" if state == "pause" else "main"
			state = "collection"
			ui.show_screen("collection")
		"settings":
			panel_origin = "pause" if state == "pause" else "main"
			state = "settings"
			ui.show_screen("settings")
		"resume":
			world.extras_enabled = ui.memes_enabled
			world.queue_redraw()
			state = "playing"
			ui.show_screen("playing")
		"restart":
			# Na campanha, o reinício manual também consome uma tentativa.
			if run_mode == 0 and stage >= 0 and state == "pause":
				if campaign_attempts_left <= 1:
					ui.flash("ÚLTIMA TENTATIVA: CONTINUE A FASE!", 2.2)
					return
				campaign_attempts_left -= 1
				ui.set_campaign_attempts(campaign_attempts_left)
			if run_mode == 0 and state == "defeat" and campaign_attempts_left <= 0:
				_back_to_main()
				return
			_retry()
		"next_stage":
			if stage == -1:
				_start_level(pending_start_stage)
			elif stage < 4 and run_mode == 0:
				stage += 1
				forest_health = mini(100, forest_health + 12)
				_start_level(stage)
		"finish_endless":
			_end_survival()
		"new_run":
			_new_run(false)
		"quit":
			get_tree().quit()

func _back_to_main() -> void:
	state = "main"
	world.visible = false
	avatar.visible = false
	ambience.visible = false
	lighting.color = Color.WHITE
	ui.hide_finale()
	ui.show_screen("main")

func _new_run(tutorial: bool) -> void:
	pending_start_stage = sprint_stage if run_mode == 1 else 0
	forest_health = 100
	campaign_attempts_left = 4
	ui.set_campaign_attempts(campaign_attempts_left)
	total_rescues = 0
	points = 0
	score_checkpoint = 0
	run_elapsed = 0.0
	stage_times.clear()
	wave_number = 1
	wave_timer = 0.0
	endless_recorded = false
	finale_started = false
	_start_level(-1 if tutorial else pending_start_stage)

func _retry() -> void:
	if run_mode == 2:
		_new_run(false)
		return
	if stage == -1:
		_start_level(-1)
		return
	# Mesma seed, mesma fase e tentativas restantes. Tempo da run NÃO é descontado:
	# reiniciar deve ter custo também no modo speedrun.
	forest_health = forest_checkpoint
	points = score_checkpoint
	_start_level(stage)

func _start_level(new_stage: int) -> void:
	stage = new_stage
	forest_checkpoint = forest_health
	score_checkpoint = points
	health = 100
	stamina = 100.0
	water = 5
	rescued = 0
	cleaned = 0
	extinguished = 0
	elapsed = 0.0
	cooldown = 0.0
	power_time = 0.0
	invulnerability = 0.0
	emergency_kits_spawned = 0
	emergency_rescue_used = false
	player_velocity = Vector2.ZERO
	interaction_buffer = 0.0
	emergency_retry_clock = 0.0
	camera_shake = 0.0
	night = false
	hud_clock = 0.0
	wave_timer = 0.0
	world.extras_enabled = ui.memes_enabled
	world.setup(stage, difficulty, seed_code, 0)
	if run_mode == 2 and stage >= 0:
		world.add_enemy_wave(1 + difficulty)
	player_pos = world.player_spawn
	avatar.hero = hero
	avatar.position = player_pos
	avatar.visible = true
	avatar.moving = false
	avatar.powered = false
	world.visible = true
	ambience.visible = stage >= 0
	ambience.biome = clampi(stage, 0, 4)
	ambience.position = player_pos
	camera.position = player_pos
	camera.reset_smoothing()
	camera.offset = camera_offset_base
	if player_light != null:
		player_light.enabled = false
	if boss_light != null:
		boss_light.enabled = false
	lighting.color = Color.WHITE
	state = "playing"
	ui.set_campaign_attempts(campaign_attempts_left)
	ui.show_screen("playing")
	if stage == -1:
		ui.announce("TREINAMENTO", "MAPA SEGURO  •  APRENDA OS COMANDOS")
	else:
		ui.announce("FASE %d" % (stage + 1), BIOMES[stage])
	if stage == 4 and run_mode == 0:
		ui.flash("CHECKPOINT FINAL: EM CASO DE DERROTA, VOLTE DIRETO AO LOBO", 3.8)
	else:
		ui.flash("E para interagir  •  ESPAÇO para usar o poder", 3.5)
	_refresh_hud()

func _process(delta: float) -> void:
	if state != "playing":
		return
	elapsed += delta
	if stage >= 0:
		run_elapsed += delta
	if run_mode == 2 and stage >= 0:
		wave_timer += delta
		if wave_timer >= 32.0:
			wave_timer = 0.0
			wave_number += 1
			points += 75 + wave_number * 10
			if world.enemies.size() >= 24:
				for i in range(mini(6, world.enemies.size())):
					world.enemies.remove_at(0)
			world.add_enemy_wave(mini(2 + difficulty + floori(float(wave_number) / 2.0), 9))
			ui.announce("ONDA %d" % wave_number, "NOVAS AMEAÇAS ESTÃO CHEGANDO", true)
	var was_night: bool = night
	night = int(elapsed / 38.0) % 2 == 1 and stage != -1
	if was_night != night:
		ui.announce("NOITE" if night else "DIA", "OS PERIGOS AUMENTARAM" if night else "A FLORESTA RESPIRA", night)
		lighting.color = Color(0.63, 0.69, 0.66) if night else Color.WHITE
		if player_light != null:
			player_light.enabled = night
		if boss_light != null:
			boss_light.enabled = night and stage == 4
	cooldown = maxf(0.0, cooldown - delta)
	power_time = maxf(0.0, power_time - delta)
	invulnerability = maxf(0.0, invulnerability - delta)
	avatar.powered = power_time > 0.0
	emergency_retry_clock -= delta
	if emergency_retry_clock <= 0.0 and health <= 38:
		emergency_retry_clock = 2.0
		_maybe_offer_heal()
	hud_clock -= delta
	if hud_clock <= 0.0:
		hud_clock = 0.13
		_refresh_hud()


func _physics_process(delta: float) -> void:
	if state != "playing":
		return
	var movement: Vector2 = Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		movement.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		movement.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		movement.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		movement.y += 1.0
	movement = movement.normalized()
	var sprint: bool = (Input.is_key_pressed(KEY_SHIFT) and stamina > 0.0) or (hero == 0 and power_time > 0.0)
	var speed: float = 128.0
	if sprint:
		speed *= 2.0 if hero == 0 and power_time > 0.0 else 1.55
		if hero != 0 or power_time <= 0.0:
			stamina = maxf(0.0, stamina - (27.0 * delta if movement != Vector2.ZERO else 0.0))
	else:
		stamina = minf(100.0, stamina + 21.0 * delta)
	# Física fixa (60 Hz), aceleração responsiva e parada rápida, sem derrapagem.
	var destination_velocity: Vector2 = movement * speed
	var response: float = 1100.0 if movement != Vector2.ZERO else 1700.0
	player_velocity = player_velocity.move_toward(destination_velocity, response * delta)
	if player_velocity.length_squared() > 0.5:
		player_pos = world.move_with_walls(player_pos, player_velocity * delta)
	if movement != Vector2.ZERO:
		avatar.direction = movement
	avatar.moving = player_velocity.length() > 8.0
	avatar.position = player_pos
	ambience.position = player_pos
	ambience.night = night
	ambience.reduced_motion = ui.reduced_motion
	camera.position = player_pos
	camera_shake = maxf(0.0, camera_shake - delta * 34.0)
	if camera_shake > 0.0 and not ui.reduced_motion:
		camera.offset = camera_offset_base + Vector2(randf_range(-camera_shake, camera_shake), randf_range(-camera_shake, camera_shake))
	else:
		camera.offset = camera_offset_base
	world.update_threats(delta, player_pos, night)
	if boss_light != null and stage == 4:
		boss_light.position = world.boss_position
	if not world.heal_items.is_empty() and player_pos.distance_to(Vector2(world.heal_items[0]["pos"])) < 24.0:
		_take_healing_plant(0)
	# Guarda tecla E por 140 ms para permitir interação ao entrar no alcance.
	if interaction_buffer > 0.0:
		interaction_buffer = maxf(0.0, interaction_buffer - delta)
		if not str(world.nearest_interaction(player_pos).get("kind", "")).is_empty():
			interaction_buffer = 0.0
			_interact()

func _make_light_texture() -> Texture2D:
	var img: Image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in range(64):
		for x in range(64):
			var r: float = Vector2(float(x) - 31.5, float(y) - 31.5).length() / 32.0
			var opacity: float = pow(clampf(1.0 - r, 0.0, 1.0), 1.7)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, opacity))
	return ImageTexture.create_from_image(img)

func _configure_lights() -> void:
	var light_texture: Texture2D = _make_light_texture()
	player_light = PointLight2D.new()
	player_light.texture = light_texture
	player_light.texture_scale = 5.0
	player_light.color = Color("#dad7cd")
	player_light.energy = 0.58
	player_light.enabled = false
	avatar.add_child(player_light)
	boss_light = PointLight2D.new()
	boss_light.texture = light_texture
	boss_light.texture_scale = 3.0
	boss_light.color = Color("#dda15e")
	boss_light.energy = 0.48
	boss_light.enabled = false
	world.add_child(boss_light)

func _play_sound(key: String) -> void:
	if sound_players.is_empty() or not ui.sound_enabled:
		return
	var file: String = "res://Assets/Audio/%s.wav" % key
	if not ResourceLoader.exists(file):
		return
	var player: AudioStreamPlayer = sound_players[sound_cursor % sound_players.size()]
	sound_cursor += 1
	player.stop()
	player.stream = load(file) as AudioStream
	player.play()

func _on_boss_phase_changed(next_phase: int) -> void:
	if state != "playing":
		return
	var text: String = str(["", "", "TERRITÓRIO EM CHAMAS", "CORAÇÃO EM CHAMAS"][clampi(next_phase, 1, 3)])
	ui.announce("LOBO DE FOGO  ·  %d/3" % next_phase, text, true)
	_play_sound("boss")

func _impact_pause() -> void:
	# Pausa curtíssima com temporizador independente da escala do jogo.
	# Desativada quando o jogador escolhe animações reduzidas.
	if ui.reduced_motion:
		return
	Engine.time_scale = 0.42
	await get_tree().create_timer(0.055, true, false, true).timeout
	Engine.time_scale = 1.0

func _exit_tree() -> void:
	Engine.time_scale = 1.0

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key: InputEventKey = event as InputEventKey
	if not key.pressed or key.echo:
		return
	if key.keycode == KEY_TAB:
		if state == "playing":
			state = "details"
			ui.show_details(true)
		elif state == "details":
			state = "playing"
			ui.show_details(false)
		return
	if key.keycode == KEY_ESCAPE:
		if state == "details":
			state = "playing"
			ui.show_details(false)
		elif state == "playing":
			state = "pause"
			ui.show_screen("pause", "tutorial" if stage == -1 else ("endless" if run_mode == 2 else ""))
		elif state == "pause":
			state = "playing"
			ui.show_screen("playing")
		elif state == "help_pause":
			state = "pause"
			ui.show_screen("pause", "endless" if run_mode == 2 else "")
	elif state == "playing":
		if key.keycode == KEY_E:
			interaction_buffer = 0.14
		elif key.keycode == KEY_SPACE:
			_use_power()

func _interact() -> void:
	var near: Dictionary = world.nearest_interaction(player_pos)
	var kind: String = str(near.get("kind", ""))
	var idx: int = int(near.get("index", -1))
	match kind:
		"animal":
			var animal_kind: int = int(world.animals[idx]["kind"])
			var species: String = world.animal_species(animal_kind)
			var biome_name: String = "TUTORIAL" if stage < 0 else BIOMES[stage]
			var first: bool = CollectionStore.discover(species, biome_name, seed_code)
			if first:
				discovered_count += 1
			world.remove_interaction("animal", idx)
			rescued += 1
			points += 100
			_play_sound("rescue")
			forest_health = mini(100, forest_health + 1)
			if hero == 2:
				health = mini(100, health + 8)
			ui.flash(("NOVA ESPÉCIE: " + species.replace("_", " ").to_upper() + "  •  +100 PTS") if first else "ANIMAL RESGATADO  •  +100 PTS")
			_boss_mission_progress(12)
		"extra":
			var secret_name: String = str(world.extras[idx]["species"])
			var is_secret: bool = bool(world.extras[idx].get("secret", true))
			var biome_secret: String = "TUTORIAL" if stage < 0 else BIOMES[stage]
			var new_secret: bool = CollectionStore.discover(secret_name, biome_secret, seed_code, is_secret)
			if new_secret:
				discovered_count += 1
			world.remove_interaction("extra", idx)
			points += 40
			ui.flash(("SEGREDO DESCOBERTO: " + secret_name.replace("_", " ").to_upper()) if new_secret else "ANIMAL SECRETO ENCONTRADO  •  +40 PTS")
		"trash":
			world.remove_interaction("trash", idx)
			cleaned += 1
			points += 45
			_play_sound("collect")
			forest_health = mini(100, forest_health + 2)
			ui.flash("HABITAT LIMPO  •  +45 PTS")
			_boss_mission_progress(7)
		"fire":
			if water < 1:
				ui.flash("SEM ÁGUA  •  PROCURE A FONTE AZUL!")
			else:
				water -= 1
				world.remove_interaction("fire", idx)
				extinguished += 1
				points += 70
				_play_sound("water")
				forest_health = mini(100, forest_health + 1)
				ui.flash("INCÊNDIO APAGADO  •  +70 PTS")
				_boss_mission_progress(18)
		"water":
			water = 5
			ui.flash("CANTIL REABASTECIDO  •  5/5")
		"heal":
			_take_healing_plant(idx)
		"exit":
			if run_mode == 2:
				ui.flash("SOBREVIVÊNCIA: SUPERE AS ONDAS E FAÇA PONTOS!")
			elif stage == 4:
				ui.flash("LOBO DE FOGO: PROTEJA A FLORESTA PARA VENCÊ-LO")
			elif _mission_done():
				_complete_level()
			else:
				ui.flash("PORTAL FECHADO  •  COMPLETE OS OBJETIVOS")
		_:
			ui.flash("APROXIME-SE DE UM ANIMAL, FOGO, LIXO OU FONTE", 1.9)
	_refresh_hud()

func _mission_done() -> bool:
	return rescued >= world.animal_target and cleaned >= world.trash_target and world.fires.is_empty()

func _boss_mission_progress(damage: int) -> void:
	if stage != 4 or state != "playing" or world.boss_health <= 0:
		return
	# O chefe enfraquece diretamente quando se preserva a floresta.
	var defeated: bool = world.damage_fire_wolf(damage)
	if defeated or _mission_done():
		world.damage_fire_wolf(1000)
		points += 600
		_finish_boss()
		return
	if damage >= 18:
		world.stun_fire_wolf(3.8 if difficulty == 0 else (3.0 if difficulty == 1 else 2.3))
		ui.flash("LOBO ATORDOADO  ·  APROVEITE A CHANCE!", 2.4)
	else:
		ui.flash("FLORESTA PROTEGIDA  ·  LOBO %d/%d" % [world.boss_health, world.boss_max_health], 1.8)

func _take_healing_plant(index: int) -> void:
	if index < 0 or index >= world.heal_items.size():
		return
	world.remove_interaction("heal", index)
	var amount: int = 55 - clampi(difficulty, 0, 2) * 8
	health = mini(100, health + amount)
	forest_health = mini(100, forest_health + 2)
	points += 15
	_play_sound("heal")
	ui.flash("FLOR DA VIDA  ·  +%d HP!" % amount, 2.6)

func _maybe_offer_heal() -> void:
	if state != "playing" or health > 38:
		return
	var limit: int = 3 if stage == 4 else 2
	if difficulty == 2:
		limit = maxi(1, limit - 1)
	if emergency_kits_spawned >= limit:
		return
	if world.spawn_emergency_heal(player_pos):
		emergency_kits_spawned += 1
		ui.flash("VIDA CRÍTICA!  ·  PROCURE A FLOR VERDE DE CURA", 3.4)

func _on_boss_warning() -> void:
	if state == "playing" and stage == 4:
		ui.flash("O LOBO MARCOU O CHÃO EM OCRE!  ·  SAIA DO CÍRCULO!", 3.0)
		_play_sound("boss")

func _use_power() -> void:
	if cooldown > 0.0:
		ui.flash("PODER RECARREGANDO  •  %.1fs" % cooldown, 1.5)
		return
	match hero:
		0:
			power_time = 3.2
			cooldown = COOLDOWNS[hero]
			ui.flash("LÉO  •  CORRIDA ESPECIAL ATIVADA")
		1:
			var count: int = world.douse_around(player_pos, 96.0, 3)
			if count <= 0:
				ui.flash("HELENA  •  APROXIME-SE DE UM INCÊNDIO")
				return
			extinguished += count
			points += count * 70
			forest_health = mini(100, forest_health + count)
			cooldown = COOLDOWNS[hero]
			ui.flash("HELENA  •  %d FOCOS CONTROLADOS" % count)
			_boss_mission_progress(18 * count)
		2:
			if health >= 100:
				ui.flash("RAFAEL  •  VIDA JÁ ESTÁ CHEIA")
				return
			health = mini(100, health + 35)
			cooldown = COOLDOWNS[hero]
			ui.flash("RAFAEL  •  PRIMEIROS SOCORROS +35")
		3:
			if water >= 5:
				ui.flash("CLARA  •  CANTIL JÁ ESTÁ CHEIO")
				return
			water = mini(5, water + 3)
			cooldown = COOLDOWNS[hero]
			ui.flash("CLARA  •  RESERVA DE ÁGUA +3")
	_refresh_hud()

func _enemy_contact(kind: String) -> void:
	if state != "playing" or invulnerability > 0.0:
		return
	var damage: int = 8 + difficulty * 3 if kind == "Lobo de Fogo" else (10 if kind == "Caçador" else 7) + difficulty * 3
	_take_damage(damage, "ATAQUE DE %s  •  -%d VIDA" % [kind.to_upper(), damage])

func _fire_contact() -> void:
	if state == "playing" and invulnerability <= 0.0:
		_take_damage(9 + difficulty * 2, "QUEIMADURA!  •  AFASTE-SE DAS CHAMAS")

func _take_damage(amount: int, message: String) -> void:
	invulnerability = 1.7 if stage == 4 else 1.3
	health = maxi(0, health - amount)
	avatar.hit_flash()
	ui.damage_flash()
	camera_shake = 5.0
	_play_sound("damage")
	_impact_pause()
	if health <= 0 and difficulty == 0 and not emergency_rescue_used:
		# No Fácil, uma recuperação de emergência por fase evita derrota repentina.
		emergency_rescue_used = true
		health = 24
		invulnerability = 3.0
		ui.flash("SEGUNDA CHANCE!  ·  PROCURE A FLOR DE CURA", 3.2)
		_maybe_offer_heal()
		return
	ui.flash(message, 1.9)
	if health <= 0:
		_defeat("O guardião perdeu toda a vida.")
	else:
		_maybe_offer_heal()

func _forest_decay(loss: int) -> void:
	if state != "playing":
		return
	forest_health = maxi(0, forest_health - loss)
	if forest_health <= 0:
		_defeat("A saúde da floresta chegou a zero.")
	elif forest_health <= 25:
		ui.flash("ALERTA  ·  SAÚDE DA FLORESTA EM PERIGO!", 2.4)

func _fire_spread() -> void:
	if state == "playing":
		ui.flash("ALERTA  •  UM NOVO INCÊNDIO SE ESPALHOU!")

func _complete_level() -> void:
	if state != "playing":
		return
	if stage >= 0:
		points += 250
		total_rescues += rescued
		stage_times.append(elapsed)
		_save_record("stage", stage, elapsed)
	if run_mode == 1 and stage >= 0:
		state = "result"
		_save_record("run", stage, run_elapsed)
		ui.show_screen("victory", "FASE COMPLETA  •  TEMPO %s  •  %d PTS  •  SEED %s" % [ScoreStore.format_time(elapsed), points, seed_code])
		return
	state = "result"
	if stage == -1:
		ui.show_screen("stage_clear", "Treinamento concluído. Pronto para a floresta!")
	else:
		ui.show_screen("stage_clear", "%s  •  TEMPO %s  •  %d PTS" % [BIOMES[stage], ScoreStore.format_time(elapsed), points])

func _finish_boss() -> void:
	if finale_started:
		return
	finale_started = true
	state = "cinematic"  # Interrompe o cronômetro neste instante.
	points += 800
	total_rescues += rescued
	stage_times.append(elapsed)
	_save_record("stage", 4, elapsed)
	_save_record("run", 4, run_elapsed)
	ui.show_finale()
	_finish_finale_later()

func _finish_finale_later() -> void:
	await get_tree().create_timer(6.3).timeout
	if state != "cinematic":
		return
	ui.hide_finale()
	state = "victory"
	# Mostra os principais dados sem revelar um painel técnico.
	ui.show_screen("victory", "TEMPO TOTAL %s  •  %d PTS  •  %d RESGATES\nSEED: %s" % [ScoreStore.format_time(run_elapsed), points, total_rescues, seed_code])

func _end_survival() -> void:
	if run_mode != 2 or endless_recorded:
		return
	if run_elapsed > 0.0:
		_save_record("run", stage, run_elapsed)
	endless_recorded = true
	state = "defeat"
	ui.show_screen("defeat", "DESAFIO ENCERRADO\nONDA %d  •  %d PTS  •  %s\nSEED: %s" % [wave_number, points, ScoreStore.format_time(run_elapsed), seed_code])

func _defeat(reason: String) -> void:
	if state != "playing":
		return
	state = "defeat"
	if run_mode == 0 and stage >= 0:
		campaign_attempts_left = maxi(0, campaign_attempts_left - 1)
		ui.set_campaign_attempts(campaign_attempts_left)
	if run_mode == 2 and not endless_recorded:
		_save_record("run", stage, run_elapsed)
		endless_recorded = true
	var attempts_info: String = "\nTENTATIVAS RESTANTES: %d/4" % campaign_attempts_left if run_mode == 0 else ""
	_play_sound("damage")
	ui.show_screen("defeat", "%s\nTEMPO %s  •  %d PTS%s\nSEED: %s" % [reason, ScoreStore.format_time(run_elapsed), points, attempts_info, seed_code])

func _save_record(category: String, phase: int, duration: float) -> void:
	var record: Dictionary = {
		"category": category,
		"generator_version": world.GENERATOR_VERSION,
		"mode": run_mode,
		"difficulty": difficulty,
		"stage": phase,
		"hero": HEROES[hero],
		"time": snappedf(duration, 0.01),
		"seed": seed_code,
		"points": points,
		"wave": wave_number,
		"forest": forest_health,
		"attempts_used": 4 - campaign_attempts_left if run_mode == 0 else 0,
		"date": Time.get_datetime_string_from_system(),
		"splits": stage_times.duplicate()
	}
	ScoreStore.save_record(record)

func _refresh_hud() -> void:
	var near: Dictionary = world.nearest_interaction(player_pos)
	var tip: String = "WASD MOVER  ·  E INTERAGIR  ·  ESPAÇO PODER  ·  TAB DETALHES"
	match str(near.get("kind", "")):
		"animal": tip = "E · RESGATAR ANIMAL"
		"extra": tip = "E · DESCOBRIR ANIMAL SECRETO"
		"trash": tip = "E · RECOLHER LIXO"
		"fire": tip = "E · APAGAR FOGO  (-1 ÁGUA)"
		"water": tip = "E · ENCHER CANTIL"
		"heal": tip = "E · CURAR VIDA  (+HP)"
		"exit": tip = "E · FINALIZAR" if _mission_done() else "PORTAL FECHADO · COMPLETE MISSÕES"
	var guide: String = ""
	if stage == -1:
		if rescued == 0:
			guide = "PASSO 1/4  •  ENCONTRE UM ANIMAL E APERTE E"
		elif cleaned == 0:
			guide = "PASSO 2/4  •  RECOLHA O LIXO COM E"
		elif not world.fires.is_empty():
			guide = "PASSO 3/4  •  APAGUE O FOGO COM E"
		else:
			guide = "PASSO 4/4  •  ENCONTRE O PORTAL AMARELO"
	if guide != "":
		tip = guide
	elif tip.begins_with("WASD") and elapsed > 8.0:
		tip = ""
	var title: String = "TUTORIAL  •  FLORESTA SEGURA" if stage == -1 else "FASE %d/5  •  %s  •  %s" % [stage + 1, BIOMES[stage], DIFFICULTIES[difficulty]]
	if run_mode == 2:
		title = "SOBREVIVÊNCIA  •  ONDA %d  •  %s" % [wave_number, DIFFICULTIES[difficulty]]
	var display_time: float = run_elapsed if stage >= 0 else elapsed
	ui.update_hud({
		"stage": title,
		"health": health, "stamina": stamina, "water": water,
		"rescued": rescued, "animals": world.animal_target,
		"cleaned": cleaned, "trash": world.trash_target,
		"fires": world.fires.size(), "hero": HEROES[hero], "hero_index": hero,
		"collection_count": discovered_count, "secrets": world.extras.size(),
		"forest": forest_health, "night": night,
		"cooldown": cooldown, "charge": 1.0 - cooldown / COOLDOWNS[hero],
		"power": HERO_POWERS[hero],
		"time": ScoreStore.format_time(display_time), "seed": seed_code,
		"mode": MODES[run_mode], "mode_index": run_mode, "points": points,
		"attempts_left": campaign_attempts_left,
		"boss_health": world.boss_health, "boss_max_health": world.boss_max_health,
		"boss_stun_time": world.boss_stun_time, "boss_phase": world.boss_phase, "stage_index": stage,
		"hint": tip, "tutorial": guide, "player_pos": player_pos
	}, world)
