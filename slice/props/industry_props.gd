extends RefCounted
## S-13: Industrie-Props aus Kenney City Kit Industrial (CC0) plus wenigen Primitiven. Je Industrie eine erkennbare Silhouette
## auf dunkler Bodenplatte (Kontrast zum Gras >= 3:1, S-08). Ein Aufruf je Gebäude (12 Stück), keine Schatten an Kleinteilen;
## Meshes und Materialien werden geteilt. Schlägt das GLB-Laden fehl (Export ohne *.glb), fehlen nur die Kenney-Teile,
## die Primitive bleiben stehen; build() liefert dann trotzdem true, solange die Typ-Silhouette erkennbar bleibt.
## Aufruf: building.gd setup() -> IndustryProps.build(self, typ, cap_color).  1 Feld = 1 Szene-Einheit.

const KENNEY_DIR := "res://props/kenney/"
const COLORMAP := "res://props/kenney/Textures/colormap.png"
const DeclutterScript := preload("res://props/label_declutter.gd")
const KenneyLoader := preload("res://props/kenney_loader.gd")

static var _models := {}      # name -> ArrayMesh|null
static var _mats := {}        # Color-Key -> StandardMaterial3D
static var _tex_mat: StandardMaterial3D

const SCALE := {"getreidefarm": 1.25, "muehle": 1.7, "kohlemine": 2.4, "erzmine": 2.4, "kraftwerk": 1.6, "stahlwerk": 1.6,
	"werkzeugfabrik": 1.6, "holzfaeller": 1.7}
const TOP := {"getreidefarm": 2.6, "muehle": 3.9, "kohlemine": 5.3, "erzmine": 2.6, "kraftwerk": 4.0, "stahlwerk": 3.5,
	"werkzeugfabrik": 3.6, "holzfaeller": 1.9}      # Oberkante inkl. Skalierung, für das Lizenz-Fähnchen

const PAD := {   # Bodenplatte je Typ (alle dunkel: Luminanz < 0,05 -> Kontrast gegen Gras > 3:1)
	"getreidefarm": Color(0.17, 0.11, 0.06), "muehle": Color(0.18, 0.15, 0.12), "kohlemine": Color(0.07, 0.07, 0.08),
	"erzmine": Color(0.16, 0.08, 0.05), "kraftwerk": Color(0.12, 0.13, 0.15), "stahlwerk": Color(0.12, 0.12, 0.14),
	"werkzeugfabrik": Color(0.12, 0.13, 0.15), "holzfaeller": Color(0.17, 0.11, 0.06)}


## Ersetzt die Grey-Box. Gibt false zurück für unbekannte Typen (dann bleibt die Grey-Box).
static func build(b: Node3D, typ: String, cap_color: Color) -> bool:
	if not PAD.has(typ):
		return false
	var fp: Vector2i = b.footprint
	# Bodenplatte ungeskaliert, etwas über den Fußabdruck hinaus (Kontrast gegen Gras, auch bei Fernzoom)
	var pad_root := Node3D.new()
	pad_root.name = "Pad"
	b.add_child(pad_root)
	_box(pad_root, Vector3(fp.x * SCALE.get(typ, 1.7) * 0.8, 0.03, fp.y * SCALE.get(typ, 1.7) * 0.8), Vector3(0, 0.015, 0), PAD[typ], false)
	# Props überhöht: bei Kartenzoom ist ein 3x3-Gebäude nur ~30 px breit, die Silhouette muss dort noch lesbar sein
	var root := Node3D.new()
	root.name = "Props"
	root.scale = Vector3.ONE * SCALE.get(typ, 1.7)
	b.add_child(root)
	match typ:
		"getreidefarm": _getreidefarm(root, fp)
		"muehle": _muehle(root, fp)
		"kohlemine": _kohlemine(root, fp)
		"erzmine": _erzmine(root, fp)
		"kraftwerk": _kraftwerk(root, fp)
		"stahlwerk": _stahlwerk(root, fp)
		"werkzeugfabrik": _werkzeugfabrik(root, fp)
		"holzfaeller": _holzfaeller(root, fp)
	# kleines Gutfarben-Schild vorn links (Ausgangsgut, wie die Kappe der Grey-Box)
	_box(root, Vector3(0.45, 0.22, 0.45), Vector3(-fp.x * 0.5 + 0.45, 0.14, fp.y * 0.5 - 0.45), cap_color, false)

	_ensure_declutter(b)
	return true


static func top(typ: String, fallback: float) -> float:
	return TOP.get(typ, fallback)


# ------------------------------------------------------------------ Typen

static func _getreidefarm(r: Node3D, fp: Vector2i) -> void:
	var gold := Color(0.88, 0.70, 0.18)
	for i in 3:                                   # Getreidestreifen (Feld), erhöht auf dunkler Erde
		_box(r, Vector3(fp.x - 0.9, 0.12, 0.55), Vector3(0.1, 0.09, 0.2 + i * 0.85), gold.darkened(0.12 * i), false)
	_box(r, Vector3(1.5, 0.9, 1.0), Vector3(-1.2, 0.48, -1.55), Color(0.62, 0.22, 0.17))        # Scheune
	_prism(r, Vector3(1.7, 0.55, 1.2), Vector3(-1.2, 1.17, -1.55), Color(0.25, 0.16, 0.12))
	_cyl(r, 0.34, 0.34, 1.7, Vector3(0.4, 0.88, -1.6), Color(0.78, 0.78, 0.75))                 # Silo
	_cyl(r, 0.0, 0.38, 0.4, Vector3(0.4, 1.9, -1.6), Color(0.55, 0.57, 0.6))
	_cyl(r, 0.2, 0.2, 0.9, Vector3(1.2, 0.48, -1.6), Color(0.78, 0.78, 0.75))                   # kleiner Silo


static func _muehle(r: Node3D, fp: Vector2i) -> void:
	_cyl(r, 0.46, 0.66, 1.6, Vector3(0, 0.83, -0.1), Color(0.82, 0.78, 0.70))                   # Turm
	_cyl(r, 0.0, 0.62, 0.7, Vector3(0, 1.98, -0.1), Color(0.40, 0.22, 0.14))                    # Kegeldach
	_box(r, Vector3(0.8, 0.5, 0.6), Vector3(0.9, 0.28, 0.7), Color(0.70, 0.52, 0.40))           # Anbau
	var hub := Vector3(0, 1.55, 0.62)
	_cyl(r, 0.12, 0.12, 0.3, hub, Color(0.3, 0.2, 0.14), Vector3(90, 0, 0))
	for i in 4:                                                                                  # Flügelkreuz
		var blade := _box(r, Vector3(0.22, 1.7, 0.04), hub + Vector3(0, 0, 0.1), Color(0.93, 0.9, 0.82))
		blade.rotation_degrees = Vector3(0, 0, 45.0 + i * 90.0 + 12.0)
		blade.position = hub + Vector3(0, 0, 0.12) + blade.basis * Vector3(0, 0.85, 0)


static func _kohlemine(r: Node3D, fp: Vector2i) -> void:
	var steel := Color(0.36, 0.42, 0.50)
	for s in [-1.0, 1.0]:                                                                        # Fördergerüst (A-Rahmen)
		var leg := _box(r, Vector3(0.12, 2.1, 0.12), Vector3(s * 0.35, 1.0, -0.2), steel)
		leg.rotation_degrees = Vector3(0, 0, -s * 14.0)
	_box(r, Vector3(0.9, 0.1, 0.18), Vector3(0, 2.0, -0.2), steel)
	_cyl(r, 0.3, 0.3, 0.1, Vector3(0, 2.1, -0.2), Color(1.0, 0.76, 0.1), Vector3(0, 0, 90))      # Seilscheibe (Amber)
	_box(r, Vector3(1.0, 0.6, 0.8), Vector3(-0.8, 0.33, 0.7), Color(0.5, 0.36, 0.26))           # Schuppen
	_cyl(r, 0.0, 0.55, 0.5, Vector3(0.8, 0.28, 0.75), Color(0.03, 0.03, 0.035))                  # Kohlehaufen
	_rock(r, Vector3(0.9, 0.0, -0.85), 0.8, 20.0)


static func _erzmine(r: Node3D, fp: Vector2i) -> void:
	_cyl(r, 0.35, 1.2, 1.1, Vector3(0, 0.58, -0.4), Color(0.45, 0.41, 0.36))                     # Felsmassiv
	_rock(r, Vector3(-0.9, 0.0, -0.5), 0.9, 70.0)
	var wood := Color(0.45, 0.3, 0.15)                                                           # Stollenportal
	_box(r, Vector3(0.14, 0.8, 0.14), Vector3(-0.35, 0.45, 0.45), wood)
	_box(r, Vector3(0.14, 0.8, 0.14), Vector3(0.35, 0.45, 0.45), wood)
	_box(r, Vector3(0.95, 0.14, 0.18), Vector3(0, 0.9, 0.45), wood)
	_box(r, Vector3(0.5, 0.65, 0.1), Vector3(0, 0.38, 0.4), Color(0.02, 0.02, 0.02))             # Stollen dunkel
	_cyl(r, 0.0, 0.5, 0.45, Vector3(0.95, 0.26, 0.8), Color(0.66, 0.40, 0.30))                   # Erzhaufen
	_cyl(r, 0.0, 0.38, 0.35, Vector3(1.25, 0.2, 0.35), Color(0.66, 0.40, 0.30))


static func _kraftwerk(r: Node3D, fp: Vector2i) -> void:
	_kenney(r, "building-a", Vector3(-0.3, 0.03, 0.4), 1.25)
	_kenney(r, "chimney-large", Vector3(1.0, 0.03, -0.6), 1.5)
	_kenney(r, "chimney-large", Vector3(0.3, 0.03, -0.9), 1.5)
	_kenney(r, "detail-tank", Vector3(-1.3, 0.03, -0.8), 1.6)


static func _stahlwerk(r: Node3D, fp: Vector2i) -> void:
	_kenney(r, "building-a", Vector3(-0.3, 0.03, 0.2), 1.55)
	_kenney(r, "chimney-large", Vector3(1.3, 0.03, -1.1), 1.2)
	_kenney(r, "detail-tank", Vector3(1.4, 0.03, 0.9), 1.8)
	var glow := _box(r, Vector3(1.2, 0.5, 0.06), Vector3(-0.3, 0.5, 1.15), Color(1.0, 0.45, 0.1), false)   # Ofentor
	(glow.material_override as StandardMaterial3D).emission_enabled = true
	(glow.material_override as StandardMaterial3D).emission = Color(1.0, 0.4, 0.05)
	(glow.material_override as StandardMaterial3D).emission_energy_multiplier = 0.6


static func _werkzeugfabrik(r: Node3D, fp: Vector2i) -> void:
	_kenney(r, "building-f", Vector3(-0.2, 0.03, 0.1), 1.35)
	for i in 3:                                                                                  # Sägezahndach
		_prism(r, Vector3(0.7, 0.45, 1.9), Vector3(-1.0 + i * 0.75, 1.95, 0.0), Color(0.25, 0.45, 0.9))
	_box(r, Vector3(2.2, 0.16, 0.06), Vector3(-0.2, 0.9, 0.95), Color(0.25, 0.45, 0.9), false)    # Werkzeug-Blau als Band


static func _holzfaeller(r: Node3D, fp: Vector2i) -> void:
	_box(r, Vector3(0.9, 0.55, 0.8), Vector3(-0.7, 0.3, -0.7), Color(0.5, 0.34, 0.2))
	_prism(r, Vector3(1.05, 0.35, 0.95), Vector3(-0.7, 0.72, -0.7), Color(0.28, 0.17, 0.1))
	for i in 3:                                                                                  # Stammstapel
		for j in 2 - (i % 2):
			_cyl(r, 0.14, 0.14, 1.3, Vector3(0.55 + j * 0.3 + (i % 2) * 0.15, 0.17 + i * 0.22, 0.5), Color(0.55, 0.38, 0.2), Vector3(0, 0, 90))


# ------------------------------------------------------------------ Bausteine

static func _mat(c: Color) -> StandardMaterial3D:
	var k := c.to_html()
	if not _mats.has(k):
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = 1.0
		_mats[k] = m
	return _mats[k]


static func _box(parent: Node3D, size: Vector3, pos: Vector3, c: Color, shadow := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var m := BoxMesh.new()
	m.size = size
	mi.mesh = m
	mi.material_override = _mat(c)
	mi.position = pos
	if not shadow:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


static func _prism(parent: Node3D, size: Vector3, pos: Vector3, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var m := PrismMesh.new()
	m.size = size
	mi.mesh = m
	mi.material_override = _mat(c)
	mi.position = pos
	parent.add_child(mi)
	return mi


static func _cyl(parent: Node3D, r_top: float, r_bot: float, h: float, pos: Vector3, c: Color, rot_deg := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var m := CylinderMesh.new()
	m.top_radius = r_top
	m.bottom_radius = r_bot
	m.height = h
	m.radial_segments = 12
	m.rings = 1
	mi.mesh = m
	mi.material_override = _mat(c)
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi


static func _rock(parent: Node3D, pos: Vector3, scale: float, yaw: float) -> void:
	_kenney(parent, "rock_largeA", pos, scale * 1.6, yaw)


## Kenney-Modell (GLB zur Laufzeit, Textur per res://-Load, damit sie im Export aus dem Import kommt).
static func _kenney(parent: Node3D, name: String, pos: Vector3, scale: float, yaw := 0.0) -> void:
	var mesh := _model(name)
	if mesh == null:
		return
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.scale = Vector3.ONE * scale
	mi.rotation_degrees.y = yaw
	if name == "rock_largeA":
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)


static func _model(name: String) -> ArrayMesh:
	if _models.has(name):
		return _models[name]
	var mesh: ArrayMesh = null
	var root: Node = KenneyLoader.load_root(KENNEY_DIR + name + ".glb")          # B-2: PCK-tauglich
	if root != null:
		var found := _first_mesh(root)
		if found != null and found.mesh is ArrayMesh:
			mesh = (found.mesh as ArrayMesh).duplicate()
			for i in mesh.get_surface_count():
				mesh.surface_set_material(i, _tex_material(mesh.surface_get_material(i)))
		root.free()
	_models[name] = mesh
	return mesh


static func _tex_material(src: Material) -> Material:
	if src is BaseMaterial3D and (src as BaseMaterial3D).albedo_texture != null:
		if _tex_mat == null:
			_tex_mat = StandardMaterial3D.new()
			_tex_mat.roughness = 1.0
			_tex_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			_tex_mat.albedo_texture = load(COLORMAP) if ResourceLoader.exists(COLORMAP) else (src as BaseMaterial3D).albedo_texture
		return _tex_mat
	if src is BaseMaterial3D:                      # Nature-Kit-Felsen: Vertexfarben/Albedo, auf Palette-Grau (berg_stein)
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.50, 0.45, 0.38)
		m.roughness = 1.0
		return m
	return src


static func _first_mesh(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D:
		return n
	for c in n.get_children():
		var r := _first_mesh(c)
		if r != null:
			return r
	return null


## Ein Declutter-Knoten je Karte (Kind des Parents der Gebäude), damit main.gd unberührt bleibt.
static func _ensure_declutter(b: Node3D) -> void:
	var p := b.get_parent()
	if p != null and p.get_node_or_null("LabelDeclutter") == null:
		var d := Node.new()
		d.set_script(DeclutterScript)
		d.name = "LabelDeclutter"
		p.add_child(d)
