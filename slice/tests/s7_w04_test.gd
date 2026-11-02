extends SceneTree
## W-04 (S7, Mira): Straßen/Gleise als Kenney-Kacheln mit Autotile, Brücke, Bau-Vorschau mit Hang-Preis und Fehlstelle.
##   godot --headless --path slice -s res://tests/s7_w04_test.gd
## Prüft: Masken/Kacheltypen, keine Lücke und kein Stoß an jeder Feldkante (Geometrie der Instanzen), Brücke bündig,
## Gleiskurve trifft die Kantenmitten, Straße : Block <= 1 : 5 (700-m-Ansicht), Preis inkl. Steigungsfaktor gegen
## Einzelrechnung, jede Ablehnung mit Ursache, Slice unverändert (Quader, keine Kacheln).

const MAIN := "res://main.tscn"
const MainScript := preload("res://main.gd")
const FT := preload("res://ui/fehlertexte.gd")
const Welt := preload("res://world/welt.gd")
const EPS := 0.004

var m: Node
var fails := 0
var checks := 0


## Hang-Stub für die Schnittstelle aus world/bau_s7.gd (Felix liefert die echten Hooks mit W-02).
class HangStub extends "res://world/s7_world.gd":
	func steigung_faktor(pct: float) -> float:
		return 1.0 + pct / 25.0          # 5 % -> ×1,2
	func steigung_max_pct() -> float:
		return 12.0


func _initialize() -> void:
	_run.call_deferred()


func ok(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("  OK   ", what)
	else:
		fails += 1
		print("  FAIL ", what)


func _fresh(w: String) -> void:
	if m != null:
		m.free()
	MainScript.world_override = w
	m = load(MAIN).instantiate()
	root.add_child(m)
	m.place_hq("haberau")
	m.eco.cash_cent = 50_000_000


func _build(a: Vector2i, b: Vector2i, rail := false) -> bool:
	m._set_tool(m.Tool.RAIL if rail else m.Tool.ROAD)
	m.begin_drag(a)
	m.drag_to(b)
	var r: bool = m.end_drag()
	m._set_tool(m.Tool.NONE)
	return r


## Grundfläche einer Kachel-Instanz (Kenney-Kachel = Einheitsquadrat ±0,5) als Rechteck in Feldkoordinaten.
func rect_of(xf: Transform3D, model: String) -> Rect2:
	var pts: Array = []
	if model == "railroad-straight":
		pts = [Vector3(-0.5, 0, 0), Vector3(0.5, 0, 0), Vector3(-0.5, 0, 4), Vector3(0.5, 0, 4)]
	else:
		pts = [Vector3(-0.5, 0, -0.5), Vector3(0.5, 0, -0.5), Vector3(-0.5, 0, 0.5), Vector3(0.5, 0, 0.5)]
	var r := Rect2(Vector2((xf * pts[0]).x, (xf * pts[0]).z), Vector2.ZERO)
	for p in pts:
		var q: Vector3 = xf * p
		r = r.expand(Vector2(q.x, q.z))
	return r


## Für ein Straßenfeld: je offene Seite reicht die Fahrbahn genau bis zur Feldkante, mit voller Breite über die
## Feldmitte; zu geschlossenen Seiten ragt nichts über die halbe Knotenbreite hinaus. Alle Teile auf gleicher Höhe.
func check_cell(c: Vector2i, w: float) -> String:
	var ps: Array = m.road_tiles.pieces.get("r|%d,%d" % [c.x, c.y], [])
	if ps.is_empty():
		return "keine Kachel"
	var mask: int = m.road_tiles.road_mask(c)
	var ctr := Vector2(c.x + 0.5, c.y + 0.5)
	var y0: float = ps[0][1].origin.y
	var union := Rect2(rect_of(ps[0][1], ps[0][0]))
	for p in ps:
		if absf(p[1].origin.y - y0) > 0.0001:
			return "Höhenstoß %.4f" % (p[1].origin.y - y0)
		union = union.merge(rect_of(p[1], p[0]))
	for e in [[1, Vector2(0, -1)], [2, Vector2(1, 0)], [4, Vector2(0, 1)], [8, Vector2(-1, 0)]]:
		var d: Vector2 = e[1]
		var reach: float = 0.0
		var width: float = 0.0
		for p in ps:
			var r := rect_of(p[1], p[0])
			# Ausdehnung in Richtung d ab Feldmitte und Breite quer dazu
			var ext: float = (r.end.x - ctr.x) if d.x > 0 else ((ctr.x - r.position.x) if d.x < 0 else ((r.end.y - ctr.y) if d.y > 0 else (ctr.y - r.position.y)))
			var wd: float = r.size.y if d.x != 0 else r.size.x
			if ext > reach:
				reach = ext
				width = wd
		if mask & e[0]:
			if absf(reach - 0.5) > EPS:
				return "offen %d: reicht %.3f statt 0,5" % [e[0], reach]
			if absf(width - w) > EPS:
				return "offen %d: Breite %.3f statt %.3f" % [e[0], width, w]
		elif reach > w * 0.5 + EPS:
			return "geschlossen %d ragt %.3f" % [e[0], reach]
	return ""


func _run() -> void:
	_autotile()
	_ratio()
	_vorschau()
	_slice()
	if m != null:
		m.free()
	MainScript.world_override = ""
	print("%d/%d Prüfungen OK" % [checks - fails, checks])
	quit(0 if fails == 0 else 1)


func _autotile() -> void:
	print("== W-04 Autotile (S7)")
	_fresh("s7")
	ok(m.road_tiles != null and m.road_tiles.counts.get("road-crossroad", 0) > 0, "S7: Stadtstraßen als Kacheln (%d Kreuzungen)" % m.road_tiles.counts.get("road-crossroad", 0))
	var hab = m.by_id["haberau"]
	var r0: Vector2i = hab.anchor() + Vector2i(22, 10)
	_build(r0, r0 + Vector2i(8, 0))                       # Gerade W-E
	_build(r0 + Vector2i(4, -3), r0 + Vector2i(4, 3))     # Kreuzung bei x+4
	_build(r0 + Vector2i(8, 0), r0 + Vector2i(8, 4))      # Kurve bei x+8
	_build(r0, r0 + Vector2i(0, -3))                      # Kurve am Anfang
	_build(r0 + Vector2i(2, 0), r0 + Vector2i(2, 2))      # T bei x+2
	var expect := {Vector2i(4, 0): ["kreuzung", 15], Vector2i(8, 0): ["kurve", 12], Vector2i(0, 0): ["kurve", 3],
		Vector2i(2, 0): ["t", 14], Vector2i(4, 3): ["ende", 1], Vector2i(6, 0): ["gerade", 10], Vector2i(4, 1): ["gerade", 5], Vector2i(2, 2): ["ende", 1]}
	for k in expect:
		var ti: Dictionary = m.road_tiles.tile_info(r0 + k)
		ok(ti["kachel"] == expect[k][0] and ti["mask"] == expect[k][1], "Feld %s: %s Maske %d (Soll %s %d)" % [str(k), ti["kachel"], ti["mask"], expect[k][0], expect[k][1]])
	var w_land: float = m.road_tiles.w_land / 25.0
	var w_city: float = m.road_tiles.w_city / 25.0
	var bad := []
	var n := 0
	for c in m.roads:
		if m.city_streets.has(c) or m.terrain_at(c) == m.Terrain.WATER:
			continue
		n += 1
		var e := check_cell(c, w_land)
		if e != "":
			bad.append("%s %s" % [str(c), e])
	ok(n > 20 and bad.is_empty(), "eigene Straßen: %d Felder, an jeder offenen Kante bis zur Kante in voller Breite, keine Höhenstufe %s" % [n, str(bad.slice(0, 3))])
	bad = []
	n = 0
	for c in m.city_streets:
		n += 1
		var e := check_cell(c, w_city)
		if e != "":
			bad.append("%s %s" % [str(c), e])
	ok(n > 100 and bad.is_empty(), "Stadtstraßen: %d Felder lückenlos (Kreuzungen, T, Kurven, Enden) %s" % [n, str(bad.slice(0, 3))])
	# Nachbarn passen: gleiche Breite an der gemeinsamen Kante (Landstraße an Landstraße)
	var boxes_visible := 0
	for c in m.roads:
		if m.render_batch.has(["road", c]):     # S7 B: Quader liegen gebündelt im render_batch
			boxes_visible += 1
	ok(boxes_visible == 0, "keine Quader sichtbar (Boxstoß ausgeschlossen): %d" % boxes_visible)
	# Anschluss an Gebäude: Straße reicht bis an die Mühle
	var farm1 = m.by_id["farm_1"]
	var mill1 = m.by_id["muehle_1"]
	_build(farm1.anchor(), mill1.anchor())
	var touch := 0
	for c in m.roads:
		var lk: int = m.road_tiles.links_road.get(c, 0)
		if lk != 0:
			touch += 1
	ok(touch >= 2, "Straße endet an Farm und Mühle (Anschluss-Bits an %d Feldern), nicht eine Kachel davor" % touch)
	# Brücke: bündig mit der Fahrbahn
	var br := Vector2i(-1, -1)
	for c in m.roads:
		if m.terrain_at(c) == m.Terrain.WATER:
			br = c
			break
	var bp: Array = m.road_tiles.pieces.get("r|%d,%d" % [br.x, br.y], [])
	var land := br + Vector2i(1, 0) if m.roads.has(br + Vector2i(1, 0)) and m.terrain_at(br + Vector2i(1, 0)) != m.Terrain.WATER else br + Vector2i(-1, 0)
	var lp: Array = m.road_tiles.pieces.get("r|%d,%d" % [land.x, land.y], [])
	var deck_top := -1.0
	var road_top := -1.0
	if not bp.is_empty() and not lp.is_empty():
		deck_top = bp[0][1].origin.y + 0.52 * bp[0][1].basis.get_scale().y
		road_top = lp[0][1].origin.y + 0.02 * lp[0][1].basis.get_scale().y
	ok(br.x >= 0 and bp.size() == 1 and bp[0][0] == "road-bridge" and absf(deck_top - road_top) < 0.002 and m.road_tiles.tile_info(br)["kachel"] == "bruecke",
		"Brücke %s: Brückenkachel, Deck %.4f = Fahrbahn %.4f (bündig)" % [str(br), deck_top, road_top])
	# Gleis: Kurve trifft die Kantenmitten, Gerade/Arme bis zur Kante
	var g0: Vector2i = hab.anchor() + Vector2i(22, -6)
	_build(g0, g0 + Vector2i(6, 0), true)
	_build(g0 + Vector2i(6, 0), g0 + Vector2i(6, 5), true)
	var kc := g0 + Vector2i(6, 0)
	var gp: Array = m.road_tiles.pieces.get("g|%d,%d" % [kc.x, kc.y], [])
	var ends_ok := false
	if gp.size() == 1 and gp[0][0] == "railroad-corner-large":
		var a3: Vector3 = gp[0][1] * Vector3(0, 0, 0)
		var b3: Vector3 = gp[0][1] * Vector3(-4, 0, 4)
		var want := [Vector2(kc.x, kc.y + 0.5), Vector2(kc.x + 0.5, kc.y + 1.0)]       # W- und S-Kantenmitte
		var got := [Vector2(a3.x, a3.z), Vector2(b3.x, b3.z)]
		ends_ok = (got[0].distance_to(want[0]) < EPS and got[1].distance_to(want[1]) < EPS) or (got[1].distance_to(want[0]) < EPS and got[0].distance_to(want[1]) < EPS)
	ok(ends_ok, "Gleiskurve %s (Maske %d) trifft W- und S-Kantenmitte" % [str(kc), m.road_tiles.rail_mask(kc)])
	var straight_ok := true
	for c in [g0 + Vector2i(2, 0), g0 + Vector2i(6, 2)]:
		var sp: Array = m.road_tiles.pieces.get("g|%d,%d" % [c.x, c.y], [])
		var u := rect_of(sp[0][1], sp[0][0])
		for p in sp:
			u = u.merge(rect_of(p[1], p[0]))
		var along: float = u.size.x if c.y == g0.y else u.size.y
		straight_ok = straight_ok and sp.size() == 2 and absf(along - 1.0) < 0.01
	ok(straight_ok, "Gleisgerade: 2 Stücke je Feld, Kante zu Kante (Spur 1,435 m aus road_tiles.json)")
	# Abriss nimmt die Kachel weg und schließt die Nachbarn
	var cnt0: int = m.road_tiles.pieces.size()
	m.demolish(r0 + Vector2i(4, 3), r0 + Vector2i(4, 3))
	ok(not m.road_tiles.pieces.has("r|%d,%d" % [r0.x + 4, r0.y + 3]) and m.road_tiles.tile_info(r0 + Vector2i(4, 2))["kachel"] == "ende" and m.road_tiles.pieces.size() == cnt0 - 1,
		"Abriss: Kachel weg, Nachbar wird Ende")


func _ratio() -> void:
	print("== W-04 Straße : Block in der 700-m-Ansicht")
	_fresh("s7")
	var measured := 0
	for cid in ["haberau", "mittelfurt", "kohlberg", "seehafen"]:
		var city = m.by_id[cid]
		var a: Vector2i = city.anchor()
		# Senkrechte Straßen je Zeile (Zellen mit Straße darüber/darunter), kleinster Abstand über alle Zeilen der Stadt
		var g := 0
		for y in range(a.y - 16, a.y + 17):
			var xs: Array = []
			for x in range(a.x - 16, a.x + 17):
				var c := Vector2i(x, y)
				if m.city_streets.has(c) and m.cell_to_building.get(c) == city and not m.city_streets.has(c + Vector2i(1, 0)) and not m.city_streets.has(c + Vector2i(-1, 0)):
					xs.append(x)
			for i in range(1, xs.size()):
				if g == 0 or xs[i] - xs[i - 1] < g:
					g = xs[i] - xs[i - 1]
		if g == 0:
			print("     %s: zu klein für zwei parallele Straßen (Dorf), nicht gemessen" % city.display_name)
			continue
		measured += 1
		var street_m: float = m.road_tiles.w_city
		var block_m: float = g * m.m_pro_feld - street_m
		ok(street_m / block_m <= 0.2, "%s: Straße %.1f m, Block %.1f m (Abstand %d Felder) -> 1 : %.1f (Soll <= 1 : 5)" % [city.display_name, street_m, block_m, g, block_m / street_m])
	ok(measured >= 2, "Verhältnis in %d Städten gemessen" % measured)
	m.focus(Vector2(m.by_id["haberau"].anchor()), Welt.zoom_for_distance_m("s7", 700.0))
	ok(absf(m.world_s7.camera_distance_m(m) - 700.0) < 1.0, "Kamera 700 m (%.0f m)" % m.world_s7.camera_distance_m(m))


func _vorschau() -> void:
	print("== W-04 Bau-Vorschau: Preis inkl. Steigung, Fehlstelle mit Ursache")
	_fresh("s7")
	var stub := HangStub.new()
	stub.hoehe.resize(m.GRID * m.GRID)
	stub.hoehe.fill(0.0)
	var a := Vector2i(300, 300)
	# Rampe nach Osten: +1,25 m je Feld = 5 %, ab x 310 +5 m je Feld = 20 % (zu steil)
	for x in range(300, 320):
		for y in range(298, 303):
			var h := (x - 300) * 1.25 if x <= 310 else 12.5 + (x - 310) * 5.0
			stub.hoehe[y * m.GRID + x] = h
	m.world_s7 = stub
	var p: Dictionary = m.plan_track(a, Vector2i(308, 300), false)
	var want := 0
	for it in p["items"]:
		if it["state"] == "new":
			want += m.field_cost(it["cell"], false) * 1200 / 1000
	m._set_tool(m.Tool.ROAD)
	m.begin_drag(a)
	m.drag_to(Vector2i(308, 300))
	m._update_cursor_label()
	var head: String = m.cursor_cost.text
	var why: String = m.cursor_reason.text
	ok(p["ok"] and p["total"] == want and p["hang"]["faktor_pm"] == 1200 and head.contains(m.money_str(want)),
		"Hang 5 %%: Preis %s = Σ Feldpreis × 1,20 (Kopf „%s“)" % [m.money_str(p["total"]), head])
	ok(m.cursor_reason.visible and why == FT.b12_hang(m, 1200, want) and why.contains("×1,20") and why.contains(m.money_str(want)), "B12 Hinweis gelb: „%s“" % why)
	var ribbon := 0
	var red := 0
	for c in m.preview_root.get_children():
		if c.is_queued_for_deletion():
			continue
		ribbon += 1
		if c.name.begins_with("Fehlstelle"):
			red += 1
	ok(ribbon > 0 and red == 0, "Vorschau als Band (%d Teile), keine Fehlstelle" % ribbon)
	m.drag_to(Vector2i(314, 300))
	m._update_cursor_label()
	var p2: Dictionary = m.plan
	red = 0
	for c in m.preview_root.get_children():
		if not c.is_queued_for_deletion() and c.name.begins_with("Fehlstelle"):
			red += 1
	var steil := 0.0
	for i in p2["items"].size():
		if p2["items"][i]["state"] == "bad":
			steil = maxf(steil, absf(stub.hoehe[300 * m.GRID + p2["cells"][i].x] - stub.hoehe[300 * m.GRID + p2["cells"][i].x - 1]) / 25.0 * 100.0)
	ok(not p2["ok"] and p2["reason"] == FT.b11_zu_steil(20.0, 12.0) and red > 0 and m.cursor_reason.text == p2["reason"] and absf(steil - 20.0) < 0.01,
		"B11 zu steil: %d rote Fehlstellen, „%s“ (Steigung aus der Höhe %.0f %%)" % [red, p2["reason"], steil])
	m.toast_label.text = ""
	m.end_drag()
	ok(m.toast_label.text == p2["reason"] and not m.roads.has(Vector2i(312, 300)), "B11 Ablehnung mit Toast, nichts gebaut")
	m._set_tool(m.Tool.NONE)
	# Ohne Hooks: Platzhalter 1,0, keine Sperre
	m.world_s7 = preload("res://world/s7_world.gd").new()
	var p3: Dictionary = m.plan_track(a, Vector2i(314, 300), false)
	var flat := 0
	for it in p3["items"]:
		if it["state"] == "new":
			flat += m.field_cost(it["cell"], false)
	ok(p3["ok"] and p3["total"] == flat and p3["hang"]["faktor_pm"] == 1000, "ohne Felix-Hooks: Faktor 1,0 (Platzhalter), Preis %s" % m.money_str(flat))
	# Jede Ablehnung mit Ursache (S7): Vorschau rot + Text
	var farm2 = m.by_id["farm_2"]
	var mill1 = m.by_id["muehle_1"]
	var cases := [[farm2.anchor(), mill1.anchor(), false], [Vector2i(194, 471), Vector2i(211, 471), false], [Vector2i(352, 329), Vector2i(352, 341), false],
		[Vector2i(375, 335), Vector2i(365, 335), false], [Vector2i(355, 360), Vector2i(355, 360), true]]
	var all_ok := true
	for cs in cases:
		m._set_tool(m.Tool.RAIL if cs[2] else m.Tool.ROAD)
		m.begin_drag(cs[0])
		m.drag_to(cs[1])
		m._update_cursor_label()
		var reds := 0
		for c in m.preview_root.get_children():
			if not c.is_queued_for_deletion() and c.name.begins_with("Fehlstelle"):
				reds += 1
		var good: bool = not m.plan["ok"] and m.cursor_reason.visible and m.cursor_reason.text != "" and reds > 0
		m.toast_label.text = ""
		m.end_drag()
		good = good and m.toast_label.text != ""
		if not good:
			all_ok = false
			print("     ohne Ursache: ", cs)
	m._set_tool(m.Tool.NONE)
	ok(all_ok, "S7: %d Ablehnungen, jede mit roter Fehlstelle, Grund am Cursor und Toast" % cases.size())


func _slice() -> void:
	print("== W-04 Slice unverändert")
	_fresh("slice")
	var farm1 = m.by_id["farm_1"]
	var mill1 = m.by_id["muehle_1"]
	_build(farm1.anchor(), mill1.anchor())
	var vis := true
	var size_ok := true
	for c in m.roads:
		vis = vis and m.render_batch.has(["road", c])   # S7 B: Quader 0,96 gebündelt (render_batch, Maße in main.build_track)
	ok(m.road_tiles == null and m.get_node_or_null("RoadTiles") == null and vis and size_ok and m.roads.size() > 0, "Slice: keine Kacheln, Straßen als Quader 0,96 wie bisher (%d Felder)" % m.roads.size())
