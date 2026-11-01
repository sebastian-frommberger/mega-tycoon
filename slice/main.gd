extends Node3D
## Mega Tycoon – Grey-Box-Slice (F-14, Sprint 4). Basis: Prototyp v3 (prototype/main.gd: UI, Bau-Tool,
## Lkw/Zug-Linien, Lager, Abriss). Neu gegenüber dem Prototyp:
##   (1) Karte 512² aus data/slice_map.json (S-10, eingefroren): Städte, Industrien K1–K3, Gelände in
##       2 Typen (Wasser = Fluss/Küste, Gebirge), Wald nur Deko; Grey-Box-Gebäude, Farben aus S-08.
##   (2) Ökonomie aus economy.gd + T-06-JSON: Ertrag nur beim Endabnehmer, Luftlinie, Lager 0 $, Sättigung,
##       Lizenzpflicht zum Laden. Fahrzeugkauf und Unterhalt aus vehicles.json, Lager-Unterhalt aus JSON.
##       Kein Kredit (S5): Kasse unter 0 $ = Bankrott.
##   (3) Start mit HQ: Startdialog Agrar/Bergbau, Klick-Panel mit Knopf „Lizenz kaufen“ (Preis, Ertrag/Monat).
##   (4) Ziele oben rechts mit „Nächster Schritt“ und gelbem Marker über dem Ziel.
## Alles wird im Code aufgebaut (keine Szenen außer main.tscn).

const Building := preload("res://building.gd")
const Vehicle := preload("res://vehicle.gd")
const Economy := preload("res://economy.gd")
const EcoShim := preload("res://eco_shim.gd")
const Bench := preload("res://bench.gd")

const MAP_PATH := "res://data/slice_map.json"
const SLICE_PATH := "res://data/economy_slice.json"
const CONSTS_PATH := "res://data/economy_constants.json"
const VEHICLES_PATH := "res://data/vehicles.json"
const GOODS_PATH := "res://data/goods.json"
const PALETTE_PATH := "res://data/palette_s08.json"

## Prototyp-Werte, die (noch) nicht im JSON stehen (ANNAHME, Genre-Standard OpenTTD; T-12 prüft):
const WATER_FACTOR := 6            # Brücke kostet das Sechsfache
const MOUNTAIN_FACTOR := 3         # Hang/Tunnel kostet das Dreifache
const BRIDGE_MAX := 8              # Brücke nur gerade, Land an beiden Enden, max. 8 Felder
const RAIL_CENT_PER_FIELD := 4000  # Gleis 40 $/Feld wie Prototyp (Baupreis Gleis fehlt im JSON)
const TRAIN_WAGONS := 4            # Zug = Lok + 4 Waggons (40 Einheiten wie Prototyp)
const TRUCK_MAX_WAIT_TICKS := 50   # Prototyp: 5 s warten auf volle Ladung
const TRAIN_MAX_WAIT_TICKS := 120  # Prototyp: 12 s

enum Terrain { PLAIN, WATER, MOUNTAIN }
enum Tool { NONE, ROAD, RAIL, WAREHOUSE, TRUCK_LINE, TRAIN_LINE, DEMOLISH }
const TOOL_NAMES := ["Auswahl", "Straße", "Gleis", "Lager", "Lkw-Linie", "Zug-Linie", "Abriss"]

const IND_NAMES := {"getreidefarm": "Getreidefarm", "muehle": "Mühle", "kohlemine": "Kohlemine", "erzmine": "Erzmine",
	"kraftwerk": "Kraftwerk", "stahlwerk": "Stahlwerk", "werkzeugfabrik": "Werkzeugfabrik", "holzfaeller": "Holzfäller"}
const IND_SIZE := {"getreidefarm": Vector2i(5, 5), "muehle": Vector2i(3, 3), "kohlemine": Vector2i(3, 3), "erzmine": Vector2i(3, 3),
	"kraftwerk": Vector2i(4, 3), "stahlwerk": Vector2i(4, 4), "werkzeugfabrik": Vector2i(4, 3), "holzfaeller": Vector2i(3, 3)}
const IND_HEIGHT := {"getreidefarm": 0.6, "muehle": 2.2, "kohlemine": 1.6, "erzmine": 1.6, "kraftwerk": 3.0,
	"stahlwerk": 3.2, "werkzeugfabrik": 2.4, "holzfaeller": 1.0}
const GOOD_COLORS := {"getreide": Color(0.95, 0.85, 0.3), "mehl": Color(1, 1, 1), "kohle": Color(0.12, 0.12, 0.12),
	"erz": Color(0.6, 0.38, 0.32), "stahl": Color(0.7, 0.72, 0.78), "werkzeug": Color(0.25, 0.45, 0.9), "holz": Color(0.45, 0.3, 0.15)}
const STAGE_NAMES := {"dorf": "Dorf", "kleinstadt": "Kleinstadt", "stadt": "Stadt", "metropole": "Metropole"}

## Startdialog und Ziel-Hinweise je Archetyp (Ketten aus L-08/D17, Orte aus slice_map.hq_optionen).
const ARCH := {
	"agrar": {"title": "Agrar", "src": "farm_1", "proc": "muehle_1", "m3_from": "muehle_1", "m3_to": "haberau",
		"m3_text": "Lizenz für die Mühle kaufen, Straße zu einer Stadt (Haberau nah, Mittelfurt weit und lohnender), Lkw-Linie Mühle → Stadt."},
	"bergbau": {"title": "Bergbau", "src": "kohle_1", "proc": "kraftwerk_1", "m3_from": "stahl_1", "m3_to": "werkzeug_1",
		"m3_text": "Erz und Kohle zum Stahlwerk fahren, Lizenz Stahlwerk kaufen, Stahl zur Werkzeugfabrik (weit: ein Zug lohnt sich)."},
}

# ---------------------------------------------------------------- Daten
var eco = null
var shim = null
var map_data: Dictionary = {}
var vdefs: Dictionary = {}          # vehicles.json id -> Dictionary
var good_names: Dictionary = {}
var palette: Dictionary = {}
var GRID := 512
var feld_mm := 1000
var tick_ms := 100
var periode_ticks := 600
var month_ticks := 600
var road_cent := 1000
var warehouse_cent := 0
var warehouse_upkeep := 0
var rail_upkeep_per_field := 0
var refund_promille := 500
var load_ticks := 100

var load_ms := 0.0                  # Kartenladezeit (JSON + Gelände + Gebäude + Wegegitter)
var ready_ms := 0.0                 # gesamtes _ready inkl. UI
var map_missing_ids: Array = []     # ID-Prüfung Karte <-> Ökonomie-JSON
var map_notes: Array = []

# ---------------------------------------------------------------- Zustand
var company_started := false
var archetyp := ""
var hq_city = null
var bankrupt := false
var speed := 0
var cost_acc := 0
var running_cost_per_period := 0
var cost_dirty := true
var expenses_total := 0
var free_trucks_left := 0
var tool: int = Tool.NONE
var terrain := PackedByteArray()
var mountain_h := PackedFloat32Array()
var decor := {}
var city_streets := {}
var forest_cells: Array = []
var astar_road := AStarGrid2D.new()
var astar_rail := AStarGrid2D.new()
var roads := {}
var rails := {}
var road_paid := {}
var rail_paid := {}
var buildings: Array = []
var by_id: Dictionary = {}          # map_id -> Building
var cell_to_building := {}
var vehicles: Array = []
var next_vid := 1
var warehouse_count := 0
var deliveries: Array = []          # {tick, units, income, trip_cost, src, dst}
var deliveries_profit := 0
var network_dirty := true
var lines_dirty := true
var line_groups := {}          # Typ|Quelle|Ziel -> Array[Vehicle]
var line_order: Array = []
var n_assigned := 0

var drag_start := Vector2i(-1, -1)
var dragging := false
var sim_hover_active := false
var sim_hover := Vector2i(-1, -1)
var plan := {}
var line_src = null
var hover_cell := Vector2i(-1, -1)
var last_preview_cell := Vector2i(-99, -99)
var label_timer := 0.0
var lines_timer := 0
var selected = null

var milestones: Array = []
var milestone_targets: Array = []
var bench = null

# ---------------------------------------------------------------- Szene
var rig: Node3D
var cam: Camera3D
var zoom := 1.0
var preview_root: Node3D
var hover_marker: MeshInstance3D
var influence_mesh: MeshInstance3D
var goal_markers: Array = []
var ui: CanvasLayer
var info_label: Label
var hint_label: Label
var toast_label: Label
var toast_time := 0.0
var milestone_labels: Array = []
var ms_panel: PanelContainer
var next_step_label: Label
var lines_label: Label
var speed_buttons: Array = []
var panel: PanelContainer
var panel_title: Label
var panel_text: Label
var panel_button: Button
var start_panel: PanelContainer
var bankrupt_panel: PanelContainer
var bankrupt_label: Label
var cursor_box: VBoxContainer
var cursor_cost: Label
var cursor_reason: Label

var mat_road: StandardMaterial3D
var mat_rail: StandardMaterial3D
var mat_bridge: StandardMaterial3D
var mat_ok: StandardMaterial3D
var mat_bad: StandardMaterial3D
var mat_exist: StandardMaterial3D
var mat_demolish: StandardMaterial3D
var mat_saum: StandardMaterial3D
var mat_marker: StandardMaterial3D
var mat_influence: StandardMaterial3D
var mm_truck: MultiMeshInstance3D
var mm_train: MultiMeshInstance3D
var mm_cargo: MultiMeshInstance3D


func _ready() -> void:
	var t0 := Time.get_ticks_usec()
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF   # nur die Fahrzeug-MultiMeshes interpolieren
	_load_data()
	_setup_materials()
	_setup_environment()
	_setup_camera()
	_setup_ground()
	_build_map()
	load_ms = (Time.get_ticks_usec() - t0) / 1000.0
	_setup_vehicle_meshes()
	_setup_ui()
	Engine.physics_ticks_per_second = int(1000 / tick_ms)
	ready_ms = (Time.get_ticks_usec() - t0) / 1000.0
	print("MAP_LOAD_MS %.1f READY_MS %.1f MISSING_IDS %d" % [load_ms, ready_ms, map_missing_ids.size()])
	for n in map_missing_ids:
		print("  FEHLENDE ID: ", n)
	if _bench_requested():
		bench = Bench.new()
		add_child(bench)
		bench.start(self)


func _bench_requested() -> bool:
	if OS.has_feature("bench"):
		return true
	return OS.get_cmdline_args().has("--bench") or OS.get_cmdline_user_args().has("--bench")


# ---------------------------------------------------------------- Daten laden

func _json(path: String) -> Variant:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Datei fehlt: " + path)
		return {}
	return JSON.parse_string(f.get_as_text())


func _load_data() -> void:
	shim = EcoShim.new()
	eco = Economy.new()
	if not eco.load_from(SLICE_PATH, CONSTS_PATH):
		for e in eco.errors:
			push_error("Ökonomie-JSON: " + e)
	eco.attach(shim)
	map_data = _json(MAP_PATH)
	for v in _json(VEHICLES_PATH)["fahrzeuge"]:
		vdefs[v["id"]] = v
	for g in _json(GOODS_PATH)["gueter"]:
		good_names[g["id"]] = g["name"]
	palette = _json(PALETTE_PATH)
	GRID = int(map_data["karte"]["breite_felder"])
	feld_mm = eco.feld_mm
	tick_ms = int(eco.consts["zeit"]["tick_ms"])
	periode_ticks = eco.periode_ticks
	month_ticks = int(eco.slice["zeit"]["spielmonat_ticks"])
	road_cent = int(eco.slice["fahrzeug_ref"]["strasse_cent_pro_feld"])
	load_ticks = int(eco.slice["fahrzeug_ref"]["load_ticks"])
	warehouse_cent = int(eco.slice["lager"]["warehouse_cost_cent"])
	warehouse_upkeep = int(eco.slice["lager"]["warehouse_upkeep_cent_pro_periode"])
	refund_promille = int(eco.slice["genre_standard"]["demolition_refund_promille"])
	rail_upkeep_per_field = int(vdefs["lok_e1"].get("gleis_cent_pro_feld_pro_periode", 0))
	if int(map_data["karte"]["feld_mm"]) != feld_mm:
		map_missing_ids.append("karte.feld_mm %s != constants raum.feld_mm %d" % [str(map_data["karte"]["feld_mm"]), feld_mm])


func _pal(token: String, alpha_override := -1.0) -> Color:
	var t: Dictionary = palette["tokens"][token]
	var g: Array = t["godot"]
	return Color(g[0], g[1], g[2], t["alpha"] if alpha_override < 0.0 else alpha_override)


func _bg(name: String) -> Color:
	var rgb: Array = palette["hintergruende"][name]["rgb"]
	return Color8(int(rgb[0]), int(rgb[1]), int(rgb[2]))


# ---------------------------------------------------------------- Aufbau

func _setup_materials() -> void:
	mat_road = _mat(_bg("stadt_strasse"))
	mat_rail = _mat(Color(0.45, 0.3, 0.2))
	mat_bridge = _mat(Color(0.75, 0.7, 0.6))
	mat_ok = _mat(_pal("ghost"), true)                         # S-08: Ghost weiß 0,75 …
	var sg: Array = palette["saum"]["godot"]
	mat_saum = _mat(Color(sg[0], sg[1], sg[2], 1.0), true)     # … mit dunklem Saum (B-04)
	mat_saum.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	mat_bad = _mat(_pal("status_bad"), true)                   # S-08 status_bad + Schraffur
	mat_bad.albedo_texture = _hatch_texture()
	mat_exist = _mat(Color(1, 1, 1, 0.25), true)
	mat_demolish = _mat(_pal("status_warn"), true)             # S-08 status_warn + Schraffur
	mat_demolish.albedo_texture = _hatch_texture()
	mat_marker = _mat(_pal("marker"), true)                    # S-08 marker
	mat_marker.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	mat_marker.no_depth_test = true
	mat_influence = _mat(Color(0.3, 0.6, 1.0, 0.16), true)


func _hatch_texture() -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for x in 16:
		for y in 16:
			img.set_pixel(x, y, Color(1, 1, 1, 1) if (x + y) % 8 < 4 else Color(1, 1, 1, 0.35))
	return ImageTexture.create_from_image(img)


func _mat(color: Color, unshaded := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	if unshaded:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


func _setup_environment() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.62, 0.75, 0.88)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.78, 0.85)
	env.ambient_light_energy = 0.6
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 35, 0)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 250.0
	add_child(sun)


func _setup_camera() -> void:
	rig = Node3D.new()
	rig.position = Vector3(GRID * 0.5, 0, GRID * 0.5)
	add_child(rig)
	cam = Camera3D.new()
	cam.far = 6000.0
	rig.add_child(cam)
	cam.rotation = Vector3(-atan2(20.0, 16.0), 0, 0)
	zoom = 16.0
	_apply_zoom()


func _apply_zoom() -> void:
	cam.position = Vector3(0, 20, 16) * zoom


func focus(cell: Vector2, z: float) -> void:
	rig.position = Vector3(cell.x, 0, cell.y)
	zoom = z
	_apply_zoom()


func _setup_ground() -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(GRID, GRID)
	ground.mesh = plane
	ground.material_override = _mat(_bg("gras"))
	ground.position = Vector3(GRID * 0.5, 0, GRID * 0.5)
	add_child(ground)
	preview_root = Node3D.new()
	add_child(preview_root)
	hover_marker = MeshInstance3D.new()
	var hb := BoxMesh.new()
	hb.size = Vector3(1, 0.05, 1)
	hover_marker.mesh = hb
	hover_marker.material_override = _mat(Color(1, 1, 1, 0.35), true)
	hover_marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(hover_marker)


func _setup_astar(a: AStarGrid2D) -> void:
	a.region = Rect2i(0, 0, GRID, GRID)
	a.cell_size = Vector2(1, 1)
	a.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	a.update()
	a.fill_solid_region(a.region, true)


# ---------------------------------------------------------------- Karte (slice_map.json)

func _build_map() -> void:
	terrain.resize(GRID * GRID)
	terrain.fill(Terrain.PLAIN)
	mountain_h.resize(GRID * GRID)
	_setup_astar(astar_road)
	_setup_astar(astar_rail)
	_check_ids()
	_raster_terrain()
	# Städte
	for st in map_data["staedte"]:
		_build_city(st)
	# Industrien
	var counts := {}
	for ind in map_data["industrien"]:
		counts[ind["typ"]] = counts.get(ind["typ"], 0) + 1
	var seen := {}
	for ind in map_data["industrien"]:
		if not ind.get("im_slice", true):
			continue
		var typ: String = ind["typ"]
		seen[typ] = seen.get(typ, 0) + 1
		var nm: String = IND_NAMES.get(typ, typ)
		if counts[typ] > 1:
			nm += " %d" % seen[typ]
		_build_industry(ind, nm)
	_retarget_chains()
	_scatter_trees()
	_build_terrain_visuals()


## ID-Prüfung: jede Industrie, jedes Gut, jede Stadtstufe, jede Kette und jede HQ-Option der Karte muss
## im Ökonomie-JSON (bzw. in der Karte selbst) auflösbar sein. Bau-Quellen (Holz) sind nach L-10 bewusst
## ohne Ökonomie-Definition: sie werden als Notiz geführt, nicht als Fehler.
func _check_ids() -> void:
	var ids := {}
	for st in map_data["staedte"]:
		ids[st["id"]] = "stadt"
		if not eco.basket.has(st["stufe"]):
			map_missing_ids.append("Stadt %s: Stufe %s fehlt in saettigung.basket_by_stage" % [st["id"], st["stufe"]])
	for ind in map_data["industrien"]:
		ids[ind["id"]] = "industrie"
		var typ: String = ind["typ"]
		if ind.get("rolle", "") == "bau_quelle":
			map_notes.append("%s (%s): Bau-Quelle ohne Ökonomie-Definition (L-10, kein Handel im Slice)" % [ind["id"], typ])
			if not good_names.has(ind["ausgang_gueter"][0]):
				map_missing_ids.append("%s: Gut %s fehlt in goods.json" % [ind["id"], ind["ausgang_gueter"][0]])
			continue
		if not eco.i_index.has(typ):
			map_missing_ids.append("Industrie %s: Typ %s fehlt in economy_slice.industrien" % [ind["id"], typ])
			continue
		for g in ind["eingang_gueter"] + ind["ausgang_gueter"]:
			if not eco.g_index.has(g):
				map_missing_ids.append("Industrie %s: Gut %s fehlt in economy_slice.gueter" % [ind["id"], g])
	for ch in map_data["ketten"]:
		for g in ch["gueter"]:
			if not eco.g_index.has(g):
				map_missing_ids.append("Kette %s: Gut %s fehlt" % [ch["id"], g])
		for s in ch["strecken"]:
			for k in ["von", "nach"]:
				if not ids.has(s[k]):
					map_missing_ids.append("Kette %s: %s %s fehlt in der Karte" % [ch["id"], k, s[k]])
	for h in map_data["hq_optionen"]:
		if not h["im_slice"]:
			continue
		if not ids.has(h["stadt"]):
			map_missing_ids.append("HQ %s: Stadt %s fehlt" % [h["archetyp"], h["stadt"]])
		for i in h["industrien_im_radius"]:
			if not ids.has(i):
				map_missing_ids.append("HQ %s: Industrie %s fehlt" % [h["archetyp"], i])
		var key: String = {"agrar": "agrar", "bergbau": "mining"}.get(h["archetyp"], "")
		if key == "" or not eco.slice["hq"].get("archetyp_%s_im_slice_flag" % key, false):
			map_missing_ids.append("HQ %s: im_slice, aber nicht in economy_slice.hq" % h["archetyp"])
		elif int(h["startkapital_cent"]) != int(eco.slice["hq"]["start_capital_%s_cent" % key]):
			map_missing_ids.append("HQ %s: Startkapital Karte %s != JSON" % [h["archetyp"], str(h["startkapital_cent"])])
	for a in ARCH:
		for k in ["src", "proc", "m3_from", "m3_to"]:
			if not ids.has(ARCH[a][k]):
				map_missing_ids.append("Ziel-Hinweis %s.%s: %s fehlt" % [a, k, ARCH[a][k]])


func idx(c: Vector2i) -> int:
	return c.y * GRID + c.x


func terrain_at(c: Vector2i) -> int:
	if not _in_grid(c):
		return Terrain.PLAIN
	return terrain[idx(c)]


func _raster_terrain() -> void:
	for g in map_data["gelaende"]:
		var typ: String = g["typ"]
		if typ == "gebirge":
			_fill_polygon(g["polygon"], Terrain.MOUNTAIN)
		elif typ == "meer":
			_fill_polygon(g["polygon"], Terrain.WATER)
		elif typ == "wald":
			_fill_polygon(g["polygon"], -1)
	for r in map_data["fluesse"]:
		var half: float = float(r["breite_felder"]) * 0.5
		var pts: Array = r["linie"]
		for i in pts.size() - 1:
			var a := Vector2(pts[i][0], pts[i][1])
			var b := Vector2(pts[i + 1][0], pts[i + 1][1])
			var x0 := int(floor(minf(a.x, b.x) - half - 1))
			var x1 := int(ceil(maxf(a.x, b.x) + half + 1))
			var y0 := int(floor(minf(a.y, b.y) - half - 1))
			var y1 := int(ceil(maxf(a.y, b.y) + half + 1))
			for y in range(maxi(0, y0), mini(GRID, y1 + 1)):
				for x in range(maxi(0, x0), mini(GRID, x1 + 1)):
					if _dist_to_segment(Vector2(x + 0.5, y + 0.5), a, b) < half:
						terrain[y * GRID + x] = Terrain.WATER


## Scanline-Füllung (Zellmitte im Polygon). value -1 = Wald (nur Deko).
func _fill_polygon(poly: Array, value: int) -> void:
	var ymin := GRID
	var ymax := 0
	for p in poly:
		ymin = mini(ymin, int(p[1]))
		ymax = maxi(ymax, int(ceil(p[1])))
	var n := poly.size()
	for y in range(maxi(0, ymin), mini(GRID, ymax + 1)):
		var py := y + 0.5
		var xs: Array = []
		for i in n:
			var p0: Array = poly[i]
			var p1: Array = poly[(i + 1) % n]
			var ya: float = p0[1]
			var yb: float = p1[1]
			if (ya <= py and py < yb) or (yb <= py and py < ya):
				xs.append(float(p0[0]) + (py - ya) * (float(p1[0]) - float(p0[0])) / (yb - ya))
		xs.sort()
		var k := 0
		while k + 1 < xs.size():
			var xa: float = xs[k]
			var xb: float = xs[k + 1]
			for x in range(maxi(0, int(ceil(xa - 0.5))), mini(GRID - 1, int(floor(xb - 0.5))) + 1):
				var i2 := y * GRID + x
				if value == -1:
					forest_cells.append(Vector2i(x, y))
				elif value == Terrain.MOUNTAIN:
					if terrain[i2] == Terrain.PLAIN:
						terrain[i2] = Terrain.MOUNTAIN
						var d := minf(x + 0.5 - xa, xb - x - 0.5)
						var noise := 0.8 + 0.35 * float(hash(i2) % 1000) / 1000.0
						mountain_h[i2] = clampf(0.8 + d * 0.12, 0.8, 7.0) * noise
				else:
					terrain[i2] = value
			k += 2


func _dist_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t)


func _new_site_node(b) -> int:
	var nid: int = shim.graph.nodes.size()
	var a: Vector2i = b.anchor()
	shim.add_node(nid, Vector2i(a.x * feld_mm, a.y * feld_mm), b.map_id)
	b.node_id = nid
	return nid


func _register(b) -> void:
	buildings.append(b)
	if b.map_id != "":
		by_id[b.map_id] = b
	for c in b.cells():
		cell_to_building[c] = b
		if _in_grid(c):
			terrain[idx(c)] = Terrain.PLAIN
		if b.kind != Building.Kind.CITY:
			astar_road.set_point_solid(c, false)
			astar_rail.set_point_solid(c, false)


func _build_industry(ind: Dictionary, nm: String) -> void:
	var typ: String = ind["typ"]
	var size: Vector2i = IND_SIZE.get(typ, Vector2i(3, 3))
	var center := Vector2i(int(ind["x_felder"]), int(ind["y_felder"]))
	var kind: int = Building.Kind.INERT
	var outs: Array = ind["ausgang_gueter"]
	if eco.i_index.has(typ):
		var d: Dictionary = eco.i_def[eco.i_index[typ]]
		if d.get("eingang_gut_ids", []).is_empty():
			kind = Building.Kind.PRODUCER
		elif d.has("ausgang_gut_id"):
			kind = Building.Kind.PROCESSOR
		else:
			kind = Building.Kind.SINK
		outs = [d["ausgang_gut_id"]] if d.has("ausgang_gut_id") else []
	var cap_col: Color = GOOD_COLORS.get(outs[0], Color(0.5, 0.5, 0.5)) if outs.size() > 0 else Color(0.35, 0.35, 0.4)
	var b := Building.new()
	add_child(b)
	b.map_id = ind["id"]
	b.typ = typ
	b.setup(kind, nm, center - size / 2, size, cap_col, IND_HEIGHT.get(typ, 1.5))
	b.out_good = outs[0] if outs.size() > 0 else ""
	b.in_goods = ind["eingang_gueter"]
	if eco.i_index.has(typ):
		b.in_goods = eco.i_def[eco.i_index[typ]].get("eingang_gut_ids", [])
		_new_site_node(b)
		b.site = eco.add_industry_site(b.node_id, typ)
		b.station = eco.s_station[b.site]
	_register(b)


func _build_city(st: Dictionary) -> void:
	var p_name: String = st["name"]
	var center := Vector2i(int(st["x_felder"]), int(st["y_felder"]))
	var pop: int = int(st["einwohner_anzahl"])
	var r: int = clampi(int(round(sqrt(float(pop)) / 7.0)), 4, 16)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(p_name)
	var cells := []
	var street_t := []
	var street_c := []
	var house_t := []
	var house_c := []
	var tall := 1.5 + r * 0.4
	var c_street := _bg("stadt_strasse")
	var c_light := _bg("stadt_haus_hell")
	var c_brick := _bg("stadt_haus_ziegel")
	var c_tower := _bg("stadt_hochhaus")
	for x in range(-r, r + 1):
		for y in range(-r, r + 1):
			var d := Vector2(x, y).length()
			if d > r - rng.randf() * 1.5:
				continue
			var c := center + Vector2i(x, y)
			if not _in_grid(c) or terrain_at(c) == Terrain.WATER:
				continue
			cells.append(c)
			if x % 4 == 0 or y % 4 == 0:
				city_streets[c] = true
				street_t.append(Transform3D(Basis(), Vector3(c.x + 0.5, 0.03, c.y + 0.5)))
				street_c.append(c_street)
			else:
				var t := d / float(r)
				var h := lerpf(tall, 0.5, t) * rng.randf_range(0.55, 1.25)
				var w := rng.randf_range(0.7, 0.92)
				house_t.append(Transform3D(Basis().scaled(Vector3(w, h, w)), Vector3(c.x + 0.5, h * 0.5, c.y + 0.5)))
				var base := c_light if rng.randf() < 0.6 else c_brick
				if t < 0.35 and r >= 10:
					base = c_tower
				house_c.append(base.lightened(rng.randf_range(-0.08, 0.08)))
	_multimesh(Vector3(1, 0.06, 1), street_t, street_c, false)
	_multimesh(Vector3(1, 1, 1), house_t, house_c, true)
	var b := Building.new()
	b.custom_cells = cells
	add_child(b)
	b.map_id = st["id"]
	b.typ = "stadt"
	b.city_stage = st["stufe"]
	b.city_pop = pop
	b.setup(Building.Kind.CITY, p_name, center - Vector2i(r, r), Vector2i(2 * r + 1, 2 * r + 1), Color.WHITE, tall + 1.5)
	# Städte der Karte ersetzen die Platzhalter-Städte aus economy_slice.staedte (dorf_agrar, kleinstadt_a, …)
	eco.c_index[b.map_id] = {"id": b.map_id, "stage_id": b.city_stage, "einwohner_anzahl": pop}
	_new_site_node(b)
	b.site = eco.add_city_site(b.node_id, b.map_id)
	b.station = eco.s_station[b.site]
	_register(b)
	for c in cells:
		if city_streets.has(c):
			astar_road.set_point_solid(c, false)
			astar_rail.set_point_solid(c, false)


## Ketten-Kanten zu Platzhalter-Städten (economy_slice.staedte) zeigen auf jede Karten-Stadt, deren
## Warenkorb das Gut annimmt; licence_quote rechnet dann mit der Luftlinie zum nächsten Abnehmer.
func _retarget_chains() -> void:
	var placeholder := {}
	for st in eco.slice["staedte"]:
		placeholder[st["id"]] = true
	for ch in eco.chains:
		var out: Array = []
		for e in ch["kanten"]:
			if not placeholder.has(e["nach_id"]):
				out.append(e)
				continue
			var g: int = eco.g_index[e["gut_id"]]
			for b in buildings:
				if b.kind == Building.Kind.CITY and eco.city_accepts(b.site, g):
					var e2: Dictionary = e.duplicate()
					e2["nach_id"] = b.map_id
					out.append(e2)
		ch["kanten"] = out


func _scatter_trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var cand: Array = []
	for c in forest_cells:
		if rng.randf() < 0.5:
			cand.append(c)
	for i in 900:
		cand.append(Vector2i(rng.randi_range(0, GRID - 1), rng.randi_range(0, GRID - 1)))
	var tt := []
	var tc := []
	var tcells := []
	var c_tree := _bg("wald_baum")
	for c in cand:
		if terrain_at(c) != Terrain.PLAIN or cell_to_building.has(c) or decor.has(c):
			continue
		var h := rng.randf_range(0.8, 1.8)
		tt.append(Transform3D(Basis().scaled(Vector3(0.6, h, 0.6)), Vector3(c.x + 0.5, h * 0.5, c.y + 0.5)))
		tc.append(c_tree.lightened(rng.randf_range(-0.05, 0.12)))
		tcells.append(c)
		decor[c] = true
	var tm := _multimesh(Vector3(1, 1, 1), tt, tc, false)
	for i in tcells.size():
		decor[tcells[i]] = [tm, i]


func _build_terrain_visuals() -> void:
	var wt := []
	var wc := []
	var mt := []
	var mcol := []
	var mcells := []
	var c_w := _bg("wasser")
	var c_w2 := _bg("wasser_hell")
	var c_rock := _bg("berg_stein")
	var c_snow := Color(0.95, 0.95, 0.97)
	for y in GRID:
		for x in GRID:
			var i := y * GRID + x
			var t := terrain[i]
			if t == Terrain.WATER:
				wt.append(Transform3D(Basis(), Vector3(x + 0.5, 0.02, y + 0.5)))
				wc.append(c_w if (x + y) % 3 else c_w2)
			elif t == Terrain.MOUNTAIN:
				var h: float = mountain_h[i]
				mt.append(Transform3D(Basis().scaled(Vector3(1, h, 1)), Vector3(x + 0.5, h * 0.5, y + 0.5)))
				mcol.append(c_snow if h > 5.5 else c_rock.lightened(clampf(h * 0.04, 0.0, 0.2)))
				mcells.append(Vector2i(x, y))
	_multimesh(Vector3(1, 0.04, 1), wt, wc, false)
	var mm := _multimesh(Vector3(1, 1, 1), mt, mcol, false)
	for i in mcells.size():
		decor[mcells[i]] = [mm, i]


func _multimesh(size: Vector3, transforms: Array, colors: Array, shadows: bool) -> MultiMeshInstance3D:
	var box := BoxMesh.new()
	box.size = size
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	box.material = mat
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = box
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
		mm.set_instance_color(i, colors[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	if not shadows:
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
	return mmi


func _clear_decor(c: Vector2i) -> void:
	if not decor.has(c):
		return
	var e = decor[c]
	if e is Array:
		var mmi: MultiMeshInstance3D = e[0]
		mmi.multimesh.set_instance_transform(e[1], Transform3D(Basis().scaled(Vector3.ZERO), Vector3.ZERO))
	decor.erase(c)


func _setup_vehicle_meshes() -> void:
	mm_truck = _vehicle_mm(Vector3(0.9, 0.55, 1.5), Color(0.059, 0.09, 0.125), false)   # S-08 Saum-Ton: hebt sich von Gras, Straße und Brücke ab
	mm_train = _vehicle_mm(Vector3(0.8, 0.6, 2.4), Color(0.2, 0.3, 0.55), false)
	mm_cargo = _vehicle_mm(Vector3(0.75, 0.4, 0.9), Color.WHITE, true)


func _vehicle_mm(size: Vector3, color: Color, colors: bool) -> MultiMeshInstance3D:
	var box := BoxMesh.new()
	box.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	if colors:
		mat.vertex_color_use_as_albedo = true
		mat.albedo_color = Color.WHITE
	box.material = mat
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = colors
	mm.mesh = box
	mm.instance_count = 0
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	add_child(mmi)
	return mmi


# ---------------------------------------------------------------- UI

func _setup_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	var top := VBoxContainer.new()
	top.position = Vector2(12, 10)
	ui.add_child(top)
	info_label = _label(20)
	top.add_child(info_label)
	var bar := HBoxContainer.new()
	top.add_child(bar)
	bar.add_child(_button("[1] Straße (%s/Feld)" % money_str(road_cent), func(): _set_tool(Tool.ROAD)))
	bar.add_child(_button("[2] Gleis (%s/Feld)" % money_str(RAIL_CENT_PER_FIELD), func(): _set_tool(Tool.RAIL)))
	bar.add_child(_button("[3] Lager (%s)" % money_str(warehouse_cent), func(): _set_tool(Tool.WAREHOUSE)))
	bar.add_child(_button("[4] Lkw-Linie (%s)" % money_str(_vehicle_price("truck")), func(): _set_tool(Tool.TRUCK_LINE)))
	bar.add_child(_button("[5] Zug-Linie (%s)" % money_str(_vehicle_price("train")), func(): _set_tool(Tool.TRAIN_LINE)))
	bar.add_child(_button("[X] Abriss (50 %)", func(): _set_tool(Tool.DEMOLISH)))
	bar.add_child(_button("[Esc]", func(): _cancel()))
	var sbar := HBoxContainer.new()
	top.add_child(sbar)
	sbar.add_child(_label(16, "Tempo:"))
	for s in [0, 1, 2, 4, 8]:
		var b := _button("Pause" if s == 0 else "%d×" % s, func(): set_speed(s))
		b.toggle_mode = true
		sbar.add_child(b)
		speed_buttons.append([s, b])
	lines_label = _label(15)
	top.add_child(lines_label)

	ms_panel = PanelContainer.new()
	ms_panel.visible = false
	ms_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	ms_panel.offset_left = -430
	ms_panel.offset_right = -12
	ms_panel.offset_top = 12
	ms_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	ui.add_child(ms_panel)
	var ms_box := VBoxContainer.new()
	ms_panel.add_child(ms_box)
	ms_box.add_child(_label(19, "Ziele"))
	for i in 7:
		var l := _label(16)
		ms_box.add_child(l)
		milestone_labels.append(l)
	next_step_label = _label(16)
	next_step_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	next_step_label.custom_minimum_size = Vector2(400, 0)
	next_step_label.modulate = _pal("marker", 1.0)
	ms_box.add_child(next_step_label)

	# Klick-Panel (Kontextdialog, Genre-Standard Cities: Skylines)
	panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	panel.offset_left = -430
	panel.offset_right = -12
	panel.offset_top = -40
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.visible = false
	ui.add_child(panel)
	var pb := VBoxContainer.new()
	panel.add_child(pb)
	panel_title = _label(20)
	pb.add_child(panel_title)
	panel_text = _label(16)
	panel_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel_text.custom_minimum_size = Vector2(400, 0)
	pb.add_child(panel_text)
	panel_button = _button("Lizenz kaufen", func(): _on_panel_button())
	panel_button.add_theme_font_size_override("font_size", 18)
	pb.add_child(panel_button)
	pb.add_child(_button("Schließen", func(): close_panel()))

	hint_label = _label(18)
	hint_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hint_label.offset_left = 12
	hint_label.offset_top = -70
	hint_label.offset_right = 1300
	hint_label.offset_bottom = -12
	ui.add_child(hint_label)

	toast_label = _label(24)
	toast_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast_label.offset_left = -480
	toast_label.offset_right = 480
	toast_label.offset_top = 150
	toast_label.offset_bottom = 220
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ui.add_child(toast_label)

	cursor_box = VBoxContainer.new()
	cursor_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cursor_box.visible = false
	ui.add_child(cursor_box)
	cursor_cost = _label(20)
	cursor_box.add_child(cursor_cost)
	cursor_reason = _label(18)
	cursor_reason.modulate = _pal("status_bad", 1.0)
	cursor_box.add_child(cursor_reason)

	_setup_start_dialog()
	_setup_bankrupt_panel()
	_refresh_speed_buttons()


func _center_panel(w: float, h: float) -> PanelContainer:
	var p := PanelContainer.new()
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.offset_left = -w * 0.5
	p.offset_right = w * 0.5
	p.offset_top = -h * 0.5
	p.offset_bottom = h * 0.5
	ui.add_child(p)
	return p


func _setup_start_dialog() -> void:
	start_panel = _center_panel(760, 330)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	start_panel.add_child(v)
	v.add_child(_label(30, "Mega Tycoon – Grey-Box-Slice"))
	var t := _label(18, "Gründe deine Firma. Das Startkapital ist deine Firma, Kredit gibt es noch nicht: fällt die Kasse unter 0 $, bist du bankrott.\nLaden darfst du nur an Industrien mit Lizenz. Geld gibt es erst, wenn die Ware beim Abnehmer ankommt.")
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.custom_minimum_size = Vector2(720, 0)
	v.add_child(t)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 20)
	v.add_child(h)
	for a in ["agrar", "bergbau"]:
		var hq := _hq_option(a)
		var key: String = "agrar" if a == "agrar" else "mining"
		var cap: int = int(eco.slice["hq"]["start_capital_%s_cent" % key])
		var city: String = by_id[hq["stadt"]].display_name if by_id.has(hq["stadt"]) else hq["stadt"]
		var txt := "%s\nHQ in %s · Startkapital %s\n%s" % [ARCH[a]["title"], city, money_str(cap),
			"Getreide → Mühle → Mehl → Stadt" if a == "agrar" else "Kohle → Kraftwerk · Erz + Kohle → Stahl"]
		var b := _button(txt, func(): start_game(a))
		b.custom_minimum_size = Vector2(350, 120)
		b.add_theme_font_size_override("font_size", 18)
		h.add_child(b)


func _setup_bankrupt_panel() -> void:
	bankrupt_panel = _center_panel(600, 240)
	bankrupt_panel.visible = false
	var v := VBoxContainer.new()
	bankrupt_panel.add_child(v)
	var l := _label(34, "Bankrott")
	l.modulate = _pal("status_bad", 1.0)
	v.add_child(l)
	bankrupt_label = _label(18)
	bankrupt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bankrupt_label.custom_minimum_size = Vector2(560, 0)
	v.add_child(bankrupt_label)
	v.add_child(_button("Neu starten", func(): get_tree().reload_current_scene()))


func _hq_option(a: String) -> Dictionary:
	for h in map_data["hq_optionen"]:
		if h["archetyp"] == a:
			return h
	return {}


func _label(size: int, text := "") -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	return b


static func money_str(cent: int) -> String:
	var neg := cent < 0
	var d := absi(cent) / 100
	var s := str(d)
	var out := ""
	while s.length() > 3:
		out = "." + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if neg else "") + s + out + " $"


func time_str(ticks: int) -> String:
	var sec := ticks * tick_ms / 1000
	return "%d:%02d" % [sec / 60, sec % 60]


func _toast(text: String, seconds := 4.0) -> void:
	toast_label.text = text
	toast_time = seconds


func set_speed(s: int) -> void:
	if not company_started or bankrupt:
		s = 0
	if s == 8 and not eco.speed_steps(vehicles.size()).has(8):
		_toast("8× nur bis %d Fahrzeuge." % eco.MAX_VEHICLES_AT_8X)
		s = 4
	speed = s
	_refresh_speed_buttons()


func _refresh_speed_buttons() -> void:
	for e in speed_buttons:
		e[1].set_pressed_no_signal(e[0] == speed)


# ---------------------------------------------------------------- Start, Lizenz, Panel

## Startdialog-Knopf: Firma gründen (HQ gratis, Startkapital = Firma, L-08 §1).
func start_game(a: String) -> bool:
	if company_started:
		return false
	var hq := _hq_option(a)
	if hq.is_empty() or not by_id.has(hq["stadt"]):
		return false
	hq_city = by_id[hq["stadt"]]
	if not eco.start_company(a, hq_city.node_id, hq_city.city_stage):
		_toast("Firma konnte nicht gegründet werden (JSON).")
		return false
	archetyp = a
	company_started = true
	free_trucks_left = int(eco.slice["fahrzeug_ref"]["startpaket_lkw_%s_anzahl" % ("agrar" if a == "agrar" else "mining")])
	start_panel.visible = false
	ms_panel.visible = true
	_show_influence()
	_init_milestones()
	var src = by_id[ARCH[a]["src"]]
	var mid: Vector3 = (hq_city.center() + src.center()) * 0.5
	focus(Vector2(mid.x, mid.z), 3.2)
	set_speed(1)
	_toast("%s gegründet. Startkapital %s, %d Lkw im Startpaket. Klick auf %s (gelber Pfeil)." % [
		"Agrarfirma" if a == "agrar" else "Bergbaufirma", money_str(eco.cash_cent), free_trucks_left, src.display_name], 8.0)
	return true


func _show_influence() -> void:
	influence_mesh = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = eco.hq_radius_felder
	cyl.bottom_radius = eco.hq_radius_felder
	cyl.height = 0.02
	influence_mesh.mesh = cyl
	influence_mesh.material_override = mat_influence
	influence_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	influence_mesh.position = hq_city.center() + Vector3(0, 0.03, 0)
	add_child(influence_mesh)


func licence_quote(b) -> Dictionary:
	if b == null or b.site < 0 or not b.is_industry():
		return {"ok": false, "fehler": "keine_lizenzierbare_industrie"}
	return eco.licence_quote(b.site)


## Knopf „Lizenz kaufen“: 1 Klick = 1 Aufruf von economy.buy_licence.
func ui_buy_licence(b) -> bool:
	var q := licence_quote(b)
	if not q.get("ok", false):
		return false
	var r: Dictionary = eco.buy_licence(b.site)
	if not r["ok"]:
		match r["fehler"]:
			"schon_lizenziert":
				_toast("%s ist schon lizenziert." % b.display_name)
			"guthaben_reicht_nicht":
				_toast("Zu wenig Geld: Lizenz kostet %s." % money_str(q["zu_zahlen_cent"]))
			_:
				_toast("Lizenz nicht möglich: %s" % r["fehler"])
		return false
	b.licence_marker.visible = true
	_toast("Lizenz %s: %s, gilt %s Spielzeit und verlängert sich automatisch." % [b.display_name,
		"gratis" if r["bezahlt_cent"] == 0 else money_str(r["bezahlt_cent"]), time_str(eco.lic_duration)], 6.0)
	_refresh_panel()
	_check_milestones()
	return true


func open_panel(b) -> void:
	selected = b
	panel.visible = true
	_refresh_panel()


func close_panel() -> void:
	selected = null
	panel.visible = false


func _on_panel_button() -> void:
	if selected != null:
		ui_buy_licence(selected)


func _goods_txt(arr: Array) -> String:
	var out := []
	for g in arr:
		out.append(good_names.get(g, g))
	return ", ".join(out)


func _refresh_panel() -> void:
	if selected == null or not panel.visible:
		return
	var b = selected
	panel_title.text = b.display_name
	panel_button.visible = false
	var lines: Array = []
	match b.kind:
		Building.Kind.CITY:
			var basket: Array = eco.basket.get(b.city_stage, [])
			lines.append("%s · %d Einwohner · Kunde (nicht kaufbar)" % [STAGE_NAMES.get(b.city_stage, b.city_stage), b.city_pop])
			lines.append("Warenkorb: %s" % ", ".join(basket))
			var dem: int = eco.city_demand(b.site)
			var sat: Dictionary = eco.s_sat[b.site] if eco.s_sat_period[b.site] == shim.tick_count / periode_ticks else {}
			for cat in basket:
				lines.append("  %s diese Minute: %d / %d (ab 100 %% sinkt der Preis)" % [cat, int(sat.get(cat, 0)), dem])
		Building.Kind.WAREHOUSE:
			lines.append("Eigenes Lager: nimmt alles an, gibt alles ab. Lager zahlt 0 $ – Geld gibt es erst beim Endabnehmer.")
			lines.append("Bestand: %d / %d · Unterhalt %s/min" % [shim.st_stock[b.station], eco.warehouse_cap, money_str(warehouse_upkeep)])
		Building.Kind.INERT:
			lines.append("Bau-Quelle (Holz). Im Slice kein Handel (L-10), nur Kulisse.")
		_:
			if eco.s_raw[b.site] == 1:
				eco._sync_raw(shim, b.site)
			if b.kind == Building.Kind.PRODUCER:
				lines.append("Rohstoff: %s · Bestand %d" % [good_names.get(b.out_good, b.out_good), shim.st_stock[b.station]])
			elif b.kind == Building.Kind.PROCESSOR:
				var buf: Dictionary = eco.s_inbuf[b.site]
				var ins := []
				for gi in buf:
					ins.append("%s %d" % [good_names.get(eco.g_ids[gi], ""), buf[gi]])
				lines.append("Verarbeiter: %s → %s" % [", ".join(ins), good_names.get(b.out_good, b.out_good)])
				lines.append("Ausgang: %d · Lieferung von %s wird hier bezahlt" % [shim.st_stock[b.station], _goods_txt(b.in_goods)])
			else:
				lines.append("Abnehmer: nimmt %s an und bezahlt die Lieferung. Keine Lizenz nötig." % _goods_txt(b.in_goods))
			var q := licence_quote(b)
			if q.get("ok", false):
				panel_button.visible = true
				var d := absi(int(Vector2(b.anchor()).distance_to(Vector2(eco.hq_x / feld_mm, eco.hq_y / feld_mm))))
				lines.append("Lizenz: 10 %% des Kaufpreises, %s Spielzeit, verlängert sich automatisch. %s" % [
					time_str(q["laufzeit_ticks"]), "Im Einflussradius (−30 %)." if d <= eco.hq_radius_felder else "Außerhalb des Einflusses: teurer."])
				lines.append("Ertrag-Schätzung: %s Felder Luftlinie bis %s, volle Frische, ohne Sättigung." % [
					str(q["ertrag_distanz_felder"]), by_id[q["ertrag_ziel_id"]].display_name if by_id.has(q["ertrag_ziel_id"]) else q["ertrag_ziel_id"]])
				if q["aktiv"]:
					panel_button.text = "Lizenz aktiv – noch %s" % time_str(eco.s_lic_until[b.site] - shim.tick_count)
					panel_button.disabled = true
				else:
					var price := "gratis (1. Lizenz, sonst %s)" % money_str(q["kosten_cent"]) if q["gratis"] else money_str(q["kosten_cent"])
					panel_button.text = "Lizenz kaufen: %s · Ertrag ≈ %s/Monat" % [price, money_str(q["ertrag_pro_monat_cent"])]
					panel_button.disabled = not q["kaufbar"]
					if not q["kaufbar"]:
						panel_button.text = "Zu wenig Geld: Lizenz %s" % money_str(q["zu_zahlen_cent"])
			lines.append("Firmenkauf: ab Sprint 5.")
	panel_text.text = "\n".join(lines)


# ---------------------------------------------------------------- Ziele / Meilensteine

func _init_milestones() -> void:
	var A: Dictionary = ARCH[archetyp]
	var src: String = by_id[A["src"]].display_name
	var proc: String = by_id[A["proc"]].display_name
	milestones = [
		{"text": "Firma gegründet (HQ %s)" % hq_city.display_name, "done": true, "hint": "", "t": []},
		{"text": "Lizenz für %s kaufen" % src, "done": false, "t": [A["src"]],
			"hint": "Klick auf %s (gelber Pfeil) und dann im Panel auf „Lizenz kaufen“." % src},
		{"text": "Straße %s → %s bauen" % [src, proc], "done": false, "t": [A["src"], A["proc"]],
			"hint": "Taste [1] Straße: Maustaste auf %s drücken, bis %s ziehen, loslassen. Wasser nur gerade queren (Brücke)." % [src, proc]},
		{"text": "Lkw-Linie %s → %s" % [src, proc], "done": false, "t": [A["src"], A["proc"]],
			"hint": "Taste [4] Lkw-Linie: erst %s, dann %s anklicken." % [src, proc]},
		{"text": "Erste Lieferung mit Ertrag", "done": false, "t": [A["proc"]],
			"hint": "Der Lkw lädt und fährt los. Schneller: Tempo 2× oder 4× oben links."},
		{"text": "3 Lieferungen mit Gewinn", "done": false, "t": [A["proc"]],
			"hint": "Mehr Lkw: dieselbe Linie mit [4] noch einmal setzen. Gewinn je Linie steht oben links."},
		{"text": "Endprodukt an einen Abnehmer (M3)", "done": false, "t": [A["m3_from"], A["m3_to"]], "hint": A["m3_text"]},
	]
	_refresh_milestones()


func _complete(i: int) -> void:
	if i >= milestones.size() or milestones[i]["done"]:
		return
	milestones[i]["done"] = true
	_refresh_milestones()
	match i:
		4:
			_toast("Erste Lieferung! Bezahlt wird beim Abnehmer, nach Luftlinie ab Herkunft.", 6.0)
		5:
			_toast("Drei Lieferungen mit Gewinn – deine erste Lieferkette läuft.", 6.0)
		6:
			_toast("Endprodukt beim Abnehmer angekommen (M3).", 6.0)


func _check_milestones() -> void:
	if milestones.is_empty():
		return
	if not milestones[1]["done"]:
		for b in buildings:
			if b.kind == Building.Kind.PRODUCER and eco.licence_valid(b.site):
				_complete(1)
				break
	if not milestones[2]["done"] and network_dirty:
		network_dirty = false
		for b in buildings:
			if b.kind == Building.Kind.PRODUCER and eco.licence_valid(b.site):
				for t in buildings:
					if t.is_industry() and t.in_goods.has(b.out_good) and not astar_road.get_id_path(b.anchor(), t.anchor()).is_empty():
						_complete(2)
	if not milestones[3]["done"] and lines_dirty:
		lines_dirty = false
		for v in vehicles:
			if v.src != null and v.src.kind == Building.Kind.PRODUCER and v.dst.is_industry():
				_complete(3)
	if deliveries_profit >= 3:
		_complete(5)


func _refresh_milestones() -> void:
	var next := -1
	for i in milestone_labels.size():
		var l: Label = milestone_labels[i]
		if i >= milestones.size():
			l.text = ""
			continue
		var m: Dictionary = milestones[i]
		l.text = ("✔ " if m["done"] else "○ ") + m["text"]
		l.modulate = _pal("status_ok", 1.0) if m["done"] else Color(1, 1, 1)
		if not m["done"] and next < 0:
			next = i
	if next >= 0:
		next_step_label.text = "Nächster Schritt: " + milestones[next]["hint"]
		milestone_targets = milestones[next]["t"]
	else:
		next_step_label.text = "Alle Ziele erreicht. Weiter: zweite Kette oder Mittelfurt beliefern."
		milestone_targets = []
	_update_goal_markers()


func _update_goal_markers() -> void:
	for m in goal_markers:
		m.queue_free()
	goal_markers.clear()
	for id in milestone_targets:
		if not by_id.has(id):
			continue
		var b = by_id[id]
		var root := Node3D.new()
		var saum := MeshInstance3D.new()
		var sm := PrismMesh.new()
		sm.size = Vector3(2.4, 2.4, 0.5)
		saum.mesh = sm
		saum.material_override = mat_saum
		saum.rotation_degrees = Vector3(0, 0, 180)
		root.add_child(saum)
		var fill := MeshInstance3D.new()
		var fm := PrismMesh.new()
		fm.size = Vector3(1.8, 1.8, 0.6)
		fill.mesh = fm
		fill.material_override = mat_marker
		fill.rotation_degrees = Vector3(0, 0, 180)
		root.add_child(fill)
		root.position = b.center() + Vector3(0, b.height + 4.0, 0)
		root.set_meta("base_y", root.position.y)
		add_child(root)
		goal_markers.append(root)


# ---------------------------------------------------------------- Werkzeuge

func _set_tool(t: int) -> void:
	if not company_started or bankrupt:
		t = Tool.NONE
	tool = t
	drag_start = Vector2i(-1, -1)
	dragging = false
	plan = {}
	line_src = null
	_clear_preview()


func _cancel() -> void:
	if dragging:
		cancel_drag()
	elif (tool == Tool.TRUCK_LINE or tool == Tool.TRAIN_LINE) and line_src != null:
		line_src = null
	elif panel.visible:
		close_panel()
	else:
		_set_tool(Tool.NONE)


func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed:
		match mb.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				zoom = clampf(zoom * 0.9, 0.4, 26.0)
				_apply_zoom()
			MOUSE_BUTTON_WHEEL_DOWN:
				zoom = clampf(zoom * 1.1, 0.4, 26.0)
				_apply_zoom()
			MOUSE_BUTTON_LEFT:
				if tool == Tool.ROAD or tool == Tool.RAIL or tool == Tool.DEMOLISH:
					begin_drag(_mouse_cell())
				else:
					click(_mouse_cell())
			MOUSE_BUTTON_RIGHT:
				_cancel()
		return
	if mb and not mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and dragging:
		end_drag()
		return
	var key := event as InputEventKey
	if key and key.pressed and not key.echo:
		match key.keycode:
			KEY_1:
				_set_tool(Tool.ROAD)
			KEY_2:
				_set_tool(Tool.RAIL)
			KEY_3:
				_set_tool(Tool.WAREHOUSE)
			KEY_4:
				_set_tool(Tool.TRUCK_LINE)
			KEY_5:
				_set_tool(Tool.TRAIN_LINE)
			KEY_X:
				_set_tool(Tool.DEMOLISH)
			KEY_SPACE, KEY_P:
				set_speed(0 if speed > 0 else 1)
			KEY_ESCAPE:
				_cancel()


func _mouse_cell() -> Vector2i:
	var mp := get_viewport().get_mouse_position()
	var from := cam.project_ray_origin(mp)
	var dir := cam.project_ray_normal(mp)
	var hit = Plane(Vector3.UP, 0.0).intersects_ray(from, dir)
	if hit == null:
		return Vector2i(-1, -1)
	var c := Vector2i(int(floor(hit.x)), int(floor(hit.z)))
	if not _in_grid(c):
		return Vector2i(-1, -1)
	return c


## Klick auf ein Feld (Maus oder Test).
func click(cell: Vector2i) -> void:
	if cell.x < 0 or not company_started or bankrupt:
		return
	var b = cell_to_building.get(cell)
	match tool:
		Tool.WAREHOUSE:
			build_warehouse(cell)
		Tool.TRUCK_LINE, Tool.TRAIN_LINE:
			if b == null:
				return
			if line_src == null:
				if not b.provides():
					_toast("%s liefert nichts – wähle Farm/Mine, Verarbeiter oder Lager." % b.display_name)
				elif b.kind != Building.Kind.WAREHOUSE and not eco.licence_valid(b.site):
					_toast("Laden nur mit Lizenz: Klick auf %s (Auswahl, Esc) und „Lizenz kaufen“." % b.display_name)
					open_panel(b)
				else:
					line_src = b
			elif b == line_src:
				line_src = null
			else:
				if not _accepts_from(line_src, b):
					_toast("%s nimmt von %s nichts an." % [b.display_name, line_src.display_name])
				else:
					create_line(line_src, b, "train" if tool == Tool.TRAIN_LINE else "truck")
					line_src = null
		_:
			if b != null:
				open_panel(b)


func _accepts_good(b, g: String) -> bool:
	if g == "" or not eco.g_index.has(g):
		return false
	match b.kind:
		Building.Kind.WAREHOUSE:
			return true
		Building.Kind.CITY:
			return eco.city_accepts(b.site, eco.g_index[g])
		Building.Kind.PROCESSOR, Building.Kind.SINK:
			return b.in_goods.has(g)
	return false


func _accepts_from(a, b) -> bool:
	if b.kind == Building.Kind.INERT or b.kind == Building.Kind.PRODUCER:
		return false
	if a.kind == Building.Kind.WAREHOUSE:
		return true
	return _accepts_good(b, a.out_good)


func _drag_path(a: Vector2i, b: Vector2i) -> Array:
	var out := [a]
	var d := b - a
	var sx := signi(d.x)
	var sy := signi(d.y)
	var adx := absi(d.x)
	var ady := absi(d.y)
	var c := a
	if adx >= ady:
		for i in adx - ady:
			c.x += sx
			out.append(c)
		for i in ady:
			c.x += sx
			out.append(c)
			c.y += sy
			out.append(c)
	else:
		for i in ady - adx:
			c.y += sy
			out.append(c)
		for i in adx:
			c.y += sy
			out.append(c)
			c.x += sx
			out.append(c)
	return out


func _terrain_factor(c: Vector2i) -> int:
	match terrain_at(c):
		Terrain.WATER:
			return WATER_FACTOR
		Terrain.MOUNTAIN:
			return MOUNTAIN_FACTOR
	return 1


## Preis eines neuen Feldes in Cent: JSON-Straßenpreis × Gelände-Faktor (kein Außerhalb-Aufschlag: steht
## nicht im JSON; der Einfluss wirkt im Slice über den Lizenzpreis).
func field_cost(c: Vector2i, rail: bool) -> int:
	return (RAIL_CENT_PER_FIELD if rail else road_cent) * _terrain_factor(c)


func _in_grid(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < GRID and c.y < GRID


func plan_track(a: Vector2i, b: Vector2i, rail: bool) -> Dictionary:
	var cells := _drag_path(a, b)
	var net: Dictionary = rails if rail else roads
	var items := []
	var n := cells.size()
	var head := _building_run(cells, false)
	var tail := _building_run(cells, true)
	for i in n:
		var c: Vector2i = cells[i]
		var it := {"cell": c, "state": "new", "cost": 0, "reason": ""}
		if not _in_grid(c):
			it["state"] = "bad"
			it["reason"] = "Außerhalb der Karte"
		elif net.has(c) or city_streets.has(c):
			it["state"] = "exist"
		elif cell_to_building.has(c):
			var bb = cell_to_building[c]
			if bb.kind != Building.Kind.CITY and (i < head or i >= n - tail):
				it["state"] = "exist"
			else:
				it["state"] = "bad"
				it["reason"] = "Gebäude im Weg: %s" % bb.display_name
		else:
			it["cost"] = field_cost(c, rail)
		items.append(it)
	_check_bridges(cells, items)
	var total := 0
	var new_count := 0
	var reason := ""
	for it in items:
		if it["state"] == "bad" and reason == "":
			reason = it["reason"]
		if it["state"] == "new":
			total += it["cost"]
			new_count += 1
	if reason == "" and total > eco.cash_cent:
		reason = "Zu wenig Geld: %s nötig, %s vorhanden" % [money_str(total), money_str(eco.cash_cent)]
		for it in items:
			if it["state"] == "new":
				it["state"] = "bad"
				it["reason"] = reason
	return {"a": a, "b": b, "rail": rail, "cells": cells, "items": items, "total": total,
		"ok": reason == "", "reason": reason, "new_count": new_count}


func _building_run(cells: Array, from_end: bool) -> int:
	var n := cells.size()
	var first: Vector2i = cells[n - 1] if from_end else cells[0]
	var bb = cell_to_building.get(first)
	if bb == null or bb.kind == Building.Kind.CITY:
		return 0
	var k := 0
	while k < n:
		var c: Vector2i = cells[n - 1 - k] if from_end else cells[k]
		if cell_to_building.get(c) != bb:
			break
		k += 1
	return k


func _check_bridges(cells: Array, items: Array) -> void:
	var n := cells.size()
	var i := 0
	while i < n:
		if not (items[i]["state"] == "new" and terrain_at(cells[i]) == Terrain.WATER):
			i += 1
			continue
		var s := i
		while i < n and items[i]["state"] == "new" and terrain_at(cells[i]) == Terrain.WATER:
			i += 1
		var e := i - 1
		var why := ""
		if s == 0 or e == n - 1:
			why = "Wasser ohne Brücke: Brückenkopf braucht Land an beiden Enden"
		elif e - s + 1 > BRIDGE_MAX:
			why = "Wasser ohne Brücke: Brücke zu lang (max. %d Felder)" % BRIDGE_MAX
		else:
			var p: Vector2i = cells[s - 1]
			var q: Vector2i = cells[e + 1]
			var straight := true
			for k in range(s - 1, e + 2):
				var c: Vector2i = cells[k]
				if not (c.x == p.x and p.x == q.x) and not (c.y == p.y and p.y == q.y):
					straight = false
			if not straight:
				why = "Wasser ohne Brücke: Brücken nur gerade, nicht diagonal"
		if why != "":
			for k in range(s, e + 1):
				items[k]["state"] = "bad"
				items[k]["reason"] = why


func build_track(a: Vector2i, b: Vector2i, rail: bool) -> bool:
	var p := plan_track(a, b, rail)
	if not p["ok"]:
		_toast(p["reason"])
		return false
	var net: Dictionary = rails if rail else roads
	var paid: Dictionary = rail_paid if rail else road_paid
	var astar: AStarGrid2D = astar_rail if rail else astar_road
	for it in p["items"]:
		if it["state"] != "new":
			continue
		var c: Vector2i = it["cell"]
		_clear_decor(c)
		var bridge: bool = terrain_at(c) == Terrain.WATER
		var mountain: bool = terrain_at(c) == Terrain.MOUNTAIN
		var lift := 0.12 if bridge else (mountain_h[idx(c)] if mountain else 0.0)
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		if rail:
			box.size = Vector3(0.5, 0.1, 0.5)
			mi.position = Vector3(c.x + 0.5, 0.09 + lift, c.y + 0.5)
			mi.material_override = mat_bridge if bridge else mat_rail
		else:
			box.size = Vector3(0.96, 0.08, 0.96)
			mi.position = Vector3(c.x + 0.5, 0.04 + lift, c.y + 0.5)
			mi.material_override = mat_bridge if bridge else mat_road
		mi.mesh = box
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		net[c] = mi
		paid[c] = it["cost"]
		astar.set_point_solid(c, false)
	charge(p["total"])
	_clear_preview()
	network_dirty = true
	cost_dirty = true
	if p["total"] > 0:
		_toast("%s gebaut: %d Felder, %s" % ["Gleis" if rail else "Straße", p["new_count"], money_str(p["total"])], 2.5)
	_check_milestones()
	return true


func _used_cells(rail: bool) -> Dictionary:
	var out := {}
	for v in vehicles:
		if v.state == Vehicle.State.IDLE or (v.type == "train") != rail:
			continue
		for pos in v.path:
			out[Vector2i(int(floor(pos.x)), int(floor(pos.y)))] = true
	return out


func plan_demolish(a: Vector2i, b: Vector2i) -> Dictionary:
	var used_road := _used_cells(false)
	var used_rail := _used_cells(true)
	var items := []
	var refund := 0
	var reason := ""
	var foreign := false
	for x in range(mini(a.x, b.x), maxi(a.x, b.x) + 1):
		for y in range(mini(a.y, b.y), maxi(a.y, b.y) + 1):
			var c := Vector2i(x, y)
			if not _in_grid(c):
				continue
			if city_streets.has(c) or cell_to_building.has(c):
				foreign = true
			for rail in [false, true]:
				var net: Dictionary = rails if rail else roads
				if not net.has(c):
					continue
				var used: Dictionary = used_rail if rail else used_road
				if used.has(c):
					items.append({"cell": c, "rail": rail, "refund": 0, "state": "bad", "reason": "Von einer Linie befahren – erst Linie entfernen"})
					if reason == "":
						reason = items[-1]["reason"]
				else:
					var paid: Dictionary = rail_paid if rail else road_paid
					var r: int = int(paid.get(c, 0)) * refund_promille / 1000
					items.append({"cell": c, "rail": rail, "refund": r, "state": "remove", "reason": ""})
					refund += r
	if reason == "" and foreign:
		reason = "Stadtstraßen und Gebäude kann man nicht abreißen"
	var count := 0
	for it in items:
		if it["state"] == "remove":
			count += 1
	return {"a": a, "b": b, "items": items, "refund": refund, "reason": reason, "count": count, "demolish": true}


func demolish(a: Vector2i, b: Vector2i) -> int:
	var p := plan_demolish(a, b)
	for it in p["items"]:
		if it["state"] != "remove":
			continue
		var c: Vector2i = it["cell"]
		var rail: bool = it["rail"]
		var net: Dictionary = rails if rail else roads
		var paid: Dictionary = rail_paid if rail else road_paid
		var astar: AStarGrid2D = astar_rail if rail else astar_road
		net[c].queue_free()
		net.erase(c)
		paid.erase(c)
		astar.set_point_solid(c, true)
	eco.cash_cent += p["refund"]
	_clear_preview()
	cost_dirty = true
	network_dirty = true
	if p["count"] > 0:
		_toast("Abriss: %d Felder, +%s erstattet (50 %%)" % [p["count"], money_str(p["refund"])], 2.5)
	elif p["reason"] != "":
		_toast(p["reason"])
	return p["refund"]


func begin_drag(cell: Vector2i) -> void:
	if cell.x < 0 or not (tool == Tool.ROAD or tool == Tool.RAIL or tool == Tool.DEMOLISH):
		return
	drag_start = cell
	dragging = true
	last_preview_cell = Vector2i(-99, -99)


## Tests/Screenshot: Cursor auf ein Feld setzen.
func drag_to(cell: Vector2i) -> void:
	sim_hover_active = true
	sim_hover = cell
	hover_cell = cell
	_update_preview()


func end_drag() -> bool:
	if not dragging:
		return false
	var end := hover_cell
	var start := drag_start
	dragging = false
	drag_start = Vector2i(-1, -1)
	plan = {}
	_clear_preview()
	if end.x < 0:
		return false
	if tool == Tool.DEMOLISH:
		demolish(start, end)
		return true
	return build_track(start, end, tool == Tool.RAIL)


func cancel_drag() -> void:
	dragging = false
	drag_start = Vector2i(-1, -1)
	plan = {}
	_clear_preview()


func _warehouse_cells(cell: Vector2i) -> Array:
	return [cell, cell + Vector2i(1, 0), cell + Vector2i(0, 1), cell + Vector2i(1, 1)]


func _warehouse_free(cell: Vector2i) -> bool:
	for c in _warehouse_cells(cell):
		if not _in_grid(c) or cell_to_building.has(c) or terrain_at(c) != Terrain.PLAIN or roads.has(c) or rails.has(c):
			return false
	return true


func build_warehouse(cell: Vector2i):
	if not _warehouse_free(cell):
		_toast("Hier ist kein Platz für ein Lager.")
		return null
	if warehouse_cent > eco.cash_cent:
		_toast("Zu wenig Geld: %s nötig." % money_str(warehouse_cent))
		return null
	warehouse_count += 1
	for c in _warehouse_cells(cell):
		_clear_decor(c)
	var w := Building.new()
	add_child(w)
	w.map_id = "lager_%d" % warehouse_count
	w.typ = "lager"
	w.setup(Building.Kind.WAREHOUSE, "Lager %d" % warehouse_count, cell, Vector2i(2, 2), Color(0.55, 0.45, 0.6), 1.2)
	w.owned = true
	_new_site_node(w)
	w.site = eco.add_warehouse_site(w.node_id)
	w.station = eco.s_station[w.site]
	_register(w)
	charge(warehouse_cent)
	cost_dirty = true
	network_dirty = true
	_clear_preview()
	_toast("%s gebaut. Lager nehmen alles an und geben alles ab – bezahlt wird erst beim Endabnehmer." % w.display_name)
	return w


func _vehicle_price(type: String) -> int:
	if type == "train":
		return int(vdefs["lok_e1"]["kauf_cent"]) + TRAIN_WAGONS * int(vdefs["waggon_e1"]["kauf_cent"])
	return int(vdefs[eco.slice["fahrzeug_ref"]["lkw_id"]]["kauf_cent"])


## Fahrzeugkauf aus Guthaben (vehicles.json). Startpaket: die ersten N Lkw kosten 0 $ (ANNAHME zu
## fahrzeug_ref.startpaket_lkw_*). Gibt das Fahrzeug (noch ohne Linie) oder null zurück.
func buy_vehicle(type: String):
	if not company_started or bankrupt:
		return null
	var price := _vehicle_price(type)
	var free := type == "truck" and free_trucks_left > 0
	if free:
		price = 0
	if price > eco.cash_cent:
		_toast("Zu wenig Geld für %s (%s)." % ["Zug" if type == "train" else "Lkw", money_str(price)])
		return null
	if free:
		free_trucks_left -= 1
	charge(price)
	var v := Vehicle.new()
	v.vid = next_vid
	next_vid += 1
	v.slot = shim.add_vehicle_slot(v.vid)
	v.type = type
	v.load_ticks = load_ticks
	v.periode_ticks = periode_ticks
	if type == "train":
		var lok: Dictionary = vdefs["lok_e1"]
		var wag: Dictionary = vdefs["waggon_e1"]
		v.kind_name = "Zug"
		v.cap = TRAIN_WAGONS * int(wag["kapazitaet_einheiten"])
		v.speed = float(lok["tempo_mm_pro_tick"]) / feld_mm
		v.fix_cent = int(lok["fix_cent_pro_periode"]) + TRAIN_WAGONS * int(wag["fix_cent_pro_periode"])
		v.var_cent_per_field = int(lok["variabel_cent_pro_feld"]) + TRAIN_WAGONS * int(wag["variabel_cent_pro_feld"])
		v.max_wait_ticks = TRAIN_MAX_WAIT_TICKS
	else:
		var d: Dictionary = vdefs[eco.slice["fahrzeug_ref"]["lkw_id"]]
		v.kind_name = "Lkw"
		v.cap = int(d["kapazitaet_einheiten"])
		v.speed = float(d["tempo_mm_pro_tick"]) / feld_mm
		v.fix_cent = int(d["fix_cent_pro_periode"])
		v.var_cent_per_field = int(d["variabel_cent_pro_feld"])
		v.max_wait_ticks = TRUCK_MAX_WAIT_TICKS
	v.rindex = n_type[type]
	n_type[type] += 1
	vehicles.append(v)
	cost_dirty = true
	return v


func create_line(a, b, type: String):
	var astar: AStarGrid2D = astar_rail if type == "train" else astar_road
	var path := astar.get_id_path(a.anchor(), b.anchor())
	if path.is_empty():
		_toast("Keine %sverbindung zwischen %s und %s." % ["Gleis" if type == "train" else "Straßen", a.display_name, b.display_name])
		return null
	var v = buy_vehicle(type)
	if v == null:
		return null
	v.assign(a, b, Array(path))
	register_line(v)
	_toast("%s-Linie: %s → %s (%d Felder)" % [v.kind_name, a.display_name, b.display_name, v.distance])
	_refresh_lines()
	_check_milestones()
	return v


## Fahrzeug mit Linie in die Linienliste aufnehmen (auch für Bench-Fahrzeuge, die direkt assign() nutzen).
func register_line(v) -> void:
	lines_dirty = true
	n_assigned += 1
	if not line_groups.has(v.group_key):
		line_groups[v.group_key] = []
		line_order.append(v.group_key)
	line_groups[v.group_key].append(v)


func _clear_preview() -> void:
	for c in preview_root.get_children():
		c.queue_free()
	last_preview_cell = Vector2i(-99, -99)


## Ghost-Feld nach S-08: Füllung plus dunkler Saum darunter (B-04).
func _ghost(c: Vector2i, mat: Material) -> void:
	var lift := 0.0
	if terrain_at(c) == Terrain.MOUNTAIN:
		lift = mountain_h[idx(c)]
	var bb = cell_to_building.get(c)
	if bb != null and not city_streets.has(c):
		lift = minf(bb.height, 3.0) + 0.05
	var saum := MeshInstance3D.new()
	var sb := BoxMesh.new()
	sb.size = Vector3(1.0, 0.06, 1.0)
	saum.mesh = sb
	saum.material_override = mat_saum
	saum.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	saum.position = Vector3(c.x + 0.5, 0.08 + lift, c.y + 0.5)
	preview_root.add_child(saum)
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.8, 0.1, 0.8)
	mi.mesh = box
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = Vector3(c.x + 0.5, 0.14 + lift, c.y + 0.5)
	preview_root.add_child(mi)


func _update_preview() -> void:
	if hover_cell == last_preview_cell:
		return
	_clear_preview()
	last_preview_cell = hover_cell
	plan = {}
	if hover_cell.x < 0:
		return
	if tool == Tool.WAREHOUSE:
		var free := _warehouse_free(hover_cell)
		for c in _warehouse_cells(hover_cell):
			_ghost(c, mat_ok if free else mat_bad)
		return
	if not dragging:
		return
	if tool == Tool.DEMOLISH:
		plan = plan_demolish(drag_start, hover_cell)
		for it in plan["items"]:
			_ghost(it["cell"], mat_demolish if it["state"] == "remove" else mat_bad)
		return
	plan = plan_track(drag_start, hover_cell, tool == Tool.RAIL)
	for it in plan["items"]:
		match it["state"]:
			"new":
				_ghost(it["cell"], mat_ok)
			"bad":
				_ghost(it["cell"], mat_bad)
			_:
				_ghost(it["cell"], mat_exist)


func _update_cursor_label() -> void:
	if not dragging or plan.is_empty() or hover_cell.x < 0:
		cursor_box.visible = false
		return
	cursor_box.visible = true
	var world := Vector3(hover_cell.x + 0.5, 0.0, hover_cell.y + 0.5)
	cursor_box.position = cam.unproject_position(world) + Vector2(22, 8)
	if plan.get("demolish", false):
		cursor_cost.text = "Abriss: %d Felder  +%s (50 %%)" % [plan["count"], money_str(plan["refund"])]
		cursor_cost.modulate = _pal("status_warn", 1.0)
		cursor_reason.text = plan["reason"]
		return
	cursor_cost.text = "%s: %d Felder  %s" % ["Gleis" if plan["rail"] else "Straße", plan["new_count"], money_str(plan["total"])]
	cursor_cost.modulate = Color(1, 1, 1) if plan["ok"] else _pal("status_bad", 1.0)
	cursor_reason.text = "" if plan["ok"] else "✖ " + plan["reason"]


# ---------------------------------------------------------------- Simulation

func charge(cent: int) -> void:
	eco.cash_cent -= cent
	expenses_total += cent


func _recompute_running_cost() -> void:
	var c := 0
	for v in vehicles:
		c += v.fix_cent
	c += warehouse_count * warehouse_upkeep
	c += rails.size() * rail_upkeep_per_field
	running_cost_per_period = c
	cost_dirty = false


## Ein fester Tick (tick_ms aus JSON): Ökonomie, Fahrzeuge, Unterhalt, Bankrott.
func sim_tick() -> void:
	if not company_started or bankrupt:
		return
	shim.tick_count += 1
	eco.on_tick(shim)
	for v in vehicles:
		v.tick(self)
	if cost_dirty:
		_recompute_running_cost()
	cost_acc += running_cost_per_period
	var c := cost_acc / periode_ticks
	if c > 0:
		cost_acc -= c * periode_ticks
		charge(c)
	if eco.cash_cent < 0:
		_go_bankrupt()
	elif shim.tick_count % 10 == 0:
		_check_milestones()


func run_ticks(n: int) -> void:
	for i in n:
		if bankrupt:
			return
		sim_tick()


func _go_bankrupt() -> void:
	bankrupt = true
	speed = 0
	_refresh_speed_buttons()
	_set_tool(Tool.NONE)
	bankrupt_panel.visible = true
	bankrupt_label.text = "Kasse %s nach %s Spielzeit. Ohne Kredit (ab Sprint 5) ist ein Konto unter 0 $ das Ende.\nEinnahmen %s · Ausgaben %s · Fahrzeuge %d (Unterhalt %s/min)." % [
		money_str(eco.cash_cent), time_str(shim.tick_count), money_str(eco.revenue_total), money_str(expenses_total),
		vehicles.size(), money_str(running_cost_per_period)]
	print("BANKROTT tick=%d kasse=%d" % [shim.tick_count, eco.cash_cent])


func on_delivery(v, units: int, income: int, trip_cost: int) -> void:
	deliveries.append({"tick": shim.tick_count, "units": units, "income": income, "trip_cost": trip_cost,
		"src": v.src.map_id, "dst": v.dst.map_id})
	if income > trip_cost:
		deliveries_profit += 1
	if income > 0:
		_complete(4)
		if not eco.ledger.is_empty():
			var g: String = eco.ledger[-1]["gut"]
			if g == "mehl" or g == "stahl":
				_complete(6)
	if is_inside_tree() and v.path.size() > 0 and bench == null:
		var p: Vector3 = v.world_xz(0.0)
		_float_text(Vector3(p.x, 0, p.z), "+%s" % money_str(income) if income > 0 else "0 $ (Lager)")
	if deliveries_profit >= 3:
		_complete(5)


func _float_text(pos: Vector3, text: String) -> void:
	var l := Label3D.new()
	l.text = text
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.font_size = 64
	l.pixel_size = 0.02
	l.modulate = _pal("status_ok", 1.0)
	l.outline_size = 12
	l.position = pos + Vector3(0, 1.5, 0)
	add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "position", l.position + Vector3(0, 3, 0), 1.5)
	tw.tween_callback(l.queue_free)


# ---------------------------------------------------------------- Anzeige

func _refresh_lines() -> void:
	var rows := []
	if not line_order.is_empty():
		rows.append("Linien (Gewinn pro Minute nach Unterhalt):")
	for i in mini(line_order.size(), 8):
		var list: Array = line_groups[line_order[i]]
		var v = list[0]
		var profit := 0.0
		var deliv := 0
		var warn := false
		for w in list:
			profit += w.profit_per_minute(month_ticks)
			deliv += w.deliveries
			warn = warn or w.no_licence
		rows.append("  %s ×%d  %s → %s  (%d Felder, %d Lieferungen)   %+d $/min%s" % [v.kind_name, list.size(), v.src.display_name,
			v.dst.display_name, v.distance, deliv, int(profit), "  ⚠ keine Lizenz" if warn else ""])
	if line_order.size() > 8:
		rows.append("  … %d weitere Linien" % (line_order.size() - 8))
	var idle := vehicles.size() - n_assigned
	if idle > 0:
		rows.append("  %d Fahrzeuge ohne Linie (Unterhalt läuft)" % idle)
	lines_label.text = "\n".join(rows)


func _building_label(b) -> String:
	match b.kind:
		Building.Kind.CITY:
			return "%s\n%s · %d Einw." % [b.display_name, STAGE_NAMES.get(b.city_stage, b.city_stage), b.city_pop]
		Building.Kind.WAREHOUSE:
			return "%s\n%d Einheiten" % [b.display_name, shim.st_stock[b.station]]
		Building.Kind.INERT:
			return "%s\n(Kulisse)" % b.display_name
		Building.Kind.SINK:
			return "%s\nnimmt %s" % [b.display_name, _goods_txt(b.in_goods)]
	var lic := "✔ Lizenz" if eco.licence_valid(b.site) else "Klick: Lizenz"
	if b.kind == Building.Kind.PROCESSOR:
		var buf: Dictionary = eco.s_inbuf[b.site]
		var n_in := 0
		for gi in buf:
			n_in += buf[gi]
		return "%s\n%s %d → %s %d\n%s" % [b.display_name, _goods_txt(b.in_goods), n_in, good_names.get(b.out_good, ""), shim.st_stock[b.station], lic]
	return "%s\n%s %d\n%s" % [b.display_name, good_names.get(b.out_good, ""), shim.st_stock[b.station], lic]


func _refresh_labels() -> void:
	eco.sync_all(shim)
	for b in buildings:
		b.label.text = _building_label(b)
		if b.site >= 0 and b.is_industry():
			b.licence_marker.visible = eco.licence_valid(b.site)


## Fahrzeuge zeichnen: drei MultiMeshes, Puffer je Sim-Tick am Stück gebaut (12 Floats Transform, Ladung + 4
## Farbe; Layout wie set_instance_transform: [c,0,s,x, 0,1,0,y, -s,0,c,z] für Drehung um Y). Zwischen zwei
## Ticks interpoliert die Engine (Physik-Interpolation, physics_ticks_per_second = 1000 / tick_ms), damit das
## Skript nicht in jedem Frame 5.000 Transformationen schreiben muss (Bench F-12).
## Indizes sind stabil (Fahrzeuge werden im Slice nie entfernt): Lkw/Zug über v.rindex, Ladung über die
## Position in `vehicles`. Fahrzeuge ohne Linie bzw. ohne Ladung haben Skalierung 0.
var _cur := {"truck": PackedFloat32Array(), "train": PackedFloat32Array(), "cargo": PackedFloat32Array()}
var _prev := {"truck": PackedFloat32Array(), "train": PackedFloat32Array(), "cargo": PackedFloat32Array()}
var n_type := {"truck": 0, "train": 0}


func _ensure_buf(key: String, n: int, stride: int, mm: MultiMesh) -> void:
	var need := n * stride
	if _cur[key].size() >= need:
		return
	var cap := maxi(64, n * 2)
	var a: PackedFloat32Array = _cur[key]
	a.resize(cap * stride)
	_cur[key] = a
	_prev[key] = a.duplicate()
	mm.instance_count = cap
	mm.visible_instance_count = -1


func _render_vehicles() -> void:
	_ensure_buf("truck", n_type["truck"], 12, mm_truck.multimesh)
	_ensure_buf("train", n_type["train"], 12, mm_train.multimesh)
	_ensure_buf("cargo", vehicles.size(), 16, mm_cargo.multimesh)
	var bt: PackedFloat32Array = _cur["truck"]
	var bz: PackedFloat32Array = _cur["train"]
	var bc: PackedFloat32Array = _cur["cargo"]
	var cargo_arr: PackedInt32Array = shim.v_cargo
	var gi := -1
	for v in vehicles:
		gi += 1
		var st: int = v.state
		var is_train: bool = v.type == "train"
		var k: int = v.rindex * 12
		var kc := gi * 16
		if st == Vehicle.State.IDLE:
			for j in 12:
				if is_train:
					bz[k + j] = 0.0
				else:
					bt[k + j] = 0.0
				bc[kc + j] = 0.0
			continue
		var path: PackedVector2Array = v.path
		var last := path.size() - 1
		var p: float = v.prog
		var i := int(p)
		var a: Vector2 = path[i]
		var b: Vector2 = path[mini(i + 1, last)]
		if i == last and last > 0:
			a = path[last - 1]
			b = path[last]
			p = float(last)
			i = last - 1
		var f := p - i
		var x := a.x + (b.x - a.x) * f
		var z := a.y + (b.y - a.y) * f
		var dx := b.x - a.x
		var dz := b.y - a.y
		if st == Vehicle.State.TO_SRC:
			dx = -dx
			dz = -dz
		var c := 1.0
		var s := 0.0
		var l := sqrt(dx * dx + dz * dz)
		if l > 0.0:
			s = dx / l      # sin(atan2(dx, dz))
			c = dz / l      # cos(atan2(dx, dz))
		if is_train:
			bz[k] = c; bz[k + 1] = 0.0; bz[k + 2] = s; bz[k + 3] = x
			bz[k + 4] = 0.0; bz[k + 5] = 1.0; bz[k + 6] = 0.0; bz[k + 7] = 0.35
			bz[k + 8] = -s; bz[k + 9] = 0.0; bz[k + 10] = c; bz[k + 11] = z
		else:
			bt[k] = c; bt[k + 1] = 0.0; bt[k + 2] = s; bt[k + 3] = x
			bt[k + 4] = 0.0; bt[k + 5] = 1.0; bt[k + 6] = 0.0; bt[k + 7] = 0.3
			bt[k + 8] = -s; bt[k + 9] = 0.0; bt[k + 10] = c; bt[k + 11] = z
		if cargo_arr[v.slot] > 0:
			var col: Color = Color.WHITE
			var lots: Array = eco.v_lots.get(v.vid, [])
			if not lots.is_empty():
				col = GOOD_COLORS.get(eco.g_ids[lots[0][0]], Color.WHITE)
			bc[kc] = c; bc[kc + 1] = 0.0; bc[kc + 2] = s; bc[kc + 3] = x
			bc[kc + 4] = 0.0; bc[kc + 5] = 1.0; bc[kc + 6] = 0.0; bc[kc + 7] = 0.75 if not is_train else 0.85
			bc[kc + 8] = -s; bc[kc + 9] = 0.0; bc[kc + 10] = c; bc[kc + 11] = z
			bc[kc + 12] = col.r; bc[kc + 13] = col.g; bc[kc + 14] = col.b; bc[kc + 15] = 1.0
		else:
			for j in 12:
				bc[kc + j] = 0.0
	_cur["truck"] = bt
	_cur["train"] = bz
	_cur["cargo"] = bc
	mm_truck.multimesh.set_buffer_interpolated(bt, _prev["truck"])
	mm_train.multimesh.set_buffer_interpolated(bz, _prev["train"])
	mm_cargo.multimesh.set_buffer_interpolated(bc, _prev["cargo"])
	_prev["truck"] = bt.duplicate()
	_prev["train"] = bz.duplicate()
	_prev["cargo"] = bc.duplicate()


## Fester Sim-Takt: ein Physik-Tick = tick_ms; Tempo n = n Sim-Ticks je Physik-Tick.
func _physics_process(_delta: float) -> void:
	if company_started and not bankrupt and speed > 0:
		for i in speed:
			sim_tick()
			if bankrupt:
				break
	_render_vehicles()


func _process(delta: float) -> void:
	if toast_time > 0.0:
		toast_time -= delta
		if toast_time <= 0.0:
			toast_label.text = ""
	_move_camera(delta)
	var ms := maxf(1.0, zoom / 1.4)          # Marker wächst beim Rauszoomen mit (S-08 marker)
	for m in goal_markers:
		m.scale = Vector3.ONE * ms
		m.position.y = m.get_meta("base_y") + (2.0 * ms) + sin(Time.get_ticks_msec() * 0.004) * 0.6 * ms

	label_timer -= delta
	if label_timer <= 0.0:
		label_timer = 0.25
		_refresh_labels()
		_refresh_panel()
		lines_timer -= 1
		if lines_timer <= 0:
			lines_timer = 4
			_refresh_lines()

	hover_cell = sim_hover if sim_hover_active else _mouse_cell()
	hover_marker.visible = hover_cell.x >= 0 and tool != Tool.NONE
	if hover_marker.visible:
		hover_marker.position = Vector3(hover_cell.x + 0.5, 0.05, hover_cell.y + 0.5)

	var cpm := running_cost_per_period * month_ticks / periode_ticks
	info_label.text = "Kasse: %s    Einnahmen: %s    Kosten: %s/min    Fahrzeuge: %d    Spielzeit %s    Werkzeug: %s" % [
		money_str(eco.cash_cent), money_str(eco.revenue_total), money_str(cpm), vehicles.size(), time_str(shim.tick_count), TOOL_NAMES[tool]]
	info_label.modulate = _pal("status_bad", 1.0) if eco.cash_cent < cpm * 2 else Color(1, 1, 1)
	_update_hint()
	_update_cursor_label()


func _update_hint() -> void:
	if not company_started:
		hint_label.text = "Wähle oben deinen Start: Agrar oder Bergbau."
		return
	match tool:
		Tool.ROAD, Tool.RAIL:
			var what: String = "Gleis" if tool == Tool.RAIL else "Straße"
			if not dragging:
				hint_label.text = "%s: Maustaste am Startfeld drücken und zum Ziel ziehen (gerade + 45°). Wasser nur gerade (Brücke ×6), Berg ×3." % what
			else:
				_update_preview()
				hint_label.text = "%s: Loslassen = bauen · Rechtsklick/Esc = abbrechen · weiß = baubar, rot = nicht baubar" % what
		Tool.DEMOLISH:
			if dragging:
				_update_preview()
			hint_label.text = "Abriss: Fläche über eigene Straßen/Gleise ziehen, Loslassen = abreißen (50 % Erstattung) · Rechtsklick/Esc = abbrechen"
		Tool.WAREHOUSE:
			_update_preview()
			hint_label.text = "Lager: Platz anklicken (2×2), %s, Unterhalt %s/min. Lager zahlen nichts – sie sammeln und verteilen." % [money_str(warehouse_cent), money_str(warehouse_upkeep)]
		Tool.TRUCK_LINE, Tool.TRAIN_LINE:
			var vname: String = "Zug" if tool == Tool.TRAIN_LINE else "Lkw"
			var need: String = "Gleis" if tool == Tool.TRAIN_LINE else "Straße"
			var extra := " (%d gratis im Startpaket)" % free_trucks_left if tool == Tool.TRUCK_LINE and free_trucks_left > 0 else ""
			if line_src == null:
				hint_label.text = "%s-Linie%s: Quelle anklicken (Farm/Mine mit Lizenz, Verarbeiter mit Lizenz oder Lager)." % [vname, extra]
			else:
				hint_label.text = "%s-Linie ab %s: Ziel anklicken. Quelle und Ziel müssen per %s verbunden sein." % [vname, line_src.display_name, need]
		_:
			hint_label.text = "Klick auf Gebäude = Panel (Lizenz) · WASD bewegen · Q/E drehen · Mausrad zoomen · [1] Straße · [2] Gleis · [3] Lager · [4] Lkw · [5] Zug · [X] Abriss · Leertaste Pause"


func _move_camera(delta: float) -> void:
	var move := Vector3.ZERO
	if Input.is_key_pressed(KEY_W):
		move.z -= 1
	if Input.is_key_pressed(KEY_S):
		move.z += 1
	if Input.is_key_pressed(KEY_A):
		move.x -= 1
	if Input.is_key_pressed(KEY_D):
		move.x += 1
	if move != Vector3.ZERO:
		rig.position += rig.basis * move.normalized() * 18.0 * zoom * delta
		rig.position = rig.position.clamp(Vector3.ZERO, Vector3(GRID, 0, GRID))
	if Input.is_key_pressed(KEY_Q):
		rig.rotation.y += 1.5 * delta
	if Input.is_key_pressed(KEY_E):
		rig.rotation.y -= 1.5 * delta
