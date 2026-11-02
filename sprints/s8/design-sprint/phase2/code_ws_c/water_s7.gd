extends RefCounted
## Design Sprint Welt (TEAM-02, Skizze Phase 2): Wasserflächen als EIGENES Mesh über dem Gelände, Material world/water.gdshader.
## Baut auf dem Knotenraster des Geländes (1 Knoten je Feldecke, Szeneneinheiten = Felder, Höhe = m / m_pro_feld) und mit
## derselben Dreiecksteilung wie terrain_s7.gd (a, a+1, a+w / a+1, a+w+1, a+w). Dadurch ist die Tiefe (Spiegel minus
## Gelände) pro Pixel exakt linear und läuft an der Uferlinie auf 0 -> weiche, opake Uferkante ohne Transparenz.
## Vertexdaten: COLOR.r = Tiefe / TIEFE_SKALA_M, UV = Fließvektor (m/s, x/z).
## Kosten: 2 Dreiecke je Wasser- bzw. Uferfeld, 1 Draw Call je Mesh. S7-Fluss: ~1.100 Wasserfelder -> ~4k Dreiecke.

const SHADER := preload("res://world/water.gdshader")
const TIEFE_SKALA_M := 8.0
const RINNE_TIEFE_M := 3.5        # tools/world_gen.py: Rinnenboden = Pegel - 3,5 m
const UFER_RING := 2              # Felder um die Wassermaske, damit die Uferlinie (bei ~ halbe Breite + 8 m) im Mesh liegt
const FLIESS_MS := 0.6            # Fließgeschwindigkeit Fluss (ruhiger Tieflandfluss 0,3-1 m/s)


## Pegel je Feld (Meter) für alle Wasserfelder (fluss Bit 1) + Uferring. Rückgabe: [pegel: PackedFloat32Array (NAN = kein
## Wasser), maske: PackedByteArray]. knoten in Szeneneinheiten, n = grid + 1.
static func fluss_pegel(knoten: PackedFloat32Array, fluss: PackedByteArray, grid: int, m: float) -> Array:
	var n := grid + 1
	var lv := PackedFloat32Array()
	lv.resize(grid * grid)
	lv.fill(NAN)
	# 1) Wasserfeld: tiefster Knoten im 5er-Umkreis + Rinnentiefe = Pegel (Generator gräbt die Rinne auf Pegel - 3,5 m)
	for y in grid:
		for x in grid:
			if fluss[y * grid + x] & 1 == 0:
				continue
			var mn := 1.0e9
			for dy in range(-2, 4):
				for dx in range(-2, 4):
					var xx := clampi(x + dx, 0, n - 1)
					var yy := clampi(y + dy, 0, n - 1)
					mn = minf(mn, knoten[yy * n + xx])
			lv[y * grid + x] = mn * m + RINNE_TIEFE_M
	# 2) glätten entlang des Flusses (3 Durchläufe 3x3 über Wasserfelder)
	for it in 3:
		var nx := lv.duplicate()
		for y in grid:
			for x in grid:
				var i := y * grid + x
				if is_nan(lv[i]):
					continue
				var s := 0.0
				var c := 0
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						var xx := x + dx
						var yy := y + dy
						if xx < 0 or yy < 0 or xx >= grid or yy >= grid:
							continue
						var v := lv[yy * grid + xx]
						if not is_nan(v):
							s += v
							c += 1
				nx[i] = s / c
		lv = nx
	# 3) Uferring: Pegel vom Nachbarn übernehmen (UFER_RING Felder)
	for it in UFER_RING:
		var nx := lv.duplicate()
		for y in grid:
			for x in grid:
				var i := y * grid + x
				if not is_nan(lv[i]):
					continue
				var s := 0.0
				var c := 0
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
					var xx: int = x + d.x
					var yy: int = y + d.y
					if xx < 0 or yy < 0 or xx >= grid or yy >= grid:
						continue
					var v := lv[yy * grid + xx]
					if not is_nan(v):
						s += v
						c += 1
				if c > 0:
					nx[i] = s / c
		lv = nx
	return [lv]


## Mesh aus Pegel je Feld (NAN = kein Wasser). Knotenpegel = Mittel der angrenzenden Wasserfelder.
## Fließvektor: Gefälle des Pegels (abwärts), Länge FLIESS_MS; ohne Gefälle (Teich) 0.
static func baue_mesh(knoten: PackedFloat32Array, lv: PackedFloat32Array, grid: int, m: float, name := "Wasser") -> MeshInstance3D:
	var n := grid + 1
	var vidx := PackedInt32Array()
	vidx.resize(n * n)
	vidx.fill(-1)
	var v := PackedVector3Array()
	var col := PackedColorArray()
	var uv := PackedVector2Array()
	var nm := PackedVector3Array()
	var idx := PackedInt32Array()
	var tri := 0
	for y in grid:
		for x in grid:
			if is_nan(lv[y * grid + x]):
				continue
			# Quad überspringen, wenn alle 4 Ecken > 1 m über dem Spiegel liegen (unsichtbar)
			var corners := [y * n + x, y * n + x + 1, (y + 1) * n + x, (y + 1) * n + x + 1]
			var l0 := lv[y * grid + x]
			var hidden := true
			for k in corners:
				if l0 - knoten[k] * m > -1.0:
					hidden = false
			if hidden:
				continue
			for k in corners:
				if vidx[k] >= 0:
					continue
				var kx: int = k % n
				var ky: int = k / n
				var s := 0.0
				var c := 0
				for d in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 0)]:
					var cx: int = kx + d.x
					var cy: int = ky + d.y
					if cx < 0 or cy < 0 or cx >= grid or cy >= grid:
						continue
					var w := lv[cy * grid + cx]
					if not is_nan(w):
						s += w
						c += 1
				var pegel := s / c
				var tiefe := pegel - knoten[k] * m
				vidx[k] = v.size()
				v.append(Vector3(kx, pegel / m, ky))
				nm.append(Vector3.UP)
				col.append(Color(clampf(tiefe / TIEFE_SKALA_M, 0.0, 1.0), 0.0, 0.0, 1.0))
				uv.append(_fliess(lv, grid, clampi(kx, 0, grid - 1), clampi(ky, 0, grid - 1)))
			var a: int = vidx[corners[0]]
			var b: int = vidx[corners[1]]
			var c2: int = vidx[corners[2]]
			var d2: int = vidx[corners[3]]
			idx.append_array([a, b, c2, b, d2, c2])
			tri += 2
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
	mi.mesh = am
	mi.name = name
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("m_pro_einheit", m)
	mat.set_shader_parameter("tiefe_skala_m", TIEFE_SKALA_M)
	mi.material_override = mat
	mi.set_meta("dreiecke", tri)
	return mi


static func _fliess(lv: PackedFloat32Array, grid: int, x: int, y: int) -> Vector2:
	var c := lv[y * grid + x]
	if is_nan(c):
		return Vector2.ZERO
	var gx := 0.0
	var gy := 0.0
	var xl := lv[y * grid + maxi(x - 3, 0)]
	var xr := lv[y * grid + mini(x + 3, grid - 1)]
	var yu := lv[maxi(y - 3, 0) * grid + x]
	var yd := lv[mini(y + 3, grid - 1) * grid + x]
	if not is_nan(xl) and not is_nan(xr):
		gx = xr - xl
	if not is_nan(yu) and not is_nan(yd):
		gy = yd - yu
	var g := Vector2(-gx, -gy)
	if g.length() < 0.02:
		return Vector2.ZERO
	return g.normalized() * FLIESS_MS


## Bach als Band (8-12 m breit) entlang einer Punktliste (Szeneneinheiten x/z), Höhe = Gelände + 0,3 m.
## Tiefe quer: Rand 0, Mitte tiefe_mitte_m -> gleiche weiche Kante wie der Fluss. Nicht in die Heightmap gegraben.
static func baue_bach(punkte: PackedVector2Array, hoehe: Callable, breite_m: float, m: float, tiefe_mitte_m := 0.8) -> MeshInstance3D:
	var v := PackedVector3Array()
	var col := PackedColorArray()
	var uv := PackedVector2Array()
	var nm := PackedVector3Array()
	var idx := PackedInt32Array()
	var hw := breite_m * 0.5 / m
	for i in punkte.size():
		var p := punkte[i]
		var t := (punkte[mini(i + 1, punkte.size() - 1)] - punkte[maxi(i - 1, 0)]).normalized()
		var q := Vector2(-t.y, t.x)
		for s in [-1.0, 0.0, 1.0]:
			var pp: Vector2 = p + q * hw * s
			v.append(Vector3(pp.x, float(hoehe.call(pp.x, pp.y)) + 0.3 / m, pp.y))
			nm.append(Vector3.UP)
			col.append(Color((tiefe_mitte_m if s == 0.0 else 0.0) / TIEFE_SKALA_M, 0, 0, 1))
			uv.append(t * 0.9)
		if i > 0:
			var b := (i - 1) * 3
			var c := i * 3
			idx.append_array([b, c, b + 1, c, c + 1, b + 1, b + 1, c + 1, b + 2, c + 1, c + 2, b + 2])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_NORMAL] = nm
	arr[Mesh.ARRAY_COLOR] = col
	arr[Mesh.ARRAY_TEX_UV] = uv
	arr[Mesh.ARRAY_INDEX] = idx
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mi := MeshInstance3D.new()
	mi.mesh = am
	mi.name = "Bach"
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("m_pro_einheit", m)
	mat.set_shader_parameter("tiefe_skala_m", TIEFE_SKALA_M)
	mat.set_shader_parameter("ufer_breite_m", 0.25)
	mi.material_override = mat
	mi.set_meta("dreiecke", idx.size() / 3)
	return mi
