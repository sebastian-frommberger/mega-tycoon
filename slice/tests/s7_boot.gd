extends SceneTree
## W-01 / D-09 (S7): Suite s7_boot. Zwei Aufrufe (beide in tests/d07_regression.sh):
##   godot --headless --path . -s res://tests/s7_boot.gd                 Default-Start = Slice, dann S7 per Main.world_override
##   godot --headless --path . -s res://tests/s7_boot.gd -- --welt=s7    S7 über die Kommandozeile (echter Schalter)
## Prüft: Schalter/Weltwahl, S7 mit Slice-Karte flach (MT_S7_KARTE=slice), S7 mit generierter Karte + Terrain (W-02/W-06:
## Chunks, Höhenspanne, Plateaus, Hang/zu steil/Brücke, Ladezeit, Max-Zoom an 4 Ecken ohne Himmel), Kamera-Klemme 40 m–5,6 km,
## Maßstab (1 Feld = 1,0 Szeneneinheit = 25 m), km-Texte (Mühle→Mittelfurt 3,15 km), Sim bleibt in Feldern.
## Exit 0 = alle Prüfungen bestanden.

const MainScript := preload("res://main.gd")
const Welt := preload("res://world/welt.gd")
const Diagnostics := preload("res://core/diagnostics.gd")

var fails := 0
var checks := 0


func ok(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("  OK   ", what)
	else:
		fails += 1
		print("  FAIL ", what)


func _initialize() -> void:
	_run.call_deferred()


func _boot() -> Node:
	var m = load("res://main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	return m


func _wheel(m, button: int, n: int) -> void:
	for i in n:
		var ev := InputEventMouseButton.new()
		ev.button_index = button
		ev.pressed = true
		m._unhandled_input(ev)


func _ground_size(m) -> Vector2:
	for c in m.get_children():
		if c is MeshInstance3D and c.mesh is PlaneMesh and is_zero_approx(c.position.y):
			return (c.mesh as PlaneMesh).size
	return Vector2.ZERO


func _count_bits(a: PackedByteArray, bit: int) -> int:
	var n := 0
	for v in a:
		n += int(v & bit != 0)
	return n


## Feld mit > 30 % Steigung, dessen 3 östliche Nachbarn auf der Karte und kein Wasser sind.
func _find_steep(m, w) -> Vector2i:
	for y in range(60, 452, 3):
		for x in range(60, 448, 3):
			var c := Vector2i(x, y)
			if w.steigung_pm[y * m.GRID + x] > 300 and m.terrain_at(c) != m.Terrain.WATER and not m.cell_to_building.has(c):
				return c
	return Vector2i(-1, -1)


## Gerade 5 Felder nach Osten mit 4–15 % Steigung je Schritt, frei.
func _find_hang(m, w) -> Vector2i:
	for y in range(60, 452, 2):
		for x in range(60, 440, 2):
			var good := true
			for k in 4:
				var a := Vector2i(x + k, y)
				var pct: float = absf(w.hoehe_at(a + Vector2i(1, 0), m.GRID) - w.hoehe_at(a, m.GRID)) / 25.0 * 100.0
				if pct < 4.0 or pct > 15.0 or m.terrain_at(a) != m.Terrain.PLAIN or m.cell_to_building.has(a):
					good = false
					break
			if good and m.terrain_at(Vector2i(x + 4, y)) == m.Terrain.PLAIN:
				return Vector2i(x, y)
	return Vector2i(-1, -1)


## Gerade Querung (Zeile oder Spalte) mit ≤ 8 Wasserfeldern und 3 freien Landfeldern je Ufer.
func _find_bridge(m, w) -> Array:
	for i in range(60, 452, 7):
		for vertical in [true, false]:
			var run := 0
			for k in range(1, 511):
				var c := Vector2i(i, k) if vertical else Vector2i(k, i)
				if m.terrain_at(c) == m.Terrain.WATER:
					run += 1
					continue
				if run > 0 and run <= 8:
					var d := Vector2i(0, 1) if vertical else Vector2i(1, 0)
					var a: Vector2i = c - d * (run + 4)
					var b: Vector2i = c + d * 3
					if m._in_grid(a) and m._in_grid(b):
						var pp: Dictionary = m.plan_track(a, b, false)
						if pp["ok"]:
							return [a, b]
						if OS.get_environment("S7_DEBUG") != "": print("     Brücke ", a, b, " ", pp["reason"])
				run = 0
	return []


func _run() -> void:
	var T0 := Time.get_ticks_usec()
	var via_arg := (OS.get_cmdline_user_args() as Array).has("--welt=s7")
	print("s7_boot (%s)" % ("Kommandozeile --welt=s7" if via_arg else "Default + world_override"))

	# --- Weltwahl (reine Funktion)
	ok(Welt.pick("", PackedStringArray()) == "slice", "ohne Schalter: slice")
	ok(Welt.pick("", PackedStringArray(["--welt=s7"])) == "s7", "--welt=s7 wählt s7")
	ok(Welt.pick("", PackedStringArray(["--welt=quatsch"])) == "slice", "unbekannte Welt fällt auf slice zurück")
	ok(Welt.pick("slice", PackedStringArray(["--welt=s7"])) == "slice", "Main.world_override hat Vorrang vor der Kommandozeile")
	ok(str(ProjectSettings.get_setting(Welt.SETTING, "")) == "slice", "ProjectSettings %s committet = \"slice\" (Default bleibt Slice)" % Welt.SETTING)

	var m
	if not via_arg:
		# --- Default-Start: Slice unverändert
		MainScript.world_override = ""
		MainScript.core_override = "soa"
		m = await _boot()
		ok(m.welt == "slice" and m.world_s7 == null, "Default-Start bootet den Slice (world_s7 == null)")
		_wheel(m, MOUSE_BUTTON_WHEEL_DOWN, 200)
		var zmax: float = m.zoom
		_wheel(m, MOUSE_BUTTON_WHEEL_UP, 400)
		ok(m.zoom_min == 0.4 and m.zoom_max == 26.0 and zmax == 26.0 and m.zoom == 0.4, "Slice: Zoom-Klemme unverändert 0,4–26 (Mausrad)")
		ok(is_equal_approx(m.cam.near, 0.8) and is_equal_approx(m.cam.far, 6000.0), "Slice: near/far unverändert (0,8 / 6000)")
		ok(m.dist_str(126) == "126 Felder" and m.dist_str(8) == "8 Felder", "Slice: Distanztexte weiter in Feldern")
		var n_slice: int = m.buildings.size()
		m.free()
		await process_frame
		# --- S7-Maßstab mit Slice-Karte, flach (Testschalter MT_S7_KARTE=slice; Block-A-Prüfungen bleiben gültig)
		OS.set_environment("MT_S7_KARTE", "slice")
		MainScript.world_override = "s7"
		m = await _boot()
		ok(m.buildings.size() == n_slice, "S7 + MT_S7_KARTE=slice: gleiche Kartenlogik/Daten wie Slice (%d Gebäude)" % n_slice)
		ok(_ground_size(m) == Vector2(512, 512) and m.world_s7.hoehe_at(Vector2i(100, 100), m.GRID) == 0.0, "flach: Ebene 512², Höhe 0")
		var mu = m.by_id.get("muehle_1")
		ok(mu != null and Vector2(mu.anchor()).distance_to(Vector2(352, 335)) < 4.0, "Weltkoordinaten in Feldern: Mühle 1 bei (352, 335)")
		ok(m.place_hq("mittelfurt"), "HQ Mittelfurt gegründet")
		var ll: int = m.eco.luftlinie_felder(mu.site, m.by_id["mittelfurt"].site)
		ok(m.dist_str(ll) == "3,15 km", "Mühle 1 → Mittelfurt Luftlinie %d Felder = %s (Soll 3,15 km)" % [ll, m.dist_str(ll)])
		var q: Dictionary = m.licence_quote(mu)
		m.open_panel(mu)
		var tip: String = m.panel_button.tooltip_text
		ok(tip.contains(m.dist_str(int(q["ertrag_distanz_felder"])) + " Luftlinie") and not tip.contains("Felder Luftlinie"), "Panel zeigt Luftlinie in km/m: \"%s\"" % tip.get_slice("\n", 0))
		m.free()
		await process_frame
		OS.set_environment("MT_S7_KARTE", "")
		m = await _boot()
		MainScript.world_override = ""
	else:
		MainScript.core_override = "soa"
		m = await _boot()

	# --- S7 bootet mit generierter Karte + Terrain (W-06/W-02)
	var w = m.world_s7
	ok(m.welt == "s7" and w != null, "S7-Welt aktiv (%s)" % ("Kommandozeile" if via_arg else "world_override"))
	ok(m.map_missing_ids.is_empty(), "0 fehlende IDs")
	ok(m.GRID == 512, "Karte 512² Felder")
	ok(w.has_terrain() and w.terrain_node != null and w.terrain_node.chunks.size() == 64, "Terrain geladen: 64 Chunks, Rand + Gebirgsring (%d Dreiecke, Bau %.0f ms, Daten %.0f ms)" % [w.terrain_node.tri_count if w.terrain_node else 0, w.terrain_node.build_ms if w.terrain_node else 0.0, w.load_ms])
	var hmin := 1.0e9
	var hmax := -1.0e9
	for v in w.hoehe_boden:
		hmin = minf(hmin, v)
		hmax = maxf(hmax, v)
	ok(hmax - hmin >= 900.0, "Höhenspanne %.0f–%.0f m (≥ 900 m), Seed %s" % [hmin, hmax, str(w.meta.get("seed"))])
	ok(m.load_ms <= 6000.0, "Ladezeit Karte %.0f ms (≤ 6 s Sandbox)" % m.load_ms)
	var n_w := 0
	var n_f := 0
	for i in m.GRID * m.GRID:
		n_w += int(m.terrain[i] == m.Terrain.WATER)
		n_f += int(m.terrain[i] == m.Terrain.MOUNTAIN)
	ok(n_w > 1000 and n_w == _count_bits(w.fluss, 1), "terrain_at aus Flussmaske: %d Wasserfelder, %d Fels (> 20 %%)" % [n_w, n_f])
	var n_ind := 0
	var plat_ok := true
	var hoehe_ok := true
	for b in m.buildings:
		if b.map_id == "":
			continue
		var a: Vector2i = b.anchor()
		if absf(b.position.y - w.hoehe_szene(b.position.x, b.position.z)) > 0.001:
			hoehe_ok = false
		if b.typ != "stadt":
			n_ind += 1
			if w.steigung_pm[a.y * m.GRID + a.x] > 30:
				plat_ok = false
	ok(n_ind >= 20 and m.map_data["staedte"].size() >= 8, "%d Industrien, %d Städte aus world_s7.json" % [n_ind, m.map_data["staedte"].size()])
	ok(hoehe_ok, "Gebäude/Industrien stehen auf Geländehöhe")
	ok(plat_ok, "Industrien auf Plateau (< 3 % am Anker)")
	ok(m.vehicle_h_grid.size() == m.GRID * m.GRID, "Fahrzeughöhe je Feld vorberechnet (%d Werte)" % m.vehicle_h_grid.size())
	# Bau: Hang kostet, zu steil wird gesperrt (B11), Fluss überbrückbar
	m.eco.cash_cent = 50_000_000
	var steil := _find_steep(m, w)
	if steil.x >= 0:
		var p: Dictionary = m.plan_track(steil, steil + Vector2i(3, 0), false)
		ok(not p["ok"] and str(p["reason"]).begins_with("Zu steil"), "Straße am Steilhang gesperrt: \"%s\"" % str(p["reason"]))
	else:
		ok(false, "kein Steilhang > 30 % gefunden")
	var hang := _find_hang(m, w)
	var ph: Dictionary = m.plan_track(hang, hang + Vector2i(4, 0), false)
	ok(ph["ok"] and int(ph["hang"].get("faktor_pm", 1000)) > 1000, "Straße am Hang %s baubar, Faktor %d ‰ %s" % [str(hang), int(ph["hang"].get("faktor_pm", 0)), str(ph["reason"])])
	var br := _find_bridge(m, w)
	var pb: Dictionary = m.plan_track(br[0], br[1], false) if br.size() == 2 else {"ok": false, "reason": "keine Stelle"}
	ok(pb["ok"], "Brücke über den Fluss %s→%s baubar (%s)" % [str(br[0]) if br.size() else "-", str(br[1]) if br.size() else "-", str(pb["reason"])])

	# --- Kamera-Klemme 40 m – 5,6 km
	ok(w.camera_distance_m(m) <= 5600.0 + 0.01, "Startzoom geklemmt: %.0f m" % w.camera_distance_m(m))
	_wheel(m, MOUSE_BUTTON_WHEEL_DOWN, 200)
	var d_max: float = m.cam.position.length() * m.m_pro_feld
	ok(absf(d_max - 5600.0) < 0.5, "maximal herausgezoomt: Abstand %.1f m (Soll 5.600)" % d_max)
	_wheel(m, MOUSE_BUTTON_WHEEL_UP, 400)
	var d_min: float = m.cam.position.length() * m.m_pro_feld
	ok(absf(d_min - 40.0) < 0.01, "maximal hineingezoomt: Abstand %.2f m (Soll 40)" % d_min)
	ok(m.cam.near * m.m_pro_feld < d_min * 0.5, "near-Ebene %.2f m < halber Nahabstand" % (m.cam.near * m.m_pro_feld))
	m.focus(Vector2(256, 256), 100.0)
	ok(absf(m.cam.position.length() * m.m_pro_feld - 5600.0) < 0.5, "focus() mit Zoom 100 wird auf 5,6 km geklemmt")
	m.focus(Vector2(256, 256), 0.0001)
	ok(absf(m.cam.position.length() * m.m_pro_feld - 40.0) < 0.01, "focus() mit Zoom 0,0001 wird auf 40 m geklemmt")
	ok(m.cam.far * m.m_pro_feld > 5600.0 * 2.0, "far-Ebene %.1f km deckt 5,6 km Abstand ab" % (m.cam.far * m.m_pro_feld / 1000.0))
	# Max-Zoom an den 4 Ecken: jeder Bildrand-Strahl trifft Gelände innerhalb des Landschaftsrands (kein Himmel, keine Kante)
	var vr: Rect2 = m.get_viewport().get_visible_rect()
	var pts := [Vector2.ZERO, Vector2(vr.size.x - 1, 0), Vector2(vr.size.x * 0.5, 0), Vector2(0, vr.size.y - 1), Vector2(vr.size.x - 1, vr.size.y - 1)]
	var worst := 0.0
	var miss := 0
	for corner in [Vector2(0, 0), Vector2(512, 0), Vector2(0, 512), Vector2(512, 512)]:
		m.focus(corner, 100.0)
		w.update_camera(m)
		for sp in pts:
			var hit = w.ray_hit(m.cam.project_ray_origin(sp), m.cam.project_ray_normal(sp))
			if hit == null:
				miss += 1
				continue
			var aus := maxf(maxf(-hit.x, hit.x - 512.0), maxf(-hit.z, hit.z - 512.0))
			worst = maxf(worst, aus)
	ok(miss == 0 and worst * m.m_pro_feld < 7500.0, "Max-Zoom 4 Ecken: %d Strahlen ohne Gelände, weitester Treffer %.1f km hinter der Kante (Rand 7,5 km)" % [miss, worst * m.m_pro_feld / 1000.0])
	ok(m.dist_str(126) == "3,15 km" and m.dist_str(18) == "450 m" and m.dist_str(512) == "12,8 km", "km-Texte: 126 → %s, 18 → %s, 512 → %s" % [m.dist_str(126), m.dist_str(18), m.dist_str(512)])
	var c0: Dictionary = m.map_data["staedte"][0]
	ok(m.place_hq(c0["id"]), "HQ %s gegründet" % c0["name"])

	m.free()
	await process_frame
	print("\n%d/%d Prüfungen OK, Laufzeit %.1f s (Sandbox)" % [checks - fails, checks, (Time.get_ticks_usec() - T0) / 1e6])
	quit(1 if fails > 0 else 0)
