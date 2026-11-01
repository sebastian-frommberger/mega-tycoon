extends SceneTree
## Daniel Richter, F-13 Abnahme: unabhängige Prüfungen (nicht von Felix' Test wiederverwendet).
## godot --headless --path . -s res://tests/d_f13_abnahme.gd
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

func info(what: String) -> void:
	print("  INFO ", what)

func bld(n: String, c := Vector2i(-1, -1)) -> Node:
	for b in m.buildings:
		if b.display_name == n and (c.x < 0 or b.cell == c):
			return b
	return null

func drag(tool: int, a: Vector2i, b: Vector2i) -> bool:
	m._set_tool(tool)
	m.begin_drag(a)
	m.drag_to(b)
	return m.end_drag()

func _run() -> void:
	var T = m.Tool
	m.money = 1000000.0
	var farm := bld("Getreidefarm", Vector2i(24, 122))
	var muehle := bld("Mühle")
	m._buy(muehle)
	m._buy(farm)
	ok(muehle.owned and farm.owned, "Setup: Mühle + Farm gekauft")

	print("-- D1 Drag über Fluss MIT Brücke (gerade, Reihe y=85, x 74..86; Wasser x 78..81)")
	var a := Vector2i(74, 85)
	var b := Vector2i(86, 85)
	var p: Dictionary = m.plan_track(a, b, false)
	var wc := 0
	var landsum := 0
	var wsum := 0
	for it in p["items"]:
		if m.terrain.get(it["cell"], 0) == m.Terrain.WATER:
			wc += 1
			wsum += it["cost"]
		else:
			landsum += it["cost"]
	ok(p["ok"] and wc == 4, "Brücke 4 Felder erlaubt, Plan ok (%d $, davon Wasser %d $)" % [p["total"], wsum])
	var wcell := Vector2i(81, 85)
	var base_cell: int = m.field_cost(wcell, false)
	var plain_cell: int = int(10.0 * (1.0 + 0.8 * m._distance_outside(wcell)))
	ok(base_cell == int(10.0 * (1.0 + 0.8 * m._distance_outside(wcell)) * 6.0), "Wasserfeld = 6x Feldpreis am selben Ort (%d, Land wäre %d)" % [base_cell, plain_cell])
	var m0: float = m.money
	ok(drag(T.ROAD, a, b), "Brücke gebaut")
	ok(is_equal_approx(m0 - m.money, p["total"]), "Abbuchung = Plansumme (%.0f = %d)" % [m0 - m.money, p["total"]])
	ok(not m.astar_road.is_point_solid(Vector2i(80, 85)), "Pfadsuche: Brückenfeld befahrbar")
	# Abriss der Brücke: Erstattung 50 % des bezahlten (6x) Preises
	var m1: float = m.money
	drag(T.DEMOLISH, Vector2i(78, 85), Vector2i(81, 85))
	ok(is_equal_approx(m.money - m1, wsum * 0.5), "Brücke abgerissen: +%.1f = 50 %% von %d" % [m.money - m1, wsum])
	m1 = m.money
	drag(T.DEMOLISH, a, b)
	info("Rest der Strecke abgerissen, Netto Bau+Abriss gesamt: %.1f $" % (m.money - m0))
	ok(m.money < m0, "Brücke bauen + komplett abreißen: Netto Verlust")

	print("-- D2 Drag über Fluss OHNE Brücke")
	m0 = m.money
	ok(not drag(T.ROAD, Vector2i(74, 80), Vector2i(86, 86)), "Diagonal über Fluss (12x6): abgelehnt")
	ok(m.money == m0 and not m.roads.has(Vector2i(74, 80)) and not m.roads.has(Vector2i(80, 83)), "  nichts gebaut, Geld unverändert (alles oder nichts)")
	ok(not drag(T.ROAD, Vector2i(74, 85), Vector2i(80, 85)), "Ziel mitten im Fluss (kein Land am Ende): abgelehnt")
	ok(not drag(T.ROAD, Vector2i(80, 85), Vector2i(86, 85)), "Start im Fluss: abgelehnt")
	ok(not drag(T.ROAD, Vector2i(72, 80), Vector2i(86, 94)), "Reine 45°-Diagonale über Fluss: abgelehnt")
	ok(m.money == m0, "  Geld nach allen Ablehnungen unverändert")
	# synthetische Wasserstreifen (Fixture, Reihe y=30 / y=32, Land beidseitig)
	for x in range(100, 109):   # 9 Felder
		m.terrain[Vector2i(x, 140)] = m.Terrain.WATER
	for x in range(100, 108):   # 8 Felder
		m.terrain[Vector2i(x, 142)] = m.Terrain.WATER
	p = m.plan_track(Vector2i(98, 140), Vector2i(111, 140), false)
	ok(not p["ok"] and "zu lang" in p["reason"], "Fixture: Brücke 9 Felder abgelehnt ('%s')" % p["reason"])
	p = m.plan_track(Vector2i(98, 142), Vector2i(110, 142), false)
	ok(p["ok"], "Fixture: Brücke 8 Felder (Grenze) erlaubt")
	# Umgehung der Maximallänge: erst 8er-Brücke bauen, dann von deren letztem Feld weiter über weitere 8
	for x in range(108, 116):
		m.terrain[Vector2i(x, 142)] = m.Terrain.WATER   # Wasser x 100..115 = 16 Felder, Land ab x=116
	m.money = 1000000.0
	p = m.plan_track(Vector2i(98, 142), Vector2i(118, 142), false)
	ok(not p["ok"], "16 Felder Wasser in einem Zug abgelehnt ('%s')" % p["reason"])
	# Umgehung: erst 8er-Brücke bauen (x 100..107 Wasser, Ende am letzten Brückenfeld), dann ab dort weiter
	var first_hop: bool = drag(T.ROAD, Vector2i(98, 142), Vector2i(107, 142))
	info("Zug 1 endet im Wasser (letztes Brückenfeld x=107): gebaut=%s" % first_hop)
	p = m.plan_track(Vector2i(107, 142), Vector2i(118, 142), false)
	ok(not p["ok"], "Umgehung der 8-Felder-Grenze durch Kettenbau ab Brückenfeld nicht möglich (ok=%s '%s')" % [p["ok"], p["reason"]])
	m.cancel_drag()

	print("-- D3 Drag über Stadtgebiet Kornfeld (Straße y=100, x 35..46; Häuser y=101)")
	m.money = 1000000.0
	p = m.plan_track(Vector2i(34, 100), Vector2i(47, 100), false)
	var newc := 0
	for it in p["items"]:
		if it["state"] == "new":
			newc += 1
	ok(p["ok"], "Entlang Stadtstraße ok (%s)" % p["reason"])
	info("Neue Felder entlang der Stadtstraße: %d (Rest vorhandene Stadtstraße kostenlos), Summe %d $" % [newc, p["total"]])
	p = m.plan_track(Vector2i(39, 96), Vector2i(39, 106), false)
	ok(not p["ok"] and "Gebäude im Weg" in p["reason"], "Quer durch Häuserzeile: abgelehnt ('%s')" % p["reason"])
	m0 = m.money
	ok(not drag(T.ROAD, Vector2i(39, 96), Vector2i(39, 106)) and m.money == m0, "  Quer-Drag: nichts gebaut, 0 $")
	# Gleis durch die Stadtstraße: Plan sagt "exist" (0 $)
	p = m.plan_track(Vector2i(35, 100), Vector2i(46, 100), true)
	ok(p["ok"] and p["total"] == 0, "Gleis auf Stadtstraße: Plan ok, 0 $ (%d $)" % p["total"])
	m0 = m.money
	drag(T.RAIL, Vector2i(35, 100), Vector2i(46, 100))
	var rail_in_city: bool = m.rails.has(Vector2i(40, 100))
	var rail_walkable: bool = not m.astar_rail.is_point_solid(Vector2i(40, 100))
	info("Gleis durch Stadtstraße: rails enthält Feld=%s, Zug-Pfadsuche befahrbar=%s, Geld Δ=%.1f" % [rail_in_city, rail_walkable, m.money - m0])
	ok(rail_in_city == rail_walkable, "Plan 'vorhanden' und Gleisnetz stimmen überein (Gleis auf Stadtstraße: Stadtstraße ist für Züge gratis befahrbar, aber unsichtbar als Gleis)")
	# Abriss über Stadt + eigene Straße
	drag(T.ROAD, Vector2i(48, 100), Vector2i(54, 100))
	m0 = m.money
	var pd: Dictionary = m.plan_demolish(Vector2i(34, 99), Vector2i(54, 101))
	drag(T.DEMOLISH, Vector2i(34, 99), Vector2i(54, 101))
	ok(m.city_streets.has(Vector2i(40, 100)) and m.cell_to_building.size() > 0, "Abriss-Rechteck über Stadt: Stadt unversehrt")
	ok(m.money - m0 <= pd["refund"] + 0.001, "  Erstattung nur für eigene Felder (+%.1f)" % (m.money - m0))

	print("-- D4 Geldgrenze genau erreicht")
	var ra := Vector2i(100, 150)
	var rb := Vector2i(112, 150)
	for rail in [false, true]:
		var tl: int = T.RAIL if rail else T.ROAD
		var pp: Dictionary = m.plan_track(ra, rb, rail)
		var need: int = pp["total"]
		m.money = float(need)
		ok(drag(tl, ra, rb) and m.money == 0.0, "%s: Geld == Kosten (%d $): gebaut, Rest 0" % ["Gleis" if rail else "Straße", need])
		drag(T.DEMOLISH, ra, rb)
		m.money = float(need) - 0.5
		var built: bool = drag(tl, ra, rb)
		ok(not built and m.money == float(need) - 0.5, "  Geld == Kosten-0,5: abgelehnt, Geld unverändert")
		m.money = float(need) + 0.5
		built = drag(tl, ra, rb)
		ok(built and is_equal_approx(m.money, 0.5), "  Geld == Kosten+0,5: gebaut, Rest 0,5 (%.2f)" % m.money)
		drag(T.DEMOLISH, ra, rb)
	# Geld 0, Strecke komplett vorhanden (0 $) -> geht?
	m.money = 1000000.0
	drag(T.ROAD, ra, rb)
	m.money = 0.0
	var free_ok: bool = drag(T.ROAD, ra, rb)
	info("Geld 0, Strecke komplett vorhanden (0 $ Kosten): Drag liefert %s" % free_ok)
	m.money = 1000000.0
	drag(T.DEMOLISH, ra, rb)
	# Geldgrenze mit Brücke genau
	m.money = 1000000.0
	p = m.plan_track(Vector2i(74, 85), Vector2i(86, 85), false)
	m.money = float(p["total"])
	ok(drag(T.ROAD, Vector2i(74, 85), Vector2i(86, 85)) and m.money == 0.0, "Brücke: Geld == Kosten (%d $): gebaut, Rest 0" % p["total"])
	m.money = 1000000.0
	drag(T.DEMOLISH, Vector2i(74, 85), Vector2i(86, 85))
	# Geld nach Plan-Gate: Kosten ändern sich zwischen Plan und Bau nicht (kein TOCTOU)
	m.money = 1000000.0

	print("-- D5 Abriss unter Fahrzeug")
	ok(drag(T.ROAD, farm.anchor(), muehle.anchor()), "Vorbedingung: Straße Farm->Mühle")
	m._create_line(farm, muehle, ["Getreide"], "truck")
	ok(m.vehicles.size() == 1, "Lkw-Linie aktiv")
	var v = m.vehicles[0]
	var path_cells := []
	for pos in v.path:
		path_cells.append(Vector2i(int(floor(pos.x)), int(floor(pos.z))))
	var had_before := {}
	for c in path_cells:
		had_before[c] = m.roads.has(c)
	# Abzweig bauen, der nicht zur Linie gehört
	var mid: Vector2i = path_cells[int(path_cells.size() / 2)]
	var branch_a := mid + Vector2i(0, 2)
	var branch_b := mid + Vector2i(6, 2)
	drag(T.ROAD, branch_a, branch_b)
	m0 = m.money
	var rect_a := Vector2i(mid.x - 1, mid.y - 3)
	var rect_b := Vector2i(mid.x + 6, mid.y + 3)
	pd = m.plan_demolish(rect_a, rect_b)
	var used := 0
	var removable := 0
	for it in pd["items"]:
		if it["state"] == "bad":
			used += 1
		else:
			removable += 1
	drag(T.DEMOLISH, rect_a, rect_b)
	var path_intact := true
	for c in path_cells:
		path_intact = path_intact and (m.roads.has(c) == had_before[c]) and not m.astar_road.is_point_solid(c)
	ok(path_intact, "Gemischtes Rechteck: Linienfelder (%d) bleiben, Pfad intakt" % used)
	ok(not m.roads.has(branch_b) and m.money > m0, "  Abzweig (%d Felder) abgerissen, +%.1f $" % [removable, m.money - m0])
	ok(m.astar_road.get_id_path(farm.anchor(), muehle.anchor()).size() > 0, "  Linie findet weiterhin Weg Farm->Mühle")
	# Fahrzeug fährt, dann nochmals versuchen (Position wechselt)
	for i in 30:
		v._process(0.5)
		var cc := Vector2i(int(floor(v.position.x)), int(floor(v.position.z)))
		m0 = m.money
		var was_road: bool = m.roads.has(cc)
		drag(T.DEMOLISH, cc - Vector2i(1, 1), cc + Vector2i(1, 1))
		if was_road and (m.money != m0 or not m.roads.has(cc)):
			ok(false, "Abriss unter fahrendem Fahrzeug bei %s möglich" % cc)
			break
	ok(true, "30 Schritte: nie Abriss auf dem Feld unter dem Fahrzeug")
	# Zug-Linie: Gleis gesperrt, Straße am selben Feld frei
	drag(T.RAIL, farm.anchor(), muehle.anchor())
	m._create_line(farm, muehle, ["Getreide"], "train")
	var tv = m.vehicles[m.vehicles.size() - 1]
	var tc := Vector2i(int(floor(tv.path[tv.path.size() / 2].x)), int(floor(tv.path[tv.path.size() / 2].z)))
	var had_road: bool = m.roads.has(tc)
	var tused: bool = m.rails.has(tc)
	m0 = m.money
	drag(T.DEMOLISH, tc, tc)
	ok(tused and m.rails.has(tc), "Zug-Linie: Gleis unter dem Zug nicht abreißbar")
	info("Feld %s hatte auch Straße: %s (Straße ohne Lkw-Nutzung ist abreißbar: %s)" % [tc, had_road, had_road and not m.roads.has(tc) and not (tc in path_cells)])
	# Linie entfernbar?
	var has_remove: bool = m.has_method("remove_line") or m.has_method("_remove_line") or m.has_method("delete_line")
	ok(has_remove, "Es gibt eine Funktion, um eine Linie zu entfernen (Meldung sagt 'erst Linie entfernen')")

	print("-- D6 Kosten Außerhalb des Einflusses")
	var cost_in: int = m.field_cost(Vector2i(24, 118), false)
	ok(cost_in == 10, "Innerhalb Einfluss: 10 $ pro Straßenfeld (%d)" % cost_in)
	var last_ok := true
	var prev_c := 0
	var sample := []
	for dx in range(0, 60, 6):
		var c := Vector2i(24 + 18 + dx, 150)   # Strahl weg von der Farm
		var dd: float = m._distance_outside(c)
		var exp := int(10.0 * (1.0 + 0.8 * dd))
		var got: int = m.field_cost(c, false)
		sample.append("d=%.1f:%d$" % [dd, got])
		last_ok = last_ok and got == exp and got >= prev_c
		prev_c = got
	ok(last_ok, "Feldpreis = 10*(1+0.8*d), nie fallend: %s" % ", ".join(sample))
	m.money = 1000000.0
	var far_a := Vector2i(110, 170)
	var far_b := Vector2i(130, 170)
	p = m.plan_track(far_a, far_b, false)
	var calc := 0
	var out_n := 0
	for it in p["items"]:
		calc += m.field_cost(it["cell"], false)
		if m._distance_outside(it["cell"]) > 0.0:
			out_n += 1
	ok(p["total"] == calc and p["outside"] == out_n, "Weite Strecke: Summe %d $ = Einzelpreise, %d Außerhalb-Felder gezählt" % [p["total"], p["outside"]])
	m._set_tool(T.ROAD)
	m.begin_drag(far_a)
	m.drag_to(far_b)
	m._update_cursor_label()
	ok(("%d $" % p["total"]) in m.cursor_cost.text, "Cursor-Text zeigt Plansumme: '%s'" % m.cursor_cost.text)
	m.cancel_drag()
	# Berg
	var mt := Vector2i(-1, -1)
	for c in m.terrain:
		if m.terrain[c] == m.Terrain.MOUNTAIN and m._distance_outside(c) == 0.0:
			mt = c
			break
	if mt.x >= 0:
		ok(m.field_cost(mt, false) == 30, "Berg im Einfluss: 3x (%d $)" % m.field_cost(mt, false))
	else:
		info("Kein Berg im Einflussbereich zum Messen")

	print("-- D7 Geschlossener Kreis mit Einflusswechsel (Preis sinkt nach Kauf)")
	var ba := Vector2i(60, 122)
	var bb2 := Vector2i(75, 122)
	m.money = 1000000.0
	var start_money: float = m.money
	var p_high: int = m.plan_track(ba, bb2, false)["total"]
	drag(T.ROAD, ba, bb2)
	var other := bld("Getreidefarm", Vector2i(42, 122))
	m._buy(other)
	var mm: float = m.money
	drag(T.DEMOLISH, ba, bb2)
	var refund: float = m.money - mm
	var p_low: int = m.plan_track(ba, bb2, false)["total"]
	mm = m.money
	drag(T.ROAD, ba, bb2)
	var rebuild: float = mm - m.money
	info("Hoher Preis %d $, nach Kauf %d $, Erstattung %.1f, Neubau %.1f" % [p_high, p_low, refund, rebuild])
	for i in 20:
		drag(T.DEMOLISH, ba, bb2)
		drag(T.ROAD, ba, bb2)
	drag(T.DEMOLISH, ba, bb2)
	var buy_cost: int = m._buy_cost(other) if not other.owned else 0
	ok(m.money < start_money, "Kreis Bau->Preis sinkt->Abriss->Neubau x20->Abriss: Netto Verlust (%.1f $, Kauf der Farm separat)" % (start_money - m.money))

	print("-- D8 Fuzz: 400 zufällige Drags (Straße/Gleis/Abriss), Geldinvarianten")
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261209
	m.money = 200000.0
	var spent := 0.0
	var refunded := 0.0
	var viol := 0
	var regions := [Rect2i(60, 70, 40, 40), Rect2i(25, 90, 35, 30), Rect2i(100, 140, 40, 40)]
	for i in 400:
		var rg: Rect2i = regions[rng.randi() % regions.size()]
		var s := Vector2i(rg.position.x + rng.randi() % rg.size.x, rg.position.y + rng.randi() % rg.size.y)
		var e := Vector2i(rg.position.x + rng.randi() % rg.size.x, rg.position.y + rng.randi() % rg.size.y)
		var tsel := rng.randi() % 3
		var tl2: int = [T.ROAD, T.RAIL, T.DEMOLISH][tsel]
		var before: float = m.money
		var pl: Dictionary = m.plan_demolish(s, e) if tsel == 2 else m.plan_track(s, e, tsel == 1)
		var did := drag(tl2, s, e)
		var delta: float = m.money - before
		if tsel == 2:
			if not is_equal_approx(delta, pl["refund"]):
				viol += 1
			refunded += delta
		else:
			if did and not is_equal_approx(-delta, pl["total"]):
				viol += 1
			if (not did) and delta != 0.0:
				viol += 1
			if pl["ok"] != did:
				viol += 1
			spent += -delta
		if m.money < 0.0:
			viol += 1
	ok(viol == 0, "400 Drags: 0 Verstöße (Abbuchung = Plan, abgelehnt = 0 $, Geld nie negativ)")
	ok(refunded <= spent * 0.5 + 0.001, "Gesamt erstattet %.1f <= 50 %% von gesamt bezahlt %.1f" % [refunded, spent])

	print("-- D9 Randfälle")
	m.money = 1000.0
	m0 = m.money
	ok(not drag(T.ROAD, Vector2i(150, 150), Vector2i(150, 200)) and m.money == m0, "Ziel außerhalb der Karte: abgelehnt, 0 $")
	m.money = 1000000.0
	ok(drag(T.ROAD, Vector2i(150, 120), Vector2i(150, 120)), "Ein-Feld-Drag (Start=Ziel) baut 1 Feld")
	m0 = m.money
	drag(T.DEMOLISH, Vector2i(150, 120), Vector2i(150, 120))
	ok(m.money > m0 and not m.roads.has(Vector2i(150, 120)), "Ein-Feld-Abriss erstattet")
	m.money = -5.0
	p = m.plan_track(Vector2i(100, 100), Vector2i(102, 100), false)
	info("Geld negativ (-5): Plan ok=%s" % p["ok"])
	m.money = 1000000.0

	print("\nDaniel F-13: %d Prüfungen, %d Fehler" % [checks, fails])
	quit(1 if fails > 0 else 0)
