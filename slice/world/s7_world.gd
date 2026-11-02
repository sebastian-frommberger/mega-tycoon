extends RefCounted
## W-01/W-02/W-06 (S7, Felix): Hooks der S7-Welt. main.gd ruft diese Funktionen nur auf, wenn `--welt=s7` aktiv ist
## (main.world_s7 != null). Ohne Schalter wird diese Datei nicht instanziiert, der Slice bleibt bitgleich.
##
## Daten (tools/world_gen.py, Seed in world_s7_meta.json): world/data/
##   world_s7.json       Karte im Slice-Schema (Städte, Industrien, Ketten, HQ-Optionen)
##   hoehe_s7.r16        513² uint16 LE, Knoten = Feldecken, Höhe = Wert × hoehe_skala_m (0,05 m)
##   rand_s7.r16         279² uint16 LE, Landschaftsrand 7,5 km je Seite, Raster 100 m (4 Felder), Knoten 75..203 = spielbar
##   fluss_s7.u8         512² je Feld: Bit 1 Rinne (Wasser), Bit 2 Aue
##   world_s7_meta.json  Skalen, Bau-Konstanten (bau.*), md5
## Fehlen die Dateien, bleibt die Welt flach (hoehe_at = 0, Block-A-Verhalten).
## Testschalter: Umgebungsvariable MT_S7_KARTE=slice -> S7-Maßstab mit Slice-Karte, flach (Block-A-Stand). Für Suiten, die
## W-04/U-03 an festen Slice-Koordinaten prüfen (s7_w04_test, s7_u03_test, u03_play_check s7). Setzen per
## OS.set_environment("MT_S7_KARTE", "slice") vor dem Instanziieren von main.tscn bzw. in der Shell.
##
## ---- API (stabil; Mira: world/industry_markers.gd, world/bau_s7.gd, world/road_tiles.gd) ----
##   hoehe_at(cell: Vector2i, grid: int) -> float     Höhe des Feldes in METERN (Sim-Wert, Mittel der 4 Eckknoten).
##                                                     Wasserfelder liefern die Brücken-/Uferhöhe (nicht den Rinnenboden),
##                                                     damit Steigung und Brückenbau über den Fluss stimmen. Außerhalb: 0.
##   hoehe_szene(x: float, z: float) -> float          Gelände (Mesh) an einem Punkt in SZENENEINHEITEN (1 Feld = 1,0,
##                                                     m / m_pro_feld), bilinear, inkl. Landschaftsrand. Für Flächen/Props.
##   feld_szene(cell: Vector2i) -> float               hoehe_at in Szeneneinheiten (Fahrzeuge, Ghost, Hover).
##   steigung_faktor(pct: float) -> float              Baukostenfaktor (1,0 flach; 1 + 0,15 × pct, 10 % -> × 2,5)
##   steigung_max_pct() -> float                       Sperre "zu steil" Straße (20 %), Text B11 in ui/fehlertexte.gd
##   ray_hit(from: Vector3, dir: Vector3) -> Variant   Mausstrahl gegen das Gelände (Vector3 oder null)
## Gebäude heben sich in Building.setup selbst (building.gd). Wer Flächen auf das Gelände legt (rebuild_surfaces), fragt
## hoehe_szene() je Eckpunkt. Die Höhe ändert sich zur Laufzeit nicht (kein Terraforming in S7).
## Sim-Regeln (Refinement S7): nur Steigung -> Baukosten und Sperre, kein Steigungstempo, 1 Trasse je Feld.

const Welt := preload("res://world/welt.gd")
const TerrainS7 := preload("res://world/terrain_s7.gd")
const WELT := "s7"
const DATA := "res://world/data/"
const MAP_S7 := DATA + "world_s7.json"
const META := DATA + "world_s7_meta.json"
const HEIGHTMAP := DATA + "hoehe_s7.r16"
const RAND := DATA + "rand_s7.r16"
const FLUSS := DATA + "fluss_s7.u8"
const FOV := 50.0           # SP-03
const P_NEAR := 36.0        # Neigung nah [°] (SP-03)
const P_FAR := 62.0         # Neigung fern [°]
const CAM_MIN_UEBER_BODEN_M := 8.0
## D-09 (S7 Block D): Schattenreichweite in Metern gedeckelt. main._apply_zoom setzt 1,4 × Abstand (Slice-Formel, in S7
## bis 8 km); Häuser werden ab 1,4 km Proxy ohne Schatten, Gartenbäume enden bei 1,8 km. Aus der Übersicht liegt der
## Boden jenseits der Deckelung -> kein Schattenpass (spart ~58 Draw Calls). Nah (≤ 1,8 km Abstand) unverändert.
const SCHATTEN_MAX_M := 2500.0
const ENV_KARTE := "MT_S7_KARTE"

var m_pro_feld := Welt.m_pro_feld(WELT)
var zoom_range := Welt.zoom_range(WELT)
var hoehe := PackedFloat32Array()        # Höhe je Feld in Metern (GRID²), Wasser = Uferhöhe; leer = flach
var hoehe_boden := PackedFloat32Array()  # wie hoehe, aber Wasser = Rinnenboden
var steigung_pm := PackedInt32Array()    # je Feld: max |dh| zu den 4 Nachbarn / 25 m in Promille (wie Generator/Validator)
var fluss := PackedByteArray()           # je Feld Bit 1 Rinne, Bit 2 Aue
var knoten := PackedFloat32Array()       # 513² Knotenhöhen in Szeneneinheiten
var rand := PackedFloat32Array()         # 279² Randknoten in Szeneneinheiten
var n_knoten := 0
var n_rand := 0
var rand_step := 4.0                     # Felder je Randzelle
var rand_ursprung := -300.0              # Felder
var grid := 0
var meta := {}
var bau := {"steigung_max_promille_strasse": 200, "kosten_promille_je_steigungs_promille": 15}
var h_min := 0.0                         # Szeneneinheiten (Rand eingeschlossen)
var h_max := 0.0
var terrain_node: Node3D = null
var env: Environment = null
var load_ms := 0.0
var slice_karte := false                 # MT_S7_KARTE=slice: Slice-Daten, flach


func _init() -> void:
	var t0 := Time.get_ticks_usec()
	slice_karte = OS.get_environment(ENV_KARTE) == "slice"
	if not slice_karte:
		_load()
	load_ms = (Time.get_ticks_usec() - t0) / 1000.0


func has_terrain() -> bool:
	return not hoehe.is_empty()


func _load() -> void:
	if not (FileAccess.file_exists(META) and FileAccess.file_exists(HEIGHTMAP) and FileAccess.file_exists(FLUSS)):
		return
	meta = JSON.parse_string(FileAccess.get_file_as_string(META))
	bau = meta["bau"]
	var sk: float = float(meta["hoehe_skala_m"]) / m_pro_feld
	n_knoten = int(meta["knoten"])
	grid = int(meta["felder"])
	knoten = _decode_u16(FileAccess.get_file_as_bytes(HEIGHTMAP), n_knoten * n_knoten, sk)
	if FileAccess.file_exists(RAND):
		n_rand = int(meta["rand"]["knoten"])
		rand_step = float(meta["rand"]["raster_m"]) / m_pro_feld
		rand_ursprung = float(meta["rand"]["ursprung_m"]) / m_pro_feld
		rand = _decode_u16(FileAccess.get_file_as_bytes(RAND), n_rand * n_rand, sk)
	fluss = FileAccess.get_file_as_bytes(FLUSS)
	# Feldhöhen (Mittel der 4 Ecken, Meter) und Steigung (Promille, max zu 4 Nachbarn), wie tools/world_gen.py
	var n := grid
	var nk := n_knoten
	hoehe_boden.resize(n * n)
	for y in n:
		var r0 := y * nk
		var r1 := r0 + nk
		for x in n:
			hoehe_boden[y * n + x] = (knoten[r0 + x] + knoten[r0 + x + 1] + knoten[r1 + x] + knoten[r1 + x + 1]) * 0.25 * m_pro_feld
	steigung_pm.resize(n * n)
	for y in n:
		for x in n:
			var i := y * n + x
			var h := hoehe_boden[i]
			var d := 0.0
			if x > 0: d = maxf(d, absf(h - hoehe_boden[i - 1]))
			if x < n - 1: d = maxf(d, absf(h - hoehe_boden[i + 1]))
			if y > 0: d = maxf(d, absf(h - hoehe_boden[i - n]))
			if y < n - 1: d = maxf(d, absf(h - hoehe_boden[i + n]))
			steigung_pm[i] = int(round(d / m_pro_feld * 1000.0))
	# Wasserfelder: Bauhöhe = Brückendeck (H2, S7 Block D). Je Wasserfeld der Lauf in der Zeile (O-W) und in der Spalte
	# (N-S); das Deck liegt linear zwischen den beiden Uferfeldern des KÜRZEREN Laufs (Gleichstand: O-W). So hält eine
	# gerade Querung die Rampe |h_Ufer2 - h_Ufer1| / ((Lauf + 1) × 25 m). Ohne zwei Ufer (Kartenrand) bleibt die alte Regel
	# (höchstes Landfeld im Umkreis 3). Dieselbe Regel rechnet tools/world_validate.py (bruecken_hoehe) für die Erreichbarkeit.
	hoehe = bruecken_hoehe(hoehe_boden, fluss, n)
	h_min = 1.0e9
	h_max = -1.0e9
	for arr in [knoten, rand]:
		for v in arr:
			h_min = minf(h_min, v)
			h_max = maxf(h_max, v)


## H2: Feldhöhen mit Brückendeck auf Wasserfeldern (Regel siehe _load). boden = Feldhöhen (Wasser = Rinnenboden), Meter.
static func bruecken_hoehe(boden: PackedFloat32Array, fl: PackedByteArray, n: int) -> PackedFloat32Array:
	var out := boden.duplicate()
	var dh := PackedFloat32Array()      # Deck aus dem Lauf in der Zeile, NAN = kein Ufer beidseitig
	var dv := PackedFloat32Array()
	var rh := PackedInt32Array()
	var rv := PackedInt32Array()
	dh.resize(n * n)
	dv.resize(n * n)
	rh.resize(n * n)
	rv.resize(n * n)
	for axis in 2:                      # 0 = Zeile (O-W), 1 = Spalte (N-S)
		var deck := dh if axis == 0 else dv
		var run := rh if axis == 0 else rv
		for line in n:
			var t := 0
			while t < n:
				var i := line * n + t if axis == 0 else t * n + line
				if fl[i] & 1 == 0:
					t += 1
					continue
				var s := t
				while t < n and fl[(line * n + t) if axis == 0 else (t * n + line)] & 1:
					t += 1
				var e := t - 1
				var ln := e - s + 1
				var ha := NAN
				var hb := NAN
				if s > 0 and e < n - 1:
					ha = boden[(line * n + s - 1) if axis == 0 else ((s - 1) * n + line)]
					hb = boden[(line * n + e + 1) if axis == 0 else ((e + 1) * n + line)]
				for q in range(s, e + 1):
					var j := line * n + q if axis == 0 else q * n + line
					run[j] = ln
					deck[j] = ha + (hb - ha) * float(q - s + 1) / float(ln + 1) if not is_nan(ha) else NAN
	for i in n * n:
		if fl[i] & 1 == 0:
			continue
		var a := dh[i]
		var b := dv[i]
		if not is_nan(a) and (is_nan(b) or rh[i] <= rv[i]):
			out[i] = a
		elif not is_nan(b):
			out[i] = b
		else:                           # Kartenrand: höchstes Landfeld im Umkreis 3 (alte Regel)
			var cx := i % n
			var cy := i / n
			var best := -1.0e9
			for yy in range(maxi(0, cy - 3), mini(n, cy + 4)):
				for xx in range(maxi(0, cx - 3), mini(n, cx + 4)):
					if fl[yy * n + xx] & 1 == 0:
						best = maxf(best, boden[yy * n + xx])
			out[i] = best if best > -1.0e8 else boden[i]
	return out


static func _decode_u16(b: PackedByteArray, count: int, scale: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(count)
	for i in count:
		out[i] = b.decode_u16(i * 2) * scale
	return out


## Kartenpfad: eigene S7-Karte, sobald der Generator sie liefert, sonst die Slice-Daten (Block A erlaubt).
func map_path(fallback: String) -> String:
	return MAP_S7 if FileAccess.file_exists(MAP_S7) and not slice_karte else fallback


## HQ-Vorschau (hq_placement.gd): generierte world/data/hq_vorschau_s7.json zur S7-Karte, sonst die Slice-Datei.
func vorschau_path(fallback: String) -> String:
	var p := DATA + "hq_vorschau_s7.json"
	return p if FileAccess.file_exists(p) and not slice_karte and FileAccess.file_exists(MAP_S7) else fallback


## Nach main._setup_camera: Zoom-Klemme, FOV SP-03.
func setup_camera(main) -> void:
	main.zoom_min = zoom_range.x
	main.zoom_max = zoom_range.y
	main.cam.fov = FOV


## Aus main._apply_zoom, vor dem Setzen der Kameraposition: Zoom klemmen, near/far an den Abstand koppeln
## (Tiefenpräzision über 40 m–5,6 km, wie SP-03: near 0,4 % des Abstands, far 8 × Abstand + 15 km), Nebel nach Abstand.
## Position/Neigung setzt update_camera (je Frame aus terrain_s7._process, nach main._process).
func apply_zoom(main) -> void:
	main.zoom = clampf(main.zoom, zoom_range.x, zoom_range.y)
	var dist: float = main.zoom * Welt.CAM_DIR_LEN            # Felder
	main.cam.near = maxf(0.01, dist * 0.004)
	main.cam.far = dist * 8.0 + 15000.0 / m_pro_feld
	if env != null and has_terrain():
		env.fog_depth_begin = dist * 1.6 + 1500.0 / m_pro_feld
		env.fog_depth_end = dist * 5.0 + 15000.0 / m_pro_feld


## Ziel folgt dem Gelände (grob, 100-m-Raster), Neigung nach Abstand 36°→62° (SP-03), Kamera nie unter Gelände + 8 m.
## Der Abstand bleibt zoom × |(0,20,16)| (Block A, Klemme 40 m–5,6 km).
func update_camera(main) -> void:
	if main.rig == null or main.cam == null or not has_terrain():
		return
	var rp: Vector3 = main.rig.position
	rp.y = hoehe_grob(rp.x, rp.z)
	main.rig.position = rp
	var dist: float = main.zoom * Welt.CAM_DIR_LEN
	var p := deg_to_rad(pitch_for(dist * m_pro_feld))
	var cp := Vector3(0.0, sin(p) * dist, cos(p) * dist)
	var gy := hoehe_szene(rp.x + cp.x, rp.z + cp.z) + CAM_MIN_UEBER_BODEN_M / m_pro_feld
	if rp.y + cp.y < gy:
		cp.y = gy - rp.y
	main.cam.position = cp
	main.cam.rotation = Vector3(-atan2(cp.y, cp.z), 0.0, 0.0)
	if main.sun != null:
		main.sun.directional_shadow_max_distance = minf(main.sun.directional_shadow_max_distance, SCHATTEN_MAX_M / m_pro_feld)


static func pitch_for(d_m: float) -> float:
	var t := clampf(log(d_m / 40.0) / log(5600.0 / 40.0), 0.0, 1.0)
	return lerpf(P_NEAR, P_FAR, pow(t, 0.8))


## Kamera-Abstand zum Zielpunkt in Metern (Tests, HUD/Debug).
func camera_distance_m(main) -> float:
	return Welt.distance_m_for_zoom(WELT, main.zoom)


## Höhe in Metern je Feld (Sim). Wasser = Uferhöhe (Brücke). Siehe API oben.
func hoehe_at(cell: Vector2i, p_grid: int) -> float:
	if hoehe.is_empty() or cell.x < 0 or cell.y < 0 or cell.x >= p_grid or cell.y >= p_grid:
		return 0.0
	return hoehe[cell.y * p_grid + cell.x]


func feld_szene(cell: Vector2i) -> float:
	return hoehe_at(cell, grid) / m_pro_feld


## Gelände in Szeneneinheiten an (x, z), bilinear über die Knoten; außerhalb über den Rand.
func hoehe_szene(x: float, z: float) -> float:
	if knoten.is_empty():
		return 0.0
	if x >= 0.0 and z >= 0.0 and x <= grid and z <= grid:
		return _bilinear(knoten, n_knoten, x, z)
	return hoehe_grob(x, z)


## Grobe Höhe (100-m-Raster des Rands, deckt auch die spielbare Fläche) für das Kameraziel.
func hoehe_grob(x: float, z: float) -> float:
	if rand.is_empty():
		return _bilinear(knoten, n_knoten, x, z) if not knoten.is_empty() else 0.0
	return _bilinear(rand, n_rand, (x - rand_ursprung) / rand_step, (z - rand_ursprung) / rand_step)


static func _bilinear(a: PackedFloat32Array, n: int, u: float, v: float) -> float:
	u = clampf(u, 0.0, n - 1.0)
	v = clampf(v, 0.0, n - 1.0)
	var x0 := mini(int(u), n - 2)
	var y0 := mini(int(v), n - 2)
	var fx := u - x0
	var fy := v - y0
	var i := y0 * n + x0
	return lerpf(lerpf(a[i], a[i + 1], fx), lerpf(a[i + n], a[i + n + 1], fx), fy)


## Baukostenfaktor bei pct % Steigung (bau_s7.gd). 1000 + 15 × Promille -> 1 + 0,15 × pct.
func steigung_faktor(pct: float) -> float:
	return 1.0 + float(bau["kosten_promille_je_steigungs_promille"]) * pct * 10.0 / 1000.0


## Sperre "zu steil" in % (Straße). Die Gleis-Grenze 12 % steht in meta.bau; bau_s7 kennt heute nur einen Wert (offen).
func steigung_max_pct() -> float:
	return float(bau["steigung_max_promille_strasse"]) / 10.0


## main.terrain aus Flussmaske und Steigung (aus main._build_map direkt nach _raster_terrain): Rinne = WATER,
## steiler als die Straßengrenze = MOUNTAIN (Fels, Bergfaktor), sonst PLAIN. Ersetzt die Polygon-Klassen der JSON-Karte.
func raster_terrain(main) -> void:
	if not has_terrain():
		return
	var lim: int = int(bau["steigung_max_promille_strasse"])
	for i in grid * grid:
		main.mountain_h[i] = 0.0
		if fluss[i] & 1:
			main.terrain[i] = main.Terrain.WATER
		elif steigung_pm[i] > lim:
			main.terrain[i] = main.Terrain.MOUNTAIN
		else:
			main.terrain[i] = main.Terrain.PLAIN


## Terrain-Chunks, Rand, Gebirgsring und Nebel statt der flachen Ebene (main._setup_ground legt sie vorher an).
func build_terrain(main) -> void:
	for c in main.get_children():
		if c is WorldEnvironment:
			env = (c as WorldEnvironment).environment
		elif c is MeshInstance3D and (c as MeshInstance3D).mesh is PlaneMesh and has_terrain():
			c.visible = false        # flache Ebene + Dunstfläche aus main._setup_ground
	if not has_terrain():
		return
	if env != null:
		env.fog_mode = Environment.FOG_MODE_DEPTH
		env.fog_density = 1.0
		env.fog_depth_curve = 1.6
	terrain_node = TerrainS7.new()
	terrain_node.name = "TerrainS7"
	main.add_child(terrain_node)
	terrain_node.build(self, main)
	apply_zoom(main)


## Nach main._build_map: Instanzen der Karten-MultiMeshes (Häuser, Bäume, Deko) auf das Gelände legen und die
## Fahrzeughöhe je Feld setzen (vorberechnet, Wasser = Brückenhöhe). Gebäude heben sich in Building.setup selbst.
func after_map(main) -> void:
	if not has_terrain():
		return
	# Wasser-/Berg-Quader aus main._build_terrain_visuals ausblenden: Rinne und Fels zeichnet das Terrain-Material
	var berg_mm = null
	for c in main.decor:
		if main.terrain_at(c) == main.Terrain.MOUNTAIN:
			berg_mm = main.decor[c][0]
			break
	for c in main.get_children():
		if c is MultiMeshInstance3D and (c == berg_mm or ((c as MultiMeshInstance3D).multimesh != null
				and (c as MultiMeshInstance3D).multimesh.mesh is BoxMesh
				and ((c as MultiMeshInstance3D).multimesh.mesh as BoxMesh).size == Vector3(1, 0.04, 1))):
			c.visible = false
			continue
		if c is MultiMeshInstance3D:
			var mm: MultiMesh = (c as MultiMeshInstance3D).multimesh
			if mm == null or mm.transform_format != MultiMesh.TRANSFORM_3D:
				continue
			for k in mm.instance_count:
				var t := mm.get_instance_transform(k)
				t.origin.y += hoehe_szene(t.origin.x, t.origin.z)
				mm.set_instance_transform(k, t)
	var vg := PackedFloat32Array()
	vg.resize(grid * grid)
	for i in grid * grid:
		vg[i] = hoehe[i] / m_pro_feld
	main.set_vehicle_heights(vg, grid)
	update_camera(main)


## Mausstrahl gegen das Gelände (spielbar + Rand). null, wenn der Strahl das Gelände nicht trifft.
func ray_hit(from: Vector3, dir: Vector3):
	if not has_terrain():
		return Plane(Vector3.UP, 0.0).intersects_ray(from, dir)
	if dir.y >= -1.0e-5:
		return null
	var t0 := maxf(0.0, (from.y - h_max) / -dir.y)
	var t1 := (from.y - h_min) / -dir.y
	var t := t0
	var prev := t0
	while t <= t1:
		var p := from + dir * t
		if p.y <= hoehe_szene(p.x, p.z):
			var lo := prev
			var hi := t
			for _k in 12:
				var mid := (lo + hi) * 0.5
				var q := from + dir * mid
				if q.y <= hoehe_szene(q.x, q.z):
					hi = mid
				else:
					lo = mid
			var hit := from + dir * hi
			hit.y = hoehe_szene(hit.x, hit.z)
			return hit
		prev = t
		t += 0.5 * maxf(1.0, (t - t0) / 200.0)
	return null
