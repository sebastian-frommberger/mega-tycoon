extends SceneTree
## D-07 (Daniel Richter, Sprint 5 Tag 6-10): UNABHÄNGIGE Abnahmeprüfungen, nicht aus slice_test.gd übernommen.
## Start: godot --headless --path slice -s res://tests/d07_abnahme.gd [-- --only=ui|kredit|parity|lager|hq]
## Exit 0 = alle Prüfungen bestanden. Zeiten sind Sandbox-Zeiten (kein Zielrechner).

const MAIN := "res://main.tscn"
const MainScript := preload("res://main.gd")
const CreditScript := preload("res://credit.gd")

var m: Node
var fails := 0
var checks := 0
var only := ""
var findings: Array = []


class FakeEco:
	var slice: Dictionary = {}
	var periode_ticks := 600
	var cash_cent := 0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.substr(7)
	_run.call_deferred()


func ok(cond: bool, what: String) -> void:
	checks += 1
	if cond:
		print("  OK   ", what)
	else:
		fails += 1
		print("  FAIL ", what)


func note(s: String) -> void:
	findings.append(s)
	print("  NOTE ", s)


func _new_main(core := "soa") -> void:
	if m != null:
		m.free()
	MainScript.core_override = core
	m = load(MAIN).instantiate()
	root.add_child(m)


func drag(tool: int, a: Vector2i, b: Vector2i) -> bool:
	m._set_tool(tool)
	m.begin_drag(a)
	m.drag_to(b)
	return m.end_drag()


func line(tool: int, a, b):
	m._set_tool(tool)
	var n0: int = m.vehicles.size()
	m.click(a.anchor())
	m.click(b.anchor())
	m._set_tool(m.Tool.NONE)
	return m.vehicles[-1] if m.vehicles.size() > n0 else null


func frames(n: int) -> void:
	for i in n:
		await process_frame


func real_click(c: Control, hold_ms := 0) -> void:
	## hold_ms = 0: Druck und Loslassen in aufeinanderfolgenden Frames (Maschinenklick); > 0: Haltezeit wie bei einem Menschen (ca. 80-120 ms).
	var p := c.get_global_rect().get_center()
	var mv := InputEventMouseMotion.new()
	mv.position = p
	mv.global_position = p
	root.push_input(mv, true)
	await process_frame
	var d := InputEventMouseButton.new()
	d.button_index = MOUSE_BUTTON_LEFT
	d.pressed = true
	d.position = p
	d.global_position = p
	root.push_input(d, true)
	if hold_ms > 0:
		await create_timer(hold_ms / 1000.0).timeout
	else:
		await process_frame
	var u := InputEventMouseButton.new()
	u.button_index = MOUSE_BUTTON_LEFT
	u.pressed = false
	u.position = p
	u.global_position = p
	root.push_input(u, true)
	await process_frame


## Klickt den Panelknopf mit echten Ereignissen, bis die Lizenz gilt (max. 4 Versuche). Rückgabe: Anzahl Klicks.
func click_panel_until_licensed(site: int) -> int:
	var n := 0
	while n < 4 and not m.eco.licence_valid(site):
		await real_click(m.panel_button)
		n += 1
		await frames(2)
	if n > 1:
		note("Klick auf Lizenzknopf ging %d-mal verloren (siehe A10b)" % (n - 1))
	return n


func _collect(n: Node, out: Array, cls: String) -> void:
	if n.is_class(cls):
		out.append(n)
	for ch in n.get_children():
		_collect(ch, out, cls)


func _lin(c: float) -> float:
	return c / 12.92 if c <= 0.03928 else pow((c + 0.055) / 1.055, 2.4)


func _contrast(a: Color, b: Color) -> float:
	var la := 0.2126 * _lin(a.r) + 0.7152 * _lin(a.g) + 0.0722 * _lin(a.b)
	var lb := 0.2126 * _lin(b.r) + 0.7152 * _lin(b.g) + 0.0722 * _lin(b.b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


func _run() -> void:
	var T0 := Time.get_ticks_usec()
	if only == "" or only == "ui":
		await _ui()
	if only == "" or only == "kredit":
		await _kredit()
	if only == "" or only == "parity":
		_parity()
	if only == "" or only == "lager":
		_lager()
	if only == "" or only == "hq":
		await _hq()
	print("")
	for f in findings:
		print("  · ", f)
	print("\n%d/%d Abnahmeprüfungen OK, Laufzeit %.1f s (Sandbox)" % [checks - fails, checks, (Time.get_ticks_usec() - T0) / 1e6])
	if m:
		m.free()
	quit(1 if fails > 0 else 0)


# ====================================================================== UI: F-15 / U-01
func _ui() -> void:
	print("== A) F-15 Lizenzkauf per ECHTEN Mausereignissen, Modale, Übergänge, Klick-Sound, Styleguide")
	_new_main()
	await frames(3)
	var wins: Array = []
	_collect(m, wins, "Window")
	ok(wins.is_empty(), "A1 keine Window/Popup/AcceptDialog-Knoten in der Szene vor dem Start (%d)" % wins.size())
	ok(_centered_panels().is_empty(), "A1b F-20: auch vor der Gründung keine zentrierte große Fläche (kein Startdialog) %s" % str(_centered_panels()))
	m.place_hq("haberau")
	await frames(10)
	wins.clear()
	_collect(m, wins, "Window")
	ok(wins.is_empty(), "A2 keine Window/Popup-Knoten nach Start (%d)" % wins.size())
	var cb := _centered_panels()
	ok(cb.is_empty(), "A3 nach Start keine sichtbare, zentrierte große Fläche (%s)" % str(cb))
	ok(not m.hq.panel.visible and m.hq.mode == m.hq.Mode.FOUNDED, "A4 HQ-Vorschau nach Gründung unsichtbar (F-20, kein Startdialog mehr)")
	var farm = m.by_id["farm_1"]
	var clicks0: int = m.fx.clicks
	var cash0: int = m.eco.cash_cent
	var n_clicks := 0
	m.click(farm.anchor())                 # Klick 1 (Welt: Zellklick, Raycast headless nicht ansprechbar)
	n_clicks += 1
	await frames(2)
	var vw: float = root.get_visible_rect().size.x
	ok(m.panel.visible, "A5 Panel sichtbar nach Klick 1")
	await create_timer(0.35).timeout        # Slide 150 ms abwarten (Realzeit)
	var pr: Rect2 = m.panel.get_global_rect()
	print("     Panel-Rect nach Slide: %s, Viewport-Breite %.0f -> Breite %.1f %%" % [str(pr), vw, pr.size.x / vw * 100.0])
	ok(pr.size.x / vw <= 0.25 + 0.0001, "A6 Panel-Breite %.2f %% ≤ 25 %%" % (pr.size.x / vw * 100.0))
	ok(pr.end.x <= vw + 0.5 and pr.end.x >= vw - 24.0, "A7 Panel rechts angedockt, Randabstand %.0f px (≤ 24 erlaubt)" % (vw - pr.end.x))
	var btn: Button = m.panel_button
	ok(btn.visible and not btn.disabled, "A8 Primärknopf sichtbar und aktiv: \"%s\"" % btn.text.replace("\n", " / "))
	var cr := btn.get_global_rect()
	ok(Rect2(Vector2.ZERO, root.get_visible_rect().size).encloses(cr), "A9 Primärknopf liegt vollständig im Viewport %s" % str(cr))
	n_clicks += await click_panel_until_licensed(farm.site)      # Klick 2 (echtes Ereignis über den Viewport)
	ok(m.eco.licence_valid(farm.site), "A10 Lizenz Farm nach ECHTEM Klick auf den Knopf aktiv")
	ok(m.fx.clicks - clicks0 == 1, "A11 genau 1 Klick-Sound beim Panelklick (%d)" % (m.fx.clicks - clicks0))
	ok(n_clicks <= 3, "A12 Lizenzkauf in %d Klicks (≤ 3), Kasse %s -> %s (1. Lizenz gratis)" % [n_clicks, m.money_str(cash0), m.money_str(m.eco.cash_cent)])
	var mill = m.by_id["muehle_1"]
	m.click(mill.anchor())
	await create_timer(0.3).timeout
	var cash1: int = m.eco.cash_cent
	var q: Dictionary = m.licence_quote(mill)
	var n13: int = await click_panel_until_licensed(mill.site)
	ok(m.eco.licence_valid(mill.site) and m.eco.cash_cent == cash1 - int(q.get("zu_zahlen_cent", -1)),
		"A13 2. Lizenz (Mühle) in %d Klicks (Welt + Panel, ≤ 3 sind erlaubt), Kasse -%s wie im Knopf angezeigt" % [n13 + 1, m.money_str(int(q.get("zu_zahlen_cent", 0)))])
	ok(m.panel_button.visible and m.panel_button.text.to_lower().contains("linie"), "A14 nach Kauf wird der Knopf zu \"%s\"" % m.panel_button.text.replace("\n", " / "))
	m.click(Vector2i(mill.anchor().x + 40, mill.anchor().y + 40))
	await create_timer(0.3).timeout
	ok(m.selected == null and not m.panel.visible, "A15 Klick daneben schließt Panel (nach Slide-out unsichtbar)")
	m.open_panel(farm)
	await create_timer(0.3).timeout
	ok(_centered_panels().is_empty(), "A16 mit offenem Panel keine zentrierte Fläche")
	m.eco.cash_cent = -1
	m.sim_tick()
	await create_timer(0.4).timeout
	ok(m.bankrupt and m.bankrupt_panel.visible, "A17 Bankrott erreicht, Banner sichtbar")
	var bc := _centered_panels()
	ok(bc.is_empty(), "A18 im Bankrott-Zustand keine zentrierte Fläche/Modal (%s)" % str(bc))
	print("     Bankrott-Banner Rect: ", m.bankrupt_panel.get_global_rect(), " Viewport ", root.get_visible_rect().size)

	# --- A19a: Klicks mit menschlicher Haltezeit (90 ms) bei wechselnder Phase zum 250-ms-Refresh des Panels
	var human_ok := 0
	var trials := 16
	for i in trials:
		_new_main()
		await frames(2)
		m.place_hq("haberau")
		await frames(4)
		var fm = m.by_id["farm_1"]
		m.click(fm.anchor())
		await create_timer(0.30 + i * 0.016).timeout      # Phase zum Refresh-Takt (0,25 s) streuen
		await real_click(m.panel_button, 90)
		await frames(2)
		if m.eco.licence_valid(fm.site):
			human_ok += 1
	ok(human_ok == trials, "A10b Lizenzklick mit 90 ms Haltezeit: %d/%d Klicks kommen an (Phase zum 0,25-s-Refresh variiert)" % [human_ok, trials])
	if human_ok < trials:
		note("A10b BUG: _refresh_panel() (main.gd, alle 0,25 s) setzt panel_button.visible=false und gleich wieder true; Godot bricht dabei einen gedrückten Knopf ab (mouse_exited), das Loslassen löst kein pressed aus. %d von %d Klicks mit 90 ms Haltezeit gingen verloren." % [trials - human_ok, trials])

	# --- Übergangszeiten: Quelltext-Scan + Realzeitmessung
	_new_main()
	await frames(3)
	m.place_hq("haberau")
	await frames(3)
	var dur: Array = []
	for path in ["res://ui/ui_fx.gd", "res://main.gd", "res://ui/ui_kit.gd", "res://ui/styleguide.gd", "res://credit.gd", "res://fleet_soa.gd", "res://core/diagnostics.gd"]:
		var f := FileAccess.open(path, FileAccess.READ)
		var txt := f.get_as_text()
		for ln in txt.split("\n"):
			if ln.contains("tween_property") or ln.contains("tween_interval") or ln.contains("tween_method"):
				dur.append(path.get_file() + ": " + ln.strip_edges())
	print("     Tween-Stellen im Code: ", dur.size())
	for d in dur:
		print("       ", d)
	var UiFx = m.UiFx
	ok(UiFx.HOVER_SEC <= 0.15 and UiFx.SLIDE_SEC <= 0.15, "A19 Konstanten Hover %.0f ms / Slide %.0f ms ≤ 150 ms" % [UiFx.HOVER_SEC * 1000, UiFx.SLIDE_SEC * 1000])
	var long_ui := []
	for d in dur:
		if d.begins_with("ui_fx.gd") and not (d.contains("HOVER_SEC") or d.contains("SLIDE_SEC")):
			long_ui.append(d)
	ok(long_ui.is_empty(), "A20 alle Tweens in ui_fx.gd laufen über HOVER_SEC/SLIDE_SEC (Abweichler: %s)" % str(long_ui))
	for d in dur:
		if d.begins_with("main.gd"):
			note("Tween außerhalb ui_fx.gd: %s (Weltlabel 1,5 s, kein UI-Übergang, aber nicht ≤ 150 ms)" % d)
	var tms: Array = []
	for k in 5:
		m.close_panel()
		await create_timer(0.3).timeout
		var s0 := Time.get_ticks_usec()
		m.open_panel(m.by_id["farm_1"])
		var tw: Tween = m.panel.get_meta("slide_tw")
		while tw.is_running():
			await process_frame
		tms.append(snappedf((Time.get_ticks_usec() - s0) / 1000.0, 1.0))
	var tmax := 0.0
	for t in tms:
		tmax = maxf(tmax, t)
	print("     Panel-Slide-in Realzeit je Lauf (ms, Sandbox, Frame-Granularität): ", tms)
	ok(tmax <= 150.0 + 40.0, "A21 Panel-Slide-in endet in ≤ 150 ms (+ 1 Frame Toleranz): max %.0f ms" % tmax)

	# --- Alle Buttons: Klick-Sound (verdrahtet UND wirksam)
	await create_timer(0.2).timeout
	var buttons: Array = []
	_collect(m.ui_root, buttons, "BaseButton")
	var unwired := []
	for b in buttons:
		var has := false
		for cn in b.pressed.get_connections():
			var cal: Callable = cn["callable"]
			if cal.get_object() == m.fx:
				has = true
		if not has:
			unwired.append(str(b.get_path()))
	ok(unwired.is_empty() and buttons.size() > 0, "A22 alle %d Knöpfe im UI haben die Klick-Verbindung zu UiFx (ohne: %s)" % [buttons.size(), str(unwired)])
	var silent := []
	for b in buttons:
		if b.disabled or ("Neu starten" in b.text):
			continue
		var c0: int = m.fx.clicks
		b.pressed.emit()
		if m.fx.clicks != c0 + 1:
			silent.append(str(b.name))
	ok(silent.is_empty(), "A23 jeder aktive Knopf löst genau einen Klick aus (still: %s)" % str(silent))
	ok(m.fx._player.stream != null and m.fx._player.volume_db <= -10.0, "A24 Klick-Stream geladen (Länge %.2f s), %.0f dB" % [m.fx._player.stream.get_length(), m.fx._player.volume_db])
	_new_main()
	await frames(3)
	m.place_hq("haberau")
	await frames(3)
	var farm2 = m.by_id["farm_1"]
	var mill2 = m.by_id["muehle_1"]
	m.ui_buy_licence(farm2)
	m.ui_buy_licence(mill2)
	drag(m.Tool.ROAD, farm2.anchor(), mill2.anchor())
	var vv = line(m.Tool.TRUCK_LINE, farm2, mill2)
	await frames(5)
	var b2: Array = []
	_collect(m.ui_root, b2, "BaseButton")
	var un2 := 0
	for b in b2:
		if not b.has_meta("ui_fx"):
			un2 += 1
	ok(vv != null and un2 == 0, "A25 Knöpfe, die erst durch Linienbau entstehen, sind verdrahtet (%d Knöpfe, %d ohne)" % [b2.size(), un2])

	# --- Styleguide: Komponenten × Zustände (eigene Zählung, Unterscheidbarkeit, Kontrast)
	var sg = load("res://ui/styleguide.tscn").instantiate()
	root.add_child(sg)
	await frames(3)
	var grids: Array = []
	_collect(sg, grids, "GridContainer")
	var comp_grid: GridContainer = null
	for g in grids:
		if g.columns == 5:
			comp_grid = g
	ok(comp_grid != null, "A26 Styleguide enthält das Komponenten-Raster (5 Spalten)")
	if comp_grid:
		var cells := comp_grid.get_child_count() - 5
		var rows := cells / 5
		ok(rows >= 12 and cells % 5 == 0, "A27 Raster: %d Komponentenzeilen × 4 Zustände (eigene Zählung, %d Kinder)" % [rows, comp_grid.get_child_count()])
		var identical := []
		for rI in rows:
			var base := 5 + rI * 5
			var name_lbl := (comp_grid.get_child(base).get_child(0) as Label).text
			var uniq := {}
			for s in 4:
				var cell := comp_grid.get_child(base + 1 + s)
				var btnx: Button = cell if cell is Button else (cell.get_child(0) as Button)
				var sbx: StyleBox = btnx.get_theme_stylebox("disabled" if btnx.disabled else "normal")
				var sb_col := Color.TRANSPARENT
				var sb_bord := Color.TRANSPARENT
				if sbx is StyleBoxFlat:
					sb_col = (sbx as StyleBoxFlat).bg_color
					sb_bord = (sbx as StyleBoxFlat).border_color
				uniq["%s|%s|%s|%s|%s" % [sb_col.to_html(), sb_bord.to_html(), str(btnx.disabled), btnx.modulate.to_html(), btnx.get_theme_color("font_color").to_html()]] = true
			if uniq.size() < 4:
				identical.append("%s (%d von 4 unterscheidbar)" % [name_lbl, uniq.size()])
		ok(identical.is_empty(), "A28 in jeder Zeile sind alle 4 Zustände sichtbar verschieden (Mängel: %s)" % str(identical))
	var th2: Theme = sg.th
	var low := []
	var minc := 99.0
	for typ in ["ButtonPrimary", "ButtonSecondary", "ButtonDanger", "ButtonGhost", "ButtonTool", "ButtonTempo", "ButtonClose", "ButtonTile", "ButtonRow", "ButtonTab", "ButtonChip"]:
		for st in [["normal", "font_color"], ["hover", "font_hover_color"], ["pressed", "font_pressed_color"], ["disabled", "font_disabled_color"]]:
			var sbx2: StyleBox = th2.get_stylebox(st[0], typ)
			if sbx2 is StyleBoxFlat:
				var bg: Color = (sbx2 as StyleBoxFlat).bg_color
				if bg.a < 0.2:
					continue
				var fg: Color = th2.get_color(st[1], typ)
				var cc := _contrast(fg, bg)
				if st[0] != "disabled":
					minc = minf(minc, cc)
				if cc < 4.5:
					low.append("%s/%s %.2f" % [typ, st[0], cc])
	print("     Kontrast Schrift/Stylebox (ohne disabled) min %.2f; unter 4,5: %s" % [minc, str(low)])
	ok(low.filter(func(x): return not x.contains("/disabled")).is_empty(), "A29 Kontrast ≥ 4,5:1 für alle aktiven Zustände gegen die echte Stylebox (min %.2f)" % minc)
	var dis_low := low.filter(func(x): return x.contains("/disabled"))
	if not dis_low.is_empty():
		note("Disabled-Texte unter 4,5:1 (WCAG nimmt disabled aus): %s" % str(dis_low))
	sg.free()


func _centered_panels() -> Array:
	var out: Array = []
	var vs := root.get_visible_rect().size
	var ctr := vs * 0.5
	var all: Array = []
	_collect(m, all, "Control")
	for c in all:
		var cc := c as Control
		if not cc.is_visible_in_tree():
			continue
		if not (cc is PanelContainer or cc is Panel):
			continue
		var r := cc.get_global_rect()
		if r.size.x < 300 or r.size.y < 120:
			continue
		if r.size.x >= vs.x * 0.9 and r.size.y >= vs.y * 0.9:
			continue
		if r.has_point(ctr) and absf(r.get_center().x - ctr.x) < vs.x * 0.15 and absf(r.get_center().y - ctr.y) < vs.y * 0.15:
			out.append("%s %s" % [cc.name, str(r)])
	return out


# ====================================================================== F-19 Kredit
func _kredit() -> void:
	print("== B) F-19 Kredit: Aufnehmen/Tilgen, Obergrenze, Zins aus JSON, Kreislauf ohne Geld-Exploit")
	_new_main()
	m.place_hq("haberau")
	var k: Dictionary = m.eco.slice["kredit"]
	var lim: int = int(k["credit_limit_cent"])
	var c0: int = m.eco.cash_cent
	var got := 0
	for i in 12:
		got += m.ui_credit_borrow()
	ok(m.credit.loan_cent == lim and got == lim and m.eco.cash_cent == c0 + lim, "B1 Obergrenze %s aus JSON hart: 12 Versuche, Kredit %s" % [m.money_str(lim), m.money_str(m.credit.loan_cent)])
	ok(m.ui_credit_borrow() == 0 and m.credit.loan_cent == lim, "B2 weiterer Versuch über Rahmen gibt 0")
	var es := FakeEco.new()
	es.slice = {"kredit": {"credit_limit_cent": 300000, "credit_interest_promille_pro_periode": 25, "credit_available_from_ticks": 0, "credit_active_in_slice_flag": true}}
	var cr = CreditScript.new()
	cr.setup(es)
	cr.borrow(es, 0)
	ok(cr.limit_cent == 300000 and cr.interest_pm == 25 and cr.interest_due(600) == (50000 * 25 + 500) / 1000, "B3 Limit 3.000 $ und Zins 25 ‰ aus abweichendem JSON übernommen (Zins je Periode %d ¢)" % cr.interest_due(600))
	es.slice = {"kredit": {"credit_limit_cent": 200000, "credit_interest_promille_pro_periode": 10, "credit_available_from_ticks": 100, "credit_active_in_slice_flag": true}}
	var cr2 = CreditScript.new()
	cr2.setup(es)
	ok(cr2.borrow(es, 99) == 0 and cr2.borrow(es, 100) > 0, "B4 credit_available_from_ticks respektiert (99 gesperrt, 100 frei)")
	es.slice = {"kredit": {"credit_limit_cent": 200000, "credit_interest_promille_pro_periode": 10, "credit_available_from_ticks": 0, "credit_active_in_slice_flag": false}}
	var cr3 = CreditScript.new()
	cr3.setup(es)
	ok(cr3.borrow(es, 0) == 0, "B5 credit_active_in_slice_flag=false sperrt den Kredit")
	_new_main()
	m.place_hq("haberau")
	for i in 4:
		m.ui_credit_borrow()
	var cash_a: int = m.eco.cash_cent
	m.run_ticks(m.periode_ticks * 3)
	var want := 3 * ((lim * int(k["credit_interest_promille_pro_periode"]) + 500) / 1000)
	ok(cash_a - m.eco.cash_cent == want and m.credit.interest_paid == want, "B6 3 Perioden Zins %s abgebucht (erwartet %s), Kasse -%s" % [m.money_str(m.credit.interest_paid), m.money_str(want), m.money_str(cash_a - m.eco.cash_cent)])
	var viol := 0
	for fall in 20:
		_new_main("soa")
		m.place_hq("haberau" if fall % 2 == 0 else "kohlberg")
		var rng := RandomNumberGenerator.new()
		rng.seed = 7000 + fall
		var start_cash: int = m.eco.cash_cent
		for step in 150:
			var r := rng.randi_range(0, 9)
			if r < 4:
				m.ui_credit_borrow()
			elif r < 8:
				m.ui_credit_repay()
			else:
				m.run_ticks(rng.randi_range(1, 400))
			var lo: int = m.credit.loan_cent
			if lo < 0 or lo > lim or lo % 50000 != 0:
				viol += 1
			if m.eco.cash_cent != start_cash + lo - m.credit.interest_paid:
				viol += 1
		for i in 5:
			m.ui_credit_repay()
		if m.credit.loan_cent == 0 and m.eco.cash_cent > start_cash:
			viol += 1
	ok(viol == 0, "B7 20 Kreislauf-Fälle × 150 Aktionen: Kasse == Start + Kredit - Zins in jedem Schritt, Kredit in [0, Rahmen] in 500-$-Schritten, kein Gewinn nach Volltilgung (Verstöße: %d)" % viol)
	_new_main()
	m.place_hq("haberau")
	m.ui_credit_borrow()
	m.eco.cash_cent = 499
	var cb: int = m.eco.cash_cent
	ok(m.ui_credit_repay() == 0 and m.eco.cash_cent == cb, "B8 Tilgen mit 4,99 $ Kasse abgelehnt, Kasse unverändert")
	# B10 zinsfreies Fenster
	_new_main()
	m.place_hq("haberau")
	m.run_ticks(1)
	for i in 4:
		m.ui_credit_borrow()
	var t_before: int = m.shim.tick_count
	m.run_ticks(m.periode_ticks - 2 - (t_before % m.periode_ticks))
	for i in 5:
		m.ui_credit_repay()
	m.run_ticks(m.periode_ticks * 2)
	var free_window: bool = m.credit.interest_paid == 0 and m.credit.loan_cent == 0
	print("     Kredit ab Tick %d bis Tilgung kurz vor Periodenende, Zins gezahlt: %d ¢" % [t_before, m.credit.interest_paid])
	if free_window:
		note("B10 Zinsfenster: 2.000 $ für fast eine volle Periode (ca. %.0f s Spielzeit) zinsfrei, weil der Zins nur auf den Bestand am Periodenende fällt (nicht zeitgewichtet)." % ((m.periode_ticks - 2) / 10.0))
	ok(true, "B10 Zinsfenster geprüft (zinsfrei möglich: %s)" % str(free_window))
	# B11 Gegenrichtung
	_new_main()
	m.place_hq("haberau")
	m.run_ticks(m.periode_ticks - 1 - (m.shim.tick_count % m.periode_ticks))
	m.ui_credit_borrow()
	m.run_ticks(2)
	if m.credit.interest_paid > 0:
		note("B11 Volle Periodenzins (%s) für ca. 1 Tick Kredit (Gegenstück zu B10, ärgerlich, kein Exploit)." % m.money_str(m.credit.interest_paid))
	ok(true, "B11 Gegenrichtung geprüft: Zins nach Aufnahme 1 Tick vor Periodenende %d ¢" % m.credit.interest_paid)
	_new_main()
	m.place_hq("haberau")
	ok(m.credit.loan_cent == 0 and m.credit.interest_paid == 0, "B12 neue Instanz startet mit Kredit 0")
	m.ui_credit_borrow()
	m.eco.cash_cent = 0
	m.run_ticks(m.periode_ticks)
	ok(m.bankrupt, "B13 Kasse 0 $ + offener Kredit: Zins macht Kasse negativ -> Bankrott")
	_new_main()
	await frames(3)
	m.place_hq("haberau")
	await frames(5)
	var plus: Button = m.credit_buttons[0]
	var minus: Button = m.credit_buttons[1]
	var cc0: int = m.eco.cash_cent
	await real_click(plus)
	ok(m.credit.loan_cent == 50000 and m.eco.cash_cent == cc0 + 50000, "B14 echter Klick auf [+] im HUD: +500 $ (Kredit %s)" % m.money_str(m.credit.loan_cent))
	await real_click(minus)
	ok(m.credit.loan_cent == 0 and m.eco.cash_cent == cc0, "B15 echter Klick auf [-]: Kredit 0, Kasse wieder %s" % m.money_str(m.eco.cash_cent))
	var rr := plus.get_global_rect()
	ok(Rect2(Vector2.ZERO, root.get_visible_rect().size).encloses(rr) and rr.size.x >= 24 and rr.size.y >= 24, "B16 [+] im Viewport und ≥ 24 px Klickfläche (%s)" % str(rr.size))
	ok(plus.tooltip_text.contains("500"), "B17 Tooltip [+]: \"%s\"" % plus.tooltip_text)


# ====================================================================== SoA gegen alt: 10 Seeds
func _scenario(core: String, seed: int) -> Dictionary:
	_new_main(core)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1000 + seed
	var arch := "agrar" if seed % 2 == 0 else "bergbau"
	m.place_hq("haberau" if arch == "agrar" else "kohlberg")
	var trucks := rng.randi_range(1, 4)
	var ticks := rng.randi_range(4000, 12000) + int(OS.get_environment("D07_TICKS_ADD") if OS.get_environment("D07_TICKS_ADD") != "" else "0")
	var use_credit := rng.randi() % 3 == 0
	if arch == "agrar":
		var farm = m.by_id["farm_1"]
		var mill = m.by_id["muehle_1"]
		m.ui_buy_licence(farm)
		if rng.randi() % 2 == 0:
			m.ui_buy_licence(mill)
		drag(m.Tool.ROAD, farm.anchor(), mill.anchor())
		for i in trucks:
			line(m.Tool.TRUCK_LINE, farm, mill)
		if rng.randi() % 2 == 0:
			var haberau = m.by_id["haberau"]
			var ys := -1
			for y in range(mill.anchor().y, haberau.anchor().y + 1):
				if m.city_streets.has(Vector2i(haberau.anchor().x, y)):
					ys = y
					break
			var corner := Vector2i(haberau.anchor().x, mill.anchor().y)
			drag(m.Tool.ROAD, mill.anchor(), corner)
			drag(m.Tool.ROAD, corner, Vector2i(haberau.anchor().x, ys))
			for i in rng.randi_range(1, 2):
				line(m.Tool.TRUCK_LINE, mill, haberau)
	else:
		var kohle = m.by_id["kohle_1"]
		var kw = m.by_id["kraftwerk_1"]
		m.ui_buy_licence(kohle)
		var kc := Vector2i(kohle.anchor().x, kw.anchor().y)
		drag(m.Tool.ROAD, kohle.anchor(), kc)
		drag(m.Tool.ROAD, kc, kw.anchor())
		for i in trucks:
			line(m.Tool.TRUCK_LINE, kohle, kw)
		if use_credit:
			for i in 4:
				m.ui_credit_borrow()
	if seed % 3 == 1:
		var sp := _corridor(Vector2i(300 + seed * 7, 300), 24)
		if sp.x >= 0:
			var a = m.build_warehouse(sp)
			var b = m.build_warehouse(sp + Vector2i(22, 0))
			drag(m.Tool.ROAD, sp + Vector2i(1, 0), sp + Vector2i(22, 0))
			m.eco.seed_stock(a.site, "getreide", rng.randi_range(20, 140))
			line(m.Tool.TRUCK_LINE, a, b)
	m.run_ticks(ticks)
	var stocks := 0
	for st in m.shim.st_stock:
		stocks += int(st)
	if OS.get_environment("D07_DEBUG") != "":
		var vs := []
		for v in m.vehicles:
			vs.append([v.deliveries, v.income_total, v.cost_total()])
		print("     DBG %s seed %d: exp=%d rev=%d run_cost=%d cost_acc=%d veh=%s" % [core, seed, m.expenses_total, m.eco.revenue_total, m.running_cost_per_period, m.cost_acc, str(vs)])
	return {"cash": m.eco.cash_cent, "deliv": m.deliveries.size(), "profit": m.deliveries_profit, "stock": stocks, "veh": m.vehicles.size(),
		"rev": m.eco.revenue_total, "ticks": ticks, "arch": arch, "trucks": trucks}


func _corridor(start: Vector2i, len: int) -> Vector2i:
	for dy in range(0, 120, 3):
		for dx in range(-100, 100, 3):
			var c := start + Vector2i(dx, dy)
			var free := true
			for x in range(c.x, c.x + len):
				for yy in [0, 1]:
					var cc := Vector2i(x, c.y + yy)
					if not m._in_grid(cc) or m.terrain_at(cc) != m.Terrain.PLAIN or m.cell_to_building.has(cc) or m.roads.has(cc) or m.city_streets.has(cc):
						free = false
			if free:
				return c
	return Vector2i(-1, -1)


func _corridor_near(start: Vector2i, len: int) -> Vector2i:
	var best := Vector2i(-1, -1)
	var bd := 1e9
	for dy in range(-60, 61, 2):
		for dx in range(-60, 61, 2):
			var c := start + Vector2i(dx, dy)
			var free := true
			for x in range(c.x, c.x + len):
				for yy in [0, 1]:
					var cc := Vector2i(x, c.y + yy)
					if not m._in_grid(cc) or m.terrain_at(cc) != m.Terrain.PLAIN or m.cell_to_building.has(cc) or m.roads.has(cc) or m.city_streets.has(cc):
						free = false
						break
				if not free:
					break
			if free and Vector2(dx, dy).length() < bd:
				bd = Vector2(dx, dy).length()
				best = c
	return best


func _parity() -> void:
	print("== C) SoA gegen alt: Parität über 10 selbst gewählte Seeds (Archetyp, Lkw-Anzahl, Laufzeit, Kette, Lager, Kredit variieren)")
	var same := 0
	for s in 10:
		var a := _scenario("alt", s)
		var b := _scenario("soa", s)
		var eq: bool = a["cash"] == b["cash"] and a["deliv"] == b["deliv"] and a["profit"] == b["profit"] and a["stock"] == b["stock"] and a["veh"] == b["veh"] and a["rev"] == b["rev"]
		if eq:
			same += 1
		print("     seed %d %s trucks=%d ticks=%d: alt cash=%d deliv=%d stock=%d | soa cash=%d deliv=%d stock=%d -> %s" % [s, a["arch"], a["trucks"], a["ticks"], a["cash"], a["deliv"], a["stock"], b["cash"], b["deliv"], b["stock"], "GLEICH" if eq else "ABWEICHUNG"])
		ok(eq, "C%d Seed %d: Kasse/Lieferungen/Gewinnlieferungen/Lagerbestand/Ertrag alt == soa" % [s + 1, s])
	ok(same == 10, "C11 Parität %d/10 Seeds identisch" % same)
	var x := _scenario("soa", 3)
	var y := _scenario("soa", 3)
	ok(x["cash"] == y["cash"] and x["deliv"] == y["deliv"], "C12 soa deterministisch (Seed 3 zweimal: %d / %d)" % [x["cash"], y["cash"]])


# ====================================================================== Lager-Bug Regression
func _lager() -> void:
	print("== D) Lager-Bug (B-xx): Bestand ≤ Kapazität, keine Einheiten aus dem Nichts, 20 Läufe mit seed_stock, dazu regulärer Lauf")
	_new_main()
	m.place_hq("haberau")
	var cap: int = m.eco.warehouse_cap
	var runs_ok := 0
	var worst := 0
	for r in 20:
		_new_main("soa" if r % 2 == 0 else "alt")
		m.place_hq("haberau")
		var sp := _corridor(Vector2i(300, 300), 24)
		var a = m.build_warehouse(sp)
		var b = m.build_warehouse(sp + Vector2i(22, 0))
		drag(m.Tool.ROAD, sp + Vector2i(1, 0), sp + Vector2i(22, 0))
		var rng := RandomNumberGenerator.new()
		rng.seed = 5000 + r
		var sa := rng.randi_range(0, cap + 80)
		var sb := rng.randi_range(0, cap + 80)
		m.eco.seed_stock(a.site, "getreide", sa)
		m.eco.seed_stock(b.site, "getreide", sb)
		var nv := rng.randi_range(1, 4)
		for k in nv:
			line(m.Tool.TRUCK_LINE, a, b)
			if rng.randi() % 2 == 0:
				line(m.Tool.TRUCK_LINE, b, a)
		var total0: int = m.shim.st_stock[a.station] + m.shim.st_stock[b.station]
		var mx := 0
		var neg := false
		for i in 2400:
			m.sim_tick()
			mx = maxi(mx, maxi(m.shim.st_stock[a.station], m.shim.st_stock[b.station]))
			if m.shim.st_stock[a.station] < 0 or m.shim.st_stock[b.station] < 0:
				neg = true
		var cargo := 0
		for v in m.vehicles:
			cargo += v.cargo(m)
		var total1: int = m.shim.st_stock[a.station] + m.shim.st_stock[b.station] + cargo
		var limit := maxi(cap, maxi(sa, sb))
		worst = maxi(worst, mx)
		var good: bool = mx <= limit and not neg and total1 == total0
		if good:
			runs_ok += 1
		print("     Lauf %2d (%s): Start %d/%d, Lkw %d, max Bestand %d (Grenze %d), Summe %d -> %d %s" % [r, m.vehicle_core, sa, sb, m.vehicles.size(), mx, limit, total0, total1, "OK" if good else "VERLETZT"])
	ok(runs_ok == 20, "D1 20/20 Läufe: Bestand ≤ max(Kapazität %d, Startbestand), nie negativ, Summe der Einheiten erhalten (%d OK, höchster %d)" % [cap, runs_ok, worst])
	# D2: reguläres Spiel ohne seed_stock: Farm (Lizenz) füttert Lager A über Lkw, A -> B pendelt; Bestand ≤ Kapazität, Lieferungen > 0
	_new_main()
	m.place_hq("haberau")
	var farm = m.by_id["farm_1"]
	m.ui_buy_licence(farm)
	var sp2 := _corridor_near(farm.anchor() + Vector2i(4, 4), 24)
	var w = m.build_warehouse(sp2)
	var w2 = m.build_warehouse(sp2 + Vector2i(22, 0))
	var r1 := drag(m.Tool.ROAD, farm.anchor(), sp2 + Vector2i(1, 0))
	print("     D2 farm %s corridor %s road1: %s" % [str(farm.anchor()), str(sp2), str(m.plan.get("reason"))])
	var r2 := drag(m.Tool.ROAD, sp2 + Vector2i(1, 0), sp2 + Vector2i(22, 0))
	var nl := 0
	for i in 3:
		if line(m.Tool.TRUCK_LINE, farm, w) != null:
			nl += 1
	if line(m.Tool.TRUCK_LINE, w, w2) != null:
		nl += 1
	var mx2 := 0
	for i in 12000:
		m.sim_tick()
		mx2 = maxi(mx2, maxi(m.shim.st_stock[w.station], m.shim.st_stock[w2.station]))
	print("     D2 Aufbau: Straßen %s/%s, Linien %d, Lieferungen %d" % [str(r1), str(r2), nl, m.deliveries.size()])
	ok(nl >= 3 and mx2 > 0 and mx2 <= cap, "D2 reguläres Spiel ohne seed_stock: %d Linien, Lagerbestand max %d (>0, ≤ Kapazität %d) nach 20 Spielminuten" % [nl, mx2, cap])


# ====================================================================== F-20 HQ-Platzierung (D22), Mira S6
## Weltklicks: echte InputEventMouseButton über root.push_input auf eine freie Kartenstelle; das Zielfeld kommt aus
## main.sim_hover (Raycast headless nicht ansprechbar, wie A5). Panelknöpfe und Toast: real_click.
const WAGNIS := ["steinbach", "eichwald", "lindach", "weidenau", "seehafen"]


func _map_point() -> Vector2:
	var vs := root.get_visible_rect().size
	return Vector2(vs.x * 0.3, vs.y * 0.55)


func hover(cell: Vector2i) -> void:
	m.sim_hover_active = true
	m.sim_hover = cell
	var mv := InputEventMouseMotion.new()
	mv.position = _map_point()
	mv.global_position = mv.position
	root.push_input(mv, true)


func world_click(cell: Vector2i, button := MOUSE_BUTTON_LEFT) -> void:
	hover(cell)
	await process_frame
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = button
		e.pressed = pressed
		e.position = _map_point()
		e.global_position = e.position
		root.push_input(e, true)
		await process_frame


func key(code: int) -> void:
	for pressed in [true, false]:
		var e := InputEventKey.new()
		e.keycode = code
		e.physical_keycode = code
		e.pressed = pressed
		root.push_input(e, true)
		await process_frame


func _bg_of(c: Control) -> Color:
	var n: Node = c.get_parent()
	while n != null:
		if n is PanelContainer:
			var sb = (n as PanelContainer).get_theme_stylebox("panel")
			if sb is StyleBoxFlat:
				return (sb as StyleBoxFlat).bg_color
		n = n.get_parent()
	return Color.BLACK


func _hq() -> void:
	print("== H) F-20 HQ-Platzierung: Hover, Ghost, Gründen, Abbruch, Umsetzen-Regel (echte Eingabeereignisse)")
	_new_main()
	await frames(3)
	var hq = m.hq
	var t0: int = m.shim.tick_count
	m.sim_tick()
	m.set_speed(4)
	await frames(3)
	ok(not m.company_started and hq.mode == hq.Mode.PLACING and m.speed == 0 and m.shim.tick_count == t0 and m.tool == m.Tool.NONE,
		"H1 Start auf der Karte: Platzierungsmodus, Zeit pausiert (Tick %d, Tempo %d), kein Werkzeug" % [m.shim.tick_count, m.speed])
	ok(m.hud_vals["kasse"].text == m.money_str(int(m.eco.slice["hq"]["start_capital_cent"])), "H2 Kopfleiste zeigt vor der Gründung das Startkapital %s" % m.hud_vals["kasse"].text)
	var src := FileAccess.open("res://main.gd", FileAccess.READ).get_as_text()
	var eco_src := FileAccess.open("res://economy.gd", FileAccess.READ).get_as_text()
	ok(not src.to_lower().contains("archetyp") and not src.contains("ARCH[") and not src.contains("start_game(") and not eco_src.contains("func start_company(")
		and not eco_src.contains("archetyp") and not m.eco.slice["hq"].has("start_capital_agrar_cent"),
		"H3 kein Archetyp mehr in main.gd/economy.gd (start_game, ARCH, start_company entfernt), ein Kapital-Key")
	# --- Hover über alle 8 Städte
	var n_ok := 0
	var worst_ms := 0.0
	var worst_w := 0.0
	var worst_rows := 0
	var min_contrast := 99.0
	var bad_c: Array = []
	var wag_ok := true
	for st in m.map_data["staedte"]:
		var city = m.by_id[st["id"]]
		hover(Vector2i(int(st["x_felder"]), int(st["y_felder"])))
		var s0 := Time.get_ticks_usec()
		var nf := 0
		while hq.shown != city and nf < 10:
			await process_frame
			nf += 1
		var ms := (Time.get_ticks_usec() - s0) / 1000.0
		await frames(1)
		var vis := 0
		for r in hq.rows:
			if r["row"].visible:
				vis += 1
		var w: float = hq.panel.get_global_rect().size.x
		worst_ms = maxf(worst_ms, ms)
		worst_w = maxf(worst_w, w)
		worst_rows = maxi(worst_rows, vis)
		var good: bool = hq.shown == city and hq.panel.visible and hq.title_label.text == city.display_name and vis >= 3 and vis <= 6 and hq.status_label.text != "" and hq.hover_ring.visible
		var labels: Array = []
		_collect(hq.panel, labels, "Label")
		for l in labels:
			if not l.is_visible_in_tree() or l.text == "":
				continue
			var cr := _contrast(l.get_theme_color("font_color"), _bg_of(l))
			min_contrast = minf(min_contrast, cr)
			if cr < 4.5:
				bad_c.append("%s:%s %.2f" % [city.map_id, l.text.left(20), cr])
		if WAGNIS.has(city.map_id):
			var col: Color = hq.status_label.get_theme_color("font_color")
			wag_ok = wag_ok and hq.status_shape.kind == "warn" and col != m.ThemeBuilder.C["status_bad"] and col != m.ThemeBuilder.C["danger"] and col != m.ThemeBuilder.C["bad_text"]
		else:
			wag_ok = wag_ok and hq.status_shape.kind == "ok"
		print("     %-10s %s %d Zeilen, %s, %.0f ms bis Panel" % [city.display_name, hq.status_label.text, vis, "OK" if good else "FEHLT", ms])
		if good:
			n_ok += 1
	ok(n_ok == 8, "H4 8 von 8 Städten zeigen die Vorschau (%d), Quelle \"%s\"" % [n_ok, hq.vorschau_quelle])
	ok(worst_rows <= 6 and worst_w <= 380.5, "H5 Vorschau ≤ 6 Zeilen (max %d), Panel ≤ 380 px (max %.0f px), rechts angedockt" % [worst_rows, worst_w])
	ok(worst_ms <= 150.0 + 40.0, "H6 Vorschau nach Hover in ≤ 150 ms (+ 1 Frame): max %.0f ms (Sandbox)" % worst_ms)
	ok(bad_c.is_empty() and min_contrast >= 4.5, "H7 Kontrast aller Panel-Texte ≥ 4,5:1 (min %.2f) %s" % [min_contrast, str(bad_c)])
	ok(wag_ok, "H8 Zustände Icon + Text: Wagnis-Städte Dreieck „warn“ ohne Rot, Kette = Kreis „ok“")
	# --- Ring-Animation ≤ 0,4 s, Reduced Motion sofort
	var mf = m.by_id["mittelfurt"]
	hover(Vector2i(-1, -1))
	await frames(2)
	hover(mf.anchor())
	await frames(1)
	var r_full := float(hq.radius_of(mf))
	var sc0: float = hq.hover_ring.scale.x
	await create_timer(0.42).timeout
	var sc1: float = hq.hover_ring.scale.x
	ok(hq.RING_SEC <= 0.4 and sc0 < r_full and absf(sc1 - r_full) < 0.01, "H9 Ring wächst in %.2f s auf Radius %d (Start %.1f, nach 0,42 s %.1f)" % [hq.RING_SEC, int(r_full), sc0, sc1])
	hq.reduced_motion = true
	hover(Vector2i(-1, -1))
	await frames(2)
	hover(m.by_id["haberau"].anchor())
	await frames(1)
	ok(absf(hq.hover_ring.scale.x - hq.radius_of(m.by_id["haberau"])) < 0.01 and hq.ring_anim_sec() == 0.0, "H10 Reduced Motion: Ring sofort voll (%.1f)" % hq.hover_ring.scale.x)
	hq.reduced_motion = false
	# --- Klick: Ghost, Wechsel, Esc
	var clicks := 0
	ok(not hq.ghost.visible and hq.button.disabled, "H11 vor dem Klick kein Ghost, Knopf „HQ hier gründen“ inaktiv")
	await world_click(m.by_id["haberau"].anchor())
	clicks += 1
	await world_click(mf.anchor())
	clicks += 1
	var gp: Vector3 = hq.ghost.position
	var gd := Vector2(gp.x - mf.center().x, gp.z - mf.center().z).length()
	ok(hq.selected == mf and hq.ghost.visible and gd > mf.footprint.x * 0.5 and gd < mf.footprint.x * 0.5 + 12, "H12 Klick wählt Mittelfurt (Wechsel von Haberau): Ghost am Stadtrand (%.1f Felder vom Zentrum)" % gd)
	hover(Vector2i(-1, -1))
	await frames(2)
	ok(hq.panel.visible and hq.shown == mf and not hq.button.disabled and hq.button.text.contains("HQ hier gründen"), "H13 ohne Hover zeigt das Panel die Wahl, Primärknopf aktiv: \"%s\"" % hq.button.text.replace("\n", " / "))
	await key(KEY_ESCAPE)
	ok(hq.selected == null and not hq.ghost.visible and not m.company_started, "H14 Esc hebt die Wahl auf (kein Ghost, keine Firma)")
	await world_click(mf.anchor())
	clicks += 1
	hover(Vector2i(-1, -1))
	await frames(2)
	var wins: Array = []
	_collect(m, wins, "Window")
	ok(wins.is_empty() and _centered_panels().is_empty(), "H15 kein Modal und keine zentrierte Fläche im Platzierungsmodus")
	await real_click(hq.button)
	clicks += 1
	await frames(2)
	ok(m.company_started and m.hq_city == mf and m.eco.cash_cent == int(m.eco.slice["hq"]["start_capital_cent"]) and m.free_trucks_left == int(m.eco.slice["fahrzeug_ref"]["startpaket_lkw_anzahl"])
		and m.eco.hq_radius_felder == hq.radius_of(mf) and m.speed == 1 and not hq.panel.visible,
		"H16 „HQ hier gründen“ (echter Klick): Firma in Mittelfurt, Kasse %s, %d Gratis-Lkw, Radius %d, Zeit läuft" % [m.money_str(m.eco.cash_cent), m.free_trucks_left, m.eco.hq_radius_felder])
	ok(clicks <= 5, "H17 Gründung in %d Klicks ab Kartenstart (inkl. Wechsel und Esc-Probe, ≤ 5)" % clicks)
	ok(m.toast_label.text.contains("gegründet. Umsetzen kostenlos bis zur ersten Lizenz") and hq.hq_building != null and hq.hq_ring.visible, "H18 Toast „%s“, HQ-Gebäude (Hook _spawn_hq_building) und Ring stehen" % m.toast_label.text)
	ok(m.milestones.size() == 7 and m.milestones[0]["text"].contains("Mittelfurt") and m.milestones[1]["text"].begins_with("Lizenz für") and m.by_id.has(m.milestones[1]["t"][0]), "H19 Meilensteine aus der Startkette, Index 1 = erste Lizenz (M1b, U-02b): %s" % m.milestones[1]["text"])
	# --- Umsetzen: Ring-Label, Ring-Klick, Uhr steht, Esc
	await frames(2)
	ok(hq.ring_label.visible and hq.ring_label.text.begins_with("Umsetzen möglich, noch"), "H20 Ring-Label „%s“" % hq.ring_label.text)
	var ring_cell := Vector2i(int(mf.center().x + m.eco.hq_radius_felder), int(mf.center().z))
	await world_click(ring_cell)
	var tk: int = m.shim.tick_count
	var left0: int = hq._left_ms()
	m.set_speed(2)
	await frames(4)
	m.sim_tick()
	m.run_ticks(50)
	ok(hq.mode == hq.Mode.MOVING and m.shim.tick_count == tk and hq._left_ms() == left0 and m.speed == 0 and m.hint_label.text == "Neuen Standort wählen. Esc: HQ bleibt in Mittelfurt.",
		"H21 Klick auf den Ring: Umsetzen-Modus, Uhr und Zähler stehen (Tick %d, noch %s)" % [m.shim.tick_count, hq._mss(hq._left_ms())])
	await key(KEY_ESCAPE)
	ok(hq.mode == hq.Mode.FOUNDED and m.hq_city == mf and m.speed > 0 and m.toast_label.text == "Umsetzen abgebrochen. HQ bleibt in Mittelfurt.", "H22 Esc bricht ab: „%s“" % m.toast_label.text)
	# Toast-Klick (nach der Gründungs-/Umsetz-Meldung) startet das Umsetzen
	hq._set_move_toast("HQ in Mittelfurt gegründet. Umsetzen kostenlos bis zur ersten Lizenz, höchstens noch %s min." % hq._mss(hq._left_ms()), 8.0, true)
	await create_timer(0.3).timeout
	await real_click(m.toast_panel)
	ok(hq.mode == hq.Mode.MOVING, "H23 Klick auf den Toast startet das Umsetzen")
	var cash_m: int = m.eco.cash_cent
	await world_click(m.by_id["haberau"].anchor())
	hover(Vector2i(-1, -1))
	await frames(2)
	ok(hq.button.text.contains("HQ hierher umsetzen"), "H24 Knopf im Umsetzen-Modus: \"%s\"" % hq.button.text.replace("\n", " / "))
	await real_click(hq.button)
	await frames(2)
	var hb = m.by_id["haberau"]
	var hp: Vector2i = m.shim.graph.nodes[hb.node_id]["pos"] if m.shim.get("graph") != null else Vector2i(m.eco.hq_x, m.eco.hq_y)
	ok(m.hq_city == hb and hq.mode == hq.Mode.FOUNDED and m.eco.cash_cent == cash_m and m.eco.hq_radius_felder == hq.radius_of(hb) and m.eco.hq_x == hp.x
		and m.toast_label.text.begins_with("HQ nach Haberau umgesetzt. Noch "), "H25 Umsetzen nach Haberau kostenlos (Kasse %s), Radius %d: „%s“" % [m.money_str(m.eco.cash_cent), m.eco.hq_radius_felder, m.toast_label.text])
	# --- Regel: erste Lizenz (gratis) macht fest
	m.ui_buy_licence(m.by_id["farm_1"])
	hq.refresh_rule()
	ok(not hq.can_move() and hq.fixed and m.toast_label.text == "Erste Lizenz erworben. HQ in Haberau ist jetzt fest." and not hq.start_move(), "H26 Gratislizenz zählt: HQ fest, „%s“" % m.toast_label.text)
	await world_click(Vector2i(int(hb.center().x + m.eco.hq_radius_felder), int(hb.center().z)))
	ok(hq.mode == hq.Mode.FOUNDED and not hq.ring_label.visible, "H27 nach Festlegung kein Umsetzen per Ring, kein Ring-Label")
	# --- Regel: 2 min Spielzeit
	_new_main()
	await frames(2)
	hq = m.hq
	ok(m.place_hq("seehafen") and m.hq_city == m.by_id["seehafen"], "H28 Wagnis-Standort Seehafen gründbar (kein Sperren)")
	# D-08 Flake-Fix H29: place_hq startet Tempo 1, _physics_process tickt dann parallel zu run_ticks. Jeder echte Tick während
	# `await frames(1)` (ca. 25 % der Läufe, unter Last fast immer) verschiebt die 2-min-Grenze um 100 ms und macht „noch frei bei 1199“ rot.
	m.set_speed(0)
	var w_ticks: int = hq.MOVE_WINDOW_MS / m.tick_ms
	m.run_ticks(w_ticks - 200)
	hq.refresh_rule()
	await frames(1)
	var lbl20: String = hq.ring_label.text
	m.run_ticks(199)
	hq.refresh_rule()
	var still: bool = hq.can_move()
	m.run_ticks(1)
	hq.refresh_rule()
	ok(lbl20 == "Umsetzen noch 20 s" and still and not hq.can_move() and m.toast_label.text == "HQ in Seehafen ist jetzt fest.", "H29 2 min Spielzeit: „%s“ bei 20 s, bei %d Ticks noch frei, danach fest: „%s“" % [lbl20, w_ticks - 1, m.toast_label.text])
	# --- Meilenstein-Ziele für alle Städte gültig
	var tgt_ok := 0
	for st in m.map_data["staedte"]:
		var t: Dictionary = hq.start_targets(st["id"])
		if m.by_id.has(t["src"]) and m.by_id.has(t["proc"]) and m.by_id.has(t["m3_from"]) and m.by_id.has(t["m3_to"]):
			tgt_ok += 1
	var tk2: Dictionary = hq.start_targets("kohlberg")
	ok(tgt_ok == 8 and tk2["src"] in ["kohle_1", "erz_1"], "H30 Meilenstein-Ziele archetyp-unabhängig für 8/8 Städte (Kohlberg: %s → %s, M3 %s → %s)" % [tk2["src"], tk2["proc"], tk2["m3_from"], tk2["m3_to"]])
	m.sim_hover_active = false
