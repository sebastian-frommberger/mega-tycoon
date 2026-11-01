extends SceneTree
## F-05 Messhaken (Daniel Richter, QA). Misst Sim-ms pro Tick um SimWorld.step() nach benchmark_pruefplan.md.
## WARTET AUF FELIX' BENCHMARK-SZENE: build_scene() unten ist ein PLATZHALTER (K1-Layout n-fach kopiert),
## kein Benchmark-Netz. Zahlen aus dem Platzhalter sind eine Funktionsprobe des Hakens, KEIN F-05-Messwert.
## Aufruf: godot --headless --path <kopie> --script res://daniel_f05_messhaken.gd -- <n_fahrzeuge> <ticks> <warmup_ticks> [ausgabe.csv]
## Ausgabe: N, Median, p95 (Nearest-Rank), Max, Mittel, Anteil > 4 ms, End-Pruefsumme (Zaehler-Ersatz, Sim hat keine).

const SimWorld := preload("res://sim_world.gd")
const SEG := 200000


## PLATZHALTER. Felix ersetzt diese Funktion durch den Aufbau seiner F-05-Szene (gleiche Signatur).
static func build_scene(n_vehicles: int):
	var s = SimWorld.new()
	var copies := int(ceil(n_vehicles / 2.0))
	var vid := 1
	for c in range(copies):
		var n0 := c * 4
		for i in range(4):
			s.graph.add_node(n0 + i, Vector2i(i * SEG, c * SEG), "K%d_%d" % [c, i])
		var e0 := c * 5
		s.graph.add_edge(e0 + 1, n0, n0 + 1)
		s.graph.add_edge(e0 + 2, n0 + 1, n0 + 2)
		s.graph.add_edge(e0 + 3, n0 + 2, n0 + 3)
		s.graph.add_edge(e0 + 5, n0 + 1, n0 + 2)
		var r1: Array = [{"edge": e0 + 1, "fwd": true}, {"edge": e0 + 2, "fwd": true}, {"edge": e0 + 3, "fwd": true}]
		var r2: Array = [{"edge": e0 + 3, "fwd": false}, {"edge": e0 + 5, "fwd": false}, {"edge": e0 + 1, "fwd": false}]
		s.add_vehicle(vid, "Z%d" % vid, r1, 4000, c % 17, [], 10, true)
		vid += 1
		if vid <= n_vehicles:
			s.add_vehicle(vid, "Z%d" % vid, r2, 5000, (c * 7) % 23, [], 10, true)
			vid += 1
	return s


static func checksum(s) -> String:
	# Ersatz-Pruefsumme (Sim liefert keine): Zaehler ueber alle Fahrzeuge, deterministisch
	var moving := 0
	var waiting := 0
	var runs := 0
	var pos_sum := 0
	for id in s.vehicles:
		var v: Dictionary = s.vehicles[id]
		if v["state"] == SimWorld.VState.UNTERWEGS:
			moving += 1
		elif v["state"] == SimWorld.VState.WARTET_BLOCK or v["state"] == SimWorld.VState.WARTET_LADUNG:
			waiting += 1
		runs += int(v["runs"])
		pos_sum = (pos_sum + int(v["pos"]) + int(v["idx"]) * 7919) % 2147483647
	return "tick=%d;fahrend=%d;wartend=%d;laeufe=%d;possum=%d;ereignisse=%d" % [s.tick_count, moving, waiting, runs, pos_sum, s.deadlock_events.size()]


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var n := int(a[0]) if a.size() > 0 else 1000
	var ticks := int(a[1]) if a.size() > 1 else 3000
	var warm := int(a[2]) if a.size() > 2 else 300
	var out := a[3] if a.size() > 3 else ""
	print("== F-05 Messhaken (Daniel) | Godot %s | %d Prozessoren | %s | Fahrzeuge %d, Ticks %d (+%d Warm-up) ==" % [
		Engine.get_version_info()["string"], OS.get_processor_count(), OS.get_name(), n, ticks, warm])
	print("ACHTUNG: Platzhalter-Szene, Sandbox (2 vCPU, keine GPU), Editor-Binary. Kein F-05-Messwert.")
	var s = build_scene(n)
	var samples: PackedFloat64Array = PackedFloat64Array()
	var warm_samples: PackedFloat64Array = PackedFloat64Array()
	for t in range(warm + ticks):
		var t0 := Time.get_ticks_usec()
		s.step()
		var dt := (Time.get_ticks_usec() - t0) / 1000.0
		if t < warm:
			warm_samples.append(dt)
		else:
			samples.append(dt)
	print("Stichprobe Zustand Tick 100: " + sample_state(s))
	var sorted := samples.duplicate()
	sorted.sort()
	var N := sorted.size()
	var median: float = sorted[N / 2] if N % 2 == 1 else (sorted[N / 2 - 1] + sorted[N / 2]) / 2.0
	var p95: float = sorted[int(ceil(0.95 * N)) - 1]
	var mx: float = sorted[N - 1]
	var mean := 0.0
	var over4 := 0
	for v in samples:
		mean += v
		if v > 4.0:
			over4 += 1
	mean /= N
	var line := "N=%d;median_ms=%.3f;p95_ms=%.3f;max_ms=%.3f;mittel_ms=%.3f;anteil_ueber_4ms=%.4f;warmup_median_ms=%.3f;pruefsumme=%s" % [
		N, median, p95, mx, mean, float(over4) / N, warm_median(warm_samples), checksum(s)]
	print(line)
	if out != "":
		var f := FileAccess.open(out, FileAccess.WRITE_READ if not FileAccess.file_exists(out) else FileAccess.READ_WRITE)
		f.seek_end()
		f.store_line("%d;%d;%s" % [n, ticks, line])
		f.close()
	quit(0)


func warm_median(w: PackedFloat64Array) -> float:
	if w.is_empty():
		return 0.0
	var c := w.duplicate()
	c.sort()
	return c[c.size() / 2]


func sample_state(s) -> String:
	var counts := {}
	for id in s.vehicles:
		var st: int = s.vehicles[id]["state"]
		counts[st] = int(counts.get(st, 0)) + 1
	return "Zustaende (0 geplant,1 unterwegs,2 wartet Block,3 wartet Ladung,4 Ende): %s" % str(counts)
