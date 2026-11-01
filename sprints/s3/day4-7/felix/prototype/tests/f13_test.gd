extends SceneTree
## F-13 Bau-Tool: headless Test. Start:
##   godot --headless --path prototype -s res://tests/f13_test.gd
## Exit 0 = alle Prüfungen bestanden.

var m: Node
var fails := 0
var checks := 0


func _initialize() -> void:
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	_run.call_deferred()


func ok(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("  OK   ", what)
	else:
		fails += 1
		print("  FAIL ", what)


func bld(n: String) -> Node:
	for b in m.buildings:
		if b.display_name == n:
			return b
	return null


## Geld vor/nach einer programmatisch gezogenen Strecke (wie Maus: drücken, ziehen, loslassen).
func drag(tool: int, a: Vector2i, b: Vector2i) -> bool:
	m._set_tool(tool)
	m.begin_drag(a)
	m.drag_to(b)
	return m.end_drag()


## Unabhängig nachgerechneter Feldpreis (bestehende Regel aus main.gd v3).
func ref_cost(c: Vector2i, rail: bool) -> int:
	var base: float = m.RAIL_COST if rail else m.ROAD_COST
	var f := 1.0
	match m.terrain.get(c, 0):
		m.Terrain.WATER:
			f = m.WATER_FACTOR
		m.Terrain.MOUNTAIN:
			f = m.MOUNTAIN_FACTOR
	return int(base * (1.0 + m.OUTSIDE_SURCHARGE * m._distance_outside(c)) * f)


func _run() -> void:
	var T = m.Tool
	m.money = 1000000.0
	var muehle := bld("Mühle")
	var farm: Node = null
	for b in m.buildings:
		if b.display_name == "Getreidefarm" and b.cell == Vector2i(24, 122):
			farm = b
	m._buy(muehle)
	m._buy(farm)
	ok(muehle.owned and farm.owned, "Setup: Mühle + Getreidefarm gekauft")

	print("-- 1 Gerade Strecke")
	var a := Vector2i(33, 118)
	var b := Vector2i(40, 118)
	var p: Dictionary = m.plan_track(a, b, false)
	ok(p["ok"], "Plan gerade ok (%s)" % p["reason"])
	var straight := true
	for c in p["cells"]:
		straight = straight and c.y == 118
	ok(straight and p["cells"].size() == 8, "8 Felder auf einer Linie y=118")
	var sum := 0
	for it in p["items"]:
		sum += ref_cost(it["cell"], false) if it["state"] == "new" else 0
	var m0: float = m.money
	ok(drag(T.ROAD, a, b), "Drag gebaut")
	ok(p["total"] == sum and is_equal_approx(m0 - m.money, sum), "Kosten = Summe Feldkosten (%d = %d, abgebucht %.1f)" % [p["total"], sum, m0 - m.money])
	var all_built := true
	for c in p["cells"]:
		all_built = all_built and m.roads.has(c)
	ok(all_built, "Alle Felder im Straßennetz")

	print("-- 2 45°-Strecke")
	a = Vector2i(30, 128)
	b = Vector2i(38, 136)
	p = m.plan_track(a, b, true)
	ok(p["ok"], "Plan 45° ok (%s)" % p["reason"])
	var diag_ok := true
	for i in range(1, p["cells"].size()):
		var d: Vector2i = p["cells"][i] - p["cells"][i - 1]
		diag_ok = diag_ok and absi(d.x) + absi(d.y) == 1
	var last: Vector2i = p["cells"][-1]
	ok(diag_ok and last == b and p["cells"].size() == 17, "Treppe 8×(1+1)+1 = 17 Felder, 4-verbunden, endet am Ziel")
	# erst gerade, dann diagonal
	var c2: Array = m._drag_path(Vector2i(0, 0), Vector2i(6, 2))
	ok(c2.slice(0, 5) == [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0)] and c2[-1] == Vector2i(6, 2), "Pfad (0,0)->(6,2): erst 4 gerade, dann 45°")
	sum = 0
	for it in p["items"]:
		sum += ref_cost(it["cell"], true) if it["state"] == "new" else 0
	m0 = m.money
	ok(drag(T.RAIL, a, b), "45° gebaut")
	ok(is_equal_approx(m0 - m.money, sum), "Kosten 45° = Summe Feldkosten (%d)" % sum)

	print("-- 3 Wasser")
	p = m.plan_track(Vector2i(170, 40), Vector2i(191, 40), false)
	ok(not p["ok"] and p["reason"].begins_with("Wasser ohne Brücke"), "Küste/Meer abgelehnt: '%s'" % p["reason"])
	m0 = m.money
	ok(not drag(T.ROAD, Vector2i(170, 40), Vector2i(191, 40)) and m.money == m0 and not m.roads.has(Vector2i(170, 40)), "Abgelehnt: nichts gebaut, kein Geld abgebucht")
	p = m.plan_track(Vector2i(72, 80), Vector2i(88, 90), false)
	ok(not p["ok"] and "gerade" in p["reason"], "Diagonal über Fluss abgelehnt: '%s'" % p["reason"])
	p = m.plan_track(Vector2i(74, 85), Vector2i(86, 85), false)
	var water_cells := 0
	for it in p["items"]:
		if m.terrain.get(it["cell"], 0) == m.Terrain.WATER:
			water_cells += 1
	ok(p["ok"] and water_cells > 0, "Gerade Brücke über Fluss erlaubt (%d Wasserfelder, %d $)" % [water_cells, p["total"]])
	p = m.plan_track(Vector2i(27, 114), Vector2i(36, 114), false)
	ok(not p["ok"] and "Mühle" in p["reason"], "Gebäude im Weg abgelehnt: '%s'" % p["reason"])
	p = m.plan_track(Vector2i(35, 114), Vector2i(31, 114), false)
	ok(p["ok"], "Anschluss am Gebäuderand erlaubt (%s)" % p["reason"])

	print("-- 4 Abriss 50 %")
	a = Vector2i(33, 140)
	b = Vector2i(44, 140)
	m0 = m.money
	drag(T.ROAD, a, b)
	var cost: float = m0 - m.money
	var m1: float = m.money
	ok(drag(T.DEMOLISH, a, b), "Abriss-Drag ausgeführt")
	ok(is_equal_approx(m.money - m1, cost * 0.5), "Erstattung genau 50 %% (%.1f von %.1f)" % [m.money - m1, cost])
	ok(not m.roads.has(a) and not m.road_paid.has(a) and m.astar_road.is_point_solid(a), "Felder entfernt, Pfadsuche gesperrt")

	print("-- 5 Exploits (Bauen/Abreißen darf kein Geld erzeugen)")
	# E1 Bauen + Abriss: Netto immer Verlust
	m0 = m.money
	drag(T.RAIL, Vector2i(50, 150), Vector2i(58, 156))
	var paid_e1: float = m0 - m.money
	drag(T.DEMOLISH, Vector2i(50, 150), Vector2i(58, 156))
	ok(m.money < m0 and is_equal_approx(m0 - m.money, paid_e1 * 0.5), "E1 Bauen+Abriss: Verlust %.1f = 50 %% von %.1f" % [m0 - m.money, paid_e1])
	# E2 50 Runden im Kreis: streng fallend
	m0 = m.money
	var prev: float = m.money
	var mono := true
	for i in 50:
		drag(T.ROAD, Vector2i(50, 145), Vector2i(60, 145))
		drag(T.DEMOLISH, Vector2i(50, 145), Vector2i(60, 145))
		mono = mono and m.money < prev
		prev = m.money
	ok(mono and m.money < m0, "E2 50× Bauen/Abriss: Geld fällt jede Runde (-%.1f gesamt)" % (m0 - m.money))
	# E3 Doppelter Abriss
	drag(T.ROAD, Vector2i(50, 147), Vector2i(55, 147))
	drag(T.DEMOLISH, Vector2i(50, 147), Vector2i(55, 147))
	m0 = m.money
	drag(T.DEMOLISH, Vector2i(50, 147), Vector2i(55, 147))
	ok(m.money == m0, "E3 Zweiter Abriss derselben Felder erstattet 0")
	# E4 Doppelt bauen (Überlappung) erstattet nur einmal
	m0 = m.money
	drag(T.ROAD, Vector2i(50, 149), Vector2i(57, 149))
	var first: float = m0 - m.money
	var m2: float = m.money
	drag(T.ROAD, Vector2i(50, 149), Vector2i(57, 149))
	ok(m.money == m2, "E4a Zweites Bauen über bestehende Felder kostet 0")
	drag(T.DEMOLISH, Vector2i(50, 149), Vector2i(57, 149))
	ok(is_equal_approx(m0 - m.money, first * 0.5), "E4b Abriss erstattet nur 50 % des einmal Bezahlten")
	# E5 Stadtstraße abreißen
	var kf_street := Vector2i(40, 100)
	ok(m.city_streets.has(kf_street), "E5 Vorbedingung: (40,100) ist Stadtstraße Kornfeld")
	m0 = m.money
	drag(T.DEMOLISH, kf_street - Vector2i(2, 2), kf_street + Vector2i(2, 2))
	ok(m.money == m0 and m.city_streets.has(kf_street) and not m.astar_road.is_point_solid(kf_street), "E5 Stadtstraße: unmöglich, 0 $, bleibt befahrbar")
	# E6 Industrie abreißen
	m0 = m.money
	var pd: Dictionary = m.plan_demolish(muehle.cell, muehle.cell + Vector2i(1, 1))
	drag(T.DEMOLISH, muehle.cell, muehle.cell + Vector2i(1, 1))
	ok(m.money == m0 and m.cell_to_building.get(muehle.cell) == muehle and "nicht abreißen" in pd["reason"], "E6 Mühle: unmöglich, 0 $, Grund '%s'" % pd["reason"])
	# E7 Lager (Gebäude) abreißen
	m._set_tool(T.WAREHOUSE)
	m._build_warehouse(Vector2i(46, 110))
	var wh = m.cell_to_building.get(Vector2i(46, 110))
	m0 = m.money
	drag(T.DEMOLISH, Vector2i(46, 110), Vector2i(47, 111))
	ok(wh != null and m.money == m0 and m.cell_to_building.get(Vector2i(46, 110)) == wh, "E7 Lager: X reißt keine Gebäude ab, 0 $")
	# E8 Erstattung nach bezahltem, nicht aktuellem Preis (Einfluss wächst nach dem Bau)
	var ea := Vector2i(60, 120)
	var eb := Vector2i(66, 120)
	m0 = m.money
	drag(T.ROAD, ea, eb)
	var paid_out: float = m0 - m.money
	var before_inf: int = m.field_cost(ea, false)
	m.owned_radius = 60.0   # Einfluss wächst (wie Meilenstein 4), aktueller Preis sinkt
	var after_inf: int = m.field_cost(ea, false)
	m1 = m.money
	drag(T.DEMOLISH, ea, eb)
	m.owned_radius = m.OWNED_RADIUS
	ok(after_inf < before_inf and is_equal_approx(m.money - m1, paid_out * 0.5), "E8 Erstattung = 50 %% des Bezahlten (%.1f), Feldpreis jetzt %d statt %d" % [paid_out * 0.5, after_inf, before_inf])
	# E9 Zu wenig Geld: nichts gebaut, Geld bleibt, nie negativ durch Bau
	p = m.plan_track(Vector2i(50, 160), Vector2i(60, 160), true)
	var need: int = p["total"]
	var keep: float = m.money
	m.money = need - 1
	var built: bool = drag(T.RAIL, Vector2i(50, 160), Vector2i(60, 160))
	ok(not built and m.money == need - 1 and not m.rails.has(Vector2i(55, 160)), "E9a Geld = Kosten-1: abgelehnt ('%s')" % m.plan_track(Vector2i(50, 160), Vector2i(60, 160), true)["reason"])
	m.money = need
	built = drag(T.RAIL, Vector2i(50, 160), Vector2i(60, 160))
	ok(built and m.money == 0.0, "E9b Geld = Kosten: gebaut, Rest 0")
	m.money = keep
	# E10 Gleis/Straße unter einer Linie abreißen
	ok(drag(T.ROAD, farm.anchor(), muehle.anchor()), "E10 Vorbedingung: Straße Farm→Mühle")
	m._create_line(farm, muehle, ["Getreide"], "truck")
	ok(m.vehicles.size() == 1, "E10 Vorbedingung: Lkw-Linie aktiv")
	var mid: Vector2i = farm.anchor() + Vector2i(0, -3)
	ok(m.roads.has(mid), "E10 Vorbedingung: (26,121) ist eigene Straße")
	m0 = m.money
	pd = m.plan_demolish(mid - Vector2i(1, 1), mid + Vector2i(1, 1))
	drag(T.DEMOLISH, mid - Vector2i(1, 1), mid + Vector2i(1, 1))
	ok(m.money == m0 and m.roads.has(mid), "E10 Befahrene Straße: Abriss gesperrt ('%s')" % pd["reason"])
	# E11 Abbrechen kostet nichts
	m0 = m.money
	m._set_tool(T.ROAD)
	m.begin_drag(Vector2i(70, 150))
	m.drag_to(Vector2i(78, 150))
	m._cancel()
	ok(m.money == m0 and not m.dragging and not m.roads.has(Vector2i(74, 150)) and m.end_drag() == false, "E11 Esc/Rechtsklick: abgebrochen, nichts gebaut, 0 $")
	# E12 Straße + Gleis auf demselben Feld (Bahnübergang), Abriss erstattet beides genau halb
	m0 = m.money
	drag(T.ROAD, Vector2i(70, 152), Vector2i(76, 152))
	drag(T.RAIL, Vector2i(73, 149), Vector2i(73, 155))
	var paid12: float = m0 - m.money
	drag(T.DEMOLISH, Vector2i(70, 149), Vector2i(76, 155))
	ok(is_equal_approx(m0 - m.money, paid12 * 0.5) and not m.roads.has(Vector2i(73, 152)) and not m.rails.has(Vector2i(73, 152)), "E12 Kreuzung: Erstattung 50 %% von beiden (%.1f)" % (paid12 * 0.5))

	print("\nF-13: %d Prüfungen, %d Fehler" % [checks, fails])
	quit(1 if fails > 0 else 0)
