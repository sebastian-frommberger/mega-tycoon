extends RefCounted
## F-18: Fahrzeug-Handle für den SoA-Kern (core/sim_world.gd, Linienbetrieb). Hält nur kalte Daten
## (Linie, Typ, Kaufpreis, Buchhaltung je Lieferung); der heiße Zustand (Position, Ladung, Zustand,
## Umschlag, gefahrene Felder) liegt in den Packed-Arrays des Kerns. Öffentliche Felder und Methoden wie
## vehicle.gd, damit main.gd, Linienliste, Panel und Tests unverändert lesen können.
## Wird nicht je Tick aufgerufen (kein tick()); main.gd ruft sim.step() und verarbeitet line_events.

const Vehicle := preload("res://vehicle.gd")
const SimWorld := preload("res://core/sim_world.gd")
const State := Vehicle.State

var sim = null                 # core/sim_world.gd
var fleet = null               # fleet_soa.gd
var vid := 0
var rindex := 0
var type := "truck"
var kind_name := "Lkw"
var src = null
var dst = null
var path := PackedVector2Array()   # nur für Abriss-Prüfung (_used_cells) und Distanz; nicht für die Sim
var cap := 10
var speed := 0.6               # Felder je Tick (Anzeige); Kern rechnet mm je Tick
var speed_mm := 600
var load_ticks := 100
var max_wait_ticks := 50
var fix_cent := 0
var var_cent_per_field := 0
var periode_ticks := 600
var leave_empty := false
var distance := 0
var group_key := ""
var paid_cent := 0
var sold := false
var buy_tick := 0              # sim.tick_count beim Kauf (Alter = tick_count − buy_tick, wie age_ticks)
var in_sim := false            # erst mit Linie im Kern
var income_total := 0
var deliveries := 0
var deliveries_profit := 0
var trip_start_age := 0
var trip_fields0 := 0          # v_fields bei der letzten Lieferung
var _stopped := false

var state: int:
	get = _get_state, set = _set_state
var prog: float:
	get = _get_prog
var no_licence: bool:
	get = _get_no_licence
var age_ticks: int:
	get: return sim.tick_count - buy_tick
var slot: int:
	get: return sim.slot_of(vid) if in_sim else -1


func assign(p_src, p_dst, cells: Array) -> void:
	src = p_src
	dst = p_dst
	path = PackedVector2Array()
	for c in cells:
		path.append(Vector2(c.x + 0.5, c.y + 0.5))
	distance = cells.size() - 1
	group_key = "%s|%s|%s" % [type, src.map_id, dst.map_id]
	fleet.add_line_vehicle(self, cells)
	in_sim = true


func _get_state() -> int:
	if _stopped or not in_sim:
		return State.IDLE
	var i: int = sim.slot_of(vid)
	match sim.v_state[i]:
		SimWorld.S_UNTERWEGS:
			return State.TO_SRC if sim.v_leg[i] == 1 else State.TO_DST
		SimWorld.S_WARTET_LADUNG:
			return State.LOADING
		SimWorld.S_ENTLADEN:
			return State.UNLOADING
	return State.IDLE


## Nur IDLE wird gesetzt (B-01 Linie auflösen): Fahrzeug im Kern stilllegen.
func _set_state(s: int) -> void:
	if s == State.IDLE and in_sim and not _stopped:
		sim.line_stop(vid)
		_stopped = true


## Position entlang der eigenen Linie in Feldern ab der Quelle (Anzeige/Tests).
func _get_prog() -> float:
	if not in_sim:
		return 0.0
	var i: int = sim.slot_of(vid)
	var rs: int = sim.v_rstart[i]
	var mm := 0
	for k in range(sim.v_idx[i]):
		mm += sim.r_len[rs + k]
	mm += sim.v_pos[i]
	var f: float = float(mm) / sim.feld_mm
	return float(distance) - f if sim.v_leg[i] == 1 else f


func _get_no_licence() -> bool:
	return in_sim and not _stopped and (sim.v_flags[sim.slot_of(vid)] & 2) != 0


func cargo(_m = null) -> int:
	return sim.v_cargo[sim.slot_of(vid)] if in_sim else 0


func fields_total() -> int:
	return sim.v_fields[sim.slot_of(vid)] if in_sim else 0


func cost_total() -> int:
	return age_ticks * fix_cent / periode_ticks + fields_total() * var_cent_per_field


func trip_cost() -> int:
	return (age_ticks - trip_start_age) * fix_cent / periode_ticks + (fields_total() - trip_fields0) * var_cent_per_field


## Nach einer Lieferung (aus sim.line_events): Buchhaltung wie vehicle.gd. Gibt trip_cost zurück.
func book_delivery(income: int) -> int:
	var tc := trip_cost()
	income_total += income
	deliveries += 1
	if income > tc:
		deliveries_profit += 1
	trip_start_age = age_ticks
	trip_fields0 = fields_total()
	return tc


func world_xz(_alpha: float) -> Vector3:
	return fleet.world_xz(self)


func profit_per_minute(ticks_per_min: int) -> float:
	return float(income_total - cost_total()) / 100.0 / maxf(float(age_ticks), 300.0) * ticks_per_min
