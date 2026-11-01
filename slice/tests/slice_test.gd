extends SceneTree
## F-14/F-16 Slice: headless Tests. Start:
##   godot --headless --path slice -s res://tests/slice_test.gd
## Exit 0 = alle Prüfungen bestanden. Zeiten sind SANDBOX-Zeiten (2-Kern-VM, kein Zielrechner).

const MAIN := "res://main.tscn"
const TICKS_30_MIN := 18000

var m: Node
var fails := 0
var checks := 0
var report: Array = []


func _initialize() -> void:
	_run.call_deferred()


func ok(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("  OK   ", what)
	else:
		fails += 1
		print("  FAIL ", what)


func _new_main() -> void:
	if m != null:
		m.free()
	var t0 := Time.get_ticks_usec()
	m = load(MAIN).instantiate()
	root.add_child(m)
	report.append("Instanz geladen in %.0f ms (Sandbox)" % ((Time.get_ticks_usec() - t0) / 1000.0))


func drag(tool: int, a: Vector2i, b: Vector2i) -> bool:
	m._set_tool(tool)
	m.begin_drag(a)
	m.drag_to(b)
	var p: Dictionary = m.plan
	var r: bool = m.end_drag()
	print("     Bau %s→%s: ok=%s, %d neue Felder, %s, %s" % [a, b, str(p.get("ok")), p.get("new_count", 0), m.money_str(p.get("total", 0)), p.get("reason", "")])
	return r


func line(tool: int, a, b):
	m._set_tool(tool)
	var n0: int = m.vehicles.size()
	m.click(a.anchor())
	m.click(b.anchor())
	m._set_tool(m.Tool.NONE)
	return m.vehicles[-1] if m.vehicles.size() > n0 else null


func _run() -> void:
	var T0 := Time.get_ticks_usec()
	# ------------------------------------------------------------------ 1) Karte
	print("== 1) Karte aus slice_map.json")
	_new_main()
	ok(m.load_ms <= 3000.0, "Karte lädt in %.0f ms (Sandbox, Ziel ≤ 3000 ms; _ready gesamt %.0f ms)" % [m.load_ms, m.ready_ms])
	ok(m.map_missing_ids.is_empty(), "0 fehlende IDs (gefunden: %d) %s" % [m.map_missing_ids.size(), str(m.map_missing_ids)])
	var n_city := 0
	var n_ind := 0
	var n_inert := 0
	for b in m.buildings:
		if b.kind == b.Kind.CITY:
			n_city += 1
		elif b.kind == b.Kind.INERT:
			n_inert += 1
		else:
			n_ind += 1
	ok(n_city == 8 and n_ind == 8 and n_inert == 2, "8 Städte, 8 Ökonomie-Industrien, 2 Holz-Kulissen (%d/%d/%d)" % [n_city, n_ind, n_inert])
	var cnt := [0, 0, 0]
	for i in m.terrain.size():
		cnt[m.terrain[i]] += 1
	var tot: float = m.terrain.size()
	ok(cnt[1] > 0 and cnt[2] > 0, "2 Geländetypen: Wasser %.1f %%, Gebirge %.1f %% (je < 40 %%)" % [cnt[1] / tot * 100.0, cnt[2] / tot * 100.0])
	ok(cnt[1] / tot < 0.4 and cnt[2] / tot < 0.4, "Region ≤ 40 % (Geländeanteile)")
	for n in m.map_notes:
		print("     Notiz: ", n)
	ok(not m.company_started and m.start_panel.visible, "Startdialog sichtbar, Spiel pausiert bis zur Wahl")

	# ------------------------------------------------------------------ 2) Durchlauf Agrar
	print("== 2) Skript-Durchlauf Agrar: Lizenz Farm + Mühle, Straße, Lkw-Linie, 30 Spielminuten")
	ok(m.start_game("agrar"), "Start Agrar (Knopf 1 von 2)")
	var cap0: int = m.eco.cash_cent
	ok(cap0 == 450000, "Startkapital 4.500 $ aus JSON (%s)" % m.money_str(cap0))
	var farm = m.by_id["farm_1"]
	var mill = m.by_id["muehle_1"]
	var haberau = m.by_id["haberau"]
	# Lizenzpflicht: ohne Lizenz keine Linie
	var v_no = line(m.Tool.TRUCK_LINE, farm, mill)
	ok(v_no == null and m.vehicles.is_empty(), "Linie ab Farm ohne Lizenz abgelehnt (Laden nur mit Lizenz)")
	m.close_panel()
	# Lizenz-Knopf: Panel öffnen, Knopf zeigt Preis und Ertrag/Monat, 1 Klick
	m.open_panel(farm)
	var btxt: String = m.panel_button.text
	ok(m.panel_button.visible and btxt.contains("Lizenz kaufen") and btxt.contains("$/Monat"), "Knopf sichtbar: \"%s\"" % btxt)
	m.panel_button.pressed.emit()
	ok(m.eco.licence_valid(farm.site), "1 Klick → Lizenz Farm aktiv (gratis, 1. Lizenz)")
	m.open_panel(mill)
	var btxt2: String = m.panel_button.text
	m.panel_button.pressed.emit()
	ok(m.eco.licence_valid(mill.site), "1 Klick → Lizenz Mühle aktiv: \"%s\"" % btxt2)
	m.close_panel()
	var cash_lic: int = m.eco.cash_cent
	# Straße Farm → Mühle (gerade, Brücke über den Fluss)
	ok(drag(m.Tool.ROAD, farm.anchor(), mill.anchor()), "Straße Farm 1 → Mühle gebaut (mit Brücke)")
	var v1 = line(m.Tool.TRUCK_LINE, farm, mill)
	ok(v1 != null, "Lkw-Linie Farm 1 → Mühle (%d Felder, Lkw aus Startpaket)" % (v1.distance if v1 else -1))
	# Zweite Strecke Mühle → Haberau (Mehl an Stadt, M3)
	var ys := -1
	for y in range(mill.anchor().y, haberau.anchor().y + 1):
		if m.city_streets.has(Vector2i(haberau.anchor().x, y)):
			ys = y
			break
	var corner := Vector2i(haberau.anchor().x, mill.anchor().y)
	var r2: bool = drag(m.Tool.ROAD, mill.anchor(), corner) and drag(m.Tool.ROAD, corner, Vector2i(haberau.anchor().x, ys))
	ok(r2, "Straße Mühle → Haberau gebaut")
	var v2 = line(m.Tool.TRUCK_LINE, mill, haberau)
	ok(v2 != null, "Lkw-Linie Mühle → Haberau (%d Felder)" % (v2.distance if v2 else -1))
	var cash_setup: int = m.eco.cash_cent
	report.append("Kasse: Start %s, nach Lizenzen %s, nach Bau %s" % [m.money_str(cap0), m.money_str(cash_lic), m.money_str(cash_setup)])
	var ts := Time.get_ticks_usec()
	var first_deliv := -1
	var third_profit := -1
	var cash_min: int = cash_setup
	for i in TICKS_30_MIN:
		m.sim_tick()
		cash_min = mini(cash_min, m.eco.cash_cent)
		if first_deliv < 0 and m.deliveries.size() > 0:
			first_deliv = m.shim.tick_count
		if third_profit < 0 and m.deliveries_profit >= 3:
			third_profit = m.shim.tick_count
	var sim_ms := (Time.get_ticks_usec() - ts) / 1000.0
	var d1 := 0
	var d1p := 0
	for d in m.deliveries:
		if d["src"] == "farm_1":
			d1 += 1
			if d["income"] > d["trip_cost"]:
				d1p += 1
	ok(not m.bankrupt, "kein Bankrott in 30 Spielminuten (Tiefststand Kasse %s)" % m.money_str(cash_min))
	ok(m.deliveries_profit >= 3, "≥ 3 Lieferungen mit Gewinn: %d von %d (Farm→Mühle %d/%d), 3. nach %s Spielzeit, 1. nach %s" % [
		m.deliveries_profit, m.deliveries.size(), d1p, d1, m.time_str(third_profit), m.time_str(first_deliv)])
	var l1: int = v1.income_total - v1.cost_total()
	var l2: int = v2.income_total - v2.cost_total()
	ok(l1 > 0, "Linie Farm→Mühle nach Unterhalt im Plus: Ertrag %s − Kosten %s = %s" % [m.money_str(v1.income_total), m.money_str(v1.cost_total()), m.money_str(l1)])
	report.append("Linie Mühle→Haberau: Ertrag %s − Kosten %s = %s, %d Lieferungen (Sättigung Dorf 9 E/min)" % [m.money_str(v2.income_total), m.money_str(v2.cost_total()), m.money_str(l2), v2.deliveries])
	ok(m.eco.cash_cent > cash_setup, "Kasse nach 30 min %s > nach Aufbau %s (Start %s)" % [m.money_str(m.eco.cash_cent), m.money_str(cash_setup), m.money_str(cap0)])
	var all_done := true
	for i in m.milestones.size():
		all_done = all_done and m.milestones[i]["done"]
		print("     Ziel %d %s: %s" % [i, "✔" if m.milestones[i]["done"] else "○", m.milestones[i]["text"]])
	ok(all_done, "alle 7 Ziele der Liste erreicht")
	var lager_cent := 0
	var non_end := 0
	for e in m.eco.ledger:
		if m.eco.s_kind[e["ziel"]] == m.eco.K_LAGER:
			lager_cent += e["cent"]
	ok(lager_cent == 0 and m.eco.revenue_total > 0, "Ertrag nur beim Endabnehmer (Lagerbuchungen 0 $, Ertrag gesamt %s)" % m.money_str(m.eco.revenue_total))
	report.append("30 Spielminuten simuliert in %.0f ms (Sandbox)" % sim_ms)
	report.append("Lizenz Mühle verlängert: Lizenzkosten gesamt %s" % m.money_str(m.eco.licence_paid_total))

	# ------------------------------------------------------------------ 3) Lager-Pingpong
	print("== 3) Lager-Pingpong")
	_new_main()
	m.start_game("agrar")
	var spot := _corridor(Vector2i(300, 300), 24)
	ok(spot.x >= 0, "freier Korridor für 2 Lager gefunden bei %s" % spot)
	var wa = m.build_warehouse(spot)
	var wb = m.build_warehouse(spot + Vector2i(22, 0))
	ok(wa != null and wb != null, "2 Lager gebaut")
	ok(drag(m.Tool.ROAD, spot + Vector2i(1, 0), spot + Vector2i(22, 0)), "Straße zwischen den Lagern")
	m.eco.seed_stock(wa.site, "getreide", 100)        # Testbestand mit Herkunftsstempel (Ursprung Lager A)
	var p1 = line(m.Tool.TRUCK_LINE, wa, wb)
	var p2 = line(m.Tool.TRUCK_LINE, wb, wa)
	ok(p1 != null and p2 != null, "Linien A→B und B→A")
	var rev0: int = m.eco.revenue_total
	m.run_ticks(6000)
	ok(m.eco.units_to_warehouse > 0, "%d Einheiten umgeschlagen in 10 Spielminuten (%d Fahrten)" % [m.eco.units_to_warehouse, p1.deliveries + p2.deliveries])
	ok(m.eco.revenue_total - rev0 == 0, "Lager-Pingpong bringt 0 $ (Ertrag %s)" % m.money_str(m.eco.revenue_total - rev0))

	# ------------------------------------------------------------------ 4) Bankrott
	print("== 4) Bankrott: nur Fahrzeuge kaufen, keine Linie")
	_new_main()
	m.start_game("agrar")
	var bought := 0
	while m.buy_vehicle("truck") != null:
		bought += 1
	report.append("Bankrott-Test: %d Lkw gekauft (davon 2 Startpaket), Kasse danach %s, Unterhalt %s/min" % [bought, m.money_str(m.eco.cash_cent), m.money_str(bought * 9000)])
	m.run_ticks(TICKS_30_MIN)
	ok(m.bankrupt, "Bankrott tritt ein nach %s Spielzeit (Kasse %s)" % [m.time_str(m.shim.tick_count), m.money_str(m.eco.cash_cent)])
	ok(m.bankrupt_panel.visible, "Bankrott-Panel sichtbar, Neustart-Knopf")
	var tk: int = m.shim.tick_count
	m.sim_tick()
	ok(m.shim.tick_count == tk, "Simulation steht nach Bankrott")
	_new_main()
	m.start_game("agrar")
	for i in 5:
		m.buy_vehicle("truck")
	m.run_ticks(TICKS_30_MIN)
	ok(m.bankrupt, "auch mit 5 Lkw ohne Linie: Bankrott nach %s" % m.time_str(m.shim.tick_count))

	# ------------------------------------------------------------------ 5) Bergbau-Start, Tempo
	print("== 5) Bergbau-Start und Tempo")
	_new_main()
	ok(m.start_game("bergbau") and m.eco.cash_cent == 700000, "Start Bergbau (Knopf 2 von 2): %s" % m.money_str(m.eco.cash_cent))
	var q: Dictionary = m.licence_quote(m.by_id["kohle_1"])
	ok(q.get("ok", false) and q["gratis"], "Lizenz-Angebot Kohlemine: %s, Ertrag %s/Monat bis %s" % [m.money_str(q["kosten_cent"]), m.money_str(q["ertrag_pro_monat_cent"]), q["ertrag_ziel_id"]])
	m.set_speed(8)
	ok(m.speed == 8, "8× erlaubt bei ≤ 5.000 Fahrzeugen")
	ok(not m.licence_quote(m.by_id["kraftwerk_1"]).get("ok", true), "Kraftwerk (Abnehmer) braucht keine Lizenz")
	# Erste Kette Bergbau wie im Ziel-Hinweis: Kohle → Kraftwerk (Straße als L: erst senkrecht, dann waagrecht)
	var kohle = m.by_id["kohle_1"]
	var kw = m.by_id["kraftwerk_1"]
	m.ui_buy_licence(kohle)
	var kc := Vector2i(kohle.anchor().x, kw.anchor().y)
	ok(drag(m.Tool.ROAD, kohle.anchor(), kc) and drag(m.Tool.ROAD, kc, kw.anchor()), "Straße Kohlemine → Kraftwerk (Gebirge ×3)")
	var vk = line(m.Tool.TRUCK_LINE, kohle, kw)
	var cash_b: int = m.eco.cash_cent
	m.run_ticks(TICKS_30_MIN)
	ok(vk != null and vk.deliveries_profit >= 3 and m.eco.cash_cent > cash_b, "Bergbau: %d Lieferungen mit Gewinn, Kasse %s → %s" % [
		vk.deliveries_profit if vk else -1, m.money_str(cash_b), m.money_str(m.eco.cash_cent)])

	m.free()
	m = null
	print("")
	for r in report:
		print("  · ", r)
	print("\n%d/%d Prüfungen OK, Laufzeit %.1f s (Sandbox)" % [checks - fails, checks, (Time.get_ticks_usec() - T0) / 1e6])
	quit(1 if fails > 0 else 0)


## Sucht ab start eine freie gerade Strecke (2 Zeilen hoch) der Länge len für Lager + Straße.
func _corridor(start: Vector2i, len: int) -> Vector2i:
	for dy in range(0, 120, 3):
		for dx in range(-100, 100, 3):
			var c := start + Vector2i(dx, dy)
			var free := true
			for x in range(c.x, c.x + len):
				for yy in [0, 1]:
					var cc := Vector2i(x, c.y + yy)
					if not m._in_grid(cc) or m.terrain_at(cc) != m.Terrain.PLAIN or m.cell_to_building.has(cc) or m.roads.has(cc) or m.city_streets.has(cc):
						free = false
			if free:
				return c
	return Vector2i(-1, -1)
