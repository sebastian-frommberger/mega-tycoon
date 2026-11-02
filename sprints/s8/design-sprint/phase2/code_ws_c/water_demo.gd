extends SceneTree
## Design Sprint Welt (TEAM-02): Testszene Wasser-Shader (world/water.gdshader) auf einem echten S7-Flussabschnitt.
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --path slice -s res://tests/water_demo.gd -- \
##       <out_dir> [<daten_dir> = res://world/data] [<tag> = s7]
## Baut das Gelände 512² (8 × 8 Chunks, Material world/art/terrain.gdshader, Rinne als Flussbett statt blau), darüber das
## Wasser-Mesh (world/water_s7.gd), einen Mühlteich (Mulde in die Knoten gegraben) und einen Bach (Band, 5 m).
## Bilder: <tag>_wasser_nah / _mittel / _uebersicht / _teich / _bach.png. Messung je Ansicht: Draw Calls, Dreiecke,
## mittlere Framezeit (llvmpipe, nur relativ) mit Wasser-Shader, ohne Wasser und mit einfarbigem Material.

const TerrainShader := preload("res://world/art/terrain.gdshader")
const WaterS7 := preload("res://world/water_s7.gd")
const CHUNK := 64

var M := 25.0
var grid := 512
var n := 513
var knoten := PackedFloat32Array()
var fluss := PackedByteArray()
var cam: Camera3D
var wasser: Array[MeshInstance3D] = []
var teich_c := Vector2i(-1, -1)
var bach_p := PackedVector2Array()
var out := "user://"
var tag := "s7"
var log_rows: Array = []


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else "user://"
	var data: String = args[1] if args.size() > 1 else "res://world/data"
	tag = args[2] if args.size() > 2 else "s7"
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_load(data)
	_teich_graben()
	_setup_env()
	_build_terrain()
	_build_wasser()
	cam = Camera3D.new()
	cam.fov = 50.0
	cam.near = 0.04
	cam.far = 3000.0
	root.add_child(cam)
	_run.call_deferred()


func _load(dir: String) -> void:
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(dir.path_join("world_s7_meta.json")))
	M = float(meta["m_pro_feld"])
	grid = int(meta["felder"])
	n = int(meta["knoten"])
	var sk: float = float(meta["hoehe_skala_m"]) / M
	var b := FileAccess.get_file_as_bytes(dir.path_join("hoehe_s7.r16"))
	knoten.resize(n * n)
	for i in n * n:
		knoten[i] = b.decode_u16(i * 2) * sk
	fluss = FileAccess.get_file_as_bytes(dir.path_join("fluss_s7.u8"))
	print("geladen %s: %d Knoten, %d Wasserfelder" % [dir, n * n, _count_water()])


func _count_water() -> int:
	var c := 0
	for v in fluss:
		c += v & 1
	return c


## Höhe (Szeneneinheiten) exakt auf den Gelände-Dreiecken (gleiche Teilung wie terrain_s7.gd)
func hoehe(x: float, z: float) -> float:
	x = clampf(x, 0.0, grid - 0.001)
	z = clampf(z, 0.0, grid - 0.001)
	var x0 := int(x)
	var z0 := int(z)
	var fx := x - x0
	var fz := z - z0
	var a := knoten[z0 * n + x0]
	var b := knoten[z0 * n + x0 + 1]
	var c := knoten[(z0 + 1) * n + x0]
	var d := knoten[(z0 + 1) * n + x0 + 1]
	if fx + fz <= 1.0:
		return a + (b - a) * fx + (c - a) * fz
	return d + (c - d) * (1.0 - fx) + (b - d) * (1.0 - fz)


func _wasser_dist(x: int, y: int, r: int) -> int:
	for k in range(0, r + 1):
		for dy in range(-k, k + 1):
			for dx in range(-k, k + 1):
				if maxi(absi(dx), absi(dy)) != k:
					continue
				var xx := x + dx
				var yy := y + dy
				if xx >= 0 and yy >= 0 and xx < grid and yy < grid and fluss[yy * grid + xx] & 1:
					return k
	return 999


## Mühlteich: Mulde (Radius 3,5 Felder = ~90 m Durchmesser, 2,5 m tief) auf flachem Land 10-16 Felder neben dem Fluss.
func _teich_graben() -> void:
	var best := Vector2i(-1, -1)
	var best_s := 1.0e9
	for y in range(120, 392, 4):
		for x in range(150, 362, 4):
			var dw := _wasser_dist(x, y, 18)
			if dw < 10 or dw > 16:
				continue
			var mn := 1.0e9
			var mx := -1.0e9
			for dy in range(-5, 6):
				for dx in range(-5, 6):
					var h := knoten[(y + dy) * n + x + dx]
					mn = minf(mn, h)
					mx = maxf(mx, h)
			var s := (mx - mn) * M + absf(x - 256) * 0.01
			if s < best_s:
				best_s = s
				best = Vector2i(x, y)
	teich_c = best
	var r := 3.5
	var rim := 1.0e9
	for dy in range(-5, 6):
		for dx in range(-5, 6):
			rim = minf(rim, knoten[(best.y + dy) * n + best.x + dx])
	for dy in range(-5, 6):
		for dx in range(-5, 6):
			var d := Vector2(dx, dy).length()
			if d < r:
				var k := (best.y + dy) * n + best.x + dx
				knoten[k] = minf(knoten[k], rim - 2.5 / M * (1.0 - (d / r) * (d / r)))
	set_meta("teich_rim", rim)
	print("Teich bei %s, Rand %.1f m, Spanne Umfeld %.1f m" % [best, rim * M, best_s])


func _setup_env() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.36, 0.56, 0.80)
	sm.sky_horizon_color = Color(0.76, 0.84, 0.91)
	sm.sky_curve = 0.18
	sm.ground_horizon_color = Color(0.76, 0.84, 0.91)
	sm.ground_bottom_color = Color(0.62, 0.72, 0.80)
	var sky := Sky.new()
	sky.sky_material = sm
	sky.radiance_size = Sky.RADIANCE_SIZE_32
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.74, 0.81, 0.92)
	env.ambient_light_energy = 0.36
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.fog_enabled = true
	env.fog_light_color = Color(0.76, 0.84, 0.91)
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_depth_begin = 200.0
	env.fog_depth_end = 900.0
	env.fog_depth_curve = 1.6
	env.fog_sky_affect = 0.0
	we.environment = env
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, 38, 0)
	sun.light_color = Color(1.0, 0.92, 0.78)
	sun.light_energy = 0.52
	root.add_child(sun)


func _build_terrain() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = TerrainShader
	mat.set_shader_parameter("m_pro_einheit", M)
	mat.set_shader_parameter("wasser_hoehe", -10000.0)
	mat.set_shader_parameter("c_wasser", Color(0.42, 0.40, 0.31))     # Rinne = Flussbett (Wasserfarbe macht der Wasser-Shader)
	var px := PackedByteArray()
	px.resize(grid * grid * 2)
	for i in grid * grid:
		px[i * 2] = 255 if fluss[i] & 1 else 0
		px[i * 2 + 1] = 255 if fluss[i] & 2 else 0
	mat.set_shader_parameter("fluss_maske", ImageTexture.create_from_image(Image.create_from_data(grid, grid, false, Image.FORMAT_RG8, px)))
	mat.set_shader_parameter("maske_rect", Vector4(0, 0, grid * M, grid * M))
	var nrm := PackedVector3Array()
	nrm.resize(n * n)
	for y in n:
		for x in n:
			var hx := (knoten[y * n + mini(x + 1, n - 1)] - knoten[y * n + maxi(x - 1, 0)]) / float(mini(x + 1, n - 1) - maxi(x - 1, 0))
			var hz := (knoten[mini(y + 1, n - 1) * n + x] - knoten[maxi(y - 1, 0) * n + x]) / float(mini(y + 1, n - 1) - maxi(y - 1, 0))
			nrm[y * n + x] = Vector3(-hx, 1.0, -hz).normalized()
	var w := CHUNK + 1
	var idx := PackedInt32Array()
	for j in CHUNK:
		for i in CHUNK:
			var a := j * w + i
			idx.append_array([a, a + 1, a + w, a + 1, a + w + 1, a + w])
	var nc := grid / CHUNK
	for ci in nc * nc:
		var cx := (ci % nc) * CHUNK
		var cy := (ci / nc) * CHUNK
		var v := PackedVector3Array()
		var nm := PackedVector3Array()
		for y in range(cy, cy + w):
			for x in range(cx, cx + w):
				v.append(Vector3(x, knoten[y * n + x], y))
				nm.append(nrm[y * n + x])
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
		root.add_child(mi)


func _build_wasser() -> void:
	var t0 := Time.get_ticks_usec()
	var lv: PackedFloat32Array = WaterS7.fluss_pegel(knoten, fluss, grid, M)[0]
	var mi := WaterS7.baue_mesh(knoten, lv, grid, M, "Fluss")
	root.add_child(mi)
	wasser.append(mi)
	# Teich: eigenes Mesh, Spiegel 0,3 m unter dem Rand, stehend
	var tl := PackedFloat32Array()
	tl.resize(grid * grid)
	tl.fill(NAN)
	var rim: float = get_meta("teich_rim")
	for dy in range(-5, 6):
		for dx in range(-5, 6):
			if Vector2(dx + 0.5, dy + 0.5).length() < 5.0:
				tl[(teich_c.y + dy) * grid + teich_c.x + dx] = rim * M - 0.3
	var tm := WaterS7.baue_mesh(knoten, tl, grid, M, "Teich")
	root.add_child(tm)
	wasser.append(tm)
	# Bach: vom Hang gegenüber dem Teich bergab zum Fluss (Fallinie, mit Zug zum Fluss), Stützpunkt alle 6 m
	var start := _bach_start()
	var p := Vector2(start) + Vector2(0.5, 0.5)
	var dir_prev := Vector2.ZERO
	bach_p.append(p)
	for i in 900:
		var e := 0.3
		var g := Vector2(hoehe(p.x + e, p.y) - hoehe(p.x - e, p.y), hoehe(p.x, p.y + e) - hoehe(p.x, p.y - e))
		var zum_fluss := _richtung_fluss(Vector2i(p))
		var d := (-g.normalized() * 0.5 + zum_fluss * 0.5) if g.length() > 0.0005 else zum_fluss
		d = d.rotated(sin(i * 0.11) * 0.35)
		if dir_prev != Vector2.ZERO:
			d = (d.normalized() + dir_prev * 2.0).normalized()
		dir_prev = d.normalized()
		p += dir_prev * (6.0 / M)
		bach_p.append(p)
		var c := Vector2i(p)
		if c.x < 0 or c.y < 0 or c.x >= grid or c.y >= grid or not is_nan(lv[c.y * grid + c.x]):
			break
	var bm := WaterS7.baue_bach(bach_p, hoehe, 5.0, M)       # 01_skalen E: Bach 4-6 m (Ufergehoelz separat)
	root.add_child(bm)
	wasser.append(bm)
	print("Wasser gebaut in %.0f ms: Fluss %d Dreiecke, Teich %d, Bach %d (%d Punkte)" % [
		(Time.get_ticks_usec() - t0) / 1000.0, mi.get_meta("dreiecke"), tm.get_meta("dreiecke"), bm.get_meta("dreiecke"), bach_p.size()])


func _bach_start() -> Vector2i:
	# Gegenüber dem Teich: am Fluss spiegeln, 30 Felder weiter weg
	var w := _naechstes_wasser(teich_c)
	var d := Vector2(w - teich_c).normalized()
	return Vector2i((Vector2(w) + d * 34.0).round()).clamp(Vector2i(8, 8), Vector2i(grid - 8, grid - 8))


func _naechstes_wasser(c: Vector2i) -> Vector2i:
	for k in range(0, 60):
		for dy in range(-k, k + 1):
			for dx in range(-k, k + 1):
				if maxi(absi(dx), absi(dy)) != k:
					continue
				var xx := c.x + dx
				var yy := c.y + dy
				if xx >= 0 and yy >= 0 and xx < grid and yy < grid and fluss[yy * grid + xx] & 1:
					return Vector2i(xx, yy)
	return c


func _richtung_fluss(c: Vector2i) -> Vector2:
	var w := _naechstes_wasser(c)
	var d := Vector2(w - c)
	return d.normalized() if d.length() > 0.0 else Vector2.ZERO


func _frames(k: int) -> void:
	for i in k:
		await process_frame


func _view(target: Vector2, dist_m: float, pitch_deg: float, yaw_deg: float) -> void:
	var ty := hoehe(target.x, target.y)
	var t := Vector3(target.x, ty, target.y)
	var p := deg_to_rad(pitch_deg)
	var y := deg_to_rad(yaw_deg)
	cam.position = t + Vector3(sin(y) * cos(p), sin(p), cos(y) * cos(p)) * (dist_m / M)
	cam.look_at(t, Vector3.UP)


func _messung(name: String) -> Dictionary:
	await _frames(8)
	var dc := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var tris := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	var t0 := Time.get_ticks_usec()
	await _frames(40)
	var ms := (Time.get_ticks_usec() - t0) / 40000.0
	return {"ansicht": name, "draw_calls": dc, "dreiecke": tris, "frame_ms": snappedf(ms, 0.01)}


func _shot(name: String, target: Vector2, dist_m: float, pitch: float, yaw: float) -> void:
	var nur := OS.get_environment("MT_WASSER_NUR")
	if nur != "" and nur != name:
		return
	_view(target, dist_m, pitch, yaw)
	await _frames(12)
	var path := out.path_join("%s_wasser_%s.png" % [tag, name])
	root.get_viewport().get_texture().get_image().save_png(path)
	# Kosten: mit Shader, ohne Wasser, mit einfarbigem Material
	var a: Dictionary = await _messung(name)
	for w in wasser:
		w.visible = false
	var b: Dictionary = await _messung(name)
	var flat := StandardMaterial3D.new()
	flat.albedo_color = Color(0.25, 0.45, 0.6)
	var mats := []
	for w in wasser:
		w.visible = true
		mats.append(w.material_override)
		w.material_override = flat
	var c: Dictionary = await _messung(name)
	for i in wasser.size():
		wasser[i].material_override = mats[i]
	var row := {"bild": path.get_file(), "dc_mit": a["draw_calls"], "dc_ohne": b["draw_calls"], "tris_mit": a["dreiecke"], "tris_ohne": b["dreiecke"],
		"ms_shader": a["frame_ms"], "ms_ohne": b["frame_ms"], "ms_flach": c["frame_ms"]}
	log_rows.append(row)
	print("MESS ", JSON.stringify(row))


func _run() -> void:
	# Debug/Tuning: MT_WASSER_PARAM="wellen_staerke=0,fresnel_staerke=0" setzt Shader-Parameter, MT_WASSER_NUR=nah nur eine Ansicht
	for kv in OS.get_environment("MT_WASSER_PARAM").split(",", false):
		var p2 := kv.split("=")
		for w2 in wasser:
			(w2.material_override as ShaderMaterial).set_shader_parameter(p2[0], float(p2[1]))
	var nur := OS.get_environment("MT_WASSER_NUR")
	await _frames(5)
	var w := _naechstes_wasser(teich_c)
	var ufer := (Vector2(w) + Vector2(teich_c)) * 0.5 + Vector2(0.5, 0.5)
	await _shot("nah", Vector2(w) + Vector2(0.5, 0.5), 160.0, 34.0, 30.0)
	await _shot("mittel", ufer, 900.0, 45.0, 30.0)
	await _shot("uebersicht", Vector2(grid * 0.5, grid * 0.5), 5600.0, 62.0, 0.0)
	await _shot("teich", Vector2(teich_c) + Vector2(0.5, 0.5), 260.0, 40.0, 210.0)
	var bm := bach_p[bach_p.size() / 2]
	await _shot("bach", bm, 220.0, 38.0, 120.0)
	# Shader-Kosten: Wasser füllt das ganze Bild (Draufsicht 30 m über Flussmitte), Pixelkosten dominieren
	await _shot("vollbild", Vector2(w) + Vector2(0.5, 0.5), 30.0, 85.0, 0.0)
	var f := FileAccess.open(out.path_join("%s_wasser_messung.json" % tag), FileAccess.WRITE)
	f.store_string(JSON.stringify(log_rows, " "))
	f.close()
	quit(0)
