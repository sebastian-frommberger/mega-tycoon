extends RefCounted
## Prototyp Phase 4 (TA): baut Prefabs nach world/data/proto/proto_prefab_bauanleitung.json (tools_proto/ta_import_faktoren.py).
## Szene in Metern. Skalierung je Achse = skala_m_pro_u (inkl. Quer-/Laengsfaktor R3), Pivot unten Mitte (R6).
##   var n := ProtoPrefabBau.baue("laubbaum")          # Modell aus res_ziel, sonst Platzhalter-Box in Kenney-bbox
##   var a := ProtoPrefabBau.messen(n)                  # AABB in m (Wurzel-Raum)
##   var p := ProtoPrefabBau.pruefe("laubbaum", a)      # {ok, wert_m, band_m, achse}
## Zusammenbauten: baue_haus_s(), baue_fuhrwerk() (Platzhalter-Teile, Welle 2 ersetzt Teile durch Modelle).
## Welle 2: Modelle nach res_ziel kopieren, --import, dann je Rolle baue() -> 1 Mesh zusammenfassen und als .tres speichern.

const ANLEITUNG := "res://world/data/proto/proto_prefab_bauanleitung.json"
static var _a := {}


static func anleitung() -> Dictionary:
	if _a.is_empty():
		_a = JSON.parse_string(FileAccess.get_file_as_string(ANLEITUNG))
	return _a


static func rolle(name: String) -> Dictionary:
	return anleitung()["rollen"][name]


## Modell laden: importierte Szene unter res_ziel, sonst lokal_asset (Arbeitskopie assets/, per GLTFDocument), sonst null.
static func lade_modell(e: Dictionary) -> Node3D:
	var p: String = e["res_ziel"]
	if ResourceLoader.exists(p, "PackedScene"):
		var ps := load(p) as PackedScene
		if ps != null:
			return ps.instantiate() as Node3D
	var la: String = e.get("lokal_asset", "")
	if la != "":
		var abs := ProjectSettings.globalize_path("res://").path_join("..").path_join(la).simplify_path()
		if FileAccess.file_exists(abs):
			var gd := GLTFDocument.new()
			var st := GLTFState.new()
			if gd.append_from_file(abs, st) == OK:
				return gd.generate_scene(st) as Node3D
	return null


## Platzhalter in Kenney-Einheiten: Box in bbox_u, Fusspunkt y = 0 (wie die Kenney-Modelle)
static func platzhalter(e: Dictionary, farbe := Color(0.8, 0.7, 0.55)) -> Node3D:
	var bb: Array = e["bbox_u"]
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(bb[0], bb[1], bb[2])
	var mat := StandardMaterial3D.new()
	mat.albedo_color = farbe
	bm.material = mat
	mi.mesh = bm
	mi.position = Vector3(0, float(bb[1]) * 0.5, 0)
	var n := Node3D.new()
	n.add_child(mi)
	return n


static func baue(name: String, modell: Node3D = null) -> Node3D:
	var e := rolle(name)
	var m := modell if modell != null else lade_modell(e)
	var quelle := "modell"
	if m == null:
		m = platzhalter(e)
		quelle = "platzhalter"
	var s: Array = e["skala_m_pro_u"]
	m.scale = Vector3(s[0], s[1], s[2])
	var w := Node3D.new()
	w.name = name
	w.add_child(m)
	var a := messen(w)
	m.position -= Vector3(a.get_center().x, a.position.y, a.get_center().z)
	w.set_meta("quelle", quelle)
	w.set_meta("rolle", name)
	return w


## AABB aller MeshInstance3D unter n, im Raum von n (funktioniert ohne SceneTree)
static func messen(n: Node) -> AABB:
	var acc := [AABB(), false]
	_mess(n, Transform3D.IDENTITY, acc, true)
	return acc[0]


static func _mess(n: Node, tr: Transform3D, acc: Array, wurzel: bool) -> void:
	var t := tr
	if n is Node3D and not wurzel:
		t = tr * (n as Node3D).transform
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		var b := t * (n as MeshInstance3D).mesh.get_aabb()
		if acc[1]:
			acc[0] = (acc[0] as AABB).merge(b)
		else:
			acc[0] = b
			acc[1] = true
	for c in n.get_children():
		_mess(c, t, acc, false)


static func pruefe(name: String, a: AABB) -> Dictionary:
	var e := rolle(name)
	var tol: Dictionary = e["toleranz"]
	var ax: String = tol["achse"]
	var wert: float = a.size["xyz".find(ax)]
	var band: Array = tol["band_m"]
	return {"ok": wert >= float(band[0]) and wert <= float(band[1]), "wert_m": wert, "band_m": band, "achse": ax}


static func _teil(name: String, pos: Vector3, rot_y := 0.0) -> Node3D:
	var n := baue(name)
	n.position = pos
	n.rotation_degrees.y = rot_y
	return n


## Haus S = 3 x 2 Module (3 m) + Dachmodule roof-high, Kenney-Modulraster (Platzhalter-Teile)
static func baue_haus_s() -> Node3D:
	var w := Node3D.new()
	w.name = "haus_s"
	var modul := 3.0
	for i in 3:
		w.add_child(_teil("haus_s_modul", Vector3((i - 1) * modul, 0, -modul), 0.0))   # Laengswand Nord (Wand duenn in x -> drehen)
		w.add_child(_teil("haus_s_modul", Vector3((i - 1) * modul, 0, modul), 0.0))
	for j in 2:
		w.add_child(_teil("haus_s_modul", Vector3(-1.5 * modul, 0, (j - 0.5) * modul), 0.0))
		w.add_child(_teil("haus_s_modul", Vector3(1.5 * modul, 0, (j - 0.5) * modul), 0.0))
	# Waende Nord/Sued liegen quer: dünne Achse x -> um 90 Grad drehen
	for c in w.get_children():
		if absf(c.position.z) > 2.0:
			c.rotation_degrees.y = 90.0
	var dach_y := modul
	for i in 3:
		for j in 2:
			var d := _teil("dach_hoch", Vector3((i - 1) * modul, dach_y, (j - 0.5) * 3.21), 0.0 if j == 0 else 180.0)
			d.rotation_degrees.y += 90.0
			w.add_child(d)
	return w


## Fuhrwerk = Wagen (cart, Querfaktor 0,65) + Deichsel + 2 Pferde (Laengsachse x -> 90 Grad), Gesamtlaenge ~9,5 m
static func baue_fuhrwerk() -> Node3D:
	var w := Node3D.new()
	w.name = "fuhrwerk"
	w.add_child(_teil("fuhrwerk_wagen", Vector3.ZERO))
	var de := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.1, 0.1, 2.0)
	de.mesh = bm
	de.position = Vector3(0, 0.8, 2.5 + 1.0)
	w.add_child(de)
	for sx in [-0.55, 0.55]:
		w.add_child(_teil("pferd", Vector3(sx, 0, 2.5 + 1.6 + 1.45), 90.0))
	return w
