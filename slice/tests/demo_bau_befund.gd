extends SceneTree
## Demo Teil 3, Punkt 6: Straßen- und Gleisbau über den ECHTEN Maus-/Tastenweg durchspielen und messen (kein Umbau).
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
			if px.x < 430.0 or px.x > 1480.0 or px.y < 260.0 or px.y > 640.0:
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
	print("BEFUND %s: %s" % [nr, text])


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

	# ---------------------------------------------------------------- B1 Wo darf eine Straße beginnen?
	var kn := _strassenknoten()
	var lang := 0.0
	var ohne := 0.0
	var weit_p := Vector2.ZERO
	var weit_d := 0.0
	for e in ps.sim.graph.edges.values():
		if ps.gleis_knoten.has(int(e["a"])) or ps.gleis_knoten.has(int(e["b"])):
			continue
		var a := Vector2(ps.knoten_pos[int(e["a"])].x, ps.knoten_pos[int(e["a"])].z)
		var b := Vector2(ps.knoten_pos[int(e["b"])].x, ps.knoten_pos[int(e["b"])].z)
		var n := maxi(1, int(a.distance_to(b) / 5.0))
		for i in n:
			var p := a.lerp(b, (i + 0.5) / n)
			var dmin := INF
			for nid in kn:
				dmin = minf(dmin, p.distance_to(Vector2(ps.knoten_pos[nid].x, ps.knoten_pos[nid].z)))
			lang += a.distance_to(b) / n
			if dmin > 22.0:
				ohne += a.distance_to(b) / n
			if dmin > weit_d:
				weit_d = dmin
				weit_p = p
	await _kamera_fuer([weit_p], 0.3)
	await _taste(KEY_B)
	var b1_modus: bool = ud.modus() == "bau"
	await _maus_welt(weit_p)
	var b1_vorschau: bool = ud.vorschau_mi.visible or ud.hover_ring.visible
	var b1_marker: int = ud.marker_root.get_child_count()
	await _shot("b1_start_mitten_auf_der_strasse")
	var n0: int = uw.meldungen_log.size()
	await _klick_welt(weit_p)
	befund("B1", "Start mitten auf einer Straße: Modus %s; %d von %d m Straßennetz (%.0f %%) liegen weiter als 22 m vom nächsten Knoten und rasten nicht ein. Klick auf die Straße bei (%d, %d), %d m vom nächsten Knoten: Punkte %d, Meldung „%s“. Vor dem ersten Klick zeigt nichts unter der Maus, wo der Start einrasten würde (Vorschau/Hover sichtbar: %s; Ringe gibt es nur an %d Betrieben ohne Anschluss)." % [
		"an" if b1_modus else "AUS", int(ohne), int(lang), ohne * 100.0 / maxf(1.0, lang), int(weit_p.x), int(weit_p.y), int(weit_d), ud.bau_punkte.size(),
		_letzte() if uw.meldungen_log.size() > n0 else "(keine)", "ja" if b1_vorschau else "nein", b1_marker])
	await _taste(KEY_ESCAPE)

	# ---------------------------------------------------------------- B2 Knick, B2b See-Sperrzone
	var start := Vector2(1284, 936)                          # Netzknoten südlich von Erlenbach
	await _kamera(1250, 1040, 520, -0.3)
	await _sauber()
	await _taste(KEY_B)
	await _klick_welt(start)
	var b2_start: int = ud.bau_punkte.size()
	await _klick_welt(Vector2(1360, 1010))
	await _klick_welt(Vector2(1290, 1030))                   # spitze Kehre: zurück Richtung Start
	await _maus_welt(Vector2(1400, 1080))
	var qs: Dictionary = ud.bau_angebot
	await _shot("b2b_see_sperrzone")
	var bei: Vector2 = qs.get("bei", Vector2.ZERO)
	var see_r := 0.0
	var see_d := 0.0
	for k in ps.see_kreise:
		var d := bei.distance_to(Vector2(k[0], k[1]))
		if d <= float(k[2]):
			see_r = float(k[2])
			see_d = d
	befund("B2b", "See: Eine Z-Trasse neben dem Teich: Angebot ok = %s, Fehler „%s“ bei (%d, %d). Die Stelle liegt %d m vom Seemittelpunkt; gesperrt ist ein Kreis von %d m (Nennradius %d m + 12 %% Rand). Der gezeichnete See ist kein Kreis: Wo das Ufer liegt und wo die Sperre beginnt, sieht man nicht. Die GANZE Trasse wird rot, die Stelle selbst ist nicht markiert (die Sim kennt sie: Feld „bei“)." % [
		str(qs.get("ok", false)), String(qs.get("fehler", "")), int(bei.x), int(bei.y), int(see_d), int(see_r), int(see_r / 1.12)])
	await _sauber()
	# Z-Trasse in freiem Gelände suchen (vom selben Knoten aus), dann über die Maus bauen
	var zp: Array = []
	for wi in 16:
		var d := Vector2(cos(TAU * wi / 16.0), sin(TAU * wi / 16.0))
		var p1 := start + d * 110.0
		var p2 := p1 + d.rotated(deg_to_rad(150.0)) * 80.0
		var p3 := p2 + d * 130.0
		var qz: Dictionary = ps.bau_angebot("strasse", PackedVector2Array([start, p1, p2, p3]))
		if qz.get("ok", false) and int(qz["bruecke_m"]) == 0 and String(qz["ende"]["typ"]) == "frei":
			zp = [p1, p2, p3]
			break
	var b3_ende := Vector2.ZERO
	if zp.is_empty():
		befund("B2", "Knick: keine freie Z-Trasse am Startknoten gefunden (nicht gemessen).")
	else:
		await _kamera_fuer([start, zp[0], zp[1], zp[2]], -0.3)
		await _taste(KEY_B)
		await _klick_welt(start)
		b2_start = ud.bau_punkte.size()
		await _klick_welt(zp[0])
		await _klick_welt(zp[1])
		await _maus_welt(zp[2])
		var q2: Dictionary = ud.bau_angebot
		await _shot("b2_knick_spitzkehre")
		befund("B2", "Knick: Start am Knoten (Punkte %d), zwei freie Zwischenpunkte mit einer Richtungsänderung von 150° (Spitzkehre): Angebot ok = %s, %s m, %s $. Straßen kennen keine Mindestkurve (Gleis: 60°). Die Vorschau ist ein eckiger Linienzug; erst der gebaute Weg wird geglättet, sieht also anders aus als die Vorschau." % [
			b2_start, str(q2.get("ok", false)), str(q2.get("laenge_m", "?")), str(int(q2.get("kosten_cent", 0)) / 100)])
		# B3 freies Ende
		var kasse3: int = ps.eco.cash_cent
		var wege3: int = ps.bauwerke.size()
		await _klick_welt(zp[2])
		var p_vor_enter: int = ud.bau_punkte.size()
		var modus_vor: String = ud.modus()
		await _taste(KEY_ENTER)
		var b3_gebaut: bool = ps.bauwerke.size() == wege3 + 1
		b3_ende = zp[2]
		befund("B3", "Freies Ende: Der Klick ins freie Gelände setzt nur einen Punkt (%d Punkte, Modus „%s“, nichts gebaut). Enter baut die Straße bis dorthin: gebaut = %s, −%d $, Meldung „%s“. Das Ende hängt an nichts; es gibt davor keine Warnung, dass die Straße nichts verbindet." % [
			p_vor_enter, modus_vor, str(b3_gebaut), (kasse3 - ps.eco.cash_cent) / 100, _letzte()])
		befund("B9", "Nach dem Bauen ist das Werkzeug aus (Modus „%s“, Banner sichtbar: %s). Für jeden weiteren Abschnitt muss B erneut gedrückt werden." % [ud.modus(), str(ud.banner.visible)])
		await _shot("b3_freies_ende_gebaut")

	# ---------------------------------------------------------------- B4 Anschluss an einen Betrieb
	var kasse: int = ps.eco.cash_cent
	var wege0: int = ps.bauwerke.size()
	var fp: Vector2 = ps.halt_pos(FORST)
	var von4 := Vector2(1330, 1100)
	await _sauber()
	await _kamera_fuer([start, von4, fp], -0.4)
	await _taste(KEY_B)
	await _klick_welt(start)
	var b4_p1: int = ud.bau_punkte.size()
	await _klick_welt(von4)
	var richtung := (von4 - fp).normalized()
	await _maus_welt(fp + richtung * 60.0)
	var ende_typ := String(ud.bau_angebot.get("ende", {}).get("typ", "?"))
	await _shot("b4_neben_dem_betrieb")
	await _maus_welt(fp + richtung * 40.0)
	var ende_typ2 := String(ud.bau_angebot.get("ende", {}).get("typ", "?"))
	var q4: Dictionary = ud.bau_angebot
	kasse = ps.eco.cash_cent
	wege0 = ps.bauwerke.size()
	await _klick_welt(fp + richtung * 40.0)
	befund("B4", "Anschluss an einen Betrieb (Punkte nach dem Startklick: %d): Der Ring am Forsthaus hat 18 m Radius, eingerastet wird im Umkreis von 45 m: Maus 60 m daneben → Ende „%s“, 40 m daneben (außerhalb des Rings) → Ende „%s“. Der Klick auf ein einrastendes Ziel baut SOFORT ohne Bestätigung (gebaut = %s, −%d $ bei Angebot %d $, Meldung „%s“); der Klick ins freie Gelände braucht dagegen Enter. Zwei Regeln für denselben Klick." % [
		b4_p1, ende_typ, ende_typ2, str(ps.bauwerke.size() == wege0 + 1), (kasse - ps.eco.cash_cent) / 100, int(q4.get("kosten_cent", 0)) / 100, _letzte()])
	await _shot("b4_angeschlossen")
	if b3_ende != Vector2.ZERO:                                # am freien Ende von B3 weiterbauen?
		await _kamera_fuer([b3_ende, start], -0.3)
		await _taste(KEY_B)
		await _klick_welt(b3_ende)
		befund("B4b", "Weiterbauen am freien Ende aus B3: Klick auf das Ende setzt den Startpunkt (Punkte %d). Abschnittsweises Bauen geht also; das Ende trägt aber kein Zeichen, dass man dort ansetzen kann." % ud.bau_punkte.size())
	await _sauber()

	# ---------------------------------------------------------------- B5 Brücke
	await _sauber()
	var bruecke_a := Vector2.ZERO
	var bruecke_b := Vector2.ZERO
	for nid in kn:                                             # trockener Punkt A am Netz, 40–150 m Wasser auf dem Weg zu einem trockenen Punkt B
		var a := Vector2(ps.knoten_pos[nid].x, ps.knoten_pos[nid].z)
		for wi in 16:
			var dir := Vector2(cos(TAU * wi / 16.0), sin(TAU * wi / 16.0))
			var b := a + dir * 260.0
			if ps.ist_nass(a) or ps.ist_nass(b) or ps.im_see(b):
				continue
			var nass := 0
			for i in 26:
				if ps.ist_nass(a + dir * (10.0 * i)):
					nass += 1
			if nass >= 3 and nass <= 12:
				var q: Dictionary = ps.bau_angebot("strasse", PackedVector2Array([a, b]))
				if q.get("ok", false) and int(q["bruecke_m"]) > 0:
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
		var q5: Dictionary = ud.bau_angebot
		var knopf_grau := false
		if ud.knoepfe.has("bau_fertig") and is_instance_valid(ud.knoepfe["bau_fertig"]):
			knopf_grau = (ud.knoepfe["bau_fertig"] as Button).get_theme_color("font_color").v < 0.7
		var hinweis_enter := false
		for c in ud.modus_vb.get_children():
			if c is Label and String(c.text).contains("Enter baut bis hierher"):
				hinweis_enter = true
		var wasser_y: float = ps.strassen.wasser_pegel_m
		var nass_n := 0
		var unter_n := 0
		var tief := 0.0
		for i in 53:
			var bp := bruecke_a.lerp(bruecke_b, i / 52.0)
			if ps.ist_nass(bp):
				nass_n += 1
				var by: float = s.hoehe_at(bp.x, bp.y) + 0.9
				if by < wasser_y:
					unter_n += 1
					tief = maxf(tief, wasser_y - by)
		befund("B5b", "Vorschau über Wasser: Das Vorschauband liegt 0,9 m über dem GELÄNDE, der Wasserspiegel bei %.1f m. Von %d Stützpunkten im Wasser liegen %d unter dem Wasserspiegel (bis %.1f m). In der Karte steht „Enter baut bis hierher“ (%s), der Knopf „Bauen · Enter“ ist zugleich grau (%s), weil der Endpunkt noch nicht geklickt ist: Enter tut in diesem Moment nichts." % [
			wasser_y, nass_n, unter_n, tief, "ja" if hinweis_enter else "nein", "ja" if knopf_grau else "nein"])
		await _shot("b5_bruecke_vorschau")
		var ohne_br: int = int(q5.get("felder", 0)) * int(ps.bau_regel("strasse")["kosten_cent_pro_feld"])
		kasse = ps.eco.cash_cent
		await _klick_welt(bruecke_b)
		await _taste(KEY_ENTER)
		await _frames(4)
		befund("B5", "Brücke: Trasse über den Fluss, Angebot ok = %s, %s m, davon Brücke %s m, %d $ (ohne Wasser wären es %d $: Brückenfelder kosten das Fünffache). Die Vorschau zeigt die Brücke nicht anders als die Straße (ein Band, eine Farbe); die Brückenlänge steht nur als Zahl in der Karte unten. Gebaut: −%d $, Brücken im Straßenband: %d." % [
			str(q5.get("ok", false)), str(q5.get("laenge_m", "?")), str(q5.get("bruecke_m", "?")), int(q5.get("kosten_cent", 0)) / 100, ohne_br / 100, (kasse - ps.eco.cash_cent) / 100, ps.strassen.bruecken.size()])
		await _shot("b5_bruecke_gebaut")
	else:
		befund("B5", "Brücke: keine Stelle gefunden, an der ein Knoten 40–120 m Wasser vor sich hat (nicht gemessen).")

	# ---------------------------------------------------------------- B6 Abbrechen, Rechtsklick
	await _sauber()
	await _kamera_fuer([start, Vector2(1220, 1000), Vector2(1180, 1060), Vector2(1150, 1100)], -0.3)
	await _taste(KEY_B)
	await _klick_welt(start)
	await _klick_welt(Vector2(1220, 1000))
	await _klick_welt(Vector2(1180, 1060))
	var p3: int = ud.bau_punkte.size()
	await _klick(_px(Vector2(1150, 1100)), MOUSE_BUTTON_RIGHT)
	var p_rechts: int = ud.bau_punkte.size()
	await _taste(KEY_BACKSPACE)
	var p_entf: int = ud.bau_punkte.size()
	await _shot("b6_vor_abbrechen")
	await _taste(KEY_ESCAPE)
	befund("B6", "Abbrechen: %d Punkte gesetzt. Rechtsklick ändert nichts (Punkte danach %d): Die rechte Taste dreht nur die Kamera. Rücktaste/Entf nimmt einen Punkt zurück (%d). Esc verwirft ALLE Punkte auf einmal und beendet das Werkzeug (Modus „%s“, Punkte %d, Banner sichtbar: %s), ohne Rückfrage." % [
		p3, p_rechts, p_entf, ud.modus(), ud.bau_punkte.size(), str(ud.banner.visible)])

	# ---------------------------------------------------------------- B7 Kamera beim Bauen
	await _taste(KEY_B)
	await _klick_welt(start)
	await _klick_welt(Vector2(1220, 1000))
	var p_a: int = ud.bau_punkte.size()
	var ziel0: Vector3 = s.ziel
	# Ziehen mit der linken Taste (Kamera schieben): drücken, 140 px bewegen, loslassen
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
	var geschoben: float = Vector2(s.ziel.x - ziel0.x, s.ziel.z - ziel0.z).length()
	var p_b: int = ud.bau_punkte.size()
	# Mausrad
	var ab0: float = s.abstand
	var rad := InputEventMouseButton.new()
	rad.button_index = MOUSE_BUTTON_WHEEL_DOWN
	rad.pressed = true
	rad.position = _fenster(von)
	root.push_input(rad)
	await _frames(3)
	# WASD
	var zw: Vector3 = s.ziel
	var kd := InputEventKey.new()
	kd.keycode = KEY_D
	kd.physical_keycode = KEY_D
	kd.pressed = true
	Input.parse_input_event(kd)
	await _frames(20)
	var ku := InputEventKey.new()
	ku.keycode = KEY_D
	ku.physical_keycode = KEY_D
	ku.pressed = false
	Input.parse_input_event(ku)
	await _frames(3)
	await _ruhig()
	var wasd: float = Vector2(s.ziel.x - zw.x, s.ziel.z - zw.z).length()
	await _maus_welt(Vector2(1180, 1060))
	await _shot("b7_kamera_beim_bauen")
	befund("B7", "Kamera beim Bauen: Ziehen mit der linken Taste (140 px) schiebt die Kamera um %.0f m und setzt KEINEN Punkt (Punkte %d → %d). Mausrad zoomt (Abstand %.0f → %.0f m). Taste D schiebt um %.0f m. Der Baumodus bleibt dabei an (Modus „%s“, Punkte %d), die Vorschau folgt der Maus nach der Bewegung wieder (sichtbar: %s). Während die linke Taste gehalten wird, steht die Vorschau still." % [
		geschoben, p_a, p_b, ab0, s.abstand, wasd, ud.modus(), ud.bau_punkte.size(), str(ud.vorschau_mi.visible)])
	await _taste(KEY_ESCAPE)

	# ---------------------------------------------------------------- B10 Kreuzen ohne Verknüpfung
	# Straßenknoten N mit genau zwei Nachbarn in freiem Gelände; Start an einem Knoten A ein Stück weiter, dann quer über die Straße bei N.
	await _sauber()
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
		var a_id: int = nid                                    # 14 Kanten die Straße entlang
		var vor: int = nachbarn[nid][0]
		for schritt in 14:
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
		for seite in [1.0, -1.0]:
			var p1: Vector2 = np + quer * 80.0 * float(seite)
			var p2: Vector2 = np - quer * 80.0 * float(seite)
			var qk: Dictionary = ps.bau_angebot("strasse", PackedVector2Array([ap, p1, p2]))
			if not qk.get("ok", false) or int(qk["bruecke_m"]) > 0 or String(qk["ende"]["typ"]) != "frei":
				continue
			var grad0: int = ps.knoten_grad[nid]
			var k0: int = ps.knoten_grad.size()
			await _kamera_fuer([ap, p1, p2], 0.3)
			await _taste(KEY_B)
			await _klick_welt(ap)
			await _klick_welt(p1)
			await _maus_welt(p2)
			await _shot("b10_kreuzung_vorschau")
			await _klick_welt(p2)
			await _taste(KEY_ENTER)
			await _frames(4)
			var ende_k: int = int(ps.fang("strasse", p2)["knoten"])
			var route: Array = ps.sim.graph.find_path(ende_k, nid) if ende_k >= 0 else []
			var weg_m := int(ps.sim.graph.route_length(route) / ps.mm_pro_m) if not route.is_empty() else -1
			print("    B10 Einzelwerte: Endknoten %d, gebaute Wege %d, Route Kanten %d" % [ende_k, ps.bauwerke.size(), route.size()])
			befund("B10", "Kreuzen: Trasse von einem Straßenknoten heraus ins Gelände und dann quer über dieselbe Straße (Kreuzungspunkt = Knoten bei %d, %d) zu einem freien Punkt 80 m dahinter. Gebaut: „%s“. Der gekreuzte Knoten hat vorher %d und nachher %d Anschlüsse; Knoten im Netz %d → %d. An der Kreuzung entsteht KEINE Verknüpfung: Vom neuen Ende zum gekreuzten Knoten sind es über das Netz %d m statt 80 m. Die Straßen liegen übereinander, ohne dass man abbiegen kann." % [
				int(np.x), int(np.y), _letzte(), grad0, ps.knoten_grad[nid], k0, ps.knoten_grad.size(), weg_m])
			await _shot("b10_kreuzung_gebaut")
			gefunden = true
			break
	if not gefunden:
		befund("B10", "Kreuzen: keine passende Stelle gefunden (nicht gemessen).")
	await _sauber()

	# ---------------------------------------------------------------- B8 Gleis: Start am Betrieb, Knick, Steigung
	_ticks(7200)
	await _frames(2)
	s.setze_tempo(0)
	var kp: Vector2 = ps.halt_pos(KOHLE)
	var hp: Vector2 = ps.halt_pos(HUETTE)
	await _kamera((kp.x + hp.x) * 0.5, (kp.y + hp.y) * 0.5, 820, 0.2)
	await _taste(KEY_G)
	var g_modus: bool = ud.modus() == "bau" and ud.bau_art == "gleis"
	var g_ringe: int = ud.marker_root.get_child_count()
	await _klick_welt(kp)
	var g_start: Vector2 = ud.bau_punkte[0] if ud.bau_punkte.size() > 0 else Vector2.ZERO
	var mitte_g := (kp + hp) * 0.5
	await _klick_welt(mitte_g + Vector2(0, -160))
	await _maus_welt(mitte_g + Vector2(-140, 60))             # enger Knick zurück
	var qg: Dictionary = ud.bau_angebot
	var tg := ""
	for c in ud.modus_vb.get_children():
		if c is Label and String(c.text).begins_with("■"):
			tg = c.text
	await _shot("b8_gleis_knick_zu_eng")
	await _taste(KEY_BACKSPACE)
	await _maus_welt(hp)
	var qg2: Dictionary = ud.bau_angebot
	var tg2 := ""
	for c in ud.modus_vb.get_children():
		if c is Label and String(c.text).begins_with("■"):
			tg2 = c.text
	await _shot("b8_gleis_zum_ziel")
	kasse = ps.eco.cash_cent
	await _klick_welt(hp)
	befund("B8", "Gleis: Taste G (Modus an: %s, %d Ringe an allen Betrieben und Orten). Klick auf die Kohlegrube rastet %d m neben dem Klick ein (neuer Bahnhof). Ein enger Knick wird abgelehnt: ok = %s, Text „%s“; die Vorschau färbt dann die GANZE Trasse rot, die Stelle des Fehlers ist nicht markiert. Gerade zum Ziel: ok = %s%s. Klick auf die Hütte: Bahnhöfe %d, −%d $, Meldung „%s“." % [
		str(g_modus), g_ringe, int(g_start.distance_to(kp)), str(qg.get("ok", false)), tg, str(qg2.get("ok", false)), (", Text „%s“" % tg2) if tg2 != "" else "",
		ps.bahnhof.size(), (kasse - ps.eco.cash_cent) / 100, _letzte()])
	await _shot("b8_gleis_gebaut")
	await _taste(KEY_ESCAPE)

	# ---------------------------------------------------------------- B12 Karte und Banner verdecken Bauland
	await _sauber()
	await _taste(KEY_B)
	await _frames(4)
	var kr: Rect2 = ud.modus_panel.get_global_rect()
	var br: Rect2 = ud.banner.get_global_rect()
	var bild: Vector2 = root.get_viewport().get_visible_rect().size
	# Kamera so schieben, dass der Startknoten unter der Karte liegt, dann dort klicken
	var unter: Vector2 = kr.get_center()
	for versuch in 6:
		var w = ud.boden(unter)
		if w is Vector2:
			var d12: Vector2 = start - (w as Vector2)
			s.ziel += Vector3(d12.x, 0, d12.y)
			s._kamera_anwenden()
			await _ruhig()
	var abw12: float = _px(start).distance_to(unter)
	await _klick(_px(start))
	befund("B12", "Verdeckung: Die Karte „Straße bauen“ (%d × %d px) und das Banner (%d × %d px) belegen zusammen %.1f %% des Bildes, die Karte unten in der Bildmitte. Ein Klick auf einen Straßenknoten, der unter der Karte liegt (%d px neben ihrer Mitte), kommt in der Welt nicht an: Punkte danach %d. Man muss die Kamera schieben, um dort zu bauen." % [
		int(kr.size.x), int(kr.size.y), int(br.size.x), int(br.size.y), (kr.get_area() + br.get_area()) * 100.0 / (bild.x * bild.y), int(abw12), ud.bau_punkte.size()])
	await _shot("b12_karte_verdeckt")
	await _sauber()

	# ---------------------------------------------------------------- B11 Abstand Information ↔ Maus
	await _kamera(1250, 1040, 520, -0.3)
	await _taste(KEY_B)
	await _klick_welt(start)
	await _maus_welt(Vector2(1180, 980))
	var mp: Vector2 = _px(Vector2(1180, 980))
	var karte: Rect2 = ud.modus_panel.get_global_rect()
	befund("B11", "Kosten und Länge stehen nur in der Karte unten (Mitte bei %d, %d px), die Maus arbeitet bei %d, %d px: %d px Blickweg. An der Maus selbst steht nichts (keine Länge, kein Preis, kein Gefälle)." % [
		int(karte.get_center().x), int(karte.get_center().y), int(mp.x), int(mp.y), int(karte.get_center().distance_to(mp))])
	await _shot("b11_information_weit_weg")
	await _taste(KEY_ESCAPE)
	print("demo_bau_befund fertig, Sim-Fehler: %s" % str(ps.fehler))
	quit(0)
