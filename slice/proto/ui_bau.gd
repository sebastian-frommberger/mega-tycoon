extends RefCounted
## Demo Teil 4: Bauwerkzeug für Straße und Gleis (Vorbild Transport Fever 2 / Cities: Skylines). Gehört zu ui_demo.gd (ud).
##
## Regeln (Bastis Feedback 12.11. und Befund DEMO_STRASSENBAU_BEFUND.md):
##  · Schon vor dem ersten Klick zeigt eine Marke unter der Maus, wo und woran der Start einrastet.
##  · Nach dem ersten Klick liegt die Trasse bis zur Maus als Vorschau in Straßenbreite da; Länge und Preis stehen an der Maus.
##  · EINE Klickregel: Klick setzt einen Punkt, nie mehr. Gebaut wird mit Enter, Doppelklick auf den letzten Punkt oder dem Knopf.
##  · Rechtsklick nimmt den letzten Punkt zurück (ohne Punkt: Werkzeug aus), Esc beendet. Nach dem Bau bleibt das Werkzeug an.
##  · Kurve (C): jedes Stück schließt tangential an und wird als Kreisbogen gezogen; gerade: Geraden mit ausgerundeten Ecken.
##    Die Vorschau ist die Mittellinie, die gebaut wird (ps.trasse_angebot → ps.trasse_bauen, Straßenband „exakt“).
##  · Fehler sind nur an der Stelle rot und tragen dort ihren Grund.
##  · Planen (P): Abschnitte werden als Blaupause abgelegt, ohne dass Geld fließt; „Plan bauen“ baut alles oder die Auswahl.

const C_GUT := Color("#48E08A")
const C_TEUER := Color("#FFA640")
const C_ROT := Color("#FF5A4A")
const C_BRUECKE := Color("#E8D9B0")
const C_PLAN := Color("#6FB8FF")
const KURZ := {
	"see": "See", "zu_steil": "zu steil ({pct} %, erlaubt {max_pct} %)", "radius_zu_klein": "Bogen zu eng ({radius_m} m, mind. {min_m} m)",
	"wende_zu_eng": "Kehre zu eng", "bruecke_zu_lang": "Brücke zu lang (max. {max_m} m)", "ende_im_wasser": "Ende im Wasser",
	"zu_kurz": "zu kurz (mind. {min_m} m)", "zu_lang": "zu lang (max. {max_m} m)", "kein_anschluss": "kein Anschluss", "gleicher_punkt": "Start = Ziel",
}

var ud = null
var uw = null
var ps = null
var welt: Node = null

var kurve := true                      # true: tangentiale Bögen, false: Geraden mit ausgerundeten Ecken
var planen := false                    # true: Abschnitte werden als Plan abgelegt (kein Geld)
var plan: Array = []                   # [{art, stuetz, kurve, t0, q, an, knoten (Node3D)}]
var start_t0: Variant = null           # Richtung, in der das nächste Stück beginnt (nach Bau/Plan am selben Punkt)
var fang: Dictionary = {}              # Einrasten unter der Maus
var angebot: Dictionary = {}           # Angebot für Punkte + Maus
var wurzel: Node3D
var vorschau: Node3D
var marke: MeshInstance3D
var marken: Node3D                     # Fehlerstellen, Kreuzungen, freies Ende
var see_ringe: Node3D
var plan_wurzel: Node3D
var schild: PanelContainer             # Text an der Maus
var schild_1: Label
var schild_2: Label
var _sig := ""


func einbauen(p_ud) -> void:
	ud = p_ud
	uw = ud.uw
	ps = ud.ps
	welt = ud.welt
	wurzel = Node3D.new()
	wurzel.name = "BauWerkzeug"
	ud.raum.add_child(wurzel)
	plan_wurzel = Node3D.new()
	plan_wurzel.name = "BauPlan"
	wurzel.add_child(plan_wurzel)
	see_ringe = Node3D.new()
	see_ringe.name = "SeeSperre"
	wurzel.add_child(see_ringe)
	vorschau = Node3D.new()
	vorschau.name = "Trasse"
	wurzel.add_child(vorschau)
	marken = Node3D.new()
	marken.name = "Marken"
	wurzel.add_child(marken)
	marke = MeshInstance3D.new()
	marke.name = "Einrastmarke"
	marke.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	marke.visible = false
	wurzel.add_child(marke)
	schild = PanelContainer.new()
	schild.name = "BauSchild"
	schild.mouse_filter = Control.MOUSE_FILTER_IGNORE
	schild.visible = false
	schild.add_theme_stylebox_override("panel", ud._stil(Color(0.1, 0.08, 0.06, 0.94), Color(0.8, 0.7, 0.5, 0.8), 1, 6, 7))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 0)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	schild.add_child(vb)
	schild_1 = ud._lbl("", 17)
	schild_1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(schild_1)
	schild_2 = ud._lbl("", 13, ud.C_MATT)
	schild_2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(schild_2)
	ud.add_child(schild)


func an() -> bool:
	return String(ud.bau_art) != ""


func _opt() -> Dictionary:
	var o := {"kurve": kurve, "plan_enden": plan_enden(String(ud.bau_art))}
	if start_t0 is Vector2:
		o["t0"] = start_t0
	return o


## Freie Enden geplanter Abschnitte derselben Art (dort darf ein weiterer Abschnitt ansetzen).
func plan_enden(art: String) -> Array:
	var r: Array = []
	for e in plan:
		if String(e["art"]) != art:
			continue
		var q: Dictionary = e["q"]
		for seite in ["start", "ende"]:
			if String(q[seite]["typ"]) in ["frei", "plan"]:
				r.append(q["punkte"][0] if seite == "start" else q["punkte"][-1])
	return r


# ------------------------------------------------------------------ Werkzeug an/aus, Punkte

func start(art: String, start_punkt: Variant = null) -> void:
	if not ps.hq_platziert:
		ud.melde_fehler({"fehler": "kein_hq"})
		return
	var rg: Dictionary = ps.bau_regel(art)
	if ps.kalenderjahr() < int(rg.get("ab_jahr", 0)):
		ud.melde_fehler({"fehler": "noch_nicht_verfuegbar", "ab_jahr": int(rg["ab_jahr"])})
		return
	ud.modus_beenden()
	ud.auswahl_leeren()
	ud.fenster_zu()
	ud.bau_art = art
	ud.bau_punkte = PackedVector2Array()
	ud.bau_angebot = {}
	start_t0 = null
	if start_punkt is Vector2:
		var f: Dictionary = ps._fang_plan(art, start_punkt, plan_enden(art))
		if String(f["typ"]) != "frei":
			ud.bau_punkte.append(f["pos"])
	ud.modus_panel.visible = true
	_see_ringe_neu()
	ud.modus_geaendert()
	neu()


func ende() -> void:
	ud.bau_art = ""
	ud.bau_punkte = PackedVector2Array()
	ud.bau_angebot = {}
	angebot = {}
	fang = {}
	start_t0 = null
	ud.modus_panel.visible = false
	schild.visible = false
	marke.visible = false
	_leeren3(vorschau)
	_leeren3(marken)
	_leeren3(see_ringe)
	_sig = ""
	ud.werte["bau_schild"] = ""
	ud.modus_geaendert()


## Klick in die Welt (Geländepunkt). Setzt genau einen Punkt; ein zweiter Klick auf den letzten Punkt (Doppelklick) baut.
func klick(p: Vector2) -> void:
	if not an():
		return
	var art := String(ud.bau_art)
	var f: Dictionary = ps._fang_plan(art, p, plan_enden(art))
	if ud.bau_punkte.is_empty():
		if String(f["typ"]) == "frei":
			ud.melde_fehler({"fehler": "kein_anschluss"})
			return
		ud.bau_punkte.append(f["pos"])
		start_t0 = null
		neu()
		return
	var pos: Vector2 = f["pos"] if String(f["typ"]) != "frei" else p
	var letzter: Vector2 = ud.bau_punkte[-1]
	if pos.distance_to(letzter) <= _doppel_m():
		if ud.bau_punkte.size() >= 2:
			fertig()
		return
	ud.bau_punkte.append(pos)
	ud._maus_boden = pos
	neu()


## Abstand in m, unter dem ein Klick als „noch einmal derselbe Punkt“ gilt (wächst mit dem Kameraabstand, etwa 12 px).
func _doppel_m() -> float:
	return clampf(float(welt.abstand) * 0.012, 4.0, 14.0)


func zurueck() -> void:
	if not ud.bau_punkte.is_empty():
		ud.bau_punkte.remove_at(ud.bau_punkte.size() - 1)
	if ud.bau_punkte.is_empty():
		start_t0 = null
	neu()


## Rechtsklick: letzten Punkt zurück; ohne Punkt beendet er das Werkzeug.
func rechts_klick() -> void:
	if ud.bau_punkte.is_empty():
		ende()
	else:
		zurueck()


func kurve_umschalten() -> void:
	kurve = not kurve
	uw.meldung("Kurve: Jedes Stück schließt im Bogen an das vorige an." if kurve else "Gerade: gerade Stücke, die Ecken werden ausgerundet.", 2.5)
	ud.banner_neu()
	neu()


func planen_umschalten() -> void:
	planen = not planen
	uw.meldung("Planen: Abschnitte werden als Blaupause abgelegt, es fließt kein Geld. „Plan bauen“ baut sie." if planen
		else "Bauen: Enter baut sofort.%s" % ((" Der Plan mit %d Abschnitt%s bleibt liegen." % [plan.size(), "" if plan.size() == 1 else "en"]) if not plan.is_empty() else ""), 3.5)
	ud.banner_neu()
	neu()


## Enter / Doppelklick / Knopf: die gesetzten Punkte bauen oder (Planen) als Abschnitt ablegen. Das Werkzeug bleibt an.
func fertig() -> Dictionary:
	if not an() or ud.bau_punkte.size() < 2:
		ud.melde_fehler({"fehler": "zu_wenig_punkte"})
		return {"ok": false, "fehler": "zu_wenig_punkte"}
	var art := String(ud.bau_art)
	var opt := _opt()
	var q: Dictionary = ps.trasse_angebot(art, ud.bau_punkte, opt)
	if not q.get("ok", false):
		ud.melde_fehler(q)
		neu()
		return q
	var r: Dictionary
	if planen:
		plan.append({"art": art, "stuetz": PackedVector2Array(ud.bau_punkte), "kurve": kurve, "t0": opt.get("t0", null), "q": q, "an": true})
		_plan_3d()
		r = {"ok": true, "geplant": true, "kosten_cent": int(q["kosten_cent"])}
		uw.meldung("Abschnitt %d geplant: %s m, %s. Es ist noch nichts gebaut." % [plan.size(), uw._tsd(int(q["laenge_m"])), ud.geld(int(q["kosten_cent"]))], 3.0)
	else:
		r = ps.trasse_bauen(art, ud.bau_punkte, opt)
		if not r.get("ok", false):
			ud.melde_fehler(r)
			neu()
			return r
		uw.meldung(String(r.get("text", "Gebaut.")))
		ud._bauwerke_pruefen()
		uw.kopf_neu()
	# Werkzeug bleibt an: Das Ende ist der neue Start, die Richtung läuft weiter
	var ende_p: Vector2 = q["punkte"][-1]
	ud.bau_punkte = PackedVector2Array([ende_p])
	start_t0 = q.get("tangente", null) if String(q["ende"]["typ"]) in ["frei", "plan"] else null
	ud._marker_neu()
	neu()
	return r


# ------------------------------------------------------------------ Plan

func plan_kosten(nur_auswahl := false) -> int:
	var c := 0
	for e in plan:
		if e["an"] or not nur_auswahl:
			c += int(e["q"]["kosten_cent"])
	return c


func plan_weg(i: int) -> void:
	if i >= 0 and i < plan.size():
		plan.remove_at(i)
		_plan_3d()
		neu()


func plan_leeren() -> void:
	plan = []
	_plan_3d()
	neu()


## Plan bauen (alles oder nur die angehakten Abschnitte), in der Reihenfolge des Plans. Nur wenn die Summe bezahlbar ist.
func plan_bauen(nur_auswahl := false) -> Dictionary:
	var liste: Array = []
	for e in plan:
		if e["an"] or not nur_auswahl:
			liste.append(e)
	if liste.is_empty():
		ud.melde_fehler({"fehler": "plan_leer"})
		return {"ok": false, "fehler": "plan_leer"}
	var summe := 0
	for e in liste:
		summe += int(e["q"]["kosten_cent"])
	if summe > ps.eco.cash_cent:
		var r0 := {"ok": false, "fehler": "plan_zu_teuer", "fehlt_cent": summe - ps.eco.cash_cent, "kosten": ud.geld(summe)}
		ud.melde_fehler(r0)
		return r0
	var gebaut := 0
	var kosten := 0
	var offen: Dictionary = {}
	for e in liste:
		var rest: Array = []                                    # Planenden, die noch nicht gebaut sind, gelten nicht als Anschluss
		var r: Dictionary = ps.trasse_bauen(String(e["art"]), e["stuetz"], {"kurve": bool(e["kurve"]), "t0": e["t0"], "plan_enden": rest})
		if r.get("ok", false):
			gebaut += 1
			kosten += int(r.get("kosten_cent", 0))
			plan.erase(e)
		else:
			offen = r
	ud._bauwerke_pruefen()
	uw.kopf_neu()
	_plan_3d()
	if gebaut > 0:
		var t := "%d Abschnitt%s gebaut: −%s." % [gebaut, "" if gebaut == 1 else "e", ud.geld(kosten)]
		if not offen.is_empty():
			var ft: String = ud.fehlertext(offen)
			t += " %d bleib%s im Plan: %s" % [liste.size() - gebaut, "t" if liste.size() - gebaut == 1 else "en", ft if ft != "" else String(offen.get("fehler", ""))]
		uw.meldung(t)
	else:
		ud.melde_fehler(offen)
	if an():
		ud.bau_punkte = PackedVector2Array()
		start_t0 = null
		ud._marker_neu()
	neu()
	return {"ok": gebaut > 0, "gebaut": gebaut, "kosten_cent": kosten, "offen": liste.size() - gebaut}


# ------------------------------------------------------------------ Anzeige

func _typ_text(f: Dictionary, art: String) -> String:
	match String(f.get("typ", "")):
		"knoten":
			return "am Gleis" if art == "gleis" else "an der Straße"
		"betrieb":
			return String(f["name"])
		"bahnhof":
			return "Bahnhof " + String(f["name"])
		"bahnhof_neu":
			return "neuer Bahnhof " + String(f["name"])
		"plan":
			return "geplantes Ende"
	return "frei"


func kurztext(st: Dictionary) -> String:
	return String(KURZ.get(String(st.get("fehler", "")), String(st.get("fehler", "?")))).format(st)


## Alles neu aus dem Zustand: Marke unter der Maus, Vorschau, Schild an der Maus, Karte unten.
func neu() -> void:
	if not an():
		return
	var art := String(ud.bau_art)
	var rg: Dictionary = ps.bau_regel(art)
	var maus: Variant = ud._maus_boden
	fang = ps._fang_plan(art, maus, plan_enden(art)) if maus is Vector2 else {}
	ud.werte["bau_punkte"] = ud.bau_punkte.size()
	ud.werte["bau_fang"] = String(fang.get("typ", ""))
	ud.werte["bau_kurve"] = kurve
	ud.werte["bau_planen"] = planen
	ud.werte["bau_plan_n"] = plan.size()
	ud.werte["bau_plan_kosten"] = plan_kosten()
	angebot = {}
	var z1 := ""
	var z2 := ""
	var f1: Color = ud.C_CREME
	if ud.bau_punkte.is_empty():
		if not fang.is_empty():
			if String(fang["typ"]) == "frei":
				z1 = "Hier kein Anschluss"
				z2 = "Beginne an %s, einem Betrieb%s." % ["einem Gleis" if art == "gleis" else "einer Straße", " oder einem geplanten Ende" if not plan.is_empty() else ""]
				f1 = C_TEUER
			else:
				z1 = "Start: " + _typ_text(fang, art)
				z2 = "Klick setzt den Startpunkt"
				f1 = C_GUT
	else:
		var pkt := PackedVector2Array(ud.bau_punkte)
		if maus is Vector2 and (maus as Vector2).distance_to(pkt[-1]) > 1.0:
			pkt.append(maus)
		if pkt.size() >= 2:
			angebot = ps.trasse_angebot(art, pkt, _opt())
			if angebot.has("punkte"):
				var q := angebot
				ud.werte["bau_kosten"] = int(q["kosten_cent"])
				z1 = "%s m · %s%s" % [uw._tsd(int(q["laenge_m"])), ud.geld(int(q["kosten_cent"])), (" · Brücke %d m" % int(q["bruecke_m"])) if int(q["bruecke_m"]) > 0 else ""]
				if not q["ok"]:
					f1 = C_ROT
					z1 = "✕ " + kurztext(q["stellen"][0])
					z2 = "%s m · rot markiert, so wird nicht gebaut" % uw._tsd(int(q["laenge_m"]))
				elif not q["kaufbar"] and not planen:
					f1 = C_TEUER
					z2 = "Es fehlen %s" % uw.fehlbetrag(int(q["fehlt_cent"]))
				else:
					f1 = C_PLAN if planen else C_GUT
					var e_typ := String(q["ende"]["typ"])
					if e_typ == "frei":
						z2 = "Endet frei: verbindet noch nichts"
					else:
						z2 = "Ende: " + _typ_text(q["ende"], art)
					if not q["kreuzungen"].is_empty():
						z2 += " · %d Kreuzung%s" % [q["kreuzungen"].size(), "" if q["kreuzungen"].size() == 1 else "en"]
			else:
				z1 = String(ud.fehlertext(angebot))
				f1 = C_ROT
		else:
			z1 = "Maus zum nächsten Punkt bewegen"
			z2 = "Enter oder Doppelklick %s" % ("legt den Abschnitt in den Plan" if planen else "baut") if ud.bau_punkte.size() >= 2 else ""
	ud.bau_angebot = angebot
	schild_1.text = z1
	schild_1.add_theme_color_override("font_color", f1)
	schild_2.text = z2
	schild_2.visible = z2 != ""
	ud.werte["bau_schild"] = z1 + (" | " + z2 if z2 != "" else "")
	_marke_neu(art)
	_vorschau_neu(art, rg)
	_karte_neu(art, rg)
	ud.banner_neu()


## Schild an die Maus (jedes Bild aus ui_demo._process).
func takt(maus_px: Vector2, ueber_gui: bool) -> void:
	if not an():
		if schild.visible:
			schild.visible = false
		return
	schild.visible = schild_1.text != "" and not ueber_gui
	if schild.visible:
		var gr: Vector2 = ud.get_viewport().get_visible_rect().size
		var p := maus_px + Vector2(22, 20)
		p.x = minf(p.x, gr.x - schild.size.x - 8.0)
		p.y = minf(p.y, gr.y - schild.size.y - 8.0)
		schild.position = p
	var fern := clampf(float(welt.abstand) / 420.0, 1.0, 5.0)
	if marke.visible:
		marke.scale = Vector3.ONE * fern


func _leeren3(n: Node) -> void:
	for c in n.get_children():
		n.remove_child(c)
		c.queue_free()


func _marke_neu(art: String) -> void:
	if fang.is_empty():
		marke.visible = false
		return
	var p: Vector2 = fang["pos"]
	var typ := String(fang["typ"])
	var farbe := Color(0.75, 0.75, 0.75)
	var voll := false
	match typ:
		"knoten":
			farbe = Color.WHITE
			voll = true
		"betrieb", "bahnhof", "bahnhof_neu":
			farbe = ud.C_GOLD
			voll = true
		"plan":
			farbe = C_PLAN
			voll = true
	var sig := "%s|%s" % [typ, voll]
	if marke.get_meta("sig", "") != sig:
		marke.set_meta("sig", sig)
		marke.mesh = ud._scheibe_lokal(5.0) if voll else ud._ring_lokal(5.0, 1.2)
		var m: StandardMaterial3D = ud._mat(Color(farbe, 0.95))
		m.no_depth_test = true
		m.render_priority = 7
		marke.material_override = m
	marke.position = Vector3(p.x, ud._h(p) + 2.2, p.y)
	marke.visible = true


func _hoehe(p: Vector2, nass: bool) -> float:
	var y: float = ud._h(p) + 0.9
	if nass:
		y = maxf(y, float(ps.strassen.wasser_pegel_m) + 2.4)
	return y


## Band je Klasse (0 gut, 1 Brücke, 2 Fehler) entlang der Mittellinie; Brücke liegt über dem Wasser.
func _baender(q: Dictionary, breite: float) -> Array:
	var pkt: PackedVector2Array = q["punkte"]
	var schlecht: PackedByteArray = q["schlecht"]
	var nass: PackedByteArray = q["nass"]
	var st: Array = [SurfaceTool.new(), SurfaceTool.new(), SurfaceTool.new()]
	var leer := [true, true, true]
	for s in st:
		(s as SurfaceTool).begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in pkt.size() - 1:
		var a := pkt[i]
		var c := pkt[i + 1]
		var kl := 2 if (schlecht[i] == 1 or schlecht[i + 1] == 1) else (1 if (nass[i] == 1 or nass[i + 1] == 1) else 0)
		var d := (c - a).normalized()
		var da := d
		var dc := d
		if i > 0:
			da = (c - pkt[i - 1]).normalized()
		if i < pkt.size() - 2:
			dc = (pkt[i + 2] - a).normalized()
		var ra := Vector2(-da.y, da.x) * breite * 0.5
		var rc := Vector2(-dc.y, dc.x) * breite * 0.5
		var ya := _hoehe(a, nass[i] == 1)
		var yc := _hoehe(c, nass[i + 1] == 1)
		var p1 := Vector3(a.x - ra.x, ya, a.y - ra.y)
		var p2 := Vector3(a.x + ra.x, ya, a.y + ra.y)
		var p3 := Vector3(c.x - rc.x, yc, c.y - rc.y)
		var p4 := Vector3(c.x + rc.x, yc, c.y + rc.y)
		for v in [p1, p2, p3, p2, p4, p3]:
			(st[kl] as SurfaceTool).add_vertex(v)
		leer[kl] = false
	var r: Array = []
	for k in 3:
		r.append(null if leer[k] else (st[k] as SurfaceTool).commit())
	return r


func _trasse_3d(eltern: Node3D, q: Dictionary, breite: float, farbe_gut: Color, alpha: float) -> void:
	var b := _baender(q, breite)
	var farben := [farbe_gut, C_BRUECKE, C_ROT]
	for k in 3:
		if b[k] == null:
			continue
		var mi := MeshInstance3D.new()
		mi.name = ["Gut", "Bruecke", "Fehler"][k]
		mi.mesh = b[k]
		var m: StandardMaterial3D = ud._mat(Color(farben[k], alpha if k != 2 else 0.9))
		m.no_depth_test = k == 2
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		eltern.add_child(mi)
	# Brückenpfeiler: alle 24 m ein Pfosten im Wasser
	var pkt: PackedVector2Array = q["punkte"]
	var nass: PackedByteArray = q["nass"]
	var seit := 99
	for i in pkt.size():
		if nass[i] == 0:
			seit = 99
			continue
		seit += 1
		if seit < 3:
			continue
		seit = 0
		var pf := MeshInstance3D.new()
		pf.name = "Pfeiler"
		var bm := BoxMesh.new()
		var oben := _hoehe(pkt[i], true)
		var unten: float = ud._h(pkt[i]) - 1.0
		bm.size = Vector3(1.6, maxf(1.0, oben - unten), 1.6)
		pf.mesh = bm
		pf.material_override = ud._mat(Color(C_BRUECKE.darkened(0.25), alpha))
		pf.position = Vector3(pkt[i].x, (oben + unten) * 0.5 - 0.2, pkt[i].y)
		pf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		eltern.add_child(pf)


func _text3d(eltern: Node3D, p: Vector2, t: String, farbe: Color, hoch := 9.0) -> void:
	var l := Label3D.new()
	l.text = t
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.fixed_size = true
	l.pixel_size = 0.001
	l.font_size = 26
	l.outline_size = 10
	l.modulate = farbe
	l.outline_modulate = Color(0.05, 0.04, 0.04)
	l.no_depth_test = true
	l.position = Vector3(p.x, ud._h(p) + hoch, p.y)
	eltern.add_child(l)


func _ring3d(eltern: Node3D, p: Vector2, r: float, farbe: Color, voll := false) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = ud._scheibe_lokal(r) if voll else ud._ring_lokal(r, maxf(1.0, r * 0.22))
	var m: StandardMaterial3D = ud._mat(Color(farbe, 0.95))
	m.no_depth_test = true
	mi.material_override = m
	mi.position = Vector3(p.x, ud._h(p) + 2.0, p.y)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	eltern.add_child(mi)


func _vorschau_neu(art: String, rg: Dictionary) -> void:
	var q := angebot
	var sig := ""
	if q.has("punkte"):
		var pk: PackedVector2Array = q["punkte"]
		sig = "%d|%s|%s|%s|%s|%s" % [pk.size(), str(pk[-1]), str(pk[pk.size() / 2]), str(q["ok"]), str(q["kaufbar"]), str(planen)]
	sig += "#%d" % ud.bau_punkte.size()
	if sig == _sig:
		return
	_sig = sig
	_leeren3(vorschau)
	_leeren3(marken)
	ud.vorschau_mi.visible = false
	ud.werte["bau_vorschau"] = q.has("punkte")
	ud.werte["bau_fehlerstellen"] = 0
	ud.werte["bau_rot_punkte"] = 0
	for p in ud.bau_punkte:                                    # gesetzte Punkte bleiben sichtbar
		_ring3d(marken, p, 3.2, Color.WHITE, true)
	if not q.has("punkte"):
		return
	var breite := float(rg.get("breite_m", 3.5)) + 1.5
	var farbe := C_PLAN if planen else (C_GUT if q["kaufbar"] else C_TEUER)
	_trasse_3d(vorschau, q, breite, farbe, 0.8)
	var rot := 0
	for b in q["schlecht"]:
		rot += int(b)
	ud.werte["bau_rot_punkte"] = rot
	ud.werte["bau_punkte_gesamt"] = q["punkte"].size()
	ud.werte["bau_fehlerstellen"] = q["stellen"].size()
	ud.werte["bau_bruecke_m"] = int(q["bruecke_m"])
	for st in q["stellen"]:
		_ring3d(marken, st["bei"], 6.0, C_ROT)
		_text3d(marken, st["bei"], "✕ " + kurztext(st), C_ROT)
	for k in q["kreuzungen"]:
		var kp: Vector3 = ps.knoten_pos[q["kreuzungen"][k]]
		_ring3d(marken, Vector2(kp.x, kp.z), 4.5, Color.WHITE)
	if q["ok"] and String(q["ende"]["typ"]) == "frei":
		_ring3d(marken, q["punkte"][-1], 5.0, C_TEUER)
	if int(q["bruecke_m"]) > 0:
		var pk2: PackedVector2Array = q["punkte"]
		var nass: PackedByteArray = q["nass"]
		var summe := Vector2.ZERO
		var n := 0
		for i in pk2.size():
			if nass[i] == 1:
				summe += pk2[i]
				n += 1
		if n > 0:
			_text3d(marken, summe / float(n), "Brücke %d m" % int(q["bruecke_m"]), C_BRUECKE, 12.0)


## Sperrzone stehender Gewässer sichtbar machen (Befund 5).
func _see_ringe_neu() -> void:
	_leeren3(see_ringe)
	for k in ps.see_kreise:
		var mi := MeshInstance3D.new()
		mi.mesh = ud._ring_mesh(Vector2(k[0], k[1]), float(k[2]), 1.6)
		mi.material_override = ud._mat(Color(C_ROT, 0.55))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		see_ringe.add_child(mi)
	ud.werte["bau_see_ringe"] = see_ringe.get_child_count()


## Blaupausen der geplanten Abschnitte (bleiben liegen, auch wenn das Werkzeug aus ist).
func _plan_3d() -> void:
	_leeren3(plan_wurzel)
	for i in plan.size():
		var e: Dictionary = plan[i]
		var n := Node3D.new()
		n.name = "Abschnitt_%d" % (i + 1)
		plan_wurzel.add_child(n)
		var breite: float = float(ps.bau_regel(String(e["art"])).get("breite_m", 3.5)) + 1.5
		_trasse_3d(n, e["q"], breite, C_PLAN if e["an"] else C_PLAN.darkened(0.35), 0.6)
		var pk: PackedVector2Array = e["q"]["punkte"]
		_text3d(n, pk[pk.size() / 2], "Plan %d" % (i + 1), C_PLAN.lightened(0.3), 8.0)
	ud.werte["bau_plan_n"] = plan.size()
	ud.leiste_neu()


func _karte_neu(art: String, rg: Dictionary) -> void:
	var vb: VBoxContainer = ud.modus_vb
	ud._leeren(vb, 2)
	(vb.get_child(0).get_node("Titel") as Label).text = "%s %s" % [String(rg.get("name", art)), "planen" if planen else "bauen"]
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	var bk: Button = ud._knopf("Kurve · C" if kurve else "Gerade · C", "bau_kurve", kurve_umschalten, ud.C_BAU)
	bk.tooltip_text = "Kurve: Jedes Stück schließt im Bogen an. Gerade: gerade Stücke mit ausgerundeten Ecken. Taste C wechselt."
	hb.add_child(bk)
	var bp: Button = ud._knopf("Planen an · P" if planen else "Planen aus · P", "bau_planen", planen_umschalten, C_PLAN if planen else Color.TRANSPARENT)
	bp.tooltip_text = "Planen: Abschnitte als Blaupause ablegen, ohne Geld auszugeben. Taste P wechselt."
	hb.add_child(bp)
	var ok: bool = ud.bau_punkte.size() >= 2
	hb.add_child(ud._knopf("In den Plan · Enter" if planen else "Bauen · Enter", "bau_fertig", fertig, (C_PLAN if planen else ud.C_OK) if ok else Color.TRANSPARENT, not ok))
	hb.add_child(ud._knopf("Punkt zurück · Rechtsklick", "bau_zurueck", zurueck, Color.TRANSPARENT, ud.bau_punkte.is_empty()))
	hb.add_child(ud._knopf("Beenden · Esc", "bau_abbrechen", ende))
	vb.add_child(hb)
	var bruecke := int(rg.get("bruecke_faktor_promille", 1000)) / 1000
	vb.add_child(ud._lbl("%s je Feld (25 m) · Brücke ×%d · Bogen mind. %d m%s" % [ud.geld(int(rg.get("kosten_cent_pro_feld", 0))), bruecke, int(ps.bau_radius(art)),
		(" · Unterhalt %s/min je Feld" % ud._cent(int(rg.get("unterhalt_cent_pro_feld_pro_periode", 0)))) if int(rg.get("unterhalt_cent_pro_feld_pro_periode", 0)) > 0 else ""], 13, ud.C_MATT))
	if plan.is_empty():
		return
	vb.add_child(ud._lbl("PLAN · %d Abschnitt%s · zusammen %s" % [plan.size(), "" if plan.size() == 1 else "e", ud.geld(plan_kosten())], 14, C_PLAN.lightened(0.2)))
	var liste := VBoxContainer.new()
	liste.add_theme_constant_override("separation", 2)
	for i in plan.size():
		var e: Dictionary = plan[i]
		var z := HBoxContainer.new()
		z.add_theme_constant_override("separation", 8)
		var hk: Button = ud._knopf("✓" if e["an"] else " ", "plan_an_%d" % i, func():
			e["an"] = not e["an"]
			_plan_3d()
			neu(), C_PLAN if e["an"] else Color.TRANSPARENT)
		hk.custom_minimum_size = Vector2(32, 28)
		hk.tooltip_text = "Abschnitt für „Auswahl bauen“ an- oder abwählen"
		z.add_child(hk)
		var l: Label = ud._lbl("Abschnitt %d · %s · %s m · %s%s" % [i + 1, String(ps.bau_regel(String(e["art"])).get("name", e["art"])), uw._tsd(int(e["q"]["laenge_m"])),
			ud.geld(int(e["q"]["kosten_cent"])), (" · Brücke %d m" % int(e["q"]["bruecke_m"])) if int(e["q"]["bruecke_m"]) > 0 else ""], 14)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		z.add_child(l)
		z.add_child(ud._knopf("✕", "plan_weg_%d" % i, plan_weg.bind(i)))
		liste.add_child(z)
	vb.add_child(liste)
	var summe := plan_kosten()
	var auswahl := plan_kosten(true)
	var fehlt: int = summe - ps.eco.cash_cent
	var hp := HBoxContainer.new()
	hp.add_theme_constant_override("separation", 8)
	var ba: Button = ud._knopf("Plan bauen · %s" % ud.geld(summe), "plan_bauen", plan_bauen.bind(false), ud.C_OK if fehlt <= 0 else Color.TRANSPARENT, fehlt > 0)
	if fehlt > 0:
		ba.tooltip_text = "Es fehlen %s." % uw.fehlbetrag(fehlt)
	hp.add_child(ba)
	if auswahl != summe and auswahl > 0:
		hp.add_child(ud._knopf("Auswahl bauen · %s" % ud.geld(auswahl), "plan_auswahl_bauen", plan_bauen.bind(true), ud.C_OK if auswahl <= ps.eco.cash_cent else Color.TRANSPARENT,
			auswahl > ps.eco.cash_cent))
	hp.add_child(ud._knopf("Plan verwerfen", "plan_leeren", plan_leeren))
	vb.add_child(hp)
	if fehlt > 0:
		vb.add_child(ud._lbl("▲ Für den ganzen Plan fehlen %s. Wähle Abschnitte ab oder warte auf Einnahmen." % uw.fehlbetrag(fehlt), 13, C_TEUER))
