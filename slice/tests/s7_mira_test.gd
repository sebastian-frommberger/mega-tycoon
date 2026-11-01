extends SceneTree
## S7 Block A (Mira): Regressionstests Z-01 und B-xx (je Bug mindestens ein Test). Start:
##   godot --headless --path slice -s res://tests/s7_mira_test.gd
## Exit 0 = alle Prüfungen bestanden.

const MAIN := "res://main.tscn"

var m: Node
var fails := 0
var checks := 0


func _initialize() -> void:
	_run.call_deferred()


func ok(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("  OK   ", what)
	else:
		fails += 1
		print("  FAIL ", what)


func _fresh(city_id: String) -> void:
	if m != null:
		m.free()
	m = load(MAIN).instantiate()
	root.add_child(m)
	m.place_hq(city_id)
	m.eco.cash_cent = 10_000_000      # Geld spielt hier keine Rolle (Bau-Logik, nicht Ökonomie)


func drag(tool: int, a: Vector2i, b: Vector2i) -> Dictionary:
	m._set_tool(tool)
	m.begin_drag(a)
	m.drag_to(b)
	var p: Dictionary = m.plan
	var marker := false
	for c in m.preview_root.get_children():
		if c.name.begins_with("DockMarker") and not c.is_queued_for_deletion():
			marker = true
	m._update_cursor_label()
	var label: String = m.cursor_cost.text
	var r: bool = m.end_drag()
	m._set_tool(m.Tool.NONE)
	return {"ok": r, "plan": p, "marker": marker, "label": label}


func connected(a, b, rail: bool) -> bool:
	var astar: AStarGrid2D = m.astar_rail if rail else m.astar_road
	return not astar.get_id_path(a.anchor(), b.anchor()).is_empty()


func _z01(src_id: String, city_id: String, hq_city: String, rail: bool) -> void:
	var kind := "Gleis" if rail else "Straße"
	for dir in ["hin", "rück"]:
		_fresh(hq_city)
		var s = m.by_id[src_id]
		var c = m.by_id[city_id]
		var r: Dictionary = drag(m.Tool.RAIL if rail else m.Tool.ROAD, s.anchor(), c.anchor()) if dir == "hin" else drag(m.Tool.RAIL if rail else m.Tool.ROAD, c.anchor(), s.anchor())
		var p: Dictionary = r["plan"]
		ok(r["ok"] and connected(s, c, rail), "Z-01 %s %s endet auf Stadt (%s): %s → %s gebaut und verbunden (%d Felder, Grund '%s')" % [
			kind, dir, city_id, src_id if dir == "hin" else city_id, city_id if dir == "hin" else src_id, p.get("new_count", 0), p.get("reason", "")])
		ok(r["marker"] and p.get("dock_street", Vector2i(-1, -1)).x >= 0 and r["label"].contains("Anschluss am Stadtrand"),
			"Z-01 %s %s: Anschlusspunkt in der Vorschau (Marker %s, Feld %s, Label '%s')" % [kind, dir, str(r["marker"]), str(p.get("dock_street")), r["label"].replace("\n", " / ")])


func _run() -> void:
	print("== Z-01 Straße/Gleis endet auf Stadt, beide Richtungen")
	_z01("muehle_1", "mittelfurt", "haberau", false)      # Aylins Route (Fluss durch Mittelfurt)
	_z01("muehle_2", "mittelfurt", "steinbach", false)    # Daniels/Lenas Route
	_z01("muehle_1", "mittelfurt", "haberau", true)       # Gleis (Aylin: rail muehle_1 mittelfurt)
	_z01("muehle_1", "haberau", "haberau", false)         # Haberau "ebenso"
	# Gleiche Strecke in beiden Richtungen (Andocken hängt nicht von der Zugrichtung ab)
	_fresh("haberau")
	var p1: Dictionary = m.plan_track(m.by_id["muehle_2"].anchor(), m.by_id["mittelfurt"].anchor(), false)
	var p2: Dictionary = m.plan_track(m.by_id["mittelfurt"].anchor(), m.by_id["muehle_2"].anchor(), false)
	var s1 := {}
	var s2 := {}
	for c in p1["cells"]:
		s1[c] = true
	for c in p2["cells"]:
		s2[c] = true
	ok(s1.size() == s2.size() and s1.keys().all(func(k): return s2.has(k)), "Z-01: hin und rück planen dieselben Felder (%d/%d)" % [s1.size(), s2.size()])
	# Brückenmeldung: Ursache + Lösung
	var bad := ""
	for y in range(m.GRID):
		if bad != "":
			break
		for x in range(m.GRID):
			var c := Vector2i(x, y)
			if m.terrain_at(c) == m.Terrain.WATER and m.terrain_at(c + Vector2i(-3, 0)) != m.Terrain.WATER and m.terrain_at(c + Vector2i(3, 3)) != m.Terrain.WATER:
				var a := c + Vector2i(-3, -3)
				var pb: Dictionary = m.plan_track(a, c + Vector2i(3, 3), false)
				if str(pb["reason"]).contains("Brücke geht nur geradeaus"):
					bad = pb["reason"]
					break
	ok(bad.contains("zwei Teilen") and bad.contains("Ufer") and not bad.contains("nicht diagonal"), "Brückenmeldung verständlich: '%s'" % bad)

	print("== B-xx 1) Klick auf Industrie am HQ-Ring startet kein Umsetzen")
	for pair in [["mittelfurt", "farm_3"], ["kohlberg", "kohle_1"]]:
		_fresh(pair[0])
		m.eco.cash_cent = 600_000
		var ind = m.by_id[pair[1]]
		ok(m.hq.can_move(), "%s: Umsetzen-Fenster offen (erste 2 min)" % pair[0])
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = true
		m.sim_hover_active = true
		m.sim_hover = ind.anchor()
		var used: bool = m.hq.handle_input(ev)
		m.click(ind.anchor())
		ok(not used and m.hq.mode != m.hq.Mode.MOVING and m.selected == ind and m.panel.visible,
			"%s: Klick auf %s öffnet das Panel, kein Umsetzen (verbraucht=%s, Modus %d)" % [pair[0], ind.display_name, str(used), m.hq.mode])
		# Gegenprobe: Ring-Label und HQ starten das Umsetzen weiterhin
		var lp: Vector3 = m.hq.ring_label.position
		m.hq._update_ring_label()
		m.sim_hover = Vector2i(int(floor(lp.x)), int(floor(lp.z)))
		var on_label: bool = m.hq._hits_ring_or_hq(m.sim_hover)
		m.sim_hover = m.hq.hq_cell(m.hq_city)
		var used2: bool = m.hq.handle_input(ev)
		ok(on_label and used2 and m.hq.mode == m.hq.Mode.MOVING, "%s: Ring-Label trifft (%s), Klick aufs HQ startet Umsetzen (%s)" % [pair[0], str(on_label), str(used2)])
		m.hq.cancel()
		m.sim_hover_active = false

	print("== B-xx 2) Ziele nennen den Typ und haken nur mit passendem Typ ab")
	_fresh("haberau")
	var t1: String = m.milestones[1]["text"]
	ok(t1 == "Lizenz für eine Getreidefarm kaufen" and m.milestones[1]["hint"].contains("Getreidefarm 2"), "Haberau Ziel 1: '%s', Pfeil/Hinweis auf %s" % [t1, m.by_id[m.milestones[1]["t"][0]].display_name])
	m.ui_buy_licence(m.by_id["farm_1"])
	m._check_milestones()
	ok(m.milestones[1]["done"], "Haberau: Lizenz Farm 1 hakt 'eine Getreidefarm' ab (Text stimmt mit dem Objekt)")
	_fresh("kohlberg")
	ok(m.milestones[3]["text"] == "Lkw-Linie Kohlemine → Kraftwerk", "Kohlberg Ziel 3: '%s'" % m.milestones[3]["text"])
	var farm3 = m.by_id["farm_3"]
	var mill2 = m.by_id["muehle_2"]
	m.ui_buy_licence(farm3)
	m.ui_buy_licence(mill2)
	drag(m.Tool.ROAD, farm3.anchor(), mill2.anchor())
	m._set_tool(m.Tool.TRUCK_LINE)
	m.click(farm3.anchor())
	m.click(mill2.anchor())
	m._set_tool(m.Tool.NONE)
	var n_lines: int = m.line_groups.size()
	m.lines_dirty = true
	m.network_dirty = true
	m._check_milestones()
	ok(n_lines == 1 and not m.milestones[3]["done"] and not m.milestones[1]["done"], "Kohlberg: Linie Farm 3 → Mühle 2 hakt 'Kohlemine → Kraftwerk' NICHT ab (Linien %d, Ziel 1 %s, Ziel 3 %s)" % [n_lines, str(m.milestones[1]["done"]), str(m.milestones[3]["done"])])
	var kohle = m.by_id["kohle_1"]
	var kw = m.by_id["kraftwerk_1"]
	m.ui_buy_licence(kohle)
	var kc := Vector2i(kohle.anchor().x, kw.anchor().y)
	drag(m.Tool.ROAD, kohle.anchor(), kc)
	drag(m.Tool.ROAD, kc, kw.anchor())
	m._set_tool(m.Tool.TRUCK_LINE)
	m.click(kohle.anchor())
	m.click(kw.anchor())
	m._set_tool(m.Tool.NONE)
	m._check_milestones()
	ok(m.milestones[1]["done"] and m.milestones[2]["done"] and m.milestones[3]["done"], "Kohlberg: Kohlemine → Kraftwerk hakt Ziele 1–3 ab")

	print("== B-xx 3) Toast bei Lizenzverlängerung mit Betrag")
	_fresh("haberau")
	var farm = m.by_id["farm_1"]
	m.ui_buy_licence(farm)
	m.ui_buy_licence(m.by_id["muehle_1"])     # zweite Lizenz kostet Geld
	var mill_site: int = m.by_id["muehle_1"].site
	var cost: int = m.eco._licence_cost(mill_site)
	var t_now: int = m.shim.tick_count
	m.eco.s_lic_until[mill_site] = t_now + 3
	m.eco._update_next_expiry()
	var cash0: int = m.eco.cash_cent
	m.licence_toasts.clear()
	m.run_ticks(m.eco.oeko_tick_ticks + 5)
	var tt: String = m.licence_toasts[0] if not m.licence_toasts.is_empty() else ""
	ok(tt.contains("Mühle 1 verlängert") and tt.contains(m.money_str(cost)) and m.toast_label.text.contains("verlängert"),
		"Toast '%s' (Betrag %s, Kasse vorher %s)" % [tt, m.money_str(cost), m.money_str(cash0)])
	ok(m.eco.licence_valid(mill_site), "Lizenz nach Verlängerung gültig")

	print("== B-xx 4) Kein '-0 $' beim Bankrott")
	ok(m.money_str(-37) == "0 $" and m.money_str(-250) == "-2 $" and m.money_str(-123456) == "-1.234 $" and m.money_str(0) == "0 $",
		"money_str: -37 ct → '%s', -250 ct → '%s', -123456 ct → '%s'" % [m.money_str(-37), m.money_str(-250), m.money_str(-123456)])
	_fresh("haberau")
	m.eco.cash_cent = -37
	m.sim_tick()
	m._update_hud(0)
	var bl: String = m.bankrupt_label.text
	var hk: String = m.hud_vals["kasse"].text
	ok(m.bankrupt and not bl.contains("-0 $") and bl.contains("-0,37 $") and hk == "0 $", "Bankrott bei -0,37 $: Overlay '%s…', Kasse oben '%s'" % [bl.substr(0, 40), hk])

	m.free()
	print("== %d/%d Prüfungen OK" % [checks - fails, checks])
	quit(0 if fails == 0 else 1)
