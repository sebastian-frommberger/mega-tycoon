extends SceneTree
## Fix-Pass W2 (Technical Artist + Mira): Nahansichten je Mangel (1–8) für vorher/nachher.
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --path slice -s res://tests/proto_shots_fix.gd -- <out_dir>
## Bilder: fix1_fuhrwerk_nah, fix1b_fuhrwerk_ganz_nah, fix2_gespann_gutshof, fix3_lindenfurt_schild (Markt, 350 m), fix4_erlenbach_schild
## (See 750 m), fix5_muehle_wasserrad, fix6_felder_750m, fix7_marktplatz_nah, fix8_hasenwinkel_300m / fix8b_hasenwinkel_650m.

var s: Node
var zeilen: Array = []


func _initialize() -> void:
	s = load("res://proto/prototyp_welt.tscn").instantiate()
	root.add_child(s)
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _kamera(ziel: Vector2, abstand: float, gier_grad: float) -> void:
	s.folgen = -1
	s.ziel = Vector3(ziel.x, 0, ziel.y)
	s.abstand = abstand
	s.gier = deg_to_rad(gier_grad)
	s._kamera_anwenden()


func _shot(out: String, name: String) -> void:
	await _frames(8)
	s._hud_text()
	await _frames(2)
	root.get_viewport().get_texture().get_image().save_png(out.path_join(name + ".png"))
	var z: Dictionary = s.zaehlung()
	var zl := "%-28s live %8d Dreiecke / %3d DC   Abstand %4.0f m" % [name, z["live_dreiecke"], z["live_dc"], s.abstand]
	print(zl)
	zeilen.append(zl)


func _bis(t: int) -> void:
	while s.proto_sim.ticks < t:
		s.proto_sim.tick()
	for i in 30:
		s.fahrzeuge.frame(0.5, 1.0 / 6.0)


func _run() -> void:
	await _frames(2)
	s.set_process(false)
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "user://fix_w2"
	DirAccess.make_dir_recursive_absolute(out)
	zeilen.append("Ladezeit Szene %.0f ms" % s.lade_ms)
	s.kulissen.zeit_setzen(5.0 + (2450.0 - 1880.0) / 1.5)
	# --- 1: Fuhrwerk 1 beladen unterwegs (wie int_fuhrwerk_nah)
	var t := 0
	while t < 3000 and not String(s.proto_sim.zustand_text(s.proto_sim.fahrzeuge[0])).contains("fährt"):
		s.proto_sim.tick()
		t += 1
	_bis(s.proto_sim.ticks + 12)
	zeilen.append("Sim-Tick %d: %s" % [s.proto_sim.ticks, s.proto_sim.zustand_text(s.proto_sim.fahrzeuge[0])])
	var z = s.proto_sim.fahrzeuge[0]["zustand"]
	_kamera(Vector2(z.pos.x, z.pos.z), 70.0, rad_to_deg(z.gier) + 135.0)
	await _shot(out, "fix1_fuhrwerk_nah")
	_kamera(Vector2(z.pos.x, z.pos.z), 40.0, rad_to_deg(z.gier) + 90.0)
	await _shot(out, "fix1b_fuhrwerk_ganz_nah")
	# --- 2: Gespann am Gutshof: weiterspulen, bis Fuhrwerk 1 (Rückkehr) am Hof hält
	var gut := Vector2(1935.0, 1355.0)
	var gefunden := false
	var dmin := 1e9
	for i in 6000:
		var txt := String(s.proto_sim.zustand_text(s.proto_sim.fahrzeuge[0]))
		var zz = s.proto_sim.fahrzeuge[0]["zustand"]
		var dd := Vector2(zz.pos.x, zz.pos.z).distance_to(gut)
		dmin = minf(dmin, dd)
		if dd < 45.0 and not txt.contains("fährt") and zz.vb < 0.01:
			gefunden = true
			break
		s.proto_sim.tick()
		s.fahrzeuge.frame(0.5, 1.0)
	_bis(s.proto_sim.ticks + 40)
	zeilen.append("Gespann am Hof gefunden=%s Tick %d dmin %.1f: %s" % [str(gefunden), s.proto_sim.ticks, dmin, s.proto_sim.zustand_text(s.proto_sim.fahrzeuge[0])])
	z = s.proto_sim.fahrzeuge[0]["zustand"]
	_kamera(Vector2(z.pos.x, z.pos.z), 60.0, rad_to_deg(z.gier) + 150.0)
	await _shot(out, "fix2_gespann_gutshof")
	# --- 3/7: Markt Lindenfurt
	s.setze_preset(3)
	await _shot(out, "fix3_lindenfurt_schild")
	_kamera(Vector2(96.0, 138.0), 120.0, -20.0)
	await _shot(out, "fix7_marktplatz_nah")
	# --- 4: See 750 m
	s.setze_preset(5)
	await _shot(out, "fix4_erlenbach_schild")
	# --- 5: Mühle
	_kamera(Vector2(1612, 1098), 45.0, 25.0)
	await _shot(out, "fix5_muehle_wasserrad")
	_kamera(Vector2(1612, 1098), 120.0, 25.0)
	await _shot(out, "fix5b_muehle_180m")
	# --- 6: Felder 750 m (Ansicht über Äcker; Mitte Kern)
	_kamera(Vector2(1400, 520), 750.0, 20.0)
	await _shot(out, "fix6_felder_750m")
	_kamera(Vector2(1000, 1000), 750.0, 200.0)
	await _shot(out, "fix6b_felder_750m_b")
	# --- 8: Hasenwinkel
	_kamera(Vector2(759.8, 856.5), 300.0, 20.0)
	await _shot(out, "fix8_hasenwinkel_300m")
	_kamera(Vector2(759.8, 856.5), 650.0, 20.0)
	await _shot(out, "fix8b_hasenwinkel_650m")
	s.setze_preset(1)
	await _shot(out, "fix9_preset_1_uebersicht")
	s.setze_preset(2)
	await _shot(out, "fix9_preset_2_dorf")
	var f := FileAccess.open(out.path_join("fix_perf.txt"), FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(PackedStringArray(zeilen)) + "\n")
		f.close()
	quit(0)
