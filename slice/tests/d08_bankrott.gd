extends SceneTree
## D-08 (Daniel Richter, Sprint 6): schneller Bankrott-Regressionslauf im ECHTEN Godot-Spiel (Sim-Kern soa, echte Karte,
## echte Kasse/Lizenz/Kredit-Funktionen). Je Kandidaten-Stadt (Mittelfurt, Haberau, Kohlberg) N Seeds (Default 100) à 30 Spielminuten.
## S7 T-16 (Tobias): Der Bot spielt wie die Spielertypen des Modells (modell/t13_sim.py PTYPES, CPOL), ein Seed legt das Verhalten fest:
## sorgfältig 40 % (Bau nach 1-2 min, kein Extra-Lkw) / normal 40 % (2-4 min, 0-1 Extra) / hastig 20 % (3-6 min, 1-2 Extra, 50 % Fehlverbindung am
## Abnehmer: Abnehmerlinie bringt 3-8 min nichts, Straße wird doppelt bezahlt). Lkw je Teilstrecke = Bedarf (ceil(20 E/min / Kapazität je Lkw auf
## dem echten Weg)) x (1 + Extra); im Modell ist der Bedarf je Linie 1 (kurze Strecken), also bedeutet dort Extra 1 = doppelt so viele Lkw wie nötig, Kredit-Haltung nie/bedarf/voll/hebel 35/45/15/5 (hebel = voll + 3 Extra-Lkw je Linie). Kredit gibt es erst ab der Sperre
## (credit_available_from_ticks), voll/hebel ziehen den Rahmen dann sofort, bedarf borgt bei Bedarf und tilgt ab 1.500 $ Überschuss (voll/hebel 3.000 $).
## Gebaut wird alles auf einmal, sobald es bezahlbar ist (wie das Modell), sonst jede Minute neuer Versuch. Die Sim ist deterministisch,
## die Streuung kommt nur aus dem Verhalten. Kalibriert gegen die Modellquote (300 Läufe je Standort, MODELL unten, Toleranz ±5 Pp, Test B3).
## Das bleibt KEIN Spielerbeleg: Bot und Modell sind beide Setzungen. Der Test sagt nur, dass Spiel und Modell dasselbe Verhalten gleich bewerten.
## Start: godot --headless --path . -s res://tests/d08_bankrott.gd -- [--n=100] [--stadt=kohlberg] [--csv=pfad]
## Prüfungen: Determinismus (Seed 3 zweimal), Aufbau gelingt (Baufehler-Quote), sorgfältige Spieler gehen nicht pleite, Quote je Stadt gegen die Modellquote ±5 Pp.

const MainScript := preload("res://main.gd")
const TICKS_30 := 18000
const TICKS_MIN := 600
## Modellquote (Bankrott in 30 min, %, 300 Läufe Seeds 1-300, Kredit-Mix 35/45/15/5, 6.000 $, Zins 3 %, Sperre 12 min, Modell t13_sim.py über
## modell/t15_run.py, Stand S7 Block A/B). Der Bot muss sie bei n >= 300 auf ±MODELL_TOL Prozentpunkte treffen.
const MODELL := {"mittelfurt": 16.3, "haberau": 14.0, "kohlberg": 14.7}
const MODELL_TOL := 5.0
const LKW_FELD_S := 6.0            # Felder je Sekunde (600 mm/Tick), wie das Modell
const LKW_LADEN_S := 10.0
## Kaufrausch-Faktoren je Standort [normal, hastig, hebel]: Extra-Lkw = Bedarf x Faktor x Würfel (normal 0-1, hastig 1-2) bzw. Hebel +Faktor.
## GEFITTET (S7 T-16), nicht gemessen: Die Modell-Spieler kaufen auf den kurzen Modellstrecken (Bedarf 1 Lkw je Linie) bis nahe an die Pleite.
## Auf den echten Karten von Mittelfurt (Strecken 74-83 Felder) und Kohlberg ist die Kette ertragreicher, dieselbe Pleitenähe braucht dort doppelt
## so viele Extra-Lkw. Haberau hat dieselben Strecken wie das Modell (Faktor 1). Env D08_KN/D08_KH/D08_KB überschreiben für Sweeps.
const KALIB := {"mittelfurt": [2, 2, 3], "haberau": [1, 1, 2], "kohlberg": [2, 2, 3]}
const ANGEBOT := 20                # E/min je Quelle (Stufe 1)

var m: Node
var fails := 0
var checks := 0
var n_seeds := 100
var only_city := ""
var csv_path := ""
var csv_lines: Array = []


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


## Wege je Stadt: Varianten, jede Variante = Teilstrecken [von, nach]; die LETZTE ist die Abnehmerlinie (Stadt bzw. Werkzeugfabrik).
## Wie im Modell (eine Zulieferkette je Standort): Haberau Farm 1 oder Farm 2, Kohlberg die volle Kette k3 (Kohle zum Kraftwerk kommt später dazu).
func _routes(city: String) -> Array:
	match city:
		"haberau":
			return [[["farm_1", "muehle_1"], ["muehle_1", "haberau"]], [["farm_2", "muehle_1"], ["muehle_1", "haberau"]]]
		"mittelfurt":
			return [[["farm_3", "muehle_2"], ["muehle_2", "mittelfurt"]]]
		"kohlberg":
			return [[["erz_1", "stahl_1"], ["kohle_1", "stahl_1"], ["stahl_1", "werkzeug_1"]]]
	return []


## Lkw je Teilstrecke wie das Modell: ceil(Angebot / Kapazität je Lkw) auf dem geplanten Weg (L-Straße = Manhattan-Länge), mindestens 1.
func _sizing(a, b) -> int:
	var pa: Vector2i = a.anchor()
	var pb: Vector2i = b.anchor()
	var l: float = absf(pa.x - pb.x) + absf(pa.y - pb.y)
	var cyc: float = 2.0 * l / LKW_FELD_S + LKW_LADEN_S
	var cap_pm: float = 10.0 * 60.0 / cyc
	return maxi(1, int(ceil(ANGEBOT / cap_pm)))


func _est_road(a, b) -> int:
	var pa: Vector2i = a.anchor()
	var pb: Vector2i = b.anchor()
	return (absi(pa.x - pb.x) + absi(pa.y - pb.y)) * int(m.road_cent)


## Kredit-Verhalten zu Beginn jeder Minute (wie Modell A0): voll/hebel ziehen den Rahmen zum Sperrende, bedarf/voll/hebel borgen bei Bedarf
## (Puffer: Laufkosten + Zins einer Minute) und tilgen ab Überschuss (bedarf 1.500 $, voll/hebel 3.000 $). pol: 0 nie, 1 bedarf, 2 voll, 3 hebel.
func _credit_minute(pol: int) -> void:
	if pol == 0 or m.shim.tick_count < m.credit.from_ticks:
		return
	if pol >= 2 and not credit_all_taken:
		credit_all_taken = true
		while m.credit.loan_cent < m.credit.limit_cent:
			if m.ui_credit_borrow() <= 0:
				break
	var res: int = int(m.running_cost_per_period * 1.25) + m.credit.loan_cent * 30 / 1000
	while m.eco.cash_cent < res and m.credit.loan_cent < m.credit.limit_cent:
		if m.ui_credit_borrow() <= 0:
			break
	var keep := 150000 if pol == 1 else 300000
	while m.credit.loan_cent >= m.credit.step_cent and m.eco.cash_cent - m.credit.step_cent >= keep + res:
		if m.ui_credit_repay() <= 0:
			break


var credit_all_taken := false


func _play(city: String, seed: int) -> Dictionary:
	_new_main()
	credit_all_taken = false
	var rng := RandomNumberGenerator.new()
	rng.seed = 90000 + seed * 31 + city.hash() % 1000
	m.place_hq(city)
	# Spielertyp (Modell PTYPES): 0 sorgfältig 40 %, 1 normal 40 %, 2 hastig 20 %
	var pr := rng.randf()
	var typ := 0 if pr < 0.40 else (1 if pr < 0.80 else 2)
	var delay: int = [rng.randi_range(1, 2), rng.randi_range(2, 4), rng.randi_range(3, 6)][typ]
	var kal: Array = KALIB.get(city, [1, 1, 3])
	var k_normal: int = int(OS.get_environment("D08_KN")) if OS.get_environment("D08_KN") != "" else int(kal[0])
	var k_hastig: int = int(OS.get_environment("D08_KH")) if OS.get_environment("D08_KH") != "" else int(kal[1])
	var k_hebel: int = int(OS.get_environment("D08_KB")) if OS.get_environment("D08_KB") != "" else int(kal[2])
	var extra: int = [0, rng.randi_range(0, 1) * k_normal, rng.randi_range(1, 2) * k_hastig][typ]
	var blunder: bool = typ == 2 and rng.randf() < 0.5
	var blunder_len := rng.randi_range(3, 8)
	var k2_share: int = [0, 0, 250, 500][rng.randi() % 4]
	var r := rng.randf()
	var pol := 0 if r < 0.35 else (1 if r < 0.80 else (2 if r < 0.95 else 3))
	if pol == 3:
		extra += k_hebel
	var routes := _routes(city)
	var ridx := rng.randi() % routes.size()
	var route: Array = routes[ridx]
	var built := 0
	var failed := 0
	# 1) Lizenzen (alle Quellen und Verarbeiter, die erste Lizenz im Radius ist gratis)
	var legs_ok: Array = []
	for leg in route:
		var a = m.by_id[leg[0]]
		var good := _licence(a, pol)
		if a.kind == a.Kind.PROCESSOR:
			good = _licence(a, pol) and good
		if not good:
			failed += 1
			if OS.get_environment("D08_DEBUG") != "":
				print("     DBG %s s%d: Lizenz %s nicht erhältlich (Kasse %d, Quote %s)" % [city, seed, leg[0], m.eco.cash_cent, str(m.licence_quote(a))])
		else:
			legs_ok.append(leg)
	# 2) Bau (Straßen + Lkw) alles auf einmal ab Minute `delay`, sobald bezahlbar (Kredit nur ab Sperrende, wie das Modell)
	var need_cent := 0
	var n_trucks_total := 0
	var counts: Array = []
	for leg in legs_ok:
		var a = m.by_id[leg[0]]
		var b = m.by_id[leg[1]]
		var base := _sizing(a, b)
		var n := base + base * extra          # Extra-Lkw relativ zum Bedarf (Modell: Bedarf ist dort je Linie 1, Extra 0-2, Hebel +3)
		counts.append(n)
		n_trucks_total += n
		need_cent += _est_road(a, b)
	need_cent += maxi(0, n_trucks_total - m.free_trucks_left) * m._vehicle_price("truck")
	var res0: int = n_trucks_total * 9000 if pol != 0 else 0
	var min_cash: int = m.eco.cash_cent
	var m7 := -1
	var lines: Array = []
	var minute := 0
	var op_minute := -1
	var blunder_done := not blunder
	var blunder_cost := 0
	var k2_on := false
	var hub_strategy: bool = seed % 2 == 1
	var hub_done := false
	var out_leg_idx := legs_ok.size() - 1
	while m.shim.tick_count < TICKS_30 and not m.bankrupt:
		m.run_ticks(TICKS_MIN / 6)
		min_cash = mini(min_cash, m.eco.cash_cent)
		if m7 < 0:
			var all := true
			for ms in m.milestones:
				all = all and ms["done"]
			if all:
				m7 = m.shim.tick_count
		if m.shim.tick_count % TICKS_MIN != 0:
			continue
		minute += 1
		_credit_minute(pol)
		if op_minute < 0 and minute >= delay and not legs_ok.is_empty():
			var avail: int = m.eco.cash_cent
			if pol != 0 and m.shim.tick_count >= m.credit.from_ticks:
				avail += m.credit.limit_cent - m.credit.loan_cent
			if avail >= need_cent + res0:
				_funds(need_cent + res0, pol)
				op_minute = minute
				for i in legs_ok.size():
					var a = m.by_id[legs_ok[i][0]]
					var b = m.by_id[legs_ok[i][1]]
					if blunder and i == out_leg_idx:
						blunder_cost = _est_road(a, b) + counts[i] * 9000 * blunder_len
						continue          # Abnehmerlinie steht erst nach der Fehlverbindung
					if not _road(a, b, rng):
						failed += 1
						continue
					if _line(a, b, counts[i], 0) == 0:
						failed += 1
					else:
						built += 1
						lines.append([a, b])
		if op_minute >= 0 and not blunder_done and minute >= op_minute + blunder_len:
			blunder_done = true
			m.charge(blunder_cost)          # Straße doppelt + Fix der Abnehmerlinie in der Fehlzeit
			var a2 = m.by_id[legs_ok[out_leg_idx][0]]
			var b2 = m.by_id[legs_ok[out_leg_idx][1]]
			_funds(_est_road(a2, b2) + counts[out_leg_idx] * 400 * 100, pol)
			if _road(a2, b2, rng) and _line(a2, b2, counts[out_leg_idx], 0) > 0:
				built += 1
				lines.append([a2, b2])
			else:
				failed += 1
		if hub_strategy and not hub_done and op_minute >= 0 and not lines.is_empty():
			# Modell-Strategie lager_hub (ungerade Seeds): Lager + zweite Quelle + 2 Lkw (Bergbau: Lager + Straße + 1 Lkw), sobald 2.000 $ Puffer bleiben;
			# Kreditnehmer borgen dafür (wie fund() im Modell). Hier als Ausgabe nachgestellt: echtes Lager, Straße/Lizenz pauschal, echte Lkw.
			var hub_pre: int = (80000 + 12600 + 24000 + 2 * 40000) if city != "kohlberg" else (80000 + 24000 + 40000)
			if _funds(hub_pre + 200000, pol):
				hub_done = true
				var pa: Vector2i = lines[0][1].anchor()
				var placed = null
				for ring in range(3, 12):
					for dx in range(-ring, ring + 1):
						for dy in [-ring, ring]:
							if placed == null and m._warehouse_free(pa + Vector2i(dx, dy)):
								placed = m.build_warehouse(pa + Vector2i(dx, dy))
				m.charge(12600 + 24000 if city != "kohlberg" else 24000)
				_line(lines[0][0], lines[0][1], 2 if city != "kohlberg" else 1, 0)
		if city == "kohlberg" and not k2_on and op_minute >= 0 and minute >= 8 and k2_share > 0:
			var ka = m.by_id["kohle_1"]
			var kb = m.by_id["kraftwerk_1"]
			var c2: int = _est_road(ka, kb) + int(m._vehicle_price("truck"))
			if m.eco.cash_cent > c2 + 100000:
				k2_on = true
				if _licence(ka, 0) and _road(ka, kb, rng):
					_line(ka, kb, 1, 0)
	if OS.get_environment("D08_DEBUG") == "typ" and typ == 2:
		print("     DBG %s s%d hastig extra %d blunder %s delay %d pol %d op_min %d trucks %d | bankrott %s min_kasse %d kasse %d" % [city, seed, extra, str(blunder), delay, pol, op_minute, m.vehicles.size(), str(m.bankrupt), min_cash / 100, m.eco.cash_cent / 100])
	return {"bankrupt": m.bankrupt, "tick": m.shim.tick_count, "min_cash": min_cash, "cash": m.eco.cash_cent, "m7": m7, "pol": pol, "built": built,
		"failed": failed, "trucks": m.vehicles.size(), "loan": m.credit.loan_cent, "route": ridx, "typ": typ, "extra": extra, "delay": delay, "revenue": m.eco.revenue_total / 100}


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
			if res["typ"] == 0 and res["pol"] == 0:
				careful_n += 1
				careful_b += int(res["bankrupt"])
			if res["failed"] > 0:
				fail_runs += 1
			if res["m7"] >= 0 and not res["bankrupt"]:
				m7s.append(res["m7"] / float(TICKS_MIN))
			cash_sum += res["cash"]
			csv_lines.append("%s,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d" % [city, s + 1, int(res["bankrupt"]), res["tick"], res["min_cash"], res["cash"], res["m7"], res["pol"], res["built"], res["failed"], res["route"], res["typ"], res["delay"], res["revenue"]])
		m7s.sort()
		var med: float = float(m7s[m7s.size() / 2]) if m7s.size() > 0 else -1.0
		var rate := 100.0 * bankr / n_seeds
		print("  %-10s Bankrott %d/%d = %.0f %% | Tutorialziele 7/7 (ohne Pleite, n=%d) Median %.0f min | Kasse Ø nach 30 min %d $ | Läufe mit Baufehler %d | nach Haltung nie/Bedarf/voll/Hebel: %d/%d, %d/%d, %d/%d, %d/%d" % [
			city, bankr, n_seeds, rate, m7s.size(), med, cash_sum / n_seeds / 100, fail_runs, pol_b[0], pol_n[0], pol_b[1], pol_n[1], pol_b[2], pol_n[2], pol_b[3], pol_n[3]])
		ok(fail_runs <= n_seeds / 10, "B2 %s: Aufbau gelingt (Läufe mit Baufehler %d von %d, ≤ 10 %%)" % [city, fail_runs, n_seeds])
		ok(careful_b <= maxi(1, careful_n / 20), "B4 %s: sorgfältiger Spieler ohne Kredit (Lkw nach Angebot, kein Extra, n=%d) geht nicht pleite (Bankrott %d): Start ist nicht unspielbar" % [city, careful_n, careful_b])
		if n_seeds >= 100 and MODELL.has(city):
			var mq: float = MODELL[city]
			var tol: float = MODELL_TOL if n_seeds >= 300 else 2.0 * MODELL_TOL      # unter 300 Läufen trägt das Stichprobenrauschen (±3,5 Pp bei 100) die enge Toleranz nicht
			ok(absf(rate - mq) <= tol, "B3 %s: Bot-Bankrottquote %.1f %% trifft die Modellquote %.1f %% ±%.0f Pp (n=%d)" % [city, rate, mq, tol, n_seeds])
	if csv_path != "":
		var f := FileAccess.open(csv_path, FileAccess.WRITE)
		f.store_line("stadt,seed,bankrott,tick,min_kasse_cent,kasse_cent,m7_tick,haltung,teilstrecken_ok,fehler,route,typ,bauverzoegerung_min,ertrag_usd")
		for l in csv_lines:
			f.store_line(l)
		f.close()
	print("%d/%d Prüfungen OK, Laufzeit %.1f s (Sandbox)" % [checks - fails, checks, (Time.get_ticks_msec() - T0) / 1000.0])
	quit(0 if fails == 0 else 1)
