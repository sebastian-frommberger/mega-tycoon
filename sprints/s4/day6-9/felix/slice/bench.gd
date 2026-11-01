extends Node
## F-12 Bench: läuft im selben Spiel (main.tscn) auf der Slice-Karte, wenn
##   - die exportierte .exe das Feature "bench" hat (Preset „Windows Desktop Bench“, Doppelklick genügt) oder
##   - mit Argument --bench gestartet wird (auch: godot --path slice -- --bench).
## Ablauf: Karte laden (Zeit messen), 5.000 Lkw (Spiel-Fahrzeuge, vehicle.gd + economy.gd) auf Straßen-
## Korridoren zwischen Lagern, VSync aus, 3 s Aufwärmen, dann 3 Läufe à RUN_SEC Sekunden bei Tempo 1×.
## Ergebnis als Textdatei neben die .exe (OS.get_executable_path().get_base_dir()), Fallback user://.
## Optionen (nach --): --bench-out=<pfad>, --bench-units=<n>, --bench-sec=<s>.
## Grenze: Lkw fahren auch leer weiter (leave_empty), damit alle 5.000 Einheiten in Bewegung sind; Ladung
## und Ertrag laufen über economy.gd wie im Spiel (Ledger aus).

const RUNS := 3
const WARMUP_SEC := 3.0
const CORRIDOR_LEN := 70

var m = null
var units := 5000
var run_sec := 15.0
var out_path := ""
var phase := "warmup"
var t := 0.0
var run_idx := 0
var frame_times: Array = []
var proc_times: Array = []
var sec_acc := 0.0
var sec_frames := 0
var fps_samples: Array = []
var results: Array = []
var corridors := 0
var setup_ms := 0.0
var last_us := 0


func start(main) -> void:
	m = main
	for a in OS.get_cmdline_user_args() + OS.get_cmdline_args():
		if a.begins_with("--bench-out="):
			out_path = a.substr(12)
		elif a.begins_with("--bench-units="):
			units = int(a.substr(14))
		elif a.begins_with("--bench-sec="):
			run_sec = float(a.substr(12))
	if out_path == "":
		out_path = OS.get_executable_path().get_base_dir().path_join("mega_tycoon_bench.txt")
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var t0 := Time.get_ticks_usec()
	m.start_game("agrar")
	m.toast_time = 0.0
	m.toast_label.text = "BENCH läuft – bitte warten (ca. %d s)" % int(WARMUP_SEC + RUNS * run_sec)
	m.eco.ledger_enabled = false
	m.eco.cash_cent = 1000000000000      # nur Bench: Geld spielt keine Rolle
	_build_traffic()
	setup_ms = (Time.get_ticks_usec() - t0) / 1000.0
	m.focus(Vector2(m.GRID * 0.5, m.GRID * 0.55), 15.0)
	m.set_speed(1)
	print("BENCH setup: %d Fahrzeuge auf %d Korridoren, %.0f ms" % [m.vehicles.size(), corridors, setup_ms])


func _free_run(y: int, x0: int) -> bool:
	for x in range(x0, x0 + CORRIDOR_LEN):
		for dy in [0, 1]:
			var c := Vector2i(x, y + dy)
			if not m._in_grid(c) or m.terrain_at(c) != m.Terrain.PLAIN or m.cell_to_building.has(c) or m.city_streets.has(c) or m.roads.has(c):
				return false
	return true


func _build_traffic() -> void:
	var pairs: Array = []
	var y := 12
	while y < m.GRID - 12 and pairs.size() * 100 < units:
		var x := 4
		while x + CORRIDOR_LEN < m.GRID - 4:
			if _free_run(y, x):
				var a = m.build_warehouse(Vector2i(x, y))
				var b = m.build_warehouse(Vector2i(x + CORRIDOR_LEN - 2, y))
				if a != null and b != null:
					m._set_tool(m.Tool.ROAD)
					m.build_track(Vector2i(x + 1, y), Vector2i(x + CORRIDOR_LEN - 2, y), false)
					m.eco.seed_stock(a.site, "getreide", 200)
					m.eco.seed_stock(b.site, "getreide", 200)
					var p1: Array = Array(m.astar_road.get_id_path(a.anchor(), b.anchor()))
					var p2: Array = Array(m.astar_road.get_id_path(b.anchor(), a.anchor()))
					if not p1.is_empty() and not p2.is_empty():
						pairs.append([a, b, p1, p2])
				x += CORRIDOR_LEN + 2
			else:
				x += 7
		y += 6
	corridors = pairs.size()
	m._set_tool(m.Tool.NONE)
	if pairs.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 47
	for i in units:
		var pr: Array = pairs[i % pairs.size()]
		var fwd := (i / pairs.size()) % 2 == 0
		var v = m.buy_vehicle("truck")
		if v == null:
			break
		if fwd:
			v.assign(pr[0], pr[1], pr[2])
		else:
			v.assign(pr[1], pr[0], pr[3])
		m.register_line(v)
		v.leave_empty = true
		v.max_wait_ticks = 5
		v.prog = rng.randf_range(0.0, float(v.path.size() - 1))
		v.state = v.State.TO_DST if rng.randf() < 0.5 else v.State.TO_SRC


## Frame-Zeit aus der Wanduhr (delta ist in Godot bei langsamen Frames auf 8 Physik-Schritte gedeckelt).
func _process(_delta: float) -> void:
	if m == null:
		return
	var now := Time.get_ticks_usec()
	var delta := (now - last_us) / 1e6 if last_us > 0 else 0.0
	last_us = now
	t += delta
	if phase == "warmup":
		if t >= WARMUP_SEC:
			_begin_run()
		return
	if phase != "run":
		return
	frame_times.append(delta * 1000.0)
	proc_times.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
	sec_acc += delta
	sec_frames += 1
	if sec_acc >= 1.0:
		fps_samples.append(sec_frames / sec_acc)
		sec_acc = 0.0
		sec_frames = 0
	if t >= run_sec:
		_end_run()


func _begin_run() -> void:
	phase = "run"
	t = 0.0
	frame_times.clear()
	proc_times.clear()
	fps_samples.clear()
	sec_acc = 0.0
	sec_frames = 0


static func _median(a: Array) -> float:
	if a.is_empty():
		return 0.0
	var s := a.duplicate()
	s.sort()
	var n := s.size()
	return s[n / 2] if n % 2 == 1 else (s[n / 2 - 1] + s[n / 2]) * 0.5


static func _pct(a: Array, p: float) -> float:
	if a.is_empty():
		return 0.0
	var s := a.duplicate()
	s.sort()
	return s[clampi(int(ceil(p * s.size())) - 1, 0, s.size() - 1)]


func _end_run() -> void:
	var total := 0.0
	for f in frame_times:
		total += f
	results.append({
		"fps_median": _median(fps_samples), "fps_mean": frame_times.size() / maxf(total / 1000.0, 0.001),
		"frame_ms_median": _median(frame_times), "frame_ms_p95": _pct(frame_times, 0.95),
		"process_ms_median": _median(proc_times), "frames": frame_times.size(),
		"vehicles_moving": _moving(), "tick": m.shim.tick_count,
	})
	print("BENCH Lauf %d: Median %.1f FPS" % [run_idx + 1, results[-1]["fps_median"]])
	run_idx += 1
	if run_idx < RUNS:
		_begin_run()
	else:
		phase = "done"
		_write()
		m.get_tree().quit(0)


func _moving() -> int:
	var n := 0
	for v in m.vehicles:
		if v.state == v.State.TO_DST or v.state == v.State.TO_SRC:
			n += 1
	return n


func _write() -> void:
	var med: Array = []
	for r in results:
		med.append(r["fps_median"])
	var lo: float = med.min()
	var hi: float = med.max()
	var mid := _median(med)
	var spread := (hi - lo) / maxf(mid, 0.001) * 100.0
	var all60 := lo >= 60.0
	var lines: Array = []
	lines.append("Mega Tycoon – F-12 Bench (Grey-Box-Slice)")
	lines.append("Datum: %s" % Time.get_datetime_string_from_system(false, true))
	lines.append("Godot: %s" % Engine.get_version_info()["string"])
	lines.append("OS: %s · CPU: %s (%d Threads)" % [OS.get_name(), OS.get_processor_name(), OS.get_processor_count()])
	lines.append("GPU: %s / %s · Treiber: %s" % [RenderingServer.get_video_adapter_vendor(), RenderingServer.get_video_adapter_name(), OS.get_video_adapter_driver_info()])
	lines.append("Renderer: %s · Fenster: %s · VSync: aus" % [ProjectSettings.get_setting("rendering/renderer/rendering_method"), str(DisplayServer.window_get_size())])
	lines.append("Karte: %d² Felder, Ladezeit %.0f ms (Ziel ≤ 3000 ms), fehlende IDs: %d" % [m.GRID, m.load_ms, m.map_missing_ids.size()])
	lines.append("Fahrzeuge: %d Lkw auf %d Korridoren, Setup %.0f ms, Tempo 1× (%d ms/Tick)" % [m.vehicles.size(), corridors, setup_ms, m.tick_ms])
	lines.append("Läufe: %d × %.0f s nach %.0f s Aufwärmen" % [RUNS, run_sec, WARMUP_SEC])
	for i in results.size():
		var r: Dictionary = results[i]
		lines.append("  Lauf %d: Median %.1f FPS · Mittel %.1f FPS · Frame Median %.2f ms · p95 %.2f ms · Performance.TIME_PROCESS Median %.2f ms (roh) · %d Frames · in Fahrt %d" % [
			i + 1, r["fps_median"], r["fps_mean"], r["frame_ms_median"], r["frame_ms_p95"], r["process_ms_median"], r["frames"], r["vehicles_moving"]])
	lines.append("Median der Läufe: %.1f FPS · Streuung (max−min)/Median: %.1f %%" % [mid, spread])
	lines.append("Ziel F-12: 3/3 Läufe ≥ 60 FPS → %s · Streuung ≤ 10 %% → %s · Absturz: nein (Datei geschrieben)" % [
		"ERFÜLLT" if all60 else "NICHT ERFÜLLT", "ERFÜLLT" if spread <= 10.0 else "NICHT ERFÜLLT"])
	var txt := "\n".join(lines) + "\n"
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	if f == null:
		out_path = "user://mega_tycoon_bench.txt"
		f = FileAccess.open(out_path, FileAccess.WRITE)
	if f != null:
		f.store_string(txt)
		f.close()
	print(txt)
	print("BENCH Ergebnis: ", ProjectSettings.globalize_path(out_path))
