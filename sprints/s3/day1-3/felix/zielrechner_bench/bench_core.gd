extends Node
## ZIELRECHNER-VARIANTE (Node-Szene, Muster _bench/bench_soa): Szene res://_bench/bench_core.tscn mit F6/Play starten.
## Ausgabe zusätzlich in res://_bench/<out_name>_out.txt (inkl. Prüfsummen je Lauf). Beendet sich selbst.
## F-10/F-11 Bench-Runner für den SoA-Kern (sim_world.gd, Sprint 3) inklusive ereignisgesteuerter
## Deadlock-Prüfung. Welt: bench_world.gd unverändert (gleicher Generator, gleicher Seed 1001 + n wie F-05).
## Aufruf (Sandbox, headless):
##   (Zielrechner) Szene res://_bench/bench_core.tscn starten; optional Kommandozeile wie Sandbox:
##   godot --path <projekt> res://_bench/bench_core.tscn -- [--vehicles=1000,5000,10000] [--ticks=3000]
##        [--warmup=300] [--runs=3] [--seed=1001]
## Messgröße: Dauer von SimWorld.step() je Tick (Time.get_ticks_usec davor/danach), enthält
## Fahrzeugschritt UND Deadlock-Prüfung; beide zusätzlich getrennt (profile_usec).
## Reihenfolge: Runde 1 über alle Größen, dann Runde 2, dann Runde 3 (wie F-05).
## 8x-Frame: Summe von je 8 aufeinanderfolgenden Ticks desselben Laufs (kein eigener Lauf).
## Prüfsumme nach Warm-up + Ticks wird je Lauf ausgegeben; Determinismus = gleiche Summe in allen Runden.

const BenchWorld := preload("res://_bench/bench_world_soa.gd")

@export var out_name := "bench_core"
var vehicles_list: Array = [1000, 5000, 10000]
@export var ticks := 3000
var warmup := 300
var runs := 3
var seed_base := 1001
var checksums: Dictionary = {}  # n -> Array der Prüfsummen je Runde


func _ready() -> void:
	_bench_main()
	get_tree().quit(0)


func _bench_main() -> void:
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=")
		if kv.size() != 2:
			continue
		match kv[0]:
			"--vehicles": vehicles_list = Array(kv[1].split(",")).map(func(x): return int(x))
			"--ticks": ticks = int(kv[1])
			"--warmup": warmup = int(kv[1])
			"--runs": runs = int(kv[1])
			"--seed": seed_base = int(kv[1])
	var build_label: String = "editor" if OS.has_feature("editor") else ("release-export" if OS.has_feature("release") else "debug-export")
	_log("== F-10/F-11 Bench SoA-Kern mit Deadlock-Prüfung, Godot %s, Build %s, CPU %s (%d Kerne), OS %s, Ticks %d (+%d Warm-up), %d Runden ==" % [
		Engine.get_version_info()["string"], build_label, OS.get_processor_name(), OS.get_processor_count(), OS.get_name(), ticks, warmup, runs])
	_log("config,run,ticks,setup_ms,median_ms,p95_ms,p99_ms,max_ms,mean_ms,share_gt4ms,share_gt6ms,veh_median_ms,dl_median_ms,dl_p99_ms,dl_max_ms,frame8_median_ms,frame8_p95_ms,moving_t2000,waiting_t2000,deadlock_events,dl_walks,dl_visits,checksum")
	var t_all := Time.get_ticks_msec()
	for run in range(1, runs + 1):
		for nv in vehicles_list:
			_run_one(int(nv), run)
	for nv in vehicles_list:
		var cs: Array = checksums.get(int(nv), [])
		var same := true
		for c in cs:
			same = same and c == cs[0]
		_log("Determinismus %dk: Prüfsummen %s -> %s" % [int(nv) / 1000, str(cs), "IDENTISCH" if same else "ABWEICHEND"])
	_log("== fertig, Wanduhr %d s ==" % [(Time.get_ticks_msec() - t_all) / 1000])


static func _pct(sorted: Array, q: float) -> float:
	var n := sorted.size()
	if n == 0:
		return 0.0
	return float(sorted[clampi(ceili(q * n) - 1, 0, n - 1)]) / 1000.0


static func _median(sorted: Array) -> float:
	var n := sorted.size()
	if n == 0:
		return 0.0
	if n % 2 == 1:
		return float(sorted[n / 2]) / 1000.0
	return float(sorted[n / 2 - 1] + sorted[n / 2]) / 2000.0


func _run_one(nv: int, run: int) -> void:
	var t0 := Time.get_ticks_usec()
	var world: Dictionary = BenchWorld.new().build(nv, seed_base + nv)
	var sim = world["sim"]
	var setup_ms: float = (Time.get_ticks_usec() - t0) / 1000.0
	var samples: Array = []
	var veh: Array = []
	var dl: Array = []
	var frames: Array = []
	var acc := 0
	var moving := -1
	var waiting := -1
	for i in range(warmup + ticks):
		var a := Time.get_ticks_usec()
		sim.step()
		var d := Time.get_ticks_usec() - a
		if i >= warmup:
			samples.append(d)
			veh.append(int(sim.profile_usec["vehicles"]))
			dl.append(int(sim.profile_usec["deadlock"]))
			acc += d
			if (i - warmup + 1) % 8 == 0:
				frames.append(acc)
				acc = 0
		if sim.tick_count == 2000:
			var sc: Dictionary = sim.state_counts()
			moving = sc["UNTERWEGS"]
			waiting = sc["WARTET_BLOCK"]
	samples.sort()
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
	var cs: int = sim.checksum()
	if not checksums.has(nv):
		checksums[nv] = []
	checksums[nv].append(cs)
	_log("%dk,%d,%d,%.1f,%.3f,%.3f,%.3f,%.3f,%.3f,%.4f,%.4f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%d,%d,%d,%d,%d,%d" % [
		nv / 1000, run, n, setup_ms, _median(samples), _pct(samples, 0.95), _pct(samples, 0.99),
		float(samples[-1]) / 1000.0, float(sum) / n / 1000.0, float(gt4) / n, float(gt6) / n,
		_median(veh), _median(dl), _pct(dl, 0.99), float(dl[-1]) / 1000.0,
		_median(frames), _pct(frames, 0.95), moving, waiting,
		sim.deadlock_events.size(), sim.dl_walks, sim.dl_visits, cs])


var _logf: FileAccess = null

func _log(s: String) -> void:
	print(s)
	if _logf == null:
		_logf = FileAccess.open("res://_bench/%s_out.txt" % out_name, FileAccess.WRITE)
	if _logf != null:
		_logf.store_line(s)
		_logf.flush()
