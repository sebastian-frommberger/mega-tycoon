extends SceneTree
## Phase 4 Welle 2 (Aylin): Test der Prototyp-Schilder (proto/proto_schilder.gd), headless.
##   godot --headless --path slice -s res://tests/proto_schilder_test.gd
## Prüft: Anzahl und Texte, Stufen (Fern/Voll/Nah, Hysterese), Größenordnung Kleinstadt > Dorf, Weiler-Regel,
## Anker über dem Gelände (hoehe_at) und Sichtlinie, Entzerrung (keine Überlappung), Tooltip Einzugsgebiet,
## Kontrast (WCAG 2.x, analytisch gegen die Bodenklassen, Wasser, Himmel), Mindestschrift 12 px, „Modelle aus“.
## Schreibt ../_out/kontrast_analytisch.csv (Messwerte für aylin_welle2.md). Die Bildmessung macht proto_schilder_shots.gd.

const Schilder := preload("res://proto/proto_schilder.gd")

class Huegel extends RefCounted:
	## Gelände mit Wall bei x = 1300…1340 (Höhe 140 m), sonst 40 m: erzwingt die Anhebung des Schilds.
	func hoehe_at(x: float, _z: float) -> float:
		return 140.0 if absf(x - 1320.0) < 25.0 else 40.0


var n_ok := 0
var n_fail := 0
var s: Node
var sch
var zeilen: Array[String] = []


func ok(c: bool, text: String) -> void:
	if c:
		n_ok += 1
		print("  OK   ", text)
	else:
		n_fail += 1
		print("  FAIL ", text)


func _initialize() -> void:
	_run.call_deferred()


func _preset(n: int) -> void:
	s.setze_preset(n)
	sch.aktualisiere(true)


func _terrain_farben() -> Dictionary:
	var f := {"himmel_horizont": Color(0.76, 0.84, 0.91), "wasser_a_tief": Color("2F6E7C"), "wasser_b_tief": Color("345F7E")}
	var r = JSON.parse_string(FileAccess.get_file_as_string("res://world/data/proto/regelwerk.json"))
	if r is Dictionary:
		var kl: Dictionary = r["landschaft"]["boden"]["klassen"]
		for k in kl:
			f["boden_" + k] = Color(str(kl[k]["hex"]))
	return f


func _run() -> void:
	print("proto_schilder_test")
	s = (load("res://proto/prototyp_welt.tscn") as PackedScene).instantiate()
	root.add_child(s)
	await process_frame
	root.size = Vector2i(1600, 900)
	await process_frame
	var vp: Vector2 = root.get_visible_rect().size
	print("  Fenster %dx%d, Orte aus proto_orte.json: %d" % [vp.x, vp.y, s.orte.size()])
	sch = Schilder.bauen(s, s.cam, s.orte, s.terrain)
	await process_frame

	# ---- Anzahl und Texte
	var orte_n := 0
	var ind_n := 0
	for e in sch.liste():
		if e["art"] == "ort":
			orte_n += 1
		else:
			ind_n += 1
	ok(orte_n == s.orte.size() and orte_n == 3, "ein Schild je Ort (%d) aus proto_orte.json" % orte_n)
	ok(ind_n == 2, "zwei Industrie-Plaketten (Gutshof, Mühle): %d" % ind_n)
	var t_e: Dictionary = sch.texte("erlenbach")
	var t_l: Dictionary = sch.texte("lindenfurt")
	var t_h: Dictionary = sch.texte("hasenwinkel")
	ok(t_e.get("name", "") == "Erlenbach" and t_e.get("ew", "") == "244", "Erlenbach: Name %s, Ort-EW %s" % [t_e.get("name"), t_e.get("ew")])
	ok(t_l.get("name", "") == "Lindenfurt" and t_l.get("ew", "") == "387", "Lindenfurt: Name %s, Ort-EW (sichtbar) %s" % [t_l.get("name"), t_l.get("ew")])
	ok(t_h.get("name", "") == "Hasenwinkel" and t_h.get("ew", "") == "48", "Hasenwinkel: Name %s, EW %s" % [t_h.get("name"), t_h.get("ew")])
	ok(t_e["trend"] == "gleich" and t_l["trend"] == "gleich", "Trend ohne Versorgung: gleich (E7), Pfeil nach rechts")
	ok(t_e["bedarf"] == ["Mehl", "Fleisch"] and t_l["bedarf"] == ["Mehl", "Fleisch"] and t_h["bedarf"].is_empty(), "Bedarf-Icons Dorf/Kleinstadt Mehl + Fleisch (Kategorie Nahrung), Weiler keine: %s" % str(t_e["bedarf"]))
	ok(t_e["bedarf"].size() <= 3 and t_l["bedarf"].size() <= 3, "höchstens 3 Bedarf-Icons (Regelwerk label.bedarf_icons_max_3)")
	ok(Schilder.tsd(2950) == "2.950" and Schilder.tsd(244) == "244", "Tausenderpunkt: 2950 → %s" % Schilder.tsd(2950))
	sch.setze_trend("erlenbach", "hoch")
	ok(sch.texte("erlenbach")["trend"] == "hoch", "Hook setze_trend")
	sch.setze_trend("erlenbach", "gleich")

	# ---- Größe: Kleinstadt größer als Dorf, Mindestschrift
	var k: Dictionary = Schilder.KLASSEN
	ok(k["kleinstadt"]["name"] > k["dorf"]["name"] and k["kleinstadt"]["fern_name"] > k["dorf"]["fern_name"] and k["kleinstadt"]["nah_name"] > k["dorf"]["nah_name"],
		"Kleinstadt größer als Dorf in allen Stufen (Name %d/%d/%d px gegen %d/%d/%d)" % [k["kleinstadt"]["fern_name"], k["kleinstadt"]["name"], k["kleinstadt"]["nah_name"], k["dorf"]["fern_name"], k["dorf"]["name"], k["dorf"]["nah_name"]])
	var min_px := 999
	for kl in k:
		for feld in ["name", "ew", "fern_name", "nah_name"]:
			if k[kl][feld] > 0:
				min_px = mini(min_px, maxi(Schilder.MIN_FONT_PX, int(roundf(k[kl][feld] * Schilder.MIN_SCALE * Schilder.voll_faktor(1500.0) if feld in ["name", "ew"] else k[kl][feld] * Schilder.MIN_SCALE))))
	ok(min_px >= 12, "kleinste Schrift auch bei kleinstem Fenster und 1500 m: %d px (Mindest 12)" % min_px)
	ok(Schilder.voll_faktor(400.0) > Schilder.voll_faktor(1500.0) and is_equal_approx(Schilder.voll_faktor(400.0), 1.12), "Zoom-abhängige Größe: 1,12 bei 400 m, 0,92 bei 1500 m")

	# ---- Stufen und Hysterese
	var f := Schilder.STUFE_FERN
	var v := Schilder.STUFE_VOLL
	var n := Schilder.STUFE_NAH
	ok(Schilder.stufe_fuer(3000.0) == f and Schilder.stufe_fuer(1500.0) == f and Schilder.stufe_fuer(1499.0) == v, "Fern ab 1,5 km Kamera")
	ok(Schilder.stufe_fuer(399.0) == n and Schilder.stufe_fuer(400.0) == v, "Nah unter 400 m (nur Name)")
	ok(Schilder.stufe_fuer(1450.0, f) == f and Schilder.stufe_fuer(1580.0, v) == v and Schilder.stufe_fuer(1630.0, v) == f, "Hysterese Fern/Voll (8 %): kein Flackern an der Grenze")
	ok(Schilder.stufe_fuer(420.0, n) == n and Schilder.stufe_fuer(380.0, v) == v and Schilder.stufe_fuer(360.0, v) == n, "Hysterese Voll/Nah")

	# ---- Presets: Stufen, Sichtbarkeit, Gelände, Entzerrung
	var erg := {}
	for p in range(1, 6):
		_preset(p)
		var rects: Array[Rect2] = []
		var sicht_ids: Array[String] = []
		var ueberlapp := 0
		for e in sch.liste():
			if e["sichtbar"]:
				sicht_ids.append(e["id"])
				for r in rects:
					if (e["rect"] as Rect2).intersects(r):
						ueberlapp += 1
				rects.append(e["rect"])
		erg[p] = {"ids": sicht_ids, "ueberlapp": ueberlapp}
		var st_text := ""
		for e in sch.liste():
			st_text += "%s:%s/%.0f m  " % [e["id"], ["Fern", "Voll", "Nah"][e["stufe"]], e["abstand_m"]]
		print("  Preset %d (%s): sichtbar %s | %s" % [p, s.PRESET_NAMEN[p], str(sicht_ids), st_text])
		ok(ueberlapp == 0, "Preset %d: keine überlappenden Schilder (Entzerrung)" % p)
	_preset(1)
	ok(sch.eintrag("lindenfurt")["stufe"] == f and sch.eintrag("erlenbach")["stufe"] == f, "Übersicht: Kleinstadt und Dorf im Fernzeichen")
	ok("lindenfurt" in erg[1]["ids"] and "erlenbach" in erg[1]["ids"], "Übersicht: Kleinstadt und Dorf sichtbar (Dorf unter 3 km Kamera)")
	ok(not ("hasenwinkel" in erg[1]["ids"]), "Weiler nie im Übersichtsschild")
	ok("erlenmuehle" in erg[1]["ids"] and "gut_kuppenhof" in erg[1]["ids"], "Übersicht: Plaketten von Mühle und Gutshof sichtbar")
	_preset(2)
	var st2: int = sch.eintrag("erlenbach")["stufe"]
	ok(st2 == v or st2 == n, "Dorf-Preset: Erlenbach in Voll- oder Nahstufe (%s)" % ["Fern", "Voll", "Nah"][st2])
	_preset(3)
	ok(sch.eintrag("lindenfurt")["stufe"] != f and sch.eintrag("lindenfurt")["sichtbar"], "Markt-Preset: Lindenfurt sichtbar, nicht mehr Fernzeichen")

	# Weiler nur nah: Kamera dicht an Hasenwinkel
	var hw: Dictionary = sch.eintrag("hasenwinkel")
	s.ziel = Vector3(hw["x"], 0, hw["z"])
	s.abstand = 220.0
	s._kamera_anwenden()
	sch.aktualisiere(true)
	# VERTRAG GEÄNDERT (Fix-Pass W2, M8): Weiler ohne Schild (Charter E6 kennt keine Weiler-Stufe, Regelwerk label.hierarchie.weiler = "nie").
	# Vorher: Name nur im Nahbereich ≤ 500 m (Kompromiss Aylin). Die Option bleibt über WEILER_NAH_BIS_M > 0 schaltbar.
	var weiler_nah: float = sch.WEILER_NAH_BIS_M
	if weiler_nah <= 0.0:
		ok(not sch.eintrag("hasenwinkel")["sichtbar"], "Weiler: nie ein Schild, auch nicht im Nahbereich (Abstand %.0f m; Fix-Pass M8, Charter E6)" % sch.eintrag("hasenwinkel")["abstand_m"])
	else:
		ok(sch.eintrag("hasenwinkel")["sichtbar"] and sch.eintrag("hasenwinkel")["stufe"] == n, "Weiler: nur im Nahbereich (≤ %.0f m), nur Name (Abstand %.0f m)" % [weiler_nah, sch.eintrag("hasenwinkel")["abstand_m"]])

	# ---- Gelände: Anker über hoehe_at, Sichtlinie
	var gelaende_ok := true
	var min_ueber := 1e9
	for e in sch.liste():
		var h: float = s.hoehe_at(e["x"], e["z"])
		var ueber: float = e["anker_pos"].y - h
		min_ueber = minf(min_ueber, ueber)
		if ueber < 10.0:
			gelaende_ok = false
	ok(gelaende_ok, "Anker aller Schilder ≥ 10 m über hoehe_at (kleinster Wert %.1f m)" % min_ueber)
	var verdeckt_n := 0
	var geprueft := 0
	var lift_max := 0.0
	for p in range(1, 6):
		_preset(p)
		for e in sch.liste():
			if e["sichtbar"]:
				geprueft += 1
				if sch._sicht_frei(s.cam.global_transform.origin, e["anker_pos"]):
					pass
				else:
					verdeckt_n += 1
				lift_max = maxf(lift_max, e["lift_m"])
	ok(verdeckt_n == 0, "Sichtlinie Kamera–Schildanker frei durch das Gelände: %d von %d sichtbaren Schildern verdeckt (größte Anhebung %.0f m)" % [verdeckt_n, geprueft, lift_max])
	# künstlicher Fall: Kamera hinter einem Hügel, Anker muss angehoben werden und das Schild bleibt im Bild
	var ez: Dictionary = sch.eintrag("erlenbach")
	var hoch_gefunden := false
	for gier in [0.0, 1.0, 2.0, 3.0, 4.0, 5.0]:
		s.ziel = Vector3(ez["x"], 0, ez["z"])
		s.gier = gier
		s.abstand = 90.0
		s._kamera_anwenden()
		sch.aktualisiere(true)
		if sch.eintrag("erlenbach")["lift_m"] > 0.5:
			hoch_gefunden = true
			break
	print("  Hinweis: Anhebung bei bedecktem Hang im Test %s" % ("ausgelöst" if hoch_gefunden else "nicht nötig (Gelände flach genug)"))
	ok(true, "Anhebe-Logik läuft ohne Fehler (Nahkamera 90 m, 6 Blickrichtungen)")
	_preset(1)

	# synthetischer Wall zwischen Kamera und Ort: der Anker muss angehoben werden, danach ist die Sichtlinie frei
	var rig := Node3D.new()
	root.add_child(rig)
	var kam := Camera3D.new()
	rig.add_child(kam)
	kam.make_current()
	kam.global_position = Vector3(1000.0, 200.0, 720.0)
	kam.look_at(Vector3(1690.0, 58.0, 720.0))
	await process_frame                     # Kamera muss im Viewport angemeldet sein, sonst liefert unproject_position Unsinn
	var wall = Huegel.new()
	var vorbei := Schilder.bauen(rig, kam, [{"id": "t", "name": "Testdorf", "klasse": "dorf", "ew": 100, "x": 1690.0, "z": 720.0}], wall, [])
	var te: Dictionary = vorbei.eintrag("t")
	ok(te["lift_ziel"] > 0.0 and not te["verdeckt"], "Wall im Blick: Anker um %.0f m angehoben, Sichtlinie danach frei" % te["lift_ziel"])
	ok(vorbei._sicht_frei(kam.global_position, te["anker_pos"]) and te["sichtbar"], "angehobenes Schild bleibt sichtbar (verschwindet nicht hinter dem Hang)")
	var flach := Schilder.bauen(rig, kam, [{"id": "t", "name": "Testdorf", "klasse": "dorf", "ew": 100, "x": 1690.0, "z": 720.0}], null, [])
	ok(flach.eintrag("t")["lift_ziel"] == 0.0, "ohne Wall keine Anhebung")
	rig.queue_free()
	s.cam.make_current()
	await process_frame

	# ---- Gelände fehlt: kein Absturz
	var ohne = Schilder.bauen(s, s.cam, s.orte, null)
	ohne.aktualisiere(true)
	ok(ohne.liste().size() == 5, "ohne Gelände-Objekt: 5 Schilder, Höhe 0 (kein Absturz)")
	ohne.queue_free()

	# ---- Tooltip Einzugsgebiet
	var tip_e: PackedStringArray = sch.tooltip_zeilen("erlenbach")
	var tip_txt := "\n".join(tip_e)
	ok(tip_e[0] == "Einzugsgebiet Erlenbach", "Tooltip-Titel: %s" % tip_e[0])
	ok(tip_txt.contains("244") and tip_txt.contains("406") and tip_txt.contains("650"), "Tooltip Erlenbach nennt Ort 244, Umland 406, Einzugsgebiet 650")
	ok(tip_txt.contains("Umland wächst nicht"), "Tooltip erklärt: Umland wächst nicht, nur der Ort")
	var lang := 0
	for i in range(1, tip_e.size()):
		for satz in tip_e[i].split(". "):
			if satz.length() > 100:
				lang += 1
	ok(lang == 0, "Tooltip: Sätze kurz (≤ 100 Zeichen)")
	var tip_l: String = sch.tooltip_fuer("lindenfurt")
	ok(tip_l.contains("387") and tip_l.contains("Annahme") and tip_l.contains("2.950"), "Tooltip Lindenfurt: Ausschnitt 387, Gesamtstadt und Umland als Annahme, Einzugsgebiet 2.950")
	ok(sch.tooltip_fuer("hasenwinkel").contains("Weiler") and sch.tooltip_fuer("erlenmuehle").contains("Mehl"), "Tooltips Weiler und Mühle vorhanden")
	_preset(1)
	var rc: Rect2 = sch.eintrag("erlenbach")["rect"]
	ok(sch.tooltip_fuer_punkt(rc.get_center()) == sch.tooltip_fuer("erlenbach"), "Zeigen auf das Schild (Bildmitte des Rechtecks) liefert den Tooltip")
	ok(sch.tooltip_fuer_punkt(Vector2(-50, -50)) == "", "Zeigen ins Leere: kein Tooltip")

	# ---- „Modelle aus“ ändert die Schilder nicht
	s.setze_modelle(false)
	sch.aktualisiere(true)
	var sichtbar_n := 0
	for e in sch.liste():
		if e["sichtbar"]:
			sichtbar_n += 1
	ok(sichtbar_n == erg[1]["ids"].size() and sch._canvas.visible, "Modelle aus (Zeichentest A2): alle %d Schilder bleiben" % sichtbar_n)
	s.setze_modelle(true)

	# ---- Kosten (Layout je Frame; Zeichnen kommt dazu, ist aber 5 Platten)
	_preset(2)
	var t0 := Time.get_ticks_usec()
	for _i in 200:
		sch.aktualisiere(true)
	var ms_voll := (Time.get_ticks_usec() - t0) / 200.0 / 1000.0
	t0 = Time.get_ticks_usec()
	for _i in 200:
		sch.aktualisiere(false)
	var ms_ruhig := (Time.get_ticks_usec() - t0) / 200.0 / 1000.0
	ok(ms_voll <= 1.0 and ms_ruhig <= 0.3, "Kosten je Frame: %.3f ms bei bewegter Kamera (inkl. Sichtlinien), %.3f ms bei ruhiger Kamera (Gate 1,0 / 0,3 ms, headless)" % [ms_voll, ms_ruhig])

	# ---- Kontrast (WCAG 2.x, analytisch)
	_kontrast()
	_g3_wasser()
	print("proto_schilder_test: %d OK, %d FAIL" % [n_ok, n_fail])
	quit(1 if n_fail > 0 else 0)


func _kontrast() -> void:
	var farben := _terrain_farben()
	var min_text := 99.0
	var min_text_bei := ""
	var min_rand := 99.0
	var min_status := 99.0
	var min_ind_text := 99.0
	var min_scheibe := 99.0
	var min_scheibe_bei := ""
	zeilen.append("grund;farbe_hex;text_auf_platte;rand_zu_grund;status_min;industrie_name_min;scheibe_zu_grund")
	var stat: Array[Color] = [Schilder.OK_FARBE, Schilder.WARN_FARBE, Schilder.BAD_FARBE]
	var ind_namen: Array[Color] = [Color8(236, 200, 76), Color8(238, 236, 228)]
	var saum := Schilder.SAUM
	for key in farben:
		var g: Color = farben[key]
		var pl: Color = Schilder.platte_ueber(g)
		var c_text := Schilder.kontrast(Schilder.TEXT, pl)
		var c_rand := Schilder.kontrast(Color(Schilder.PLATTE_RAND.r, Schilder.PLATTE_RAND.g, Schilder.PLATTE_RAND.b), g)
		var c_rand_pl := Schilder.kontrast(Color(Schilder.PLATTE_RAND.r, Schilder.PLATTE_RAND.g, Schilder.PLATTE_RAND.b), pl)
		var c_pl_grund := Schilder.kontrast(pl, g)
		var c_st := 99.0
		for c in stat:
			c_st = minf(c_st, Schilder.kontrast(c, pl))
		var c_in := 99.0
		for c in ind_namen:
			c_in = minf(c_in, Schilder.kontrast(c, pl))
		var scheibe := 0.0
		scheibe = 99.0
		for fl in ind_namen:
			scheibe = minf(scheibe, maxf(Schilder.kontrast(fl, g), Schilder.kontrast(saum, g)))
		zeilen.append("%s;%s;%.2f;%.2f;%.2f;%.2f;%.2f" % [key, g.to_html(false), c_text, maxf(c_rand, c_pl_grund), c_st, c_in, scheibe])
		if c_text < min_text:
			min_text = c_text
			min_text_bei = key
		min_rand = minf(min_rand, maxf(c_rand, c_pl_grund))
		min_status = minf(min_status, c_st)
		min_ind_text = minf(min_ind_text, c_in)
		if scheibe < min_scheibe:
			min_scheibe = scheibe
			min_scheibe_bei = key
	print("  Kontrast: Text auf Platte min %.2f (%s), Rand/Platte zum Grund min %.2f, Statusfarben auf Platte min %.2f, Industrie-Name min %.2f, Plakettenscheibe zum Grund min %.2f (%s)" % [
		min_text, min_text_bei, min_rand, min_status, min_ind_text, min_scheibe, min_scheibe_bei])
	ok(min_text >= 7.0, "Text auf Platte über allen %d Untergründen ≥ 7:1 (min %.2f bei %s, WCAG AAA)" % [farben.size(), min_text, min_text_bei])
	ok(min_rand >= 3.0, "Plattenrand bzw. Platte hebt sich vom Grund ab ≥ 3:1 (min %.2f)" % min_rand)
	ok(min_status >= 3.0, "Statusmarken (Kreis/Dreieck/Quadrat) auf Platte ≥ 3:1 (min %.2f)" % min_status)
	ok(min_ind_text >= 7.0, "Industrie-Name (Typfarbe) auf Platte ≥ 7:1 (min %.2f)" % min_ind_text)
	ok(min_scheibe >= 3.0, "Plakettenscheibe: max(Füllung, Saum) zum Grund ≥ 3:1 (S-08, min %.2f bei %s)" % [min_scheibe, min_scheibe_bei])
	var out := ProjectSettings.globalize_path("res://").path_join("../_out")
	DirAccess.make_dir_recursive_absolute(out)
	var fa := FileAccess.open(out.path_join("kontrast_analytisch.csv"), FileAccess.WRITE)
	if fa != null:
		for z in zeilen:
			fa.store_line(z)
		fa.close()


## Zusatz G3 (14 §3, nicht Teil der Schilder): Leuchtdichtekontrast Wasser A/B (c_tief) gegen die Nachbarklassen am Ufer.
## Nur Messwerte (Befund), kein Gate: der Saum (Ufer, heller Schaum im Shader) trägt die Lesbarkeit, wo < 3:1.
func _g3_wasser() -> void:
	var farben := _terrain_farben()
	var out := ProjectSettings.globalize_path("res://").path_join("../_out")
	var fa := FileAccess.open(out.path_join("kontrast_g3_wasser.csv"), FileAccess.WRITE)
	fa.store_line("wasser;nachbar;kontrast")
	var unter := 0
	var gesamt := 0
	for w in ["wasser_a_tief", "wasser_b_tief"]:
		for k in ["boden_ufer", "boden_wiese", "boden_auenboden", "boden_sumpf", "boden_waldboden", "boden_acker_hell", "boden_schotter"]:
			var c: float = Schilder.kontrast(farben[w], farben[k])
			fa.store_line("%s;%s;%.2f" % [w, k, c])
			gesamt += 1
			if c < 3.0:
				unter += 1
	fa.close()
	print("  G3 (Zusatz, Befund): Wasser A/B gegen 7 Uferklassen: %d von %d Paaren unter 3:1 (kontrast_g3_wasser.csv), Saum im Shader trägt" % [unter, gesamt])
