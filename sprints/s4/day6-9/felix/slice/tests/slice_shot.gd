extends SceneTree
## Screenshots Start und nach dem 30-min-Durchlauf:
##   xvfb-run -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --path slice -s res://tests/slice_shot.gd -- <out_dir>

var m: Node


func _initialize() -> void:
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(path: String) -> void:
	await _frames(10)
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(path)
	print("saved ", path, " ", img.get_size())


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "user://"
	await _shot(out.path_join("shot_start.png"))
	m.start_game("agrar")
	m.toast_time = 0.0
	m.toast_label.text = ""
	await _shot(out.path_join("shot_start_agrar.png"))
	var farm = m.by_id["farm_1"]
	var mill = m.by_id["muehle_1"]
	var hab = m.by_id["haberau"]
	m.ui_buy_licence(farm)
	m.ui_buy_licence(mill)
	# Ghost-Vorschau beim Ziehen (S-08: weiß mit Saum, rot schraffiert)
	m.focus(Vector2(366, 338), 1.3)
	m._set_tool(m.Tool.ROAD)
	m.begin_drag(farm.anchor())
	m.drag_to(mill.anchor())
	m.toast_label.text = ""
	await _shot(out.path_join("shot_ghost.png"))
	m.end_drag()
	m._set_tool(m.Tool.TRUCK_LINE)
	m.click(farm.anchor())
	m.click(mill.anchor())
	var corner := Vector2i(hab.anchor().x, mill.anchor().y)
	var ys := -1
	for y in range(mill.anchor().y, hab.anchor().y + 1):
		if m.city_streets.has(Vector2i(hab.anchor().x, y)):
			ys = y
			break
	m._set_tool(m.Tool.ROAD)
	m.begin_drag(mill.anchor())
	m.drag_to(corner)
	m.end_drag()
	m.begin_drag(corner)
	m.drag_to(Vector2i(hab.anchor().x, ys))
	m.end_drag()
	m._set_tool(m.Tool.TRUCK_LINE)
	m.click(mill.anchor())
	m.click(hab.anchor())
	m._set_tool(m.Tool.NONE)
	m.sim_hover_active = true
	m.sim_hover = Vector2i(-1, -1)
	m.run_ticks(18000)
	m.open_panel(mill)
	m.focus(Vector2(364, 344), 2.0)
	m.toast_time = 0.0
	m.toast_label.text = ""
	m.set_speed(1)
	await _shot(out.path_join("shot_after_30min.png"))
	print("Kasse nach 30 min: ", m.money_str(m.eco.cash_cent), " Lieferungen mit Gewinn: ", m.deliveries_profit)
	quit(0)
