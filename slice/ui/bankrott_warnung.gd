extends RefCounted
## U-03 K1/K2 (S7, Mira): Bankrott-Vorwarnung mit größtem Verlustposten – nur Text (A-08 Diagnose-Toast folgt S8).
## Prognose: Kasse ÷ Betriebs-Saldo je Tick der letzten 2 Spielminuten. Betriebs-Saldo = Kassenänderung innerhalb von
## main.sim_tick (Erträge, Fahrkosten, Unterhalt, Zins, Lizenzverlängerung); Käufe/Bau des Spielers zählen nicht.
## Warnung, sobald die Prognose ≤ WARN_SEC fällt (Puffer über den geforderten 60 s), Wiederholung einmal je Spielminute,
## Ende, wenn die Prognose über CLEAR_SEC steigt oder der Saldo nicht mehr negativ ist.
## Rein lesend: verändert keinen Sim-Wert (Parität/Determinismus bleiben).

const FT := preload("res://ui/fehlertexte.gd")
const BUCKET_TICKS := 100        # 10 s bei 100 ms/Tick
const WINDOW_BUCKETS := 12       # 2 Spielminuten
const MIN_TICKS := 300           # erst ab 30 s Daten prognostizieren
const WARN_SEC := 90.0
const CLEAR_SEC := 150.0

var buckets: Array = []          # [Saldo Cent, Ticks]
var cur_sum := 0
var cur_n := 0
var active := false
var last_warn_tick := -100000
var warn_ticks: Array = []       # Testspur: Ticks der ausgegebenen Warnungen
var last_text := ""
var last_posten := {}            # {"name", "cent_min"}
var last_t_sec := -1


## Je Sim-Tick aus main.sim_tick (delta = Kassenänderung in diesem Tick).
func tick(m, delta: int) -> void:
	cur_sum += delta
	cur_n += 1
	if cur_n >= BUCKET_TICKS:
		buckets.append([cur_sum, cur_n])
		if buckets.size() > WINDOW_BUCKETS:
			buckets.pop_front()
		cur_sum = 0
		cur_n = 0
	if m.shim.tick_count % 10 != 0:
		return
	var t := forecast_sec(m)
	last_t_sec = t
	if t < 0 or t > CLEAR_SEC:
		active = false
		return
	if t > WARN_SEC and not active:
		return
	active = true
	if m.shim.tick_count - last_warn_tick >= m.periode_ticks:
		last_warn_tick = m.shim.tick_count
		warn_ticks.append(m.shim.tick_count)
		last_posten = biggest_loss(m)
		last_text = FT.k1_vorwarnung(m, t, last_posten["name"], last_posten["cent_min"])
		m._toast(last_text, 6.0)


## Saldo je Tick (Cent) über das Fenster, 0 bei zu wenig Daten.
func net_per_tick() -> float:
	var s := cur_sum
	var n := cur_n
	for b in buckets:
		s += b[0]
		n += b[1]
	if n < MIN_TICKS:
		return 0.0
	return float(s) / float(n)


## Spielsekunden bis 0 $ bei aktuellem Verlauf, -1 = kein Verlust.
func forecast_sec(m) -> int:
	var net := net_per_tick()
	if net >= 0.0:
		return -1
	var ticks := float(maxi(m.eco.cash_cent, 0)) / -net
	return int(ticks * m.tick_ms / 1000.0)


## Größter negativer Posten je Spielminute: Linie (netto), Fahrzeuge ohne Linie, Gleisunterhalt, Lager, Kreditzins.
func biggest_loss(m) -> Dictionary:
	var per_min: float = float(m.month_ticks) / float(m.periode_ticks)
	var cands: Array = []
	for key in m.line_order:
		var p: float = m._line_profit(m.line_groups[key])     # $/min
		if p < 0.0:
			cands.append({"name": m.line_title(key), "cent_min": int(round(-p * 100.0))})
	var idle_fix := 0
	var idle_n := 0
	for v in m.vehicles:
		if not v.sold and v.state == m.Vehicle.State.IDLE and v.fix_cent > 0:
			idle_fix += v.fix_cent
			idle_n += 1
	if idle_n > 0:
		cands.append({"name": "%d Fahrzeug%s ohne Linie" % [idle_n, "" if idle_n == 1 else "e"], "cent_min": int(idle_fix * per_min)})
	if m.rails.size() * m.rail_upkeep_per_field > 0:
		cands.append({"name": "Gleisunterhalt", "cent_min": int(m.rails.size() * m.rail_upkeep_per_field * per_min)})
	if m.warehouse_count * m.warehouse_upkeep > 0:
		cands.append({"name": "Lager", "cent_min": int(m.warehouse_count * m.warehouse_upkeep * per_min)})
	if m.credit.interest_per_period() > 0:
		cands.append({"name": "Kreditzins", "cent_min": int(m.credit.interest_per_period() * per_min)})
	var best := {"name": "laufende Kosten", "cent_min": int(m.running_cost_per_period * per_min)}
	for c in cands:
		if c["cent_min"] > int(best.get("_v", -1)):
			best = c
			best["_v"] = c["cent_min"]
	best.erase("_v")
	return best
