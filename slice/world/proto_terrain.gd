class_name ProtoTerrain
extends Node3D
## Prototyp-Welt Phase 4 (TA, TEAM-02): Gelaende, Wasser und Baeume aus slice/world/data/proto (tools_proto/ta_export.py).
## Szene in METERN (1 Einheit = 1 m), Ursprung = NW-Ecke des Kerns, +x Ost, +z Sued, y = Hoehe ueber NN (VERTRAG.md).
##   var t := ProtoTerrain.bauen(parent, "res://world/data/proto")
##   t.hoehe_at(x_m, z_m)        exakt die Hoehe der gerenderten Dreiecke (Grob- 25 m bzw. Feinraster 5 m)
##   t.boden_at(x_m, z_m)        Bodenklasse (Index in proto_meta.json boden.klassen)
##   t.ist_wasser(x_m, z_m)      Fluss, See, Teich (Bach nicht: blockiert nicht)
##   t.baeume_freistellen([Vector3(x, z, r), ...])   Baeume in Kreisen entfernen (Orte, Wege, Hofstellen)
##   t.wasser_variante_b(true)   Wasser A/B (12_welt_regelwerk_v1 §6)
## Gelaende: 4 x 4 Chunks; Felder mit proto_fein_maske = 1 im 5-m-Raster (See, Teiche, Bachrinne), sonst 25 m.
## Gleiche Dreiecksteilung ueberall: (a,b,c), (b,d,c) mit a=(x,z), b=(x+1,z), c=(x,z+1), d=(x+1,z+1).

const SHADER := preload("res://world/proto_terrain.gdshader")
const BAUM_SHADER := preload("res://world/proto_baum.gdshader")
const Wasser := preload("res://world/proto_wasser.gd")
const M := 25.0
const FM := 5.0
const SUB := 5
const SKALA := 0.05
const CHUNKS_X := 4
const CHUNKS_Z := 4
const SCHUERZE_M := 30.0
## Baeume (08_landschaft d, 10_import_faktoren.json; Faktor je Feld -> m je Kenney-Einheit = Faktor * 25)
const BAUM_LAUB := "res://props/kenney/tree_default.glb"
const BAUM_NADEL := "res://props/kenney/tree_pineDefaultA.glb"
const LAUB_FAKTOR := 0.42
const NADEL_FAKTOR := 0.65
const BAUM_SICHT_M := 1800.0            # visibility_range_end je Chunk (08: 2.500 m; 1.800 wegen Perf-Gate, Doku)
const BAUM_CHUNK_M := 500.0
const BAUM_BEREICH := Rect2(-500.0, -500.0, 3000.0, 2600.0)   # Kern + 500 m; aussen nur Waldboden + Kronentupfen
## Baeume je Feld nach Bodenklasse (08 d; Wald innen/Rand reduziert, Doku): id -> Dichte
const DICHTE := {0: 0.1, 1: 0.25, 2: 1.0, 5: 0.3, 6: 4.0, 10: 0.6}
const DICHTE_WALDRAND := 2.5
const NADEL_ANTEIL := 0.15

var gw := 0
var gh := 0
var ox := 0.0
var oz := 0.0
var fnx := 0
var fny := 0
var hoehe := PackedFloat32Array()        # Grobknoten (gw+1)*(gh+1)
var fein := PackedByteArray()            # Feinknoten uint16 LE
var fein_maske := PackedByteArray()
var fluss := PackedByteArray()
var boden_klasse := PackedByteArray()    # je Feld
var boden_tex: ImageTexture
var pegel_spalte := PackedFloat32Array()
var meta := {}
var see := {}
var bach := {}
var gewaesser: Array = []               # [{name, mitte: Vector2, r: float, r_aussen: float, pegel: float}]
var terrain_mat: ShaderMaterial
var wasser_mats: Array = []
var stats := {}
var _baeume: Array = []                 # [art(0 laub/1 nadel), Transform3D, Color]
var _baum_meshes: Array = []
var _baum_mat: ShaderMaterial
var _baum_node: Node3D


static func bauen(parent: Node3D, daten_dir: String) -> ProtoTerrain:
	var t0 := Time.get_ticks_usec()
	var t := ProtoTerrain.new()
	t.name = "ProtoTerrain"
	parent.add_child(t)
	t._laden(daten_dir)
	var t1 := Time.get_ticks_usec()
	t._baue_gelaende()
	var t2 := Time.get_ticks_usec()
	t._baue_wasser()
	var t3 := Time.get_ticks_usec()
	t._baue_baeume()
	var t4 := Time.get_ticks_usec()
	t.stats["ms_laden"] = (t1 - t0) / 1000.0
	t.stats["ms_gelaende"] = (t2 - t1) / 1000.0
	t.stats["ms_wasser"] = (t3 - t2) / 1000.0
	t.stats["ms_baeume"] = (t4 - t3) / 1000.0
	t.stats["ms_gesamt"] = (t4 - t0) / 1000.0
	return t


# ------------------------------------------------------------------ Daten
func _laden(dir: String) -> void:
	meta = JSON.parse_string(FileAccess.get_file_as_string(dir.path_join("proto_meta.json")))
	gw = int(meta["felder"][0])
	gh = int(meta["felder"][1])
	ox = float(meta["ursprung_knoten0_m"][0])
	oz = float(meta["ursprung_knoten0_m"][1])
	fnx = int(meta["fein"]["knoten"][0])
	fny = int(meta["fein"]["knoten"][1])
	var hb := FileAccess.get_file_as_bytes(dir.path_join("proto_hoehe.r16"))
	var n := (gw + 1) * (gh + 1)
	assert(hb.size() == n * 2, "proto_hoehe.r16 Groesse")
	hoehe.resize(n)
	for i in n:
		hoehe[i] = hb.decode_u16(i * 2) * SKALA
	fein = FileAccess.get_file_as_bytes(dir.path_join("proto_fein.r16"))
	assert(fein.size() == fnx * fny * 2, "proto_fein.r16 Groesse")
	fein_maske = FileAccess.get_file_as_bytes(dir.path_join("proto_fein_maske.u8"))
	fluss = FileAccess.get_file_as_bytes(dir.path_join("proto_fluss.u8"))
	for v in meta["fluss_pegel_spalte_m"]:
		pegel_spalte.append(float(v))
	see = JSON.parse_string(FileAccess.get_file_as_string(dir.path_join("proto_see.json")))
	bach = JSON.parse_string(FileAccess.get_file_as_string(dir.path_join("proto_bach.json")))
	for k in ["see", "muehlteich", "dorfteich"]:
		if not see.has(k):
			continue
		var g: Dictionary = see[k]
		var r := float(g["radius_m"])
		gewaesser.append({"name": k, "mitte": Vector2(g["mitte_m"][0], g["mitte_m"][1]), "r": r,
			"rauschen": float(g.get("ufer_rauschen", 0.0)), "phase": float(g.get("rausch_phase", 0.0)),
			"r_aussen": r * (1.0 + float(g.get("ufer_rauschen", 0.0)) * 1.2) + float(g["boeschung_m"]), "pegel": float(g["pegel_m"])})
	var img := Image.new()
	img.load_png_from_buffer(FileAccess.get_file_as_bytes(dir.path_join("proto_boden.png")))
	assert(img != null and img.get_width() == gw and img.get_height() == gh, "proto_boden.png Groesse")
	img.convert(Image.FORMAT_RGBA8)
	var data := img.get_data()
	boden_klasse.resize(gw * gh)
	for i in gw * gh:
		boden_klasse[i] = int(floor(data[i * 4 + 3] / 20.0))
	boden_tex = ImageTexture.create_from_image(img)


# ------------------------------------------------------------------ Abfragen
func _h(ix: int, iz: int) -> float:
	return hoehe[iz * (gw + 1) + ix]


func _fh(ix: int, iz: int) -> float:
	return fein.decode_u16((iz * fnx + ix) * 2) * SKALA


static func _tri(a: float, b: float, c: float, d: float, u: float, v: float) -> float:
	if u + v <= 1.0:
		return a + (b - a) * u + (c - a) * v
	return d + (c - d) * (1.0 - u) + (b - d) * (1.0 - v)


func hoehe_at(x_m: float, z_m: float) -> float:
	var gx := clampf((x_m - ox) / M, 0.0, gw - 0.0001)
	var gz := clampf((z_m - oz) / M, 0.0, gh - 0.0001)
	var cx := int(gx)
	var cz := int(gz)
	if fein_maske[cz * gw + cx] != 0:
		var fx := clampf((x_m - ox) / FM, 0.0, fnx - 1.0001)
		var fz := clampf((z_m - oz) / FM, 0.0, fny - 1.0001)
		var ix := int(fx)
		var iz := int(fz)
		return _tri(_fh(ix, iz), _fh(ix + 1, iz), _fh(ix, iz + 1), _fh(ix + 1, iz + 1), fx - ix, fz - iz)
	return _tri(_h(cx, cz), _h(cx + 1, cz), _h(cx, cz + 1), _h(cx + 1, cz + 1), gx - cx, gz - cz)


func _feld(x_m: float, z_m: float) -> int:
	var cx := clampi(int(floor((x_m - ox) / M)), 0, gw - 1)
	var cz := clampi(int(floor((z_m - oz) / M)), 0, gh - 1)
	return cz * gw + cx


func boden_at(x_m: float, z_m: float) -> int:
	return boden_klasse[_feld(x_m, z_m)]


func fluss_bits_at(x_m: float, z_m: float) -> int:
	return fluss[_feld(x_m, z_m)]


## Flusspegel (m) an x (je Feldspalte, linear zwischen Spaltenmitten)
func fluss_pegel_at(x_m: float) -> float:
	var g := clampf((x_m - ox) / M - 0.5, 0.0, gw - 1.0)
	var i := mini(int(g), gw - 2)
	return lerpf(pegel_spalte[i], pegel_spalte[i + 1], g - i)


func ist_wasser(x_m: float, z_m: float) -> bool:
	var b := fluss[_feld(x_m, z_m)]
	var h := hoehe_at(x_m, z_m)
	if b & 1 and h < fluss_pegel_at(x_m):
		return true
	for g in gewaesser:
		if Vector2(x_m, z_m).distance_to(g["mitte"]) < g["r_aussen"] and h < g["pegel"]:
			return true
	return false


# ------------------------------------------------------------------ Gelaende
func _normal_grob(ix: int, iz: int) -> Vector3:
	var l := _h(maxi(ix - 1, 0), iz)
	var r := _h(mini(ix + 1, gw), iz)
	var u := _h(ix, maxi(iz - 1, 0))
	var d := _h(ix, mini(iz + 1, gh))
	var sx := float(mini(ix + 1, gw) - maxi(ix - 1, 0)) * M
	var sz := float(mini(iz + 1, gh) - maxi(iz - 1, 0)) * M
	return Vector3(-(r - l) / sx, 1.0, -(d - u) / sz).normalized()


func _normal_fein(ix: int, iz: int) -> Vector3:
	var l := _fh(maxi(ix - 1, 0), iz)
	var r := _fh(mini(ix + 1, fnx - 1), iz)
	var u := _fh(ix, maxi(iz - 1, 0))
	var d := _fh(ix, mini(iz + 1, fny - 1))
	var sx := float(mini(ix + 1, fnx - 1) - maxi(ix - 1, 0)) * FM
	var sz := float(mini(iz + 1, fny - 1) - maxi(iz - 1, 0)) * FM
	return Vector3(-(r - l) / sx, 1.0, -(d - u) / sz).normalized()


func _ist_fein(cx: int, cz: int) -> bool:
	if cx < 0 or cz < 0 or cx >= gw or cz >= gh:
		return false
	return fein_maske[cz * gw + cx] != 0


func _material() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter("boden", boden_tex)
	m.set_shader_parameter("boden_rect", Vector4(ox, oz, gw * M, gh * M))
	var arr := PackedVector4Array()
	for g in gewaesser:
		arr.append(Vector4(g["mitte"].x, g["mitte"].y, g["r_aussen"], g["pegel"]))
	while arr.size() < 4:
		arr.append(Vector4.ZERO)
	m.set_shader_parameter("gewaesser", arr)
	m.set_shader_parameter("gewaesser_n", mini(gewaesser.size(), 4))
	return m


func _baue_gelaende() -> void:
	terrain_mat = _material()
	var cw := int(ceil(float(gw) / CHUNKS_X))
	var ch := int(ceil(float(gh) / CHUNKS_Z))
	var tris := 0
	var dc := 0
	var fein_felder := 0
	for kz in CHUNKS_Z:
		for kx in CHUNKS_X:
			var x0 := kx * cw
			var z0 := kz * ch
			var x1 := mini(x0 + cw, gw)
			var z1 := mini(z0 + ch, gh)
			var v := PackedVector3Array()
			var nm := PackedVector3Array()
			var idx := PackedInt32Array()
			var gidx := {}      # Grobknoten -> Vertex
			var fidx := {}      # Feinknoten -> Vertex
			for cz in range(z0, z1):
				for cx in range(x0, x1):
					if fein_maske[cz * gw + cx] != 0:
						fein_felder += 1
						for sz in SUB:
							for sx in SUB:
								var ix := cx * SUB + sx
								var iz := cz * SUB + sz
								var q := [Vector2i(ix, iz), Vector2i(ix + 1, iz), Vector2i(ix, iz + 1), Vector2i(ix + 1, iz + 1)]
								var vi: Array[int] = []
								for k: Vector2i in q:
									var key := k.y * fnx + k.x
									if not fidx.has(key):
										fidx[key] = v.size()
										v.append(Vector3(ox + k.x * FM, _fh(k.x, k.y), oz + k.y * FM))
										nm.append(_normal_fein(k.x, k.y))
									vi.append(fidx[key])
								idx.append_array([vi[0], vi[1], vi[2], vi[1], vi[3], vi[2]])
					else:
						var q2 := [Vector2i(cx, cz), Vector2i(cx + 1, cz), Vector2i(cx, cz + 1), Vector2i(cx + 1, cz + 1)]
						var vi2: Array[int] = []
						for k: Vector2i in q2:
							var key2 := k.y * (gw + 1) + k.x
							if not gidx.has(key2):
								gidx[key2] = v.size()
								v.append(Vector3(ox + k.x * M, _h(k.x, k.y), oz + k.y * M))
								nm.append(_normal_grob(k.x, k.y))
							vi2.append(gidx[key2])
						if not (_ist_fein(cx, cz - 1) or _ist_fein(cx + 1, cz) or _ist_fein(cx, cz + 1) or _ist_fein(cx - 1, cz)):
							idx.append_array([vi2[0], vi2[1], vi2[2], vi2[1], vi2[3], vi2[2]])
							continue
						# Nachbar im Feinraster: Faecher ueber die Feldmitte mit den Feinknoten der gemeinsamen Kante
						# (keine T-Kreuzung -> keine Pixelrisse). Mitte liegt auf der Diagonale b-c, die Faecherdreiecke
						# liegen in den Ebenen der beiden Originaldreiecke -> Flaeche und hoehe_at unveraendert.
						var ring: Array[int] = []
						var kanten := [[vi2[0], Vector2i(0, 0), Vector2i(1, 0), _ist_fein(cx, cz - 1)],
							[vi2[1], Vector2i(1, 0), Vector2i(0, 1), _ist_fein(cx + 1, cz)],
							[vi2[3], Vector2i(1, 1), Vector2i(-1, 0), _ist_fein(cx, cz + 1)],
							[vi2[2], Vector2i(0, 1), Vector2i(0, -1), _ist_fein(cx - 1, cz)]]
						for e in kanten:
							ring.append(e[0])
							if e[3]:
								var start: Vector2i = Vector2i(cx * SUB, cz * SUB) + (e[1] as Vector2i) * SUB
								for s in range(1, SUB):
									var f: Vector2i = start + (e[2] as Vector2i) * s
									ring.append(v.size())
									v.append(Vector3(ox + f.x * FM, _fh(f.x, f.y), oz + f.y * FM))
									nm.append(_normal_fein(f.x, f.y))
						var mitte := v.size()
						v.append(Vector3(ox + (cx + 0.5) * M, (_h(cx + 1, cz) + _h(cx, cz + 1)) * 0.5, oz + (cz + 0.5) * M))
						nm.append((_normal_grob(cx + 1, cz) + _normal_grob(cx, cz + 1)).normalized())
						for r in ring.size():
							idx.append_array([mitte, ring[r], ring[(r + 1) % ring.size()]])
			var arr := []
			arr.resize(Mesh.ARRAY_MAX)
			arr[Mesh.ARRAY_VERTEX] = v
			arr[Mesh.ARRAY_NORMAL] = nm
			arr[Mesh.ARRAY_INDEX] = idx
			var am := ArrayMesh.new()
			am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
			var mi := MeshInstance3D.new()
			mi.name = "Gelaende_%d_%d" % [kx, kz]
			mi.mesh = am
			mi.material_override = terrain_mat
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(mi)
			tris += idx.size() / 3
			dc += 1
	tris += _baue_schuerze()
	dc += 1
	stats["gelaende_dreiecke"] = tris
	stats["gelaende_meshes"] = dc
	stats["fein_felder"] = fein_felder


func _baue_schuerze() -> int:
	# Kartenkante: senkrechter Streifen 30 m nach unten, damit man nicht unter die Karte sieht
	var v := PackedVector3Array()
	var nm := PackedVector3Array()
	var idx := PackedInt32Array()
	var rand: Array = []
	for x in gw + 1:
		rand.append([Vector2i(x, 0), Vector3(0, 0, -1)])
	for z in gh + 1:
		rand.append([Vector2i(gw, z), Vector3(1, 0, 0)])
	for x in range(gw, -1, -1):
		rand.append([Vector2i(x, gh), Vector3(0, 0, 1)])
	for z in range(gh, -1, -1):
		rand.append([Vector2i(0, z), Vector3(-1, 0, 0)])
	for i in rand.size():
		var k: Vector2i = rand[i][0]
		var p := Vector3(ox + k.x * M, _h(k.x, k.y), oz + k.y * M)
		v.append(p)
		v.append(p - Vector3(0, SCHUERZE_M + (p.y - 30.0) * 0.0, 0))
		nm.append(rand[i][1])
		nm.append(rand[i][1])
		if i > 0:
			var a := (i - 1) * 2
			var b := i * 2
			idx.append_array([a, a + 1, b, b, a + 1, b + 1])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_NORMAL] = nm
	arr[Mesh.ARRAY_INDEX] = idx
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.36, 0.33, 0.27)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mi := MeshInstance3D.new()
	mi.name = "Schuerze"
	mi.mesh = am
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return idx.size() / 3


# ------------------------------------------------------------------ Wasser
func _baue_wasser() -> void:
	var w := Node3D.new()
	w.name = "Wasser"
	add_child(w)
	var tris := 0
	var meshes := 0
	var f: MeshInstance3D = Wasser.fluss_mesh(self)
	w.add_child(f)
	tris += int(f.get_meta("dreiecke"))
	meshes += 1
	wasser_mats.append(f.material_override)
	for g in gewaesser:
		var s: MeshInstance3D = Wasser.steh_mesh(self, g)
		w.add_child(s)
		tris += int(s.get_meta("dreiecke"))
		meshes += 1
		wasser_mats.append(s.material_override)
	var b: MeshInstance3D = Wasser.bach_mesh(self, bach)
	w.add_child(b)
	tris += int(b.get_meta("dreiecke"))
	meshes += 1
	wasser_mats.append(b.material_override)
	stats["wasser_dreiecke"] = tris
	stats["wasser_meshes"] = meshes


## Wasser A/B (12_welt_regelwerk_v1 §6): B = c_tief #2F6E7C, tiefe_voll 3,5 m
func wasser_variante_b(an: bool) -> void:
	for m: ShaderMaterial in wasser_mats:
		m.set_shader_parameter("c_tief", Color("2F6E7C") if an else Color("345F7E"))
		m.set_shader_parameter("tiefe_voll_m", 3.5 if an else 2.5)


# ------------------------------------------------------------------ Baeume
static func _hash(a: int, b: int, s: int) -> float:
	var v := sin(a * 127.1 + b * 311.7 + s * 74.7) * 43758.5453
	return v - floor(v)


func _baum_mesh(path: String, m_pro_u: float, stamm: Color, krone: Color) -> ArrayMesh:
	# Kenney-Modell laden, alle Flaechen zu EINER Flaeche mit Vertexfarbe zusammenfassen (1 Draw Call je MultiMesh),
	# Fusspunkt auf y = 0, Skalierung in Metern.
	if not ResourceLoader.exists(path):
		return null
	var ps := load(path) as PackedScene
	if ps == null:
		return null
	var root := ps.instantiate()
	var mis: Array = []
	var stack: Array = [[root, Transform3D.IDENTITY]]
	while not stack.is_empty():
		var e: Array = stack.pop_back()
		var nd: Node = e[0]
		var tr: Transform3D = e[1]
		if nd is Node3D:
			tr = tr * (nd as Node3D).transform
		if nd is MeshInstance3D:
			mis.append([nd, tr])
		for c in nd.get_children():
			stack.append([c, tr])
	var v := PackedVector3Array()
	var nm := PackedVector3Array()
	var col := PackedColorArray()
	var idx := PackedInt32Array()
	for e in mis:
		var mesh: Mesh = (e[0] as MeshInstance3D).mesh
		var tr: Transform3D = e[1]
		for s in mesh.get_surface_count():
			var a := mesh.surface_get_arrays(s)
			var mat := mesh.surface_get_material(s)
			var mn := String(mat.resource_name).to_lower() if mat != null else ""
			var ist_stamm := mn.contains("wood") or mn.contains("trunk") or mn.contains("brown")
			var c := stamm if ist_stamm else krone
			c.a = 0.0 if ist_stamm else 1.0
			var base := v.size()
			var sv: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
			var sn: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
			for i in sv.size():
				v.append(tr * sv[i])
				nm.append((tr.basis * sn[i]).normalized())
				col.append(c)
			var si = a[Mesh.ARRAY_INDEX]
			if si == null:
				for i in sv.size():
					idx.append(base + i)
			else:
				for i in (si as PackedInt32Array):
					idx.append(base + i)
	root.free()
	var miny := INF
	for p in v:
		miny = minf(miny, p.y)
	for i in v.size():
		v[i] = (v[i] - Vector3(0, miny, 0)) * m_pro_u
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_NORMAL] = nm
	arr[Mesh.ARRAY_COLOR] = col
	arr[Mesh.ARRAY_INDEX] = idx
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	am.set_meta("dreiecke", idx.size() / 3)
	return am


func _baue_baeume() -> void:
	_baum_mat = ShaderMaterial.new()
	_baum_mat.shader = BAUM_SHADER
	_baum_meshes = [
		_baum_mesh(BAUM_LAUB, LAUB_FAKTOR * M, Color("6B4A2E"), Color("5A8A40")),
		_baum_mesh(BAUM_NADEL, NADEL_FAKTOR * M, Color("5E4330"), Color("3F6640")),
	]
	if _baum_meshes[0] == null or _baum_meshes[1] == null:
		push_warning("ProtoTerrain: Kenney-Baeume fehlen, keine Baeume")
		stats["baeume"] = 0
		return
	_baeume.clear()
	var c0 := int(floor((BAUM_BEREICH.position.x - ox) / M))
	var c1 := int(ceil((BAUM_BEREICH.end.x - ox) / M))
	var r0 := int(floor((BAUM_BEREICH.position.y - oz) / M))
	var r1 := int(ceil((BAUM_BEREICH.end.y - oz) / M))
	for cz in range(maxi(r0, 0), mini(r1, gh)):
		for cx in range(maxi(c0, 0), mini(c1, gw)):
			var i := cz * gw + cx
			var k := int(boden_klasse[i])
			if not DICHTE.has(k) or fluss[i] & 8:
				continue
			var d: float = DICHTE[k]
			if k == 6:
				for nb in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var xx: int = cx + nb.x
					var zz: int = cz + nb.y
					if xx >= 0 and zz >= 0 and xx < gw and zz < gh and boden_klasse[zz * gw + xx] != 6:
						d = DICHTE_WALDRAND
						break
			var n := int(d) + (1 if _hash(cx, cz, 1) < d - int(d) else 0)
			for j in n:
				var x := ox + (cx + _hash(cx * 7 + j, cz, 2)) * M
				var z := oz + (cz + _hash(cx, cz * 7 + j, 3)) * M
				if ist_wasser(x, z):
					continue
				var art := 1 if (k == 6 and _hash(cx + j, cz, 4) < NADEL_ANTEIL) else 0
				var s := 0.85 + _hash(cx, cz + j, 5) * 0.3
				if k == 2 or k == 10:
					s *= 0.75      # Erlen/Weiden am Wasser kleiner
				_baum_dazu(art, x, z, s, _hash(cx + j * 3, cz, 6))
	# Gehoelzsaum am Bach: 1 Baum je 10 m je Seite, 5-15 m neben der Bachachse
	var pts: Array = bach["punkte"]
	var lauf := 0.0
	var naechster := 0.0
	for i in range(1, pts.size()):
		var a := Vector2(pts[i - 1][0], pts[i - 1][1])
		var b := Vector2(pts[i][0], pts[i][1])
		lauf += a.distance_to(b)
		if lauf < naechster or int(pts[i][3]) == 1:
			continue
		naechster = lauf + 10.0
		var t := (b - a).normalized()
		var q := Vector2(-t.y, t.x)
		for seite in [-1.0, 1.0]:
			var off := 5.0 + _hash(i, int(seite), 7) * 10.0
			var p: Vector2 = b + q * off * seite + t * (_hash(i, int(seite), 8) - 0.5) * 6.0
			if ist_wasser(p.x, p.y):
				continue
			_baum_dazu(0, p.x, p.y, 0.6 + _hash(i, int(seite), 9) * 0.25, _hash(i, int(seite), 10))
	_baeume_chunks()


func _baum_dazu(art: int, x: float, z: float, s: float, rot: float) -> void:
	var y := hoehe_at(x, z) - 0.3
	var basis := Basis(Vector3.UP, rot * TAU).scaled(Vector3(s, s, s))
	var tint := Color(0.86 + _hash(int(x), int(z), 11) * 0.28, 0.9 + _hash(int(z), int(x), 12) * 0.2, 0.85 + _hash(int(x), int(z), 13) * 0.2)
	_baeume.append([art, Transform3D(basis, Vector3(x, y, z)), tint])


func _baeume_chunks() -> void:
	if _baum_node != null:
		_baum_node.free()
	_baum_node = Node3D.new()
	_baum_node.name = "Baeume"
	add_child(_baum_node)
	var nx := int(ceil(BAUM_BEREICH.size.x / BAUM_CHUNK_M))
	var nz := int(ceil(BAUM_BEREICH.size.y / BAUM_CHUNK_M))
	var gruppen := {}
	for e in _baeume:
		var t: Transform3D = e[1]
		var kx := clampi(int((t.origin.x - BAUM_BEREICH.position.x) / BAUM_CHUNK_M), 0, nx - 1)
		var kz := clampi(int((t.origin.z - BAUM_BEREICH.position.y) / BAUM_CHUNK_M), 0, nz - 1)
		var key := (kz * nx + kx) * 2 + int(e[0])
		if not gruppen.has(key):
			gruppen[key] = []
		gruppen[key].append(e)
	var tris_alle := 0
	var n_mm := 0
	var keys := gruppen.keys()
	keys.sort()
	for key in keys:
		var liste: Array = gruppen[key]
		var art: int = key % 2
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = _baum_meshes[art]
		mm.instance_count = liste.size()
		for i in liste.size():
			mm.set_instance_transform(i, liste[i][1])
			mm.set_instance_color(i, liste[i][2])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Baeume_%d_%s" % [key / 2, "nadel" if art == 1 else "laub"]
		mmi.multimesh = mm
		mmi.material_override = _baum_mat
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.visibility_range_end = BAUM_SICHT_M
		mmi.visibility_range_end_margin = 50.0
		_baum_node.add_child(mmi)
		tris_alle += liste.size() * int(_baum_meshes[art].get_meta("dreiecke"))
		n_mm += 1
	stats["baeume"] = _baeume.size()
	stats["baum_multimeshes"] = n_mm
	stats["baum_dreiecke_alle"] = tris_alle
	stats["baum_dreiecke_je_art"] = [int(_baum_meshes[0].get_meta("dreiecke")), int(_baum_meshes[1].get_meta("dreiecke"))]


## Baeume in Kreisen entfernen: kreise = [Vector3(x_m, z_m, r_m), ...]. Gibt die Zahl entfernter Baeume zurueck.
func baeume_freistellen(kreise: Array) -> int:
	var vorher := _baeume.size()
	var rest: Array = []
	for e in _baeume:
		var o: Vector3 = (e[1] as Transform3D).origin
		var frei := true
		for k: Vector3 in kreise:
			if Vector2(o.x, o.z).distance_squared_to(Vector2(k.x, k.y)) < k.z * k.z:
				frei = false
				break
		if frei:
			rest.append(e)
	_baeume = rest
	if not _baum_meshes.is_empty() and _baum_meshes[0] != null:
		_baeume_chunks()
	return vorher - _baeume.size()
