extends SceneTree
## D-08 (Daniel Richter, S6): HQ-Platzierung mit ECHTER Maus (X-Zeiger über warp_mouse, echte Bildschirm→Feld-Projektion
## main._mouse_cell, kein sim_hover) und Screenshots je Standorttyp. Läuft nur mit Display (xvfb), weil headless keine Mausposition kennt:
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --path . -s res://tests/d08_maus.gd -- <out_dir>
## Ergänzt d07_abnahme --only=hq (dort liefern Weltklicks das Zielfeld aus main.sim_hover, die Mausposition ist konstant).
## Typen: Stadt (Mittelfurt), Kleinstadt (Kohlberg), Dorf (Haberau), Wagnis (Steinbach = Dorf, Seehafen = Kleinstadt).

const MainScript := preload("res://main.gd")
const Building := preload("res://building.gd")
var m: Node
var fails := 0
var checks := 0
var out_dir := "user://"


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out_dir = a[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	_run.call_deferred()


func ok(cond: bool, what: String) -> void:
	checks += 1
	print("  %s %s" % ["OK  " if cond else "FAIL", what])
	if not cond:
		fails += 1


func frames(n: int) -> void:
	for i in n:
		await process_frame


func _fresh() -> void:
	if m != null:
		m.free()
	MainScript.core_override = "soa"
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	await frames(3)


## Bildschirmposition eines Weltpunkts (Feldkoordinate) über die echte Kamera.
func scr(world: Vector2) -> Vector2:
	return m.cam.unproject_position(Vector3(world.x, 0.0, world.y))


func move_to(p: Vector2) -> void:
	root.warp_mouse(p)
	var mv := InputEventMouseMotion.new()
	mv.position = p
	mv.global_position = p
	root.push_input(mv, true)
	await frames(2)
	await create_timer(0.04).timeout


func click_at(p: Vector2, button := MOUSE_BUTTON_LEFT) -> void:
	await move_to(p)
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = button
		e.pressed = pressed
		e.position = p
		e.global_position = p
		root.push_input(e, true)
		await process_frame
	await frames(2)


func key(code: int) -> void:
	for pressed in [true, false]:
		var e := InputEventKey.new()
		e.keycode = code
		e.physical_keycode = code
		e.pressed = pressed
		root.push_input(e, true)
		await process_frame
	await frames(2)


## Sichtbare Bedienelemente, die den Punkt verdecken (mouse_filter != ignore), als Text.
func occluders(p: Vector2) -> Array:
	var out: Array = []
	_occ(m, p, out)
	return out


func _occ(n: Node, p: Vector2, out: Array) -> void:
	for ch in n.get_children():
		_occ(ch, p, out)
	var c := n as Control
	if c != null and c.is_visible_in_tree() and c.mouse_filter != Control.MOUSE_FILTER_IGNORE and c.get_global_rect().has_point(p):
		if not (c is PanelContainer and c.get_global_rect().size.x > 1500):      # Vollflächen-Wurzeln ignorieren
			out.append(c.name)


func shot(name: String) -> void:
	if OS.get_environment("D08_NOSHOT") != "":
		await frames(2)
		return
	await frames(10)
	await create_timer(0.5).timeout
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(out_dir.path_join(name + ".png"))
	print("     Bild ", name, ".png ", img.get_size())


func city_scr(id: String) -> Vector2:
	var c = m.by_id[id]
	return scr(Vector2(c.center().x, c.center().z))


func _run() -> void:
	print("== D-08 HQ-Platzierung mit echter Maus (warp_mouse, Kamera-Projektion), 1600×900")
	await _fresh()
	var hq = m.hq
	ok(root.get_visible_rect().size == Vector2(1600, 900), "M0 Fenster 1600×900 (%s)" % str(root.get_visible_rect().size))
	# ---- 1) Hover über alle 8 Städte, nur Mausbewegung
	var hov_ok := 0
	var occl: Array = []
	var max_frames := 0
	for st in m.map_data["staedte"]:
		var city = m.by_id[st["id"]]
		var p := city_scr(st["id"])
		var oc := occluders(p)
		if not oc.is_empty() and not (oc.size() == 1 and oc[0] == "PanelDock"):
			occl.append("%s: %s" % [st["id"], str(oc)])
		root.warp_mouse(p)
		var mv := InputEventMouseMotion.new()
		mv.position = p
		mv.global_position = p
		root.push_input(mv, true)
		var nf := 0
		while hq.shown != city and nf < 20:
			await process_frame
			nf += 1
		max_frames = maxi(max_frames, nf)
		if hq.shown == city and hq.hovered == city and hq.panel.visible and hq.hover_ring.visible:
			hov_ok += 1
		else:
			print("     Hover fehlt bei %s (Bildschirm %s, Zelle %s, shown %s)" % [st["id"], str(p), str(m._mouse_cell()), hq.shown.display_name if hq.shown else "-"])
		await shot("hover_%s" % st["id"])
	ok(hov_ok == 8, "M1 echte Mausbewegung über Stadtmitte zeigt Vorschau + Ring bei %d von 8 Städten (max. %d Frames bis Panel)" % [hov_ok, max_frames])
	ok(occl.is_empty(), "M2 keine Stadtmitte liegt unter Panel/Kopfleiste/Werkzeugleiste in der Startansicht %s" % str(occl))
	# ---- 2b) Ring-Animation nur bei Wechsel der angezeigten Stadt (Bastis Bug: Ring animierte beim Wegfahren erneut)
	await _fresh()
	hq = m.hq
	hq.reduced_motion = false
	var pa := city_scr("haberau")
	var pb := city_scr("mittelfurt")
	var pe := Vector2(700, 200)
	await move_to(pa)
	ok(hq.shown == m.by_id["haberau"] and hq.hover_ring.visible, "M3a Hover A zeigt Ring A")
	await click_at(pa)
	await create_timer(hq.RING_SEC + 0.2).timeout
	var an0: int = hq.ring_anims
	var sc0: Vector3 = hq.hover_ring.scale
	await move_to(pe)
	await create_timer(0.15).timeout
	ok(hq.ring_anims == an0 and hq.hover_ring.visible and hq.shown == m.by_id["haberau"] and hq.hover_ring.scale.is_equal_approx(sc0),
		"M3b Gewählt A, Maus weg: Ring A bleibt ruhig, keine neue Animation (%d -> %d)" % [an0, hq.ring_anims])
	await move_to(pb)
	ok(hq.shown == m.by_id["mittelfurt"] and hq.ring_anims == an0 + 1 and hq.selected == m.by_id["haberau"], "M3c Hover B zeigt Ring B (Vorschau, Wahl bleibt A), genau eine Animation")
	await create_timer(hq.RING_SEC + 0.2).timeout
	var an1: int = hq.ring_anims
	await move_to(pe)
	await create_timer(0.1).timeout
	ok(hq.shown == m.by_id["haberau"] and hq.ring_anims == an1 and hq.hover_ring.scale.x >= hq.radius_of(m.by_id["haberau"]) - 0.01, "M3d Von B weg: Ring A kehrt ohne Animation zurück (%d -> %d)" % [an1, hq.ring_anims])
	await create_timer(hq.RING_SEC + 0.2).timeout
	var an2: int = hq.ring_anims
	await move_to(pa)
	await move_to(pe)
	await create_timer(0.1).timeout
	ok(hq.ring_anims == an2 and hq.shown == m.by_id["haberau"], "M3e Hover über gewählte A und weg: keine Animation (%d -> %d)" % [an2, hq.ring_anims])
	# ---- 2) Klick-Ablauf mit echten Klicks inkl. Wechsel, Esc, Abbruch
	var clicks := 0
	await click_at(city_scr("haberau"))
	clicks += 1
	ok(hq.selected == m.by_id["haberau"] and hq.ghost.visible, "M3 Mausklick auf Haberau wählt (Ghost sichtbar)")
	await click_at(city_scr("mittelfurt"))
	clicks += 1
	ok(hq.selected == m.by_id["mittelfurt"], "M4 Mausklick auf Mittelfurt wechselt die Wahl")
	await key(KEY_ESCAPE)
	ok(hq.selected == null and not hq.ghost.visible and not m.company_started, "M5 Esc hebt die Wahl auf")
	await click_at(city_scr("mittelfurt"), MOUSE_BUTTON_LEFT)
	clicks += 1
	await click_at(Vector2(700, 200), MOUSE_BUTTON_RIGHT)
	ok(hq.selected == null, "M6 Rechtsklick auf Leerfläche hebt die Wahl auf")
	await click_at(city_scr("mittelfurt"))
	clicks += 1
	await shot("gewaehlt_mittelfurt")
	var btn_c: Vector2 = hq.button.get_global_rect().get_center()
	await click_at(btn_c)
	clicks += 1
	ok(m.company_started and m.hq_city == m.by_id["mittelfurt"] and m.speed == 1, "M7 Klick auf „HQ hier gründen“ gründet in Mittelfurt, Zeit läuft (%d Klicks inkl. Wechsel, Esc, Rechtsklick)" % clicks)
	ok(clicks <= 5 + 2, "M8 Mindestweg: Stadt + Knopf = 2 Klicks; hier %d inkl. 4 absichtlicher Umwege" % clicks)
	m.toast_time = 120.0
	await shot("gegruendet_mittelfurt")
	# ---- 3) Umsetzen: Ring-Klick mit der Maus, Abbruch per Esc und Rechtsklick, Umsetzen nach Haberau
	var mf = m.by_id["mittelfurt"]
	var ring_p := scr(Vector2(mf.center().x + m.eco.hq_radius_felder, mf.center().z))
	await click_at(ring_p)
	ok(hq.mode == hq.Mode.MOVING, "M9 Mausklick auf den HQ-Ring startet Umsetzen (Bildschirm %s)" % str(ring_p))
	await key(KEY_ESCAPE)
	ok(hq.mode == hq.Mode.FOUNDED and m.hq_city == mf, "M10 Esc bricht Umsetzen ab, HQ bleibt")
	await click_at(ring_p)
	await click_at(Vector2(700, 200), MOUSE_BUTTON_RIGHT)
	ok(hq.mode == hq.Mode.FOUNDED and m.hq_city == mf, "M11 Rechtsklick bricht Umsetzen ab")
	await click_at(ring_p)
	await frames(2)
	var vis_before: bool = Rect2(Vector2.ZERO, root.get_visible_rect().size).has_point(city_scr("haberau"))
	ok(vis_before and hq.mode == hq.Mode.MOVING, "M11b Umsetzen-Modus zoomt auf Übersicht (B-10), Haberau im Bild (Bildschirm %s)" % str(city_scr("haberau")))
	await frames(30)
	await click_at(city_scr("haberau"))
	var btn_t: String = hq.button.text
	await click_at(hq.button.get_global_rect().get_center())
	ok(m.hq_city == m.by_id["haberau"] and hq.mode == hq.Mode.FOUNDED and btn_t.contains("umsetzen"), "M12 Umsetzen nach Haberau per Maus (Knopf „%s“)" % btn_t.replace("\n", " / "))
	await shot("umgesetzt_haberau")
	# ---- 4) Screenshot je Standorttyp nach Gründung (Kohlberg Kleinstadt, Seehafen Wagnis, Steinbach Wagnis-Dorf)
	for id in ["kohlberg", "seehafen", "steinbach"]:
		await _fresh()
		hq = m.hq
		await click_at(city_scr(id))
		await shot("gewaehlt_%s" % id)
		await click_at(hq.button.get_global_rect().get_center())
		ok(m.company_started and m.hq_city == m.by_id[id], "M13 %s per Mausklick gegründet" % id)
		# S6 Tag 10 (Mira): Zeit läuft nach der Gründung (L-12), Shot ohne set_speed(0), sonst zeigt er „Pause“ (Lenas Meldung)
		var tk0: int = m.shim.tick_count
		var pf0 := Engine.get_physics_frames()
		var t_ms := Time.get_ticks_msec()
		while Engine.get_physics_frames() - pf0 < 5 and Time.get_ticks_msec() - t_ms < 5000:   # xvfb rendert langsam: 5 Physik-Frames abwarten
			await process_frame
		ok(m.speed == 1 and m.shim.tick_count > tk0, "M14 %s: Zeit läuft nach Gründung (Tempo %d, %d Ticks in %d Physik-Frames)" % [id, m.speed, m.shim.tick_count - tk0, Engine.get_physics_frames() - pf0])
		if hq.is_wagnis(id):
			var p := city_scr(id)
			var vs: Vector2 = root.get_visible_rect().size
			var src = m.by_id[hq.start_targets(id)["src"]]
			ok(p.distance_to(vs * 0.5) < vs.y * 0.15 and src.site >= 0 and m.eco.s_out_good[src.site] >= 0 and src.kind == Building.Kind.PRODUCER,
				"M15 %s (Wagnis): Kamera auf HQ (Bildschirm %s), Ziel nächster Rohstoff %s" % [id, str(p), src.display_name])
		m.toast_time = 120.0
		await shot("gegruendet_%s" % id)
	# ---- 5) Nahzoom: Ring gegen Industrie-Labels (Kohlberg, Kohlemine am Ringrand)
	await _fresh()
	hq = m.hq
	await click_at(city_scr("kohlberg"))
	await click_at(hq.button.get_global_rect().get_center())
	m.set_speed(0)
	m.toast_time = 0.1
	var k = m.by_id["kohle_1"]
	m.focus(Vector2(k.center().x, k.center().z), 2.2)
	await shot("nahzoom_kohlberg_kohle")
	var kw = m.by_id["kraftwerk_1"]
	m.focus(Vector2(kw.center().x, kw.center().z), 2.2)
	await shot("nahzoom_kohlberg_kraftwerk")
	await _fresh()
	hq = m.hq
	await click_at(city_scr("haberau"))
	await click_at(hq.button.get_global_rect().get_center())
	m.set_speed(0)
	m.toast_time = 0.1
	var h = m.by_id["haberau"]
	m.focus(Vector2(h.center().x, h.center().z), 2.2)
	await shot("nahzoom_haberau")
	print("%d/%d Prüfungen OK" % [checks - fails, checks])
	quit(0 if fails == 0 else 1)
