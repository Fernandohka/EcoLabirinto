extends SceneTree
## Rode: godot --headless --path Eco --script res://Adventure/qa_menu_v7_1.gd
const MainScene = preload("res://Adventure/main.tscn")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var app: Variant = MainScene.instantiate()
	get_root().add_child(app)
	assert(app.ui != null, "UI não iniciou")
	var screens: Array[String] = ["main", "modes", "difficulty", "stage_select", "characters", "seed", "tutorial_offer", "help", "settings", "collection", "scores"]
	for screen in screens:
		app.ui.show_screen(screen)
		assert(app.ui.menu_box.get_child_count() > 2, "Menu vazio: " + screen)
		assert(app.ui.menu_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "Scroll horizontal indevido: " + screen)
		var headline: Label = app.ui.menu_box.get_child(1) as Label
		assert(headline != null, "Título ausente: " + screen)
		assert(headline.custom_minimum_size.y >= 40.0, "Título sem espaço: " + screen)
		await process_frame
		assert(headline.size.y >= 40.0, "Título colapsado: " + screen)
		var labels: Array[Label] = []
		_collect_labels(app.ui.menu_box, labels)
		var visible_texts: int = 0
		for label in labels:
			if not label.text.is_empty():
				assert(label.text_overrun_behavior != TextServer.OVERRUN_TRIM_ELLIPSIS or label.autowrap_mode == TextServer.AUTOWRAP_OFF, "Rótulo de menu truncado: " + screen)
				visible_texts += 1
		assert(visible_texts >= 3, "Faltam textos: " + screen)
	app.ui.show_screen("main")
	assert(app.ui.showcase_title.text.length() > 10, "Chamada da floresta ausente")
	assert(app.ui.showcase_title.custom_minimum_size.y > 0.0, "Texto da vitrine sem altura")
	print("QA MENU V7.1: textos, dimensões, navegação e telas OK")
	app.queue_free()
	quit(0)

func _collect_labels(node: Node, output: Array[Label]) -> void:
	for child in node.get_children():
		if child is Label:
			output.append(child as Label)
		_collect_labels(child, output)
