extends RefCounted
## F-18: Anbindung der Slice-Fahrzeuge an den SoA-Kern (core/sim_world.gd, Linienbetrieb).
##   - Routen: Feldpfad (AStarGrid2D, nur waagrecht/senkrecht) -> Eckpunkte als Knoten, gerade Stücke als
##     Kanten (Länge exakt Felder × feld_mm). Gleiche Knoten/Kanten werden wiederverwendet.
##   - Darstellung: füllt die MultiMesh-Puffer direkt aus den Packed-Arrays (Position in mm, Kante a->b).
##   - Ereignisse: line_events des Kerns -> Buchhaltung im Handle + main.on_delivery().
## Schalter in main.gd: VEHICLE_CORE ("alt" = vehicle.gd, "soa" = dieser Weg), Kommandozeile --fahrzeuge=soa.

const VehicleSoa := preload("res://vehicle_soa.gd")

var sim = null
var feld_mm := 1000
var by_vid: Dictionary = {}       # vid -> Handle
var _edge_of: Dictionary = {}     # Vector2i(a, b) mit a < b -> Kanten-ID
var _nx := PackedInt32Array()     # Knotenposition (mm), Index = Knoten-ID (Zwischenspeicher für Darstellung)
var _ny := PackedInt32Array()


func _init(p_sim, p_feld_mm: int) -> void:
	sim = p_sim
	feld_mm = p_feld_mm
	sim.feld_mm = p_feld_mm


func new_vehicle(vid: int) -> RefCounted:
	var v := VehicleSoa.new()
	v.sim = sim
	v.fleet = self
	v.vid = vid
	v.buy_tick = sim.tick_count
	by_vid[vid] = v
	return v


func _node_at(c: Vector2i) -> int:
	var pos := Vector2i(c.x * feld_mm, c.y * feld_mm)
	if sim.node_by_pos.has(pos):
		return sim.node_by_pos[pos]
	var nid: int = sim.graph.nodes.size()
	sim.add_node(nid, pos, "")
	return nid


func _edge(a: int, b: int) -> Dictionary:
	var key := Vector2i(mini(a, b), maxi(a, b))
	var eid: int
	if _edge_of.has(key):
		eid = _edge_of[key]
	else:
		eid = sim.graph.edges.size() + 1
		while sim.graph.edges.has(eid):
			eid += 1
		sim.graph.add_edge(eid, key.x, key.y, false)
		_edge_of[key] = eid
	return {"edge": eid, "fwd": sim.graph.edges[eid]["a"] == a}


## Feldpfad -> Route [{edge, fwd}] über die Eckpunkte. Erster/letzter Knoten = Standortknoten (Anker).
func route_from_cells(cells: Array) -> Array:
	var corners: Array = [cells[0]]
	for k in range(1, cells.size() - 1):
		var d0: Vector2i = cells[k] - cells[k - 1]
		var d1: Vector2i = cells[k + 1] - cells[k]
		if d0 != d1:
			corners.append(cells[k])
	corners.append(cells[-1])
	var route: Array = []
	var prev := _node_at(corners[0])
	for k in range(1, corners.size()):
		var nd := _node_at(corners[k])
		route.append(_edge(prev, nd))
		prev = nd
	return route


func add_line_vehicle(v, cells: Array) -> void:
	var route := route_from_cells(cells)
	sim.add_line_vehicle(v.vid, "%s %d" % [v.kind_name, v.vid], route, v.speed_mm, v.cap,
		v.src.station, v.dst.station, v.load_ticks, v.max_wait_ticks, v.var_cent_per_field)
	if v.leave_empty:
		sim.set_line_flags(v.vid, true, v.max_wait_ticks)


## Nach sim.step(): Fahrkosten abbuchen, Lieferungen verbuchen (Reihenfolge = Fahrzeug-ID, wie Prototyp).
func after_step(m) -> void:
	if sim.line_cost_cent != 0:
		m.charge(sim.line_cost_cent)
		sim.line_cost_cent = 0
	if sim.line_events.is_empty():
		return
	var evs: Array = sim.line_events
	sim.line_events = []
	for e in evs:
		var v = by_vid[e[0]]
		var tc: int = v.book_delivery(e[2])
		m.on_delivery(v, e[1], e[2], tc, e[3])


func _sync_nodes() -> void:
	var cnt: int = sim.graph.nodes.size()
	if _nx.size() == cnt:
		return
	_nx.resize(cnt)
	_ny.resize(cnt)
	for id in sim.graph.nodes:
		var p: Vector2i = sim.graph.nodes[id]["pos"]
		_nx[id] = p.x
		_ny[id] = p.y


## Weltposition (x, Blickwinkel, z) in Feldern wie vehicle.world_xz (Feldmitte = +0,5).
func world_xz(v) -> Vector3:
	if not v.in_sim:
		return Vector3.ZERO
	_sync_nodes()
	var i: int = sim.slot_of(v.vid)
	var ri: int = sim.v_rstart[i] + mini(sim.v_idx[i], sim.v_rlen[i] - 1)
	var a: int = sim.r_from[ri]
	var b: int = sim.r_to[ri]
	var f: float = float(sim.v_pos[i]) / sim.r_len[ri]
	var x: float = (_nx[a] + (_nx[b] - _nx[a]) * f) / feld_mm + 0.5
	var z: float = (_ny[a] + (_ny[b] - _ny[a]) * f) / feld_mm + 0.5
	return Vector3(x, atan2(float(_nx[b] - _nx[a]), float(_ny[b] - _ny[a])), z)


## MultiMesh-Puffer füllen (Layout wie main._render_vehicles). Gibt nichts zurück; schreibt in bt/bz/bc.
func fill_buffers(vehicles: Array, bt: PackedFloat32Array, bz: PackedFloat32Array, bc: PackedFloat32Array,
		eco, good_colors: Dictionary) -> Array:
	_sync_nodes()
	_sync_vcache(vehicles)
	return _fill_range(0, _c_vid.size(), bt, bz, bc, eco, good_colors)


func _fill_range(from: int, to: int, bt: PackedFloat32Array, bz: PackedFloat32Array, bc: PackedFloat32Array,
		eco, good_colors: Dictionary) -> Array:
	var inv := 1.0 / feld_mm
	var v_state: PackedInt32Array = sim.v_state
	var v_idx: PackedInt32Array = sim.v_idx
	var v_pos: PackedInt32Array = sim.v_pos
	var v_rstart: PackedInt32Array = sim.v_rstart
	var v_rlen: PackedInt32Array = sim.v_rlen
	var v_cargo: PackedInt32Array = sim.v_cargo
	var r_from: PackedInt32Array = sim.r_from
	var r_to: PackedInt32Array = sim.r_to
	var r_len: PackedInt32Array = sim.r_len
	var slot_of: Dictionary = sim._slot_of
	var nx := _nx
	var ny := _ny
	var c_vid := _c_vid
	var c_k := _c_k
	var c_train := _c_train
	var v_lots: Dictionary = eco.v_lots
	for gi in range(from, to):
		var is_train: bool = c_train[gi] == 1
		var k: int = c_k[gi]
		var kc := gi * 16
		var i: int = slot_of.get(c_vid[gi], -1)   # S6: vid steht erst mit Linie (in_sim) im Kern
		if i < 0 or v_state[i] == 4:      # ohne Linie oder verkauft (S_ENDE)
			for j in 12:
				if is_train:
					bz[k + j] = 0.0
				else:
					bt[k + j] = 0.0
				bc[kc + j] = 0.0
			continue
		var ri: int = v_rstart[i] + mini(v_idx[i], v_rlen[i] - 1)
		var a: int = r_from[ri]
		var b: int = r_to[ri]
		var f := float(v_pos[i]) / r_len[ri]
		var dx := float(nx[b] - nx[a])
		var dz := float(ny[b] - ny[a])
		var x := (nx[a] + dx * f) * inv + 0.5
		var z := (ny[a] + dz * f) * inv + 0.5
		var c := 1.0
		var s := 0.0
		var l := sqrt(dx * dx + dz * dz)
		if l > 0.0:
			s = dx / l
			c = dz / l
		if is_train:
			bz[k] = c; bz[k + 1] = 0.0; bz[k + 2] = s; bz[k + 3] = x
			bz[k + 4] = 0.0; bz[k + 5] = 1.0; bz[k + 6] = 0.0; bz[k + 7] = 0.35
			bz[k + 8] = -s; bz[k + 9] = 0.0; bz[k + 10] = c; bz[k + 11] = z
		else:
			bt[k] = c; bt[k + 1] = 0.0; bt[k + 2] = s; bt[k + 3] = x
			bt[k + 4] = 0.0; bt[k + 5] = 1.0; bt[k + 6] = 0.0; bt[k + 7] = 0.3
			bt[k + 8] = -s; bt[k + 9] = 0.0; bt[k + 10] = c; bt[k + 11] = z
		if v_cargo[i] > 0:
			var col: Color = Color.WHITE
			var lots: Array = v_lots.get(c_vid[gi], [])
			if not lots.is_empty():
				col = good_colors.get(eco.g_ids[lots[0][0]], Color.WHITE)
			bc[kc] = c; bc[kc + 1] = 0.0; bc[kc + 2] = s; bc[kc + 3] = x
			bc[kc + 4] = 0.0; bc[kc + 5] = 1.0; bc[kc + 6] = 0.0; bc[kc + 7] = 0.75 if not is_train else 0.85
			bc[kc + 8] = -s; bc[kc + 9] = 0.0; bc[kc + 10] = c; bc[kc + 11] = z
			bc[kc + 12] = col.r; bc[kc + 13] = col.g; bc[kc + 14] = col.b; bc[kc + 15] = 1.0
		else:
			for j in 12:
				bc[kc + j] = 0.0
	return [bt, bz, bc]


# ---- S6 (F-12-Auflage p95): Puffer-Aufbau über die Frames zwischen zwei Ticks verteilen.
## Ablauf je Physik-Tick (main._render_vehicles): render_finish() schließt den Auftrag des Vortick-Zustands ab
## (Rest synchron) und liefert die Puffer zum Commit, render_begin() startet den Auftrag für den neuen Zustand;
## main._process ruft render_step() mit einem Teil der Flotte. Der Sim-Zustand ändert sich nur im Tick, die
## Puffer zeigen also exakt den Tick-Zustand, nur einen Tick (tick_ms) später. Rein Darstellung, Sim/Parität unberührt.
const RENDER_STEP_PARTS := 4      # Flotte in höchstens 4 Frame-Portionen (bei 45 FPS liegen ~4,5 Frames zwischen Ticks)
const RENDER_STEP_MIN := 256
var _job_next := -1               # nächster Index, -1 = kein offener Auftrag
var _job_end := 0
var _job_step := 0
var _job_bufs: Array = []
var _job_eco = null
var _job_colors: Dictionary = {}


func render_pending() -> bool:
	return _job_next >= 0


func render_begin(vehicles: Array, bt: PackedFloat32Array, bz: PackedFloat32Array, bc: PackedFloat32Array,
		eco, good_colors: Dictionary) -> void:
	_sync_nodes()
	_sync_vcache(vehicles)
	_job_bufs = [bt, bz, bc]
	_job_eco = eco
	_job_colors = good_colors
	_job_next = 0
	_job_end = _c_vid.size()
	_job_step = maxi(RENDER_STEP_MIN, ceili(_job_end / float(RENDER_STEP_PARTS)))


## Eine Portion (Frame) des offenen Auftrags.
func render_step() -> void:
	if _job_next < 0 or _job_next >= _job_end:
		return
	var to := mini(_job_next + _job_step, _job_end)
	_job_bufs = _fill_range(_job_next, to, _job_bufs[0], _job_bufs[1], _job_bufs[2], _job_eco, _job_colors)
	_job_next = to


## Rest synchron füllen, Auftrag schließen, Puffer [bt, bz, bc] zurückgeben.
func render_finish() -> Array:
	if _job_next >= 0 and _job_next < _job_end:
		_job_bufs = _fill_range(_job_next, _job_end, _job_bufs[0], _job_bufs[1], _job_bufs[2], _job_eco, _job_colors)
	_job_next = -1
	var r := _job_bufs
	_job_bufs = []
	return r


## S6 (F-12-Auflage p95): unveränderliche Fahrzeugdaten (vid, rindex, Typ) als Packed-Arrays, damit fill_buffers
## je Tick keine 3 × 5.000 Objekt-Property-Zugriffe macht. Fahrzeuge werden im Slice nur angehängt (main.buy_vehicle).
var _c_vid := PackedInt32Array()
var _c_k := PackedInt32Array()
var _c_train := PackedByteArray()

func _sync_vcache(vehicles: Array) -> void:
	var n0 := _c_vid.size()
	if n0 == vehicles.size():
		return
	_c_vid.resize(vehicles.size())
	_c_k.resize(vehicles.size())
	_c_train.resize(vehicles.size())
	for gi in range(n0, vehicles.size()):
		var v = vehicles[gi]
		_c_vid[gi] = v.vid
		_c_k[gi] = v.rindex * 12
		_c_train[gi] = 1 if v.type == "train" else 0
