extends RefCounted
## F-16 Ökonomie-Tests (laufen im test_runner). Erwartungswerte werden aus den JSON-Rohwerten
## (eco.slice) mit eigener, einfacher Ganzzahlrechnung gebildet, nicht über die Modul-Funktionen.

const EcoWorld := preload("res://eco_world.gd")
const Economy := preload("res://economy.gd")

var t   # test_runner (check())


func run(runner) -> void:
	t = runner
	test_e0_laden()
	test_e1_nur_endabnehmer()
	test_e2_lager_stempel()
	test_e3_lager_pingpong()
	test_e4_umweg()
	test_e5_saettigung()
	test_e6_lizenz_api()
	test_e7_firma_tempo()
	test_e8_determinismus()
	test_e9_lager_kapazitaet()


func check(c: bool, m: String) -> void:
	t.check(c, m)


## Erwarteter Ertrag, direkt aus JSON-Rohwerten (eine Division durch 10^9, halb auf, B_skill = 0).
static func exp_yield(sl: Dictionary, gut_id: String, units: int, d: int, fz: int, fs: int) -> int:
	var e: Dictionary = sl["ertrag"]
	var price := 0
	for g in sl["gueter"]:
		if g["id"] == gut_id:
			price = sl["preise"]["%s_cent_pro_einheit_feld" % g["preis_ref_id"]]
	var deff: int = 0
	if d >= e["dist_min_felder"]:
		deff = d * 1000 if d <= e["dist_knee_felder"] else e["dist_knee_felder"] * 1000 + e["dist_slope_beyond_promille"] * (d - e["dist_knee_felder"])
	var z: int = units * price * deff * fz * fs
	return (z + 500000000) / 1000000000


func _paid(eco) -> Array:
	return eco.ledger.filter(func(b): return b["cent"] > 0)


# ------------------------------------------------------------------------------------------------

func test_e0_laden() -> void:
	print("E0 JSON laden (F-16): Slice + Konstanten, Festkomma, Gegenprobe")
	var w = EcoWorld.new()
	check(w.eco.ok and w.eco.errors.is_empty(), "economy_slice.json + economy_constants.json geladen, 0 Fehler %s" % str(w.eco.errors))
	check(w.eco.g_ids.size() == w.eco.slice["gueter"].size() and w.eco.i_ids.size() == w.eco.slice["industrien"].size()
		and w.eco.chains.size() == 3, "Güter %d, Industrien %d, Ketten %d (K1–K3)" % [w.eco.g_ids.size(), w.eco.i_ids.size(), w.eco.chains.size()])
	# Negativfall: Gleitkommazahl wird abgelehnt
	var src := FileAccess.get_file_as_string(EcoWorld.SLICE).replace("\"dist_knee_felder\": 60", "\"dist_knee_felder\": 60.5")
	var f := FileAccess.open("user://f16_float_slice.json", FileAccess.WRITE)
	f.store_string(src)
	f.close()
	var e2 = Economy.new()
	var ok2: bool = e2.load_from("user://f16_float_slice.json", EcoWorld.CONSTS)
	check(not ok2 and str(e2.errors).contains("keine Festkommazahl"), "Gleitkommawert im JSON -> Ladefehler (%s)" % str(e2.errors))


## K1 mit Lizenzen: Farm -> Mühle -> Kleinstadt. Ertrag nur bei Mühle (Eingangsgut) und Stadt.
func test_e1_nur_endabnehmer() -> void:
	print("E1 Ertrag nur beim Endabnehmer (K1: Farm -> Mühle -> Kleinstadt)")
	var w = EcoWorld.new()
	var e = w.eco
	var sl: Dictionary = e.slice
	w.node(0, 0, 0, "Farm")
	w.node(1, 18, 0, "Mühle")
	w.node(2, 63, 0, "Kleinstadt A")
	var farm: int = e.add_industry_site(0, "getreidefarm")
	var muehle: int = e.add_industry_site(1, "muehle")
	var stadt: int = e.add_city_site(2, "kleinstadt_a")
	w.road(0, 1)
	w.road(1, 2)
	w.truck([0, 1], [0], [1])
	w.truck([1, 2], [1], [2], 5)
	check(e.start_company("agrar", 2, "kleinstadt"), "Firma Agrar gegründet")
	var cash0: int = e.cash_cent
	check(e.buy_licence(farm)["ok"] and e.buy_licence(muehle)["ok"], "Lizenzen Farm + Mühle gekauft")
	w.sim.run_ticks(6000)
	var paid := _paid(e)
	var at_farm: int = e.s_revenue[farm]
	var bad := paid.filter(func(b): return b["ziel"] != muehle and b["ziel"] != stadt)
	check(at_farm == 0 and bad.is_empty(), "kein Ertrag beim Laden/an der Quelle: Farm %d Cent, Buchungen außerhalb Endabnehmer %d" % [at_farm, bad.size()])
	var g_m := paid.filter(func(b): return b["ziel"] == muehle)
	var m_s := paid.filter(func(b): return b["ziel"] == stadt)
	check(g_m.size() > 0 and m_s.size() > 0, "Lieferungen bezahlt: Getreide an Mühle %d, Mehl an Stadt %d" % [g_m.size(), m_s.size()])
	if g_m.size() > 0:
		var b: Dictionary = g_m[0]
		var ex := exp_yield(sl, "getreide", b["menge"], 18, b["f_zeit"], 1000)
		check(b["ursprung"] == farm and b["felder"] == 18 and b["cent"] == ex,
			"erste Getreide-Lieferung: %d E, Ursprung Farm, 18 Felder, F_zeit %d -> %d Cent (erwartet %d)" % [b["menge"], b["f_zeit"], b["cent"], ex])
	if m_s.size() > 0:
		var b: Dictionary = m_s[0]
		var ex := exp_yield(sl, "mehl", 1, 45, b["f_zeit"], b["f_saett_summe"])
		check(b["ursprung"] == muehle and b["felder"] == 45 and b["cent"] == ex,
			"erste Mehl-Lieferung: Ursprung Mühle, 45 Felder Luftlinie, %d Cent (erwartet %d)" % [b["cent"], ex])
	check(e.cash_cent == cash0 - e.licence_paid_total + e.revenue_total,
		"Kasse = Startkapital − Lizenzen + Erträge (%d = %d − %d + %d)" % [e.cash_cent, cash0, e.licence_paid_total, e.revenue_total])


## Farm -> Lager -> Mühle: Lager zahlt 0, Stempel bleibt, Distanz = Luftlinie Farm -> Mühle.
func test_e2_lager_stempel() -> void:
	print("E2 Zwischenlager zahlt 0 $, Herkunftsstempel bleibt (Farm -> Lager -> Mühle)")
	var w = EcoWorld.new()
	var e = w.eco
	w.node(0, 0, 0, "Farm")
	w.node(1, 10, 15, "Lager")
	w.node(2, 30, 0, "Mühle")
	var farm: int = e.add_industry_site(0, "getreidefarm")
	var lager: int = e.add_warehouse_site(1)
	var muehle: int = e.add_industry_site(2, "muehle")
	w.road(0, 1)
	w.road(1, 2)
	w.truck([0, 1], [0], [1])
	w.truck([1, 2], [1], [2], 3)
	e.start_company("agrar", 2, "kleinstadt")
	e.buy_licence(farm)
	w.sim.run_ticks(4000)
	var to_lager: Array = e.ledger.filter(func(b): return b["ziel"] == lager)
	var lager_cent := 0
	for b in to_lager:
		lager_cent += b["cent"]
	check(to_lager.size() > 0 and lager_cent == 0 and e.s_revenue[lager] == 0,
		"Lieferungen ins Lager: %d, Ertrag dort %d Cent (JSON warehouse_yield_cent = %d)" % [to_lager.size(), lager_cent, e.slice["lager"]["warehouse_yield_cent"]])
	var at_m: Array = e.ledger.filter(func(b): return b["ziel"] == muehle)
	var stamp_ok := at_m.size() > 0
	for b in at_m:
		stamp_ok = stamp_ok and b["ursprung"] == farm and b["felder"] == 30
	check(stamp_ok, "%d Lieferungen an der Mühle, alle mit Ursprung Farm und 30 Feldern Luftlinie (Pfad über Lager %d Felder)" % [
		at_m.size(), (w.sim.graph.route_length(w.sim.graph.route_from_nodes([0, 1, 2])) + 500) / 1000])
	if at_m.size() > 0:
		var b: Dictionary = at_m[0]
		check(b["cent"] == exp_yield(e.slice, "getreide", b["menge"], 30, b["f_zeit"], 1000),
			"Mühle zahlt Luftlinie Farm->Mühle: %d Cent" % b["cent"])


## Lager-Pingpong: ein Lkw lädt und entlädt zwischen zwei Lagern hin und her -> 0 $.
func test_e3_lager_pingpong() -> void:
	print("E3 Lager-Pingpong bringt 0 $")
	var w = EcoWorld.new()
	var e = w.eco
	w.node(0, 0, 0, "Farm")
	w.node(1, 20, 0, "Lager 1")
	w.node(2, 60, 0, "Lager 2")
	var farm: int = e.add_industry_site(0, "getreidefarm")
	e.add_warehouse_site(1)
	e.add_warehouse_site(2)
	w.road(0, 1)
	w.road(1, 2)
	w.truck([0, 1], [0], [1])
	w.truck([2, 1], [1, 2], [1, 2], 600)   # Pingpong: startet an Lager 2, lädt und entlädt an beiden Lagern
	e.start_company("agrar", 0, "kleinstadt")
	e.buy_licence(farm)
	var cash0: int = e.cash_cent
	w.sim.run_ticks(9000)
	var pp: int = w.sim.vehicle(2)["runs"]
	check(e.units_to_warehouse > 100 and pp > 20, "Aktivität: %d Einheiten in Lager umgeschlagen, Pingpong-Lkw %d Fahrten" % [e.units_to_warehouse, pp])
	check(e.revenue_total == 0 and e.cash_cent == cash0, "Ertrag gesamt %d Cent, Kasse unverändert (%d)" % [e.revenue_total, e.cash_cent])


## Umweg: gleicher Abnehmer, einmal gerade 40 Felder, einmal Pfad 1,5× (60 Felder). Ertrag je Lieferung
## nach Luftlinie, also nie höher; gesamt weniger (weniger Fahrten).
func test_e4_umweg() -> void:
	print("E4 Umweg 1,5× Pfad bringt nicht mehr als Luftlinie")
	var res := []
	for detour in [false, true]:
		var w = EcoWorld.new()
		var e = w.eco
		w.node(0, 0, 0, "Farm")
		w.node(2, 40000, 0, "Mühle", true)
		if detour:
			w.node(1, 20000, 22361, "Umweg", true)   # zwei Schenkel à 30 Felder
			w.road(0, 1)
			w.road(1, 2)
		else:
			w.road(0, 2)
		var farm: int = e.add_industry_site(0, "getreidefarm")
		var m: int = e.add_industry_site(2, "muehle")
		var path: Array = [0, 1, 2] if detour else [0, 2]
		w.truck(path, [0], [2])
		e.start_company("agrar", 2, "kleinstadt")
		e.buy_licence(farm)
		w.sim.run_ticks(6000)
		var at_m: Array = e.ledger.filter(func(b): return b["ziel"] == m)
		var per := []
		for b in at_m:
			per.append(b["cent"] * 1000 / b["menge"])
		res.append({"path": w.sim.graph.route_length(w.sim.graph.route_from_nodes(path)), "total": e.s_revenue[m],
			"n": at_m.size(), "first": at_m[0]["cent"] if at_m.size() > 0 else -1, "felder": at_m[0]["felder"] if at_m.size() > 0 else -1,
			"max_per": per.max() if per.size() > 0 else -1})
	var a: Dictionary = res[0]
	var b: Dictionary = res[1]
	print("    gerade: Pfad %d mm, %d Lieferungen, %d Cent; Umweg: Pfad %d mm, %d Lieferungen, %d Cent" % [a["path"], a["n"], a["total"], b["path"], b["n"], b["total"]])
	check(b["path"] * 100 >= a["path"] * 149 and b["path"] * 100 <= a["path"] * 151, "Umweg-Pfad = 1,5× gerade (%d / %d mm)" % [b["path"], a["path"]])
	check(a["felder"] == 40 and b["felder"] == 40, "beide Lieferungen mit 40 Feldern Luftlinie bewertet")
	check(b["max_per"] <= a["max_per"] and b["first"] <= a["first"], "Ertrag je Einheit Umweg (max %d) <= gerade (max %d) [Milli-Cent]" % [b["max_per"], a["max_per"]])
	check(b["total"] <= a["total"], "Ertrag gesamt Umweg %d <= gerade %d Cent" % [b["total"], a["total"]])


## Sättigung: Kennlinie an den JSON-Stützpunkten und Ende-zu-Ende eine Lieferung über 100 % Bedarf.
func test_e5_saettigung() -> void:
	print("E5 Sättigung senkt den Preis wie im JSON (je Stadt und Kategorie)")
	var w = EcoWorld.new()
	var e = w.eco
	var s: Dictionary = e.slice["saettigung"]
	var full: int = s["sat_full_until_promille"]
	var knee: int = s["sat_knee_promille"]
	var flo: int = s["sat_floor_at_150_promille"]
	var over: int = s["sat_over_150_promille"]
	var mid: int = (full + knee) / 2
	check(e.f_saett_promille(full) == 1000 and e.f_saett_promille(mid) == 1000 - (1000 - flo) / 2
		and e.f_saett_promille(knee) == flo and e.f_saett_promille(knee + 1) == over,
		"Kennlinie: %d‰ -> %d, %d‰ -> %d, %d‰ -> %d, >%d‰ -> %d" % [full, e.f_saett_promille(full), mid, e.f_saett_promille(mid), knee, e.f_saett_promille(knee), knee, e.f_saett_promille(knee + 1)])
	# Ende-zu-Ende: Mühle mit 100 Mehl (Stempel Mühle), ein Lkw mit 50 Einheiten an Kleinstadt A (Bedarf Einwohner/100)
	w.node(0, 0, 0, "Mühle")
	w.node(1, 45, 0, "Kleinstadt A")
	var m: int = e.add_industry_site(0, "muehle")
	var st: int = e.add_city_site(1, "kleinstadt_a")
	w.road(0, 1)
	w.truck([0, 1], [0], [1], 0, 50)
	e.start_company("agrar", 1, "kleinstadt")
	e.buy_licence(m)
	e.seed_stock(m, "mehl", 100)
	var demand: int = int(e.slice["staedte"][1]["einwohner_anzahl"]) * s["demand_per_100_inhabitants_einheiten_pro_periode"] / 100
	w.sim.run_ticks(300)
	var at_s: Array = e.ledger.filter(func(b): return b["ziel"] == st)
	check(at_s.size() == 1, "eine Lieferung an die Stadt (%d)" % at_s.size())
	if at_s.size() == 1:
		var b: Dictionary = at_s[0]
		var fs_sum := 0
		for u in range(1, b["menge"] + 1):
			var lvl: int = (u * 1000 * 2 + demand) / (2 * demand)   # halb auf
			var f: int = 1000
			if lvl > knee:
				f = over
			elif lvl > full:
				f = 1000 - ((1000 - flo) * (lvl - full) * 2 + (knee - full)) / (2 * (knee - full))
			fs_sum += f
		var ex := exp_yield(e.slice, "mehl", 1, 45, b["f_zeit"], fs_sum)
		var unsat := exp_yield(e.slice, "mehl", b["menge"], 45, b["f_zeit"], 1000)
		check(b["f_saett_summe"] == fs_sum and b["cent"] == ex,
			"%d Mehl bei Bedarf %d/Periode: Σ F_sätt %d (erwartet %d), %d Cent (erwartet %d)" % [b["menge"], demand, b["f_saett_summe"], fs_sum, b["cent"], ex])
		check(b["cent"] < unsat, "gesättigt %d Cent < ungesättigt %d Cent (−%d %%)" % [b["cent"], unsat, 100 - b["cent"] * 100 / maxi(1, unsat)])


func test_e6_lizenz_api() -> void:
	print("E6 Lizenz-API (1 Klick): Preis, Laufzeit, Ertrag/Monat, Kauf, Laden erst mit Lizenz, Verlängerung")
	var w = EcoWorld.new()
	var e = w.eco
	var sl: Dictionary = e.slice
	var r: Dictionary = sl["hq"]
	w.node(0, 0, 0, "Farm")
	w.node(1, 18, 0, "Mühle")
	w.node(2, 63, 0, "Kleinstadt A")
	w.node(3, 63 + int(r["hq_radius_town_felder"]) + 20, 0, "Mühle fern")
	var farm: int = e.add_industry_site(0, "getreidefarm")
	var m: int = e.add_industry_site(1, "muehle")
	e.add_city_site(2, "kleinstadt_a")
	var fern: int = e.add_industry_site(3, "muehle")
	w.road(0, 1)
	w.truck([0, 1], [0], [1])
	check(not e.licence_quote(m)["ok"], "ohne Firma kein Angebot (%s)" % e.licence_quote(m).get("fehler", ""))
	e.start_company("agrar", 2, "kleinstadt")
	var lz: Dictionary = sl["lizenz"]
	var preis_m: int = sl["industrien"][1]["kaufpreis_stufe1_cent"]
	var q_farm: Dictionary = e.licence_quote(farm)
	check(q_farm["gratis"] and q_farm["zu_zahlen_cent"] == 0, "erste Lizenz gratis (free_licence_count %d)" % r["free_licence_count_anzahl"])
	w.sim.run_ticks(400)
	check(w.sim.vehicle(1)["state"] == w.sim.VState.WARTET_LADUNG and w.sim.vehicle(1)["cargo"] == 0, "ohne Lizenz: Lkw wartet an der Farm, lädt nicht")
	var b0: Dictionary = e.buy_licence(farm)
	check(b0["ok"] and b0["bezahlt_cent"] == 0, "Klick 1 (Farm): gekauft, 0 Cent")
	w.sim.run_ticks(5)
	check(w.sim.vehicle(1)["cargo"] > 0, "nach Kauf lädt der Lkw (%d E)" % w.sim.vehicle(1)["cargo"])
	var q: Dictionary = e.licence_quote(m)
	var ex_cost: int = (preis_m * lz["licence_cost_share_promille"] * (1000 - lz["licence_discount_in_radius_promille"]) + 500000) / 1000000
	var months: int = sl["zeit"]["spielmonat_ticks"] / sl["zeit"]["periode_ticks"]
	var ex_y := exp_yield(sl, "mehl", sl["fabrik"]["factory_throughput_l1_einheiten_pro_periode"] * months, 45, 1000, 1000)
	check(q["ok"] and q["kosten_cent"] == ex_cost and q["kosten_cent"] == 14000, "Mühle im HQ-Radius: %d Cent (JSON-Rechnung %d, F-09-Probe 14.000)" % [q["kosten_cent"], ex_cost])
	check(q["laufzeit_ticks"] == lz["licence_duration_ticks"], "Laufzeit %d Ticks (= %d Spielminuten)" % [q["laufzeit_ticks"], q["laufzeit_ticks"] / sl["zeit"]["periode_ticks"]])
	check(q["ertrag_pro_monat_cent"] == ex_y and q["ertrag_distanz_quelle"] == "welt",
		"Ertrag/Monat %d Cent (Mehl %d E × 45 Felder Luftlinie zur Kleinstadt, erwartet %d)" % [q["ertrag_pro_monat_cent"], sl["fabrik"]["factory_throughput_l1_einheiten_pro_periode"] * months, ex_y])
	var qf: Dictionary = e.licence_quote(fern)
	var d_f: int = int(r["hq_radius_town_felder"]) + 20
	var ex_f: int = (preis_m * lz["licence_cost_share_promille"] * (1000 + lz["licence_surcharge_per_field_promille"] * (d_f - int(r["hq_radius_town_felder"]))) + 500000) / 1000000
	check(qf["kosten_cent"] == ex_f, "Mühle 20 Felder außerhalb Radius: %d Cent (erwartet %d)" % [qf["kosten_cent"], ex_f])
	var cash: int = e.cash_cent
	var b1: Dictionary = e.buy_licence(m)
	check(b1["ok"] and e.cash_cent == cash - ex_cost and e.licence_valid(m), "Klick 2 (Mühle): %d Cent abgebucht, Lizenz gültig bis Tick %d" % [b1["bezahlt_cent"], b1["gueltig_bis_tick"]])
	check(e.buy_licence(m)["fehler"] == "schon_lizenziert", "zweiter Klick: schon_lizenziert")
	var keep: int = e.cash_cent
	e.cash_cent = ex_f - 1
	var b2: Dictionary = e.buy_licence(fern)
	check(not b2["ok"] and b2["fehler"] == "guthaben_reicht_nicht" and e.cash_cent == ex_f - 1, "zu wenig Guthaben: abgelehnt, kein Minus (kein Kredit in S4)")
	e.cash_cent = keep
	var c_before: int = e.cash_cent - e.revenue_total
	var paid0: int = e.licence_paid_total
	w.sim.run_ticks(lz["licence_duration_ticks"] + 20)
	check(e.licence_valid(m) and e.licence_paid_total == paid0 + ex_cost + e._licence_cost(farm),
		"Auto-Verlängerung nach Laufzeit: Mühle + Farm verlängert, %d Cent (Farm-Verlängerung nicht gratis)" % [e.licence_paid_total - paid0])
	check(e.cash_cent == c_before + e.revenue_total - (e.licence_paid_total - paid0), "Kasse konsistent nach Verlängerung")


func test_e7_firma_tempo() -> void:
	print("E7 Firma = Startkapital, kein Kredit; 8×-Tempo nur bis 5k Fahrzeuge")
	var w = EcoWorld.new()
	var e = w.eco
	w.node(0, 0, 0, "HQ")
	check(e.start_company("agrar", 0, "kleinstadt") and e.cash_cent == e.slice["hq"]["start_capital_agrar_cent"], "Agrar: %d Cent" % e.cash_cent)
	var w2 = EcoWorld.new()
	w2.node(0, 0, 0, "HQ")
	check(w2.eco.start_company("bergbau", 0, "dorf") and w2.eco.cash_cent == w2.eco.slice["hq"]["start_capital_mining_cent"]
		and w2.eco.hq_radius_felder == w2.eco.slice["hq"]["hq_radius_village_felder"], "Bergbau: %d Cent, HQ-Radius Dorf %d Felder" % [w2.eco.cash_cent, w2.eco.hq_radius_felder])
	var w3 = EcoWorld.new()
	w3.node(0, 0, 0, "HQ")
	check(not w3.eco.start_company("hafen", 0, "dorf"), "Hafen nicht im Slice -> keine Firma")
	check(not ("kredit" in str(e.get_method_list())), "keine Kredit-Funktion im Modul (S5)")
	check(e.speed_steps(Economy.MAX_VEHICLES_AT_8X).has(8) and not e.speed_steps(Economy.MAX_VEHICLES_AT_8X + 1).has(8)
		and e.speed_steps(10000) == e.slice["genre_standard"]["game_speed_stufen"],
		"Tempo: %s bei 5.000, %s bei 5.001 Fahrzeugen" % [str(e.speed_steps(5000)), str(e.speed_steps(5001))])


func test_e8_determinismus() -> void:
	print("E8 Determinismus Slice-Welt K1–K3 mit Ökonomie, 3 Läufe à 9000 Ticks")
	var cs := []
	var cash := []
	var last
	for k in range(3):
		var w = EcoWorld.slice_world()
		w.sim.run_ticks(9000)
		cs.append(w.sim.checksum())
		cash.append(w.eco.cash_cent)
		last = w
	print("    Prüfsummen %s, Kasse %s" % [str(cs), str(cash)])
	check(cs[0] == cs[1] and cs[1] == cs[2] and cash[0] == cash[1] and cash[1] == cash[2], "3 Läufe identisch (Prüfsumme und Kasse)")
	var e = last.eco
	var by_chain := {}
	for b in e.ledger:
		if b["cent"] > 0:
			var key: String = "%s->%s" % [b["gut"], e.i_ids[e.s_def[b["ziel"]]] if e.s_kind[b["ziel"]] == 0 else e.s_city_id[b["ziel"]]]
			by_chain[key] = by_chain.get(key, 0) + b["cent"]
	print("    Erträge je Gut->Abnehmer (Cent): %s; Lizenzen %d; Start %d -> Kasse %d" % [str(by_chain), e.licence_paid_total, e.start_capital_cent, e.cash_cent])
	check(by_chain.has("getreide->muehle") and by_chain.has("mehl->kleinstadt_a") and by_chain.has("kohle->kraftwerk")
		and by_chain.has("erz->stahlwerk") and by_chain.has("kohle->stahlwerk") and by_chain.has("stahl->werkzeugfabrik"),
		"alle Kanten K1–K3 liefern bezahlt")
	var ok_check: bool = last.sim.checksum() != 0
	var tmp = EcoWorld.slice_world()
	tmp.sim.run_ticks(9000)
	tmp.eco.cash_cent += 1
	check(ok_check and tmp.sim.checksum() != cs[0], "Prüfsumme erfasst Ökonomie (1 Cent Unterschied -> andere Summe)")


## F-21a (S6): Lager nimmt nie über Kapazität an, auch wenn der Bestand (seed_stock) schon darüber liegt.
## Vorher machte mini(q, cap - stock) acc negativ -> on_unload gab < 0 zurück, Ladung und Lose wuchsen.
## 20 Läufe: Zulieferer mit 10/40/70 E, mit/ohne Abholer, jeder 4. Lauf mit Bestand über Kapazität,
## jeder 4. (versetzt) knapp darunter (Lieferung > Restplatz).
func test_e9_lager_kapazitaet() -> void:
	print("E9 Lager <= Kapazität in 20 Läufen (F-21a, economy.gd:746 clampi)")
	var ok_runs := 0
	var detail := []
	for run in range(20):
		var w = EcoWorld.new()
		var e = w.eco
		w.node(0, 0, 0, "Farm")
		w.node(1, 12 + run % 5, 6, "Lager")
		w.node(2, 40, 0, "Mühle")
		var farm: int = e.add_industry_site(0, "getreidefarm")
		var lager: int = e.add_warehouse_site(1)
		e.add_industry_site(2, "muehle")
		w.road(0, 1)
		w.road(1, 2)
		var n_in: int = [10, 40, 70][run % 3]   # Zulieferer-Kapazität (ein Pendler je Straße, sonst Hold-and-Wait)
		w.truck([0, 1], [0], [1], run, n_in)
		var pickup: bool = run % 2 == 0
		if pickup:
			w.truck([1, 2], [1], [2], 300 + run * 13)
		e.start_company("agrar", 2, "kleinstadt")
		e.buy_licence(farm)
		var cap: int = e.warehouse_cap
		var k: int = e.s_station[lager]
		var seeded: bool = run % 4 == 3
		var near: bool = run % 4 == 1   # Grenzlauf: Bestand knapp unter Kapazität, Lieferung größer als Restplatz
		if seeded:
			e.seed_stock(lager, "getreide", cap + 50 + run)
		elif near:
			e.seed_stock(lager, "getreide", cap - 5 - run % 7)
		var sim = w.sim
		var bad := ""
		var max_stock := 0
		var prev: int = sim.st_stock[k]
		for tick in range(4000):
			sim.step()
			var s: int = sim.st_stock[k]
			max_stock = maxi(max_stock, s)
			if s > maxi(cap, prev):
				bad = "Tick %d: Bestand %d > max(Kap %d, vorher %d)" % [sim.tick_count, s, cap, prev]
			elif not seeded and s > cap:
				bad = "Tick %d: Bestand %d > Kap %d" % [sim.tick_count, s, cap]
			for i in range(sim.n):
				if sim.v_cargo[i] < 0 or sim.v_cargo[i] > sim.v_cargo_cap[i]:
					bad = "Tick %d: Lkw %d Ladung %d außerhalb 0..%d" % [sim.tick_count, sim.v_id[i], sim.v_cargo[i], sim.v_cargo_cap[i]]
			prev = s
			if bad != "":
				break
		var activity: bool = e.units_to_warehouse > 0 or seeded
		if near and (max_stock != cap or e.units_to_warehouse == 0):
			activity = false   # Grenzlauf muss das Lager genau bis zur Kapazität füllen
		if bad == "" and activity:
			ok_runs += 1
		else:
			detail.append("Lauf %d: %s" % [run, bad if bad != "" else "keine Lager-Aktivität"])
		if run <= 3:
			print("    Lauf %d: Zulieferer-Kap %d, Abholer %s, Seed %s, max Bestand %d (Kap %d), ins Lager %d E" % [
				run, n_in, str(pickup), str(seeded), max_stock, cap, e.units_to_warehouse])
	check(ok_runs == 20, "Lager <= Kapazität, Ladung 0..Kap in %d/20 Läufen %s" % [ok_runs, str(detail.slice(0, 3))])
