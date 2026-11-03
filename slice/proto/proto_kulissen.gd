extends Node3D
## Phase 4 W2 (TA): Kulissen-Animationen am Wasser (keine Sim). Plan 16 §2 See-Nutzung + Basti-Wunsch E15 (Floss).
##   var k := ProtoKulissen.bauen(parent, terrain)       # terrain: ProtoTerrain (hoehe_at, fluss_pegel_at, fluss_mitte_z, see)
##   k.zeit_setzen(t_s)                                  # alles ist eine reine Funktion der Zeit (Bilder, Tests)
## Inhalt: Steg 25 x 2 m + Ruderboot am Steg (duempelt), zweites Ruderboot faehrt eine langsame Kreisschleife,
## Holzfloss (8 x 3 m, Stammladung) treibt flussabwaerts (Fluss fliesst nach Westen), legt an der Holzlaende am Suedufer an,
## liegt, wird zurueckgesetzt (taucht ab, erscheint oberhalb wieder). Lage aus proto_orte.json _meta.see_nutzung (Stadt),
## sonst TA-Vorschlag Suedufer (1212 / 1262). Typen, die hier gebaut werden, NICHT zusaetzlich aus den Instanzen bauen.
class_name ProtoKulissen

const TYPEN_SELBST := ["steg", "ruderboot"]
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
	lage = {"quelle": quelle, "steg_wurzel": wurzel, "steg_ende": ende, "steg_laenge_m": wurzel.distance_to(ende),
		"see_mitte": see_mitte, "pegel_see": pegel_see, "boot_schleife": [_kreis_mitte, _kreis_r, _kreis_umlauf],
		"laende": _laende_punkt, "floss_periode_s": _periode}
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
