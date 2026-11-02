extends Node3D
## W-02 (S7, Felix): Gelände der S7-Welt als Meshes. Nur bei --welt=s7 (world/s7_world.gd build_terrain).
##   - spielbar: 8 × 8 Chunks à 64² Felder (65² Knoten, 1 Knoten je Feldecke), gebaut im WorkerThreadPool
##   - Schürze an der Kartenkante (30 m nach unten) gegen Risse zum gröberen Rand
##   - Rand: 279² Knoten im 100-m-Raster (7,5 km je Seite), Innenfläche ausgespart
##   - Gebirgsring: Fernlandschaft ab Randkante bis ×4,5 Abstand, im Nebel; die Kamera sieht bei Max-Zoom nie Himmel
## Material: world/art/terrain.gdshader (Sophie), Fluss-Rinne über fluss_maske (R Rinne, G Aue), Meter über m_pro_einheit.
## _process hält das Kameraziel auf dem Gelände (s7_world.update_camera), läuft nach main._process (Kind von main).

const SHADER := preload("res://world/art/terrain.gdshader")
const CHUNK := 64
const SCHUERZE_M := 30.0
const RING_FAKTOR := 4.5

var s7 = null
var main_ref = null
var chunks: Array[MeshInstance3D] = []
var rand_mi: MeshInstance3D = null
var ring_mi: MeshInstance3D = null
var build_ms := 0.0
var tri_count := 0
var _nrm := PackedVector3Array()
var _res: Array = []


func build(p_s7, p_main) -> void:
	var t0 := Time.get_ticks_usec()
	s7 = p_s7
	main_ref = p_main
	var n: int = s7.n_knoten
	_nrm.resize(n * n)
	var gid := WorkerThreadPool.add_group_task(_normals_row, n, -1, true, "terrain_s7 normals")
	WorkerThreadPool.wait_for_group_task_completion(gid)
	var nc: int = s7.grid / CHUNK
	_res.resize(nc * nc)
	gid = WorkerThreadPool.add_group_task(_chunk_arrays, nc * nc, -1, true, "terrain_s7 chunks")
	WorkerThreadPool.wait_for_group_task_completion(gid)
	var idx := _grid_indices(CHUNK + 1, CHUNK + 1)
	var mat := _material(true)
	for k in nc * nc:
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = _res[k][0]
		arr[Mesh.ARRAY_NORMAL] = _res[k][1]
		arr[Mesh.ARRAY_INDEX] = idx
		var am := ArrayMesh.new()
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		var mi := MeshInstance3D.new()
		mi.mesh = am
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.name = "Chunk_%d" % k
		add_child(mi)
		chunks.append(mi)
		tri_count += idx.size() / 3
	_res.clear()
	_build_skirt(mat)
	_build_rand()
	build_ms = (Time.get_ticks_usec() - t0) / 1000.0


func _process(_delta: float) -> void:
	if s7 != null and main_ref != null:
		s7.update_camera(main_ref)


func _material(mask: bool) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter("m_pro_einheit", s7.m_pro_feld)
	m.set_shader_parameter("wasser_hoehe", -10000.0)   # Rinne/Aue nur über die Maske (Pegel fällt entlang des Flusses)
	if mask:
		var g: int = s7.grid
		var px := PackedByteArray()
		px.resize(g * g * 2)
		for i in g * g:
			px[i * 2] = 255 if s7.fluss[i] & 1 else 0
			px[i * 2 + 1] = 255 if s7.fluss[i] & 2 else 0
		var img := Image.create_from_data(g, g, false, Image.FORMAT_RG8, px)
		m.set_shader_parameter("fluss_maske", ImageTexture.create_from_image(img))
		m.set_shader_parameter("maske_rect", Vector4(0.0, 0.0, g * s7.m_pro_feld, g * s7.m_pro_feld))
	return m


func _normals_row(y: int) -> void:
	var n: int = s7.n_knoten
	var k: PackedFloat32Array = s7.knoten
	for x in n:
		var xl := maxi(x - 1, 0)
		var xr := mini(x + 1, n - 1)
		var yu := maxi(y - 1, 0)
		var yd := mini(y + 1, n - 1)
		var hx := (k[y * n + xr] - k[y * n + xl]) / float(xr - xl)
		var hz := (k[yd * n + x] - k[yu * n + x]) / float(yd - yu)
		_nrm[y * n + x] = Vector3(-hx, 1.0, -hz).normalized()


func _chunk_arrays(ci: int) -> void:
	var n: int = s7.n_knoten
	var nc: int = s7.grid / CHUNK
	var cx := (ci % nc) * CHUNK
	var cy := (ci / nc) * CHUNK
	var k: PackedFloat32Array = s7.knoten
	var v := PackedVector3Array()
	var nm := PackedVector3Array()
	v.resize((CHUNK + 1) * (CHUNK + 1))
	nm.resize(v.size())
	var o := 0
	for y in range(cy, cy + CHUNK + 1):
		for x in range(cx, cx + CHUNK + 1):
			v[o] = Vector3(x, k[y * n + x], y)
			nm[o] = _nrm[y * n + x]
			o += 1
	_res[ci] = [v, nm]


## Dreiecke eines w × h Knotengitters (Zeilen von Nord nach Süd, Gegen-Uhrzeiger von oben gesehen).
static func _grid_indices(w: int, h: int, skip := Rect2i()) -> PackedInt32Array:
	var idx := PackedInt32Array()
	for j in h - 1:
		for i in w - 1:
			if skip.size.x > 0 and i >= skip.position.x and i < skip.end.x and j >= skip.position.y and j < skip.end.y:
				continue
			var a := j * w + i
			idx.append_array([a, a + 1, a + w, a + 1, a + w + 1, a + w])
	return idx


## Schürze rund um die spielbare Fläche: Kantenknoten und dieselben 30 m tiefer.
func _build_skirt(mat: Material) -> void:
	var n: int = s7.n_knoten
	var k: PackedFloat32Array = s7.knoten
	var d: float = SCHUERZE_M / s7.m_pro_feld
	var ring: Array[Vector2i] = []
	for x in n:
		ring.append(Vector2i(x, 0))
	for y in range(1, n):
		ring.append(Vector2i(n - 1, y))
	for x in range(n - 2, -1, -1):
		ring.append(Vector2i(x, n - 1))
	for y in range(n - 2, -1, -1):
		ring.append(Vector2i(0, y))
	var v := PackedVector3Array()
	var nm := PackedVector3Array()
	for p in ring:
		var h := k[p.y * n + p.x]
		var out := Vector3(signf(p.x - n * 0.5), 0.0, signf(p.y - n * 0.5)).normalized()
		v.append(Vector3(p.x, h, p.y))
		v.append(Vector3(p.x, h - d, p.y))
		nm.append(out)
		nm.append(out)
	var idx := PackedInt32Array()
	for i in ring.size() - 1:
		var a := i * 2
		idx.append_array([a, a + 2, a + 1, a + 2, a + 3, a + 1, a, a + 1, a + 2, a + 2, a + 1, a + 3])   # beidseitig
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_NORMAL] = nm
	arr[Mesh.ARRAY_INDEX] = idx
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mi := MeshInstance3D.new()
	mi.mesh = am
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.name = "Schuerze"
	add_child(mi)


## Rand (100-m-Raster, Innenfläche ausgespart) und Gebirgsring (Fernlandschaft) als zwei Meshes ohne Fluss-Maske.
func _build_rand() -> void:
	if s7.rand.is_empty():
		return
	var n: int = s7.n_rand
	var r: PackedFloat32Array = s7.rand
	var st: float = s7.rand_step
	var o0: float = s7.rand_ursprung
	var v := PackedVector3Array()
	var nm := PackedVector3Array()
	v.resize(n * n)
	nm.resize(n * n)
	for j in n:
		for i in n:
			var hx := (r[j * n + mini(i + 1, n - 1)] - r[j * n + maxi(i - 1, 0)]) / (float(mini(i + 1, n - 1) - maxi(i - 1, 0)) * st)
			var hz := (r[mini(j + 1, n - 1) * n + i] - r[maxi(j - 1, 0) * n + i]) / (float(mini(j + 1, n - 1) - maxi(j - 1, 0)) * st)
			v[j * n + i] = Vector3(o0 + i * st, r[j * n + i], o0 + j * st)
			nm[j * n + i] = Vector3(-hx, 1.0, -hz).normalized()
	var inner0 := int(round(-o0 / st))              # 75
	var inner_n := int(round(s7.grid / st))         # 128 Zellen
	var idx := _grid_indices(n, n, Rect2i(inner0, inner0, inner_n, inner_n))
	var mat := _material(false)
	rand_mi = _mesh(v, nm, idx, mat, "Rand")
	tri_count += idx.size() / 3
	# Gebirgsring: äußere Randknoten -> nach außen gestreckt (Faktor RING_FAKTOR vom Kartenmittelpunkt), Höhe = Mittel der Kante
	var edge: Array[int] = []
	for i in n:
		edge.append(i)
	for j in range(1, n):
		edge.append(j * n + n - 1)
	for i in range(n - 2, -1, -1):
		edge.append((n - 1) * n + i)
	for j in range(n - 2, 0, -1):
		edge.append(j * n)
	var mean := 0.0
	for e in edge:
		mean += r[e]
	mean /= edge.size()
	var c := Vector3(s7.grid * 0.5, 0.0, s7.grid * 0.5)
	var rv := PackedVector3Array()
	var rn := PackedVector3Array()
	for e in edge:
		var p: Vector3 = v[e]
		rv.append(p)
		rn.append(nm[e])
		var q := c + (p - c) * RING_FAKTOR
		q.y = mean * 0.85
		rv.append(q)
		rn.append(Vector3.UP)
	var ri := PackedInt32Array()
	var m := edge.size()
	for k in m:
		var a := k * 2
		var b := ((k + 1) % m) * 2
		ri.append_array([a, b, a + 1, b, b + 1, a + 1])
		ri.append_array([a, a + 1, b, b, a + 1, b + 1])   # beidseitig (Umlaufsinn je Seite verschieden)
	ring_mi = _mesh(rv, rn, ri, mat, "Gebirgsring")
	tri_count += ri.size() / 3


func _mesh(v: PackedVector3Array, nm: PackedVector3Array, idx: PackedInt32Array, mat: Material, nm_name: String) -> MeshInstance3D:
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_NORMAL] = nm
	arr[Mesh.ARRAY_INDEX] = idx
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mi := MeshInstance3D.new()
	mi.mesh = am
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.name = nm_name
	add_child(mi)
	return mi
