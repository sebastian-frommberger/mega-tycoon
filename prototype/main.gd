extends Node3D
## Mega Tycoon – Prototyp „Start-Simulation“
## Firma kaufen → erste Kette verbinden → Meilensteine öffnen die Karte.
## Version 3: große Karte mit 5 Städten (Straßen + Häuser), 5 Produktionsketten,
## Fluss, Küste, Berge und Wälder. Firmenkauf, Lager, Gleise, Züge, Gewinn pro Linie.
## Alles wird im Code aufgebaut, Gebäude sind farbige Würfel.

const Building := preload("res://building.gd")
const Vehicle := preload("res://truck.gd")

const GRID := 192
const START_MONEY := 15000.0
const ROAD_COST := 10              # $ pro Feld Straße im Einflussbereich
const RAIL_COST := 40              # $ pro Feld Gleis im Einflussbereich
const OUTSIDE_SURCHARGE := 0.8     # Aufschlag-Faktor pro Feld Abstand zum Einflussbereich
const WAREHOUSE_COST := 800
const OWNED_RADIUS := 18.0         # Einfluss um eigene Firmen
const OWNED_RADIUS_OPEN := 26.0    # nach Meilenstein „Karte öffnet sich“
const BUY_SURCHARGE := 0.04        # Kaufpreis-Aufschlag pro Feld außerhalb des Einflusses
const BUILDING_RADIUS := 6.0
const OPEN_THRESHOLD := 2500.0     # Einnahmen für Meilenstein 4
const WATER_FACTOR := 6.0          # Brücke: Bau über Wasser kostet das Sechsfache
const MOUNTAIN_FACTOR := 3.0       # Berg: Hang/Tunnel kostet das Dreifache
enum Terrain { PLAIN, WATER, MOUNTAIN }
const PAY_PER_UNIT_FIELD := 0.5    # Ertrag pro Einheit und Feld Distanz (Rohstoff)
const PRODUCT_FACTOR := 2.0        # Endprodukte bringen das Doppelte

## Die beiden Verkehrsmittel. Hier wird das Verhältnis Lkw/Zug getunt.
const VEHICLES := {
	"truck": {"name": "Lkw", "cost": 400, "capacity": 10, "speed": 6.0, "load_rate": 5.0,
		"max_wait": 5.0, "upkeep": 1.5, "y": 0.25, "size": Vector3(0.45, 0.3, 0.75), "color": Color(0.92, 0.92, 0.97)},
	"train": {"name": "Zug", "cost": 1500, "capacity": 40, "speed": 10.0, "load_rate": 10.0,
		"max_wait": 12.0, "upkeep": 5.0, "y": 0.3, "size": Vector3(0.55, 0.4, 1.6), "color": Color(0.2, 0.3, 0.55)},
}

enum Tool { NONE, ROAD, RAIL, WAREHOUSE, TRUCK_LINE, TRAIN_LINE, BUY, DEMOLISH }
const TOOL_NAMES := ["–", "Straße", "Gleis", "Lager", "Lkw-Linie", "Zug-Linie", "Firma kaufen", "Abriss"]

## F-13 Bau-Tool (wie OpenTTD): ziehen, gerade + 45°, Ghost, Abriss mit Erstattung.
const BRIDGE_MAX := 8              # wie OpenTTD: Brücke nur gerade, Land an beiden Enden, begrenzte Länge
const REFUND_SHARE := 0.5          # Abriss erstattet 50 % des tatsächlich bezahlten Feldpreises

const GOOD_COLORS := {
	"Getreide": Color(0.95, 0.85, 0.3),
	"Mehl": Color(1, 1, 1),
	"Öl": Color(0.1, 0.1, 0.1),
	"Benzin": Color(1.0, 0.55, 0.1),
	"Vieh": Color(0.55, 0.35, 0.2),
	"Fleisch": Color(0.85, 0.2, 0.2),
	"Holz": Color(0.45, 0.3, 0.15),
	"Bretter": Color(0.85, 0.7, 0.45),
	"Erz": Color(0.5, 0.35, 0.35),
	"Stahl": Color(0.7, 0.72, 0.78),
	"Werkzeug": Color(0.25, 0.45, 0.9),
}
const PRODUCTS := ["Mehl", "Benzin", "Fleisch", "Bretter", "Stahl", "Werkzeug"]

var money := START_MONEY
var earned := 0.0
var tool: int = Tool.BUY
var owned_radius := OWNED_RADIUS
var owned: Array = []
var metropole: Node3D
var warehouse_count := 0
var terrain := {}        # Zelle -> Terrain (nur WATER/MOUNTAIN gespeichert)
var decor := {}          # Zelle -> [MultiMeshInstance3D, Index] für Bäume/Berge
var city_streets := {}   # Zelle -> true

var astar_road := AStarGrid2D.new()
var astar_rail := AStarGrid2D.new()
var roads := {}
var rails := {}
var buildings: Array = []
var cell_to_building := {}
var vehicles: Array = []
var connected: Array = []

var drag_start := Vector2i(-1, -1)
var dragging := false
var road_paid := {}      # Zelle -> bezahlter Feldpreis (int $), Grundlage der Abriss-Erstattung
var rail_paid := {}
var sim_hover_active := false   # Tests/Screenshot: Cursor programmatisch setzen
var sim_hover := Vector2i(-1, -1)
var plan := {}           # aktueller Ghost-Plan während des Ziehens
var line_src: Node3D = null
var hover_cell := Vector2i(-1, -1)
var last_preview_cell := Vector2i(-99, -99)
var lines_timer := 0.0

var milestones := [
	{"text": "Kaufe deine erste Firma", "done": false},
	{"text": "Erste Lieferung an einen Verarbeiter", "done": false},
	{"text": "Erstes Endprodukt in einer Stadt", "done": false},
	{"text": "2.500 $ Transporteinnahmen → Einfluss wächst", "done": false},
	{"text": "Beliefere die Metropole", "done": false},
]

# Szene
var rig: Node3D
var cam: Camera3D
var zoom := 1.0
var influence_root: Node3D
var preview_root: Node3D
var hover_marker: MeshInstance3D
var info_label: Label
var hint_label: Label
var toast_label: Label
var toast_time := 0.0
var milestone_labels: Array = []
var lines_label: Label

var mat_road: StandardMaterial3D
var mat_rail: StandardMaterial3D
var mat_bridge: StandardMaterial3D
var mat_ok: StandardMaterial3D
var mat_bad: StandardMaterial3D
var mat_exist: StandardMaterial3D
var mat_demolish: StandardMaterial3D
var cursor_box: VBoxContainer
var cursor_cost: Label
var cursor_reason: Label
var mat_influence: StandardMaterial3D
var mat_influence_hq: StandardMaterial3D


func _ready() -> void:
	_setup_materials()
	_setup_environment()
	_setup_camera()
	_setup_ground()
	_setup_astar(astar_road)
	_setup_astar(astar_rail)
	_create_map()
	_setup_ui()


# ---------------------------------------------------------------- Aufbau

func _setup_materials() -> void:
	mat_road = _mat(Color(0.25, 0.25, 0.27))
	mat_rail = _mat(Color(0.45, 0.3, 0.2))
	mat_bridge = _mat(Color(0.75, 0.7, 0.6))
	mat_ok = _mat(Color(1.0, 1.0, 1.0, 0.75), true)        # weiß = baubar (wie OpenTTD/TF2)
	mat_bad = _mat(Color(1.0, 0.2, 0.15, 0.8), true)       # rot schraffiert = nicht baubar
	mat_bad.albedo_texture = _hatch_texture()
	mat_exist = _mat(Color(1.0, 1.0, 1.0, 0.25), true)     # schon vorhanden, kostet nichts
	mat_demolish = _mat(Color(1.0, 0.55, 0.1, 0.8), true)  # wird abgerissen
	mat_demolish.albedo_texture = _hatch_texture()
	mat_influence = _mat(Color(0.3, 0.6, 1.0, 0.12), true)
	mat_influence_hq = _mat(Color(0.3, 0.6, 1.0, 0.18), true)


## Diagonale Streifen für "nicht baubar" / "Abriss" (Schraffur).
func _hatch_texture() -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for x in 16:
		for y in 16:
			img.set_pixel(x, y, Color(1, 1, 1, 1) if (x + y) % 8 < 4 else Color(1, 1, 1, 0.35))
	return ImageTexture.create_from_image(img)


func _mat(color: Color, transparent := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	if transparent:
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
	rig.add_child(cam)
	cam.rotation = Vector3(-atan2(20.0, 16.0), 0, 0)
	zoom = 5.5
	_apply_zoom()


func _apply_zoom() -> void:
	cam.position = Vector3(0, 20, 16) * zoom


func _setup_ground() -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(GRID, GRID)
	ground.mesh = plane
	ground.material_override = _mat(Color(0.45, 0.58, 0.36))
	ground.position = Vector3(GRID * 0.5, 0, GRID * 0.5)
	add_child(ground)

	influence_root = Node3D.new()
	add_child(influence_root)
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
	for x in GRID:
		for y in GRID:
			a.set_point_solid(Vector2i(x, y), true)


func _create_map() -> void:
	_generate_terrain()

	# Städte (Name, Mitte, Radius, Bedarf)
	_build_city("Kornfeld", Vector2i(40, 100), 7, ["Mehl", "Bretter", "Fleisch"])
	_build_city("Nordheim", Vector2i(110, 30), 8, ["Mehl", "Werkzeug", "Bretter"])
	metropole = _build_city("Metropole", Vector2i(106, 104), 13, ["Mehl", "Fleisch", "Benzin", "Werkzeug", "Bretter"])
	_build_city("Bergstadt", Vector2i(70, 165), 7, ["Fleisch", "Benzin", "Werkzeug"])
	_build_city("Küstenhaven", Vector2i(158, 70), 8, ["Benzin", "Fleisch", "Mehl"])

	var P := Building.Kind.PRODUCER
	var V := Building.Kind.PROCESSOR

	# Getreide → Mühle → Mehl (Ebene westlich, nahe Kornfeld)
	for c in [Vector2i(20, 104), Vector2i(24, 122), Vector2i(42, 122), Vector2i(12, 114)]:
		_industry(P, "Getreidefarm", c, Vector2i(4, 4), Color(0.92, 0.8, 0.3), 0.3, "", "Getreide", 0.6, 1200)
	_industry(V, "Mühle", Vector2i(30, 113), Vector2i(2, 2), Color(0.95, 0.95, 0.9), 1.6, "Getreide", "Mehl", 1.0, 2500)

	# Holz → Sägewerk → Bretter (Wälder am Fuß der Berge)
	for c in [Vector2i(55, 45), Vector2i(66, 56), Vector2i(50, 60)]:
		_industry(P, "Forst", c, Vector2i(4, 4), Color(0.15, 0.4, 0.15), 0.8, "", "Holz", 0.8, 1000)
	_industry(V, "Sägewerk", Vector2i(62, 70), Vector2i(3, 2), Color(0.6, 0.42, 0.25), 1.4, "Holz", "Bretter", 1.0, 2200)

	# Erz → Stahlwerk → Stahl → Werkzeugfabrik → Werkzeug (3 Stufen)
	for c in [Vector2i(30, 40), Vector2i(44, 30)]:
		_industry(P, "Erzmine", c, Vector2i(3, 3), Color(0.35, 0.3, 0.3), 1.4, "", "Erz", 0.6, 1800)
	_industry(V, "Stahlwerk", Vector2i(36, 58), Vector2i(4, 3), Color(0.45, 0.3, 0.3), 2.6, "Erz", "Stahl", 1.0, 4000)
	_industry(V, "Werkzeugfabrik", Vector2i(96, 50), Vector2i(3, 3), Color(0.35, 0.45, 0.6), 2.0, "Stahl", "Werkzeug", 1.0, 3500)

	# Öl → Raffinerie → Benzin (an der Küste)
	for c in [Vector2i(166, 92), Vector2i(172, 106)]:
		_industry(P, "Ölfeld", c, Vector2i(2, 2), Color(0.12, 0.12, 0.12), 1.2, "", "Öl", 0.8, 1500)
	_industry(V, "Raffinerie", Vector2i(155, 110), Vector2i(3, 3), Color(0.95, 0.55, 0.15), 2.2, "Öl", "Benzin", 1.0, 3500)

	# Vieh → Schlachthof → Fleisch (südlich des Flusses)
	for c in [Vector2i(126, 160), Vector2i(146, 168), Vector2i(132, 176)]:
		_industry(P, "Weide", c, Vector2i(4, 4), Color(0.35, 0.78, 0.3), 0.3, "", "Vieh", 0.6, 1200)
	_industry(V, "Schlachthof", Vector2i(140, 154), Vector2i(2, 2), Color(0.8, 0.25, 0.25), 1.6, "Vieh", "Fleisch", 1.0, 2500)

	_scatter_trees()
	_build_terrain_visuals()


func _industry(kind: int, p_name: String, cell: Vector2i, size: Vector2i, color: Color, height: float, input: String, output: String, rate: float, price: int) -> Node3D:
	var b := _add_building(kind, p_name, cell, size, color, height, "")
	b.input_good = input
	b.output_good = output
	b.rate = rate
	b.price = price
	return b


func _add_building(kind: int, p_name: String, cell: Vector2i, size: Vector2i, color: Color, height: float, region: String) -> Node3D:
	var b := Building.new()
	add_child(b)
	b.setup(kind, p_name, cell, size, color, height, region)
	buildings.append(b)
	for c in b.cells():
		cell_to_building[c] = b
		terrain.erase(c)
		astar_road.set_point_solid(c, false)
		astar_rail.set_point_solid(c, false)
	return b


# ---------------------------------------------------------------- Gelände

func _generate_terrain() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1947

	# Fluss: Polylinie von Nord nach Ost ins Meer
	var river := [Vector2(70, 0), Vector2(76, 35), Vector2(80, 70), Vector2(80, 95), Vector2(95, 128), Vector2(130, 140), Vector2(160, 138), Vector2(192, 141)]
	for x in GRID:
		for y in GRID:
			var p := Vector2(x + 0.5, y + 0.5)
			var d := INF
			for i in river.size() - 1:
				d = minf(d, _dist_to_segment(p, river[i], river[i + 1]))
			var coast := 178.0 + sin(y * 0.11) * 3.0 + sin(y * 0.031) * 4.0
			if d < 1.8 or x >= coast:
				terrain[Vector2i(x, y)] = Terrain.WATER

	# Berge: Gipfel (Mitte, Radius, Höhe)
	var peaks := [
		[Vector2(25, 25), 18.0, 9.0], [Vector2(45, 16), 14.0, 7.0], [Vector2(12, 50), 12.0, 6.0],
		[Vector2(35, 165), 15.0, 8.0], [Vector2(26, 182), 10.0, 6.0], [Vector2(140, 12), 10.0, 5.0],
	]
	mountain_height.clear()
	for pk in peaks:
		var center: Vector2 = pk[0]
		var r: float = pk[1]
		var h: float = pk[2]
		for x in range(int(center.x - r), int(center.x + r) + 1):
			for y in range(int(center.y - r), int(center.y + r) + 1):
				var c := Vector2i(x, y)
				if x < 0 or y < 0 or x >= GRID or y >= GRID or terrain.get(c, -1) == Terrain.WATER:
					continue
				var t := 1.0 - Vector2(x, y).distance_to(center) / r
				if t <= 0.0:
					continue
				var hh := h * t * rng.randf_range(0.75, 1.15)
				if hh > mountain_height.get(c, 0.0):
					mountain_height[c] = hh
	for c in mountain_height:
		if mountain_height[c] > 0.6:
			terrain[c] = Terrain.MOUNTAIN


var mountain_height := {}
var tree_cells: Array = []


func _dist_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t)


func _scatter_trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for x in GRID:
		for y in GRID:
			var c := Vector2i(x, y)
			if terrain.has(c) or cell_to_building.has(c):
				continue
			var chance := 0.012
			# Bergfuß
			var mh: float = mountain_height.get(c, 0.0)
			if mh > 0.0:
				chance = 0.45
			# Wald um die Forste
			for b in buildings:
				if b.output_good == "Holz" and b.center().distance_to(Vector3(x, 0, y)) < 12.0:
					chance = maxf(chance, 0.5)
			if rng.randf() < chance:
				tree_cells.append(c)


func _build_terrain_visuals() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7

	# Wasser
	var wt := []
	var wc := []
	for c in terrain:
		if terrain[c] == Terrain.WATER:
			wt.append(Transform3D(Basis(), Vector3(c.x + 0.5, 0.02, c.y + 0.5)))
			wc.append(Color(0.25, 0.5, 0.8).lightened(rng.randf_range(0.0, 0.06)))
	_multimesh(Vector3(1, 0.04, 1), wt, wc, false)

	# Berge: Säulen nach Höhe, oben Schnee
	var mt := []
	var mcol := []
	var mcells := []
	for c in terrain:
		if terrain[c] != Terrain.MOUNTAIN:
			continue
		var h: float = mountain_height[c]
		var basis := Basis().scaled(Vector3(1, h, 1))
		mt.append(Transform3D(basis, Vector3(c.x + 0.5, h * 0.5, c.y + 0.5)))
		var col := Color(0.5, 0.45, 0.38) if h < 3.0 else Color(0.55, 0.55, 0.57)
		if h > 6.0:
			col = Color(0.95, 0.95, 0.97)
		mcol.append(col.lightened(rng.randf_range(-0.05, 0.05)))
		mcells.append(c)
	var mm := _multimesh(Vector3(1, 1, 1), mt, mcol, true)
	for i in mcells.size():
		decor[mcells[i]] = [mm, i]

	# Bäume
	var tt := []
	var tc := []
	for c in tree_cells:
		var h := rng.randf_range(0.8, 1.8)
		var basis := Basis().scaled(Vector3(0.6, h, 0.6))
		var off := Vector3(rng.randf_range(-0.2, 0.2), 0, rng.randf_range(-0.2, 0.2))
		tt.append(Transform3D(basis, Vector3(c.x + 0.5, h * 0.5, c.y + 0.5) + off))
		tc.append(Color(0.13, 0.38, 0.16).lightened(rng.randf_range(-0.05, 0.12)))
	var tm := _multimesh(Vector3(1, 1, 1), tt, tc, true)
	for i in tree_cells.size():
		decor[tree_cells[i]] = [tm, i]


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


## Entfernt Baum oder Bergsäule auf einer Zelle (z. B. beim Straßenbau).
func _clear_decor(c: Vector2i) -> void:
	if not decor.has(c):
		return
	var e: Array = decor[c]
	var mmi: MultiMeshInstance3D = e[0]
	mmi.multimesh.set_instance_transform(e[1], Transform3D(Basis().scaled(Vector3.ZERO), Vector3.ZERO))
	decor.erase(c)


# ---------------------------------------------------------------- Städte

func _build_city(p_name: String, center: Vector2i, r: int, demands: Array) -> Node3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(p_name)
	var cells := []
	var street_t := []
	var street_c := []
	var house_t := []
	var house_c := []
	var tall := 1.5 + r * 0.4
	for x in range(-r, r + 1):
		for y in range(-r, r + 1):
			var d := Vector2(x, y).length()
			if d > r - rng.randf() * 1.5:
				continue
			var c := center + Vector2i(x, y)
			if terrain.get(c, -1) == Terrain.WATER:
				continue
			cells.append(c)
			if x % 4 == 0 or y % 4 == 0:
				city_streets[c] = true
				street_t.append(Transform3D(Basis(), Vector3(c.x + 0.5, 0.03, c.y + 0.5)))
				street_c.append(Color(0.3, 0.3, 0.32))
			else:
				var t := d / float(r)
				var h := lerpf(tall, 0.5, t) * rng.randf_range(0.55, 1.25)
				var w := rng.randf_range(0.7, 0.92)
				house_t.append(Transform3D(Basis().scaled(Vector3(w, h, w)), Vector3(c.x + 0.5, h * 0.5, c.y + 0.5)))
				var base := Color(0.82, 0.78, 0.7) if rng.randf() < 0.6 else Color(0.7, 0.45, 0.38)
				if t < 0.35 and r >= 10:
					base = Color(0.6, 0.66, 0.75)  # Hochhäuser in der Mitte
				house_c.append(base.lightened(rng.randf_range(-0.12, 0.1)))
	_multimesh(Vector3(1, 0.06, 1), street_t, street_c, false)
	_multimesh(Vector3(1, 1, 1), house_t, house_c, true)

	var b := Building.new()
	b.custom_cells = cells
	add_child(b)
	b.setup(Building.Kind.CITY, p_name, center - Vector2i(r, r), Vector2i(2 * r + 1, 2 * r + 1), Color.WHITE, tall + 1.5, "")
	b.demands = demands
	buildings.append(b)
	for c in cells:
		cell_to_building[c] = b
		terrain.erase(c)
		if city_streets.has(c):
			astar_road.set_point_solid(c, false)
			astar_rail.set_point_solid(c, false)
	return b


# ---------------------------------------------------------------- UI

func _setup_ui() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)

	var top := VBoxContainer.new()
	top.position = Vector2(12, 10)
	ui.add_child(top)
	info_label = _label(20)
	top.add_child(info_label)
	var bar := HBoxContainer.new()
	top.add_child(bar)
	bar.add_child(_button("[B] Firma kaufen", func(): _set_tool(Tool.BUY)))
	bar.add_child(_button("[1] Straße (%d $/Feld)" % ROAD_COST, func(): _set_tool(Tool.ROAD)))
	bar.add_child(_button("[2] Gleis (%d $/Feld)" % RAIL_COST, func(): _set_tool(Tool.RAIL)))
	bar.add_child(_button("[3] Lager (%d $)" % WAREHOUSE_COST, func(): _set_tool(Tool.WAREHOUSE)))
	bar.add_child(_button("[4] Lkw-Linie (%d $)" % VEHICLES["truck"]["cost"], func(): _set_tool(Tool.TRUCK_LINE)))
	bar.add_child(_button("[5] Zug-Linie (%d $)" % VEHICLES["train"]["cost"], func(): _set_tool(Tool.TRAIN_LINE)))
	bar.add_child(_button("[X] Abriss (50 %)", func(): _set_tool(Tool.DEMOLISH)))
	bar.add_child(_button("[Esc]", func(): _cancel()))
	lines_label = _label(15)
	top.add_child(lines_label)

	var ms_panel := PanelContainer.new()
	ms_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	ms_panel.offset_left = -380
	ms_panel.offset_right = -12
	ms_panel.offset_top = 12
	ms_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	ui.add_child(ms_panel)
	var ms_box := VBoxContainer.new()
	ms_panel.add_child(ms_box)
	ms_box.add_child(_label(18, "Meilensteine"))
	for m in milestones:
		var l := _label(16)
		ms_box.add_child(l)
		milestone_labels.append(l)
	_refresh_milestones()

	hint_label = _label(18)
	hint_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hint_label.offset_left = 12
	hint_label.offset_top = -70
	hint_label.offset_right = 1200
	hint_label.offset_bottom = -12
	ui.add_child(hint_label)

	toast_label = _label(24)
	toast_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast_label.offset_left = -450
	toast_label.offset_right = 450
	toast_label.offset_top = 110
	toast_label.offset_bottom = 180
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui.add_child(toast_label)

	# Kosten und Grund direkt am Cursor (wie OpenTTD/TF2)
	cursor_box = VBoxContainer.new()
	cursor_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cursor_box.visible = false
	ui.add_child(cursor_box)
	cursor_cost = _label(20)
	cursor_box.add_child(cursor_cost)
	cursor_reason = _label(18)
	cursor_reason.modulate = Color(1, 0.45, 0.4)
	cursor_box.add_child(cursor_reason)



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


func _refresh_milestones() -> void:
	for i in milestones.size():
		var m: Dictionary = milestones[i]
		milestone_labels[i].text = ("✔ " if m["done"] else "○ ") + m["text"]
		milestone_labels[i].modulate = Color(0.6, 1, 0.6) if m["done"] else Color(1, 1, 1)


func _refresh_lines() -> void:
	if vehicles.is_empty():
		lines_label.text = ""
		return
	var rows := ["Linien (Gewinn pro Minute nach Unterhalt):"]
	for v in vehicles:
		var what: String = "/".join(v.filter) if v.filter.size() > 0 else "alles"
		rows.append("  %s  %s → %s  (%s, %d Felder)   %+d $/min" % [v.kind_name, v.src.display_name, v.dst.display_name, what, v.distance, int(v.profit_per_minute())])
	lines_label.text = "\n".join(rows)


func _toast(text: String, seconds := 4.0) -> void:
	toast_label.text = text
	toast_time = seconds


# ---------------------------------------------------------------- Firmenkauf

func _buy_cost(b: Node3D) -> int:
	return int(b.price * (1.0 + BUY_SURCHARGE * _distance_outside(b.cell)))


func _buy(b: Node3D) -> void:
	if b.kind == Building.Kind.CITY or b.price == 0:
		_toast("%s kann man nicht kaufen – Städte sind Kunden." % b.display_name)
		return
	if b.owned:
		_toast("%s gehört dir schon." % b.display_name)
		return
	var cost := _buy_cost(b)
	if cost > money:
		_toast("Zu wenig Geld: %s kostet %d $." % [b.display_name, cost])
		return
	money -= cost
	b.set_owned()
	owned.append(b)
	connected.erase(b)
	_refresh_influence()
	var first := owned.size() == 1
	_complete(0)
	if first:
		_set_tool(Tool.NONE)
		_toast("%s gehört dir! Bau eine Straße [1] zum Abnehmer und setz eine Lkw-Linie [4]." % b.display_name, 7.0)
	else:
		_toast("%s gekauft für %d $." % [b.display_name, cost])


# ---------------------------------------------------------------- Einfluss

func _influence_sources() -> Array:
	var out := []
	for b in owned:
		out.append([b.center(), owned_radius])
	for b in connected:
		out.append([b.center(), BUILDING_RADIUS])
	return out


func _distance_outside(cell: Vector2i) -> float:
	var p := Vector3(cell.x + 0.5, 0, cell.y + 0.5)
	var sources := _influence_sources()
	if sources.is_empty():
		return 0.0
	var best := INF
	for s in sources:
		var d: float = p.distance_to(s[0]) - s[1]
		best = minf(best, maxf(0.0, d))
	return best


func _refresh_influence() -> void:
	for c in influence_root.get_children():
		c.queue_free()
	var n_owned := owned.size()
	var i := 0
	for s in _influence_sources():
		var mi := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = s[1]
		cyl.bottom_radius = s[1]
		cyl.height = 0.02
		mi.mesh = cyl
		mi.material_override = mat_influence_hq if i < n_owned else mat_influence
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = s[0] + Vector3(0, 0.02, 0)
		influence_root.add_child(mi)
		i += 1


func _connect_influence(b: Node3D) -> void:
	if not owned.has(b) and not connected.has(b):
		connected.append(b)
		_refresh_influence()


# ---------------------------------------------------------------- Werkzeuge

func _set_tool(t: int) -> void:
	if owned.is_empty() and t != Tool.BUY:
		_toast("Kaufe zuerst eine Firma [B].")
		t = Tool.BUY
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
	else:
		_set_tool(Tool.NONE)


func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed:
		match mb.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				zoom = clampf(zoom * 0.9, 0.4, 9.0)
				_apply_zoom()
			MOUSE_BUTTON_WHEEL_DOWN:
				zoom = clampf(zoom * 1.1, 0.4, 9.0)
				_apply_zoom()
			MOUSE_BUTTON_LEFT:
				if tool == Tool.ROAD or tool == Tool.RAIL or tool == Tool.DEMOLISH:
					begin_drag(_mouse_cell())
				else:
					_click(_mouse_cell())
			MOUSE_BUTTON_RIGHT:
				_cancel()
		return
	if mb and not mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and dragging:
		end_drag()
		return
	var key := event as InputEventKey
	if key and key.pressed and not key.echo:
		match key.keycode:
			KEY_B:
				_set_tool(Tool.BUY)
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
	if c.x < 0 or c.y < 0 or c.x >= GRID or c.y >= GRID:
		return Vector2i(-1, -1)
	return c


func _click(cell: Vector2i) -> void:
	if cell.x < 0:
		return
	match tool:
		Tool.WAREHOUSE:
			_build_warehouse(cell)
		Tool.BUY:
			var bb = cell_to_building.get(cell)
			if bb != null and bb.visible:
				_buy(bb)
		Tool.TRUCK_LINE, Tool.TRAIN_LINE:
			var b = cell_to_building.get(cell)
			if b == null or not b.visible:
				return
			if line_src == null:
				if not b.provides():
					_toast("%s liefert nichts – wähle Produzent, Verarbeiter oder Lager." % b.display_name)
				elif not b.owned:
					_toast("%s gehört dir nicht. Laden kannst du nur bei eigenen Firmen – kaufen mit [B] (%d $)." % [b.display_name, _buy_cost(b)])
				else:
					line_src = b
			elif b == line_src:
				line_src = null
			else:
				var filter := _line_filter(line_src, b)
				if filter.is_empty() and b.kind != Building.Kind.WAREHOUSE:
					_toast("%s kann von %s nichts gebrauchen." % [b.display_name, line_src.display_name])
				else:
					_create_line(line_src, b, filter, "train" if tool == Tool.TRAIN_LINE else "truck")
					line_src = null
		Tool.NONE:
			var b2 = cell_to_building.get(cell)
			if b2 != null and b2.visible:
				_toast(b2.label.text.replace("\n", "  ·  "), 3.0)


## Welche Güter eine Linie von a nach b transportieren darf. Leer = alles (Lager → Lager).
func _line_filter(a: Node3D, b: Node3D) -> Array:
	if a.kind != Building.Kind.WAREHOUSE:
		return [a.output_good] if b.accepts(a.output_good) else []
	match b.kind:
		Building.Kind.PROCESSOR:
			return [b.input_good]
		Building.Kind.CITY:
			return b.demands.duplicate()
	return []


## Zugroute wie OpenTTD-Drag: erst gerade entlang der Hauptachse, dann 45°.
## Das Raster ist 4-verbunden; ein 45°-Schritt belegt deshalb zwei Felder (Treppe) –
## so belegt auch OpenTTD eine Diagonale (Halbfeld-Stücke auf einer Feldtreppe).
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


func _cell_cost(c: Vector2i, base: float) -> float:
	return base * (1.0 + OUTSIDE_SURCHARGE * _distance_outside(c))


func _terrain_factor(c: Vector2i) -> float:
	match terrain.get(c, Terrain.PLAIN):
		Terrain.WATER:
			return WATER_FACTOR
		Terrain.MOUNTAIN:
			return MOUNTAIN_FACTOR
	return 1.0


## Preis eines neuen Feldes (ganze $). Bestehende Regeln: Außerhalb-Aufschlag × Gelände-Faktor.
func field_cost(c: Vector2i, rail: bool) -> int:
	var base := RAIL_COST if rail else ROAD_COST
	return int(_cell_cost(c, base) * _terrain_factor(c))


func _in_grid(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < GRID and c.y < GRID


## Plant eine Strecke von a nach b. Ergebnis:
## {cells, items:[{cell, state:"new"|"exist"|"bad", cost, reason}], total, ok, reason, outside, new_count}
## Alles oder nichts (wie TF2): ist ein Feld rot, wird nichts gebaut.
func plan_track(a: Vector2i, b: Vector2i, rail: bool) -> Dictionary:
	var cells := _drag_path(a, b)
	var net: Dictionary = rails if rail else roads
	var items := []
	var n := cells.size()
	# Anschluss an ein Gebäude am Anfang/Ende ist erlaubt (wie OpenTTD an Station/Industrie).
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
	var outside := 0
	var new_count := 0
	var reason := ""
	for it in items:
		if it["state"] == "bad" and reason == "":
			reason = it["reason"]
		if it["state"] == "new":
			total += it["cost"]
			new_count += 1
			if _distance_outside(it["cell"]) > 0.0:
				outside += 1
	if reason == "" and total > money:
		reason = "Zu wenig Geld: %d $ nötig, %d $ vorhanden" % [total, int(money)]
		for it in items:
			if it["state"] == "new":
				it["state"] = "bad"
				it["reason"] = reason
	return {"a": a, "b": b, "rail": rail, "cells": cells, "items": items, "total": total,
		"ok": reason == "", "reason": reason, "outside": outside, "new_count": new_count}


## Länge der Gebäudefelder am Anfang (bzw. Ende) des Pfads, die zum End-Gebäude gehören.
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


## Wasser: automatische Brücke nur wie OpenTTD – gerade, Land an beiden Köpfen, max. BRIDGE_MAX Felder.
func _check_bridges(cells: Array, items: Array) -> void:
	var n := cells.size()
	var i := 0
	while i < n:
		if not (items[i]["state"] == "new" and terrain.get(cells[i], -1) == Terrain.WATER):
			i += 1
			continue
		var s := i
		while i < n and items[i]["state"] == "new" and terrain.get(cells[i], -1) == Terrain.WATER:
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


## Baut eine geplante Strecke. Gibt false zurück (und baut nichts), wenn ein Feld rot ist.
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
		var bridge: bool = terrain.get(c, Terrain.PLAIN) == Terrain.WATER
		var lift := 0.12 if bridge else 0.0
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
		add_child(mi)
		net[c] = mi
		paid[c] = it["cost"]
		astar.set_point_solid(c, false)
	money -= p["total"]
	_clear_preview()
	if p["total"] > 0:
		_toast("%s gebaut: %d Felder, %d $" % ["Gleis" if rail else "Straße", p["new_count"], p["total"]], 2.5)
	return true


## Felder, auf denen eine Linie fährt (Abriss dort gesperrt, wie OpenTTD bei Fahrzeug auf dem Gleis).
func _used_cells(rail: bool) -> Dictionary:
	var out := {}
	for v in vehicles:
		if (v.kind_name == VEHICLES["train"]["name"]) != rail:
			continue
		for pos in v.path:
			out[Vector2i(int(floor(pos.x)), int(floor(pos.z)))] = true
	return out


## Abriss-Rechteck wie OpenTTD (Feld a bis Feld b). Nur eigene Straßen/Gleise.
## {items:[{cell, rail, refund, state:"remove"|"bad", reason}], refund, reason, count}
func plan_demolish(a: Vector2i, b: Vector2i) -> Dictionary:
	var used_road := _used_cells(false)
	var used_rail := _used_cells(true)
	var items := []
	var refund := 0.0
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
					items.append({"cell": c, "rail": rail, "refund": 0.0, "state": "bad", "reason": "Von einer Linie befahren – erst Linie entfernen"})
					if reason == "":
						reason = items[-1]["reason"]
				else:
					var paid: Dictionary = rail_paid if rail else road_paid
					var r: float = paid.get(c, 0) * REFUND_SHARE
					items.append({"cell": c, "rail": rail, "refund": r, "state": "remove", "reason": ""})
					refund += r
	if reason == "" and foreign:
		reason = "Stadtstraßen und Gebäude kann man nicht abreißen"
	var count := 0
	for it in items:
		if it["state"] == "remove":
			count += 1
	return {"a": a, "b": b, "items": items, "refund": refund, "reason": reason, "count": count, "demolish": true}


## Reißt alle erlaubten Felder im Rechteck ab und erstattet genau 50 % des bezahlten Preises.
func demolish(a: Vector2i, b: Vector2i) -> float:
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
	money += p["refund"]
	_clear_preview()
	if p["count"] > 0:
		_toast("Abriss: %d Felder, +%d $ erstattet (50 %%)" % [p["count"], int(p["refund"])], 2.5)
	elif p["reason"] != "":
		_toast(p["reason"])
	return p["refund"]


# ---- Ziehen (Maus oder programmatisch aus Tests)

func begin_drag(cell: Vector2i) -> void:
	if cell.x < 0 or not (tool == Tool.ROAD or tool == Tool.RAIL or tool == Tool.DEMOLISH):
		return
	drag_start = cell
	dragging = true
	last_preview_cell = Vector2i(-99, -99)


## Nur für Tests/Screenshot: Cursor auf ein Feld setzen.
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


func _warehouse_cost(cell: Vector2i) -> int:
	return int(_cell_cost(cell, WAREHOUSE_COST))


func _warehouse_free(cell: Vector2i) -> bool:
	for c in _warehouse_cells(cell):
		if c.x >= GRID or c.y >= GRID or cell_to_building.has(c) or terrain.has(c):
			return false
	return true


func _build_warehouse(cell: Vector2i) -> void:
	if not _warehouse_free(cell):
		_toast("Hier ist kein Platz für ein Lager.")
		return
	var cost := _warehouse_cost(cell)
	if cost > money:
		_toast("Zu wenig Geld: %d $ nötig." % cost)
		return
	warehouse_count += 1
	for c in _warehouse_cells(cell):
		_clear_decor(c)
	var w := _add_building(Building.Kind.WAREHOUSE, "Lager %d" % warehouse_count, cell, Vector2i(2, 2), Color(0.55, 0.45, 0.6), 1.2, "")
	money -= cost
	w.set_owned()
	_connect_influence(w)
	_clear_preview()
	_toast("%s gebaut. Lager nehmen alles an und geben alles ab." % w.display_name)


func _create_line(a: Node3D, b: Node3D, filter: Array, type: String) -> void:
	var p: Dictionary = VEHICLES[type]
	if money < p["cost"]:
		_toast("Zu wenig Geld für %s (%d $)." % [p["name"], p["cost"]])
		return
	var astar: AStarGrid2D = astar_rail if type == "train" else astar_road
	var path := astar.get_id_path(a.anchor(), b.anchor())
	if path.is_empty():
		var net := "Gleis" if type == "train" else "Straßen"
		_toast("Keine %sverbindung zwischen %s und %s." % [net, a.display_name, b.display_name])
		return
	var params := p.duplicate()
	params["good_colors"] = GOOD_COLORS
	var v := Vehicle.new()
	add_child(v)
	v.setup(p["name"], a, b, filter, Array(path), _on_delivery, params)
	vehicles.append(v)
	money -= p["cost"]
	_connect_influence(a)
	_connect_influence(b)
	_refresh_lines()
	_toast("%s-Linie: %s → %s (%d Felder)" % [p["name"], a.display_name, b.display_name, path.size()])


func _clear_preview() -> void:
	for c in preview_root.get_children():
		c.queue_free()
	last_preview_cell = Vector2i(-99, -99)


func _ghost(c: Vector2i, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.9, 0.1, 0.9)
	mi.mesh = box
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var lift := 0.25 if terrain.get(c, -1) == Terrain.MOUNTAIN else 0.0
	var bb = cell_to_building.get(c)
	if bb != null and not city_streets.has(c):
		lift = minf(bb.height, 3.0) + 0.05   # über dem Gebäude, damit Rot sichtbar ist
	mi.position = Vector3(c.x + 0.5, 0.12 + lift, c.y + 0.5)
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
			_ghost(c, mat_ok if free and _distance_outside(c) <= 0.0 else mat_bad)
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


## Kosten / Erstattung und Grund am Cursor.
func _update_cursor_label() -> void:
	if not dragging or plan.is_empty() or hover_cell.x < 0:
		cursor_box.visible = false
		return
	cursor_box.visible = true
	var world := Vector3(hover_cell.x + 0.5, 0.0, hover_cell.y + 0.5)
	cursor_box.position = cam.unproject_position(world) + Vector2(22, 8)
	if plan.get("demolish", false):
		cursor_cost.text = "Abriss: %d Felder  +%d $ (50 %%)" % [plan["count"], int(plan["refund"])]
		cursor_cost.modulate = Color(1, 0.8, 0.5)
		cursor_reason.text = plan["reason"]
		return
	cursor_cost.text = "%s: %d Felder  %d $" % ["Gleis" if plan["rail"] else "Straße", plan["new_count"], plan["total"]]
	cursor_cost.modulate = Color(1, 1, 1) if plan["ok"] else Color(1, 0.6, 0.55)
	cursor_reason.text = "" if plan["ok"] else "✖ " + plan["reason"]


# ---------------------------------------------------------------- Wirtschaft & Meilensteine

func _on_delivery(v: Node3D, n: int) -> void:
	if n <= 0:
		return
	var factor := PRODUCT_FACTOR if v.good in PRODUCTS else 1.0
	var income: float = n * v.distance * PAY_PER_UNIT_FIELD * factor
	money += income
	earned += income
	v.income_total += income
	_float_text(v.position, "+%d $" % int(income))

	if v.dst.kind == Building.Kind.PROCESSOR:
		_complete(1)
	if v.dst.kind == Building.Kind.CITY:
		_complete(2)
	if earned >= OPEN_THRESHOLD:
		_complete(3)
	if v.dst == metropole:
		_complete(4)


func _complete(i: int) -> void:
	if milestones[i]["done"]:
		return
	milestones[i]["done"] = true
	_refresh_milestones()
	match i:
		1:
			_toast("Meilenstein: Erste Lieferung! Das Endprodukt bringt doppelt so viel – dafür brauchst du den Verarbeiter.")
		2:
			_toast("Meilenstein: Die erste Stadt wird versorgt!")
		3:
			owned_radius = OWNED_RADIUS_OPEN
			_refresh_influence()
			_toast("Dein Einfluss wächst! Die Metropole braucht fünf Güter – lange Strecken, lohnt sich ein Zug?", 7.0)
		4:
			_toast("Metropole beliefert – Ende des Prototyps. Nächster Schritt: zweite Kette erschließen.", 8.0)


func _float_text(pos: Vector3, text: String) -> void:
	var l := Label3D.new()
	l.text = text
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.font_size = 64
	l.pixel_size = 0.012
	l.modulate = Color(0.4, 1, 0.4)
	l.position = pos + Vector3(0, 1, 0)
	add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "position", l.position + Vector3(0, 2, 0), 1.2)
	tw.tween_callback(l.queue_free)


# ---------------------------------------------------------------- Loop

func _process(delta: float) -> void:
	if toast_time > 0.0:
		toast_time -= delta
		if toast_time <= 0.0:
			toast_label.text = ""
	_move_camera(delta)
	for v in vehicles:
		money -= v.upkeep * delta

	lines_timer -= delta
	if lines_timer <= 0.0:
		lines_timer = 1.0
		_refresh_lines()

	hover_cell = sim_hover if sim_hover_active else _mouse_cell()
	hover_marker.visible = hover_cell.x >= 0 and tool != Tool.NONE
	if hover_marker.visible:
		hover_marker.position = Vector3(hover_cell.x + 0.5, 0.05, hover_cell.y + 0.5)

	info_label.text = "Geld: %d $    Einnahmen: %d $    Fahrzeuge: %d    Werkzeug: %s" % [int(money), int(earned), vehicles.size(), TOOL_NAMES[tool]]
	info_label.modulate = Color(1, 0.5, 0.5) if money < 0 else Color(1, 1, 1)

	match tool:
		Tool.ROAD, Tool.RAIL:
			var what: String = "Gleis" if tool == Tool.RAIL else "Straße"
			if not dragging:
				hint_label.text = "%s: Maustaste am Startfeld drücken und zum Ziel ziehen (gerade + 45°). Blau = dein Einfluss (günstig)." % what
			else:
				_update_preview()
				hint_label.text = "%s: Loslassen = bauen · Rechtsklick/Esc = abbrechen · weiß = baubar, rot = nicht baubar" % what
		Tool.DEMOLISH:
			if dragging:
				_update_preview()
			hint_label.text = "Abriss: Fläche über eigene Straßen/Gleise ziehen, Loslassen = abreißen (50 % Erstattung) · Rechtsklick/Esc = abbrechen"
		Tool.WAREHOUSE:
			_update_preview()
			var wc: int = _warehouse_cost(hover_cell) if hover_cell.x >= 0 else 0
			hint_label.text = "Lager: Platz anklicken (2×2).  Kosten: %d $. Lager sammeln Güter von mehreren Linien und verteilen sie weiter." % wc
		Tool.BUY:
			var hb = cell_to_building.get(hover_cell) if hover_cell.x >= 0 else null
			var start := "Kaufe deine erste Firma, um loszulegen: " if owned.is_empty() else ""
			if hb != null and hb.visible and hb.price > 0 and not hb.owned:
				hint_label.text = "%s%s kaufen für %d $ – Klick." % [start, hb.display_name, _buy_cost(hb)]
			else:
				hint_label.text = "%sKlick auf Farm, Weide, Ölfeld, Forst, Mine oder Verarbeiter. Laden kannst du nur bei eigenen Firmen. Außerhalb deines Einflusses wird es teurer." % start
		Tool.TRUCK_LINE, Tool.TRAIN_LINE:
			var vname: String = "Zug" if tool == Tool.TRAIN_LINE else "Lkw"
			var need: String = "Gleis" if tool == Tool.TRAIN_LINE else "Straße"
			if line_src == null:
				hint_label.text = "%s-Linie: Quelle anklicken (Produzent, Verarbeiter oder Lager)." % vname
			else:
				hint_label.text = "%s-Linie: Ziel anklicken. Quelle und Ziel müssen per %s verbunden sein." % [vname, need]
		_:
			hint_label.text = "WASD bewegen · Q/E drehen · Mausrad zoomen · [B] Kaufen · [1] Straße · [2] Gleis · [3] Lager · [4] Lkw · [5] Zug · [X] Abriss · Klick auf Gebäude = Info"
	_update_cursor_label()


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
