extends SceneTree
## Zocker-Session (Felix, S6): spielt eine Befehlsliste wie ein Spieler über Maus/Tasten ab und schreibt
## shot.png, state.md und eine Zeile in log.md. Aufruf über tools/play.sh <session_ordner>.
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --path . -s res://tests/play_session.gd -- <ordner>
## Determinismus: Die Sim läuft NUR in `wait` (run_ticks). _physics_process von main ist abgeschaltet, damit die
## Wanduhr (langsames Software-GL) keine Ticks einschiebt. Echte UI-Wege: warp_mouse + push_input wie d08_maus.gd.
## Befehle und Kennzeichnung (UI/API): tools/play_help.md.

const MainScript := preload("res://main.gd")
const Building := preload("res://building.gd")
const SAFE := Rect2(360, 90, 840, 640)       # freie Kartenfläche zwischen Linksspalte, Panel, HUD und Werkzeugleiste

var m: Node
var out_dir := ""
var toasts: Array = []          # [zeit, text]
var _last_toast := ""
var _ms_done: Array = []
var list_wanted := false
var cam_note := ""
var no_shot := false            # --no-shot: kein Schlussbild (spart ca. 10 s Software-GL)
var fast := false               # --fast: kürzere Panel-Pausen (spart ca. 0,2 s je Klickbefehl)
var budget_s := 100.0           # --budget=<s>: ab dieser Laufzeit werden restliche Befehle nicht mehr gespielt (0 = aus)
var settle_s := 0.35
var real_equiv_s := 0.0         # T-02: Echtzeit, die die `wait`s im Spiel bei dem jeweils eingestellten Tempo gedauert hätten
var aborted := ""


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	out_dir = a[0] if a.size() > 0 else "user://play"
	for x in a.slice(1):
		if x == "--no-shot":
			no_shot = true
		elif x == "--fast":
			fast = true
			settle_s = 0.12
		elif x.begins_with("--budget="):
			budget_s = float(x.substr(9))
	_run.call_deferred()


func frames(n: int) -> void:
	for i in n:
		await process_frame
		if m != null:
			poll()


func pause(sec: float) -> void:
	await create_timer(sec).timeout


# ------------------------------------------------------------------ Maus / Tasten (echte Eingaben)

func scr_cell(c: Vector2i) -> Vector2:
	return m.cam.unproject_position(Vector3(c.x + 0.5, 0.0, c.y + 0.5))


func move_to(p: Vector2) -> void:
	root.warp_mouse(p)
	var mv := InputEventMouseMotion.new()
	mv.position = p
	mv.global_position = p
	root.push_input(mv, true)
	await frames(2)


func button_ev(p: Vector2, pressed: bool, button := MOUSE_BUTTON_LEFT) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = button
	e.pressed = pressed
	e.position = p
	e.global_position = p
	root.push_input(e, true)
	await process_frame


func click_at(p: Vector2, button := MOUSE_BUTTON_LEFT) -> void:
	await move_to(p)
	await button_ev(p, true, button)
	await button_ev(p, false, button)
	await frames(2)


func click_control(c: Control) -> bool:
	if c == null or not c.is_visible_in_tree():
		return false
	await click_at(c.get_global_rect().get_center())
	return true


func key(code: int) -> void:
	for pressed in [true, false]:
		var e := InputEventKey.new()
		e.keycode = code
		e.physical_keycode = code
		e.pressed = pressed
		root.push_input(e, true)
		await process_frame
	await frames(1)


func occluded(p: Vector2) -> bool:
	return _occ(m, p)


func _occ(n: Node, p: Vector2) -> bool:
	for ch in n.get_children():
		if _occ(ch, p):
			return true
	var c := n as Control
	if c != null and c.is_visible_in_tree() and c.mouse_filter != Control.MOUSE_FILTER_IGNORE and c.get_global_rect().has_point(p):
		if not (c.get_global_rect().size.x > 1500):
			return true
	return false


## Maus auf ein Feld bringen, so dass main._mouse_cell() genau dieses Feld liefert. Schwenkt die Kamera wie ein
## Spieler (WASD/Zoom), wenn das Feld nicht frei im Bild liegt. ok_fn(cell) prüft „richtig getroffen“.
func point_cell(c: Vector2i, ok_fn: Callable, max_zoom := 4.0) -> bool:
	for attempt in 3:
		var p := scr_cell(c)
		if attempt > 0 or not SAFE.has_point(p) or occluded(p):
			m.focus(Vector2(c.x + 0.5, c.y + 0.5), minf(m.zoom, max_zoom) if attempt == 0 else 3.0)
			await frames(2)
			p = scr_cell(c)
		for off in [Vector2.ZERO, Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1), Vector2(1, 1), Vector2(-1, -1), Vector2(2, 0), Vector2(0, 2), Vector2(-2, 0), Vector2(0, -2)]:
			await move_to((p + off).round())
			if ok_fn.call(m._mouse_cell()):
				return true
	return false


func point_building(b) -> bool:
	if b.kind == Building.Kind.CITY and not m.company_started:
		return await point_cell(b.anchor(), func(cc): return m.hq.city_at(cc) == b, 16.0)
	return await point_cell(b.anchor(), func(cc): return m.cell_to_building.get(cc) == b, 16.0)


func click_building(b) -> bool:
	if not await point_building(b):
		return false
	var p := root.get_mouse_position()
	if OS.get_environment("PLAY_DEBUG") != "":
		print("DBG toast ", m.toast_panel.get_global_rect(), " ", m.toast_panel.mouse_filter, " lbl ", m.toast_label.size, " ", m.toast_label.autowrap_mode)
		print("DBG click ", b.map_id, " p=", p, " cell=", m._mouse_cell(), " hq.mode=", m.hq.mode, " tool=", m.tool, " occ=", occluded(p), " hov=", root.gui_get_hovered_control(), " par=", (root.gui_get_hovered_control().get_parent() if root.gui_get_hovered_control() else null), " rect=", (root.gui_get_hovered_control().get_global_rect() if root.gui_get_hovered_control() else null), " hqp=", m.hq.panel, m.hq.panel.visible)
	await button_ev(p, true)
	await button_ev(p, false)
	await frames(2)
	if OS.get_environment("PLAY_DEBUG") != "":
		print("DBG after sel=", m.selected, " panel=", m.panel.visible, " src=", m.line_src)
	return true


func tool_off() -> void:
	for i in 4:
		if m.tool == m.Tool.NONE and not m.panel.visible:
			return
		await key(KEY_ESCAPE)


func select_tool(t: int) -> void:
	if m.tool == t:
		return
	for e in m.tool_buttons:
		if e[0] == t:
			await click_control(e[1])
	if m.tool != t:              # Rückfall Tastenkürzel (sollte nicht nötig sein)
		await key([KEY_0, KEY_1, KEY_2, KEY_3, KEY_4, KEY_5][t] if t <= 5 else KEY_X)


func fit_two(a: Vector2, b: Vector2) -> void:
	var mid := (a + b) * 0.5
	m.focus(mid, clampf(a.distance_to(b) / 26.0, 2.5, 16.0))


func panel_settle() -> void:
	await pause(settle_s)
	await frames(2)


# ------------------------------------------------------------------ Hilfen

func find_b(token: String):
	var t := token.strip_edges().to_lower()
	if m.by_id.has(t):
		return m.by_id[t]
	for b in m.buildings:
		var dn: String = b.display_name.to_lower()
		if dn == t or dn.replace(" ", "_") == t or dn.replace(" ", "") == t:
			return b
	return null


## U-03 (S7, Mira): Ziel als Gebäude-ID oder Feld „x,y“ (auch außerhalb der Karte, z. B. 600,335). null = unbekannt.
func pt(token: String):
	var t := token.strip_edges()
	if t.contains(","):
		var p := t.split(",")
		if p.size() == 2 and p[0].strip_edges().lstrip("-").is_valid_int() and p[1].strip_edges().lstrip("-").is_valid_int():
			return Vector2i(int(p[0]), int(p[1]))
	var b = find_b(t)
	return b.anchor() if b != null else null


## Treffer-Bedingung für point_cell: Feld außerhalb der Karte = Maus zeigt auf die Ebene jenseits des Rands (-1).
func cell_hit(c: Vector2i) -> Callable:
	if m._in_grid(c):
		return func(cc): return cc == c
	return func(cc): return cc.x < 0


func money(c: int) -> String:
	return m.money_str(c)


func gt() -> String:
	return m.time_str(m.shim.tick_count)


func poll() -> void:
	var t: String = m.toast_label.text
	if t != "" and t != _last_toast:
		toasts.append([gt(), t.replace("\n", " ")])
	_last_toast = t
	for i in m.milestones.size():
		if m.milestones[i]["done"] and not _ms_done.has(i):
			_ms_done.append(i)
			if i > 0:
				toasts.append([gt(), "ZIEL ERREICHT: " + str(m.milestones[i]["text"])])


func texts_of(n: Node, out: Array) -> void:
	var c := n as CanvasItem
	if c != null and not c.visible:
		return
	if n is Label and str(n.text).strip_edges() != "":
		out.append(str(n.text).replace("\n", " / "))
	elif n is Button and str(n.text).strip_edges() != "":
		out.append("[Knopf%s: %s]" % [" gesperrt" if n.disabled else "", str(n.text).replace("\n", " / ")])
	if n is Button:
		var inner: Array = []
		for ch in n.get_children():
			texts_of(ch, inner)
		if not inner.is_empty() and str(n.text).strip_edges() == "":
			out.append("[Knopf%s: %s]" % [" gesperrt" if n.disabled else "", " / ".join(inner)])
		return
	for ch in n.get_children():
		texts_of(ch, out)


# ------------------------------------------------------------------ Befehle (Rückgabe: Fehlertext, "" = ok)

func cmd(line: String) -> String:
	var w := line.split(" ", false)
	var op := w[0].to_lower()
	var n := w.size()
	match op:
		"hover":
			if n < 2: return "hover <id>"
			var b = find_b(w[1])
			if b == null: return "Unbekannt: %s (siehe `list`)" % w[1]
			if not await point_building(b): return "Maus trifft %s nicht" % b.display_name
			await panel_settle()
			cam_note = "auf %s" % b.display_name
			return ""
		"click":
			if n < 2: return "click <id>"
			var b = find_b(w[1])
			if b == null: return "Unbekannt: %s (siehe `list`)" % w[1]
			if not m.company_started and b.kind != Building.Kind.CITY:
				return "Vor der Gründung wählt ein Klick nur Städte (HQ-Platzierung)."
			if not await click_building(b): return "Maus trifft %s nicht" % b.display_name
			await panel_settle()
			cam_note = "auf %s" % b.display_name
			if m.company_started and m.tool == m.Tool.NONE and m.selected != b:
				return "Panel von %s nicht geöffnet" % b.display_name
			return ""
		"found_hq":
			if m.company_started: return "HQ schon gegründet (%s)" % m.hq_city.display_name
			if m.hq.selected == null: return "Keine Stadt gewählt: erst `click <stadt>`"
			if not m.hq.button.is_visible_in_tree() or m.hq.button.disabled: return "Knopf „HQ hier gründen“ nicht bedienbar"
			await click_control(m.hq.button)
			await frames(2)
			cam_note = "Startansicht nach Gründung (vom Spiel gesetzt)"
			return "" if m.company_started else "Gründung fehlgeschlagen"
		"buy_licence":
			if n < 2: return "buy_licence <industrie_id>"
			var b = find_b(w[1])
			if b == null: return "Unbekannt: %s" % w[1]
			if not m.company_started: return "Erst HQ gründen"
			await tool_off()
			if not await click_building(b): return "Maus trifft %s nicht" % b.display_name
			await panel_settle()
			cam_note = "auf %s" % b.display_name
			if m.selected != b: return "Panel von %s nicht geöffnet" % b.display_name
			var q: Dictionary = m.licence_quote(b)
			if not q.get("ok", false): return "%s braucht keine Lizenz (nimmt nur an / Kulisse)" % b.display_name
			if q["aktiv"]: return "%s ist schon lizenziert" % b.display_name
			if m.panel_button.disabled:
				return "Knopf gesperrt: %s" % (m.panel_reason.text if m.panel_reason.visible else m.panel_button.text)
			await click_control(m.panel_button)
			await frames(2)
			return "" if m.eco.licence_valid(b.site) else "Lizenzkauf ohne Wirkung"
		"road", "rail", "demolish":
			# U-03: Ziele als ID oder Feld „x,y“; demolish = Abriss-Werkzeug über die Fläche a–b ziehen.
			if n < 3: return "%s <id|x,y> <id|x,y>" % op
			var a = pt(w[1])
			var b = pt(w[2])
			if a == null or b == null: return "Unbekannt: %s / %s" % [w[1], w[2]]
			if not m.company_started: return "Erst HQ gründen"
			var rail := op == "rail"
			var net: Dictionary = m.rails if rail else m.roads
			var before: int = net.size() + (m.rails.size() if op == "demolish" else 0)
			var cash0: int = m.eco.cash_cent
			await tool_off()
			await select_tool(m.Tool.DEMOLISH if op == "demolish" else (m.Tool.RAIL if rail else m.Tool.ROAD))
			# Drücken auf A, Kamera mitschwenken (wie WASD bei gehaltener Maustaste), auf B loslassen
			if not await point_cell(a, cell_hit(a)):
				return "Maus trifft Startfeld %s nicht" % w[1]
			await button_ev(root.get_mouse_position(), true)
			await frames(2)
			if not m.dragging: return "Ziehen startet nicht (Werkzeug %d)" % m.tool
			var ok_b := await point_cell(b, cell_hit(b))
			await frames(2)
			await button_ev(root.get_mouse_position(), false)
			await frames(2)
			await tool_off()
			fit_two(Vector2(a), Vector2(b))
			cam_note = "%s %s – %s" % ["Abriss" if op == "demolish" else "Strecke", w[1], w[2]]
			if not ok_b: return "Maus trifft Zielfeld %s nicht" % w[2]
			var after: int = net.size() + (m.rails.size() if op == "demolish" else 0)
			if after == before:
				if op == "demolish": return "nichts abgerissen"
				return "nichts gebaut" if m.eco.cash_cent == cash0 else ""
			return ""
		"warehouse":
			if n < 3: return "warehouse <x> <y>"
			if not m.company_started: return "Erst HQ gründen"
			var c := Vector2i(int(w[1]), int(w[2]))
			if not m._in_grid(c): return "Feld %d,%d liegt außerhalb der Karte (0–%d)" % [c.x, c.y, m.GRID - 1]
			var k0: int = m.warehouse_count
			await tool_off()
			await select_tool(m.Tool.WAREHOUSE)
			if not await point_cell(c, func(cc): return cc == c): return "Maus trifft Feld %s nicht" % str(c)
			var p := root.get_mouse_position()
			await button_ev(p, true)
			await button_ev(p, false)
			await frames(2)
			await tool_off()
			cam_note = "auf Feld %d,%d" % [c.x, c.y]
			return "" if m.warehouse_count > k0 else "kein Lager gebaut"
		"truck_line", "train_line":
			if n < 3: return "%s <id_a> <id_b>" % op
			var a = find_b(w[1])
			var b = find_b(w[2])
			if a == null or b == null: return "Unbekannt: %s / %s" % [w[1], w[2]]
			if not m.company_started: return "Erst HQ gründen"
			var n0: int = m.n_assigned
			await tool_off()
			await select_tool(m.Tool.TRAIN_LINE if op == "train_line" else m.Tool.TRUCK_LINE)
			if not await click_building(a): return "Maus trifft %s nicht" % a.display_name
			if m.line_src != a:
				await tool_off()
				return "Quelle %s nicht angenommen" % a.display_name
			if not await click_building(b): return "Maus trifft %s nicht" % b.display_name
			await tool_off()
			fit_two(Vector2(a.anchor()), Vector2(b.anchor()))
			cam_note = "Linie %s – %s" % [a.display_name, b.display_name]
			return "" if m.n_assigned > n0 else "keine Linie angelegt"
		"remove_line":
			if n < 3: return "remove_line <id_a> <id_b>"
			var a = find_b(w[1])
			var b = find_b(w[2])
			if a == null or b == null: return "Unbekannt: %s / %s" % [w[1], w[2]]
			for key_ in m.line_order:
				var v = m.line_groups[key_][0]
				if v.src == a and v.dst == b:
					if not m.line_rows.has(key_): m._refresh_lines()
					var del: Control = m.line_rows[key_]["del"]
					if not del.is_visible_in_tree(): return "Papierkorb der Linie nicht sichtbar (nur 8 Linien in der Liste)"
					await click_control(del)
					return "" if not m.line_groups.has(key_) else "Linie nicht aufgelöst"
			return "keine Linie %s → %s" % [a.display_name, b.display_name]
		"credit":
			if n < 2 or not (w[1] in ["+", "-"]): return "credit + | credit -"
			var l0: int = m.credit.loan_cent
			var bt: Button = m.credit_buttons[0 if w[1] == "+" else 1]
			if bt.disabled: return "Knopf Kredit %s gesperrt" % w[1]
			await click_control(bt)
			return "" if m.credit.loan_cent != l0 else "Kredit unverändert"
		"speed":
			if n < 2: return "speed 0|1|2|4|8"
			var s := int(w[1])
			for e in m.speed_buttons:
				if e[0] == s:
					await click_control(e[1])
					return "" if m.speed == s else "Tempo ist %d (gewünscht %d)" % [m.speed, s]
			return "Tempo %s gibt es nicht" % w[1]
		"wait":
			if n < 2: return "wait <minuten>"
			if not m.company_started: return "Zeit läuft erst nach der Gründung"
			if m.bankrupt: return "Bankrott – Zeit steht"
			if m.speed == 0: return "Pause (Tempo 0): keine Spielzeit vergangen – erst `speed 1`"
			if m.hq.time_frozen(): return "HQ-Umsetzen-Modus: Zeit steht – `esc` oder `move_hq <stadt>`"
			# T-02/T-08: wie _physics_process des Spiels: je Schritt `speed` Ticks (Tempo-Faktor), danach die Frame-Regeln
			# (HQ-Frist, Meldungen) – dadurch exakt auf den Tick statt in 15-s-Schritten.
			var ticks := int(round(float(w[1]) * m.month_ticks))
			var step: int = maxi(1, m.speed)
			var done := 0
			var n_steps := 0
			while done < ticks and not m.bankrupt:
				var k := mini(step, ticks - done)
				m.run_ticks(k)
				done += k
				n_steps += 1
				m.hq.refresh_rule()
				poll()
				if n_steps % 300 == 0:
					await process_frame
			real_equiv_s += float(done) * m.tick_ms / 1000.0 / float(step)
			return "BANKROTT nach %s" % gt() if m.bankrupt else ""
		"hq_move", "move_hq":
			# T-01: HQ-Umsetzen mit echter Maus. hq_move [ring|toast] startet nur den Modus,
			# move_hq <stadt> [ring|toast] startet (falls nötig), wählt die Stadt und klickt „HQ hierher umsetzen“.
			if not m.company_started: return "Erst HQ gründen"
			var via := "ring"
			var city = null
			if op == "move_hq":
				if n < 2: return "move_hq <stadt> [ring|toast]"
				city = find_b(w[1])
				if city == null or city.kind != Building.Kind.CITY: return "Keine Stadt: %s (siehe `list`)" % w[1]
				if n > 2: via = w[2]
			elif n > 1:
				via = w[1]
			if m.hq.mode != m.hq.Mode.MOVING:
				if not m.hq.can_move():
					return "Umsetzen nicht möglich: %s" % ("HQ ist fest (Frist 2:00 oder erste Lizenz)" if m.hq.fixed or m.hq._licence_bought() else "Frist abgelaufen")
				await tool_off()
				if via == "toast":
					if not (m.hq._move_toast != "" and m.toast_label.text == m.hq._move_toast):
						return "Umsetzen-Toast nicht mehr sichtbar (läuft wenige Sekunden Echtzeit) – `ring` nehmen"
					m.toast_time = maxf(m.toast_time, 2.0)
					await frames(2)
					await click_control(m.toast_panel)
				else:
					var hc: Vector2i = m.hq.hq_cell(m.hq_city)
					if not await point_cell(hc, func(cc): return m.hq._hits_ring_or_hq(cc)): return "Maus trifft den HQ-Ring nicht"
					var rp := root.get_mouse_position()
					await button_ev(rp, true)
					await button_ev(rp, false)
					await frames(2)
				if m.hq.mode != m.hq.Mode.MOVING: return "Klick auf %s startete das Umsetzen nicht" % via
				await panel_settle()
				cam_note = "Umsetzen-Übersicht (vom Spiel gesetzt)"
			if op == "hq_move": return ""
			if city == m.hq_city: return "%s ist schon das HQ" % city.display_name
			if not await point_cell(city.anchor(), func(cc): return m.hq.city_at(cc) == city, 16.0): return "Maus trifft %s nicht" % city.display_name
			var p := root.get_mouse_position()
			await button_ev(p, true)
			await button_ev(p, false)
			await frames(2)
			await panel_settle()
			if m.hq.selected != city: return "Stadt %s nicht gewählt" % city.display_name
			if not m.hq.button.is_visible_in_tree() or m.hq.button.disabled: return "Knopf „HQ hierher umsetzen“ nicht bedienbar"
			await click_control(m.hq.button)
			await frames(2)
			cam_note = "Ansicht nach Umsetzen (vom Spiel gesetzt)"
			return "" if (m.hq_city == city and m.hq.mode == m.hq.Mode.FOUNDED) else "Umsetzen nach %s fehlgeschlagen" % city.display_name
		"drag_start":
			# T-03: Zwischenzustand – Werkzeug wählen, Maustaste auf A drücken und HALTEN (danach drag_to/drag_end/esc).
			if n < 3 or not (w[1] in ["road", "rail"]): return "drag_start road|rail <id_a>"
			var a = find_b(w[2])
			if a == null: return "Unbekannt: %s" % w[2]
			if not m.company_started: return "Erst HQ gründen"
			await tool_off()
			await select_tool(m.Tool.RAIL if w[1] == "rail" else m.Tool.ROAD)
			if not await point_cell(a.anchor(), func(cc): return cc == a.anchor()): return "Maus trifft Startfeld %s nicht" % a.display_name
			await button_ev(root.get_mouse_position(), true)
			await frames(2)
			cam_note = "Ziehen ab %s" % a.display_name
			return "" if m.dragging else "Ziehen startet nicht"
		"drag_to":
			if n < 2: return "drag_to <id|x,y>"
			var b = pt(w[1])
			if b == null: return "Unbekannt: %s" % w[1]
			if not m.dragging: return "Kein Ziehen aktiv (erst `drag_start`)"
			if not await point_cell(b, cell_hit(b)): return "Maus trifft Zielfeld %s nicht" % w[1]
			await frames(2)
			cam_note = "Ziehen bis %s" % w[1]
			return ""
		"drag_end":
			if not m.dragging: return "Kein Ziehen aktiv"
			await button_ev(root.get_mouse_position(), false)
			await frames(2)
			return ""
		"dblclick":
			if n < 2: return "dblclick <id>"
			var b = find_b(w[1])
			if b == null: return "Unbekannt: %s" % w[1]
			if not await point_building(b): return "Maus trifft %s nicht" % b.display_name
			var p := root.get_mouse_position()
			for i in 2:
				var e := InputEventMouseButton.new()
				e.button_index = MOUSE_BUTTON_LEFT
				e.pressed = true
				e.double_click = i == 1
				e.position = p
				e.global_position = p
				root.push_input(e, true)
				await process_frame
				e = e.duplicate()
				e.pressed = false
				e.double_click = false
				root.push_input(e, true)
				await process_frame
			await frames(2)
			await panel_settle()
			cam_note = "auf %s" % b.display_name
			return ""
		"camera":
			# camera <id> [zoom]  oder  camera <x> <y> [zoom]  (Feldkoordinaten). Zoom: GRÖSSER = WEITER WEG (0,4–26).
			if n < 2: return "camera <id> [zoom] | camera <x> <y> [zoom]"
			if w[1].is_valid_int() and n > 2 and w[2].is_valid_int():
				var z2 := float(w[3]) if n > 3 else 3.2
				m.focus(Vector2(float(w[1]) + 0.5, float(w[2]) + 0.5), clampf(z2, 0.4, 26.0))
				cam_note = "camera %s,%s Zoom %.1f" % [w[1], w[2], z2]
				return ""
			var b = find_b(w[1])
			if b == null: return "Unbekannt: %s" % w[1]
			var z := float(w[2]) if n > 2 else 3.2
			m.focus(Vector2(b.center().x, b.center().z), clampf(z, 0.4, 26.0))
			cam_note = "camera %s Zoom %.1f" % [b.display_name, z]
			return ""
		"list":
			list_wanted = true
			return ""
		"esc":
			await key(KEY_ESCAPE)
			await panel_settle()
			return ""
	return "Unbekannter Befehl: %s (siehe tools/play_help.md)" % op


# ------------------------------------------------------------------ Ausgabe

func state_md(cmds: Array, last_err: String, run_s: float) -> String:
	var L: Array = []
	var cpm: int = m.running_cost_per_period * m.month_ticks / m.periode_ticks
	var now: int = m.shim.tick_count
	var inc := 0
	var trip := 0
	for d in m.deliveries:
		if d["tick"] > now - m.month_ticks:
			inc += d["income"]
			trip += d["trip_cost"]
	L.append("# Spielstand nach %d Befehlen" % cmds.size())
	L.append("")
	L.append("Letzter Befehl: `%s`" % (cmds[-1] if cmds.size() > 0 else "-"))
	L.append("Fehler des letzten Befehls: %s" % (last_err if last_err != "" else "keiner"))
	L.append("")
	L.append("| Wert | Stand |")
	L.append("|---|---|")
	L.append("| Spielzeit | %s (Tempo %d×%s) |" % [gt(), m.speed, ", Pause" if m.speed == 0 else ""])
	L.append("| HQ | %s |" % (m.hq_city.display_name if m.hq_city else "noch nicht gegründet"))
	L.append("| Kasse | %s |" % money(m.eco.cash_cent if m.company_started else int(m.eco.slice["hq"]["start_capital_cent"])))
	L.append("| Kredit | %s offen (Rahmen %s, Zins %s/min) |" % [money(m.credit.loan_cent), money(m.credit.limit_cent), money(m.credit.interest_per_period())])
	L.append("| Einnahmen letzte Spielminute | %s (gesamt %s) |" % [money(inc), money(m.eco.revenue_total)])
	L.append("| Fahrtkosten letzte Spielminute | %s |" % money(trip))
	L.append("| Laufende Kosten | %s/min (Unterhalt Fahrzeuge, Lager, Gleise) |" % money(cpm))
	L.append("| Ausgaben gesamt | %s |" % money(m.expenses_total))
	L.append("| Fahrzeuge | %d (davon ohne Linie %d, Startpaket-Lkw gratis übrig %d) |" % [m.fleet_size(), m.fleet_size() - m.n_assigned, m.free_trucks_left])
	L.append("| Lieferungen | %d (mit Gewinn %d) |" % [m.deliveries.size(), m.deliveries_profit])
	L.append("| Bankrott | %s |" % ("JA" if m.bankrupt else "nein"))
	L.append("")
	L.append("## Linien")
	if m.line_order.is_empty():
		L.append("keine")
	for key_ in m.line_order:
		var list: Array = m.line_groups[key_]
		var v = list[0]
		var deliv := 0
		var warn := false
		var st := {}
		for x in list:
			deliv += x.deliveries
			warn = warn or x.no_licence
			var sn: String = ["ohne Auftrag", "lädt", "fährt zum Ziel", "entlädt", "fährt zur Quelle"][clampi(int(x.state), 0, 4)]
			st[sn] = st.get(sn, 0) + 1
		var pr: float = m._line_profit(list)
		var fz: Array = []
		for k in st:
			fz.append("%d %s" % [st[k], k])
		L.append("- %s: %d× · %d Felder · %d Lieferungen · Gewinn %+d $/min · Status: %s · Fahrzeuge: %s" % [m.line_title(key_), list.size(), v.distance, deliv,
			int(pr), "KEINE LIZENZ an der Quelle!" if warn else ("Gewinn" if pr > 0 else ("Verlust" if pr < 0 else "noch ohne Ertrag")), ", ".join(fz)])
	L.append("")
	L.append("## Ziele")
	if m.milestones.is_empty():
		L.append("(erscheinen nach der Gründung)")
	for e in m.milestones:
		L.append("- [%s] %s" % ["x" if e["done"] else " ", e["text"]])
	if m.next_step_label and m.next_step_label.is_visible_in_tree() and m.next_step_label.text != "":
		L.append("")
		L.append("Nächster Schritt (Spiel): %s" % m.next_step_label.text.replace("\n", " "))
	L.append("")
	L.append("## Offenes Panel")
	var shown := false
	for pn in [m.hq.panel, m.panel, m.bankrupt_panel]:
		if pn != null and pn.is_visible_in_tree():
			var t: Array = []
			texts_of(pn, t)
			L.append("- " + " | ".join(t))
			shown = true
	if not shown:
		L.append("keins")
	L.append("")
	L.append("Hinweisleiste: %s" % m.hint_label.text.replace("\n", " "))
	L.append("Werkzeug: %s" % (["Auswahl", "Straße", "Gleis", "Lager", "Lkw-Linie", "Zug-Linie", "Abriss"][m.tool] if m.tool < 7 else str(m.tool)))
	L.append("")
	L.append("## Letzte Meldungen (Toasts + erreichte Ziele, max. 12, neueste unten)")
	if toasts.is_empty():
		L.append("keine")
	for e in toasts.slice(maxi(0, toasts.size() - 12)):
		L.append("- %s %s" % [e[0], e[1]])
	if list_wanted:
		L.append("")
		L.append("## Karte (list)")
		L.append("| ID | Name | Typ | Feld x,y | Lizenz |")
		L.append("|---|---|---|---|---|")
		for b in m.buildings:
			var typ: String = b.typ if b.typ != "" else "stadt"
			var lic := "–"
			if b.kind == Building.Kind.CITY:
				typ = "Stadt (%s, %d Einw.)%s" % [m.STAGE_NAMES.get(b.city_stage, b.city_stage), b.city_pop, " HQ" if b == m.hq_city else ""]
			elif b.kind == Building.Kind.INERT:
				typ += " (Kulisse)"
			elif b.site >= 0 and b.is_industry():
				var q: Dictionary = m.licence_quote(b)
				if not m.company_started:
					lic = "erst nach Gründung"          # T-07: vor der Gründung gibt es kein Angebot, nicht „nicht nötig“
				elif not q.get("ok", false):
					lic = "nicht nötig (Abnehmer)"
				elif q["aktiv"]:
					lic = "aktiv"
				else:
					lic = "keine (%s)" % ("gratis" if q["gratis"] else money(q["kosten_cent"]))
				typ += " (%s)" % {Building.Kind.PRODUCER: "Rohstoff", Building.Kind.PROCESSOR: "Verarbeiter", Building.Kind.SINK: "Abnehmer"}.get(b.kind, "")
			L.append("| %s | %s | %s | %d,%d | %s |" % [b.map_id, b.display_name, typ, b.anchor().x, b.anchor().y, lic])
	L.append("")
	L.append("Tempo-Faktor: `wait` spielt je Schritt `speed` Ticks wie das Spiel; die gewarteten Spielminuten entsprächen bei dem jeweils gewählten Tempo %.0f s Echtzeit." % real_equiv_s)
	L.append("Kamera: %s · Laufzeit %.1f s%s" % [cam_note if cam_note != "" else "Startansicht", run_s, " · KEIN BILD (--no-shot)" if no_shot else ""])
	if aborted != "":
		L.append("")
		L.append("**ABBRUCH: %s**" % aborted)
	return "\n".join(L) + "\n"


func _run() -> void:
	var t0 := Time.get_ticks_msec()
	DirAccess.make_dir_recursive_absolute(out_dir)
	var cmds: Array = []
	var f := FileAccess.open(out_dir.path_join("commands.txt"), FileAccess.READ)
	if f != null:
		for raw in f.get_as_text().split("\n"):
			var s := raw.strip_edges()
			if s != "" and not s.begins_with("#"):
				cmds.append(s)
	MainScript.core_override = "soa"
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	await frames(3)
	print("START %d ms" % (Time.get_ticks_msec() - t0))
	m.set_physics_process(false)      # Sim nur über `wait` -> deterministisch
	root.disable_3d = OS.get_environment("PLAY_RENDER") == ""     # Tempo: Software-GL zeichnet die 3D-Welt erst fürs Schlussbild (UI läuft echt)
	var last_err := ""
	var errs: Array = []
	var played := 0
	for i in cmds.size():
		if budget_s > 0.0 and (Time.get_ticks_msec() - t0) / 1000.0 > budget_s:
			aborted = "Zeitbudget %.0f s erreicht nach %d von %d Befehlen (Rest nicht gespielt; Lauf kürzen oder `--no-shot`/`--fast`/`--budget=0`)" % [budget_s, i, cmds.size()]
			print("ABBRUCH ", aborted)
			break
		played += 1
		poll()
		var tc := Time.get_ticks_msec()
		var mode0: int = m.hq.mode
		var nt := toasts.size()
		last_err = await cmd(cmds[i])
		poll()
		if last_err != "" and toasts.size() > nt and not str(toasts[-1][1]).begins_with("ZIEL"):
			last_err += " – Spiel meldet: „%s“" % toasts[-1][1]
		if m.hq.mode == m.hq.Mode.MOVING:
			last_err = ("%s · " % last_err if last_err != "" else "") + ("Klick traf den HQ-Ring: " if mode0 != m.hq.Mode.MOVING else "") + "HQ-Umsetzen-Modus aktiv (Zeit steht, Werkzeuge aus) – `esc` bricht ab."
		poll()
		print("CMD %d `%s` %d ms" % [i + 1, cmds[i], Time.get_ticks_msec() - tc])
		if last_err != "":
			errs.append("Zeile %d `%s`: %s" % [i + 1, cmds[i], last_err])
			print("FEHLER ", errs[-1])
	if not no_shot:
		root.disable_3d = false
		# Bild: Fahrzeug-Puffer ohne Physik-Ticks füllen (RENDER_SPLIT braucht begin -> step(_process) -> finish)
		for i in 3:
			m._render_vehicles()
			await frames(2)
		if OS.get_environment("PLAY_DEBUG") != "" and m.mm_truck.multimesh.instance_count > 0:
			print("DBG truck ", m.mm_truck.multimesh.get_instance_transform(0), " states ", m.vehicles.map(func(v): return v.state))
		m.toast_time = maxf(m.toast_time, 2.0)
		await frames(6)
		await pause(0.5)
		poll()
		var img := root.get_viewport().get_texture().get_image()
		img.save_png(out_dir.path_join("shot.png"))
	else:
		poll()
		DirAccess.remove_absolute(out_dir.path_join("shot.png"))     # kein altes Bild stehen lassen
	var run_s := (Time.get_ticks_msec() - t0) / 1000.0
	var md := state_md(cmds.slice(0, played), last_err, run_s)
	if errs.size() > 0:
		md += "\n## Fehler in früheren Zeilen\n" + "\n".join(errs.map(func(e): return "- " + e)) + "\n"
	var sf := FileAccess.open(out_dir.path_join("state.md"), FileAccess.WRITE)
	sf.store_string(md)
	sf.close()
	var lp := out_dir.path_join("log.md")
	var lf: FileAccess
	if FileAccess.file_exists(lp):
		lf = FileAccess.open(lp, FileAccess.READ_WRITE)
		lf.seek_end()
	else:
		lf = FileAccess.open(lp, FileAccess.WRITE)
		lf.store_line("| # | letzter Befehl | Spielzeit | Kasse | Ziele | Fehler |")
		lf.store_line("|---|---|---|---|---|---|")
	var ms_done := 0
	for e in m.milestones:
		ms_done += 1 if e["done"] else 0
	lf.store_line("| %d | `%s` | %s | %s | %d/%d | %s |" % [played, cmds[played - 1] if played > 0 else "-", gt(),
		money(m.eco.cash_cent), ms_done, m.milestones.size(), ("ABBRUCH Zeitbudget; " if aborted != "" else "") + (last_err if last_err != "" else "–")])
	lf.close()
	print("PLAY_OK %d Befehle, %s, %.1f s" % [played, gt(), run_s])
	quit(3 if aborted != "" else 0)
