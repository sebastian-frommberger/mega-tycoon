extends Node3D
## Gebäude aus dem Prototyp, Grey-Box: grauer Quader, oben eine Kappe in der Farbe des Ausgangsguts.
## Bestände, Lizenz und Ertrag liegen in economy.gd (Standort `site`, Lager-Slot `station`), nicht hier.

enum Kind { PRODUCER, PROCESSOR, CITY, WAREHOUSE, SINK, INERT }

var kind: int = Kind.PRODUCER
var display_name := ""
var map_id := ""               # ID aus slice_map.json
var typ := ""                  # Industrie-ID aus economy_slice.json (oder "holzfaeller", "stadt", "lager")
var cell := Vector2i.ZERO
var footprint := Vector2i(2, 2)
var height := 1.0
var label: Label3D
var site := -1                 # economy.gd Standort
var station := -1              # EcoShim Lager-Slot
var node_id := -1
var out_good := ""
var in_goods: Array = []
var custom_cells: Array = []   # Städte: unregelmäßige Fläche
var city_stage := ""
var city_pop := 0
var owned := false             # Lager (eigener Bau)
var licence_marker: MeshInstance3D

const GREY := Color(0.62, 0.63, 0.66)
# D-07 BUG-4: ca. 25 % kleiner (Stadt ~14 px, Industrie ~11 px bei 900 px Höhe); k = Bildschirm-px je Label-Einheit ~ pixel_size * 560
const LABEL_PX_CITY := 0.00080
const LABEL_PX_IND := 0.00064


func setup(p_kind: int, p_name: String, p_cell: Vector2i, p_size: Vector2i, cap_color: Color, p_height: float) -> void:
	kind = p_kind
	display_name = p_name
	cell = p_cell
	footprint = p_size
	height = p_height
	position = center()
	if kind == Kind.WAREHOUSE:
		_add_box(Vector3(footprint.x - 0.15, height * 0.7, footprint.y - 0.15), Vector3(0, height * 0.35, 0), GREY.darkened(0.15))
		_add_box(Vector3(footprint.x - 0.05, height * 0.3, footprint.y * 0.4), Vector3(0, height * 0.85, 0), cap_color)
	elif kind != Kind.CITY:
		var body := GREY if kind != Kind.INERT else GREY.darkened(0.35)
		_add_box(Vector3(footprint.x - 0.15, height, footprint.y - 0.15), Vector3(0, height * 0.5, 0), body)
		_add_box(Vector3(footprint.x - 0.6, 0.25, footprint.y - 0.6), Vector3(0, height + 0.125, 0), cap_color)

	# S-11: kleiner und schlanker als zuvor (Stadt ~17 px, Industrie ~12 px Schrift bei 1600x900), dezenter Saum;
	# Stil (Font, Farbe, Saum) setzt main._style_map_labels, Ausblendung nach Zoom main._update_label_lod.
	label = Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true       # Boden/Wege verdecken den Text sonst; HUD-Überdeckung löst main._place_map_labels (Ausblenden)
	label.render_priority = -1       # Weltlabels hinter Zielpfeil und Fähnchen (Saum noch eine Stufe dahinter)
	label.outline_render_priority = -2
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.font_size = 40
	label.fixed_size = true          # Bildschirmgröße unabhängig vom Zoom (Lesbarkeit bei 512²)
	label.pixel_size = LABEL_PX_CITY if kind == Kind.CITY else LABEL_PX_IND
	label.outline_size = 7
	label.line_spacing = -4.0
	label.position = Vector3(0, 0.05, 0)    # D-07 BUG-4: Text UNTER dem Gebäude (Versatz je Frame in main._place_map_labels), Pfeil/Fähnchen oben frei
	add_child(label)

	# Lizenz-Fähnchen (Palette S-08 status_ok mit Saum)
	licence_marker = MeshInstance3D.new()
	var fb := BoxMesh.new()
	fb.size = Vector3(0.6, 0.6, 0.6)
	licence_marker.mesh = fb
	var fm := StandardMaterial3D.new()
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fm.albedo_color = Color(0.282, 0.878, 0.541)
	licence_marker.material_override = fm
	licence_marker.position = Vector3(0, height + 0.6, 0)
	licence_marker.visible = false
	add_child(licence_marker)


func _add_box(size: Vector3, pos: Vector3, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mi.material_override = mat
	mi.position = pos
	add_child(mi)


func center() -> Vector3:
	return Vector3(cell.x + footprint.x * 0.5, 0.0, cell.y + footprint.y * 0.5)


## Zelle, über die Fahrzeuge das Gebäude anfahren (Mitte).
func anchor() -> Vector2i:
	return cell + footprint / 2


func cells() -> Array:
	if not custom_cells.is_empty():
		return custom_cells
	var out := []
	for x in footprint.x:
		for y in footprint.y:
			out.append(cell + Vector2i(x, y))
	return out


## Kann hier geladen werden (Rohstoff, Verarbeiter mit Ausgang, Lager)?
func provides() -> bool:
	return kind == Kind.PRODUCER or kind == Kind.PROCESSOR or kind == Kind.WAREHOUSE


func is_industry() -> bool:
	return kind == Kind.PRODUCER or kind == Kind.PROCESSOR or kind == Kind.SINK
