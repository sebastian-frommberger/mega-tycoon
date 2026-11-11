extends RefCounted
## Demo Teil 3: Verkehrsverwaltung nach dem Muster von Transport Fever 2.
## Ein Fenster „Verkehr“ (Reiter Linien | Fahrzeuge | Depots | Strecken), ein Depotfenster (Katalog, Bestand, Zuweisen)
## und der Linien-Editor (Halte in der Welt anklicken). Gehört zu ui_demo.gd (ud): Bausteine, Moduswechsel und Auswahl liegen dort.
##
## Ablauf: Linie anlegen (ohne Fahrzeug) → im Depot kaufen → Fahrzeuge (auch mehrere) der Linie zuweisen.
## Mehrfachauswahl: Klick wählt/entwählt eine Zeile, Umschalt+Klick wählt den Bereich seit dem letzten Klick.

const C_BG2 := Color(0.20, 0.16, 0.12, 0.96)
const C_ZEILE := Color(0.17, 0.14, 0.11, 0.92)
const C_ZEILE_AN := Color(0.33, 0.26, 0.13, 0.98)
const TABS := [["linien", "Linien"], ["fahrzeuge", "Fahrzeuge"], ["depots", "Depots"], ["strecken", "Strecken"]]
const ART_KURZ := {"strasse_gueter": "Straße · Güter", "strasse_personen": "Straße · Personen", "gleis_gueter": "Gleis · Güter", "gleis_personen": "Gleis · Personen"}
const ART_TEXT := {
	"strasse_gueter": "Fuhrwerke bringen Waren von Betrieb zu Betrieb und in die Orte.",
	"strasse_personen": "Kutschen und Omnibusse fahren Haltestellen in den Orten ab.",
	"gleis_gueter": "Güterzüge zwischen Bahnhöfen: viel Ladung, braucht ein Gleis.",
	"gleis_personen": "Personenzüge zwischen den Bahnhöfen der Orte.",
}

var ud = null                         # ui_demo.gd
var uw = null
var ps = null
var welt: Node = null

var panel: PanelContainer
var vb: VBoxContainer
var tab := "linien"
var linie_sel := 0                    # gewählte Linie (0 = keine): Detail rechts, Route in der Welt hervorgehoben
var art_wahl := false                 # Reiter Linien: Auswahl der Linienart ist offen
var fz_auswahl: Dictionary = {}       # Schlüssel -> true (Mehrfachauswahl, gilt für Fahrzeugliste und Depotfenster)
var fz_letzter := ""                  # zuletzt angeklickte Zeile (Anker für Umschalt+Klick)
var fz_sicht: Dictionary = {}         # Listen-ID -> Schlüssel in Anzeigereihenfolge
var zeilen: Dictionary = {}           # "liste:key" -> Zeile (Tests: echter Mausklick auf die Zeile)
var filter_linie := "alle"            # "alle" | "depot" | "l<id>"
var filter_art := "alle"
var verkauf_frage := ""               # Listen-ID mit offener Verkaufsbestätigung

var depot_panel: PanelContainer
var depot_vb: VBoxContainer
var depot_offen := -1                 # Index des offenen Depots (−1 = zu)
var kauf_menge: Dictionary = {}       # def_id -> Stückzahl im Katalog

var editor_panel: PanelContainer
var editor_vb: VBoxContainer
var halte_an := false                 # Modus „Halte in der Welt anklicken“
var halte_linie := 0                  # 0 = neue Linie, sonst: Halte an eine bestehende Linie anhängen
var halte_art := ""
var halte_liste: Array = []
var halte_auftrag: Array = []

var linie_mi: MeshInstance3D          # Route der gewählten Linie in der Welt
var linie_marker: Node3D              # Nummern an den Halten
var _sig_route := ""
var _t := 0.0
var _scroll: Dictionary = {}          # Name -> gemerkte Rollposition


func einbauen(p_ud) -> void:
	ud = p_ud
	uw = ud.uw
	ps = ud.ps
	welt = ud.welt
	var k: Array = ud._karte("Verkehr", ud.C_PLAN, 1060.0, schliessen, "verkehr")
	panel = k[0]
	vb = k[1]
	panel.name = "VerkehrPanel"
	ud._mitte(panel)
	(panel.get_parent() as Control).offset_top = 150.0          # Fenster mittig unter Kopf- und Werkzeugleiste
	panel.visible = false
	var kd: Array = ud._karte("Depot", ud.C_FUHR, 640.0, depot_schliessen, "depotfenster")
	depot_panel = kd[0]
	depot_vb = kd[1]
	depot_panel.name = "DepotFenster"
	depot_panel.anchor_left = 1.0
	depot_panel.anchor_right = 1.0
	depot_panel.offset_right = -12.0
	depot_panel.offset_left = -12.0 - 640.0
	depot_panel.offset_top = 178.0
	depot_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	depot_panel.visible = false
	ud.add_child(depot_panel)
	var ke: Array = ud._karte("Linie", ud.C_PLAN, 430.0, halte_abbrechen, "editor")
	editor_panel = ke[0]
	editor_vb = ke[1]
	editor_panel.name = "LinienEditor"
	editor_panel.offset_left = 8.0
	editor_panel.offset_top = 236.0
	editor_panel.visible = false
	ud.add_child(editor_panel)
	linie_mi = MeshInstance3D.new()
	linie_mi.name = "LinienRoute"
	linie_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	linie_mi.visible = false
	ud.raum.add_child(linie_mi)
	linie_marker = Node3D.new()
	linie_marker.name = "LinienMarker"
	ud.raum.add_child(linie_marker)


# ------------------------------------------------------------------ Bausteine

func geld(c: int) -> String:
	return ud.geld(c)


func _farbe(l: Dictionary) -> Color:
	return Color(String(l.get("farbe", "#C98BD0")))


func _chip(farbe: Color, b := 10.0, h := 22.0) -> ColorRect:
	var c := ColorRect.new()
	c.color = farbe
	c.custom_minimum_size = Vector2(b, h)
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


func _titelzeile(t: String, farbe: Color = Color("#CDBB9B")) -> Label:
	return ud._lbl(t, 13, farbe)


func _rollfeld(name: String, breite: float, hoehe: float) -> Array:
	var sc := ScrollContainer.new()
	sc.name = name
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.custom_minimum_size = Vector2(breite, hoehe)
	var lv := VBoxContainer.new()
	lv.add_theme_constant_override("separation", 3)
	lv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(lv)
	if _scroll.has(name):
		var ziel := int(_scroll[name])
		sc.ready.connect(func(): sc.set_deferred("scroll_vertical", ziel))
	sc.get_v_scroll_bar().value_changed.connect(func(v): _scroll[name] = int(v))
	return [sc, lv]


## Kästchen der Mehrfachauswahl (gezeichnet, keine Schriftzeichen: die Standardschrift hat keine Häkchen).
func _haken(an: bool) -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(20, 20)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", ud._stil(Color(0.1, 0.08, 0.06), ud.C_GOLD if an else Color(0.55, 0.47, 0.36), 2, 4, 3))
	if an:
		var c := ColorRect.new()
		c.color = ud.C_GOLD
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(c)
	return p


func _melde(r: Dictionary, ok_text: String) -> Dictionary:
	if r.get("ok", false):
		uw.meldung(ok_text)
	else:
		ud.melde_fehler(r)
	uw.kopf_neu()
	neu()
	return r


func _kamera_zu(p: Vector2, abstand := 340.0) -> void:
	welt.ziel = Vector3(p.x, ud._h(p), p.y)
	welt.abstand = abstand
	welt._kamera_anwenden()


# ------------------------------------------------------------------ Fenster „Verkehr“

func oeffnen(p_tab := "") -> void:
	if p_tab != "":
		tab = p_tab
	ud.fenster_zu("verkehr")
	depot_schliessen()
	panel.visible = true
	neu()


func schliessen() -> void:
	panel.visible = false
	art_wahl = false
	verkauf_frage = ""


## Taste L/U und Leistenknopf: gleicher Reiter schließt, anderer Reiter wechselt.
func umschalten(p_tab: String) -> void:
	if panel.visible and tab == p_tab:
		schliessen()
	else:
		oeffnen(p_tab)


func linie_waehlen(id: int) -> void:
	linie_sel = id
	art_wahl = false
	if id > 0:
		ud.auswahl_leeren(false)
	_sig_route = ""
	neu()


## Linie im Fenster zeigen (aus der Linienliste links unten, aus dem Betriebspanel).
func linie_zeigen(id: int) -> void:
	linie_sel = id
	_sig_route = ""
	oeffnen("linien")


func fahrzeug_zeigen(key: String) -> void:
	fz_auswahl = {key: true}
	fz_letzter = key
	filter_linie = "alle"
	filter_art = "alle"
	oeffnen("fahrzeuge")


func neu() -> void:
	if depot_panel != null and depot_panel.visible:
		depot_neu()
	if editor_panel != null and editor_panel.visible:
		editor_neu()
	if panel == null or not panel.visible:
		return
	_auswahl_putzen()
	ud._leeren(vb, 2)
	zeilen = _zeilen_ohne("fz")
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	var zahl := {"linien": ps.linien.size(), "fahrzeuge": ps.alle_fahrzeuge().size(), "depots": ps.depots.size(), "strecken": ps.strecken().size()}
	for e in TABS:
		var id := String(e[0])
		var b: Button = ud._knopf("%s (%d)" % [e[1], int(zahl[id])], "vk_tab_" + id, func():
			tab = id
			art_wahl = false
			verkauf_frage = ""
			neu(), ud.C_PLAN if tab == id else Color.TRANSPARENT)
		b.custom_minimum_size = Vector2(150, 36)
		tabs.add_child(b)
	var luft := Control.new()
	luft.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.add_child(luft)
	tabs.add_child(ud._lbl("L Linien · U Fahrzeuge · Esc schließt", 13, ud.C_MATT))
	vb.add_child(tabs)
	ud.werte["verkehr_tab"] = tab
	match tab:
		"fahrzeuge":
			_tab_fahrzeuge()
		"depots":
			_tab_depots()
		"strecken":
			_tab_strecken()
		_:
			_tab_linien()


func _zeilen_ohne(liste: String) -> Dictionary:
	var r := {}
	for k in zeilen:
		if not String(k).begins_with(liste + ":"):
			r[k] = zeilen[k]
	return r


# ------------------------------------------------------------------ Reiter Linien

func _tab_linien() -> void:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	vb.add_child(hb)
	var links := VBoxContainer.new()
	links.add_theme_constant_override("separation", 6)
	links.custom_minimum_size = Vector2(360, 0)
	hb.add_child(links)
	var bn: Button = ud._knopf("+ Neue Linie", "vk_neue_linie", func():
		art_wahl = not art_wahl
		neu(), ud.C_PLAN)
	bn.custom_minimum_size = Vector2(0, 38)
	links.add_child(bn)
	var rf := _rollfeld("vk_linien", 360.0, 420.0)
	links.add_child(rf[0])
	if ps.linien.is_empty():
		rf[1].add_child(ud._umbruch(ud._lbl("Noch keine Linie. Eine Linie ist ein Fahrweg mit zwei bis acht Halten. Fahrzeuge kaufst du danach im Depot und weist sie der Linie zu.", 15, ud.C_MATT), 340))
	if linie_sel > 0 and ps.linie_plan(linie_sel).is_empty():
		linie_sel = 0
	for l in ps.linien:
		rf[1].add_child(_linien_zeile(l))
	var rechts := VBoxContainer.new()
	rechts.add_theme_constant_override("separation", 6)
	rechts.custom_minimum_size = Vector2(660, 0)
	rechts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(rechts)
	if art_wahl:
		_art_wahl(rechts)
	elif linie_sel > 0:
		_linie_detail(rechts, ps.linie_plan(linie_sel))
	else:
		rechts.add_child(ud._lbl("So läuft es", 20, ud.C_GOLD))
		for t in ["1  Neue Linie: Art wählen, dann die Halte in der Welt anklicken.", "2  Im Depot Fahrzeuge kaufen: Der Fuhrhof am Firmensitz ist dein erstes Depot.",
				"3  Fahrzeuge im Depot auswählen (auch mehrere) und der Linie zuweisen.", "4  Die Fahrzeuge rücken aus und fahren die Halte reihum ab."]:
			rechts.add_child(ud._umbruch(ud._lbl(t, 16), 640))
		rechts.add_child(ud._umbruch(ud._lbl("Wähle links eine Linie, um Halte, Ladeaufträge und Fahrzeuge zu sehen. Die gewählte Linie leuchtet in der Welt in ihrer Farbe.", 15, ud.C_MATT), 640))


func _linien_zeile(l: Dictionary) -> Control:
	var id := int(l["id"])
	var an := id == linie_sel
	var kz: Dictionary = ps.linie_kennzahlen(id)
	var p := PanelContainer.new()
	p.name = "linie_%d" % id
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	p.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	p.add_theme_stylebox_override("panel", ud._stil(C_ZEILE_AN if an else C_ZEILE, _farbe(l) if an else Color(0.4, 0.34, 0.26), 2 if an else 1, 6, 7))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(hb)
	hb.add_child(_chip(_farbe(l), 10, 34))
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 0)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var nl: Label = ud._lbl(String(l["name"]), 16)
	nl.clip_text = true
	tv.add_child(nl)
	tv.add_child(ud._lbl("%s · %d Halte" % [ART_KURZ.get(ps.art_der_linie(l), ""), l["halte"].size()], 13, ud.C_MATT))
	hb.add_child(tv)
	var n := int(kz["fahrzeuge"])
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 0)
	rv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fl: Label = ud._lbl("%d Fahrzeug%s" % [n, "" if n == 1 else "e"] if n > 0 else "kein Fahrzeug", 14, ud.C_CREME if n > 0 else ud.C_WARN)
	fl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rv.add_child(fl)
	var el: Label = ud._lbl("%s/min" % geld(int(kz["ertrag_cent"])), 14, ud.C_OK if int(kz["ertrag_cent"]) > 0 else ud.C_MATT)
	el.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rv.add_child(el)
	hb.add_child(rv)
	p.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			uw.klicks += 1
			linie_waehlen.call_deferred(id))
	zeilen["linie:%d" % id] = p
	return p


func _art_wahl(c: VBoxContainer) -> void:
	c.add_child(ud._lbl("Neue Linie: Was soll sie fahren?", 20, ud.C_GOLD))
	c.add_child(ud._umbruch(ud._lbl("Die Art legt fest, welche Fahrzeuge du der Linie zuweisen kannst und welche Halte gelten. Fahrzeuge kaufst du danach im Depot.", 15, ud.C_MATT), 640))
	var gr := GridContainer.new()
	gr.columns = 2
	gr.add_theme_constant_override("h_separation", 10)
	gr.add_theme_constant_override("v_separation", 10)
	for art in ["strasse_gueter", "strasse_personen", "gleis_gueter", "gleis_personen"]:
		var a: Dictionary = ps.ARTEN[art]
		var gesperrt: bool = bool(a["gleis"]) and not ps.gleis_frei()
		var box := VBoxContainer.new()
		box.custom_minimum_size = Vector2(318, 0)
		var b: Button = ud._knopf(ART_KURZ[art], "vk_art_" + art, halte_start.bind(art, 0, ""), ud.C_PLAN if not gesperrt else Color.TRANSPARENT, gesperrt)
		b.custom_minimum_size = Vector2(318, 44)
		box.add_child(b)
		var t := String(ART_TEXT[art])
		if gesperrt:
			t = "Ab %d: Dann darfst du Gleise bauen (Taste G)." % int(ps.bau_regel("gleis").get("ab_jahr", 0))
		box.add_child(ud._umbruch(ud._lbl(t, 14, ud.C_MATT), 318))
		gr.add_child(box)
	c.add_child(gr)
	c.add_child(ud._knopf("Abbrechen", "vk_art_abbrechen", func():
		art_wahl = false
		neu()))


func _linie_detail(c: VBoxContainer, l: Dictionary) -> void:
	var id := int(l["id"])
	var farbe := _farbe(l)
	var kz: Dictionary = ps.linie_kennzahlen(id)
	var fzl: Array = ps.linie_fahrzeuge(id)
	var kopf := HBoxContainer.new()
	kopf.add_theme_constant_override("separation", 10)
	var fb: Button = ud._knopf("", "vk_farbe", func():
		var i: int = ps.LINIENFARBEN.find(String(l["farbe"]))
		l["farbe"] = ps.LINIENFARBEN[(i + 1) % ps.LINIENFARBEN.size()]
		_sig_route = ""
		neu(), farbe)
	fb.custom_minimum_size = Vector2(34, 34)
	fb.add_theme_stylebox_override("normal", ud._stil(farbe, Color.WHITE, 1, 6, 4))
	fb.add_theme_stylebox_override("hover", ud._stil(farbe.lightened(0.2), Color.WHITE, 2, 6, 4))
	fb.tooltip_text = "Linienfarbe wechseln"
	kopf.add_child(fb)
	var nl: Label = ud._lbl(String(l["name"]), 22, farbe.lightened(0.35))
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nl.clip_text = true
	kopf.add_child(nl)
	kopf.add_child(ud._lbl(String(ART_KURZ.get(ps.art_der_linie(l), "")), 15, ud.C_MATT))
	kopf.add_child(ud._knopf("In der Welt zeigen", "vk_linie_welt", func():
		var pkt: PackedVector2Array = ps.linie_punkte(id)
		if pkt.is_empty():
			return
		var lo := pkt[0]
		var hi := pkt[0]
		for q in pkt:
			lo = Vector2(minf(lo.x, q.x), minf(lo.y, q.y))
			hi = Vector2(maxf(hi.x, q.x), maxf(hi.y, q.y))
		schliessen()
		_kamera_zu((lo + hi) * 0.5, clampf(lo.distance_to(hi) * 1.1, 260.0, 1600.0))))
	c.add_child(kopf)
	var q: Dictionary = ps.plan_pruefen_art(l["halte"], bool(l["gleis"]), String(l["fracht"]))
	var ausl := int(kz["ladung"]) * 100 / maxi(1, int(kz["kapazitaet"]))
	ud.werte["linie_detail"] = {"id": id, "ertrag_cent": int(kz["ertrag_cent"]), "auslastung_pct": ausl, "fahrzeuge": fzl.size()}
	var zahlen := HBoxContainer.new()
	zahlen.add_theme_constant_override("separation", 22)
	for e in [["Ertrag letzte Minute", geld(int(kz["ertrag_cent"])), ud.C_OK if int(kz["ertrag_cent"]) > 0 else ud.C_CREME],
			["Auslastung jetzt", ("%d %% (%d von %d)" % [ausl, int(kz["ladung"]), int(kz["kapazitaet"])]) if not fzl.is_empty() else "—", ud.C_CREME],
			["Rundkurs", ("%s m" % uw._tsd(int(q["strecke_m"]))) if q.get("ok", false) else "unterbrochen", ud.C_CREME if q.get("ok", false) else ud.C_BAD],
			["Fahrzeuge", "%d" % fzl.size(), ud.C_CREME if not fzl.is_empty() else ud.C_WARN]]:
		var zv := VBoxContainer.new()
		zv.add_theme_constant_override("separation", 0)
		zv.add_child(_titelzeile(String(e[0])))
		zv.add_child(ud._lbl(String(e[1]), 18, e[2]))
		zahlen.add_child(zv)
	c.add_child(zahlen)
	if not q.get("ok", false):
		c.add_child(ud._umbruch(ud._lbl("■ " + _plan_fehler(q, bool(l["gleis"])), 15, ud.C_BAD), 640))
	for nm in lizenz_fehlt(l):                                 # ohne Lizenz lädt dort kein Fahrzeug: hier sagen, nicht erst an der Rampe
		var site: int = uw.site_of(nm)
		var lq: Dictionary = ps.eco.licence_quote(site, false)
		var preis := int(lq.get("zu_zahlen_cent", 0))
		var lh := HBoxContainer.new()
		lh.add_theme_constant_override("separation", 10)
		var ll: Label = ud._lbl("▲ Lizenz fehlt: Ohne Lizenz lädt bei %s kein Fahrzeug." % nm, 15, ud.C_WARN)
		ll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lh.add_child(ll)
		lh.add_child(ud._knopf("Lizenz kaufen · %s" % geld(preis), "vk_lizenz_%d" % site, func():
			uw.lizenz_kaufen(nm)
			neu(), ud.C_OK if preis <= ps.eco.cash_cent else Color.TRANSPARENT, preis > ps.eco.cash_cent))
		c.add_child(lh)
	c.add_child(_titelzeile("HALTE · die Fahrzeuge fahren sie reihum ab und kehren vom letzten zum ersten zurück"))
	var rf := _rollfeld("vk_halte", 640.0, minf(l["halte"].size() * 38.0 + 4.0, 196.0))
	for i in l["halte"].size():
		_halt_zeile(rf[1], i, String(l["halte"][i]), String(l["auftrag"][i]), id, l)
	c.add_child(rf[0])
	var hk := HBoxContainer.new()
	hk.add_theme_constant_override("separation", 8)
	hk.add_child(ud._knopf("+ Halt in der Welt anklicken", "vk_halt_dazu", halte_start.bind(ps.art_der_linie(l), id, ""), Color.TRANSPARENT, l["halte"].size() >= 8))
	c.add_child(hk)
	c.add_child(_titelzeile("FAHRZEUGE"))
	var art: String = ps.art_der_linie(l)
	var di: int = ps.depot_erreicht(String(l["halte"][0]), bool(l["gleis"]))
	var wartend: Array = []
	for rec in ps.abgestellt:
		if ps.art_von(ps.vdef(String(rec["def_id"]))) == art:
			wartend.append(String(rec["key"]))
	if fzl.is_empty():
		var box := PanelContainer.new()
		box.add_theme_stylebox_override("panel", ud._stil(Color(0.28, 0.2, 0.08, 0.95), ud.C_WARN, 1, 6, 10))
		var bv := VBoxContainer.new()
		box.add_child(bv)
		bv.add_child(ud._lbl("▲ Noch kein Fahrzeug: im Depot kaufen und zuweisen.", 17, ud.C_WARN))
		if di < 0:
			bv.add_child(ud._umbruch(ud._lbl("Kein %s erreicht den ersten Halt %s. Baue eines an %s." % ["Lokschuppen" if l["gleis"] else "Betriebshof", l["halte"][0],
				"diesem Gleis" if l["gleis"] else "dieser Straße"], 15), 600))
		c.add_child(box)
	else:
		var fl := HFlowContainer.new()
		fl.add_theme_constant_override("h_separation", 6)
		fl.add_theme_constant_override("v_separation", 4)
		for f in fzl:
			var key: String = ps.fz_key(f)
			var b: Button = ud._knopf(String(f["name"]), "vk_fz_" + key, fahrzeug_zeigen.bind(key))
			b.tooltip_text = _zustand(key)
			fl.add_child(b)
		c.add_child(fl)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	if not wartend.is_empty():
		hb.add_child(ud._knopf("%d passende%s aus dem Depot zuweisen" % [wartend.size(), "s" if wartend.size() == 1 else ""], "vk_wartende_zuweisen", func():
			zuweisen(wartend, id), ud.C_OK))
	if di >= 0:
		hb.add_child(ud._knopf("Zum Depot: %s" % String(ps.depots[di]["name"]), "vk_zum_depot", depot_oeffnen.bind(di), ud.C_FUHR if fzl.is_empty() and wartend.is_empty() else Color.TRANSPARENT))
	else:
		hb.add_child(ud._knopf("%s bauen · %s" % ["Lokschuppen" if l["gleis"] else "Betriebshof", geld(int(ps.daten["depot"]["kosten_cent"]))], "vk_depot_bauen_linie", func():
			schliessen()
			ud.depot_modus_start(), ud.C_FUHR))
	if not fzl.is_empty():
		hb.add_child(ud._knopf("Alle ins Depot", "vk_linie_ins_depot", func():
			ins_depot(fzl.map(func(f): return ps.fz_key(f)))))
	else:
		hb.add_child(ud._knopf("Linie auflösen", "vk_linie_aufloesen", func():
			_melde(ps.linie_aufloesen(id), "%s aufgelöst." % l["name"])
			linie_sel = 0
			neu()))
	c.add_child(hb)


## Betriebe der Linie, an denen geladen werden soll, für die aber die Lizenz fehlt.
func lizenz_fehlt(l: Dictionary) -> Array:
	var r: Array = []
	if String(l.get("fracht", "")) != "gueter":
		return r
	for i in l["halte"].size():
		var nm := String(l["halte"][i])
		var site: int = uw.site_of(nm)
		if site < 0 or not uw.ist_industrie(site) or uw.lizenz_ok(site) or r.has(nm):
			continue
		if String(l["auftrag"][i]) != "nichts" and ps.halt_ladbar(l, i):
			r.append(nm)
	return r


func _plan_fehler(q: Dictionary, gl: bool) -> String:
	var f := String(q.get("fehler", ""))
	if f in ["keine_verbindung", "keine_gleisverbindung"]:
		return "Zwischen %s und %s fehlt %s. Baue sie (Taste %s) oder nimm den Halt heraus." % [q.get("von", "?"), q.get("nach", "?"), "das Gleis" if gl else "die Straße", "G" if gl else "B"]
	var t: String = ud.fehlertext(q)
	return t if t != "" else f


func _halt_zeile(c: VBoxContainer, i: int, nm: String, modus: String, id: int, l: Dictionary) -> void:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	var nr: Label = ud._lbl("%d" % (i + 1), 15, ud.C_GOLD)
	nr.custom_minimum_size = Vector2(18, 0)
	hb.add_child(nr)
	var nl: Label = ud._lbl(nm, 15)
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nl.clip_text = true
	hb.add_child(nl)
	var pre := "halt_%d_%d_" % [id, i]
	if id > 0 and modus != "nichts" and String(l.get("fracht", "")) == "gueter" and not ps.halt_ladbar(l, i):
		var hl: Label = ud._lbl("lädt nichts: kein Halt nimmt die Ware", 13, ud.C_MATT)
		hl.tooltip_text = "Kein anderer Halt dieser Linie nimmt an, was es hier gibt. Das Fahrzeug lädt deshalb nicht."
		hl.mouse_filter = Control.MOUSE_FILTER_PASS
		hb.add_child(hl)
	var ab: Button = ud._knopf(String(ud.AUFTRAG_TEXT.get(modus, modus)), pre + "auftrag", func():
		var n: String = ud.AUFTRAG_FOLGE[(ud.AUFTRAG_FOLGE.find(modus) + 1) % 3]
		if id > 0:
			_melde(ps.linie_auftrag(id, i, n), "Halt %d (%s): %s." % [i + 1, nm, ud.AUFTRAG_TEXT[n]])
		else:
			halte_auftrag[i] = n
			neu())
	ab.custom_minimum_size = Vector2(190, 30)
	ab.tooltip_text = "Ladeauftrag wechseln: voll laden → mitnehmen, was da ist → nur abladen"
	hb.add_child(ab)
	hb.add_child(ud._knopf("▲", pre + "hoch", func():
		if id > 0:
			_melde(ps.linie_halt_schieben(id, i, -1), "Halt %s eine Stelle früher. Die Fahrzeuge beginnen wieder am ersten Halt." % nm)
		elif i > 0:
			var t = halte_liste[i]
			halte_liste[i] = halte_liste[i - 1]
			halte_liste[i - 1] = t
			halte_auftrag = ps._auftrag_std(halte_liste, String(ps.ARTEN[halte_art]["fracht"]))
			ud._marker_neu()
			neu(), Color.TRANSPARENT, i == 0))
	hb.add_child(ud._knopf("✕", pre + "weg", func():
		if id > 0:
			_melde(ps.linie_halt_weg(id, i), "Halt %s aus der Linie genommen. Die Fahrzeuge beginnen wieder am ersten Halt." % nm)
			_sig_route = ""
		else:
			halte_liste.remove_at(i)
			halte_auftrag = ps._auftrag_std(halte_liste, String(ps.ARTEN[halte_art]["fracht"]))
			ud._marker_neu()
			neu()))
	c.add_child(hb)


# ------------------------------------------------------------------ Linien-Editor: Halte in der Welt anklicken

## Modus „Halte anklicken“ starten. id 0 = neue Linie der Art `art`, sonst Halte an die Linie anhängen. erster: Halt, der schon gesetzt ist.
func halte_start(art: String, id := 0, erster := "") -> void:
	if not ps.hq_platziert:
		ud.melde_fehler({"fehler": "kein_hq"})
		return
	var a: Dictionary = ps.ARTEN.get(art, {})
	if a.is_empty():
		return
	if bool(a["gleis"]) and not ps.gleis_frei():
		ud.melde_fehler({"fehler": "noch_nicht_verfuegbar", "ab_jahr": int(ps.bau_regel("gleis").get("ab_jahr", 0))})
		return
	ud.modus_beenden()
	ud.auswahl_leeren(false)
	schliessen()
	depot_schliessen()
	halte_an = true
	halte_linie = id
	halte_art = art
	halte_liste = []
	halte_auftrag = []
	if id > 0:
		linie_sel = id
		_sig_route = ""
	editor_panel.visible = true
	if erster != "" and halte_gueltig(erster) == "":
		halte_liste.append(erster)
		halte_auftrag = ps._auftrag_std(halte_liste, String(a["fracht"]))
	ud.modus_geaendert()
	editor_neu()


func halte_name() -> String:
	if halte_linie > 0:
		return String(ps.linie_plan(halte_linie).get("name", "Linie"))
	return "Linie %d" % (ps._linie_nr + 1)


## "" = Halt gilt für die Linienart, sonst der Grund in Worten.
func halte_gueltig(nm: String) -> String:
	if not ps.stationen.has(nm):
		return "Das ist kein Halt."
	var a: Dictionary = ps.ARTEN[halte_art]
	if bool(a["gleis"]) and not ps.bahnhof.has(nm):
		return "%s hat keinen Bahnhof. Baue ein Gleis dorthin (Taste G), dann entsteht einer." % nm
	if String(a["fracht"]) == "personen" and not ps._fracht_ok("personen", nm, true):
		return "%s ist ein Betrieb: Personenlinien halten nur in Orten und an Haltestellen." % nm
	if not bool(a["gleis"]) and not ps.angeschlossen(nm):
		return "%s hat keinen Straßenanschluss. Baue zuerst eine Straße dorthin (Taste B)." % nm
	return ""


## Weltklick im Modus (nm = Station unter der Maus oder "").
func halte_klick(nm: String) -> void:
	if not halte_an:
		return
	if nm == "":
		uw.meldung("Klicke einen markierten Halt an (Ring in Linienfarbe). Enter schließt die Linie ab, Esc bricht ab.", 3.0)
		return
	var grund := halte_gueltig(nm)
	if grund != "":
		uw.meldung(grund, 4.0)
		return
	if halte_linie > 0:
		var l: Dictionary = ps.linie_plan(halte_linie)
		if not l["halte"].is_empty() and String(l["halte"][-1]) == nm:
			ud.melde_fehler({"fehler": "gleicher_ort", "name": nm})
			return
		var r: Dictionary = ps.linie_halt_dazu(halte_linie, nm)
		if r.get("ok", false):
			uw.meldung("%s ist jetzt Halt %d von %s." % [nm, l["halte"].size(), l["name"]], 3.0)
		else:
			ud.melde_fehler(r)
		_sig_route = ""
	else:
		if not halte_liste.is_empty() and String(halte_liste[-1]) == nm:
			ud.melde_fehler({"fehler": "gleicher_ort", "name": nm})
			return
		if halte_liste.size() >= 8:
			ud.melde_fehler({"fehler": "zu_viele_halte", "max": 8})
			return
		halte_liste.append(nm)
		halte_auftrag = ps._auftrag_std(halte_liste, String(ps.ARTEN[halte_art]["fracht"]))
	ud._marker_neu()
	ud.banner_neu()
	editor_neu()


func halte_zurueck() -> void:
	if halte_an and halte_linie == 0 and not halte_liste.is_empty():
		halte_liste.remove_at(halte_liste.size() - 1)
		halte_auftrag = ps._auftrag_std(halte_liste, String(ps.ARTEN[halte_art]["fracht"]))
		ud._marker_neu()
		ud.banner_neu()
		editor_neu()


func halte_anzahl() -> int:
	if halte_linie > 0:
		return int(ps.linie_plan(halte_linie).get("halte", []).size())
	return halte_liste.size()


## Enter / „Fertig“: neue Linie anlegen (ohne Fahrzeug) oder das Anhängen beenden. Danach öffnet das Fenster mit der Linie.
func halte_fertig() -> Dictionary:
	if not halte_an:
		return {"ok": false, "fehler": "kein_modus"}
	var id := halte_linie
	var r := {"ok": true, "linie": id}
	if id == 0:
		r = ps.linie_neu(halte_art, halte_liste, halte_auftrag)
		if not r.get("ok", false):
			var t := _plan_fehler(r, bool(ps.ARTEN[halte_art]["gleis"]))
			uw.meldung(t if t != "" else "Die Linie lässt sich so nicht anlegen.")
			editor_neu()
			return r
		id = int(r["linie"])
		uw.meldung("%s angelegt. Jetzt im Depot Fahrzeuge kaufen und zuweisen." % ps.linie_plan(id)["name"])
	_halte_ende()
	linie_zeigen(id)
	return r


func halte_abbrechen() -> void:
	if not halte_an:
		return
	_halte_ende()


func _halte_ende() -> void:
	halte_an = false
	halte_liste = []
	halte_auftrag = []
	halte_linie = 0
	editor_panel.visible = false
	_sig_route = ""
	ud.modus_geaendert()


func editor_neu() -> void:
	if not halte_an:
		return
	ud._leeren(editor_vb, 2)
	var a: Dictionary = ps.ARTEN[halte_art]
	(editor_vb.get_child(0).get_node("Titel") as Label).text = ("Neue Linie" if halte_linie == 0 else halte_name())
	editor_vb.add_child(ud._lbl(String(ART_KURZ[halte_art]), 15, ud.C_MATT))
	var ok := false
	if halte_linie > 0:
		var l: Dictionary = ps.linie_plan(halte_linie)
		editor_vb.add_child(ud._umbruch(ud._lbl("Jeder Klick auf einen markierten Halt hängt ihn hinten an.", 15), 400))
		for i in l["halte"].size():
			editor_vb.add_child(ud._lbl("%d  %s" % [i + 1, l["halte"][i]], 15))
		ok = true
	else:
		if halte_liste.is_empty():
			editor_vb.add_child(ud._umbruch(ud._lbl("Klicke den ersten Halt in der Welt an. Gültige Halte tragen einen Ring, alle anderen sind abgedunkelt.", 15), 400))
		for i in halte_liste.size():
			_halt_zeile(editor_vb, i, String(halte_liste[i]), String(halte_auftrag[i]) if i < halte_auftrag.size() else "mitnehmen", 0, {})
		if halte_liste.size() == 1:
			editor_vb.add_child(ud._lbl("Noch mindestens ein Halt.", 15, ud.C_MATT))
		elif halte_liste.size() >= 2:
			var q: Dictionary = ps.plan_pruefen_art(halte_liste, bool(a["gleis"]), String(a["fracht"]))
			ok = q.get("ok", false)
			ud.werte["plan_pruefung"] = q
			if ok:
				editor_vb.add_child(ud._lbl("● Rundkurs %s m über %d Halte" % [uw._tsd(int(q["strecke_m"])), halte_liste.size()], 15, ud.C_OK))
			else:
				editor_vb.add_child(ud._umbruch(ud._lbl("■ " + _plan_fehler(q, bool(a["gleis"])), 15, ud.C_BAD), 400))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	hb.add_child(ud._knopf("Fertig · Enter", "halte_fertig", halte_fertig, ud.C_OK if ok else Color.TRANSPARENT, not ok))
	if halte_linie == 0:
		hb.add_child(ud._knopf("Zurück · Entf", "halte_zurueck", halte_zurueck, Color.TRANSPARENT, halte_liste.is_empty()))
	hb.add_child(ud._knopf("Abbrechen · Esc", "halte_abbrechen", halte_abbrechen))
	editor_vb.add_child(hb)
	if halte_linie == 0:
		editor_vb.add_child(ud._umbruch(ud._lbl("Die Linie entsteht ohne Fahrzeug und kostet nichts. Fahrzeuge kaufst du danach im Depot.", 13, ud.C_MATT), 400))


# ------------------------------------------------------------------ Fahrzeuge: Zeilen, Mehrfachauswahl, Sammelaktionen

func _zustand(key: String) -> String:
	var x: Dictionary = ps.fz(key)
	if x.is_empty():
		return ""
	if key.begins_with("d"):
		return "steht im %s" % String(ps.depots[int(x["depot"])]["name"])
	if x.get("ausfahrt", false):
		return "rückt aus zum ersten Halt"
	var zt: String = ps.zustand_text(x)
	return zt.substr(zt.find(": ") + 2) if zt.find(": ") >= 0 else zt


func _auswahl_putzen() -> void:
	for k in fz_auswahl.keys():
		if ps.fz(String(k)).is_empty():
			fz_auswahl.erase(k)


func auswahl_liste() -> Array:
	var r: Array = []
	for k in ps.alle_fahrzeuge():
		if fz_auswahl.has(k):
			r.append(k)
	return r


## Klick auf eine Fahrzeugzeile. Umschalt: Bereich seit dem letzten Klick wählen.
func zeile_klick(liste: String, key: String, umschalt: bool) -> void:
	var sicht: Array = fz_sicht.get(liste, [])
	if umschalt and fz_letzter != "" and sicht.has(fz_letzter) and sicht.has(key):
		var a: int = sicht.find(fz_letzter)
		var b: int = sicht.find(key)
		for i in range(mini(a, b), maxi(a, b) + 1):
			fz_auswahl[sicht[i]] = true
	else:
		if fz_auswahl.has(key):
			fz_auswahl.erase(key)
		else:
			fz_auswahl[key] = true
		fz_letzter = key
	verkauf_frage = ""
	neu()


func alle_waehlen(liste: String, an: bool) -> void:
	for k in fz_sicht.get(liste, []):
		if an:
			fz_auswahl[k] = true
		else:
			fz_auswahl.erase(k)
	if not an:
		fz_letzter = ""
	verkauf_frage = ""
	neu()


func _fz_zeile(liste: String, key: String, spalten: Array) -> Control:
	var an := fz_auswahl.has(key)
	var p := PanelContainer.new()
	p.name = "fz_" + key
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	p.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var normal: StyleBoxFlat = ud._stil(C_ZEILE_AN if an else C_ZEILE, ud.C_GOLD if an else Color(0.36, 0.3, 0.23), 2 if an else 1, 5, 5)
	var hover: StyleBoxFlat = ud._stil((C_ZEILE_AN if an else C_ZEILE).lightened(0.1), ud.C_GOLD, 2 if an else 1, 5, 5)
	p.add_theme_stylebox_override("panel", normal)
	p.mouse_entered.connect(func(): p.add_theme_stylebox_override("panel", hover))
	p.mouse_exited.connect(func(): p.add_theme_stylebox_override("panel", normal))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(hb)
	hb.add_child(_haken(an))
	for s in spalten:
		var c: Control = s
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb.add_child(c)
	p.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			uw.klicks += 1
			zeile_klick.call_deferred(liste, key, (ev as InputEventMouseButton).shift_pressed))
	zeilen["%s:%s" % [liste, key]] = p
	return p


func _linie_zelle(x: Dictionary, key: String, breite: float) -> Control:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	hb.custom_minimum_size = Vector2(breite, 0)
	if key.begins_with("d"):
		hb.add_child(_chip(Color(0.5, 0.45, 0.38), 8, 18))
		hb.add_child(ud._zelle("im Depot", breite - 16.0, ud.C_WARN))
	else:
		var l: Dictionary = ps.linie_plan(int(x.get("plan", 0)))
		hb.add_child(_chip(_farbe(l) if not l.is_empty() else Color(0.5, 0.45, 0.38), 8, 18))
		hb.add_child(ud._zelle(String(l.get("name", "—")), breite - 16.0))
	return hb


func _zaehler(liste: String) -> Label:
	var n := 0
	for k in fz_sicht.get(liste, []):
		if fz_auswahl.has(k):
			n += 1
	ud.werte["auswahl_" + liste] = n
	var l: Label = ud._lbl("%d ausgewählt" % n if n > 0 else "nichts ausgewählt", 18, ud.C_GOLD if n > 0 else ud.C_MATT)
	l.name = "Zaehler"
	l.custom_minimum_size = Vector2(160, 0)
	return l


## Schlüssel der Auswahl, die in dieser Liste sichtbar sind.
func _gewaehlt(liste: String) -> Array:
	var r: Array = []
	for k in fz_sicht.get(liste, []):
		if fz_auswahl.has(k):
			r.append(k)
	return r


## Linien, denen ALLE gewählten Fahrzeuge zugewiesen werden können (gleiche Art); leer, wenn die Auswahl gemischt ist.
func _passende_linien(keys: Array) -> Array:
	var art := ""
	for k in keys:
		var a: String = ps.art_von(ps.vdef(String(ps.fz(String(k))["def_id"])))
		if art == "":
			art = a
		elif art != a:
			return []
	var r: Array = []
	for l in ps.linien:
		if ps.art_der_linie(l) == art:
			r.append(l)
	return r


func _zuweis_leiste(liste: String, c: Container) -> void:
	var keys := _gewaehlt(liste)
	if keys.is_empty():
		return
	var fl := HFlowContainer.new()
	fl.add_theme_constant_override("h_separation", 6)
	fl.add_theme_constant_override("v_separation", 4)
	fl.add_child(ud._lbl("Zuweisen an:", 15, ud.C_MATT))
	var linien := _passende_linien(keys)
	for l in linien:
		var id := int(l["id"])
		var b: Button = ud._knopf(String(l["name"]), "%s_zu_%d" % [liste, id], zuweisen.bind(keys, id), _farbe(l))
		b.tooltip_text = "%d Fahrzeug%s dieser Linie zuweisen" % [keys.size(), "" if keys.size() == 1 else "e"]
		fl.add_child(b)
	if linien.is_empty():
		var gemischt := false
		var art0 := ""
		for k in keys:
			var a: String = ps.art_von(ps.vdef(String(ps.fz(String(k))["def_id"])))
			if art0 != "" and a != art0:
				gemischt = true
			art0 = a
		if gemischt:
			fl.add_child(ud._lbl("Die Auswahl mischt Fahrzeugarten. Wähle nur Fahrzeuge einer Art (z. B. nur Fuhrwerke).", 15, ud.C_WARN))
		else:
			fl.add_child(ud._lbl("Noch keine Linie der Art „%s“." % ART_KURZ.get(art0, art0), 15, ud.C_WARN))
			fl.add_child(ud._knopf("Linie anlegen", liste + "_linie_anlegen", halte_start.bind(art0, 0, ""), ud.C_PLAN))
	c.add_child(fl)


func zuweisen(keys: Array, linie_id: int) -> Dictionary:
	var l: Dictionary = ps.linie_plan(linie_id)
	var r: Dictionary = ps.zuweisen(keys, linie_id)
	if r.get("ok", false):
		for k in keys:
			fz_auswahl.erase(k)
		for k in r["keys"]:
			fz_auswahl[k] = true
		fz_letzter = ""
		uw._fahrzeuge_neu()
		var abg: Array = r.get("abgelehnt", [])
		var einz := int(r["zugewiesen"]) == 1
		var t := "%d Fahrzeug%s %s jetzt auf %s und %s zum ersten Halt aus." % [int(r["zugewiesen"]), "" if einz else "e",
			"fährt" if einz else "fahren", l.get("name", "der Linie"), "rückt" if einz else "rücken"]
		if not abg.is_empty():
			var ft: String = ud.fehlertext(abg[0])
			t += " %d nicht: %s" % [abg.size(), ft if ft != "" else String(abg[0].get("fehler", ""))]
		uw.meldung(t)
		uw.kopf_neu()
		_sig_route = ""
		neu()
		return r
	if r.has("abgelehnt") and not r["abgelehnt"].is_empty() and not r.has("fehler"):
		r["fehler"] = String(r["abgelehnt"][0].get("fehler", ""))
	if String(r.get("fehler", "")) in ["keine_verbindung", "keine_gleisverbindung"]:
		uw.meldung(_plan_fehler(r, bool(l.get("gleis", false))))
		neu()
		return r
	return _melde(r, "")


func ins_depot(keys: Array) -> Dictionary:
	var r: Dictionary = ps.ins_depot(keys)
	if r.get("ok", false):
		for k in keys:
			fz_auswahl.erase(k)
		for k in r["keys"]:
			fz_auswahl[k] = true
		fz_letzter = ""
		uw._fahrzeuge_neu()
	return _melde(r, "%d Fahrzeug%s im Depot. Dort kosten sie ein Viertel des Unterhalts und verdienen nichts." % [int(r.get("n", 0)), " steht" if int(r.get("n", 0)) == 1 else "e stehen"])


func verkaufen(keys: Array) -> Dictionary:
	verkauf_frage = ""
	var r: Dictionary = ps.verkaufen_viele(keys)
	if r.get("ok", false):
		for k in keys:
			fz_auswahl.erase(k)
		uw._fahrzeuge_neu()
	return _melde(r, "%d Fahrzeug%s verkauft: +%s Restwert." % [int(r.get("n", 0)), "" if int(r.get("n", 0)) == 1 else "e", geld(int(r.get("erloes_cent", 0)))])


func ersetzen(keys: Array) -> Dictionary:
	var r: Dictionary = ps.ersetzen_viele(keys)
	if r.get("ok", false):
		uw._fahrzeuge_neu()                               # neues Modell kann eine andere Darstellung haben (Dampfzug); die Auswahl bleibt
	return _melde(r, "%d Fahrzeug%s durch das neueste Modell ersetzt: −%s." % [int(r.get("n", 0)), "" if int(r.get("n", 0)) == 1 else "e", geld(int(r.get("netto_cent", 0)))])


func ueberholen(keys: Array) -> void:
	var n := 0
	var summe := 0
	var letzter := {}
	for k in keys:
		var r: Dictionary = ps.ueberholen_key(String(k))
		if r.get("ok", false):
			n += 1
			summe += int(r.get("kosten_cent", 0))
		else:
			letzter = r
	if n > 0:
		_melde({"ok": true}, "%d Fahrzeug%s überholt: −%s. Der Alterszuschlag auf den Unterhalt ist wieder 0." % [n, "" if n == 1 else "e", geld(summe)])
	else:
		_melde(letzter if not letzter.is_empty() else {"ok": false, "fehler": "keine_auswahl"}, "")


## Sammelknöpfe unter einer Liste (Ins Depot nur für fahrende, Überholen nur mit Angebot).
func _sammel_leiste(liste: String, c: Container) -> void:
	var keys := _gewaehlt(liste)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	hb.add_child(_zaehler(liste))
	var fahrend: Array = keys.filter(func(k): return String(k).begins_with("v"))
	if liste == "fz":
		hb.add_child(ud._knopf("Ins Depot", liste + "_ins_depot", ins_depot.bind(fahrend), Color.TRANSPARENT, fahrend.is_empty()))
	var ers: Array = []
	var ers_netto := 0
	var ueb: Array = []
	var ueb_kosten := 0
	var wert := 0
	for k in keys:
		var eq: Dictionary = ps.ersetzen_angebot_key(String(k))
		if eq.get("ok", false):
			ers.append(k)
			ers_netto += int(eq["netto_cent"])
		var uq: Dictionary = ps.ueberholen_angebot_key(String(k))
		if uq.get("ok", false):
			ueb.append(k)
			ueb_kosten += int(uq["kosten_cent"])
		wert += int(ps.restwert(ps.fz(String(k))))
	var be: Button = ud._knopf("Ersetzen · %s" % geld(ers_netto) if not ers.is_empty() else "Ersetzen", liste + "_ersetzen", ersetzen.bind(ers), Color.TRANSPARENT, ers.is_empty() or ers_netto > ps.eco.cash_cent)
	be.tooltip_text = "Durch das neueste Modell derselben Art ersetzen (Restwert wird angerechnet)." if not ers.is_empty() else "Für die Auswahl gibt es kein neueres Modell."
	hb.add_child(be)
	var bu: Button = ud._knopf("Überholen · %s" % geld(ueb_kosten) if not ueb.is_empty() else "Überholen", liste + "_ueberholen", ueberholen.bind(ueb), Color.TRANSPARENT, ueb.is_empty() or ueb_kosten > ps.eco.cash_cent)
	bu.tooltip_text = "Setzt den Alterszuschlag auf den Unterhalt zurück. Geht für Fahrzeuge im Depot und für Linien, die ein Depot erreicht."
	hb.add_child(bu)
	if verkauf_frage == liste and not keys.is_empty():
		hb.add_child(ud._lbl("Wirklich verkaufen?", 15, ud.C_WARN))
		hb.add_child(ud._knopf("Ja · +%s" % geld(wert), liste + "_verkaufen_ja", verkaufen.bind(keys), ud.C_BAD))
		hb.add_child(ud._knopf("Nein", liste + "_verkaufen_nein", func():
			verkauf_frage = ""
			neu()))
	else:
		hb.add_child(ud._knopf("Verkaufen · +%s" % geld(wert) if not keys.is_empty() else "Verkaufen", liste + "_verkaufen", func():
			verkauf_frage = liste
			neu(), Color.TRANSPARENT, keys.is_empty()))
	c.add_child(hb)
	_zuweis_leiste(liste, c)


func _filter_knopf(text: String, id: String, an: bool, f: Callable, farbe: Color = Color.TRANSPARENT) -> Button:
	var b: Button = ud._knopf(text, id, f, (farbe if farbe != Color.TRANSPARENT else ud.C_FUHR) if an else Color.TRANSPARENT)
	b.custom_minimum_size = Vector2(0, 28)
	b.add_theme_font_size_override("font_size", 14)
	return b


func _tab_fahrzeuge() -> void:
	var fl := HFlowContainer.new()
	fl.add_theme_constant_override("h_separation", 6)
	fl.add_theme_constant_override("v_separation", 4)
	fl.add_child(ud._lbl("Zeige:", 14, ud.C_MATT))
	fl.add_child(_filter_knopf("alle", "fz_f_alle", filter_linie == "alle", func():
		filter_linie = "alle"
		neu()))
	fl.add_child(_filter_knopf("im Depot (%d)" % ps.abgestellt.size(), "fz_f_depot", filter_linie == "depot", func():
		filter_linie = "depot"
		neu()))
	for l in ps.linien:
		var lid := "l%d" % int(l["id"])
		fl.add_child(_filter_knopf(String(l["name"]), "fz_f_" + lid, filter_linie == lid, func():
			filter_linie = lid
			neu(), _farbe(l)))
	vb.add_child(fl)
	var fa := HBoxContainer.new()
	fa.add_theme_constant_override("separation", 6)
	fa.add_child(ud._lbl("Art:", 14, ud.C_MATT))
	for e in [["alle", "alle"], ["strasse_gueter", "Straße · Güter"], ["strasse_personen", "Straße · Personen"], ["gleis_gueter", "Gleis · Güter"], ["gleis_personen", "Gleis · Personen"]]:
		var aid := String(e[0])
		fa.add_child(_filter_knopf(String(e[1]), "fz_a_" + aid, filter_art == aid, func():
			filter_art = aid
			neu()))
	var luft := Control.new()
	luft.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fa.add_child(luft)
	fa.add_child(ud._knopf("Alle wählen", "fz_alle", alle_waehlen.bind("fz", true)))
	fa.add_child(ud._knopf("Keine", "fz_keine", alle_waehlen.bind("fz", false)))
	vb.add_child(fa)
	var kopf := HBoxContainer.new()
	kopf.add_theme_constant_override("separation", 8)
	var luecke := Control.new()
	luecke.custom_minimum_size = Vector2(25, 0)
	kopf.add_child(luecke)
	for e in [["Fahrzeug", 170.0], ["Art", 130.0], ["Linie", 210.0], ["Zustand", 200.0], ["Alter", 60.0], ["Unterhalt", 90.0], ["Restwert", 70.0]]:
		kopf.add_child(ud._zelle(String(e[0]), float(e[1]), ud.C_MATT, 13))
	vb.add_child(kopf)
	var sicht: Array = []
	var rf := _rollfeld("vk_fz", 1030.0, 330.0)
	var fix_summe := 0
	for key in ps.alle_fahrzeuge():
		var x: Dictionary = ps.fz(String(key))
		var d: Dictionary = ps.vdef(String(x["def_id"]))
		var art: String = ps.art_von(d)
		var im_depot := String(key).begins_with("d")
		if filter_art != "alle" and art != filter_art:
			continue
		if filter_linie == "depot" and not im_depot:
			continue
		if filter_linie.begins_with("l") and (im_depot or "l%d" % int(x.get("plan", 0)) != filter_linie):
			continue
		sicht.append(key)
	fz_sicht["fz"] = sicht
	for key in sicht:
		var x: Dictionary = ps.fz(String(key))
		var d: Dictionary = ps.vdef(String(x["def_id"]))
		var im_depot := String(key).begins_with("d")
		var ld := int(d.get("lebensdauer_jahre", 0))
		var alter: int = ps.alter_jahre(x)
		var fe: int = ps.fix_eff(x)
		if im_depot:
			fe = fe * int(ps.daten.get("depot", {}).get("abgestellt_unterhalt_promille", 250)) / 1000
		fix_summe += fe
		rf[1].add_child(_fz_zeile("fz", String(key), [
			ud._zelle(String(x["name"]), 170.0),
			ud._zelle(String(ART_KURZ.get(ps.art_von(d), "")), 130.0, ud.C_MATT, 13),
			_linie_zelle(x, String(key), 210.0),
			ud._zelle(_zustand(String(key)), 200.0, ud.C_BAD if x.get("gestrandet", false) else ud.C_MATT, 13),
			ud._zelle("%d/%d J" % [alter, ld], 60.0, ud.C_WARN if ld > 0 and alter * 10 >= ld * 8 else ud.C_CREME),
			ud._zelle(geld(fe) + "/min", 90.0),
			ud._zelle(geld(int(ps.restwert(x))), 70.0)]))
	if sicht.is_empty():
		rf[1].add_child(ud._umbruch(ud._lbl("Hier steht noch kein Fahrzeug. Fahrzeuge kaufst du im Depot (Reiter Depots oder Depot in der Welt anklicken)." if ps.alle_fahrzeuge().is_empty()
			else "Kein Fahrzeug passt zu diesem Filter.", 15, ud.C_MATT), 1000))
	vb.add_child(rf[0])
	ud.werte["fuhrpark_fahrzeuge"] = ps.alle_fahrzeuge().size()
	ud.werte["fuhrpark_fix"] = fix_summe
	_sammel_leiste("fz", vb)
	vb.add_child(ud._lbl("Klick wählt eine Zeile, Umschalt+Klick den ganzen Bereich. Gezeigt: %d · Unterhalt zusammen %s/min" % [sicht.size(), geld(fix_summe)], 13, ud.C_MATT))


# ------------------------------------------------------------------ Reiter Depots, Strecken

func _tab_depots() -> void:
	var dd: Dictionary = ps.daten["depot"]
	vb.add_child(ud._umbruch(ud._lbl("Fahrzeuge kaufst du im Depot: Straßenfahrzeuge im Betriebshof, Züge im Lokschuppen. Gekaufte Fahrzeuge stehen dort, bis du sie einer Linie zuweist. Im Depot kannst du Fahrzeuge auch überholen.", 15), 1020))
	var rf := _rollfeld("vk_depots", 1030.0, 330.0)
	for i in ps.depots.size():
		var dp: Dictionary = ps.depots[i]
		var gl := String(dp["art"]) == "gleis"
		var unterwegs := 0
		for f in ps.fahrzeuge:
			if not f["verkauft"] and int(f.get("heimat_depot", -1)) == i:
				unterwegs += 1
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", ud._stil(C_ZEILE, Color(ud.C_FUHR, 0.6), 1, 6, 8))
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		p.add_child(hb)
		hb.add_child(ud._zelle(String(dp["name"]), 260.0, ud.C_FUHR.lightened(0.35), 17))
		hb.add_child(ud._zelle("Gleis · Züge" if gl else "Straße · Wagen", 130.0, ud.C_MATT))
		hb.add_child(ud._zelle("%d im Depot" % ps.depot_bestand(i).size(), 100.0, ud.C_WARN if ps.depot_bestand(i).size() > 0 else ud.C_CREME))
		hb.add_child(ud._zelle("%d unterwegs" % unterwegs, 110.0))
		hb.add_child(ud._zelle("frei" if dp.get("fuhrhof", false) else geld(int(dd["unterhalt_cent_pro_periode"])) + "/min", 90.0, ud.C_MATT))
		var luft := Control.new()
		luft.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(luft)
		hb.add_child(ud._knopf("Öffnen", "vk_depot_%d" % i, depot_oeffnen.bind(i), ud.C_FUHR))
		hb.add_child(ud._knopf("Zeigen", "vk_depot_zeigen_%d" % i, func():
			schliessen()
			_kamera_zu(dp["pos"], 300.0)))
		rf[1].add_child(p)
	if ps.depots.is_empty():
		rf[1].add_child(ud._lbl("Noch kein Depot: Der Firmensitz (Taste H) bringt den ersten Fuhrhof mit.", 15, ud.C_WARN))
	vb.add_child(rf[0])
	var q := HBoxContainer.new()
	q.add_theme_constant_override("separation", 10)
	var teuer: bool = int(dd["kosten_cent"]) > ps.eco.cash_cent
	q.add_child(ud._knopf("Betriebshof oder Lokschuppen bauen · %s" % geld(int(dd["kosten_cent"])), "depot_bauen", func():
		schliessen()
		ud.depot_modus_start(), ud.C_FUHR if not teuer else Color.TRANSPARENT, teuer))
	q.add_child(ud._lbl("Danach eine Stelle an einer Straße (Betriebshof) oder an einem Gleis (Lokschuppen) anklicken.", 14, ud.C_MATT))
	vb.add_child(q)


func _tab_strecken() -> void:
	vb.add_child(ud._umbruch(ud._lbl("Strecken sind Besitz: Eigene Trassen kosten Unterhalt und bringen beim Verkauf die Hälfte der Baukosten zurück (sie werden dann abgebaut). Auf der Staatschaussee zahlt jedes deiner Fahrzeuge Chausseegeld; wer sie kauft, fährt dort frei.", 15), 1020))
	var kopf := HBoxContainer.new()
	for e in [["Strecke", 330.0], ["Länge", 80.0], ["Besitz", 90.0], ["Unterhalt", 110.0], ["Fahrzeuge", 90.0]]:
		kopf.add_child(ud._zelle(String(e[0]), float(e[1]), ud.C_MATT, 13))
	vb.add_child(kopf)
	ud.werte["strecken"] = ps.strecken()
	var rf := _rollfeld("vk_strecken", 1030.0, 320.0)
	for st in ps.strecken():
		var id := String(st["id"])
		var eigen: bool = st["besitz"] == "eigen"
		var hb := HBoxContainer.new()
		hb.add_child(ud._zelle(("● " if eigen else "○ ") + String(st["name"]), 330.0, ud.C_OK if eigen else ud.C_CREME, 15))
		hb.add_child(ud._zelle("%s m" % uw._tsd(int(st["laenge_m"])), 80.0, ud.C_CREME, 15))
		hb.add_child(ud._zelle("deine" if eigen else "Staat", 90.0, ud.C_CREME, 15))
		hb.add_child(ud._zelle(geld(int(st["unterhalt_cent"])) + "/min" if eigen else "Maut %d ¢/Feld" % int(st.get("maut_cent_pro_feld", 0)), 110.0, ud.C_CREME, 14))
		hb.add_child(ud._zelle("%d" % int(st["benutzt"]), 90.0, ud.C_CREME, 15))
		if eigen:
			var gesperrt: bool = int(st["benutzt"]) > 0 and id.begins_with("bau_")
			var bv: Button = ud._knopf("Verkaufen · +%s" % geld(int(st["wert_cent"])), "strecke_vk_" + id, strecke_verkaufen.bind(id), Color.TRANSPARENT, gesperrt)
			if gesperrt:
				bv.tooltip_text = "Hier fahren noch Fahrzeuge. Nimm sie zuerst von der Linie (Reiter Fahrzeuge: Ins Depot)."
			hb.add_child(bv)
		else:
			var q: Dictionary = ps.strecke_kauf_angebot(id)
			var kauf: bool = q.get("ok", false) and q.get("kaufbar", false)
			var b: Button = ud._knopf("Kaufen · %s" % geld(int(st["wert_cent"])), "strecke_kauf_" + id, strecke_kaufen.bind(id), ud.C_FUHR if kauf else Color.TRANSPARENT, not kauf)
			if q.get("ok", false):
				b.tooltip_text = "Deine Fahrzeuge zahlen dort etwa %s/min Maut. Nach dem Kauf: Unterhalt %s/min. Nur aus der Kasse, nicht mit Kredit." % [geld(int(q["maut_cent_pro_periode"])), geld(int(q["unterhalt_cent"]))]
				hb.add_child(ud._zelle("Maut ca. %s/min" % geld(int(q["maut_cent_pro_periode"])), 130.0, ud.C_WARN, 13))
			hb.add_child(b)
		rf[1].add_child(hb)
	vb.add_child(rf[0])
	vb.add_child(ud._lbl("Neue Strecken baust du mit B (Straße) und G (Gleis).", 13, ud.C_MATT))


func strecke_kaufen(id: String) -> Dictionary:
	var r: Dictionary = ps.strecke_kaufen(id)
	return _melde(r, "Strecke gekauft: −%s. Keine Maut mehr, Unterhalt %s/min." % [geld(int(r.get("preis_cent", 0))), geld(int(r.get("unterhalt_cent", 0)))])


func strecke_verkaufen(id: String) -> Dictionary:
	var r: Dictionary = ps.strecke_verkaufen(id)
	if r.get("ok", false):
		ud._bauwerke_pruefen()
	return _melde(r, "Strecke verkauft: +%s." % geld(int(r.get("erloes_cent", 0))))


# ------------------------------------------------------------------ Depotfenster: Katalog, Bestand, Zuweisen

func depot_oeffnen(di: int) -> void:
	if di < 0 or di >= ps.depots.size():
		return
	ud.modus_beenden()
	ud.auswahl_leeren(false)
	schliessen()
	depot_offen = di
	fz_auswahl = {}
	fz_letzter = ""
	verkauf_frage = ""
	depot_panel.visible = true
	ud.auswahl_geaendert()
	depot_neu()


func depot_schliessen() -> void:
	if depot_offen < 0:
		return
	depot_offen = -1
	depot_panel.visible = false
	verkauf_frage = ""
	ud.auswahl_geaendert()


func depot_kaufen(def_id: String) -> Dictionary:
	var n := int(kauf_menge.get(def_id, 1))
	var r: Dictionary = ps.depot_kaufen(depot_offen, def_id, n)
	if r.get("ok", false):
		fz_auswahl = {}
		for k in r["keys"]:
			fz_auswahl[k] = true                              # frisch Gekauftes ist gleich ausgewählt: ein Klick weist es zu
		fz_letzter = ""
		kauf_menge[def_id] = 1
	return _melde(r, "%d × %s gekauft: −%s. %s im Depot und %s ausgewählt." % [n, ps.vdef(def_id).get("name", ""), geld(int(r.get("preis_cent", 0))),
		"Es steht" if n == 1 else "Sie stehen", "ist" if n == 1 else "sind"])


func depot_neu() -> void:
	if depot_offen < 0 or depot_offen >= ps.depots.size():
		return
	_auswahl_putzen()
	ud._leeren(depot_vb, 2)
	zeilen = _zeilen_ohne("depot")
	var di := depot_offen
	var dp: Dictionary = ps.depots[di]
	var gl := String(dp["art"]) == "gleis"
	(depot_vb.get_child(0).get_node("Titel") as Label).text = String(dp["name"])
	depot_vb.add_child(ud._lbl("%s · Unterhalt %s · hier kaufst und überholst du %s" % ["Lokschuppen am Gleis" if gl else "Betriebshof an der Straße",
		"frei (gehört zum Firmensitz)" if dp.get("fuhrhof", false) else geld(int(ps.daten["depot"]["unterhalt_cent_pro_periode"])) + "/min", "Züge" if gl else "Wagen und Kutschen"], 14, ud.C_MATT))
	depot_vb.add_child(_titelzeile("KATALOG"))
	var kat: Array = ps.depot_katalog(di)
	ud.werte["depot_katalog"] = kat
	for id in kat:
		var d: Dictionary = ps.vdef(String(id))
		var n := int(kauf_menge.get(id, 1))
		var preis: int = ps._preis(d)
		var pers: bool = ps.fracht(d) == "personen"
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", ud._stil(C_ZEILE, Color(0.4, 0.34, 0.26), 1, 6, 7))
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 8)
		p.add_child(hb)
		var tv := VBoxContainer.new()
		tv.add_theme_constant_override("separation", 0)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(ud._lbl(String(d["name"]), 16))
		tv.add_child(ud._lbl("%s · %d %s · Unterhalt %s/min · %s je Stück" % ["Personen" if pers else "Güter", ps._kap(d), "Plätze" if pers else "E Ladung",
			geld(int(d.get("fix_cent_pro_periode", 0))), geld(preis)], 13, ud.C_MATT))
		hb.add_child(tv)
		hb.add_child(ud._knopf("−", "kat_minus_" + String(id), func():
			kauf_menge[id] = maxi(1, n - 1)
			depot_neu(), Color.TRANSPARENT, n <= 1))
		var ml: Label = ud._lbl("%d" % n, 18, ud.C_GOLD)
		ml.custom_minimum_size = Vector2(26, 0)
		ml.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hb.add_child(ml)
		hb.add_child(ud._knopf("+", "kat_plus_" + String(id), func():
			kauf_menge[id] = mini(20, n + 1)
			depot_neu()))
		var teuer: bool = preis * n > ps.eco.cash_cent
		var bk: Button = ud._knopf("Kaufen · %s" % geld(preis * n), "kat_kaufen_" + String(id), depot_kaufen.bind(String(id)), ud.C_OK if not teuer else Color.TRANSPARENT, teuer)
		bk.custom_minimum_size = Vector2(150, 34)
		if teuer:
			bk.tooltip_text = "Es fehlen %s." % uw.fehlbetrag(preis * n - ps.eco.cash_cent)
		hb.add_child(bk)
		depot_vb.add_child(p)
	if kat.is_empty():
		depot_vb.add_child(ud._lbl("Noch kein Modell für dieses Depot verfügbar.", 15, ud.C_MATT))
	var best: Array = ps.depot_bestand(di)
	var kopf := HBoxContainer.new()
	kopf.add_theme_constant_override("separation", 8)
	var tl := _titelzeile("IM DEPOT (%d) · ohne Linie, kein Ertrag, ein Viertel Unterhalt" % best.size())
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kopf.add_child(tl)
	kopf.add_child(ud._knopf("Alle wählen", "depot_alle", alle_waehlen.bind("depot", true), Color.TRANSPARENT, best.is_empty()))
	kopf.add_child(ud._knopf("Keine", "depot_keine", alle_waehlen.bind("depot", false), Color.TRANSPARENT, best.is_empty()))
	depot_vb.add_child(kopf)
	var sicht: Array = []
	for rec in best:
		sicht.append(String(rec["key"]))
	fz_sicht["depot"] = sicht
	ud.werte["depot_bestand"] = sicht.size()
	var rf := _rollfeld("vk_depotliste", 610.0, clampf(sicht.size() * 37.0 + 6.0, 44.0, 230.0))
	for rec in best:
		var d: Dictionary = ps.vdef(String(rec["def_id"]))
		rf[1].add_child(_fz_zeile("depot", String(rec["key"]), [
			ud._zelle(String(rec["name"]), 190.0),
			ud._zelle(String(ART_KURZ.get(ps.art_von(d), "")), 130.0, ud.C_MATT, 13),
			ud._zelle("%d J" % ps.alter_jahre(rec), 40.0),
			ud._zelle("Restwert %s" % geld(int(ps.restwert(rec))), 130.0, ud.C_MATT, 13)]))
	if best.is_empty():
		rf[1].add_child(ud._lbl("Das Depot ist leer. Kaufe oben im Katalog.", 15, ud.C_MATT))
	depot_vb.add_child(rf[0])
	_sammel_leiste("depot", depot_vb)
	if not best.is_empty() and _gewaehlt("depot").is_empty():
		depot_vb.add_child(ud._lbl("Wähle Fahrzeuge aus (Klick, Umschalt+Klick für einen Bereich), dann erscheinen die passenden Linien.", 13, ud.C_MATT))
	var fuss := HBoxContainer.new()
	fuss.add_theme_constant_override("separation", 8)
	fuss.add_child(ud._knopf("Verkehr öffnen · L", "depot_zu_verkehr", oeffnen.bind("linien")))
	fuss.add_child(ud._knopf("Schließen · Esc", "depot_schliessen", depot_schliessen))
	depot_vb.add_child(fuss)


# ------------------------------------------------------------------ Takt, Route der gewählten Linie in der Welt

func takt(delta: float) -> void:
	_t += delta
	if _t >= 1.0 and not uw._taste_unten:
		_t = 0.0
		neu()
	_route_neu()


func _route_neu() -> void:
	var id := linie_sel if (linie_sel > 0 and (panel.visible or halte_linie == linie_sel or ud.sel_art == "linie")) else 0
	var l: Dictionary = ps.linie_plan(id) if id > 0 else {}
	var sig := "%d|%s|%s|%d" % [id, str(l.get("halte", [])), String(l.get("farbe", "")), ps.bauwerke.size()]
	if halte_an and halte_linie == 0:
		sig = "neu|%s|%s" % [halte_art, str(halte_liste)]
	if sig == _sig_route:
		return
	_sig_route = sig
	for c in linie_marker.get_children():
		linie_marker.remove_child(c)
		c.queue_free()
	linie_mi.visible = false
	var halte: Array = []
	var farbe := Color.WHITE
	var pkt := PackedVector2Array()
	if halte_an and halte_linie == 0:
		halte = halte_liste
		farbe = Color(ps.LINIENFARBEN[ps._linie_nr % ps.LINIENFARBEN.size()])
		for nm in halte:
			pkt.append(ps.halt_pos(String(nm)))
	elif not l.is_empty():
		halte = l["halte"]
		farbe = _farbe(l)
		pkt = ps.linie_punkte(id)
	ud.werte["route_linie"] = id
	ud.werte["route_punkte"] = pkt.size()
	if pkt.size() >= 2:
		linie_mi.mesh = ud._band(pkt, 7.0, 1.7)
		var m: StandardMaterial3D = ud._mat(Color(farbe, 0.85))
		m.no_depth_test = true
		linie_mi.material_override = m
		linie_mi.visible = true
	for i in halte.size():
		var p: Vector2 = ps.halt_pos(String(halte[i]))
		var t := Label3D.new()
		t.text = "%d" % (i + 1)
		t.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		t.fixed_size = true
		t.pixel_size = 0.0012
		t.font_size = 40
		t.outline_size = 14
		t.modulate = farbe.lightened(0.25)
		t.outline_modulate = Color(0.05, 0.05, 0.07)
		t.no_depth_test = true
		t.position = Vector3(p.x, ud._h(p) + 26.0, p.y)
		linie_marker.add_child(t)
