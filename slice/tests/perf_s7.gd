extends SceneTree
## D-09 Perf-Baseline (Daniel, S7): Dreiecke, Draw Calls und Objekte im Frame an den 6 SP-03-Kamerapositionen,
## je mit 0 und 5.000 Lkw, als CSV. Braucht ein echtes Renderziel (xvfb + opengl3), headless liefert 0.
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --path . -s res://tests/perf_s7.gd -- \
##       [--welt=slice|s7] [--lkw=0,5000] [--out=<csv>] [--check=<baseline.csv>]
## --welt     Weltschalter, wird an main.gd durchgereicht (Felix: `--welt=s7`); ohne Angabe = Slice.
## --check    vergleicht mit einer Baseline-CSV: Dreiecke, Draw Calls oder Objekte > +10 % = FAIL (Exit 1).
##            Für --welt=s7 gelten zusätzlich die absoluten Budgets aus D-09 (S7_LIMITS).
## Messgrößen: RenderingServer-Monitore (RENDER_TOTAL_PRIMITIVES/DRAW_CALLS/OBJECTS_IN_FRAME). Das sind Zählwerte der
## gerenderten Szene, keine Zeiten: sie sind auf jedem Rechner gleich (Software-GL genügt), eine FPS-Aussage folgt daraus nicht.
## Kameras: Zielfeld + Abstand in Metern (Quelle: sprints/s6/zocken/sophie_sp03.md, Slice-Äquivalente wie sp03_vorher.gd),
## umgerechnet in den Spielzoom: zoom = Abstand / (25,6 · m_pro_feld) (Slice: 10 m je Feld, S7: 25 m).

const GATE := 1.10
const S7_LIMITS := {          # D-09: Perf-Gate S7-Welt (absolut)
	"uebersicht": {"tris": 1000000, "dc": 300},
	"stadt_nah": {"tris": 2900000},
}
## [name, Zielfeld Slice, Abstand m Slice, Zielfeld S7, Abstand m S7]; Abstand >= 99999 = maximaler Zoom
const VIEWS := [
	["uebersicht", Vector2(172, 236), 4300.0, Vector2(264, 220), 4300.0],
	["stadt_nah", Vector2(164, 247), 700.0, Vector2(298, 253), 700.0],
	["stadt_strasse", Vector2(166, 241), 160.0, Vector2(298, 250), 160.0],
	["mine", Vector2(182, 199), 420.0, Vector2(176, 174), 420.0],
	["farm", Vector2(385, 340), 900.0, Vector2(390, 313), 900.0],
	["rand_max", Vector2(0, 0), 99999.0, Vector2(0, 0), 99999.0],
]

var m: Node
var welt := "slice"
var lkw_list: Array = [0, 5000]
var out_path := "res://tests/perf_s7_out.csv"
var check_path := ""
var rows: Array = []     # {welt, lkw, view, tris, dc, obj, zoom}


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--welt="):
			welt = a.substr(7)
		elif a.begins_with("--lkw="):
			lkw_list = Array(a.substr(6).split(",", false)).map(func(x): return int(x))
		elif a.begins_with("--out="):
			out_path = a.substr(6)
		elif a.begins_with("--check="):
			check_path = a.substr(8)
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _boot() -> void:
	if m != null:
		m.queue_free()
		await _frames(3)
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	await _frames(3)
	m.set_physics_process(false)         # keine Wanduhr-Ticks: Zustand bleibt reproduzierbar
	m.toast_time = 0.0
	m.toast_label.text = ""


func _setup_trucks(n: int) -> void:
	if n <= 0:
		m.place_hq("haberau")
		m.toast_label.text = ""
		return
	var b = load("res://bench.gd").new()
	b.units = n
	m.bench = b
	m.add_child(b)
	b.start(m)                           # HQ, Lager, Straßen, n Lkw auf Korridoren (wie F-12)
	b.set_process(false)                 # kein Wanduhr-Lauf, kein Quit am Ende
	m.set_physics_process(false)
	m.run_ticks(60)                      # Fahrzeuge aus den Startpositionen in Bewegung
	print("PERF Lkw gebaut: %d (gewünscht %d)" % [m.vehicles.size(), n])


func _measure(v: Array) -> void:
	var s7 := welt == "s7"
	var cell: Vector2 = v[3] if s7 else v[1]
	var d_m: float = v[4] if s7 else v[2]
	var mpf: float = float(m.map_data["karte"].get("m_pro_feld", 10.0))
	var z := 26.0 if d_m >= 99999.0 else d_m / (25.6 * mpf)
	m.focus(cell, clampf(z, 0.4, 26.0))
	m.toast_label.text = ""
	for i in 2:
		m._render_vehicles()
		await _frames(2)
	await create_timer(0.3).timeout      # Label-Timer (0,25 s) einmal durchlaufen lassen
	m._render_vehicles()
	await _frames(2)
	var r := {"welt": welt, "lkw": m.vehicles.size(), "view": v[0], "zoom": m.zoom,
		"tris": int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
		"dc": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		"obj": int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))}
	rows.append(r)
	print("PERF %s lkw=%d %-14s zoom=%.2f Dreiecke=%d DrawCalls=%d Objekte=%d" % [welt, r["lkw"], r["view"], r["zoom"], r["tris"], r["dc"], r["obj"]])


func _write_csv() -> void:
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	if f == null:
		print("FEHLER CSV nicht schreibbar: ", out_path)
		return
	f.store_line("welt,lkw,ansicht,zoom,dreiecke,draw_calls,objekte")
	for r in rows:
		f.store_line("%s,%d,%s,%.2f,%d,%d,%d" % [r["welt"], r["lkw"], r["view"], r["zoom"], r["tris"], r["dc"], r["obj"]])
	f.close()
	print("PERF CSV: ", ProjectSettings.globalize_path(out_path))


## Rückgabe: Anzahl Verstöße
func _check() -> int:
	var fails := 0
	if check_path != "":
		var f := FileAccess.open(check_path, FileAccess.READ)
		if f == null:
			print("  FAIL Baseline fehlt: ", check_path)
			return 1
		var base := {}
		f.get_line()
		while not f.eof_reached():
			var p := f.get_line().split(",")
			if p.size() >= 7:
				base["%s|%s|%s" % [p[0], p[1], p[2]]] = [int(p[4]), int(p[5]), int(p[6])]
		for r in rows:
			var k := "%s|%d|%s" % [r["welt"], 0 if r["lkw"] == 0 else 5000, r["view"]]
			if not base.has(k):
				print("  FAIL keine Baseline für ", k)
				fails += 1
				continue
			var b: Array = base[k]
			for pair in [["Dreiecke", r["tris"], b[0]], ["DrawCalls", r["dc"], b[1]], ["Objekte", r["obj"], b[2]]]:
				if float(pair[1]) > float(pair[2]) * GATE:
					print("  FAIL %s %s Lkw=%d: %s %d > %d (+10 %%)" % [r["welt"], r["view"], r["lkw"], pair[0], pair[1], int(pair[2] * GATE)])
					fails += 1
	if welt == "s7":
		for r in rows:
			var lim: Dictionary = S7_LIMITS.get(r["view"], {})
			if lim.has("tris") and r["tris"] > lim["tris"]:
				print("  FAIL s7 %s Lkw=%d: Dreiecke %d > Budget %d" % [r["view"], r["lkw"], r["tris"], lim["tris"]])
				fails += 1
			if lim.has("dc") and r["dc"] > lim["dc"]:
				print("  FAIL s7 %s Lkw=%d: DrawCalls %d > Budget %d" % [r["view"], r["lkw"], r["dc"], lim["dc"]])
				fails += 1
	return fails


func _run() -> void:
	var t0 := Time.get_ticks_msec()
	for n in lkw_list:
		await _boot()
		await _setup_trucks(int(n))
		for v in VIEWS:
			await _measure(v)
	_write_csv()
	var fails := _check()
	if rows.is_empty() or int(rows[0]["tris"]) <= 0:
		print("  FAIL Renderer liefert 0 Dreiecke (headless? xvfb + --rendering-driver opengl3 nötig)")
		fails += 1
	print("perf_s7 %s: %d Messwerte, %.0f s" % [welt, rows.size(), (Time.get_ticks_msec() - t0) / 1000.0])
	if fails == 0:
		print("perf_s7 Prüfungen OK (%d Messwerte%s)" % [rows.size(), ", Gate +10 %" if check_path != "" else ", ohne Gate"])
	else:
		print("perf_s7 FEHLER: %d Verstöße" % fails)
	quit(0 if fails == 0 else 1)
