extends SceneTree
## U-02b (Felix, S6): Vorher/Nachher-Screenshots + Messwerte bei 1600×900.
##   xvfb-run -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --path slice -s res://tests/u02b_shots.gd -- <out_dir>
## Nutzt nur API, die in beiden Ständen existiert (has_method-Wächter für Neues).
## Einstieg seit F-20 über m.place_hq("haberau") (D-08, Daniel).

var m: Node
var out := "user://"
var fails := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else "user://"
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	_run.call_deferred()


func _wait(sec: float) -> void:
	await create_timer(sec).timeout
	for i in 3:
		await process_frame


func _shot(name: String) -> void:
	await _wait(0.4)
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(out.path_join(name))
	print("saved ", out.path_join(name), " ", img.get_size())


func _check(ok: bool, what: String) -> void:
	print(("  OK   " if ok else "  FAIL ") + what)
	if not ok:
		fails += 1


func _clear_toast() -> void:
	m.toast_time = 0.0
	m.toast_label.text = ""


## Bildschirm-Rechteck eines Label3D (gleiche Näherung wie main._place_map_labels).
func _label_rect(b) -> Rect2:
	var l: Label3D = b.label
	var cam: Camera3D = m.cam
	var vp := root.get_viewport().get_visible_rect().size
	var k: float = l.pixel_size * vp.y / 900.0 * 560.0
	var pc := cam.unproject_position(b.position)
	var top := pc.y - l.offset.y * k
	var fpx: float = l.font_size * k
	var lines := l.text.split("\n")
	var wmax := 0
	for ln in lines:
		wmax = maxi(wmax, ln.length())
	return Rect2(pc.x - wmax * fpx * 0.29, top, wmax * fpx * 0.58, lines.size() * fpx * 1.4)


func _marker_rect(mk: Node3D) -> Rect2:
	var cam: Camera3D = m.cam
	var s: float = mk.scale.x
	var pts := []
	for dx in [-1.2, 1.2]:
		for dy in [-1.2, 1.2]:
			pts.append(cam.unproject_position(mk.global_position + Vector3(dx * s, dy * s, 0)))
	var r := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		r = r.expand(p)
	return r


func _measure(tag: String) -> void:
	print("--- Messung ", tag)
	var vp := root.get_viewport().get_visible_rect().size
	# Linienliste
	var col: Control = m.lines_card.get_parent()
	print("  linke Spalte Breite: %.0f px (lines_card %.0f)" % [col.size.x, m.lines_card.size.x])
	_check(m.lines_card.size.x <= 340.5, "Linienliste <= 340 px (%.0f)" % m.lines_card.size.x)
	for key in m.line_rows:
		var r: Dictionary = m.line_rows[key]
		var d: Control = r["del"]
		_check(d.size.x >= 24 and d.size.y >= 24, "Papierkorb >= 24 px (%.0f×%.0f)" % [d.size.x, d.size.y])
		print("  Zeile: '%s' / '%s' / '%s'" % [r["title"].text, r["sub"].text, r["val"].text])
	# Kopfleiste: Inhalt passt in die Breite
	var bar: Control = m.hud_vals["kasse"].get_parent()
	while bar != null and not (bar is PanelContainer and bar.theme_type_variation == "PanelHud"):
		bar = bar.get_parent()
	if bar != null:
		var h: Control = bar.get_child(0)
		print("  Kopfleiste: min %.0f px, Breite %.0f px, Höhe %.0f" % [h.get_combined_minimum_size().x, bar.size.x, bar.size.y])
		_check(h.get_combined_minimum_size().x <= bar.size.x, "Kopfleiste ohne Clipping")
		var parts := []
		for c in h.get_children():
			parts.append("%s=%.0f" % [c.get_class().substr(0, 6), c.get_combined_minimum_size().x])
		print("  Kopfleiste Teile: ", " ".join(parts))
		_check(bar.size.y <= m.HUD_H + 0.5, "Kopfleiste <= HUD_H")
	var sp: String = m.hud_vals["skill"].text if m.hud_vals.has("skill") else "(keine Zeile)"
	print("  Skillpunkt-Zeile: ", sp)
	# Alle sichtbaren Controls im Bildschirm
	var out_of := []
	_offscreen(m.ui_root, vp, out_of)
	_check(out_of.is_empty(), "keine Control außerhalb 1600×900 %s" % str(out_of.slice(0, 4)))


func _offscreen(n: Node, vp: Vector2, acc: Array) -> void:
	for c in n.get_children():
		if c is Control and c.is_visible_in_tree():
			var r: Rect2 = c.get_global_rect()
			if r.size.x > 0 and (r.position.x < -0.5 or r.position.y < -0.5 or r.end.x > vp.x + 0.5 or r.end.y > vp.y + 0.5):
				acc.append("%s %s" % [c.name, r])
			_offscreen(c, vp, acc)


func _marker_check(tag: String) -> void:
	var hit := []
	for mk in m.goal_markers:
		var mr := _marker_rect(mk)
		for b in m.buildings:
			if b.label.visible and b.label.modulate.a > 0.05 and _label_rect(b).intersects(mr):
				hit.append(b.display_name)
	_check(hit.is_empty(), "%s: Zielpfeil frei von Labels %s" % [tag, str(hit)])


func _run() -> void:
	m.place_hq("haberau")
	_clear_toast()
	if "--nur-kohlberg" in OS.get_cmdline_user_args():
		# Vorher-Fund aus dem Scan als feste Ansicht: Zielpfeil über Kohlberg, Zoom 2,2 (Stahlwerk-Label lag darauf)
		m.milestone_targets = ["kohlberg"]
		m._update_goal_markers()
		m.focus(Vector2(m.by_id["kohlberg"].anchor()), 2.2)
		await _shot("u02b_6_zielpfeil_kohlberg.png")
		_marker_check("Kohlberg z2.2")
		print("U02b-Prüfungen: %d FAIL" % fails)
		quit(0)
		return
	var farm = m.by_id["farm_1"]
	var mill = m.by_id["muehle_1"]
	var hab = m.by_id["haberau"]
	# 1) Nahzoom Haberau (Miras bekannter Fall: Name an der Hinweisleiste ausgeblendet)
	m.focus(Vector2(366, 342), 2.2)
	await _shot("u02b_1_nah_haberau.png")
	_check(hab.label.visible, "Haberau-Label im Nahzoom 2,2 sichtbar")
	_marker_check("Start")
	# 2) Zielpfeil auf der Farm, mittlerer Zoom
	m.focus(Vector2(farm.anchor()), 5.0)
	await _shot("u02b_2_zielpfeil.png")
	_marker_check("Zoom 5")
	# 3) Kette aufbauen (wie ui_shots), Lizenz = M1b
	m.ui_buy_licence(farm)
	m.ui_buy_licence(mill)
	m._set_tool(m.Tool.ROAD)
	m.begin_drag(farm.anchor())
	m.drag_to(mill.anchor())
	m.end_drag()
	var corner := Vector2i(hab.anchor().x, mill.anchor().y)
	var ys := -1
	for y in range(mill.anchor().y, hab.anchor().y + 1):
		if m.city_streets.has(Vector2i(hab.anchor().x, y)):
			ys = y
			break
	m.begin_drag(mill.anchor())
	m.drag_to(corner)
	m.end_drag()
	m.begin_drag(corner)
	m.drag_to(Vector2i(hab.anchor().x, ys))
	m.end_drag()
	m._set_tool(m.Tool.TRUCK_LINE)
	m.click(farm.anchor())
	m.click(mill.anchor())
	m.click(mill.anchor())
	m.click(hab.anchor())
	m._set_tool(m.Tool.NONE)
	m.sim_hover_active = true
	m.sim_hover = Vector2i(-1, -1)
	m.run_ticks(3000)
	m.ui_credit_borrow()
	m.focus(Vector2(366, 342), 2.2)
	m.open_panel(farm)
	m.lines_timer = 0
	_clear_toast()
	await _shot("u02b_3_hud_linien.png")
	await _measure("nach Aufbau")
	_check(hab.label.visible, "Haberau-Label im Nahzoom 2,2 sichtbar (nach Aufbau)")
	_marker_check("nach Aufbau")
	m.close_panel()
	m.focus(Vector2(mill.anchor()), 3.0)
	await _shot("u02b_4_zielpfeil_nah.png")
	_marker_check("Zoom 3")
	# 5) Scan: Zielpfeil über jedem Gebäude, mehrere Zoomstufen, Kamera aufs Gebäude
	var worst := ""
	var hits := 0
	var n := 0
	for b in m.buildings:
		m.milestone_targets = [b.map_id]
		m._update_goal_markers()
		for z in [2.2, 3.5, 5.0, 8.0, 12.0]:
			m.focus(Vector2(b.anchor()), z)
			await _wait(0.05)
			n += 1
			for mk in m.goal_markers:
				var mr := _marker_rect(mk)
				for o in m.buildings:
					if o.label.visible and o.label.modulate.a > 0.05 and _label_rect(o).intersects(mr):
						hits += 1
						if worst == "":
							worst = "%s z%.1f <- %s" % [b.map_id, z, o.display_name]
	_check(hits == 0, "Scan %d Ansichten: Zielpfeil frei von Labels (%d Treffer, z. B. %s)" % [n, hits, worst])
	if worst != "":
		var parts := worst.split(" ")
		m.milestone_targets = [parts[0]]
		m._update_goal_markers()
		m.focus(Vector2(m.by_id[parts[0]].anchor()), float(parts[1].substr(1)))
	else:
		m.milestone_targets = ["mittelfurt"] if m.by_id.has("mittelfurt") else []
		m._update_goal_markers()
		m.focus(Vector2(m.by_id["mittelfurt"].anchor()), 5.0)
	await _shot("u02b_5_zielpfeil_scan.png")
	print("U02b-Prüfungen: %d FAIL" % fails)
	quit(0)
