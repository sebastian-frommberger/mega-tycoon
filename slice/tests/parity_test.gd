extends SceneTree
## F-18 Paritätstest (Retro S4 Punkt 3): gleiches Skript, gleiche Daten, Fahrzeug-Kern "alt" (vehicle.gd)
## gegen "soa" (core/sim_world.gd). Skripte: Agrar-Durchlauf (wie slice_test Abschnitt 2), Bergbau-Kette
## (Abschnitt 5), Bench-Korridore mit 1.000 Lkw (Tick-Zeit), Determinismus 10 Läufe "soa".
## Kriterien: Kasse ±1 %, gleiche Lieferanzahl; 10/10 Läufe gleiche Kasse; Ausgabe "PARITY ..." je Lauf.
## Start: godot --headless --path slice -s res://tests/parity_test.gd   (Exit 0 = alle Kriterien erfüllt)

const MAIN := "res://main.tscn"
const MainScript := preload("res://main.gd")
const TICKS_30_MIN := 18000

var m: Node
var fails := 0
var checks := 0


func _initialize() -> void:
	_run.call_deferred()


func ok(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("  OK   ", what)
	else:
		fails += 1
		print("  FAIL ", what)


func _new_main(core: String) -> void:
	if m != null:
		m.free()
	MainScript.core_override = core
	m = load(MAIN).instantiate()
	root.add_child(m)


func drag(tool: int, a: Vector2i, b: Vector2i) -> bool:
	m._set_tool(tool)
	m.begin_drag(a)
	m.drag_to(b)
	return m.end_drag()


func line(tool: int, a, b):
	m._set_tool(tool)
	var n0: int = m.vehicles.size()
	m.click(a.anchor())
	m.click(b.anchor())
	m._set_tool(m.Tool.NONE)
	return m.vehicles[-1] if m.vehicles.size() > n0 else null


## Agrar-Skript wie slice_test Abschnitt 2. Ergebnis: Kasse, Lieferungen, Kurve je 5 min.
func agrar(core: String) -> Dictionary:
	_new_main(core)
	m.place_hq("haberau")
	var farm = m.by_id["farm_1"]
	var mill = m.by_id["muehle_1"]
	var haberau = m.by_id["haberau"]
	m.ui_buy_licence(farm)
	m.ui_buy_licence(mill)
	drag(m.Tool.ROAD, farm.anchor(), mill.anchor())
	var v1 = line(m.Tool.TRUCK_LINE, farm, mill)
	var ys := -1
	for y in range(mill.anchor().y, haberau.anchor().y + 1):
		if m.city_streets.has(Vector2i(haberau.anchor().x, y)):
			ys = y
			break
	var corner := Vector2i(haberau.anchor().x, mill.anchor().y)
	drag(m.Tool.ROAD, mill.anchor(), corner)
	drag(m.Tool.ROAD, corner, Vector2i(haberau.anchor().x, ys))
	var v2 = line(m.Tool.TRUCK_LINE, mill, haberau)
	var curve: Array = []
	var t0 := Time.get_ticks_usec()
	for i in TICKS_30_MIN:
		m.sim_tick()
		if (i + 1) % 3000 == 0:
			curve.append(m.eco.cash_cent)
	var ms := (Time.get_ticks_usec() - t0) / 1000.0
	return {"cash": m.eco.cash_cent, "deliv": m.deliveries.size(), "profit": m.deliveries_profit, "rev": m.eco.revenue_total,
		"exp": m.expenses_total, "v1": [v1.deliveries, v1.income_total, v1.cost_total()], "v2": [v2.deliveries, v2.income_total, v2.cost_total()],
		"curve": curve, "ms": ms, "ticks": m.shim.tick_count, "ms_done": _milestones_done()}


func bergbau(core: String) -> Dictionary:
	_new_main(core)
	m.place_hq("kohlberg")
	var kohle = m.by_id["kohle_1"]
	var kw = m.by_id["kraftwerk_1"]
	m.ui_buy_licence(kohle)
	var kc := Vector2i(kohle.anchor().x, kw.anchor().y)
	drag(m.Tool.ROAD, kohle.anchor(), kc)
	drag(m.Tool.ROAD, kc, kw.anchor())
	var vk = line(m.Tool.TRUCK_LINE, kohle, kw)
	var vk2 = line(m.Tool.TRUCK_LINE, kohle, kw)       # 2 Lkw auf derselben Linie: Konkurrenz um den Bestand
	m.run_ticks(TICKS_30_MIN)
	return {"cash": m.eco.cash_cent, "deliv": m.deliveries.size(), "profit": m.deliveries_profit,
		"vk": [vk.deliveries, vk2.deliveries if vk2 else -1]}


## Zug-Linie (Gleis Kohlemine → Kraftwerk als L, Kredit aufgenommen für den Zugpreis) + Lkw daneben.
func zug(core: String) -> Dictionary:
	_new_main(core)
	m.place_hq("kohlberg")
	var kohle = m.by_id["kohle_1"]
	var kw = m.by_id["kraftwerk_1"]
	m.ui_buy_licence(kohle)
	for i in 4:
		m.ui_credit_borrow()
	var kc := Vector2i(kohle.anchor().x, kw.anchor().y)
	var r1: bool = drag(m.Tool.RAIL, kohle.anchor(), kc) and drag(m.Tool.RAIL, kc, kw.anchor())
	var vz = line(m.Tool.TRAIN_LINE, kohle, kw)
	m.run_ticks(TICKS_30_MIN)
	return {"rail": r1, "train": vz != null, "cash": m.eco.cash_cent, "deliv": m.deliveries.size(),
		"zug": [vz.deliveries, vz.income_total, vz.cost_total()] if vz else [], "bankrupt": m.bankrupt, "zins": m.credit.interest_paid}


func _milestones_done() -> int:
	var n := 0
	for x in m.milestones:
		if x["done"]:
			n += 1
	return n


## 1.000 Lkw auf Bench-Korridoren (bench.gd-Aufbau, ohne Rendering-Läufe): mittlere Sim-Tick-Zeit.
func bench_ticks(core: String, units: int, ticks: int) -> Dictionary:
	_new_main(core)
	var Bench = load("res://bench.gd")
	var b = Bench.new()
	b.m = m
	b.units = units
	m.place_hq("haberau")
	m.eco.ledger_enabled = false
	m.eco.cash_cent = 1000000000000
	b._build_traffic()
	for i in 50:
		m.sim_tick()
	var samples: Array = []
	for i in ticks:
		var t0 := Time.get_ticks_usec()
		m.sim_tick()
		samples.append((Time.get_ticks_usec() - t0) / 1000.0)
	samples.sort()
	var tot := 0.0
	for s in samples:
		tot += s
	var moving := 0
	for v in m.vehicles:
		if v.state == v.State.TO_DST or v.state == v.State.TO_SRC:
			moving += 1
	b.free()
	return {"n": m.vehicles.size(), "mean": tot / samples.size(), "p95": samples[int(samples.size() * 0.95)], "moving": moving,
		"cash": m.eco.cash_cent, "units_wh": m.eco.units_to_warehouse}


func _pct(a: int, b: int) -> float:
	return absf(float(a - b)) / maxf(1.0, absf(float(b))) * 100.0


func _run() -> void:
	print("== F-18 Parität alt (vehicle.gd) gegen soa (core/sim_world.gd)")
	var ra := agrar("alt")
	var rs := agrar("soa")
	for r in [["alt", ra], ["soa", rs]]:
		var d: Dictionary = r[1]
		print("PARITY agrar %s kasse=%d lieferungen=%d mit_gewinn=%d ertrag=%d ausgaben=%d v1=%s v2=%s kurve_5min=%s ziele=%d sim_ms=%.0f" % [
			r[0], d["cash"], d["deliv"], d["profit"], d["rev"], d["exp"], str(d["v1"]), str(d["v2"]), str(d["curve"]), d["ms_done"], d["ms"]])
	var dc := _pct(rs["cash"], ra["cash"])
	ok(dc <= 1.0, "Agrar: Kasse soa %s vs alt %s (Abweichung %.3f %%, Ziel ≤ 1 %%)" % [m.money_str(rs["cash"]), m.money_str(ra["cash"]), dc])
	ok(rs["deliv"] == ra["deliv"], "Agrar: Lieferungen soa %d vs alt %d" % [rs["deliv"], ra["deliv"]])
	ok(rs["ms_done"] == ra["ms_done"], "Agrar: Ziele erreicht soa %d vs alt %d" % [rs["ms_done"], ra["ms_done"]])
	var ba := bergbau("alt")
	var bs := bergbau("soa")
	print("PARITY bergbau alt kasse=%d lieferungen=%d lkw=%s" % [ba["cash"], ba["deliv"], str(ba["vk"])])
	print("PARITY bergbau soa kasse=%d lieferungen=%d lkw=%s" % [bs["cash"], bs["deliv"], str(bs["vk"])])
	var db := _pct(bs["cash"], ba["cash"])
	ok(db <= 1.0 and bs["deliv"] == ba["deliv"], "Bergbau (2 Lkw auf einer Linie): Kasse Abweichung %.3f %%, Lieferungen %d vs %d" % [db, bs["deliv"], ba["deliv"]])

	var za := zug("alt")
	var zs := zug("soa")
	print("PARITY zug alt %s" % str(za))
	print("PARITY zug soa %s" % str(zs))
	ok(za["train"] and zs["train"] and _pct(zs["cash"], za["cash"]) <= 1.0 and zs["deliv"] == za["deliv"] and zs["zug"] == za["zug"],
		"Zug-Linie (mit Kredit F-19): Kasse %s vs %s, Lieferungen %d vs %d" % [m.money_str(zs["cash"]), m.money_str(za["cash"]), zs["deliv"], za["deliv"]])

	print("== Determinismus: 10 Läufe soa, gleiches Skript")
	var cashes := {}
	for k in 10:
		var r := agrar("soa")
		cashes[r["cash"]] = true
	ok(cashes.size() == 1 and cashes.has(rs["cash"]), "10/10 Läufe soa gleiche Kasse (%s verschiedene Werte)" % cashes.size())

	print("== Tick-Zeit 1.000 Lkw (Bench-Korridore, Sandbox-VM, kein Zielrechner)")
	var ta := bench_ticks("alt", 1000, 300)
	var tsoa := bench_ticks("soa", 1000, 300)
	for r in [["alt", ta], ["soa", tsoa]]:
		var d: Dictionary = r[1]
		print("PARITY tick %s fahrzeuge=%d mittel_ms=%.3f p95_ms=%.3f in_fahrt=%d umschlag_lager=%d" % [r[0], d["n"], d["mean"], d["p95"], d["moving"], d["units_wh"]])
	ok(tsoa["n"] == 1000 and tsoa["moving"] == ta["moving"] and tsoa["units_wh"] == ta["units_wh"],
		"1.000 SoA-Fahrzeuge: gleiche Lage wie alt nach 350 Ticks (in Fahrt %d/%d, Lager-Umschlag %d/%d)" % [tsoa["moving"], ta["moving"], tsoa["units_wh"], ta["units_wh"]])
	ok(tsoa["mean"] <= 2.0, "Sim-Tick Ø %.3f ms ≤ 2 ms (Sandbox; Zielrechner offen)" % tsoa["mean"])
	MainScript.core_override = ""
	m.free()
	m = null
	print("\n%d/%d Paritätsprüfungen OK" % [checks - fails, checks])
	quit(1 if fails > 0 else 0)
