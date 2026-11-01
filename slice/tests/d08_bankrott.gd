extends SceneTree
## D-08 (Daniel Richter, Sprint 6): schneller Bankrott-Regressionslauf im ECHTEN Godot-Spiel (Sim-Kern soa, echte Karte,
## echte Kasse/Lizenz/Kredit-Funktionen). Je Kandidaten-Stadt (Mittelfurt, Haberau, Kohlberg) N Seeds (Default 100) à 30 Spielminuten.
## Ein Seed legt das Spielerverhalten fest (Kredit-Haltung 35/45/15/5 wie T-14, Route, Lkw-Zahl, Reihenfolge, Nachkauf-Gier).
## Die Sim selbst ist deterministisch, die Streuung kommt also nur aus dem Verhalten. Das ist KEIN kalibrierter Spieler:
## Die Quote ist ein Drift-Wächter (gleiche Seeds, gleicher Code -> gleiche Zahl), kein Beleg für das Band 10–30 % (Referenz: Tobias' Modell).
## Start: godot --headless --path . -s res://tests/d08_bankrott.gd -- [--n=100] [--stadt=kohlberg] [--csv=pfad]
## Prüfungen: Determinismus (Seed 3 zweimal), Aufbau gelingt (Baufehler-Quote), Quote je Stadt gegen den Wächter-Korridor (WACHTER).

const MainScript := preload("res://main.gd")
const TICKS_30 := 18000
const TICKS_MIN := 600
## Korridor des Wächters je Stadt in % (nur bei 100 Seeds scharf). Referenzlauf 01.11. (Daniel, Sandbox, Code-Stand D24 + p95-Fix):
## Mittelfurt 2 %, Haberau 35 %, Kohlberg 38 %. Korridor = Referenz ± 10 Prozentpunkte. Er soll Drift sichtbar machen (Karte, Kosten, Kredit,
## Nachfrage), er sagt NICHT, dass 35 % oder 2 % das Spielziel wären. Das Band 10–30 % ist ein Modellziel (T-14), kein Botziel.
const WACHTER := {"mittelfurt": [0, 12], "haberau": [25, 45], "kohlberg": [28, 48]}

var m: Node
var fails := 0
var checks := 0
var n_seeds := 100
var only_city := ""
var csv_path := ""
var csv_lines: Array = []
var reserve_cent := 0              # Puffer, den der Spieler beim Kaufen stehen lässt (Seed-abhängig)


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--n="):
			n_seeds = int(a.substr(4))
		elif a.begins_with("--stadt="):
			only_city = a.substr(8)
		elif a.begins_with("--csv="):
			csv_path = a.substr(6)
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
	MainScript.core_override = "soa"
	m = load("res://main.tscn").instantiate()
	root.add_child(m)


func _drag(tool: int, a: Vector2i, b: Vector2i) -> bool:
	m._set_tool(tool)
	m.begin_drag(a)
	m.drag_to(b)
	var r: bool = m.end_drag()
	m._set_tool(m.Tool.NONE)
	return r


## Straße als L-Strecke (Ecke wahlweise oben/unten), Ziel ist ein Feld der Stadtstraße, wenn b eine Stadt ist.
func _road(a, b, rng: RandomNumberGenerator) -> bool:
	var pa: Vector2i = a.anchor()
	var pb: Vector2i = b.anchor()
	if b.kind == b.Kind.CITY:
		var best := pb
		var bd := 1e9
		for c in m.city_streets.keys():
			var d: float = Vector2(c - pa).length()
			if d < bd and not m.astar_road.get_id_path(c, pb).is_empty():     # nur Straßenfelder, die zum Stadtzentrum führen
				bd = d
				best = c
		pb = best
	var first := rng.randi() % 2
	for k in 2:
		var corner := Vector2i(pb.x, pa.y) if (k + first) % 2 == 0 else Vector2i(pa.x, pb.y)
		if _drag(m.Tool.ROAD, pa, corner) and _drag(m.Tool.ROAD, corner, pb):
			return true
	return false


func _funds(need: int, pol: int) -> bool:
	## true = bezahlbar (ggf. nach Kredit). pol: 0 nie, 1 bei Bedarf, 2 voll, 3 Hebel
	need += (reserve_cent if need > 0 else 0)
	while m.eco.cash_cent < need and pol != 0 and m.credit.loan_cent < m.credit.limit_cent:
		if m.ui_credit_borrow() <= 0:
			break
	return m.eco.cash_cent >= need


func _licence(b, pol: int) -> bool:
	if m.eco.licence_valid(b.site):
		return true
	var q: Dictionary = m.licence_quote(b)
	if not q.get("ok", false):
		return false
	if not _funds(int(q["zu_zahlen_cent"]), pol):
		return false
	return m.ui_buy_licence(b)


func _line(a, b, n: int, pol: int) -> int:
	var made := 0
	for i in n:
		var price: int = m._vehicle_price("truck") if m.free_trucks_left <= 0 else 0
		if not _funds(price, pol):
			break
		m._set_tool(m.Tool.TRUCK_LINE)
		var n0: int = m.vehicles.size()
		m.click(a.anchor())
		m.click(b.anchor())
		m._set_tool(m.Tool.NONE)
		if m.vehicles.size() > n0:
			made += 1
		else:
			if OS.get_environment("D08_DEBUG") != "":
				print("     DBG Linie %s -> %s fehlgeschlagen: Toast \"%s\", Kasse %d" % [a.map_id, b.map_id, m.toast_label.text, m.eco.cash_cent])
			break
	return made


## Wege je Stadt: Liste von Varianten, jede Variante = Liste von Teilstrecken [von, nach].
func _routes(city: String) -> Array:
	match city:
		"haberau":
			return [[["farm_1", "muehle_1"], ["muehle_1", "haberau"]], [["farm_2", "muehle_1"], ["muehle_1", "haberau"]], [["farm_2", "muehle_1"]],
				[["farm_1", "muehle_1"], ["farm_2", "muehle_1"], ["muehle_1", "haberau"]]]
		"mittelfurt":
			return [[["farm_3", "muehle_2"], ["muehle_2", "mittelfurt"]], [["farm_3", "muehle_2"]], [["farm_3", "muehle_2"], ["muehle_2", "mittelfurt"]]]
		"kohlberg":
			# Stahlwerk braucht Erz UND Kohle: die volle Kette k3 ist erz→stahl, kohle→stahl, stahl→werkzeug
			return [[["kohle_1", "kraftwerk_1"]], [["erz_1", "stahl_1"], ["kohle_1", "stahl_1"], ["stahl_1", "werkzeug_1"]],
				[["kohle_1", "kraftwerk_1"], ["erz_1", "stahl_1"], ["kohle_1", "stahl_1"], ["stahl_1", "werkzeug_1"]]]
	return []


func _play(city: String, seed: int) -> Dictionary:
	_new_main()
	var rng := RandomNumberGenerator.new()
	rng.seed = 90000 + seed * 31 + city.hash() % 1000
	m.place_hq(city)
	var r := rng.randf()
	var pol := 0 if r < 0.35 else (1 if r < 0.80 else (2 if r < 0.95 else 3))
	var routes := _routes(city)
	var ridx := rng.randi() % routes.size()
	var route: Array = routes[ridx]
	var trucks_per := rng.randi_range(1, 3)
	reserve_cent = 0 if pol == 3 else rng.randi_range(2, 12) * 10000
	var greed := rng.randi_range(0, 3)          # wie viele Lkw nachgekauft werden, wenn Geld da ist
	var built := 0
	var failed := 0
	if pol >= 2:
		for i in (4 if pol == 2 else 4):
			m.ui_credit_borrow()
	for leg in route:
		var a = m.by_id[leg[0]]
		var b = m.by_id[leg[1]]
		var good := _licence(a, pol)
		# Verarbeiter braucht ebenfalls eine Lizenz, wenn er weiterliefert (Mühle -> Stadt)
		if a.kind == a.Kind.PROCESSOR:
			good = _licence(a, pol) and good
		if not good:
			failed += 1
			if OS.get_environment("D08_DEBUG") != "":
				print("     DBG %s s%d: Lizenz %s nicht erhältlich (Kasse %d, Quote %s)" % [city, seed, leg[0], m.eco.cash_cent, str(m.licence_quote(a))])
			continue
		if not _funds(2000, pol):
			pass
		if not _road(a, b, rng):
			failed += 1
			if OS.get_environment("D08_DEBUG") != "":
				print("     DBG %s s%d: Straße %s -> %s nicht baubar (Kasse %d)" % [city, seed, leg[0], leg[1], m.eco.cash_cent])
			continue
		var n := _line(a, b, trucks_per, pol)
		if n == 0:
			failed += 1
		else:
			built += 1
	var min_cash: int = m.eco.cash_cent
	var m7 := -1
	var lines: Array = []
	for leg in route:
		lines.append([m.by_id[leg[0]], m.by_id[leg[1]]])
	var minute := 0
	while m.shim.tick_count < TICKS_30 and not m.bankrupt:
		m.run_ticks(TICKS_MIN / 6)
		min_cash = mini(min_cash, m.eco.cash_cent)
		if m7 < 0:
			var all := true
			for ms in m.milestones:
				all = all and ms["done"]
			if all:
				m7 = m.shim.tick_count
		if m.shim.tick_count % TICKS_MIN == 0:
			minute += 1
			# Spielerreaktion einmal pro Minute: Bei-Bedarf-Spieler borgen vor der Pleite, Gierige kaufen Lkw nach
			if pol == 1 and m.eco.cash_cent < 800 * 100 and m.credit.loan_cent < m.credit.limit_cent:
				m.ui_credit_borrow()
			if greed > 0 and minute % 4 == 0 and m.eco.cash_cent > 3000 * 100 and not lines.is_empty():
				var ln: Array = lines[rng.randi() % lines.size()]
				if _funds(m._vehicle_price("truck") + 1000 * 100, 0):
					_line(ln[0], ln[1], 1, 0)
					greed -= 1
	return {"bankrupt": m.bankrupt, "tick": m.shim.tick_count, "min_cash": min_cash, "cash": m.eco.cash_cent, "m7": m7, "pol": pol, "built": built,
		"failed": failed, "trucks": m.vehicles.size(), "loan": m.credit.loan_cent, "route": ridx, "tpl": trucks_per, "reserve": reserve_cent / 100, "revenue": m.eco.revenue_total / 100}


func _run() -> void:
	var T0 := Time.get_ticks_msec()
	var cities := ["mittelfurt", "haberau", "kohlberg"]
	if only_city != "":
		cities = [only_city]
	print("== D-08 Bankrott-Regression im Godot-Spiel: %d Seeds × %d Städte × 30 Spielminuten (soa, 6.000 $, Kredit-Mix 35/45/15/5)" % [n_seeds, cities.size()])
	var det_a := _play("haberau", 3)
	var det_b := _play("haberau", 3)
	ok(det_a["bankrupt"] == det_b["bankrupt"] and det_a["cash"] == det_b["cash"] and det_a["tick"] == det_b["tick"] and det_a["trucks"] == det_b["trucks"],
		"B1 deterministisch: Seed 3 Haberau zweimal gleich (Kasse %d / %d, Tick %d / %d)" % [det_a["cash"], det_b["cash"], det_a["tick"], det_b["tick"]])
	for city in cities:
		var bankr := 0
		var fail_runs := 0
		var m7s: Array = []
		var cash_sum := 0
		var pol_b := [0, 0, 0, 0]
		var pol_n := [0, 0, 0, 0]
		var first_t: Array = []
		var careful_n := 0
		var careful_b := 0
		for s in n_seeds:
			var res := _play(city, s + 1)
			pol_n[res["pol"]] += 1
			if res["bankrupt"]:
				bankr += 1
				pol_b[res["pol"]] += 1
				first_t.append(res["tick"])
			if res["tpl"] == 1:
				careful_n += 1
				careful_b += int(res["bankrupt"])
			if res["failed"] > 0:
				fail_runs += 1
			if res["m7"] >= 0 and not res["bankrupt"]:
				m7s.append(res["m7"] / float(TICKS_MIN))
			cash_sum += res["cash"]
			csv_lines.append("%s,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d" % [city, s + 1, int(res["bankrupt"]), res["tick"], res["min_cash"], res["cash"], res["m7"], res["pol"], res["built"], res["failed"], res["route"], res["tpl"], res["reserve"], res["revenue"]])
		m7s.sort()
		var med: float = float(m7s[m7s.size() / 2]) if m7s.size() > 0 else -1.0
		var rate := 100.0 * bankr / n_seeds
		print("  %-10s Bankrott %d/%d = %.0f %% | Tutorialziele 7/7 (ohne Pleite, n=%d) Median %.0f min | Kasse Ø nach 30 min %d $ | Läufe mit Baufehler %d | nach Haltung nie/Bedarf/voll/Hebel: %d/%d, %d/%d, %d/%d, %d/%d" % [
			city, bankr, n_seeds, rate, m7s.size(), med, cash_sum / n_seeds / 100, fail_runs, pol_b[0], pol_n[0], pol_b[1], pol_n[1], pol_b[2], pol_n[2], pol_b[3], pol_n[3]])
		ok(fail_runs <= n_seeds / 10, "B2 %s: Aufbau gelingt (Läufe mit Baufehler %d von %d, ≤ 10 %%)" % [city, fail_runs, n_seeds])
		ok(careful_b <= maxi(1, careful_n / 20), "B4 %s: vorsichtiger Spieler (1 Lkw je Linie, n=%d) geht nicht pleite (Bankrott %d): Start ist nicht unspielbar" % [city, careful_n, careful_b])
		if n_seeds >= 100 and WACHTER.has(city):
			var w: Array = WACHTER[city]
			ok(rate >= w[0] and rate <= w[1], "B3 %s: Bankrottquote %.0f %% im Wächter-Korridor %d–%d %%" % [city, rate, w[0], w[1]])
	if csv_path != "":
		var f := FileAccess.open(csv_path, FileAccess.WRITE)
		f.store_line("stadt,seed,bankrott,tick,min_kasse_cent,kasse_cent,m7_tick,haltung,teilstrecken_ok,fehler,route,lkw_je_linie,puffer_usd,ertrag_usd")
		for l in csv_lines:
			f.store_line(l)
		f.close()
	print("%d/%d Prüfungen OK, Laufzeit %.1f s (Sandbox)" % [checks - fails, checks, (Time.get_ticks_msec() - T0) / 1000.0])
	quit(0 if fails == 0 else 1)
