extends SceneTree
## QA manual automatizável no Godot 4.7.2: menus, texturas e semente.
## godot --headless --path Eco --script res://Adventure/qa_visual.gd
const MainScene = preload("res://Adventure/main.tscn")

func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	var app: Variant = MainScene.instantiate()
	get_root().add_child(app)
	assert(app.ui != null, "Interface não iniciou")
	for screen in ["main", "modes", "difficulty", "characters", "seed", "tutorial_offer", "help", "settings", "collection", "scores", "defeat", "victory"]:
		app.ui.show_screen(screen, "QA visual")
		assert(app.ui.menu_box.get_child_count() > 0, "Menu vazio: " + screen)
	app.seed_code = "QA-VISUAL-2026"
	app.difficulty = 1
	app.hero = 2
	app._start_level(0)
	assert(app.world.animals.size() == app.world.animal_target, "Animais da fase")
	assert(app.ui.portrait.texture != null, "Retrato não foi importado")
	app._refresh_hud()
	var original: Array = app.world.animals.duplicate(true)
	app.world.extras_enabled = false
	app.world.setup(0, 1, "QA-VISUAL-2026", 0)
	assert(app.world.animals == original, "Cosméticos alteraram a seed principal")
	print("QA VISUAL: menus, HUD, texturas e seed verificados nesta execução.")
	app.queue_free()
	quit(0)
