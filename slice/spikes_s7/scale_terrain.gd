extends Node3D
## SP-03 Spike (Sophie, S7-Vorbereitung): Maßstab, Terrain, Kartenrand. NUR Darstellung, keine Sim-Anbindung.
## Einheit: 1 Godot-Einheit = 1 m. Spielbare Fläche 12,8 km (512 Felder × 25 m, Vorschlag), Rand 7,5 km je Seite.
## Achsen wie Slice: X = Ost, Z = Süd, Ursprung = NW-Ecke der spielbaren Fläche.

const L := 12800.0          # spielbare Kantenlänge [m]
const STEP := 25.0          # Heightmap-Raster innen [m] (= vorgeschlagenes Sim-Feld)
const N := 513              # Stützpunkte je Kante innen
const CHUNK := 64           # Zellen je Terrain-Chunk innen (8×8 Chunks)
const B := 7500.0           # Außenrand je Seite [m]
const OSTEP := 100.0        # Raster Außenrand [m]
const D_MIN := 40.0         # Kamera-Abstand min [m]
const D_MAX := 5600.0       # Kamera-Abstand max [m]
const P_NEAR := 36.0        # Neigung nah [°]
const P_FAR := 62.0         # Neigung fern [°]
const FOV := 50.0

const CITY_C := Vector2(7400, 6200)
const CITY_R := 450.0       # Kleinstadt (2.500 EW)
const CITY_ANG := 12.0
const GRID_P := 72.0        # Rasterabstand Straße-Straße (Block 60 m + Straße 12 m)
const ROAD_W := 12.0        # Stadtstraße inkl. Gehweg (Kenney-Kachel × 12)
const SUB_S := 9.0          # Kenney Suburban → EFH ~12×9 m, 7–10 m hoch
const COM_S := 9.0          # Kenney Commercial → 8–19 m breit, 8–15 m hoch
const IND_S := 10.0
const NAT_S := 8.0

const MINE_P := Vector2(4450, 4300)
const FARM_P := Vector2(9550, 7700)

var hf := PackedFloat32Array()
var sw := PackedFloat32Array()     # Stempel-Gewicht (Trassen)
var sh := PackedFloat32Array()     # Stempel-Höhe
var n_hills := FastNoiseLite.new()
var n_ridge := FastNoiseLite.new()
var n_ridge2 := FastNoiseLite.new()
var n_det := FastNoiseLite.new()
var n_forest := FastNoiseLite.new()
var n_city := FastNoiseLite.new()
var city_h := 0.0
var pads: Array = []               # [Mittelpunkt, Radius, Höhe] für Trassen-Anschluss
var rng := RandomNumberGenerator.new()

var track_pts := PackedVector2Array()
var track_h := PackedFloat32Array()
var roads: Array = []             # [[pts, hs], ...]
var stats := {"verts": 0, "tris": 0, "instances": 0, "mmi": 0}

var cam: Camera3D
var sun: DirectionalLight3D
var env: Environment
var target := Vector3(CITY_C.x, 0, CITY_C.y)
var yaw := 0.0
var dist := 1600.0
var pitch_override := -1.0
var gen_ms := 0


func _ready() -> void:
	var t0 := Time.get_ticks_msec()
	rng.seed = 7
	_setup_noise()
	_build_heights()
	_setup_env()
	_build_terrain_inner()
	_build_terrain_outer()
	_build_river()
	_build_track_visual()
	for r in roads:
		_build_road_ribbon(r[0], r[1], 7.5)
	var lots: Array = _build_city()
	_build_edge_houses(lots)
	_build_station()
	_build_mine()
	_build_farm()
	_build_trees()
	_labels()
	_setup_camera()
	gen_ms = Time.get_ticks_msec() - t0
	print("SP03 gen_ms=%d verts=%d tris=%d instances=%d mmi=%d" % [gen_ms, stats["verts"], stats["tris"], stats["instances"], stats["mmi"]])


# ---------------------------------------------------------------- Höhen

func _setup_noise() -> void:
	n_hills.seed = 11
	n_hills.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n_hills.frequency = 1.0 / 2600.0
	n_hills.fractal_octaves = 4
	n_ridge.seed = 23
	n_ridge.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n_ridge.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	n_ridge.frequency = 1.0 / 1900.0
	n_ridge.fractal_octaves = 5
	n_ridge2.seed = 5
	n_ridge2.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n_ridge2.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	n_ridge2.frequency = 1.0 / 2400.0
	n_ridge2.fractal_octaves = 5
	n_det.seed = 3
	n_det.frequency = 1.0 / 420.0
	n_det.fractal_octaves = 3
	n_forest.seed = 9
	n_forest.frequency = 1.0 / 950.0
	n_forest.fractal_octaves = 3
	n_city.seed = 4
	n_city.frequency = 0.35


func river_x(z: float) -> float:
	return 7600.0 + 900.0 * sin(z / 2300.0) + 400.0 * sin(z / 870.0 + 1.0)


func river_dx(z: float) -> float:
	return 900.0 / 2300.0 * cos(z / 2300.0) + 400.0 / 870.0 * cos(z / 870.0 + 1.0)


func river_dist(x: float, z: float) -> float:
	var dx := river_dx(z)
	return absf(x - river_x(z)) / sqrt(1.0 + dx * dx)


func river_level(z: float) -> float:
	return 46.0 - z * 0.0014


func _carve(h: float, x: float, z: float) -> float:
	var d := river_dist(x, z)
	var c := 1.0 - smoothstep(12.0, 34.0, d)
	return lerpf(h, river_level(z) - 3.5, c)


func base_h(x: float, z: float) -> float:
	var h := 70.0 + n_hills.get_noise_2d(x, z) * 55.0
	var mn := 1.0 - smoothstep(1200.0, 5200.0, Vector2(x - 2300.0, z - 2100.0).length())
	var r := n_ridge.get_noise_2d(x, z) * 0.5 + 0.5
	h += mn * (150.0 + pow(r, 1.6) * 820.0)
	var ox := maxf(0.0, maxf(-x, x - L))
	var oz := maxf(0.0, maxf(-z, z - L))
	var o := sqrt(ox * ox + oz * oz)
	var mb := smoothstep(300.0, 5200.0, o)
	if mb > 0.0:
		var r2 := n_ridge2.get_noise_2d(x, z) * 0.5 + 0.5
		h += mb * (250.0 + pow(r2, 1.4) * 1150.0)
	var d := river_dist(x, z)
	var lv := river_level(z)
	var bank := lv + 3.0 + d * 0.012
	h = lerpf(bank, h, smoothstep(150.0, 1500.0, d))
	h = maxf(h, lv + 1.5)
	return _carve(h, x, z)


func hi(ix: int, iz: int) -> float:
	return hf[clampi(iz, 0, N - 1) * N + clampi(ix, 0, N - 1)]


func hget(x: float, z: float) -> float:
	if x < 0.0 or z < 0.0 or x > L or z > L:
		return base_h(x, z)
	var fx := x / STEP
	var fz := z / STEP
	var ix := int(floor(fx))
	var iz := int(floor(fz))
	var tx := fx - ix
	var tz := fz - iz
	var a := lerpf(hi(ix, iz), hi(ix + 1, iz), tx)
	var b := lerpf(hi(ix, iz + 1), hi(ix + 1, iz + 1), tx)
	return lerpf(a, b, tz)


func _rot(v: Vector2) -> Vector2:
	return v.rotated(deg_to_rad(CITY_ANG))


func city_pt(u: float, v: float) -> Vector2:
	return CITY_C + _rot(Vector2(u, v))


func _flatten(c: Vector2, r_in: float, r_out: float, level: float) -> void:
	var i0 := maxi(0, int((c.x - r_out) / STEP))
	var i1 := mini(N - 1, int((c.x + r_out) / STEP) + 1)
	var j0 := maxi(0, int((c.y - r_out) / STEP))
	var j1 := mini(N - 1, int((c.y + r_out) / STEP) + 1)
	for j in range(j0, j1 + 1):
		for i in range(i0, i1 + 1):
			var d := Vector2(i * STEP, j * STEP).distance_to(c)
			var w := 1.0 - smoothstep(r_in, r_out, d)
			if w > 0.0:
				hf[j * N + i] = lerpf(hf[j * N + i], level, w)


func _catmull(ctrl: PackedVector2Array, spacing: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in ctrl.size() - 1:
		var p0 := ctrl[maxi(k - 1, 0)]
		var p1 := ctrl[k]
		var p2 := ctrl[k + 1]
		var p3 := ctrl[mini(k + 2, ctrl.size() - 1)]
		var n := maxi(1, int(p1.distance_to(p2) / spacing))
		for s in n:
			var t := float(s) / n
			var t2 := t * t
			var t3 := t2 * t
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	out.append(ctrl[ctrl.size() - 1])
	return out


func _smooth(a: PackedFloat32Array, win: int) -> PackedFloat32Array:
	var o := PackedFloat32Array()
	o.resize(a.size())
	for i in a.size():
		var s := 0.0
		var c := 0
		for k in range(maxi(0, i - win), mini(a.size(), i + win + 1)):
			s += a[k]
			c += 1
		o[i] = s / c
	return o


func _path_heights(pts: PackedVector2Array, clearance: float) -> PackedFloat32Array:
	var h := PackedFloat32Array()
	for p in pts:
		h.append(hget(p.x, p.y))
	h = _smooth(_smooth(h, 30), 30)
	for i in pts.size():
		for pad in pads:
			var w := 1.0 - smoothstep(pad[1] * 0.6, pad[1] * 1.6, pts[i].distance_to(pad[0]))
			h[i] = lerpf(h[i], pad[2], w)
		var p := pts[i]
		if river_dist(p.x, p.y) < 70.0:
			h[i] = maxf(h[i], river_level(p.y) + clearance)
	return _smooth(h, 8)


func _stamp(pts: PackedVector2Array, hs: PackedFloat32Array, r_in: float, r_out: float) -> void:
	for k in pts.size():
		var c := pts[k]
		var i0 := maxi(0, int((c.x - r_out) / STEP))
		var i1 := mini(N - 1, int((c.x + r_out) / STEP) + 1)
		var j0 := maxi(0, int((c.y - r_out) / STEP))
		var j1 := mini(N - 1, int((c.y + r_out) / STEP) + 1)
		for j in range(j0, j1 + 1):
			for i in range(i0, i1 + 1):
				var d := Vector2(i * STEP, j * STEP).distance_to(c)
				var w := 1.0 - smoothstep(r_in, r_out, d)
				var id := j * N + i
				if w > sw[id]:
					sw[id] = w
					sh[id] = hs[k]


func _build_heights() -> void:
	hf.resize(N * N)
	sw.resize(N * N)
	sh.resize(N * N)
	for j in N:
		for i in N:
			hf[j * N + i] = base_h(i * STEP, j * STEP)
	city_h = hget(CITY_C.x, CITY_C.y)
	_flatten(CITY_C, CITY_R + 80.0, CITY_R + 450.0, city_h)
	var mh := hget(MINE_P.x, MINE_P.y)
	_flatten(MINE_P, 140.0, 320.0, mh)
	var fh := hget(FARM_P.x + 250, FARM_P.y + 200)
	_flatten(FARM_P + Vector2(250, 200), 380.0, 650.0, fh)
	pads = [[CITY_C, CITY_R + 80.0, city_h], [MINE_P, 140.0, mh], [FARM_P + Vector2(250, 200), 380.0, fh]]
	# Gleis: Mine → Bahnhof (Stadtsüdrand, parallel zum Raster) → Fluss → Osten aus der Karte
	var st_w := city_pt(-300, 510)
	var st_e := city_pt(300, 510)
	track_pts = _catmull(PackedVector2Array([MINE_P + Vector2(60, 40), Vector2(5200, 5250), Vector2(6150, 6150),
		st_w + _rot(Vector2(-300, 0)), st_w, st_e, st_e + _rot(Vector2(300, 0)), Vector2(9000, 7000), Vector2(10500, 7330), Vector2(L + 50, 7700)]), 10.0)
	track_h = _path_heights(track_pts, 9.0)
	var r_e := _catmull(PackedVector2Array([city_pt(504, 0), Vector2(8300, 6420), Vector2(8900, 6720), Vector2(9400, 7300), FARM_P + Vector2(-20, -40)]), 10.0)
	var r_w := _catmull(PackedVector2Array([city_pt(-504, 0), Vector2(6200, 5900), Vector2(5300, 5000), MINE_P + Vector2(80, -60)]), 10.0)
	var r_n := _catmull(PackedVector2Array([city_pt(0, -504), Vector2(7300, 4500), Vector2(6900, 2800), Vector2(6500, -50)]), 10.0)
	for pts in [r_e, r_w, r_n]:
		roads.append([pts, _path_heights(pts, 7.0)])
	_stamp(track_pts, track_h, 10.0, 55.0)
	for r in roads:
		_stamp(r[0], r[1], 10.0, 50.0)
	for id in N * N:
		if sw[id] > 0.0:
			hf[id] = lerpf(hf[id], sh[id], sw[id])
	for j in N:
		for i in N:
			hf[j * N + i] = _carve(hf[j * N + i], i * STEP, j * STEP)


# ---------------------------------------------------------------- Terrain-Meshes

func _color_at(x: float, z: float, h: float, ny: float, inner: bool) -> Color:
	var dv := n_det.get_noise_2d(x, z)
	var dv2 := n_hills.get_noise_2d(x * 3.1 + 500.0, z * 3.1)
	var c := Color(0.32, 0.42, 0.20).lerp(Color(0.50, 0.49, 0.28), clampf(dv * 1.2 + dv2 * 0.6 + 0.3, 0.0, 1.0))
	var rd := river_dist(x, z)
	if rd < 700.0:
		c = c.lerp(Color(0.36, 0.50, 0.24), (1.0 - rd / 700.0) * 0.6)
	var fw := smoothstep(0.08, 0.20, _forest(x, z, h, ny))
	if fw > 0.0:
		c = c.lerp(Color(0.17, 0.27, 0.12).lerp(Color(0.23, 0.32, 0.15), dv * 0.5 + 0.5), fw)
	var rock := smoothstep(0.86, 0.70, ny) + smoothstep(600.0, 1000.0, h) * 0.5
	c = c.lerp(Color(0.47, 0.44, 0.40).lerp(Color(0.56, 0.53, 0.49), dv * 0.5 + 0.5), clampf(rock, 0.0, 1.0))
	if h > 980.0 + dv * 150.0 and ny > 0.62:
		c = c.lerp(Color(0.90, 0.91, 0.93), smoothstep(980.0, 1150.0, h + dv * 150.0))
	if rd < 42.0:
		c = c.lerp(Color(0.55, 0.50, 0.40), 0.7)
	if inner:
		var cd := Vector2(x, z).distance_to(CITY_C)
		if cd < CITY_R + 60.0:
			c = c.lerp(Color(0.47, 0.46, 0.38), 0.6 * (1.0 - smoothstep(CITY_R - 100.0, CITY_R + 60.0, cd)))
		var ix := clampi(int(round(x / STEP)), 0, N - 1)
		var iz := clampi(int(round(z / STEP)), 0, N - 1)
		var w := sw[iz * N + ix]
		if w > 0.6:
			c = c.lerp(Color(0.55, 0.52, 0.42), 0.35)   # Böschung
	return c


func _forest(x: float, z: float, h: float, ny: float) -> float:
	var f := n_forest.get_noise_2d(x, z)
	if f < 0.08 or ny < 0.78 or h > 880.0:
		return 0.0
	if Vector2(x, z).distance_to(CITY_C) < CITY_R + 250.0:
		return 0.0
	if Vector2(x, z).distance_to(MINE_P) < 330.0:
		return 0.0
	var fr := Rect2(FARM_P - Vector2(200, 150), Vector2(1100, 800))
	if fr.has_point(Vector2(x, z)):
		return 0.0
	if river_dist(x, z) < 70.0:
		return 0.0
	return f


func _mat_vc() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	m.roughness = 1.0
	return m


func _add_mesh(arrays: Array, mat: Material, shadow: bool) -> MeshInstance3D:
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	am.surface_set_material(0, mat)
	var mi := MeshInstance3D.new()
	mi.mesh = am
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	stats["verts"] += (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	stats["tris"] += (arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
	return mi


func _grid_arrays(x0: float, z0: float, cells: int, step: float, hfun: Callable, inner: bool, skirt: Dictionary) -> Array:
	var v := PackedVector3Array()
	var nm := PackedVector3Array()
	var col := PackedColorArray()
	var idx := PackedInt32Array()
	var n := cells + 1
	for j in n:
		for i in n:
			var x := x0 + i * step
			var z := z0 + j * step
			var h: float = hfun.call(x, z)
			var hx: float = hfun.call(x + step, z) - hfun.call(x - step, z)
			var hz: float = hfun.call(x, z + step) - hfun.call(x, z - step)
			var nn := Vector3(-hx, 2.0 * step, -hz).normalized()
			v.append(Vector3(x, h, z))
			nm.append(nn)
			col.append(_color_at(x, z, h, nn.y, inner))
	for j in cells:
		for i in cells:
			var a := j * n + i
			idx.append_array([a, a + 1, a + n, a + 1, a + n + 1, a + n])
	# Schürzen an Kartenrand-Kanten (gegen Risse zum gröberen Außenraster)
	for side in skirt.keys():
		var ids: Array = []
		for k in n:
			match side:
				"n": ids.append(k)
				"s": ids.append(cells * n + k)
				"w": ids.append(k * n)
				"e": ids.append(k * n + cells)
		var base := v.size()
		for id in ids:
			v.append(v[id] - Vector3(0, 30, 0))
			nm.append(nm[id])
			col.append(col[id])
		for k in n - 1:
			var a: int = ids[k]
			var b: int = ids[k + 1]
			idx.append_array([a, b, base + k, b, base + k + 1, base + k])
			idx.append_array([a, base + k, b, b, base + k, base + k + 1])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_NORMAL] = nm
	arr[Mesh.ARRAY_COLOR] = col
	arr[Mesh.ARRAY_INDEX] = idx
	return arr


func _build_terrain_inner() -> void:
	var mat := _mat_vc()
	var nc := (N - 1) / CHUNK
	for cj in nc:
		for ci in nc:
			var sk := {}
			if cj == 0: sk["n"] = true
			if cj == nc - 1: sk["s"] = true
			if ci == 0: sk["w"] = true
			if ci == nc - 1: sk["e"] = true
			_add_mesh(_grid_arrays(ci * CHUNK * STEP, cj * CHUNK * STEP, CHUNK, STEP, hget, true, sk), mat, false)


func _outer_h(x: float, z: float) -> float:
	var inside := x > 0.5 and z > 0.5 and x < L - 0.5 and z < L - 0.5
	return hget(x, z) - (6.0 if inside else 0.0)


func _build_terrain_outer() -> void:
	var cells := int((L + 2.0 * B) / OSTEP)
	var half := cells / 2
	var mat := _mat_vc()
	# 4 Kacheln, damit Frustum-Culling greift
	for q in 4:
		var qi := q % 2
		var qj := q / 2
		_add_mesh(_grid_arrays(-B + qi * half * OSTEP, -B + qj * half * OSTEP, half, OSTEP, _outer_h, false, {}), mat, false)


func _ribbon(pts: PackedVector2Array, hs: PackedFloat32Array, half_l: float, half_r: float, lift: float, c: Color, out: Array) -> void:
	var v: PackedVector3Array = out[0]
	var col: PackedColorArray = out[1]
	var idx: PackedInt32Array = out[2]
	var base := v.size()
	for i in pts.size():
		var d := (pts[mini(i + 1, pts.size() - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var nrm := Vector2(-d.y, d.x)
		var a := pts[i] + nrm * half_l
		var b := pts[i] + nrm * half_r
		v.append(Vector3(a.x, hs[i] + lift, a.y))
		v.append(Vector3(b.x, hs[i] + lift, b.y))
		col.append(c)
		col.append(c)
		if i > 0:
			var k := base + (i - 1) * 2
			idx.append_array([k, k + 2, k + 1, k + 1, k + 2, k + 3])


func _flush_ribbons(out: Array, mat: Material) -> void:
	var v: PackedVector3Array = out[0]
	var nm := PackedVector3Array()
	nm.resize(v.size())
	nm.fill(Vector3.UP)
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_NORMAL] = nm
	arr[Mesh.ARRAY_COLOR] = out[1]
	arr[Mesh.ARRAY_INDEX] = out[2]
	_add_mesh(arr, mat, false)


func _build_river() -> void:
	var pts := PackedVector2Array()
	var hs := PackedFloat32Array()
	var z := -B
	while z <= L + B:
		pts.append(Vector2(river_x(z), z))
		hs.append(river_level(z) - 0.8)
		z += 25.0
	var out := [PackedVector3Array(), PackedColorArray(), PackedInt32Array()]
	_ribbon(pts, hs, -24.0, 24.0, 0.0, Color(0.23, 0.36, 0.42), out)
	var m := _mat_vc()
	m.roughness = 0.15
	m.metallic_specular = 0.8
	_flush_ribbons(out, m)


func _build_track_visual() -> void:
	var out := [PackedVector3Array(), PackedColorArray(), PackedInt32Array()]
	_ribbon(track_pts, track_h, -2.6, 2.6, 0.05, Color(0.50, 0.46, 0.40), out)     # Schotter 5,2 m Fuß
	_ribbon(track_pts, track_h, -1.9, 1.9, 0.35, Color(0.42, 0.39, 0.35), out)     # Krone ~3,8 m
	_ribbon(track_pts, track_h, -0.80, -0.65, 0.55, Color(0.22, 0.20, 0.19), out)  # Schienen, Spur 1,435 m
	_ribbon(track_pts, track_h, 0.65, 0.80, 0.55, Color(0.22, 0.20, 0.19), out)
	_flush_ribbons(out, _mat_vc())
	# Schwellen (MultiMesh, nur nah sichtbar)
	var tf: Array = []
	var acc := 0.0
	for i in range(1, track_pts.size()):
		acc += track_pts[i].distance_to(track_pts[i - 1])
		var d := (track_pts[i] - track_pts[i - 1]).normalized()
		while acc >= 1.2:
			acc -= 1.2
			var p := track_pts[i] - d * acc
			var b := Basis(Vector3.UP, atan2(d.x, d.y))
			tf.append(Transform3D(b, Vector3(p.x, track_h[i] + 0.42, p.y)))
	var mm := _multimesh(_box(Vector3(2.6, 0.16, 0.25)), tf, [], Color(0.33, 0.27, 0.22), false)
	mm.visibility_range_end = 900.0
	_bridges(track_pts, track_h, 6.0)


func _bridges(pts: PackedVector2Array, hs: PackedFloat32Array, w: float) -> void:
	var tf: Array = []
	var deck: Array = []
	var acc := 0.0
	for i in range(1, pts.size()):
		var g := hget(pts[i].x, pts[i].y)
		if hs[i] - g > 2.5:
			var d := (pts[i] - pts[i - 1]).normalized()
			var b := Basis(Vector3.UP, atan2(d.x, d.y))
			deck.append(Transform3D(b * Basis.from_scale(Vector3(w, 1.0, 10.4)), Vector3(pts[i].x, hs[i] - 0.4, pts[i].y)))
			acc += 10.0
			if acc >= 30.0:
				acc = 0.0
				var hh := hs[i] - g + 4.0
				tf.append(Transform3D(b * Basis.from_scale(Vector3(w * 0.7, hh, 2.0)), Vector3(pts[i].x, g - 4.0 + hh * 0.5, pts[i].y)))
	if deck.size() > 0:
		_multimesh(_box(Vector3.ONE * Vector3(1, 1.2, 1)), deck, [], Color(0.55, 0.53, 0.50), true)
	if tf.size() > 0:
		_multimesh(_box(Vector3.ONE), tf, [], Color(0.60, 0.58, 0.55), true)


func _build_road_ribbon(pts: PackedVector2Array, hs: PackedFloat32Array, w: float) -> void:
	var out := [PackedVector3Array(), PackedColorArray(), PackedInt32Array()]
	_ribbon(pts, hs, -w * 0.5 - 1.2, w * 0.5 + 1.2, 0.10, Color(0.52, 0.49, 0.42), out)  # Bankett
	_ribbon(pts, hs, -w * 0.5, w * 0.5, 0.30, Color(0.27, 0.27, 0.28), out)             # Asphalt
	_ribbon(pts, hs, -w * 0.5 + 0.3, -w * 0.5 + 0.5, 0.33, Color(0.80, 0.80, 0.78), out) # Randlinie
	_ribbon(pts, hs, w * 0.5 - 0.5, w * 0.5 - 0.3, 0.33, Color(0.80, 0.80, 0.78), out)
	_flush_ribbons(out, _mat_vc())
	_bridges(pts, hs, w + 1.0)


# ---------------------------------------------------------------- Assets

var _mesh_cache := {}

func _load_mesh(path: String) -> Array:
	if _mesh_cache.has(path):
		return _mesh_cache[path]
	var res: Array = [null, Transform3D(), AABB()]
	var ps := load(path) as PackedScene
	if ps != null:
		var root := ps.instantiate()
		var found: Array = []
		_find_meshes(root, Transform3D(), found)
		if found.size() > 0:
			res = [found[0][0], found[0][1], (found[0][1] as Transform3D) * (found[0][0] as Mesh).get_aabb()]
			if found.size() > 1:
				push_warning("SP03: %s hat %d Meshes, nur erstes genutzt" % [path, found.size()])
		root.free()
	_mesh_cache[path] = res
	return res


func _find_meshes(n: Node, xf: Transform3D, out: Array) -> void:
	var t := xf
	if n is Node3D:
		t = xf * (n as Node3D).transform
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		out.append([(n as MeshInstance3D).mesh, t])
	for c in n.get_children():
		_find_meshes(c, t, out)


func _box(s: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = s
	return b


func _multimesh(mesh: Mesh, tfs: Array, cols: Array, tint: Color, shadow: bool) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = cols.size() > 0
	mm.mesh = mesh
	mm.instance_count = tfs.size()
	for i in tfs.size():
		mm.set_instance_transform(i, tfs[i])
		if cols.size() > 0:
			mm.set_instance_color(i, cols[i])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	if mesh is PrimitiveMesh:
		var m := StandardMaterial3D.new()
		m.albedo_color = tint
		m.roughness = 1.0
		if cols.size() > 0:
			m.vertex_color_use_as_albedo = true
		mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	stats["instances"] += tfs.size()
	stats["mmi"] += 1
	var tri := 0
	for s in mesh.get_surface_count():
		var a := mesh.surface_get_arrays(s)
		var ix = a[Mesh.ARRAY_INDEX]
		tri += (ix.size() if ix != null else (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
	stats["tris"] += tri * tfs.size()
	return mi


const KIT_SHADER := """
shader_type spatial;
render_mode cull_back;
uniform sampler2D tex : source_color, filter_linear_mipmap;
uniform vec3 tint = vec3(1.0);
uniform vec3 roof = vec3(0.56, 0.24, 0.17);
uniform float remap = 1.0;
void fragment() {
	vec3 c = texture(tex, UV).rgb;
	float teal = remap * smoothstep(0.04, 0.20, min(c.g, c.b) - c.r);
	float lum = dot(c, vec3(0.3, 0.5, 0.2));
	ALBEDO = mix(c * tint, roof * (0.5 + lum), teal);
	ROUGHNESS = 0.92;
}
"""
var _kit_shader: Shader
var _kit_mats := {}

## Palette-Umlegung für Kenney-Stadtkits: Türkis-Dächer → Ziegelrot, Weiß → warmer Putz, Straßen dunkler.
func _kit_mat(mesh: Mesh, path: String) -> Material:
	var src := mesh.surface_get_material(0)
	if not (src is StandardMaterial3D) or (src as StandardMaterial3D).albedo_texture == null:
		return null
	var tex := (src as StandardMaterial3D).albedo_texture
	var tint := Vector3(0.88, 0.84, 0.78)
	if path.contains("/roads/"):
		tint = Vector3(0.62, 0.60, 0.57)
	elif path.contains("tree"):
		tint = Vector3(0.55, 0.75, 0.42)
	elif path.contains("/com/"):
		tint = Vector3(0.86, 0.80, 0.72)
	var key := str(tex.get_rid()) + str(tint)
	if _kit_mats.has(key):
		return _kit_mats[key]
	if _kit_shader == null:
		_kit_shader = Shader.new()
		_kit_shader.code = KIT_SHADER
	var sm := ShaderMaterial.new()
	sm.shader = _kit_shader
	sm.set_shader_parameter("tex", tex)
	sm.set_shader_parameter("tint", tint)
	sm.set_shader_parameter("remap", 0.0 if (path.contains("/roads/") or path.contains("tree")) else 1.0)
	_kit_mats[key] = sm
	return sm


## Gruppiert Instanzen nach Modellpfad und legt je Modell ein MultiMesh an.
func _place_models(items: Array, shadow: bool, vis_end: float) -> void:
	var groups := {}
	for it in items:
		var p: String = it[0]
		if not groups.has(p):
			groups[p] = []
		groups[p].append(it[1])
	for p in groups.keys():
		var m := _load_mesh(p)
		if m[0] == null:
			continue
		var tfs: Array = []
		for t in groups[p]:
			tfs.append((t as Transform3D) * (m[1] as Transform3D))
		var mi := _multimesh(m[0], tfs, [], Color.WHITE, shadow)
		if (m[0] as Mesh).get_surface_count() == 1:
			var km := _kit_mat(m[0], p)
			if km != null:
				mi.material_override = km
		if vis_end > 0.0:
			mi.visibility_range_end = vis_end


func _xf(p: Vector2, y: float, yaw_rad: float, s: float) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, yaw_rad).scaled(Vector3(s, s, s)), Vector3(p.x, y, p.y))


# ---------------------------------------------------------------- Stadt

const SUB := ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u"]
const COM := ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k"]

var _road_open := {}

func _tile_open(path: String) -> Array:
	## Offene Seiten einer Kenney-Straßenkachel aus der Geometrie: Seite mit durchgehendem Bordstein = zu.
	if _road_open.has(path):
		return _road_open[path]
	var m := _load_mesh(path)
	var mesh: Mesh = m[0]
	var tris: Array = []
	for si in mesh.get_surface_count():
		var arr := mesh.surface_get_arrays(si)
		var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var ix = arr[Mesh.ARRAY_INDEX]
		var cnt: int = ix.size() if ix != null else vs.size()
		for t in range(0, cnt, 3):
			var i0: int = ix[t] if ix != null else t
			var i1: int = ix[t + 1] if ix != null else t + 1
			var i2: int = ix[t + 2] if ix != null else t + 2
			tris.append([vs[i0], vs[i1], vs[i2]])
	var open: Array = []
	for k in ["+x", "-x", "+z", "-z"]:
		var q := Vector2(0.46, 0.0)
		match k:
			"-x": q = Vector2(-0.46, 0.0)
			"+z": q = Vector2(0.0, 0.46)
			"-z": q = Vector2(0.0, -0.46)
		var ymax := -1.0
		for tr in tris:
			var a2 := Vector2(tr[0].x, tr[0].z)
			var b2 := Vector2(tr[1].x, tr[1].z)
			var c2 := Vector2(tr[2].x, tr[2].z)
			if Geometry2D.point_is_inside_triangle(q, a2, b2, c2):
				ymax = maxf(ymax, maxf(tr[0].y, maxf(tr[1].y, tr[2].y)))
		if ymax < 0.016:
			open.append(k)
	print("SP03 tile ", path.get_file(), " open=", open)
	_road_open[path] = open
	return open


func _dir_key(d: Vector2) -> String:
	if absf(d.x) > absf(d.y):
		return "+x" if d.x > 0 else "-x"
	return "+z" if d.y > 0 else "-z"


func _road_tile(node_p: Vector2, need: Array) -> Array:
	## need: Liste Richtungen im Stadtraster ("+x"...), Rückgabe [pfad, yaw_lokal]
	var cands := ["road-crossroad", "road-intersection", "road-straight", "road-bend-square", "road-end"]
	for c in cands:
		var path := "res://spikes_s7/assets/roads/%s.glb" % c
		var open := _tile_open(path)
		if open.size() != need.size():
			continue
		for k in 4:
			var ang := k * PI * 0.5
			var ok := true
			for o in open:
				var dv := Vector2.ZERO
				match o:
					"+x": dv = Vector2(1, 0)
					"-x": dv = Vector2(-1, 0)
					"+z": dv = Vector2(0, 1)
					"-z": dv = Vector2(0, -1)
				# Basis(UP, a) dreht (x,z) → (x cos a + z sin a, −x sin a + z cos a)
				var r := Vector2(dv.x * cos(ang) + dv.y * sin(ang), -dv.x * sin(ang) + dv.y * cos(ang))
				if not need.has(_dir_key(r)):
					ok = false
			if ok:
				return [path, ang]
	return ["res://spikes_s7/assets/roads/road-square.glb", 0.0]


func _build_city() -> Array:
	var nodes := {}
	var lim := 8
	for j in range(-lim, lim + 1):
		for i in range(-lim, lim + 1):
			var d := Vector2(i, j).length() * GRID_P
			var r := CITY_R * (0.80 + 0.40 * n_city.get_noise_2d(i, j))
			if j * GRID_P > 470.0:
				continue
			if d < r or ((i == 0 or j == 0) and d < CITY_R * 1.15):
				nodes[Vector2i(i, j)] = true
	# isolierte Knoten entfernen
	for k in nodes.keys():
		var nb := 0
		for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if nodes.has(k + o):
				nb += 1
		if nb == 0:
			nodes.erase(k)
	var ang := deg_to_rad(CITY_ANG)
	var items: Array = []
	var s := ROAD_W
	for k in nodes.keys():
		var need: Array = []
		for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if nodes.has(k + o):
				need.append(_dir_key(Vector2(o)))
		var p := city_pt(k.x * GRID_P, k.y * GRID_P)
		var t: Array = _road_tile(p, need)
		# Weltrotation der Stadt: lokale +z (Süd) → gedreht um CITY_ANG; Basis(UP,a) dreht entgegengesetzt zu Vector2.rotated
		items.append([t[0], _xf(p, city_h + 0.25, t[1] - ang, s)])
		# Segmente nach +x und +z
		for o in [Vector2i(1, 0), Vector2i(0, 1)]:
			if nodes.has(k + o):
				var st: Array = _road_tile(p, ["+x", "-x"] if o.x == 1 else ["+z", "-z"])
				for n in range(1, 6):
					var q := city_pt((k.x + o.x * n / 6.0) * GRID_P, (k.y + o.y * n / 6.0) * GRID_P)
					items.append([st[0], _xf(q, city_h + 0.25, st[1] - ang, s)])
	_place_models(items, false, 0.0)
	# Bebauung je Block
	var lots: Array = []
	var bitems: Array = []
	for k in nodes.keys():
		var has_n := nodes.has(k + Vector2i(1, 0))
		var has_w := nodes.has(k + Vector2i(0, 1))
		var has_s := has_w and nodes.has(k + Vector2i(1, 1))
		var has_e := has_n and nodes.has(k + Vector2i(1, 1))
		var mid := city_pt((k.x + 0.5) * GRID_P, (k.y + 0.5) * GRID_P)
		var dn := mid.distance_to(CITY_C) / CITY_R
		var zone := 0 if dn < 0.33 else (1 if dn < 0.72 else 2)
		if zone == 0 and has_n and has_s and has_w and has_e and rng.randf() < 0.07:
			_park(k, bitems)
			continue
		var o0 := Vector2((k.x) * GRID_P + ROAD_W * 0.5, (k.y) * GRID_P + ROAD_W * 0.5)
		var blk := GRID_P - ROAD_W
		var depth := 22.0
		if has_n: _row(o0, blk, Vector2(1, 0), Vector2(0, 1), 0.0, blk, zone, bitems, lots)            # Straße bei v=0 (Norden)
		if has_s: _row(o0 + Vector2(blk, blk), blk, Vector2(-1, 0), Vector2(0, -1), 0.0, blk, zone, bitems, lots)
		if has_w: _row(o0 + Vector2(0, blk), blk, Vector2(0, -1), Vector2(1, 0), depth if has_s else 0.0, blk - (depth if has_n else 0.0), zone, bitems, lots)
		if has_e: _row(o0 + Vector2(blk, 0), blk, Vector2(0, 1), Vector2(-1, 0), depth if has_n else 0.0, blk - (depth if has_s else 0.0), zone, bitems, lots)
	_place_models(bitems, true, 0.0)
	print("SP03 city nodes=%d buildings=%d" % [nodes.size(), lots.size()])
	return lots


func _row(origin: Vector2, _blk: float, u: Vector2, inward: Vector2, t0: float, t1: float, zone: int, items: Array, lots: Array) -> void:
	## Häuserzeile entlang einer Blockkante im Stadt-Lokalraum. u = Laufrichtung, inward = von Straße weg.
	var fill: float = [0.97, 0.92, 0.6][zone]
	var setback: float = [0.5, 4.0, 6.0][zone]
	var t := t0 + rng.randf_range(0.0, 3.0)
	while t < t1:
		var com := zone == 0 or (zone == 1 and rng.randf() < 0.12)
		var path := ("res://spikes_s7/assets/com/building-%s.glb" % COM[rng.randi() % COM.size()]) if com else ("res://spikes_s7/assets/sub/building-type-%s.glb" % SUB[rng.randi() % SUB.size()])
		var sc := COM_S if com else SUB_S
		var m := _load_mesh(path)
		var ab: AABB = m[2]
		var w := ab.size.x * sc
		var dp := ab.size.z * sc
		var gap := (0.5 if zone == 0 else rng.randf_range(1.5, 3.5 + zone * 3.0))
		if t + w > t1 + 1.0:
			break
		if rng.randf() < fill and dp < 24.0:
			var lp := origin + u * (t + w * 0.5) + inward * (setback + dp * 0.5)
			var wp := city_pt(lp.x, lp.y)
			var front := _rot(-inward)                         # Front zur Straße
			var yaw_r := atan2(front.x, front.y)              # lokale +Z → front
			items.append([path, _xf(wp, city_h + 0.25, yaw_r, sc)])
			lots.append(wp)
			if zone > 0 and rng.randf() < 0.5:
				var tp := city_pt((origin + u * (t + w * 0.5) + inward * (setback + dp + 4.0)).x, (origin + u * (t + w * 0.5) + inward * (setback + dp + 4.0)).y)
				items.append(["res://spikes_s7/assets/sub/tree-large.glb", _xf(tp, city_h + 0.25, rng.randf() * TAU, SUB_S * rng.randf_range(1.0, 1.5))])
		t += w + gap


func _park(k: Vector2i, items: Array) -> void:
	for n in 14:
		var lp := Vector2((k.x + rng.randf_range(0.2, 0.8)) * GRID_P, (k.y + rng.randf_range(0.2, 0.8)) * GRID_P)
		items.append(["res://spikes_s7/assets/sub/tree-large.glb", _xf(city_pt(lp.x, lp.y), city_h + 0.25, rng.randf() * TAU, SUB_S * 1.6)])


func _build_edge_houses(_lots: Array) -> void:
	## Lockerer Rand: Einzelhäuser entlang der Ausfallstraßen, Dichte nimmt nach außen ab.
	var items: Array = []
	for r in roads:
		var pts: PackedVector2Array = r[0]
		var hs: PackedFloat32Array = r[1]
		var acc := 0.0
		for i in range(1, pts.size()):
			acc += pts[i].distance_to(pts[i - 1])
			if acc < 22.0:
				continue
			acc = 0.0
			var dc := pts[i].distance_to(CITY_C)
			if dc < CITY_R + 40.0 or dc > CITY_R + 700.0:
				continue
			var pr := 0.75 * (1.0 - (dc - CITY_R - 40.0) / 660.0)
			var d := (pts[i] - pts[i - 1]).normalized()
			for side in [-1.0, 1.0]:
				if rng.randf() > pr:
					continue
				var path := "res://spikes_s7/assets/sub/building-type-%s.glb" % SUB[rng.randi() % SUB.size()]
				var nrm: Vector2 = Vector2(-d.y, d.x) * float(side)
				var p: Vector2 = pts[i] + nrm * rng.randf_range(15.0, 20.0)
				var y := hget(p.x, p.y)
				var yaw_r := atan2(-nrm.x, -nrm.y)
				items.append([path, _xf(p, y, yaw_r, SUB_S)])
				if rng.randf() < 0.6:
					var tp: Vector2 = p + nrm * 14.0 + d * rng.randf_range(-6, 6)
					items.append(["res://spikes_s7/assets/sub/tree-large.glb", _xf(tp, hget(tp.x, tp.y), 0.0, SUB_S * 1.3)])
	_place_models(items, true, 0.0)


func _build_station() -> void:
	var c := city_pt(0, 500)
	var y := hget(c.x, c.y)
	var k := 0
	for i in track_pts.size():
		if track_pts[i].distance_to(city_pt(0, 510)) < track_pts[k].distance_to(city_pt(0, 510)):
			k = i
	y = track_h[k]
	var b := Basis(Vector3.UP, -deg_to_rad(CITY_ANG))
	var plat := MeshInstance3D.new()
	plat.mesh = _box(Vector3(220, 1.0, 6))
	plat.transform = Transform3D(b, Vector3(c.x, y + 0.5, c.y))
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.62, 0.58, 0.52)
	plat.material_override = m
	add_child(plat)
	var roof := MeshInstance3D.new()
	roof.mesh = _box(Vector3(120, 0.6, 7))
	roof.transform = Transform3D(b, Vector3(c.x, y + 4.5, c.y))
	var mr := StandardMaterial3D.new()
	mr.albedo_color = Color(0.45, 0.30, 0.25)
	roof.material_override = mr
	add_child(roof)
	var sb := city_pt(0, 482)
	_place_models([["res://spikes_s7/assets/com/building-e.glb", _xf(sb, city_h + 0.25, atan2(_rot(Vector2(0, 1)).x, _rot(Vector2(0, 1)).y), COM_S * 1.2)]], true, 0.0)


func _build_mine() -> void:
	var y := hget(MINE_P.x, MINE_P.y)
	var items: Array = [
		["res://spikes_s7/assets/ind/building-a.glb", _xf(MINE_P + Vector2(-40, 0), y, 0.3, IND_S)],
		["res://spikes_s7/assets/ind/building-f.glb", _xf(MINE_P + Vector2(10, -45), y, 0.3, IND_S)],
		["res://spikes_s7/assets/ind/chimney-large.glb", _xf(MINE_P + Vector2(-70, -40), y, 0.0, IND_S * 1.3)],
		["res://spikes_s7/assets/ind/detail-tank.glb", _xf(MINE_P + Vector2(40, 10), y, 0.3, IND_S)],
		["res://spikes_s7/assets/ind/detail-tank.glb", _xf(MINE_P + Vector2(40, 25), y, 0.3, IND_S)],
	]
	_place_models(items, true, 0.0)
	# Förderturm (Grey-Box) und Abraumhalde
	var tower := MeshInstance3D.new()
	tower.mesh = _box(Vector3(8, 36, 8))
	tower.position = Vector3(MINE_P.x - 10, y + 18, MINE_P.y - 10)
	var mt := StandardMaterial3D.new()
	mt.albedo_color = Color(0.35, 0.25, 0.22)
	tower.material_override = mt
	add_child(tower)
	var heap := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 6.0
	cm.bottom_radius = 75.0
	cm.height = 38.0
	cm.radial_segments = 20
	heap.mesh = cm
	heap.position = Vector3(MINE_P.x - 170, y + 16, MINE_P.y + 60)
	var mh := StandardMaterial3D.new()
	mh.albedo_color = Color(0.20, 0.19, 0.19)
	mh.roughness = 1.0
	heap.material_override = mh
	add_child(heap)


func _build_farm() -> void:
	var y := hget(FARM_P.x, FARM_P.y)
	_place_models([
		["res://spikes_s7/assets/ind/building-f.glb", _xf(FARM_P, y, 0.5, 8.0)],
		["res://spikes_s7/assets/sub/building-type-n.glb", _xf(FARM_P + Vector2(-35, 20), y, 0.5, SUB_S)],
		["res://spikes_s7/assets/ind/detail-tank.glb", _xf(FARM_P + Vector2(25, 25), y, 0.5, 8.0)],
	], true, 0.0)
	# Felder: Raster 4×3 à 200×140 m, folgen dem Gelände
	var cols := [Color(0.80, 0.68, 0.35), Color(0.55, 0.62, 0.30), Color(0.52, 0.40, 0.27), Color(0.86, 0.76, 0.42), Color(0.45, 0.56, 0.27)]
	var out := [PackedVector3Array(), PackedColorArray(), PackedInt32Array()]
	var v: PackedVector3Array = out[0]
	var col: PackedColorArray = out[1]
	var idx: PackedInt32Array = out[2]
	var origin := FARM_P + Vector2(60, -60)
	for fj in 3:
		for fi in 4:
			if fi == 0 and fj == 0:
				continue
			var c: Color = cols[(fi * 3 + fj * 2) % cols.size()]
			var p0 := origin + Vector2(fi * 210.0, fj * 150.0)
			var base := v.size()
			var nx := 10
			var nz := 7
			for j in nz + 1:
				for i in nx + 1:
					var p := p0 + Vector2(i * 20.0, j * 20.0)
					v.append(Vector3(p.x, hget(p.x, p.y) + 0.25, p.y))
					var stripe := 0.05 if (i % 2 == 0) else 0.0
					col.append(c.lightened(stripe))
			for j in nz:
				for i in nx:
					var a := base + j * (nx + 1) + i
					idx.append_array([a, a + 1, a + nx + 1, a + 1, a + nx + 2, a + nx + 1])
	_flush_ribbons(out, _mat_vc())


func _build_trees() -> void:
	var paths := ["res://spikes_s7/assets/nat/tree_default.glb", "res://spikes_s7/assets/nat/tree_pineDefaultA.glb"]
	var chunks := 4
	var cs := L / chunks
	var buckets := {}
	var x := 0.0
	var n := 0
	while x < L:
		var z := 0.0
		while z < L:
			var px := x + rng.randf_range(0, 38)
			var pz := z + rng.randf_range(0, 38)
			var h := hget(px, pz)
			var hx := hget(px + 10, pz) - hget(px - 10, pz)
			var hz := hget(px, pz + 10) - hget(px, pz - 10)
			var ny := Vector3(-hx, 20.0, -hz).normalized().y
			var f := _forest(px, pz, h, ny)
			var ix := clampi(int(round(px / STEP)), 0, N - 1)
			var iz := clampi(int(round(pz / STEP)), 0, N - 1)
			var ok := f > 0.0 and sw[iz * N + ix] < 0.15 and rng.randf() < clampf(f * 4.0, 0.3, 0.95)
			if not ok and f == 0.0 and rng.randf() < 0.012 and sw[iz * N + ix] < 0.15 and ny > 0.8 and h < 800.0 and river_dist(px, pz) > 50.0 and Vector2(px, pz).distance_to(CITY_C) > CITY_R + 60.0:
				ok = true
			if ok:
				var key := Vector3i(int(px / cs), int(pz / cs), 1 if h > 260.0 or rng.randf() < 0.3 else 0)
				if not buckets.has(key):
					buckets[key] = []
				buckets[key].append(_xf(Vector2(px, pz), h - 0.3, rng.randf() * TAU, NAT_S * rng.randf_range(0.8, 1.35)))
				n += 1
			z += 40.0
		x += 40.0
	var tmeshes: Array = []
	for pi in 2:
		var src: Mesh = _load_mesh(paths[pi])[0]
		var dm := (src as ArrayMesh).duplicate() as ArrayMesh
		var m_trunk := StandardMaterial3D.new()
		m_trunk.albedo_color = Color(0.36, 0.26, 0.18)
		m_trunk.roughness = 1.0
		var m_crown := StandardMaterial3D.new()
		m_crown.albedo_color = Color(0.20, 0.33, 0.15) if pi == 0 else Color(0.14, 0.27, 0.15)
		m_crown.roughness = 1.0
		for si in dm.get_surface_count():
			var nm := String(dm.surface_get_material(si).resource_name).to_lower() if dm.surface_get_material(si) != null else ""
			var is_trunk := nm.contains("wood") or nm.contains("trunk") or nm.contains("brown")
			dm.surface_set_material(si, m_trunk if is_trunk else m_crown)
		tmeshes.append(dm)
	for key in buckets.keys():
		var m := _load_mesh(paths[key.z])
		var tfs: Array = []
		for t in buckets[key]:
			tfs.append((t as Transform3D) * (m[1] as Transform3D))
		var mi := _multimesh(tmeshes[key.z], tfs, [], Color.WHITE, true)
		mi.visibility_range_end = 4200.0
		mi.visibility_range_end_margin = 300.0
	print("SP03 trees=%d" % n)


func _labels() -> void:
	for d in [["Kohlberg", CITY_C, 60.0], ["Kohlemine", MINE_P, 60.0], ["Gut Haberau", FARM_P, 40.0]]:
		var l := Label3D.new()
		l.text = d[0]
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.fixed_size = true
		l.pixel_size = 0.0012
		l.font_size = 28
		l.outline_size = 8
		l.no_depth_test = true
		var p: Vector2 = d[1]
		l.position = Vector3(p.x, hget(p.x, p.y) + d[2], p.y)
		add_child(l)


# ---------------------------------------------------------------- Umgebung, Kamera

func _setup_env() -> void:
	var we := WorldEnvironment.new()
	env = Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.36, 0.52, 0.74)
	sm.sky_horizon_color = Color(0.74, 0.79, 0.84)
	sm.ground_horizon_color = Color(0.74, 0.79, 0.84)
	sm.ground_bottom_color = Color(0.5, 0.55, 0.5)
	sky.sky_material = sm
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.66, 0.72)
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = Color(0.64, 0.70, 0.78)
	env.fog_density = 1.0
	env.fog_sky_affect = 0.0
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, 35, 0)
	sun.light_color = Color(1.0, 0.95, 0.86)
	sun.light_energy = 1.0
	sun.shadow_enabled = true
	sun.shadow_opacity = 0.6
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	add_child(sun)


func _setup_camera() -> void:
	cam = Camera3D.new()
	cam.fov = FOV
	add_child(cam)
	_apply_cam()


func pitch_for(d: float) -> float:
	var t := clampf(log(d / D_MIN) / log(D_MAX / D_MIN), 0.0, 1.0)
	return lerpf(P_NEAR, P_FAR, pow(t, 0.8))


func set_view(t2: Vector2, yaw_deg: float, d: float, pitch_deg := -1.0) -> void:
	target = Vector3(t2.x, 0, t2.y)
	yaw = deg_to_rad(yaw_deg)
	dist = d
	pitch_override = pitch_deg
	_apply_cam()


func _apply_cam() -> void:
	# Kamera-Grenze: Ziel in der spielbaren Fläche, Abstand in [D_MIN, D_MAX]
	target.x = clampf(target.x, 0.0, L)
	target.z = clampf(target.z, 0.0, L)
	dist = clampf(dist, D_MIN, D_MAX)
	target.y = hget(target.x, target.z)
	var p := deg_to_rad(pitch_override if pitch_override > 0.0 else pitch_for(dist))
	var off := Basis(Vector3.UP, yaw) * Vector3(0, sin(p) * dist, cos(p) * dist)
	cam.position = target + off
	var gy := hget(cam.position.x, cam.position.z) + 8.0
	if cam.position.y < gy:
		cam.position.y = gy
	cam.look_at(target, Vector3.UP)
	cam.near = maxf(0.5, dist * 0.004)
	cam.far = minf(60000.0, dist * 8.0 + 15000.0)
	env.fog_depth_begin = dist * 1.6 + 1500.0
	env.fog_depth_end = dist * 5.0 + 15000.0
	env.fog_depth_curve = 1.6
	sun.directional_shadow_max_distance = clampf(dist * 2.0, 250.0, 3500.0)
	sun.shadow_enabled = dist < 3000.0   # fern: Schatten aus (blockig, teuer)


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP:
			dist *= 0.88
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			dist *= 1.12
		_apply_cam()


func _process(delta: float) -> void:
	var mv := Vector3.ZERO
	if Input.is_key_pressed(KEY_W): mv.z -= 1
	if Input.is_key_pressed(KEY_S): mv.z += 1
	if Input.is_key_pressed(KEY_A): mv.x -= 1
	if Input.is_key_pressed(KEY_D): mv.x += 1
	if Input.is_key_pressed(KEY_Q): yaw += delta * 1.2
	if Input.is_key_pressed(KEY_E): yaw -= delta * 1.2
	if mv != Vector3.ZERO or Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_E):
		target += Basis(Vector3.UP, yaw) * mv.normalized() * dist * 0.9 * delta
		_apply_cam()


## Prüft, ob alle vier Bildecken-Strahlen auf Gelände innerhalb der Welt treffen (kein Blick ins Leere).
func border_check() -> Dictionary:
	var vp := get_viewport().get_visible_rect().size
	var worst := 0.0
	var miss := 0
	for c in [Vector2(0, 0), Vector2(vp.x, 0), Vector2(0, vp.y), vp]:
		var o := cam.project_ray_origin(c)
		var dn := cam.project_ray_normal(c)
		var hit := false
		var t := 0.0
		while t < 60000.0:
			var p := o + dn * t
			if p.y <= hget(p.x, p.z):
				var out := maxf(maxf(-p.x, p.x - L), maxf(-p.z, p.z - L))
				worst = maxf(worst, out)
				if out > B:
					miss += 1
				hit = true
				break
			t += maxf(20.0, t * 0.01)
		if not hit:
			miss += 1
	return {"max_out_m": worst, "miss": miss}
