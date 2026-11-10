extends CanvasLayer
## Demo-Sprint: UI der Demo über ui_welt.gd. Werkzeugleiste (Firmensitz H, Straße B, Gleis G, Verträge V, Skills K, Hilfe F1),
## Baumodus mit Vorschau am Gelände, Firmensitz-Platzierung mit Standortvorschau, Vertragskarten, Skillbaum, Startbild,
## Esc-Abfrage. Kein Modal (D21): die Welt läuft hinter jedem Panel weiter, Esc schließt das oberste.
## Alle Zahlen kommen aus proto/demo_sim.gd (Spieler-API); `werte` hält die zuletzt gezeigten Zahlen für Tests.
## Aktionen sind auch ohne Maus aufrufbar (Tests, Bot-Screenshots): bau_start/klick_boden/bau_fertig, hq_modus_start,
## vertrag_annehmen/ablehnen, skill_klick, hq_ausbauen/hq_anbauen.

const Prefabs := preload("res://world/proto_prefabs.gd")
const FONT_TITEL := ""             # leer = Standardschrift (Kenney Future zeichnet Z wie 2: schlecht lesbar)
const C_BG := Color(0.13, 0.10, 0.08, 0.95)
const C_BG2 := Color(0.20, 0.16, 0.12, 0.96)
const C_CREME := Color("#F8EFD9")
const C_MATT := Color("#CDBB9B")
const C_GOLD := Color("#D9B25A")
const C_OK := Color("#48E08A")
const C_WARN := Color("#FFA640")
const C_BAD := Color("#FF988A")
const C_VERTRAG := Color("#C8623F")
const C_SKILL := Color("#5DB58A")
const C_BAU := Color("#7FA8D8")
const C_HQ := Color("#D9B25A")

## Fehlertexte: Ursache + Lösung, Du-Form (AT-14 G1).
const FT := {
	"kein_hq": "Du hast noch keinen Firmensitz. Platziere ihn zuerst in einem Ort (Taste H).",
	"bankrott": "Du bist bankrott, das geht nicht mehr. Starte neu über das Menü (Esc).",
	"noch_nicht_verfuegbar": "Das gibt es erst ab {ab_jahr}. Bis dahin: Straßen und Fuhrwerke.",
	"zu_wenig_punkte": "Setze mindestens zwei Punkte: Start und Ziel.",
	"kein_anschluss": "Die Trasse hängt in der Luft. Beginne an einer Straße, einem Betrieb oder einem Bahnhof.",
	"kein_anschluss_gleis": "Das Gleis hängt in der Luft. Beginne an einem Betrieb, einem Ort oder an einem Gleis.",
	"gleicher_punkt": "Start und Ziel sind derselbe Punkt. Klicke ein anderes Ziel an.",
	"see": "Hier liegt ein See. Führe die Trasse mit einem Zwischenpunkt am Ufer vorbei.",
	"zu_kurz": "Die Trasse ist zu kurz (mindestens {min_m} m). Setze das Ziel weiter weg.",
	"zu_lang": "Die Trasse ist zu lang (höchstens {max_m} m). Baue sie in zwei Abschnitten.",
	"bruecke_zu_lang": "Die Brücke wäre länger als {max_m} m. Quere das Wasser an einer schmaleren Stelle.",
	"ende_im_wasser": "Ein Ende liegt im Wasser. Setze Start und Ziel ans Ufer.",
	"zu_steil": "Zu steil: {pct} % (erlaubt {max_pct} %). Umgehe den Hang mit Zwischenpunkten.",
	"kurve_zu_eng": "Der Knick ist zu eng für ein Gleis ({grad}°, erlaubt {max_grad}°). Setze die Punkte in einem weiteren Bogen.",
	"guthaben_reicht_nicht": "Dafür fehlen dir {fehlt} in der Kasse. Warte auf Einnahmen oder nimm Kredit.",
	"kein_bahnhof": "{name} hat keinen Bahnhof. Baue ein Gleis bis dorthin (Taste G).",
	"keine_gleisverbindung": "Zwischen den Bahnhöfen fehlt ein Stück Gleis. Schließe die Lücke (Taste G).",
	"keine_verbindung": "Dorthin führt keine Straße. Baue eine (Taste B) oder wähle ein Ziel am Netz.",
	"kein_ort": "Der Firmensitz muss in einem Ort stehen: Erlenbach, Lindenfurt oder Hasenwinkel.",
	"wasser": "Hier ist Wasser. Wähle einen trockenen Platz im Ort.",
	"auf_der_strasse": "Hier verläuft eine Straße. Rücke den Firmensitz ein Stück daneben.",
	"hoechste_stufe": "Dein Firmensitz hat schon die höchste Stufe.",
	"kredit_sperrt_hq": "Kreditgeld zahlt keinen Ausbau. Tilge erst oder warte auf Einnahmen.",
	"schon_gebaut": "Diesen Anbau hast du schon.",
	"kein_platz": "Kein Platz für einen weiteren Anbau ({max} auf dieser Stufe). Baue den Firmensitz aus.",
	"kein_punkt": "Du hast keinen freien Skillpunkt. Punkte gibt es für Meilensteine.",
	"vorgaenger_fehlt": "Dafür brauchst du zuerst „{braucht}“.",
	"schon_gesetzt": "Diesen Skill hast du schon.",
	"angebot_weg": "Dieses Angebot gibt es nicht mehr. Schau dir die anderen an.",
	"zu_viele_vertraege": "Du hast schon {max} Verträge laufen. Erfülle einen oder baue den Firmensitz aus.",
	"unbekanntes_fahrzeug": "Dieses Fahrzeug gibt es nicht. Wähle ein anderes Modell.",
}

var welt: Node = null
var uw = null                         # ui_welt.gd
var ps = null                         # demo_sim.gd
var werte: Dictionary = {}            # zuletzt gezeigte Zahlen (Tests)
var knoepfe: Dictionary = {}          # ID -> Button (Tests)
var _titel_font: Font = null
# Leisten und Panels
var leiste: PanelContainer
var leiste_kn: Dictionary = {}
var lbl_moeglich: Label
var modus_panel: PanelContainer
var modus_vb: VBoxContainer
var vertrag_panel: PanelContainer
var vertrag_vb: VBoxContainer
var skill_panel: PanelContainer
var skill_vb: VBoxContainer
var hq_panel: PanelContainer
var hq_vb: VBoxContainer
var start_panel: PanelContainer
var menue_panel: PanelContainer
var hilfe_offen := false
# Zustände
var bau_art := ""                     # "" | "strasse" | "gleis"
var bau_punkte := PackedVector2Array()
var bau_angebot: Dictionary = {}
var hq_modus := false
var hq_vorschau: Dictionary = {}
var _maus_boden = null                # Vector2 oder null
var maus_aus := false                 # Tests/Screenshots: Mausverfolgung aus (Vorschau wird von Hand gesetzt)
var _t := 0.0
var _t_vorschau := 0.0
var _sig_vertrag := ""
var _sig_skill := ""
var _sig_hq := ""
var _sig_fz := ""
var _n_bauwerke := 0
var _n_bahnhof := 0
var _ereignis_idx := 0
# 3D
var raum: Node3D
var vorschau_mi: MeshInstance3D
var marker_root: Node3D
var hq_ring: MeshInstance3D
var hq_geist: MeshInstance3D
var hq_haus: Node3D
var _ring_t := 0.0


func einbauen(p_welt: Node, p_uw) -> void:
	welt = p_welt
	uw = p_uw
	ps = welt.proto_sim
	name = "UiDemo"
	layer = 3
	welt.add_child(self)
	uw.demo_ui = self
	if FONT_TITEL != "" and ResourceLoader.exists(FONT_TITEL):
		_titel_font = load(FONT_TITEL)
	raum = Node3D.new()
	raum.name = "DemoRaum"
	welt.add_child(raum)
	_baue_3d()
	_baue_leiste()
	_baue_modus()
	_baue_vertraege()
	_baue_skills()
	_baue_hq_panel()
	_baue_menue()
	_baue_start()
	if welt.get("hud") != null and welt.hud != null:
		welt.hud_an = false                                 # altes Prototyp-HUD (Zählung) aus, Taste H gehört dem Firmensitz
		welt.hud.visible = false
	uw.ziele_neu()
	leiste_neu()


# ------------------------------------------------------------------ Bausteine

func geld(c: int) -> String:
	return uw.geld(c)


func _stil(bg: Color, rand_farbe: Color = Color.TRANSPARENT, rand := 0, radius := 8, innen := 10) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_content_margin_all(innen)
	sb.set_corner_radius_all(radius)
	if rand > 0:
		sb.set_border_width_all(rand)
		sb.border_color = rand_farbe
	return sb


func _lbl(t: String, gr := 16, farbe := C_CREME, titel := false) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", gr)
	l.add_theme_color_override("font_color", farbe)
	if titel and _titel_font != null:
		l.add_theme_font_override("font", _titel_font)
	return l


func _umbruch(l: Label, breite: float) -> Label:
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(breite, 0)
	return l


func _knopf(t: String, id: String, f: Callable, akzent: Color = Color.TRANSPARENT, grau := false) -> Button:
	var b := Button.new()
	b.text = t
	b.name = id
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 32)
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_color_override("font_color", C_CREME if not grau else Color(0.62, 0.58, 0.52))
	b.add_theme_color_override("font_hover_color", Color.WHITE if not grau else Color(0.62, 0.58, 0.52))
	var basis := Color(0.26, 0.21, 0.16) if akzent == Color.TRANSPARENT else akzent.darkened(0.45)
	if grau:
		basis = Color(0.2, 0.18, 0.16)
	var n := _stil(basis, akzent if akzent != Color.TRANSPARENT else Color(0.45, 0.38, 0.28), 1, 6, 8)
	var h := _stil(basis.lightened(0.12), (akzent if akzent != Color.TRANSPARENT else C_GOLD), 1, 6, 8)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", _stil(basis.darkened(0.15), C_GOLD, 1, 6, 8))
	b.pressed.connect(func():
		uw.klicks += 1
		f.call())
	knoepfe[id] = b
	return b


## Karte mit Kopfzeile (Akzentbalken, Titel in Versalien, Schließen). Gibt [PanelContainer, VBoxContainer] zurück.
func _karte(titel: String, akzent: Color, breite: float, zu: Callable = Callable(), id := "") -> Array:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := _stil(C_BG, akzent.darkened(0.25), 2, 10, 14)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 10
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(breite, 0)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	p.add_child(vb)
	var kopf := HBoxContainer.new()
	kopf.add_theme_constant_override("separation", 10)
	var balken := ColorRect.new()
	balken.color = akzent
	balken.custom_minimum_size = Vector2(6, 26)
	kopf.add_child(balken)
	var t := _lbl(titel, 24, akzent.lightened(0.45), true)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.name = "Titel"
	kopf.add_child(t)
	if zu.is_valid():
		kopf.add_child(_knopf("✕", (id if id != "" else titel) + "_zu", zu))
	vb.add_child(kopf)
	var linie := ColorRect.new()
	linie.color = Color(akzent, 0.55)
	linie.custom_minimum_size = Vector2(0, 2)
	vb.add_child(linie)
	return [p, vb]


func _leeren(c: Node, ab := 0) -> void:
	var kinder := c.get_children()
	for i in range(ab, kinder.size()):
		c.remove_child(kinder[i])
		kinder[i].queue_free()


## Panel in die Bildmitte: eigener CenterContainer über das ganze Bild (fängt keine Klicks), das Panel wächst mit seinem Inhalt.
func _mitte(p: Control, _dy := 0.0) -> void:
	var c := CenterContainer.new()
	c.name = String(p.name) + "_Mitte"
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(c)
	c.add_child(p)


func fehlertext(r: Dictionary) -> String:
	var f := String(r.get("fehler", ""))
	if f == "kein_anschluss" and bau_art == "gleis":
		f = "kein_anschluss_gleis"
	if not FT.has(f):
		return ""
	var w := r.duplicate()
	w["fehlt"] = uw.fehlbetrag(int(r.get("fehlt_cent", 0)))
	return String(FT[f]).format(w)


func melde_fehler(r: Dictionary) -> void:
	var t := fehlertext(r)
	uw.meldung(t if t != "" else "Das geht gerade nicht (Meldung an uns: %s)." % String(r.get("fehler", "?")))


# ------------------------------------------------------------------ Werkzeugleiste

func _baue_leiste() -> void:
	leiste = PanelContainer.new()
	leiste.name = "Werkzeugleiste"
	leiste.mouse_filter = Control.MOUSE_FILTER_STOP
	leiste.add_theme_stylebox_override("panel", _stil(C_BG, Color(C_GOLD, 0.5), 1, 8, 8))
	leiste.anchor_left = 0.0
	leiste.anchor_right = 0.0
	leiste.offset_left = 8.0
	leiste.offset_top = 92.0
	add_child(leiste)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	leiste.add_child(vb)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	vb.add_child(hb)
	for e in [["hq", "Firmensitz", "H", C_HQ, hq_knopf], ["strasse", "Straße", "B", C_BAU, func(): bau_start("strasse")],
			["gleis", "Gleis", "G", C_BAU, func(): bau_start("gleis")], ["vertrag", "Verträge", "V", C_VERTRAG, vertraege_umschalten],
			["skill", "Skills", "K", C_SKILL, skills_umschalten], ["hilfe", "Hilfe", "F1", Color.TRANSPARENT, hilfe_umschalten]]:
		var b := _knopf("%s  [%s]" % [e[1], e[2]], "leiste_" + String(e[0]), e[4], e[3])
		leiste_kn[e[0]] = b
		hb.add_child(b)
	lbl_moeglich = _lbl("", 14, C_MATT)
	lbl_moeglich.name = "Moeglich"
	vb.add_child(lbl_moeglich)


func _akt_text(a: String) -> String:
	var t: PackedStringArray = a.split(":")
	var ziel := t[1] if t.size() > 1 else ""
	match t[0]:
		"hq":
			return "Firmensitz platzieren"
		"skill":
			return "Skill setzen"
		"vertrag":
			return "Vertrag annehmen"
		"lizenz":
			return "Lizenz " + ziel
		"strasse":
			return "Straße zu " + ziel
		"gleis":
			return "Gleis " + ziel.replace(">", " → ")
		"fahrzeug":
			return "Fahrzeug " + ziel.replace(">", " → ")
		"zug":
			return "Zug " + ziel.replace(">", " → ")
		"firma":
			return ziel + " kaufen"
		"ausbau":
			return ziel + " ausbauen"
		"hq_ausbau":
			return "Firmensitz ausbauen"
		"hq_anbau":
			return "Anbau am Firmensitz"
		"ersetzen":
			return "Fahrzeug ersetzen"
	return a


func leiste_neu() -> void:
	if ps == null or leiste == null:
		return
	var n_ang: int = ps.vertraege_angebote.size()
	var n_akt: int = ps.vertraege_aktiv.size()
	leiste_kn["vertrag"].text = "Verträge%s  [V]" % ((" · %d neu" % n_ang) if n_ang > 0 else ((" · %d laufen" % n_akt) if n_akt > 0 else ""))
	var frei: int = ps.skillpunkte_frei()
	leiste_kn["skill"].text = "Skills%s  [K]" % ((" · %d Punkt%s frei" % [frei, "" if frei == 1 else "e"]) if frei > 0 else "")
	leiste_kn["hq"].text = "%s  [H]" % ("Firmensitz platzieren" if not ps.hq_platziert else String(ps._hq_stufe_daten().get("name", "Firmensitz")))
	leiste_kn["gleis"].text = "Gleis  [G]" if ps.gleis_frei() else "Gleis ab %d" % int(ps.bau_regel("gleis").get("ab_jahr", 0))
	_puls(leiste_kn["hq"], not ps.hq_platziert)
	_puls(leiste_kn["vertrag"], n_ang > 0)
	_puls(leiste_kn["skill"], frei > 0)
	var akt: Array = ps.aktionen_moeglich()
	werte["aktionen"] = akt
	var gezeigt: Array = []
	var arten := {}
	for a in akt:
		var art := String(a).split(":")[0]
		if arten.has(art):
			continue
		arten[art] = true
		gezeigt.append(_akt_text(String(a)))
		if gezeigt.size() >= 4:
			break
	lbl_moeglich.text = ("Jetzt möglich: " + " · ".join(PackedStringArray(gezeigt)) + (" · …" if akt.size() > gezeigt.size() else "")) if not gezeigt.is_empty() else "Gerade nichts bezahlbar: Einnahmen abwarten oder Kredit nehmen."


func _puls(b: Button, an: bool) -> void:
	b.modulate = Color(1.0, 1.0, 1.0) if not an else Color(1.0, 0.92 + 0.08 * sin(_ring_t * 5.0), 0.7 + 0.2 * sin(_ring_t * 5.0))


func naechster_text() -> String:
	var m: Dictionary = ps.naechster_meilenstein()
	if m.is_empty():
		return "Alle Meilensteine erreicht. Baue dein Netz weiter aus."
	return "%s (Meilenstein „%s“, +%d Skillpunkt)" % [String(m["tipp"]), String(m["name"]), int(m.get("skillpunkte", 0))]


# ------------------------------------------------------------------ Baumodus (Straße, Gleis)

func _baue_modus() -> void:
	var k := _karte("Bauen", C_BAU, 620.0, modus_ende, "modus")
	modus_panel = k[0]
	modus_vb = k[1]
	modus_panel.name = "BauModus"
	modus_panel.anchor_left = 0.5
	modus_panel.anchor_right = 0.5
	modus_panel.anchor_top = 1.0
	modus_panel.anchor_bottom = 1.0
	modus_panel.offset_left = -260.0
	modus_panel.offset_right = 360.0
	modus_panel.offset_bottom = -14.0
	modus_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	modus_panel.visible = false
	add_child(modus_panel)


func bau_start(art: String, start: Variant = null) -> void:
	if not ps.hq_platziert:
		melde_fehler({"fehler": "kein_hq"})
		return
	var rg: Dictionary = ps.bau_regel(art)
	if ps.kalenderjahr() < int(rg.get("ab_jahr", 0)):
		melde_fehler({"fehler": "noch_nicht_verfuegbar", "ab_jahr": int(rg["ab_jahr"])})
		return
	hq_modus_ende()
	uw.modus_ende()
	bau_art = art
	bau_punkte = PackedVector2Array()
	bau_angebot = {}
	if start is Vector2:
		bau_punkte.append(ps.fang(art, start)["pos"])
	modus_panel.visible = true
	_marker_neu()
	modus_neu()


func modus_ende() -> void:
	bau_art = ""
	bau_punkte = PackedVector2Array()
	bau_angebot = {}
	modus_panel.visible = false
	vorschau_mi.visible = false
	_marker_neu()


func _fang_text(f: Dictionary) -> String:
	match String(f.get("typ", "")):
		"knoten":
			return "am Netz"
		"betrieb":
			return String(f["name"])
		"bahnhof":
			return "Bahnhof " + String(f["name"])
		"bahnhof_neu":
			return "neuer Bahnhof " + String(f["name"])
	return "freies Ende"


func modus_neu() -> void:
	if bau_art == "":
		return
	_leeren(modus_vb, 2)
	var rg: Dictionary = ps.bau_regel(bau_art)
	(modus_vb.get_child(0).get_node("Titel") as Label).text = "%s bauen" % String(rg.get("name", bau_art))
	var pkt := PackedVector2Array(bau_punkte)
	if _maus_boden is Vector2 and not bau_punkte.is_empty():
		pkt.append(_maus_boden)
	werte["bau_punkte"] = bau_punkte.size()
	if bau_punkte.is_empty():
		var ziel := "an einer Straße oder einem Betrieb ohne Anschluss (Ring)" if bau_art == "strasse" else "an einem Betrieb, Ort oder Gleis (Ring)"
		modus_vb.add_child(_umbruch(_lbl("Klicke den Startpunkt " + ziel + ". Danach Zwischenpunkte, zuletzt das Ziel.", 16), 590))
		modus_vb.add_child(_lbl("%s je Feld (25 m)%s · Brücken ×%d" % [geld(int(rg.get("kosten_cent_pro_feld", 0))),
			(" · Unterhalt %s/min je Feld" % _cent(int(rg.get("unterhalt_cent_pro_feld_pro_periode", 0)))) if int(rg.get("unterhalt_cent_pro_feld_pro_periode", 0)) > 0 else "",
			int(rg.get("bruecke_faktor_promille", 1000)) / 1000], 15, C_MATT))
		bau_angebot = {}
	elif pkt.size() >= 2:
		bau_angebot = ps.bau_angebot(bau_art, pkt)
		if bau_angebot.get("ok", false):
			var q := bau_angebot
			werte["bau_kosten"] = int(q["kosten_cent"])
			modus_vb.add_child(_lbl("%s m · %s%s%s" % [uw._tsd(int(q["laenge_m"])), geld(int(q["kosten_cent"])),
				(" · Brücke %d m" % int(q["bruecke_m"])) if int(q["bruecke_m"]) > 0 else "",
				(" · Unterhalt %s/min" % geld(int(q["unterhalt_cent"]))) if int(q["unterhalt_cent"]) > 0 else ""], 20, C_OK if q["kaufbar"] else C_WARN))
			modus_vb.add_child(_lbl("Start: %s  →  Ende: %s" % [_fang_text(q["start"]), _fang_text(q["ende"])], 16))
			if not q["kaufbar"]:
				modus_vb.add_child(_lbl("▲ Es fehlen %s." % uw.fehlbetrag(int(q["fehlt_cent"])), 16, C_WARN))
			elif String(q["ende"]["typ"]) == "frei":
				modus_vb.add_child(_lbl("Das Ende ist frei: Klick auf ein Ziel (Ring) schließt an, Enter baut bis hierher.", 15, C_MATT))
		else:
			var ft := fehlertext(bau_angebot)
			modus_vb.add_child(_umbruch(_lbl("■ " + (ft if ft != "" else String(bau_angebot.get("fehler", "?"))), 16, C_BAD), 590))
	else:
		modus_vb.add_child(_lbl("Bewege die Maus zum nächsten Punkt.", 16, C_MATT))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	var ok: bool = bau_angebot.get("ok", false) and bau_angebot.get("kaufbar", false) and bau_punkte.size() >= 2
	hb.add_child(_knopf("Bauen · Enter", "bau_fertig", bau_fertig, C_OK if ok else Color.TRANSPARENT, not ok))
	hb.add_child(_knopf("Punkt zurück · Entf", "bau_zurueck", bau_zurueck, Color.TRANSPARENT, bau_punkte.is_empty()))
	hb.add_child(_knopf("Abbrechen · Esc", "bau_abbrechen", modus_ende))
	modus_vb.add_child(hb)
	_vorschau_mesh(pkt, bau_angebot)


func _cent(c: int) -> String:
	return "%d,%02d $" % [c / 100, c % 100]


## Klick im Baumodus (Weltpunkt in m). Rastet ein; ein Klick auf ein Ziel (kein freies Ende) baut sofort.
func klick_boden(p: Vector2) -> void:
	if bau_art == "":
		return
	var f: Dictionary = ps.fang(bau_art, p)
	if bau_punkte.is_empty():
		if String(f["typ"]) == "frei":
			melde_fehler({"fehler": "kein_anschluss"})
			return
		bau_punkte.append(f["pos"])
		modus_neu()
		return
	bau_punkte.append(f["pos"] if String(f["typ"]) != "frei" else p)
	if String(f["typ"]) != "frei":
		var q: Dictionary = ps.bau_angebot(bau_art, bau_punkte)
		if q.get("ok", false) and q.get("kaufbar", false):
			bau_fertig()
			return
		if not q.get("ok", false):
			melde_fehler(q)
			bau_punkte.remove_at(bau_punkte.size() - 1)
		else:
			melde_fehler({"fehler": "guthaben_reicht_nicht", "fehlt_cent": int(q["fehlt_cent"])})
	modus_neu()


func bau_zurueck() -> void:
	if not bau_punkte.is_empty():
		bau_punkte.remove_at(bau_punkte.size() - 1)
	modus_neu()


func bau_fertig() -> Dictionary:
	if bau_art == "" or bau_punkte.size() < 2:
		melde_fehler({"fehler": "zu_wenig_punkte"})
		return {"ok": false, "fehler": "zu_wenig_punkte"}
	var art := bau_art
	var r: Dictionary = ps.bauen(art, bau_punkte)
	if not r.get("ok", false):
		melde_fehler(r)
		modus_neu()
		return r
	uw.meldung(String(r.get("text", "Gebaut.")))
	modus_ende()
	_bauwerke_pruefen()
	uw.kopf_neu()
	if uw.auswahl != "":
		uw.panel_neu()
	return r


# ------------------------------------------------------------------ Firmensitz

func hq_knopf() -> void:
	if not ps.hq_platziert:
		hq_modus_start()
	else:
		hq_panel.visible = not hq_panel.visible
		if hq_panel.visible:
			skill_panel.visible = false
			hq_panel_neu()


func hq_modus_start() -> void:
	modus_ende()
	uw.modus_ende()
	hq_panel.visible = false
	hq_modus = true
	hq_vorschau = {}
	modus_panel.visible = true
	_marker_neu()
	hq_modus_neu()


func hq_modus_ende() -> void:
	if not hq_modus:
		return
	hq_modus = false
	modus_panel.visible = bau_art != ""
	hq_geist.visible = false
	if _ring_t > 3.0 or not ps.hq_platziert:
		hq_ring.visible = false
	_marker_neu()


func hq_modus_neu() -> void:
	if not hq_modus:
		return
	_leeren(modus_vb, 2)
	(modus_vb.get_child(0).get_node("Titel") as Label).text = "Firmensitz platzieren" if not ps.hq_platziert else "Firmensitz umziehen"
	var v := hq_vorschau
	if v.is_empty():
		modus_vb.add_child(_umbruch(_lbl("Bewege die Maus in einen Ort (Erlenbach, Lindenfurt, Hasenwinkel). Die Vorschau zeigt, was der Platz bringt. Klick setzt den Firmensitz.", 16), 590))
	elif not v.get("ok", false):
		var ft := fehlertext(v)
		modus_vb.add_child(_umbruch(_lbl("■ " + (ft if ft != "" else String(v.get("fehler", "?"))), 16, C_BAD), 590))
	else:
		werte["hq_vorschau"] = v
		modus_vb.add_child(_lbl("%s (%s) · Einflussradius %d Felder" % [v["ort"], {"dorf": "Dorf", "kleinstadt": "Kleinstadt", "weiler": "Weiler"}.get(String(v["klasse"]), String(v["klasse"])),
			int(v["radius_felder"])], 20, C_GOLD))
		modus_vb.add_child(_lbl("● %d von %d Betrieben im Radius: Lizenz dort 30 %% billiger, außerhalb +2,5 %% je Feld" % [int(v["im_radius_n"]), v["betriebe"].size()], 16,
			C_OK if int(v["im_radius_n"]) >= 4 else C_WARN))
		if int(v["heimat_bonus_promille"]) > 0:
			modus_vb.add_child(_lbl("● Heimatort %s: jede Lieferung dorthin bringt +%d %% Ertrag" % [v["heimat"], int(v["heimat_bonus_promille"]) / 10], 16, C_OK))
		else:
			modus_vb.add_child(_lbl("○ Kein Heimatbonus: %s kauft selbst nichts" % v["ort"], 16, C_MATT))
		var gr := GridContainer.new()
		gr.columns = 3
		gr.add_theme_constant_override("h_separation", 18)
		gr.add_theme_constant_override("v_separation", 0)
		for b in v["betriebe"]:
			gr.add_child(_lbl("%s %s · %s" % ["●" if b["im_radius"] else "○", b["name"], geld(int(b["lizenz_cent"]))], 14, C_CREME if b["im_radius"] else C_MATT))
		modus_vb.add_child(gr)
		modus_vb.add_child(_lbl("Alle Lizenzen zusammen: %s%s" % [geld(int(v["lizenz_summe_cent"])),
			(" · Umzug kostet %s" % geld(int(v["kosten_cent"]))) if int(v["kosten_cent"]) > 0 else " · Gründung kostenlos, 1 Lizenz im Radius gratis"], 15, C_MATT))
	var hb := HBoxContainer.new()
	hb.add_child(_knopf("Abbrechen · Esc", "hq_abbrechen", hq_modus_ende))
	modus_vb.add_child(hb)


## Standortvorschau für einen Weltpunkt zeigen (Mausbewegung im HQ-Modus).
func hq_zeigen(p: Vector2) -> void:
	hq_vorschau = ps.hq_vorschau(p)
	_hq_vorschau_3d(p)
	hq_modus_neu()


## Firmensitz an einem Weltpunkt setzen (Klick im HQ-Modus).
func hq_setzen(p: Vector2) -> Dictionary:
	var r: Dictionary = ps.hq_platzieren(p)
	if not r.get("ok", false):
		melde_fehler(r)
		return r
	uw.meldung("Firmensitz in %s gegründet. %d Betriebe im Umkreis, dort sind Lizenzen 30 %% billiger." % [r["ort"], int(r["im_radius_n"])])
	hq_modus = false
	hq_geist.visible = false
	modus_panel.visible = false
	_ring_t = 0.0
	_ring_setzen(p, float(ps.eco.hq_radius_felder) * 25.0, C_GOLD)
	_hq_haus_neu()
	_marker_neu()
	leiste_neu()
	uw.kopf_neu()
	return r


func _baue_hq_panel() -> void:
	var k := _karte("Firmensitz", C_HQ, 520.0, func(): hq_panel.visible = false, "hq")
	hq_panel = k[0]
	hq_vb = k[1]
	hq_panel.name = "HqPanel"
	_mitte(hq_panel, -40.0)
	hq_panel.visible = false


func hq_panel_neu() -> void:
	if not hq_panel.visible:
		return
	_leeren(hq_vb, 2)
	var sd: Dictionary = ps._hq_stufe_daten()
	(hq_vb.get_child(0).get_node("Titel") as Label).text = "%s in %s" % [String(sd.get("name", "Firmensitz")), ps.hq_ort]
	werte["hq_stufe"] = ps.hq_stufe
	hq_vb.add_child(_lbl("Stufe %d von 3 · Einflussradius %d Felder · %d Verträge zugleich · Kreditrahmen %s" % [ps.hq_stufe, int(ps.eco.hq_radius_felder),
		ps.vertraege_max(), geld(ps.credit.limit_cent)], 16))
	var heimat := ""
	for site in ps.eco.demo_site_bonus:
		heimat = "Heimatort %s: +%d %% Ertrag auf Lieferungen dorthin" % [ps.hq_ort, int(ps.eco.demo_site_bonus[site]) / 10]
	hq_vb.add_child(_lbl(heimat if heimat != "" else "Kein Heimatbonus an diesem Standort", 15, C_MATT))
	var q: Dictionary = ps.hq_ausbau_angebot()
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", _stil(C_BG2, Color(C_HQ, 0.4), 1, 6, 10))
	var bv := VBoxContainer.new()
	box.add_child(bv)
	if q.get("ok", false):
		bv.add_child(_lbl("Ausbau: %s" % String(q.get("name", "")), 18, C_GOLD))
		bv.add_child(_umbruch(_lbl("Radius +%d Felder · %d Verträge zugleich · %d Anbauten · Kreditrahmen +%s%s · Unterhalt %s/min" % [
			int(q.get("radius_bonus_felder", 0)) - int(sd.get("radius_bonus_felder", 0)), int(q.get("vertraege_max", 2)), int(q.get("anbauten_max", 1)),
			geld(int(q.get("kredit_bonus_cent", 0)) - int(sd.get("kredit_bonus_cent", 0))),
			" · +1 Skillpunkt" if int(q.get("skillpunkte", 0)) > 0 else "", geld(int(q.get("unterhalt_cent_pro_periode", 0)))], 15), 470))
		var b := _knopf("Ausbauen · %s" % geld(int(q["kosten_cent"])), "hq_ausbau", hq_ausbauen, C_HQ if q["kaufbar"] else Color.TRANSPARENT, not q["kaufbar"])
		if not q["kaufbar"]:
			b.tooltip_text = "Es fehlen %s (nur aus der Kasse, nicht mit Kredit)." % uw.fehlbetrag(int(q["fehlt_cent"]))
		bv.add_child(b)
	else:
		bv.add_child(_lbl("Höchste Stufe erreicht.", 16, C_OK))
	hq_vb.add_child(box)
	hq_vb.add_child(_lbl("Anbauten (%d von %d Plätzen belegt)" % [ps.hq_anbauten.size(), int(sd.get("anbauten_max", 1))], 16, C_MATT))
	for an in ps.daten["hq"]["anbauten"]:
		var id := String(an["id"])
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		var gebaut: bool = id in ps.hq_anbauten
		var l := _lbl("%s %s: %s" % ["●" if gebaut else "○", an["name"], an["text"]], 15, C_OK if gebaut else C_CREME)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(l)
		if not gebaut:
			var aq: Dictionary = ps.hq_anbau_angebot(id)
			var kauf: bool = aq.get("ok", false) and aq.get("kaufbar", false)
			hb.add_child(_knopf("Bauen · %s" % geld(int(an["kosten_cent"])), "hq_anbau_" + id, hq_anbauen.bind(id), C_HQ if kauf else Color.TRANSPARENT, not kauf))
		hq_vb.add_child(hb)
	var fuss := HBoxContainer.new()
	fuss.add_child(_knopf("Umziehen · %s" % geld(int(ps.daten["hq"].get("umzug_cent", 0))), "hq_umzug", hq_modus_start))
	hq_vb.add_child(fuss)


func hq_ausbauen() -> Dictionary:
	var r: Dictionary = ps.hq_ausbauen()
	if r.get("ok", false):
		uw.meldung("Firmensitz ausgebaut: %s. Radius +, mehr Verträge, mehr Kredit." % String(r.get("name", "")))
		_ring_t = 0.0
		_ring_setzen(ps.hq_pos, float(ps.eco.hq_radius_felder) * 25.0, C_GOLD)
		_hq_haus_neu()
	else:
		melde_fehler(r)
	hq_panel_neu()
	uw.kopf_neu()
	return r


func hq_anbauen(id: String) -> Dictionary:
	var r: Dictionary = ps.hq_anbauen(id)
	if r.get("ok", false):
		uw.meldung("%s gebaut. %s" % [String(r.get("name", id)), String(r.get("text", ""))])
		_hq_haus_neu()
	else:
		melde_fehler(r)
	hq_panel_neu()
	uw.kopf_neu()
	return r


# ------------------------------------------------------------------ Verträge

func _baue_vertraege() -> void:
	var k := _karte("Verträge", C_VERTRAG, 430.0, func(): vertrag_panel.visible = false, "vertrag")
	vertrag_panel = k[0]
	vertrag_vb = k[1]
	vertrag_panel.name = "VertragPanel"
	vertrag_panel.offset_left = 8.0
	vertrag_panel.offset_top = 176.0
	vertrag_panel.visible = false
	add_child(vertrag_panel)


func vertraege_umschalten() -> void:
	vertrag_panel.visible = not vertrag_panel.visible
	_sig_vertrag = ""
	vertraege_neu()


func _zeit(ticks: int) -> String:
	var s := maxi(0, ticks) / 10
	return "%d:%02d min" % [s / 60, s % 60]


func _balken(anteil: float, farbe: Color, breite := 380.0) -> Control:
	var hg := ColorRect.new()
	hg.color = Color(0, 0, 0, 0.4)
	hg.custom_minimum_size = Vector2(breite, 12)
	var v := ColorRect.new()
	v.color = farbe
	v.size = Vector2(breite * clampf(anteil, 0.0, 1.0), 12)
	hg.add_child(v)
	return hg


func vertraege_neu() -> void:
	if not vertrag_panel.visible:
		return
	_leeren(vertrag_vb, 2)
	var t: int = ps.sim.tick_count
	var ruf: int = ps.ruf
	var sterne := ""
	for i in 5:
		sterne += "★" if i < ruf else "☆"
	var rt := "Ruf %s%s" % [sterne, (" (%+d): Prämien %+d %%" % [ruf, ruf * int(ps.daten["vertraege"].get("ruf_praemie_promille_je_punkt", 0)) / 10]) if ruf != 0 else ""]
	vertrag_vb.add_child(_lbl("%s · erfüllt %d · verfehlt %d · %d von %d Plätzen belegt" % [rt, ps.vertraege_erfuellt, ps.vertraege_verfehlt,
		ps.vertraege_aktiv.size(), ps.vertraege_max()], 14, C_MATT))
	if ps.vertraege_angebote.is_empty() and ps.vertraege_aktiv.is_empty():
		vertrag_vb.add_child(_umbruch(_lbl("Noch kein Angebot. Orte und Betriebe melden sich alle paar Minuten: eine Menge, eine Frist, eine Prämie.", 16), 400))
	if not ps.vertraege_aktiv.is_empty():
		vertrag_vb.add_child(_lbl("LÄUFT", 15, C_GOLD, true))
	for v in ps.vertraege_aktiv:
		var box := PanelContainer.new()
		box.add_theme_stylebox_override("panel", _stil(C_BG2, Color(C_GOLD, 0.5), 1, 6, 10))
		var bv := VBoxContainer.new()
		bv.add_theme_constant_override("separation", 4)
		box.add_child(bv)
		var ant := float(v["geliefert"]) / maxf(1.0, float(v["menge"]))
		var zeit_ant := float(t - int(v["start_tick"])) / maxf(1.0, float(v["frist_ticks"]))
		var farbe := C_OK if ant >= zeit_ant else (C_WARN if ant >= zeit_ant - 0.25 else C_BAD)
		bv.add_child(_lbl("%s: %d %s" % [v["ort"], int(v["menge"]), ps.gutname(v["gut"])], 18))
		bv.add_child(_balken(ant, farbe))
		bv.add_child(_lbl("%d / %d geliefert · noch %s · Prämie %s%s" % [int(v["geliefert"]), int(v["menge"]), _zeit(int(v["ende_tick"]) - t),
			geld(ps.vertrag_praemie(v)), (" + %d %% Preisbonus" % (int(v["bonus_promille"]) / 10)) if int(v["bonus_promille"]) > 0 else ""], 14, farbe))
		vertrag_vb.add_child(box)
	if not ps.vertraege_angebote.is_empty():
		vertrag_vb.add_child(_lbl("ANGEBOTE", 15, C_VERTRAG.lightened(0.3), true))
	for v in ps.vertraege_angebote:
		var box := PanelContainer.new()
		box.add_theme_stylebox_override("panel", _stil(C_BG2, Color(C_VERTRAG, 0.7), 1, 6, 10))
		var bv := VBoxContainer.new()
		bv.add_theme_constant_override("separation", 4)
		box.add_child(bv)
		bv.add_child(_lbl("%s sucht %d %s" % [v["ort"], int(v["menge"]), ps.gutname(v["gut"])], 18))
		bv.add_child(_lbl("Frist %s · Prämie %s · bei Verfehlen −%s" % [_zeit(int(v["frist_ticks"])), geld(ps.vertrag_praemie(v)), geld(int(v["strafe_cent"]))], 15))
		var je_min := float(v["menge"]) / (float(v["frist_ticks"]) / 600.0)
		bv.add_child(_lbl("Das sind %.0f E je Minute%s · Angebot gilt noch %s" % [je_min,
			(" · +%d %% auf den Erlös dieser Lieferungen" % (int(v["bonus_promille"]) / 10)) if int(v["bonus_promille"]) > 0 else "", _zeit(int(v["angebot_bis_tick"]) - t)], 14, C_MATT))
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		var voll: bool = ps.vertraege_aktiv.size() >= ps.vertraege_max()
		hb.add_child(_knopf("Annehmen", "vertrag_an_%d" % int(v["id"]), vertrag_annehmen.bind(int(v["id"])), C_OK if not voll else Color.TRANSPARENT, voll))
		hb.add_child(_knopf("Ablehnen", "vertrag_ab_%d" % int(v["id"]), vertrag_ablehnen.bind(int(v["id"]))))
		bv.add_child(hb)
		vertrag_vb.add_child(box)


func vertrag_annehmen(id: int) -> Dictionary:
	var r: Dictionary = ps.vertrag_annehmen(id)
	if r.get("ok", false):
		uw.meldung("Vertrag angenommen: %d %s nach %s in %s. Prämie %s." % [int(r["menge"]), ps.gutname(r["gut"]), r["ort"], _zeit(int(r["frist_ticks"])), geld(ps.vertrag_praemie(r))])
	else:
		melde_fehler(r)
	_sig_vertrag = ""
	vertraege_neu()
	leiste_neu()
	return r


func vertrag_ablehnen(id: int) -> Dictionary:
	var r: Dictionary = ps.vertrag_ablehnen(id)
	if r.get("ok", false):
		uw.meldung("Angebot abgelehnt. Das kostet nichts.", 3.0)
	else:
		melde_fehler(r)
	_sig_vertrag = ""
	vertraege_neu()
	leiste_neu()
	return r


# ------------------------------------------------------------------ Skilltree

func _baue_skills() -> void:
	var k := _karte("Skilltree", C_SKILL, 900.0, func(): skill_panel.visible = false, "skill")
	skill_panel = k[0]
	skill_vb = k[1]
	skill_panel.name = "SkillPanel"
	_mitte(skill_panel, -20.0)
	skill_panel.visible = false


func skills_umschalten() -> void:
	skill_panel.visible = not skill_panel.visible
	if skill_panel.visible:
		hq_panel.visible = false
	_sig_skill = ""
	skills_neu()


func skills_neu() -> void:
	if not skill_panel.visible:
		return
	_leeren(skill_vb, 2)
	var frei: int = ps.skillpunkte_frei()
	werte["skillpunkte_frei"] = frei
	var kopf := HBoxContainer.new()
	var kl := _lbl("%d Punkt%s frei" % [frei, "" if frei == 1 else "e"], 22, C_OK if frei > 0 else C_MATT)
	kl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kopf.add_child(kl)
	kopf.add_child(_lbl("verdient %d · gesetzt %d · Punkte gibt es für Meilensteine" % [ps.skillpunkte, ps.skills.size()], 15, C_MATT))
	skill_vb.add_child(kopf)
	var spalten := HBoxContainer.new()
	spalten.add_theme_constant_override("separation", 14)
	for ast in ps.daten["skilltree"]["aeste"]:
		var farbe := Color(String(ast.get("farbe", "#D9B25A")))
		var sv := VBoxContainer.new()
		sv.add_theme_constant_override("separation", 0)
		sv.custom_minimum_size = Vector2(280, 0)
		var band := PanelContainer.new()
		band.add_theme_stylebox_override("panel", _stil(farbe.darkened(0.55), farbe, 1, 6, 8))
		var bandv := VBoxContainer.new()
		bandv.add_theme_constant_override("separation", 0)
		bandv.add_child(_lbl(String(ast["name"]).to_upper(), 18, farbe.lightened(0.35), true))
		bandv.add_child(_umbruch(_lbl(String(ast["text"]), 13, C_MATT), 250))
		band.add_child(bandv)
		sv.add_child(band)
		var kn: Array = ast["knoten"]
		for i in kn.size():
			var id := String(kn[i]["id"])
			var zst: String = ps.skill_zustand(id)
			var steg := ColorRect.new()
			steg.custom_minimum_size = Vector2(4, 14)
			steg.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			steg.color = farbe if zst == "gesetzt" or (zst == "frei") else Color(0.35, 0.3, 0.25)
			sv.add_child(steg)
			var b := Button.new()
			b.name = "skill_" + id
			b.focus_mode = Control.FOCUS_NONE
			b.custom_minimum_size = Vector2(280, 76)
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.add_theme_font_size_override("font_size", 15)
			b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			var marke := "✓ " if zst == "gesetzt" else ("◆ " if zst == "frei" else "· ")
			b.text = "%s%s\n%s" % [marke, kn[i]["name"], kn[i]["text"]]
			var bg := farbe.darkened(0.25) if zst == "gesetzt" else (C_BG2 if zst == "frei" else Color(0.12, 0.11, 0.1, 0.9))
			var rf := farbe.lightened(0.2) if zst != "gesperrt" else Color(0.3, 0.27, 0.23)
			b.add_theme_stylebox_override("normal", _stil(bg, rf, 2 if zst == "frei" and frei > 0 else 1, 8, 10))
			b.add_theme_stylebox_override("hover", _stil(bg.lightened(0.08), C_GOLD if zst == "frei" else rf, 2, 8, 10))
			b.add_theme_stylebox_override("pressed", _stil(bg.darkened(0.1), C_GOLD, 2, 8, 10))
			var tf := C_CREME if zst != "gesperrt" else Color(0.55, 0.5, 0.45)
			b.add_theme_color_override("font_color", tf)
			b.add_theme_color_override("font_hover_color", Color.WHITE if zst == "frei" else tf)
			b.tooltip_text = {"gesetzt": "Gesetzt.", "frei": "Klick setzt diesen Skill (1 Punkt)." if frei > 0 else "Kein Punkt frei: erreiche den nächsten Meilenstein.",
				"gesperrt": "Erst den Skill darüber setzen."}[zst]
			b.pressed.connect(skill_klick.bind(id))
			knoepfe["skill_" + id] = b
			sv.add_child(b)
		spalten.add_child(sv)
	skill_vb.add_child(spalten)
	# Meilensteine
	var ml := HFlowContainer.new()
	ml.add_theme_constant_override("h_separation", 12)
	ml.add_theme_constant_override("v_separation", 2)
	for m in ps.daten["meilensteine"]:
		var ok: bool = ps.meilensteine_erreicht.has(String(m["id"]))
		ml.add_child(_lbl("%s %s" % ["●" if ok else "○", m["name"]], 13, C_OK if ok else C_MATT))
	skill_vb.add_child(_lbl("MEILENSTEINE %d / %d" % [ps.meilensteine_erreicht.size(), ps.daten["meilensteine"].size()], 14, C_GOLD, true))
	skill_vb.add_child(ml)
	var fuss := HBoxContainer.new()
	fuss.add_theme_constant_override("separation", 12)
	var nt := _umbruch(_lbl("Nächster Punkt: " + naechster_text(), 14, C_CREME), 640)
	nt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fuss.add_child(nt)
	fuss.add_child(_knopf("Zurücksetzen (kostenlos)", "skill_reset", skill_reset, Color.TRANSPARENT, ps.skills.is_empty()))
	skill_vb.add_child(fuss)


func skill_klick(id: String) -> Dictionary:
	var r: Dictionary = ps.skill_setzen(id)
	if r.get("ok", false):
		uw.meldung("Skill gesetzt: %s. %s" % [r["name"], r["text"]])
	else:
		melde_fehler(r)
	_sig_skill = ""
	skills_neu()
	leiste_neu()
	uw.kopf_neu()
	return r


func skill_reset() -> void:
	var r: Dictionary = ps.skill_zuruecksetzen()
	uw.meldung("Skills zurückgesetzt: %d Punkte wieder frei." % int(r.get("punkte", 0)))
	_sig_skill = ""
	skills_neu()
	leiste_neu()


# ------------------------------------------------------------------ Start, Hilfe, Menü

const HILFE := [
	["1", "Firmensitz", "Taste H: frei in Erlenbach, Lindenfurt oder Hasenwinkel platzieren. Die Vorschau zeigt Radius, Lizenzpreise und Heimatbonus."],
	["2", "Erste Kette", "Gut Kuppenhof anklicken → Lizenz → „Linie von hier“ → Erlenmühle → Erlenbach. Mehl bringt das erste Geld."],
	["3", "Verträge", "Taste V: Orte und Betriebe bieten Menge, Frist und Prämie. Annehmen lohnt, wenn deine Linie die Menge schafft."],
	["4", "Bauen", "Taste B Straße, ab 1824 Taste G Gleis: Start klicken, Zwischenpunkte, Ziel klicken. Forsthaus, Gruben und Hütte brauchen einen Anschluss."],
	["5", "Skills", "Taste K: Jeder Meilenstein bringt einen Punkt. Drei Äste, du kannst nicht alles haben (Zurücksetzen ist frei)."],
	["6", "Wachsen", "Neue Modelle (1822, 1824, 1826, 1828): Fahrzeug anklicken → Ersetzen. Betriebe kaufen ab 1823, Firmensitz ausbauen."],
]


func _baue_start() -> void:
	var k := _karte("Mega Tycoon · Demo 1820–1830", C_GOLD, 760.0, start_schliessen, "start")
	start_panel = k[0]
	start_panel.name = "StartPanel"
	var vb: VBoxContainer = k[1]
	vb.add_child(_umbruch(_lbl("30 Minuten, drei Warenketten, ein Firmensitz. Du beginnst mit 6.000 $ und ohne Linie. 3 Minuten sind ein Jahr; neue Fahrzeuge kommen im Zeitraffer.", 17), 720))
	for h in HILFE:
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 12)
		var nr := _lbl(String(h[0]), 26, C_GOLD, true)
		nr.custom_minimum_size = Vector2(26, 0)
		hb.add_child(nr)
		var tv := VBoxContainer.new()
		tv.add_theme_constant_override("separation", 0)
		tv.add_child(_lbl(String(h[1]), 17, C_GOLD))
		tv.add_child(_umbruch(_lbl(String(h[2]), 15, C_CREME), 660))
		hb.add_child(tv)
		vb.add_child(hb)
	vb.add_child(_umbruch(_lbl("Kamera: WASD schieben, Q/E drehen, Mausrad zoomen, 1–5 Ansichten. Leertaste Pause, Tempo oben rechts. Die Zeile „Jetzt möglich“ sagt dir immer, was gerade geht.", 14, C_MATT), 720))
	var hb2 := HBoxContainer.new()
	hb2.alignment = BoxContainer.ALIGNMENT_CENTER
	hb2.add_child(_knopf("Los geht's: Firmensitz platzieren", "start_los", start_schliessen, C_GOLD))
	vb.add_child(hb2)
	_mitte(start_panel, -10.0)
	welt.setze_tempo(0)


func start_schliessen() -> void:
	var war_start: bool = start_panel.visible and not ps.hq_platziert and not hilfe_offen
	start_panel.visible = false
	hilfe_offen = false
	if welt.sim_tempo == 0:
		welt.setze_tempo(1)
	if war_start:
		welt.setze_preset(2)                                 # Blick auf Erlenbach
		hq_modus_start()


func hilfe_umschalten() -> void:
	hilfe_offen = not start_panel.visible
	start_panel.visible = not start_panel.visible
	if knoepfe.has("start_los"):
		(knoepfe["start_los"] as Button).text = "Weiter spielen" if ps.hq_platziert else "Los geht's: Firmensitz platzieren"


func _baue_menue() -> void:
	var k := _karte("Zurück ins Menü?", C_BAD, 460.0, func(): menue_panel.visible = false, "menue")
	menue_panel = k[0]
	menue_panel.name = "MenuePanel"
	var vb: VBoxContainer = k[1]
	vb.add_child(_umbruch(_lbl("Dein Spielstand geht verloren, Speichern kommt in einer späteren Version.", 16), 420))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	hb.add_child(_knopf("Weiter spielen", "menue_weiter", func(): menue_panel.visible = false, C_OK))
	hb.add_child(_knopf("Zum Menü", "menue_ja", func(): welt.get_tree().change_scene_to_file(welt.START_MENU)))
	vb.add_child(hb)
	_mitte(menue_panel)
	menue_panel.visible = false


# ------------------------------------------------------------------ Eingabe

## true = verbraucht. Reihenfolge Esc: Startbild → Baumodus/HQ-Modus → Panels → (ui_welt) → Menü-Abfrage.
func eingabe(ev: InputEvent) -> bool:
	if not (ev is InputEventKey) or not ev.pressed or ev.echo:
		return false
	var k: int = ev.keycode
	if k == KEY_ESCAPE:
		if menue_panel.visible:
			menue_panel.visible = false
			return true
		if start_panel.visible:
			start_schliessen()
			return true
		if bau_art != "":
			modus_ende()
			return true
		if hq_modus:
			hq_modus_ende()
			return true
		for p in [skill_panel, hq_panel, vertrag_panel]:
			if p.visible:
				p.visible = false
				return true
		if uw.modus_von != "" or uw.vorschau_ziel != "" or uw.auswahl != "":
			return false                                    # ui_welt schließt sein Panel/seinen Modus
		menue_panel.visible = true
		return true
	if start_panel.visible and k in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
		start_schliessen()
		return true
	match k:
		KEY_H:
			hq_knopf()
		KEY_B:
			bau_start("strasse")
		KEY_G:
			bau_start("gleis")
		KEY_V:
			vertraege_umschalten()
		KEY_K:
			skills_umschalten()
		KEY_F1:
			hilfe_umschalten()
		KEY_ENTER, KEY_KP_ENTER:
			if bau_art == "":
				return false
			bau_fertig()
		KEY_BACKSPACE, KEY_DELETE:
			if bau_art == "":
				return false
			bau_zurueck()
		_:
			return false
	return true


## Bildschirmpunkt → Geländepunkt (m) oder null.
func boden(pos: Vector2) -> Variant:
	var cam: Camera3D = welt.cam
	var o := cam.project_ray_origin(pos)
	var d := cam.project_ray_normal(pos)
	if d.y > -0.02:
		return null
	var t := 0.0
	var t_alt := 0.0
	for i in 600:
		var p := o + d * t
		var h: float = welt.hoehe_at(p.x, p.z)
		if p.y <= h:
			break
		t_alt = t
		t += maxf(1.5, (p.y - h) * 0.6)
		if t > 12000.0:
			return null
	for i in 12:
		var tm := (t + t_alt) * 0.5
		var pm := o + d * tm
		if pm.y <= welt.hoehe_at(pm.x, pm.z):
			t = tm
		else:
			t_alt = tm
	var r := o + d * t
	return Vector2(r.x, r.z)


## Weltklick. true = von der Demo-UI verbraucht (Baumodus, HQ-Modus, Klick auf den Firmensitz).
func welt_klick(pos: Vector2) -> bool:
	if start_panel.visible:
		return true
	var p = boden(pos)
	if bau_art != "":
		if p is Vector2:
			klick_boden(p)
		return true
	if hq_modus:
		if p is Vector2:
			hq_setzen(p)
		return true
	if ps.hq_platziert and p is Vector2 and (p as Vector2).distance_to(ps.hq_pos) < 14.0 and uw.modus_von == "":
		hq_panel.visible = true
		hq_panel_neu()
		return true
	return false


# ------------------------------------------------------------------ Hooks aus ui_welt

## Zusatzzeilen im Betriebs-/Ortspanel: Anschluss, Bahnhof, Heimatort, Verträge.
func panel_zusatz(nm: String, site: int) -> void:
	if site < 0:
		return
	var vb: VBoxContainer = uw.panel_vb
	var e = ps.eco
	if e.s_kind[site] == 0:
		if not ps.angeschlossen(nm):
			vb.add_child(HSeparator.new())
			vb.add_child(_umbruch(_lbl("▲ Kein Straßenanschluss. Ohne Straße oder Gleis fährt hier nichts ab.", 16, C_WARN), 330))
			vb.add_child(uw._knopf("Straße hierher bauen · B", "demo_strasse", func(): bau_start("strasse", ps.halt_pos(nm)), true))
		var gl: String = "Bahnhof vorhanden" if ps.bahnhof.has(nm) else ("kein Bahnhof" if ps.gleis_frei() else "Gleis ab %d" % int(ps.bau_regel("gleis").get("ab_jahr", 0)))
		vb.add_child(_lbl("Schiene: " + gl, 15, C_OK if ps.bahnhof.has(nm) else C_MATT))
		if ps.gleis_frei():
			vb.add_child(uw._knopf("Gleis von hier bauen · G", "demo_gleis", func(): bau_start("gleis", ps.halt_pos(nm) + Vector2(14, 0) if not ps.bahnhof.has(nm) else ps.halt_pos(nm))))
		var kq: Dictionary = ps.kauf_angebot(nm)
		if kq.get("ok", false) and String(kq.get("grund", "")) == "noch_nicht_verfuegbar":
			vb.add_child(_lbl("Betriebe stehen ab %d zum Verkauf." % int(kq.get("ab_jahr", 0)), 15, C_MATT))
	elif e.demo_site_bonus.has(site):
		vb.add_child(_lbl("● Heimatort deines Firmensitzes: +%d %% Ertrag" % (int(e.demo_site_bonus[site]) / 10), 15, C_OK))
	for v in ps.vertraege_aktiv:
		if v["ort"] == nm:
			vb.add_child(_lbl("Vertrag: %d / %d %s, noch %s" % [int(v["geliefert"]), int(v["menge"]), ps.gutname(v["gut"]), _zeit(int(v["ende_tick"]) - ps.sim.tick_count)], 15, C_GOLD))
	for v in ps.vertraege_angebote:
		if v["ort"] == nm:
			vb.add_child(uw._knopf("Angebot: %d %s für %s · V" % [int(v["menge"]), ps.gutname(v["gut"]), geld(ps.vertrag_praemie(v))], "demo_angebot", func():
				vertrag_panel.visible = true
				vertraege_neu()))


## Modell für die Linienvorschau wählen: Straße, wenn es eine gibt, sonst Gleis; immer das neueste kaufbare Modell.
func modell_waehlen(von: String, nach: String) -> void:
	var hat_strasse: bool = not ps.strassenroute(von, nach).is_empty()
	var hat_gleis: bool = not ps.gleisroute(von, nach).is_empty() and not ps.modelle("zug").is_empty()
	var d: Dictionary = ps.vdef(uw.kauf_def)
	var ist_zug: bool = String(d.get("kategorie", "")) == "zug"
	if uw.kauf_def == "" or d.is_empty() or (ist_zug and not hat_gleis) or (not ist_zug and not hat_strasse):
		uw.kauf_def = ps.def_fuer("zug") if (hat_gleis and not hat_strasse) else ps.def_fuer("fuhrwerk")
	elif not ist_zug:
		uw.kauf_def = ps.def_fuer("fuhrwerk")


## Modell für [+ Fahrzeug] an einer bestehenden Linie: fahren dort Züge, das neueste Zugmodell, sonst das neueste Straßenfahrzeug.
func linie_def(von: String, nach: String) -> Dictionary:
	var a: int = int(ps.stationen[von]["knoten"])
	var b: int = int(ps.stationen[nach]["knoten"])
	var zug := false
	var strasse := false
	for f in ps.fahrzeuge:
		if f["verkauft"] or int(f["von"]) != a or int(f["nach"]) != b:
			continue
		if ps.ist_zug(f):
			zug = true
		else:
			strasse = true
	if (zug and not strasse) or (ps.strassenroute(von, nach).is_empty() and not ps.gleisroute(von, nach).is_empty()):
		return ps.vdef(ps.def_fuer("zug"))
	return ps.vdef(ps.def_fuer("fuhrwerk"))


func text_keine_verbindung(von: String, nach: String) -> String:
	for nm in [von, nach]:
		if not ps.angeschlossen(nm) and not ps.bahnhof.has(nm):
			return "%s hat keinen Anschluss. Baue eine Straße dorthin (Taste B)%s." % [nm, " oder ein Gleis (Taste G)" if ps.gleis_frei() else ""]
	return "Zwischen %s und %s gibt es keine Verbindung. Baue eine Straße (B)%s." % [von, nach, " oder ein Gleis (G)" if ps.gleis_frei() else ""]


## Modellwahl in der Linienvorschau (Knöpfe je kaufbarem Modell, Zug nur mit Gleisverbindung).
func vorschau_modelle(vb: VBoxContainer, von: String, nach: String, n_alt: int) -> void:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	hb.add_child(_lbl("Modell:", 15, C_MATT))
	var liste: Array = []
	if not ps.strassenroute(von, nach).is_empty():
		liste += ps.modelle("fuhrwerk")
	if not ps.gleisroute(von, nach).is_empty():
		liste += ps.modelle("zug")
	for id in liste:
		var d: Dictionary = ps.vdef(id)
		var gewaehlt: bool = id == String(uw.fuhrwerk_def().get("id", ""))
		var b: Button = uw._knopf("%s · %d E · %s" % [d["name"], ps._kap(d), geld(ps._preis(d))], "modell_" + String(id), func():
			uw.kauf_def = String(id)
			uw.vorschau_zeigen(von, nach, n_alt), gewaehlt, false, "vorschau")
		hb.add_child(b)
	vb.add_child(hb)
	if ps.gleis_frei() and ps.gleisroute(von, nach).is_empty():
		vb.add_child(_lbl("Kein Gleis zwischen diesen Orten: mit Taste G bauen, dann fahren hier Züge (60 E und mehr).", 14, C_MATT))


# ------------------------------------------------------------------ Takt

func _process(delta: float) -> void:
	if ps == null:
		return
	_ring_t += delta
	_t += delta
	_t_vorschau += delta
	if _t_vorschau >= 0.06 and (bau_art != "" or hq_modus) and not maus_aus:
		_t_vorschau = 0.0
		var mp := get_viewport().get_mouse_position()
		var p = boden(mp)
		if p is Vector2 and (not (_maus_boden is Vector2) or (_maus_boden as Vector2).distance_to(p) > 1.5):
			_maus_boden = p
			if bau_art != "":
				modus_neu()
			else:
				hq_zeigen(p)
	if hq_ring.visible and not hq_modus and _ring_t > 6.0:
		hq_ring.visible = false
	if _t < 0.3:
		return
	_t = 0.0
	leiste_neu()
	_ereignisse()
	_bauwerke_pruefen()
	var sv := "%d|%d|%d|%d" % [ps.vertraege_angebote.size(), ps.vertraege_aktiv.size(), ps.vertraege_erfuellt + ps.vertraege_verfehlt, ps.sim.tick_count / 10]
	if sv != _sig_vertrag:
		_sig_vertrag = sv
		if not uw._taste_unten:
			vertraege_neu()
	var ss := "%d|%d|%d" % [ps.skillpunkte, ps.skills.size(), ps.meilensteine_erreicht.size()]
	if ss != _sig_skill:
		_sig_skill = ss
		skills_neu()
	var sh := "%d|%d|%d" % [ps.hq_stufe, ps.hq_anbauten.size(), ps.eco.cash_cent / 10000]
	if sh != _sig_hq:
		_sig_hq = sh
		if not uw._taste_unten:
			hq_panel_neu()
	var sf := ""
	for f in ps.fahrzeuge:
		sf += String(f["kat"]) + ","
	if sf != _sig_fz:
		if _sig_fz != "":
			uw._fahrzeuge_neu()
		_sig_fz = sf


## Chronik-Ereignisse der Sim, die nicht schon als Toast kamen (Meilenstein, Vertrag, Freischaltung laufen über ps.meldungen).
func _ereignisse() -> void:
	while _ereignis_idx < ps.ereignisse.size():
		var e: Dictionary = ps.ereignisse[_ereignis_idx]
		_ereignis_idx += 1
		if String(e["art"]) == "meilenstein" and ps.skillpunkte_frei() > 0 and not skill_panel.visible:
			pass


# ------------------------------------------------------------------ 3D: Vorschau, Marker, Firmensitz, Gleis

func _mat(farbe: Color, unschattiert := true) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = farbe
	if unschattiert:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if farbe.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


func _baue_3d() -> void:
	vorschau_mi = MeshInstance3D.new()
	vorschau_mi.name = "BauVorschau"
	vorschau_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	vorschau_mi.visible = false
	raum.add_child(vorschau_mi)
	marker_root = Node3D.new()
	marker_root.name = "Marker"
	raum.add_child(marker_root)
	hq_ring = MeshInstance3D.new()
	hq_ring.name = "HqRing"
	hq_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hq_ring.visible = false
	raum.add_child(hq_ring)
	hq_geist = MeshInstance3D.new()
	hq_geist.name = "HqGeist"
	hq_geist.mesh = Prefabs.mesh_fuer("buergerhaus") if Prefabs.vorhanden("buergerhaus") else BoxMesh.new()
	hq_geist.visible = false
	raum.add_child(hq_geist)
	hq_haus = Node3D.new()
	hq_haus.name = "Firmensitz"
	raum.add_child(hq_haus)


func _h(p: Vector2) -> float:
	return float(welt.hoehe_at(p.x, p.y))


## Band entlang eines Linienzugs am Gelände (Breite b), als Dreiecke.
func _band(pkt: PackedVector2Array, b: float, y_off: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var dicht := PackedVector2Array()
	for i in pkt.size() - 1:
		var n := maxi(1, ceili(pkt[i].distance_to(pkt[i + 1]) / 8.0))
		for j in n:
			dicht.append(pkt[i].lerp(pkt[i + 1], float(j) / n))
	if pkt.size() > 0:
		dicht.append(pkt[-1])
	for i in dicht.size() - 1:
		var a := dicht[i]
		var c := dicht[i + 1]
		var d := (c - a).normalized()
		var r := Vector2(-d.y, d.x) * b * 0.5
		var p1 := Vector3(a.x - r.x, _h(a) + y_off, a.y - r.y)
		var p2 := Vector3(a.x + r.x, _h(a) + y_off, a.y + r.y)
		var p3 := Vector3(c.x - r.x, _h(c) + y_off, c.y - r.y)
		var p4 := Vector3(c.x + r.x, _h(c) + y_off, c.y + r.y)
		for v in [p1, p2, p3, p2, p4, p3]:
			st.add_vertex(v)
	return st.commit()


func _vorschau_mesh(pkt: PackedVector2Array, q: Dictionary) -> void:
	if pkt.size() < 2:
		vorschau_mi.visible = false
		return
	var p := pkt
	if q.get("ok", false):
		p = q["punkte"]
	vorschau_mi.mesh = _band(p, 5.0 if bau_art == "strasse" else 4.0, 0.9)
	var farbe := C_BAD
	if q.get("ok", false):
		farbe = C_OK if q.get("kaufbar", false) else C_WARN
	vorschau_mi.material_override = _mat(Color(farbe, 0.7))
	vorschau_mi.visible = true


func _ring_mesh(mitte: Vector2, radius: float, breite: float, am_boden := true) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := clampi(int(radius * 0.5), 24, 160)
	var y0 := _h(mitte) + 1.2
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var pts: Array = []
		for a in [a0, a1]:
			for r in [radius - breite * 0.5, radius + breite * 0.5]:
				var q: Vector2 = mitte + Vector2(cos(a), sin(a)) * float(r)
				pts.append(Vector3(q.x, (_h(q) + 1.2) if am_boden else y0, q.y))
		for v in [pts[0], pts[1], pts[2], pts[1], pts[3], pts[2]]:
			st.add_vertex(v)
	return st.commit()


func _ring_setzen(mitte: Vector2, radius: float, farbe: Color) -> void:
	hq_ring.mesh = _ring_mesh(mitte, radius, maxf(6.0, radius * 0.012))
	hq_ring.material_override = _mat(Color(farbe, 0.55))
	hq_ring.visible = true


func _hq_vorschau_3d(p: Vector2) -> void:
	var ok: bool = hq_vorschau.get("ok", false)
	hq_geist.visible = true
	hq_geist.position = Vector3(p.x, _h(p), p.y)
	hq_geist.material_override = _mat(Color(C_OK if ok else C_BAD, 0.6))
	if ok:
		_ring_setzen(p, float(hq_vorschau["radius_felder"]) * 25.0, C_GOLD)
	else:
		hq_ring.visible = false


func _hq_haus_neu() -> void:
	for c in hq_haus.get_children():
		hq_haus.remove_child(c)
		c.queue_free()
	if not ps.hq_platziert:
		return
	var p: Vector2 = ps.hq_pos
	hq_haus.position = Vector3(p.x, _h(p), p.y)
	var typ: String = ["buergerhaus", "buergerhaus", "rathaus"][clampi(ps.hq_stufe - 1, 0, 2)]
	var haus := MeshInstance3D.new()
	haus.mesh = Prefabs.mesh_fuer(typ) if Prefabs.vorhanden(typ) else BoxMesh.new()
	haus.scale = Vector3.ONE * (1.0 + 0.12 * (ps.hq_stufe - 1))
	hq_haus.add_child(haus)
	var hoehe: float = haus.mesh.get_aabb().size.y * haus.scale.y
	# Fahnenmast mit Firmenfahne, damit der Sitz aus der Ferne lesbar ist
	var mast := MeshInstance3D.new()
	var zyl := CylinderMesh.new()
	zyl.top_radius = 0.18
	zyl.bottom_radius = 0.22
	zyl.height = hoehe + 9.0
	mast.mesh = zyl
	mast.material_override = _mat(Color(0.25, 0.2, 0.16), false)
	mast.position = Vector3(7.5, zyl.height * 0.5, 5.0)
	hq_haus.add_child(mast)
	var fahne := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(5.0, 3.0)
	fahne.mesh = qm
	fahne.material_override = _mat(C_GOLD, true)
	fahne.position = Vector3(7.5 + 2.6, zyl.height - 1.8, 5.0)
	hq_haus.add_child(fahne)
	for i in ps.hq_anbauten.size():
		var an := MeshInstance3D.new()
		an.mesh = Prefabs.mesh_fuer("nebengebaeude") if Prefabs.vorhanden("nebengebaeude") else BoxMesh.new()
		an.position = Vector3(-14.0 + i * 0.0, 0.0, -10.0 + i * 10.0)
		an.rotation.y = PI * 0.5
		hq_haus.add_child(an)
	var schild := Label3D.new()
	schild.text = "Firmensitz · %s" % String(ps._hq_stufe_daten().get("name", ""))
	schild.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	schild.fixed_size = true
	schild.pixel_size = 0.0011
	schild.font_size = 26
	schild.outline_size = 8
	schild.modulate = C_GOLD
	schild.outline_modulate = Color(0.06, 0.09, 0.13)
	schild.no_depth_test = true
	schild.position = Vector3(0, hoehe + 12.0, 0)
	hq_haus.add_child(schild)


## Ringe an den Einrast-Zielen des aktiven Modus (Betriebe ohne Anschluss, Bahnhofsplätze, Orte für den Firmensitz).
func _marker_neu() -> void:
	for c in marker_root.get_children():
		marker_root.remove_child(c)
		c.queue_free()
	if ps == null:
		return
	var ziele: Array = []
	if bau_art == "strasse":
		for nm in ps.stationen:
			if not ps.angeschlossen(nm):
				ziele.append([ps.halt_pos(nm), 18.0, C_WARN])
	elif bau_art == "gleis":
		for nm in ps.stationen:
			ziele.append([ps.halt_pos(nm), 22.0, C_OK if ps.bahnhof.has(nm) else C_BAU])
	elif hq_modus:
		for o in ps.orte_liste:
			ziele.append([Vector2(float(o["x"]), float(o["z"])), float(o.get("r_max_m", o.get("r_m", 150.0))), C_CREME])
	for zl in ziele:
		var mi := MeshInstance3D.new()
		mi.mesh = _ring_mesh(zl[0], zl[1], maxf(2.5, float(zl[1]) * 0.04))
		mi.material_override = _mat(Color(zl[2], 0.75))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		marker_root.add_child(mi)


## Neue Bauwerke und Bahnhöfe der Sim sichtbar machen (Schienen/Schwellen auf dem Gleisband, Bahnsteig, Schild).
func _bauwerke_pruefen() -> void:
	while _n_bauwerke < ps.bauwerke.size():
		var bw: Dictionary = ps.bauwerke[_n_bauwerke]
		_n_bauwerke += 1
		if String(bw["art"]) == "gleis":
			_gleis_schmuck(int(bw["weg"]))
	if _n_bahnhof != ps.bahnhof.size():
		_n_bahnhof = ps.bahnhof.size()
		for nm in ps.bahnhof:
			if raum.has_node("Bahnhof_" + String(nm).validate_node_name()):
				continue
			_bahnhof_bauen(nm)


func _gleis_schmuck(wi: int) -> void:
	var fl = welt.strassen.fahrlinien[wi]
	var band: Node = welt.wege_root.get_node_or_null("Weg_%d_gleis" % wi)
	if band is MeshInstance3D:
		var sm := ShaderMaterial.new()
		sm.shader = (band as MeshInstance3D).material_override.shader
		sm.set_shader_parameter("farbe_fahrbahn", Color(0.42, 0.40, 0.38))
		sm.set_shader_parameter("farbe_rand", Color(0.33, 0.31, 0.29))
		sm.set_shader_parameter("linie_staerke", 0.0)
		(band as MeshInstance3D).material_override = sm
	var schiene := SurfaceTool.new()
	schiene.begin(Mesh.PRIMITIVE_TRIANGLES)
	var schwelle := SurfaceTool.new()
	schwelle.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = fl.punkte.size()
	for k in n - 1:
		var a: Vector3 = fl.punkte[k]
		var b: Vector3 = fl.punkte[k + 1]
		var d := Vector3(b.x - a.x, 0, b.z - a.z).normalized()
		var r := Vector3(-d.z, 0, d.x)
		for seite in [-0.72, 0.72]:
			var o: Vector3 = r * seite
			var w: Vector3 = r * 0.07
			var up := Vector3(0, 0.28, 0)
			for v in [a + o - w + up, a + o + w + up, b + o - w + up, a + o + w + up, b + o + w + up, b + o - w + up]:
				schiene.add_vertex(v)
		if k % 2 == 0:
			var m := a
			var l: Vector3 = r * 1.15
			var t: Vector3 = d * 0.14
			var up2 := Vector3(0, 0.2, 0)
			for v in [m - l - t + up2, m + l - t + up2, m - l + t + up2, m + l - t + up2, m + l + t + up2, m - l + t + up2]:
				schwelle.add_vertex(v)
	for paar in [[schiene, Color(0.2, 0.2, 0.22), "Schienen_%d" % wi], [schwelle, Color(0.36, 0.26, 0.18), "Schwellen_%d" % wi]]:
		var mi := MeshInstance3D.new()
		mi.name = paar[2]
		mi.mesh = (paar[0] as SurfaceTool).commit()
		mi.material_override = _mat(paar[1], false)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		raum.add_child(mi)


func _bahnhof_bauen(nm: String) -> void:
	var n: int = ps.bahnhof[nm]
	var kp: Vector3 = ps.knoten_pos[n]
	var wurzel := Node3D.new()
	wurzel.name = "Bahnhof_" + nm.validate_node_name()
	wurzel.position = Vector3(kp.x, _h(Vector2(kp.x, kp.z)), kp.z)
	var steig := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(5.0, 0.7, 18.0)
	steig.mesh = bm
	steig.material_override = _mat(Color(0.62, 0.58, 0.52), false)
	steig.position = Vector3(5.0, 0.45, 0.0)
	wurzel.add_child(steig)
	var dach := MeshInstance3D.new()
	var dm := BoxMesh.new()
	dm.size = Vector3(4.4, 0.3, 9.0)
	dach.mesh = dm
	dach.material_override = _mat(Color(0.48, 0.2, 0.16), false)
	dach.position = Vector3(5.0, 4.0, 0.0)
	wurzel.add_child(dach)
	for z in [-4.0, 4.0]:
		var pf := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(0.3, 3.4, 0.3)
		pf.mesh = pm
		pf.material_override = _mat(Color(0.3, 0.22, 0.16), false)
		pf.position = Vector3(5.0, 2.3, z)
		wurzel.add_child(pf)
	var schild := Label3D.new()
	schild.text = "Bahnhof " + nm
	schild.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	schild.fixed_size = true
	schild.pixel_size = 0.001
	schild.font_size = 22
	schild.outline_size = 8
	schild.modulate = C_CREME
	schild.outline_modulate = Color(0.06, 0.09, 0.13)
	schild.position = Vector3(5.0, 7.0, 0.0)
	wurzel.add_child(schild)
	raum.add_child(wurzel)
