extends SceneTree
## F-05 Benchmark-Runner (reine Sim, headless). Aufruf:
##   godot --headless --path <spike> --script res://bench_runner.gd -- [--vehicles=1000,5000,10000]
##        [--speeds=1,8] [--ticks=3000] [--warmup=300] [--runs=3] [--seed=1001] [--out=res://bench_results.csv]
##        [--order=rotate]
##
## Messgröße: Sim-ms pro Tick = Dauer von SimWorld.step() (Time.get_ticks_usec davor/danach).
## Enthält Fahrzeugschritt und Deadlock-Prüfung; beide werden zusätzlich getrennt ausgewiesen
## (SimWorld.profile_usec). Nicht enthalten: Rendering, UI, Log, Dateischreiben.
## Pacing: "Frame" = 1 Tick bei 1×, 8 Ticks bei 8×. Es wird nicht geschlafen, die Sim läuft so schnell
## wie möglich; pro Tick ist 1× deshalb gleich 8×, der Unterschied liegt im Frame-Wert (Summe).
## Warm-up: die ersten --warmup Ticks werden verworfen und separat berichtet.
## Reihenfolge (Daniel, Abschnitt 2): Runde 1 über alle Konfigurationen, dann Runde 2, dann Runde 3.
## Abweichung vom Prüfplan: feste Tickzahl statt 5 min Wanduhr (Sandbox, siehe f05_benchmark.md).
## Kennzahlen: N, Median, p95 (Nearest-Rank ⌈0,95·N⌉), Max, Mittel, Anteil > 4 ms, Anteil > 6 ms,
## Frame-Median/p95 (bei 8× Summe von 8 Ticks), Zustandsverteilung Tick 100/2000, End-Prüfsumme.

const BenchWorld := preload("res://bench_world.gd")

var vehicles_list: Array = [1000, 5000, 10000]
var speeds: Array = [1, 8]
var ticks := 3000
var warmup := 300
var runs := 3
var seed_base := 1001
var out_path := "res://bench_results.csv"


func _init() -> void:
	_parse_args()
	var build_label: String = "editor-headless" if OS.has_feature("editor") else ("release-export" if OS.has_feature("release") else "debug-export")
	var header := "config,vehicles,speed,run,seed,build,godot,cpu,cores,n_nodes,n_edges,n_blocks,ticks_measured,warmup_ticks,setup_ms,median_ms,p95_ms,max_ms,mean_ms,share_gt4ms,share_gt6ms,frame_ticks,frame_median_ms,frame_p95_ms,veh_median_ms,deadlock_median_ms,warmup_median_ms,moving_t100,waiting_t100,moving_t2000,waiting_t2000,deadlock_events,checksum,wall_s"
	var fa := FileAccess.open(out_path, FileAccess.WRITE)
	fa.store_line(header)
	fa.close()
	print("== F-05 Benchmark, Godot %s, Build %s, CPU %s (%d Kerne), Ticks %d (+%d Warm-up), %d Runden ==" % [
		Engine.get_version_info()["string"], build_label, OS.get_processor_name(), OS.get_processor_count(), ticks, warmup, runs])
	print("Konfigurationen: Fahrzeuge %s, Tempo %s" % [str(vehicles_list), str(speeds)])
	var t_all := Time.get_ticks_msec()
	for run in range(1, runs + 1):
		for nv in vehicles_list:
			for sp in speeds:
				var row := _run_one(int(nv), int(sp), run, build_label)
				var f := FileAccess.open(out_path, FileAccess.READ_WRITE)
				f.seek_end()
				f.store_line(row)
				f.close()
	print("== fertig, Wanduhr gesamt %d s, Ergebnis %s ==" % [(Time.get_ticks_msec() - t_all) / 1000, out_path])
	quit(0)


func _parse_args() -> void:
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=")
		if kv.size() != 2:
			continue
		match kv[0]:
			"--vehicles":
				vehicles_list = Array(kv[1].split(",")).map(func(x): return int(x))
			"--speeds":
				speeds = Array(kv[1].split(",")).map(func(x): return int(x))
			"--ticks":
				ticks = int(kv[1])
			"--warmup":
				warmup = int(kv[1])
			"--runs":
				runs = int(kv[1])
			"--seed":
				seed_base = int(kv[1])
			"--out":
				out_path = kv[1]


static func _percentile(sorted: Array, q: float) -> float:
	var n := sorted.size()
	if n == 0:
		return 0.0
	var k: int = clampi(ceili(q * n) - 1, 0, n - 1)
	return float(sorted[k]) / 1000.0


static func _median(sorted: Array) -> float:
	var n := sorted.size()
	if n == 0:
		return 0.0
	if n % 2 == 1:
		return float(sorted[n / 2]) / 1000.0
	return float(sorted[n / 2 - 1] + sorted[n / 2]) / 2000.0


func _run_one(nv: int, sp: int, run: int, build_label: String) -> String:
	var seed: int = seed_base + nv  # je Größe fester Seed (Daniel: 1001/5001/10001), gleich für alle Läufe
	var t_wall := Time.get_ticks_msec()
	var t0 := Time.get_ticks_usec()
	var world: Dictionary = BenchWorld.new().build(nv, seed)
	var sim = world["sim"]
	var setup_ms: float = (Time.get_ticks_usec() - t0) / 1000.0
	var samples: Array = []     # usec je Tick (Messfenster)
	var warm: Array = []        # usec je Tick (Warm-up)
	var veh: Array = []
	var dl: Array = []
	var frames: Array = []      # usec je Frame (sp Ticks)
	var total := warmup + ticks
	var frame_acc := 0
	var moving100 := -1
	var waiting100 := -1
	var moving2000 := -1
	var waiting2000 := -1
	for i in range(total):
		var a := Time.get_ticks_usec()
		sim.step()
		var d := Time.get_ticks_usec() - a
		if i < warmup:
			warm.append(d)
		else:
			samples.append(d)
			veh.append(int(sim.profile_usec["vehicles"]))
			dl.append(int(sim.profile_usec["deadlock"]))
			frame_acc += d
			if (i - warmup + 1) % sp == 0:
				frames.append(frame_acc)
				frame_acc = 0
		if sim.tick_count == 100 or sim.tick_count == 2000:
			var sc: Dictionary = sim.state_counts()
			if sim.tick_count == 100:
				moving100 = sc["UNTERWEGS"]
				waiting100 = sc["WARTET_BLOCK"]
			else:
				moving2000 = sc["UNTERWEGS"]
				waiting2000 = sc["WARTET_BLOCK"]
	samples.sort()
	warm.sort()
	veh.sort()
	dl.sort()
	frames.sort()
	var sum := 0
	var gt4 := 0
	var gt6 := 0
	for s in samples:
		sum += s
		if s > 4000:
			gt4 += 1
		if s > 6000:
			gt6 += 1
	var n := samples.size()
	var median := _median(samples)
	var p95 := _percentile(samples, 0.95)
	var wall_s: float = (Time.get_ticks_msec() - t_wall) / 1000.0
	var cfg := "%dk/%dx" % [nv / 1000, sp]
	print("%s Lauf %d: N=%d Median %.3f ms, p95 %.3f ms, Max %.3f ms, >4ms %.1f %%, Frame(%d Ticks) Median %.3f ms p95 %.3f ms | Fahrzeuge %.3f, Deadlock-Prüfung %.3f (Mediane) | unterwegs/wartend T100 %d/%d, T2000 %d/%d | Ereignisse %d | Wanduhr %.0f s" % [
		cfg, run, n, median, p95, float(samples[-1]) / 1000.0, 100.0 * gt4 / n, sp, _median(frames), _percentile(frames, 0.95),
		_median(veh), _median(dl), moving100, waiting100, moving2000, waiting2000, sim.deadlock_events.size(), wall_s])
	return ",".join(PackedStringArray([
		cfg, str(nv), str(sp), str(run), str(seed), build_label, Engine.get_version_info()["string"],
		"\"" + OS.get_processor_name() + "\"", str(OS.get_processor_count()),
		str(world["n_nodes"]), str(world["n_edges"]), str(world["n_blocks"]),
		str(n), str(warmup), "%.1f" % setup_ms,
		"%.3f" % median, "%.3f" % p95, "%.3f" % (float(samples[-1]) / 1000.0), "%.3f" % (float(sum) / n / 1000.0),
		"%.4f" % (float(gt4) / n), "%.4f" % (float(gt6) / n),
		str(sp), "%.3f" % _median(frames), "%.3f" % _percentile(frames, 0.95),
		"%.3f" % _median(veh), "%.3f" % _median(dl), "%.3f" % _median(warm),
		str(moving100), str(waiting100), str(moving2000), str(waiting2000),
		str(sim.deadlock_events.size()), str(sim.checksum()), "%.1f" % wall_s,
	]))
