extends SceneTree
## W-04 (S7, Mira): Screenshots der Kachel-Straßen in der S7-Welt.
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --path slice -s res://tests/w04_shots.gd -- <out_dir>
## Bilder: w04_kreuzung_nah, w04_700m, w04_vorschau_fehler, w04_bruecke, w04_gleis, w04_vorschau_ok.

const Welt := preload("res://world/welt.gd")
const MainScript := preload("res://main.gd")

var m: Node


func _initialize() -> void:
	MainScript.world_override = "s7"
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(path: String) -> void:
	m.toast_time = 0.0
	m.toast_label.text = ""
	await _frames(12)
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(path)
	print("saved ", path, " ", img.get_size())


func z(meter: float) -> float:
	return Welt.zoom_for_distance_m("s7", meter)


func _build(a: Vector2i, b: Vector2i, rail := false) -> bool:
	m._set_tool(m.Tool.RAIL if rail else m.Tool.ROAD)
	m.begin_drag(a)
	m.drag_to(b)
	var r: bool = m.end_drag()
	m._set_tool(m.Tool.NONE)
	return r


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "user://"
	m.place_hq("haberau")
	m.eco.cash_cent = 50_000_000
	var hab = m.by_id["haberau"]
	var farm = m.by_id["farm_1"]
	var mill = m.by_id["muehle_1"]
	print("bau farm1->muehle1 ", _build(farm.anchor(), mill.anchor()))
	print("bau muehle1->haberau ", _build(mill.anchor(), hab.anchor()))
	# Gleis mit Kurven und Kreuzung neben Haberau
	var c0: Vector2i = hab.anchor() + Vector2i(22, -6)
	print("gleis ", _build(c0, c0 + Vector2i(8, 0), true), " ", _build(c0 + Vector2i(8, 0), c0 + Vector2i(8, 6), true),
		" ", _build(c0 + Vector2i(4, -3), c0 + Vector2i(4, 4), true))
	# Straßen-Kreuzung, T, Kurve, Ende auf freier Fläche
	var r0: Vector2i = hab.anchor() + Vector2i(22, 10)
	_build(r0, r0 + Vector2i(8, 0))
	_build(r0 + Vector2i(4, -3), r0 + Vector2i(4, 3))
	_build(r0 + Vector2i(8, 0), r0 + Vector2i(8, 4))
	_build(r0 + Vector2i(0, 0), r0 + Vector2i(0, -3))
	m.sim_hover_active = true
	m.sim_hover = Vector2i(-1, -1)
	m.set_speed(0)
	# 1) Kreuzung nah (Stadt): Stadtstraßen-Kreuzung im Zentrum
	var cx: Vector2i = hab.anchor()
	for dy in range(-6, 7):
		for dx in range(-6, 7):
			var c: Vector2i = hab.anchor() + Vector2i(dx, dy)
			if m.city_streets.has(c) and m.road_tiles.road_mask(c) == 15:
				cx = c
	m.focus(Vector2(cx.x + 0.5, cx.y + 0.5), z(140.0))
	await _shot(out.path_join("w04_kreuzung_nah.png"))
	m.focus(Vector2(r0.x + 4.5, r0.y + 0.5), z(260.0))
	await _shot(out.path_join("w04_kacheln_frei.png"))
	# 2) 700-m-Ansicht über Haberau
	m.focus(Vector2(hab.anchor().x + 0.5, hab.anchor().y + 0.5), z(700.0))
	await _shot(out.path_join("w04_700m.png"))
	# 3) Brücke + Gleis nah
	var br := Vector2i(-1, -1)
	for c in m.roads:
		if m.terrain_at(c) == m.Terrain.WATER:
			br = c
			break
	print("bruecke ", br)
	if br.x >= 0:
		m.focus(Vector2(br.x + 0.5, br.y + 0.5), z(220.0))
		await _shot(out.path_join("w04_bruecke.png"))
	m.focus(Vector2(c0.x + 5.5, c0.y + 1.5), z(260.0))
	await _shot(out.path_join("w04_gleis.png"))
	# 4) Vorschau mit Fehler: diagonal über den Fluss (B1) mit Preis und Ursache am Cursor
	var bad_a := Vector2i(-1, -1)
	var bad_b := Vector2i(-1, -1)
	for c in m.roads:
		if m.terrain_at(c) == m.Terrain.WATER:
			bad_a = c + Vector2i(-6, 4)
			bad_b = c + Vector2i(4, 14)
			break
	m.sim_hover_active = false
	m._set_tool(m.Tool.ROAD)
	m.begin_drag(bad_a)
	m.drag_to(bad_b)
	m.focus(Vector2((bad_a.x + bad_b.x) * 0.5, (bad_a.y + bad_b.y) * 0.5), z(700.0))
	await _frames(3)
	m.drag_to(bad_b)
	m._update_cursor_label()
	print("vorschau ok=", m.plan.get("ok"), " grund=", m.plan.get("reason"), " kopf=", m.cursor_cost.text)
	await _shot(out.path_join("w04_vorschau_fehler.png"))
	m.cancel_drag()
	# 5) Vorschau baubar mit Preis
	m.begin_drag(r0 + Vector2i(0, 6))
	m.drag_to(r0 + Vector2i(10, 9))
	m.focus(Vector2(r0.x + 5, r0.y + 7), z(500.0))
	await _frames(3)
	m.drag_to(r0 + Vector2i(10, 9))
	m._update_cursor_label()
	await _shot(out.path_join("w04_vorschau_ok.png"))
	m.cancel_drag()
	print("counts ", m.road_tiles.counts)
	quit(0)
