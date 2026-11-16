extends SceneTree
## Executar com: godot --headless --path Eco --script res://Adventure/qa_v7.gd
const MainScene = preload("res://Adventure/main.tscn")

func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	var app: Variant = MainScene.instantiate()
	get_root().add_child(app)
	assert(app.ui != null, "HUD não foi criada")
	assert(app.ui.hud_root.find_children("*", "ScrollContainer", true, false).is_empty(), "HUD não pode ter scroll")
	assert(app.ui.hero_label.autowrap_mode == TextServer.AUTOWRAP_OFF, "Texto do guardião deve ser horizontal")
	app.seed_code = "ECO-QA-V7"
	app.run_mode = 0
	app.difficulty = 0
	app.hero = 0
	app._start_level(4)
	assert(app.world.terrain_layer != null, "Camada de terreno ausente")
	assert(int(app.world.terrain_layer.get("rebuild_count")) == 1, "Terreno deve ser construído apenas na geração da fase")
	app.world.queue_redraw()
	assert(int(app.world.terrain_layer.get("rebuild_count")) == 1, "Redesenho dinâmico não pode reconstruir a mata")
	assert(app.world.boss_health == 75, "Lobo no Fácil deve ter 75 HP")
	assert(app.world.fires.size() <= 3, "Fogo no Fácil acima do limite")
	app.world.enemies.clear()
	app.world.fires.clear()
	app.world.boss_position = app.world.exit_position
	app.health = 28
	app._maybe_offer_heal()
	assert(app.world.heal_items.size() == 1, "Cura deve surgir perto do jogador")
	var med: Vector2 = app.world.heal_items[0]["pos"]
	assert(not app.world.astar.get_id_path(app.world.world_cell(app.player_pos), app.world.world_cell(med)).is_empty(), "Cura inacessível")
	app._take_healing_plant(0)
	assert(app.health > 28, "Cura não restaurou a vida")
	app.world.damage_fire_wolf(25)
	assert(app.world.boss_phase == 2, "Lobo deveria passar à fase 2")
	app.world.damage_fire_wolf(25)
	assert(app.world.boss_phase == 3, "Lobo deveria passar à fase 3")
	app._start_level(0)
	for i in range(4):
		app._defeat("TESTE")
		assert(app.campaign_attempts_left == 3 - i, "Campanha deve descontar uma tentativa por derrota")
		if i < 3:
			app._retry()
	assert(app.campaign_attempts_left == 0, "Quatro derrotas encerram a campanha")
	for sound in ["rescue", "collect", "water", "heal", "damage", "boss"]:
		assert(ResourceLoader.exists("res://Assets/Audio/%s.wav" % sound), "Som ausente: " + sound)
	print("QA V7: terreno estático, HUD, cura navegável, 3 fases do Lobo, 4 tentativas, áudio OK")
	app.queue_free()
	quit(0)
