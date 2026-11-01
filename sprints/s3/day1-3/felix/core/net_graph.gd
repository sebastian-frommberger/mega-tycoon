extends RefCounted
## Spike F-04: Graph aus Knoten und Kanten, Blöcke, Signale, eigenes deterministisches A*.
## Reine Daten, Einheit überall mm (ganzzahlig). Kanten sind Geraden (keine Polylines im Spike).
##
## F-10 (Sprint 3): Der Graph ist nur noch statische Struktur (Aufbau, A*, Diagnose-Orte). Der Laufzeit-
## zustand der Blöcke (Halter, Richtung) liegt als PackedInt32Array im SimWorld (SoA). Die Eigenschaft
## `blocks` bleibt als Lesesicht für bestehende Aufrufer (Tests, F-06, Daniels Lauf): sie liefert
## block_data plus holder/holder_fwd aus dem SimWorld, gepuffert je Sim-Version. Schreiben in diese
## Sicht hat keine Wirkung. Heißer Pfad und Diagnose lesen block_data + SimWorld.block_holder().

# node_id -> {pos: Vector2i, name: String}
var nodes: Dictionary = {}
# edge_id -> {a: int, b: int, length: int, single: bool, block_fwd: int, block_rev: int, sig_fwd: int, sig_rev: int}
var edges: Dictionary = {}
# block_id -> {edge: int, single: bool, center: Vector2i}   (statisch)
var block_data: Dictionary = {}
# Lesesicht (Kompatibilität): block_id -> {edge, single, center, holder, holder_fwd}; holder = Fahrzeug-ID
var blocks: Dictionary:
	get = _get_blocks_view
# signal_id -> {node: int, block: int, edge: int, fwd: bool}
var signals: Dictionary = {}

var _adj: Dictionary = {}  # node_id -> Array[{edge, to, fwd}]
var _next_block := 1
var _next_signal := 1
var _holder_src: WeakRef = null  # SimWorld, gesetzt von SimWorld._init()
var _view_cache: Dictionary = {}
var _view_ver := -1


func next_block_id() -> int:
	return _next_block


func _get_blocks_view() -> Dictionary:
	var sim = _holder_src.get_ref() if _holder_src != null else null
	var ver: int = sim.state_version() if sim != null else 0
	if ver == _view_ver and _view_cache.size() == block_data.size():
		return _view_cache
	var out: Dictionary = {}
	for bid in block_data:
		var d: Dictionary = block_data[bid].duplicate()
		d["holder"] = sim.block_holder(bid) if sim != null else -1
		d["holder_fwd"] = sim.block_holder_fwd(bid) if sim != null else true
		out[bid] = d
	_view_cache = out
	_view_ver = ver
	return out


func add_node(id: int, pos: Vector2i, node_name: String = "") -> void:
	nodes[id] = {"pos": pos, "name": node_name}
	_adj[id] = []


## single = true: ein Block für beide Richtungen (eingleisig). false: je Richtung ein Block.
func add_edge(id: int, a: int, b: int, single: bool = true) -> void:
	var pa: Vector2i = nodes[a]["pos"]
	var pb: Vector2i = nodes[b]["pos"]
	# aufgerundet, damit die Luftlinie als A*-Heuristik zulässig bleibt
	var length: int = ceili(Vector2(pa).distance_to(Vector2(pb)))
	var center: Vector2i = (pa + pb) / 2
	var b_fwd := _new_block(id, single, center)
	var b_rev := b_fwd if single else _new_block(id, single, center)
	var s_fwd := _new_signal(a, b_fwd, id, true)
	var s_rev := _new_signal(b, b_rev, id, false)
	edges[id] = {
		"a": a, "b": b, "length": length, "single": single,
		"block_fwd": b_fwd, "block_rev": b_rev, "sig_fwd": s_fwd, "sig_rev": s_rev,
	}
	_adj[a].append({"edge": id, "to": b, "fwd": true})
	_adj[b].append({"edge": id, "to": a, "fwd": false})


func _new_block(edge_id: int, single: bool, center: Vector2i) -> int:
	var id := _next_block
	_next_block += 1
	block_data[id] = {"edge": edge_id, "single": single, "center": center}
	return id


func _new_signal(node_id: int, block_id: int, edge_id: int, fwd: bool) -> int:
	var id := _next_signal
	_next_signal += 1
	signals[id] = {"node": node_id, "block": block_id, "edge": edge_id, "fwd": fwd}
	return id


func block_of(edge_id: int, fwd: bool) -> int:
	var e: Dictionary = edges[edge_id]
	return e["block_fwd"] if fwd else e["block_rev"]


func signal_of(edge_id: int, fwd: bool) -> int:
	var e: Dictionary = edges[edge_id]
	return e["sig_fwd"] if fwd else e["sig_rev"]


func step_from_node(step: Dictionary) -> int:
	var e: Dictionary = edges[step["edge"]]
	return e["a"] if step["fwd"] else e["b"]


func step_to_node(step: Dictionary) -> int:
	var e: Dictionary = edges[step["edge"]]
	return e["b"] if step["fwd"] else e["a"]


## Route aus Knotenliste (explizit, z. B. für Szenarien mit festem Umlauf).
## Nimmt je Knotenpaar die erste Kante mit kleinster Kanten-ID.
func route_from_nodes(node_path: Array) -> Array:
	var steps: Array = []
	for i in range(node_path.size() - 1):
		var best: Dictionary = {}
		for link in _adj[node_path[i]]:
			if link["to"] == node_path[i + 1] and (best.is_empty() or link["edge"] < best["edge"]):
				best = link
		assert(not best.is_empty(), "keine Kante zwischen %d und %d" % [node_path[i], node_path[i + 1]])
		steps.append({"edge": best["edge"], "fwd": best["fwd"]})
	return steps


func reverse_route(route: Array) -> Array:
	var out: Array = []
	for i in range(route.size() - 1, -1, -1):
		out.append({"edge": route[i]["edge"], "fwd": not route[i]["fwd"]})
	return out


func _h(from_id: int, to_id: int) -> int:
	return floori(Vector2(nodes[from_id]["pos"]).distance_to(Vector2(nodes[to_id]["pos"])))


## Eigenes A*: ganzzahlige Kosten (mm), Tie-Break (f, dann Knoten-ID), deterministisch.
## Gibt Schritte [{edge, fwd}] zurück, leer wenn kein Weg. Gesamtlänge optional über route_length().
func find_path(from_id: int, to_id: int) -> Array:
	if from_id == to_id:
		return []
	var open: Array = [from_id]
	var g: Dictionary = {from_id: 0}
	var came: Dictionary = {}  # node -> {prev, edge, fwd}
	var closed: Dictionary = {}
	while not open.is_empty():
		var best_i := 0
		var best_f: int = g[open[0]] + _h(open[0], to_id)
		for i in range(1, open.size()):
			var f: int = g[open[i]] + _h(open[i], to_id)
			if f < best_f or (f == best_f and open[i] < open[best_i]):
				best_f = f
				best_i = i
		var cur: int = open[best_i]
		open.remove_at(best_i)
		if cur == to_id:
			var steps: Array = []
			var n := to_id
			while n != from_id:
				var c: Dictionary = came[n]
				steps.push_front({"edge": c["edge"], "fwd": c["fwd"]})
				n = c["prev"]
			return steps
		closed[cur] = true
		for link in _adj[cur]:
			var nb: int = link["to"]
			if closed.has(nb):
				continue
			var ng: int = g[cur] + int(edges[link["edge"]]["length"])
			if not g.has(nb) or ng < g[nb]:
				g[nb] = ng
				came[nb] = {"prev": cur, "edge": link["edge"], "fwd": link["fwd"]}
				if not open.has(nb):
					open.append(nb)
	return []


func route_length(route: Array) -> int:
	var total := 0
	for s in route:
		total += int(edges[s["edge"]]["length"])
	return total
