extends Node
## F-20 (D22) HQ-Platzierung: Spielstart direkt auf der Karte, Zeit pausiert. Hover über eine Stadt zeigt die Vorschau
## im rechten Kontextpanel-Slot (380 px, ≤ 6 Zeilen aus data/hq_vorschau.json), den HQ-Radiusring und die Luftlinie zu
## den Industrien im Ring. Klick wählt die Stadt (Ghost am Stadtrand), „HQ hier gründen“ startet die Firma mit
## economy.start_company_at (ein Startkapital, Lkw-Paket aus JSON). Kein Dialog, kein Archetyp.
## Umsetzen (L-12 §1.2, Jonas D22-2): kostenlos, bis die erste Lizenz erworben ist (Gratislizenz zählt) oder 2 min
## Spielzeit seit Gründung vergangen sind. Ein Klick auf Toast oder Ring; im Umsetzen-Modus stehen Uhr und Zähler.
## main.gd ruft nur Hooks: handle_input, time_frozen, hint, place (Testeinstieg main.place_hq).

const Building := preload("res://building.gd")
const Kit := preload("res://ui/ui_kit.gd")
const UiFx := preload("res://ui/ui_fx.gd")
const TB := preload("res://ui/theme/theme_builder.gd")

const VORSCHAU_PATH := "res://data/hq_vorschau.json"   # T-14b: {"quelle", "staedte": {id: {radius, ketten[], groesse, lizenzfaktor, gelaende, hinweis}}}
const RING_SEC := 0.35          # Ring-Animation ≤ 0,4 s (F-20), bei Reduced Motion sofort
const MOVE_WINDOW_MS := 120000  # 2 min Spielzeit (D22-2)
const MAX_ROWS := 6
const PICK_FELDER := 3          # Hover/Klick trifft eine Stadt bis 3 Felder außerhalb ihres Rands
const RING_HIT_FELDER := 2.5    # Klick auf den HQ-Ring (±) startet das Umsetzen
const OVERVIEW_CELL := Vector2(285, 335)   # Übersicht über alle Städte (Spielstart, Umsetzen)
const OVERVIEW_ZOOM := 14.5
const RADMAP := {"dorf": "village", "kleinstadt": "town", "stadt": "city", "metropole": "metro"}

enum Mode { PLACING, FOUNDED, MOVING }

var m: Node                      # main.gd
var mode: int = Mode.PLACING
var vorschau: Dictionary = {}    # stadt_id -> Vorschau-Eintrag
var vorschau_quelle := ""
var hovered = null               # Stadt (Building) unter der Maus
var selected = null              # angeklickte Stadt (Ghost)
var shown = null                 # Stadt, die das Panel gerade zeigt
var found_tick := 0
var fixed := false
var reduced_motion := false
var last_hover_ms := 0.0         # Messwert: Zeit vom Hover-Wechsel bis Panel gefüllt (ms)
var _speed_before := 1
var _cam_before: Array = []     # [Feld, Zoom] vor dem Umsetzen-Modus (B-10)
var _move_toast := ""            # Text des Toasts, dessen Klick das Umsetzen startet

var panel: PanelContainer
var title_label: Label
var status_shape: Control
var status_label: Label
var rows: Array = []             # {row, icon, val}
var button: Button
var reason_label: Label
var hover_ring: MeshInstance3D
var hq_ring: MeshInstance3D
var ring_label: Label3D
var ghost: Node3D
var hq_building: Node3D
var dist_labels: Array = []
var _ring_tw: Tween


func setup(main: Node) -> void:
	m = main
	reduced_motion = OS.get_cmdline_user_args().has("--reduced-motion") or bool(ProjectSettings.get_setting("mega_tycoon/reduced_motion", false))
	_load_vorschau()
	_build_panel()
	_build_world()
	m.toast_panel.gui_input.connect(_on_toast_input)
	# Spielstart auf der Karte: Übersicht über alle Städte, rechts Platz für das Panel
	m.focus(OVERVIEW_CELL, OVERVIEW_ZOOM)


func _load_vorschau() -> void:
	var f := FileAccess.open(VORSCHAU_PATH, FileAccess.READ)
	if f == null:
		push_warning("hq_vorschau.json fehlt")
		return
	var d = JSON.parse_string(f.get_as_text())
	if d is Dictionary:
		vorschau_quelle = str(d.get("quelle", ""))
		vorschau = d.get("staedte", {})


## Fehlende Vorschau-Einträge (für main._check_ids / Tests): jede Karten-Stadt braucht eine Karte (8 von 8).
func missing_preview_ids() -> Array:
	var out: Array = []
	for st in m.map_data["staedte"]:
		if not vorschau.has(st["id"]):
			out.append("Vorschau %s fehlt in hq_vorschau.json" % st["id"])
	return out


# ---------------------------------------------------------------- Hooks für main.gd

## Uhr und 2-min-Zähler stehen im Umsetzen-Modus (Lena §1.4, von Jonas bestätigt).
func time_frozen() -> bool:
	return mode == Mode.MOVING


## Hinweisleiste: leer = main entscheidet.
func hint() -> String:
	match mode:
		Mode.PLACING:
			if selected != null:
				return "%s gewählt: rechts „HQ hier gründen“. Andere Stadt anklicken wechselt · Esc hebt die Wahl auf." % selected.display_name
			return "Wo gründest du? Fahre über eine Stadt für die Vorschau, Klick wählt sie. Die Zeit läuft erst nach der Gründung."
		Mode.MOVING:
			return "Neuen Standort wählen. Esc: HQ bleibt in %s." % m.hq_city.display_name
	return ""


## Eingaben vor main: true = verbraucht. Mausrad und Tastatur (außer Esc) bleiben bei der Karte.
func handle_input(event: InputEvent) -> bool:
	if m.bankrupt:
		return false
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.keycode == KEY_ESCAPE:
		return cancel()
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed:
		return false
	if mb.button_index == MOUSE_BUTTON_RIGHT and mode != Mode.FOUNDED:
		return cancel()
	if mb.button_index != MOUSE_BUTTON_LEFT:
		return false
	var c := _cell()
	if mode != Mode.FOUNDED:
		var city = city_at(c)
		if city != null:
			select(city)
		return true
	if can_move() and _hits_ring_or_hq(c):
		return start_move()
	return false


## Testeinstieg und Kurzweg: Stadt wählen und gründen (bzw. im Umsetzen-Modus umsetzen).
func place(city_id: String) -> bool:
	var city = m.by_id.get(city_id, null)
	if city == null or city.kind != Building.Kind.CITY:
		return false
	select(city)
	return confirm()


# ---------------------------------------------------------------- Zustände

func select(city) -> void:
	if mode == Mode.FOUNDED or city == null:
		return
	selected = city
	_show_ghost(city)
	_show(city)


## Esc / Rechtsklick: im Umsetzen-Modus Abbruch, sonst Wahl aufheben.
func cancel() -> bool:
	if mode == Mode.MOVING:
		mode = Mode.FOUNDED
		selected = null
		ghost.visible = false
		_hide_preview()
		if _cam_before.size() == 2:
			m.focus(_cam_before[0], _cam_before[1])
		m.set_speed(_speed_before)
		_set_move_toast("Umsetzen abgebrochen. HQ bleibt in %s." % m.hq_city.display_name, 5.0, false)
		return true
	if mode == Mode.PLACING and selected != null:
		selected = null
		ghost.visible = false
		_show(hovered)
		return true
	return false


## Primärknopf „HQ hier gründen“ / „HQ hierher umsetzen“.
func confirm() -> bool:
	if selected == null or mode == Mode.FOUNDED:
		return false
	if mode == Mode.PLACING:
		return _found(selected)
	return _move(selected)


func _found(city) -> bool:
	if not m.eco.start_company_at(city.node_id, city.city_stage):
		m._toast("Firma konnte nicht gegründet werden (JSON).")
		return false
	m.hq_city = city
	m.company_started = true
	m.free_trucks_left = int(m.eco.slice["fahrzeug_ref"]["startpaket_lkw_anzahl"]) if m.start_trucks_free else 0   # S6: 2 für alle
	mode = Mode.FOUNDED
	found_tick = m.shim.tick_count
	fixed = false
	selected = null
	_hide_preview()
	_set_hq(city)
	m.ms_panel.visible = true
	if m.ms_panel.is_inside_tree():
		UiFx.slide_in(m.ms_panel, Vector2(-40, 0))
	m._refresh_tool_buttons()
	var t := start_targets(city.map_id)
	m._init_milestones(t)
	_focus_start(city, t)
	m.set_speed(1)
	_set_move_toast("HQ in %s gegründet. Umsetzen kostenlos bis zur ersten Lizenz, höchstens noch %s min." % [city.display_name, _mss(_left_ms())], 8.0, true)
	return true


func _move(city) -> bool:
	if city == m.hq_city:
		return cancel()
	if not m.eco.move_hq_to(city.node_id, city.city_stage):
		return false
	m.hq_city = city
	mode = Mode.FOUNDED
	selected = null
	_hide_preview()
	_set_hq(city)
	var t := start_targets(city.map_id)
	m._init_milestones(t)
	m._check_milestones()
	_focus_start(city, t)
	m.set_speed(_speed_before)
	_set_move_toast("HQ nach %s umgesetzt. Noch %s Umsetzen frei." % [city.display_name, _mss(_left_ms())], 6.0, true)
	return true


## Umsetzen-Modus (Klick auf Toast oder Ring).
func start_move() -> bool:
	if not can_move():
		return false
	mode = Mode.MOVING
	_speed_before = maxi(m.speed, 1)
	m.set_speed(0)
	m._set_tool(m.Tool.NONE)
	m.close_panel()
	selected = null
	hovered = null
	_show(null)
	_cam_before = [Vector2(m.rig.position.x, m.rig.position.z), m.zoom]
	m.focus(OVERVIEW_CELL, OVERVIEW_ZOOM)    # S6 B-10: alle Städte im Bild; Abbruch stellt die Ansicht wieder her
	return true


## Kamera nach Gründung/Umsetzen: Kette im Radius = Mitte HQ–Quelle; Wagnis (Quelle weit weg) = auf das HQ (S6 B-3).
func _focus_start(city, t: Dictionary) -> void:
	var c: Vector3 = city.center()
	if not is_wagnis(city.map_id):
		var src = m.by_id.get(t["src"], city)
		c = (city.center() + src.center()) * 0.5
	m.focus(Vector2(c.x, c.z), 3.2)


func can_move() -> bool:
	return mode != Mode.PLACING and not fixed and not _licence_bought() and _left_ms() > 0


func _licence_bought() -> bool:
	return m.eco.free_licences_left < m.eco.free_licences_start or m.eco.licence_paid_total > 0


func _left_ms() -> int:
	if mode == Mode.PLACING:
		return MOVE_WINDOW_MS
	return maxi(0, MOVE_WINDOW_MS - (m.shim.tick_count - found_tick) * m.tick_ms)


## Regel prüfen (jedes Frame und von Tests): erste Lizenz oder Ablauf macht das HQ fest.
func refresh_rule() -> void:
	if mode != Mode.FOUNDED or fixed:
		return
	if _licence_bought():
		fixed = true
		_set_move_toast("Erste Lizenz erworben. HQ in %s ist jetzt fest." % m.hq_city.display_name, 5.0, false)
	elif _left_ms() <= 0:
		fixed = true
		_set_move_toast("HQ in %s ist jetzt fest." % m.hq_city.display_name, 5.0, false)


func _set_move_toast(text: String, sec: float, clickable: bool) -> void:
	m._toast(text, sec)
	_move_toast = Kit.txt(text) if clickable else ""


func _on_toast_input(ev: InputEvent) -> void:
	var mb := ev as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and _move_toast != "" and m.toast_label.text == _move_toast:
		start_move()


# ---------------------------------------------------------------- Meilensteine aus der Startkette (statt Archetyp)

## Index 1 der Liste bleibt „Lizenz kaufen“ (M1b, liest U-02b „Skillpunkt gespart“).
## Ziele für die Meilensteinliste: Quelle = nächster Rohstoff einer Kette (bevorzugt im HQ-Radius laut hq_optionen,
## dort zuerst mit Endabnehmer als Ziel),
## Verarbeiter = Ziel dieser Strecke, M3 = erste Verarbeiter-Strecke der Startkette (hq_optionen.startkette, sonst die
## Kette der Quelle). Gilt für alle 8 Städte; Wagnis-Standorte (S6 B-3): nächster lizenzierbarer Rohstoff, ohne Endabnehmer-Vorrang.
func start_targets(city_id: String) -> Dictionary:
	var city = m.by_id[city_id]
	var opt: Dictionary = {}
	for h in m.map_data["hq_optionen"]:
		if h["stadt"] == city_id:
			opt = h
	var in_radius: Array = opt.get("industrien_im_radius", [])
	var wagnis := is_wagnis(city_id)    # S6 B-3: Wagnis = nächster lizenzierbarer Rohstoff, kein Endabnehmer-Vorrang
	var best := {}
	var best_score := INF
	for ch in m.map_data["ketten"]:
		for s in ch["strecken"]:
			var a = m.by_id.get(s["von"], null)
			var b = m.by_id.get(s["nach"], null)
			if a == null or b == null or a.kind != Building.Kind.PRODUCER or not b.is_industry():
				continue
			if wagnis:
				var dw: float = m.eco.luftlinie_felder(a.site, city.site) + m.eco.luftlinie_felder(a.site, b.site) * 0.001
				if a.site >= 0 and m.eco.s_out_good[a.site] >= 0 and dw < best_score:
					best_score = dw
					best = {"src": s["von"], "proc": s["nach"], "kette": ch["id"]}
				continue
			var score: float = m.eco.luftlinie_felder(a.site, city.site) + m.eco.luftlinie_felder(a.site, b.site)
			if not in_radius.has(s["von"]):
				score += 10000.0
			if b.kind == Building.Kind.SINK:
				score -= 1000.0      # Endabnehmer zuerst: erste Lieferung bringt sofort Ertrag (Kohle → Kraftwerk)
			if score < best_score:
				best_score = score
				best = {"src": s["von"], "proc": s["nach"], "kette": ch["id"]}
	if best.is_empty():
		return {"src": city_id, "proc": city_id, "m3_from": city_id, "m3_to": city_id, "m3_text": "Keine Kette auf der Karte."}
	var chain_id: String = opt.get("startkette", best["kette"])
	if chain_id == "keine":
		chain_id = best["kette"]
	best["m3_from"] = best["src"]
	best["m3_to"] = best["proc"]
	for ch in m.map_data["ketten"]:
		if ch["id"] != chain_id:
			continue
		for s in ch["strecken"]:
			var a = m.by_id.get(s["von"], null)
			if a != null and a.kind == Building.Kind.PROCESSOR and m.by_id.has(s["nach"]):
				best["m3_from"] = s["von"]
				best["m3_to"] = s["nach"]
				break
	var f: String = m.by_id[best["m3_from"]].display_name
	var t: String = m.by_id[best["m3_to"]].display_name
	best["m3_text"] = "Lizenz für %s kaufen, Straße bis %s bauen, Linie %s → %s (weite Strecke: ein Zug lohnt sich)." % [f, t, f, t]
	return best


# ---------------------------------------------------------------- Hover, Vorschau

func _process(delta: float) -> void:
	if m == null:
		return
	refresh_rule()
	if mode != Mode.FOUNDED:
		var city = city_at(_cell())
		if city != hovered:
			hovered = city
			_show(city if city != null else selected)
		if mode == Mode.MOVING and m.speed > 0:
			m.set_speed(0)
	if mode == Mode.PLACING:
		var cap: int = int(m.eco.slice["hq"]["start_capital_cent"])
		m.hud_vals["kasse"].text = m.money_str(cap)        # Aylin Flow 1: Kopfleiste zeigt das Startkapital schon vor der Gründung
	_update_ring_label()
	m.toast_panel.mouse_filter = Control.MOUSE_FILTER_STOP if (_move_toast != "" and can_move() and m.toast_label.text == _move_toast) else Control.MOUSE_FILTER_IGNORE


func _cell() -> Vector2i:
	return m.sim_hover if m.sim_hover_active else m._mouse_cell()


## Stadt unter dem Feld (Fläche der Stadt + PICK_FELDER), sonst null.
func city_at(c: Vector2i):
	if c.x < 0:
		return null
	var best = null
	var best_d := INF
	for b in m.buildings:
		if b.kind != Building.Kind.CITY:
			continue
		var ctr: Vector2i = b.cell + b.footprint / 2
		var d: float = Vector2(c - ctr).length()
		if d <= b.footprint.x * 0.5 + PICK_FELDER and d < best_d:
			best = b
			best_d = d
	return best


func radius_of(city) -> int:
	return int(m.eco.slice["hq"]["hq_radius_%s_felder" % RADMAP.get(city.city_stage, "village")])


## Vorschau-Zeilen laut L-12: radius + ketten[] + groesse + lizenzfaktor + gelaende + hinweis (falls nicht leer), max. 6.
## Kürzung bei Überlänge (F-20-Reihenfolge): zuerst die Geländezeile.
func preview_lines(city_id: String) -> Array:
	var e: Dictionary = vorschau.get(city_id, {})
	if e.is_empty():
		var city = m.by_id[city_id]
		return [{"icon": "hq", "text": "Radius %d Felder" % radius_of(city)},
			{"icon": "stadt", "text": "%s, %d Einwohner" % [m.STAGE_NAMES.get(city.city_stage, ""), city.city_pop]},
			{"icon": "info", "text": "Keine Vorschau-Daten (T-14b ausstehend)."}]
	var out: Array = [{"icon": "hq", "text": str(e.get("radius", ""))}]
	for k in e.get("ketten", []):
		out.append({"icon": "fabrik", "text": str(k)})
	out.append({"icon": "stadt", "text": str(e.get("groesse", ""))})
	out.append({"icon": "lizenz", "text": str(e.get("lizenzfaktor", ""))})
	var gel := {"icon": "info", "text": str(e.get("gelaende", "")), "gelaende": true}
	out.append(gel)
	if str(e.get("hinweis", "")) != "":
		out.append({"icon": "warnung", "text": str(e["hinweis"])})
	if out.size() > MAX_ROWS:
		out.erase(gel)
	return out.slice(0, MAX_ROWS)


## Wagnis = kein Rohstoff im Radius (Text aus L-12): Zustand „warn“ (Dreieck, kein Rot), sonst „ok“.
## S6 B-9: Feld „wagnis“ aus hq_vorschau.json (Satz steht nur noch in der Statuszeile); Alttext als Rückfall.
func is_wagnis(city_id: String) -> bool:
	var e: Dictionary = vorschau.get(city_id, {})
	if e.has("wagnis"):
		return bool(e["wagnis"])
	for k in e.get("ketten", []):
		if str(k).begins_with("Kein Rohstoff"):
			return true
	return false


func _show(city) -> void:
	var t0 := Time.get_ticks_usec()
	shown = city
	if city == null:
		_hide_preview()
		return
	var wag := is_wagnis(city.map_id)
	var has := vorschau.has(city.map_id)
	title_label.text = Kit.txt(city.display_name)
	status_shape.kind = "warn" if wag else ("ok" if has else "none")
	status_label.text = "Wagnis: kein Rohstoff im Radius" if wag else ("Kette im Radius" if has else "Keine Vorschau-Daten")
	status_label.add_theme_color_override("font_color", TB.C["warn_text"] if wag else (TB.C["ok_text"] if has else TB.C["muted"]))
	var lines := preview_lines(city.map_id)
	for i in rows.size():
		var r: Dictionary = rows[i]
		r["row"].visible = i < lines.size()
		if i < lines.size():
			r["icon"].texture = Kit.icon_tex(lines[i]["icon"])
			r["val"].text = Kit.txt(lines[i]["text"])
	var moving := mode == Mode.MOVING
	var chosen: bool = selected == city
	Kit.set_price_button(button, "hq", "HQ hierher umsetzen" if moving else "HQ hier gründen", "kostenlos" if moving else m.money_str(int(m.eco.slice["hq"]["start_capital_cent"])) + " Startkapital", not chosen)
	reason_label.text = "" if chosen else "Klick auf %s wählt den Standort." % city.display_name
	reason_label.visible = not chosen
	if not panel.visible:
		panel.visible = true
		if panel.is_inside_tree() and not reduced_motion:
			UiFx.slide_in(panel, Vector2(m.PANEL_W * 0.5, 0))
	var tw: Tween = panel.get_meta("slide_tw") if panel.has_meta("slide_tw") else null
	if tw == null or not tw.is_running():
		panel.reset_size()        # Höhe folgt der Zeilenzahl der gezeigten Stadt
	_show_ring(city)
	last_hover_ms = (Time.get_ticks_usec() - t0) / 1000.0


func _hide_preview() -> void:
	shown = null
	panel.visible = false
	hover_ring.visible = false
	for l in dist_labels:
		l.visible = false


# ---------------------------------------------------------------- UI

func _build_panel() -> void:
	panel = Kit.panel("PanelDock")
	panel.name = "HqPreview"
	panel.custom_minimum_size = Vector2(m.PANEL_W, 0)
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_left = -m.PANEL_W - 14
	panel.offset_right = -14
	panel.offset_top = m.HUD_H + 14
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.visible = false
	m.ui_root.add_child(panel)
	var v := Kit.vbox(0)
	panel.add_child(v)
	var head := Kit.panel("PanelHeader")
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(head)
	var disc := Kit.panel("PanelIconDisc")
	disc.add_theme_stylebox_override("panel", TB.sb(TB.C["amber"], 22, 2, TB.C["amber_edge"], Vector4(7, 7, 7, 7)))
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	disc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	disc.add_child(Kit.icon("hq", 26, TB.C["ink"]))
	title_label = Kit.label("", "LabelWoodTitle")
	title_label.clip_text = true
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var tv := Kit.vbox(0, [Kit.label("HQ-STANDORT", "LabelHudSmall"), title_label])
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(Kit.hbox(12, [disc, tv]))
	var body := Kit.margin(18, 14, 18, 18)
	v.add_child(body)
	var bv := Kit.vbox(10)
	body.add_child(bv)
	status_shape = Kit.status("ok", 16)
	status_label = Kit.label("", "LabelBody")
	bv.add_child(Kit.hbox(10, [status_shape, status_label]))
	bv.add_child(HSeparator.new())
	var fields := Kit.vbox(8)
	bv.add_child(fields)
	for i in MAX_ROWS:
		var ic := Kit.icon("info", 18, TB.C["muted"])
		ic.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		var val := Kit.label("", "", true)
		val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var row := Kit.hbox(10, [ic, val])
		fields.add_child(row)
		rows.append({"row": row, "icon": ic, "val": val})
	bv.add_child(Kit.margin(0, 2, 0, 0))
	button = Kit.price_button("hq", "HQ hier gründen", "", func(): confirm())
	button.name = "HqFound"
	bv.add_child(button)
	reason_label = Kit.label("", "LabelMuted", true)
	bv.add_child(reason_label)


func _ring_mat(col: Color) -> StandardMaterial3D:
	var mt := StandardMaterial3D.new()
	mt.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mt.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mt.albedo_color = col
	mt.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mt


func _ring(col: Color, width: float) -> MeshInstance3D:
	var r := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 1.0 - width
	tm.outer_radius = 1.0
	tm.rings = 96
	tm.ring_segments = 6
	r.mesh = tm
	r.material_override = _ring_mat(col)
	r.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	r.visible = false
	m.add_child(r)
	return r


func _build_world() -> void:
	hover_ring = _ring(Color(TB.C["amber"], 0.9), 0.025)
	hq_ring = _ring(Color(TB.C["cream"], 0.85), 0.012)
	ring_label = Label3D.new()
	ring_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	ring_label.no_depth_test = true
	ring_label.fixed_size = true
	ring_label.pixel_size = 0.0008
	ring_label.font_size = 36
	ring_label.font = TB.font(TB.FONT_BODY)
	ring_label.modulate = TB.C["cream"]
	ring_label.outline_modulate = Color(TB.C["ink"], 0.95)
	ring_label.outline_size = 9
	ring_label.visible = false
	m.add_child(ring_label)
	ghost = Node3D.new()      # leer bis zur ersten Wahl (_show_ghost ersetzt ihn über den S-13-Hook)
	ghost.visible = false
	m.add_child(ghost)


## Feld für das HQ am Stadtrand (Osten, sonst Süd/West/Nord): Land, kein Gebäude, kein Weg. Nur Optik, belegt nichts.
func hq_cell(city) -> Vector2i:
	var ctr: Vector2i = city.cell + city.footprint / 2
	var r: int = city.footprint.x / 2 + 3
	for d in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
		for extra in 6:
			var c: Vector2i = ctr + d * (r + extra)
			if m._in_grid(c) and m.terrain_at(c) == m.Terrain.PLAIN and not m.cell_to_building.has(c) and not m.roads.has(c) and not m.city_streets.has(c):
				return c
	return ctr + Vector2i(r, 0)


func _make_ghost() -> Node3D:
	var g := Node3D.new()
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(2.6, 2.2, 2.6)
	mi.mesh = bm
	mi.position.y = 1.1
	mi.material_override = _ring_mat(Color(1, 1, 1, 0.6))    # Ghost weiß = baubar (Aylin Flow 4, Sophie S-13)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	g.add_child(mi)
	return g


func _show_ghost(city) -> void:
	if ghost != null:
		ghost.free()
	ghost = _spawn_hq_building(city, true)
	ghost.visible = true


## S-13 Hook (Sophie): HQ-Gebäude an der Stadt. Nutzt props/hq_building.gd (static spawn(parent, pos, ghost) -> Node3D,
## kommt mit Felix' Merge), sonst Platzhalter: Holzquader mit Bernstein-Dach. Rückgabe hängt schon an m, Position gesetzt.
const HQ_PROP := "res://props/hq_building.gd"

func _spawn_hq_building(city, as_ghost := false) -> Node3D:
	var c := hq_cell(city)
	var pos := Vector3(c.x + 0.5, 0, c.y + 0.5)
	if ResourceLoader.exists(HQ_PROP):
		return load(HQ_PROP).spawn(m, pos, as_ghost)
	var g: Node3D = _make_ghost() if as_ghost else _placeholder_hq(city)
	g.position = pos
	m.add_child(g)
	return g


func _placeholder_hq(city) -> Node3D:
	var g := Node3D.new()
	g.name = "HQ_" + city.map_id
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(2.6, 2.2, 2.6)
	body.mesh = bm
	body.position.y = 1.1
	var mb := StandardMaterial3D.new()
	mb.albedo_color = TB.C["wood3"]
	body.material_override = mb
	g.add_child(body)
	var roof := MeshInstance3D.new()
	var rm := PrismMesh.new()
	rm.size = Vector3(3.0, 1.0, 2.8)
	roof.mesh = rm
	roof.position.y = 2.7
	var mr := StandardMaterial3D.new()
	mr.albedo_color = TB.C["amber"]
	roof.material_override = mr
	g.add_child(roof)
	return g


func _set_hq(city) -> void:
	ghost.visible = false
	if hq_building != null:
		hq_building.free()
	hq_building = _spawn_hq_building(city)
	var r := float(m.eco.hq_radius_felder)
	hq_ring.position = city.center() + Vector3(0, 0.08, 0)
	hq_ring.scale = Vector3(r, 0.05, r)
	hq_ring.visible = true
	ring_label.position = city.center() + Vector3(0, 0.5, -r - 5.0)   # knapp außerhalb des Rings, Linie kreuzt den Text nicht


func _show_ring(city) -> void:
	var r := float(radius_of(city))
	hover_ring.position = city.center() + Vector3(0, 0.1, 0)
	hover_ring.visible = true
	if _ring_tw != null and _ring_tw.is_running():
		_ring_tw.kill()
	var full := Vector3(r, 0.05, r)
	if reduced_motion or not hover_ring.is_inside_tree():
		hover_ring.scale = full
	else:
		hover_ring.scale = Vector3(r * 0.2, 0.05, r * 0.2)
		_ring_tw = hover_ring.create_tween()
		_ring_tw.tween_property(hover_ring, "scale", full, RING_SEC).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# Industrien im Ring: Luftlinie in Feldern (Rest bleibt ohne Marke)
	var n := 0
	for b in m.buildings:
		if not b.is_industry():
			continue
		var d: int = m.eco.luftlinie_felder(b.site, city.site)
		if d > r:
			continue
		if n >= dist_labels.size():
			var l := Label3D.new()
			l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			l.no_depth_test = true
			l.fixed_size = true
			l.pixel_size = 0.0007
			l.font_size = 34
			l.font = TB.font(TB.FONT_BODY)
			l.modulate = TB.C["amber"]
			l.outline_modulate = Color(TB.C["ink"], 0.95)
			l.outline_size = 9
			m.add_child(l)
			dist_labels.append(l)
		var lab: Label3D = dist_labels[n]
		lab.text = "%d F." % d
		lab.position = b.center() + Vector3(0, b.height + 2.4, 0)
		lab.visible = true
		n += 1
	for i in range(n, dist_labels.size()):
		dist_labels[i].visible = false


func ring_anim_sec() -> float:
	return 0.0 if reduced_motion else RING_SEC


func _hits_ring_or_hq(c: Vector2i) -> bool:
	if m.hq_city == null:
		return false
	var hc := hq_cell(m.hq_city)
	if absi(c.x - hc.x) <= 2 and absi(c.y - hc.y) <= 2:
		return true
	var ctr: Vector3 = m.hq_city.center()
	var d := Vector2(c.x + 0.5 - ctr.x, c.y + 0.5 - ctr.z).length()
	return absf(d - float(m.eco.hq_radius_felder)) <= RING_HIT_FELDER


func _update_ring_label() -> void:
	var show := mode == Mode.FOUNDED and can_move()
	ring_label.visible = show
	if not show:
		return
	var left := _left_ms()
	ring_label.text = Kit.txt("Umsetzen noch %d s" % ceili(left / 1000.0) if left <= 20000 else "Umsetzen möglich, noch %s" % _mss(left))


static func _mss(ms: int) -> String:
	var s := ceili(ms / 1000.0)
	return "%d:%02d" % [s / 60, s % 60]
