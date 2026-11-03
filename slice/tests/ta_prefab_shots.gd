extends SceneTree
## Phase 4 W2 (TA): Prefab-Galerie + Massliste + Varianten-/Gang-Test im MultiMesh.
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --path slice -s res://tests/ta_prefab_shots.gd -- <out_dir>
## Bilder: prefab_haeuser, prefab_sonder, prefab_fahrzeuge, prefab_wasser, prefab_varianten (MultiMesh mit 4 Varianten).

var w: Node3D
var cam: Camera3D


func _initialize() -> void:
	_run.call_deferred()


func _umgebung() -> void:
	w = Node3D.new()
	root.add_child(w)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.76, 0.84, 0.91)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.74, 0.81, 0.92)
	e.ambient_light_energy = 0.45
	env.environment = e
	w.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, 38, 0)
	sun.light_color = Color(1.0, 0.94, 0.82)
	sun.light_energy = 0.9
	sun.shadow_enabled = true
	w.add_child(sun)
	var boden := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(600, 600)
	var bm := StandardMaterial3D.new()
	bm.albedo_color = Color("73945C")
	pm.material = bm
	boden.mesh = pm
	w.add_child(boden)
	cam = Camera3D.new()
	cam.fov = 40
	cam.far = 3000
	w.add_child(cam)
	cam.current = true


func _reihe(typen: Array, z: float, abstand: float, gruppe: Node3D) -> float:
	var x := 0.0
	for t in typen:
		var m := ProtoPrefabs.mesh_fuer(t)
		var a := m.get_aabb()
		x += a.size.x * 0.5
		var mi := MeshInstance3D.new()
		mi.mesh = m
		mi.position = Vector3(x, 0, z)
		gruppe.add_child(mi)
		var l := Label3D.new()
		l.text = "%s\n%.1f x %.1f x %.1f" % [t, a.size.x, a.size.z, a.size.y]
		l.font_size = 64
		l.pixel_size = 0.02 * maxf(1.0, abstand / 60.0)
		l.modulate = Color.BLACK
		l.outline_size = 0
		l.position = Vector3(x, -0.2, z + a.size.z * 0.5 + 2.5)
		l.rotation_degrees.x = -60
		gruppe.add_child(l)
		x += a.size.x * 0.5 + abstand * 0.12
	return x


func _shot(out: String, name: String, ziel: Vector3, dist: float, gier := 20.0, neig := 35.0) -> void:
	var n := deg_to_rad(neig)
	var g := deg_to_rad(gier)
	cam.position = ziel + Vector3(sin(g) * cos(n), sin(n), cos(g) * cos(n)) * dist
	cam.look_at(ziel)
	for i in 8:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png(out.path_join(name + ".png"))
	print("Bild ", name, "  Dreiecke ", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
		"  DC ", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))


func _run() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "user://"
	DirAccess.make_dir_recursive_absolute(out)
	_umgebung()
	var t0 := Time.get_ticks_usec()
	var summe := 0
	for t in ProtoPrefabs.TYPEN:
		var m := ProtoPrefabs.mesh_fuer(t)
		summe += int(m.get_meta("dreiecke"))
	print("Bauzeit alle %d Typen: %.0f ms, Dreiecke zusammen %d" % [ProtoPrefabs.TYPEN.size(), (Time.get_ticks_usec() - t0) / 1000.0, summe])
	for t in ProtoPrefabs.TYPEN:
		var m := ProtoPrefabs.mesh_fuer(t)
		var a := m.get_aabb()
		print("  %-30s %6.2f x %6.2f x %6.2f m  (y0 %.2f, cx %.2f, cz %.2f)  %5d Dreiecke  %d Flaechen" % [t, a.size.x, a.size.z, a.size.y,
			a.position.y, a.get_center().x, a.get_center().z, int(m.get_meta("dreiecke")), m.get_surface_count()])
	for t in ProtoPrefabs.FERN_TYPEN:
		var mn := ProtoPrefabs.mesh_fuer(t)
		var mf := ProtoPrefabs.mesh_fern(t)
		print("  fern %-28s %5d -> %4d Dreiecke  AABB nah %s fern %s" % [t, int(mn.get_meta("dreiecke")), int(mf.get_meta("dreiecke")), str(mn.get_aabb().size.snapped(Vector3.ONE * 0.1)), str(mf.get_aabb().size.snapped(Vector3.ONE * 0.1))])
	for k in ["fuhrwerk", "postkutsche", "dampflok", "personenwagen"]:
		var f := ProtoPrefabs.fahrzeug(k)
		print("  fahrzeug %-14s L %.2f B %.2f H %.2f  gang %s" % [k, f["laenge_m"], f["breite_m"], f["hoehe_m"], JSON.stringify(f["gang"]["rad_radien_m"])])
	# Galerie
	var g1 := Node3D.new()
	w.add_child(g1)
	var x1 := _reihe(["kate", "bauernhof", "grosshof", "handwerkerhaus", "buergerhaus", "gasthaus", "schmiede"], 0.0, 60.0, g1)
	await _shot(out, "prefab_haeuser", Vector3(x1 * 0.5, 4, 0), x1 * 0.75, 15.0, 28.0)
	g1.free()
	var g2 := Node3D.new()
	w.add_child(g2)
	var x2 := _reihe(["kirche_dorf", "rathaus", "speicher", "stadttor", "wassermuehle", "wassermuehle_rad", "nebengebaeude/scheune_18x10",
		"nebengebaeude/stall_12x8", "nebengebaeude/schuppen_6x4"], 0.0, 80.0, g2)
	await _shot(out, "prefab_sonder", Vector3(x2 * 0.5, 6, 0), x2 * 0.72, 15.0, 26.0)
	g2.free()
	var g2b := Node3D.new()
	w.add_child(g2b)
	var x2b := _reihe(["kirche_stadt", "gutshof"], 0.0, 120.0, g2b)
	await _shot(out, "prefab_gross", Vector3(x2b * 0.5, 8, 0), x2b * 0.9, 25.0, 30.0)
	g2b.free()
	var g3 := Node3D.new()
	w.add_child(g3)
	var x3 := _reihe(["fuhrwerk_2_pferde", "postkutsche_4_pferde", "dampflok", "tender", "personenwagen", "gueterwagen", "ruderboot", "floss"], 0.0, 40.0, g3)
	await _shot(out, "prefab_fahrzeuge", Vector3(x3 * 0.5, 1.5, 0), x3 * 0.6, 60.0, 30.0)
	g3.free()
	var g4 := Node3D.new()
	w.add_child(g4)
	var x4 := _reihe(["fischerhuette", "netzgestell", "steg", "heuhaufen", "holzstapel", "zaun_latte", "obstbaum", "laubbaum", "eiche", "brunnen", "passant", "fass", "amboss"], 0.0, 40.0, g4)
	await _shot(out, "prefab_klein", Vector3(x4 * 0.5, 2, 0), x4 * 0.6, 15.0, 30.0)
	g4.free()
	# Varianten + Gang im MultiMesh (Compatibility: use_colors + Weiss, use_custom_data)
	var typen := ["kate", "bauernhof", "handwerkerhaus", "buergerhaus"]
	for ti in typen.size():
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.use_custom_data = true
		mm.mesh = ProtoPrefabs.mesh_fuer(typen[ti])
		mm.instance_count = 4
		for v in 4:
			mm.set_instance_transform(v, Transform3D(Basis(), Vector3(v * 18.0, 0, ti * 20.0)))
			mm.set_instance_color(v, Color.WHITE)
			mm.set_instance_custom_data(v, Color(0, ProtoPrefabs.variante_wert(v), 0, 0))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		w.add_child(mmi)
	await _shot(out, "prefab_varianten", Vector3(27, 2, 30), 95.0, 10.0, 32.0)
	# Gang: Fuhrwerke mit verschiedenen Phasen
	var mmf := MultiMesh.new()
	mmf.transform_format = MultiMesh.TRANSFORM_3D
	mmf.use_colors = true
	mmf.use_custom_data = true
	mmf.mesh = ProtoPrefabs.fahrzeug("fuhrwerk")["mesh"]
	mmf.instance_count = 10
	for i in 10:
		mmf.set_instance_transform(i, Transform3D(Basis(), Vector3(150 + i * 4.0, 0, 0)))
		mmf.set_instance_color(i, Color.WHITE)
		mmf.set_instance_custom_data(i, Color(i * 0.33, ProtoPrefabs.variante_wert(i % 4), 0, 0))
	var mmif := MultiMeshInstance3D.new()
	mmif.multimesh = mmf
	w.add_child(mmif)
	await _shot(out, "prefab_gang", Vector3(168, 1.2, 0), 26.0, 75.0, 18.0)
	# Kosten: 10 Fahrzeuge je Frame Custom-Data setzen
	var t1 := Time.get_ticks_usec()
	for f in 1000:
		for i in 10:
			mmf.set_instance_custom_data(i, Color(fmod(f * 0.3 + i, ProtoPrefabs.PERIODE_M), 0.125, 0.0, 0.0))
	print("Gang-Update CPU: %.4f ms je Frame (10 Fahrzeuge)" % [(Time.get_ticks_usec() - t1) / 1000.0 / 1000.0])
	quit(0)
