extends SceneTree
## F-05 Zusatzmessung: Untergrenze für einen GDScript-Sim-Kern in Struct-of-Arrays-Form
## (PackedInt32Array je Feld, flache Routen, keine Dictionaries), wie im technischen Konzept geplant.
## Dieselbe Welt wie bench_runner.gd (BenchWorld, gleicher Seed), dieselben Regeln für Bewegung und
## Blockreservierung (Hold-and-Wait), aber OHNE Deadlock-Prüfung, ohne Lager, ohne Diagnose.
## Zweck: zeigt, wie viel vom Spike-Wert Datenlayout ist und wie viel GDScript selbst.
## Zählt nicht als G2-Messwert (Sandbox, Editor-Binary, reduzierte Regeln). Aufruf:
##   godot --headless --path . --script res://bench_soa.gd -- [--vehicles=1000,5000,10000] [--ticks=3000] [--warmup=300] [--runs=3]

const BenchWorld := preload("res://bench_world.gd")

var vehicles_list: Array = [1000, 5000, 10000]
var ticks := 3000
var warmup := 300
var runs := 3

const ST_PLANNED := 0
const ST_MOVING := 1
const ST_WAIT := 2

# SoA
var n := 0
var v_state := PackedInt32Array()
var v_idx := PackedInt32Array()
var v_pos := PackedInt32Array()
var v_speed := PackedInt32Array()
var v_held := PackedInt32Array()
var v_start := PackedInt32Array()
var v_rstart := PackedInt32Array()   # Index in r_block/r_len
var v_rlen := PackedInt32Array()
var r_block := PackedInt32Array()    # flache Routen: Block-ID je Schritt
var r_len := PackedInt32Array()      # Kantenlänge je Schritt
var block_holder := PackedInt32Array()
var tick := 0


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=")
		if kv.size() != 2:
			continue
		match kv[0]:
			"--vehicles": vehicles_list = Array(kv[1].split(",")).map(func(x): return int(x))
			"--ticks": ticks = int(kv[1])
			"--warmup": warmup = int(kv[1])
			"--runs": runs = int(kv[1])
	print("== F-05 SoA-Untergrenze (ohne Deadlock-Prüfung), Godot %s, CPU %s (%d Kerne), Ticks %d (+%d), %d Runden ==" % [
		Engine.get_version_info()["string"], OS.get_processor_name(), OS.get_processor_count(), ticks, warmup, runs])
	print("config,run,ticks,median_ms,p95_ms,max_ms,moving_t2000,waiting_t2000")
	for run in range(1, runs + 1):
		for nv in vehicles_list:
			_run_one(int(nv), run)
	quit(0)


func _load(world: Dictionary) -> void:
	var sim = world["sim"]
	var g = sim.graph
	n = sim.vehicles.size()
	v_state.resize(n); v_idx.resize(n); v_pos.resize(n); v_speed.resize(n); v_held.resize(n)
	v_start.resize(n); v_rstart.resize(n); v_rlen.resize(n)
	r_block = PackedInt32Array(); r_len = PackedInt32Array()
	block_holder.resize(g.blocks.size() + 1)
	block_holder.fill(-1)
	for id in sim.sorted_ids():
		var v: Dictionary = sim.vehicles[id]
		v_state[id] = ST_PLANNED
		v_idx[id] = 0
		v_pos[id] = 0
		v_speed[id] = v["speed"]
		v_held[id] = -1
		v_start[id] = v["start_tick"]
		v_rstart[id] = r_block.size()
		v_rlen[id] = v["route"].size()
		for s in v["route"]:
			r_block.append(g.block_of(s["edge"], s["fwd"]))
			r_len.append(g.edges[s["edge"]]["length"])
	tick = 0


func _step() -> void:
	tick += 1
	for i in range(n):
		var st := v_state[i]
		if st == ST_MOVING:
			var ri := v_rstart[i] + v_idx[i]
			var p := v_pos[i] + v_speed[i]
			if p >= r_len[ri]:
				# Ankunft: nächster Schritt (Rundkurs: Index modulo Länge), Block anfordern
				var ni := v_idx[i] + 1
				if ni >= v_rlen[i]:
					ni = 0
				v_idx[i] = ni
				_try_enter(i)
			else:
				v_pos[i] = p
		elif st == ST_WAIT:
			_try_enter(i)
		elif st == ST_PLANNED and tick >= v_start[i]:
			_try_enter(i)


func _try_enter(i: int) -> void:
	var b := r_block[v_rstart[i] + v_idx[i]]
	var h := block_holder[b]
	if h == -1 or h == i:
		var held := v_held[i]
		if held != -1 and held != b:
			block_holder[held] = -1
		block_holder[b] = i
		v_held[i] = b
		v_state[i] = ST_MOVING
		v_pos[i] = 0
	else:
		v_state[i] = ST_WAIT


func _run_one(nv: int, run: int) -> void:
	var world: Dictionary = BenchWorld.new().build(nv, 1001 + nv)
	_load(world)
	var samples: Array = []
	var moving := 0
	var waiting := 0
	for t in range(warmup + ticks):
		var a := Time.get_ticks_usec()
		_step()
		var d := Time.get_ticks_usec() - a
		if t >= warmup:
			samples.append(d)
		if tick == 2000:
			for i in range(n):
				if v_state[i] == ST_MOVING:
					moving += 1
				elif v_state[i] == ST_WAIT:
					waiting += 1
	samples.sort()
	var N := samples.size()
	var med: float = (float(samples[N / 2 - 1] + samples[N / 2]) / 2000.0) if N % 2 == 0 else float(samples[N / 2]) / 1000.0
	var p95: float = float(samples[clampi(ceili(0.95 * N) - 1, 0, N - 1)]) / 1000.0
	print("%dk-SoA,%d,%d,%.3f,%.3f,%.3f,%d,%d" % [nv / 1000, run, N, med, p95, float(samples[-1]) / 1000.0, moving, waiting])
