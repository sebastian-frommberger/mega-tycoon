extends RefCounted
## F-10 (Sprint 3): SimWorld als Struct-of-Arrays-Kern. Gleiche Regeln wie der Spike F-04
## (fester Tick 10 Hz, Hold-and-Wait-Blockreservierung, Lager, Zulieferung, Pendel/Rundkurs),
## gleiche Prüfsumme, gleiche Diagnose-API. Reine Daten, kein Node, kein Rendering.
##
## Datenlayout
##   Fahrzeuge:  je Feld ein Packed*Array, Index = Slot. Slots stehen in aufsteigender Fahrzeug-ID
##               (Tick-Reihenfolge des Spikes), _slot_of bildet ID -> Slot ab (nur kalte Pfade).
##   Routen:     flach (r_edge, r_fwd, r_block, r_len, r_from, r_to), je Fahrzeug Start + Länge.
##               Pendel (Route ohne Rundschluss) wird am Ende in place umgedreht (gleiche Länge).
##   Blöcke:     b_holder (Slot oder -1), b_holder_fwd, b_wait_head (Liste der Wartenden je Block).
##   Lager:      st_* je Lager-Slot, _station_of: Knoten -> Lager-Slot (nur bei Ladeknoten benutzt).
##
## F-11 Deadlock-Prüfung ereignisgesteuert (kein Vollscan je Tick):
##   Ereignis A: ein Fahrzeug beginnt, auf einen Block zu warten        -> Fahrzeug in die Prüfliste
##   Ereignis B: ein Block, auf den jemand wartet, wechselt den Halter   -> dessen Wartende in die Prüfliste
##   Am Tick-Ende läuft von jedem Fahrzeug der Prüfliste die Warte-Kette entlang (jedes Fahrzeug höchstens
##   einmal je Tick). Ein gefundener Zyklus wird wie im Spike erst nach DEADLOCK_CONFIRM_TICKS Ticks in
##   Folge gemeldet; fährt ein Mitglied wieder oder wechselt ein beteiligter Block den Halter, wird der
##   Zyklus nachgeprüft und ggf. verworfen. Meldungen (deadlock_events) sind feldgleich zum Spike
##   (Äquivalenztest K8 gegen res://ref/sim_world.gd). Genre-Standard (D15): Warte-Graph mit
##   Zykluserkennung, wie bei Block-Signalsystemen üblich; nichts Neues erfunden.
##
## F-16: `economy` (economy.gd) hängt sich optional ein: on_tick (Öko-Tick), load_gate/on_load beim Laden,
## on_unload beim Entladen (Ertrag nur beim Endabnehmer, Stempel). economy == null -> Verhalten und Prüfsumme wie S3.
##
## Kompatibilität: `vehicles` und `stations` sind Lesesichten (Dictionary je ID wie im Spike), gepuffert
## je Sim-Version. Schreiben in die Sicht hat keine Wirkung; Änderungen gehen über set_vehicle_speed().

const NetGraph := preload("res://net_graph.gd")
const Diagnostics := preload("res://diagnostics.gd")

const TICK_HZ := 10
const DEADLOCK_CONFIRM_TICKS := 5  # Zyklus muss so viele Ticks in Folge bestehen

enum VState { GEPLANT, UNTERWEGS, WARTET_BLOCK, WARTET_LADUNG, ENDE }
const S_GEPLANT := 0
const S_UNTERWEGS := 1
const S_WARTET_BLOCK := 2
const S_WARTET_LADUNG := 3
const S_ENDE := 4

var graph = NetGraph.new()
var economy = null                      # F-16: Ökonomie-Modul (economy.gd), optional; null = Kern wie S3
var tick_count := 0
# Erkannte Deadlocks: [{members, root_cause, tick_formed, tick_detected, ticks_to_detect}]
var deadlock_events: Array = []
# Profil des letzten Ticks in Mikrosekunden
var profile_usec := {"vehicles": 0, "deadlock": 0, "total": 0, "economy": 0}  # economy: on_tick-Anteil (in vehicles enthalten)
# Statistik Deadlock-Prüfung (kumuliert): Kettenläufe, besuchte Fahrzeuge
var dl_walks := 0
var dl_visits := 0

# ---- Fahrzeuge (SoA) ----
var n := 0
var v_id := PackedInt32Array()
var v_state := PackedInt32Array()
var v_idx := PackedInt32Array()
var v_pos := PackedInt32Array()
var v_speed := PackedInt32Array()
var v_start := PackedInt32Array()
var v_held := PackedInt32Array()        # Block-ID oder -1
var v_wait_block := PackedInt32Array()  # Block-ID oder -1
var v_wait_since := PackedInt32Array()
var v_cargo_cap := PackedInt32Array()
var v_cargo := PackedInt32Array()
var v_cyclic := PackedByteArray()
var v_runs := PackedInt32Array()
var v_loaded_tick := PackedInt32Array()
var v_waited := PackedInt32Array()      # waited_ticks_total
var v_rstart := PackedInt32Array()
var v_rlen := PackedInt32Array()
var v_lstart := PackedInt32Array()      # load_nodes in l_nodes
var v_lcount := PackedInt32Array()
var v_ustart := PackedInt32Array()      # unload_nodes in u_nodes
var v_ucount := PackedInt32Array()
var v_wait_next := PackedInt32Array()   # nächster Wartender am selben Block (Slot) oder -1
var v_cyc := PackedInt32Array()         # Serien-Nr. des bekannten Zyklus oder -1
var v_mark := PackedInt32Array()        # Stempel des laufenden Kettenlaufs
var v_done := PackedInt32Array()        # Tick, in dem die Kette ab hier schon verfolgt wurde
var v_name := PackedStringArray()

# ---- Routen (flach) ----
var r_edge := PackedInt32Array()
var r_fwd := PackedByteArray()
var r_block := PackedInt32Array()
var r_len := PackedInt32Array()
var r_from := PackedInt32Array()
var r_to := PackedInt32Array()
var r_stop := PackedByteArray()         # F-16: 1 = Zielknoten des Schritts ist Lade-/Entladeknoten dieses Fahrzeugs
var l_nodes := PackedInt32Array()
var u_nodes := PackedInt32Array()

# ---- Blöcke (Index = Block-ID) ----
var b_holder := PackedInt32Array()      # Slot oder -1
var b_holder_fwd := PackedByteArray()
var b_wait_head := PackedInt32Array()   # erster wartender Slot oder -1

# ---- Lager ----
var st_node := PackedInt32Array()
var st_stock := PackedInt32Array()
var st_every := PackedInt32Array()
var st_amount := PackedInt32Array()
var st_delivered := PackedInt32Array()
var st_name := PackedStringArray()
var _station_of: Dictionary = {}        # Knoten-ID -> Lager-Slot
var _producers := PackedInt32Array()    # F-16: Lager-Slots mit produce_every > 0, aufsteigend (nur diese besucht _produce)

var _slot_of: Dictionary = {}           # Fahrzeug-ID -> Slot
var _order_dirty := false
var _ver := 0                           # Sim-Version (für Lesesichten)

# ---- Deadlock-Prüfung (F-11) ----
var _ev_vehicles := PackedInt32Array()  # Ereignis A (und Wartende aus Ereignis B), Slots
var _ev_blocks := PackedInt32Array()    # Ereignis B, Block-IDs
var _stamp := 0
var _cycles: Dictionary = {}            # Serien-Nr. -> {ids, key, first_seen, reported, dirty}
var _cycle_by_key: Dictionary = {}      # Schlüssel -> Serien-Nr.
var _next_cycle := 1
var _cycles_dirty := false

# ---- Lesesichten ----
var vehicles: Dictionary:
	get = _get_vehicles_view
var stations: Dictionary:
	get = _get_stations_view
var _vview: Dictionary = {}
var _vview_ver := -1
var _sview: Dictionary = {}
var _sview_ver := -1


func _init() -> void:
	graph._holder_src = weakref(self)


func state_version() -> int:
	return _ver


# =====================================================================================  Aufbau

func add_station(node_id: int, station_name: String, stock: int, produce_every: int, produce_amount: int) -> void:
	if _station_of.has(node_id):
		var k: int = _station_of[node_id]
		st_name[k] = station_name
		st_stock[k] = stock
		st_every[k] = produce_every
		st_amount[k] = produce_amount
		st_delivered[k] = 0
	else:
		_station_of[node_id] = st_node.size()
		st_node.append(node_id)
		st_stock.append(stock)
		st_every.append(produce_every)
		st_amount.append(produce_amount)
		st_delivered.append(0)
		st_name.append(station_name)
		if produce_every > 0:
			_producers.append(st_node.size() - 1)   # neuer Slot ist der größte -> Liste bleibt aufsteigend
		_ver += 1
		return
	_producers = PackedInt32Array()                 # bestehendes Lager geändert: Liste neu aufbauen
	for kk in range(st_node.size()):
		if st_every[kk] > 0:
			_producers.append(kk)
	_ver += 1


## route: Array[{edge, fwd}]. load_nodes: Knoten, an denen geladen werden muss (cargo_cap Einheiten).
## unload_nodes: Knoten (Lager), an denen die Ladung abgeladen wird (Zulieferung, zählt für n_lkw).
func add_vehicle(id: int, vname: String, route: Array, speed_mm_per_tick: int, start_tick: int = 0,
		load_nodes: Array = [], cargo_cap: int = 10, cyclic: bool = false, unload_nodes: Array = []) -> void:
	assert(not _slot_of.has(id), "Fahrzeug-ID %d doppelt" % id)
	var i := n
	n += 1
	_slot_of[id] = i
	if i > 0 and id < v_id[i - 1]:
		_order_dirty = true
	v_id.append(id)
	v_state.append(S_GEPLANT)
	v_idx.append(0)
	v_pos.append(0)
	v_speed.append(speed_mm_per_tick)
	v_start.append(start_tick)
	v_held.append(-1)
	v_wait_block.append(-1)
	v_wait_since.append(-1)
	v_cargo_cap.append(cargo_cap)
	v_cargo.append(0)
	v_cyclic.append(1 if cyclic else 0)
	v_runs.append(0)
	v_loaded_tick.append(-1)
	v_waited.append(0)
	v_wait_next.append(-1)
	v_cyc.append(-1)
	v_mark.append(0)
	v_done.append(-1)
	v_name.append(vname)
	v_rstart.append(r_edge.size())
	v_rlen.append(route.size())
	for s in route:
		var eid: int = s["edge"]
		var fwd: bool = s["fwd"]
		var e: Dictionary = graph.edges[eid]
		r_edge.append(eid)
		r_fwd.append(1 if fwd else 0)
		r_block.append(e["block_fwd"] if fwd else e["block_rev"])
		r_len.append(e["length"])
		r_from.append(e["a"] if fwd else e["b"])
		r_to.append(e["b"] if fwd else e["a"])
		r_stop.append(0)
	v_lstart.append(l_nodes.size())
	v_lcount.append(load_nodes.size())
	for x in load_nodes:
		l_nodes.append(x)
	v_ustart.append(u_nodes.size())
	v_ucount.append(unload_nodes.size())
	for x in unload_nodes:
		u_nodes.append(x)
	_calc_stops(i)
	_ver += 1


## F-16: Halte-Markierung je Routenschritt (für den schnellen Pfad in step(); gleiches Ergebnis wie _arrive).
func _calc_stops(i: int) -> void:
	var rs := v_rstart[i]
	for k in range(rs, rs + v_rlen[i]):
		var nd := r_to[k]
		var stop := (v_lcount[i] > 0 and _has_node(l_nodes, v_lstart[i], v_lcount[i], nd)) \
			or (v_ucount[i] > 0 and _has_node(u_nodes, v_ustart[i], v_ucount[i], nd))
		r_stop[k] = 1 if stop else 0


## Geschwindigkeit ändern (Ersatz für das Schreiben in vehicles[id]["speed"] im Spike).
func set_vehicle_speed(id: int, speed_mm_per_tick: int) -> void:
	_ensure()
	v_speed[_slot_of[id]] = speed_mm_per_tick
	_ver += 1


## Vor jedem Tick und jeder Abfrage: Blockfelder auf Graphgröße, Slot-Reihenfolge nach ID.
func _ensure() -> void:
	var nb: int = graph.next_block_id()
	if b_holder.size() < nb:
		var old := b_holder.size()
		b_holder.resize(nb)
		b_holder_fwd.resize(nb)
		b_wait_head.resize(nb)
		for b in range(old, nb):
			b_holder[b] = -1
			b_holder_fwd[b] = 1
			b_wait_head[b] = -1
	if _order_dirty:
		_resort()


## Slots nach Fahrzeug-ID ordnen (nur wenn IDs nicht aufsteigend hinzugefügt wurden; Aufbauzeit).
func _resort() -> void:
	_order_dirty = false
	var pairs: Array = []
	for i in range(n):
		pairs.append([v_id[i], i])
	pairs.sort_custom(func(a, b): return a[0] < b[0])
	var perm := PackedInt32Array()  # neuer Slot -> alter Slot
	var inv := PackedInt32Array()   # alter Slot -> neuer Slot
	perm.resize(n)
	inv.resize(n)
	for k in range(n):
		perm[k] = pairs[k][1]
		inv[pairs[k][1]] = k
	v_id = _perm_i(v_id, perm)
	v_state = _perm_i(v_state, perm)
	v_idx = _perm_i(v_idx, perm)
	v_pos = _perm_i(v_pos, perm)
	v_speed = _perm_i(v_speed, perm)
	v_start = _perm_i(v_start, perm)
	v_held = _perm_i(v_held, perm)
	v_wait_block = _perm_i(v_wait_block, perm)
	v_wait_since = _perm_i(v_wait_since, perm)
	v_cargo_cap = _perm_i(v_cargo_cap, perm)
	v_cargo = _perm_i(v_cargo, perm)
	v_runs = _perm_i(v_runs, perm)
	v_loaded_tick = _perm_i(v_loaded_tick, perm)
	v_waited = _perm_i(v_waited, perm)
	v_rstart = _perm_i(v_rstart, perm)
	v_rlen = _perm_i(v_rlen, perm)
	v_lstart = _perm_i(v_lstart, perm)
	v_lcount = _perm_i(v_lcount, perm)
	v_ustart = _perm_i(v_ustart, perm)
	v_ucount = _perm_i(v_ucount, perm)
	var cyc := PackedByteArray()
	cyc.resize(n)
	var names := PackedStringArray()
	names.resize(n)
	for k in range(n):
		cyc[k] = v_cyclic[perm[k]]
		names[k] = v_name[perm[k]]
	v_cyclic = cyc
	v_name = names
	v_mark.fill(0)
	v_done.fill(-1)
	for b in range(b_holder.size()):
		if b_holder[b] != -1:
			b_holder[b] = inv[b_holder[b]]
	_slot_of.clear()
	for k in range(n):
		_slot_of[v_id[k]] = k
	# Warte-Listen und Zyklus-Zuordnung neu aufbauen
	b_wait_head.fill(-1)
	v_wait_next.fill(-1)
	v_cyc.fill(-1)
	for k in range(n - 1, -1, -1):
		if v_state[k] == S_WARTET_BLOCK:
			_link_waiter(k, v_wait_block[k])
	for serial in _cycles:
		for vid in _cycles[serial]["ids"]:
			v_cyc[_slot_of[vid]] = serial
	_ver += 1


static func _perm_i(a: PackedInt32Array, perm: PackedInt32Array) -> PackedInt32Array:
	var out := PackedInt32Array()
	out.resize(perm.size())
	for k in range(perm.size()):
		out[k] = a[perm[k]]
	return out


func sorted_ids() -> Array:
	_ensure()
	return Array(v_id)


func has_vehicle(id: int) -> bool:
	return _slot_of.has(id)


func slot_of(id: int) -> int:
	_ensure()
	return _slot_of.get(id, -1)


# =====================================================================================  Tick

func step() -> void:
	_ensure()
	var t0 := Time.get_ticks_usec()
	tick_count += 1
	_ver += 1
	if _producers.size() > 0:
		_produce()
	if economy != null:
		var te := Time.get_ticks_usec()
		economy.on_tick(self)
		profile_usec["economy"] = Time.get_ticks_usec() - te
	var t := tick_count
	for i in range(n):
		var st := v_state[i]
		if st == S_UNTERWEGS:
			var ri := v_rstart[i] + v_idx[i]
			var p := v_pos[i] + v_speed[i]
			var length := r_len[ri]
			if p >= length:
				v_pos[i] = length
				if r_stop[ri] == 0 and v_idx[i] + 1 < v_rlen[i]:
					# schneller Pfad (gleiches Ergebnis wie _arrive): Zielknoten ist kein Lade-/Entladeknoten
					# dieses Fahrzeugs (F-16: je Schritt statt je Fahrzeug), Route nicht zu Ende
					v_idx[i] += 1
					_try_enter(i)
				else:
					_arrive(i)
			else:
				v_pos[i] = p
		elif st == S_WARTET_BLOCK:
			v_waited[i] += 1
			# schneller Pfad: Block weiter belegt -> nichts zu tun (gleiches Ergebnis wie _try_enter)
			var hb := b_holder[r_block[v_rstart[i] + v_idx[i]]]
			if hb == -1 or hb == i:
				_try_enter(i)
		elif st == S_GEPLANT:
			if t >= v_start[i]:
				_try_enter(i)
		elif st == S_WARTET_LADUNG:
			_try_load(i)
	var t1 := Time.get_ticks_usec()
	_deadlock_tick()
	var t2 := Time.get_ticks_usec()
	profile_usec["vehicles"] = t1 - t0
	profile_usec["deadlock"] = t2 - t1
	profile_usec["total"] = t2 - t0


func run_ticks(count: int) -> void:
	for k in range(count):
		step()


func _produce() -> void:
	for k in _producers:
		if tick_count % st_every[k] == 0:
			st_stock[k] += st_amount[k]


## Nächsten Block der Route reservieren. Hält der Fahrer ihn selbst, gilt er als frei.
## Der alte Block wird erst beim erfolgreichen Eintritt freigegeben (Hold-and-Wait, deshalb Deadlock möglich).
func _try_enter(i: int) -> void:
	var ri := v_rstart[i] + v_idx[i]
	var b := r_block[ri]
	var h := b_holder[b]
	if h == -1 or h == i:
		if v_state[i] == S_WARTET_BLOCK:
			_unlink_waiter(i, v_wait_block[i])
			if v_cyc[i] != -1:
				_mark_cycle_dirty(v_cyc[i])
		var held := v_held[i]
		if held != -1 and held != b:
			b_holder[held] = -1
			if b_wait_head[held] != -1:
				_ev_blocks.append(held)    # Ereignis B: Halterwechsel an einem Block mit Wartenden
		b_holder[b] = i
		b_holder_fwd[b] = r_fwd[ri]
		if h != i and b_wait_head[b] != -1:
			_ev_blocks.append(b)           # Ereignis B
		v_held[i] = b
		v_state[i] = S_UNTERWEGS
		v_pos[i] = 0
		v_wait_block[i] = -1
		v_wait_since[i] = -1
	elif v_state[i] != S_WARTET_BLOCK:
		v_state[i] = S_WARTET_BLOCK
		v_wait_block[i] = b
		v_wait_since[i] = tick_count
		_link_waiter(i, b)
		_ev_vehicles.append(i)             # Ereignis A: beginnt zu warten


func _arrive(i: int) -> void:
	var ri := v_rstart[i] + v_idx[i]
	var node_id := r_to[ri]
	v_idx[i] += 1
	if v_cargo[i] > 0 and v_ucount[i] > 0 and _has_node(u_nodes, v_ustart[i], v_ucount[i], node_id) and _station_of.has(node_id):
		var k: int = _station_of[node_id]
		if economy != null:
			v_cargo[i] -= economy.on_unload(self, i, k)   # nur angenommene Einheiten verlassen das Fahrzeug
		else:
			st_stock[k] += v_cargo[i]
			st_delivered[k] += v_cargo[i]
			v_cargo[i] = 0
	if v_lcount[i] > 0 and _has_node(l_nodes, v_lstart[i], v_lcount[i], node_id) and _station_of.has(node_id):
		v_state[i] = S_WARTET_LADUNG
		v_wait_since[i] = tick_count
		_try_load(i)
	else:
		_continue(i)


static func _has_node(arr: PackedInt32Array, start: int, count: int, node_id: int) -> bool:
	for k in range(start, start + count):
		if arr[k] == node_id:
			return true
	return false


func _try_load(i: int) -> void:
	# Fahrzeug steht am Lagerknoten: letzter Schritt ist idx-1
	var node_id := r_to[v_rstart[i] + v_idx[i] - 1]
	var k: int = _station_of[node_id]
	if economy != null:
		var gate: int = economy.load_gate(self, i, k)
		if gate == 0:      # Economy.L_WAIT (z. B. keine Lizenz)
			return
		if gate == 2:      # Economy.L_SKIP: Restladung an Bord, weiterfahren
			v_wait_since[i] = -1
			_continue(i)
			return
	if st_stock[k] >= v_cargo_cap[i]:
		st_stock[k] -= v_cargo_cap[i]
		v_cargo[i] = v_cargo_cap[i]
		v_loaded_tick[i] = tick_count
		v_wait_since[i] = -1
		if economy != null:
			economy.on_load(self, i, k, v_cargo_cap[i])
		_continue(i)


func _continue(i: int) -> void:
	if v_idx[i] >= v_rlen[i]:
		v_runs[i] += 1
		if v_cyclic[i] == 1:
			# geschlossene Route (Ende == Start): Rundkurs ohne Wenden, sonst Pendel (Route umkehren)
			var rs := v_rstart[i]
			if r_to[rs + v_rlen[i] - 1] != r_from[rs]:
				_reverse_route(i)
			v_idx[i] = 0
			_try_enter(i)
		else:
			var held := v_held[i]
			if held != -1:
				b_holder[held] = -1
				if b_wait_head[held] != -1:
					_ev_blocks.append(held)
				v_held[i] = -1
			v_state[i] = S_ENDE
	else:
		_try_enter(i)


## Pendel: Route in place umdrehen (Reihenfolge und Richtung), Länge bleibt gleich.
func _reverse_route(i: int) -> void:
	var rs := v_rstart[i]
	var rl := v_rlen[i]
	var lo := rs
	var hi := rs + rl - 1
	while lo < hi:
		_swap_step(lo, hi)
		lo += 1
		hi -= 1
	for k in range(rs, rs + rl):
		var fwd := r_fwd[k] == 0  # Richtung umdrehen
		var e: Dictionary = graph.edges[r_edge[k]]
		r_fwd[k] = 1 if fwd else 0
		r_block[k] = e["block_fwd"] if fwd else e["block_rev"]
		var f := r_from[k]
		r_from[k] = r_to[k]
		r_to[k] = f
	_calc_stops(i)


func _swap_step(a: int, b: int) -> void:
	var t := r_edge[a]
	r_edge[a] = r_edge[b]
	r_edge[b] = t
	var tf := r_fwd[a]
	r_fwd[a] = r_fwd[b]
	r_fwd[b] = tf
	t = r_block[a]
	r_block[a] = r_block[b]
	r_block[b] = t
	t = r_len[a]
	r_len[a] = r_len[b]
	r_len[b] = t
	t = r_from[a]
	r_from[a] = r_from[b]
	r_from[b] = t
	t = r_to[a]
	r_to[a] = r_to[b]
	r_to[b] = t


# =====================================================================================  Warte-Listen

func _link_waiter(i: int, b: int) -> void:
	v_wait_next[i] = b_wait_head[b]
	b_wait_head[b] = i


func _unlink_waiter(i: int, b: int) -> void:
	var cur := b_wait_head[b]
	if cur == i:
		b_wait_head[b] = v_wait_next[i]
	else:
		while cur != -1:
			var nx := v_wait_next[cur]
			if nx == i:
				v_wait_next[cur] = v_wait_next[i]
				break
			cur = nx
	v_wait_next[i] = -1


# =====================================================================================  F-11 Deadlock

func _mark_cycle_dirty(serial: int) -> void:
	_cycles[serial]["dirty"] = true
	_cycles_dirty = true


## Tick-Ende: Ereignisse auswerten, bekannte Zyklen nachprüfen, bestätigte Zyklen melden.
func _deadlock_tick() -> void:
	if _ev_blocks.size() > 0:
		for b in _ev_blocks:
			var w := b_wait_head[b]
			while w != -1:
				_ev_vehicles.append(w)
				if v_cyc[w] != -1:
					_mark_cycle_dirty(v_cyc[w])
				w = v_wait_next[w]
		_ev_blocks.clear()
	if _cycles_dirty:
		_recheck_cycles()
	if _ev_vehicles.size() > 0:
		var found: Array = []
		for s in _ev_vehicles:
			if v_state[s] == S_WARTET_BLOCK and v_cyc[s] == -1 and v_done[s] != tick_count:
				var cyc := _walk(s)
				if not cyc.is_empty():
					found.append(cyc)
		_ev_vehicles.clear()
		for cyc in found:
			_register_cycle(cyc)
	if not _cycles.is_empty():
		_confirm_cycles()


## Warte-Kette ab Slot s. Liefert Zyklus-Slots (in Warterichtung) oder leer.
## Stoppt an nicht wartenden Fahrzeugen, an Fahrzeugen eines bekannten Zyklus (dann kann kein neuer
## entstehen, jedes Fahrzeug hat höchstens eine Warte-Kante) und an Fahrzeugen, deren Kette in diesem
## Tick schon verfolgt wurde (deren Zyklus, falls vorhanden, ist bereits gefunden).
func _walk(s: int) -> PackedInt32Array:
	dl_walks += 1
	_stamp += 1
	if _stamp > 2000000000:
		v_mark.fill(0)
		_stamp = 1
	var stamp := _stamp
	var t := tick_count
	var path := PackedInt32Array()
	var cur := s
	var closed := false
	while cur != -1:
		if v_mark[cur] == stamp:
			closed = true
			break
		if v_state[cur] != S_WARTET_BLOCK or v_cyc[cur] != -1 or v_done[cur] == t:
			break
		v_mark[cur] = stamp
		path.append(cur)
		cur = b_holder[v_wait_block[cur]]
	dl_visits += path.size()
	for p in path:
		v_done[p] = t
	if closed:
		return path.slice(path.find(cur))
	return PackedInt32Array()


func _register_cycle(slots: PackedInt32Array) -> void:
	# kanonisch: kleinste ID zuerst, Warterichtung beibehalten (wie Spike find_wait_cycles)
	var ids: Array = []
	for s in slots:
		ids.append(v_id[s])
	var m: int = ids.find(ids.min())
	ids = ids.slice(m) + ids.slice(0, m)
	var key := ",".join(PackedStringArray(ids.map(func(x): return str(x))))
	if _cycle_by_key.has(key):
		return
	var serial := _next_cycle
	_next_cycle += 1
	_cycles[serial] = {"ids": ids, "key": key, "first_seen": tick_count, "reported": false, "dirty": false}
	_cycle_by_key[key] = serial
	for s in slots:
		v_cyc[s] = serial


func _cycle_intact(ids: Array) -> bool:
	var cnt := ids.size()
	for k in range(cnt):
		var s: int = _slot_of[ids[k]]
		if v_state[s] != S_WARTET_BLOCK:
			return false
		var nxt: int = _slot_of[ids[(k + 1) % cnt]]
		if b_holder[v_wait_block[s]] != nxt:
			return false
	return true


func _recheck_cycles() -> void:
	_cycles_dirty = false
	for serial in _cycles.keys():
		var c: Dictionary = _cycles[serial]
		if not c["dirty"]:
			continue
		c["dirty"] = false
		if not _cycle_intact(c["ids"]):
			for vid in c["ids"]:
				var s: int = _slot_of[vid]
				if v_cyc[s] == serial:
					v_cyc[s] = -1
				# aufgelöster Zyklus: Mitglieder, die noch warten, neu prüfen
				if v_state[s] == S_WARTET_BLOCK:
					_ev_vehicles.append(s)
			_cycle_by_key.erase(c["key"])
			_cycles.erase(serial)


func _confirm_cycles() -> void:
	var due: Array = []
	for serial in _cycles:
		var c: Dictionary = _cycles[serial]
		if not c["reported"] and tick_count - int(c["first_seen"]) + 1 >= DEADLOCK_CONFIRM_TICKS:
			due.append(c)
	if due.is_empty():
		return
	due.sort_custom(func(a, b): return a["ids"][0] < b["ids"][0])
	for c in due:
		c["reported"] = true
		var formed := 0
		for vid in c["ids"]:
			formed = maxi(formed, v_wait_since[_slot_of[vid]])
		deadlock_events.append({
			"members": c["ids"].duplicate(),
			"root_cause": Diagnostics.classify_cycle(self, c["ids"]),
			"tick_formed": formed,
			"tick_detected": tick_count,
			"ticks_to_detect": tick_count - formed,
		})


## Aktuell bekannte Zyklen (Mitglieder-IDs, kanonisch rotiert), sortiert nach erstem Mitglied.
func active_cycles() -> Array:
	var out: Array = []
	for serial in _cycles:
		out.append(_cycles[serial]["ids"].duplicate())
	out.sort_custom(func(a, b): return a[0] < b[0])
	return out


## Vollscan wie im Spike (alle wartenden Fahrzeuge). Nur für Tests/Orakel, läuft nicht im Tick.
func find_wait_cycles_full() -> Array:
	_ensure()
	var cycles: Array = []
	var seen: Dictionary = {}
	var done: Dictionary = {}
	for start in range(n):
		if v_state[start] != S_WARTET_BLOCK or done.has(start):
			continue
		var path: Array = []
		var on_path: Dictionary = {}
		var cur := start
		while cur != -1 and not on_path.has(cur) and not done.has(cur):
			path.append(cur)
			on_path[cur] = true
			cur = b_holder[v_wait_block[cur]] if v_state[cur] == S_WARTET_BLOCK else -1
		if cur != -1 and on_path.has(cur):
			var ids: Array = path.slice(path.find(cur)).map(func(x): return v_id[x])
			var m: int = ids.find(ids.min())
			ids = ids.slice(m) + ids.slice(0, m)
			var key := ",".join(PackedStringArray(ids.map(func(x): return str(x))))
			if not seen.has(key):
				seen[key] = true
				cycles.append(ids)
		for p in path:
			done[p] = true
	cycles.sort_custom(func(a, b): return a[0] < b[0])
	return cycles


## Kompatibel zum Spike: Zyklen aus Vollscan.
func find_wait_cycles() -> Array:
	return find_wait_cycles_full()


# =====================================================================================  Abfragen

## Halter eines Blocks als Fahrzeug-ID (-1 = frei).
func block_holder(block_id: int) -> int:
	_ensure()
	if block_id < 0 or block_id >= b_holder.size():
		return -1
	var h := b_holder[block_id]
	return -1 if h == -1 else v_id[h]


func block_holder_fwd(block_id: int) -> bool:
	_ensure()
	if block_id < 0 or block_id >= b_holder_fwd.size():
		return true
	return b_holder_fwd[block_id] == 1


## Schnappschuss eines Fahrzeugs als Dictionary (Felder wie im Spike). Kalter Pfad.
func vehicle(id: int) -> Dictionary:
	_ensure()
	return _snapshot(_slot_of[id])


func _snapshot(i: int) -> Dictionary:
	var route: Array = []
	var rs := v_rstart[i]
	for k in range(rs, rs + v_rlen[i]):
		route.append({"edge": r_edge[k], "fwd": r_fwd[k] == 1})
	var ln: Array = []
	for k in range(v_lstart[i], v_lstart[i] + v_lcount[i]):
		ln.append(l_nodes[k])
	var un: Array = []
	for k in range(v_ustart[i], v_ustart[i] + v_ucount[i]):
		un.append(u_nodes[k])
	return {
		"id": v_id[i], "name": v_name[i], "route": route, "idx": v_idx[i], "pos": v_pos[i],
		"speed": v_speed[i], "state": v_state[i], "start_tick": v_start[i],
		"held_block": v_held[i], "wait_block": v_wait_block[i], "wait_since": v_wait_since[i],
		"load_nodes": ln, "cargo_cap": v_cargo_cap[i], "cyclic": v_cyclic[i] == 1,
		"unload_nodes": un, "cargo": v_cargo[i],
		"runs": v_runs[i], "loaded_tick": v_loaded_tick[i], "waited_ticks_total": v_waited[i],
	}


func _get_vehicles_view() -> Dictionary:
	_ensure()
	if _vview_ver != _ver:
		var out: Dictionary = {}
		for i in range(n):
			out[v_id[i]] = _snapshot(i)
		_vview = out
		_vview_ver = _ver
	return _vview


func _get_stations_view() -> Dictionary:
	if _sview_ver != _ver:
		if economy != null:
			economy.sync_all(self)   # F-16: Rohstoffbestände nachziehen
		var out: Dictionary = {}
		for k in range(st_node.size()):
			out[st_node[k]] = {
				"name": st_name[k], "stock": st_stock[k], "produce_every": st_every[k],
				"produce_amount": st_amount[k], "delivered_total": st_delivered[k],
			}
		_sview = out
		_sview_ver = _ver
	return _sview


func station(node_id: int) -> Dictionary:
	return _get_stations_view()[node_id]


func has_station(node_id: int) -> bool:
	return _station_of.has(node_id)


## IDs der Fahrzeuge, die an diesem Lager abladen (Zulieferer). D9: n_lkw = size().
func station_suppliers(node_id: int) -> Array:
	_ensure()
	var out: Array = []
	for i in range(n):
		if v_ucount[i] > 0 and _has_node(u_nodes, v_ustart[i], v_ucount[i], node_id):
			out.append(v_id[i])
	return out


## Auf wen wartet das Fahrzeug? Halter-ID oder -1. Nimmt Fahrzeug-Dictionary (Spike-Signatur) oder ID.
func wait_target(v) -> int:
	_ensure()
	var i: int = _slot_of[v["id"] if v is Dictionary else int(v)]
	if v_state[i] == S_WARTET_BLOCK:
		var h := b_holder[v_wait_block[i]]
		return -1 if h == -1 else v_id[h]
	return -1


## Öffentliche Diagnose-API: siehe diagnostics.gd
func get_wait_chain(vehicle_id: int) -> Dictionary:
	_ensure()
	return Diagnostics.build_wait_chain(self, vehicle_id)


## Position eines Fahrzeugs in mm (Interpolation entlang der Kante, ganzzahlig, int64).
## Nimmt Fahrzeug-Dictionary (Spike-Signatur) oder ID.
func vehicle_pos(v) -> Vector2i:
	_ensure()
	return vehicle_pos_slot(_slot_of[v["id"] if v is Dictionary else int(v)])


func vehicle_pos_slot(i: int) -> Vector2i:
	var rs := v_rstart[i]
	var idx: int = mini(v_idx[i], v_rlen[i] - 1)
	var st := v_state[i]
	if st == S_UNTERWEGS:
		var pa: Vector2i = graph.nodes[r_from[rs + idx]]["pos"]
		var pb: Vector2i = graph.nodes[r_to[rs + idx]]["pos"]
		var length: int = r_len[rs + idx]
		var p: int = v_pos[i]
		return Vector2i(pa.x + (pb.x - pa.x) * p / length, pa.y + (pb.y - pa.y) * p / length)
	if st == S_WARTET_LADUNG or st == S_ENDE:
		return graph.nodes[r_to[rs + v_idx[i] - 1]]["pos"]
	return graph.nodes[r_from[rs + idx]]["pos"]


# =====================================================================================  Prüfsumme

## Deterministische Prüfsumme, identische Formel wie im Spike: Tick, je Fahrzeug (ID-Reihenfolge)
## id, state, idx, pos, cargo, held_block, wait_block, runs, waited_ticks_total; Lagerbestände nach
## Knoten-ID. FNV-1a-Variante auf Ganzzahlen (int64, Überlauf gewollt).
func checksum() -> int:
	_ensure()
	if economy != null:
		economy.sync_all(self)       # F-16: Rohstoffbestände nachziehen (lazy Produktion)
	var h: int = -3750763034362895579
	var prime: int = 1099511628211
	h = (h ^ tick_count) * prime
	for i in range(n):
		h = (h ^ (v_id[i] & 0xFFFFFFFF)) * prime
		h = (h ^ (v_state[i] & 0xFFFFFFFF)) * prime
		h = (h ^ (v_idx[i] & 0xFFFFFFFF)) * prime
		h = (h ^ (v_pos[i] & 0xFFFFFFFF)) * prime
		h = (h ^ (v_cargo[i] & 0xFFFFFFFF)) * prime
		h = (h ^ (v_held[i] & 0xFFFFFFFF)) * prime
		h = (h ^ (v_wait_block[i] & 0xFFFFFFFF)) * prime
		h = (h ^ (v_runs[i] & 0xFFFFFFFF)) * prime
		h = (h ^ (v_waited[i] & 0xFFFFFFFF)) * prime
	var snodes: Array = Array(st_node)
	snodes.sort()
	for nd in snodes:
		h = (h ^ (st_stock[_station_of[nd]] & 0xFFFFFFFF)) * prime
	if economy != null:
		h = (h ^ economy.checksum()) * prime   # F-16: ohne Ökonomie bleibt die Formel wie in S3
	return h


## Zustandsverteilung {GEPLANT, UNTERWEGS, WARTET_BLOCK, WARTET_LADUNG, ENDE} -> Anzahl.
func state_counts() -> Dictionary:
	var c := PackedInt32Array([0, 0, 0, 0, 0])
	for i in range(n):
		c[v_state[i]] += 1
	return {"GEPLANT": c[0], "UNTERWEGS": c[1], "WARTET_BLOCK": c[2], "WARTET_LADUNG": c[3], "ENDE": c[4]}
