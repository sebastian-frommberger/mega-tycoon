extends SceneTree
## S8 AT-07/AT-08/AT-09 (Mira): Welt-UI der Prototyp-Szene gegen die Spielwerte (headless).
## godot --headless --path slice -s res://tests/proto_ui_welt_test.gd [-- --nur=at07|at08|at09]
## Start ohne Kette (kette_modus "leer", 6.000 $). Weltklicks als echte InputEventMouseButton (Drücken + Loslassen) an die
## projizierte Ortsmitte über _unhandled_input der Szene; Knöpfe headless per pressed.emit() (Layout/echte Maus: xvfb-Test).

var n_ok := 0
var n_fail := 0
var s: Node
var ui
var ps


func ok(c: bool, t: String) -> void:
	if c:
		n_ok += 1
		print("  OK   ", t)
	else:
		n_fail += 1
		print("  FAIL ", t)


func _initialize() -> void:
	_run.call_deferred()


func _nur() -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--nur="):
			return a.substr(6)
	return ""


func _run() -> void:
	print("proto_ui_welt_test")
	var roh: Node = (load("res://proto/prototyp_welt.tscn") as PackedScene).instantiate()
	ok(roh.kette_modus == "leer", "Szenen-Default: Start ohne Kette (kette_modus = %s, PO-Entscheidung AT-08)" % roh.kette_modus)
	roh.free()
	s = (load("res://proto/prototyp_welt.tscn") as PackedScene).instantiate()
	s.kette_modus = "leer"
	root.add_child(s)
	await process_frame
	ui = s.ui_welt
	ps = s.proto_sim
	ok(ui != null and ps != null and ps.eco != null and ps.eco.company_started, "Szene ohne Kette: UiWelt da, Firma gegründet")
	ok(ps.eco.cash_cent == 600000 and ps.fahrzeuge.is_empty(), "Start 6.000 $, 0 Fahrzeuge (Kasse %d ¢)" % ps.eco.cash_cent)
	s.setze_tempo(0)                   # Pause: Zahlen ändern sich nur, wenn der Test tickt
	var nur := _nur()
	if nur == "" or nur == "at07":
		await _at07()
	if nur == "" or nur == "at08":
		await _at08()
	if nur == "" or nur == "at09":
		await _at09()
	if nur == "layout":
		await _at08_maus()
		await _at09_layout()
	print("Prüfungen OK: %d, FAIL: %d" % [n_ok, n_fail])
	quit(0 if n_fail == 0 else 1)


# ------------------------------------------------------------------ Hilfen

func _blick(nm: String, abstand := 700.0) -> void:
	var p: Vector3 = ui.orte_pos[nm]
	s.ziel = Vector3(p.x, 0, p.z)
	s.abstand = abstand
	s.gier = 0.0
	s._kamera_anwenden()


## Echter Weltklick: Drücken + Loslassen an der projizierten Ortsmitte (+ Versatz).
func _klick(nm: String, versatz := Vector2.ZERO) -> void:
	_blick(nm)
	var pos: Vector2 = ui.bildschirm_pos(nm) + versatz
	_maus(pos)


func _maus(pos: Vector2) -> void:
	for gedrueckt in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = gedrueckt
		ev.position = pos
		s._unhandled_input(ev)


func _druecke(id: String) -> bool:
	if not ui.knoepfe.has(id):
		print("    (Knopf fehlt: %s, da: %s)" % [id, str(ui.knoepfe.keys())])
		return false
	(ui.knoepfe[id] as Button).pressed.emit()
	return true


func _panel_text() -> String:
	var t := ""
	var st: Array = [ui.panel_vb]
	while not st.is_empty():
		var n: Node = st.pop_front()
		if n is Label:
			t += (n as Label).text + "\n"
		elif n is Button:
			t += "[" + (n as Button).text + "]\n"
		for c in n.get_children():
			st.append(c)
	return t


func _letzte() -> String:
	return ui.meldungen_log[-1]["text"] if not ui.meldungen_log.is_empty() else ""


## Fahrzeug-Darstellung nach API-Käufen außerhalb der UI neu bauen (wie der Adapter in ui_welt).
func _fz_neu() -> void:
	var alt = s.fahrzeuge
	var neu = preload("res://proto/proto_fahrzeuge.gd").new()
	s.add_child(neu)
	neu.bauen(ps, s.regelwerk)
	s.fahrzeuge = neu
	alt.queue_free()


# ------------------------------------------------------------------ AT-07

func _at07() -> void:
	print("  -- AT-07 Welt-Panel")
	var e = ps.eco
	ok(not ui.panel.visible and ui.panel.mouse_filter == Control.MOUSE_FILTER_STOP and ui.toast_panel.mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"Panel zu; Panel STOP (Klicks nicht in die Welt), Toast IGNORE")
	# Klick daneben (60 px) öffnet nichts
	_klick("Gut Kuppenhof", Vector2(60, 60))
	ok(ui.auswahl == "", "Klick 60 px neben Gut Kuppenhof öffnet nichts")
	# Ziehen ist kein Klick
	_blick("Gut Kuppenhof")
	var p0: Vector2 = ui.bildschirm_pos("Gut Kuppenhof")
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = p0
	s._unhandled_input(ev)
	var ev2 := InputEventMouseButton.new()
	ev2.button_index = MOUSE_BUTTON_LEFT
	ev2.pressed = false
	ev2.position = p0 + Vector2(30, 0)
	s._unhandled_input(ev2)
	ok(ui.auswahl == "", "Ziehen (30 px) öffnet kein Panel")
	_klick("Gut Kuppenhof")
	ok(ui.auswahl == "Gut Kuppenhof" and ui.panel.visible, "Klick auf Gut Kuppenhof öffnet das Panel")
	# --- Farm: Bestand, Rate, Lizenz
	for i in 1200:
		ps.tick()
	ui.panel_neu()
	var site: int = ui.site_of("Gut Kuppenhof")
	e.sync_all(ps.sim)                 # Spielwert: Rohstoffbestand nachgezogen (economy-Lesesicht)
	var b_spiel: int = ps.sim.st_stock[e.s_station[site]]
	var pt := _panel_text()
	ok(ui.panel_werte["bestand"] == b_spiel and pt.contains("Bestand %d E" % b_spiel), "Farm Bestand %d E = Spielwert %d (Tick %d)" % [ui.panel_werte["bestand"], b_spiel, ps.sim.tick_count])
	ok(ui.panel_werte["rate"] == e.s_rate[site] and pt.contains("liefert %d E/min" % e.s_rate[site]), "Farm liefert %d E/min = s_rate" % e.s_rate[site])
	ok(pt.contains("Lizenz: keine"), "Lizenzzeile: keine")
	var q: Dictionary = e.licence_quote(site, false)
	ok(ui.panel_werte["lizenz_preis"] == q["zu_zahlen_cent"] and pt.contains("[Lizenz kaufen %s]" % ui.geld(q["zu_zahlen_cent"])),
		"Vorschaupreis Lizenz %s = licence_quote" % ui.geld(q["zu_zahlen_cent"]))
	ok(ui.panel_werte.get("abnehmer", []) == ["Erlenmühle"], "Abnehmer in Reichweite: %s" % str(ui.panel_werte.get("abnehmer", [])))
	var k0: int = e.cash_cent
	var vor: int = ui.panel_werte["lizenz_preis"]
	ok(_druecke("lizenz_kaufen"), "Knopf Lizenz kaufen")
	ok(k0 - e.cash_cent == vor and e.licence_valid(site), "Lizenzkauf Kuppenhof: Kasse −%d ¢ = Vorschau %d ¢ ± 0" % [k0 - e.cash_cent, vor])
	ok(_letzte().begins_with("Lizenz für Gut Kuppenhof gekauft, sie gilt 30 min."), "Toast: %s" % _letzte())
	pt = _panel_text()
	var rest: int = int(ceil((e.s_lic_until[site] - ps.sim.tick_count) / 600.0))
	ok(ui.panel_werte["lizenz_rest_min"] == rest and pt.contains("gilt noch %d min" % rest), "Lizenz gilt noch %d min = s_lic_until" % rest)
	ui.lizenz_kaufen("Gut Kuppenhof")
	ok(_letzte() == "Gut Kuppenhof ist schon lizenziert, noch %d min." % rest, "F1.3: %s" % _letzte())
	# --- Mühle: Preis > 0, zu wenig Geld (F1.1), Kauf
	_klick("Erlenmühle")
	var sm: int = ui.site_of("Erlenmühle")
	var qm: Dictionary = e.licence_quote(sm, false)
	ok(ui.auswahl == "Erlenmühle" and ui.panel_werte["lizenz_preis"] == qm["zu_zahlen_cent"] and qm["zu_zahlen_cent"] > 0,
		"Mühle: Vorschaupreis %s = licence_quote (> 0)" % ui.geld(qm["zu_zahlen_cent"]))
	ok(ui.panel_werte["bedarf"] == e.s_rate[sm] and ui.panel_werte.has("eingang_getreide") and ui.panel_werte["eingang_getreide"] == e.s_inbuf[sm][e.g_index["getreide"]],
		"Mühle: Bedarf %d E/min = Durchsatz, Eingang Getreide %d E = s_inbuf" % [ui.panel_werte["bedarf"], ui.panel_werte["eingang_getreide"]])
	ok(ui.panel_werte["bestand"] == ui.bestand(sm) and ui.bestand(sm) == ps.sim.st_stock[e.s_station[sm]], "Mühle: Bestand Mehl %d E = st_stock" % ui.panel_werte["bestand"])
	var echt: int = e.cash_cent
	e.cash_cent = qm["zu_zahlen_cent"] - 150     # Test: 1,50 $ zu wenig
	ui.panel_neu()
	var lk: Button = ui.knoepfe["lizenz_kaufen"]
	ok(lk.tooltip_text == "Es fehlen 2 $." and not lk.disabled, "Knopf grau, aber klickbar; Tooltip nennt Fehlbetrag (%s)" % lk.tooltip_text)
	var k1: int = e.cash_cent
	_druecke("lizenz_kaufen")
	ok(e.cash_cent == k1 and not e.licence_valid(sm) and _letzte() == "Lizenz kostet %s, es fehlen 2 $. Kredit gibt es erst ab Minute 12." % ui.geld(qm["zu_zahlen_cent"]),
		"F1.1 (vor Minute 12): %s" % _letzte())
	e.cash_cent = echt
	ui.panel_neu()
	k0 = e.cash_cent
	vor = ui.panel_werte["lizenz_preis"]
	_druecke("lizenz_kaufen")
	ok(k0 - e.cash_cent == vor and e.licence_valid(sm), "Lizenzkauf Mühle: Kasse −%d ¢ = Vorschau %d ¢ ± 0" % [k0 - e.cash_cent, vor])
	# --- Ort und HQ
	_klick("Erlenbach")
	var so: int = ui.site_of("Erlenbach")
	pt = _panel_text()
	ok(ui.auswahl == "Erlenbach" and ui.panel_werte["bedarf"] == e.city_demand(so) and pt.contains("Bedarf %d E/min" % e.city_demand(so)),
		"Erlenbach: Bedarf %d E/min = city_demand" % e.city_demand(so))
	ok(ui.panel_werte["einwohner"] == int(e.c_index[e.s_city_id[so]]["einwohner_anzahl"]), "Erlenbach: Einwohner %d = Sim (sim_ew)" % ui.panel_werte["einwohner"])
	ok(pt.contains("Lizenz: nicht nötig") and not ui.knoepfe.has("lizenz_kaufen") and not ui.knoepfe.has("linie_von_hier"), "Ort: Lizenz nicht nötig, kein Kauf-/Linienknopf")
	ui.lizenz_kaufen("Erlenbach")
	ok(_letzte() == "Erlenbach braucht keine Lizenz. Lege direkt eine Linie dorthin.", "F1.4: %s" % _letzte())
	var d: Dictionary = ps.vdef(ps.def_fuer("fuhrwerk"))
	ok(ui.ist_hq(so) and pt.contains("Fuhrhalterei") and pt.contains("Unterhalt enthält Futter, Knecht, Stellmacher.")
		and ui.panel_werte["fuhrwerk_preis"] == int(d["kauf_cent"]) and ui.panel_werte["fuhrwerk_fix"] == int(d["fix_cent_pro_periode"])
		and pt.contains("Fuhrwerk %s · Unterhalt %s/min" % [ui.geld(int(d["kauf_cent"])), ui.geld(int(d["fix_cent_pro_periode"]))]),
		"HQ Erlenbach: Fuhrhalterei-Eintrag, Fuhrwerk %s, Unterhalt %s/min = vehicles.json" % [ui.geld(int(d["kauf_cent"])), ui.geld(int(d["fix_cent_pro_periode"]))])
	_klick("Lindenfurt")
	ok(ui.auswahl == "Lindenfurt" and not ui.ist_hq(ui.site_of("Lindenfurt")) and not _panel_text().contains("Fuhrhalterei"), "Lindenfurt: kein HQ-Eintrag")
	# --- Sättigung gegen Spielwert: Linien über die API, Ticks bis Mehl in Erlenbach ankommt
	var r1: Dictionary = ps.linie_anlegen("Gut Kuppenhof", "Erlenmühle")
	var r2: Dictionary = ps.linie_anlegen("Erlenmühle", "Erlenbach")
	_fz_neu()
	var kat: String = e.g_cat[e.g_index["mehl"]]
	var gefunden := false
	for i in 9000:
		ps.tick()
		if i % 50 == 0 and ui.ort_geliefert(so, kat) > 0:
			gefunden = true
			break
	_klick("Erlenbach")
	var per: int = ps.sim.tick_count / e.periode_ticks
	var geliefert: int = e.s_sat[so].get(kat, 0) if e.s_sat_period[so] == per else 0
	var pct: int = Economy_rdiv(geliefert * 100, e.city_demand(so))
	pt = _panel_text()
	ok(r1["ok"] and r2["ok"] and gefunden and ui.panel_werte["geliefert_" + kat] == geliefert and ui.panel_werte["saettigung_" + kat] == pct
		and pt.contains("%s: %d %% (%d von %d E diese Minute)" % [kat.capitalize(), pct, geliefert, e.city_demand(so)]),
		"Erlenbach Sättigung %s %d %% (%d E) = s_sat (Tick %d)" % [kat, pct, geliefert, ps.sim.tick_count])
	_klick("Erlenmühle")
	ok(_panel_text().contains("Erlenbach") and _panel_text().contains("%d %%" % pct), "Mühle-Panel: Abnehmer Erlenbach mit Sättigung %d %%" % pct)
	# --- Esc: erst Panel zu, Szene bleibt
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	s._unhandled_input(esc)
	ok(ui.auswahl == "" and not ui.panel.visible and s.is_inside_tree(), "Esc schließt das Panel, die Szene bleibt (G5)")
	# --- alle Meldungen ≤ 90 Zeichen mit echten Werten
	var lang: Array = []
	for m in ui.meldungen_log:
		if String(m["text"]).length() > 90:
			lang.append(m["text"])
	ok(lang.is_empty(), "%d Meldungen, alle ≤ 90 Zeichen mit eingesetzten Werten %s" % [ui.meldungen_log.size(), str(lang)])
	for i in 3:
		await process_frame
	ok(true, "3 Frames nach den Käufen ohne Fehler")


# ------------------------------------------------------------------ AT-08

func _neue_szene() -> void:
	if s != null:
		s.queue_free()
		await process_frame
	s = (load("res://proto/prototyp_welt.tscn") as PackedScene).instantiate()
	s.kette_modus = "leer"
	root.add_child(s)
	await process_frame
	ui = s.ui_welt
	ps = s.proto_sim
	s.setze_tempo(0)


func _at08() -> void:
	print("  -- AT-08 Linie anlegen, Fuhrwerk kaufen, Routenvorschau")
	await _neue_szene()
	var e = ps.eco
	var d: Dictionary = ps.vdef(ps.def_fuer("fuhrwerk"))
	var preis := int(d["kauf_cent"])
	ui.klicks = 0
	var lizenzklicks := 0
	# 1 Klick Gut Kuppenhof, 2 Lizenz, 3 Linie von hier, 4 Klick Erlenmühle, 5 Anlegen
	_klick("Gut Kuppenhof")
	_druecke("lizenz_kaufen")
	lizenzklicks += 1
	_druecke("linie_von_hier")
	ok(ui.modus_von == "Gut Kuppenhof" and ui.modus_panel.visible, "Modus Linie von Gut Kuppenhof (Modusleiste sichtbar)")
	_klick("Erlenmühle")
	var v: Dictionary = ui.vorschau_werte
	var a: Dictionary = ps.stationen["Gut Kuppenhof"]
	var b: Dictionary = ps.stationen["Erlenmühle"]
	var route: Array = ps.sim.graph.find_path(int(a["knoten"]), int(b["knoten"]))
	var strecke := roundi(ps.sim.graph.route_length(route) / ps.mm_pro_m)
	ok(ui.vorschau_panel.visible and v.get("nach", "") == "Erlenmühle", "Vorschau Gut Kuppenhof → Erlenmühle offen")
	ok(v["preis_cent"] == preis and v["fix_cent"] == int(d["fix_cent_pro_periode"]) and v["strecke_m"] == strecke
		and v["felder"] == e.luftlinie_felder(int(a["site"]), int(b["site"])),
		"Vorschau = Spielwerte: Preis %s, Unterhalt %s/min, Strecke %d m, %d Felder" % [ui.geld(v["preis_cent"]), ui.geld(v["fix_cent"]), v["strecke_m"], v["felder"]])
	var g: int = e.g_index["getreide"]
	ok(v["ertrag_fuhre_cent"] == e.yield_cent(g, v["felder"], 1000, int(d["kapazitaet_einheiten"]) * 1000), "Ertrag je Fuhre %s = yield_cent (volle Frische, ohne Sättigung)" % ui.geld(v["ertrag_fuhre_cent"]))
	var k0: int = e.cash_cent
	_druecke("anlegen")
	ok(k0 - e.cash_cent == v["preis_cent"] and ps.fahrzeuge.size() == 1 and s.fahrzeuge.mmis.size() == 1,
		"Anlegen: Kasse −%d ¢ = Vorschaupreis ± 0, 1 Fuhrwerk, Darstellung neu gebaut" % (k0 - e.cash_cent))
	ok(_letzte() == "Linie Gut Kuppenhof → Erlenmühle läuft. Fuhrwerk 1 ist unterwegs.", "Toast: %s" % _letzte())
	ok(ui.modus_von == "Erlenmühle" and ui.auswahl == "Erlenmühle", "Kette: Modus geht an der Erlenmühle weiter, Panel Erlenmühle offen")
	ok(ui.knoepfe.has("modus_lizenz"), "Modusleiste: Erlenmühle ohne Lizenz, Kauf-Knopf in der Leiste")
	# keine Lizenz (Fehlerfall 3): Ziel klicken, bevor die Mühle lizenziert ist
	var n_log: int = ui.meldungen_log.size()
	var k_vor: int = ui.klicks
	_klick("Erlenbach")
	ok(ui.meldungen_log.size() == n_log + 1 and _letzte() == "Erlenmühle hat keine Lizenz. Kaufe sie im Panel (Klick auf das Gebäude)." and ps.fahrzeuge.size() == 1,
		"Fehlerfall keine Lizenz: %s" % _letzte())
	ui.klicks = k_vor                  # Fehlklick zählt nicht in den Erfolgsweg
	# 6 Lizenz Mühle (Leiste), 7 Klick Erlenbach, 8 Anlegen
	_druecke("modus_lizenz")
	lizenzklicks += 1
	_klick("Erlenbach")
	k0 = e.cash_cent
	_druecke("anlegen")
	ok(ps.fahrzeuge.size() == 2 and k0 - e.cash_cent == preis and ui.modus_von == "" and ui.auswahl == "Erlenbach",
		"Mehl-Linie Erlenmühle → Erlenbach angelegt (−%d ¢), Modus endet am Dorf" % (k0 - e.cash_cent))
	var klicks_ges: int = ui.klicks
	ok(klicks_ges - lizenzklicks <= 6, "Farm → Mühle → Dorf: %d Klicks gesamt, davon %d Lizenzklicks, %d Klicks ohne Lizenzen (Soll ≤ 6)" % [klicks_ges, lizenzklicks, klicks_ges - lizenzklicks])
	# + Fuhrwerk aus dem Panel (≤ 2 Klicks)
	ui.klicks = 0
	_klick("Gut Kuppenhof")
	ps.tick()                          # Fix der bisherigen Käufe ist gebucht (dirty → konto.fix_neu)
	k0 = e.cash_cent
	var fix0: int = ps.konto.running_cost_per_period
	_druecke("plus_Erlenmühle")
	ok(ui.klicks == 2 and ps.fahrzeuge.size() == 3 and k0 - e.cash_cent == preis, "+ Fuhrwerk: 2 Klicks ab Welt, Kasse −%d ¢ = Preis ± 0" % (k0 - e.cash_cent))
	ps.tick()
	ok(ps.konto.running_cost_per_period == fix0 + int(d["fix_cent_pro_periode"]) and _letzte().begins_with("Fuhrwerk 3 gekauft: −300 $, Unterhalt +60 $/min."),
		"Fix je Minute +%s; Toast: %s" % [ui.geld(int(d["fix_cent_pro_periode"])), _letzte()])
	ok(ui.panel_werte.get("linie_Erlenmühle", 0) == 2, "Panel: Linie → Erlenmühle mit 2 Fuhrwerken")
	# Frames laufen mit den neuen Fahrzeugen
	s.setze_tempo(4)
	for i in 30:
		await process_frame
	s.setze_tempo(0)
	ok(s.fahrzeuge.mmis["fuhrwerk"].multimesh.instance_count == 3, "30 Frames mit 3 Fuhrwerken (MultiMesh 3 Instanzen)")
	# --- Fehlerfälle: kein Geld, keine Verbindung, weitere (nie stumm)
	var echt: int = e.cash_cent
	e.cash_cent = 100
	ui.linie_von_hier("Gut Kuppenhof")
	_klick("Erlenmühle")
	ok(_letzte() == "Diese Linie gibt es schon. Füge ihr ein Fuhrwerk hinzu (+ Fuhrwerk)." and (ui.knoepfe["anlegen"] as Button).text.begins_with("+ Fuhrwerk"),
		"F2.6 Linie gibt es schon: Text + Knopf „+ Fuhrwerk“")
	var vt := ""
	for c in ui.vorschau_vb.get_children():
		if c is Label:
			vt += (c as Label).text + "\n"
	ok(vt.contains("▲ Gut Kuppenhof liefert nur 20 E/min. Ein weiteres Fuhrwerk bringt kaum mehr."), "F3.2 Hinweis in der Vorschau (Quelle begrenzt, Kauf bleibt möglich)")
	var anl: Button = ui.knoepfe["anlegen"]
	ok(anl.tooltip_text == "Es fehlen 299 $." and not anl.disabled, "Kein Geld: Knopf grau, klickbar, Tooltip %s" % anl.tooltip_text)
	n_log = ui.meldungen_log.size()
	_druecke("anlegen")
	ok(ui.meldungen_log.size() == n_log + 1 and _letzte() == "Fuhrwerk kostet 300 $, es fehlen 299 $. Nimm Kredit oder warte auf Einnahmen." and ps.fahrzeuge.size() == 3 and e.cash_cent == 100,
		"Fehlerfall kein Geld: %s" % _letzte())
	e.cash_cent = echt
	# keine Verbindung: Insel-Station auf einem Knoten ohne Kante (Testaufbau)
	var nid: int = 0
	for k in ps.sim.graph.nodes:
		nid = maxi(nid, int(k) + 1)
	var pa: Vector2i = ps.sim.graph.nodes[int(ps.stationen["Erlenbach"]["knoten"])]["pos"]
	ps.sim.graph.add_node(nid, pa + Vector2i(4000000, 0), "Insel")
	var sid: int = e.add_city_site(nid, String(e.s_city_id[ui.site_of("Erlenbach")]))
	ps.stationen["Insel"] = {"knoten": nid, "site": sid, "k": e.s_station[sid], "id": "insel"}
	ui.orte_pos["Insel"] = ui.orte_pos["Erlenbach"] + Vector3(60, 0, 0)
	ui.linie_von_hier("Erlenmühle")
	n_log = ui.meldungen_log.size()
	_klick("Insel")
	ok(ui.meldungen_log.size() == n_log + 1 and _letzte() == "Zwischen Erlenmühle und Insel gibt es keine Straße. Wähle ein Ziel am bestehenden Netz." and not ui.vorschau_panel.visible,
		"Fehlerfall keine Verbindung: %s" % _letzte())
	var r: Dictionary = ps.linie_anlegen("Erlenmühle", "Insel")
	ok(not r["ok"] and ui.linie_fehlertext("Erlenmühle", "Insel", r) == _letzte(), "API keine_verbindung → derselbe Text")
	# weitere Ablehnungen aus AT-14 S2
	ui.linie_von_hier("Gut Kuppenhof")
	_klick("Erlenbach")
	ok(_letzte() == "Erlenbach nimmt Getreide nicht an. Wähle einen Abnehmer, der sie braucht.", "F2.4: %s" % _letzte())
	_klick("Gut Kuppenhof")
	ok(_letzte() == "Start und Ziel sind gleich. Wähle ein anderes Ziel.", "F2.8: %s" % _letzte())
	_blick("Gut Kuppenhof")
	_maus(ui.bildschirm_pos("Gut Kuppenhof") + Vector2(200, 200))
	ok(_letzte() == "Klicke ein Gebäude an: erst die Quelle, dann das Ziel." and ui.modus_von == "Gut Kuppenhof", "F2.7 Klick ins Leere: %s, Modus bleibt" % _letzte())
	ui.linie_von_hier("Erlenbach")
	ok(_letzte() == "Erlenbach liefert nichts. Starte die Linie bei Farm, Mühle oder Lager." and ui.modus_von == "Gut Kuppenhof", "F2.2: %s" % _letzte())
	ok(ui.fuhrwerk_kaufen("Hof Hasenwinkel", "Erlenmühle").get("fehler", "") == "keine_lizenz" and _letzte() == "Hof Hasenwinkel hat keine Lizenz. Kaufe sie im Panel (Klick auf das Gebäude)." and ui.auswahl == "Hof Hasenwinkel",
		"F2.3 auch beim Kauf ohne Modus, Panel Hof Hasenwinkel öffnet")
	# Esc: Modus ohne Text, dann Panel, dann Menü
	ui.linie_von_hier("Gut Kuppenhof")
	n_log = ui.meldungen_log.size()
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	s._unhandled_input(esc)
	ok(ui.modus_von == "" and not ui.modus_panel.visible and ui.meldungen_log.size() == n_log and ui.auswahl != "", "Esc beendet den Modus ohne Text, Panel bleibt")
	s._unhandled_input(esc)
	ok(ui.auswahl == "" and s.is_inside_tree(), "Esc schließt danach das Panel")
	# Vorschau gegen Messung nach 5 min (UX-2, nur gemessen, keine Abnahme hier)
	await _vorschau_messung()


## Eine Linie Kuppenhof → Mühle (1 Fuhrwerk) in neuer Szene: Vorschau ca. $/min gegen gemessenes Netto der Minuten 2–6.
func _vorschau_messung() -> void:
	await _neue_szene()
	var e = ps.eco
	ps.lizenz_kaufen("Gut Kuppenhof")
	ui.linie_von_hier("Gut Kuppenhof")
	ui.ziel_waehlen("Erlenmühle")
	var vor: int = ui.vorschau_werte["netto_min_cent"]
	ui.anlegen()
	for i in 1200:
		ps.tick()
	var r0: int = e.revenue_total
	var x0: int = ps.konto.expenses_total
	for i in 3000:
		ps.tick()
	var netto: float = ((e.revenue_total - r0) - (ps.konto.expenses_total - x0)) / 5.0
	var abw: float = (vor - netto) / maxf(1.0, absf(netto)) * 100.0
	print("    MESSUNG Vorschau Kuppenhof → Mühle: ca. %s/min, gemessen %s/min (Minute 2–7), Abweichung %+.1f %%" % [ui.geld(vor), ui.geld(roundi(netto)), abw])
	ok(true, "Vorschau-Messung ausgegeben (UX-2 ±5 %%: %s)" % ("ja" if absf(abw) <= 5.0 else "nein"))

# ------------------------------------------------------------------ AT-09

## Ticks über die Szene (sim_schritt → nach_tick), 4× Tempo, simulierte Frames (ohne Wanduhr).
func _ticks(n: int) -> void:
	s.setze_tempo(4)
	var ziel: int = ps.ticks + n
	while ps.ticks < ziel:
		s.sim_acc = 0.0
		s.sim_schritt(minf(0.2, (ziel - ps.ticks) / 40.0 + 0.0001))
	s.setze_tempo(0)


func _at09() -> void:
	print("  -- AT-09 Kopfleiste")
	await _neue_szene()
	var e = ps.eco
	ui.kopf_neu()
	ok(ui.kopf != null and ui.kopf.mouse_filter == Control.MOUSE_FILTER_STOP and s.datum_label.get_parent() == ui.kopf_hb
		and (s.tempo_knoepfe[1] as Button).get_parent() == ui.kopf_hb, "Kopfleiste da; Datum und Tempo-Knöpfe der Szene stecken darin")
	ok(ui.hud_werte["kasse"] == e.cash_cent and ui.lbl_kasse.text == "Kasse ● 6.000 $", "Kasse %s = cash_cent" % ui.lbl_kasse.text)
	ok(ui.lbl_netto.text == "Netto — $/min" and ui.lbl_fix.text == "Fix 0 $/min" and ui.lbl_kredit.text == "Kredit —", "Start: Netto —, Fix 0 $/min, Kredit —")
	ok(ui.lbl_k.text == "k=%d" % ps.tempo_k and ui.hud_werte["k"] == ps.tempo_k, "k angezeigt: %s = proto_sim.tempo_k (A7)" % ui.lbl_k.text)
	# Spiel: 2 Linien, dann 4 Minuten
	ps.lizenz_kaufen("Gut Kuppenhof")
	ps.lizenz_kaufen("Erlenmühle")
	ui.linie_von_hier("Gut Kuppenhof")
	ui.ziel_waehlen("Erlenmühle")
	ui.anlegen()
	ui.ziel_waehlen("Erlenbach")
	ui.anlegen()
	ok(ps.fahrzeuge.size() == 2, "2 Linien über die UI")
	var a0: int = ps.konto.expenses_total
	_ticks(2400 - ps.ticks)
	var r_a: int = e.revenue_total
	var x_a: int = ps.konto.expenses_total
	var k_a: int = ps.kauf_total
	var c_a: int = e.cash_cent
	_ticks(600)
	ok(ps.ticks == 3000 and ps.sim.tick_count == 3000, "Tick 3.000 über sim_schritt erreicht")
	ui.kopf_neu()
	var ertrag: int = e.revenue_total - r_a
	var laufend: int = (ps.konto.expenses_total - x_a) - (ps.kauf_total - k_a)
	ok(ui.hud_werte["ertrag"] == ertrag and ui.hud_werte["netto"] == ertrag - laufend,
		"Netto Minute 5 = %s (Ertrag %s − Kosten %s) = Spielwert" % [ui.geld(ui.hud_werte["netto"]), ui.geld(ertrag), ui.geld(laufend)])
	ok(ui.hud_werte["netto"] == e.cash_cent - c_a, "Netto = Kassenänderung der Minute ohne Käufe (%d ¢)" % (e.cash_cent - c_a))
	var nt: String = ("+" if ui.hud_werte["netto"] > 0 else "") + ui.geld(ui.hud_werte["netto"])
	ok(ui.lbl_netto.text.contains(nt + "/min"), "Text %s" % ui.lbl_netto.text)
	var fix_soll := 0
	for f in ps.fahrzeuge:
		fix_soll += ps.fix_eff(f)
	ok(ui.hud_werte["fix"] == fix_soll and ui.lbl_fix.text == "Fix %s/min" % ui.geld(fix_soll), "%s = Σ fix_eff" % ui.lbl_fix.text)
	ok(ui.hud_werte["kasse"] == e.cash_cent and ui.lbl_kasse.text == "Kasse ● %s" % ui.geld(e.cash_cent), "%s = cash_cent" % ui.lbl_kasse.text)
	s._hud_text()
	ok(s.datum_label.text == ps.kalender.datum_text(ps.ticks) and ui.hud_werte["datum"] == s.datum_label.text, "Datum %s = Kalender (Tick %d)" % [s.datum_label.text, ps.ticks])
	# Kredit: vor Minute 12 abgelehnt mit Text, danach Chip
	var c0: int = e.cash_cent
	_druecke("kredit")
	ok(_letzte() == "Kredit gibt es ab Minute 12. Bis dahin: Einnahmen abwarten." and e.cash_cent == c0 and ps.credit.loan_cent == 0, "F4.1: %s" % _letzte())
	_ticks(7200 - ps.ticks)
	c0 = e.cash_cent
	_druecke("kredit")
	ui.kopf_neu()
	ok(ps.credit.loan_cent == 50000 and e.cash_cent - c0 == 50000 and ui.lbl_kredit.text == "Kredit 500 $ · Zins %s/min" % ui.geld(ps.credit.interest_per_period())
		and ui.hud_werte["kredit"] == 50000 and ui.hud_werte["zins"] == ps.credit.interest_per_period(), "Kredit-Chip: %s = credit" % ui.lbl_kredit.text)
	ok(_letzte() == "Kredit 500 $ aufgenommen. Zins 15 $/min, Rahmen noch 1.500 $.", "Toast: %s" % _letzte())
	for i in 3:
		_druecke("kredit")
	_druecke("kredit")
	ok(ps.credit.loan_cent == 200000 and _letzte() == "Kreditrahmen 2.000 $ ist voll. Tilge Schulden oder warte auf Einnahmen.", "F4.2: %s" % _letzte())
	var echt: int = e.cash_cent
	e.cash_cent = 100
	_druecke("tilgen")
	ok(_letzte() == "Zum Tilgen fehlen 499 $ in der Kasse. Warte auf Einnahmen." and ps.credit.loan_cent == 200000, "F4.3: %s" % _letzte())
	e.cash_cent = echt
	_druecke("tilgen")
	ok(ps.credit.loan_cent == 150000 and e.cash_cent == echt - 50000, "Tilgen 500 $")
	# Tempo
	s.setze_tempo(2)
	ui.kopf_neu()
	ok(ui.hud_werte["tempo"] == 2 and (s.tempo_knoepfe[2] as Button).button_pressed, "Tempo 2× markiert (= sim_tempo)")
	s.setze_tempo(0)
	var lang: Array = []
	for m in ui.meldungen_log:
		if String(m["text"]).length() > 90:
			lang.append(m["text"])
	ok(lang.is_empty(), "alle %d Meldungen ≤ 90 Zeichen %s" % [ui.meldungen_log.size(), str(lang)])


## Nur unter xvfb (1600 × 900, echtes Layout): Kopfleiste ohne Clipping mit Worst-Case-Werten, Screenshot.
func _at09_layout() -> void:
	print("  -- AT-09 Layout (xvfb)")
	await _neue_szene()
	var vp := root.get_visible_rect().size
	ok(vp.x >= 1599.0 and DisplayServer.get_name() != "headless", "Fenster %.0f × %.0f, Treiber %s (Layout nur unter xvfb gültig)" % [vp.x, vp.y, DisplayServer.get_name()])
	var e = ps.eco
	ps.lizenz_kaufen("Gut Kuppenhof")
	for i in 7201:
		ps.tick()
	ps.kredit_aufnehmen()
	ps.kredit_aufnehmen()
	ps.kredit_aufnehmen()
	ps.kredit_aufnehmen()
	ui.kopf_neu()
	e.cash_cent = -9999999                               # Worst Case Text: "-100.000 $"
	ui._schnapp = [{"tick": 0, "rev": 0, "ausg": 0, "kauf": 0}, {"tick": 600, "rev": 0, "ausg": 999999, "kauf": 0}]
	ui.kopf_neu()
	s._hud_text()
	for i in 3:
		await process_frame
	var r: Rect2 = ui.kopf.get_global_rect()
	var min_b: float = ui.kopf.get_combined_minimum_size().x
	var abgeschnitten: Array = []
	for c in ui.kopf_hb.get_children():
		if c is Control and (c as Control).visible:
			var cc := c as Control
			if cc.size.x + 0.5 < cc.get_combined_minimum_size().x or cc.get_global_rect().end.x > r.end.x + 0.5:
				abgeschnitten.append(cc.name)
	ok(r.position.x >= 0.0 and r.end.x <= vp.x + 0.5 and min_b <= vp.x - 16.0 and abgeschnitten.is_empty(),
		"Kopfleiste %.0f px breit (Mindestbreite %.0f px) in %.0f px, nichts abgeschnitten %s; Texte: %s | %s | %s | %s" % [r.size.x, min_b, vp.x, str(abgeschnitten),
		ui.lbl_kasse.text, ui.lbl_netto.text, ui.lbl_fix.text, ui.lbl_kredit.text])
	_klick("Gut Kuppenhof")
	ui.linie_von_hier("Gut Kuppenhof")
	e.cash_cent = 600000
	ui.ziel_waehlen("Erlenmühle")
	ui.kopf_neu()
	for i in 3:
		await process_frame
	var ueber: bool = ui.panel.get_global_rect().intersects(ui.kopf.get_global_rect()) or ui.vorschau_panel.get_global_rect().intersects(ui.panel.get_global_rect()) \
		or ui.modus_panel.get_global_rect().intersects(ui.vorschau_panel.get_global_rect()) or ui.modus_panel.get_global_rect().end.y > vp.y
	ok(not ueber and ui.panel.get_global_rect().end.y <= vp.y and ui.vorschau_panel.get_global_rect().position.y >= 0.0,
		"Panel, Vorschau, Modusleiste und Kopfleiste überlappen nicht, alles im Bild")
	var img := root.get_texture().get_image()
	var pfad := OS.get_environment("UI_WELT_SHOT")
	if pfad != "" and img != null:
		img.save_png(pfad)
		print("    SHOT ", pfad)

## Nur unter xvfb: Farm → Mühle → Dorf mit echter Maus (warp_mouse + push_input, je 2 Frames), Knöpfe an ihrer Bildschirmmitte.
func _echt(pos: Vector2) -> void:
	root.warp_mouse(pos)
	await process_frame                # X11 liefert die Warp-Bewegung verzögert; sonst kommt sie nach dem Drücken (= Ziehen)
	await process_frame
	for gedrueckt in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = gedrueckt
		ev.position = pos
		ev.global_position = pos
		root.push_input(ev)
		await process_frame
		await process_frame


func _echt_ort(nm: String) -> void:
	_blick(nm)
	await process_frame
	var p: Vector2 = ui.bildschirm_pos(nm)
	await _echt(p)


func _echt_knopf(id: String) -> bool:
	if not ui.knoepfe.has(id):
		print("    (Knopf fehlt: %s)" % id)
		return false
	await process_frame
	var b: Button = ui.knoepfe[id]
	await _echt(b.get_global_rect().get_center())
	return true


func _at08_maus() -> void:
	print("  -- AT-08 echte Maus (xvfb)")
	await _neue_szene()
	ui.klicks = 0
	var n0: int = ui.meldungen_log.size()
	await _echt_ort("Gut Kuppenhof")
	await _echt_knopf("lizenz_kaufen")
	await _echt_knopf("linie_von_hier")
	await _echt_ort("Erlenmühle")
	await _echt_knopf("anlegen")
	await _echt_knopf("modus_lizenz")
	await _echt_ort("Erlenbach")
	await _echt_knopf("anlegen")
	var texte: Array = ui.meldungen_log.slice(n0).map(func(m): return m["text"])
	ok(ps.fahrzeuge.size() == 2 and ui.klicks == 8 and ps.eco.licence_valid(ui.site_of("Erlenmühle")),
		"Echte Maus: Farm → Mühle → Dorf mit %d Klicks (2 davon Lizenz), %d Fuhrwerke; Meldungen %s" % [ui.klicks, ps.fahrzeuge.size(), str(texte)])

static func Economy_rdiv(z: int, n: int) -> int:
	return preload("res://economy.gd").rdiv(z, maxi(1, n))
