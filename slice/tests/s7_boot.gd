extends SceneTree
## W-01 / D-09 (S7): Suite s7_boot. Zwei Aufrufe (beide in tests/d07_regression.sh):
##   godot --headless --path . -s res://tests/s7_boot.gd                 Default-Start = Slice, dann S7 per Main.world_override
##   godot --headless --path . -s res://tests/s7_boot.gd -- --welt=s7    S7 über die Kommandozeile (echter Schalter)
## Prüft: Schalter/Weltwahl, S7 bootet als 512²-Ebene mit Slice-Kartenlogik, Kamera-Klemme 40 m–5,6 km,
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
		MainScript.world_override = "s7"
		m = await _boot()
		MainScript.world_override = ""
		ok(m.buildings.size() == n_slice, "S7 Block A: gleiche Kartenlogik/Daten wie Slice (%d Gebäude)" % n_slice)
	else:
		MainScript.core_override = "soa"
		m = await _boot()

	# --- S7 bootet
	ok(m.welt == "s7" and m.world_s7 != null, "S7-Welt aktiv (%s)" % ("Kommandozeile" if via_arg else "world_override"))
	ok(m.map_missing_ids.is_empty(), "0 fehlende IDs")
	ok(m.GRID == 512, "Karte 512² Felder")
	var gs := _ground_size(m)
	ok(gs == Vector2(512, 512), "flache Ebene 512×512 Szeneneinheiten = %s × %s" % [Welt.meter_text(gs.x * m.m_pro_feld), Welt.meter_text(gs.y * m.m_pro_feld)])
	ok(m.world_s7.hoehe_at(Vector2i(100, 100), m.GRID) == 0.0, "Block A: Höhe überall 0 (Heightmap folgt in Block B)")

	# --- Maßstab: Szeneneinheit = 1 Feld, m_pro_feld nur Darstellung
	ok(m.m_pro_feld == 25.0, "m_pro_feld = 25")
	ok(Welt.scene_to_meter("s7", 1.0) == 25.0 and is_equal_approx(Welt.meter_to_scene("s7", 12.0), 0.48), "1 Feld = 1,0 Szeneneinheit = 25 m (Haus 12 m = 0,48)")
	var mu = m.by_id.get("muehle_1")
	ok(mu != null and Vector2(mu.anchor()).distance_to(Vector2(352, 335)) < 4.0, "Weltkoordinaten in Feldern: Mühle 1 bei x/y_felder (352, 335), Anker %s" % str(mu.anchor() if mu else null))
	ok(m.eco.feld_mm == 1000 and Diagnostics.FELD_MM == m.eco.feld_mm, "Sim bleibt in Feldern: feld_mm 1000 = diagnostics.FELD_MM")

	# --- Kamera-Klemme 40 m – 5,6 km
	ok(m.world_s7.camera_distance_m(m) <= 5600.0 + 0.01, "Startzoom geklemmt: %.0f m" % m.world_s7.camera_distance_m(m))
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

	# --- km-Texte
	ok(m.dist_str(126) == "3,15 km", "126 Felder → \"%s\" (Soll 3,15 km)" % m.dist_str(126))
	ok(m.dist_str(18) == "450 m" and m.dist_str(8) == "200 m" and m.dist_str(512) == "12,8 km", "18 → %s, 8 → %s, 512 → %s" % [m.dist_str(18), m.dist_str(8), m.dist_str(512)])
	ok(m.place_hq("mittelfurt"), "HQ Mittelfurt gegründet")
	var q: Dictionary = m.licence_quote(mu)
	print("     Lizenz Mühle 1: Ziel %s, Luftlinie %d Felder" % [str(q.get("ertrag_ziel_id")), int(q.get("ertrag_distanz_felder", -1))])
	var ll: int = m.eco.luftlinie_felder(mu.site, m.by_id["mittelfurt"].site)
	ok(m.dist_str(ll) == "3,15 km", "Mühle 1 → Mittelfurt Luftlinie %d Felder = %s (Soll 3,15 km)" % [ll, m.dist_str(ll)])
	m.open_panel(mu)
	var tip: String = m.panel_button.tooltip_text
	ok(tip.contains(m.dist_str(int(q["ertrag_distanz_felder"])) + " Luftlinie") and not tip.contains("Felder Luftlinie"), "Panel zeigt Luftlinie in km/m: \"%s\"" % tip.get_slice("\n", 0))

	m.free()
	await process_frame
	print("\n%d/%d Prüfungen OK, Laufzeit %.1f s (Sandbox)" % [checks - fails, checks, (Time.get_ticks_usec() - T0) / 1e6])
	quit(1 if fails > 0 else 0)
