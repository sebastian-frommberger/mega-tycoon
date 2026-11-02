extends Node3D
## Mega Tycoon – Grey-Box-Slice (F-14, Sprint 4). Basis: Prototyp v3 (prototype/main.gd: UI, Bau-Tool,
## Lkw/Zug-Linien, Lager, Abriss). Neu gegenüber dem Prototyp:
##   (1) Karte 512² aus data/slice_map.json (S-10, eingefroren): Städte, Industrien K1–K3, Gelände in
##       2 Typen (Wasser = Fluss/Küste, Gebirge), Wald nur Deko; Grey-Box-Gebäude, Farben aus S-08.
##   (2) Ökonomie aus economy.gd + T-06-JSON: Ertrag nur beim Endabnehmer, Luftlinie, Lager 0 $, Sättigung,
##       Lizenzpflicht zum Laden. Fahrzeugkauf und Unterhalt aus vehicles.json, Lager-Unterhalt aus JSON.
##       Kredit (F-19): bis 2.000 $ manuell; Kasse unter 0 $ = Bankrott.
##   (3) Start auf der Karte: HQ-Platzierung (F-20, hq_placement.gd), Klick-Panel mit Knopf „Lizenz kaufen“ (Preis, Ertrag/Monat).
##   (4) Ziele oben rechts mit „Nächster Schritt“ und gelbem Marker über dem Ziel.
## Alles wird im Code aufgebaut (keine Szenen außer main.tscn).

const Building := preload("res://building.gd")
const Vehicle := preload("res://vehicle.gd")
const Economy := preload("res://economy.gd")
const EcoShim := preload("res://eco_shim.gd")
const KenneyLoader := preload("res://props/kenney_loader.gd")   # S-11: Natur-Props (CC0)
const HqPlacement := preload("res://hq_placement.gd")            # F-20: HQ-Platzierung (D22)
const SimWorld := preload("res://core/sim_world.gd")    # F-18: SoA-Kern mit Linienbetrieb
const FleetSoa := preload("res://fleet_soa.gd")
const Credit := preload("res://credit.gd")             # F-19
const Bench := preload("res://bench.gd")
const RenderBatch := preload("res://render_batch.gd")
const WorldSel := preload("res://world/welt.gd")       # W-01 (S7): Weltauswahl + Maßstab, siehe world/welt.gd
const S7World := preload("res://world/s7_world.gd")    # W-01: Hooks der S7-Welt (nur bei --welt=s7)
const RoadTiles := preload("res://world/road_tiles.gd")  # W-04 (S7): Kenney-Kacheln mit Autotile (nur bei --welt=s7)
const BauS7 := preload("res://world/bau_s7.gd")          # W-04: Hang-Preis/Steigungssperre (nur bei --welt=s7)
const FT := preload("res://ui/fehlertexte.gd")           # U-03 (S7): Fehlertexte nach Aylins Liste
const BankrottWarnung := preload("res://ui/bankrott_warnung.gd")   # U-03: Vorwarnung >= 60 s vor 0 $
const ThemeBuilder := preload("res://ui/theme/theme_builder.gd")
const Kit := preload("res://ui/ui_kit.gd")
const UiFx := preload("res://ui/ui_fx.gd")
const HUD_H := 62          # Höhe HUD-Leiste oben
const PANEL_W := 380       # Kontextpanel rechts: 380 / 1600 = 23,75 % (F-15: ≤ 25 %)
const LEFT_W := 340        # Ziele/Linien links

const MAP_PATH := "res://data/slice_map.json"
const SLICE_PATH := "res://data/economy_slice.json"
const CONSTS_PATH := "res://data/economy_constants.json"
const VEHICLES_PATH := "res://data/vehicles.json"
const GOODS_PATH := "res://data/goods.json"
const PALETTE_PATH := "res://data/palette_s08.json"

## T-12: Gleis-, Brücken-, Berg-Kosten und Gratis-Startlkw stehen jetzt im JSON (economy_slice.json, Abschnitt bau_kosten).
## Prototyp-Werte, die (noch) nicht im JSON stehen (ANNAHME, Genre-Standard OpenTTD):
const BRIDGE_MAX := 8              # Brücke nur gerade, Land an beiden Enden, max. 8 Felder
const TRAIN_WAGONS := 4            # Zug = Lok + 4 Waggons (40 Einheiten wie Prototyp)
const RENDER_SPLIT := true         # S6: Fahrzeug-Puffer (SoA) über die Frames zwischen Ticks verteilen (F-12 p95)
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

# ---------------------------------------------------------------- Daten
## F-18 Schalter Fahrzeug-Kern: "alt" = Prototyp-Fahrzeuge (vehicle.gd + eco_shim.gd), "soa" = SoA-Kern
## (core/sim_world.gd über fleet_soa.gd). Default "soa" seit F-18 (Parität exakt, siehe felix.md); "alt" bleibt Rückfall.
## Umschalten: Kommandozeile --fahrzeuge=soa (bzw. =alt) oder vor dem Laden Main.core_override = "soa".
const VEHICLE_CORE_DEFAULT := "soa"
static var core_override := ""
## W-01 (S7): Welt "slice" (Default) oder "s7". Umschalten: --welt=s7, ProjectSettings mega_tycoon/welt oder
## vor dem Laden Main.world_override = "s7" (Reihenfolge siehe world/welt.gd).
static var world_override := ""
var welt := WorldSel.DEFAULT
var world_s7 = null                 # S7World, nur bei welt == "s7"
var road_tiles = null               # W-04: RoadTiles, nur bei welt == "s7" (Slice: Quader wie bisher)
var bk_warn = BankrottWarnung.new() # U-03: Kassenprognose + größter Verlustposten
var m_pro_feld := WorldSel.m_pro_feld(WorldSel.DEFAULT)   # nur Darstellung/Text, Sim bleibt in Feldern
var zoom_min := 0.4
var zoom_max := 26.0
var vehicle_core := VEHICLE_CORE_DEFAULT
var fleet = null                    # F-18: FleetSoa (nur bei vehicle_core == "soa")
var credit = Credit.new()           # F-19: Kredit (Werte aus economy_slice.json „kredit“)
var credit_buttons: Array = []      # [+ aufnehmen, − tilgen] im HUD-Kassenfeld
var eco = null
var shim = null                     # alt: EcoShim, soa: SimWorld (beide mit der Schnittstelle, die economy.gd liest)
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
var rail_cent := 4000                # bau_kosten.gleis_cent_pro_feld
var water_factor_pm := 6000          # bau_kosten.bruecke_faktor_promille
var mountain_factor_pm := 3000       # bau_kosten.berg_faktor_promille
var start_trucks_free := true        # bau_kosten.startpaket_lkw_gratis_flag
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
var sun: DirectionalLight3D
var label_tier := -1          # S-11 Label-LOD: 0 fern, 1 mittel, 2 nah
var zoom := 1.0
var preview_root: Node3D
var hover_marker: MeshInstance3D
var goal_markers: Array = []
var ui: CanvasLayer
var ui_root: Control
var ui_theme: Theme
var fx: Node
var hud_vals := {}
var hint_label: Label
var hint_panel: PanelContainer
var toast_label: Label
var toast_panel: PanelContainer
var toast_time := 0.0
var milestone_rows: Array = []
var ms_panel: PanelContainer
var ms_count_label: Label
var next_step_label: Label
var lines_card: PanelContainer
var lines_box: VBoxContainer
var lines_label: Label
var line_rows := {}             # group_key -> {row, title, sub, val}
var lines_scroll: ScrollContainer   # U-03: Linienliste scrollt
const LINE_ROW_H := 54             # Zeilenhöhe Linienliste (2 Zeilen + Abstand), für Fenster und Scrollhöhe
var speed_buttons: Array = []
var tool_buttons: Array = []
var panel: PanelContainer
var panel_icon: TextureRect
var panel_title: Label
var panel_sub: Label
var panel_status_shape: Control
var panel_status_text: Label
var panel_fields: VBoxContainer
var panel_field_rows: Array = []
var panel_lic: PanelContainer
var panel_lic_head: Label
var panel_lic_text: Label
var panel_lic_bar: ProgressBar
var panel_why: PanelContainer
var panel_why_text: Label
var panel_button: Button
var panel_reason: Label
var panel_line_button: Button
var hq = null                   # F-20: hq_placement.gd
var bankrupt_panel: PanelContainer
var bankrupt_label: Label
var cursor_box: PanelContainer
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
var mm_truck: MultiMeshInstance3D
var mm_train: MultiMeshInstance3D
var mm_cargo: MultiMeshInstance3D
var render_batch: Node3D             # S7 B (Felix 2): Straßen-/Gleisfelder und Lager gebündelt (render_batch.gd)
## S7 B Hook Fahrzeughöhe (Felix/Fable, Terrain): Höhe je Feld vorberechnet, Index = z * Breite + x (Felder);
## leer = 0 (Slice). Alternativ vehicle_height_fn(x: float, z: float) -> float (langsamer, nur wenn kein Gitter).
## Setzen über set_vehicle_heights(); wirkt ab dem nächsten Fahrzeug-Puffer, rein Darstellung.
var vehicle_h_grid := PackedFloat32Array()
var vehicle_h_w := 0
var vehicle_height_fn := Callable()


func _ready() -> void:
	var t0 := Time.get_ticks_usec()
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF   # nur die Fahrzeug-MultiMeshes interpolieren
	_load_data()
	_setup_materials()
	_setup_environment()
	_setup_camera()
	_setup_ground()
	if world_s7 != null:
		world_s7.build_terrain(self)   # W-01: Block A no-op (flache 512²-Ebene), Block B Heightmap
	_build_map()
	if world_s7 != null:
		road_tiles = RoadTiles.new()   # W-04: Stadtstraßen + eigene Strecken als Kacheln
		road_tiles.setup(self)
		road_tiles.refresh()
	load_ms = (Time.get_ticks_usec() - t0) / 1000.0
	_setup_vehicle_meshes()
	render_batch = RenderBatch.new()
	render_batch.name = "RenderBatch"
	add_child(render_batch)
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


func _pick_vehicle_core() -> String:
	if core_override != "":
		return core_override
	for a in OS.get_cmdline_user_args() + OS.get_cmdline_args():
		if a.begins_with("--fahrzeuge="):
			return "soa" if a.substr(12) == "soa" else "alt"
	return VEHICLE_CORE_DEFAULT


func _load_data() -> void:
	vehicle_core = _pick_vehicle_core()
	welt = WorldSel.pick(world_override, OS.get_cmdline_user_args() + OS.get_cmdline_args())
	m_pro_feld = WorldSel.m_pro_feld(welt)
	if welt == "s7":
		world_s7 = S7World.new()
	shim = SimWorld.new() if vehicle_core == "soa" else EcoShim.new()
	eco = Economy.new()
	if not eco.load_from(SLICE_PATH, CONSTS_PATH):
		for e in eco.errors:
			push_error("Ökonomie-JSON: " + e)
	eco.attach(shim)
	map_data = _json(MAP_PATH if world_s7 == null else world_s7.map_path(MAP_PATH))
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
	var bk: Dictionary = eco.slice["bau_kosten"]
	rail_cent = int(bk["gleis_cent_pro_feld"])
	water_factor_pm = int(bk["bruecke_faktor_promille"])
	mountain_factor_pm = int(bk["berg_faktor_promille"])
	start_trucks_free = bool(bk["startpaket_lkw_gratis_flag"])
	load_ticks = int(eco.slice["fahrzeug_ref"]["load_ticks"])
	warehouse_cent = int(eco.slice["lager"]["warehouse_cost_cent"])
	warehouse_upkeep = int(eco.slice["lager"]["warehouse_upkeep_cent_pro_periode"])
	refund_promille = int(eco.slice["genre_standard"]["demolition_refund_promille"])
	rail_upkeep_per_field = int(vdefs["lok_e1"].get("gleis_cent_pro_feld_pro_periode", 0))
	if vehicle_core == "soa":
		fleet = FleetSoa.new(shim, feld_mm)
		fleet.h_grid = vehicle_h_grid      # S7 B: Höhen-Hook auch, wenn vor dem Kern gesetzt
		fleet.h_w = vehicle_h_w
		fleet.h_fn = vehicle_height_fn
	credit.setup(eco)
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


## S-11 Licht + Palette: warme Sonne, tiefer Winkel mit weichen, leichten Schatten; Himmel und Dunst dezent
## und im Farbton des Horizonts, damit das Kartenende nicht hart abbricht. Gras bleibt bei der S-08-Palette:
## Ambient + Sonne sind so gewählt, dass die beleuchtete Wiese ungefähr den Palettenwert trifft, nicht heller.
const SUN_COLOR := Color(1.0, 0.92, 0.78)
const SKY_HORIZON := Color(0.76, 0.84, 0.91)
const SUN_ENERGY := 0.52
const AMBIENT_ENERGY := 0.36


func _setup_environment() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.36, 0.56, 0.80)
	sm.sky_horizon_color = SKY_HORIZON
	sm.sky_curve = 0.18
	sm.ground_horizon_color = SKY_HORIZON
	sm.ground_bottom_color = Color(0.62, 0.72, 0.80)
	sm.sun_angle_max = 0.0
	var sky := Sky.new()
	sky.sky_material = sm
	sky.radiance_size = Sky.RADIANCE_SIZE_32
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.74, 0.81, 0.92)
	env.ambient_light_energy = AMBIENT_ENERGY
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.fog_enabled = true
	env.fog_light_color = SKY_HORIZON
	env.fog_density = 0.00022
	env.fog_sky_affect = 0.0
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, 38, 0)
	sun.light_color = SUN_COLOR
	sun.light_energy = SUN_ENERGY
	sun.shadow_enabled = true
	sun.shadow_opacity = 0.5
	sun.shadow_blur = 1.6
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 250.0
	add_child(sun)


func _setup_camera() -> void:
	rig = Node3D.new()
	rig.position = Vector3(GRID * 0.5, 0, GRID * 0.5)
	add_child(rig)
	cam = Camera3D.new()
	cam.far = 6000.0
	cam.near = 0.8                  # S-11: bessere Tiefenpräzision bei weitem Zoom (Streifen zwischen Ebenen)
	rig.add_child(cam)
	cam.rotation = Vector3(-atan2(20.0, 16.0), 0, 0)
	if world_s7 != null:
		world_s7.setup_camera(self)
	zoom = 16.0
	_apply_zoom()


func _apply_zoom() -> void:
	if world_s7 != null:
		world_s7.apply_zoom(self)   # W-01: Klemme 40 m–5,6 km, near/far
	cam.position = Vector3(0, 20, 16) * zoom
	if sun != null:   # Schattenreichweite folgt dem Zoom: nah scharf, fern nicht verschwendet
		sun.directional_shadow_max_distance = clampf(zoom * 26.0 * 1.4, 110.0, 520.0)


## W-01: Distanztext. Slice: "%d Felder" wie bisher (bitgleich), S7: m/km aus m_pro_feld (world/welt.gd).
func dist_str(felder: int) -> String:
	return WorldSel.dist_text(welt, felder)


func focus(cell: Vector2, z: float) -> void:
	rig.position = Vector3(cell.x, 0, cell.y)
	zoom = z
	_apply_zoom()


func _setup_ground() -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(GRID, GRID)
	plane.subdivide_width = 63     # Compatibility-Renderer rechnet Nebel je Vertex: grobe Flächen würden sonst komplett vernebelt
	plane.subdivide_depth = 63
	ground.mesh = plane
	ground.material_override = _grass_material()
	ground.position = Vector3(GRID * 0.5, 0, GRID * 0.5)
	add_child(ground)
	# Weite Fläche um die Karte im Dunstton: kein harter Schnitt zwischen Kartenrand und Himmel (S-11)
	var outer := MeshInstance3D.new()
	var op := PlaneMesh.new()
	op.size = Vector2(GRID * 12.0, GRID * 12.0)
	op.subdivide_width = 47
	op.subdivide_depth = 47
	outer.mesh = op
	outer.material_override = _mat(Color(0.64, 0.74, 0.84), true)   # unshaded im Dunstton
	(outer.material_override as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	outer.position = Vector3(GRID * 0.5, -0.9, GRID * 0.5)       # Abstand gegen Z-Fighting bei weitem Zoom
	outer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(outer)
	preview_root = Node3D.new()
	add_child(preview_root)
	hover_marker = MeshInstance3D.new()
	var hb := BoxMesh.new()
	hb.size = Vector3(1, 0.05, 1)
	hover_marker.mesh = hb
	hover_marker.material_override = _mat(Color(1, 1, 1, 0.35), true)
	hover_marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(hover_marker)


## Gras: Palettenfarbe S-08 mit sehr leiser, kachelnder Helligkeitsvariation (±5 %), damit die Fläche nicht tot wirkt.
## Mittelwert der Textur ≈ 0,97, die Kontraste der Marker (S-08) bleiben dadurch unverändert.
func _grass_material() -> StandardMaterial3D:
	var m := _mat(_bg("gras"))
	m.roughness = 1.0
	var n := FastNoiseLite.new()
	n.seed = 7
	n.frequency = 0.018
	n.fractal_octaves = 3
	var img := n.get_seamless_image(256, 256)
	img.convert(Image.FORMAT_L8)
	var px := img.get_data()
	for i in px.size():
		px[i] = int(clampf(0.90 + (px[i] / 255.0) * 0.12, 0.0, 1.0) * 255.0)
	var tex := ImageTexture.create_from_image(Image.create_from_data(256, 256, false, Image.FORMAT_L8, px))
	m.albedo_texture = tex
	m.uv1_scale = Vector3(28, 28, 1)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return m


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
			map_missing_ids.append("HQ: Stadt %s fehlt" % h["stadt"])
		for i in h["industrien_im_radius"]:
			if not ids.has(i):
				map_missing_ids.append("HQ %s: Industrie %s fehlt" % [h["stadt"], i])


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
	if world_s7 == null:
		_multimesh(Vector3(1, 0.06, 1), street_t, street_c, false)   # W-04: S7 zeichnet Stadtstraßen als Kacheln
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


## Bäume: Kenney Nature Kit (CC0, 114/230 Dreiecke, Faktor ×0,8 Szene-Einheiten je Modell-Einheit) als zwei
## MultiMeshes; fehlt die GLB, fallen die Quader-Bäume des Prototyps ein. Krone nimmt die Palettenfarbe wald_baum.
func _scatter_trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var cand: Array = []
	for c in forest_cells:
		if rng.randf() < 0.5:
			cand.append(c)
	for i in 900:
		cand.append(Vector2i(rng.randi_range(0, GRID - 1), rng.randi_range(0, GRID - 1)))
	var c_tree := _bg("wald_baum")
	var trunk := Color(0.36, 0.26, 0.17)
	var meshes := [KenneyLoader.tree_mesh(KenneyLoader.TREE_DEFAULT, trunk), KenneyLoader.tree_mesh(KenneyLoader.TREE_PINE, trunk)]
	var use_kenney: bool = meshes[0] != null and meshes[1] != null
	var tt := [[], []]
	var tc := [[], []]
	var tcells := [[], []]
	for c in cand:
		if terrain_at(c) != Terrain.PLAIN or cell_to_building.has(c) or decor.has(c):
			continue
		var v := 0 if rng.randf() < 0.6 else 1
		var jitter := Vector3(rng.randf_range(-0.3, 0.3), 0.0, rng.randf_range(-0.3, 0.3))
		if use_kenney:
			var sc := KenneyLoader.NATURE_SCALE * rng.randf_range(0.8, 1.3)
			var b := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(sc, sc * rng.randf_range(0.9, 1.15), sc))
			tt[v].append(Transform3D(b, Vector3(c.x + 0.5, 0.0, c.y + 0.5) + jitter))
		else:
			var h := rng.randf_range(0.8, 1.8)
			tt[v].append(Transform3D(Basis().scaled(Vector3(0.6, h, 0.6)), Vector3(c.x + 0.5, h * 0.5, c.y + 0.5)))
		tc[v].append(c_tree.lightened(rng.randf_range(-0.05, 0.12)) if v == 0 else c_tree.darkened(0.08).lightened(rng.randf_range(-0.04, 0.08)))
		tcells[v].append(c)
		decor[c] = true
	for v in 2:
		var tm: MultiMeshInstance3D
		if use_kenney:
			tm = _multimesh_mesh(meshes[v], tt[v], tc[v], false)          # B-5: Bäume ohne Schatten (S-13)
		else:
			tm = _multimesh(Vector3(1, 1, 1), tt[v], tc[v], false)
		for i in tcells[v].size():
			decor[tcells[v][i]] = [tm, i]


## Wie _multimesh, aber mit beliebigem Mesh (Instanzfarbe tönt Flächen mit vertex_color_use_as_albedo).
func _multimesh_mesh(mesh: Mesh, transforms: Array, colors: Array, shadows: bool) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
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


func _build_terrain_visuals() -> void:
	var wt := []
	var wc := []
	var mt := []
	var mcol := []
	var mcells := []
	var c_w := _bg("wasser")
	var c_w2 := _bg("wasser_hell")
	var c_rock := _bg("berg_stein")
	var c_snow := _bg("berg_schnee").darkened(0.10)   # S-11: unter Sonne sonst ausgebrannt
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
	ui_theme = ThemeBuilder.build()
	fx = UiFx.new()
	fx.name = "UiFx"
	add_child(fx)
	ui_root = Control.new()
	ui_root.name = "UiRoot"
	ui_root.theme = ui_theme
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(ui_root)
	_setup_hud()
	_setup_left_column()
	_setup_dock_panel()
	_setup_toolbar()

	toast_panel = Kit.panel("PanelToast")
	toast_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	toast_panel.offset_top = HUD_H + 14
	toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_panel.visible = false
	ui_root.add_child(toast_panel)
	toast_label = Kit.label("", "LabelToast")
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_panel.add_child(Kit.hbox(10, [Kit.icon("info", 20, ThemeBuilder.C["amber"]), toast_label]))

	cursor_box = Kit.panel("PanelHint")
	cursor_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cursor_box.visible = false
	ui_root.add_child(cursor_box)
	var cb := Kit.vbox(2)
	cursor_box.add_child(cb)
	cursor_cost = Kit.label("", "LabelHud")
	cb.add_child(cursor_cost)
	cursor_reason = Kit.label("", "LabelHudSmall")
	cursor_reason.add_theme_color_override("font_color", ThemeBuilder.C["status_bad"])
	cb.add_child(cursor_reason)

	_style_map_labels()
	hq = HqPlacement.new()
	add_child(hq)
	hq.setup(self)
	map_missing_ids.append_array(hq.missing_preview_ids())
	_setup_bankrupt_panel()
	_refresh_speed_buttons()
	_refresh_tool_buttons()


## HUD oben (Genre: Anno-Ressourcenleiste): Kasse, Einnahmen, Kosten, Fahrzeuge, Zeit | Tempo.
func _setup_hud() -> void:
	var bar := Kit.panel("PanelHud")
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_bottom = HUD_H
	ui_root.add_child(bar)
	var h := Kit.hbox(8)      # D-07: 8-px-Raster, Kopfleiste passt auch mit breiten Zahlen in 1600 px
	bar.add_child(h)
	var logo := Kit.label("MEGA TYCOON", "LabelAmber")
	logo.add_theme_font_size_override("font_size", ThemeBuilder.SIZE_VALUE)
	h.add_child(logo)
	var sep := VSeparator.new()
	sep.add_theme_stylebox_override("separator", _vline())
	h.add_child(sep)
	for e in [["kasse", "geld", "Kasse", "Dein Geld. " + FT.u10_kasse_tip()],
			["einnahmen", "einnahmen", "Einnahmen", "Summe aller Erträge beim Abnehmer"],
			["kosten", "kosten", "Kosten", "Laufender Unterhalt je Spielminute (Fahrzeuge, Lager, Gleise)"],
			["fahrzeuge", "lkw", "Fahrzeuge", "Fahrzeuge im Einsatz"],
			["zeit", "uhr", "Spielzeit", "Spielzeit (Minuten:Sekunden)"]]:
		h.add_child(_hud_chip(e[0], e[1], e[2], e[3]))
		if e[0] == "kasse" and credit.active:
			h.add_child(_credit_chip())
		# U-03 U4: Zeile „Skillpunkt gespart“ raus aus der Kopfleiste (Clipping bei 1600 px), Toast bei M1b (_complete).
	h.add_child(Kit.spacer())
	var seg := Kit.hbox(4)      # U-02b: Label „TEMPO“ entfällt (U-02-Spec Fix 2), Platz für die Skillpunkt-Zeile
	h.add_child(seg)
	for s in [0, 1, 2, 4, 8]:
		var b: Button
		if s == 0:
			b = Kit.button("", "ButtonTempo", "pause", func(): set_speed(s))
			b.tooltip_text = "Pause (Leertaste)"
		else:
			b = Kit.button("%d×" % s, "ButtonTempo", "play" if s == 1 else "tempo", func(): set_speed(s))
			b.tooltip_text = "Tempo %d×" % s
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(44 if s == 0 else 56, 34)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		seg.add_child(b)
		speed_buttons.append([s, b])


## Karten-Beschriftung im Theme (S-11): Poppins etwas leichter (negative Emboldening), cremefarben, dezenter
## dunkler Holz-Saum statt dicker Kontur. Lesbarkeit bleibt über den Saum (hell auf Gras, Wasser, Berg).
func _style_map_labels() -> void:
	var fv := FontVariation.new()
	fv.base_font = ThemeBuilder.font(ThemeBuilder.FONT_BODY)
	fv.variation_embolden = -0.08
	for b in buildings:
		var l: Label3D = b.label
		l.font = fv
		l.modulate = ThemeBuilder.C["cream"]
		l.outline_modulate = Color(ThemeBuilder.C["ink"], 0.92)
		l.outline_size = 7
		l.line_spacing = -4.0
	_update_label_lod(true)


## Label-LOD nach Zoom (Kamera-Zoom, kleiner = näher): 
##   fern  (> 9):  nur Stadtnamen, Industrie-Labels ausgeblendet (weich zwischen Zoom 8 und 10)
##   mittel (3,5-9): Stadt Name + Größe, Industrie nur Name
##   nah   (<= 3,5): voller Text (Bestand, Lizenz)
func _update_label_lod(force := false) -> void:
	var tier := 0 if zoom > 9.0 else (1 if zoom > 3.5 else 2)
	var industry_alpha := clampf((10.0 - zoom) / 2.0, 0.0, 1.0)
	for b in buildings:
		var l: Label3D = b.label
		if b.kind == Building.Kind.CITY:
			l.modulate.a = 1.0
		else:
			l.modulate.a = industry_alpha
			l.visible = industry_alpha > 0.02
		if b.kind == Building.Kind.CITY:
			l.visible = true
	if tier != label_tier or force:
		label_tier = tier
		_refresh_label_text()
	_place_map_labels()          # nach dem Textwechsel, damit die HUD-Prüfung die echte Zeilenzahl sieht


## D-07 BUG-4: Label sitzt unter dem Gebäude (oberer Textrand knapp unter der untersten Fußabdruck-Ecke, Bildschirm-px),
## damit weder Gebäude noch gelber Zielpfeil verdeckt werden; Labels, die ein HUD-Panel (oder die Hinweisleiste) berühren,
## werden ausgeblendet statt unter dem HUD durchzuscheinen/abgeschnitten zu werden.
var _goal_mark_rects: Array[Rect2] = []          # B-6: Zielpfeil-Rechtecke des letzten Label-Durchlaufs


func _place_map_labels() -> void:
	if cam == null or ui_root == null:
		return
	var vp := get_viewport().get_visible_rect().size
	var kscale := vp.y / 900.0 * 560.0       # Bildschirm-px je Label-Einheit = pixel_size * kscale (gemessen bei 900 px Höhe)
	var hud: Array[Rect2] = []
	_collect_hud_rects(ui_root, 0, hud)
	# U-02b: Zielpfeile haben Vorrang vor Beschriftungen (Spec: Überlappung -> niedrigere Priorität ausblenden).
	# Rechteck deckt den ganzen Wipp-Bereich ab (siehe _process), damit das Label nicht im Takt flackert.
	var marks: Array[Rect2] = []
	for mk in goal_markers:
		var ms: float = mk.scale.x
		var mid := Vector3(mk.position.x, mk.get_meta("base_y") + 2.0 * ms, mk.position.z)
		var ext := Vector3(1.3 * ms, 1.3 * ms + 0.6 * ms, 1.3 * ms)
		var mr := Rect2()
		var first := true
		for sx in [-1.0, 1.0]:
			for sy in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					var p3 := mid + Vector3(ext.x * sx, ext.y * sy, ext.z * sz)
					if cam.is_position_behind(p3):
						continue
					var p2 := cam.unproject_position(p3)
					mr = Rect2(p2, Vector2.ZERO) if first else mr.expand(p2)
					first = false
		if not first:
			marks.append(mr.grow(4.0))
	for b in buildings:
		var l: Label3D = b.label
		if not l.visible:
			continue
		var c: Vector3 = b.position
		if cam.is_position_behind(c):
			l.visible = false
			continue
		var pc := cam.unproject_position(c)
		var bottom := pc.y
		if b.custom_cells.is_empty():
			for dx in [0.0, 1.0]:
				for dz in [0.0, 1.0]:
					var corner := Vector3(b.cell.x + b.footprint.x * dx, 0.0, b.cell.y + b.footprint.y * dz)
					if not cam.is_position_behind(corner):
						bottom = maxf(bottom, cam.unproject_position(corner).y)
		else:          # Stadt: nur die bebauten Zellen zählen, nicht das ganze 9x9-Rechteck
			for cc in b.custom_cells:
				var corner := Vector3(cc.x + 0.5, 0.0, cc.y + 1.0)
				if not cam.is_position_behind(corner):
					bottom = maxf(bottom, cam.unproject_position(corner).y)
		var k := l.pixel_size * kscale
		var off := -(bottom - pc.y + 5.0) / k
		var fpx := l.font_size * k
		var lines := l.text.split("\n")
		var wmax := 0
		for ln in lines:
			wmax = maxi(wmax, ln.length())
		var r := Rect2(pc.x - wmax * fpx * 0.29, bottom + 5.0, wmax * fpx * 0.58, lines.size() * fpx * 1.4)
		# U-02b: stößt das Label von oben an eine Leiste unten (Hinweis-/Werkzeugleiste), wird es nach oben
		# verschoben statt ausgeblendet (Haberau im Nahzoom). Max. eine Labelhöhe, sonst wie bisher ausblenden.
		var lift := 0.0
		for h in hud:
			var hg := h.grow(4.0)
			if r.intersects(hg) and hg.position.y > r.position.y:
				lift = maxf(lift, r.end.y - hg.position.y)
		if lift > 0.0 and lift <= r.size.y:
			r.position.y -= lift
			off += lift / k
		if absf(l.offset.y - off) > 0.4:
			l.offset = Vector2(0, off)
		for h in hud:
			if r.intersects(h.grow(4.0)):
				l.visible = false
				break
	_goal_mark_rects = marks
	hide_labels_under_goal_markers()


## B-6: Zielpfeil hat Vorrang. Läuft am Ende von _place_map_labels und noch einmal nach props/label_declutter.gd
## (process_priority 100), weil der Declutter Labels nach unten verschiebt und sie sonst wieder unter den Pfeil geraten.
## Rechteck aus dem aktuellen Label-Offset (oberer Textrand = pc.y - offset.y * k, wie im Declutter).
func hide_labels_under_goal_markers() -> void:
	if cam == null or _goal_mark_rects.is_empty():
		return
	var kscale := get_viewport().get_visible_rect().size.y / 900.0 * 560.0
	for b in buildings:
		var l: Label3D = b.label
		if not l.visible or cam.is_position_behind(b.position):
			continue
		var k := l.pixel_size * kscale
		var pc := cam.unproject_position(b.position)
		var fpx := l.font_size * k
		var lines := l.text.split("\n")
		var wmax := 0
		for ln in lines:
			wmax = maxi(wmax, ln.length())
		var r := Rect2(pc.x - wmax * fpx * 0.29, pc.y - l.offset.y * k, wmax * fpx * 0.58, lines.size() * fpx * 1.4)
		for mr in _goal_mark_rects:
			if r.intersects(mr):
				l.visible = false
				break


func _collect_hud_rects(n: Node, depth: int, out: Array[Rect2]) -> void:
	for c in n.get_children():
		if c is PanelContainer and c.visible and c.size.x > 8.0:
			out.append(c.get_global_rect())
		elif c is Control and c.visible and depth < 2:
			_collect_hud_rects(c, depth + 1, out)


func _label_lod_text(b) -> String:
	var full: String = Kit.txt(_building_label(b))
	if label_tier >= 2:
		return full
	var parts := full.split("\n")
	if b.kind == Building.Kind.CITY:
		return parts[0] if label_tier == 0 else full
	return parts[0]


func _vline() -> StyleBoxLine:
	var l := StyleBoxLine.new()
	l.vertical = true
	l.color = Color(ThemeBuilder.C["cream"], 0.18)
	l.thickness = 2
	l.grow_begin = -8
	l.grow_end = -8
	return l


## F-19: Kredit-Eintrag am Kassenfeld: offener Betrag / Rahmen, [+] aufnehmen, [−] tilgen (je 500 $).
func _credit_chip() -> Control:
	var tip := "Kredit: fester Zins %s %% je Spielminute auf den offenen Betrag, max. %s.\n+ nimmt %s auf, - tilgt %s (Geld muss in der Kasse sein)." % [
		String.num(credit.interest_pm / 10.0, 1).replace(".", ","), money_str(credit.limit_cent), money_str(credit.step_cent), money_str(credit.step_cent)]
	var p := _hud_chip("kredit", "geld", "Kredit", tip)
	var h: HBoxContainer = p.get_child(0)
	hud_vals["kredit"].custom_minimum_size = Vector2(74, 0)          # U-02b: nur offener Betrag, Rahmen als „max.“ im Tooltip (U-02-Spec)
	var plus := Kit.button("+", "ButtonTempo", "", ui_credit_borrow)
	var minus := Kit.button("-", "ButtonTempo", "", ui_credit_repay)
	plus.tooltip_text = "Kredit aufnehmen: +%s" % money_str(credit.step_cent)
	minus.tooltip_text = "Kredit tilgen: -%s" % money_str(credit.step_cent)
	for b in [plus, minus]:
		b.custom_minimum_size = Vector2(30, 30)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(Kit.hbox(4, [plus, minus]))
	credit_buttons = [plus, minus]
	return p


func ui_credit_borrow() -> int:
	if not company_started or bankrupt:
		return 0
	var a: int = credit.borrow(eco, shim.tick_count)
	if a > 0:
		_toast("Kredit aufgenommen: +%s. Offen %s, Zins %s je Spielminute." % [money_str(a), money_str(credit.loan_cent), money_str(credit.interest_per_period())], 3.0)
	elif FT.kredit_gesperrt(self):
		_toast(FT.kredit_ab(self) + ".")       # T-15/U-03: Sperrzeit statt „Rahmen voll“
	else:
		_toast(FT.l12_kredit_voll(self))
	_update_hud(running_cost_per_period)
	return a


func ui_credit_repay() -> int:
	if not company_started or bankrupt:
		return 0
	var a: int = credit.repay(eco, shim.tick_count)
	if a > 0:
		_toast("Kredit getilgt: -%s. Offen %s." % [money_str(a), money_str(credit.loan_cent)], 3.0)
	elif credit.loan_cent > 0:
		_toast(FT.l13_tilgen(self, mini(credit.step_cent, credit.loan_cent) - eco.cash_cent))
	_update_hud(running_cost_per_period)
	return a


func _hud_chip(key: String, icon_name: String, caption: String, tip: String) -> Control:
	var p := Kit.panel("PanelChip")
	p.tooltip_text = tip
	p.mouse_filter = Control.MOUSE_FILTER_PASS
	var h := Kit.hbox(8)
	p.add_child(h)
	h.add_child(Kit.icon(icon_name, 22, ThemeBuilder.C["amber"]))
	var v := Kit.vbox(-2)
	h.add_child(v)
	v.add_child(Kit.label(caption, "LabelHudSmall"))
	var val := Kit.label("–", "LabelHud")
	val.custom_minimum_size = Vector2(96 if key == "kasse" else 74, 0)
	v.add_child(val)
	hud_vals[key] = val
	return p


## Links: Ziele-Karte mit „Nächster Schritt“ und Linien-Karte (inkl. Auflösen, B-01).
func _setup_left_column() -> void:
	var col := Kit.vbox(12)
	col.position = Vector2(14, HUD_H + 14)
	col.custom_minimum_size = Vector2(LEFT_W, 0)
	ui_root.add_child(col)
	ms_panel = Kit.panel("PanelCard")
	ms_panel.visible = false
	col.add_child(ms_panel)
	var v := Kit.vbox(6)
	ms_panel.add_child(v)
	var head := Kit.hbox(8, [Kit.icon("ziele", 22, ThemeBuilder.C["amber_edge"]), Kit.label("Ziele", "LabelValue"), Kit.spacer()])
	ms_count_label = Kit.label("", "LabelMuted")
	head.add_child(ms_count_label)
	v.add_child(head)
	for i in 7:
		var ok := Kit.icon("ok", 16, ThemeBuilder.C["ok_text"])
		var open := Kit.status("none", 14)
		var holder := CenterContainer.new()
		holder.custom_minimum_size = Vector2(18, 18)
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var nxt := Kit.icon("ziel", 16, ThemeBuilder.C["amber_edge"])
		holder.add_child(ok)
		holder.add_child(open)
		holder.add_child(nxt)
		var l := Kit.label("", "", true)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var row := Kit.hbox(8, [holder, l])
		v.add_child(row)
		milestone_rows.append({"row": row, "ok": ok, "open": open, "next": nxt, "label": l})
	var cal := Kit.panel("PanelCallout")
	cal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	next_step_label = Kit.label("", "", true)
	next_step_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cv := Kit.vbox(2, [Kit.hbox(6, [Kit.icon("ziel", 16, ThemeBuilder.C["amber_edge"]), Kit.label("NÄCHSTER SCHRITT", "LabelCaps")]), next_step_label])
	cal.add_child(cv)
	v.add_child(Kit.margin(0, 4, 0, 0))
	v.add_child(cal)

	lines_card = Kit.panel("PanelCard")
	lines_card.visible = false
	col.add_child(lines_card)
	var lv := Kit.vbox(4)
	lines_card.add_child(lv)
	lv.add_child(Kit.hbox(8, [Kit.icon("lkw", 22, ThemeBuilder.C["amber_edge"]), Kit.label("Linien", "LabelValue"), Kit.spacer(),
		Kit.label("Gewinn/min", "LabelMuted")]))
	lines_box = Kit.vbox(2)
	# U-03: Linienliste scrollt (vorher: 8 Zeilen + „… weitere“). Höhe = Inhalt, höchstens bis über die Werkzeugleiste.
	lines_scroll = ScrollContainer.new()
	lines_scroll.name = "LinesScroll"
	lines_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	lines_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	lines_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lines_scroll.add_child(lines_box)
	lv.add_child(lines_scroll)
	lines_scroll.get_v_scroll_bar().value_changed.connect(func(_v): _refresh_lines())
	lines_label = Kit.label("", "LabelMuted", true)
	lv.add_child(lines_label)


## Rechts angedocktes Kontextpanel (A-07): Kopf aus Holz, Infos oben, eine primäre Aktion unten.
func _setup_dock_panel() -> void:
	panel = Kit.panel("PanelDock")
	panel.custom_minimum_size = Vector2(PANEL_W, 0)
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_left = -PANEL_W - 14
	panel.offset_right = -14
	panel.offset_top = HUD_H + 14
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.visible = false
	ui_root.add_child(panel)
	var v := Kit.vbox(0)
	panel.add_child(v)
	var head := Kit.panel("PanelHeader")
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(head)
	var hh := Kit.hbox(12)
	head.add_child(hh)
	var disc := Kit.panel("PanelIconDisc")
	disc.add_theme_stylebox_override("panel", ThemeBuilder.sb(ThemeBuilder.C["amber"], 22, 2, ThemeBuilder.C["amber_edge"], Vector4(7, 7, 7, 7)))
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	disc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel_icon = Kit.icon("fabrik", 26, ThemeBuilder.C["ink"])
	disc.add_child(panel_icon)
	hh.add_child(disc)
	var tv := Kit.vbox(0)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_title = Kit.label("", "LabelWoodTitle")
	panel_title.clip_text = true
	panel_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	panel_sub = Kit.label("", "LabelHudSmall")
	tv.add_child(panel_title)
	tv.add_child(panel_sub)
	hh.add_child(tv)
	var close := Kit.button("", "ButtonClose", "schliessen", func(): close_panel())
	close.tooltip_text = "Schließen (Esc)"
	close.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	hh.add_child(close)

	var body := Kit.margin(18, 14, 18, 18)
	v.add_child(body)
	var bv := Kit.vbox(10)
	body.add_child(bv)
	panel_status_shape = Kit.status("ok", 16)
	panel_status_text = Kit.label("", "LabelBody")
	bv.add_child(Kit.hbox(10, [panel_status_shape, panel_status_text]))
	bv.add_child(HSeparator.new())
	panel_fields = Kit.vbox(8)
	bv.add_child(panel_fields)
	for i in 6:
		var ic := Kit.icon("geld", 18, ThemeBuilder.C["muted"])
		var k := Kit.label("", "LabelMuted")
		k.custom_minimum_size = Vector2(108, 0)
		var val := Kit.label("", "", true)
		val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var row := Kit.hbox(10, [ic, k, val])
		panel_fields.add_child(row)
		panel_field_rows.append({"row": row, "icon": ic, "key": k, "val": val})

	panel_lic = Kit.panel("PanelLicence")
	panel_lic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bv.add_child(panel_lic)
	var lv := Kit.vbox(6)
	panel_lic.add_child(lv)
	panel_lic_head = Kit.label("LIZENZ", "LabelCaps")
	lv.add_child(Kit.hbox(8, [Kit.icon("lizenz", 18, ThemeBuilder.C["amber_edge"]), panel_lic_head]))
	panel_lic_text = Kit.label("", "", true)
	lv.add_child(panel_lic_text)
	panel_lic_bar = ProgressBar.new()
	panel_lic_bar.show_percentage = false
	panel_lic_bar.custom_minimum_size = Vector2(0, 12)
	panel_lic_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lv.add_child(panel_lic_bar)

	panel_why = Kit.panel("PanelCallout")
	panel_why.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_why_text = Kit.label("", "", true)
	panel_why.add_child(Kit.vbox(2, [Kit.hbox(6, [Kit.icon("warnung", 16, ThemeBuilder.C["warn_text"]), Kit.label("WARUM?", "LabelCaps")]), panel_why_text]))
	bv.add_child(panel_why)

	bv.add_child(Kit.margin(0, 2, 0, 0))
	panel_button = Kit.price_button("lizenz", "Lizenz kaufen", "", func(): _on_panel_button())
	bv.add_child(panel_button)
	panel_reason = Kit.label("", "LabelBad", true)
	bv.add_child(panel_reason)
	panel_line_button = Kit.button("Linie ab hier anlegen", "ButtonSecondary", "lkw", func(): _panel_start_line())
	panel_line_button.custom_minimum_size = Vector2(0, 40)
	bv.add_child(panel_line_button)


## Werkzeugleiste unten (Genre: Cities: Skylines/TF2): Icon + Name, Hotkey-Plakette, Preis im Tooltip.
func _setup_toolbar() -> void:
	var dock := Kit.vbox(8)
	dock.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	dock.grow_horizontal = Control.GROW_DIRECTION_BOTH
	dock.grow_vertical = Control.GROW_DIRECTION_BEGIN
	dock.offset_bottom = -14
	dock.alignment = BoxContainer.ALIGNMENT_END
	ui_root.add_child(dock)
	hint_panel = Kit.panel("PanelHint")
	hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hint_label = Kit.label("", "LabelHudSmall")
	hint_label.add_theme_color_override("font_color", ThemeBuilder.C["cream"])
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_panel.add_child(hint_label)
	dock.add_child(hint_panel)
	var bar := Kit.panel("PanelToolbar")
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dock.add_child(bar)
	var h := Kit.hbox(8)
	bar.add_child(h)
	for e in [[Tool.ROAD, "strasse", "Straße", "1", "Straße bauen: %s/Feld (Brücke ×6, Hang ×3)" % money_str(road_cent)],
			[Tool.RAIL, "gleis", "Gleis", "2", "Gleis bauen: %s/Feld" % money_str(rail_cent)],
			[Tool.WAREHOUSE, "lager", "Lager", "3", "Lager setzen: %s, sammelt und verteilt.\n%s" % [money_str(warehouse_cent), FT.b17_lager_hinweis()]],
			[Tool.TRUCK_LINE, "lkw", "Lkw", "4", "Lkw-Linie: %s je Lkw" % money_str(_vehicle_price("truck"))],
			[Tool.TRAIN_LINE, "zug", "Zug", "5", "Zug-Linie: %s je Zug" % money_str(_vehicle_price("train"))],
			[Tool.DEMOLISH, "abriss", "Abriss", "X", "Abriss eigener Straßen/Gleise (50 % zurück)"]]:
		var t: int = e[0]
		var b := Kit.button(e[2], "ButtonTool", e[1], func(): _set_tool(Tool.NONE if tool == t else t))
		b.toggle_mode = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.custom_minimum_size = Vector2(78, 70)
		b.tooltip_text = "[%s] %s" % [e[3], e[4]]
		var bd := Kit.badge(e[3])
		bd.position = Vector2(5, 4)
		b.add_child(bd)
		h.add_child(b)
		tool_buttons.append([t, b])


## Bankrott: kein zentriertes Modal, sondern Banner unter dem HUD (Karte bleibt sichtbar).
func _setup_bankrupt_panel() -> void:
	bankrupt_panel = Kit.panel("PanelBanner")
	bankrupt_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	bankrupt_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bankrupt_panel.offset_top = HUD_H + 70
	bankrupt_panel.custom_minimum_size = Vector2(620, 0)
	bankrupt_panel.visible = false
	ui_root.add_child(bankrupt_panel)
	var v := Kit.vbox(10)
	bankrupt_panel.add_child(v)
	v.add_child(Kit.hbox(10, [Kit.status("bad", 18), Kit.label("Bankrott", "LabelTitle")]))
	bankrupt_label = Kit.label("", "", true)
	bankrupt_label.custom_minimum_size = Vector2(580, 0)
	v.add_child(bankrupt_label)
	var b := Kit.button("Neu starten", "ButtonPrimary", "", func(): get_tree().reload_current_scene())
	b.size_flags_horizontal = Control.SIZE_SHRINK_END
	v.add_child(b)


func _refresh_tool_buttons() -> void:
	for e in tool_buttons:
		e[1].set_pressed_no_signal(e[0] == tool)
		e[1].disabled = not company_started or bankrupt


static func money_str(cent: int) -> String:
	var neg := cent < 0
	var d := absi(cent) / 100
	var s := str(d)
	var out := ""
	while s.length() > 3:
		out = "." + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if neg and d > 0 else "") + s + out + " $"      # B-xx S7: nie „-0 $“ (Bankrott bei -0,xx $)


## B-xx (S7): Kasse im Bankrott-Overlay. Unter 1 $ im Minus mit Cent („-0,37 $“), sonst wie money_str; so steht dort
## nie „-0 $“ und nie „0 $“ neben „Ein Konto unter 0 $ ist das Ende“.
static func bankrupt_cash_str(cent: int) -> String:
	if cent < 0 and cent > -100:
		return "-0,%02d $" % (-cent)
	return money_str(cent)


func time_str(ticks: int) -> String:
	var sec := ticks * tick_ms / 1000
	return "%d:%02d" % [sec / 60, sec % 60]


func _toast(text: String, seconds := 4.0) -> void:
	toast_label.text = Kit.txt(text)
	# lange Meldungen umbrechen, kurze einzeilig (Breite nach Schrift gemessen)
	var f: Font = toast_label.get_theme_font("font")
	var w := f.get_string_size(toast_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, toast_label.get_theme_font_size("font_size")).x if f else 0.0
	if w > 720.0:
		toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		toast_label.custom_minimum_size = Vector2(720, 0)
	else:
		toast_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		toast_label.custom_minimum_size = Vector2.ZERO
	_fit_toast()
	_fit_toast.call_deferred()      # F-20: nach dem Umbruch neu messen (erste Messung nimmt die Höhe aus der alten Breite)
	toast_time = seconds
	if toast_panel and toast_panel.is_inside_tree() and not toast_panel.visible:
		toast_panel.visible = true
		UiFx.slide_in(toast_panel, Vector2(0, -16))


func _fit_toast() -> void:
	var tsz := toast_panel.get_combined_minimum_size()
	UiFx.set_rest(toast_panel, -tsz.x * 0.5, HUD_H + 14, tsz.x * 0.5, HUD_H + 14 + tsz.y)


func set_speed(s: int) -> void:
	if not company_started or bankrupt:
		s = 0
	if s == 8 and not eco.speed_steps(fleet_size()).has(8):
		_toast(FT.l14_tempo8(eco.MAX_VEHICLES_AT_8X))
		s = 4
	speed = s
	_refresh_speed_buttons()


func _refresh_speed_buttons() -> void:
	for e in speed_buttons:
		e[1].set_pressed_no_signal(e[0] == speed)


# ---------------------------------------------------------------- Start, Lizenz, Panel

## F-20 Testeinstieg / Kurzweg: HQ in einer Stadt gründen (Platzierungsmodus, hq_placement.gd).
func place_hq(city_id: String) -> bool:
	return hq.place(city_id)


func licence_quote(b) -> Dictionary:
	if b == null or b.site < 0 or not b.is_industry():
		return {"ok": false, "fehler": "keine_lizenzierbare_industrie"}
	return eco.licence_quote(b.site)


## Knopf „Lizenz kaufen“: 1 Klick = 1 Aufruf von economy.buy_licence.
func ui_buy_licence(b) -> bool:
	var q := licence_quote(b)
	if not q.get("ok", false):
		_toast(FT.l10_keine_lizenz_noetig())       # U-03 L10: vorher stumm
		return false
	var r: Dictionary = eco.buy_licence(b.site)
	if not r["ok"]:
		match r["fehler"]:
			"schon_lizenziert":
				_toast(FT.l7_schon(b.display_name))
			"guthaben_reicht_nicht":
				_toast(FT.l8_lizenz_geld(self, q["zu_zahlen_cent"]))
			_:
				_toast(FT.l9_lizenz_sonst(str(r["fehler"])))
		return false
	b.licence_marker.visible = true
	_toast("Lizenz %s: %s, gilt %s Spielzeit und verlängert sich automatisch." % [b.display_name,
		"gratis" if r["bezahlt_cent"] == 0 else money_str(r["bezahlt_cent"]), time_str(eco.lic_duration)], 6.0)
	_refresh_panel()
	_check_milestones()
	return true


func open_panel(b) -> void:
	var was_open: bool = panel.visible and selected != null
	selected = b
	panel.visible = true
	_refresh_panel()
	if not was_open:
		UiFx.slide_in(panel, Vector2(PANEL_W * 0.5, 0))


func close_panel() -> void:
	selected = null
	if panel.visible:
		if panel.is_inside_tree() and is_inside_tree():
			UiFx.slide_out(panel, Vector2(PANEL_W * 0.5, 0))
		else:
			panel.visible = false


## Primärknopf: ohne Lizenz = Lizenz kaufen; mit Lizenz = Linie ab hier anlegen (eine Primäraktion je Panel).
func _on_panel_button() -> void:
	if selected == null:
		return
	var q := licence_quote(selected)
	if q.get("ok", false) and not q["aktiv"]:
		ui_buy_licence(selected)
	else:
		_panel_start_line()


func _panel_start_line() -> void:
	if selected == null or not selected.provides():
		return
	var b = selected
	close_panel()
	_set_tool(Tool.TRUCK_LINE)
	if b.kind == Building.Kind.WAREHOUSE or eco.licence_valid(b.site):
		line_src = b


func _goods_txt(arr: Array) -> String:
	var out := []
	for g in arr:
		out.append(good_names.get(g, g))
	return ", ".join(out)


## Linien, die an b starten (out) bzw. enden (in): [[key, Array[Vehicle]], ...]
func _lines_at(b, outgoing: bool) -> Array:
	var out := []
	for key in line_order:
		var list: Array = line_groups[key]
		var v = list[0]
		if (v.src == b) if outgoing else (v.dst == b):
			out.append([key, list])
	return out


func _line_profit(list: Array) -> float:
	var p := 0.0
	for w in list:
		p += w.profit_per_minute(month_ticks)
	return p


## Ertragsziel aus economy (Industrie- oder Stadt-ID) als Anzeigename.
func _target_name(id: String) -> String:
	if by_id.has(id):
		return by_id[id].display_name
	if IND_NAMES.has(id):
		return IND_NAMES[id]
	return id.capitalize()


func _set_fields(rows: Array) -> void:
	for i in panel_field_rows.size():
		var r: Dictionary = panel_field_rows[i]
		r["row"].visible = i < rows.size()
		if i >= rows.size():
			continue
		var e: Array = rows[i]
		r["icon"].texture = Kit.icon_tex(e[0])
		r["key"].text = Kit.txt(e[1])
		r["val"].text = Kit.txt(e[2])
		r["val"].add_theme_color_override("font_color", e[3] if e.size() > 3 else ThemeBuilder.C["ink"])


var _pv: Dictionary = {}

func _set_primary(icon_name: String, l1: String, l2: String, disabled: bool) -> void:
	if _pv.is_empty():
		panel_button.visible = true
	else:
		_pv[panel_button] = true
	Kit.set_price_button(panel_button, icon_name, l1, l2, disabled)


func _set_status(kind: String, text: String) -> void:
	panel_status_shape.kind = kind
	panel_status_text.text = Kit.txt(text)


## A-07 Feldliste (max. 8): 1 Name/Stufe (Kopf), 2 Status, 3 Produktion, 4 Bedarf/Zufluss, 5 Lieferziele,
## 6 Lizenz (Block mit Restzeit-Balken), 7 Ertrag/min, 8 Warum? (nur bei ▲/■). Kein Firmenkauf (R2).
func _refresh_panel() -> void:
	if selected == null or not panel.visible:
		return
	var b = selected
	panel_title.text = Kit.txt(b.display_name).to_upper()
	var tf: Font = panel_title.get_theme_font("font")
	var big := tf == null or tf.get_string_size(panel_title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, ThemeBuilder.SIZE_TITLE).x <= PANEL_W - 130
	panel_title.add_theme_font_size_override("font_size", ThemeBuilder.SIZE_TITLE if big else ThemeBuilder.SIZE_VALUE)
	# BUG-1 (D-07): Sichtbarkeit erst am Ende setzen, sonst verschluckt der 0,25-s-Refresh gehaltene Klicks.
	_pv = {panel_button: false, panel_reason: false, panel_line_button: false, panel_lic: false, panel_why: false}
	var fields: Array = []
	var why := ""
	var C: Dictionary = ThemeBuilder.C
	match b.kind:
		Building.Kind.CITY:
			panel_icon.texture = Kit.icon_tex("stadt")
			var hq: bool = b == hq_city
			panel_sub.text = Kit.txt("%s · %d Einwohner%s" % [STAGE_NAMES.get(b.city_stage, b.city_stage), b.city_pop, " · dein HQ" if hq else ""])
			var basket: Array = eco.basket.get(b.city_stage, [])
			var dem: int = eco.city_demand(b.site)
			var sat: Dictionary = eco.s_sat[b.site] if eco.s_sat_period[b.site] == shim.tick_count / periode_ticks else {}
			var got := 0
			for cat in basket:
				got += int(sat.get(cat, 0))
			if got == 0:
				_set_status("warn", "Diese Minute noch nicht beliefert")
			else:
				_set_status("ok", "Wird beliefert")
			fields.append(["stadt", "Rolle", "Kunde: bezahlt Lieferungen, nicht kaufbar"])
			for cat in basket.slice(0, 3):
				var n := int(sat.get(cat, 0))
				fields.append(["fabrik", str(cat).capitalize(), "%d / %d E diese Minute%s" % [n, dem, " (Preis sinkt)" if n >= dem and dem > 0 else ""]])
			var ins := _lines_at(b, false)
			fields.append(["lkw", "Lieferanten", "keine" if ins.is_empty() else ", ".join(ins.map(func(e): return e[1][0].src.display_name))])
		Building.Kind.WAREHOUSE:
			panel_icon.texture = Kit.icon_tex("lager")
			panel_sub.text = "Eigenes Lager"
			_set_status("ok" if shim.st_stock[b.station] < eco.warehouse_cap else "warn", "Bestand %d / %d" % [shim.st_stock[b.station], eco.warehouse_cap])
			fields.append(["lager", "Funktion", "nimmt alles an, gibt alles ab"])
			fields.append(["geld", "Ertrag", "0 $ – Geld gibt es erst beim Endabnehmer"])
			fields.append(["kosten", "Unterhalt", "%s/min" % money_str(warehouse_upkeep)])
			_pv[panel_line_button] = true
		Building.Kind.INERT:
			panel_icon.texture = Kit.icon_tex("fabrik")
			panel_sub.text = "Kulisse"
			_set_status("none", "Im Slice kein Handel (L-10)")
		_:
			if eco.s_raw[b.site] == 1:
				eco._sync_raw(shim, b.site)
			var lic: bool = eco.licence_valid(b.site)
			var outs := _lines_at(b, true)
			var rate: int = eco.s_rate[b.site] * month_ticks / periode_ticks
			if b.kind == Building.Kind.PRODUCER:
				panel_icon.texture = Kit.icon_tex("farm" if b.out_good == "getreide" else "mine")
				panel_sub.text = "Rohstoff · Stufe 1"
				fields.append(["fabrik", "Produktion", "%d E/min %s" % [rate, good_names.get(b.out_good, b.out_good)]])
				fields.append(["lager", "Lager", "%d E bereit" % shim.st_stock[b.station]])
			elif b.kind == Building.Kind.PROCESSOR:
				panel_icon.texture = Kit.icon_tex("fabrik")
				panel_sub.text = "Verarbeiter · Stufe 1"
				var buf: Dictionary = eco.s_inbuf[b.site]
				var ins := []
				var n_in := 0
				for gi in buf:
					ins.append("%s %d" % [good_names.get(eco.g_ids[gi], ""), buf[gi]])
					n_in += buf[gi]
				fields.append(["fabrik", "Produktion", "%s · Ausgang %d" % [good_names.get(b.out_good, b.out_good), shim.st_stock[b.station]]])
				fields.append(["kosten", "Bedarf", "%s · Eingang %d" % [_goods_txt(b.in_goods), n_in]])
				if lic and n_in == 0 and shim.st_stock[b.station] == 0 and _lines_at(b, false).is_empty():
					why = "Kein %s im Eingang. Lege eine Linie von einer Quelle hierher." % _goods_txt(b.in_goods)
			else:
				panel_icon.texture = Kit.icon_tex("fabrik")
				panel_sub.text = "Abnehmer"
				fields.append(["kosten", "Nimmt an", "%s, bezahlt die Lieferung" % _goods_txt(b.in_goods)])
			var q := licence_quote(b)
			if not q.get("ok", false):
				_set_status("ok", "Nimmt Ware an · keine Lizenz nötig")
			else:
				fields.append(["lkw", "Lieferziele", "noch keine Linie" if outs.is_empty() else ", ".join(outs.map(func(e): return "%s (%s)" % [e[1][0].dst.display_name, dist_str(e[1][0].distance)]))])
				var prof := 0.0
				for e in outs:
					prof += _line_profit(e[1])
				fields.append(["geld", "Ertrag/min", "–" if outs.is_empty() else "%+d $/min" % int(prof), C["ok_text"] if prof > 0 else (C["bad_text"] if prof < 0 else C["ink"])])
				_pv[panel_lic] = true
				if q["aktiv"]:
					var rest: int = eco.s_lic_until[b.site] - shim.tick_count
					panel_lic_head.text = "LIZENZ AKTIV"
					panel_lic_text.text = Kit.txt("Lizenz aktiv – noch %s · verlängert sich automatisch" % time_str(rest))
					panel_lic_bar.visible = true
					panel_lic_bar.max_value = float(q["laufzeit_ticks"])
					panel_lic_bar.value = float(rest)
					panel_lic_bar.theme_type_variation = "ProgressWarn" if rest < q["laufzeit_ticks"] / 6 else ""
					if outs.is_empty():
						_set_status("warn", "Lizenz aktiv · noch keine Linie")
						why = "Hier lädt noch niemand. Lege eine Lkw-Linie zu einem Abnehmer an."
					elif why != "":
						_set_status("warn", "Lizenz aktiv · Eingang leer")
					else:
						_set_status("ok", "Läuft · %d Linie%s" % [outs.size(), "" if outs.size() == 1 else "n"])
					_set_primary("lkw", "Linie ab hier anlegen", "Lkw %s" % (money_str(_vehicle_price("truck")) if free_trucks_left == 0 else "gratis (Startpaket)"), false)
					panel_button.tooltip_text = "Startet das Lkw-Werkzeug mit %s als Quelle" % b.display_name
				else:
					var d := absi(int(Vector2(b.anchor()).distance_to(Vector2(eco.hq_x / feld_mm, eco.hq_y / feld_mm))))
					var near: bool = d <= eco.hq_radius_felder
					panel_lic_head.text = "LIZENZ"
					panel_lic_text.text = Kit.txt("Leihen für %s Spielzeit, verlängert sich automatisch. %s" % [
						time_str(q["laufzeit_ticks"]), "Im HQ-Radius −30 %." if near else "Außerhalb des HQ-Radius: teurer."])
					panel_lic_bar.visible = false
					_set_status("bad", "Ohne Lizenz · Laden gesperrt")
					var price := "gratis" if q["gratis"] else money_str(q["kosten_cent"])
					_set_primary("lizenz", "Lizenz kaufen · %s" % price, FT.u1_ertrag(self, q["ertrag_pro_monat_cent"]), not q["kaufbar"])
					panel_button.tooltip_text = Kit.txt("Ertrag geschätzt bis %s, %s Luftlinie, volle Frische, ohne Sättigung.%s" % [
						_target_name(str(q["ertrag_ziel_id"])), dist_str(int(q["ertrag_distanz_felder"])),
						"\n1. Lizenz gratis (sonst %s)." % money_str(q["kosten_cent"]) if q["gratis"] else ""])
					if not q["kaufbar"]:
						var miss: int = q["zu_zahlen_cent"] - eco.cash_cent
						_pv[panel_reason] = true
						panel_reason.text = FT.l8_panel(self, miss)
						panel_button.tooltip_text = panel_reason.text
	_set_fields(fields)
	_pv[panel_why] = why != ""
	for n in _pv:
		if n.visible != _pv[n]:
			n.visible = _pv[n]
	_pv = {}
	panel_why_text.text = Kit.txt(why)
	var tw: Tween = panel.get_meta("slide_tw") if panel.has_meta("slide_tw") else null
	if tw == null or not tw.is_running():
		panel.reset_size()


# ---------------------------------------------------------------- Ziele / Meilensteine

## Ziele aus der Startkette der HQ-Stadt (hq_placement.start_targets: src, proc, m3_from, m3_to, m3_text).
func _init_milestones(A: Dictionary) -> void:
	var src: String = by_id[A["src"]].display_name
	var proc: String = by_id[A["proc"]].display_name
	# B-xx (S7): Ziele 1–3 nennen den TYP („eine Getreidefarm“) und haken mit jedem Objekt dieses Typs ab; der Pfeil
	# zeigt die nächste Empfehlung (src/proc). Objektgenau würde Spieler sperren, die auf eine andere Farm ausweichen
	# (Aylin: Farm 2 nur über Fluss-Diagonale erreichbar), und „jede erste Linie“ machte den Kohlberg-Text falsch.
	ms_src_typ = by_id[A["src"]].typ if by_id[A["src"]].kind == Building.Kind.PRODUCER else ""
	ms_proc_typ = by_id[A["proc"]].typ if by_id[A["proc"]].is_industry() else ""
	var st: String = IND_NAMES.get(ms_src_typ, src)
	var pt: String = IND_NAMES.get(ms_proc_typ, proc)
	var alt := " Jede andere %s zählt auch." % st if ms_src_typ != "" and _typ_count(ms_src_typ) > 1 else ""
	milestones = [
		{"text": "Firma gegründet (HQ %s)" % hq_city.display_name, "done": true, "hint": "", "t": []},
		{"text": "Lizenz für %s %s kaufen" % [_article_acc(ms_src_typ), st] if ms_src_typ != "" else "Lizenz für %s kaufen" % src,
			"done": false, "t": [A["src"]],
			"hint": "Am nächsten: %s (gelber Pfeil). Klick darauf, dann im Panel auf „Lizenz kaufen“.%s" % [src, alt]},
		{"text": "Straße %s → %s bauen" % [st, pt], "done": false, "t": [A["src"], A["proc"]],
			"hint": "Taste [1] Straße: Maustaste auf %s drücken, bis %s ziehen, loslassen. Wasser nur gerade queren (Brücke)." % [src, proc]},
		{"text": "Lkw-Linie %s → %s" % [st, pt], "done": false, "t": [A["src"], A["proc"]],
			"hint": "Taste [4] Lkw-Linie: erst %s, dann %s anklicken." % [src, proc]},
		{"text": "Erste Lieferung mit Ertrag", "done": false, "t": [A["proc"]],
			"hint": "Der Lkw lädt und fährt los. Schneller: Tempo 2× oder 4× (Tempo-Knöpfe: oben rechts)."},
		{"text": "3 Lieferungen mit Ertrag", "done": false, "t": [A["proc"]],
			"hint": "Mehr Lkw: dieselbe Linie mit [4] noch einmal setzen. Gewinn je Linie: Liste links, unter Linien."},
		{"text": "Endprodukt an einen Abnehmer (M3)", "done": false, "t": [A["m3_from"], A["m3_to"]], "hint": A["m3_text"]},
	]
	_refresh_milestones()


var ms_src_typ := ""     # B-xx S7: Typ der Startquelle (Ziele 1–3), "" = jeder
var ms_proc_typ := ""


func _typ_ok(b, typ: String) -> bool:
	return typ == "" or b.typ == typ


func _typ_count(typ: String) -> int:
	var n := 0
	for b in buildings:
		if b.typ == typ:
			n += 1
	return n


## Unbestimmter Artikel im Akkusativ je Industrietyp („Lizenz für eine Getreidefarm / ein Kraftwerk / einen Holzfäller“).
static func _article_acc(typ: String) -> String:
	match typ:
		"kraftwerk", "stahlwerk":
			return "ein"
		"holzfaeller":
			return "einen"
	return "eine"


func _complete(i: int) -> void:
	if i >= milestones.size() or milestones[i]["done"]:
		return
	milestones[i]["done"] = true
	_refresh_milestones()
	match i:
		1:
			_toast(FT.u4_skillpunkt(), 5.0)      # U-03 U4: M1b (erste Lizenz) = 1 Skillpunkt, statt Zeile in der Kopfleiste
		4:
			_toast("Erste Lieferung! Bezahlt wird beim Abnehmer, nach Luftlinie ab Herkunft.", 6.0)
		5:
			_toast("Drei Lieferungen mit Ertrag – deine erste Lieferkette läuft.", 6.0)
		6:
			_toast("Endprodukt beim Abnehmer angekommen (M3).", 6.0)


func _check_milestones() -> void:
	if milestones.is_empty():
		return
	if not milestones[1]["done"]:
		for b in buildings:
			if b.kind == Building.Kind.PRODUCER and _typ_ok(b, ms_src_typ) and eco.licence_valid(b.site):
				_complete(1)
				break
	if not milestones[2]["done"] and network_dirty:
		network_dirty = false
		for b in buildings:
			if b.kind == Building.Kind.PRODUCER and _typ_ok(b, ms_src_typ) and eco.licence_valid(b.site):
				for t in buildings:
					if t.is_industry() and _typ_ok(t, ms_proc_typ) and t.in_goods.has(b.out_good) and not astar_road.get_id_path(b.anchor(), t.anchor()).is_empty():
						_complete(2)
	if not milestones[3]["done"] and lines_dirty:
		lines_dirty = false
		for v in vehicles:
			if v.src != null and v.src.kind == Building.Kind.PRODUCER and v.dst.is_industry() and _typ_ok(v.src, ms_src_typ) and _typ_ok(v.dst, ms_proc_typ):
				_complete(3)
	if deliveries_profit >= 3:
		_complete(5)


func _refresh_milestones() -> void:
	var next := -1
	var done := 0
	for i in milestone_rows.size():
		var r: Dictionary = milestone_rows[i]
		r["row"].visible = i < milestones.size()
		if i >= milestones.size():
			continue
		var m: Dictionary = milestones[i]
		var l: Label = r["label"]
		l.text = Kit.txt(m["text"])
		r["ok"].visible = m["done"]
		r["open"].visible = not m["done"]
		r["next"].visible = false
		if m["done"]:
			done += 1
			l.theme_type_variation = "LabelMuted"
		elif next < 0:
			next = i
			l.theme_type_variation = "LabelNext"
			r["open"].visible = false
			r["next"].visible = true
		else:
			l.theme_type_variation = ""
	ms_count_label.text = "%d / %d" % [done, milestones.size()]
	if next >= 0:
		next_step_label.text = Kit.txt(milestones[next]["hint"])
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
	if tool_buttons.size() > 0:
		_refresh_tool_buttons()


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
	if hq.handle_input(event):
		return
	var mb := event as InputEventMouseButton
	if mb and mb.pressed:
		match mb.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				zoom = clampf(zoom * 0.9, zoom_min, zoom_max)
				_apply_zoom()
			MOUSE_BUTTON_WHEEL_DOWN:
				zoom = clampf(zoom * 1.1, zoom_min, zoom_max)
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
				_toast(FT.l5_leeres_feld(), 2.0)      # U-03 L5: vorher stumm
				return
			if line_src == null:
				if not b.provides():
					_toast(FT.l2_liefert_nichts(b.display_name))
				elif b.kind != Building.Kind.WAREHOUSE and not eco.licence_valid(b.site):
					_toast(FT.l3_keine_lizenz(b.display_name))
					open_panel(b)
				else:
					line_src = b
			elif b == line_src:
				line_src = null
			else:
				if not _accepts_from(line_src, b):
					_toast(FT.l4_nimmt_nicht(b.display_name, _src_goods_txt(line_src)))
				else:
					create_line(line_src, b, "train" if tool == Tool.TRAIN_LINE else "truck")
					line_src = null
		_:
			if b != null:
				open_panel(b)
			elif panel.visible:
				close_panel()      # A-07: Klick daneben schließt


## U-03 L4: Ware der Quelle (Lager: „diese Ware“, es gibt alles ab).
func _src_goods_txt(src) -> String:
	if src.kind == Building.Kind.WAREHOUSE or src.out_good == "":
		return "diese Ware"
	return good_names.get(src.out_good, src.out_good)


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


## Geländefaktor in Promille (1000 = Flachland), Werte aus bau_kosten.
func _terrain_factor(c: Vector2i) -> int:
	match terrain_at(c):
		Terrain.WATER:
			return water_factor_pm
		Terrain.MOUNTAIN:
			return mountain_factor_pm
	return 1000


## Preis eines neuen Feldes in Cent: JSON-Straßenpreis × Gelände-Faktor (kein Außerhalb-Aufschlag: steht
## nicht im JSON; der Einfluss wirkt im Slice über den Lizenzpreis).
func field_cost(c: Vector2i, rail: bool) -> int:
	return ((rail_cent if rail else road_cent) * _terrain_factor(c)) / 1000


func _in_grid(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < GRID and c.y < GRID


## Z-01 (S7): Endet oder beginnt der Drag auf einer Stadtfläche, dockt die Strecke am Stadtrand an (beide
## Richtungen gleich): Weg vom Außenende zur Stadt, abgeschnitten am ersten Stadtfeld. Ist das eine Stadtstraße,
## endet die Straße dort (Gleis: ein Feld davor). Liegt dort ein Haus, sucht _city_dock ein Randfeld neben einer
## Stadtstraße. plan["dock_street"] = Anschlusspunkt (Vorschau-Marker), plan["dock_city"] = Stadtname.
func plan_track(a: Vector2i, b: Vector2i, rail: bool) -> Dictionary:
	var ca = _city_of(a)
	var cb = _city_of(b)
	if (ca == null and cb == null) or ca == cb:
		return _plan_cells(a, b, _drag_path(a, b), rail)
	if ca != null and cb != null:
		# Stadt zu Stadt: erst b vom Zentrum von a aus andocken, dann a vom Andockfeld von b aus.
		var pb := _city_dock(ca.anchor(), b, cb, rail)
		var pa := _city_dock(pb["end"], a, ca, rail)
		var cells2: Array = pa["cells"].duplicate()
		cells2.reverse()
		var tail := _drag_path(pa["end"], pb["end"])
		for i in range(1, tail.size()):
			cells2.append(tail[i])
		var p2 := _plan_cells(a, b, cells2, rail)
		p2["dock_street"] = pb["street"]
		p2["dock_city"] = cb.display_name
		return p2
	var city = cb if cb != null else ca
	var outer := a if cb != null else b
	var d := _city_dock(outer, b if cb != null else a, city, rail)
	var cells: Array = d["cells"]
	if ca != null:
		cells = cells.duplicate()
		cells.reverse()
	var p := _plan_cells(a, b, cells, rail)
	p["dock_street"] = d["street"]
	p["dock_city"] = city.display_name
	_dock_reason(p, d, city)
	return p


## U-03 S2: Kein Randfeld der Stadt ist von hier baubar (Wasser, Berg, zu steil) -> Ursache "nicht anschließbar"
## statt der Meldung des zufällig gewählten Fehlversuchs. Geld- und Gebäude-Gründe bleiben stehen (sind die echte Ursache).
func _dock_reason(p: Dictionary, d: Dictionary, city) -> void:
	if p["ok"] or d.get("ok", true):
		return
	var r: String = p["reason"]
	if r.begins_with("Es fehlen") or r.contains("steht im Weg") or r.contains("liegt im Weg"):
		return
	p["reason"] = FT.s2_nicht_anschliessbar(city.display_name)
	for it in p["items"]:
		if it["state"] == "bad":
			it["reason"] = p["reason"]


func _l_path(a: Vector2i, b: Vector2i, horiz_first: bool) -> Array:
	var out := [a]
	var c := a
	for leg in 2:
		if (leg == 0) == horiz_first:
			while c.x != b.x:
				c.x += signi(b.x - c.x)
				out.append(c)
		else:
			while c.y != b.y:
				c.y += signi(b.y - c.y)
				out.append(c)
	return out


func _city_of(c: Vector2i):
	var bb = cell_to_building.get(c)
	return bb if bb != null and bb.kind == Building.Kind.CITY else null


## Weg vom Außenpunkt `outer` zur Stadt `city` (gezielt auf `target`). Ergebnis: cells (outer … Ende),
## end (letztes Feld), street (Stadtstraße, an der die Strecke anschließt).
func _city_dock(outer: Vector2i, target: Vector2i, city, rail: bool) -> Dictionary:
	var raw := _drag_path(outer, target)
	var k := 0
	while k < raw.size() and cell_to_building.get(raw[k]) != city:
		k += 1
	var trunc := {}
	var reach := _city_reach(city)
	if k < raw.size() and reach.has(raw[k]) and (not rail or k > 0):
		var endk := k - 1 if rail else k
		trunc = {"cells": raw.slice(0, endk + 1), "end": raw[endk], "street": raw[k]}
		if _plan_cells(outer, trunc["end"], trunc["cells"], rail, false)["ok"]:
			trunc["ok"] = true
			return trunc
	# Randfelder: freies Feld außerhalb, 4-Nachbar einer mit dem Zentrum verbundenen Stadtstraße. Nach Abstand
	# sortiert; das erste baubare gewinnt. Höchstens PLAN_BUDGET Vollplanungen je Aufruf (Vorschau läuft je Mausfeld).
	var cand: Array = []
	for s in city.cells():
		if not reach.has(s):
			continue
		for dv in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = s + dv
			if not _in_grid(n) or cell_to_building.has(n) or terrain_at(n) == Terrain.WATER:
				continue
			cand.append([absi(n.x - outer.x) + absi(n.y - outer.y), n, s])
	cand.sort_custom(func(x, y): return x[0] < y[0] or (x[0] == y[0] and (x[1].x < y[1].x or (x[1].x == y[1].x and x[1].y < y[1].y))))
	var best := {}
	var best_ok := false
	var budget := 24
	for e in cand:
		if budget <= 0:
			break
		var n: Vector2i = e[1]
		# Form wie beim Drag, sonst als L (erst waagrecht bzw. erst senkrecht): so quert eine Brücke gerade.
		for shape in 3:
			var cells: Array = _drag_path(outer, n) if shape == 0 else _l_path(outer, n, shape == 1)
			var clean := true
			for c in cells:
				if cell_to_building.get(c) == city:
					clean = false
					break
			if not clean:
				continue
			budget -= 1
			if best.is_empty():
				best = {"cells": cells, "end": n, "street": e[2]}
			if _plan_cells(outer, n, cells, rail, false)["ok"]:
				best = {"cells": cells, "end": n, "street": e[2]}
				best_ok = true
				break
		if best_ok:
			break
	var best_key := 0.0 if best_ok else 100000.0
	if best.is_empty() or (best_key >= 100000.0 and not trunc.is_empty()):
		if not trunc.is_empty():
			trunc["ok"] = false
			return trunc
		return {"cells": raw, "end": target, "street": Vector2i(-1, -1), "ok": false}
	best["ok"] = best_ok
	return best


## Stadtstraßen, die über Stadtstraßen mit dem Stadtzentrum (anchor, Ziel der Linien) verbunden sind. Ein Fluss
## kann eine Stadt teilen (Mittelfurt): Andocken am abgetrennten Teil verbände nicht. Statisch, daher gecacht.
var _reach_cache := {}

func _city_reach(city) -> Dictionary:
	if _reach_cache.has(city):
		return _reach_cache[city]
	var seen := {}
	var a: Vector2i = city.anchor()
	if city_streets.has(a):
		seen[a] = true
		var q: Array = [a]
		while not q.is_empty():
			var p: Vector2i = q.pop_back()
			for dv in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var n: Vector2i = p + dv
				if city_streets.has(n) and not seen.has(n) and cell_to_building.get(n) == city:
					seen[n] = true
					q.append(n)
	_reach_cache[city] = seen
	return seen


func _plan_cells(a: Vector2i, b: Vector2i, cells: Array, rail: bool, check_money := true) -> Dictionary:
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
			it["reason"] = FT.b7_aussen()
		elif rail and city_streets.has(c) and not net.has(c):
			# B-02: Gleis auf Stadtstraße ist nicht erlaubt (vorher: 0 $ angezeigt, aber nicht gebaut). Grund im Ghost.
			it["state"] = "bad"
			it["reason"] = FT.b6_gleis_stadt()
		elif net.has(c) or city_streets.has(c):
			it["state"] = "exist"
		elif cell_to_building.has(c):
			var bb = cell_to_building[c]
			if bb.kind != Building.Kind.CITY and (i < head or i >= n - tail):
				it["state"] = "exist"
			elif bb.kind == Building.Kind.CITY:
				it["state"] = "bad"
				it["reason"] = FT.b4_stadt(bb.display_name)
			else:
				it["state"] = "bad"
				it["reason"] = FT.b4_gebaeude(bb.display_name)
		else:
			it["cost"] = field_cost(c, rail)
		items.append(it)
	_check_bridges(cells, items)
	var hang := {}
	if world_s7 != null:
		hang = BauS7.apply(self, cells, items)     # W-04: Preis × Hangfaktor, B11 zu steil (Slice: unberührt)
	var total := 0
	var new_count := 0
	var reason := ""
	for it in items:
		if it["state"] == "bad" and reason == "":
			reason = it["reason"]
		if it["state"] == "new":
			total += it["cost"]
			new_count += 1
	if check_money and reason == "" and total > eco.cash_cent:
		reason = FT.b8_geld(self, total)
		for it in items:
			if it["state"] == "new":
				it["state"] = "bad"
				it["reason"] = reason
	return {"a": a, "b": b, "rail": rail, "cells": cells, "items": items, "total": total,
		"ok": reason == "", "reason": reason, "new_count": new_count, "hang": hang,
		"hint": FT.b9_vorhanden() if reason == "" and new_count == 0 else ""}


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
			why = FT.b3_brueckenkopf()
		elif e - s + 1 > BRIDGE_MAX:
			why = FT.b2_bruecke_zu_lang(self, e - s + 1)
		else:
			var p: Vector2i = cells[s - 1]
			var q: Vector2i = cells[e + 1]
			var straight := true
			for k in range(s - 1, e + 2):
				var c: Vector2i = cells[k]
				if not (c.x == p.x and p.x == q.x) and not (c.y == p.y and p.y == q.y):
					straight = false
			if not straight:
				why = FT.b1_bruecke_diagonal()      # U-03 B1
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
		if road_tiles != null:     # W-04: S7 zeigt Kacheln (road_tiles), kein Quader
			pass
		elif rail:         # S7 B: gebündelt (render_batch), Maße/Material/Schatten wie zuvor der MeshInstance3D je Feld
			render_batch.add_box(["rail", c], Vector3(c.x + 0.5, 0.09 + lift, c.y + 0.5), Vector3(0.5, 0.1, 0.5),
				mat_bridge if bridge else mat_rail, false)
		else:
			render_batch.add_box(["road", c], Vector3(c.x + 0.5, 0.04 + lift, c.y + 0.5), Vector3(0.96, 0.08, 0.96),
				mat_bridge if bridge else mat_road, false)
		net[c] = true
		paid[c] = it["cost"]
		astar.set_point_solid(c, false)
	charge(p["total"])
	_clear_preview()
	network_dirty = true
	cost_dirty = true
	if road_tiles != null:
		road_tiles.note_path(p["cells"], rail)
		road_tiles.refresh()
	if p["total"] > 0:
		var dock: String = " · angeschlossen am Stadtrand %s" % p["dock_city"] if p.get("dock_city", "") != "" else ""
		_toast("%s gebaut: %s, %s%s" % ["Gleis" if rail else "Straße", dist_str(p["new_count"]), money_str(p["total"]), dock], 2.5)
	elif p["new_count"] == 0:
		_toast(FT.b9_vorhanden())          # U-03 B9: vorher stumm (nichts gebaut, kein Toast)
	_check_milestones()
	return true


## Felder, die eine Linie befährt: Feld -> group_key der (ersten) Linie.
func _used_cells(rail: bool) -> Dictionary:
	var out := {}
	for v in vehicles:
		if v.state == Vehicle.State.IDLE or (v.type == "train") != rail:
			continue
		for pos in v.path:
			var c := Vector2i(int(floor(pos.x)), int(floor(pos.y)))
			if not out.has(c):
				out[c] = v.group_key
	return out


## Anzahl Fahrzeuge im Besitz (verkaufte zählen nicht).
var _fleet_n := -1   # S6: Cache für fleet_size() (HUD fragt je Frame; -1 = neu zählen bei Kauf/Verkauf)

func fleet_size() -> int:
	if _fleet_n < 0:
		_fleet_n = 0
		for v in vehicles:
			if not v.sold:
				_fleet_n += 1
	return _fleet_n


func line_title(key: String) -> String:
	if not line_groups.has(key):
		return key
	var v = line_groups[key][0]
	return "%s-Linie %s › %s" % [v.kind_name, v.src.display_name, v.dst.display_name]


## B-01: Linie auflösen. Fahrzeuge werden verkauft (Erstattung refund_promille des Kaufpreises, wie Abriss
## 50 %), Ladung verfällt. Danach sind die befahrenen Felder wieder abreißbar. Gibt die Erstattung (Cent) zurück.
func remove_line(key: String) -> int:
	if not line_groups.has(key):
		return 0
	var title := line_title(key)
	var refund := 0
	var list: Array = line_groups[key]
	for v in list:
		refund += v.paid_cent * refund_promille / 1000
		eco.v_lots.erase(v.vid)
		shim.v_cargo[v.slot] = 0
		v.state = Vehicle.State.IDLE
		v.path = PackedVector2Array()
		v.fix_cent = 0
		v.var_cent_per_field = 0
		v.sold = true
		_fleet_n = -1
		n_assigned -= 1
	line_groups.erase(key)
	line_order.erase(key)
	eco.cash_cent += refund
	cost_dirty = true
	lines_dirty = true
	network_dirty = true
	if refund == 0:
		_toast(FT.l15_gratis_rueckkauf(), 5.0)         # U-03 L15: statt „+0 $“
	else:
		_toast("%s aufgelöst: %d Fahrzeug%s verkauft, +%s. Die Strecke ist jetzt abreißbar." % [
			title, list.size(), "" if list.size() == 1 else "e", money_str(refund)], 5.0)
	_refresh_lines()
	if selected != null:
		_refresh_panel()
	return refund


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
					items.append({"cell": c, "rail": rail, "refund": 0, "state": "bad", "line": used[c],
						"reason": "%s fährt hier. Erst links unter „Linien“ auflösen (Papierkorb)." % line_title(used[c])})
					if reason == "":
						reason = items[-1]["reason"]
				else:
					var paid: Dictionary = rail_paid if rail else road_paid
					var r: int = int(paid.get(c, 0)) * refund_promille / 1000
					items.append({"cell": c, "rail": rail, "refund": r, "state": "remove", "reason": ""})
					refund += r
	if reason == "" and foreign:
		reason = FT.b14_abriss_fremd()
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
		render_batch.remove(["rail" if rail else "road", c])
		net.erase(c)
		paid.erase(c)
		astar.set_point_solid(c, true)
		if road_tiles != null:
			road_tiles.forget(c, rail)
	eco.cash_cent += p["refund"]
	_clear_preview()
	cost_dirty = true
	network_dirty = true
	if road_tiles != null:
		road_tiles.refresh()
	if p["count"] > 0:
		_toast("Abriss: %s, +%s erstattet (50 %%)" % [dist_str(p["count"]), money_str(p["refund"])], 2.5)
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
		_toast(FT.b7_aussen() if _mouse_off_map() else FT.b10_kein_ziel())    # U-03 B7/B10: vorher stumm
		return false
	if tool == Tool.DEMOLISH:
		demolish(start, end)
		return true
	if start == end and not roads.has(end) and not rails.has(end) and not city_streets.has(end) and not cell_to_building.has(end):
		_toast(FT.b10_kein_ziel())      # U-03 B10: Klick ohne Ziehen baut keinen 1-Feld-Stummel mehr
		return false
	return build_track(start, end, tool == Tool.RAIL)


## U-03 B7: Maus zeigt auf die Ebene außerhalb der Karte (sonst: ins Leere/auf die UI -> B10).
func _mouse_off_map() -> bool:
	if sim_hover_active:
		return sim_hover != Vector2i(-1, -1)
	var mp := get_viewport().get_mouse_position()
	var hit = Plane(Vector3.UP, 0.0).intersects_ray(cam.project_ray_origin(mp), cam.project_ray_normal(mp))
	return hit != null


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
		_toast(FT.b15_lager_platz())
		return null
	if warehouse_cent > eco.cash_cent:
		_toast(FT.b16_lager_geld(self, warehouse_cent))
		return null
	warehouse_count += 1
	for c in _warehouse_cells(cell):
		_clear_decor(c)
	var w := Building.new()
	add_child(w)
	w.box_batch = render_batch       # S7 B: Lager-Quader gebündelt
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
	_toast("%s gebaut. %s" % [w.display_name, FT.b17_lager_hinweis()])
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
		_toast(FT.l6_fahrzeug_geld(self, "Zug" if type == "train" else "Lkw", price))
		return null
	if free:
		free_trucks_left -= 1
	charge(price)
	var v
	if fleet != null:
		v = fleet.new_vehicle(next_vid)          # F-18: Slot im Kern erst mit Linie (assign)
	else:
		v = Vehicle.new()
		v.slot = shim.add_vehicle_slot(next_vid)
		v.feld_mm = feld_mm
		v.vid = next_vid
	v.paid_cent = price
	next_vid += 1
	v.type = type
	v.load_ticks = load_ticks
	v.periode_ticks = periode_ticks
	if type == "train":
		var lok: Dictionary = vdefs["lok_e1"]
		var wag: Dictionary = vdefs["waggon_e1"]
		v.kind_name = "Zug"
		v.cap = TRAIN_WAGONS * int(wag["kapazitaet_einheiten"])
		v.speed = float(lok["tempo_mm_pro_tick"]) / feld_mm
		v.speed_mm = int(lok["tempo_mm_pro_tick"])
		v.fix_cent = int(lok["fix_cent_pro_periode"]) + TRAIN_WAGONS * int(wag["fix_cent_pro_periode"])
		v.var_cent_per_field = int(lok["variabel_cent_pro_feld"]) + TRAIN_WAGONS * int(wag["variabel_cent_pro_feld"])
		v.max_wait_ticks = TRAIN_MAX_WAIT_TICKS
	else:
		var d: Dictionary = vdefs[eco.slice["fahrzeug_ref"]["lkw_id"]]
		v.kind_name = "Lkw"
		v.cap = int(d["kapazitaet_einheiten"])
		v.speed = float(d["tempo_mm_pro_tick"]) / feld_mm
		v.speed_mm = int(d["tempo_mm_pro_tick"])
		v.fix_cent = int(d["fix_cent_pro_periode"])
		v.var_cent_per_field = int(d["variabel_cent_pro_feld"])
		v.max_wait_ticks = TRUCK_MAX_WAIT_TICKS
	v.rindex = n_type[type]
	n_type[type] += 1
	vehicles.append(v)
	_fleet_n = -1
	cost_dirty = true
	return v


func create_line(a, b, type: String):
	var astar: AStarGrid2D = astar_rail if type == "train" else astar_road
	var path := astar.get_id_path(a.anchor(), b.anchor())
	if path.is_empty():
		_toast(FT.l1_keine_verbindung(a.display_name, b.display_name, type == "train", b.kind == Building.Kind.CITY))
		return null
	var v = buy_vehicle(type)
	if v == null:
		return null
	v.assign(a, b, Array(path))
	register_line(v)
	_toast("%s-Linie: %s → %s (%s)" % [v.kind_name, a.display_name, b.display_name, dist_str(v.distance)])
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
	if road_tiles != null:     # W-04: schmales Band + rote Fehlstelle statt Feldquader
		road_tiles.preview(plan, preview_root, {"new": mat_ok, "bad": mat_bad, "exist": mat_exist, "saum": mat_saum})
		_dock_marker(plan.get("dock_street", Vector2i(-1, -1)))
		return
	for it in plan["items"]:
		match it["state"]:
			"new":
				_ghost(it["cell"], mat_ok)
			"bad":
				_ghost(it["cell"], mat_bad)
			_:
				_ghost(it["cell"], mat_exist)
	_dock_marker(plan.get("dock_street", Vector2i(-1, -1)))


## Z-01: Anschlusspunkt am Stadtrand in der Vorschau (Marker-Farbe S-08, Säule über der Stadtstraße).
func _dock_marker(c: Vector2i) -> void:
	if c.x < 0:
		return
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.5, 1.6, 0.5)
	mi.mesh = box
	mi.material_override = mat_marker
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = Vector3(c.x + 0.5, 0.8, c.y + 0.5)
	mi.name = "DockMarker"
	preview_root.add_child(mi)


func _update_cursor_label() -> void:
	if not dragging or plan.is_empty() or hover_cell.x < 0:
		cursor_box.visible = false
		return
	cursor_box.visible = true
	var world := Vector3(hover_cell.x + 0.5, 0.0, hover_cell.y + 0.5)
	cursor_box.position = cam.unproject_position(world) + Vector2(22, 8)
	if plan.get("demolish", false):
		cursor_cost.text = "Abriss: %s  +%s (50 %%)" % [dist_str(plan["count"]), money_str(plan["refund"])]
		cursor_cost.add_theme_color_override("font_color", ThemeBuilder.C["status_warn"])
		cursor_reason.text = Kit.txt(plan["reason"])
		cursor_reason.visible = plan["reason"] != ""
		cursor_box.reset_size()
		return
	cursor_cost.text = cursor_cost_text(plan)
	var hang: Dictionary = plan.get("hang", {})
	var warn: bool = plan["ok"] and int(hang.get("faktor_pm", 1000)) > 1000
	cursor_cost.add_theme_color_override("font_color", ThemeBuilder.C["status_bad"] if not plan["ok"] else (ThemeBuilder.C["status_warn"] if warn else ThemeBuilder.C["cream"]))
	var why := ""
	if not plan["ok"]:
		why = plan["reason"]
	elif warn:
		why = FT.b12_hang(self, int(hang["faktor_pm"]), plan["total"])      # U-03 B12 (S7): Hinweis, kein Fehler
	elif plan.get("hint", "") != "":
		why = plan["hint"]                                                   # U-03 B9: grau, nichts Neues zu bauen
	cursor_reason.text = Kit.txt(why)
	cursor_reason.visible = why != ""
	cursor_box.reset_size()


## U-03 U12/S1: Kopfzeile der Bau-Vorschau. Slice „Straße: 12 Felder · 480 $“, S7 „Straße: 12 Felder (300 m) · 480 $“.
func cursor_cost_text(p: Dictionary) -> String:
	var n: int = p["new_count"]
	var d := ("%d Felder (%s)" % [n, dist_str(n)]) if world_s7 != null else dist_str(n)
	var t := "%s: %s · %s" % ["Gleis" if p["rail"] else "Straße", d, money_str(p["total"])]
	if p.get("dock_city", "") != "":
		t += "\n" + FT.s1_anschluss(p["dock_city"])
	return t


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
	if not company_started or bankrupt or hq.time_frozen():
		return
	var cash0: int = eco.cash_cent
	if fleet != null:
		shim.step()                 # F-18: Tick, Öko-Tick (economy.on_tick) und alle Fahrzeuge im SoA-Kern
		fleet.after_step(self)      # Fahrkosten abbuchen, Lieferungen verbuchen
	else:
		shim.tick_count += 1
		eco.on_tick(shim)
		for v in vehicles:
			v.tick(self)
	if not eco.lic_events.is_empty():
		_licence_events()
	if cost_dirty:
		_recompute_running_cost()
	cost_acc += running_cost_per_period
	var c := cost_acc / periode_ticks
	if c > 0:
		cost_acc -= c * periode_ticks
		charge(c)
	var zi: int = credit.interest_due(shim.tick_count)     # F-19: Festzins am Periodenende
	if zi > 0:
		charge(zi)
		credit.interest_paid += zi
	if eco.cash_cent < 0:
		_go_bankrupt()
	else:
		bk_warn.tick(self, eco.cash_cent - cash0)     # U-03 K1: nur lesend
		if shim.tick_count % 10 == 0:
			_check_milestones()


## B-xx (S7): Toast je automatischer Lizenzverlängerung mit Betrag (vorher still, Daniel Z-05 / Lena S6).
var licence_toasts: Array = []      # Testspur: Texte der Verlängerungs-Toasts

func _licence_events() -> void:
	for e in eco.lic_events:
		var nm := "Lizenz"
		for b in buildings:
			if b.site == e["site"] and b.kind != Building.Kind.CITY:
				nm = b.display_name
				break
		var t: String
		if e["ok"]:
			t = FT.l11_verlaengert(self, nm, e["cent"])
		else:
			t = FT.l11_abgelaufen(self, nm, e["cent"])
		licence_toasts.append(t)
		_toast(t, 6.0)
	eco.lic_events.clear()


func run_ticks(n: int) -> void:
	for i in n:
		if bankrupt:
			return
		sim_tick()


var bankrupt_posten := {}      # U-03 K2: Testspur

func _go_bankrupt() -> void:
	bankrupt = true
	speed = 0
	_refresh_speed_buttons()
	_set_tool(Tool.NONE)
	bankrupt_panel.visible = true
	if bankrupt_panel.is_inside_tree():
		UiFx.slide_in(bankrupt_panel, Vector2(0, -20))
	var po: Dictionary = bk_warn.biggest_loss(self)       # U-03 K2: Ursache als Posten statt nur Zahlen
	bankrupt_posten = po
	bankrupt_label.text = Kit.txt("%s\nKasse %s nach %s Spielzeit · Einnahmen %s · Ausgaben %s · Fahrzeuge %d (Unterhalt %s/min)." % [
		FT.k2_bankrott(self, po["name"], po["cent_min"]), bankrupt_cash_str(eco.cash_cent), time_str(shim.tick_count),
		money_str(eco.revenue_total), money_str(expenses_total), fleet_size(), money_str(running_cost_per_period)])
	print("BANKROTT tick=%d kasse=%d" % [shim.tick_count, eco.cash_cent])


func on_delivery(v, units: int, income: int, trip_cost: int, gut := "") -> void:
	deliveries.append({"tick": shim.tick_count, "units": units, "income": income, "trip_cost": trip_cost,
		"src": v.src.map_id, "dst": v.dst.map_id})
	if income > trip_cost:
		deliveries_profit += 1
	if income > 0:
		_complete(4)
		if gut != "" or not eco.ledger.is_empty():
			var g: String = gut if gut != "" else eco.ledger[-1]["gut"]
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
	l.font = ThemeBuilder.font(ThemeBuilder.FONT_TITLE)
	l.outline_modulate = Color(ThemeBuilder.C["saum"], 0.95)
	l.outline_size = 14
	l.position = pos + Vector3(0, 1.5, 0)
	add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "position", l.position + Vector3(0, 3, 0), 1.5)
	tw.tween_callback(l.queue_free)


# ---------------------------------------------------------------- Anzeige

func _refresh_lines() -> void:
	lines_card.visible = company_started and (not line_order.is_empty() or fleet_size() > 0)
	for key in line_rows.keys():
		if not line_groups.has(key):
			line_rows[key]["row"].queue_free()
			line_rows.erase(key)
	var max_h := lines_max_height()
	var vis_n := int(max_h / LINE_ROW_H) + 2
	var first_vis := int(lines_scroll.scroll_vertical / LINE_ROW_H) - 1
	lines_scroll.custom_minimum_size = Vector2(LEFT_W - 28, minf(line_order.size() * LINE_ROW_H, max_h))
	for i in line_order.size():
		var key: String = line_order[i]
		var list: Array = line_groups[key]
		var v = list[0]
		if not line_rows.has(key):
			line_rows[key] = _make_line_row(key, v)
		var r: Dictionary = line_rows[key]
		r["row"].visible = true
		if i < first_vis or i > first_vis + vis_n:
			continue                # S6: Zeilen außerhalb des Scrollfensters nicht durchrechnen (5.000 Lkw)
		var profit := _line_profit(list)
		var deliv := 0
		var warn := false
		for w in list:
			deliv += w.deliveries
			warn = warn or w.no_licence
		# U-02b: Zeile kürzen statt Spalte verbreitern („Lief.“), Warnung vorn, damit eine Kürzung nur das Ende trifft
		r["sub"].text = Kit.txt("%s×%d · %s · %d Lief." % ["keine Lizenz! · " if warn else "", list.size(), dist_str(v.distance), deliv])
		r["sub"].theme_type_variation = "LabelBad" if warn else "LabelMuted"
		r["val"].text = "%+d $" % int(profit)
		r["val"].add_theme_color_override("font_color", ThemeBuilder.C["ok_text"] if profit > 0 else (ThemeBuilder.C["bad_text"] if profit < 0 else ThemeBuilder.C["muted"]))
	var rows := []
	var idle := fleet_size() - n_assigned
	if idle > 0:
		rows.append("%d Fahrzeuge ohne Linie (Unterhalt läuft)" % idle)
	lines_label.text = Kit.txt("\n".join(rows))
	lines_label.visible = not rows.is_empty()


## U-03: Platz für die Linienliste bis über die Werkzeugleiste (Hinweis + Leiste ca. 150 px), mindestens 3 Zeilen.
func lines_max_height() -> float:
	var vh: float = get_viewport().get_visible_rect().size.y if is_inside_tree() else 900.0
	var top: float = lines_card.global_position.y + 44.0 if lines_card.is_inside_tree() and lines_card.visible else HUD_H + 300.0
	return maxf(3.0 * LINE_ROW_H, vh - top - 190.0)


func _make_line_row(key: String, v) -> Dictionary:
	var title := Kit.label("%s › %s" % [v.src.display_name, v.dst.display_name], "")
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var sub := Kit.label("", "LabelMuted")
	sub.clip_text = true          # U-02b: Zeile wächst nie über die 340-px-Spalte hinaus
	sub.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var val := Kit.label("", "LabelValue")
	var del := Kit.button("", "ButtonGhost", "abriss", func(): remove_line(key))
	del.tooltip_text = "Linie auflösen: Fahrzeuge verkaufen (+50 % Kaufpreis), Ladung geht verloren. Danach ist die Straße abreißbar."
	del.add_theme_constant_override("icon_max_width", 18)
	del.custom_minimum_size = Vector2(30, 30)          # D-07 BUG-6: Klickziel >= 24 px (vorher ca. 12 px)
	del.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val.custom_minimum_size.x = 56
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 0)             # Platzhalter: zwei Trenner (je 8 px) = 16 px Abstand Text-zu-Gewinn statt 8 px
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# U-02b: zwei Zeilen statt einer breiten: oben Name + Papierkorb, unten Kennzahlen + Gewinn (rechtsbündig unter
	# „Gewinn/min“). So bleibt die Spalte bei 340 px und der Name wird nicht mehr von Gewinn/Knopf abgeschnitten.
	var tv := Kit.vbox(0, [Kit.hbox(8, [title, del]), Kit.hbox(8, [sub, gap, val])])
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := Kit.hbox(8, [Kit.icon("zug" if v.type == "train" else "lkw", 20, ThemeBuilder.C["muted"]), tv])
	row.custom_minimum_size.y = LINE_ROW_H - 2
	lines_box.add_child(row)
	return {"row": row, "title": title, "sub": sub, "val": val, "del": del}


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
	var lic := "Lizenz aktiv" if eco.licence_valid(b.site) else "ohne Lizenz"
	if b.kind == Building.Kind.PROCESSOR:
		var buf: Dictionary = eco.s_inbuf[b.site]
		var n_in := 0
		for gi in buf:
			n_in += buf[gi]
		return "%s\n%s %d → %s %d\n%s" % [b.display_name, _goods_txt(b.in_goods), n_in, good_names.get(b.out_good, ""), shim.st_stock[b.station], lic]
	return "%s\n%s %d\n%s" % [b.display_name, good_names.get(b.out_good, ""), shim.st_stock[b.station], lic]


func _refresh_labels() -> void:
	eco.sync_all(shim)
	_refresh_label_text()
	for b in buildings:
		if b.site >= 0 and b.is_industry():
			b.licence_marker.visible = eco.licence_valid(b.site)


func _refresh_label_text() -> void:
	for b in buildings:
		b.label.text = _label_lod_text(b)


## Fahrzeuge zeichnen: drei MultiMeshes, Puffer je Sim-Tick am Stück gebaut (12 Floats Transform, Ladung + 4
## Farbe; Layout wie set_instance_transform: [c,0,s,x, 0,1,0,y, -s,0,c,z] für Drehung um Y). Zwischen zwei
## Ticks interpoliert die Engine (Physik-Interpolation, physics_ticks_per_second = 1000 / tick_ms), damit das
## Skript nicht in jedem Frame 5.000 Transformationen schreiben muss (Bench F-12).
## Indizes sind stabil (Fahrzeuge werden im Slice nie entfernt): Lkw/Zug über v.rindex, Ladung über die
## Position in `vehicles`. Fahrzeuge ohne Linie bzw. ohne Ladung haben Skalierung 0.
var _cur := {"truck": PackedFloat32Array(), "train": PackedFloat32Array(), "cargo": PackedFloat32Array()}
var _prev := {"truck": PackedFloat32Array(), "train": PackedFloat32Array(), "cargo": PackedFloat32Array()}
var n_type := {"truck": 0, "train": 0}


## S7 B Hook für das Terrain (Felix/Fable): Fahrzeughöhe je Feld. grid[z * w + x] in Weltmetern der Szene
## (gleiche Einheit wie position.y), w = Kartenbreite in Feldern; leeres grid = Höhe 0. fn(x, z) -> float nur als
## Rückfall ohne Gitter (je Fahrzeug und Tick aufgerufen). Rein Darstellung, gilt für beide Kerne (soa/alt).
func set_vehicle_heights(grid: PackedFloat32Array, w: int, fn := Callable()) -> void:
	vehicle_h_grid = grid
	vehicle_h_w = w if not grid.is_empty() else 0
	vehicle_height_fn = fn
	if fleet != null:
		fleet.h_grid = vehicle_h_grid
		fleet.h_w = vehicle_h_w
		fleet.h_fn = vehicle_height_fn


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
	if fleet != null and RENDER_SPLIT:
		if fleet.render_pending():          # S6: Puffer des Vortick-Zustands (über Frames gefüllt) übergeben
			var rp: Array = fleet.render_finish()
			_commit_buffers(rp[0], rp[1], rp[2])
		_ensure_buf("truck", n_type["truck"], 12, mm_truck.multimesh)
		_ensure_buf("train", n_type["train"], 12, mm_train.multimesh)
		_ensure_buf("cargo", vehicles.size(), 16, mm_cargo.multimesh)
		fleet.render_begin(vehicles, _cur["truck"], _cur["train"], _cur["cargo"], eco, GOOD_COLORS)
		return
	_ensure_buf("truck", n_type["truck"], 12, mm_truck.multimesh)
	_ensure_buf("train", n_type["train"], 12, mm_train.multimesh)
	_ensure_buf("cargo", vehicles.size(), 16, mm_cargo.multimesh)
	var bt: PackedFloat32Array = _cur["truck"]
	var bz: PackedFloat32Array = _cur["train"]
	var bc: PackedFloat32Array = _cur["cargo"]
	if fleet != null:
		var r: Array = fleet.fill_buffers(vehicles, bt, bz, bc, eco, GOOD_COLORS)   # F-18
		_commit_buffers(r[0], r[1], r[2])
		return
	var cargo_arr: PackedInt32Array = shim.v_cargo
	var hg := vehicle_h_grid
	var hw := vehicle_h_w
	var hfn := vehicle_height_fn
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
		var h := 0.0          # S7 B Hook Fahrzeughöhe (Terrain), Default 0
		if hw > 0:
			var cx := int(x)
			var cz := int(z)
			if cx >= 0 and cz >= 0 and cx < hw and cz * hw + cx < hg.size():
				h = hg[cz * hw + cx]
		elif hfn.is_valid():
			h = hfn.call(x, z)
		if is_train:
			bz[k] = c; bz[k + 1] = 0.0; bz[k + 2] = s; bz[k + 3] = x
			bz[k + 4] = 0.0; bz[k + 5] = 1.0; bz[k + 6] = 0.0; bz[k + 7] = 0.35 + h
			bz[k + 8] = -s; bz[k + 9] = 0.0; bz[k + 10] = c; bz[k + 11] = z
		else:
			bt[k] = c; bt[k + 1] = 0.0; bt[k + 2] = s; bt[k + 3] = x
			bt[k + 4] = 0.0; bt[k + 5] = 1.0; bt[k + 6] = 0.0; bt[k + 7] = 0.3 + h
			bt[k + 8] = -s; bt[k + 9] = 0.0; bt[k + 10] = c; bt[k + 11] = z
		if cargo_arr[v.slot] > 0:
			var col: Color = Color.WHITE
			var lots: Array = eco.v_lots.get(v.vid, [])
			if not lots.is_empty():
				col = GOOD_COLORS.get(eco.g_ids[lots[0][0]], Color.WHITE)
			bc[kc] = c; bc[kc + 1] = 0.0; bc[kc + 2] = s; bc[kc + 3] = x
			bc[kc + 4] = 0.0; bc[kc + 5] = 1.0; bc[kc + 6] = 0.0; bc[kc + 7] = (0.75 if not is_train else 0.85) + h
			bc[kc + 8] = -s; bc[kc + 9] = 0.0; bc[kc + 10] = c; bc[kc + 11] = z
			bc[kc + 12] = col.r; bc[kc + 13] = col.g; bc[kc + 14] = col.b; bc[kc + 15] = 1.0
		else:
			for j in 12:
				bc[kc + j] = 0.0
	_commit_buffers(bt, bz, bc)


func _commit_buffers(bt: PackedFloat32Array, bz: PackedFloat32Array, bc: PackedFloat32Array) -> void:
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
			if toast_panel.visible:
				UiFx.slide_out(toast_panel, Vector2(0, -16))
	if toast_label.text == "" and toast_panel.visible:
		var tw: Tween = toast_panel.get_meta("slide_tw") if toast_panel.has_meta("slide_tw") else null
		if tw == null or not tw.is_running():
			toast_panel.visible = false
	_move_camera(delta)
	if fleet != null:
		fleet.render_step()          # S6: Portion des Fahrzeug-Puffers (siehe _render_vehicles)
	_update_label_lod()
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
	if not company_started:
		for k in hud_vals:
			hud_vals[k].text = "–"
	else:
		_update_hud(cpm)
	_update_hint()
	hint_label.text = Kit.txt(hint_label.text)
	_update_cursor_label()


func _update_hud(cpm: int) -> void:
	hud_vals["kasse"].text = money_str(eco.cash_cent)
	hud_vals["kasse"].add_theme_color_override("font_color", ThemeBuilder.C["status_bad"] if eco.cash_cent < cpm * 2 else ThemeBuilder.C["cream"])
	hud_vals["einnahmen"].text = money_str(eco.revenue_total)
	hud_vals["kosten"].text = money_str(cpm) + "/min"
	hud_vals["fahrzeuge"].text = str(fleet_size())
	hud_vals["zeit"].text = time_str(shim.tick_count)
	if hud_vals.has("kredit"):
		hud_vals["kredit"].text = money_str(credit.loan_cent)          # U-02b: Rahmen steht als „max.“ im Tooltip
		credit_buttons[0].disabled = not company_started or bankrupt or credit.borrow_amount(shim.tick_count) <= 0
		# T-15/U-03: grauer [+] erklärt sich (Sperrzeit aus kredit.credit_available_from_ticks, Rest m:ss)
		credit_buttons[0].tooltip_text = FT.kredit_ab(self) if FT.kredit_gesperrt(self) else "Kredit aufnehmen: +%s" % money_str(credit.step_cent)
		credit_buttons[1].disabled = not company_started or bankrupt or credit.repay_amount(eco.cash_cent) <= 0
	if bk_warn.active:      # U-03 K1: Kasse rot, solange die Vorwarnung gilt
		hud_vals["kasse"].add_theme_color_override("font_color", ThemeBuilder.C["status_bad"])


func _update_hint() -> void:
	if hq.hint() != "":
		hint_label.text = hq.hint()
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
			hint_label.text = "Klick auf Gebäude: Infos und Lizenz  ·  WASD bewegen  ·  Q/E drehen  ·  Mausrad zoomen  ·  Leertaste Pause"


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
