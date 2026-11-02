extends SceneTree
## U-03 (S7, Mira): Fehlertexte nach Aylins Liste in BEIDEN Welten, jede neue Zahl gegen den Spielwert (Retro S6),
## 0 stumme Ablehnungen (API-Ebene; Maus-Ebene: tests/u03_play_check.sh), Bankrott-Vorwarnung >= 60 s mit Posten,
## Linienliste scrollt, Kopfleiste bei 1600 px ohne Clipping, Begriffe (U1-U12).
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --path slice -s res://tests/s7_u03_test.gd
## (xvfb statt --headless: headless liefert ein 1600×1600-Fenster, Kopfleiste/Linienliste brauchen echte 1600×900)
## Exit 0 = alle Prüfungen bestanden.

const MAIN := "res://main.tscn"
const MainScript := preload("res://main.gd")
const FT := preload("res://ui/fehlertexte.gd")

var m: Node
var fails := 0
var checks := 0
var welt := "slice"


func _initialize() -> void:
	_run.call_deferred()


func ok(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("  OK   [%s] %s" % [welt, what])
	else:
		fails += 1
		print("  FAIL [%s] %s" % [welt, what])


func _fresh(city_id := "haberau", cash := 10_000_000) -> void:
	if m != null:
		m.free()
	MainScript.world_override = welt
	OS.set_environment("MT_S7_KARTE", "slice")   # W-02: Prüfungen an Slice-Koordinaten (S7-Maßstab, flach)
	m = load(MAIN).instantiate()
	root.add_child(m)
	if OS.get_environment("U03_DEBUG") != "": print("DBG fresh added")
	if city_id != "":
		m.place_hq(city_id)
		if OS.get_environment("U03_DEBUG") != "": print("DBG hq")
		m.eco.cash_cent = cash
	m.toast_label.text = ""


func toast() -> String:
	return m.toast_label.text


## Plan mit gehaltener Maus: Vorschau-Text (Kopf, Grund) und Toast beim Loslassen.
func drag(tool: int, a: Vector2i, b: Vector2i) -> Dictionary:
	m.toast_label.text = ""
	m._set_tool(tool)
	m.begin_drag(a)
	m.drag_to(b)
	var p: Dictionary = m.plan.duplicate(true)
	m._update_cursor_label()
	var head: String = m.cursor_cost.text
	var why: String = m.cursor_reason.text if m.cursor_reason.visible else ""
	var r: bool = m.end_drag()
	var t := toast()
	m._set_tool(m.Tool.NONE)
	return {"ok": r, "plan": p, "head": head, "why": why, "toast": t}


func short(s: String) -> bool:
	return s.length() <= FT.MAX_LEN


func _run() -> void:
	for w in ["slice", "s7"]:
		welt = w
		if OS.get_environment("U03_ONLY") == "liste":
			await _linienliste()
			continue
		_bau()
		_linien()
		_bankrott()
		_begriffe()
		await _hud_1600()
		await _linienliste()
	if m != null:
		m.free()
	MainScript.world_override = ""
	print("%d/%d Prüfungen OK" % [checks - fails, checks])
	quit(0 if fails == 0 else 1)


# ---------------------------------------------------------------- 1 Bau

func _bau() -> void:
	print("== [%s] U-03 Bau B1-B17, S1/S2" % welt)
	_fresh()
	var farm1 = m.by_id["farm_1"]
	var farm2 = m.by_id["farm_2"]
	var mill1 = m.by_id["muehle_1"]
	# B1
	var d := drag(m.Tool.ROAD, farm2.anchor(), mill1.anchor())
	ok(not d["ok"] and d["toast"] == FT.b1_bruecke_diagonal() and d["why"] == FT.b1_bruecke_diagonal(), "B1 diagonal: Vorschau + Toast „%s“" % d["toast"])
	# B2: Bucht > 200 m (Zahl gegen den Spielwert: gezählte Wasserfelder im Pfad). W-03 (Sophie): von Zeile 471 nach 474
	# verschoben, weil Seehafen in S7 beide Ufer in Zeile 471 bebaut (dort dockt der Plan an die Stadt an).
	d = drag(m.Tool.ROAD, Vector2i(184, 474), Vector2i(233, 474))
	var nw := 0
	for c in d["plan"]["cells"]:
		if m.terrain_at(c) == m.Terrain.WATER:
			nw += 1
	ok(not d["ok"] and d["toast"] == FT.b2_bruecke_zu_lang(m, nw) and d["toast"].contains(m.dist_str(nw)) and d["toast"].contains(m.dist_str(m.BRIDGE_MAX)),
		"B2 Fluss %d Felder (%s), max. %s: „%s“" % [nw, m.dist_str(nw), m.dist_str(m.BRIDGE_MAX), d["toast"]])
	# B3
	d = drag(m.Tool.ROAD, Vector2i(375, 335), Vector2i(365, 335))
	ok(not d["ok"] and d["toast"] == FT.b3_brueckenkopf() and d["why"] != "", "B3 Brückenkopf: „%s“" % d["toast"])
	# B4
	d = drag(m.Tool.ROAD, Vector2i(352, 329), Vector2i(352, 341))
	ok(not d["ok"] and d["toast"] == FT.b4_gebaeude(mill1.display_name) and short(d["toast"]), "B4 Gebäude im Weg: „%s“" % d["toast"])
	# B6
	var st := Vector2i(355, 360)
	d = drag(m.Tool.RAIL, st, st)
	ok(m.city_streets.has(st) and not d["ok"] and d["toast"] == FT.b6_gleis_stadt() and d["why"] == FT.b6_gleis_stadt() and not m.rails.has(st), "B6 Gleis Stadtstraße: „%s“" % d["toast"])
	# B7: Ziel außerhalb der Karte (Plan) und Loslassen jenseits des Rands (Maus)
	var p7: Dictionary = m.plan_track(farm1.anchor(), Vector2i(600, 335), false)
	ok(not p7["ok"] and p7["reason"] == FT.b7_aussen(), "B7 Plan über den Rand: „%s“" % p7["reason"])
	# B8: Fehlbetrag = Preis - Kasse (Spielwert), Kredit-Hinweis nur mit freiem Rahmen
	m.eco.cash_cent = 300_000
	d = drag(m.Tool.RAIL, Vector2i(100, 100), Vector2i(300, 300))
	var need: int = d["plan"]["total"]
	var delta: int = need - 300_000
	ok(not d["ok"] and d["toast"].contains(m.money_str(delta)) and d["toast"].contains("Kredit") and d["why"] == d["toast"],
		"B8 Kasse 3.000 $, Preis %s: Fehlbetrag %s im Text „%s“" % [m.money_str(need), m.money_str(delta), d["toast"]])
	m.credit.loan_cent = m.credit.limit_cent
	m.shim.tick_count = maxi(m.shim.tick_count, m.credit.from_ticks)   # nach der Kreditsperre (T-15)
	var r8 := FT.b8_geld(m, need)
	ok(not r8.contains("Kredit") and r8.contains("Warte auf Einnahmen"), "B8 Kreditrahmen voll: „%s“" % r8)
	m.credit.loan_cent = 0
	# T-15: Kredit gesperrt bis credit_available_from_ticks (Wert aus dem JSON; hier 7200 gesetzt wie Tobias' Merge)
	m.credit.from_ticks = 7200
	m.shim.tick_count = 7200 - 2000
	var r8g := FT.b8_geld(m, need)
	var rest: String = m.time_str(2000)
	ok(not r8g.contains("Nimm Kredit") and r8g.contains("ab Minute 12") and r8g.contains(m.money_str(delta)) and short(r8g), "B8 in der Sperrzeit: „%s“" % r8g)
	m._update_hud(0)
	var ktip: String = m.credit_buttons[0].tooltip_text
	ok(m.credit_buttons[0].disabled and ktip == "Kredit ab Minute 12 verfügbar (noch %s)" % rest, "[+] grau mit Hinweis „%s“ (Rest %s)" % [ktip, rest])
	m.ui_credit_borrow()
	ok(toast().begins_with("Kredit ab Minute 12 verfügbar (noch %s)" % rest) and m.credit.loan_cent == 0, "Klick auf [+] in der Sperrzeit: „%s“" % toast())
	ok(FT.l6_fahrzeug_geld(m, "Lkw", m.eco.cash_cent + 100).ends_with("Warte auf Einnahmen (Kredit ab Minute 12)."), "L6/L8/B16 in der Sperrzeit ohne Kredit-Rat")
	m.shim.tick_count = 7200
	m._update_hud(0)
	ok(not m.credit_buttons[0].disabled and FT.b8_geld(m, need).contains("Nimm Kredit"), "ab Minute 12: [+] frei, Kredit-Rat zurück")
	m.credit.from_ticks = 0
	m.shim.tick_count = 0
	m.eco.cash_cent = 10_000_000
	# B9: zweimal dieselbe Strecke
	d = drag(m.Tool.ROAD, farm1.anchor(), mill1.anchor())
	var n_roads: int = m.roads.size()
	var d9 := drag(m.Tool.ROAD, farm1.anchor(), mill1.anchor())
	ok(d["ok"] and d9["toast"] == FT.b9_vorhanden() and d9["why"] == FT.b9_vorhanden() and m.roads.size() == n_roads, "B9 schon vorhanden: Vorschau grau + Toast „%s“" % d9["toast"])
	# B10: Klick ohne Ziehen auf freier Wiese, Loslassen ins Leere
	var free := Vector2i(300, 300)
	var d10 := drag(m.Tool.ROAD, free, free)
	ok(not d10["ok"] and d10["toast"] == FT.b10_kein_ziel() and not m.roads.has(free), "B10 Klick ohne Ziehen: kein Stummel, „%s“" % d10["toast"])
	m.toast_label.text = ""
	m._set_tool(m.Tool.ROAD)
	m.begin_drag(free)
	m.drag_to(Vector2i(-1, -1))
	m.end_drag()
	ok(toast() == FT.b10_kein_ziel(), "B10 Loslassen ohne Ziel: „%s“" % toast())
	m._set_tool(m.Tool.NONE)
	# B13/B14 Abriss
	m.ui_buy_licence(farm1)
	m._set_tool(m.Tool.TRUCK_LINE)
	m.click(farm1.anchor())
	m.click(mill1.anchor())
	m._set_tool(m.Tool.NONE)
	var used: Dictionary = m._used_cells(false)
	var uc := Vector2i(-1, -1)
	for c in used:
		if m.roads.has(c):
			uc = c
			break
	var pd: Dictionary = m.plan_demolish(uc, uc)
	ok(uc.x >= 0 and pd["count"] == 0 and str(pd["reason"]).contains("auflösen"), "B13 Abriss unter Linie: „%s“" % pd["reason"])
	pd = m.plan_demolish(st, st)
	ok(pd["reason"] == FT.b14_abriss_fremd(), "B14 Abriss Stadt: „%s“" % pd["reason"])
	m.toast_label.text = ""
	m.demolish(st, st)
	ok(toast() == FT.b14_abriss_fremd(), "B14 Toast beim Loslassen")
	# B15/B16/B17 Lager
	m.toast_label.text = ""
	m.build_warehouse(Vector2i(365, 335))
	ok(toast() == FT.b15_lager_platz() and short(toast()), "B15 Lager auf Wasser: „%s“" % toast())
	var wc := _free_warehouse_cell()
	m.eco.cash_cent = m.warehouse_cent - 12_345
	m.toast_label.text = ""
	var w0 = m.build_warehouse(wc)
	ok(w0 == null and toast().contains(m.money_str(m.warehouse_cent)) and toast().contains(m.money_str(12_345)), "B16 Lager %s, es fehlen %s: „%s“" % [m.money_str(m.warehouse_cent), m.money_str(12_345), toast()])
	m.eco.cash_cent = 10_000_000
	var tip := ""
	for e in m.tool_buttons:
		if e[0] == m.Tool.WAREHOUSE:
			tip = e[1].tooltip_text
	ok(tip.contains(FT.b17_lager_hinweis()), "B17 Hinweis schon im Werkzeug-Tooltip vor dem Bau")
	m.build_warehouse(wc)
	ok(toast().contains(FT.b17_lager_hinweis()), "B17 Hinweis nach dem Bau: „%s“" % toast())
	# S1: Anschluss-Text in der Vorschau
	_fresh()
	var hab = m.by_id["haberau"]
	mill1 = m.by_id["muehle_1"]
	farm1 = m.by_id["farm_1"]
	farm2 = m.by_id["farm_2"]
	d = drag(m.Tool.ROAD, mill1.anchor(), hab.anchor())
	ok(d["ok"] and d["head"].contains(FT.s1_anschluss(hab.display_name)), "S1 Anschluss: „%s“" % d["head"].replace("\n", " / "))
	# U12: Kopfzeile mit Feldern (S7 + Meter) und Preis aus dem Plan
	var n: int = d["plan"]["new_count"]
	var want := ("Straße: %d Felder (%s) · %s" % [n, m.dist_str(n), m.money_str(d["plan"]["total"])]) if welt == "s7" else ("Straße: %d Felder · %s" % [n, m.money_str(d["plan"]["total"])])
	ok(d["head"].begins_with(want), "U12 Vorschau-Kopf „%s“ (Soll „%s“)" % [d["head"].get_slice("\n", 0), want])
	# Jede Ablehnung mit Text: alle roten Felder tragen einen Grund
	var all_have := true
	for a in [[farm2.anchor(), mill1.anchor()], [Vector2i(194, 471), Vector2i(211, 471)], [Vector2i(352, 329), Vector2i(352, 341)]]:
		var pl: Dictionary = m.plan_track(a[0], a[1], false)
		for it in pl["items"]:
			if it["state"] == "bad" and str(it["reason"]) == "":
				all_have = false
	ok(all_have, "jede rote Fehlstelle trägt eine Ursache")


func _free_warehouse_cell() -> Vector2i:
	for y in range(320, 360):
		for x in range(392, 420):
			if m._warehouse_free(Vector2i(x, y)):
				return Vector2i(x, y)
	return Vector2i(-1, -1)


# ---------------------------------------------------------------- 3 Linien, Lizenz, Kredit

func _linien() -> void:
	print("== [%s] U-03 Linien/Lizenz/Kredit L1-L15" % welt)
	_fresh()
	var farm1 = m.by_id["farm_1"]
	var mill1 = m.by_id["muehle_1"]
	var hab = m.by_id["haberau"]
	var holz = m.by_id["holz_agrar"]
	# L3 ohne Lizenz, L2 liefert nichts, L5 leeres Feld
	m._set_tool(m.Tool.TRUCK_LINE)
	m.click(farm1.anchor())
	ok(toast() == FT.l3_keine_lizenz(farm1.display_name) and m.panel.visible and short(toast()), "L3: „%s“ + Panel offen" % toast())
	m.close_panel()
	m._set_tool(m.Tool.TRUCK_LINE)
	m.click(hab.anchor())
	ok(toast() == FT.l2_liefert_nichts(hab.display_name), "L2: „%s“" % toast())
	m.toast_label.text = ""
	m.click(Vector2i(300, 300))
	ok(toast() == FT.l5_leeres_feld(), "L5 leeres Feld (vorher stumm): „%s“" % toast())
	# L1: keine Verbindung (Ziel Industrie bzw. Stadt -> Stadtrand)
	m.ui_buy_licence(farm1)
	m.ui_buy_licence(mill1)
	m._set_tool(m.Tool.TRUCK_LINE)
	m.click(farm1.anchor())
	m.click(mill1.anchor())
	ok(toast() == FT.l1_keine_verbindung(farm1.display_name, mill1.display_name, false, false) and toast().contains("[1]"), "L1: „%s“" % toast())
	m.click(mill1.anchor())
	m.click(hab.anchor())
	ok(toast() == FT.l1_keine_verbindung(mill1.display_name, hab.display_name, false, true) and toast().contains("Stadtrand von"), "S3: „%s“" % toast())
	# L4: Ziel nimmt Ware nicht an (Getreide an Haberau? Mühle nimmt kein Mehl)
	m._set_tool(m.Tool.TRUCK_LINE)
	m.click(mill1.anchor())
	m.click(m.by_id["farm_2"].anchor())
	ok(toast() == FT.l4_nimmt_nicht(m.by_id["farm_2"].display_name, m.good_names.get(mill1.out_good, "")) and toast().contains(m.good_names.get(mill1.out_good, "?")),
		"L4 nennt die Ware: „%s“" % toast())
	m._set_tool(m.Tool.NONE)
	# L6 Fahrzeug: Fehlbetrag
	m.free_trucks_left = 0
	var price: int = m._vehicle_price("truck")
	m.eco.cash_cent = price - 7_700
	m.buy_vehicle("truck")
	ok(toast().contains(m.money_str(price)) and toast().contains(m.money_str(7_700)), "L6 Lkw %s, es fehlen %s: „%s“" % [m.money_str(price), m.money_str(7_700), toast()])
	# L7/L8/L9/L10
	m.eco.cash_cent = 10_000_000
	m.ui_buy_licence(farm1)
	ok(toast() == FT.l7_schon(farm1.display_name), "L7: „%s“" % toast())
	var f2 = m.by_id["farm_3"]
	var q: Dictionary = m.licence_quote(f2)
	m.eco.cash_cent = int(q["zu_zahlen_cent"]) - 4_200
	m.ui_buy_licence(f2)
	ok(toast().contains(m.money_str(q["zu_zahlen_cent"])) and toast().contains(m.money_str(4_200)), "L8 Lizenz %s, es fehlen %s: „%s“" % [m.money_str(q["zu_zahlen_cent"]), m.money_str(4_200), toast()])
	ok(FT.l9_lizenz_sonst("x_code") == "Lizenz gerade nicht möglich. Bitte erneut klicken (Meldung an uns: x_code).", "L9 Text ohne Rohcode vorn")
	m.toast_label.text = ""
	m.ui_buy_licence(hab)
	ok(toast() == FT.l10_keine_lizenz_noetig(), "L10 (vorher stumm): „%s“" % toast())
	# L11 Verlängerung mit Betrag aus dem Ereignis
	m.eco.cash_cent = 10_000_000
	m.eco.lic_events.append({"site": mill1.site, "ok": true, "cent": 14_000})
	m._licence_events()
	ok(toast() == FT.l11_verlaengert(m, mill1.display_name, 14_000) and toast().contains("140 $"), "L11: „%s“" % toast())
	# L12/L13 Kredit (nach der Kreditsperre, T-15)
	m.shim.tick_count = maxi(m.shim.tick_count, m.credit.from_ticks)
	m.credit.loan_cent = m.credit.limit_cent
	m.ui_credit_borrow()
	ok(toast() == FT.l12_kredit_voll(m) and toast().contains(m.money_str(m.credit.limit_cent)), "L12: „%s“" % toast())
	m.eco.cash_cent = 12_000
	m.ui_credit_repay()
	var miss: int = mini(m.credit.step_cent, m.credit.loan_cent) - 12_000
	ok(toast().contains(m.money_str(miss)) and toast().contains("Warte auf Einnahmen"), "L13 Fehlbetrag %s: „%s“" % [m.money_str(miss), toast()])
	m.credit.loan_cent = 0
	# L14
	m.eco.cash_cent = 2_000_000_000
	for i in m.eco.MAX_VEHICLES_AT_8X + 1:
		m.buy_vehicle("truck")
	m.set_speed(8)
	ok(toast() == FT.l14_tempo8(m.eco.MAX_VEHICLES_AT_8X) and m.speed == 4, "L14: „%s“, Tempo %d×" % [toast(), m.speed])
	# L15: Gratis-Lkw auflösen
	_fresh()
	farm1 = m.by_id["farm_1"]
	mill1 = m.by_id["muehle_1"]
	m.ui_buy_licence(farm1)
	m.build_track(farm1.anchor(), mill1.anchor(), false)
	var v = m.create_line(farm1, mill1, "truck")
	m.remove_line(v.group_key)
	ok(toast() == FT.l15_gratis_rueckkauf(), "L15 Gratis-Lkw: „%s“" % toast())


# ---------------------------------------------------------------- 4 Bankrott

func _bankrott() -> void:
	print("== [%s] U-03 K1/K2 Bankrott-Vorwarnung" % welt)
	_fresh("haberau", 300_000)
	var n := 5
	for i in n:
		m.buy_vehicle("truck")
	m.toast_label.text = ""
	var warn_tick := -1
	var warn_text := ""
	var t_said := -1
	var guard := 0
	while not m.bankrupt and guard < 60000:
		m.sim_tick()
		guard += 1
		if warn_tick < 0 and not m.bk_warn.warn_ticks.is_empty():
			warn_tick = m.bk_warn.warn_ticks[0]
			warn_text = m.bk_warn.last_text
			t_said = m.bk_warn.last_t_sec
	var bt: int = m.shim.tick_count
	var gap_s: float = (bt - warn_tick) * m.tick_ms / 1000.0
	ok(m.bankrupt and warn_tick > 0 and gap_s >= 60.0, "K1 Vorwarnung %.0f s vor dem Bankrott (Soll >= 60 s): „%s“" % [gap_s, warn_text])
	var fix: int = int(m.vdefs["lkw_e1"]["fix_cent_pro_periode"])
	var cm: int = n * fix * m.month_ticks / m.periode_ticks
	var posten := "%d Fahrzeuge ohne Linie" % n
	ok(warn_text.contains(posten) and warn_text.contains("−" + m.money_str(cm) + "/min"), "K1 Posten aus dem Spielwert: %s, −%s/min" % [posten, m.money_str(cm)])
	ok(absf(t_said - gap_s) <= maxf(6.0, gap_s * 0.1) and warn_text.contains(FT.zeit_kurz(t_said)), "K1 Prognose %s gegen echte Restzeit %.0f s" % [FT.zeit_kurz(t_said), gap_s])
	ok(warn_text.length() <= 130, "K1 Länge %d Zeichen (PO: ≤ 130 mit Posten-Name, Liste: 90 ohne Namen)" % warn_text.length())
	var bl: String = m.bankrupt_label.text
	ok(bl.contains("Bankrott: %s kostete %s/min" % [posten, m.money_str(cm)]) and bl.contains(m.bankrupt_cash_str(m.eco.cash_cent)), "K2 Overlay: „%s“" % bl.get_slice("\n", 0))
	# Kein Fehlalarm im laufenden Betrieb mit Gewinn
	_fresh("haberau", 600_000)
	var farm1 = m.by_id["farm_1"]
	var mill1 = m.by_id["muehle_1"]
	m.ui_buy_licence(farm1)
	m.build_track(farm1.anchor(), mill1.anchor(), false)
	m.create_line(farm1, mill1, "truck")
	m.run_ticks(6000)
	ok(not m.bankrupt and m.bk_warn.warn_ticks.is_empty(), "K1 kein Fehlalarm bei Gewinnlinie (10 min, Kasse %s)" % m.money_str(m.eco.cash_cent))


# ---------------------------------------------------------------- 5 Begriffe

func _begriffe() -> void:
	print("== [%s] U-03 Begriffe U1-U10, Radius" % welt)
	_fresh()
	var farm3 = m.by_id["farm_3"]
	m.open_panel(farm3)
	m._refresh_panel()
	var q: Dictionary = m.licence_quote(farm3)
	var bt := _button_text(m.panel_button)
	ok(bt.contains(FT.u1_ertrag(m, q["ertrag_pro_monat_cent"])) and not bt.contains("Monat"), "U1 Lizenzknopf: „%s“" % bt.replace("\n", " / "))
	var tips := ""
	for c in _all(m.ui_root):
		if c is Control:
			tips += c.tooltip_text + "|"
	ok(not tips.contains("Monat") and tips.contains(FT.u10_kasse_tip()), "U1/U10 Tooltips ohne „Monat“, Kasse-Tooltip neu")
	ok(not m.hud_vals.has("skill"), "U4 keine Skillpunkt-Zeile in der Kopfleiste")
	m.toast_label.text = ""
	m.ui_buy_licence(m.by_id["farm_1"])
	m._check_milestones()
	ok(m.milestones[1]["done"] and _toast_seen(FT.u4_skillpunkt()), "U4 Toast bei M1b")
	var hints := ""
	for ms in m.milestones:
		hints += str(ms["hint"]) + str(ms["text"])
	ok(not hints.contains("oben links") and hints.contains("oben rechts") and hints.contains("Liste links"), "U5 „oben links“ ersetzt")
	ok(m.milestones[5]["text"] == "3 Lieferungen mit Ertrag", "U7: „%s“" % m.milestones[5]["text"])
	# U3: Lieferziele mit voller Einheit (Zahl = Linienlänge)
	var farm1 = m.by_id["farm_1"]
	var mill1 = m.by_id["muehle_1"]
	m.build_track(farm1.anchor(), mill1.anchor(), false)
	var v = m.create_line(farm1, mill1, "truck")
	m.open_panel(farm1)
	m._refresh_panel()
	var ft := _all_text(m.panel)
	ok(ft.contains("%s (%s)" % [mill1.display_name, m.dist_str(v.distance)]) and not ft.contains(" F.)"), "U3 Lieferziele „%s (%s)“" % [mill1.display_name, m.dist_str(v.distance)])
	# Radius über main.dist_str, Slice-Text = Daten (bitgleich)
	_fresh("")
	var hab = m.by_id["haberau"]
	var rl: Array = m.hq.preview_lines("haberau")
	var r: int = m.hq.radius_of(hab)
	ok(rl[0]["text"] == "Radius " + m.dist_str(r), "Radius über dist_str: „%s“" % rl[0]["text"])
	if welt == "slice":
		ok(rl[0]["text"] == str(m.hq.vorschau["haberau"]["radius"]), "Slice: Radiuszeile gleich den Vorschau-Daten")
	# U2 Ringlabels: Name + volle Einheit, Zahl = Luftlinie
	m.hq._show(hab)
	var lab_ok := true
	var seen := 0
	for l in m.hq.dist_labels:
		if l.visible:
			seen += 1
			if l.text.ends_with(" F.") or not l.text.contains(" · "):
				lab_ok = false
	ok(lab_ok and seen > 0, "U2 Ringlabels mit Name + Einheit (%d sichtbar)" % seen)
	# U6
	_fresh()
	m.hq._update_ring_label()
	ok(m.hq.ring_label.text == FT.u6_ring(m.hq._mss(m.hq._left_ms())), "U6 Ringlabel: „%s“" % m.hq.ring_label.text)


func _toast_seen(t: String) -> bool:
	return m.toast_label.text == t or m.toast_label.text.contains(t)


func _button_text(b: Button) -> String:
	return b.text + " / " + _all_text(b)


func _all(n: Node) -> Array:
	var out := [n]
	for c in n.get_children():
		out.append_array(_all(c))
	return out


func _all_text(n: Node) -> String:
	var s := ""
	for c in _all(n):
		if c is Label:
			s += c.text + " | "
	return s


# ---------------------------------------------------------------- Kopfleiste 1600 px

func _hud_1600() -> void:
	print("== [%s] U-03 Kopfleiste 1600 px" % welt)
	_fresh()
	m.eco.cash_cent = 123_456_789
	m.eco.revenue_total = 98_765_432
	m.credit.loan_cent = m.credit.limit_cent
	for i in 30:
		m.buy_vehicle("truck")
	m.running_cost_per_period = 4_567_800
	m.shim.tick_count = 599_990
	m._update_hud(m.running_cost_per_period)
	await process_frame
	await process_frame
	var vs: Vector2 = m.get_viewport().get_visible_rect().size
	var vw: float = vs.x
	var clip := []
	for k in m.hud_vals:
		var l: Label = m.hud_vals[k]
		if l.visible and l.get_minimum_size().x > l.size.x + 0.5:
			clip.append("%s %s" % [k, l.text])
		var font: Font = l.get_theme_font("font")
		var fs: int = l.get_theme_font_size("font_size")
		if font != null and font.get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > l.size.x + 0.5:
			clip.append("%s „%s“ > %.0f px" % [k, l.text, l.size.x])
	var right := 0.0
	var speed_left := 99999.0
	for e in m.speed_buttons:
		speed_left = minf(speed_left, e[1].get_global_rect().position.x)
	for k in m.hud_vals:
		var chip: Control = m.hud_vals[k].get_parent().get_parent().get_parent()
		right = maxf(right, chip.get_global_rect().end.x)
	for b in m.credit_buttons:
		right = maxf(right, b.get_global_rect().end.x)
	var last_speed: Control = m.speed_buttons[-1][1]
	ok(vs == Vector2(1600, 900) and clip.is_empty() and right <= speed_left and last_speed.get_global_rect().end.x <= vw,
		"Kopfleiste %d px: kein Abschneiden (%s), Chips bis %.0f px, Tempo ab %.0f bis %.0f px" % [vw, ", ".join(clip), right, speed_left, last_speed.get_global_rect().end.x])


# ---------------------------------------------------------------- Linienliste

func _linienliste() -> void:
	print("== [%s] U-03 Linienliste scrollt" % welt)
	_fresh()
	var farm1 = m.by_id["farm_1"]
	var mill1 = m.by_id["muehle_1"]
	m.ui_buy_licence(farm1)
	m.ui_buy_licence(mill1)
	m.build_track(farm1.anchor(), mill1.anchor(), false)
	var whs: Array = []
	for i in 3:
		var c := _free_warehouse_cell()
		var w = m.build_warehouse(c)
		m.build_track(farm1.anchor(), c, false)
		whs.append(w)
	m.create_line(farm1, mill1, "truck")
	for w in whs:
		m.create_line(farm1, w, "truck")
		m.create_line(w, mill1, "truck")
	var n_groups: int = m.line_order.size()
	m._refresh_lines()
	await process_frame
	await process_frame
	m._refresh_lines()
	await process_frame
	var sc: ScrollContainer = m.lines_scroll
	var max_h: float = m.lines_max_height()
	var content: float = m.lines_box.get_combined_minimum_size().y
	var bar: VScrollBar = sc.get_v_scroll_bar()
	var card_bottom: float = m.lines_card.get_global_rect().end.y
	ok(m.get_viewport().get_visible_rect().size.y == 900.0 and n_groups >= 7 and content > sc.size.y + 1.0 and sc.size.y <= max_h + 1.0 and card_bottom <= m.get_viewport().get_visible_rect().size.y - 150.0,
		"%d Linien: Liste %.0f px hoch (Inhalt %.0f, max. %.0f), Karte endet bei %.0f px über der Werkzeugleiste" % [n_groups, sc.size.y, content, max_h, card_bottom])
	sc.scroll_vertical = int(bar.max_value)
	await process_frame
	m._refresh_lines()
	var last: Dictionary = m.line_rows[m.line_order[-1]]
	var lr: Rect2 = last["row"].get_global_rect()
	var sr: Rect2 = sc.get_global_rect()
	ok(sc.scroll_vertical > 0 and sr.grow(1.0).encloses(lr) and last["val"].text != "" and last["sub"].text != "",
		"nach unten gescrollt: letzte Linie sichtbar und befüllt („%s“, %s)" % [last["title"].text, last["val"].text])
	ok(not m.lines_label.text.contains("weitere Linien"), "kein „… weitere Linien“ mehr")
