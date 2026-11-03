extends RefCounted
## Prototyp-Welt Phase 4 (TA): Wasser-Meshes mit world/proto_water.gdshader (= phase2/code_ws_c/water.gdshader, opak).
## Szene in Metern (m_pro_einheit = 1). Prinzip wie water_s7.gd: Wasserflaeche auf DEMSELBEN Knotenraster und derselben
## Dreiecksteilung wie das Gelaende -> Tiefe (COLOR.r = Tiefe / 8 m) pro Pixel exakt, weiche Uferkante ohne Alpha.
##   fluss_mesh: 25-m-Raster, Rinne (Bit 1) + 2 Felder Uferring, Pegel je Feldspalte, Fliessen 0,6 m/s nach Westen
##   steh_mesh:  See/Teich im 5-m-Raster (Feinraster), Fliessvektor 0 -> Teich-Modus (Wellen x 0,45 im Shader)
##   bach_mesh:  Band 5 m entlang proto_bach.json, Tiefe quer 0 -> 0,8 m -> 0, im Muehlteich ausgelassen

const SHADER := preload("res://world/proto_water.gdshader")
const TIEFE_SKALA_M := 8.0
const FLIESS_MS := 0.6


static func _material(ufer_breite: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter("m_pro_einheit", 1.0)
	m.set_shader_parameter("tiefe_skala_m", TIEFE_SKALA_M)
	m.set_shader_parameter("ufer_breite_m", ufer_breite)
	return m


static func _instanz(name: String, v: PackedVector3Array, col: PackedColorArray, uv: PackedVector2Array, idx: PackedInt32Array, mat: ShaderMaterial) -> MeshInstance3D:
	var nm := PackedVector3Array()
	nm.resize(v.size())
	nm.fill(Vector3.UP)
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_NORMAL] = nm
	arr[Mesh.ARRAY_COLOR] = col
	arr[Mesh.ARRAY_TEX_UV] = uv
	arr[Mesh.ARRAY_INDEX] = idx
	var am := ArrayMesh.new()
	if idx.size() > 0:
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = am
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.set_meta("dreiecke", idx.size() / 3)
	return mi


static func fluss_mesh(t) -> MeshInstance3D:
	var gw: int = t.gw
	var gh: int = t.gh
	var M: float = t.M
	# Maske: Rinne + 2 Felder Ring
	var mask := PackedByteArray()
	mask.resize(gw * gh)
	for i in gw * gh:
		mask[i] = 1 if t.fluss[i] & 1 else 0
	for it in 2:
		var nx := mask.duplicate()
		for z in gh:
			for x in gw:
				if mask[z * gw + x]:
					continue
				for dz in range(-1, 2):
					for dx in range(-1, 2):
						var xx := x + dx
						var zz := z + dz
						if xx >= 0 and zz >= 0 and xx < gw and zz < gh and mask[zz * gw + xx] == 1:
							nx[z * gw + x] = 2
		for i in gw * gh:
			if nx[i] == 2:
				nx[i] = 1
		mask = nx
	# Flussmitte je Spalte (fuer die Fliessrichtung)
	var zmit := PackedFloat32Array()
	zmit.resize(gw)
	for x in gw:
		var s := 0.0
		var c := 0
		for z in gh:
			if t.fluss[z * gw + x] & 1:
				s += z
				c += 1
		zmit[x] = (s / c + 0.5) * M + t.oz if c > 0 else NAN
	var v := PackedVector3Array()
	var col := PackedColorArray()
	var uv := PackedVector2Array()
	var idx := PackedInt32Array()
	var vid := {}
	for z in gh:
		for x in gw:
			if mask[z * gw + x] == 0:
				continue
			var q := [Vector2i(x, z), Vector2i(x + 1, z), Vector2i(x, z + 1), Vector2i(x + 1, z + 1)]
			var sicht := false
			for k: Vector2i in q:
				var wx: float = t.ox + k.x * M
				if t.fluss_pegel_at(wx) - t._h(k.x, k.y) > -1.0:
					sicht = true
			if not sicht:
				continue
			var vi: Array[int] = []
			for k: Vector2i in q:
				var key := k.y * (gw + 1) + k.x
				if not vid.has(key):
					vid[key] = v.size()
					var wx2: float = t.ox + k.x * M
					var pg: float = t.fluss_pegel_at(wx2)
					v.append(Vector3(wx2, pg, t.oz + k.y * M))
					col.append(Color(clampf((pg - t._h(k.x, k.y)) / TIEFE_SKALA_M, 0.0, 1.0), 0, 0, 1))
					var c0 := clampi(k.x - 2, 0, gw - 1)
					var c1 := clampi(k.x + 2, 0, gw - 1)
					var dzv := 0.0
					if not is_nan(zmit[c0]) and not is_nan(zmit[c1]):
						dzv = zmit[c0] - zmit[c1]
					uv.append(Vector2(-(c1 - c0) * M, dzv).normalized() * FLIESS_MS)
				vi.append(vid[key])
			idx.append_array([vi[0], vi[1], vi[2], vi[1], vi[3], vi[2]])
	return _instanz("Fluss", v, col, uv, idx, _material(0.35))


## Uferradius mit Rauschen wie tools_proto/ta_export.py (ufer_radius)
static func ufer_radius(g: Dictionary, th: float) -> float:
	var st: float = g["rauschen"]
	if st <= 0.0:
		return g["r"]
	var s: float = g["phase"]
	var k := sin(3.0 * th + 0.7 + s) * 0.035 + sin(5.0 * th + 2.1 + s * 1.3) * 0.025 + sin(8.0 * th + 4.0 + s * 0.4) * 0.012
	return float(g["r"]) * (1.0 + k * st / 0.07)


static func steh_mesh(t, g: Dictionary) -> MeshInstance3D:
	var FM: float = t.FM
	var c: Vector2 = g["mitte"]
	var ra: float = g["r_aussen"]
	var pg: float = g["pegel"]
	var i0 := maxi(int(floor((c.x - ra - t.ox) / FM)), 0)
	var i1 := mini(int(ceil((c.x + ra - t.ox) / FM)), t.fnx - 2)
	var j0 := maxi(int(floor((c.y - ra - t.oz) / FM)), 0)
	var j1 := mini(int(ceil((c.y + ra - t.oz) / FM)), t.fny - 2)
	var v := PackedVector3Array()
	var col := PackedColorArray()
	var uv := PackedVector2Array()
	var idx := PackedInt32Array()
	var vid := {}
	for j in range(j0, j1 + 1):
		for i in range(i0, i1 + 1):
			var q := [Vector2i(i, j), Vector2i(i + 1, j), Vector2i(i, j + 1), Vector2i(i + 1, j + 1)]
			var nass := false
			for k: Vector2i in q:
				if pg - t._fh(k.x, k.y) > 0.0:
					nass = true
			# nur das Gewaesser selbst (Uferlinie + 1 Feinzelle), nicht tiefere Rinnen daneben (Bach am Muehlteich-Damm)
			var mq := Vector2(t.ox + (i + 0.5) * FM, t.oz + (j + 0.5) * FM)
			var re := ufer_radius(g, atan2(mq.y - c.y, mq.x - c.x))
			if not nass or mq.distance_to(c) > re + FM:
				continue
			var vi: Array[int] = []
			for k: Vector2i in q:
				var key: int = k.y * t.fnx + k.x
				if not vid.has(key):
					vid[key] = v.size()
					v.append(Vector3(t.ox + k.x * FM, pg, t.oz + k.y * FM))
					col.append(Color(clampf((pg - t._fh(k.x, k.y)) / TIEFE_SKALA_M, 0.0, 1.0), 0, 0, 1))
					uv.append(Vector2.ZERO)
				vi.append(vid[key])
			idx.append_array([vi[0], vi[1], vi[2], vi[1], vi[3], vi[2]])
	var mi := _instanz(String(g["name"]).capitalize(), v, col, uv, idx, _material(0.3))
	return mi


static func bach_mesh(t, bach: Dictionary) -> MeshInstance3D:
	var pts: Array = bach["punkte"]
	var hw: float = float(bach["breite_m"]) * 0.5
	var tiefe: float = float(bach["tiefe_mitte_m"])
	var fl: float = float(bach.get("fliess_ms", FLIESS_MS))
	var v := PackedVector3Array()
	var col := PackedColorArray()
	var uv := PackedVector2Array()
	var idx := PackedInt32Array()
	var vorher := false
	for i in pts.size():
		var p := Vector2(pts[i][0], pts[i][1])
		var y: float = pts[i][2]
		var aus := int(pts[i][3]) == 1
		# Muendung: im Fluss endet das Band (Flusswasser liegt darueber)
		if t.fluss_bits_at(p.x, p.y) & 1 and t.hoehe_at(p.x, p.y) < t.fluss_pegel_at(p.x) - 0.3:
			aus = true
		if aus:
			vorher = false
			continue
		var a := Vector2(pts[maxi(i - 1, 0)][0], pts[maxi(i - 1, 0)][1])
		var b := Vector2(pts[mini(i + 1, pts.size() - 1)][0], pts[mini(i + 1, pts.size() - 1)][1])
		var tg := (b - a).normalized()
		var qn := Vector2(-tg.y, tg.x)
		for s in [-1.0, 0.0, 1.0]:
			var pp: Vector2 = p + qn * hw * s
			v.append(Vector3(pp.x, y, pp.y))
			col.append(Color((tiefe if s == 0.0 else 0.0) / TIEFE_SKALA_M, 0, 0, 1))
			uv.append(tg * fl)
		if vorher:
			var c := v.size() - 3
			var bb := c - 3
			idx.append_array([bb, c, bb + 1, c, c + 1, bb + 1, bb + 1, c + 1, bb + 2, c + 1, c + 2, bb + 2])
		vorher = true
	return _instanz("Bach", v, col, uv, idx, _material(0.25))
