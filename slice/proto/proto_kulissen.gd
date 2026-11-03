extends Node3D
## Phase 4 W2 (TA): Kulissen-Animationen am Wasser (keine Sim). Plan 16 §2 See-Nutzung + Basti-Wunsch E15 (Floss).
##   var k := ProtoKulissen.bauen(parent, terrain)       # terrain: ProtoTerrain (hoehe_at, fluss_pegel_at, fluss_mitte_z, see)
##   k.zeit_setzen(t_s)                                  # alles ist eine reine Funktion der Zeit (Bilder, Tests)
## Inhalt: Steg 25 x 2 m + Ruderboot am Steg (duempelt), zweites Ruderboot faehrt eine langsame Kreisschleife,
## Holzfloss (8 x 3 m, Stammladung) treibt flussabwaerts (Fluss fliesst nach Westen), legt an der Holzlaende am Suedufer an,
## liegt, wird zurueckgesetzt (taucht ab, erscheint oberhalb wieder). Lage aus proto_orte.json _meta.see_nutzung (Stadt),
## sonst TA-Vorschlag Suedufer (1212 / 1262). Typen, die hier gebaut werden, NICHT zusaetzlich aus den Instanzen bauen.
## Fix-Pass W2 (TA): Muehlrad am Muehlgraben (Rad dreht sich, Graben vom Muehlteich am Rad vorbei in den Bach, M5) und
## Marktstaende auf dem Marktplatz (Kenney-Tisch + Plane, M7).
class_name ProtoKulissen

const Wasser := preload("res://world/proto_wasser.gd")
const TYPEN_SELBST := ["steg", "ruderboot", "wassermuehle_rad"]
const RAD_D_M := 5.0                # Muehlrad-Durchmesser (Prefab wassermuehle_rad)
const RAD_DICKE_M := 2.36
const GRABEN_B_M := 3.0             # Muehlgraben: Wand der Muehle bis Aussenplanke, Rad in der Mitte
const GRABEN_FLUSS_MS := 1.0
const GRABEN_DY_M := 0.14           # Wasserflaeche ueber dem Gelaende
const RAD_TAUCH_M := 0.4            # Rad taucht so tief ins Wasser (unterschlaechtig)
const FLOSS_X0 := 2450.0           # Start oberhalb (Ost, Randlandschaft)
const FLOSS_XL := 1600.0           # Holzlaende (Suedufer, unterhalb Erlenbach-Muendung)
const FLOSS_MS := 1.5              # Treibgeschwindigkeit
const T_ANLEGEN := 25.0
const T_LIEGEN := 40.0
const T_TAUCHEN := 5.0

var terrain = null
var pegel_see := 44.8
var steg_mi: MeshInstance3D
var boot_steg: MeshInstance3D
var boot_kreis: MeshInstance3D
var floss: MeshInstance3D
var laende: MeshInstance3D
var muehlrad: MeshInstance3D
var muehlgraben: MeshInstance3D
var markt_mmi: MultiMeshInstance3D
var zeit := 0.0
var lage := {}                      # Kennwerte fuer Tests (M14/M15)
var _steg_mitte := Vector3.ZERO
var _steg_gier := 0.0
var _boot_ruhe := Vector3.ZERO
var _kreis_mitte := Vector2(1182.5, 1032.5)
var _kreis_r := 110.0
var _kreis_umlauf := 300.0
var _laende_punkt := Vector3.ZERO
var _laende_gier := 0.0
var _t_treiben := 0.0
var _periode := 0.0
var _rad_lage := {}
var _markt_n := 0


static func bauen(parent: Node3D, p_terrain, daten_dir := "res://world/data/proto/") -> ProtoKulissen:
	var k := ProtoKulissen.new()
	k.name = "Kulissen"
	k.terrain = p_terrain
	parent.add_child(k)
	k._aufbauen(daten_dir)
	return k


func _mi(typ: String, n: String) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.name = n
	m.mesh = ProtoPrefabs.mesh_fuer(typ)
	add_child(m)
	return m


func _json(p: String) -> Variant:
	if not FileAccess.file_exists(p):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(p))


func _aufbauen(dir: String) -> void:
	var see = _json(dir.path_join("proto_see.json"))
	var see_mitte := Vector2(1212.5, 1012.5)
	if see is Dictionary and see.has("see"):
		pegel_see = float(see["see"]["pegel_m"])
		see_mitte = Vector2(see["see"]["mitte_m"][0], see["see"]["mitte_m"][1])
	var wurzel := Vector2(1212.0, 1262.0)
	var ende := Vector2(1212.0, 1237.0)
	var boot := Vector2(1214.5, 1240.0)
	var orte = _json(dir.path_join("proto_orte.json"))
	var quelle := "TA-Vorschlag Suedufer"
	if orte is Dictionary and orte.get("_meta", {}).has("see_nutzung"):
		var sn: Dictionary = orte["_meta"]["see_nutzung"]
		wurzel = Vector2(sn["steg_wurzel"][0], sn["steg_wurzel"][1])
		ende = Vector2(sn["steg_ende"][0], sn["steg_ende"][1])
		boot = Vector2(sn["boot_am_steg"][0], sn["boot_am_steg"][1])
		if sn.has("boot_schleife"):
			_kreis_mitte = Vector2(sn["boot_schleife"]["mitte"][0], sn["boot_schleife"]["mitte"][1])
			_kreis_r = float(sn["boot_schleife"]["radius_m"])
			_kreis_umlauf = float(sn["boot_schleife"].get("umlauf_s", 300.0))
		quelle = "proto_orte.json _meta.see_nutzung"
	# Steg: lokales +z zeigt zum Land (Wurzel)
	var achse := (wurzel - ende).normalized()
	_steg_gier = atan2(achse.x, achse.y)
	var mitte := (wurzel + ende) * 0.5
	steg_mi = _mi("steg", "Steg")
	_steg_mitte = Vector3(mitte.x, pegel_see + ProtoPrefabs.info("steg")["y_versatz"], mitte.y)
	steg_mi.transform = Transform3D(Basis(Vector3.UP, _steg_gier), _steg_mitte)
	# Boot am Steg: 2,2 m seitlich neben dem Stegende, parallel zum Steg
	var quer := Vector2(achse.y, -achse.x)
	var bp := ende + achse * 4.0 + quer * 2.3
	if boot.distance_to(ende) < 8.0:
		bp = bp
	boot_steg = _mi("ruderboot", "BootSteg")
	_boot_ruhe = Vector3(bp.x, pegel_see - 0.18, bp.y)
	boot_kreis = _mi("ruderboot", "BootSchleife")
	floss = _mi("floss", "Floss")
	laende = _mi("anlegestelle", "Holzlaende")
	_laende_einrichten()
	_muehlrad_einrichten(dir)
	_markt_einrichten(dir)
	lage = {"quelle": quelle, "steg_wurzel": wurzel, "steg_ende": ende, "steg_laenge_m": wurzel.distance_to(ende),
		"see_mitte": see_mitte, "pegel_see": pegel_see, "boot_schleife": [_kreis_mitte, _kreis_r, _kreis_umlauf],
		"laende": _laende_punkt, "floss_periode_s": _periode, "muehlrad": _rad_lage, "markt_staende": _markt_n}
	zeit_setzen(0.0)


## Holzlaende: am Suedufer bei FLOSS_XL, Steg 10 m quer zum Ufer ins Wasser
func _laende_einrichten() -> void:
	var zm: float = terrain.fluss_mitte_z(FLOSS_XL)
	var z := zm
	var pg: float = terrain.fluss_pegel_at(FLOSS_XL)
	while z < zm + 250.0 and float(terrain.hoehe_at(FLOSS_XL, z)) < pg - 0.1:
		z += 1.0
	var ufer := Vector2(FLOSS_XL, z)
	# Steg ragt 8 m ins Wasser (nach Norden, -z); lokales +z = Land (Sueden)
	_laende_gier = 0.0
	var mitte := ufer + Vector2(0, -3.0)
	laende.transform = Transform3D(Basis(Vector3.UP, _laende_gier), Vector3(mitte.x, pg + ProtoPrefabs.info("steg")["y_versatz"], mitte.y))
	_laende_punkt = Vector3(FLOSS_XL - 0.5, pg, ufer.y - 9.5)
	_t_treiben = (FLOSS_X0 - FLOSS_XL) / FLOSS_MS
	_periode = _t_treiben + T_ANLEGEN + T_LIEGEN + T_TAUCHEN * 2.0



func _boden(x: float, z: float) -> float:
	return float(terrain.hoehe_at(x, z))


func _holz_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.43, 0.33, 0.24)
	m.roughness = 1.0
	return m


func _box_mi(n: String, mitte: Vector3, groesse: Vector3, gier: float, mat: Material) -> MeshInstance3D:
	var bm := BoxMesh.new()
	bm.size = groesse
	var mi := MeshInstance3D.new()
	mi.name = n
	mi.mesh = bm
	mi.material_override = mat
	mi.transform = Transform3D(Basis(Vector3.UP, gier), mitte)
	add_child(mi)
	return mi


## Abstand eines Punkts zur Bach-Mittellinie (Punkte aus proto_bach.json, ohne Muehlteich-Abschnitt)
func _bach_abstand(p: Vector2, bach: Array) -> float:
	var best := INF
	for b in bach:
		if int(b[3]) == 1:
			continue
		best = minf(best, p.distance_to(Vector2(b[0], b[1])))
	return best


## Muehlrad (Fix-Pass W2, M5): das Prefab wassermuehle_rad steht parallel zur Wand der Muehle, die dem Muehlteich zugewandt
## ist (vorher quer zur Giebelwand an der Hauswand, 10 m vom Wasser). Ein Muehlgraben (Wasserband, 3 m) kommt vom Teichufer,
## laeuft am Rad vorbei (unterschlaechtig, Rad taucht 0,4 m) und muendet in den Bach. Das Rad dreht der Prefab-Shader (TIME);
## die Drehrichtung folgt dem Fliessen (Radunterseite bewegt sich mit dem Wasser).
func _muehlrad_einrichten(dir: String) -> void:
	var inst = _json(dir.path_join("proto_instanzen.json"))
	var orte = _json(dir.path_join("proto_orte.json"))
	var bach_d = _json(dir.path_join("proto_bach.json"))
	var see_d = _json(dir.path_join("proto_see.json"))
	if not (inst is Array) or not (orte is Dictionary) or not (bach_d is Dictionary):
		return
	var muehle := {}
	for it in inst:
		if String(it.get("typ", "")) == "wassermuehle":
			muehle = it
			break
	if muehle.is_empty():
		return
	var m := Vector2(float(muehle["x"]), float(muehle["z"]))
	var rot := deg_to_rad(float(muehle.get("rot_deg", 0.0)))
	var halb_t := float(muehle.get("t", 12.0)) * 0.5
	var teich := m + Vector2(0.0, 60.0)
	var teich_pegel := pegel_see
	for ind in orte.get("industrie", []):
		if String(ind.get("typ", "")) == "wassermuehle" and ind.has("muehlteich"):
			teich = Vector2(float(ind["muehlteich"]["x"]), float(ind["muehlteich"]["z"]))
	if see_d is Dictionary and see_d.has("muehlteich"):
		teich_pegel = float(see_d["muehlteich"]["pegel_m"])
	var f := Vector2(sin(rot), cos(rot))
	var n := f if f.dot(teich - m) > 0.0 else -f                     # Aussennormale der Wand zum Teich
	var tv := Vector2(-n.y, n.x)                                     # Richtung entlang der Wand
	var wc := m + n * (halb_t + 0.05 + RAD_DICKE_M * 0.5 + 0.32)    # Radmitte (Boden), 0,32 m Luft zur Wand
	var bach: Array = bach_d["punkte"]
	# Stromab: die Seite, auf der der Bach liegt
	var s_best := 1.0
	var d_best := INF
	for s in [1.0, -1.0]:
		var d := 0.0
		while d <= 40.0:
			if _bach_abstand(wc + tv * s * d, bach) < 2.0:
				break
			d += 0.5
		if d < d_best:
			d_best = d
			s_best = s
	var d_ab := minf(d_best + 1.0, 40.0) if d_best <= 40.0 else 14.0
	var ab := tv * s_best                                            # Fliessrichtung am Rad
	var ecke := wc - ab * (RAD_D_M * 0.5 + 2.5)                      # Knick Zulauf → Graben (stromauf vom Rad)
	var ufer := ecke
	var steps := 0
	while steps < 40 and _boden(ufer.x, ufer.y) >= teich_pegel - 0.02:
		ufer += n * 0.5
		steps += 1
	ufer += n * 1.5                                                  # ein Stück ins Teichwasser hinein (verdeckt vom Teich)
	# Rad
	var base_y := _boden(wc.x, wc.y) + GRABEN_DY_M - RAD_TAUCH_M
	muehlrad = _mi("wassermuehle_rad", "Muehlrad")
	var zr := -ab                                                    # lokales +z des Rads: Oberkante dreht nach +z, Unterkante nach −z = mit dem Wasser
	var gier := atan2(zr.x, zr.y)
	muehlrad.transform = Transform3D(Basis(Vector3.UP, gier), Vector3(wc.x, base_y, wc.y))
	muehlrad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	# Welle (vom Mauerwerk durch das Rad) und Aussenplanke
	var holz := _holz_material()
	var wand := m + n * (halb_t + 0.05)
	var achs_y := base_y + RAD_D_M * 0.5
	var achs_l := RAD_DICKE_M + 0.32 + 0.35
	var achs_m := wand + n * (achs_l * 0.5)
	_box_mi("Muehlwelle", Vector3(achs_m.x, achs_y, achs_m.y), Vector3(0.28, 0.28, achs_l), atan2(n.x, n.y), holz)
	var pm := m + n * (halb_t + 0.05 + GRABEN_B_M)                  # Aussenplanke des Radgrabens
	var planke_l := RAD_D_M + 1.2
	var gy := _boden(pm.x, pm.y) + 0.3 + GRABEN_DY_M * 0.5
	_box_mi("Radgraben_Planke", Vector3(pm.x, gy, pm.y), Vector3(0.18, 0.7, planke_l), atan2(tv.x, tv.y), holz)
	# Muehlgraben: zwei Wasserstreifen (Zulauf vom Teichufer zur Ecke, Graben an der Wand entlang bis in den Bach)
	var v := PackedVector3Array()
	var col := PackedColorArray()
	var uv := PackedVector2Array()
	var idx := PackedInt32Array()
	_streifen(ufer, ecke + n * (GRABEN_B_M * 0.5), -n, v, col, uv, idx)       # Zulauf endet an der Kante des Grabens (keine Überlappung)
	_streifen(ecke - ab * (GRABEN_B_M * 0.5), wc + ab * d_ab, ab, v, col, uv, idx)
	muehlgraben = Wasser._instanz("Muehlgraben", v, col, uv, idx, Wasser._material(0.25))
	add_child(muehlgraben)
	_rad_lage = {"mitte": Vector3(wc.x, base_y + RAD_D_M * 0.5, wc.y), "wand_normale": n, "fliess": ab, "graben_ende": wc + ab * d_ab,
		"teichufer": ufer, "bach_abstand_m": _bach_abstand(wc + ab * d_ab, bach), "durchmesser_m": RAD_D_M}


## Wasserband von a nach b (Mitte), Breite GRABEN_B_M, 1-m-Raster am Gelaende (+GRABEN_DY_M), Fliessvektor fluss_r · 1 m/s.
## Tiefe quer 0 → 0,45 m → 0 (weiche Kanten wie der Bach).
func _streifen(a: Vector2, b: Vector2, fluss_r: Vector2, v: PackedVector3Array, col: PackedColorArray, uv: PackedVector2Array, idx: PackedInt32Array) -> void:
	var laenge := a.distance_to(b)
	var nseg := maxi(1, ceili(laenge))
	var dir := (b - a).normalized()
	var q := Vector2(-dir.y, dir.x)
	var base := v.size()
	for i in nseg + 1:
		var p := a.lerp(b, float(i) / nseg)
		for s in [-1.0, 0.0, 1.0]:
			var pp: Vector2 = p + q * (GRABEN_B_M * 0.5) * s
			v.append(Vector3(pp.x, _boden(pp.x, pp.y) + GRABEN_DY_M, pp.y))
			col.append(Color((0.45 if s == 0.0 else 0.0) / Wasser.TIEFE_SKALA_M, 0, 0, 1))
			uv.append(fluss_r * GRABEN_FLUSS_MS)
	for i in nseg:
		var r0 := base + i * 3
		var r1 := r0 + 3
		idx.append_array([r0, r1, r0 + 1, r1, r1 + 1, r0 + 1, r0 + 1, r1 + 1, r0 + 2, r1 + 1, r1 + 2, r0 + 2])


## Marktstaende (Fix-Pass W2, M7): zwei Reihen auf dem Marktplatz (Platz aus proto_instanzen.json, flaeche_marktplatz), Front
## zur Platzmitte, Brunnen und Platzmitte bleiben frei. Prefab "marktstand" (Kenney-Tisch, Plane, Kisten).
func _markt_einrichten(dir: String) -> void:
	var inst = _json(dir.path_join("proto_instanzen.json"))
	if not (inst is Array):
		return
	var platz := {}
	for it in inst:
		if String(it.get("typ", "")) == "flaeche_marktplatz":
			platz = it
			break
	if platz.is_empty():
		return
	var c := Vector2(float(platz["x"]), float(platz["z"]))
	var rot := deg_to_rad(float(platz.get("rot_deg", 0.0)))
	var b := float(platz.get("b", 80.0))
	var tt := float(platz.get("t", 60.0))
	var rechts := Vector2(cos(rot), -sin(rot))
	var vor := Vector2(sin(rot), cos(rot))
	var liste: Array = []                                           # [Position, Gier]
	for reihe in [-1.0, 1.0]:
		for xi in [-27.0, -17.0, 17.0, 27.0]:
			var lz: float = reihe * (tt * 0.5 - 9.0)
			var lx: float = float(xi) * (b / 80.0)
			var pos := c + rechts * lx + vor * lz
			liste.append([pos, rot + (0.0 if reihe < 0.0 else PI)])
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = ProtoPrefabs.mesh_fuer("marktstand")
	mm.instance_count = liste.size()
	for i in liste.size():
		var p: Vector2 = liste[i][0]
		var y := _boden(p.x, p.y)
		for e in [Vector2(-1.2, -0.7), Vector2(1.2, -0.7), Vector2(1.2, 0.7), Vector2(-1.2, 0.7)]:
			var w := Basis(Vector3.UP, float(liste[i][1])) * Vector3(e.x, 0, e.y)
			y = maxf(y, _boden(p.x + w.x, p.y + w.z))
		mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, float(liste[i][1])), Vector3(p.x, y + 0.08, p.y)))
		mm.set_instance_color(i, Color.WHITE)
		mm.set_instance_custom_data(i, ProtoPrefabs.custom_fuer({"x": p.x, "z": p.y, "typ": "marktstand"}))
	markt_mmi = MultiMeshInstance3D.new()
	markt_mmi.name = "Marktstaende"
	markt_mmi.multimesh = mm
	markt_mmi.visibility_range_end = 900.0
	markt_mmi.visibility_range_end_margin = 50.0
	add_child(markt_mmi)
	_markt_n = liste.size()


func _process(delta: float) -> void:
	zeit_setzen(zeit + delta)


func zeit_setzen(t: float) -> void:
	zeit = t
	# Boot am Steg: Duempeln (Hub, Rollen, Stampfen, leichtes Gieren)
	var bas := Basis(Vector3.UP, _steg_gier + 0.05 * sin(t * 0.21))
	bas = bas * Basis(Vector3.FORWARD, 0.035 * sin(t * 1.1)) * Basis(Vector3.RIGHT, 0.025 * sin(t * 0.83 + 1.0))
	boot_steg.transform = Transform3D(bas, _boot_ruhe + Vector3(0, 0.05 * sin(t * 1.3), 0))
	# Schleifenboot: Kreis im Uhrzeigersinn (Blick von oben, +x Ost, +z Sued)
	var w := -TAU * t / _kreis_umlauf
	var p := _kreis_mitte + Vector2(cos(w), sin(w)) * _kreis_r
	var tang := Vector2(sin(w), -cos(w))
	var b2 := Basis(Vector3.UP, atan2(tang.x, tang.y)) * Basis(Vector3.FORWARD, 0.03 * sin(t * 1.4))
	boot_kreis.transform = Transform3D(b2, Vector3(p.x, pegel_see - 0.18 + 0.04 * sin(t * 1.7), p.y))
	_floss_stellen(fposmod(t, _periode))


func _floss_stellen(t: float) -> void:
	var pos: Vector3
	var gier: float
	var tief := 0.0
	if t < T_TAUCHEN:
		# erscheint oberhalb (taucht auf)
		pos = _kurs(FLOSS_X0)
		gier = _kurs_gier(FLOSS_X0)
		tief = 2.0 * (1.0 - t / T_TAUCHEN)
	elif t < T_TAUCHEN + _t_treiben:
		var x := FLOSS_X0 - (t - T_TAUCHEN) * FLOSS_MS
		pos = _kurs(x)
		gier = _kurs_gier(x)
	elif t < T_TAUCHEN + _t_treiben + T_ANLEGEN:
		var u := smoothstep(0.0, 1.0, (t - T_TAUCHEN - _t_treiben) / T_ANLEGEN)
		var a := _kurs(FLOSS_XL)
		pos = a.lerp(_laende_punkt, u)
		gier = lerp_angle(_kurs_gier(FLOSS_XL), _laende_gier + PI * 0.5, u)      # drehen: laengsseits an die Laende
	elif t < T_TAUCHEN + _t_treiben + T_ANLEGEN + T_LIEGEN:
		pos = _laende_punkt
		gier = _laende_gier + PI * 0.5
	else:
		var u2 := (t - T_TAUCHEN - _t_treiben - T_ANLEGEN - T_LIEGEN) / T_TAUCHEN
		pos = _laende_punkt
		gier = _laende_gier + PI * 0.5
		tief = 2.0 * clampf(u2, 0.0, 1.0)
	var bob := 0.03 * sin(zeit * 0.9)
	floss.transform = Transform3D(Basis(Vector3.UP, gier) * Basis(Vector3.FORWARD, 0.012 * sin(zeit * 0.7)),
		Vector3(pos.x, pos.y - 0.18 + bob - tief, pos.z))
	floss.visible = tief < 1.9


func _kurs(x: float) -> Vector3:
	return Vector3(x, terrain.fluss_pegel_at(x), terrain.fluss_mitte_z(x) + 12.0)


func _kurs_gier(x: float) -> float:
	var a := _kurs(x + 10.0)
	var b := _kurs(x - 10.0)
	var d := b - a          # flussabwaerts = nach Westen
	return atan2(d.x, d.z)


## Kennwerte fuer M14/M15
func messwerte() -> Dictionary:
	var out := lage.duplicate()
	var fl := ProtoPrefabs.mesh_fuer("floss").get_aabb()
	out["floss_m"] = [fl.size.z, fl.size.x]
	var st := ProtoPrefabs.mesh_fuer("steg").get_aabb()
	out["steg_m"] = [st.size.z, st.size.x]
	var bo := ProtoPrefabs.mesh_fuer("ruderboot").get_aabb()
	out["boot_m"] = bo.size.z
	return out
