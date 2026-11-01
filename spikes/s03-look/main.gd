extends Node3D
## S-03 Look-Test Diorama vs. Karte (Sophie, Sprint 2).
## Die komplette Szene wird hier per Code gebaut: 1 Stadt, 2 Industrien (Farm, Stahlwerk),
## Strecke (Doppelgleis) + Strasse, 200 MultiMesh-Quader (Fahrzeuge), Baeume (zweites MultiMesh,
## NICHT Teil der 200), Kamerafahrt 50 -> 1000 m in 5 s, Blend Diorama/Betrieb/Karte um 150/800 m.
##
## Aufruf (Argumente nach "--"):
##   (ohne)       interaktiv: Kamerafahrt in Schleife; 1-5 = Zoomstufen, SPACE = Pause, L = Labels, H = hart statt Blend
##   --shots      Screenshots 50/150/400/800/1000 (+920) nach shots/
##   --far        Zusatz: Lesbarkeit ueber 1000 m hinaus (1500/2500/4000/6000 m) nach shots_far/
##   --strip      Blend-Streifen 640..940 m nach strip/
##   --popping    Popping-Proxy: Bild-zu-Bild-Differenz ueber 50..1000 m (mit --hard: harter Wechsel) nach measure/
##   --fly        5-s-Fahrt in Echtzeit, Frame-Zeiten nach measure/ (3 Durchlaeufe, 1. = kalt)
##   --movie      eine Fahrt, danach Ende (fuer --write-movie --fixed-fps 30)
##   --labels     Label3D fuer Stadt/Industrien einblenden
##   --hard       harter Wechsel statt Blend (Vergleich "Zoom-Blend ja/nein")

const H_MIN := 50.0
const H_MAX := 1000.0
const FLY_SECONDS := 5.0
const FOV_DEG := 40.0
# Blend-Zonen: Mitte 150 m / 800 m, Breite +-40 m bzw. +-120 m
const MID_C := 150.0
const MID_W := 40.0
const MAP_C := 800.0
const MAP_W := 120.0

const FOCUS_NEAR := Vector3(-150.0, 0.0, -30.0)   # Bahnhof am Stadtrand
const FOCUS_FAR := Vector3(10.0, 0.0, -90.0)      # Schwerpunkt der Szene

const TOWN_HALF := 150.0
const FARM_C := Vector2(-560.0, -250.0)
const FARM_SIZE := 120.0
const MILL_C := Vector2(560.0, -230.0)
const MILL_SIZE := 150.0

# Farben (Terrain <= 35 % Saettigung, Spielernetz Signalorange)
const C_GRASS := Color(0.56, 0.60, 0.49)
const C_ROAD := Color(0.36, 0.36, 0.37)
const C_BALLAST := Color(0.50, 0.46, 0.41)
const C_RAIL := Color(0.18, 0.18, 0.20)
const C_ORANGE := Color(1.0, 0.52, 0.06)
const C_GRAIN := Color(0.88, 0.70, 0.16)
const C_STEEL := Color(0.38, 0.50, 0.66)
const C_WOOD := Color(0.55, 0.38, 0.22)
const C_ENERGY := Color(0.10, 0.74, 0.80)
const C_FOOD := Color(0.82, 0.26, 0.20)

var args: PackedStringArray
var rng := RandomNumberGenerator.new()

var cam: Camera3D
var sun: DirectionalLight3D
var env: Environment
var hud: Label
var mats: Array[ShaderMaterial] = []
var obj_mat: ShaderMaterial
var track_mat: ShaderMaterial
var road_mat: ShaderMaterial
var rail_mat: ShaderMaterial
var casing_mat: ShaderMaterial
var outline_mat: ShaderMaterial
var patch_mat: ShaderMaterial
var ground_mat: ShaderMaterial
var veh_mat: ShaderMaterial
var tree_mat: ShaderMaterial
var icons: Array[Sprite3D] = []
var labels3d: Array[Label3D] = []

var track_pts := PackedVector2Array()
var road_pts := PackedVector2Array()
var veh_mm: MultiMesh
var tree_mm: MultiMesh
var veh_data: Array = []   # je Instanz: {path, s0, speed, len, hgt, wid, col, y}
var paths: Dictionary = {}  # name -> {pts, cum, length}

var t_fly := 0.0
var paused := false
var hard_switch := false
var animate := true
var cur_h := H_MIN
var cur_map := 0.0
var cur_mid := 0.0
var mode := "interactive"

# ---------------------------------------------------------------- Meshbau

class MB:
	var st := SurfaceTool.new()
	var cur_base := 0.0
	var cur_anchor := Vector2.ZERO
	func _init() -> void:
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
	## Dreieck; "out" = Soll-Normale (Seite, die sichtbar sein soll). Godot: Front = im Uhrzeigersinn.
	func tri(p0: Vector3, p1: Vector3, p2: Vector3, col: Color, out: Vector3, detail := 0.0,
			ux := Vector3.ZERO, uv2a := Vector2.ZERO, uv2b := Vector2.ZERO, uv2c := Vector2.ZERO) -> void:
		if detail > 0.5 and ux == Vector3.ZERO:
			# Detail: UV.x = Basishoehe, UV2 = Ankerpunkt -> Shader schrumpft das Detail darauf
			ux = Vector3(cur_base, cur_base, cur_base)
			uv2a = cur_anchor
			uv2b = cur_anchor
			uv2c = cur_anchor
		var gn := (p1 - p0).cross(p2 - p0)
		var ps := [p0, p1, p2]
		var us := [ux.x, ux.y, ux.z]
		var u2 := [uv2a, uv2b, uv2c]
		if gn.dot(out) > 0.0:
			ps = [p0, p2, p1]
			us = [ux.x, ux.z, ux.y]
			u2 = [uv2a, uv2c, uv2b]
		var n := out.normalized()
		for i in 3:
			st.set_color(col)
			st.set_normal(n)
			st.set_uv(Vector2(us[i], detail))
			st.set_uv2(u2[i])
			st.add_vertex(ps[i])
	func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color, out: Vector3, detail := 0.0) -> void:
		tri(a, b, c, col, out, detail)
		tri(a, c, d, col, out, detail)
	## Quader, pos = Mitte der Grundflaeche
	func box(pos: Vector3, size: Vector3, col: Color, detail := 0.0, top_col := Color(0, 0, 0, 0)) -> void:
		var x0 := pos.x - size.x * 0.5
		var x1 := pos.x + size.x * 0.5
		var z0 := pos.z - size.z * 0.5
		var z1 := pos.z + size.z * 0.5
		var y0 := pos.y
		var y1 := pos.y + size.y
		cur_base = pos.y
		cur_anchor = Vector2(pos.x, pos.z)
		var tc := col if top_col.a == 0.0 else top_col
		quad(Vector3(x0, y1, z1), Vector3(x1, y1, z1), Vector3(x1, y1, z0), Vector3(x0, y1, z0), tc, Vector3.UP, detail)
		quad(Vector3(x0, y0, z1), Vector3(x1, y0, z1), Vector3(x1, y1, z1), Vector3(x0, y1, z1), col * 0.92, Vector3.BACK, detail)
		quad(Vector3(x1, y0, z0), Vector3(x0, y0, z0), Vector3(x0, y1, z0), Vector3(x1, y1, z0), col * 0.92, Vector3.FORWARD, detail)
		quad(Vector3(x1, y0, z1), Vector3(x1, y0, z0), Vector3(x1, y1, z0), Vector3(x1, y1, z1), col * 0.85, Vector3.RIGHT, detail)
		quad(Vector3(x0, y0, z0), Vector3(x0, y0, z1), Vector3(x0, y1, z1), Vector3(x0, y1, z0), col * 0.85, Vector3.LEFT, detail)
	## Satteldach ueber Grundflaeche, First entlang der laengeren Seite
	func gable(pos: Vector3, size: Vector3, rh: float, col: Color, detail := 0.0) -> void:
		var x0 := pos.x - size.x * 0.5
		var x1 := pos.x + size.x * 0.5
		var z0 := pos.z - size.z * 0.5
		var z1 := pos.z + size.z * 0.5
		var y0 := pos.y
		var y1 := pos.y + rh
		if size.x >= size.z:
			var zm := pos.z
			var r0 := Vector3(x0, y1, zm)
			var r1 := Vector3(x1, y1, zm)
			var n_s := Vector3(0, size.z * 0.5, rh).normalized()
			var n_n := Vector3(0, size.z * 0.5, -rh).normalized()
			quad(Vector3(x0, y0, z1), Vector3(x1, y0, z1), r1, r0, col, n_s, detail)
			quad(Vector3(x1, y0, z0), Vector3(x0, y0, z0), r0, r1, col * 0.9, n_n, detail)
			tri(Vector3(x0, y0, z0), Vector3(x0, y0, z1), r0, col * 0.8, Vector3.LEFT, detail)
			tri(Vector3(x1, y0, z1), Vector3(x1, y0, z0), r1, col * 0.8, Vector3.RIGHT, detail)
		else:
			var xm := pos.x
			var r0 := Vector3(xm, y1, z0)
			var r1 := Vector3(xm, y1, z1)
			var n_e := Vector3(rh, size.x * 0.5, 0).normalized()
			var n_w := Vector3(-rh, size.x * 0.5, 0).normalized()
			quad(Vector3(x1, y0, z1), Vector3(x1, y0, z0), r0, r1, col, n_e, detail)
			quad(Vector3(x0, y0, z0), Vector3(x0, y0, z1), r1, r0, col * 0.9, n_w, detail)
			tri(Vector3(x0, y0, z1), Vector3(x1, y0, z1), r1, col * 0.8, Vector3.BACK, detail)
			tri(Vector3(x1, y0, z0), Vector3(x0, y0, z0), r0, col * 0.8, Vector3.FORWARD, detail)
	## Zylinder/Kegelstumpf, pos = Mitte der Grundflaeche
	func cyl(pos: Vector3, r_bot: float, r_top: float, h: float, col: Color, sides := 12, detail := 0.0) -> void:
		var top := pos + Vector3(0, h, 0)
		for i in sides:
			var a0 := TAU * float(i) / sides
			var a1 := TAU * float(i + 1) / sides
			var d0 := Vector3(cos(a0), 0, sin(a0))
			var d1 := Vector3(cos(a1), 0, sin(a1))
			var am := (a0 + a1) * 0.5
			var out := Vector3(cos(am), (r_bot - r_top) / maxf(h, 0.01), sin(am))
			var shade := 0.82 + 0.18 * (0.5 + 0.5 * cos(am - 0.9))
			if r_top > 0.01:
				quad(pos + d0 * r_bot, pos + d1 * r_bot, top + d1 * r_top, top + d0 * r_top, col * shade, out, detail)
				tri(top, top + d0 * r_top, top + d1 * r_top, col, Vector3.UP, detail)
			else:
				tri(pos + d0 * r_bot, pos + d1 * r_bot, top, col * shade, out, detail)
	func disc(pos: Vector3, r: float, col: Color, sides := 24) -> void:
		for i in sides:
			var a0 := TAU * float(i) / sides
			var a1 := TAU * float(i + 1) / sides
			tri(pos, pos + Vector3(cos(a0), 0, sin(a0)) * r, pos + Vector3(cos(a1), 0, sin(a1)) * r, col, Vector3.UP)
	func flat_rect(c: Vector2, sx: float, sz: float, y: float, col: Color) -> void:
		var x0 := c.x - sx * 0.5
		var x1 := c.x + sx * 0.5
		var z0 := c.y - sz * 0.5
		var z1 := c.y + sz * 0.5
		quad(Vector3(x0, y, z1), Vector3(x1, y, z1), Vector3(x1, y, z0), Vector3(x0, y, z0), col, Vector3.UP)
	## Band entlang Polylinie (xz). UV.x = Seite (-1/+1), UV2 = Lateralvektor -> Verbreiterung im Shader
	func ribbon(pts: PackedVector2Array, half_w: float, y: float, col: Color, detail := 0.0) -> void:
		var n := pts.size()
		var lat := PackedVector2Array()
		var sc := PackedFloat32Array()
		for i in n:
			var acc := Vector2.ZERO
			var first := Vector2.ZERO
			if i > 0:
				var l0 := _lat(pts[i] - pts[i - 1])
				acc += l0
				first = l0
			if i < n - 1:
				var l1 := _lat(pts[i + 1] - pts[i])
				acc += l1
				if first == Vector2.ZERO:
					first = l1
			var m := acc.normalized()
			lat.append(m)
			sc.append(1.0 / maxf(0.5, m.dot(first)))
		for i in n - 1:
			var p0 := pts[i]
			var p1 := pts[i + 1]
			var a := Vector3(p0.x - lat[i].x * half_w * sc[i], y, p0.y - lat[i].y * half_w * sc[i])
			var b := Vector3(p0.x + lat[i].x * half_w * sc[i], y, p0.y + lat[i].y * half_w * sc[i])
			var c := Vector3(p1.x + lat[i + 1].x * half_w * sc[i + 1], y, p1.y + lat[i + 1].y * half_w * sc[i + 1])
			var d := Vector3(p1.x - lat[i + 1].x * half_w * sc[i + 1], y, p1.y - lat[i + 1].y * half_w * sc[i + 1])
			# Dreiecke einzeln, damit UV.x (Seite) und UV2 (Lateral) je Vertex gesetzt sind
			tri(a, b, c, col, Vector3.UP, detail, Vector3(-1, 1, 1), lat[i], lat[i], lat[i + 1])
			tri(a, c, d, col, Vector3.UP, detail, Vector3(-1, 1, -1), lat[i], lat[i + 1], lat[i + 1])
	static func _lat(d: Vector2) -> Vector2:
		return Vector2(-d.y, d.x).normalized()
	func commit() -> ArrayMesh:
		return st.commit()

# ---------------------------------------------------------------- Hilfsfunktionen Pfade

func _lat(d: Vector2) -> Vector2:
	return Vector2(-d.y, d.x).normalized()

func offset_poly(p: PackedVector2Array, d: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in p.size():
		var acc := Vector2.ZERO
		var first := Vector2.ZERO
		if i > 0:
			first = _lat(p[i] - p[i - 1])
			acc += first
		if i < p.size() - 1:
			var l1 := _lat(p[i + 1] - p[i])
			acc += l1
			if first == Vector2.ZERO:
				first = l1
		var m := acc.normalized()
		out.append(p[i] + m * d / maxf(0.5, m.dot(first)))
	return out

func make_path(pname: String, pts: PackedVector2Array) -> void:
	var cum := PackedFloat32Array([0.0])
	for i in range(1, pts.size()):
		cum.append(cum[i - 1] + pts[i].distance_to(pts[i - 1]))
	paths[pname] = {"pts": pts, "cum": cum, "length": cum[cum.size() - 1]}

func sample_path(pname: String, s: float) -> Dictionary:
	var p: Dictionary = paths[pname]
	var pts: PackedVector2Array = p["pts"]
	var cum: PackedFloat32Array = p["cum"]
	var L: float = p["length"]
	s = clampf(s, 0.0, L - 0.01)
	var i := 0
	while i < pts.size() - 2 and cum[i + 1] < s:
		i += 1
	var seg_t := (s - cum[i]) / maxf(cum[i + 1] - cum[i], 0.001)
	var pos := pts[i].lerp(pts[i + 1], seg_t)
	return {"pos": pos, "dir": (pts[i + 1] - pts[i]).normalized()}

func dist_to_poly(pt: Vector2, p: PackedVector2Array) -> float:
	var best := 1e9
	for i in p.size() - 1:
		var cp := Geometry2D.get_closest_point_to_segment(pt, p[i], p[i + 1])
		best = minf(best, cp.distance_to(pt))
	return best

# ---------------------------------------------------------------- Materialien

func make_mat(params: Dictionary, shader_path := "res://look.gdshader") -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(shader_path)
	for k in params:
		m.set_shader_parameter(k, params[k])
	mats.append(m)
	return m

func build_materials() -> void:
	obj_mat = make_mat({"use_detail": 1.0, "desat_amount": 0.5})
	track_mat = make_mat({"network": 1.0, "desat_amount": 0.0, "map_color": Vector3(C_ORANGE.r, C_ORANGE.g, C_ORANGE.b), "emission_lift": 0.5})
	rail_mat = make_mat({"network": 1.0, "desat_amount": 0.0, "map_color": Vector3(C_ORANGE.r, C_ORANGE.g, C_ORANGE.b), "emission_lift": 0.5})
	casing_mat = make_mat({"network": 1.0, "desat_amount": 0.0, "map_color": Vector3(0.16, 0.17, 0.19), "emission_lift": 0.2})
	road_mat = make_mat({"network": 1.0, "desat_amount": 0.0, "map_color": Vector3(0.93, 0.91, 0.84), "emission_lift": 0.5})
	outline_mat = make_mat({"network": 1.0, "max_alpha": 1.0, "emission_lift": 0.0}, "res://look_alpha.gdshader")
	patch_mat = make_mat({"max_alpha": 0.88, "emission_lift": 0.3}, "res://look_alpha.gdshader")
	ground_mat = make_mat({"ground_pattern": 1.0, "desat_amount": 0.35, "flatten_on": 0.0, "emission_lift": 0.4})
	veh_mat = make_mat({"flatten_on": 0.0, "desat_amount": 0.0, "emission_lift": 0.6})
	tree_mat = make_mat({"desat_amount": 0.6, "flatten_min": 0.3, "map_color": Vector3(0.40, 0.49, 0.37)})

func add_mesh(mesh: Mesh, mat: Material, nname: String, shadows := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.name = nname
	if not shadows:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi

# ---------------------------------------------------------------- Szene

func _ready() -> void:
	args = OS.get_cmdline_user_args()
	rng.seed = 1947
	Engine.max_fps = 0
	hard_switch = "--hard" in args
	if "--shots" in args: mode = "shots"
	elif "--clicktest" in args or "--selftest" in args: mode = "clicktest"
	elif "--far" in args: mode = "far"
	elif "--strip" in args: mode = "strip"
	elif "--popping" in args: mode = "popping"
	elif "--fly" in args: mode = "fly"
	elif "--movie" in args: mode = "movie"
	build_materials()
	build_environment()
	build_ground()
	build_network()
	build_town()
	build_farm()
	build_mill()
	build_trees()
	build_vehicles()
	build_icons_labels()
	build_hud()
	if "--nohud" in args or mode == "clicktest":
		hud.visible = false
	apply_height(H_MIN)
	print("S-03 Look-Test gestartet, Modus: ", mode, " hart=", hard_switch)
	print("Renderer: ", RenderingServer.get_current_rendering_method(), " / Treiber: ", RenderingServer.get_current_rendering_driver_name(), " / Adapter: ", RenderingServer.get_video_adapter_name())
	if mode in ["shots", "strip", "popping", "far"]:
		animate = false
		call_deferred("run_sequence")
	elif mode == "fly":
		call_deferred("run_fly_measure")
	elif mode == "clicktest":
		animate = false
		call_deferred("setup_clicktest")

func build_environment() -> void:
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.45, 0.58, 0.78)
	sm.sky_horizon_color = Color(0.74, 0.80, 0.88)
	sm.ground_horizon_color = Color(0.74, 0.80, 0.88)
	sm.ground_bottom_color = Color(0.60, 0.66, 0.72)
	sky.sky_material = sm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.78, 0.83, 0.92)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.70, 0.78, 0.88)
	env.fog_density = 0.00035
	env.fog_sky_affect = 0.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, 35, 0)
	sun.light_energy = 1.25
	sun.light_color = Color(1.0, 0.96, 0.88)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 450.0
	add_child(sun)
	cam = Camera3D.new()
	cam.fov = FOV_DEG
	cam.near = 2.0
	cam.far = 8000.0
	cam.current = true
	add_child(cam)

func build_ground() -> void:
	var mb := MB.new()
	mb.flat_rect(Vector2(0, 0), 9000.0, 9000.0, 0.0, C_GRASS)
	add_mesh(mb.commit(), ground_mat, "Boden", false)

func build_network() -> void:
	# Gleis: Farm -> (45 Grad SE) -> durch die Stadt auf z=-30 -> (45 Grad NE) -> Stahlwerk
	track_pts = PackedVector2Array([Vector2(-500, -250), Vector2(-420, -250), Vector2(-200, -30),
		Vector2(200, -30), Vector2(340, -170), Vector2(480, -170)])
	# Strasse: Farm -> Stadt-Hauptstrasse z=-90 -> Stahlwerk (Sued-Kante)
	road_pts = PackedVector2Array([Vector2(-500, -290), Vector2(-300, -290), Vector2(-100, -90),
		Vector2(560, -90), Vector2(560, -150)])
	var tA := offset_poly(track_pts, -4.5)
	var tB := offset_poly(track_pts, 4.5)
	var mt := MB.new()
	var mr := MB.new()
	for tr in [tA, tB]:
		mt.ribbon(tr, 2.0, 0.22, C_BALLAST)
		mr.ribbon(offset_poly(tr, -0.75), 0.18, 0.3, C_RAIL)
		mr.ribbon(offset_poly(tr, 0.75), 0.18, 0.3, C_RAIL)
	var mc := MB.new()   # Casing: dunkler Saum unter Gleis und Strasse (S-05: Netz muss auch in Graustufen stehen)
	for tr in [tA, tB]:
		mc.ribbon(tr, 3.3, 0.16, Color(0.30, 0.28, 0.26))
	mc.ribbon(road_pts, 5.3, 0.08, Color(0.22, 0.22, 0.23))
	add_mesh(mc.commit(), casing_mat, "Netz_Casing", false)
	add_mesh(mt.commit(), track_mat, "Gleis", false)
	add_mesh(mr.commit(), rail_mat, "Schienen", false)
	var mro := MB.new()
	mro.ribbon(road_pts, 4.0, 0.12, C_ROAD)
	add_mesh(mro.commit(), road_mat, "Strasse", false)
	make_path("trainA", tA)
	var tBrev := PackedVector2Array()
	for i in range(tB.size() - 1, -1, -1):
		tBrev.append(tB[i])
	make_path("trainB", tBrev)
	var rA := offset_poly(road_pts, -2.0)
	var rB := offset_poly(road_pts, 2.0)
	var rBrev := PackedVector2Array()
	for i in range(rB.size() - 1, -1, -1):
		rBrev.append(rB[i])
	make_path("roadA", rA)
	make_path("roadB", rBrev)

func build_town() -> void:
	var mb := MB.new()    # Gebaeude + Strassen im Ort
	var mp := MB.new()    # nur Karte: Flaeche
	var mo := MB.new()    # nur Karte: Umriss
	var wall_cols := [Color(0.84, 0.76, 0.62), Color(0.78, 0.68, 0.55), Color(0.86, 0.82, 0.70), Color(0.72, 0.64, 0.54)]
	var roof_cols := [Color(0.62, 0.30, 0.22), Color(0.52, 0.28, 0.24), Color(0.36, 0.36, 0.40), Color(0.58, 0.34, 0.24)]
	# Stadtflaeche (Pflaster) und Strassenraster
	mb.flat_rect(Vector2.ZERO, 316.0, 316.0, 0.06, Color(0.70, 0.67, 0.60))
	for k in 6:
		var c := -150.0 + 60.0 * k
		if absf(c - (-30.0)) > 0.1:   # z=-30 ist die Bahntrasse
			mb.flat_rect(Vector2(0, c), 316.0, 10.0, 0.14, C_ROAD)
		mb.flat_rect(Vector2(c, 0), 10.0, 316.0, 0.13, C_ROAD)
	# Kartenflaeche + Umriss
	mp.flat_rect(Vector2.ZERO, 330.0, 330.0, 0.5, Color(0.80, 0.74, 0.62))
	var ring := PackedVector2Array([Vector2(-165, -165), Vector2(165, -165), Vector2(165, 165), Vector2(-165, 165), Vector2(-165, -165)])
	mo.ribbon(ring, 2.0, 0.7, Color(0.30, 0.26, 0.22))
	# Blocks
	var n_houses := 0
	for bx in 5:
		for bz in 5:
			var c := Vector2(-120.0 + 60.0 * bx, -120.0 + 60.0 * bz)
			var d := c.length() / 170.0   # 0 = Kern, 1 = Rand
			mb.flat_rect(c, 26.0, 26.0, 0.16, Color(0.46, 0.55, 0.38))   # Rasen im Blockinneren
			var slots: Array[Vector2] = []
			for k in [-15.0, -5.0, 5.0, 15.0]:
				slots.append(Vector2(c.x + k, c.y - 17.0))
				slots.append(Vector2(c.x + k, c.y + 17.0))
			for k in [-5.0, 5.0]:
				slots.append(Vector2(c.x - 17.0, c.y + k))
				slots.append(Vector2(c.x + 17.0, c.y + k))
			for s in slots:
				if absf(s.y - (-30.0)) < 13.0:
					continue   # Bahntrasse freihalten
				var core := d < 0.30
				var h := 0.0
				if core:
					h = rng.randf_range(18.0, 26.0)
				else:
					h = lerpf(14.0, 6.0, clampf((d - 0.3) / 0.7, 0.0, 1.0)) + rng.randf_range(-1.0, 1.5)
				var wc: Color = wall_cols[rng.randi() % wall_cols.size()]
				var rc: Color = roof_cols[rng.randi() % roof_cols.size()]
				mb.box(Vector3(s.x, 0, s.y), Vector3(9, h, 9), wc)
				if core:
					mb.box(Vector3(s.x, h, s.y), Vector3(8, 1.2, 8), Color(0.60, 0.58, 0.55))
				else:
					mb.gable(Vector3(s.x, h, s.y), Vector3(9.8, h, 9.8), 3.5 + (1.0 if d < 0.6 else 0.0), rc)
					mb.box(Vector3(s.x + 1.5, h + 1.0, s.y), Vector3(1.0, 3.5, 1.0), Color(0.45, 0.30, 0.25), 1.0)   # Detail
				n_houses += 1
	# Kirchturm im Zentrum
	mb.box(Vector3(0, 0, 0), Vector3(9, 30, 9), Color(0.78, 0.74, 0.68))
	mb.cyl(Vector3(0, 30, 0), 7.0, 0.0, 12.0, Color(0.30, 0.36, 0.38), 4)
	# Bahnhof am Westrand
	mb.box(Vector3(-176, 0, -48), Vector3(18, 8, 10), Color(0.80, 0.70, 0.55))
	mb.gable(Vector3(-176, 8, -48), Vector3(19, 10, 11), 4.5, Color(0.5, 0.28, 0.24))
	mb.box(Vector3(-176, 0.3, -38.5), Vector3(70, 0.9, 3.5), Color(0.62, 0.60, 0.56), 1.0)
	add_mesh(mb.commit(), obj_mat, "Stadt")
	add_mesh(mp.commit(), patch_mat, "Stadt_Flaeche_Karte", false)
	add_mesh(mo.commit(), outline_mat, "Stadt_Umriss_Karte", false)
	print("Haeuser: ", n_houses)

func build_farm() -> void:
	var mb := MB.new()
	var mp := MB.new()
	var cx := FARM_C.x
	var cz := FARM_C.y
	mb.flat_rect(FARM_C, FARM_SIZE, FARM_SIZE, 0.07, Color(0.62, 0.59, 0.52))
	var fcols := [Color(0.76, 0.68, 0.45), Color(0.58, 0.63, 0.45), Color(0.72, 0.64, 0.42), Color(0.52, 0.58, 0.44)]
	var k := 0
	for fx in [-1, 0, 1]:
		for fz in [-1, 0, 1]:
			if fx == 0 and fz == 0:
				continue
			mb.flat_rect(Vector2(cx + fx * 100.0, cz + fz * 100.0), 96.0, 96.0, 0.05, fcols[k % 4])
			k += 1
	mb.box(Vector3(cx - 22, 0, cz - 20), Vector3(30, 11, 14), Color(0.66, 0.30, 0.24))
	mb.gable(Vector3(cx - 22, 11, cz - 20), Vector3(31, 14, 15), 6.0, Color(0.38, 0.26, 0.22))
	mb.box(Vector3(cx - 28, 0, cz + 14), Vector3(26, 6, 9), Color(0.76, 0.66, 0.50))
	mb.gable(Vector3(cx - 28, 6, cz + 14), Vector3(27, 9, 10), 3.5, Color(0.5, 0.28, 0.24))
	mb.box(Vector3(cx + 20, 0, cz + 20), Vector3(12, 7, 10), Color(0.84, 0.78, 0.64))
	mb.gable(Vector3(cx + 20, 7, cz + 20), Vector3(13, 10, 11), 4.0, Color(0.58, 0.32, 0.24))
	mb.cyl(Vector3(cx + 10, 0, cz - 15), 5.5, 5.5, 20.0, Color(0.66, 0.68, 0.70), 14)
	mb.cyl(Vector3(cx + 10, 20, cz - 15), 5.6, 0.0, 4.0, Color(0.42, 0.44, 0.48), 14)
	mb.cyl(Vector3(cx + 24, 0, cz - 15), 5.0, 5.0, 17.0, Color(0.66, 0.68, 0.70), 14)
	mb.cyl(Vector3(cx + 24, 17, cz - 15), 5.1, 0.0, 3.6, Color(0.42, 0.44, 0.48), 14)
	mb.cyl(Vector3(cx + 3, 0, cz + 2), 9.0, 0.0, 6.0, C_GRAIN, 10)     # Getreidehalde = Lagergut in Gueterfarbe
	mb.cyl(Vector3(cx + 10, 14, cz - 15), 5.7, 5.7, 1.6, C_GRAIN, 14)  # Familien-Akzent am Silo
	mp.flat_rect(FARM_C, 150.0, 150.0, 0.5, Color(0.80, 0.72, 0.46))
	add_mesh(mb.commit(), obj_mat, "Farm")
	add_mesh(mp.commit(), patch_mat, "Farm_Flaeche_Karte", false)

func build_mill() -> void:
	var mb := MB.new()
	var mp := MB.new()
	var cx := MILL_C.x
	var cz := MILL_C.y
	mb.flat_rect(MILL_C, MILL_SIZE, MILL_SIZE, 0.07, Color(0.56, 0.56, 0.55))
	mb.cyl(Vector3(cx - 20, 0, cz - 25), 11.0, 7.0, 42.0, Color(0.50, 0.50, 0.53), 14)   # Hochofen
	mb.cyl(Vector3(cx - 20, 42, cz - 25), 7.0, 3.0, 6.0, Color(0.40, 0.40, 0.44), 14)
	mb.box(Vector3(cx - 20, 0, cz - 5), Vector3(4, 40, 4), Color(0.45, 0.45, 0.48))
	var hs := [72.0, 80.0, 66.0]
	for i in 3:
		mb.cyl(Vector3(cx + 14 + i * 12, 0, cz - 32), 2.8, 2.0, hs[i], Color(0.58, 0.50, 0.46), 10)
		mb.cyl(Vector3(cx + 14 + i * 12, hs[i] - 6.0, cz - 32), 2.35, 2.35, 1.4, C_STEEL, 10)
	mb.box(Vector3(cx + 10, 0, cz + 14), Vector3(90, 14, 28), Color(0.56, 0.56, 0.60))
	for i in 4:
		var hx := cx - 24.0 + i * 22.5
		mb.gable(Vector3(hx, 14, cz + 14), Vector3(22.5, 28, 28.5), 6.0, C_STEEL)
	mb.box(Vector3(cx - 45, 0, cz + 22), Vector3(26, 26, 30), Color(0.52, 0.52, 0.56))
	mb.gable(Vector3(cx - 45, 26, cz + 22), Vector3(27, 30, 31), 5.0, C_STEEL)
	for i in 3:
		mb.cyl(Vector3(cx - 50 + i * 20, 0, cz + 60), 9.0, 0.0, 7.5, C_STEEL, 10)   # Erzhalden
	mb.box(Vector3(cx + 40, 0, cz + 52), Vector3(3, 18, 3), Color(0.50, 0.40, 0.2), 1.0)
	mb.box(Vector3(cx + 40, 18, cz + 52), Vector3(26, 2, 3), Color(0.50, 0.40, 0.2), 1.0)
	mp.flat_rect(MILL_C, 170.0, 170.0, 0.5, Color(0.56, 0.64, 0.76))
	add_mesh(mb.commit(), obj_mat, "Stahlwerk")
	add_mesh(mp.commit(), patch_mat, "Stahlwerk_Flaeche_Karte", false)
	var ml := MB.new()
	ml.disc(Vector3(250, 0.35, 250), 160.0, Color(0.42, 0.58, 0.68), 32)   # Weiher fuer Kartenfarbe
	add_mesh(ml.commit(), obj_mat, "Weiher", false)

func tree_free(p: Vector2) -> bool:
	if absf(p.x) < TOWN_HALF + 25.0 and absf(p.y) < TOWN_HALF + 25.0:
		return false
	if dist_to_poly(p, track_pts) < 22.0 or dist_to_poly(p, road_pts) < 16.0:
		return false
	if absf(p.x - FARM_C.x) < FARM_SIZE * 0.5 + 15.0 and absf(p.y - FARM_C.y) < FARM_SIZE * 0.5 + 15.0:
		return false
	if absf(p.x - MILL_C.x) < MILL_SIZE * 0.5 + 15.0 and absf(p.y - MILL_C.y) < MILL_SIZE * 0.5 + 15.0:
		return false
	if p.distance_to(Vector2(250, 250)) < 175.0:
		return false
	return true

func build_trees() -> void:
	# Baum-Mesh: kurzer Stamm + Krone (Kegel). Kronenradius 4,2 m (= 0,42 Feld), Gesamthoehe 12 m
	var mb := MB.new()
	mb.cyl(Vector3.ZERO, 0.45, 0.35, 2.4, Color(0.60, 0.50, 0.42), 6)
	mb.cyl(Vector3(0, 2.0, 0), 4.2, 0.0, 10.0, Color(1, 1, 1), 8)
	var tmesh := mb.commit()
	var pos: Array[Vector3] = []
	var clusters := [Vector3(-380, 80, 150), Vector3(380, 130, 120), Vector3(150, -380, 110), Vector3(-160, -400, 100),
		Vector3(-450, -470, 100), Vector3(700, -80, 70), Vector3(-700, 120, 90), Vector3(40, 260, 90), Vector3(-260, 250, 70)]
	for c in clusters:
		var tries := 0
		var placed := 0
		while placed < 70 and tries < 600:
			tries += 1
			var p := Vector2(c.x, c.y) + Vector2(rng.randfn(0.0, c.z * 0.45), rng.randfn(0.0, c.z * 0.45))
			if tree_free(p):
				pos.append(Vector3(p.x, 0, p.y))
				placed += 1
	for bx in 5:
		for bz in 5:
			var c := Vector2(-120.0 + 60.0 * bx, -120.0 + 60.0 * bz)
			for i in 2:
				var p := c + Vector2(rng.randf_range(-8, 8), rng.randf_range(-8, 8))
				if absf(p.y - (-30.0)) > 14.0:
					pos.append(Vector3(p.x, 0, p.y))
	tree_mm = MultiMesh.new()
	tree_mm.transform_format = MultiMesh.TRANSFORM_3D
	tree_mm.use_colors = true
	tree_mm.mesh = tmesh
	tree_mm.instance_count = pos.size()
	for i in pos.size():
		var sc := rng.randf_range(0.75, 1.3)
		var b := Basis(Vector3.UP, rng.randf() * TAU) * Basis.from_scale(Vector3(sc, sc * rng.randf_range(0.9, 1.15), sc))
		tree_mm.set_instance_transform(i, Transform3D(b, pos[i]))
		var g := rng.randf_range(0.0, 1.0)
		tree_mm.set_instance_color(i, Color(lerpf(0.30, 0.38, g), lerpf(0.40, 0.48, g), lerpf(0.25, 0.30, g)))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = tree_mm
	mmi.material_override = tree_mat
	mmi.name = "Baeume_MultiMesh"
	add_child(mmi)
	print("Baeume (zweites MultiMesh, nicht Teil der 200): ", pos.size())

func build_vehicles() -> void:
	var bm := BoxMesh.new()
	bm.size = Vector3.ONE
	veh_mm = MultiMesh.new()
	veh_mm.transform_format = MultiMesh.TRANSFORM_3D
	veh_mm.use_colors = true
	veh_mm.mesh = bm
	veh_mm.instance_count = 200
	var idx := 0
	# 8 Zuege a 8 Wagen = 64 Instanzen (je 4 pro Richtung), Wagen 9 m, Abstand 11 m -> Zug ca. 88 m
	for dir_i in 2:
		var pname := "trainA" if dir_i == 0 else "trainB"
		var L: float = paths[pname]["length"]
		for tr in 4:
			var head := L * (float(tr) / 4.0) + dir_i * L * 0.13
			for car in 8:
				var col := C_ORANGE if car == 0 else (C_GRAIN if dir_i == 0 else C_STEEL)
				veh_data.append({"path": pname, "s0": head - car * 11.0, "speed": 18.0, "len": 9.0 if car > 0 else 10.0, "hgt": 3.6, "wid": 3.2, "col": col, "y": 1.9})
				idx += 1
	# Lkw (10 m = 1 Feld lang) auf der Strasse, beide Richtungen
	var tcols := [C_GRAIN, C_STEEL, C_WOOD, C_ENERGY, C_FOOD, C_GRAIN, C_STEEL]
	var n_trucks := 200 - idx
	for i in n_trucks:
		var pname := "roadA" if i % 2 == 0 else "roadB"
		var L: float = paths[pname]["length"]
		veh_data.append({"path": pname, "s0": rng.randf() * L, "speed": rng.randf_range(10.0, 14.0), "len": 10.0, "hgt": 3.0, "wid": 2.6, "col": tcols[rng.randi() % tcols.size()], "y": 1.7})
	for i in 200:
		veh_mm.set_instance_color(i, veh_data[i]["col"])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = veh_mm
	mmi.material_override = veh_mat
	mmi.name = "Fahrzeuge_MultiMesh_200"
	add_child(mmi)
	update_vehicles(0.0)
	print("Fahrzeug-Instanzen im MultiMesh: ", veh_mm.instance_count, " (Zugwagen ", idx, ", Lkw ", n_trucks, ")")

var veh_time := 0.0
func update_vehicles(delta: float) -> void:
	veh_time += delta
	for i in 200:
		var d: Dictionary = veh_data[i]
		var L: float = paths[d["path"]]["length"]
		var s := fposmod(float(d["s0"]) + float(d["speed"]) * veh_time, L)
		var smp := sample_path(d["path"], s)
		var p: Vector2 = smp["pos"]
		var dir: Vector2 = smp["dir"]
		# an den Pfadenden (Betriebe) ein-/ausblenden, damit das Umsetzen nicht sichtbar springt
		var edge := minf(s, L - s)
		var f := smoothstep(0.0, 40.0, edge)
		var ang := atan2(-dir.y, dir.x)
		var b := Basis(Vector3.UP, ang) * Basis.from_scale(Vector3(d["len"], d["hgt"], d["wid"]) * maxf(f, 0.001))
		veh_mm.set_instance_transform(i, Transform3D(b, Vector3(p.x, float(d["y"]) * f, p.y)))

func build_icons_labels() -> void:
	var defs := [
		{"pos": Vector3(FARM_C.x, 40, FARM_C.y), "kind": "farm", "col": Color(0.88, 0.72, 0.28), "label": "Farm (Industrie)"},
		{"pos": Vector3(MILL_C.x, 95, MILL_C.y), "kind": "steel", "col": Color(0.46, 0.60, 0.80), "label": "Stahlwerk (Industrie)"},
	]
	for d in defs:
		var sp := Sprite3D.new()
		sp.texture = make_icon(d["kind"], d["col"])
		sp.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sp.fixed_size = true
		sp.pixel_size = 0.00088          # ca. 56 px Bildschirmgroesse bei 720p, FOV 40
		sp.shaded = false
		sp.no_depth_test = true
		sp.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		sp.position = d["pos"]
		sp.visible = false
		sp.name = "Icon_" + str(d["kind"])
		add_child(sp)
		icons.append(sp)
		labels3d.append(make_label(str(d["label"]), d["pos"]))
	labels3d.append(make_label("Muehlbach (Stadt)", Vector3(0, 30, 0)))

func make_label(text: String, pos: Vector3) -> Label3D:
	var lb := Label3D.new()
	lb.text = text
	lb.fixed_size = true
	lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lb.pixel_size = 0.0007
	lb.font_size = 32
	lb.outline_size = 10
	lb.no_depth_test = true
	lb.position = pos
	lb.offset = Vector2(0, -60)
	lb.visible = false
	add_child(lb)
	return lb

func make_icon(kind: String, fill: Color) -> ImageTexture:
	var n := 64
	var img := Image.create_empty(n, n, true, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(31.5, 31.5)
	var dark := Color(0.09, 0.09, 0.11)
	for y in n:
		for x in n:
			var d := Vector2(x, y).distance_to(c)
			if d > 30.5:
				continue
			var col := Color(0.97, 0.97, 0.95)
			if d <= 28.0:
				col = fill
				if _sil(kind, float(x), float(y)):
					col = dark
			img.set_pixel(x, y, col)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

func _sil(kind: String, x: float, y: float) -> bool:
	if y > 46.0 and y < 48.0 and x > 12.0 and x < 52.0:
		return true   # Boden
	if kind == "farm":
		if x >= 17.0 and x <= 29.0 and y >= 24.0 and y <= 46.0:
			return true   # Rundsilo
		if y < 24.0 and Vector2(x, y).distance_to(Vector2(23.0, 24.0)) <= 6.0:
			return true   # Kuppel
		if x >= 32.0 and x <= 49.0 and y >= 34.0 and y <= 46.0:
			return true   # Scheune
		if y >= 26.0 and y < 34.0 and absf(x - 40.5) <= (y - 26.0) * 1.1 + 0.5:
			return true   # Satteldach
	else:
		if y >= 18.0 and y <= 46.0 and absf(x - 22.0) <= 4.0 + (y - 18.0) * 0.18:
			return true   # Hochofen
		if x >= 33.0 and x <= 36.5 and y >= 12.0 and y <= 46.0:
			return true
		if x >= 38.5 and x <= 42.0 and y >= 16.0 and y <= 46.0:
			return true
		if x >= 44.0 and x <= 47.5 and y >= 22.0 and y <= 46.0:
			return true   # 3 Schornsteine
		if x >= 14.0 and x <= 50.0 and y >= 40.0 and y <= 46.0:
			return true   # Halle
	return false

func build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Label.new()
	hud.position = Vector2(10, 6)
	hud.add_theme_font_size_override("font_size", 16)
	hud.add_theme_color_override("font_color", Color(1, 1, 1))
	hud.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	hud.add_theme_constant_override("outline_size", 5)
	layer.add_child(hud)

# ---------------------------------------------------------------- Kamera + Blend

func tlog(h: float) -> float:
	return clampf(log(h / H_MIN) / log(H_MAX / H_MIN), 0.0, 1.0)

func pitch_for(h: float) -> float:
	return lerpf(30.0, 70.0, smoothstep(0.0, 1.0, tlog(h)))

func blend_mid(h: float) -> float:
	if hard_switch:
		return 1.0 if h >= MID_C else 0.0
	return smoothstep(MID_C - MID_W, MID_C + MID_W, h)

func blend_map(h: float) -> float:
	if hard_switch:
		return 1.0 if h >= MAP_C else 0.0
	return smoothstep(MAP_C - MAP_W, MAP_C + MAP_W, h)

func apply_height(h: float) -> void:
	cur_h = h
	var s := smoothstep(0.0, 1.0, tlog(h))
	var focus := FOCUS_NEAR.lerp(FOCUS_FAR, s)
	var p := deg_to_rad(pitch_for(h))
	var dist := h / sin(p)
	cam.position = focus + Vector3(0, h, dist * cos(p))
	cam.look_at(focus, Vector3.UP)
	var mid := blend_mid(h)
	var mp := blend_map(h)
	cur_mid = mid
	cur_map = mp
	for m in mats:
		m.set_shader_parameter("map_blend", mp)
		m.set_shader_parameter("mid_blend", mid)
	# Netz-Verbreiterung (Halbbreite in m, wachsend mit Hoehe) und Fahrzeug-Skalierung
	var wd := h * (0.0006 * mid + 0.0010 * mp)
	track_mat.set_shader_parameter("widen", wd)
	road_mat.set_shader_parameter("widen", wd)
	casing_mat.set_shader_parameter("widen", wd + 1.5 * mp)
	rail_mat.set_shader_parameter("widen", -0.18 * mid)   # Schienen schrumpfen auf Breite 0 (Detail)
	outline_mat.set_shader_parameter("widen", h * 0.0012 * mp)
	veh_mat.set_shader_parameter("veh_scale", 1.0 + h * (0.0006 * mid + 0.0012 * mp))
	# Schatten nur in Nah
	# (shadow_opacity wirkte im Compatibility-Renderer nicht sichtbar -> harter Sprung bei Abschalten, siehe measure/)
	# Stattdessen: Schattenreichweite relativ zur Kameradistanz schrumpfen, Rand blendet weich aus.
	var sf := smoothstep(120.0, 300.0, h)
	sun.directional_shadow_fade_start = 0.4
	sun.directional_shadow_max_distance = dist * lerpf(1.7, 0.30, sf)
	sun.shadow_enabled = true   # nicht abschalten: Abschalten aendert im Compat-Renderer die Gesamthelligkeit (Sprung)
	# Nebel: in der Karte kaum, im Diorama Luftperspektive
	env.fog_density = lerpf(0.00035, 0.00002, mp)
	for sp in icons:
		sp.modulate = Color(1, 1, 1, mp)
		sp.visible = mp > 0.01
	var show_labels := "--labels" in args
	for lb in labels3d:
		lb.visible = show_labels
		lb.modulate = Color(1, 1, 1, clampf(0.3 + mp, 0.0, 1.0))
	if hud:
		hud.text = "Hoehe %4d m | Neigung %2d Grad | mid %.2f | map %.2f%s" % [int(h), int(pitch_for(h)), mid, mp, " | HART" if hard_switch else ""]

func height_at(t: float) -> float:
	# konstante Zoomrate (exponentiell): 50 -> 1000 m in FLY_SECONDS
	return H_MIN * pow(H_MAX / H_MIN, clampf(t / FLY_SECONDS, 0.0, 1.0))

var frame_times: Array = []
var script_ms: Array = []
var recording := false
var last_us := 0

func _process(delta: float) -> void:
	if recording:
		var now := Time.get_ticks_usec()
		if last_us > 0:
			frame_times.append(float(now - last_us) / 1000.0)
		last_us = now
	if mode == "clicktest":
		ct_tick()
		return
	if mode in ["shots", "strip", "popping", "far", "fly"]:
		return
	if animate:
		update_vehicles(delta)
	if not paused:
		t_fly += delta
		if mode == "movie":
			if t_fly > FLY_SECONDS + 0.4:
				get_tree().quit()
			apply_height(height_at(t_fly))
		else:
			apply_height(height_at(fposmod(t_fly, FLY_SECONDS + 1.0)))

func _unhandled_input(e: InputEvent) -> void:
	if mode == "clicktest":
		if e is InputEventKey and e.pressed and e.keycode == KEY_SPACE and ct_state == "wait_start":
			ct_next_prompt()
		elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and ct_state == "running":
			ct_register_click(e.position, Time.get_ticks_usec())
		return
	if e is InputEventKey and e.pressed:
		match e.keycode:
			KEY_SPACE:
				paused = not paused
			KEY_L:
				if "--labels" in args:
					args.remove_at(args.find("--labels"))
				else:
					args.append("--labels")
				apply_height(cur_h)
			KEY_H:
				hard_switch = not hard_switch
				apply_height(cur_h)
			KEY_1:
				paused = true
				apply_height(50.0)
			KEY_2:
				paused = true
				apply_height(150.0)
			KEY_3:
				paused = true
				apply_height(400.0)
			KEY_4:
				paused = true
				apply_height(800.0)
			KEY_5:
				paused = true
				apply_height(1000.0)

# ---------------------------------------------------------------- Messlaeufe und Screenshots

func out_dir(sub: String) -> String:
	var d := ProjectSettings.globalize_path("res://").path_join(sub)
	DirAccess.make_dir_recursive_absolute(d)
	return d

func grab(path: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(path)

func settle(n := 4) -> void:
	for i in n:
		await get_tree().process_frame

func run_sequence() -> void:
	await settle(6)
	if mode == "shots":
		var d := out_dir("shots_hard" if hard_switch else ("shots_labels" if "--labels" in args else ("stimulus_nohud" if "--nohud" in args else "shots")))
		var counters: PackedStringArray = ["height_m,objekte,drawcalls,primitive_dreiecke"]
		var hs: Array = [50, 150, 400, 800, 920, 1000]
		for a in args:
			if a.begins_with("--heights="):
				hs = []
				for x in a.substr(10).split(","):
					hs.append(int(x))
				d = out_dir("shots_custom")
		for h in hs:
			apply_height(float(h))
			await settle(4)
			await grab(d.path_join("zoom_%04dm.png" % h))
			counters.append("%d,%d,%d,%d" % [h, RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),
				RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
				RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)])
			print("Screenshot ", h, " m")
		if not hard_switch and not ("--labels" in args) and not ("--nohud" in args):
			var cf := FileAccess.open(out_dir("measure").path_join("szene_zaehler.csv"), FileAccess.WRITE)
			cf.store_string("\n".join(counters) + "\n")
			cf.close()
	elif mode == "far":
		var d := out_dir("shots_far")
		for h in [1500, 2500, 4000, 6000]:
			apply_height(float(h))
			await settle(4)
			await grab(d.path_join("far_%04dm.png" % h))
			print("Far ", h)
	elif mode == "strip":
		var d := out_dir("strip")
		for h in [640, 700, 760, 820, 880, 940]:
			apply_height(float(h))
			await settle(4)
			await grab(d.path_join("strip_%04dm.png" % h))
			print("Strip ", h)
	elif mode == "popping":
		var d := out_dir("measure")
		var steps := 150
		var prev := PackedByteArray()
		var rows: PackedStringArray = ["step,height_m,map_blend,mid_blend,mean_abs_diff_0_255"]
		for i in steps + 1:
			var h := H_MIN * pow(H_MAX / H_MIN, float(i) / steps)
			apply_height(h)
			await settle(3)
			await RenderingServer.frame_post_draw
			var img := get_viewport().get_texture().get_image()
			img.resize(256, 144, Image.INTERPOLATE_BILINEAR)
			img.convert(Image.FORMAT_RGB8)
			var cur := img.get_data()
			var diff := 0.0
			if prev.size() == cur.size():
				var acc := 0
				for k in cur.size():
					acc += absi(int(cur[k]) - int(prev[k]))
				diff = float(acc) / cur.size()
			prev = cur
			rows.append("%d,%.2f,%.3f,%.3f,%.4f" % [i, h, cur_map, cur_mid, diff])
		var f := FileAccess.open(d.path_join("popping_%s.csv" % ("hart" if hard_switch else "blend")), FileAccess.WRITE)
		f.store_string("\n".join(rows) + "\n")
		f.close()
		print("popping csv geschrieben")
	get_tree().quit()

func run_fly_measure() -> void:
	await settle(6)
	var res: Array = []
	for pass_i in 3:
		frame_times.clear()
		last_us = 0
		recording = true
		var t := 0.0
		var t0 := Time.get_ticks_usec()
		# Fahrt in Echtzeit, Kamerazeit = Wanduhr (so wirken lange Frames als Ruckler)
		while t < FLY_SECONDS:
			t = float(Time.get_ticks_usec() - t0) / 1e6
			var c0 := Time.get_ticks_usec()
			update_vehicles(0.016)
			apply_height(height_at(t))
			script_ms.append(float(Time.get_ticks_usec() - c0) / 1000.0)
			await get_tree().process_frame
		recording = false
		var sm: Array = script_ms.duplicate()
		script_ms.clear()
		sm.sort()
		var ft: Array = frame_times.duplicate()
		ft.sort()
		var n := ft.size()
		var sum := 0.0
		var over := 0
		for v in ft:
			sum += v
			if v > 33.3:
				over += 1
		res.append({
			"pass": pass_i + 1, "kalt": pass_i == 0, "frames": n,
			"mean_ms": snappedf(sum / maxf(n, 1), 0.01), "median_ms": snappedf(ft[n / 2], 0.01),
			"p95_ms": snappedf(ft[int(n * 0.95)], 0.01), "max_ms": snappedf(ft[n - 1], 0.01),
			"frames_ueber_33_3ms": over,
			"cpu_skriptzeit_median_ms": snappedf(sm[sm.size() / 2], 0.001), "cpu_skriptzeit_max_ms": snappedf(sm[sm.size() - 1], 0.001),
		})
	var out := {
		"renderer_method": RenderingServer.get_current_rendering_method(),
		"renderer_driver": RenderingServer.get_current_rendering_driver_name(),
		"adapter": RenderingServer.get_video_adapter_name(),
		"viewport": str(get_viewport().get_visible_rect().size),
		"hard_switch": hard_switch,
		"durchlaeufe": res,
	}
	var d := out_dir("measure")
	var f := FileAccess.open(d.path_join("flytime_%s.json" % ("hart" if hard_switch else "blend")), FileAccess.WRITE)
	f.store_string(JSON.stringify(out, "  "))
	f.close()
	print(JSON.stringify(out, "  "))
	get_tree().quit()

# ---------------------------------------------------------------- Klick-Test (Testaufbau fuer 4/6 Kollegen)
# Misst je Ziel (Stadt, Industrie, Strecke) die Zeit von der Aufforderung bis zum ersten Treffer.
# Ablauf: Leertaste = Start; Zielreihenfolge je Testperson nach Lateinischem Quadrat (--pid=1..6).
# --selftest: simulierte Klicks NUR zur Pruefung der Trefferzonen-Logik, KEINE Messdaten.
const ORDERS := [["Stadt", "Industrie", "Strecke"], ["Stadt", "Strecke", "Industrie"], ["Industrie", "Stadt", "Strecke"],
	["Industrie", "Strecke", "Stadt"], ["Strecke", "Stadt", "Industrie"], ["Strecke", "Industrie", "Stadt"]]
const CT_TIMEOUT_MS := 20000
var ct_state := "init"
var ct_targets: Array = []
var ct_i := 0
var ct_t0 := 0
var ct_pid := 1
var ct_height := 1000.0
var ct_rows: PackedStringArray = ["pid,ziel,hoehe_m,zeit_ms,treffer,klick_x,klick_y,unter_10s,hinweis"]
var ct_zones: Dictionary = {}
var ct_label: Label

func _proj(x: float, z: float, y := 0.5) -> Vector2:
	return cam.unproject_position(Vector3(x, y, z))

func _pa(poly: PackedVector2Array) -> Array:
	var out: Array = []
	for v in poly:
		out.append([snappedf(v.x, 0.1), snappedf(v.y, 0.1)])
	return out

func _square(c: Vector2, half: float) -> PackedVector2Array:
	return PackedVector2Array([_proj(c.x - half, c.y - half), _proj(c.x + half, c.y - half), _proj(c.x + half, c.y + half), _proj(c.x - half, c.y + half)])

func compute_zones() -> Dictionary:
	var z := {}
	z["Stadt"] = [_square(Vector2.ZERO, 165.0)]
	z["Industrie_polys"] = [_square(FARM_C, 75.0), _square(MILL_C, 85.0)]
	z["Industrie_icons"] = [cam.unproject_position(Vector3(FARM_C.x, 40, FARM_C.y)), cam.unproject_position(Vector3(MILL_C.x, 95, MILL_C.y))]
	var line := PackedVector2Array()
	for p in track_pts:
		line.append(_proj(p.x, p.y, 0.3))
	z["Strecke"] = line
	return z

func ct_in_zone(target: String, pos: Vector2) -> bool:
	if target == "Stadt":
		return Geometry2D.is_point_in_polygon(pos, ct_zones["Stadt"][0])
	if target == "Industrie":
		for poly in ct_zones["Industrie_polys"]:
			if Geometry2D.is_point_in_polygon(pos, poly):
				return true
		for c in ct_zones["Industrie_icons"]:
			if pos.distance_to(c) <= 34.0:
				return true
		return false
	var line: PackedVector2Array = ct_zones["Strecke"]
	for i in line.size() - 1:
		if Geometry2D.get_closest_point_to_segment(pos, line[i], line[i + 1]).distance_to(pos) <= 14.0:
			return true
	return false

func setup_clicktest() -> void:
	for a in args:
		if a.begins_with("--pid="):
			ct_pid = int(a.substr(6))
		if a.begins_with("--height="):
			ct_height = float(a.substr(9))
	apply_height(ct_height)
	var layer := CanvasLayer.new()
	add_child(layer)
	ct_label = Label.new()
	ct_label.position = Vector2(0, 14)
	ct_label.size = Vector2(1280, 60)
	ct_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ct_label.add_theme_font_size_override("font_size", 30)
	ct_label.add_theme_color_override("font_color", Color(1, 1, 1))
	ct_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	ct_label.add_theme_constant_override("outline_size", 8)
	layer.add_child(ct_label)
	await settle(6)
	ct_zones = compute_zones()
	var zf := FileAccess.open(out_dir("clicktest").path_join("trefferzonen_%dm.json" % int(ct_height)), FileAccess.WRITE)
	var ip: Array = []
	for poly in ct_zones["Industrie_polys"]:
		ip.append(_pa(poly))
	var ic: Array = []
	for c in ct_zones["Industrie_icons"]:
		ic.append([snappedf(c.x, 0.1), snappedf(c.y, 0.1)])
	zf.store_string(JSON.stringify({"hoehe_m": ct_height, "aufloesung": "1280x720", "stadt_polygon": _pa(ct_zones["Stadt"][0]), "industrie_polygone": ip,
		"industrie_icon_zentren_radius_34px": ic, "strecke_polylinie_toleranz_14px": _pa(ct_zones["Strecke"])}, "  "))
	zf.close()
	ct_targets = ORDERS[(ct_pid - 1) % 6]
	if "--selftest" in args:
		ct_selftest()
		return
	ct_state = "wait_start"
	ct_label.text = "Testperson %d: Leertaste = Start" % ct_pid

func ct_next_prompt() -> void:
	if ct_i >= 3:
		ct_finish()
		return
	ct_state = "running"
	ct_label.text = "Klicke auf: %s" % str(ct_targets[ct_i]).to_upper()
	ct_t0 = Time.get_ticks_usec()

func ct_register_click(pos: Vector2, now_us: int) -> void:
	var target: String = ct_targets[ct_i]
	var t_ms := int((now_us - ct_t0) / 1000)
	var hit := ct_in_zone(target, pos)
	ct_rows.append("%d,%s,%d,%d,%d,%d,%d,%d," % [ct_pid, target, int(ct_height), t_ms, int(hit), int(pos.x), int(pos.y), int(hit and t_ms < 10000)])
	if hit:
		ct_i += 1
		ct_next_prompt()

func ct_tick() -> void:
	if ct_state == "running" and (Time.get_ticks_usec() - ct_t0) / 1000 > CT_TIMEOUT_MS:
		ct_rows.append("%d,%s,%d,%d,0,-1,-1,0,timeout" % [ct_pid, ct_targets[ct_i], int(ct_height), CT_TIMEOUT_MS])
		ct_i += 1
		ct_next_prompt()

func ct_finish() -> void:
	ct_state = "done"
	ct_label.text = "Danke!"
	var fname := "selftest.csv" if "--selftest" in args else "pid_%d.csv" % ct_pid
	var f := FileAccess.open(out_dir("clicktest").path_join(fname), FileAccess.WRITE)
	if "--selftest" in args:
		f.store_string("# FUNKTIONSTEST mit simulierten Klicks, KEINE Messdaten von Personen\n")
	f.store_string("\n".join(ct_rows) + "\n")
	f.close()
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()

func ct_selftest() -> void:
	# je Ziel: ein bewusster Fehlklick (Ecke), dann ein Klick in die Zone; Zeiten simuliert
	var good := {"Stadt": _proj(0, 0), "Industrie": cam.unproject_position(Vector3(FARM_C.x, 40, FARM_C.y)), "Strecke": _proj(0, -30, 0.3)}
	ct_state = "running"
	var fake_now := Time.get_ticks_usec()
	ct_t0 = fake_now
	while ct_i < 3:
		var tgt: String = ct_targets[ct_i]
		ct_register_click(Vector2(3, 3), fake_now + 1500000)
		ct_register_click(good[tgt], fake_now + 4000000)
		fake_now += 4000000
		ct_t0 = fake_now
