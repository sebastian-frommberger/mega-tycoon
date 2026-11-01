extends RefCounted
## S-13: HQ-Gebäude. spawn(parent, pos, ghost) -> Node3D (Wurzel sitzt auf pos, Boden y = pos.y).
##   ghost = true : weiß, halbtransparent (Palette-Token "ghost"), dunkler Saum als Sockel (B-04), kein Schatten.
##   ghost = false: Firmenfarbe = Palette-Token "marker" (#FFC21A, S-08) als Korpus, dunkles Dach/Sockel, Fahne.
## Maße in Feldern (1 Feld = 1 Einheit): Fußabdruck 3x3, Höhe ca. 4. Höher als Stadthäuser, damit der Ghost auf der Karte
## lesbar bleibt. Für Aufrufer: free() des Rückgabeknotens entfernt alles, Materialien sind pro Aufruf neu (kein Cache-Leck).
## Mira ruft das aus _spawn_hq_building(city) auf; die Platzierung (Position, Wechsel, Freigabe) liegt nicht hier.

const PALETTE_PATH := "res://data/palette_s08.json"
const FALLBACK_COMPANY := Color8(255, 194, 26)
const FALLBACK_SAUM := Color8(15, 23, 32)
const FOOT := 3.0


static func company_color() -> Color:
	return _token("marker", FALLBACK_COMPANY)


static func _token(name: String, fb: Color) -> Color:
	var f := FileAccess.open(PALETTE_PATH, FileAccess.READ)
	if f == null:
		return fb
	var d = JSON.parse_string(f.get_as_text())
	if d is Dictionary:
		var src: Dictionary = d.get("tokens", {}) if name != "saum" else {"saum": d.get("saum", {})}
		if src.has(name) and src[name].has("godot"):
			var g: Array = src[name]["godot"]
			return Color(g[0], g[1], g[2], float(src[name].get("alpha", 1.0)))
	return fb


static func spawn(parent: Node3D, pos: Vector3, ghost: bool) -> Node3D:
	var root := Node3D.new()
	root.name = "HQGhost" if ghost else "HQBuilding"
	root.position = pos
	parent.add_child(root)
	var saum := _token("saum", FALLBACK_SAUM)
	var body: Color
	var dark: Color
	var accent: Color
	var glass: Color
	if ghost:
		body = _token("ghost", Color(1, 1, 1, 0.75))
		body.a = 0.62
		dark = body
		accent = body
		glass = body
	else:
		body = company_color()
		dark = saum.lightened(0.08)
		accent = Color(0.97, 0.94, 0.85)
		glass = Color(0.18, 0.24, 0.32)
	# Sockel (Saum, bleibt beim Ghost deckend: Kontur gegen Gras, B-04)
	_box(root, Vector3(FOOT + 0.5, 0.12, FOOT + 0.5), Vector3(0, 0.06, 0), saum, ghost, false)
	_box(root, Vector3(FOOT, 2.2, FOOT * 0.75), Vector3(0, 1.22, -0.1), body, ghost)                    # Hauptkörper
	_box(root, Vector3(FOOT * 0.62, 1.5, FOOT * 0.55), Vector3(0.2, 3.07, -0.25), body, ghost)          # Aufbau
	_box(root, Vector3(FOOT + 0.15, 0.16, FOOT * 0.75 + 0.15), Vector3(0, 2.4, -0.1), dark, ghost)      # Dachkante
	_box(root, Vector3(FOOT * 0.62 + 0.12, 0.14, FOOT * 0.55 + 0.12), Vector3(0.2, 3.88, -0.25), dark, ghost)
	_box(root, Vector3(1.0, 1.1, 0.5), Vector3(0, 0.67, 1.05), accent, ghost)                           # Eingangsvorbau
	if not ghost:
		for i in 3:                                                                                      # Fensterbänder
			_box(root, Vector3(FOOT + 0.02, 0.22, FOOT * 0.75 + 0.02), Vector3(0, 0.95 + i * 0.55, -0.1), glass, false, false)
		_box(root, Vector3(0.6, 0.8, 0.06), Vector3(0, 0.55, 1.33), glass, false, false)                # Tür
		_box(root, Vector3(0.05, 1.4, 0.05), Vector3(1.0, 4.65, -0.25), accent, false)                   # Fahnenmast
		_box(root, Vector3(0.65, 0.4, 0.04), Vector3(1.35, 5.1, -0.25), body, false, false)               # Fahne (Firmenfarbe)
	else:
		_box(root, Vector3(0.05, 1.4, 0.05), Vector3(1.0, 4.65, -0.25), body, true)
	return root


static func _box(parent: Node3D, size: Vector3, pos: Vector3, c: Color, ghost: bool, shadow := true) -> void:
	var mi := MeshInstance3D.new()
	var m := BoxMesh.new()
	m.size = size
	mi.mesh = m
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.roughness = 1.0
	if ghost and c.a < 0.99:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = mat
	mi.position = pos
	if ghost or not shadow:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
