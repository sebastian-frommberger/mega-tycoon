class_name ProtoSchilder
extends Node
## Phase 4 Welle 2 (Aylin, UX): Ortsschilder und Industrie-Plaketten für die Prototyp-Welt.
##
## Hook (Felix):   var sch := ProtoSchilder.bauen(self, cam, orte, terrain)      # nach Gelände und Kamera
##   parent  Node3D der Szene (nur als Elternknoten), kamera  die aktive Camera3D, orte  proto_orte.json["orte"],
##   terrain  Objekt mit hoehe_at(x_m, z_m) -> float (ProtoTerrain oder Stub), industrie  optional (sonst aus
##   proto_orte.json["industrie"]). Alles weitere liest die Klasse selbst (Daten je Datei wie prototyp_welt.datei()).
## Weitere Hooks: setze_trend(id, "hoch"|"gleich"|"runter"), setze_ew(id, n), setze_bedarf(id, [{gut,status,ersatz}]),
##   setze_sichtbar(an), meiden (Array[Rect2], Bildschirm-Rechtecke, denen Schilder ausweichen; HUD-Panels werden
##   automatisch erkannt), Abfragen für Tests: liste(), eintrag(id), tooltip_fuer(id), tooltip_fuer_punkt(p).
##
## Konzept (Details: sprints/s8/design-sprint/phase4/aylin_welle2.md):
##  * Zeichen statt Objektgröße (E1): die Schilder sind Bildschirm-Overlay (CanvasLayer) mit Pixelgrößen, die Modelle
##    bleiben im echten Maßstab. Kein pixel_size/label_kscale nötig, weil die Größe schon in Bildschirm-px gesetzt wird
##    (ui_scale = Fensterhöhe / 900, damit es mit der Auflösung mitwächst, min. 12 px Schrift).
##  * Drei Stufen je Kameraabstand zum Ort: Fern ≥ 1500 m (Icon + Name), Voll 400–1500 m (Name, Einwohner, Trend,
##    Bedarf), Nah < 400 m (nur Name). Hysterese 8 %. Kleinstadt größer als Dorf, Weiler nur Nah (≤ 500 m).
##  * Industrie: farbige Plakette (Scheibe aus ui/assets/industry) + Name in der Typfarbe, Gebäude bleiben neutral.
##  * Entzerrung wie props/label_declutter.gd (Städte zuerst, dann Dörfer, Industrie, Weiler; weichen nach oben aus).
##  * Gelände: Anker über hoehe_at; ist die Sichtlinie Kamera–Ort durch das Gelände verdeckt, wird der Anker
##    angehoben (bis 150 m), damit das Schild über dem Hang steht.
##  * Tooltip „Einzugsgebiet“ beim Zeigen auf ein Schild: kein Modal, kein Klick, folgt der Maus.

const DATEN := "res://world/data/proto/"
const TEST := "res://proto/testdaten/"
const SCHILDER_DATEN := "res://proto/proto_schilder_daten.json"
const REGELWERK := "res://world/data/proto/regelwerk.json"
const FONT_PFAD := "res://ui/assets/fonts/poppins_medium.ttf"
const ICON_STADT := "res://ui/assets/icons/c_stadt.png"
const ICON_DORF := "res://proto/proto_icons/p_dorf.png"
const ICON_PERSON := "res://proto/proto_icons/p_person.png"
const ICON_KETTE := "res://proto/proto_icons/p_kette.png"
const ICON_HOCH := "res://ui/assets/icons/k_arrowUp.png"
const ICON_GLEICH := "res://proto/proto_icons/p_pfeil_rechts.png"
const ICON_RUNTER := "res://ui/assets/icons/k_arrowDown.png"

# Stufen (Kameraabstand zum Ort in m)
const FERN_AB_M := 1500.0
const NAH_UNTER_M := 400.0
const HYSTERESE := 0.08
const WEILER_NAH_BIS_M := 0.0            # Fix-Pass W2 (M8): Regelwerk label.hierarchie.weiler = "nie" gilt strikt, kein Schild;
#                                          > 0 (z. B. 250.0) schaltet ein dezentes Namenslabel im Nahbereich wieder ein
const RAND_PX := 8.0                     # Mindestabstand der Schilder zum Bildschirmrand (Fix-Pass W2, M4), px bei 900 px Höhe
const SICHT_RAND_PX := 48.0              # Anker darf so weit außerhalb des Bildes liegen, solange das Schild hineingeschoben wird
const STUFE_FERN := 0
const STUFE_VOLL := 1
const STUFE_NAH := 2

# Größen in px bei 900 px Fensterhöhe
const KLASSEN := {
	"kleinstadt": {"prio": 0, "name": 21, "ew": 15, "icon": 22, "fern_name": 17, "fern_icon": 28, "nah_name": 18, "anker_m": 24.0},
	"marktflecken": {"prio": 0, "name": 19, "ew": 15, "icon": 20, "fern_name": 16, "fern_icon": 26, "nah_name": 17, "anker_m": 20.0},
	"dorf": {"prio": 1, "name": 16, "ew": 14, "icon": 18, "fern_name": 14, "fern_icon": 22, "nah_name": 15, "anker_m": 14.0},
	"weiler": {"prio": 3, "name": 13, "ew": 13, "icon": 0, "fern_name": 13, "fern_icon": 0, "nah_name": 13, "anker_m": 12.0},
	"industrie": {"prio": 2, "name": 14, "ew": 13, "icon": 18, "fern_name": 14, "fern_icon": 34, "nah_name": 13, "anker_m": 12.0},
}
const MIN_FONT_PX := 12
const MIN_SCALE := 0.85
const MAX_SCALE := 1.5
const ZEILE := 1.28
const GAP_PX := 6.0                       # Abstand Schild-Unterkante zum Ort (ohne Zeiger)
const ZEIGER_PX := 7.0
const STEP_PX := 12.0
const HOCH_PX := [0.0, 20.0, 10.0]          # Grundversatz nach oben je Stufe (Fern, Voll, Nah): Schild über dem Ort, nicht mitten drauf
const MAX_STEPS := 8
const LIFT_STUFEN_M := [0.0, 15.0, 30.0, 60.0, 100.0, 150.0]
const SICHT_PROBEN := 20

# Farben (cream auf dunkler Platte, wie HUD und Palette S-08)
const PLATTE := Color(0.10, 0.09, 0.08, 0.88)
const PLATTE_RAND := Color(0.96, 0.92, 0.84, 0.80)
const TEXT := Color(0.98, 0.95, 0.88)
const SAUM := Color(0.059, 0.09, 0.125)         # palette_s08 saum #0F1720
const OK_FARBE := Color(0.282, 0.878, 0.541)    # status_ok #48E08A
const WARN_FARBE := Color(1.0, 0.651, 0.251)    # status_warn #FFA640
const BAD_FARBE := Color(1.0, 0.596, 0.541)     # status_bad #FF988A
const TREND_FARBEN := {"hoch": OK_FARBE, "gleich": TEXT, "runter": BAD_FARBE}

var kamera: Camera3D
var terrain = null
var orte: Array = []
var meiden: Array[Rect2] = []                   # zusätzliche Sperrflächen (Bildschirm)
var sichtbar := true
var eintraege: Array[Dictionary] = []
var daempfen: Dictionary = {}                   # Demo: Name -> Faktor (Schilder ungültiger Ziele abdunkeln); leer = unverändert
var betonen: Dictionary = {}                    # Demo: Name -> Color (Rahmen um das Schild: Auswahl, Hover, gültige Ziele)
var guete := {}
var ind_cfg := {}
var ort_extra := {}
var _canvas: CanvasLayer
var _flaeche: Control
var _font: Font
var _tex := {}
var _scale := 1.0
var _hover := ""
var _hover_t := 0.0
var _maus := Vector2(-1000, -1000)
var _letzte_kam := Transform3D()
var _letzte_vp := Vector2.ZERO
var _hud_t := 99.0
var _hud_rects: Array[Rect2] = []
var _tip_rect := Rect2()
var _test_hover := ""                           # erzwungener Tooltip (Tests, Bilder); leer = Maus


static func datei(name: String) -> String:
	return DATEN + name if FileAccess.file_exists(DATEN + name) else TEST + name


## Hook für Felix. Gibt die Instanz zurück (Kind von parent).
static func bauen(parent: Node3D, kamera_: Camera3D, orte_: Array, terrain_, industrie_: Array = []) -> ProtoSchilder:
	var s := ProtoSchilder.new()
	s.name = "ProtoSchilder"
	s.kamera = kamera_
	s.terrain = terrain_
	s.orte = orte_
	parent.add_child(s)
	s._aufbauen(industrie_)
	return s


func _json(pfad: String) -> Variant:
	if not FileAccess.file_exists(pfad):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(pfad))


func _aufbauen(industrie_: Array) -> void:
	process_priority = 100                     # nach Felix' Kamera-Update (_process, Priorität 0)
	_font = load(FONT_PFAD) as Font
	var d = _json(SCHILDER_DATEN)
	if d is Dictionary:
		ort_extra = d.get("orte", {})
		guete = d.get("guete", {})
		ind_cfg = d.get("industrie", {})
	var ind: Array = industrie_
	if ind.is_empty():
		var po = _json(datei("proto_orte.json"))
		if po is Dictionary:
			ind = po.get("industrie", [])
	var anker_pts := _ankerpunkte()
	for o in orte:
		_neuer_ort(o, anker_pts)
	for i in ind:
		_neue_industrie(i)
	_canvas = CanvasLayer.new()
	_canvas.name = "SchilderLayer"
	_canvas.layer = 0                          # unter Felix' HUD (Layer 1)
	add_child(_canvas)
	_flaeche = Control.new()
	_flaeche.name = "Schilder"
	_flaeche.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flaeche.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_flaeche.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flaeche.draw.connect(_zeichne)
	_canvas.add_child(_flaeche)
	aktualisiere(true)


func _bodenhoehe(x: float, z: float) -> float:
	if terrain != null and terrain.has_method("hoehe_at"):
		return float(terrain.hoehe_at(x, z))
	return 0.0


## Fußpunkt je Ort (Fix-Pass W2, M3): Marktplatz (Kleinstadt/Marktflecken) bzw. Kirche (Dorf) aus proto_instanzen.json,
## sonst die Ortsmitte aus proto_orte.json. Das Schild steht am Ortskern, nicht auf der Wiese daneben.
func _ankerpunkte() -> Dictionary:
	var out := {}
	var inst = _json(datei("proto_instanzen.json"))
	if not (inst is Array):
		return out
	var markt := {}
	var kirche := {}
	for it in inst:
		var typ := str(it.get("typ", ""))
		var ort := str(it.get("ort", ""))
		if ort == "":
			continue
		var p := Vector2(float(it.get("x", 0.0)), float(it.get("z", 0.0)))
		if typ == "flaeche_marktplatz" and not markt.has(ort):
			markt[ort] = p
		elif typ.begins_with("kirche_") and not kirche.has(ort):
			kirche[ort] = p
	for o in orte:
		var id := str(o.get("id", ""))
		var kl := str(o.get("klasse", ""))
		if kl in ["kleinstadt", "marktflecken"]:
			if markt.has(id):
				out[id] = markt[id]
			elif kirche.has(id):
				out[id] = kirche[id]
		elif kl == "dorf" and kirche.has(id):
			out[id] = kirche[id]
	return out


func _neuer_ort(o: Dictionary, anker_pts: Dictionary = {}) -> void:
	var id: String = str(o.get("id", ""))
	var kl: String = str(o.get("klasse", "dorf"))
	if not KLASSEN.has(kl):
		kl = "dorf"
	var ex: Dictionary = ort_extra.get(id, {})
	var e := {
		"id": id, "art": "ort", "name": str(o.get("name", id)), "klasse": kl, "typ": kl,
		"x": float(o.get("x", 0.0)), "z": float(o.get("z", 0.0)),
		"ew": int(o.get("ew", 0)), "trend": str(ex.get("trend", "gleich")),
		"bedarf": (ex.get("bedarf", []) as Array).duplicate(true),
		"extra": ex, "farbe": TEXT,
	}
	var ap: Vector2 = anker_pts.get(id, Vector2(e["x"], e["z"]))
	e["ax"] = ap.x
	e["az"] = ap.y
	_eintrag_grunddaten(e)
	eintraege.append(e)


func _neue_industrie(i: Dictionary) -> void:
	var typ: String = str(i.get("typ", ""))
	var cfg: Dictionary = ind_cfg.get(typ, {})
	var f: Array = cfg.get("farbe", [236, 200, 76])
	var e := {
		"id": str(i.get("id", typ)), "art": "industrie", "name": str(i.get("name", typ)), "klasse": "industrie", "typ": typ,
		"x": float(i.get("x", 0.0)), "z": float(i.get("z", 0.0)), "ew": 0, "trend": "gleich", "bedarf": [],
		"extra": cfg, "farbe": Color8(int(f[0]), int(f[1]), int(f[2])),
	}
	_eintrag_grunddaten(e)
	eintraege.append(e)


func _eintrag_grunddaten(e: Dictionary) -> void:
	if not e.has("ax"):
		e["ax"] = e["x"]
		e["az"] = e["z"]
	e["boden"] = _bodenhoehe(e["ax"], e["az"])
	e["anker_m"] = float(KLASSEN[e["klasse"]]["anker_m"])
	e["lift_m"] = 0.0
	e["lift_ziel"] = 0.0
	e["verdeckt"] = false
	e["stufe"] = -1
	e["alpha"] = 0.0
	e["sichtbar"] = false
	e["abstand_m"] = 0.0
	e["rect"] = Rect2()
	e["anker_scr"] = Vector2.ZERO
	e["verschub_px"] = 0.0
	e["anker_pos"] = Vector3(e["ax"], e["boden"] + e["anker_m"], e["az"])
	e["fuss_pos"] = Vector3(e["ax"], e["boden"], e["az"])
	e["fuss_scr"] = Vector2.ZERO


# ------------------------------------------------------------------ Daten-Hooks

func eintrag(id: String) -> Dictionary:
	for e in eintraege:
		if e["id"] == id:
			return e
	return {}


func liste() -> Array[Dictionary]:
	return eintraege


func setze_trend(id: String, trend: String) -> void:
	var e := eintrag(id)
	if not e.is_empty() and TREND_FARBEN.has(trend):
		e["trend"] = trend


func setze_ew(id: String, ew: int) -> void:
	var e := eintrag(id)
	if not e.is_empty():
		e["ew"] = ew


func setze_bedarf(id: String, bedarf: Array) -> void:
	var e := eintrag(id)
	if not e.is_empty():
		e["bedarf"] = bedarf.duplicate(true)


## Für Tests und Bilder: Tooltip eines Schilds erzwingen (leer = wieder Maus).
func zeige_tooltip(id: String) -> void:
	_test_hover = id


func setze_sichtbar(an: bool) -> void:
	sichtbar = an
	if _canvas != null:
		_canvas.visible = an


# ------------------------------------------------------------------ Hilfen (statisch, testbar)

## WCAG 2.x Kontrastverhältnis (wie industry_markers.contrast).
static func kontrast(a: Color, b: Color) -> float:
	var la := Color(a.r, a.g, a.b).srgb_to_linear().get_luminance()
	var lb := Color(b.r, b.g, b.b).srgb_to_linear().get_luminance()
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


## Platte (mit Alpha) über einem Untergrund, wie sie auf dem Bildschirm erscheint.
static func platte_ueber(untergrund: Color) -> Color:
	return Color(untergrund.r, untergrund.g, untergrund.b).lerp(Color(PLATTE.r, PLATTE.g, PLATTE.b), PLATTE.a)


static func tsd(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "." + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out


## Stufe aus Abstand (m) mit Hysterese; alt = bisherige Stufe oder −1.
static func stufe_fuer(abstand_m: float, alt: int = -1) -> int:
	var fern := FERN_AB_M * (1.0 - HYSTERESE if alt == STUFE_FERN else 1.0 + (HYSTERESE if alt == STUFE_VOLL else 0.0))
	var nah := NAH_UNTER_M * (1.0 + HYSTERESE if alt == STUFE_NAH else 1.0 - (HYSTERESE if alt == STUFE_VOLL else 0.0))
	if abstand_m >= fern:
		return STUFE_FERN
	if abstand_m < nah:
		return STUFE_NAH
	return STUFE_VOLL


## Größenfaktor des Vollschilds: wächst sanft beim Heranzoomen (1,12 bei 400 m) und schrumpft zur Ferne (0,92 bei 1500 m).
static func voll_faktor(abstand_m: float) -> float:
	var t := clampf((abstand_m - NAH_UNTER_M) / (FERN_AB_M - NAH_UNTER_M), 0.0, 1.0)
	return lerpf(1.12, 0.92, t)


func _px(v: float) -> float:
	return roundf(v * _scale)


func _fs(v: float) -> int:
	return maxi(MIN_FONT_PX, int(roundf(v * _scale)))


func _textur(pfad: String) -> Texture2D:
	if pfad == "":
		return null
	if not _tex.has(pfad):
		var src := load(pfad) as Texture2D
		if src == null:
			_tex[pfad] = null
		else:
			var img := src.get_image()
			if img.is_compressed():
				img.decompress()
			img.generate_mipmaps()
			_tex[pfad] = ImageTexture.create_from_image(img)
	return _tex[pfad]


# ------------------------------------------------------------------ Texte (Inhalt der Schilder)

## Die sichtbaren Texte eines Schilds in der Stufe voll (für Tests und Doku).
func texte(id: String) -> Dictionary:
	var e := eintrag(id)
	if e.is_empty():
		return {}
	var bed: Array[String] = []
	for b in e["bedarf"]:
		bed.append(str(guete.get(b.get("gut", ""), {}).get("name", b.get("gut", ""))))
	return {"name": e["name"], "ew": tsd(int(e["ew"])) if e["art"] == "ort" else "", "trend": e["trend"], "bedarf": bed}


func _status_text(s: String) -> String:
	match s:
		"ok":
			return "gedeckt"
		"bad":
			return "fehlt dringend"
	return "wird gebraucht"


## Tooltip „Einzugsgebiet“: Zeilen (erste = Titel). Kurze Sätze, Du-Form wie ui/fehlertexte.gd.
func tooltip_zeilen(id: String) -> PackedStringArray:
	var e := eintrag(id)
	var z := PackedStringArray()
	if e.is_empty():
		return z
	var ex: Dictionary = e["extra"]
	if e["art"] == "industrie":
		z.append(e["name"])
		for t in ex.get("tooltip", []):
			z.append(str(t))
		return z
	var kl: String = e["klasse"]
	var ew: int = int(e["ew"])
	var umland: int = int(ex.get("umland_ew", 0))
	if kl == "weiler":
		z.append("%s (Weiler)" % e["name"])
		z.append("%d Menschen wohnen hier, auf %d Höfen." % [ew, int(ex.get("hoefe", 6))])
		z.append("Ein Weiler hat keinen eigenen Bedarf.")
		z.append("Seine Bewohner zählen zum Umland eines Ortes in der Nähe.")
		return z
	z.append("Einzugsgebiet %s" % e["name"])
	if bool(ex.get("annahme", false)):
		z.append("Im Kartenausschnitt siehst du %s Menschen. Die Stadt reicht nach Westen über den Rand hinaus." % tsd(ew))
		z.append("Die ganze Stadt hat etwa %s Einwohner (Annahme). Dazu kommen etwa %s im Umland." % [tsd(int(ex.get("ew_gesamt", ew))), tsd(umland)])
		z.append("Zusammen sind das etwa %s. Danach richtet sich der Bedarf." % tsd(int(ex.get("sim_ew", ew + umland))))
	else:
		z.append("Im Ort wohnen %s Menschen. Das sind die Häuser, die du siehst." % tsd(ew))
		if umland > 0:
			z.append("Dazu kommen %s im Umland, auf Höfen und in Weilern ringsum." % tsd(umland))
			z.append("Zusammen sind das %s. Danach richtet sich der Bedarf." % tsd(int(ex.get("sim_ew", ew + umland))))
	var braucht := PackedStringArray()
	var status := "ok"
	for b in e["bedarf"]:
		if not bool(b.get("ersatz", false)):
			braucht.append(str(guete.get(b["gut"], {}).get("name", b["gut"])))
		if b["status"] == "bad" or (b["status"] == "warn" and status == "ok"):
			status = b["status"]
	if not e["bedarf"].is_empty():
		z.append("Bedarf: Nahrung, zum Beispiel %s oder Fleisch. %s." % [", ".join(braucht), _status_text(status).substr(0, 1).to_upper() + _status_text(status).substr(1)])
	if umland > 0:
		z.append("Das Umland wächst nicht. Nur der Ort wächst.")
	var tr: String = e["trend"]
	z.append("Trend: " + {"hoch": "steigt", "gleich": "bleibt gleich", "runter": "sinkt"}.get(tr, "bleibt gleich") + ". Der Ort wächst, wenn er versorgt ist.")
	return z


func tooltip_fuer(id: String) -> String:
	return "\n".join(tooltip_zeilen(id))


## Welches Schild liegt unter dem Bildschirmpunkt p? Leere Zeichenkette, wenn keines.
func schild_bei(p: Vector2) -> String:
	var beste := ""
	var prio := 99
	for e in eintraege:
		if e["sichtbar"] and e["alpha"] > 0.05 and (e["rect"] as Rect2).grow(3.0).has_point(p):
			var pr: int = int(KLASSEN[e["klasse"]]["prio"])
			if pr < prio:
				prio = pr
				beste = e["id"]
	return beste


func tooltip_fuer_punkt(p: Vector2) -> String:
	var id := schild_bei(p)
	return tooltip_fuer(id) if id != "" else ""


# ------------------------------------------------------------------ Layout je Frame

func _process(delta: float) -> void:
	if kamera == null or not sichtbar:
		return
	_maus = get_viewport().get_mouse_position()
	aktualisiere(false)
	var id := schild_bei(_maus)
	if _test_hover != "":
		id = _test_hover
		var te := eintrag(id)
		if not te.is_empty() and te["sichtbar"]:
			_maus = (te["rect"] as Rect2).get_center()
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) \
			or Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		id = ""
	if id != _hover:
		_hover = id
		_hover_t = 0.0
	else:
		_hover_t += delta
	_flaeche.queue_redraw()


## Stufen, Größen, Positionen, Entzerrung. force = auch ohne Kamerabewegung (Aufbau, Tests).
func aktualisiere(force := true) -> void:
	if kamera == null or not kamera.is_inside_tree():
		return
	var vp := kamera.get_viewport().get_visible_rect().size
	var kt := kamera.global_transform
	var bewegt := force or not kt.is_equal_approx(_letzte_kam) or vp != _letzte_vp
	_scale = clampf(vp.y / 900.0, MIN_SCALE, MAX_SCALE)
	if bewegt:
		_letzte_kam = kt
		_letzte_vp = vp
		_hud_t += 1.0
		for e in eintraege:
			_gelaende_anker(e, force)
	var cam_pos := kt.origin
	var viewrect := Rect2(Vector2.ZERO, vp).grow(_px(SICHT_RAND_PX))
	if _hud_t > 30.0 or force:
		_hud_t = 0.0
		_hud_suchen()
	var reihe: Array[Dictionary] = []
	for e in eintraege:
		e["abstand_m"] = cam_pos.distance_to(e["anker_pos"])
		var st := stufe_fuer(e["abstand_m"], e["stufe"])
		var an := not kamera.is_position_behind(e["anker_pos"])
		var scr := Vector2.ZERO
		if an:
			scr = kamera.unproject_position(e["anker_pos"])
			an = viewrect.has_point(scr)
		if e["klasse"] == "weiler" and (WEILER_NAH_BIS_M <= 0.0 or e["abstand_m"] > WEILER_NAH_BIS_M):
			an = false
		e["stufe"] = st
		e["sichtbar"] = an
		e["anker_scr"] = scr
		e["fuss_scr"] = scr
		if an and not kamera.is_position_behind(e["fuss_pos"]):
			e["fuss_scr"] = kamera.unproject_position(e["fuss_pos"])
		e["alpha"] = 1.0 if an else 0.0
		if an:
			if e["art"] == "industrie":
				e["alpha"] = 0.92 if st == STUFE_NAH else 1.0         # Text bleibt voll deckend (Kontrast), nur Nah leicht zurück
			elif st == STUFE_NAH:
				e["alpha"] = 0.92
			e["groesse"] = _messen(e)
			reihe.append(e)
	reihe.sort_custom(func(a, b): return int(KLASSEN[a["klasse"]]["prio"]) < int(KLASSEN[b["klasse"]]["prio"]))
	var belegt: Array[Rect2] = []
	for m in meiden:
		belegt.append(m)
	belegt.append_array(_hud_rects)
	for e in reihe:
		var gr: Vector2 = e["groesse"]
		var gap := _px(GAP_PX) + _px(ZEIGER_PX)
		var unten: Vector2 = e["anker_scr"] + Vector2(0.0, -gap)
		var verschub := _px(HOCH_PX[e["stufe"]]) if e["art"] == "ort" else 0.0
		var rect := Rect2(unten - Vector2(gr.x * 0.5, gr.y), gr)
		var frei := false
		var rand := _px(RAND_PX)
		var verschub0 := verschub
		var richtung := 1.0
		for _i in 2 * MAX_STEPS + 2:
			rect = Rect2(unten + Vector2(-gr.x * 0.5, -gr.y - verschub), gr)
			# Fix-Pass W2 (M4): Schild nie über den Bildschirmrand hinaus; der Zeiger bleibt auf den Fußpunkt gerichtet
			rect.position.x = clampf(rect.position.x, rand, maxf(rand, vp.x - gr.x - rand))
			rect.position.y = clampf(rect.position.y, rand, maxf(rand, vp.y - gr.y - rand))
			var treffer := false
			for b in belegt:
				if rect.grow(2.0).intersects(b):
					treffer = true
					break
			if not treffer:
				frei = true
				break
			if richtung > 0.0 and (rect.position.y <= rand + 0.5 or _i >= MAX_STEPS):
				richtung = -1.0                 # oben ist kein Platz mehr (Bildrand): unterhalb des Ankers weitersuchen
				verschub = verschub0
			verschub += richtung * _px(STEP_PX)
		var prio: int = int(KLASSEN[e["klasse"]]["prio"])
		if not frei and prio >= 2:             # Industrie und Weiler weichen, Orte nie
			e["sichtbar"] = false
			e["alpha"] = 0.0
			continue
		e["rect"] = rect
		e["verschub_px"] = verschub
		belegt.append(rect)
	for e in eintraege:
		if not e["sichtbar"]:
			e["rect"] = Rect2(-10000, -10000, 0, 0)


func _hud_suchen() -> void:
	_hud_rects.clear()
	var wurzel: Node = get_parent()
	if wurzel == null:
		return
	for c in wurzel.get_children():
		if c is CanvasLayer and c != _canvas:
			for k in c.get_children():
				if k is Control and (k as Control).visible:
					var r := (k as Control).get_global_rect()
					if r.size.x > 4.0 and r.size.y > 4.0:
						_hud_rects.append(r)


## Anker über dem Gelände; Sichtlinie prüfen, bei Verdeckung anheben (nur bei bewegter Kamera).
func _gelaende_anker(e: Dictionary, snap: bool) -> void:
	var kp := kamera.global_transform.origin
	e["boden"] = _bodenhoehe(e["ax"], e["az"])
	var ziel_lift := 0.0
	var verdeckt := true
	for lift in LIFT_STUFEN_M:
		var p := Vector3(e["ax"], e["boden"] + e["anker_m"] + lift, e["az"])
		if _sicht_frei(kp, p):
			ziel_lift = lift
			verdeckt = false
			break
		ziel_lift = lift
	e["lift_ziel"] = ziel_lift
	e["verdeckt"] = verdeckt
	e["lift_m"] = ziel_lift if snap else lerpf(e["lift_m"], ziel_lift, 0.35)
	e["anker_pos"] = Vector3(e["ax"], e["boden"] + e["anker_m"] + e["lift_m"], e["az"])
	e["fuss_pos"] = Vector3(e["ax"], e["boden"], e["az"])


func _sicht_frei(von: Vector3, nach: Vector3) -> bool:
	for i in range(1, SICHT_PROBEN):
		var p := von.lerp(nach, float(i) / SICHT_PROBEN)
		if p.y < _bodenhoehe(p.x, p.z) + 0.5:
			return false
	return true


# ------------------------------------------------------------------ Messen und Zeichnen

func _gut_icon(gut: String) -> String:
	return str(guete.get(gut, {}).get("icon", ""))


func _klassen_icon(e: Dictionary) -> String:
	return ICON_STADT if e["klasse"] in ["kleinstadt", "marktflecken"] else ICON_DORF


## Größe des Schilds in px (je nach Stufe), inkl. Innenabstand; ohne Zeiger.
func _messen(e: Dictionary) -> Vector2:
	var k: Dictionary = KLASSEN[e["klasse"]]
	var st: int = e["stufe"]
	var pad_x := _px(9.0)
	var pad_y := _px(5.0)
	var f := voll_faktor(e["abstand_m"]) if st == STUFE_VOLL else 1.0
	if e["art"] == "industrie":
		return _messen_industrie(e, st, f, pad_x, pad_y)
	if st == STUFE_NAH or e["klasse"] == "weiler":
		var n := _fs(k["nah_name"])
		var w := _font.get_string_size(e["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, n).x
		return Vector2(w + pad_x * 1.6, n * ZEILE + pad_y * 1.4)
	if st == STUFE_FERN:
		var n := _fs(k["fern_name"])
		var ic := _px(k["fern_icon"])
		var w := ic + _px(6.0) + _font.get_string_size(e["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, n).x
		return Vector2(w + pad_x * 1.4, maxf(ic, n * ZEILE) + pad_y * 1.2)
	# Vollschild: zwei Zeilen
	var n1 := _fs(k["name"] * f)
	var n2 := _fs(k["ew"] * f)
	var ic1 := _px(k["name"] * f + 4.0)
	var bi := _px(k["icon"] * f)
	var w1 := ic1 + _px(6.0) + _font.get_string_size(e["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, n1).x
	var w2 := _zeile2_breite(e, n2, bi)
	return Vector2(maxf(w1, w2) + pad_x * 2.0, maxf(ic1, n1 * ZEILE) + _px(3.0) + maxf(float(bi), n2 * ZEILE) + pad_y * 2.0)


func _zeile2_breite(e: Dictionary, n2: int, bi: float) -> float:
	var w := bi * 0.72 + _px(3.0) + _font.get_string_size(tsd(int(e["ew"])), HORIZONTAL_ALIGNMENT_LEFT, -1, n2).x
	w += _px(10.0) + n2 * 0.95
	if not e["bedarf"].is_empty():
		w += _px(14.0)
		var vorher_ersatz := false
		for b in e["bedarf"]:
			w += bi + _px(4.0)
			if bool(b.get("ersatz", false)) and not vorher_ersatz:
				w += _px(8.0)
			vorher_ersatz = bool(b.get("ersatz", false))
	return w


func _messen_industrie(e: Dictionary, st: int, f: float, pad_x: float, pad_y: float) -> Vector2:
	var k: Dictionary = KLASSEN["industrie"]
	var n := _fs(k["name"] if st != STUFE_NAH else k["nah_name"])
	var disc := _px(lerpf(22.0, 34.0, clampf((e["abstand_m"] - 600.0) / 900.0, 0.0, 1.0)))
	var wn := _font.get_string_size(e["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, n).x
	var w := disc + _px(6.0) + wn + pad_x * 1.4
	var h := maxf(disc, n * ZEILE) + pad_y * 1.2
	if st == STUFE_VOLL:      # Kette „Eingang → Ausgang“ unter dem Namen
		h += _px(18.0)
		w = maxf(w, disc + _px(6.0) + _px(70.0) + pad_x * 1.4)
	e["disc_px"] = disc
	return Vector2(w, h)


func _zeichne() -> void:
	if not sichtbar or _font == null:
		return
	for e in eintraege:
		if e["sichtbar"] and e["alpha"] > 0.01:
			_zeichne_eintrag(e)
	if _hover != "" and _hover_t > 0.12:
		_zeichne_tooltip(_hover)


func _platte(r: Rect2, alpha: float, radius: float) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(PLATTE.r, PLATTE.g, PLATTE.b, PLATTE.a * alpha)
	sb.border_color = Color(PLATTE_RAND.r, PLATTE_RAND.g, PLATTE_RAND.b, PLATTE_RAND.a * alpha)
	sb.set_border_width_all(maxi(1, int(roundf(_scale * 1.5))))
	sb.set_corner_radius_all(int(radius))
	sb.anti_aliasing = true
	_flaeche.draw_style_box(sb, r)


func _zeiger(e: Dictionary, r: Rect2, alpha: float) -> void:
	var c := Color(PLATTE_RAND.r, PLATTE_RAND.g, PLATTE_RAND.b, alpha)
	var fuss: Vector2 = e["fuss_scr"]
	var w := _px(5.0)
	# Zeigerfuß wandert an der Unterkante zum Fußpunkt (Schild am Bildrand geklemmt: Zeiger bleibt auf dem Ort)
	var bx := clampf(fuss.x, r.position.x + w + _px(7.0), r.end.x - w - _px(7.0))
	var by := r.end.y
	_flaeche.draw_colored_polygon(PackedVector2Array([Vector2(bx - w, by - 1.0), Vector2(bx + w, by - 1.0), Vector2(bx, by + _px(ZEIGER_PX))]),
		Color(PLATTE.r, PLATTE.g, PLATTE.b, PLATTE.a * alpha))
	# Fußpunkt-Linie (Fix-Pass W2, M3): vom Schild senkrecht zum Boden am Ortskern, dort Ring; so sitzt das Schild am Ort
	var von := Vector2(bx, by + _px(ZEIGER_PX))
	if von.distance_to(fuss) > _px(6.0):
		var lc := Color(PLATTE_RAND.r, PLATTE_RAND.g, PLATTE_RAND.b, alpha * 0.85)
		_flaeche.draw_line(von, fuss, Color(SAUM.r, SAUM.g, SAUM.b, alpha * 0.7), maxf(3.0, _scale * 3.0), true)
		_flaeche.draw_line(von, fuss, lc, maxf(1.5, _scale * 1.5), true)
	var rr := maxf(3.0, _scale * 3.5)
	_flaeche.draw_circle(fuss, rr + 1.5, Color(SAUM.r, SAUM.g, SAUM.b, alpha))
	_flaeche.draw_circle(fuss, rr, c)
	_flaeche.draw_circle(fuss, maxf(1.2, rr * 0.45), Color(SAUM.r, SAUM.g, SAUM.b, alpha))


func _icon(pfad: String, mitte: Vector2, px: float, farbe: Color) -> void:
	var t := _textur(pfad)
	if t != null:
		_flaeche.draw_texture_rect(t, Rect2(mitte - Vector2(px, px) * 0.5, Vector2(px, px)), false, farbe)


func _text(s: String, links_unten: Vector2, px: int, farbe: Color) -> float:
	_flaeche.draw_string(_font, links_unten, s, HORIZONTAL_ALIGNMENT_LEFT, -1, px, farbe)
	return _font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x


func _grundlinie(mitte_y: float, px: int) -> float:
	return mitte_y + _font.get_ascent(px) * 0.5 - _font.get_descent(px) * 0.5


func _zeichne_eintrag(e: Dictionary) -> void:
	var a: float = e["alpha"] * float(daempfen.get(e["name"], 1.0))
	var r: Rect2 = e["rect"]
	var tc := Color(TEXT.r, TEXT.g, TEXT.b, a)
	_platte(r, a, _px(6.0))
	if betonen.has(e["name"]):
		var bf: Color = betonen[e["name"]]
		_flaeche.draw_rect(r.grow(_px(3.0)), Color(bf.r, bf.g, bf.b, e["alpha"]), false, _px(3.0))
	_zeiger(e, r, a)
	if e["art"] == "industrie":
		_zeichne_industrie(e, r, a)
		return
	var k: Dictionary = KLASSEN[e["klasse"]]
	var st: int = e["stufe"]
	var cx := r.position.x + r.size.x * 0.5
	if st == STUFE_NAH or e["klasse"] == "weiler":
		var n := _fs(k["nah_name"])
		var w := _font.get_string_size(e["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, n).x
		_text(e["name"], Vector2(cx - w * 0.5, _grundlinie(r.position.y + r.size.y * 0.5, n)), n, tc)
		return
	if st == STUFE_FERN:
		var n := _fs(k["fern_name"])
		var ic := _px(k["fern_icon"])
		var w := _font.get_string_size(e["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, n).x
		var gesamt := ic + _px(6.0) + w
		var x0 := cx - gesamt * 0.5
		var my := r.position.y + r.size.y * 0.5
		_icon(_klassen_icon(e), Vector2(x0 + ic * 0.5, my), ic, tc)
		_text(e["name"], Vector2(x0 + ic + _px(6.0), _grundlinie(my, n)), n, tc)
		return
	# Vollschild
	var f := voll_faktor(e["abstand_m"])
	var n1 := _fs(k["name"] * f)
	var n2 := _fs(k["ew"] * f)
	var ic1 := _px(k["name"] * f + 4.0)
	var bi := _px(k["icon"] * f)
	var pad_y := _px(5.0)
	var z1h := maxf(ic1, n1 * ZEILE)
	var z1y := r.position.y + pad_y + z1h * 0.5
	var w1 := ic1 + _px(6.0) + _font.get_string_size(e["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, n1).x
	var x1 := cx - w1 * 0.5
	_icon(_klassen_icon(e), Vector2(x1 + ic1 * 0.5, z1y), ic1, tc)
	_text(e["name"], Vector2(x1 + ic1 + _px(6.0), _grundlinie(z1y, n1)), n1, tc)
	var z2h := maxf(float(bi), n2 * ZEILE)
	var z2y := r.position.y + pad_y + z1h + _px(3.0) + z2h * 0.5
	var w2 := _zeile2_breite(e, n2, bi)
	var x := cx - w2 * 0.5
	var pi := bi * 0.72
	_icon(ICON_PERSON, Vector2(x + pi * 0.5, z2y), pi, tc)
	x += pi + _px(3.0)
	x += _text(tsd(int(e["ew"])), Vector2(x, _grundlinie(z2y, n2)), n2, tc)
	x += _px(10.0)
	var tr: String = e["trend"]
	var tpfad := ICON_HOCH if tr == "hoch" else (ICON_RUNTER if tr == "runter" else ICON_GLEICH)
	var tf: Color = TREND_FARBEN.get(tr, TEXT)
	_icon(tpfad, Vector2(x + n2 * 0.475, z2y), n2 * 0.95, Color(tf.r, tf.g, tf.b, a))
	x += n2 * 0.95
	if not e["bedarf"].is_empty():
		x += _px(14.0)
		var vorher_ersatz := false
		for b in e["bedarf"]:
			var ers := bool(b.get("ersatz", false))
			if ers and not vorher_ersatz:
				_flaeche.draw_line(Vector2(x + _px(3.0), z2y + bi * 0.32), Vector2(x + _px(6.0), z2y - bi * 0.32), tc, 1.5, true)
				x += _px(8.0)
			_icon(_gut_icon(b["gut"]), Vector2(x + bi * 0.5, z2y), bi * 0.9, tc)
			_status_marke(str(b.get("status", "warn")), Vector2(x + bi * 0.86, z2y + bi * 0.40), _px(4.5), a)
			x += bi + _px(4.0)
			vorher_ersatz = ers


## Statusform nach A-07: Kreis = gedeckt, Dreieck = wird gebraucht, Quadrat = fehlt. Form UND Farbe, dunkler Saum.
func _status_marke(status: String, mitte: Vector2, r: float, a: float) -> void:
	var farbe: Color = OK_FARBE if status == "ok" else (BAD_FARBE if status == "bad" else WARN_FARBE)
	farbe.a = a
	var saum := Color(SAUM.r, SAUM.g, SAUM.b, a)
	match status:
		"ok":
			_flaeche.draw_circle(mitte, r + 1.5, saum)
			_flaeche.draw_circle(mitte, r, farbe)
		"bad":
			_flaeche.draw_rect(Rect2(mitte - Vector2(r + 1.5, r + 1.5), Vector2(r + 1.5, r + 1.5) * 2.0), saum)
			_flaeche.draw_rect(Rect2(mitte - Vector2(r, r), Vector2(r, r) * 2.0), farbe)
		_:
			var g := r + 2.2
			_flaeche.draw_colored_polygon(PackedVector2Array([mitte + Vector2(0, -g), mitte + Vector2(g * 1.1, g * 0.8), mitte + Vector2(-g * 1.1, g * 0.8)]), saum)
			var h := r + 0.4
			_flaeche.draw_colored_polygon(PackedVector2Array([mitte + Vector2(0, -h), mitte + Vector2(h * 1.1, h * 0.8), mitte + Vector2(-h * 1.1, h * 0.8)]), farbe)


func _zeichne_industrie(e: Dictionary, r: Rect2, a: float) -> void:
	var k: Dictionary = KLASSEN["industrie"]
	var st: int = e["stufe"]
	var n := _fs(k["name"] if st != STUFE_NAH else k["nah_name"])
	var disc: float = e["disc_px"]
	var pad_x := _px(9.0)
	var farbe: Color = e["farbe"]
	farbe.a = a
	var my := r.position.y + _px(5.0) + maxf(disc, n * ZEILE) * 0.5
	var dc := Vector2(r.position.x + pad_x * 0.7 + disc * 0.5, my)
	var ex: Dictionary = e["extra"]
	var plak := _textur(str(ex.get("plakette", "")))
	if plak != null:
		_flaeche.draw_texture_rect(plak, Rect2(dc - Vector2(disc, disc) * 0.5, Vector2(disc, disc)), false, Color(1, 1, 1, a))
	var x := dc.x + disc * 0.5 + _px(6.0)
	_text(e["name"], Vector2(x, _grundlinie(my, n)), n, farbe)
	if st == STUFE_VOLL:
		# Kette: [Eingang] → [Ausgang], je Güter-Icon
		var ky := r.end.y - _px(5.0) - _px(9.0)
		var ic := _px(15.0)
		var kx := x
		_icon(ICON_KETTE, Vector2(kx + ic * 0.5, ky), ic, Color(farbe.r, farbe.g, farbe.b, a * 0.9))
		kx += ic + _px(5.0)
		for g in ex.get("ein", []):
			_icon(_gut_icon(str(g)), Vector2(kx + ic * 0.5, ky), ic, farbe)
			kx += ic + _px(3.0)
		_text("→", Vector2(kx, _grundlinie(ky, _fs(13))), _fs(13), farbe)
		kx += _px(15.0)
		for g in ex.get("aus", []):
			_icon(_gut_icon(str(g)), Vector2(kx + ic * 0.5, ky), ic, farbe)
			kx += ic + _px(3.0)


func _zeichne_tooltip(id: String) -> void:
	var z := tooltip_zeilen(id)
	if z.is_empty():
		return
	var breite := _px(330.0)
	var pad := _px(11.0)
	var ft := _fs(16)
	var fb := _fs(14)
	var th := _font.get_string_size(z[0], HORIZONTAL_ALIGNMENT_LEFT, breite, ft).y
	var h := th + _px(6.0)
	var hoehen: Array[float] = []
	for i in range(1, z.size()):
		var s := _font.get_multiline_string_size(z[i], HORIZONTAL_ALIGNMENT_LEFT, breite, fb)
		hoehen.append(s.y)
		h += s.y + _px(5.0)
	var vp := _flaeche.get_viewport_rect().size
	var pos := _maus + Vector2(_px(16.0), _px(20.0))
	var te := eintrag(id)
	if not te.is_empty() and te["sichtbar"]:
		pos.y = maxf(pos.y, (te["rect"] as Rect2).end.y + _px(ZEIGER_PX) + _px(8.0))    # unter dem Schild, nicht darüber
	var gesamt := Vector2(breite + pad * 2.0, h + pad * 2.0)
	if pos.x + gesamt.x > vp.x - 6.0:
		pos.x = _maus.x - gesamt.x - _px(12.0)
	if pos.y + gesamt.y > vp.y - 6.0:
		pos.y = _maus.y - gesamt.y - _px(12.0)
	pos = pos.clamp(Vector2(6, 6), Vector2(maxf(6.0, vp.x - gesamt.x - 6.0), maxf(6.0, vp.y - gesamt.y - 6.0)))
	var r := Rect2(pos, gesamt)
	_tip_rect = r
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(PLATTE.r, PLATTE.g, PLATTE.b, 0.96)
	sb.border_color = PLATTE_RAND
	sb.set_border_width_all(maxi(1, int(roundf(_scale * 1.5))))
	sb.set_corner_radius_all(int(_px(7.0)))
	sb.anti_aliasing = true
	_flaeche.draw_style_box(sb, r)
	var y := pos.y + pad
	var e := eintrag(id)
	var tfarbe: Color = TEXT if e["art"] == "ort" else e["farbe"]
	_flaeche.draw_string(_font, Vector2(pos.x + pad, y + _font.get_ascent(ft)), z[0], HORIZONTAL_ALIGNMENT_LEFT, breite, ft, tfarbe)
	y += th + _px(6.0)
	for i in range(1, z.size()):
		_flaeche.draw_multiline_string(_font, Vector2(pos.x + pad, y + _font.get_ascent(fb)), z[i], HORIZONTAL_ALIGNMENT_LEFT, breite, fb, -1, TEXT)
		y += hoehen[i - 1] + _px(5.0)
