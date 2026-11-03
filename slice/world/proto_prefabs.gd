class_name ProtoPrefabs
extends RefCounted
## Phase 4 W2 (TA + Sophie): Prefabs der Prototyp-Welt als GEMERGTE Meshes (1 Mesh, 1 Flaeche, 1 Material je Typ).
## Szene in Metern, Ursprung = Bodenmitte der AABB (y = 0 unten), Front = +z (VERTRAG Welle 2).
##   ProtoPrefabs.vorhanden("kate")                 -> true
##   ProtoPrefabs.mesh_fuer("kate")                 -> ArrayMesh (Material ist in der Flaeche gesetzt, nicht ueberschreiben)
##   ProtoPrefabs.schluessel(instanz)               -> "nebengebaeude/stall_12x8" usw. (Typ + Variante, falls es eine gibt)
##   ProtoPrefabs.custom_fuer(instanz)              -> Color fuer MultiMesh.set_instance_custom_data (Variante in .g)
##   ProtoPrefabs.fahrzeug("fuhrwerk")              -> {mesh, laenge_m, breite_m, gang: {...}}
##   ProtoPrefabs.info(typ)                         -> {y_modus, einheit, ...} (Platzierungshinweise)
## Bausteine: Kenney-Kits (CC0) unter res://props/kenney_proto/<kit>/, umgefaerbt auf Sophies Palette (gebrochene Erdtoene,
## keine Signalfarben): jede Kenney-Farbe wird einer Quellklasse zugeordnet (Holz dunkel/hell, Putz, Rot, Gruen, ...),
## je Bauteil auf eine Zielklasse abgebildet (Fachwerk: dunkle Bretter -> Putz, helle Rahmen -> dunkles Holz) und als
## Spalte einer Palettentextur gespeichert (UV.x). Varianten = 4 Palettenzeilen, gewaehlt per INSTANCE_CUSTOM.y im Shader
## -> 2-4 Hausvarianten je Typ ohne zusaetzliche Draw Calls. Vertexfarbe = Zeile 0 (Ersatz fuer fremde Materialien).
## MultiMesh: use_custom_data = true (Variante, Gang), im Compatibility-Renderer zusaetzlich use_colors = true + Weiss.

const KP := "res://props/kenney_proto/"
const SHADER := preload("res://world/proto_prefab.gdshader")
const PERIODE_M := 240.0          # gang = fmod(strecke_m, PERIODE_M); Rad- und Schrittzahl sind je Periode ganzzahlig
const SCHRITT_M := 2.6            # Trab: ein Doppelschritt
const ZEILEN := 4
const STUFEN := 5
const KLASSEN_N := 20
const STUFE_F := [0.72, 0.86, 1.0, 1.1, 1.2]

# Zielklassen (Palettenspalten)
enum { K_PUTZ, K_FACHWERK, K_HOLZ, K_HOLZ_HELL, K_DACH, K_REET, K_STEIN, K_METALL, K_FENSTER, K_LAUB, K_HEU, K_PFERD,
	K_STOFF, K_SOCKEL, K_SCHIEFER, K_DUNKEL, K_ERDE, K_GRAS, K_PFLASTER, K_GARTEN }
# Quellklassen (Kenney-Farben)
enum { S_PUTZ, S_GLAS, S_DUNKEL, S_HOLZ_D, S_HOLZ_H, S_ROT, S_GRUEN, S_BLAU, S_SIGNAL, S_BEIGE, S_SCHWARZ }
const S_REF_V := [0.77, 1.0, 0.32, 0.58, 0.79, 0.81, 0.75, 0.85, 1.0, 0.99, 0.05]

## Sophies Palette (sRGB): je Klasse 4 Zeilen = Varianten. Dach Zeile 3 = Schiefer, Putz Zeile 3 = leicht grau.
const PALETTE := [
	["D8CDB6", "E2D9C6", "CEC0A4", "D6CFC2"],   # PUTZ (Kalkputz)
	["54402F", "4A3829", "61493A", "5B4636"],   # FACHWERK (Eiche dunkel)
	["7A5D43", "6E553F", "86684B", "735C49"],   # HOLZ (Bretter)
	["A6855F", "9A7B58", "AE8D67", "A08765"],   # HOLZ_HELL
	["9A5944", "8B4F3D", "A1674E", "5E6268"],   # DACH (Ziegel, Zeile 3 Schiefer)
	["8D7A56", "83714F", "96825C", "7E6F50"],   # REET / Stroh
	["A69E8F", "9C958A", "AFA796", "A0998B"],   # STEIN (Sandstein grau)
	["48494D", "444549", "4C4D50", "46484C"],   # METALL
	["3A424E", "3A424E", "3F4752", "383F49"],   # FENSTER
	["587843", "64824A", "4F6E3D", "6A7D46"],   # LAUB
	["A89058", "B09862", "9E8A54", "A4905C"],   # HEU
	["6A4A33", "5B3F2C", "856650", "3F3530"],   # PFERD (Braun, Fuchs, Falbe, Rappe)
	["B6B0A0", "A6A294", "C0B8A2", "9C9F9E"],   # STOFF (Plane, Netz, Kleidung)
	["7E776B", "767069", "857F72", "7A7367"],   # SOCKEL
	["565A61", "5C6066", "51555B", "5A5D63"],   # SCHIEFER (Turmhelm)
	["2E3032", "34322F", "2B2E2E", "323436"],   # DUNKEL (Lok)
	["8A7A62", "857660", "917F66", "8C7C63"],   # ERDE (Hof)
	["6E8C55", "76925A", "688650", "718E57"],   # GRAS
	["8E877C", "948D82", "89827A", "908A80"],   # PFLASTER
	["5E6B45", "66724A", "5A6640", "627048"],   # GARTEN
]

const FT := KP + "fantasy_town/"
## Wandmodule je Stil: [schlicht..], [Fenster..], Tuer, Regel
const STIL := {
	"fachwerk": {"schlicht": ["wall-wood-detail-cross", "wall-wood-detail-diagonal", "wall-wood-detail-horizontal"],
		"fenster": ["wall-wood-window-shutters", "wall-wood-window-small"], "tuer": "wall-wood-door", "regel": "fachwerk", "giebel": K_PUTZ},
	"putz": {"schlicht": ["wall"], "fenster": ["wall-window-shutters", "wall-window-small"], "tuer": "wall-door", "regel": "putz", "giebel": K_PUTZ},
	"stein": {"schlicht": ["wall"], "fenster": ["wall-window-small", "wall-window-shutters"], "tuer": "wall-door", "regel": "stein", "giebel": K_STEIN},
	"stein_arkade": {"schlicht": ["wall"], "fenster": ["wall-arch"], "tuer": "wall-arch", "regel": "stein", "giebel": K_STEIN, "alle_front": "wall-arch"},
	"kirche": {"schlicht": ["wall"], "fenster": ["wall-window-round"], "tuer": "wall-doorway-round", "regel": "stein", "giebel": K_STEIN},
	"holz": {"schlicht": ["wall-wood"], "fenster": ["wall-wood-window-small"], "tuer": "wall-wood-door", "tor": "wall-wood-doorway-square-wide", "regel": "holz", "giebel": K_HOLZ},
}

## Regeln Quellklasse -> Zielklasse (fehlende Eintraege: Standard)
const REGEL_STANDARD := {S_PUTZ: K_PUTZ, S_GLAS: K_FENSTER, S_DUNKEL: K_METALL, S_HOLZ_D: K_HOLZ, S_HOLZ_H: K_HOLZ_HELL,
	S_ROT: K_DACH, S_GRUEN: K_DACH, S_BLAU: K_METALL, S_SIGNAL: K_HOLZ_HELL, S_BEIGE: K_HOLZ_HELL, S_SCHWARZ: K_METALL}
const REGELN := {
	"standard": {},
	"fachwerk": {S_HOLZ_D: K_PUTZ, S_HOLZ_H: K_FACHWERK, S_SIGNAL: K_FACHWERK, S_BEIGE: K_FACHWERK, S_PUTZ: K_PUTZ},
	"putz": {S_PUTZ: K_PUTZ, S_HOLZ_D: K_FACHWERK, S_HOLZ_H: K_FACHWERK, S_BEIGE: K_FACHWERK, S_SIGNAL: K_FACHWERK},
	"stein": {S_PUTZ: K_STEIN, S_HOLZ_D: K_SOCKEL, S_HOLZ_H: K_STEIN, S_BEIGE: K_STEIN, S_SIGNAL: K_STEIN},
	"holz": {S_HOLZ_D: K_HOLZ, S_HOLZ_H: K_FACHWERK, S_BEIGE: K_HOLZ_HELL, S_SIGNAL: K_FACHWERK, S_PUTZ: K_HOLZ},
	"baum": {S_GRUEN: K_LAUB, S_HOLZ_D: K_HOLZ, S_HOLZ_H: K_HOLZ, S_BEIGE: K_HOLZ, S_ROT: K_LAUB, S_SIGNAL: K_LAUB, S_PUTZ: K_LAUB},
	"pferd": {S_HOLZ_D: K_PFERD, S_HOLZ_H: K_PFERD, S_BEIGE: K_PFERD, S_SIGNAL: K_PFERD, S_ROT: K_PFERD, S_PUTZ: K_PFERD,
		S_GRUEN: K_PFERD, S_BLAU: K_PFERD, S_DUNKEL: K_DUNKEL, S_SCHWARZ: K_DUNKEL, S_GLAS: K_PFERD},
	"wagen": {S_PUTZ: K_HOLZ_HELL, S_ROT: K_HOLZ, S_GRUEN: K_HOLZ, S_BLAU: K_METALL, S_SIGNAL: K_HOLZ, S_BEIGE: K_HOLZ_HELL},
	"kutsche": {S_PUTZ: K_DUNKEL, S_ROT: K_DUNKEL, S_GRUEN: K_DUNKEL, S_BLAU: K_DUNKEL, S_SIGNAL: K_HOLZ, S_BEIGE: K_HOLZ_HELL, S_HOLZ_D: K_HOLZ},
	"lok": {S_ROT: K_DUNKEL, S_GRUEN: K_DUNKEL, S_BLAU: K_DUNKEL, S_PUTZ: K_METALL, S_SIGNAL: K_HOLZ_HELL, S_BEIGE: K_HOLZ_HELL, S_GLAS: K_FENSTER},
	"bahnwagen": {S_ROT: K_HOLZ, S_GRUEN: K_HOLZ, S_BLAU: K_HOLZ, S_PUTZ: K_HOLZ_HELL, S_SIGNAL: K_HOLZ_HELL, S_BEIGE: K_HOLZ_HELL},
	"boot": {S_PUTZ: K_HOLZ, S_ROT: K_HOLZ, S_GRUEN: K_HOLZ, S_BLAU: K_HOLZ, S_SIGNAL: K_HOLZ_HELL, S_BEIGE: K_HOLZ_HELL, S_GLAS: K_HOLZ},
	"brunnen": {S_PUTZ: K_STEIN, S_BLAU: K_FENSTER, S_GLAS: K_FENSTER, S_HOLZ_D: K_STEIN, S_HOLZ_H: K_STEIN, S_BEIGE: K_STEIN, S_SIGNAL: K_STEIN},
	"figur": {S_ROT: K_STOFF, S_GRUEN: K_STOFF, S_BLAU: K_STOFF, S_SIGNAL: K_STOFF, S_PUTZ: K_STOFF, S_DUNKEL: K_FACHWERK, S_BEIGE: K_HOLZ_HELL, S_GLAS: K_STOFF},
	"stamm": {S_HOLZ_D: K_HOLZ, S_HOLZ_H: K_HOLZ_HELL, S_BEIGE: K_HOLZ_HELL, S_SIGNAL: K_HOLZ, S_ROT: K_HOLZ, S_GRUEN: K_LAUB},
	"eisen": {S_PUTZ: K_METALL, S_BLAU: K_METALL, S_ROT: K_HOLZ, S_SIGNAL: K_HOLZ, S_BEIGE: K_HOLZ_HELL},
}

## Bekannte Typen (Schluessel fuer mesh_fuer). Fahrzeuge zusaetzlich ueber fahrzeug().
const TYPEN := ["kate", "bauernhof", "grosshof", "handwerkerhaus", "buergerhaus", "gasthaus", "schmiede", "pfarrhaus", "schule",
	"rathaus", "speicher", "kirche_dorf", "kirche_stadt", "kapelle", "stadttor", "scheune", "nebengebaeude",
	"nebengebaeude/scheune_18x10", "nebengebaeude/stall_12x8", "nebengebaeude/schuppen_6x4", "gutshof", "wassermuehle",
	"wassermuehle_rad", "fischerhuette", "netzgestell", "steg", "ruderboot", "floss", "anlegestelle",
	"obstbaum", "laubbaum", "eiche", "heuhaufen", "holzstapel", "zaun_latte", "zaun_feld", "fass", "amboss", "brunnen", "passant",
	"pferd", "fuhrwerk_wagen", "kutsche_wagen", "fuhrwerk_2_pferde", "postkutsche_4_pferde", "dampflok", "tender",
	"personenwagen", "gueterwagen", "flaeche_hof", "flaeche_garten", "flaeche_obstwiese", "flaeche_kirchhof",
	"flaeche_marktplatz", "flaeche_schlag"]
const FAHRZEUGE := {"fuhrwerk": "fuhrwerk_2_pferde", "fuhrwerk_2_pferde": "fuhrwerk_2_pferde", "postkutsche": "postkutsche_4_pferde",
	"postkutsche_4_pferde": "postkutsche_4_pferde", "dampflok": "dampflok_zug", "personenwagen": "personenwagen",
	"gueterwagen": "gueterwagen", "ruderboot": "ruderboot", "floss": "floss"}

static var _cache := {}
static var _modelle := {}
static var _bilder := {}
static var _mat: ShaderMaterial
static var _pal: ImageTexture
static var stats := {"ms_gesamt": 0.0}


# ------------------------------------------------------------------ oeffentliche API
static func vorhanden(typ: String) -> bool:
	return typ in TYPEN or FAHRZEUGE.has(typ)


static func typen() -> PackedStringArray:
	return PackedStringArray(TYPEN)


## Schluessel fuer eine Instanz aus proto_instanzen.json (Nebengebaeude haben Varianten mit eigenem Mesh)
static func schluessel(inst: Dictionary) -> String:
	var typ := String(inst.get("typ", ""))
	var v := String(inst.get("variante", ""))
	if v != "" and (typ + "/" + v) in TYPEN:
		return typ + "/" + v
	return typ


## Custom-Daten je Instanz: r = gang (0, Felix setzt bei Fahrzeugen), g = Variante 0..1 (Palettenzeile), b/a = Nicken/Wanken
static func custom_fuer(inst: Dictionary) -> Color:
	var h := hash(str(inst.get("x", 0.0)) + "/" + str(inst.get("z", 0.0)) + String(inst.get("typ", "")))
	return Color(0.0, variante_wert(absi(h) % ZEILEN), 0.0, 0.0)


static func variante_wert(zeile: int) -> float:
	return (float(zeile) + 0.5) / ZEILEN


static func info(typ: String) -> Dictionary:
	if typ.begins_with("flaeche_"):
		return {"y_modus": "boden_min", "einheit": "1 x 1 m, Instanz mit b (x) und t (z) skalieren", "y_versatz": 0.0}
	if typ in ["steg", "ruderboot", "floss"]:
		return {"y_modus": "wasser", "einheit": "m", "y_versatz": -0.35 if typ == "steg" else -0.15,
			"hinweis": "von ProtoKulissen gesetzt (Pegel), nicht aus den Instanzen bauen"}
	return {"y_modus": "boden_min", "einheit": "m", "y_versatz": 0.0}


static func material() -> ShaderMaterial:
	if _mat == null:
		_mat = ShaderMaterial.new()
		_mat.shader = SHADER
		_mat.set_shader_parameter("palette", palette_textur())
		_mat.set_shader_parameter("palette_zeilen", float(ZEILEN))
		_mat.set_shader_parameter("periode_m", PERIODE_M)
		_mat.set_shader_parameter("schritt_m", SCHRITT_M)
	return _mat


static func palette_textur() -> ImageTexture:
	if _pal == null:
		var img := Image.create(KLASSEN_N * STUFEN, ZEILEN, false, Image.FORMAT_RGB8)
		for k in KLASSEN_N:
			for l in STUFEN:
				for z in ZEILEN:
					img.set_pixel(k * STUFEN + l, z, farbe(k, l, z))
		_pal = ImageTexture.create_from_image(img)
	return _pal


static func farbe(k: int, stufe: int, zeile: int) -> Color:
	var c := Color(PALETTE[k][zeile])
	var f: float = STUFE_F[stufe]
	return Color(minf(c.r * f, 1.0), minf(c.g * f, 1.0), minf(c.b * f, 1.0))


static func mesh_fuer(typ: String) -> Mesh:
	if _cache.has(typ):
		return _cache[typ]
	var t0 := Time.get_ticks_usec()
	var m: ArrayMesh = null
	if typ in TYPEN:
		var b := Bau.new()
		_baue(typ, b)
		m = b.mesh(material())
		m.resource_name = typ
	elif FAHRZEUGE.has(typ):
		m = fahrzeug(typ)["mesh"]
	_cache[typ] = m
	stats["ms_gesamt"] = float(stats["ms_gesamt"]) + (Time.get_ticks_usec() - t0) / 1000.0
	return m


## Fern-LOD (ab ca. 600 m): gleiche Kubatur, Fassaden als Flaechen (Gebaeude ~40-120 statt 1.000-12.000 Dreiecke).
## Fuer Nicht-Gebaeude (Baeume, Kleinkram, Fahrzeuge) = mesh_fuer(typ). Gleiches Material, gleiche Varianten.
const FERN_TYPEN := ["kate", "bauernhof", "grosshof", "handwerkerhaus", "buergerhaus", "gasthaus", "schmiede", "pfarrhaus", "schule",
	"rathaus", "speicher", "kirche_dorf", "kirche_stadt", "kapelle", "stadttor", "scheune", "nebengebaeude",
	"nebengebaeude/scheune_18x10", "nebengebaeude/stall_12x8", "nebengebaeude/schuppen_6x4", "gutshof", "wassermuehle", "fischerhuette"]


static func mesh_fern(typ: String) -> Mesh:
	if not (typ in FERN_TYPEN):
		return mesh_fuer(typ)
	var key := "fern:" + typ
	if _cache.has(key):
		return _cache[key]
	var b := Bau.new()
	b.fern = true
	_baue(typ, b)
	var m := b.mesh(material())
	m.resource_name = typ + "_fern"
	_cache[key] = m
	return m


## Fahrzeug: {mesh, laenge_m, breite_m, hoehe_m, gang: {periode_m, schritt_m, rad_radien_m, custom}, teile}
static func fahrzeug(kategorie: String) -> Dictionary:
	var key := "fz:" + kategorie
	if _cache.has(key):
		return _cache[key]
	var typ: String = FAHRZEUGE.get(kategorie, kategorie)
	var b := Bau.new()
	var teile: Dictionary = {}
	if typ == "dampflok_zug":
		teile = _dampflok_zug(b)
	else:
		_baue(typ, b)
	var m := b.mesh(material())
	m.resource_name = kategorie
	var a := m.get_aabb()
	var d := {"mesh": m, "laenge_m": a.size.z, "breite_m": a.size.x, "hoehe_m": a.size.y, "typ": typ,
		"gang": {"periode_m": PERIODE_M, "schritt_m": SCHRITT_M, "rad_radien_m": b.rad_radien,
			"custom": "INSTANCE_CUSTOM = Color(fmod(strecke_m, periode_m), ProtoPrefabs.variante_wert(0..3), nicken_rad, wanken_rad)",
			"kosten": "Shader: Rad 1 sin/cos je Ecke; CPU: 1 set_instance_custom_data je Fahrzeug und Frame"},
		"teile": teile}
	_cache[key] = d
	return d


# ------------------------------------------------------------------ Farben aus Kenney-Modellen
static func quellklasse(c: Color) -> int:
	var h := c.h
	var s := c.s
	var v := c.v
	if v < 0.12:
		return S_SCHWARZ
	if s < 0.32 and h >= 0.5 and h < 0.78:
		if v > 0.95:
			return S_GLAS
		return S_PUTZ if v >= 0.45 else S_DUNKEL
	if s < 0.14:
		return S_PUTZ if v >= 0.6 else S_DUNKEL
	if h < 0.025 or h > 0.93:
		return S_ROT if s > 0.35 else S_BEIGE
	if h < 0.14:
		if s > 0.68 and v > 0.95:
			return S_SIGNAL
		if s < 0.3:
			return S_BEIGE
		return S_HOLZ_D if v < 0.72 else S_HOLZ_H
	if h < 0.2:
		return S_SIGNAL
	if h < 0.5:
		return S_GRUEN
	if h < 0.78:
		return S_BLAU
	return S_SIGNAL


static func _uv(k: int, stufe: int) -> Vector2:
	return Vector2((k * STUFEN + stufe + 0.5) / float(KLASSEN_N * STUFEN), 0.5 / ZEILEN)


static func _bild(tex: Texture2D) -> Image:
	if tex == null:
		return null
	var key := tex.resource_path if tex.resource_path != "" else str(tex.get_instance_id())
	if _bilder.has(key):
		return _bilder[key]
	var img := tex.get_image()
	if img != null and img.is_compressed():
		img.decompress()
	if img != null:
		img.convert(Image.FORMAT_RGBA8)
	_bilder[key] = img
	return img


## Modell laden und je Flaeche Ecken/Normalen/Indizes + Quellklasse/Stufe je Ecke liefern (Cache je Pfad)
static func modell(pfad: String) -> Array:
	if _modelle.has(pfad):
		return _modelle[pfad]
	var out: Array = []
	var ps := load(pfad) as PackedScene
	if ps == null:
		push_warning("ProtoPrefabs: Modell fehlt " + pfad)
		_modelle[pfad] = out
		return out
	var root := ps.instantiate()
	var stapel: Array = [[root, Transform3D.IDENTITY]]
	while not stapel.is_empty():
		var e: Array = stapel.pop_back()
		var nd: Node = e[0]
		var tr: Transform3D = e[1]
		if nd is Node3D and nd != root:
			tr = tr * (nd as Node3D).transform
		if nd is MeshInstance3D and (nd as MeshInstance3D).mesh != null:
			var mi := nd as MeshInstance3D
			for s in mi.mesh.get_surface_count():
				var arr := mi.mesh.surface_get_arrays(s)
				var mat := mi.get_active_material(s)
				var alb := Color.WHITE
				var img: Image = null
				if mat is BaseMaterial3D:
					alb = (mat as BaseMaterial3D).albedo_color
					img = _bild((mat as BaseMaterial3D).albedo_texture)
				var sv: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var sn: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
				var suv = arr[Mesh.ARRAY_TEX_UV]
				var kl := PackedByteArray()
				var st := PackedByteArray()
				kl.resize(sv.size())
				st.resize(sv.size())
				for i in sv.size():
					var c := alb
					if img != null and suv != null:
						var u: Vector2 = suv[i]
						var px := clampi(int(fposmod(u.x, 1.0) * img.get_width()), 0, img.get_width() - 1)
						var py := clampi(int(fposmod(u.y, 1.0) * img.get_height()), 0, img.get_height() - 1)
						c = img.get_pixel(px, py) * alb
					var q := quellklasse(c)
					kl[i] = q
					st[i] = clampi(int(roundf((c.v - float(S_REF_V[q])) / 0.09)), -2, 2) + 2
				var ix = arr[Mesh.ARRAY_INDEX]
				var idx := PackedInt32Array()
				if ix == null:
					for i in sv.size():
						idx.append(i)
				else:
					idx = ix
				# Vertices in Modellwurzel-Raum
				var v2 := PackedVector3Array()
				var n2 := PackedVector3Array()
				v2.resize(sv.size())
				n2.resize(sv.size())
				var nb := tr.basis.inverse().transposed()
				for i in sv.size():
					v2[i] = tr * sv[i]
					n2[i] = (nb * sn[i]).normalized()
				out.append({"name": String(nd.name), "v": v2, "n": n2, "idx": idx, "kl": kl, "st": st})
		for c in nd.get_children():
			stapel.append([c, tr])
	root.free()
	_modelle[pfad] = out
	return out


# ------------------------------------------------------------------ Akkumulator
class Bau:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var uv := PackedVector2Array()
	var uv2 := PackedVector2Array()
	var col := PackedColorArray()
	var idx := PackedInt32Array()
	var xf := Transform3D.IDENTITY       # Platzierung des aktuellen Teils (nur Drehung + Verschiebung)
	var anim := Vector2.ZERO             # UV2 fuer neue Ecken (Teil * 100 + Drehpunkt-y, Drehpunkt-z)
	var rad_radien: Array = []
	var fern := false                    # Fern-LOD: Fassaden als Flaechen statt Kenney-Module, ohne Kamin

	func _ecke(p: Vector3, nm: Vector3, k: int, s: int) -> void:
		v.append(xf * p)
		n.append((xf.basis * nm).normalized())
		uv.append(ProtoPrefabs._uv(k, s))
		uv2.append(anim)
		col.append(ProtoPrefabs.farbe(k, s, 0))

	## Dreieck; Orientierung automatisch so, dass die Normale zu `aussen` zeigt
	func tri(a: Vector3, b: Vector3, c: Vector3, k: int, s := 2, aussen := Vector3.ZERO) -> void:
		var nm := (b - a).cross(c - a)
		if nm.length_squared() < 1e-12:
			return
		if aussen != Vector3.ZERO and nm.dot(aussen) < 0.0:
			var t := b
			b = c
			c = t
			nm = -nm
		nm = nm.normalized()
		var i := v.size()
		_ecke(a, nm, k, s)
		_ecke(b, nm, k, s)
		_ecke(c, nm, k, s)
		idx.append_array([i, i + 2, i + 1])

	func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, k: int, s := 2, aussen := Vector3.ZERO) -> void:
		tri(a, b, c, k, s, aussen)
		tri(a, c, d, k, s, aussen)

	## Quader (Mitte, Groesse, optional gedreht)
	func box(c: Vector3, g: Vector3, k: int, s := 2, bas := Basis.IDENTITY) -> void:
		var h := g * 0.5
		var p := []
		for e in [Vector3(-1, -1, -1), Vector3(1, -1, -1), Vector3(1, 1, -1), Vector3(-1, 1, -1),
				Vector3(-1, -1, 1), Vector3(1, -1, 1), Vector3(1, 1, 1), Vector3(-1, 1, 1)]:
			p.append(c + bas * (e * h))
		var faces := [[0, 3, 2, 1, Vector3(0, 0, -1)], [4, 5, 6, 7, Vector3(0, 0, 1)], [0, 4, 7, 3, Vector3(-1, 0, 0)],
			[1, 2, 6, 5, Vector3(1, 0, 0)], [3, 7, 6, 2, Vector3(0, 1, 0)], [0, 1, 5, 4, Vector3(0, -1, 0)]]
		for f in faces:
			quad(p[f[0]], p[f[1]], p[f[2]], p[f[3]], k, s, bas * (f[4] as Vector3))

	## Zylinder/Kegel um die y-Achse (r0 unten, r1 oben), seg Seiten
	func kegel(c: Vector3, r0: float, r1: float, h: float, seg: int, k: int, s := 2, deckel := true) -> void:
		for i in seg:
			var a0 := TAU * i / seg
			var a1 := TAU * (i + 1) / seg
			var p0 := c + Vector3(cos(a0) * r0, 0, sin(a0) * r0)
			var p1 := c + Vector3(cos(a1) * r0, 0, sin(a1) * r0)
			var q0 := c + Vector3(cos(a0) * r1, h, sin(a0) * r1)
			var q1 := c + Vector3(cos(a1) * r1, h, sin(a1) * r1)
			var mitte := Vector3(cos((a0 + a1) * 0.5), 0.3, sin((a0 + a1) * 0.5))
			if r1 > 0.001:
				quad(p0, p1, q1, q0, k, s, mitte)
				if deckel:
					tri(c + Vector3(0, h, 0), q0, q1, k, s, Vector3.UP)
			else:
				tri(p0, p1, c + Vector3(0, h, 0), k, s, mitte)

	## Kenney-Modell anhaengen: m_xf (Modellraum -> Bauraum, darf skalieren/spiegeln), regel (Quell- -> Zielklasse),
	## teile: Knotenname -> Teil-Kennung fuer Animation (Drehpunkt = Mitte bzw. Oberkante des Knotens), nur: Knotenfilter
	func modell(pfad: String, m_xf: Transform3D, regel: Dictionary = {}, teile: Dictionary = {}, nur: Array = []) -> void:
		var flaechen: Array = ProtoPrefabs.modell(pfad)
		var gesamt := xf * m_xf
		var nb := gesamt.basis.inverse().transposed()
		var spiegel := gesamt.basis.determinant() < 0.0
		var alt_anim := anim
		for f: Dictionary in flaechen:
			var name: String = f["name"]
			if not nur.is_empty() and not ProtoPrefabs._passt(name, nur):
				continue
			var sv: PackedVector3Array = f["v"]
			var sn: PackedVector3Array = f["n"]
			var kl: PackedByteArray = f["kl"]
			var st: PackedByteArray = f["st"]
			var a := Vector2.ZERO
			var tk := ProtoPrefabs._passt_key(name, teile.keys())
			if tk != "":
				var teil: int = teile[tk]
				var lo := Vector3(INF, INF, INF)
				var hi := -lo
				for p in sv:
					var w: Vector3 = gesamt * p
					lo = lo.min(w)
					hi = hi.max(w)
				var piv_y := (lo.y + hi.y) * 0.5
				if teil == 2 or teil == 3:
					piv_y = hi.y
				a = Vector2(teil * 100.0 + piv_y, (lo.z + hi.z) * 0.5)
				if teil == 1:
					rad_radien.append(snappedf(piv_y, 0.01))
			var basis := v.size()
			for i in sv.size():
				var q: int = kl[i]
				var k: int = regel.get(q, ProtoPrefabs.REGEL_STANDARD[q])
				v.append(gesamt * sv[i])
				n.append((nb * sn[i]).normalized())
				uv.append(ProtoPrefabs._uv(k, st[i]))
				uv2.append(a)
				col.append(ProtoPrefabs.farbe(k, st[i], 0))
			var ix: PackedInt32Array = f["idx"]
			for t in range(0, ix.size(), 3):
				if spiegel:
					idx.append_array([basis + ix[t], basis + ix[t + 2], basis + ix[t + 1]])
				else:
					idx.append_array([basis + ix[t], basis + ix[t + 1], basis + ix[t + 2]])
		anim = alt_anim

	## Fertig: Ursprung = Bodenmitte der AABB (Drehpunkte in UV2 werden mitverschoben)
	func mesh(mat: Material, zentrieren := true) -> ArrayMesh:
		var lo := Vector3(INF, INF, INF)
		var hi := -lo
		for p in v:
			lo = lo.min(p)
			hi = hi.max(p)
		var sh := Vector3(-(lo.x + hi.x) * 0.5, -lo.y, -(lo.z + hi.z) * 0.5) if zentrieren else Vector3(0, -lo.y, 0)
		for i in v.size():
			v[i] += sh
			var a := uv2[i]
			if a.x >= 99.0:
				var teil := floorf(a.x / 100.0 + 0.001)
				uv2[i] = Vector2(teil * 100.0 + (a.x - teil * 100.0) + sh.y, a.y + sh.z)
		for j in rad_radien.size():
			rad_radien[j] = snappedf(float(rad_radien[j]), 0.01)
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = v
		arr[Mesh.ARRAY_NORMAL] = n
		arr[Mesh.ARRAY_TEX_UV] = uv
		arr[Mesh.ARRAY_TEX_UV2] = uv2
		arr[Mesh.ARRAY_COLOR] = col
		arr[Mesh.ARRAY_INDEX] = idx
		var am := ArrayMesh.new()
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		am.surface_set_material(0, mat)
		am.set_meta("dreiecke", idx.size() / 3)
		return am


# ------------------------------------------------------------------ Bausteine Haus
## Knotennamen: Godot benennt doppelte Namen beim Import um (Group, Group2, ...) -> Praefix-Vergleich
static func _passt(name: String, liste: Array) -> bool:
	return _passt_key(name, liste) != ""


static func _passt_key(name: String, liste: Array) -> String:
	for k in liste:
		if name == k or name.begins_with(String(k)):
			return k
	return ""


static func _h(a: int, b: int) -> int:
	return absi(hash(Vector2i(a, b)))


## Wandmodul (Kenney 1 x 1 u, Platte bei x 0,4..0,5) auf ein Segment legen: Mitte unten p, Aussenrichtung nrm, Breite w, Hoehe h
static func _modul(b: Bau, name: String, p: Vector3, nrm: Vector3, w: float, h: float, regel: Dictionary) -> void:
	var t := nrm.cross(Vector3.UP)
	if b.fern:
		return
	var bas := Basis(nrm * 3.0, Vector3.UP * h, t * w)
	b.modell(FT + name + ".glb", Transform3D(bas, p - nrm * 1.5), regel)


## Eine Etage: vier Fassaden. front = +z. art: "eg" (Tuer vorn), "og", "kniestock"
static func _etage(b: Bau, bx: float, tz: float, y0: float, h: float, stil_name: String, art: String, seed: int,
		tor_vorn := false, tuer_seite := "") -> void:
	var stil: Dictionary = STIL[stil_name]
	var regel: Dictionary = REGELN[stil["regel"]]
	var seiten := [[Vector3(0, 0, 1), bx, "front"], [Vector3(0, 0, -1), bx, "hinten"], [Vector3(1, 0, 0), tz, "rechts"], [Vector3(-1, 0, 0), tz, "links"]]
	for si in seiten.size():
		var nrm: Vector3 = seiten[si][0]
		var laenge: float = seiten[si][1]
		var seite: String = seiten[si][2]
		var mz := maxi(1, int(roundf(laenge / 3.0)))
		var w := laenge / mz
		var t := nrm.cross(Vector3.UP)
		var tiefe := tz if absf(nrm.z) > 0.5 else bx
		var mitte := nrm * tiefe * 0.5 + Vector3(0, y0, 0)
		if b.fern:
			var k_f: int = {"fachwerk": K_PUTZ, "putz": K_PUTZ, "holz": K_HOLZ}.get(stil_name, K_STEIN)
			var a0 := mitte - t * laenge * 0.5
			var a1 := mitte + t * laenge * 0.5
			b.quad(a0, a1, a1 + Vector3(0, h, 0), a0 + Vector3(0, h, 0), k_f, 1 if stil_name == "fachwerk" else 2, nrm)
			continue
		for i in mz:
			var off := (i + 0.5) * w - laenge * 0.5
			var p := mitte + t * off
			var name: String
			var hs := _h(seed + si * 31, i)
			var schlicht: Array = stil["schlicht"]
			var fenster: Array = stil["fenster"]
			name = schlicht[hs % schlicht.size()]
			var rand := mz >= 3 and (i == 0 or i == mz - 1)
			if art == "kniestock":
				name = "wall-wood-detail-horizontal" if stil_name == "fachwerk" else schlicht[0]
			elif seite == "front" or seite == "hinten":
				if art == "eg" and seite == "front" and i == mz / 2:
					name = stil.get("tor", stil["tuer"]) if tor_vorn else stil["tuer"]
				elif stil.has("alle_front") and seite == "front" and art == "eg":
					name = stil["alle_front"]
				elif seite == "front" and (not rand or mz <= 2):
					name = fenster[hs % fenster.size()]
				elif seite == "hinten" and i % 2 == 1:
					name = fenster[(hs + 1) % fenster.size()]
			else:
				if art == "eg" and tuer_seite == seite and i == mz / 2:
					name = stil["tuer"]
				elif not rand and (i + si) % 2 == 0:
					name = fenster[hs % fenster.size()]
			_modul(b, name, p, nrm, w, h, regel)


## Satteldach. first_x: First entlang x (Giebel auf +-x), sonst entlang z. ye = Traufhoehe, rise = Dachhoehe.
static func _dach(b: Bau, bx: float, tz: float, ye: float, rise: float, first_x: bool, k: int, giebel_k: int,
		fachwerk_giebel: bool, ue := 0.45, ug := 0.35, dicke := 0.22) -> void:
	var L := (bx if first_x else tz) * 0.5
	var D := (tz if first_x else bx) * 0.5
	var P := func(u: float, y: float, w: float) -> Vector3:
		return Vector3(u, y, w) if first_x else Vector3(w, y, u)
	var sl := rise / D
	var yr := ye + rise
	var ye2 := ye - ue * sl
	var Lg := L + ug
	for sg in [1.0, -1.0]:
		var aussen: Vector3 = P.call(0.0, D, sg * rise).normalized()
		var e0: Vector3 = P.call(-Lg, ye2, sg * (D + ue))
		var e1: Vector3 = P.call(Lg, ye2, sg * (D + ue))
		var r0: Vector3 = P.call(-Lg, yr, 0.0)
		var r1: Vector3 = P.call(Lg, yr, 0.0)
		b.quad(e0, e1, r1, r0, k, 2, aussen)
		var dy := Vector3(0, -dicke, 0)
		b.quad(e0 + dy, e1 + dy, r1 + dy, r0 + dy, k, 0, -aussen)
		var aw: Vector3 = P.call(0.0, 0.0, sg)
		b.quad(e0, e1, e1 + dy, e0 + dy, k, 1, aw)
		for su in [1.0, -1.0]:
			var au: Vector3 = P.call(su, 0.0, 0.0)
			var a0: Vector3 = P.call(su * Lg, ye2, sg * (D + ue))
			var a1: Vector3 = P.call(su * Lg, yr, 0.0)
			b.quad(a0, a1, a1 + dy, a0 + dy, k, 1, au)
	# Firstbalken
	var fg: Vector3 = (Vector3(Lg * 2.0, 0.28, 0.32) if first_x else Vector3(0.32, 0.28, Lg * 2.0))
	b.box(Vector3(0, yr + 0.06, 0), fg, k, 0)
	# Giebeldreiecke
	for su in [1.0, -1.0]:
		var au: Vector3 = P.call(su, 0.0, 0.0)
		var g0: Vector3 = P.call(su * L, ye, -D)
		var g1: Vector3 = P.call(su * L, ye, D)
		var g2: Vector3 = P.call(su * L, yr, 0.0)
		b.tri(g0, g1, g2, giebel_k, 2, au)
		if fachwerk_giebel:
			var vor := 0.06
			var s_b := Vector3(0.14, 0.22, 2.0 * D) if first_x else Vector3(2.0 * D, 0.22, 0.14)
			b.box(P.call(su * (L + vor), ye + 0.11, 0.0), s_b, K_FACHWERK, 2)
			var hm := ye + rise * 0.48
			var s_m := Vector3(0.14, 0.2, D) if first_x else Vector3(D, 0.2, 0.14)
			b.box(P.call(su * (L + vor), hm, 0.0), s_m, K_FACHWERK, 2)
			var s_p := Vector3(0.14, rise * 0.92, 0.2) if first_x else Vector3(0.2, rise * 0.92, 0.14)
			b.box(P.call(su * (L + vor), ye + rise * 0.46, 0.0), s_p, K_FACHWERK, 2)


static func _kamin(b: Bau, x: float, yr: float, z: float, gross := false) -> void:
	if b.fern:
		return
	var s := 3.6 if gross else 3.0
	b.modell(FT + "chimney.glb", Transform3D(Basis().scaled(Vector3(s, s, s)), Vector3(x - 0.32 * s, yr - s * 0.7, z)), REGELN["stein"])


## Generisches Haus. cfg: bx, tz, sockel, etagen [[h, stil, art]], rise, first_x, dach_k, kamin (x-Anteil oder null), tor_vorn
static func _haus(b: Bau, cfg: Dictionary, seed: int) -> float:
	var bx: float = cfg["bx"]
	var tz: float = cfg["tz"]
	var sh: float = cfg.get("sockel", 0.4)
	if sh > 0.0:
		b.box(Vector3(0, sh * 0.5, 0), Vector3(bx + 0.3, sh, tz + 0.3), K_SOCKEL, 2)
	var y := sh
	var etagen: Array = cfg["etagen"]
	var letzter := "putz"
	for ei in etagen.size():
		var e: Array = etagen[ei]
		var art: String = e[2] if e.size() > 2 else ("eg" if ei == 0 else "og")
		_etage(b, bx, tz, y, e[0], e[1], art, seed + ei * 7, cfg.get("tor_vorn", false) and ei == 0, cfg.get("tuer_seite", ""))
		y += float(e[0])
		letzter = e[1]
	var first_x: bool = cfg.get("first_x", bx >= tz)
	var stil: Dictionary = STIL[letzter]
	var rise: float = cfg["rise"]
	_dach(b, bx, tz, y, rise, first_x, cfg.get("dach_k", K_DACH), stil["giebel"], letzter == "fachwerk",
		cfg.get("ue", 0.45), cfg.get("ug", 0.35), cfg.get("dicke", 0.22))
	if cfg.get("kamin", null) != null:
		var kx: float = cfg["kamin"]
		if first_x:
			_kamin(b, bx * kx, y + rise, 0.0, cfg.get("kamin_gross", false))
		else:
			_kamin(b, 0.0, y + rise, tz * kx, cfg.get("kamin_gross", false))
	return y + rise


## Turm: quadratisch, Etagen aus Steinmodulen, Helm (Pyramide) in Schiefer
static func _turm(b: Bau, c: Vector3, s: float, etagen: int, eh: float, helm_h: float, seed: int, tor := false) -> float:
	var alt := b.xf
	b.xf = alt * Transform3D(Basis(), c)
	b.box(Vector3(0, 0.25, 0), Vector3(s + 0.4, 0.5, s + 0.4), K_SOCKEL, 2)
	var y := 0.5
	for i in etagen:
		var stil := "stein"
		var art := "og"
		if i == etagen - 1:
			stil = "kirche"
		if tor and i == 0:
			stil = "stein_arkade"
			art = "eg"
		_etage(b, s, s, y, eh, stil, art, seed + i)
		y += eh
	# Gesims + Helm
	b.box(Vector3(0, y + 0.15, 0), Vector3(s + 0.6, 0.3, s + 0.6), K_STEIN, 1)
	var hs := s * 0.5 + 0.35
	var top := Vector3(0, y + 0.3 + helm_h, 0)
	var ecken := [Vector3(-hs, y + 0.3, -hs), Vector3(hs, y + 0.3, -hs), Vector3(hs, y + 0.3, hs), Vector3(-hs, y + 0.3, hs)]
	for i in 4:
		var a: Vector3 = ecken[i]
		var bb: Vector3 = ecken[(i + 1) % 4]
		b.tri(a, bb, top, K_SCHIEFER, 2, ((a + bb) * 0.5 - Vector3(0, y, 0)) * Vector3(1, 0, 1) + Vector3(0, 0.4, 0))
	b.box(top + Vector3(0, 0.5, 0), Vector3(0.12, 1.0, 0.12), K_METALL, 1)
	b.xf = alt
	return y + 0.3 + helm_h + 1.0


# ------------------------------------------------------------------ Bauplaene je Typ
static func _baue(typ: String, b: Bau) -> void:
	var sd := absi(hash(typ)) % 1000
	match typ:
		"kate":
			_haus(b, {"bx": 8.0, "tz": 6.0, "sockel": 0.3, "etagen": [[3.0, "fachwerk"]], "rise": 3.3, "dach_k": K_REET,
				"ue": 0.6, "ug": 0.4, "dicke": 0.35, "kamin": 0.15}, sd)
		"bauernhof":
			_haus(b, {"bx": 12.0, "tz": 9.0, "etagen": [[3.0, "putz"], [1.5, "fachwerk", "kniestock"]], "rise": 5.0, "kamin": -0.2}, sd)
		"grosshof":
			_haus(b, {"bx": 12.0, "tz": 9.0, "etagen": [[3.0, "stein"], [3.0, "fachwerk"]], "rise": 4.6, "kamin": 0.25}, sd)
		"handwerkerhaus":
			_haus(b, {"bx": 9.0, "tz": 12.0, "etagen": [[3.0, "putz"], [3.0, "fachwerk"]], "rise": 4.0, "first_x": false, "kamin": -0.25}, sd)
		"buergerhaus":
			_haus(b, {"bx": 12.0, "tz": 14.0, "sockel": 0.6, "etagen": [[3.6, "putz"], [3.6, "fachwerk"], [3.6, "fachwerk"]],
				"rise": 3.9, "first_x": false, "kamin": -0.3}, sd)
		"gasthaus":
			_haus(b, {"bx": 14.0, "tz": 12.0, "etagen": [[3.2, "putz"], [3.0, "fachwerk"]], "rise": 5.5, "kamin": 0.3}, sd)
		"pfarrhaus":
			_haus(b, {"bx": 12.0, "tz": 10.0, "etagen": [[3.0, "putz"], [3.0, "putz"]], "rise": 4.8, "kamin": 0.3}, sd)
		"schule":
			_haus(b, {"bx": 12.0, "tz": 9.0, "etagen": [[3.4, "putz"]], "rise": 4.4, "kamin": 0.3}, sd)
		"schmiede":
			_haus(b, {"bx": 9.0, "tz": 7.0, "etagen": [[3.2, "stein"]], "rise": 3.5, "kamin": 0.28, "kamin_gross": true, "tor_vorn": true}, sd)
		"rathaus":
			var yr := _haus(b, {"bx": 16.0, "tz": 12.0, "sockel": 0.5, "etagen": [[3.6, "stein_arkade"], [3.3, "fachwerk"], [3.3, "fachwerk"]],
				"rise": 5.5}, sd)
			# Dachreiter (Glockentuermchen)
			b.box(Vector3(0, yr + 1.0, 0), Vector3(1.6, 2.6, 1.6), K_FACHWERK, 2)
			b.kegel(Vector3(0, yr + 2.3, 0), 1.25, 0.0, 3.2, 4, K_SCHIEFER, 2)
		"speicher":
			_haus(b, {"bx": 20.0, "tz": 12.0, "sockel": 0.5, "etagen": [[3.5, "stein"], [3.2, "fachwerk"], [3.2, "fachwerk"]],
				"rise": 6.0, "tor_vorn": true}, sd)
		"scheune", "nebengebaeude", "nebengebaeude/scheune_18x10":
			_haus(b, {"bx": 18.0, "tz": 10.0, "sockel": 0.3, "etagen": [[4.5, "holz"]], "rise": 4.4, "tor_vorn": true}, sd)
		"nebengebaeude/stall_12x8":
			_haus(b, {"bx": 12.0, "tz": 8.0, "sockel": 0.3, "etagen": [[3.0, "stein"]], "rise": 3.6}, sd)
		"nebengebaeude/schuppen_6x4":
			_haus(b, {"bx": 6.0, "tz": 4.0, "sockel": 0.1, "etagen": [[2.6, "holz"]], "rise": 2.0, "ue": 0.35, "ug": 0.3}, sd)
		"fischerhuette":
			_haus(b, {"bx": 8.0, "tz": 6.0, "sockel": 0.2, "etagen": [[2.6, "holz"]], "rise": 3.0, "dach_k": K_REET,
				"ue": 0.5, "ug": 0.35, "dicke": 0.32, "kamin": 0.25}, sd)
		"wassermuehle":
			_haus(b, {"bx": 12.0, "tz": 12.0, "sockel": 0.6, "etagen": [[3.5, "stein"], [3.0, "fachwerk"]], "rise": 5.5,
				"first_x": true, "kamin": 0.3}, sd)
		"wassermuehle_rad":
			var s := 5.0 / 1.799
			b.modell(FT + "watermill.glb", Transform3D(Basis().scaled(Vector3(s, s, s)), Vector3(0, 2.5, 0)), REGELN["holz"],
				{"watermill": 5})
		"kirche_dorf":
			_kirche(b, 20.0, 10.0, 6.5, 5.0, 4, 5.0, 9.5, sd)
		"kirche_stadt":
			_kirche(b, 35.0, 15.0, 10.0, 7.0, 5, 6.0, 19.0, sd)
		"kapelle":
			_kirche(b, 10.0, 7.0, 4.0, 0.0, 0, 0.0, 0.0, sd)
		"stadttor":
			_turm(b, Vector3.ZERO, 8.0, 3, 4.4, 4.0, sd, true)
		"gutshof":
			_gutshof(b, sd)
		"netzgestell":
			for i in 2:
				_modul(b, "poles", Vector3(-1.0 + i * 2.0, 0, 0.15), Vector3(0, 0, 1), 2.0, 2.2, REGELN["holz"])
			for i in 2:
				var x0 := -1.95 + i * 2.0
				b.quad(Vector3(x0, 0.5, 0.0), Vector3(x0 + 1.8, 0.5, 0.0), Vector3(x0 + 1.8, 2.0, 0.0), Vector3(x0, 2.0, 0.0), K_STOFF, 1, Vector3(0, 0, 1))
				b.quad(Vector3(x0, 0.5, 0.0), Vector3(x0 + 1.8, 0.5, 0.0), Vector3(x0 + 1.8, 2.0, 0.0), Vector3(x0, 2.0, 0.0), K_STOFF, 1, Vector3(0, 0, -1))
		"steg":
			_steg(b, 25.0, 2.0)
		"anlegestelle":
			_steg(b, 10.0, 3.0)
		"ruderboot":
			var s := 4.5 / 2.372
			b.modell(KP + "watercraft/boat-row-small.glb", Transform3D(Basis().scaled(Vector3(s * 0.55, 1.2, s)), Vector3.ZERO), REGELN["boot"])
		"floss":
			_floss(b)
		"obstbaum":
			# runde Krone (Nature tree_default, 7 m) statt Fantasy-Town-Tanne
			var s := 7.0 / 1.708
			b.modell(KP + "nature/tree_default.glb", Transform3D(Basis().scaled(Vector3(s * 1.15, s, s * 1.15)), Vector3.ZERO), REGELN["baum"])
		"laubbaum":
			var s := 18.0 / 1.708
			b.modell(KP + "nature/tree_default.glb", Transform3D(Basis().scaled(Vector3(s, s, s)), Vector3.ZERO), REGELN["baum"])
		"eiche":
			var s := 20.0 / 1.226
			b.modell(KP + "nature/tree_oak.glb", Transform3D(Basis().scaled(Vector3(s, s, s)), Vector3.ZERO), REGELN["baum"])
		"heuhaufen":
			b.kegel(Vector3.ZERO, 1.25, 1.1, 0.7, 8, K_HEU, 2, false)
			b.kegel(Vector3(0, 0.7, 0), 1.1, 0.55, 0.9, 8, K_HEU, 3, false)
			b.kegel(Vector3(0, 1.6, 0), 0.55, 0.0, 0.6, 8, K_HEU, 3)
			b.box(Vector3(0, 2.1, 0), Vector3(0.06, 0.6, 0.06), K_HOLZ, 1)
		"holzstapel":
			var s := 4.0 / 0.71
			b.modell(KP + "nature/log_stack.glb", Transform3D(Basis().scaled(Vector3(s, s, s)), Vector3.ZERO), REGELN["stamm"])
		"zaun_latte":
			var s := 2.895
			b.modell(FT + "fence.glb", Transform3D(Basis().scaled(Vector3(s, s, s)), Vector3(-0.46 * s, 0, 0)), REGELN["holz"])
		"zaun_feld":
			b.box(Vector3(0, 0.5, -1.45), Vector3(0.12, 1.0, 0.12), K_HOLZ, 1)
			b.box(Vector3(0, 0.5, 1.45), Vector3(0.12, 1.0, 0.12), K_HOLZ, 1)
			b.box(Vector3(0, 0.85, 0), Vector3(0.08, 0.1, 3.0), K_HOLZ_HELL, 1)
			b.box(Vector3(0, 0.45, 0), Vector3(0.08, 0.1, 3.0), K_HOLZ_HELL, 1)
		"fass":
			var s := 0.9 / 0.344
			b.modell(KP + "survival/barrel.glb", Transform3D(Basis().scaled(Vector3(s, s, s)), Vector3.ZERO), REGELN["standard"])
		"amboss":
			var s := 0.8 / 0.323
			b.modell(KP + "survival/workbench-anvil.glb", Transform3D(Basis().scaled(Vector3(s, s, s)), Vector3.ZERO), REGELN["eisen"])
		"brunnen":
			b.modell(FT + "fountain-round.glb", Transform3D(Basis().scaled(Vector3(3.0, 3.0, 3.0)), Vector3.ZERO), REGELN["brunnen"])
		"passant":
			var s := 1.75 / 0.862
			b.modell(KP + "graveyard/character-keeper.glb", Transform3D(Basis().scaled(Vector3(s, s, s)), Vector3.ZERO), REGELN["figur"])
		"pferd":
			_pferd(b, Vector3.ZERO, false)
		"fuhrwerk_wagen":
			_wagen(b, false, Vector3.ZERO)
		"kutsche_wagen":
			_wagen(b, true, Vector3.ZERO)
		"fuhrwerk_2_pferde":
			_gespann(b, false)
		"postkutsche_4_pferde":
			_gespann(b, true)
		"dampflok":
			_lok(b, 0.0)
		"tender":
			_tender(b, 0.0)
		"personenwagen":
			var sz := 6.8 / 2.7
			b.modell(KP + "train/train-carriage-box.glb", Transform3D(Basis().scaled(Vector3(2.5, 2.5, sz)), Vector3.ZERO), REGELN["bahnwagen"])
			# Personenwagen 1835: geschlossener Kasten mit Fensterband und flachem Dach (Kenney-Box ist offen)
			b.box(Vector3(0, 3.33, 0), Vector3(3.1, 0.18, 6.6), K_DUNKEL, 2)
			for sx in [-1.0, 1.0]:
				for i in 4:
					b.box(Vector3(sx * 1.52, 2.55, -2.25 + i * 1.5), Vector3(0.06, 0.7, 0.9), K_FENSTER, 2)
		"gueterwagen":
			var sz := 6.9 / 2.7
			b.modell(KP + "train/train-carriage-coal.glb", Transform3D(Basis().scaled(Vector3(2.5, 2.2, sz)), Vector3.ZERO), REGELN["bahnwagen"])
		_:
			if typ.begins_with("flaeche_"):
				var k := K_ERDE
				match typ:
					"flaeche_garten": k = K_GARTEN
					"flaeche_obstwiese": k = K_GRAS
					"flaeche_kirchhof": k = K_GRAS
					"flaeche_marktplatz": k = K_PFLASTER
				b.box(Vector3(0, 0.06, 0), Vector3(1.0, 0.12, 1.0), k, 2)
			else:
				push_warning("ProtoPrefabs: kein Bauplan fuer " + typ)
				b.box(Vector3(0, 2.5, 0), Vector3(5, 5, 5), K_SOCKEL)


static func _kirche(b: Bau, lang: float, breit: float, traufe: float, turm_s: float, turm_etagen: int, turm_eh: float, helm: float, sd: int) -> void:
	# Schiff entlang x, Turm am Westende (-x) innerhalb der Laenge
	var schiff_l := lang - turm_s
	b.xf = Transform3D(Basis(), Vector3(turm_s * 0.5, 0, 0))
	var etagen: Array = [[traufe, "kirche"]]
	_haus(b, {"bx": schiff_l, "tz": breit, "sockel": 0.5, "etagen": etagen, "rise": breit * 0.62, "first_x": true,
		"tuer_seite": "rechts"}, sd)
	b.xf = Transform3D.IDENTITY
	if turm_etagen > 0:
		_turm(b, Vector3(-lang * 0.5 + turm_s * 0.5, 0, 0), turm_s, turm_etagen, turm_eh, helm, sd + 5)


static func _gutshof(b: Bau, sd: int) -> void:
	# Vierseithof 40 x 40, Tor im Sueden (+z): Herrenhaus Nord, Scheune West, Stall Ost, Torwand Sued
	b.xf = Transform3D(Basis(), Vector3(0, 0, -14.5))
	_haus(b, {"bx": 40.0, "tz": 11.0, "sockel": 0.6, "etagen": [[3.4, "putz"], [3.2, "fachwerk"]], "rise": 6.2, "kamin": 0.3}, sd)
	b.xf = Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(-15.0, 0, 5.5))
	_haus(b, {"bx": 29.0, "tz": 10.0, "sockel": 0.3, "etagen": [[4.5, "holz"]], "rise": 4.4, "tor_vorn": true}, sd + 1)
	b.xf = Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(15.0, 0, 5.5))
	_haus(b, {"bx": 29.0, "tz": 10.0, "sockel": 0.3, "etagen": [[3.2, "stein"]], "rise": 3.8}, sd + 2)
	b.xf = Transform3D.IDENTITY
	# Torwand mit Pfeilern
	for sx in [-1.0, 1.0]:
		b.box(Vector3(sx * 6.0, 1.3, 19.6), Vector3(8.0, 2.6, 0.6), K_STEIN, 2)
		b.box(Vector3(sx * 2.0, 1.7, 19.6), Vector3(0.9, 3.4, 0.9), K_STEIN, 3)
	b.box(Vector3(0, 0.03, 4.0), Vector3(20.0, 0.06, 29.0), K_ERDE, 2)


static func _steg(b: Bau, lang: float, breit: float) -> void:
	# Deck aus Kenney-Planken (Segmente 2,5 m), Pfaehle je 2,5 m beidseitig; y = 0 Pfahlfuss, Deck auf 1,0 m
	var n := int(roundf(lang / 2.5))
	var seg := lang / n
	for i in n:
		var z := -lang * 0.5 + (i + 0.5) * seg
		b.modell(FT + "planks.glb", Transform3D(Basis().scaled(Vector3(breit, 1.5, seg)), Vector3(0, 1.0, z)), REGELN["stamm"])
		b.box(Vector3(0, 0.95, z - seg * 0.5 + 0.1), Vector3(breit, 0.12, 0.16), K_FACHWERK, 2)
	for i in n + 1:
		var z := -lang * 0.5 + i * seg
		z = clampf(z, -lang * 0.5 + 0.1, lang * 0.5 - 0.1)
		for sx in [-1.0, 1.0]:
			b.box(Vector3(sx * (breit * 0.5 - 0.1), 0.6, z), Vector3(0.18, 1.2, 0.18), K_FACHWERK, 1)


static func _floss(b: Bau) -> void:
	# 7 Staemme 8 m (Survival tree-log, d 0,4 m), 2 Querhoelzer, Stammladung 3 + 2 + 1, Steuerruder hinten (-z)
	var r := 1.6
	for i in 7:
		var x := (i - 3) * 0.42
		b.modell(KP + "survival/tree-log.glb", Transform3D(Basis().scaled(Vector3(r, r, 8.0)), Vector3(x, 0.17, 0.0)), REGELN["stamm"])
	for z in [-3.0, 3.0]:
		b.modell(KP + "survival/tree-log.glb", Transform3D(Basis(Vector3.UP, PI * 0.5).scaled(Vector3(1.1, 1.1, 3.0)), Vector3(0, 0.5, z)), REGELN["stamm"])
	var lage := [[-0.5, 0], [0.0, 0], [0.5, 0], [-0.25, 1], [0.25, 1], [0.0, 2]]
	for e in lage:
		b.modell(KP + "survival/tree-log.glb", Transform3D(Basis().scaled(Vector3(2.0, 2.0, 5.5)), Vector3(e[0], 0.72 + e[1] * 0.45, 0.6)), REGELN["stamm"])
	b.box(Vector3(0, 1.2, -3.6), Vector3(0.12, 1.4, 0.12), K_HOLZ, 1)
	b.box(Vector3(0, 1.0, -4.3), Vector3(0.1, 0.08, 1.6), K_HOLZ_HELL, 1, Basis(Vector3.RIGHT, -0.25))


static func _pferd(b: Bau, pos: Vector3, phase_tausch: bool) -> void:
	# Kenney animal-horse: Kopf bei -x -> +90 Grad (Kopf nach +z); Laenge 2,9 m, Hoehe 2,2 m
	var bas := Basis(Vector3.UP, PI * 0.5) * Basis().scaled(Vector3(2.88, 2.45, 2.88))
	var a := 2 if not phase_tausch else 3
	var c := 3 if not phase_tausch else 2
	var teile := {"leg-front-left": a, "leg-back-right": a, "leg-front-right": c, "leg-back-left": c,
		"torso": 4, "neck": 4, "head": 4, "tail": 4}
	b.modell(KP + "prototype/animal-horse.glb", Transform3D(bas, pos), REGELN["pferd"], teile)


## Wagen: Kenney cart (Leiterwagen) bzw. cart-high (Kutschkasten) + Vorderachse, Querfaktor 0,65 (Audit)
static func _wagen(b: Bau, kutsche: bool, pos: Vector3) -> float:
	var pfad := FT + ("cart-high.glb" if kutsche else "cart.glb")
	var lz := 1.39 if kutsche else 1.34
	var ziel := 5.0
	var s := ziel / lz
	var bas := Basis().scaled(Vector3(s * 0.65, s, s))
	b.modell(pfad, Transform3D(bas, pos), REGELN["kutsche" if kutsche else "wagen"], {"Group": 1})
	# Vorderachse: dieselben Raeder, kleiner, 2,2 m weiter vorn
	var bas2 := Basis().scaled(Vector3(s * 0.65 * 0.8, s * 0.78, s * 0.78))
	b.modell(pfad, Transform3D(bas2, pos + Vector3(0, 0, -2.6)), REGELN["wagen"], {"Group": 1}, ["Group"])
	if kutsche:
		# Verdeck/Dach: flache Kiste mit Gepaeckgitter
		b.box(pos + Vector3(0, 3.05, -0.1), Vector3(2.0, 0.18, 3.6), K_DUNKEL, 1)
		b.box(pos + Vector3(0, 3.25, -0.6), Vector3(1.6, 0.3, 1.8), K_STOFF, 1)
	return 0.695 * s


static func _gespann(b: Bau, kutsche: bool) -> void:
	# Wagen hinten (-z), Deichsel, Pferde vorn (+z). Fuhrwerk: 2 Pferde nebeneinander, Postkutsche: 2 x 2 (Vierspaenner)
	var front := _wagen(b, kutsche, Vector3.ZERO)
	var z0 := front + 0.55 + 1.45
	b.box(Vector3(0, 0.95, front + 1.4), Vector3(0.12, 0.12, 2.9 if not kutsche else 6.0), K_HOLZ, 1)
	var paare := 2 if kutsche else 1
	for pz in paare:
		for sx in [-0.62, 0.62]:
			_pferd(b, Vector3(sx, 0, z0 + pz * 3.0), false)


static func _lok(b: Bau, z: float) -> void:
	# Train Kit Lok: Hoehe als Bezug (2,592 m/u -> H 4,3 m), Laenge mit Laengsfaktor auf 9,04 m (1,19 x 7,62 m real)
	var bas := Basis().scaled(Vector3(2.592, 2.592, 9.04 / 2.6))
	b.modell(KP + "train/train-locomotive-a.glb", Transform3D(bas, Vector3(0, 0, z)), REGELN["lok"])


static func _tender(b: Bau, z: float) -> void:
	var bas := Basis().scaled(Vector3(2.5, 2.0, 4.76 / 2.7))
	b.modell(KP + "train/train-carriage-coal.glb", Transform3D(bas, Vector3(0, 0, z)), REGELN["lok"])


static func _dampflok_zug(b: Bau) -> Dictionary:
	_lok(b, 4.76 * 0.5 + 0.0)
	_tender(b, -9.04 * 0.5)
	return {"lok_m": 9.04, "tender_m": 4.76, "real_m": 7.62 + 3.97, "faktor": 13.8 / (7.62 + 3.97)}
