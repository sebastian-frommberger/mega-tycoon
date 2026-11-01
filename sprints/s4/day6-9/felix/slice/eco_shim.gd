extends RefCounted
## F-14: Adapter zwischen economy.gd (F-16, unverändert aus day1-5/felix/core) und den Prototyp-Fahrzeugen.
## economy.gd erwartet die Schnittstelle von sim_world.gd (SoA-Kern). Für R1 fahren die Prototyp-Fahrzeuge
## (vehicle.gd); dieser Shim stellt nur die Felder bereit, die economy.gd liest oder schreibt:
##   graph.nodes[id]["pos"] (mm), add_station(), _station_of, st_stock, st_delivered, tick_count, v_id, v_cargo.
## Entscheidung (dokumentiert in felix.md): SoA-Kern erst, wenn die Fahrzeugzahlen es verlangen (S5+).

class Graph:
	var nodes: Dictionary = {}   # id -> {"pos": Vector2i (mm), "label": String}

var graph := Graph.new()
var economy = null
var tick_count := 0
var _station_of: Dictionary = {}       # node_id -> Lager-Slot k
var st_node := PackedInt32Array()
var st_stock := PackedInt32Array()
var st_delivered := PackedInt32Array()
var v_id := PackedInt32Array()          # Fahrzeug-Slot i -> Fahrzeug-ID
var v_cargo := PackedInt32Array()       # Fahrzeug-Slot i -> Ladung (Einheiten)


func add_node(id: int, pos_mm: Vector2i, label: String) -> void:
	graph.nodes[id] = {"pos": pos_mm, "label": label}


func add_station(node_id: int, _station_name: String, stock: int, _every: int, _amount: int) -> void:
	if _station_of.has(node_id):
		st_stock[_station_of[node_id]] = stock
		return
	_station_of[node_id] = st_node.size()
	st_node.append(node_id)
	st_stock.append(stock)
	st_delivered.append(0)


## Neuer Fahrzeug-Slot; gibt den Slot-Index zurück.
func add_vehicle_slot(vid: int) -> int:
	v_id.append(vid)
	v_cargo.append(0)
	return v_id.size() - 1
