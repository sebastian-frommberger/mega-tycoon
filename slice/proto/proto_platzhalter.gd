extends RefCounted
## Phase 4 Welle 1 (Felix): Platzhalter für Gebäude, Fahrzeuge und Kulisse aus proto_instanzen.json.
## Je Typ ein Mesh aus Boxen (Häuser mit Satteldach-Prisma, Kirchen mit Turm, Bäume mit Stamm und Krone) in den
## ZIELMASSEN, neutrale Farbe nach Kategorie (Vertexfarbe), ein MultiMesh je Typ (1 Draw Call je Typ und Pass).
## Instanz: {typ, x, z, rot_deg, parzelle}; rot_deg = Drehung um +Y in Grad (Godot-Konvention, Modell-Vorne = +z);
## Fußpunkt = tiefste Geländehöhe unter den 4 Ecken (nichts schwebt am Hang).
##
## Maßquelle je Typ (erste passende gewinnt, Quelle steht in masse(typ).quelle):
##   1. regelwerk.haustypen[typ]           grundriss_m [b, t], first_m / traufe_m / turm_m, geschosse
##   2. regelwerk.skalen.gebaeude_m[typ]   b, t, h
##   3. regelwerk.skalen.industrie_m[typ]  haupt [b, t], landmarke_h
##   4. regelwerk.skalen.fahrzeuge_dm[typ] l, b (dm), h
##   5. import_faktoren.rollen[typ]        masse_m [x, y, z] (Zielmaße der Kenney-Rolle, 10_import_faktoren.json)
##   6. ZUSATZ (unten)                     Steg, Fischerhütte (16 §5 M14), Annahmen Felix
## Unbekannter Typ: 5 × 5 × 5 m magenta, Eintrag in unbekannt (proto_mass meldet ihn rot).
## Welle 2: flaeche_* (Stadt-Erweiterung: Garten, Hof, Kirchhof, Marktplatz, Obstwiese, Schlag; b × t je Instanz) sind
## flache Bodenflächen: ein Mesh je Typ (alle Instanzen), Raster ≤ 2,5 m am Gelände anliegend (+0,08 m, unter dem
## Straßenband +0,15 m), Farbe nach Typ, kein Schatten, 1 Draw Call je Typ. Typen mit varianten_m (nebengebaeude) werden
## je Instanz auf b × t skaliert (Grundmesh = mittlere Variante). Sichtweiten (Perf, felix_perf_aufschluesselung.md):
## Kleinteile 700 m, Platzhalter-Bäume 1.800 m (wie TA), Flächen 2.500 m.
## Echte Prefabs (Welle 2) ersetzen das Mesh je Typ; proto_mass misst dann die Prefab-AABB statt dieser Boxen.

const IMPORT_PFAD := "res://world/data/proto/import_faktoren.json"   # Kopie von phase2/10_import_faktoren.json
const PREFABS := "res://world/proto_prefabs.gd"     # TA (Welle 2): ProtoPrefabs.vorhanden(typ) / mesh_fuer(typ)

## Zusatzmaße [b, h, t] in m mit Quelle. Nur, was in regelwerk und Import-Faktoren fehlt.
const ZUSATZ := {
	"steg": {"m": [2.0, 0.8, 25.0], "kat": "holz", "quelle": "16_prototyp_plan §5 M14 (25 × 2 m)"},
	"fischerhuette": {"m": [8.0, 5.5, 6.0], "kat": "wohnhaus", "quelle": "16_prototyp_plan §5 M14 (8 × 6 m), H Annahme wie Kate"},
	"netzgestell": {"m": [4.0, 2.2, 0.6], "kat": "holz", "quelle": "Annahme Felix"},
}

const FARBE := {
	"wohnhaus": [Color(0.80, 0.76, 0.68), Color(0.50, 0.33, 0.27)],
	"sonder": [Color(0.86, 0.84, 0.79), Color(0.40, 0.40, 0.43)],
	"industrie": [Color(0.64, 0.57, 0.49), Color(0.42, 0.33, 0.28)],
	"landwirtschaft": [Color(0.62, 0.52, 0.40), Color(0.45, 0.36, 0.28)],
	"fahrzeug": [Color(0.36, 0.43, 0.56), Color(0.30, 0.30, 0.32)],
	"natur": [Color(0.32, 0.46, 0.27), Color(0.40, 0.30, 0.22)],
	"holz": [Color(0.56, 0.43, 0.29), Color(0.45, 0.34, 0.22)],
	"objekt": [Color(0.66, 0.64, 0.60), Color(0.50, 0.48, 0.45)],
	"unbekannt": [Color(0.9, 0.1, 0.8), Color(0.9, 0.1, 0.8)],
}

const FLAECHE_FARBE := {
	"flaeche_garten": Color(0.40, 0.38, 0.22), "flaeche_hof": Color(0.56, 0.51, 0.42),
	"flaeche_kirchhof": Color(0.34, 0.44, 0.27), "flaeche_marktplatz": Color(0.60, 0.58, 0.54),
	"flaeche_obstwiese": Color(0.44, 0.54, 0.29), "flaeche_schlag": Color(0.64, 0.57, 0.33),
}
const FLAECHE_RASTER_M := 2.5
const FLAECHE_Y_M := 0.08
const SICHT_KLEIN := ["zaun_latte", "zaun_feld", "fass", "heuhaufen", "holzstapel", "passant", "amboss", "netzgestell", "brunnen"]
const SICHT_KLEIN_M := 700.0
const SICHT_BAUM := ["obstbaum", "laubbaum", "eiche", "nadelbaum", "nadelbaum_schlank", "busch"]
const SICHT_BAUM_M := 1800.0
const SICHT_FLAECHE_M := 2500.0

var regelwerk: Dictionary = {}
var flaechen: Dictionary = {}        # typ -> MeshInstance3D (Bodenflächen)
var import_faktoren: Dictionary = {}
var unbekannt: Dictionary = {}       # typ -> Anzahl
var mmis: Dictionary = {}            # typ -> MultiMeshInstance3D
var anzahl: Dictionary = {}          # typ -> Instanzen
var _mesh_cache: Dictionary = {}
var _mat: StandardMaterial3D
var prefab_typen: Dictionary = {}    # typ -> true, wenn das Mesh von ProtoPrefabs kommt
var _prefab_scr: Script = null
var _prefab_geprueft := false


## Hook Welle 2: ProtoPrefabs (TA) per Pfad laden, damit Szene und Tests ohne die Datei kompilieren.
func prefab_script() -> Script:
	if not _prefab_geprueft:
		_prefab_geprueft = true
		if ResourceLoader.exists(PREFABS):
			var scr: Script = load(PREFABS)
			if scr != null and scr.can_instantiate():
				_prefab_scr = scr
	return _prefab_scr


## Echtes Prefab-Mesh für typ oder null (Ursprung am Boden, Front +z, Maße laut Import-Faktoren – Vertrag TA).
func prefab_mesh(typ: String) -> Mesh:
	var scr := prefab_script()
	if scr == null:
		return null
	if not bool(scr.call("vorhanden", typ)):
		return null
	var m = scr.call("mesh_fuer", typ)
	return m if m is Mesh else null


func _init(p_regelwerk: Dictionary = {}) -> void:
	regelwerk = p_regelwerk
	if FileAccess.file_exists(IMPORT_PFAD):
		var d = JSON.parse_string(FileAccess.get_file_as_string(IMPORT_PFAD))
		if d is Dictionary:
			import_faktoren = d


## Maße eines Typs: {groesse: Vector3(b, h, t), kat, quelle, teile: [[mitte: Vector3, groesse: Vector3, dach: bool, farbe_idx]]}
func masse(typ: String) -> Dictionary:
	if typ.begins_with("flaeche_"):
		return {"groesse": Vector3(10, 0.05, 10), "kat": "flaeche", "teile": [],
			"quelle": "Stadt-Erweiterung (Bodenfläche, b × t je Instanz, stadt_welle1 §7)"}
	var ht: Dictionary = regelwerk.get("haustypen", {})
	var sk: Dictionary = regelwerk.get("skalen", {})
	if ht.has(typ):
		return _haustyp(typ, ht[typ])
	if sk.get("gebaeude_m", {}).has(typ):
		var g: Dictionary = sk["gebaeude_m"][typ]
		if g.has("b") and g.has("t"):
			var h := _mittel(g.get("h", g.get("turm", 8.0)))
			return _haus(float(g["b"]), float(g["t"]), h * 0.6, h, "landwirtschaft" if typ == "scheune" else "wohnhaus",
				"regelwerk.skalen.gebaeude_m.%s" % typ)
	if sk.get("industrie_m", {}).has(typ):
		var g: Dictionary = sk["industrie_m"][typ]
		var hp: Array = g.get("haupt", [g.get("haupt_d", 10.0), g.get("haupt_d", 10.0)]) if g.get("haupt") is Array else [float(g.get("haupt_d", 10)), float(g.get("haupt_d", 10))]
		var h := _mittel(g.get("landmarke_h", 9.0))
		return _haus(float(hp[0]), float(hp[1]), h * 0.65, h, "industrie", "regelwerk.skalen.industrie_m.%s" % typ)
	if sk.get("fahrzeuge_dm", {}).has(typ):
		var g: Dictionary = sk["fahrzeuge_dm"][typ]
		var l := float(g.get("l", 50)) / 10.0
		var b := float(g.get("b", 22)) / 10.0
		var h := float(g.get("h", 25)) / 10.0
		return {"groesse": Vector3(b, h, l), "kat": "fahrzeug", "quelle": "regelwerk.skalen.fahrzeuge_dm.%s" % typ,
			"teile": [[Vector3(0, h * 0.5, 0), Vector3(b, h, l), false, 0]]}
	var ro: Dictionary = import_faktoren.get("rollen", {})
	if ro.has(typ) and ro[typ].has("masse_m"):
		var m: Array = ro[typ]["masse_m"]
		var sz := Vector3(float(m[0]), float(m[1]), float(m[2]))
		var kat := _kat_rolle(typ)
		var teile: Array
		if kat == "natur" and sz.y > 3.0:     # Baum: Stamm + Krone
			teile = [[Vector3(0, sz.y * 0.2, 0), Vector3(sz.x * 0.1, sz.y * 0.4, sz.z * 0.1), false, 1],
				[Vector3(0, sz.y * 0.65, 0), Vector3(sz.x, sz.y * 0.7, sz.z), false, 0]]
		else:
			teile = [[Vector3(0, sz.y * 0.5, 0), sz, false, 0]]
		return {"groesse": sz, "kat": kat, "quelle": "import_faktoren.rollen.%s.masse_m" % typ, "teile": teile}
	if ZUSATZ.has(typ):
		var z: Dictionary = ZUSATZ[typ]
		var sz := Vector3(z["m"][0], z["m"][1], z["m"][2])
		if z["kat"] == "wohnhaus":
			return _haus(sz.x, sz.z, sz.y * 0.55, sz.y, "wohnhaus", z["quelle"])
		return {"groesse": sz, "kat": z["kat"], "quelle": z["quelle"], "teile": [[Vector3(0, sz.y * 0.5, 0), sz, false, 0]]}
	return {"groesse": Vector3(5, 5, 5), "kat": "unbekannt", "quelle": "unbekannt", "teile": [[Vector3(0, 2.5, 0), Vector3(5, 5, 5), false, 0]]}


func aabb(typ: String) -> AABB:
	var s: Vector3 = masse(typ)["groesse"]
	return AABB(Vector3(-s.x * 0.5, 0, -s.z * 0.5), s)


func _haustyp(typ: String, h: Dictionary) -> Dictionary:
	var g: Array = h.get("grundriss_m", [10, 8])
	if not h.has("grundriss_m") and h.get("varianten_m") is Array and not h["varianten_m"].is_empty():
		var vs: Array = h["varianten_m"]
		g = vs[vs.size() / 2]                    # mittlere Variante, Instanzen skalieren auf b × t
	var b := float(g[0])
	var t := float(g[1])
	var stufe: String = h.get("stufe", "")
	var kat := "sonder" if stufe == "sonder" else "wohnhaus"
	var quelle := "regelwerk.haustypen.%s" % typ
	if h.has("turm_m"):
		var turm := _mittel(h["turm_m"])
		if typ == "stadttor":
			return {"groesse": Vector3(b, turm, t), "kat": kat, "quelle": quelle,
				"teile": [[Vector3(0, turm * 0.5, 0), Vector3(b, turm, t), false, 0]]}
		# Kirche/Kapelle: Schiff (Traufe ≈ 1/3 Turm, First +40 % Breite) + Turm am Westende (Annahme Felix)
		var lang := maxf(b, t)
		var quer := minf(b, t)
		var traufe := maxf(4.0, turm * 0.3)
		var first := traufe + quer * 0.45
		var tb := maxf(3.0, quer * 0.45)
		var teile := _haus_teile(b, t, traufe, first)
		var achse := Vector3(1, 0, 0) if b >= t else Vector3(0, 0, 1)
		var tpos := -achse * (lang * 0.5 - tb * 0.5)
		teile.append([tpos + Vector3(0, turm * 0.5, 0), Vector3(tb, turm, tb), false, 0])
		return {"groesse": Vector3(b, turm, t), "kat": kat, "quelle": quelle, "teile": teile}
	var first := _mittel(h.get("first_m", 9.0))
	var traufe: float
	if h.has("traufe_m"):
		traufe = _mittel(h["traufe_m"])
	else:
		var gs := float(h.get("geschosse", float(h.get("geschosse_promille", 1000)) / 1000.0))
		traufe = minf(gs * 3.0 + 0.5, first - 2.0)
	return _haus(b, t, traufe, first, kat, quelle)


func _haus(b: float, t: float, traufe: float, first: float, kat: String, quelle: String) -> Dictionary:
	return {"groesse": Vector3(b, first, t), "kat": kat, "quelle": quelle, "teile": _haus_teile(b, t, traufe, first)}


func _haus_teile(b: float, t: float, traufe: float, first: float) -> Array:
	var teile := [[Vector3(0, traufe * 0.5, 0), Vector3(b, traufe, t), false, 0]]
	if first > traufe + 0.2:
		teile.append([Vector3(0, traufe, 0), Vector3(b, first - traufe, t), true, 1])
	return teile


func _kat_rolle(typ: String) -> String:
	if typ in ["laubbaum", "eiche", "nadelbaum", "nadelbaum_schlank", "obstbaum", "busch", "getreide"]:
		return "natur"
	if typ in ["dampflok", "tender", "gueterwagen", "personenwagen", "fuhrwerk_wagen", "kutsche_wagen", "pferd", "ruderboot"]:
		return "fahrzeug"
	if typ in ["zaun_latte", "zaun_feld", "holzstapel", "heuhaufen", "fass"]:
		return "holz"
	return "objekt"


static func _mittel(v: Variant) -> float:
	if v is Array:
		var s := 0.0
		for x in v:
			s += float(x)
		return s / maxf(1.0, v.size())
	return float(v)


## Mesh je Typ (Einheit Meter, Fußpunkt y = 0, Mitte des Grundrisses im Ursprung), Vertexfarben nach Kategorie.
func mesh_fuer(typ: String) -> Mesh:
	if _mesh_cache.has(typ):
		return _mesh_cache[typ]
	var pm := prefab_mesh(typ) if not typ.begins_with("flaeche_") else null
	if pm != null:
		prefab_typen[typ] = true
		_mesh_cache[typ] = pm
		return pm
	var m := masse(typ)
	var farben: Array = FARBE.get(m["kat"], FARBE["objekt"])
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for tl in m["teile"]:
		var mitte: Vector3 = tl[0]
		var g: Vector3 = tl[1]
		st.set_color(farben[tl[3]])
		if tl[2]:
			_prisma(st, mitte, g)
		else:
			_box(st, mitte, g)
	st.generate_normals()
	var am := st.commit()
	_mesh_cache[typ] = am
	return am


## Quader mit flachen Normalen (je Fläche eigene Ecken).
func _box(st: SurfaceTool, c: Vector3, g: Vector3) -> void:
	var h := g * 0.5
	var p := [Vector3(-h.x, -h.y, -h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(-h.x, h.y, -h.z),
		Vector3(-h.x, -h.y, h.z), Vector3(h.x, -h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(-h.x, h.y, h.z)]
	# Flächen von außen gesehen gegen den Uhrzeigersinn (_tri dreht für Godot um)
	for f in [[0, 3, 2, 1], [4, 5, 6, 7], [0, 4, 7, 3], [1, 2, 6, 5], [3, 7, 6, 2], [0, 1, 5, 4]]:
		_quad(st, c + p[f[0]], c + p[f[1]], c + p[f[2]], c + p[f[3]])


## Satteldach: Basis-Rechteck bei y = c.y (Traufe), First entlang der längeren Seite, Höhe g.y.
func _prisma(st: SurfaceTool, c: Vector3, g: Vector3) -> void:
	var hx := g.x * 0.5
	var hz := g.z * 0.5
	var y0 := c.y
	var y1 := c.y + g.y
	var ue := 0.4   # Dachüberstand
	if g.x >= g.z:
		var a := Vector3(-hx - ue, y0, -hz - ue); var b := Vector3(hx + ue, y0, -hz - ue)
		var cc := Vector3(hx + ue, y0, hz + ue); var d := Vector3(-hx - ue, y0, hz + ue)
		var r0 := Vector3(-hx - ue, y1, 0); var r1 := Vector3(hx + ue, y1, 0)
		_quad(st, c * Vector3(1, 0, 1) + a, c * Vector3(1, 0, 1) + r0, c * Vector3(1, 0, 1) + r1, c * Vector3(1, 0, 1) + b)
		_quad(st, c * Vector3(1, 0, 1) + cc, c * Vector3(1, 0, 1) + r1, c * Vector3(1, 0, 1) + r0, c * Vector3(1, 0, 1) + d)
		_tri(st, c * Vector3(1, 0, 1) + d, c * Vector3(1, 0, 1) + r0, c * Vector3(1, 0, 1) + a)
		_tri(st, c * Vector3(1, 0, 1) + b, c * Vector3(1, 0, 1) + r1, c * Vector3(1, 0, 1) + cc)
	else:
		var a := Vector3(-hx - ue, y0, -hz - ue); var b := Vector3(hx + ue, y0, -hz - ue)
		var cc := Vector3(hx + ue, y0, hz + ue); var d := Vector3(-hx - ue, y0, hz + ue)
		var r0 := Vector3(0, y1, -hz - ue); var r1 := Vector3(0, y1, hz + ue)
		var o := c * Vector3(1, 0, 1)
		_quad(st, o + d, o + r1, o + r0, o + a)
		_quad(st, o + b, o + r0, o + r1, o + cc)
		_tri(st, o + a, o + r0, o + b)
		_tri(st, o + cc, o + r1, o + d)


func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_tri(st, a, b, c)
	_tri(st, a, c, d)


## Eckpunkte werden außen gegen den Uhrzeigersinn übergeben; Godot erwartet Vorderseiten im Uhrzeigersinn -> a, c, b.
func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(c)
	st.add_vertex(b)


## Instanzen bauen: MultiMesh je Typ unter parent.
func bauen(parent: Node3D, instanzen: Array, hoehe_fn: Callable) -> void:
	_mat = StandardMaterial3D.new()
	_mat.vertex_color_use_as_albedo = true
	_mat.roughness = 1.0
	var je_typ := {}
	for it in instanzen:
		# TA-W2-Testhook (Felix ersetzt durch seinen Hook): Schluessel inkl. Variante, Wasser-Kulissen baut ProtoKulissen
		var typ := ProtoPrefabs.schluessel(it)
		if typ in ProtoKulissen.TYPEN_SELBST:
			continue
		if not je_typ.has(typ):
			je_typ[typ] = []
		je_typ[typ].append(it)
	var typen := je_typ.keys()
	typen.sort()
	for typ in typen:
		var m := masse(typ)
		if m["kat"] == "flaeche":
			_flaeche_bauen(parent, typ, je_typ[typ], hoehe_fn)
			continue
		var var_skal: bool = regelwerk.get("haustypen", {}).get(typ, {}).has("varianten_m") \
			and not regelwerk.get("haustypen", {}).get(typ, {}).has("grundriss_m")
		if m["kat"] == "unbekannt":
			unbekannt[typ] = je_typ[typ].size()
		var liste: Array = je_typ[typ]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		var g: Vector3 = m["groesse"]
		var flaeche := typ.begins_with("flaeche_")
		if prefab:
			mm.use_colors = true
			mm.use_custom_data = true
			mm.mesh = ProtoPrefabs.mesh_fuer(typ)
			g = mm.mesh.get_aabb().size
		else:
			mm.mesh = mesh_fuer(typ)
		mm.instance_count = liste.size()
		for k in liste.size():
			var it: Dictionary = liste[k]
			var x := float(it.get("x", 0.0))
			var z := float(it.get("z", 0.0))
			var rot := deg_to_rad(float(it.get("rot_deg", 0.0)))
			var bas := Basis(Vector3.UP, rot)
			if var_skal and it.has("b") and it.has("t"):
				var mb := float(m["groesse"].x)
				var mt := float(m["groesse"].z)
				bas = bas * Basis.from_scale(Vector3(float(it["b"]) / mb, 1.0, float(it["t"]) / mt))
			var y := INF
			for e in [Vector3(-gi.x, 0, -gi.z), Vector3(gi.x, 0, -gi.z), Vector3(gi.x, 0, gi.z), Vector3(-gi.x, 0, gi.z)]:
				var w: Vector3 = Basis(Vector3.UP, rot) * (e * 0.5)
				y = minf(y, float(hoehe_fn.call(x + w.x, z + w.z)))
			mm.set_instance_transform(k, Transform3D(bas, Vector3(x, y, z)))
			if prefab:
				mm.set_instance_color(k, Color.WHITE)
				mm.set_instance_custom_data(k, ProtoPrefabs.custom_fuer(it))
		var mmi := MultiMeshInstance3D.new()
		mmi.name = ("PF_" if prefab_typen.has(typ) else "PH_") + typ
		mmi.multimesh = mm
		if not prefab_typen.has(typ):
			mmi.material_override = _mat         # Prefabs bringen ihre Materialien mit
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if m["kat"] != "natur" or g.y > 3.0 else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if typ in SICHT_KLEIN:
			mmi.visibility_range_end = SICHT_KLEIN_M
			mmi.visibility_range_end_margin = 50.0
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		elif typ in SICHT_BAUM:
			mmi.visibility_range_end = SICHT_BAUM_M
			mmi.visibility_range_end_margin = 50.0
		parent.add_child(mmi)
		mmis[typ] = mmi
		anzahl[typ] = liste.size()
		# TA-W2: Fern-LOD fuer Gebaeude (gleiche Transformationen/Varianten, ab 650 m)
		if prefab and typ in ProtoPrefabs.FERN_TYPEN:
			mmi.visibility_range_end = 650.0
			mmi.visibility_range_end_margin = 30.0
			var mf := MultiMesh.new()
			mf.transform_format = MultiMesh.TRANSFORM_3D
			mf.use_colors = true
			mf.use_custom_data = true
			mf.mesh = ProtoPrefabs.mesh_fern(typ)
			mf.instance_count = mm.instance_count
			for k in mm.instance_count:
				mf.set_instance_transform(k, mm.get_instance_transform(k))
				mf.set_instance_color(k, Color.WHITE)
				mf.set_instance_custom_data(k, mm.get_instance_custom_data(k))
			var mfi := MultiMeshInstance3D.new()
			mfi.name = "PHF_" + typ.replace("/", "_")
			mfi.multimesh = mf
			mfi.visibility_range_begin = 650.0
			mfi.visibility_range_begin_margin = 30.0
			mfi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			parent.add_child(mfi)


func dreiecke() -> int:
	var t := 0
	for typ in mmis:
		var mm: MultiMesh = mmis[typ].multimesh
		t += mm.mesh.get_faces().size() / 3 * mm.instance_count
	for typ in flaechen:
		t += (flaechen[typ] as MeshInstance3D).mesh.get_faces().size() / 3
	return t


## Bodenflächen eines Typs als ein Mesh: je Instanz ein Raster (≤ 2,5 m) über b × t, gedreht um rot_deg, Höhe aus
## dem Gelände (+0,08 m). Leichte Tönung je Instanz, damit Nachbarparzellen unterscheidbar bleiben.
func _flaeche_bauen(parent: Node3D, typ: String, liste: Array, hoehe_fn: Callable) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var basis_farbe: Color = FLAECHE_FARBE.get(typ, Color(0.5, 0.52, 0.4))
	var n_v := 0
	for k in liste.size():
		var it: Dictionary = liste[k]
		var b := maxf(float(it.get("b", 10.0)), 0.5)
		var t := maxf(float(it.get("t", 10.0)), 0.5)
		var x0 := float(it.get("x", 0.0))
		var z0 := float(it.get("z", 0.0))
		var bas := Basis(Vector3.UP, deg_to_rad(float(it.get("rot_deg", 0.0))))
		var nx := maxi(1, ceili(b / FLAECHE_RASTER_M))
		var nz := maxi(1, ceili(t / FLAECHE_RASTER_M))
		var ton := 0.92 + 0.16 * fposmod(sin(x0 * 12.9898 + z0 * 78.233) * 43758.5453, 1.0)
		var col := Color(basis_farbe.r * ton, basis_farbe.g * ton, basis_farbe.b * ton)
		for j in nz + 1:
			for i in nx + 1:
				var lp := bas * Vector3((float(i) / nx - 0.5) * b, 0.0, (float(j) / nz - 0.5) * t)
				var wx := x0 + lp.x
				var wz := z0 + lp.z
				st.set_color(col)
				st.set_normal(Vector3.UP)
				st.add_vertex(Vector3(wx, float(hoehe_fn.call(wx, wz)) + FLAECHE_Y_M, wz))
		for j in nz:
			for i in nx:
				var a := n_v + j * (nx + 1) + i
				var c := a + nx + 1
				st.add_index(a); st.add_index(a + 1); st.add_index(c)
				st.add_index(a + 1); st.add_index(c + 1); st.add_index(c)
		n_v += (nx + 1) * (nz + 1)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.name = "FL_" + typ
	mi.mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_end = SICHT_FLAECHE_M
	mi.visibility_range_end_margin = 100.0
	parent.add_child(mi)
	flaechen[typ] = mi
	anzahl[typ] = liste.size()
