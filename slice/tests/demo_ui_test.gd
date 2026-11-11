extends SceneTree
## Demo-Sprint: UI-Test der Demo (ui_demo.gd + ui_welt.gd im Demo-Modus) und Screenshots der Schlüsselmomente (Gate G).
##   godot --headless --path slice -s res://tests/demo_ui_test.gd                      (nur Prüfungen)
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --path slice -s res://tests/demo_ui_test.gd -- --shots=<ordner>
## Spielt einen Durchlauf: Start, Firmensitz, Linie anlegen (ohne Fahrzeug) → im Depot kaufen → zuweisen, Vertrag, Skill, Straße,
## Gleis, Zug, Modellwechsel, HQ-Ausbau, Esc. Prüft: Anzeige = Spielwert, keine stumme Ablehnung, Fehlertexte, und (Teil 3, A1–A12)
## über den ECHTEN Maus-/Tastenweg (Ereignisse durch den Viewport): Kauf im Depot ohne Linie, Mehrfachauswahl mit Umschalt+Klick,
## Sammelzuweisung, Auswahlring sichtbar/weg, Banner in jedem Modus, Esc und Klick ins Leere, altes Muster nicht erreichbar.

const SZENE := "res://proto/prototyp_welt.tscn"
const FARM := "Gut Kuppenhof"
const MUEHLE := "Erlenmühle"
const DORF := "Erlenbach"
const FORST := "Forsthaus Rotwald"
const KOHLE := "Kohlegrube Schwarzgrund"
const HUETTE := "Rotachhütte"
const HQ := Vector2(1668, 688)

var n_ok := 0
var n_fail := 0
var s: Node
var ud
var uw
var ps
var shots := ""
var kann_bild := false


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shots="):
			shots = a.substr(8)
	kann_bild = shots != "" and DisplayServer.get_name() != "headless"
	if shots != "":
		DirAccess.make_dir_recursive_absolute(shots)
	s = (load(SZENE) as PackedScene).instantiate()
	s.set("demo", true)
	root.add_child(s)
	_run.call_deferred()


func pruef(ok: bool, text: String) -> void:
	if ok:
		n_ok += 1
	else:
		n_fail += 1
	print("  %s %s" % ["OK  " if ok else "FAIL", text])


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _ticks(bis: int) -> void:
	while ps.sim.tick_count < bis and not ps.konto.bankrupt:
		ps.tick()
		uw.nach_tick()


func _kamera(x: float, z: float, abstand: float, gier := 0.0) -> void:
	s.ziel = Vector3(x, s.hoehe_at(x, z), z)
	s.abstand = abstand
	s.gier = gier
	s._kamera_anwenden()


func _shot(name: String) -> void:
	ud.leiste_neu()
	uw.kopf_neu()
	uw.linien_neu()
	if s.fahrzeuge != null:
		s.fahrzeuge.frame(0.0, 0.0)
	await _frames(4)
	if not kann_bild:
		return
	await RenderingServer.frame_post_draw
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(shots.path_join(name + ".png"))
	print("    Bild %s.png" % name)


func _letzte() -> String:
	return String(uw.meldungen_log[-1]["text"]) if not uw.meldungen_log.is_empty() else ""


func _taste(k: int) -> bool:
	var ev := InputEventKey.new()
	ev.keycode = k
	ev.pressed = true
	return ud.eingabe(ev)


func _druecke(k: int) -> void:
	var ev := InputEventKey.new()
	ev.keycode = k
	ev.physical_keycode = k
	ev.pressed = true
	root.push_input(ev)
	var ev2 := InputEventKey.new()
	ev2.keycode = k
	ev2.pressed = false
	root.push_input(ev2)


## Bildpunkt (Canvas) → Fensterkoordinaten: headless ist das Fenster 64×64 und der Canvas gestreckt, im echten Fenster 1:1.
func _fenster(pos: Vector2) -> Vector2:
	return root.get_final_transform() * pos


func _klick(p_pos: Vector2) -> void:
	var pos := _fenster(p_pos)
	for druck in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = druck
		ev.position = pos
		ev.global_position = pos
		root.push_input(ev)



## Echter Mausklick auf ein Control (Mitte), optional mit Umschalt: Ereignisse laufen durch den Viewport wie beim Spieler.
func _klick_ctrl(c: Control, umschalt := false) -> bool:
	if c == null or not is_instance_valid(c) or not c.is_visible_in_tree():
		return false
	var pos := _fenster(c.get_global_rect().get_center())
	var mv := InputEventMouseMotion.new()
	mv.position = pos
	mv.global_position = pos
	root.push_input(mv)
	for druck in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = druck
		ev.position = pos
		ev.global_position = pos
		ev.shift_pressed = umschalt
		root.push_input(ev)
	await _frames(3)
	return true


func _kn(id: String) -> Button:
	var b = ud.knoepfe.get(id)
	if b != null and is_instance_valid(b) and (b as Button).is_visible_in_tree():
		return b
	b = uw.knoepfe.get(id)
	if b != null and is_instance_valid(b) and (b as Button).is_visible_in_tree():
		return b
	return null


## Knopf über den echten Mausweg drücken. Wartet, bis der Knopf nach einem Neuaufbau der Karte seinen Platz hat.
func _knopf_klick(id: String) -> bool:
	for i in 6:
		await _frames(2)
		var b := _kn(id)
		if b != null and b.get_global_rect().size.x > 4.0 and b.get_global_rect().position != Vector2.ZERO:
			return await _klick_ctrl(b)
	return false


func _zeile_klick(id: String, umschalt := false) -> bool:
	for i in 6:
		await _frames(2)
		var z := _zeile(id)
		if z != null and z.is_visible_in_tree() and z.get_global_rect().size.x > 4.0 and z.get_global_rect().position != Vector2.ZERO:
			return await _klick_ctrl(z, umschalt)
	return false


func _zeile(id: String) -> Control:
	var z = ud.vk.zeilen.get(id)
	return z if z != null and is_instance_valid(z) else null


## Bildschirmpunkt einer Station (Schildfuß, dorthin klickt der Spieler).
## Warten, bis die gezeichnete Kamera (Physik-Interpolation) am Ziel steht: erst dann stimmen Bildpunkte für Mausklicks.
func _ruhig() -> void:
	s.rig.reset_physics_interpolation()
	s.cam.reset_physics_interpolation()
	for i in 90:
		if s.cam.get_camera_transform().origin.distance_to(s.cam.global_position) < 0.05:
			break
		await physics_frame
	await process_frame


func _px(nm: String) -> Vector2:
	return uw.bildschirm_pos(nm)


## Echter Mausklick in die Welt auf eine Station.
func _klick_ort(nm: String) -> void:
	_klick(_px(nm))
	await _frames(3)


## Kamera so stellen, dass alle Stationen im freien Bildbereich liegen (nicht unter Leiste, Karten oder Listen).
func _sicht(namen: Array, abstand := 0.0, gier := 0.3) -> void:
	var m := Vector2.ZERO
	for nm in namen:
		m += Vector2(uw.orte_pos[nm].x, uw.orte_pos[nm].z)
	m /= float(namen.size())
	var weit := 0.0
	for nm in namen:
		weit = maxf(weit, m.distance_to(Vector2(uw.orte_pos[nm].x, uw.orte_pos[nm].z)))
	var ab := abstand if abstand > 0.0 else weit * 2.6 + 420.0
	var gr: Vector2 = root.get_viewport().get_visible_rect().size
	for versuch in 8:
		_kamera(m.x, m.y, ab, gier)
		await _ruhig()
		var passt := true
		for nm in namen:
			var px := _px(nm)
			if px.x < 470.0 or px.x > gr.x - 420.0 or px.y < 250.0 or px.y > gr.y - 330.0:
				passt = false
		if passt:
			break
		ab *= 1.25


func _text_in(n: Node, teil: String) -> bool:
	if n is Label and (n as Label).is_visible_in_tree() and String((n as Label).text).contains(teil):
		return true
	for c in n.get_children():
		if _text_in(c, teil):
			return true
	return false


func _dbg_unter(n: Node, pos: Vector2) -> void:
	if n is Control and (n as Control).is_visible_in_tree() and (n as Control).mouse_filter != Control.MOUSE_FILTER_IGNORE and (n as Control).get_global_rect().has_point(pos):
		print("      unter Maus: ", n.get_path(), " filter=", (n as Control).mouse_filter, " rect=", (n as Control).get_global_rect())
	for c in n.get_children():
		_dbg_unter(c, pos)


func _wpx(wp: Vector2) -> Vector2:
	return s.cam.unproject_position(Vector3(wp.x, s.hoehe_at(wp.x, wp.y), wp.y))


## Maus über einen Weltpunkt: Bewegungsereignis durch den Viewport; der Geländepunkt wird gesetzt wie in ui_demo._process
## (headless gibt es keinen Mauszeiger, den das Spiel abfragen könnte; echte Mausbewegung prüft demo_bau_befund unter xvfb).
func _maus_welt(wp: Vector2) -> void:
	var mv := InputEventMouseMotion.new()
	mv.position = _fenster(_wpx(wp))
	mv.global_position = mv.position
	root.push_input(mv)
	ud._maus_boden = ud.boden(_wpx(wp))
	ud.modus_neu()


## Echter Mausklick auf einen Weltpunkt.
func _klick_welt(wp: Vector2) -> void:
	_klick(_wpx(wp))
	await _frames(3)


func _klick_rechts(p_pos: Vector2) -> void:
	var pos := _fenster(p_pos)
	for druck in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_RIGHT
		ev.pressed = druck
		ev.position = pos
		ev.global_position = pos
		root.push_input(ev)


## Kamera so stellen, dass alle Weltpunkte im freien Bildbereich liegen (nicht unter Banner, Leiste, Karten).
func _sicht_punkte(punkte: Array, gier := 0.3) -> void:
	var m := Vector2.ZERO
	for p in punkte:
		m += p
	m /= float(punkte.size())
	var gr: Vector2 = root.get_viewport().get_visible_rect().size
	var ab := 380.0
	for versuch in 12:
		_kamera(m.x, m.y, ab, gier)
		await _ruhig()
		var passt := true
		for p in punkte:
			var px := _wpx(p)
			if px.x < 470.0 or px.x > gr.x - 420.0 or px.y < 270.0 or px.y > gr.y - 300.0:
				passt = false
		if passt:
			return
		ab *= 1.18


func _frei_px() -> Vector2:
	return Vector2(root.get_viewport().get_visible_rect().size.x * 0.5, root.get_viewport().get_visible_rect().size.y * 0.62)


func _run() -> void:
	print("demo_ui_test (Bilder: %s)" % (shots if kann_bild else "aus"))
	await _frames(3)
	ud = s.ui_demo
	uw = s.ui_welt
	ps = s.proto_sim
	if ud != null:
		ud.maus_aus = true
	pruef(ud != null and uw != null and ps != null and ps.get("demo") == true and uw.demo, "U1 Demo-Szene: DemoSim, ui_welt im Demo-Modus, ui_demo eingebaut")
	if ud == null:
		quit(1)
		return
	var vk = ud.vk
	pruef(ud.start_panel.visible and s.sim_tempo == 0 and ud.leiste_kn.size() == 7 and ud.leiste_kn.has("verkehr") and String(ud.lbl_moeglich.text).contains("Firmensitz platzieren"),
		"U2 Startbild sichtbar, Spiel pausiert, Werkzeugleiste mit 7 Knöpfen (ein Knopf „Verkehr“), Zeile: %s" % ud.lbl_moeglich.text)
	await _shot("01_startbild")
	# Vor dem Firmensitz: jede Aktion erklärt sich
	var n0: int = uw.meldungen_log.size()
	ud.bau_start("strasse")
	uw.lizenz_kaufen(FARM)
	pruef(uw.meldungen_log.size() == n0 + 2 and _letzte().contains("Firmensitz") and ud.bau_art == "", "U3 ohne Firmensitz: Bauen und Lizenz melden „%s“" % _letzte())
	_taste(KEY_SPACE)
	var banner := {}
	banner["hq"] = String(ud.werte.get("banner", ""))
	pruef(not ud.start_panel.visible and ud.hq_modus and s.sim_tempo == 1 and ud.modus_panel.visible and ud.banner.visible and banner["hq"].contains("Firmensitz platzieren"),
		"U4 Leertaste schließt das Startbild, Zeit läuft, Firmensitz-Modus ist an, Banner: „%s“" % banner["hq"])
	s.setze_tempo(0)
	_kamera(1640, 760, 620, 0.5)
	# Echter Eingabeweg: Geländepunkt unter der Maus, Taste und Mausklick durch den Viewport
	var abw := 0.0
	for wp in [Vector2(1668, 688), Vector2(1500, 900), Vector2(1900, 700)]:
		var sp: Vector2 = s.cam.unproject_position(Vector3(wp.x, s.hoehe_at(wp.x, wp.y), wp.y))
		var zur = ud.boden(sp)
		abw = maxf(abw, (zur as Vector2).distance_to(wp) if zur is Vector2 else 999.0)
	pruef(abw < 2.0, "U4b Geländepunkt unter der Maus: Bildpunkt → Welt weicht höchstens %.2f m ab" % abw)
	_druecke(KEY_ESCAPE)
	var esc_hq: bool = not ud.hq_modus and not ud.banner.visible and not ud.menue_panel.visible
	_druecke(KEY_H)
	var per_taste: bool = ud.hq_modus and ud.banner.visible
	_klick(s.cam.unproject_position(Vector3(1000, s.hoehe_at(1000, 500), 500)))
	await _frames(2)
	pruef(esc_hq and per_taste and not ps.hq_platziert and _letzte().contains("Ort"), "U4c Esc beendet den Modus (Banner weg, kein Menü), Taste H startet ihn wieder; Klick außerhalb meldet „%s“" % _letzte())
	ud.hq_zeigen(Vector2(1000, 500))
	var t_fehl: String = ""
	for c in ud.modus_vb.get_children():
		if c is Label and String(c.text).begins_with("■"):
			t_fehl = c.text
	pruef(t_fehl.contains("Ort") and not ud.hq_ring.visible, "U5 Vorschau außerhalb eines Orts: „%s“" % t_fehl)
	ud.hq_zeigen(HQ)
	var v: Dictionary = ps.hq_vorschau(HQ)
	pruef(ud.werte["hq_vorschau"]["im_radius_n"] == v["im_radius_n"] and ud.werte["hq_vorschau"]["lizenz_summe_cent"] == v["lizenz_summe_cent"] and ud.hq_ring.visible and ud.hq_geist.visible,
		"U6 Standortvorschau = Spielwert: %d Betriebe im Radius, Lizenzen %d $, Ring und Geisterhaus sichtbar" % [int(v["im_radius_n"]), int(v["lizenz_summe_cent"]) / 100])
	await _shot("02_firmensitz_vorschau")
	n0 = uw.meldungen_log.size()
	ud.hq_setzen(Vector2(1625, 730))
	pruef(not ps.hq_platziert and uw.meldungen_log.size() == n0 + 1 and _letzte().contains("Straße"), "U7 Platz auf der Straße abgelehnt: „%s“" % _letzte())
	var r: Dictionary = ud.hq_setzen(HQ)
	pruef(r.get("ok", false) and ps.hq_platziert and ud.hq_haus.get_child_count() >= 3 and not ud.hq_modus and _letzte().contains("gegründet") and not ud.banner.visible
		and ps.depots.size() == 1 and ps.depots[0].get("fuhrhof", false) and ud.raum.has_node("Depot_1"),
		"U8 Firmensitz gesetzt: Haus, Fahne, Schild und der Fuhrhof (erstes Depot) in der Welt; Banner weg; „%s“" % _letzte())
	await _shot("03_firmensitz_gesetzt")

	# ------------------------------------------------------------ Teil 3: Auswahl, Modus, Linie → Depot → Zuweisen (echter Maus-/Tastenweg)
	await _sicht([FARM, MUEHLE], 0.0, 0.3)
	await _klick_ort(FARM)
	ud._process(0.2)
	var ring_an: bool = uw.auswahl == FARM and ud.sel_ring.visible and ud.sel_pfeil.visible and ud.werte["auswahl"]["art"] == "ort"
	pruef(ring_an and _kn("linie_hier_beginnen") != null and _kn("linie_von_hier") == null and int(ud.werte.get("linien_hier", -1)) == 0 and _text_in(uw.panel_vb, "Hier hält noch keine Linie"),
		"A1 Klick auf Gut Kuppenhof: Panel offen, pulsierender Ring + Pfeil am Betrieb; Panel zeigt „Linie hier beginnen“ und „Hier hält noch keine Linie“, kein „Linie von hier“")
	await _shot("20_auswahl_ring")
	_klick(_frei_px())
	await _frames(3)
	ud._process(0.2)
	var leer_weg: bool = uw.auswahl == "" and not ud.sel_ring.visible and not uw.panel.visible
	await _klick_ort(MUEHLE)
	var sel2: bool = uw.auswahl == MUEHLE and ud.sel_ring.visible
	_druecke(KEY_ESCAPE)
	await _frames(2)
	pruef(leer_weg and sel2 and uw.auswahl == "" and not ud.sel_ring.visible and not ud.menue_panel.visible,
		"A2 Klick ins Leere hebt die Auswahl auf (Ring weg, Panel zu); Esc ebenso, ohne dass das Menü aufgeht")
	ud.hover_setzen(_px(MUEHLE))
	var h1: bool = ud.werte["hover"] == MUEHLE and ud.hover_ring.visible and int(ud.werte["cursor"]) == Input.CURSOR_POINTING_HAND
	ud.hover_setzen(_frei_px())
	pruef(h1 and ud.werte["hover"] == "" and not ud.hover_ring.visible and int(ud.werte["cursor"]) == Input.CURSOR_ARROW,
		"A3 Hover: Ring und Zeigehand über der Erlenmühle, Pfeil und kein Ring über freiem Gelände")
	# Altes Muster ist im Demo-Modus nicht erreichbar
	uw.lizenz_kaufen(FARM)
	var kasse: int = ps.eco.cash_cent
	uw.linie_von_hier(FARM)
	var alt1: bool = uw.modus_von == "" and not uw.modus_panel.visible and ud.modus() == "halte" and vk.halte_liste == [FARM]
	uw.ziel_waehlen(MUEHLE)
	var ra: Dictionary = uw.anlegen()
	var rk: Dictionary = uw.fuhrwerk_kaufen(FARM, MUEHLE)
	pruef(alt1 and uw.vorschau_ziel == "" and not uw.vorschau_panel.visible and not ra.get("ok", true) and not rk.get("ok", true) and ps.alle_fahrzeuge().is_empty() and ps.eco.cash_cent == kasse,
		"A4 altes Muster nicht erreichbar: „Linie von hier“ öffnet den Linien-Editor (Halt 1 gesetzt), Ziel wählen/Anlegen/+Fuhrwerk kaufen nichts (Kasse unverändert)")
	_druecke(KEY_ESCAPE)
	# Linie anlegen: L → Neue Linie → Art → Halte in der Welt anklicken → Enter
	_druecke(KEY_L)
	await _frames(3)
	var per_l: bool = vk.panel.visible and vk.tab == "linien"
	await _knopf_klick("vk_neue_linie")
	var art_offen: bool = vk.art_wahl and _kn("vk_art_strasse_gueter") != null and _kn("vk_art_gleis_gueter") != null
	await _knopf_klick("vk_art_gleis_gueter")
	var gleis_zu: bool = ud.modus() == "" and _letzte().contains("1824")
	await _knopf_klick("vk_art_strasse_gueter")
	ud._process(0.2)
	banner["halte"] = String(ud.werte.get("banner", ""))
	var g_n := int(ud.werte.get("marker_gueltig", 0))
	var u_n := int(ud.werte.get("marker_ungueltig", 0))
	pruef(per_l and art_offen and gleis_zu and ud.modus() == "halte" and not vk.panel.visible and vk.editor_panel.visible and ud.banner.visible
		and banner["halte"].contains("Halte für Linie 1 anklicken") and banner["halte"].contains("0 gewählt") and g_n >= 3 and u_n >= 4 and g_n + u_n == ps.stationen.size(),
		"A5 Taste L → Neue Linie → Straße · Güter (Gleis vor 1824 erklärt sich): Banner „%s“, %d Halte mit Ring, %d abgedunkelt" % [banner["halte"], g_n, u_n])
	await _klick_ort(FARM)
	await _shot("21_modus_banner_halte")
	n0 = uw.meldungen_log.size()
	_klick(_frei_px())
	await _frames(2)
	var leer_text := _letzte()
	await _sicht([FARM, MUEHLE, FORST], 0.0, 0.3)
	ud.hover_setzen(_px(FORST))
	var verboten: bool = int(ud.werte["cursor"]) == Input.CURSOR_FORBIDDEN and not ud.werte["hover_gueltig"]
	await _klick_ort(FORST)
	var ung_text := _letzte()
	await _klick_ort(MUEHLE)
	ud._process(0.2)
	pruef(vk.halte_liste == [FARM, MUEHLE] and leer_text.contains("markierten Halt") and verboten and ung_text.contains("Straßenanschluss") and String(ud.werte["banner"]).contains("2 gewählt")
		and ud.werte["plan_pruefung"].get("ok", false) and _kn("halt_0_0_auftrag") != null,
		"A6 Halte per Weltklick: Farm, Mühle (Banner „2 gewählt“); Klick ins Leere sagt „%s“; Forsthaus ohne Straße: Verbotszeiger und „%s“" % [leer_text, ung_text])
	kasse = ps.eco.cash_cent
	_druecke(KEY_ENTER)
	await _frames(3)
	ud._process(0.2)
	var l1: Dictionary = ps.linie_plan(1)
	pruef(ps.linien.size() == 1 and l1["halte"] == [FARM, MUEHLE] and ps.alle_fahrzeuge().is_empty() and ps.eco.cash_cent == kasse and ud.modus() == "" and not ud.banner.visible
		and vk.panel.visible and vk.linie_sel == 1 and _text_in(vk.vb, "Noch kein Fahrzeug: im Depot kaufen und zuweisen") and _kn("vk_zum_depot") != null
		and int(ud.werte.get("route_linie", 0)) == 1 and vk.linie_mi.visible,
		"A7 Enter legt Linie 1 OHNE Fahrzeug an (Kasse unverändert): Fenster zeigt „Noch kein Fahrzeug: im Depot kaufen und zuweisen“ mit Sprung zum Depot, Route leuchtet in der Welt")
	await _shot("22_verkehr_linie_ohne_fahrzeug")
	# Depot: Kauf ohne Linie, Mehrfachauswahl, Sammelzuweisung
	await _knopf_klick("vk_zum_depot")
	ud._process(0.2)
	var kat: Array = ud.werte.get("depot_katalog", [])
	var depot_auf: bool = vk.depot_offen == 0 and vk.depot_panel.visible and not vk.panel.visible and ud.werte["auswahl"]["art"] == "depot" and ud.sel_ring.visible and kat.has("fuhrwerk_d") and kat.has("kutsche_d")
	await _knopf_klick("kat_plus_fuhrwerk_d")
	await _knopf_klick("kat_plus_fuhrwerk_d")
	kasse = ps.eco.cash_cent
	await _knopf_klick("kat_kaufen_fuhrwerk_d")
	var stueck: int = ps._preis(ps.vdef("fuhrwerk_d"))
	pruef(depot_auf and ps.abgestellt.size() == 3 and kasse - ps.eco.cash_cent == 3 * stueck and stueck == int(ps.vdef("fuhrwerk_d")["kauf_cent"]) and ps.linie_fahrzeuge(1).is_empty()
		and int(ud.werte["depot_bestand"]) == 3 and int(ud.werte["auswahl_depot"]) == 3 and _letzte().contains("3 × Fuhrwerk"),
		"A8 Kauf im Depot ohne Linie: Menge 3 per [+], −%d $ (Listenpreis, kein Depotrabatt), 3 Fuhrwerke stehen im Depot, keins fährt; „%s“" % [3 * stueck / 100, _letzte()])
	var keys: Array = vk.fz_sicht["depot"].duplicate()
	await _knopf_klick("depot_keine")
	var keine: bool = int(ud.werte["auswahl_depot"]) == 0 and _kn("depot_zu_1") == null
	await _zeile_klick("depot:" + String(keys[0]))
	var eins: bool = int(ud.werte["auswahl_depot"]) == 1 and vk.fz_auswahl.has(keys[0])
	await _zeile_klick("depot:" + String(keys[2]), true)
	var bereich: bool = int(ud.werte["auswahl_depot"]) == 3
	await _zeile_klick("depot:" + String(keys[1]))
	var zwei: bool = int(ud.werte["auswahl_depot"]) == 2 and not vk.fz_auswahl.has(keys[1])
	var zaehler_text := ""
	for c in vk.depot_vb.find_children("Zaehler", "Label", true, false):
		zaehler_text = (c as Label).text
	pruef(keine and eins and bereich and zwei and zaehler_text == "2 ausgewählt" and _kn("depot_zu_1") != null,
		"A9 Mehrfachauswahl per Maus: Keine → Klick (1) → Umschalt+Klick wählt den Bereich (3) → Klick entwählt (2); Zähler „%s“, Linie 1 als Ziel angeboten" % zaehler_text)
	await _shot("23_depot_mehrfachauswahl")
	await _knopf_klick("depot_zu_1")
	var fz1: Array = ps.linie_fahrzeuge(1)
	pruef(fz1.size() == 2 and ps.abgestellt.size() == 1 and fz1[0].get("ausfahrt", false) and _letzte().contains("2 Fahrzeuge fahren jetzt auf Linie 1") and int(ud.werte["depot_bestand"]) == 1
		and s.fahrzeuge.mmis.has("fuhrwerk"),
		"A10 Sammelzuweisung per Klick auf die Linie: 2 Fuhrwerke rücken aus, 1 bleibt im Depot; „%s“" % _letzte())
	# Fenster Verkehr, Reiter Fahrzeuge: Filter, Alle, Ins Depot, wieder zuweisen
	_druecke(KEY_U)
	await _frames(3)
	var u_ok: bool = vk.panel.visible and vk.tab == "fahrzeuge" and vk.depot_offen < 0 and vk.fz_sicht["fz"].size() == 3
	await _knopf_klick("fz_f_depot")
	var f_depot: bool = vk.fz_sicht["fz"].size() == 1
	await _knopf_klick("fz_f_alle")
	await _knopf_klick("fz_alle")
	var alle3: bool = int(ud.werte["auswahl_fz"]) == 3
	await _shot("24_verkehr_fahrzeuge")
	await _knopf_klick("fz_ins_depot")
	var im_depot: bool = ps.abgestellt.size() == 3 and ps.linie_fahrzeuge(1).is_empty() and int(ud.werte["auswahl_fz"]) == 3
	await _knopf_klick("fz_zu_1")
	pruef(u_ok and f_depot and alle3 and im_depot and ps.linie_fahrzeuge(1).size() == 3 and ps.abgestellt.is_empty(),
		"A11 Taste U (Reiter Fahrzeuge): Filter „im Depot“ zeigt 1, „Alle wählen“ 3 ausgewählt, „Ins Depot“ holt alle zurück, Klick auf Linie 1 weist alle 3 wieder zu")
	# gemischte Auswahl, Verkauf mit Rückfrage
	ps.depot_kaufen(0, "kutsche_d", 1)
	vk.neu()
	await _frames(2)
	await _knopf_klick("fz_alle")
	var gemischt: bool = _text_in(vk.vb, "mischt Fahrzeugarten") and _kn("fz_zu_1") == null
	await _knopf_klick("fz_keine")
	await _zeile_klick("fz:" + String(ps.abgestellt[0]["key"]))
	kasse = ps.eco.cash_cent
	var rw: int = ps.restwert(ps.abgestellt[0])
	await _knopf_klick("fz_verkaufen")
	var frage: bool = _kn("fz_verkaufen_ja") != null and ps.abgestellt.size() == 1
	await _knopf_klick("fz_verkaufen_ja")
	pruef(gemischt and frage and ps.abgestellt.is_empty() and ps.eco.cash_cent - kasse == rw and rw > 0 and _letzte().contains("Restwert"),
		"A12 gemischte Auswahl (Fuhrwerke + Kutsche) erklärt sich und bietet keine Linie an; Verkauf fragt nach, dann +%d $ Restwert" % (rw / 100))
	_druecke(KEY_ESCAPE)
	await _frames(2)
	var zu: bool = not vk.panel.visible
	# zweite Linie Mühle → Erlenbach (Sim-API), damit Mehl fließt
	var l2: Dictionary = ps.linie_neu("strasse_gueter", [MUEHLE, DORF])
	var k2: Dictionary = ps.depot_kaufen(0, "fuhrwerk_d", 1)
	ps.zuweisen(k2["keys"], int(l2["linie"]))
	uw._fahrzeuge_neu()
	vk.linie_zeigen(2)
	await _frames(3)
	var liz_site: int = uw.site_of(MUEHLE)
	var liz_warn: bool = vk.lizenz_fehlt(ps.linie_plan(2)) == [MUEHLE] and _text_in(vk.vb, "Lizenz fehlt") and _kn("vk_lizenz_%d" % liz_site) != null
	await _knopf_klick("vk_lizenz_%d" % liz_site)
	pruef(zu and ps.linien.size() == 2 and ps.alle_fahrzeuge().size() == 4 and ps.fehler.is_empty() and liz_warn and uw.lizenz_ok(liz_site) and not _text_in(vk.vb, "Lizenz fehlt"),
		"U10 Esc schließt das Fenster; Linie 2 (Mühle → Erlenbach) warnt „Lizenz fehlt“ und kauft sie per Klick; 4 Fuhrwerke laufen")
	vk.schliessen()
	_ticks(900)
	await _frames(2)
	ud.vertraege_umschalten()
	ud.leiste_neu()
	pruef(ud.vertrag_panel.visible and ud.knoepfe.has("vertrag_an_1") and String(ud.leiste_kn["vertrag"].text).contains("1 neu"), "U11 Vertragsangebot in Leiste und Panel (%s)" % ud.leiste_kn["vertrag"].text)
	_kamera(1640, 800, 900, 0.3)
	await _shot("04_vertragsangebot")
	ud.vertrag_annehmen(1)
	pruef(ps.vertraege_aktiv.size() == 1 and _letzte().contains("Vertrag angenommen"), "U12 annehmen: „%s“" % _letzte())
	n0 = uw.meldungen_log.size()
	ud.vertrag_annehmen(1)
	pruef(uw.meldungen_log.size() == n0 + 1 and _letzte().contains("gibt es nicht mehr"), "U13 zweites Annehmen erklärt sich: „%s“" % _letzte())
	_ticks(1700)
	ud.vertraege_neu()
	await _shot("05_vertrag_laeuft")
	ud.vertrag_panel.visible = false
	# Linienfenster mit laufender Linie: Kennzahlen = Spielwert
	vk.linie_zeigen(1)
	await _frames(3)
	var kz: Dictionary = ps.linie_kennzahlen(1)
	var ld: Dictionary = ud.werte.get("linie_detail", {})
	pruef(int(ld.get("ertrag_cent", -1)) == int(kz["ertrag_cent"]) and int(ld.get("fahrzeuge", 0)) == 3 and int(kz["ertrag_cent"]) > 0 and _kn("vk_fz_" + ps.fz_key(ps.linie_fahrzeuge(1)[0])) != null
		and int(ud.werte["route_punkte"]) >= 2,
		"A13 Linie 1 im Fenster: Ertrag letzte Minute %d $ = Spielwert, Auslastung %d %%, 3 Fahrzeuge, Halte mit Ladeauftrag" % [int(kz["ertrag_cent"]) / 100, int(ld.get("auslastung_pct", 0))])
	await _shot("25_verkehr_linien")
	await _knopf_klick("vk_linie_welt")
	ud._process(0.2)
	var welt_linie: bool = not vk.panel.visible and ud.werte["auswahl"]["art"] == "linie" and vk.linie_mi.visible
	await _shot("26_linie_in_der_welt")
	_klick(_frei_px())
	await _frames(3)
	vk._route_neu()
	pruef(welt_linie and vk.linie_sel == 0 and not vk.linie_mi.visible, "A14 „In der Welt zeigen“: Fenster zu, Route in Linienfarbe; Klick ins Leere hebt die Linienauswahl auf (Route weg)")
	# Skilltree
	_ticks(2400)
	ud.skills_umschalten()
	pruef(ud.skill_panel.visible and int(ud.werte["skillpunkte_frei"]) == ps.skillpunkte_frei() and ps.skillpunkte_frei() >= 2 and ud.knoepfe.has("skill_marktstand"),
		"U14 Skillbaum offen: %d Punkte frei = Spielwert" % ps.skillpunkte_frei())
	n0 = uw.meldungen_log.size()
	ud.skill_klick("futtermeister")
	var t_sperre := _letzte()
	ud.skill_klick("marktstand")
	pruef(uw.meldungen_log.size() == n0 + 2 and t_sperre.contains("Stellmacher") and ps.skills == ["marktstand"], "U15 gesperrter Knoten: „%s“; freier Knoten gesetzt" % t_sperre)
	await _shot("06_skilltree")
	ud.skill_panel.visible = false
	# Ein Modus beendet den anderen sichtbar; Auswahl hängt nicht
	uw.oeffnen(FARM)
	vk.halte_start("strasse_gueter")
	var m1: bool = ud.modus() == "halte" and uw.auswahl == ""
	_druecke(KEY_B)
	await _frames(2)
	ud._process(0.2)
	banner["bau_strasse"] = String(ud.werte.get("banner", ""))
	pruef(m1 and ud.modus() == "bau" and not vk.halte_an and not vk.editor_panel.visible and banner["bau_strasse"].contains("Straße bauen") and banner["bau_strasse"].contains("Startpunkt"),
		"A15 ein Modus beendet den anderen: Linien-Editor startet (Auswahl weg), Taste B wechselt in den Straßenbau, Editor zu, Banner „%s“" % banner["bau_strasse"])
	# ------------------------------------------------------------ Teil 4: Bauwerkzeug (Marke, Vorschau, eine Klickregel, Kurve, Plan)
	var start_k := Vector2(1284, 936)
	var forst_p: Vector2 = ps.halt_pos(FORST)
	pruef(ud.bau_art == "strasse" and ud.marker_root.get_child_count() == 4 and ud.modus_panel.visible and int(ud.werte["bau_see_ringe"]) == ps.see_kreise.size()
		and _kn("banner_kurve") != null and _kn("banner_planen") != null,
		"U16 Baumodus Straße: %d Ringe an Betrieben ohne Anschluss, Seesperre sichtbar (%d Ringe), Banner mit Umschaltern Kurve und Planen" % [ud.marker_root.get_child_count(), int(ud.werte["bau_see_ringe"])])
	await _sicht_punkte([start_k, Vector2(1330, 1100), forst_p, Vector2(900, 1300)], -0.4)
	# B1 Marke und Schild unter der Maus VOR dem ersten Klick
	_maus_welt(Vector2(900, 1300))
	var m_frei: bool = ud.werte["bau_fang"] == "frei" and ud.bau.marke.visible and String(ud.werte["bau_schild"]).contains("Hier kein Anschluss")
	_maus_welt(start_k)
	var m_knoten: bool = ud.werte["bau_fang"] == "knoten" and String(ud.werte["bau_schild"]).contains("Start: an der Straße")
	_maus_welt(forst_p + Vector2(20, -10))
	var m_betrieb: bool = ud.werte["bau_fang"] == "betrieb" and String(ud.werte["bau_schild"]).contains("Start: Forsthaus Rotwald")
	pruef(m_frei and m_knoten and m_betrieb and ud.bau_punkte.is_empty(), "B1 vor dem ersten Klick: Marke unter der Maus, Schild „Hier kein Anschluss“ / „Start: an der Straße“ / „Start: Forsthaus Rotwald“")
	n0 = uw.meldungen_log.size()
	await _klick_welt(Vector2(900, 1300))
	pruef(ud.bau_punkte.is_empty() and uw.meldungen_log.size() == n0 + 1 and _letzte().contains("hängt in der Luft"), "U17 Mausklick im Nichts: kein Punkt, „%s“" % _letzte())
	# B2 erster Klick → sofort Vorschau in Straßenbreite, Länge und Preis an der Maus
	_druecke(KEY_C)
	var gerade_an: bool = not ud.bau.kurve and String(ud.werte["banner"]).contains("gerade")
	await _klick_welt(start_k)
	_maus_welt(Vector2(1330, 1100))
	var q_t4: Dictionary = ps.trasse_angebot("strasse", PackedVector2Array([start_k, Vector2(1330, 1100)]), {"kurve": false})
	pruef(gerade_an and ud.bau_punkte.size() == 1 and ud.werte["bau_vorschau"] and ud.bau.vorschau.has_node("Gut") and int(ud.werte["bau_kosten"]) == int(q_t4["kosten_cent"])
		and String(ud.werte["bau_schild"]).contains("%s m" % uw._tsd(int(q_t4["laenge_m"]))) and String(ud.werte["bau_schild"]).contains(uw.geld(int(q_t4["kosten_cent"]))) and String(ud.werte["bau_schild"]).contains("Endet frei"),
		"B2 Taste C schaltet auf gerade; nach dem ersten Klick liegt die Vorschau bis zur Maus da, Schild an der Maus „%s“ = Spielwert" % ud.werte["bau_schild"])
	# B3 eine Klickregel: auch der Klick auf ein einrastendes Ziel setzt nur einen Punkt
	kasse = ps.eco.cash_cent
	var wege0_t4: int = ps.bauwerke.size()
	await _klick_welt(Vector2(1330, 1100))
	_maus_welt(forst_p)
	var ziel_schild: String = ud.werte["bau_schild"]
	await _klick_welt(forst_p)
	var drei_b: bool = ud.bau_punkte.size() == 3 and ps.bauwerke.size() == wege0_t4 and ps.eco.cash_cent == kasse
	# B4 Rechtsklick nimmt den letzten Punkt zurück
	_klick_rechts(_wpx(Vector2(1200, 1150)))
	await _frames(3)
	var zwei_b: bool = ud.bau_punkte.size() == 2 and ud.bau_art == "strasse"
	await _klick_welt(forst_p)
	_maus_welt(forst_p)
	q_t4 = ps.trasse_angebot("strasse", ud.bau_punkte, {"kurve": false})
	pruef(drei_b and zwei_b and ud.bau_punkte.size() == 3 and ziel_schild.contains("Ende: Forsthaus Rotwald") and String(ud.werte["banner"]).contains("3 Punkte") and q_t4["ok"],
		"B3 eine Klickregel: Klick auf das einrastende Ziel setzt nur den Punkt (nichts gebaut, Kasse gleich), Schild „%s“; Rechtsklick nimmt ihn zurück" % ziel_schild)
	_kamera(1180, 1100, 760, -0.4)
	await _shot("07_strassenbau")
	kasse = ps.eco.cash_cent
	_druecke(KEY_ENTER)
	await _frames(3)
	var abw_bau := 99.0
	if ps.bauwerke.size() == wege0_t4 + 1:
		abw_bau = 0.0
		var fl_t4 = ps.strassen.fahrlinien[int(ps.bauwerke[-1]["weg"])]
		for gp2 in q_t4["punkte"]:
			var best_t4 := INF
			for k2_t4 in range(0, fl_t4.punkte.size(), 2):
				best_t4 = minf(best_t4, Vector2(fl_t4.punkte[k2_t4].x, fl_t4.punkte[k2_t4].z).distance_to(gp2))
			abw_bau = maxf(abw_bau, best_t4)
	pruef(ps.angeschlossen(FORST) and kasse - ps.eco.cash_cent == int(q_t4["kosten_cent"]) and abw_bau < 1.2 and ud.bau_art == "strasse" and ud.bau_punkte.size() == 1 and ud.banner.visible
		and _letzte().contains("Forsthaus Rotwald ist angeschlossen"),
		"U19 Enter baut genau die Vorschau (Abweichung %.2f m), das Werkzeug bleibt an (1 Punkt am Ende, Banner da): „%s“" % [abw_bau, _letzte()])
	# B5 Kurve: tangentialer Bogen; B6 Fehler nur an der Stelle
	_klick_rechts(_wpx(Vector2(1200, 1150)))
	await _frames(2)
	_druecke(KEY_C)
	var s2_t4: Vector2 = ps.fang("strasse", Vector2(1330, 1100))["pos"]
	var frei_p := Vector2.ZERO
	var frei_p2 := Vector2.ZERO
	for wi2 in 16:
		var d2_t4 := Vector2(cos(TAU * wi2 / 16.0), sin(TAU * wi2 / 16.0))
		var c1_t4 := s2_t4 + d2_t4 * 120.0
		var c2_t4 := c1_t4 + d2_t4.rotated(deg_to_rad(50.0)) * 110.0
		var qa_t4: Dictionary = ps.trasse_angebot("strasse", PackedVector2Array([s2_t4, c1_t4, c2_t4]), {"kurve": true})
		if qa_t4["ok"] and int(qa_t4["bruecke_m"]) == 0 and qa_t4["ende"]["typ"] == "frei" and qa_t4["kreuzungen"].is_empty():
			frei_p = c1_t4
			frei_p2 = c2_t4
			break
	await _sicht_punkte([s2_t4, frei_p, frei_p2], -0.4)
	await _klick_welt(s2_t4)
	await _klick_welt(frei_p)
	_maus_welt(frei_p2)
	var qk_t4: Dictionary = ud.bau_angebot
	var knick_b := 0.0
	var gk_t4: PackedVector2Array = qk_t4.get("punkte", PackedVector2Array())
	for i2_t4 in range(2, gk_t4.size()):
		knick_b = maxf(knick_b, absf(rad_to_deg((gk_t4[i2_t4 - 1] - gk_t4[i2_t4 - 2]).angle_to(gk_t4[i2_t4] - gk_t4[i2_t4 - 1]))))
	pruef(ud.bau.kurve and frei_p != Vector2.ZERO and qk_t4.get("ok", false) and float(qk_t4["r_min"]) < 1000.0 and float(qk_t4["r_min"]) >= ps.bau_radius("strasse") and knick_b < 8.0
		and String(ud.werte["banner"]).contains("Kurve"),
		"B5 Kurve (Taste C): zweites Stück als Kreisbogen mit Radius %.0f m, tangential (größter Knick zwischen Punkten %.1f°)" % [float(qk_t4.get("r_min", 0.0)), knick_b])
	await _shot("29_bau_kurve")
	var sk_b: Array = ps.see_kreise[0]
	for k3_t4 in ps.see_kreise:
		if Vector2(k3_t4[0], k3_t4[1]).distance_to(s2_t4) < Vector2(sk_b[0], sk_b[1]).distance_to(s2_t4):
			sk_b = k3_t4
	var sm_b := Vector2(sk_b[0], sk_b[1])
	_klick_rechts(_wpx(frei_p))
	await _frames(2)
	_druecke(KEY_C)
	_maus_welt(sm_b + (sm_b - s2_t4).normalized() * (float(sk_b[2]) + 90.0))
	var rot_b: int = int(ud.werte["bau_rot_punkte"])
	var see_text := false
	for c_t4 in ud.bau.marken.get_children():
		if c_t4 is Label3D and String((c_t4 as Label3D).text).contains("See"):
			see_text = true
	wege0_t4 = ps.bauwerke.size()
	n0 = uw.meldungen_log.size()
	await _shot("30_bau_fehler_lokal")
	_druecke(KEY_ENTER)
	await _frames(2)
	pruef(not ud.bau_angebot.get("ok", true) and rot_b > 0 and rot_b < int(ud.werte["bau_punkte_gesamt"]) and int(ud.werte["bau_fehlerstellen"]) >= 1 and see_text and ud.bau.vorschau.has_node("Fehler")
		and ud.bau.vorschau.has_node("Gut") and String(ud.werte["bau_schild"]).begins_with("✕ See") and ps.bauwerke.size() == wege0_t4,
		"B6 Trasse durch den See: nur %d von %d Punkten rot, Marke „See“ an der Stelle, Schild „%s“; Enter baut nichts" % [rot_b, int(ud.werte["bau_punkte_gesamt"]), ud.werte["bau_schild"]])
	# B7 Doppelklick baut; freies Ende wird angesagt
	_druecke(KEY_C)
	_maus_welt(frei_p)
	var frei_schild: String = ud.werte["bau_schild"]
	kasse = ps.eco.cash_cent
	await _klick_welt(frei_p)
	var vor_doppel: int = ps.bauwerke.size()
	await _klick_welt(frei_p)
	pruef(ud.bau.kurve and frei_schild.contains("Endet frei: verbindet noch nichts") and vor_doppel == wege0_t4 and ps.bauwerke.size() == wege0_t4 + 1 and ps.eco.cash_cent < kasse and ud.bau_punkte.size() == 1,
		"B7 freies Ende: Schild „%s“; erster Klick setzt den Punkt, der zweite Klick auf denselben Punkt (Doppelklick) baut" % frei_schild)
	# B8 Planen: Abschnitte ablegen ohne Geld, Summe, verwerfen, Plan bauen nur wenn bezahlbar
	_druecke(KEY_P)
	kasse = ps.eco.cash_cent
	_maus_welt(frei_p2)
	await _klick_welt(frei_p2)
	_druecke(KEY_ENTER)
	await _frames(2)
	var plan1: bool = ud.bau.planen and ud.bau.plan.size() == 1 and ps.eco.cash_cent == kasse and ps.bauwerke.size() == wege0_t4 + 1 and ud.bau.plan_wurzel.get_child_count() == 1
	var p3_t4 := frei_p2 + (frei_p2 - frei_p).normalized().rotated(deg_to_rad(20.0)) * 100.0
	_maus_welt(frei_p2)
	var am_plan: bool = ud.werte["bau_fang"] == "plan"
	_maus_welt(p3_t4)
	await _klick_welt(p3_t4)
	_druecke(KEY_ENTER)
	await _frames(3)
	var summe_b: int = ud.bau.plan_kosten()
	var plan2: bool = ud.bau.plan.size() == 2 and int(ud.werte["bau_plan_kosten"]) == summe_b and summe_b == int(ud.bau.plan[0]["q"]["kosten_cent"]) + int(ud.bau.plan[1]["q"]["kosten_cent"])
	await _shot("28_bau_plan")
	var geld_alt: int = ps.eco.cash_cent
	ps.eco.cash_cent = summe_b - 100                              # Testwerkzeug: zu wenig Geld für den ganzen Plan
	ud.bau.neu()
	n0 = uw.meldungen_log.size()
	ud.bau.plan_bauen(false)
	var zu_teuer: bool = ud.bau.plan.size() == 2 and ps.bauwerke.size() == wege0_t4 + 1 and _letzte().contains("Der Plan kostet")
	ps.eco.cash_cent = geld_alt
	ud.bau.neu()
	await _knopf_klick("plan_weg_1")
	var verworfen: bool = ud.bau.plan.size() == 1
	kasse = ps.eco.cash_cent
	var k1_t4: int = int(ud.bau.plan[0]["q"]["kosten_cent"]) if ud.bau.plan.size() == 1 else -1
	await _knopf_klick("plan_bauen")
	pruef(plan1 and am_plan and plan2 and zu_teuer and verworfen and ud.bau.plan.is_empty() and ps.bauwerke.size() == wege0_t4 + 2 and kasse - ps.eco.cash_cent == k1_t4 and ud.bau.plan_wurzel.get_child_count() == 0,
		"B8 Planen (Taste P): 2 Abschnitte als Blaupause ohne Geld (zweiter setzt am geplanten Ende an), Summe %d $; zu wenig Geld: „Der Plan kostet …“; Abschnitt 2 verworfen; „Plan bauen“ baut Abschnitt 1 für %d $" % [summe_b / 100, k1_t4 / 100])
	_druecke(KEY_P)
	_druecke(KEY_ESCAPE)
	await _frames(2)
	pruef(ud.bau_art == "" and not ud.banner.visible and not ud.bau.schild.visible and not ud.bau.marke.visible and ud.bau.vorschau.get_child_count() == 0 and not ud.bau.planen,
		"B9 Esc beendet das Werkzeug: Banner, Schild, Marke und Vorschau sind weg")
	# Stadtlinie mit drei Halten über das Ortspanel („Personenlinie hier beginnen“)
	uw.oeffnen(DORF)
	await _frames(2)
	await _knopf_klick("linie_hier_beginnen")
	ud._process(0.2)
	var ringe := int(ud.werte.get("marker_gueltig", 0))
	n0 = uw.meldungen_log.size()
	vk.halte_klick(MUEHLE)
	var t_betrieb := _letzte()
	vk.halte_klick("Erlenbach Ostend")
	vk.halte_klick("Erlenbach Kirchgasse")
	pruef(ud.modus() == "halte" and vk.halte_art == "strasse_personen" and vk.halte_liste == [DORF, "Erlenbach Ostend", "Erlenbach Kirchgasse"] and ringe == 7 and t_betrieb.contains("Personenlinien halten nur in Orten")
		and ud.werte["plan_pruefung"].get("ok", false),
		"V1 „Personenlinie hier beginnen“ in Erlenbach: Halt 1 gesetzt, %d Orte/Haltestellen mit Ring; Mühle abgelehnt („%s“); 3 Halte gültig, Rundkurs %d m" % [ringe, t_betrieb, int(ud.werte["plan_pruefung"].get("strecke_m", 0))])
	_kamera(1700, 720, 620, 0.5)
	await _shot("14_linien_editor_stadtlinie")
	var pr: Dictionary = vk.halte_fertig()
	var lid: int = int(pr.get("linie", 0))
	await _frames(2)
	kasse = ps.eco.cash_cent
	var kk: Dictionary = ps.depot_kaufen(0, "kutsche_d", 1)
	vk.zuweisen(kk["keys"], lid)
	pruef(pr.get("ok", false) and kasse - ps.eco.cash_cent == 30000 and ps.linien.size() == 3 and ps.linie_fahrzeuge(lid).size() == 1 and s.fahrzeuge.mmis.has("postkutsche"),
		"V2 Stadtlinie angelegt, Stadtkutsche im Fuhrhof für 300 $ gekauft und zugewiesen: „%s“" % _letzte())
	vk.linie_zeigen(lid)
	await _frames(3)
	await _knopf_klick("halt_%d_0_auftrag" % lid)
	var auftrag_neu: String = ps.linie_plan(lid)["auftrag"][0]
	await _knopf_klick("halt_%d_0_auftrag" % lid)
	await _knopf_klick("halt_%d_0_auftrag" % lid)
	pruef(auftrag_neu == "nichts" and ps.linie_plan(lid)["auftrag"][0] == "mitnehmen", "V3 Ladeauftrag je Halt per Mausklick umschalten (mitnehmen → nur abladen → voll → mitnehmen)")
	vk.schliessen()
	_ticks(ps.sim.tick_count + 900)
	uw.oeffnen("Erlenbach Ostend")
	pruef(int(ud.werte["wartende"]) == ps.wartende("Erlenbach Ostend") and int(ps.geliefert.get("fahrgaeste", 0)) > 0 and ud.raum.has_node("Halt_" + "Erlenbach Ostend".validate_node_name())
		and int(ud.werte["linien_hier"]) == 1 and _kn("linie_hier_%d" % lid) != null,
		"V4 Stadtverkehr: %d Fahrgäste befördert, Haltestelle zeigt %d Wartende = Spielwert und die Linie, die hier hält" % [int(ps.geliefert.get("fahrgaeste", 0)), int(ud.werte["wartende"])])
	var kf: Dictionary = ps.linie_fahrzeuge(lid)[0]
	var kp: Vector3 = kf["zustand"].pos
	_kamera(kp.x, kp.z, 240, 0.7)
	await _shot("15_stadtverkehr_kutsche")
	uw.schliessen()
	# Depot bauen (Betriebshof), in der Welt anklicken, Überholung
	vk.oeffnen("depots")
	await _frames(3)
	var d_tab: bool = _kn("vk_depot_0") != null and _kn("depot_bauen") != null
	await _shot("27_verkehr_depots")
	await _knopf_klick("depot_bauen")
	ud._process(0.2)
	banner["depot"] = String(ud.werte.get("banner", ""))
	var d_modus: bool = ud.modus() == "depot" and not vk.panel.visible and banner["depot"].contains("Depot bauen")
	ud.depot_zeigen(Vector2(1000, 500))
	var d_fehl: String = ""
	for c in ud.modus_vb.get_children():
		if c is Label and String(c.text).begins_with("■"):
			d_fehl = c.text
	var mp: Vector2 = ps.halt_pos(MUEHLE)
	ud.depot_zeigen(mp)
	kasse = ps.eco.cash_cent
	var dr: Dictionary = ud.depot_setzen(mp)
	pruef(d_tab and d_modus and d_fehl.contains("kein Weg") and dr.get("ok", false) and kasse - ps.eco.cash_cent == int(ps.daten["depot"]["kosten_cent"]) and int(ps.daten["depot"]["kosten_cent"]) == 25000 and ud.raum.has_node("Depot_2") and not ud.depot_modus and not ud.banner.visible
		and vk.depot_offen == 1,
		"V6 Reiter Depots → bauen: Banner „%s“; ohne Weg „%s“; an der Straße gebaut (−250 $), Haus in der Welt, Depotfenster öffnet sich" % [banner["depot"], d_fehl])
	_druecke(KEY_ESCAPE)
	await _frames(2)
	var dpos: Vector2 = ps.depots[1]["pos"]
	_kamera(dpos.x, dpos.y, 300, 0.4)
	await _ruhig()
	var d_px: Vector2 = s.cam.unproject_position(Vector3(dpos.x - 5.0, s.hoehe_at(dpos.x, dpos.y) + 4.0, dpos.y + 3.0))
	ud.hover_setzen(d_px)
	var d_hover: bool = String(ud.werte["hover"]) == String(ps.depots[1]["name"])
	_klick(d_px)
	await _frames(3)
	ud._process(0.2)
	pruef(d_hover and vk.depot_offen == 1 and vk.depot_panel.visible and ud.werte["auswahl"]["art"] == "depot" and ud.sel_ring.visible,
		"V7 Depot in der Welt: Hover-Ring, Mausklick öffnet das Depotfenster, Ring am Depot")
	await _knopf_klick("kat_kaufen_kutsche_d")
	await _shot("17_depot_in_der_welt")
	kasse = ps.eco.cash_cent
	var rwk: int = ps.restwert(ps.abgestellt[0])
	await _knopf_klick("depot_verkaufen")
	await _knopf_klick("depot_verkaufen_ja")
	pruef(ps.abgestellt.is_empty() and ps.eco.cash_cent - kasse == rwk and rwk > 0, "V8 Kutsche im Betriebshof gekauft (gleich ausgewählt) und aus dem Depot verkauft: +%d $ Restwert" % (rwk / 100))
	_klick(_frei_px())
	await _frames(3)
	ud._process(0.2)
	var depot_zu: bool = vk.depot_offen < 0 and not ud.sel_ring.visible
	# Gleis (ab 1824)
	n0 = uw.meldungen_log.size()
	ud.bau_start("gleis")
	pruef(depot_zu and ud.bau_art == "" and uw.meldungen_log.size() == n0 + 1 and _letzte().contains("1824"), "U20 Klick ins Leere schließt das Depotfenster; Gleis vor 1824: „%s“" % _letzte())
	ps.eco.cash_cent += 1500000                  # Testwerkzeug: Geld für die späten Schritte
	_ticks(7200)
	await _frames(2)
	_druecke(KEY_G)
	await _frames(2)
	ud._process(0.2)
	banner["bau_gleis"] = String(ud.werte.get("banner", ""))
	ud.bau.kurve = false
	ud.klick_boden(Vector2(370, 1235))
	ud.klick_boden(Vector2(700, 1120))
	ud._maus_boden = Vector2(985, 1020)
	ud.modus_neu()
	_kamera(680, 1130, 820, 0.2)
	await _shot("08_gleisbau")
	ud.klick_boden(Vector2(985, 1020))
	ud.bau_fertig()
	ud.modus_ende()
	ud.bau.kurve = true
	await _frames(2)
	var wi: int = ps.bauwerke[-1]["weg"]
	pruef(banner["bau_gleis"].contains("Gleis bauen") and ps.bahnhof.has(KOHLE) and ps.bahnhof.has(HUETTE) and ud.raum.has_node("Schienen_%d" % wi) and ud.raum.has_node("Bahnhof_" + KOHLE.validate_node_name()),
		"U21 Taste G: Banner „%s“; Gleis gebaut: Schienen, Schwellen und zwei Bahnhöfe in der Welt; „%s“" % [banner["bau_gleis"], _letzte()])
	uw.lizenz_kaufen(KOHLE)
	vk.halte_start("gleis_gueter")
	var gl_ringe := int(ud.werte.get("marker_gueltig", 0))
	vk.halte_klick(KOHLE)
	vk.halte_klick(HUETTE)
	var zr: Dictionary = vk.halte_fertig()
	var zl: int = int(zr.get("linie", 0))
	await _frames(3)
	var ohne_schuppen: bool = _text_in(vk.vb, "Kein Lokschuppen erreicht") and _kn("vk_depot_bauen_linie") != null and _kn("vk_zum_depot") == null
	await _knopf_klick("vk_depot_bauen_linie")
	var bk: Vector3 = ps.knoten_pos[ps.bahnhof[KOHLE]]
	var lr: Dictionary = ud.depot_setzen(Vector2(bk.x, bk.z))
	await _frames(2)
	var lkat: Array = ud.werte.get("depot_katalog", [])
	pruef(zr.get("ok", false) and gl_ringe == 2 and ohne_schuppen and lr.get("ok", false) and String(lr.get("art", "")) == "gleis" and vk.depot_offen == ps.depots.size() - 1 and lkat.has("pferdebahn_d") and not lkat.has("fuhrwerk_d"),
		"U22 Zuglinie: nur die %d Bahnhöfe gelten; ohne Lokschuppen sagt das Fenster es und bietet den Bau an; Lokschuppen-Katalog: %s" % [gl_ringe, str(lkat)])
	await _knopf_klick("kat_kaufen_pferdebahn_d")
	await _knopf_klick("depot_zu_%d" % zl)
	var zug: Dictionary = ps.linie_fahrzeuge(zl)[0] if not ps.linie_fahrzeuge(zl).is_empty() else {}
	pruef(not zug.is_empty() and ps.ist_zug(zug) and s.fahrzeuge.mmis.has("pferdebahn"), "U23 Pferdebahn im Lokschuppen gekauft, per Klick zugewiesen, fährt auf dem Gleis (eigene Darstellung)")
	_druecke(KEY_ESCAPE)
	_ticks(7200 + 500)
	var zp: Vector3 = zug["zustand"].pos
	_kamera(zp.x, zp.z, 260, 0.6)
	await _shot("09_pferdebahn")
	# Strecken: Chaussee kaufen/verkaufen, eigene Strecke
	vk.oeffnen("strecken")
	await _frames(2)
	var sl: Array = ud.werte["strecken"]
	n0 = uw.meldungen_log.size()
	vk.strecke_verkaufen("bau_0")
	var t_ben := _letzte()
	kasse = ps.eco.cash_cent
	vk.strecke_kaufen("chaussee")
	var gekauft: bool = ps.maut_gekauft and kasse - ps.eco.cash_cent == 280000
	vk.neu()
	await _shot("18_verkehr_strecken")
	vk.strecke_verkaufen("chaussee")
	await _frames(2)
	pruef(sl.size() >= 3 and uw.meldungen_log.size() >= n0 + 3 and t_ben.contains("Strecke verkauft") and gekauft and not ps.maut_gekauft and _kn("strecke_kauf_chaussee") != null,
		"V9 Reiter Strecken: %d Einträge; ungenutzte Forststraße verkauft („%s“), Chaussee gekauft (−2.800 $) und wieder verkauft" % [sl.size(), t_ben])
	vk.schliessen()
	# Personenzug: Gleis Erlenbach – Hasenwinkel, Pferdestraßenbahn
	var gp: Dictionary = ps.bauen("gleis", PackedVector2Array([Vector2(1660, 640), Vector2(1400, 760), Vector2(1000, 830), Vector2(800, 870)]))
	ud._bauwerke_pruefen()
	vk.halte_start("gleis_personen")
	var ringe_gl := int(ud.werte.get("marker_gueltig", 0))
	vk.halte_klick(DORF)
	vk.halte_klick("Hasenwinkel")
	var pz: Dictionary = vk.halte_fertig()
	var pl: int = int(pz.get("linie", 0))
	var bd: Vector3 = ps.knoten_pos[ps.bahnhof[DORF]]
	ud.depot_modus_start()
	ud.depot_setzen(Vector2(bd.x, bd.z))
	var pk: Dictionary = ps.depot_kaufen(vk.depot_offen, "pferdetram_d", 1)
	var pzu: Dictionary = vk.zuweisen(pk.get("keys", []), pl)
	var pzf: Dictionary = ps.linie_fahrzeuge(pl)[0] if not ps.linie_fahrzeuge(pl).is_empty() else {}
	pruef(gp.get("ok", false) and ringe_gl == 2 and pz.get("ok", false) and pzu.get("ok", false) and not pzf.is_empty() and ps.ist_zug(pzf),
		"V10 Personenzug: nur die %d Bahnhöfe an Orten gelten; Linie Erlenbach ↔ Hasenwinkel, Pferdestraßenbahn aus dem Lokschuppen zugewiesen" % ringe_gl)
	vk.depot_schliessen()
	_ticks(ps.sim.tick_count + 1500)
	var pp: Vector3 = pzf["zustand"].pos
	_kamera(pp.x, pp.z, 320, 0.5)
	vk.linie_sel = pl
	await _shot("19_personenzug")
	vk.linie_sel = 0
	# Modellwechsel: Reiter Fahrzeuge → auswählen → Ersetzen
	_ticks(14400 + 60)
	await _frames(2)
	vk.fahrzeug_zeigen(ps.fz_key(zug))
	await _frames(3)
	var eq: Dictionary = ps.ersetzen_angebot_key(ps.fz_key(zug))
	pruef(int(ud.werte["auswahl_fz"]) == 1 and eq.get("ok", false) and String(eq.get("def_id", "")) == "dampfzug_d" and _kn("fz_ersetzen") != null and not _kn("fz_ersetzen").disabled if _kn("fz_ersetzen") != null else false,
		"U24 1828: Pferdebahn in der Fahrzeugliste ausgewählt, „Ersetzen“ bietet den Dampfzug an (%d $ netto)" % (int(eq.get("netto_cent", 0)) / 100))
	await _shot("10_modellwechsel_angebot")
	await _knopf_klick("fz_ersetzen")
	await _frames(2)
	pruef(String(zug["def_id"]) == "dampfzug_d" and s.fahrzeuge.mmis.has("dampflok") and _letzte().contains("ersetzt"), "U25 ersetzt per Klick: Dampfzug auf derselben Linie, Meldung „%s“" % _letzte())
	vk.schliessen()
	_ticks(14400 + 400)
	zp = zug["zustand"].pos
	_kamera(zp.x, zp.z, 220, 0.9)
	await _shot("11_dampfzug")
	# Firmensitz ausbauen
	ud.hq_knopf()
	ud._process(0.2)
	pruef(ud.hq_panel.visible and ud.knoepfe.has("hq_ausbau") and int(ud.werte["hq_stufe"]) == 1 and ud.werte["auswahl"]["art"] == "hq" and ud.sel_ring.visible, "U26 Firmensitz-Panel: Ausbau und Anbauten; der Firmensitz ist die Auswahl (Ring)")
	ud.hq_anbauen("remise")
	n0 = uw.meldungen_log.size()
	ud.hq_anbauen("stall")
	var t_platz := _letzte()
	ud.hq_ausbauen()
	pruef(ps.hq_stufe == 2 and ps.hq_anbauten == ["remise"] and uw.meldungen_log.size() == n0 + 2 and t_platz.contains("Kein Platz"), "U27 Anbau, zweiter ohne Platz („%s“), Ausbau auf Stufe 2" % t_platz)
	_kamera(HQ.x, HQ.y, 420, 0.5)
	await _shot("12_firmensitz_ausbau")
	# Esc-Reihenfolge und Menü-Abfrage
	var e1 := _taste(KEY_ESCAPE)
	var zu1: bool = not ud.hq_panel.visible
	var e2 := _taste(KEY_ESCAPE)
	pruef(e1 and zu1 and e2 and ud.menue_panel.visible, "U28 Esc hebt erst die Auswahl auf, dann fragt es nach (kein stiller Verlust des Spielstands)")
	_taste(KEY_ESCAPE)
	# Alle Stationspanels öffnen; Linienliste links unten öffnet die Linie im Fenster; kein Knopf des alten Musters
	var offen := 0
	var alt_knopf := 0
	for nm in ps.stationen:
		uw.oeffnen(nm)
		if uw.panel.visible and uw.panel_vb.get_child_count() >= 2:
			offen += 1
		for id in uw.knoepfe:
			if is_instance_valid(uw.knoepfe[id]) and (String(id) == "linie_von_hier" or String(id).begins_with("plus_") or String(id).begins_with("lplus_") or String(id) == "anlegen"):
				alt_knopf += 1
	uw.schliessen()
	uw.linien_neu()
	await _frames(2)
	await _knopf_klick("linie_2")
	pruef(offen == ps.stationen.size() and alt_knopf == 0 and uw.linien_werte.size() == ps.linien.size() and vk.panel.visible and vk.linie_sel == 2 and uw.modus_von == "",
		"U28b alle %d Stationspanels öffnen ohne Knopf des alten Musters; Linienliste links unten (%d Linien) öffnet per Klick die Linie im Fenster" % [offen, uw.linien_werte.size()])
	vk.schliessen()
	vk.linie_sel = 0
	# Kein stiller Modus: jeder Modus hat sein Banner, Esc beendet jeden
	var still: Array = []
	for m in [["hq", func(): ud.hq_modus_start()], ["bau", func(): ud.bau_start("strasse")], ["bau", func(): ud.bau_start("gleis")], ["depot", func(): ud.depot_modus_start()],
			["halte", func(): vk.halte_start("strasse_gueter")], ["halte", func(): vk.halte_start("strasse_gueter", 1)]]:
		(m[1] as Callable).call()
		ud._process(0.2)
		var form := int(ud.werte["cursor"])
		if ud.modus() != m[0] or not ud.banner.visible or String(ud.werte["banner"]).length() < 20 or not String(ud.werte["banner"]).contains("Esc") or form == Input.CURSOR_ARROW:
			still.append(m[0])
		_druecke(KEY_ESCAPE)
		await _frames(1)
		if ud.modus() != "" or ud.banner.visible or ud.menue_panel.visible:
			still.append("esc_" + String(m[0]))
	var texte := {}
	for k in banner:
		texte[banner[k]] = true
	pruef(still.is_empty() and texte.size() == 5 and not texte.has(""), "A16 kein stiller Modus: Firmensitz, Straße, Gleis, Depot, Halte (neu und anhängen) zeigen Banner mit „Esc“ und eigenen Mauszeiger; Esc beendet jeden. Abweichungen: %s" % str(still))
	# Bilanz nach 30 Minuten
	_ticks(18000)
	ud._t = 1.0
	ud._process(0.0)
	await _frames(2)
	pruef(ud.ende_gezeigt and ud.ende_panel.visible and s.sim_tempo == 0 and int(ud.werte["ende"]["kasse"]) == ps.eco.cash_cent and int(ud.werte["ende"]["meilensteine"]) == ps.meilensteine_erreicht.size(),
		"U28c Minute 30: Bilanzkarte mit Spielwerten (Kasse %d $, %d Meilensteine), Spiel pausiert" % [ps.eco.cash_cent / 100, ps.meilensteine_erreicht.size()])
	_kamera(1300, 900, 1500, 0.4)
	await _shot("13_bilanz_minute_30")
	_taste(KEY_ESCAPE)
	# Fehlertexte
	var zu_lang: Array = []
	for k in ud.FT:
		if String(ud.FT[k]).length() > 130:
			zu_lang.append(k)
	var codes := ["kein_hq", "noch_nicht_verfuegbar", "zu_wenig_punkte", "kein_anschluss", "gleicher_punkt", "see", "zu_kurz", "zu_lang", "bruecke_zu_lang", "ende_im_wasser",
		"zu_steil", "kurve_zu_eng", "guthaben_reicht_nicht", "kein_bahnhof", "keine_gleisverbindung", "kein_ort", "wasser", "auf_der_strasse", "hoechste_stufe",
		"schon_gebaut", "kein_platz", "kein_punkt", "vorgaenger_fehlt", "schon_gesetzt", "angebot_weg", "zu_viele_vertraege",
		"zu_wenig_halte", "zu_viele_halte", "gleicher_ort", "falsche_fracht", "unbekannte_linie", "unbekannter_halt", "passt_nicht_zur_linie", "linie_hat_fahrzeuge", "kein_depot",
		"nichts_zu_ueberholen", "depot_erreicht_linie_nicht", "nicht_kaeuflich", "schon_gekauft", "nicht_im_besitz", "strecke_benutzt", "depot_an_strecke", "unbekannte_strecke", "unbekannter_ort",
		"unbekannte_linienart", "falsches_depot", "kein_neueres_modell", "keine_auswahl", "unbekanntes_fahrzeug"]
	var ohne: Array = []
	for c in codes:
		if ud.fehlertext({"fehler": c, "ab_jahr": 1824, "fehlt_cent": 1234, "name": "X", "max": 2, "braucht": "Y", "n": 2, "art": "Betriebshof", "depot": "Z"}) == "" or ud.fehlertext({"fehler": c}).contains("Meldung an uns"):
			ohne.append(c)
	pruef(zu_lang.is_empty() and ohne.is_empty(), "U29 %d Fehlercodes der Demo haben einen Text mit Handlungsvorschlag (≤ 130 Zeichen); ohne Text: %s" % [codes.size(), str(ohne + zu_lang)])
	pruef(ps.fehler.is_empty(), "U30 0 Sim-Fehler im UI-Durchlauf: %s" % str(ps.fehler))
	print("demo_ui_test: %d/%d Prüfungen OK" % [n_ok, n_ok + n_fail])
	quit(0 if n_fail == 0 else 1)
