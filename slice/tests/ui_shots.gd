extends SceneTree
## U-01/F-15 Screenshots (vorher/nachher vergleichbar, nutzt nur API, die es in beiden Ständen gibt):
##   xvfb-run -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --path slice -s res://tests/ui_shots.gd -- <out_dir>
## 1 Startdialog, 2 HUD + angedocktes Panel mit Lizenzknopf (Getreidefarm ohne Lizenz),
## 3 Panel „Lizenz aktiv – noch mm:ss“ nach Aufbau, 4 Styleguide (falls vorhanden).

var m: Node
var out := "user://"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else "user://"
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	_run.call_deferred()


func _wait(sec: float) -> void:
	await create_timer(sec).timeout
	for i in 3:
		await process_frame


func _shot(name: String) -> void:
	await _wait(0.4)
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(out.path_join(name))
	print("saved ", out.path_join(name), " ", img.get_size())


func _clear_toast() -> void:
	m.toast_time = 0.0
	m.toast_label.text = ""


func _run() -> void:
	await _shot("ui_1_startdialog.png")
	m.place_hq("haberau")
	_clear_toast()
	var farm = m.by_id["farm_1"]
	var mill = m.by_id["muehle_1"]
	var hab = m.by_id["haberau"]
	m.focus(Vector2(366, 342), 2.2)
	m.open_panel(farm)
	await _shot("ui_2_hud_panel_lizenz.png")
	m.ui_buy_licence(farm)
	m.ui_buy_licence(mill)
	m._set_tool(m.Tool.ROAD)
	m.begin_drag(farm.anchor())
	m.drag_to(mill.anchor())
	m.end_drag()
	var corner := Vector2i(hab.anchor().x, mill.anchor().y)
	var ys := -1
	for y in range(mill.anchor().y, hab.anchor().y + 1):
		if m.city_streets.has(Vector2i(hab.anchor().x, y)):
			ys = y
			break
	m.begin_drag(mill.anchor())
	m.drag_to(corner)
	m.end_drag()
	m.begin_drag(corner)
	m.drag_to(Vector2i(hab.anchor().x, ys))
	m.end_drag()
	m._set_tool(m.Tool.TRUCK_LINE)
	m.click(farm.anchor())
	m.click(mill.anchor())
	m.click(mill.anchor())
	m.click(hab.anchor())
	m._set_tool(m.Tool.NONE)
	m.sim_hover_active = true
	m.sim_hover = Vector2i(-1, -1)
	m.run_ticks(3000)
	m.close_panel()
	await _wait(0.3)
	m.open_panel(farm)
	_clear_toast()
	await _shot("ui_3_panel_lizenz_aktiv.png")
	# Toast + Abriss-Sperre (B-01) sichtbar machen
	m.close_panel()
	m._toast("Lizenz Mühle: 140 $, gilt 30:00 Spielzeit und verlängert sich automatisch.", 8.0)
	await _shot("ui_4_toast.png")
	_clear_toast()
	if ResourceLoader.exists("res://ui/styleguide.tscn"):
		m.queue_free()
		await process_frame
		var sg = load("res://ui/styleguide.tscn").instantiate()
		root.add_child(sg)
		await _shot("ui_5_styleguide.png")
		if sg.has_method("scroll_to_bottom"):
			sg.scroll_to_bottom()
			await _shot("ui_6_styleguide_unten.png")
	quit(0)
