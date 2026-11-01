extends Node3D
## Ein Gebäude als farbiger Quader: Produzent, Verarbeiter, Stadt oder Lager.

enum Kind { PRODUCER, PROCESSOR, CITY, WAREHOUSE }

const WAREHOUSE_CAP := 200  # pro Gut

var kind: int = Kind.PRODUCER
var display_name := ""
var cell := Vector2i.ZERO
var footprint := Vector2i(2, 2)
var region := ""
var input_good := ""
var output_good := ""
var demands: Array = []
var rate := 1.0
var max_stock := 40.0
var stock_in := 0.0
var stock_out := 0.0
var stocks := {}       # nur Lager: Gut -> Menge
var delivered := {}    # nur Stadt: Gut -> Menge
var height := 1.0
var label: Label3D
var price := 0           # Kaufpreis (0 = nicht käuflich, z. B. Stadt)
var owned := false
var owner_marker: MeshInstance3D
var custom_cells: Array = []   # Städte: unregelmäßige Fläche statt Rechteck


func setup(p_kind: int, p_name: String, p_cell: Vector2i, p_size: Vector2i, color: Color, p_height: float, p_region: String) -> void:
	kind = p_kind
	display_name = p_name
	cell = p_cell
	footprint = p_size
	height = p_height
	region = p_region
	position = center()

	if kind == Kind.CITY:
		pass  # Straßen und Häuser baut main.gd
	elif kind == Kind.WAREHOUSE:
		# Lager = flache Halle mit Dach
		_add_box(Vector3(footprint.x - 0.15, height * 0.7, footprint.y - 0.15), Vector3(0, height * 0.35, 0), color)
		_add_box(Vector3(footprint.x - 0.05, height * 0.3, footprint.y * 0.4), Vector3(0, height * 0.85, 0), color.darkened(0.3))
	else:
		_add_box(Vector3(footprint.x - 0.15, height, footprint.y - 0.15), Vector3(0, height * 0.5, 0), color)

	label = Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.font_size = 48
	label.pixel_size = 0.03 if kind == Kind.CITY else 0.014
	label.outline_size = 10
	label.position = Vector3(0, height + 0.9, 0)
	add_child(label)

	# Fähnchen auf eigenen Firmen
	owner_marker = MeshInstance3D.new()
	var fb := BoxMesh.new()
	fb.size = Vector3(0.35, 0.35, 0.35)
	owner_marker.mesh = fb
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.2, 0.55, 1.0)
	fm.emission_enabled = true
	fm.emission = Color(0.2, 0.55, 1.0)
	owner_marker.material_override = fm
	owner_marker.position = Vector3(0, height + 0.35, 0)
	owner_marker.visible = false
	add_child(owner_marker)
	_update_label()


func set_owned() -> void:
	owned = true
	owner_marker.visible = true


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


func _process(delta: float) -> void:
	match kind:
		Kind.PRODUCER:
			stock_out = minf(max_stock, stock_out + rate * delta)
		Kind.PROCESSOR:
			var amt := minf(stock_in, rate * delta)
			amt = minf(amt, max_stock - stock_out)
			stock_in -= amt
			stock_out += amt
	_update_label()


## Kann dieses Gebäude etwas abgeben?
func provides() -> bool:
	return output_good != "" or kind == Kind.WAREHOUSE


func stock_of(good: String) -> int:
	if kind == Kind.WAREHOUSE:
		return int(stocks.get(good, 0))
	if good == output_good:
		return int(floor(stock_out))
	return 0


## Das Gut aus filter mit dem größten Bestand (filter leer = alles).
func best_good(filter: Array) -> String:
	var best := ""
	var best_n := 0
	var candidates: Array = filter
	if candidates.is_empty():
		candidates = stocks.keys() if kind == Kind.WAREHOUSE else [output_good]
	for g in candidates:
		var n := stock_of(g)
		if n > best_n:
			best = g
			best_n = n
	return best


func take(good: String, amount: int) -> int:
	var n := mini(amount, stock_of(good))
	if n <= 0:
		return 0
	if kind == Kind.WAREHOUSE:
		stocks[good] = stocks[good] - n
	else:
		stock_out -= n
	return n


func accepts(good: String) -> bool:
	match kind:
		Kind.PROCESSOR:
			return good == input_good
		Kind.CITY:
			return good in demands
		Kind.WAREHOUSE:
			return true
	return false


func deliver(good: String, n: int) -> void:
	match kind:
		Kind.PROCESSOR:
			stock_in += n
		Kind.CITY:
			delivered[good] = delivered.get(good, 0) + n
		Kind.WAREHOUSE:
			stocks[good] = mini(WAREHOUSE_CAP, stocks.get(good, 0) + n)


func _update_label() -> void:
	var own := "" if owned or price == 0 else "\nzu kaufen: %d $" % price
	match kind:
		Kind.PRODUCER:
			label.text = "%s\n%s: %d%s" % [display_name, output_good, int(stock_out), own]
		Kind.PROCESSOR:
			label.text = "%s\n%s %d  →  %s %d%s" % [display_name, input_good, int(stock_in), output_good, int(stock_out), own]
		Kind.CITY:
			var parts := []
			for g in demands:
				parts.append("%s %d" % [g, delivered.get(g, 0)])
			label.text = "%s\nbraucht: %s" % [display_name, ", ".join(parts)]
		Kind.WAREHOUSE:
			var parts := []
			for g in stocks:
				if stocks[g] > 0:
					parts.append("%s %d" % [g, stocks[g]])
			label.text = "%s\n%s" % [display_name, ", ".join(parts) if parts.size() > 0 else "leer"]
