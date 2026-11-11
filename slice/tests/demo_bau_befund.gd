extends SceneTree
## Demo Teil 3/4: Straßen- und Gleisbau über den ECHTEN Maus-/Tastenweg durchspielen und messen.
## Teil 3 (11.11.) war der Befund am alten Werkzeug; seit Teil 4 (12.11.) prüft das Skript das neue Werkzeug (Zeilen „NACHHER …“)
## an denselben Punkten. Die Zahlen des alten Befunds stehen in DEMO_STRASSENBAU_BEFUND.md.
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --path slice -s res://tests/demo_bau_befund.gd -- --shots=<ordner>
## Jede Beobachtung ist eine Messung aus diesem Lauf (Zeile „BEFUND …“). Mausbewegung, Klicks und Tasten laufen als Ereignisse durch
## den Viewport (push_input / Input.parse_input_event), nichts ruft die Bau-Funktionen direkt. Ergebnis: sprints/s8/umsetzung/DEMO_STRASSENBAU_BEFUND.md

const SZENE := "res://proto/prototyp_welt.tscn"
const HQ := Vector2(1668, 688)
const FORST := "Forsthaus Rotwald"
const KOHLE := "Kohlegrube Schwarzgrund"
const HUETTE := "Rotachhütte"

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


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _fenster(pos: Vector2) -> Vector2:
	return root.get_final_transform() * pos


func _ruhig() -> void:
	s.rig.reset_physics_interpolation()
	s.cam.reset_physics_interpolation()
	for i in 90:
		if s.cam.get_camera_transform().origin.distance_to(s.cam.global_position) < 0.05:
			break
		await physics_frame
	await process_frame


func _kamera(x: float, z: float, abstand: float, gier := 0.0) -> void:
	s.ziel = Vector3(x, s.hoehe_at(x, z), z)
	s.abstand = abstand
	s.gier = gier
	s._kamera_anwenden()
	await _ruhig()


## Kamera so stellen, dass alle Weltpunkte im freien Bildbereich liegen (nicht unter Banner, Leiste oder der Karte unten).
func _kamera_fuer(punkte: Array, gier := 0.3) -> void:
	var m := Vector2.ZERO
	for p in punkte:
		m += p
	m /= float(punkte.size())
	var ab := 360.0
	for versuch in 10:
		await _kamera(m.x, m.y, ab, gier)
		var passt := true
		var mitte := Vector2.ZERO
		for p in punkte:
			var px := _px(p)
			mitte += px
			if px.x < 480.0 or px.x > 1480.0 or px.y < 260.0 or px.y > 700.0:
				passt = false
		if passt:
			return
		mitte /= float(punkte.size())
		if absf(mitte.y - 450.0) > 60.0 and versuch % 2 == 0:   # Schwerpunkt in die freie Bildmitte schieben
			var w = ud.boden(Vector2(800, 450))
			var z = ud.boden(mitte)
			if w is Vector2 and z is Vector2:
				m += (z as Vector2) - (w as Vector2)
				continue
		ab *= 1.2


func _px(wp: Vector2) -> Vector2:
	return s.cam.unproject_position(Vector3(wp.x, s.hoehe_at(wp.x, wp.y), wp.y))


## Maus an einen Bildpunkt bewegen (Bewegungsereignis + Zeigerposition), dann warten, bis die Vorschau nachgezogen hat.
func _maus(pos: Vector2) -> void:
	var w := _fenster(pos)
	Input.warp_mouse(w)
	var mv := InputEventMouseMotion.new()
	mv.position = w
	mv.global_position = w
	root.push_input(mv)
	await _frames(8)


func _maus_welt(wp: Vector2) -> void:
	await _maus(_px(wp))


func _klick(pos: Vector2, knopf := MOUSE_BUTTON_LEFT) -> void:
	await _maus(pos)
	var w := _fenster(pos)
	for druck in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = knopf
		ev.pressed = druck
		ev.position = w
		ev.global_position = w
		root.push_input(ev)
	await _frames(4)


func _klick_welt(wp: Vector2) -> void:
	await _klick(_px(wp))


func _taste(k: int) -> void:
	for druck in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = k
		ev.physical_keycode = k
		ev.pressed = druck
		root.push_input(ev)
	await _frames(3)


func _shot(name: String) -> void:
	ud.leiste_neu()
	uw.kopf_neu()
	await _frames(4)
	if not kann_bild:
		return
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(shots.path_join(name + ".png"))
	print("    Bild %s.png" % name)


func _letzte() -> String:
	return String(uw.meldungen_log[-1]["text"]) if not uw.meldungen_log.is_empty() else ""


func _ticks(bis: int) -> void:
	while ps.sim.tick_count < bis and not ps.konto.bankrupt:
		ps.tick()
		uw.nach_tick()


## Jeden Versuch mit leerem Werkzeug beginnen.
func _sauber() -> void:
	if ud.modus() != "":
		await _taste(KEY_ESCAPE)


func befund(nr: String, text: String) -> void:
	print("NACHHER %s: %s" % [nr, text])


func _knick(pk: PackedVector2Array) -> float:
	var k := 0.0
	for i in range(2, pk.size()):
		k = maxf(k, absf(rad_to_deg((pk[i - 1] - pk[i - 2]).angle_to(pk[i] - pk[i - 1]))))
	return k


func _abweichung(q: Dictionary, weg: int) -> float:
	var fl = ps.strassen.fahrlinien[weg]
	var a := 0.0
	for p in q["punkte"]:
		var best := INF
		for k in range(0, fl.punkte.size(), 2):
			best = minf(best, Vector2(fl.punkte[k].x, fl.punkte[k].z).distance_to(p))
		a = maxf(a, best)
	return a


func _strassenknoten() -> Array:
	var r: Array = []
	for nid in ps.knoten_grad:
		if ps.knoten_grad[nid] > 0 and not ps.gleis_knoten.has(nid):
			r.append(nid)
	return r


func _run() -> void:
	await _frames(3)
	ud = s.ui_demo
	uw = s.ui_welt
	ps = s.proto_sim
	print("demo_bau_befund (Bilder: %s, Fenster %s)" % [shots if kann_bild else "aus", str(root.get_viewport().get_visible_rect().size)])
	await _taste(KEY_SPACE)
	s.setze_tempo(0)
	await _kamera(1640, 760, 620, 0.5)
	await _klick_welt(HQ)
	if not ps.hq_platziert:
		print("ABBRUCH: Firmensitz ließ sich nicht per Mausklick setzen (%s)" % _letzte())
		quit(1)
		return
	ps.eco.cash_cent += 2000000                              # Testwerkzeug: Geld spielt für den Befund keine Rolle
	var start := Vector2(1284, 936)                          # Netzknoten südlich von Erlenbach
	var fp: Vector2 = ps.halt_pos(FORST)
	var von4 := Vector2(1330, 1100)

	# ---------------------------------------------------------------- N1 Marke und Schild vor dem ersten Klick (Befund 3)
	var leer := Vector2(1000, 1000)
	for wi in 24:
		var kand: Vector2 = von4 + Vector2(cos(TAU * wi / 24.0), sin(TAU * wi / 24.0)) * 150.0
		if String(ps.fang("strasse", kand)["typ"]) == "frei":
			leer = kand
			break
	await _kamera_fuer([start, von4, fp, leer], -0.4)
	await _taste(KEY_B)
	await _maus_welt(leer)
	var t_frei: String = ud.werte["bau_schild"]
	var m_frei: bool = ud.bau.marke.visible and ud.werte["bau_fang"] == "frei"
	await _maus_welt(start + Vector2(6, 4))
	var t_knoten: String = ud.werte["bau_schild"]
	var m_knoten: bool = ud.bau.marke.visible and ud.werte["bau_fang"] == "knoten"
	await _shot("n1_marke_vor_dem_klick")
	await _maus_welt(fp + Vector2(25, -15))
	var t_betrieb: String = ud.werte["bau_schild"]
	befund("N1", "Vor dem ersten Klick (echte Mausbewegung): freies Gelände → Marke %s, Schild „%s“; an der Straße → Marke %s, Schild „%s“; am Forsthaus → „%s“. Schild an der Maus sichtbar: %s." % [
		"sichtbar (hohl)" if m_frei else "FEHLT", t_frei, "sichtbar (voll)" if m_knoten else "FEHLT", t_knoten, t_betrieb, str(ud.bau.schild.visible)])

	# ---------------------------------------------------------------- N2 Vorschau ab dem ersten Klick, N3 eine Klickregel (Befund 1, 9, 11)
	await _taste(KEY_C)                                        # gerade
	await _klick_welt(start)
	await _maus_welt(von4)
	var q2: Dictionary = ud.bau_angebot
	var sch2: String = ud.werte["bau_schild"]
	var schild_px: Vector2 = ud.bau.schild.get_global_rect().position
	var maus_px: Vector2 = _px(von4)
	await _shot("n2_vorschau_nach_erstem_klick")
	var kasse: int = ps.eco.cash_cent
	var wege0: int = ps.bauwerke.size()
	await _klick_welt(von4)
	await _maus_welt(fp + Vector2(30, -20))
	var sch3: String = ud.werte["bau_schild"]
	await _klick_welt(fp + Vector2(30, -20))
	var nach_ziel: int = ps.bauwerke.size()
	var p_nach_ziel: int = ud.bau_punkte.size()
	befund("N2", "Nach dem ersten Klick: Punkte %d, Vorschau sichtbar: %s (Band in %.1f m Breite), Schild an der Maus „%s“, %d px von der Maus entfernt (vorher: Karte 444 px entfernt)." % [
		1, str(q2.has("punkte")), float(ps.bau_regel("strasse")["breite_m"]) + 1.5, sch2, int(schild_px.distance_to(maus_px))])
	befund("N3", "Eine Klickregel: Klick auf das einrastende Forsthaus (Schild „%s“) setzt nur den Punkt: Punkte %d, gebaut %d, Kasse %s. Vorher baute dieser Klick sofort." % [
		sch3, p_nach_ziel, nach_ziel - wege0, "unverändert" if ps.eco.cash_cent == kasse else "VERÄNDERT"])
	# N4 Rechtsklick (Befund 6)
	await _klick(_px(Vector2(1200, 1150)), MOUSE_BUTTON_RIGHT)
	var p_rechts: int = ud.bau_punkte.size()
	await _klick_welt(fp + Vector2(30, -20))
	await _maus_welt(fp + Vector2(30, -20))
	var q3: Dictionary = ps.trasse_angebot("strasse", ud.bau_punkte, {"kurve": false})
	await _shot("n3_vor_dem_bauen")
	await _taste(KEY_ENTER)
	var gebaut3: bool = ps.bauwerke.size() == wege0 + 1
	befund("N4", "Rechtsklick nimmt den letzten Punkt zurück (3 → %d). Enter baut: gebaut = %s, −%d $ (Angebot %d $), „%s“. Gebaute Mittellinie weicht höchstens %.2f m von der Vorschau ab. Danach bleibt das Werkzeug an: Modus „%s“, %d Punkt am Ende, Banner sichtbar: %s (Befund 7)." % [
		p_rechts, str(gebaut3), (kasse - ps.eco.cash_cent) / 100, int(q3["kosten_cent"]) / 100, _letzte(), _abweichung(q3, int(ps.bauwerke[-1]["weg"])) if gebaut3 else -1.0,
		ud.modus(), ud.bau_punkte.size(), str(ud.banner.visible)])
	await _klick(_px(Vector2(1200, 1150)), MOUSE_BUTTON_RIGHT)
	await _klick(_px(Vector2(1200, 1150)), MOUSE_BUTTON_RIGHT)
	befund("N4b", "Rechtsklick ohne gesetzten Punkt beendet das Werkzeug: Modus „%s“, Banner sichtbar: %s, Schild sichtbar: %s." % [ud.modus(), str(ud.banner.visible), str(ud.bau.schild.visible)])

	# ---------------------------------------------------------------- N5 Kurve (Befund 12, Bastis „keine richtigen Kurven“)
	var s2: Vector2 = ps.fang("strasse", von4)["pos"]
	var c1 := Vector2.ZERO
	var c2 := Vector2.ZERO
	for wi in 16:
		var d := Vector2(cos(TAU * wi / 16.0), sin(TAU * wi / 16.0))
		var a1 := s2 + d * 120.0
		var a2 := a1 + d.rotated(deg_to_rad(55.0)) * 120.0
		var qa: Dictionary = ps.trasse_angebot("strasse", PackedVector2Array([s2, a1, a2]), {"kurve": true})
		if qa["ok"] and int(qa["bruecke_m"]) == 0 and qa["ende"]["typ"] == "frei" and qa["kreuzungen"].is_empty():
			c1 = a1
			c2 = a2
			break
	await _kamera_fuer([s2, c1, c2], -0.4)
	await _taste(KEY_B)
	await _taste(KEY_C)                                        # Kurve
	await _klick_welt(s2)
	await _klick_welt(c1)
	await _maus_welt(c2)
	var q5: Dictionary = ud.bau_angebot
	await _shot("n5_kurve_vorschau")
	wege0 = ps.bauwerke.size()
	await _klick_welt(c2)
	var sch5: String = ud.werte["bau_schild"]
	await _klick_welt(c2)                                      # Doppelklick baut
	var gebaut5: bool = ps.bauwerke.size() == wege0 + 1
	befund("N5", "Kurve (Taste C, Banner „%s“): zweites Stück als Kreisbogen, Radius %.0f m (Minimum %d m), größter Knick zwischen zwei Punkten %.1f° bei ≤ 8 m Punktabstand. Doppelklick auf den letzten Punkt baut: %s. Gebaute Mittellinie weicht höchstens %.2f m von der Vorschau ab. Freies Ende wird angesagt: „%s“ (Befund 10)." % [
		String(ud.werte["banner"]).split(" · ")[1] if String(ud.werte["banner"]).contains(" · ") else "?", float(q5.get("r_min", 0.0)), int(ps.bau_radius("strasse")),
		_knick(q5.get("punkte", PackedVector2Array())), str(gebaut5), _abweichung(q5, int(ps.bauwerke[-1]["weg"])) if gebaut5 else -1.0, sch5])
	await _shot("n5_kurve_gebaut")
	# Weiterbauen am Ende: Richtung läuft weiter
	var c3: Vector2 = c2 + (q5["tangente"] as Vector2).rotated(deg_to_rad(-35.0)) * 110.0
	await _maus_welt(c3)
	var q5b: Dictionary = ud.bau_angebot
	var pk5: PackedVector2Array = q5b.get("punkte", PackedVector2Array())
	var anschluss := 999.0
	if pk5.size() >= 2:
		anschluss = absf(rad_to_deg((q5["tangente"] as Vector2).angle_to(pk5[1] - pk5[0])))
	befund("N5b", "Weiterbauen am neuen Ende (Werkzeug blieb an, %d Punkt): Das nächste Stück setzt in der Richtung des gebauten an, Abweichung am Anschluss %.1f°." % [ud.bau_punkte.size(), anschluss])
	await _taste(KEY_ESCAPE)

	# ---------------------------------------------------------------- N6 Fehler lokal (Befund 4, 5)
	var sk: Array = ps.see_kreise[0]
	for k in ps.see_kreise:
		if Vector2(k[0], k[1]).distance_to(s2) < Vector2(sk[0], sk[1]).distance_to(s2):
			sk = k
	var sm := Vector2(sk[0], sk[1])
	var jenseits: Vector2 = sm + (sm - s2).normalized() * (float(sk[2]) + 90.0)
	await _kamera_fuer([s2, sm, jenseits], -0.4)
	await _taste(KEY_B)
	await _taste(KEY_C)                                        # gerade
	await _klick_welt(s2)
	await _maus_welt(jenseits)
	var n_label := 0
	for c in ud.bau.marken.get_children():
		if c is Label3D:
			n_label += 1
	wege0 = ps.bauwerke.size()
	await _shot("n6_fehler_lokal_see")
	var sch6: String = ud.werte["bau_schild"]
	var rot6: int = int(ud.werte["bau_rot_punkte"])
	var ges6: int = int(ud.werte["bau_punkte_gesamt"])
	await _klick_welt(jenseits)
	await _taste(KEY_ENTER)
	befund("N6", "Trasse durch den See: %d von %d Punkten der Vorschau sind rot, der Rest grün; %d Marke mit Grund an der Stelle; Schild „%s“. Die Sperrzone der %d Seen ist im Baumodus als rote Linie gezeichnet. Enter baut nichts (gebaut %d), Meldung „%s“." % [
		rot6, ges6, n_label, sch6, int(ud.werte["bau_see_ringe"]), ps.bauwerke.size() - wege0, _letzte()])
	await _taste(KEY_ESCAPE)

	# ---------------------------------------------------------------- N7 Brücke in der Vorschau (Befund 13)
	var kn := _strassenknoten()
	var bruecke_a := Vector2.ZERO
	var bruecke_b := Vector2.ZERO
	for nid in kn:
		var a := Vector2(ps.knoten_pos[nid].x, ps.knoten_pos[nid].z)
		for wi in 16:
			var dir := Vector2(cos(TAU * wi / 16.0), sin(TAU * wi / 16.0))
			var b := a + dir * 260.0
			if ps.ist_nass(a) or ps.ist_nass(b) or ps.im_see(b):
				continue
			var q: Dictionary = ps.trasse_angebot("strasse", PackedVector2Array([a, b]), {"kurve": false})
			if q.get("ok", false) and int(q["bruecke_m"]) >= 30 and q["kreuzungen"].is_empty():
				bruecke_a = a
				bruecke_b = b
				break
		if bruecke_a != Vector2.ZERO:
			break
	if bruecke_a != Vector2.ZERO:
		await _kamera_fuer([bruecke_a, bruecke_b], 0.4)
		await _taste(KEY_B)
		await _klick_welt(bruecke_a)
		await _maus_welt(bruecke_b)
		var q7: Dictionary = ud.bau_angebot
		var pfeiler := 0
		for c in ud.bau.vorschau.get_children():
			if String(c.name).begins_with("Pfeiler"):
				pfeiler += 1
		var sch7: String = ud.werte["bau_schild"]
		await _shot("n7_bruecke_vorschau")
		kasse = ps.eco.cash_cent
		await _klick_welt(bruecke_b)
		await _taste(KEY_ENTER)
		await _frames(4)
		befund("N7", "Brücke: Vorschau hat ein eigenes Brückenband (%s) über dem Wasserspiegel, %d Pfeiler und die Aufschrift „Brücke %d m“; Schild „%s“. Gebaut: −%d $, Brücken im Straßenband: %d." % [
			"ja" if ud.bau.vorschau.has_node("Bruecke") or pfeiler > 0 else "NEIN", pfeiler, int(q7.get("bruecke_m", 0)), sch7, (kasse - ps.eco.cash_cent) / 100, ps.strassen.bruecken.size()])
		await _shot("n7_bruecke_gebaut")
		await _taste(KEY_ESCAPE)
	else:
		befund("N7", "Brücke: keine Stelle gefunden (nicht gemessen).")

	# ---------------------------------------------------------------- N8 Kreuzung wird verbunden (Befund 2)
	var nachbarn := {}
	for e in ps.sim.graph.edges.values():
		if ps.gleis_knoten.has(int(e["a"])) or ps.gleis_knoten.has(int(e["b"])):
			continue
		for paar in [[int(e["a"]), int(e["b"])], [int(e["b"]), int(e["a"])]]:
			if not nachbarn.has(paar[0]):
				nachbarn[paar[0]] = []
			if not nachbarn[paar[0]].has(paar[1]):
				nachbarn[paar[0]].append(paar[1])
	var gefunden := false
	for nid in nachbarn:
		if nachbarn[nid].size() != 2 or gefunden:
			continue
		var np := Vector2(ps.knoten_pos[nid].x, ps.knoten_pos[nid].z)
		var n1 := Vector2(ps.knoten_pos[nachbarn[nid][0]].x, ps.knoten_pos[nachbarn[nid][0]].z)
		var n2 := Vector2(ps.knoten_pos[nachbarn[nid][1]].x, ps.knoten_pos[nachbarn[nid][1]].z)
		var quer := (n2 - n1).normalized().orthogonal()
		var a_id: int = nid
		var vor: int = nachbarn[nid][0]
		for schritt in 22:
			var weiter := -1
			for nb in nachbarn.get(a_id, []):
				if nb != vor:
					weiter = nb
			if weiter < 0 or nachbarn.get(weiter, []).size() != 2:
				break
			vor = a_id
			a_id = weiter
		var ap := Vector2(ps.knoten_pos[a_id].x, ps.knoten_pos[a_id].z)
		if ap.distance_to(np) < 80.0:
			continue
		var p1: Vector2 = np + quer * 80.0
		var p2: Vector2 = np - quer * 80.0
		var qk: Dictionary = ps.trasse_angebot("strasse", PackedVector2Array([ap, p1, p2]), {"kurve": false})
		if not qk.get("ok", false) or int(qk["bruecke_m"]) > 0 or qk["kreuzungen"].is_empty() or String(qk["ende"]["typ"]) != "frei":
			continue
		var grad0: int = ps.knoten_grad[nid]
		await _kamera_fuer([ap, p1, p2], 0.3)
		await _taste(KEY_B)
		await _klick_welt(ap)
		await _klick_welt(p1)
		await _maus_welt(p2)
		var sch8: String = ud.werte["bau_schild"]
		await _shot("n8_kreuzung_vorschau")
		await _klick_welt(p2)
		await _taste(KEY_ENTER)
		await _frames(4)
		var ende_k: int = int(ps.fang("strasse", p2)["knoten"])
		var route: Array = ps.sim.graph.find_path(ende_k, nid) if ende_k >= 0 else []
		var weg_m := int(ps.sim.graph.route_length(route) / ps.mm_pro_m) if not route.is_empty() else -1
		befund("N8", "Kreuzen: Trasse quer über eine bestehende Straße. Schild in der Vorschau „%s“. Gebaut: „%s“. Vom neuen Ende zum gekreuzten Knoten sind es über das Netz %d m (Luftlinie 80 m; vorher 366 m, weil nicht verbunden). Anschlüsse des gekreuzten Knotens: %d → %d (die Verbindung liegt am nächsten Knoten der Kreuzung)." % [
			sch8, _letzte(), weg_m, grad0, ps.knoten_grad[nid]])
		await _shot("n8_kreuzung_gebaut")
		gefunden = true
		await _taste(KEY_ESCAPE)
	if not gefunden:
		befund("N8", "Kreuzen: keine passende Stelle gefunden (nicht gemessen).")

	# ---------------------------------------------------------------- N9 Planungsmodus
	var pl: Array = []
	var s9: Vector2 = ps.fang("strasse", c2)["pos"]
	for wi in 16:
		var d := Vector2(cos(TAU * wi / 16.0), sin(TAU * wi / 16.0))
		var e1 := s9 + d * 110.0
		var e2 := e1 + d.rotated(deg_to_rad(40.0)) * 110.0
		var e3 := e2 + d.rotated(deg_to_rad(80.0)) * 110.0
		var qa: Dictionary = ps.trasse_angebot("strasse", PackedVector2Array([s9, e1]), {"kurve": true})
		var qb: Dictionary = ps.trasse_angebot("strasse", PackedVector2Array([e1, e2]), {"kurve": true, "plan_enden": [e1], "t0": qa.get("tangente", null)})
		var qc: Dictionary = ps.trasse_angebot("strasse", PackedVector2Array([e2, e3]), {"kurve": true, "plan_enden": [e2], "t0": qb.get("tangente", null)})
		if qa["ok"] and qb.get("ok", false) and qc.get("ok", false) and int(qa["bruecke_m"]) + int(qb["bruecke_m"]) + int(qc["bruecke_m"]) == 0 and qa["ende"]["typ"] == "frei" and qc["ende"]["typ"] == "frei":
			pl = [e1, e2, e3]
			break
	if pl.is_empty():
		befund("N9", "Plan: keine freie Stelle für drei Abschnitte gefunden (nicht gemessen).")
	else:
		await _kamera_fuer([s9, pl[0], pl[1], pl[2]], -0.3)
		await _taste(KEY_B)
		await _taste(KEY_P)
		kasse = ps.eco.cash_cent
		wege0 = ps.bauwerke.size()
		await _klick_welt(s9)
		for i in 3:
			await _maus_welt(pl[i])
			await _klick_welt(pl[i])
			await _taste(KEY_ENTER)
		var n_plan: int = ud.bau.plan.size()
		var summe: int = ud.bau.plan_kosten()
		var geist: int = ud.bau.plan_wurzel.get_child_count()
		await _shot("n9_plan_drei_abschnitte")
		var unberuehrt: bool = ps.eco.cash_cent == kasse and ps.bauwerke.size() == wege0
		# Abschnitt 3 verwerfen (Mausklick auf ✕), dann „Plan bauen“ (Mausklick)
		var bw: Button = ud.knoepfe.get("plan_weg_2")
		if bw != null and is_instance_valid(bw):
			await _klick(bw.get_global_rect().get_center())
		var n_nach: int = ud.bau.plan.size()
		var summe2: int = ud.bau.plan_kosten()
		var bb: Button = ud.knoepfe.get("plan_bauen")
		if bb != null and is_instance_valid(bb):
			await _klick(bb.get_global_rect().get_center())
		await _frames(4)
		befund("N9", "Planen (Taste P, Banner zeigt „planen“): drei Abschnitte per Klick und Enter abgelegt: %d im Plan, %d Blaupausen in der Welt, Summe %d $; Kasse und Netz dabei unverändert: %s. Abschnitt 3 per Mausklick verworfen: %d im Plan, Summe %d $. „Plan bauen“ per Mausklick: gebaut %d Abschnitte, −%d $, Plan danach %d, Meldung „%s“." % [
			n_plan, geist, summe / 100, str(unberuehrt), n_nach, summe2 / 100, ps.bauwerke.size() - wege0, (kasse - ps.eco.cash_cent) / 100, ud.bau.plan.size(), _letzte()])
		await _shot("n9_plan_gebaut")
		await _taste(KEY_P)
		await _taste(KEY_ESCAPE)

	# ---------------------------------------------------------------- N10 Karte verdeckt die Bildmitte nicht mehr (Befund 8)
	await _taste(KEY_B)
	await _frames(4)
	var kr: Rect2 = ud.modus_panel.get_global_rect()
	var br: Rect2 = ud.banner.get_global_rect()
	var bild: Vector2 = root.get_viewport().get_visible_rect().size
	befund("N10", "Karte „Straße bauen“ liegt jetzt links unter der Werkzeugleiste (%d, %d, %d × %d px), das Banner oben (%d × %d px): zusammen %.1f %% des Bildes (vorher 12,1 %%). Die Bildmitte und der untere Rand sind frei: Karte überdeckt die Bildmitte: %s." % [
		int(kr.position.x), int(kr.position.y), int(kr.size.x), int(kr.size.y), int(br.size.x), int(br.size.y), (kr.get_area() + br.get_area()) * 100.0 / (bild.x * bild.y),
		"ja" if kr.has_point(bild * 0.5) else "nein"])
	await _taste(KEY_ESCAPE)

	# ---------------------------------------------------------------- N11 Gleis mit Bogen
	_ticks(7200)
	await _frames(2)
	s.setze_tempo(0)
	var kp: Vector2 = ps.halt_pos(KOHLE)
	var hp: Vector2 = ps.halt_pos(HUETTE)
	await _kamera_fuer([kp, hp, (kp + hp) * 0.5 + Vector2(0, -120)], 0.2)
	await _taste(KEY_G)
	await _klick_welt(kp)
	var g0: Vector2 = ud.bau_punkte[0] if ud.bau_punkte.size() > 0 else kp
	var eng_p: Vector2 = g0 + (hp - g0).normalized() * 60.0
	await _klick_welt(eng_p)
	await _maus_welt(eng_p + (hp - g0).normalized().rotated(deg_to_rad(80.0)) * 40.0)
	var sch11: String = ud.werte["bau_schild"]
	var rot11: int = int(ud.werte["bau_rot_punkte"])
	var ges11: int = int(ud.werte["bau_punkte_gesamt"])
	await _shot("n11_gleis_bogen_zu_eng")
	await _klick(_px(eng_p), MOUSE_BUTTON_RIGHT)
	var mitte11: Vector2 = (g0 + hp) * 0.5 + (hp - g0).normalized().orthogonal() * 60.0
	await _klick_welt(mitte11)
	await _maus_welt(hp)
	var q11: Dictionary = ud.bau_angebot
	await _shot("n11_gleis_bogen")
	kasse = ps.eco.cash_cent
	await _klick_welt(hp)
	await _taste(KEY_ENTER)
	befund("N11", "Gleis (Taste G, Kurve): enger Bogen wird nur dort rot (%d von %d Punkten), Schild „%s“. Mit weitem Bogen über einen Zwischenpunkt zur Hütte: Angebot ok = %s, kleinster Radius %.0f m (Minimum %d m), größter Knick %.1f°. Enter: Bahnhöfe %d, −%d $, „%s“." % [
		rot11, ges11, sch11, str(q11.get("ok", false)), float(q11.get("r_min", 0.0)), int(ps.bau_radius("gleis")), _knick(q11.get("punkte", PackedVector2Array())),
		ps.bahnhof.size(), (kasse - ps.eco.cash_cent) / 100, _letzte()])
	await _shot("n11_gleis_gebaut")
	await _taste(KEY_ESCAPE)

	# ---------------------------------------------------------------- N12 Kamera beim Bauen (unverändert gut)
	await _kamera_fuer([start, Vector2(1220, 1000)], -0.3)
	await _taste(KEY_B)
	await _klick_welt(start)
	var ziel0: Vector3 = s.ziel
	var von := _px(Vector2(1150, 1080))
	await _maus(von)
	var dn := InputEventMouseButton.new()
	dn.button_index = MOUSE_BUTTON_LEFT
	dn.pressed = true
	dn.position = _fenster(von)
	dn.global_position = dn.position
	root.push_input(dn)
	for i in 7:
		var mv := InputEventMouseMotion.new()
		mv.position = _fenster(von + Vector2(20.0 * (i + 1), 0))
		mv.global_position = mv.position
		mv.relative = Vector2(20, 0)
		mv.button_mask = MOUSE_BUTTON_MASK_LEFT
		root.push_input(mv)
		await _frames(1)
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = _fenster(von + Vector2(140, 0))
	up.global_position = up.position
	root.push_input(up)
	await _frames(4)
	await _ruhig()
	befund("N12", "Kamera beim Bauen: Ziehen mit der linken Taste (140 px) schiebt die Kamera um %.0f m und setzt keinen Punkt (Punkte %d). Ziehen mit der rechten Taste dreht weiter die Kamera und nimmt keinen Punkt zurück (nur der Klick ohne Ziehen)." % [
		Vector2(s.ziel.x - ziel0.x, s.ziel.z - ziel0.z).length(), ud.bau_punkte.size()])
	await _taste(KEY_ESCAPE)
	print("demo_bau_befund fertig, Sim-Fehler: %s" % str(ps.fehler))
	quit(0)
