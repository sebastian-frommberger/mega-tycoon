extends SceneTree
## Demo-Sprint: UI-Test der Demo (ui_demo.gd + ui_welt.gd im Demo-Modus) und Screenshots der Schlüsselmomente (Gate G).
##   godot --headless --path slice -s res://tests/demo_ui_test.gd                      (nur Prüfungen)
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --path slice -s res://tests/demo_ui_test.gd -- --shots=<ordner>
## Spielt einen Durchlauf über die UI-Funktionen (dieselben, die Knöpfe und Tasten rufen): Start, Firmensitz, Linie, Vertrag,
## Skill, Straße, Gleis, Zug, Modellwechsel, HQ-Ausbau, Esc. Prüft: Anzeige = Spielwert, keine stumme Ablehnung, Fehlertexte.

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


func _klick(pos: Vector2) -> void:
	for druck in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = druck
		ev.position = pos
		ev.global_position = pos
		root.push_input(ev)


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
	pruef(ud.start_panel.visible and s.sim_tempo == 0 and ud.leiste_kn.size() == 8 and String(ud.lbl_moeglich.text).contains("Firmensitz platzieren"),
		"U2 Startbild sichtbar, Spiel pausiert, Werkzeugleiste mit 8 Knöpfen, Zeile: %s" % ud.lbl_moeglich.text)
	await _shot("01_startbild")
	# Vor dem Firmensitz: jede Aktion erklärt sich
	var n0: int = uw.meldungen_log.size()
	ud.bau_start("strasse")
	uw.lizenz_kaufen(FARM)
	pruef(uw.meldungen_log.size() == n0 + 2 and _letzte().contains("Firmensitz") and ud.bau_art == "", "U3 ohne Firmensitz: Bauen und Lizenz melden „%s“" % _letzte())
	_taste(KEY_SPACE)
	pruef(not ud.start_panel.visible and ud.hq_modus and s.sim_tempo == 1 and ud.modus_panel.visible, "U4 Leertaste schließt das Startbild, Zeit läuft, Firmensitz-Modus ist an")
	s.setze_tempo(0)
	_kamera(1640, 760, 620, 0.5)
	# Echter Eingabeweg: Geländepunkt unter der Maus, Taste und Mausklick durch den Viewport
	var abw := 0.0
	for wp in [Vector2(1668, 688), Vector2(1500, 900), Vector2(1900, 700)]:
		var sp: Vector2 = s.cam.unproject_position(Vector3(wp.x, s.hoehe_at(wp.x, wp.y), wp.y))
		var zur = ud.boden(sp)
		abw = maxf(abw, (zur as Vector2).distance_to(wp) if zur is Vector2 else 999.0)
	pruef(abw < 2.0, "U4b Geländepunkt unter der Maus: Bildpunkt → Welt weicht höchstens %.2f m ab" % abw)
	ud.hq_modus_ende()
	_druecke(KEY_H)
	var per_taste: bool = ud.hq_modus
	_klick(s.cam.unproject_position(Vector3(1000, s.hoehe_at(1000, 500), 500)))
	await _frames(2)
	pruef(per_taste and not ps.hq_platziert and _letzte().contains("Ort"), "U4c Taste H und Mausklick laufen durch die Szene: Klick außerhalb meldet „%s“" % _letzte())
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
	pruef(r.get("ok", false) and ps.hq_platziert and ud.hq_haus.get_child_count() >= 3 and not ud.hq_modus and _letzte().contains("gegründet"),
		"U8 Firmensitz gesetzt: Haus, Fahne, Schild in der Welt; Meldung „%s“" % _letzte())
	await _shot("03_firmensitz_gesetzt")
	# Kette 1 über die Welt-UI
	uw.oeffnen(FARM)
	uw.lizenz_kaufen(FARM)
	uw.linie_von_hier(FARM)
	uw.ziel_waehlen(MUEHLE)
	pruef(uw.vorschau_panel.visible and uw.knoepfe.has("modell_fuhrwerk_d") and int(uw.vorschau_werte["preis_cent"]) == ps._preis(ps.vdef("fuhrwerk_d")),
		"U9 Linienvorschau mit Modellwahl: Fuhrwerk %d ¢" % int(uw.vorschau_werte.get("preis_cent", 0)))
	uw.anlegen()
	uw.ziel_waehlen(DORF)
	uw.anlegen()
	uw.modus_ende()
	pruef(ps.fahrzeuge.size() == 2 and ps.fehler.is_empty(), "U10 zwei Linien über die UI angelegt (Farm → Mühle → Erlenbach)")
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
	# Straße bauen
	ud.bau_start("strasse")
	pruef(ud.bau_art == "strasse" and ud.marker_root.get_child_count() == 4 and ud.modus_panel.visible, "U16 Baumodus Straße: %d Ringe an Betrieben ohne Anschluss" % ud.marker_root.get_child_count())
	n0 = uw.meldungen_log.size()
	ud.klick_boden(Vector2(900, 1300))
	pruef(ud.bau_punkte.is_empty() and uw.meldungen_log.size() == n0 + 1 and _letzte().contains("hängt in der Luft"), "U17 Start im Nichts: „%s“" % _letzte())
	ud.klick_boden(Vector2(1284, 936))
	ud.klick_boden(Vector2(1330, 1100))
	ud._maus_boden = Vector2(1052, 1248)
	ud.modus_neu()
	var q: Dictionary = ps.bau_angebot("strasse", PackedVector2Array([Vector2(1284, 936), Vector2(1330, 1100), Vector2(1052, 1248)]))
	pruef(ud.bau_punkte.size() == 2 and int(ud.werte["bau_kosten"]) == int(q["kosten_cent"]) and ud.vorschau_mi.visible, "U18 Vorschau = Spielwert: %d ¢ für %d m" % [int(q["kosten_cent"]), int(q["laenge_m"])])
	_kamera(1180, 1100, 760, -0.4)
	await _shot("07_strassenbau")
	var kasse: int = ps.eco.cash_cent
	ud.klick_boden(Vector2(1052, 1248))
	pruef(ps.angeschlossen(FORST) and kasse - ps.eco.cash_cent == int(q["kosten_cent"]) and ud.bau_art == "" and _letzte().contains("Forsthaus Rotwald ist angeschlossen"),
		"U19 Klick auf das Ziel baut: „%s“" % _letzte())
	# Linienplaner: Stadtlinie mit drei Halten
	_druecke(KEY_L)
	var per_l: bool = ud.plan_panel.visible
	ud.plan_start("kutsche_d")
	var ringe: int = ud.marker_root.get_child_count()
	ud.plan_halt_klick(DORF)
	ud.plan_halt_klick("Erlenmühle")
	var pf: Dictionary = ud.werte.get("plan_pruefung", {})
	ud.plan_halte.remove_at(1)
	ud.plan_halt_klick("Erlenbach Ostend")
	ud.plan_halt_klick("Erlenbach Kirchgasse")
	pruef(per_l and ud.plan_neu_an and ringe == 7 and String(pf.get("fehler", "")) == "falsche_fracht" and ud.werte["plan_pruefung"].get("ok", false) and ud.knoepfe.has("plan_0_1_auftrag"),
		"V1 Linienplaner (Taste L): Stadtkutsche, %d Ringe an Orten/Haltestellen; Mühle als Halt abgelehnt (falsche_fracht); 3 Halte gültig, Rundkurs %d m" % [ringe, int(ud.werte["plan_pruefung"].get("strecke_m", 0))])
	_kamera(1700, 720, 620, 0.5)
	await _shot("14_linienplaner")
	kasse = ps.eco.cash_cent
	var pr: Dictionary = ud.plan_anlegen()
	pruef(pr.get("ok", false) and kasse - ps.eco.cash_cent == 30000 and ps.linien.size() == 1 and not ud.plan_neu_an and s.fahrzeuge.mmis.has("postkutsche") and _letzte().contains("Linie 1 läuft"),
		"V2 Linie angelegt: „%s“" % _letzte())
	(ud.knoepfe["plan_1_0_auftrag"] as Button).pressed.emit()
	var auftrag_neu: String = ps.linien[0]["auftrag"][0]
	(ud.knoepfe["plan_1_0_auftrag"] as Button).pressed.emit()
	(ud.knoepfe["plan_1_0_auftrag"] as Button).pressed.emit()
	pruef(auftrag_neu == "nichts" and ps.linien[0]["auftrag"][0] == "mitnehmen", "V3 Ladeauftrag je Halt per Knopf umschalten (mitnehmen → nur abladen → voll → mitnehmen)")
	_ticks(ps.sim.tick_count + 900)
	ud.plan_panel.visible = false
	uw.oeffnen("Erlenbach Ostend")
	pruef(int(ud.werte["wartende"]) == ps.wartende("Erlenbach Ostend") and int(ps.geliefert.get("fahrgaeste", 0)) > 0 and ud.raum.has_node("Halt_" + "Erlenbach Ostend".validate_node_name()),
		"V4 Stadtverkehr: %d Fahrgäste befördert, Haltestelle zeigt %d Wartende = Spielwert" % [int(ps.geliefert.get("fahrgaeste", 0)), int(ud.werte["wartende"])])
	var kf: Dictionary = ps.linie_fahrzeuge(1)[0]
	var kp: Vector3 = kf["zustand"].pos
	_kamera(kp.x, kp.z, 240, 0.7)
	await _shot("15_stadtverkehr_kutsche")
	uw.schliessen()
	# Fuhrpark: Liste, Depot, Kauf im Depot, Verkauf
	_druecke(KEY_U)
	pruef(ud.fuhr_panel.visible and int(ud.werte["fuhrpark_fahrzeuge"]) == 3 and ud.knoepfe.has("fuhr_vk_3") and ud.knoepfe.has("fuhr_karte_1"), "V5 Fuhrpark (Taste U): Liste mit 3 Fahrzeugen, Karte und Verkaufen je Zeile")
	await _shot("16_fahrzeugliste")
	ud.fuhrpark_umschalten("depots")
	ud.depot_modus_start()
	ud.depot_zeigen(Vector2(1000, 500))
	var d_fehl: String = ""
	for c in ud.modus_vb.get_children():
		if c is Label and String(c.text).begins_with("■"):
			d_fehl = c.text
	ud.depot_zeigen(Vector2(1640, 700))
	kasse = ps.eco.cash_cent
	var dr: Dictionary = ud.depot_setzen(Vector2(1640, 700))
	pruef(d_fehl.contains("kein Weg") and dr.get("ok", false) and kasse - ps.eco.cash_cent == 60000 and ud.raum.has_node("Depot_1") and not ud.depot_modus, "V6 Depot: ohne Weg „%s“; an der Straße gebaut (−600 $), Haus in der Welt" % d_fehl)
	ud.fuhr_tab = "depots"
	ud.fuhr_panel.visible = true
	ud.fuhrpark_neu()
	kasse = ps.eco.cash_cent
	var dk: Dictionary = ud.depot_kauf(0, "kutsche_d", 1)
	pruef(dk.get("ok", false) and kasse - ps.eco.cash_cent == 27600 and ud.knoepfe.has("depot_kauf_0_1") and _letzte().contains("Depotpreis"), "V7 Kauf im Depot: zweite Stadtkutsche für 276 $ statt 300 $; „%s“" % _letzte())
	_kamera(1640, 700, 300, 0.4)
	await _shot("17_depot")
	kasse = ps.eco.cash_cent
	var rwk: int = ps.restwert(ps.fahrzeug(int(dk["vid"])))
	ud.verkaufen(int(dk["vid"]))
	pruef(ps.eco.cash_cent - kasse == rwk and rwk > 0 and _letzte().contains("Restwert") and ps.linie_fahrzeuge(1).size() == 1, "V8 Verkauf aus der Fahrzeugliste: +%d ¢ Restwert; „%s“" % [rwk, _letzte()])
	ud.fuhr_panel.visible = false
	# Gleis (ab 1824)
	n0 = uw.meldungen_log.size()
	ud.bau_start("gleis")
	pruef(ud.bau_art == "" and uw.meldungen_log.size() == n0 + 1 and _letzte().contains("1824"), "U20 Gleis vor 1824: „%s“" % _letzte())
	ps.eco.cash_cent += 1500000                  # Testwerkzeug: Geld für die späten Schritte
	_ticks(7200)
	await _frames(2)
	ud.bau_start("gleis")
	ud.klick_boden(Vector2(370, 1235))
	ud.klick_boden(Vector2(700, 1120))
	ud._maus_boden = Vector2(985, 1020)
	ud.modus_neu()
	_kamera(680, 1130, 820, 0.2)
	await _shot("08_gleisbau")
	ud.klick_boden(Vector2(985, 1020))
	await _frames(2)
	var wi: int = ps.bauwerke[-1]["weg"]
	pruef(ps.bahnhof.has(KOHLE) and ps.bahnhof.has(HUETTE) and ud.raum.has_node("Schienen_%d" % wi) and ud.raum.has_node("Bahnhof_" + KOHLE.validate_node_name()),
		"U21 Gleis gebaut: Schienen, Schwellen und zwei Bahnhöfe in der Welt; „%s“" % _letzte())
	uw.lizenz_kaufen(KOHLE)
	uw.linie_von_hier(KOHLE)
	uw.ziel_waehlen(HUETTE)
	pruef(uw.kauf_def == "pferdebahn_d" and uw.vorschau_panel.visible, "U22 ohne Straße wählt die Vorschau den Zug: %s" % uw.kauf_def)
	uw.anlegen()
	uw.modus_ende()
	var zug: Dictionary = ps.fahrzeuge[-1]
	pruef(ps.ist_zug(zug) and s.fahrzeuge.mmis.has("pferdebahn"), "U23 Pferdebahn fährt auf dem Gleis (eigene Darstellung)")
	_ticks(7200 + 500)
	var zp: Vector3 = zug["zustand"].pos
	_kamera(zp.x, zp.z, 260, 0.6)
	await _shot("09_pferdebahn")
	# Strecken: Chaussee kaufen/verkaufen, eigene Strecke
	ud.fuhrpark_umschalten("strecken")
	var sl: Array = ud.werte["strecken"]
	n0 = uw.meldungen_log.size()
	ud.strecke_verkaufen("bau_0")
	var t_ben := _letzte()
	kasse = ps.eco.cash_cent
	ud.strecke_kaufen("chaussee")
	var gekauft: bool = ps.maut_gekauft and kasse - ps.eco.cash_cent == 280000
	ud.fuhrpark_neu()
	await _shot("18_strecken")
	ud.strecke_verkaufen("chaussee")
	pruef(sl.size() == 3 and uw.meldungen_log.size() >= n0 + 3 and t_ben.contains("Strecke verkauft") and gekauft and not ps.maut_gekauft and ud.knoepfe.has("strecke_kauf_chaussee"),
		"V9 Strecken: %d Einträge; ungenutzte Forststraße verkauft („%s“), Chaussee gekauft (−2.800 $) und wieder verkauft" % [sl.size(), t_ben])
	ud.fuhr_panel.visible = false
	# Personenzug: Gleis Erlenbach – Hasenwinkel, Pferdestraßenbahn per Linienplaner
	var gp: Dictionary = ps.bauen("gleis", PackedVector2Array([Vector2(1660, 640), Vector2(1400, 760), Vector2(1000, 830), Vector2(800, 870)]))
	ud._bauwerke_pruefen()
	ud.plan_start("pferdetram_d")
	var ringe_gl: int = ud.marker_root.get_child_count()
	ud.plan_halt_klick(DORF)
	ud.plan_halt_klick("Hasenwinkel")
	var pz: Dictionary = ud.plan_anlegen()
	pruef(gp.get("ok", false) and ringe_gl == 2 and pz.get("ok", false) and ps.ist_zug(ps.fahrzeug(int(pz.get("vid", 0)))) and ps.linien.size() == 2,
		"V10 Personenzug: Planer bietet für die Pferdestraßenbahn nur die %d Bahnhöfe an Orten an; Linie Erlenbach ↔ Hasenwinkel angelegt" % ringe_gl)
	_ticks(ps.sim.tick_count + 1500)
	var pzf: Dictionary = ps.fahrzeug(int(pz.get("vid", 0)))
	var pp: Vector3 = pzf["zustand"].pos
	ud.plan_edit = int(pz.get("linie", 0))
	ud.plan_panel.visible = true
	ud.plan_neu()
	_kamera(pp.x, pp.z, 320, 0.5)
	await _shot("19_personenzug_linienplan")
	ud.plan_panel.visible = false
	# Modellwechsel
	_ticks(14400 + 60)
	await _frames(2)
	uw.fahrzeug_oeffnen(int(zug["vid"]))
	pruef(uw.knoepfe.has("ersetzen_dampfzug_d") and uw.panel_werte.has("ersetzen_dampfzug_d"), "U24 Fahrzeugkarte bietet 1828 den Dampfzug an (Restwert, Preis, Ladung)")
	zp = zug["zustand"].pos
	_kamera(zp.x, zp.z, 300, 0.6)
	await _shot("10_modellwechsel_angebot")
	uw.ersetzen(int(zug["vid"]), "dampfzug_d")
	await _frames(2)
	pruef(String(zug["def_id"]) == "dampfzug_d" and s.fahrzeuge.mmis.has("dampflok") and _letzte().contains("ersetzt"), "U25 ersetzt: Dampfzug auf derselben Linie, Meldung „%s“" % _letzte())
	_ticks(14400 + 400)
	zp = zug["zustand"].pos
	_kamera(zp.x, zp.z, 220, 0.9)
	await _shot("11_dampfzug")
	uw.schliessen()
	# Firmensitz ausbauen
	ud.hq_knopf()
	pruef(ud.hq_panel.visible and ud.knoepfe.has("hq_ausbau") and int(ud.werte["hq_stufe"]) == 1, "U26 Firmensitz-Panel: Ausbau und Anbauten")
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
	pruef(e1 and zu1 and e2 and ud.menue_panel.visible, "U28 Esc schließt erst das Panel, dann fragt es nach (kein stiller Verlust des Spielstands)")
	_taste(KEY_ESCAPE)
	# Alle Stationspanels und Linienvorschauen öffnen (Demo-Betriebe im Bestandspanel), Linienliste aufklappen
	var offen := 0
	for nm in ps.stationen:
		uw.oeffnen(nm)
		if uw.panel.visible and uw.panel_vb.get_child_count() >= 2:
			offen += 1
		if uw.ausgang(uw.site_of(nm)) != "":
			uw.linie_von_hier(nm)
			for k in ps.kanten():
				if k["von"] == nm:
					uw.ziel_waehlen(k["nach"])
			uw.modus_ende()
	uw.schliessen()
	uw.linien_neu()
	var lk: String = uw.linien_werte.keys()[0]
	(uw.knoepfe["linie_" + lk] as Button).pressed.emit()
	n0 = uw.meldungen_log.size()
	uw.kauf_klick("Hof Hasenwinkel")
	pruef(offen == ps.stationen.size() and uw.linie_offen == lk and uw.linien_werte.size() >= 3 and uw.linien_scroll != null,
		"U28b alle %d Stationspanels und Vorschauen öffnen, kompakte Linienliste mit %d Linien klappt auf" % [offen, uw.linien_werte.size()])
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
		"nichts_zu_ueberholen", "depot_erreicht_linie_nicht", "nicht_kaeuflich", "schon_gekauft", "nicht_im_besitz", "strecke_benutzt", "depot_an_strecke", "unbekannte_strecke", "unbekannter_ort"]
	var ohne: Array = []
	for c in codes:
		if ud.fehlertext({"fehler": c, "ab_jahr": 1824, "fehlt_cent": 1234, "name": "X", "max": 2, "braucht": "Y", "n": 2, "art": "Betriebshof"}) == "" or ud.fehlertext({"fehler": c}).contains("Meldung an uns"):
			ohne.append(c)
	pruef(zu_lang.is_empty() and ohne.is_empty(), "U29 %d Fehlercodes der Demo haben einen Text mit Handlungsvorschlag (≤ 130 Zeichen); ohne Text: %s" % [codes.size(), str(ohne + zu_lang)])
	pruef(ps.fehler.is_empty(), "U30 0 Sim-Fehler im UI-Durchlauf: %s" % str(ps.fehler))
	print("demo_ui_test: %d/%d Prüfungen OK" % [n_ok, n_ok + n_fail])
	quit(0 if n_fail == 0 else 1)
