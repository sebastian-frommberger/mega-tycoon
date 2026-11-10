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
	pruef(ud.start_panel.visible and s.sim_tempo == 0 and ud.leiste_kn.size() == 6 and String(ud.lbl_moeglich.text).contains("Firmensitz platzieren"),
		"U2 Startbild sichtbar, Spiel pausiert, Werkzeugleiste mit 6 Knöpfen, Zeile: %s" % ud.lbl_moeglich.text)
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
	# Fehlertexte
	var zu_lang: Array = []
	for k in ud.FT:
		if String(ud.FT[k]).length() > 120:
			zu_lang.append(k)
	var codes := ["kein_hq", "noch_nicht_verfuegbar", "zu_wenig_punkte", "kein_anschluss", "gleicher_punkt", "see", "zu_kurz", "zu_lang", "bruecke_zu_lang", "ende_im_wasser",
		"zu_steil", "kurve_zu_eng", "guthaben_reicht_nicht", "kein_bahnhof", "keine_gleisverbindung", "kein_ort", "wasser", "auf_der_strasse", "hoechste_stufe",
		"schon_gebaut", "kein_platz", "kein_punkt", "vorgaenger_fehlt", "schon_gesetzt", "angebot_weg", "zu_viele_vertraege"]
	var ohne: Array = []
	for c in codes:
		if ud.fehlertext({"fehler": c, "ab_jahr": 1824, "fehlt_cent": 1234, "name": "X", "max": 2, "braucht": "Y"}) == "" or ud.fehlertext({"fehler": c}).contains("Meldung an uns"):
			ohne.append(c)
	pruef(zu_lang.is_empty() and ohne.is_empty(), "U29 %d Fehlercodes der Demo haben einen Text mit Handlungsvorschlag (≤ 120 Zeichen); ohne Text: %s" % [codes.size(), str(ohne + zu_lang)])
	pruef(ps.fehler.is_empty(), "U30 0 Sim-Fehler im UI-Durchlauf: %s" % str(ps.fehler))
	print("demo_ui_test: %d/%d Prüfungen OK" % [n_ok, n_ok + n_fail])
	quit(0 if n_fail == 0 else 1)
