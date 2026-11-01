extends RefCounted
## Spike F-04: SimWorld mit festem Tick (10 Hz Simulationszeit), Fahrzeugen, Blockreservierung,
## Lagern und Deadlock-Erkennung über den Warte-Graphen. Reine Daten, kein Node, kein Rendering.
##
## Änderungen Tag 4 (19.11., D9 / Daniel S5):
##   - Zulieferung: Fahrzeuge können an einem Lager abladen (unload_nodes); daraus folgt n_lkw je Lager.
##   - checksum(): deterministische Prüfsumme über den Sim-Zustand (Daniel S5, F-05-Gültigkeit).
##   - state_counts(): Zustandsverteilung (Last-Beschreibung für F-05).
##   - Profil je Tick (profile_usec): Fahrzeugschritt und Deadlock-Prüfung getrennt.
##   - Deadlock-Suche startet nur bei wartenden Fahrzeugen und nutzt Dictionary statt Array.has
##     (gleiches Ergebnis, weniger Arbeit bei vielen Fahrzeugen). ID-Liste wird nur bei Änderung neu sortiert.

const NetGraph := preload("res://net_graph.gd")
const Diagnostics := preload("res://diagnostics.gd")

const TICK_HZ := 10
const DEADLOCK_CONFIRM_TICKS := 5  # Zyklus muss so viele Ticks in Folge bestehen

enum VState { GEPLANT, UNTERWEGS, WARTET_BLOCK, WARTET_LADUNG, ENDE }

var graph = NetGraph.new()
var tick_count := 0
# vehicle_id -> Dictionary (siehe add_vehicle)
var vehicles: Dictionary = {}
# node_id -> {name, stock, produce_every, produce_amount, delivered_total}   (Lager an einem Knoten)
var stations: Dictionary = {}
# Erkannte Deadlocks: [{members, root_cause, tick_formed, tick_detected, ticks_to_detect}]
var deadlock_events: Array = []
# Profil des letzten Ticks in Mikrosekunden
var profile_usec := {"vehicles": 0, "deadlock": 0, "total": 0}

var _cycle_seen: Dictionary = {}  # key -> erster Tick, in dem dieser Zyklus gesehen wurde
var _cycle_reported: Dictionary = {}
var _sorted_ids: Array = []
var _ids_dirty := true


func add_station(node_id: int, station_name: String, stock: int, produce_every: int, produce_amount: int) -> void:
	stations[node_id] = {
		"name": station_name, "stock": stock,
		"produce_every": produce_every, "produce_amount": produce_amount, "delivered_total": 0,
	}


## route: Array[{edge, fwd}]. load_nodes: Knoten, an denen geladen werden muss (cargo_cap Einheiten).
## unload_nodes: Knoten (Lager), an denen die Ladung abgeladen wird (Zulieferung, zählt für n_lkw).
func add_vehicle(id: int, vname: String, route: Array, speed_mm_per_tick: int, start_tick: int = 0,
		load_nodes: Array = [], cargo_cap: int = 10, cyclic: bool = false, unload_nodes: Array = []) -> void:
	vehicles[id] = {
		"id": id, "name": vname, "route": route, "idx": 0, "pos": 0,
		"speed": speed_mm_per_tick, "state": VState.GEPLANT, "start_tick": start_tick,
		"held_block": -1, "wait_block": -1, "wait_since": -1,
		"load_nodes": load_nodes, "cargo_cap": cargo_cap, "cyclic": cyclic,
		"unload_nodes": unload_nodes, "cargo": 0,
		"runs": 0, "loaded_tick": -1, "waited_ticks_total": 0,
	}
	_ids_dirty = true


func sorted_ids() -> Array:
	if _ids_dirty:
		_sorted_ids = vehicles.keys()
		_sorted_ids.sort()
		_ids_dirty = false
	return _sorted_ids


func step() -> void:
	var t0 := Time.get_ticks_usec()
	tick_count += 1
	_produce()
	for id in sorted_ids():
		_step_vehicle(vehicles[id])
	var t1 := Time.get_ticks_usec()
	_detect_deadlocks()
	var t2 := Time.get_ticks_usec()
	profile_usec["vehicles"] = t1 - t0
	profile_usec["deadlock"] = t2 - t1
	profile_usec["total"] = t2 - t0


func run_ticks(n: int) -> void:
	for i in range(n):
		step()


func _produce() -> void:
	for node_id in stations:
		var s: Dictionary = stations[node_id]
		if s["produce_every"] > 0 and tick_count % int(s["produce_every"]) == 0:
			s["stock"] += int(s["produce_amount"])


func _step_vehicle(v: Dictionary) -> void:
	match v["state"]:
		VState.GEPLANT:
			if tick_count >= v["start_tick"]:
				_try_enter(v)
		VState.UNTERWEGS:
			var length: int = graph.edges[v["route"][v["idx"]]["edge"]]["length"]
			v["pos"] += v["speed"]
			if v["pos"] >= length:
				v["pos"] = length
				_arrive(v)
		VState.WARTET_BLOCK:
			v["waited_ticks_total"] += 1
			_try_enter(v)
		VState.WARTET_LADUNG:
			_try_load(v)
		VState.ENDE:
			pass


## Nächsten Block der Route reservieren. Hält der Halter schon der Fahrer selbst, gilt das als frei.
## Der alte Block wird erst beim erfolgreichen Eintritt freigegeben (Hold-and-Wait, deshalb Deadlock möglich).
func _try_enter(v: Dictionary) -> void:
	var step: Dictionary = v["route"][v["idx"]]
	var block_id: int = graph.block_of(step["edge"], step["fwd"])
	var b: Dictionary = graph.blocks[block_id]
	if b["holder"] == -1 or b["holder"] == v["id"]:
		if v["held_block"] != -1 and v["held_block"] != block_id:
			graph.blocks[v["held_block"]]["holder"] = -1
		b["holder"] = v["id"]
		b["holder_fwd"] = step["fwd"]
		v["held_block"] = block_id
		v["state"] = VState.UNTERWEGS
		v["pos"] = 0
		v["wait_block"] = -1
		v["wait_since"] = -1
	elif v["state"] != VState.WARTET_BLOCK:
		v["state"] = VState.WARTET_BLOCK
		v["wait_block"] = block_id
		v["wait_since"] = tick_count


func _arrive(v: Dictionary) -> void:
	var node_id: int = graph.step_to_node(v["route"][v["idx"]])
	v["idx"] += 1
	if v["cargo"] > 0 and v["unload_nodes"].has(node_id) and stations.has(node_id):
		var s: Dictionary = stations[node_id]
		s["stock"] += int(v["cargo"])
		s["delivered_total"] += int(v["cargo"])
		v["cargo"] = 0
	if v["load_nodes"].has(node_id) and stations.has(node_id):
		v["state"] = VState.WARTET_LADUNG
		v["wait_since"] = tick_count
		_try_load(v)
	else:
		_continue(v)


func _try_load(v: Dictionary) -> void:
	# Fahrzeug steht am Lagerknoten: letzter Schritt hat idx-1 gezeigt
	var node_id: int = graph.step_to_node(v["route"][v["idx"] - 1])
	var s: Dictionary = stations[node_id]
	if s["stock"] >= v["cargo_cap"]:
		s["stock"] -= v["cargo_cap"]
		v["cargo"] = v["cargo_cap"]
		v["loaded_tick"] = tick_count
		v["wait_since"] = -1
		_continue(v)


func _continue(v: Dictionary) -> void:
	if v["idx"] >= v["route"].size():
		v["runs"] += 1
		if v["cyclic"]:
			# geschlossene Route (Ende == Start): Rundkurs ohne Wenden, sonst Pendel (Route umkehren)
			if graph.step_to_node(v["route"][-1]) != graph.step_from_node(v["route"][0]):
				v["route"] = graph.reverse_route(v["route"])
			v["idx"] = 0
			_try_enter(v)
		else:
			if v["held_block"] != -1:
				graph.blocks[v["held_block"]]["holder"] = -1
				v["held_block"] = -1
			v["state"] = VState.ENDE
	else:
		_try_enter(v)


## IDs der Fahrzeuge, die an diesem Lager abladen (Zulieferer). D9: n_lkw = size().
func station_suppliers(node_id: int) -> Array:
	var out: Array = []
	for id in sorted_ids():
		if vehicles[id]["unload_nodes"].has(node_id):
			out.append(id)
	return out


# ---------- Warte-Graph und Deadlock-Erkennung ----------

## Auf wen wartet das Fahrzeug? Halter-ID oder -1 (wartet nicht auf ein anderes Fahrzeug).
func wait_target(v: Dictionary) -> int:
	if v["state"] == VState.WARTET_BLOCK:
		return int(graph.blocks[v["wait_block"]]["holder"])
	return -1


## Jedes Fahrzeug hat höchstens eine ausgehende Warte-Kante, der Graph ist also funktional.
## Zyklen findet das Entlanglaufen mit Besucht-Liste. Ergebnis: Array von Mitglieder-Arrays (kanonisch rotiert).
## Ergebnis identisch zur Fassung vom 18.11.; nur wartende Fahrzeuge starten einen Lauf, und
## Fahrzeuge, deren Lauf schon einmal zu Ende verfolgt wurde, werden nicht erneut verfolgt.
func find_wait_cycles() -> Array:
	var cycles: Array = []
	var seen_keys: Dictionary = {}
	var done: Dictionary = {}  # Fahrzeug -> Lauf von hier bereits abgeschlossen
	for start in sorted_ids():
		if vehicles[start]["state"] != VState.WARTET_BLOCK or done.has(start):
			continue
		var path: Array = []
		var on_path: Dictionary = {}
		var cur: int = start
		while cur != -1 and not on_path.has(cur) and not done.has(cur):
			path.append(cur)
			on_path[cur] = true
			cur = wait_target(vehicles[cur])
		if cur != -1 and on_path.has(cur):
			var cyc: Array = path.slice(path.find(cur))
			var m: int = cyc.find(cyc.min())
			cyc = cyc.slice(m) + cyc.slice(0, m)
			var key := ",".join(PackedStringArray(cyc.map(func(x): return str(x))))
			if not seen_keys.has(key):
				seen_keys[key] = true
				cycles.append(cyc)
		for p in path:
			done[p] = true
	return cycles


func _detect_deadlocks() -> void:
	var current: Dictionary = {}
	for cyc in find_wait_cycles():
		var key := ",".join(PackedStringArray(cyc.map(func(x): return str(x))))
		current[key] = cyc
		if not _cycle_seen.has(key):
			_cycle_seen[key] = tick_count
		var confirmed: bool = tick_count - int(_cycle_seen[key]) + 1 >= DEADLOCK_CONFIRM_TICKS
		if confirmed and not _cycle_reported.has(key):
			_cycle_reported[key] = true
			var formed := 0
			for vid in cyc:
				formed = maxi(formed, int(vehicles[vid]["wait_since"]))
			deadlock_events.append({
				"members": cyc.duplicate(),
				"root_cause": Diagnostics.classify_cycle(self, cyc),
				"tick_formed": formed,
				"tick_detected": tick_count,
				"ticks_to_detect": tick_count - formed,
			})
	for key in _cycle_seen.keys():
		if not current.has(key):
			_cycle_seen.erase(key)
			_cycle_reported.erase(key)


## Öffentliche Diagnose-API (Spike): siehe diagnostics.gd
func get_wait_chain(vehicle_id: int) -> Dictionary:
	return Diagnostics.build_wait_chain(self, vehicle_id)


## Position eines Fahrzeugs in mm (Interpolation entlang der Kante, ganzzahlig).
func vehicle_pos(v: Dictionary) -> Vector2i:
	var idx: int = mini(v["idx"], v["route"].size() - 1)
	var step: Dictionary = v["route"][idx]
	if v["state"] == VState.UNTERWEGS:
		var pa: Vector2i = graph.nodes[graph.step_from_node(step)]["pos"]
		var pb: Vector2i = graph.nodes[graph.step_to_node(step)]["pos"]
		var length: int = graph.edges[step["edge"]]["length"]
		# int64 rechnen: Vector2i hat int32-Komponenten, (pb - pa) * pos läuft ab ~46 m Kantenlänge über
		# (gefunden beim float32-Check 23.11.; Fassung 18.11. lieferte für fahrende Fahrzeuge falsche Orte)
		var p: int = int(v["pos"])
		return Vector2i(pa.x + (pb.x - pa.x) * p / length, pa.y + (pb.y - pa.y) * p / length)
	if v["state"] == VState.WARTET_LADUNG or v["state"] == VState.ENDE:
		return graph.nodes[graph.step_to_node(v["route"][v["idx"] - 1])]["pos"]
	return graph.nodes[graph.step_from_node(step)]["pos"]


# ---------- Prüfsumme und Last-Beschreibung (Daniel S5, F-05) ----------

## Deterministische Prüfsumme über Tick, Fahrzeuge (Zustand, Routenindex, Position, Ladung, Halter)
## und Lager (Bestand). FNV-1a-Variante auf Ganzzahlen (int64, Überlauf gewollt); kein kryptografischer Hash.
func checksum() -> int:
	var h: int = -3750763034362895579  # FNV-Offset 0xcbf29ce484222325 als signed int64
	var prime: int = 1099511628211
	h = (h ^ tick_count) * prime
	for id in sorted_ids():
		var v: Dictionary = vehicles[id]
		for x in [id, int(v["state"]), int(v["idx"]), int(v["pos"]), int(v["cargo"]), int(v["held_block"]), int(v["wait_block"]), int(v["runs"]), int(v["waited_ticks_total"])]:
			h = (h ^ (x & 0xFFFFFFFF)) * prime
	var snodes: Array = stations.keys()
	snodes.sort()
	for n in snodes:
		h = (h ^ (int(stations[n]["stock"]) & 0xFFFFFFFF)) * prime
	return h


## Zustandsverteilung {GEPLANT, UNTERWEGS, WARTET_BLOCK, WARTET_LADUNG, ENDE} -> Anzahl.
func state_counts() -> Dictionary:
	var out := {"GEPLANT": 0, "UNTERWEGS": 0, "WARTET_BLOCK": 0, "WARTET_LADUNG": 0, "ENDE": 0}
	var names: Array = VState.keys()
	for id in vehicles:
		out[names[int(vehicles[id]["state"])]] += 1
	return out
