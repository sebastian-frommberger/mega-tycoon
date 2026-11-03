extends Node3D
## Phase 4 Welle 1 (Felix): Platzhalter für ProtoTerrain (TA, res://world/proto_terrain.gd), bis TA liefert.
## Gleiche API wie im Vertrag, aber FLACH (HOEHE_M); einzige Ausnahme: Knoten an Rinnenfeldern (proto_fluss.u8 Bit 1)
## liegen auf RINNE_M, damit Brücke und Uferrampen prüfbar sind (Wasser auf PEGEL_M). hoehe_at linear auf den Mesh-Dreiecken. Beim Merge gilt TAs Datei; die Szene
## nimmt automatisch res://world/proto_terrain.gd, sobald es die Datei gibt (prototyp_welt.gd _baue_gelaende).
## Absichtlich ohne class_name, damit es beim Merge keinen Namenskonflikt mit TAs `class_name ProtoTerrain` gibt.
##
## API (Vertrag):  static func bauen(parent: Node3D, daten_dir: String) -> Node3D   (fügt sich selbst in parent ein)
##                 func hoehe_at(x_m: float, z_m: float) -> float                    (m über NN)
## Zusatz-Hooks (optional, auch für TA vorgeschlagen, die Szene ruft sie nur, wenn vorhanden):
##                 func set_wasser_modus(modus: String) -> void                     ("A"/"B", Schalter V)
##                 func dreiecke() -> int                                           (Perf-Zählung ohne Renderziel)
## Darstellung: eine Bodenplatte über den ganzen Ausschnitt (−1000..3000 × −1000..2600 m), Fluss-Rinne als flache
## Wasserfläche aus proto_fluss.u8 (Bit 1), See als Scheibe aus proto_see.json, Bach als Linie aus proto_bach.json.

const HOEHE_M := 40.0
const RINNE_M := 34.5
const PEGEL_M := 36.4
const X0 := -1000.0
const Z0 := -1000.0
const W_FELDER := 160
const H_FELDER := 144
const M_PRO_FELD := 25.0

var daten_dir := ""
var wasser_modus := "A"
var _tris := 0
var _wasser_mat: StandardMaterial3D
var _knoten := PackedFloat32Array()     # (W+1) × (H+1)


static func bauen(parent: Node3D, p_daten_dir: String) -> Node3D:
	var t = load("res://proto/proto_terrain_stub.gd").new()
	t.name = "ProtoTerrainStub"
	t.daten_dir = p_daten_dir
	parent.add_child(t)
	t._baue()
	return t


func hoehe_at(x_m: float, z_m: float) -> float:
	if _knoten.is_empty():
		return HOEHE_M
	var fx := clampf((x_m - X0) / M_PRO_FELD, 0.0, W_FELDER - 0.0001)
	var fz := clampf((z_m - Z0) / M_PRO_FELD, 0.0, H_FELDER - 0.0001)
	var c := int(fx)
	var r := int(fz)
	var tx := fx - c
	var tz := fz - r
	var n := W_FELDER + 1
	var h00 := _knoten[r * n + c]
	var h10 := _knoten[r * n + c + 1]
	var h01 := _knoten[(r + 1) * n + c]
	var h11 := _knoten[(r + 1) * n + c + 1]
	# gleiche Dreiecksteilung wie das Mesh (Diagonale NW–SO), sonst taucht das Band an Kanten ins Gelände
	if tx >= tz:
		return h00 + (h10 - h00) * tx + (h11 - h10) * tz
	return h00 + (h11 - h01) * tx + (h01 - h00) * tz


func set_wasser_modus(modus: String) -> void:
	wasser_modus = modus
	if _wasser_mat != null:     # Hook-Nachweis: A = Fluss-Blau, B = ruhiger/dunkler (TA ersetzt das durch water.gdshader)
		_wasser_mat.albedo_color = Color(0.25, 0.45, 0.6) if modus == "A" else Color(0.18, 0.33, 0.42)


func dreiecke() -> int:
	return _tris


func _baue() -> void:
	var fluss := FileAccess.get_file_as_bytes(daten_dir.path_join("proto_fluss.u8"))
	var n := W_FELDER + 1
	_knoten.resize(n * (H_FELDER + 1))
	_knoten.fill(HOEHE_M)
	if fluss.size() == W_FELDER * H_FELDER:
		for r in H_FELDER:
			for c in W_FELDER:
				if fluss[r * W_FELDER + c] & 1:
					for k in [r * n + c, r * n + c + 1, (r + 1) * n + c, (r + 1) * n + c + 1]:
						_knoten[k] = RINNE_M
	var boden := StandardMaterial3D.new()
	boden.albedo_color = Color(0.47, 0.56, 0.33)
	boden.roughness = 1.0
	var gs := SurfaceTool.new()
	gs.begin(Mesh.PRIMITIVE_TRIANGLES)
	for r in H_FELDER + 1:
		for c in n:
			gs.add_vertex(Vector3(X0 + c * M_PRO_FELD, _knoten[r * n + c], Z0 + r * M_PRO_FELD))
	for r in H_FELDER:
		for c in W_FELDER:
			var a := r * n + c
			gs.add_index(a); gs.add_index(a + 1); gs.add_index(a + n + 1)
			gs.add_index(a); gs.add_index(a + n + 1); gs.add_index(a + n)
	gs.generate_normals()
	var mi := MeshInstance3D.new()
	mi.name = "Boden"
	mi.mesh = gs.commit()
	mi.material_override = boden
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	_tris += W_FELDER * H_FELDER * 2
	_wasser_mat = StandardMaterial3D.new()
	_wasser_mat.roughness = 0.2
	_wasser_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	set_wasser_modus(wasser_modus)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	var y := PEGEL_M
	if fluss.size() == W_FELDER * H_FELDER:
		for r in H_FELDER:
			for c in W_FELDER:
				if fluss[r * W_FELDER + c] & 1:
					var x := X0 + c * M_PRO_FELD
					var z := Z0 + r * M_PRO_FELD
					_quad(st, Vector3(x, y, z), Vector3(x + M_PRO_FELD, y, z + M_PRO_FELD))
	y = HOEHE_M + 0.04                     # See und Bach im flachen Stub knapp über dem Boden
	var see = _json(daten_dir.path_join("proto_see.json"))
	if see is Dictionary and see.has("mitte_m"):
		var m := Vector3(float(see["mitte_m"][0]), y, float(see["mitte_m"][1]))
		var r := float(see.get("radius_m", 250.0))
		var ns := 64
		for i in ns:
			var a0 := TAU * i / ns
			var a1 := TAU * (i + 1) / ns
			st.add_vertex(m)
			st.add_vertex(m + Vector3(cos(a0), 0, sin(a0)) * r)
			st.add_vertex(m + Vector3(cos(a1), 0, sin(a1)) * r)
			_tris += 1
	var bach = _json(daten_dir.path_join("proto_bach.json"))
	if bach is Dictionary and bach.has("polyline_m"):
		var p: Array = bach["polyline_m"]
		for i in p.size() - 1:
			var a := Vector3(float(p[i][0]), y, float(p[i][1]))
			var b := Vector3(float(p[i + 1][0]), y, float(p[i + 1][1]))
			var q := (b - a).normalized().cross(Vector3.UP) * 2.5
			st.add_vertex(a - q); st.add_vertex(b + q); st.add_vertex(a + q)
			st.add_vertex(a - q); st.add_vertex(b - q); st.add_vertex(b + q)
			_tris += 2
	var wm := st.commit()
	if wm != null and wm.get_surface_count() > 0:
		var wi := MeshInstance3D.new()
		wi.name = "Wasser"
		wi.mesh = wm
		wi.material_override = _wasser_mat
		wi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(wi)


func _quad(st: SurfaceTool, a: Vector3, b: Vector3) -> void:
	st.add_vertex(Vector3(a.x, a.y, a.z)); st.add_vertex(Vector3(b.x, a.y, a.z)); st.add_vertex(Vector3(b.x, a.y, b.z))
	st.add_vertex(Vector3(a.x, a.y, a.z)); st.add_vertex(Vector3(b.x, a.y, b.z)); st.add_vertex(Vector3(a.x, a.y, b.z))
	_tris += 2


static func _json(pfad: String) -> Variant:
	if not FileAccess.file_exists(pfad):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(pfad))
