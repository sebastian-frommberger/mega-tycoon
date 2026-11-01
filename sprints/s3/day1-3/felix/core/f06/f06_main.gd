extends Node
## F-06 Testbuild (Diagnose-Playtest L-06), Felix 24.11. 2D-Testszene: Karte (Node2D + Camera2D) mit den drei
## Testfehlern aus Lenas l06_fehler_final.md und zwei Kontrollzügen, rechts das Meldungspanel nach Aylins
## f06_panel_spezifikation.md (Z1–Z5, Kamerasprung, Kontur, Klick-Log). Kein 3D, kein Look (S-03 getrennt).
## Alles wird im Code aufgebaut; die .tscn enthält nur den Wurzelknoten mit diesem Skript.
##
## Startparameter (nach "--"): --tester=T1..T6 (Reihenfolge der Meldungen, Standard T1)
##   --logdir=<pfad> (Standard user://) · --demo=F1|F2|F3 --demo-row=<n> --screenshot=<png> (Screenshot-Modus)
## Klick-Log: <logdir>/klicklog_<session>.csv (Aylin Abschnitt 5) · Session/Replay: <logdir>/session_<session>.json

const F06World := preload("res://f06/f06_world.gd")
const SimWorld := preload("res://sim_world.gd")

# ---- Farben/Maße (Aylin Abschnitt 2, Mini-Entwurf)
const C_PANEL := Color("#2B2B2B")
const C_ROW := Color("#383838")
const C_ROW_HOVER := Color("#454545")
const C_SEL := Color("#F0F0F0")
const C_SEL_TEXT := Color("#1A1A1A")
const C_TEXT := Color("#F0F0F0")
const C_DIM := Color("#A8A8A8")
const C_MAP_BG := Color("#1E2326")
const PANEL_W := 400.0
const BASE := Vector2(1920, 1080)
const JUMP_ZOOM := 3.0      # 200-m-Abschnitt ganz im Bild (Annahme Aylin, Sophies Zoomregel fehlt)
const JUMP_TIME := 0.6
const FORMAT := "f06-session-v1"

var opts := {"tester": "T1", "logdir": "user://", "demo": "", "demo_row": 0, "screenshot": "", "quit_after": 0.0}
var opts_override: Dictionary = {}   # vom Smoke-Test gesetzt

var world
var sim
var session_id := ""
var klicklog_path := ""
var session_path := ""
var _log: FileAccess
var _start_ms := 0
var _acc := 0.0
var _title_timer := 0.0
var _session_timer := 0.0
var events_logged := 0
var vertragsfehler := 0

# Meldungen: [{meldung_id, vehicle_id, fehler}]
var meldungen: Array = []
var open_id := -1            # meldung_id der offenen Meldung, -1 = Z1
var snap_chain: Dictionary = {}
var snap_rows: Array = []
var snap_tick := 0
var selected_row := -1       # 1..n, -1 = keine (Z2)
var collapsed := false
var cam_before := {}         # Position/Zoom vor dem ersten Sprung dieser Meldung
var contour := {}            # {kind, id, pos, wurzel} aktuelles Konturziel
var pulse := 0.0

var cam: Camera2D
var karte: Node2D
var overlay: Control
var panel: PanelContainer
var list_box: VBoxContainer
var header_btn: Button
var collapse_btn: Button
var badge: Button
var session_label: Label
var _cam_tween: Tween
var _pulse_tween: Tween
var _title_labels: Dictionary = {}   # meldung_id -> Label
var _drag := false
var font_bold: FontVariation


func _ready() -> void:
	_parse_args()
	RenderingServer.set_default_clear_color(C_MAP_BG)
	world = F06World.new()
	world.build()
	world.vorlauf()
	sim = world.sim
	_start_ms = Time.get_ticks_msec()
	_open_logs()
	_build_scene()
	_create_meldungen()
	_render_list()
	_overview()
	_write_session(false)
	if opts["demo"] != "":
		_run_demo()


func _parse_args() -> void:
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = String(a).trim_prefix("--").split("=", true, 1)
		if kv.size() == 2:
			match kv[0]:
				"tester": opts["tester"] = kv[1].to_upper()
				"logdir": opts["logdir"] = kv[1]
				"demo": opts["demo"] = kv[1].to_upper()
				"demo-row": opts["demo_row"] = int(kv[1])
				"screenshot": opts["screenshot"] = kv[1]
				"quit-after": opts["quit_after"] = float(kv[1])
	for k in opts_override:
		opts[k] = opts_override[k]
	if not F06World.PERMUTATION.has(opts["tester"]):
		push_warning("Unbekannter Tester %s, nehme T1" % opts["tester"])
		opts["tester"] = "T1"


# ---------------- Logs ----------------

func _open_logs() -> void:
	var dt := Time.get_datetime_dict_from_system()
	session_id = "%s_%04d%02d%02d-%02d%02d%02d" % [opts["tester"], dt["year"], dt["month"], dt["day"], dt["hour"], dt["minute"], dt["second"]]
	var dir: String = opts["logdir"]
	if not dir.ends_with("/"):
		dir += "/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	klicklog_path = dir + "klicklog_%s.csv" % session_id
	session_path = dir + "session_%s.json" % session_id
	_log = FileAccess.open(klicklog_path, FileAccess.WRITE)
	if _log == null:
		push_error("Klick-Log nicht schreibbar: %s (%d)" % [klicklog_path, FileAccess.get_open_error()])
	else:
		_log.store_line("unix_ms;ms_seit_start;tick;ereignis;meldung_id;vehicle_id;index;ziel")
		_log.flush()
	print("F-06 Testbuild, Session %s, Tester %s, Reihenfolge %s" % [session_id, opts["tester"], str(F06World.PERMUTATION[opts["tester"]])])
	print("Klick-Log: %s" % ProjectSettings.globalize_path(klicklog_path))
	print("Session/Replay: %s" % ProjectSettings.globalize_path(session_path))
	log_event("session_start")


func log_event(ereignis: String, meldung_id: int = -1, vehicle_id: int = -1, index: int = -1, ziel: String = "") -> void:
	var unix_ms: int = int(Time.get_unix_time_from_system() * 1000.0)
	var line := "%d;%d;%d;%s;%s;%s;%s;%s" % [unix_ms, Time.get_ticks_msec() - _start_ms, sim.tick_count, ereignis,
		"" if meldung_id < 0 else str(meldung_id), "" if vehicle_id < 0 else str(vehicle_id),
		"" if index < 0 else str(index), ziel]
	events_logged += 1
	if _log != null:
		_log.store_line(line)
		_log.flush()


## Session-/Replay-Datei: alles, was zum Nachfahren nötig ist. Die Sim hat keine Spielerbefehle; Replay =
## Welt neu bauen, gleiche Ticks laufen, Prüfsummen vergleichen, Klick-Log an den Ticks nachlesen (f06_replay.gd).
func _write_session(final: bool) -> void:
	var data := {
		"format": FORMAT, "szenario": "F06_v1", "godot": Engine.get_version_info()["string"],
		"session": session_id, "tester": opts["tester"], "reihenfolge": F06World.PERMUTATION[opts["tester"]],
		"vorlauf_ticks": F06World.VORLAUF_TICKS, "checksum_start": str(_checksum_start),
		"meldungen": meldungen, "klicklog": klicklog_path.get_file(), "tick_ende": sim.tick_count,
		"checksum_ende": str(sim.checksum()), "ereignisse": events_logged, "vertragsfehler": vertragsfehler,
		"abgeschlossen": final, "unix_ms_ende": int(Time.get_unix_time_from_system() * 1000.0),
	}
	var f := FileAccess.open(session_path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(data, "  "))
		f.close()


var _checksum_start := 0


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		if sim != null and _log != null:
			log_event("session_ende")
			_write_session(true)
			_log.close()
			_log = null


# ---------------- Szene ----------------

func _build_scene() -> void:
	_checksum_start = sim.checksum()
	font_bold = FontVariation.new()
	font_bold.base_font = ThemeDB.fallback_font
	font_bold.variation_embolden = 0.8
	karte = Karte.new()
	karte.main = self
	add_child(karte)
	cam = Camera2D.new()
	add_child(cam)
	cam.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	overlay = Overlay.new()
	overlay.main = self
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(overlay)
	# Panel rechts, 400 px bei 1080p
	panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(C_PANEL, 8))
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 0.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -PANEL_W
	panel.offset_right = 0
	panel.gui_input.connect(_on_ui_other.bind("panel"))
	layer.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	header_btn = _flat_button("MELDUNGEN 0", 18, true)
	header_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	header_btn.pressed.connect(_on_header)
	head.add_child(header_btn)
	collapse_btn = _flat_button("[−]", 18, true)
	collapse_btn.pressed.connect(_on_collapse)
	head.add_child(collapse_btn)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	list_box = VBoxContainer.new()
	list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_box.add_theme_constant_override("separation", 8)
	scroll.add_child(list_box)
	session_label = Label.new()
	session_label.add_theme_font_size_override("font_size", 14)
	session_label.add_theme_color_override("font_color", Color(C_DIM, 0.6))
	session_label.text = "Testbuild F-06 · %s" % session_id
	v.add_child(session_label)
	badge = Button.new()
	badge.text = "0"
	badge.add_theme_font_size_override("font_size", 18)
	badge.anchor_left = 1.0
	badge.anchor_right = 1.0
	badge.offset_left = -48
	badge.offset_right = -8
	badge.offset_top = 8
	badge.offset_bottom = 48
	badge.visible = false
	badge.pressed.connect(_on_badge)
	layer.add_child(badge)


func _box(c: Color, margin: float, border: Color = Color(0, 0, 0, 0), bw: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_content_margin_all(margin)
	if bw > 0:
		sb.border_color = border
		sb.set_border_width_all(bw)
	return sb


func _flat_button(text: String, size: int, bold: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.flat = true
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", C_TEXT)
	b.add_theme_color_override("font_hover_color", C_TEXT)
	b.add_theme_color_override("font_pressed_color", C_TEXT)
	if bold:
		b.add_theme_font_override("font", font_bold)
	return b


func _label(text: String, size: int, color: Color, bold: bool = false, wrap: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if bold:
		l.add_theme_font_override("font", font_bold)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


# ---------------- Meldungen ----------------

func _create_meldungen() -> void:
	var order: Array = F06World.PERMUTATION[opts["tester"]]
	for key in order:
		var vid: int = F06World.FEHLER[key]["vehicle"]
		var c: Dictionary = sim.get_wait_chain(vid)
		var chk: Dictionary = world.ui_check(c, world.rows_for(c))
		if not chk["fehler"].is_empty():
			vertragsfehler += 1
			log_event("vertragsfehler", -1, vid, -1, ",".join(PackedStringArray(chk["fehler"])))
			continue
		meldungen.append({"meldung_id": meldungen.size() + 1, "vehicle_id": vid, "fehler": key})


func meldung_by_id(mid: int) -> Dictionary:
	for m in meldungen:
		if m["meldung_id"] == mid:
			return m
	return {}


func _render_list() -> void:
	for c in list_box.get_children():
		list_box.remove_child(c)
		c.queue_free()
	_title_labels.clear()
	header_btn.text = "MELDUNGEN %d" % meldungen.size()
	badge.text = str(meldungen.size())
	if meldungen.is_empty():
		list_box.add_child(_label("Keine Probleme.", 16, C_DIM))
		return
	for m in meldungen:
		var is_open: bool = m["meldung_id"] == open_id
		var row := PanelContainer.new()
		row.custom_minimum_size = Vector2(0, 72)
		row.add_theme_stylebox_override("panel", _box(C_ROW, 8, C_TEXT if is_open else Color(0, 0, 0, 0), 2 if is_open else 0))
		row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		row.gui_input.connect(_on_row_input.bind(row, m["meldung_id"], -1))
		row.mouse_entered.connect(_hover.bind(row, true, is_open))
		row.mouse_exited.connect(_hover.bind(row, false, is_open))
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(h)
		var sq := ColorRect.new()
		sq.color = C_DIM
		sq.custom_minimum_size = Vector2(12, 12)
		sq.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		sq.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(sq)
		var tv := VBoxContainer.new()
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(tv)
		var t := _label(world.titel(m["vehicle_id"]), 18, C_TEXT, true, true)
		_title_labels[m["meldung_id"]] = t
		tv.add_child(t)
		tv.add_child(_label("bei %s" % F06World.FEHLER[m["fehler"]]["ort"], 14, C_DIM, false, true))
		var arrow := _label("v" if is_open else ">", 18, C_TEXT, true)
		arrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(arrow)
		list_box.add_child(row)
		if is_open:
			_render_chain(m)


func _render_chain(m: Dictionary) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	list_box.add_child(box)
	var head := _label("WARUM? · Stand %s" % F06World.spielzeit_text(snap_tick), 14, C_DIM, true)
	head.mouse_filter = Control.MOUSE_FILTER_STOP
	head.gui_input.connect(_on_ui_other.bind("warum_kopf"))
	box.add_child(head)
	for r in snap_rows:
		var sel: bool = r["index"] == selected_row
		var bright: bool = r["wurzel"] or sel
		var bg: Color = C_SEL if bright else C_ROW
		var fg: Color = C_SEL_TEXT if bright else C_TEXT
		var row := PanelContainer.new()
		row.custom_minimum_size = Vector2(0, 40)
		var border := Color(0, 0, 0, 0)
		var bw := 0
		if r["wurzel"] and sel:
			border = Color("#1A1A1A")
			bw = 3
		elif sel:
			border = C_TEXT
			bw = 2
		row.add_theme_stylebox_override("panel", _box(bg, 8, border, bw))
		row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		row.gui_input.connect(_on_row_input.bind(row, m["meldung_id"], r["index"]))
		if not bright:
			row.mouse_entered.connect(_hover.bind(row, true, false))
			row.mouse_exited.connect(_hover.bind(row, false, false))
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(h)
		var num := _label(str(r["index"]), 16, fg, true)
		num.custom_minimum_size = Vector2(20, 0)
		h.add_child(num)
		var tv := VBoxContainer.new()
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_theme_constant_override("separation", 0)
		tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(tv)
		if r["wurzel"]:
			tv.add_child(_label("WURZELURSACHE", 14, fg, true))
		tv.add_child(_label(r["text"], 16, fg, false, true))
		var arrow := _label(">", 16, fg, true)
		arrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(arrow)
		box.add_child(row)
	# K_ZURUECK nur beim Kreis mit >= 3 Zügen (Aylins ausgefüllte Vorlagen: F2 ja, F1-Zweierkreis nein)
	if snap_chain.get("is_deadlock", false) and snap_chain.get("cycle", []).size() >= 3:
		var k := _label("< zurück zu Zeile 1", 16, C_DIM)
		k.mouse_filter = Control.MOUSE_FILTER_STOP
		k.gui_input.connect(_on_ui_other.bind("k_zurueck"))
		box.add_child(k)
	# Vorschlag ausgeblendet (D11): bewusst kein Vorschlagsblock
	var back := Button.new()
	back.text = "Zurück zur Übersicht"
	back.custom_minimum_size = Vector2(0, 40)
	back.add_theme_font_size_override("font_size", 16)
	back.pressed.connect(_on_back)
	box.add_child(back)


func _hover(row: PanelContainer, inside: bool, is_open: bool) -> void:
	if not is_instance_valid(row):
		return
	row.add_theme_stylebox_override("panel", _box(C_ROW_HOVER if inside else C_ROW, 8, C_TEXT if is_open else Color(0, 0, 0, 0), 2 if is_open else 0))


func _on_row_input(ev: InputEvent, _row: Control, mid: int, index: int) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		if index < 0:
			click_meldung(mid)
		else:
			click_zeile(index)
		get_viewport().set_input_as_handled()


func _on_ui_other(ev: InputEvent, name: String) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		log_event("klick_sonstige", -1, -1, -1, "ui:%s" % name)
		get_viewport().set_input_as_handled()


## Z1 -> Z2 (oder Z2 -> Z1 bei Klick auf die offene Meldung)
func click_meldung(mid: int) -> void:
	var m := meldung_by_id(mid)
	if m.is_empty():
		return
	if open_id == mid:
		close_meldung()
		return
	if open_id != -1:
		close_meldung(false)
	var c: Dictionary = sim.get_wait_chain(m["vehicle_id"])   # Schnappschuss, eingefroren bis Z2 -> Z1
	var rows: Array = world.rows_for(c)
	var chk: Dictionary = world.ui_check(c, rows)
	if not chk["fehler"].is_empty():
		vertragsfehler += 1
		log_event("vertragsfehler", mid, m["vehicle_id"], -1, ",".join(PackedStringArray(chk["fehler"])))
		return
	for w in chk["warnungen"]:
		push_warning("Meldung %d: %s" % [mid, w])
	snap_chain = c
	snap_rows = rows
	snap_tick = sim.tick_count
	open_id = mid
	selected_row = -1
	cam_before = {"pos": cam.position, "zoom": cam.zoom}
	log_event("meldung_geoeffnet", mid, m["vehicle_id"])
	_set_contour(rows[0], false)
	jump_to(rows[0]["pos"])
	_render_list()


func close_meldung(render: bool = true) -> void:
	if open_id == -1:
		return
	var m := meldung_by_id(open_id)
	log_event("meldung_geschlossen", open_id, m.get("vehicle_id", -1))
	open_id = -1
	selected_row = -1
	snap_rows = []
	snap_chain = {}
	contour = {}
	if render:
		_render_list()


## Z2/Z3 -> Z3
func click_zeile(index: int) -> void:
	if open_id == -1 or index < 1 or index > snap_rows.size():
		return
	var m := meldung_by_id(open_id)
	log_event("zeile_klick", open_id, m["vehicle_id"], index)
	selected_row = index
	var r: Dictionary = snap_rows[index - 1]
	_set_contour(r, true)
	jump_to(r["pos"])
	_render_list()


func _on_header() -> void:
	if open_id != -1:
		close_meldung()
	else:
		log_event("klick_sonstige", -1, -1, -1, "ui:kopf")


func _on_back() -> void:
	var m := meldung_by_id(open_id)
	log_event("sprung_zurueck", open_id, m.get("vehicle_id", -1))
	if not cam_before.is_empty():
		_tween_cam(cam_before["pos"], cam_before["zoom"])
	close_meldung()


func _on_collapse() -> void:
	collapsed = true
	panel.visible = false
	badge.visible = true
	log_event("feed_eingeklappt")


func _on_badge() -> void:
	collapsed = false
	panel.visible = true
	badge.visible = false
	log_event("feed_ausgeklappt")


# ---------------- Kamera, Kontur ----------------

func world_px(p: Vector2i) -> Vector2:
	return Vector2(p) / 1000.0


## Kamera so, dass der Punkt in der Mitte der sichtbaren Karte (links vom Panel) liegt.
func _cam_pos_for(target: Vector2, zoom: float) -> Vector2:
	var shift: float = 0.0 if collapsed else PANEL_W * 0.5
	return target + Vector2(shift / zoom, 0)


func jump_to(p: Vector2i) -> void:
	_tween_cam(_cam_pos_for(world_px(p), JUMP_ZOOM), Vector2(JUMP_ZOOM, JUMP_ZOOM))


func _tween_cam(pos: Vector2, zoom: Vector2) -> void:
	if _cam_tween != null and _cam_tween.is_valid():
		_cam_tween.kill()   # neuer Klick unterbricht die laufende Fahrt
	_cam_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_cam_tween.tween_property(cam, "position", pos, JUMP_TIME)
	_cam_tween.tween_property(cam, "zoom", zoom, JUMP_TIME)


func _set_contour(r: Dictionary, do_pulse: bool) -> void:
	contour = {"kind": r["kind"], "id": r["id"], "pos": r["pos"], "wurzel": r["wurzel"], "obj_kind": r.get("obj_kind", "")}
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
	pulse = 0.0
	if do_pulse:
		_pulse_tween = create_tween().set_loops(2)
		_pulse_tween.tween_property(self, "pulse", 1.0, 0.2)
		_pulse_tween.tween_property(self, "pulse", 0.0, 0.2)


func _overview() -> void:
	var r := Rect2(world_px(sim.graph.nodes[sim.graph.nodes.keys()[0]]["pos"]), Vector2.ZERO)
	for nid in sim.graph.nodes:
		r = r.expand(world_px(sim.graph.nodes[nid]["pos"]))
	r = r.grow(80)
	var avail := Vector2(BASE.x - PANEL_W, BASE.y)
	var z: float = minf(avail.x / r.size.x, avail.y / r.size.y)
	cam.zoom = Vector2(z, z)
	cam.position = _cam_pos_for(r.get_center(), z)


## Darstellungsort eines Fahrzeugs: wartende Fahrzeuge stehen am Ende ihres gehaltenen Abschnitts (15 m vor
## dem Knoten), damit zwei Züge am selben Knoten nicht übereinander liegen. Nur Darstellung, nicht Vertrag.
func vehicle_draw_pos(v: Dictionary) -> Vector2:
	var p := world_px(sim.vehicle_pos(v))
	if v["state"] == SimWorld.VState.WARTET_BLOCK and v["held_block"] != -1:
		var e: Dictionary = sim.graph.edges[sim.graph.blocks[v["held_block"]]["edge"]]
		var na := world_px(sim.graph.nodes[e["a"]]["pos"])
		var nb := world_px(sim.graph.nodes[e["b"]]["pos"])
		var other: Vector2 = na if na.distance_to(p) > nb.distance_to(p) else nb
		if other.distance_to(p) > 1.0:
			p += (other - p).normalized() * 15.0
	return p


func signal_draw_pos(sig_id: int) -> Vector2:
	var s: Dictionary = sim.graph.signals[sig_id]
	var e: Dictionary = sim.graph.edges[s["edge"]]
	var n := world_px(sim.graph.nodes[s["node"]]["pos"])
	var other := world_px(sim.graph.nodes[e["b"] if s["fwd"] else e["a"]]["pos"])
	var d: Vector2 = (other - n).normalized()
	return n + d * 8.0 + Vector2(-d.y, d.x) * 7.0


## Bildschirmort eines Konturziels / einer Kettenzeile
func target_world(kind: String, id: int, pos: Vector2i) -> Vector2:
	if kind == "FAHRZEUG" and sim.vehicles.has(id):
		return vehicle_draw_pos(sim.vehicles[id])
	if kind == "SIGNAL" and sim.graph.signals.has(id):
		return signal_draw_pos(id)
	return world_px(pos)


func to_screen(p: Vector2) -> Vector2:
	return karte.get_global_transform_with_canvas() * p


# ---------------- Sim-Takt, Eingaben ----------------

func _process(delta: float) -> void:
	_acc += delta
	var n := 0
	while _acc >= 1.0 / SimWorld.TICK_HZ and n < 5:
		sim.step()
		_acc -= 1.0 / SimWorld.TICK_HZ
		n += 1
	if n == 5:
		_acc = 0.0
	_title_timer += delta
	if _title_timer >= 1.0:
		_title_timer = 0.0
		for mid in _title_labels:
			var lab: Label = _title_labels[mid]
			if is_instance_valid(lab):
				lab.text = world.titel(meldung_by_id(mid)["vehicle_id"])
	_session_timer += delta
	if _session_timer >= 30.0:
		_session_timer = 0.0
		_write_session(false)
	karte.queue_redraw()
	overlay.queue_redraw()


func step_sim(n: int) -> void:
	for i in range(n):
		sim.step()


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed:
		match ev.button_index:
			MOUSE_BUTTON_LEFT:
				log_event("klick_sonstige", -1, -1, -1, _hit_test(ev.position))
			MOUSE_BUTTON_WHEEL_UP:
				cam.zoom = (cam.zoom * 1.15).clamp(Vector2(0.3, 0.3), Vector2(8, 8))
			MOUSE_BUTTON_WHEEL_DOWN:
				cam.zoom = (cam.zoom / 1.15).clamp(Vector2(0.3, 0.3), Vector2(8, 8))
			MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE:
				_drag = true
	elif ev is InputEventMouseButton and not ev.pressed and (ev.button_index == MOUSE_BUTTON_RIGHT or ev.button_index == MOUSE_BUTTON_MIDDLE):
		_drag = false
	elif ev is InputEventMouseMotion and _drag:
		cam.position -= ev.relative / cam.zoom.x


## Klick auf die Karte: Objekt in 14 px Umkreis oder karte_leer (Aylin ziel-Spalte).
func _hit_test(screen: Vector2) -> String:
	var best := ""
	var best_d := 14.0
	for id in sim.vehicles:
		var d := to_screen(vehicle_draw_pos(sim.vehicles[id])).distance_to(screen)
		if d < best_d:
			best_d = d
			best = "karte_objekt:%s:%d" % [world.vehicle_kind[id], id]
	for nid in sim.stations:
		var d2 := to_screen(world_px(sim.graph.nodes[nid]["pos"])).distance_to(screen)
		if d2 < best_d:
			best_d = d2
			best = "karte_objekt:LAGER:%d" % nid
	for sid in sim.graph.signals:
		var d3 := to_screen(signal_draw_pos(sid)).distance_to(screen)
		if d3 < best_d:
			best_d = d3
			best = "karte_objekt:SIGNAL:%d" % sid
	return best if best != "" else "karte_leer"


# ---------------- Demo/Screenshot-Modus ----------------

func _run_demo() -> void:
	await get_tree().create_timer(0.5).timeout
	for m in meldungen:
		if m["fehler"] == opts["demo"]:
			click_meldung(m["meldung_id"])
	await get_tree().create_timer(1.0).timeout
	if int(opts["demo_row"]) > 0:
		click_zeile(int(opts["demo_row"]))
	await get_tree().create_timer(1.4).timeout
	if opts["screenshot"] != "":
		var img: Image = get_viewport().get_texture().get_image()
		var err := img.save_png(opts["screenshot"])
		print("Screenshot %s: %s (%dx%d)" % [opts["screenshot"], "ok" if err == OK else "Fehler %d" % err, img.get_width(), img.get_height()])
		log_event("session_ende")
		_write_session(true)
		get_tree().quit(0)


# ================= Zeichnen =================

## Weltgeometrie: Strecken, Blöcke, Knoten, Fahrzeuge (1 m = 1 px Welt).
class Karte extends Node2D:
	var main

	func _draw() -> void:
		var sim = main.sim
		var g = sim.graph
		var z: float = main.cam.zoom.x
		var w: float = 3.0 / z
		for eid in g.edges:
			var e: Dictionary = g.edges[eid]
			var a: Vector2 = main.world_px(g.nodes[e["a"]]["pos"])
			var b: Vector2 = main.world_px(g.nodes[e["b"]]["pos"])
			if main.world.parallel_edges.has(eid):
				var d: Vector2 = (b - a).normalized()
				var off := Vector2(-d.y, d.x) * 14.0
				draw_line(a, a + d * 25.0 + off, Color("#6B7378"), w)
				draw_line(b, b - d * 25.0 + off, Color("#6B7378"), w)
				a += d * 25.0 + off
				b -= d * 25.0 + off
			var held: bool = g.blocks[e["block_fwd"]]["holder"] != -1 or g.blocks[e["block_rev"]]["holder"] != -1
			draw_line(a, b, Color("#8A9499") if held else Color("#5A6267"), w * (1.0 if e["single"] else 1.6))
		for nid in g.nodes:
			draw_circle(main.world_px(g.nodes[nid]["pos"]), 4.0 / z, Color("#8A9499"))
		for nid in sim.stations:
			var p: Vector2 = main.world_px(g.nodes[nid]["pos"])
			var s := 9.0 / z
			draw_rect(Rect2(p - Vector2(s, s), Vector2(2 * s, 2 * s)), Color("#C9A86A"))
		for sid in g.signals:
			var sp: Vector2 = main.signal_draw_pos(sid)
			var free: bool = g.blocks[g.signals[sid]["block"]]["holder"] == -1
			draw_circle(sp, 3.0 / z, Color("#6FBF73") if free else Color("#D9534F"))
		for id in sim.vehicles:
			var v: Dictionary = sim.vehicles[id]
			var vp: Vector2 = main.vehicle_draw_pos(v)
			var lkw: bool = main.world.vehicle_kind[id] == "LKW"
			var r := (5.0 if lkw else 7.0) / z
			var col := Color("#E8E8E8") if v["state"] == 1 else Color("#F2B134")
			draw_rect(Rect2(vp - Vector2(r * 1.4, r), Vector2(r * 2.8, r * 2)), col)


## Bildschirm-Ebene: Beschriftungen, nummerierte Markierungen, Kettenlinie, Kontur (zoomunabhängig).
class Overlay extends Control:
	var main

	func _draw() -> void:
		var sim = main.sim
		var g = sim.graph
		var font: Font = ThemeDB.fallback_font
		for nid in g.nodes:
			var p: Vector2 = main.to_screen(main.world_px(g.nodes[nid]["pos"]))
			draw_string(font, p + Vector2(6, 50), g.nodes[nid]["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#A8A8A8"))
		for id in sim.vehicles:
			var vp: Vector2 = main.to_screen(main.vehicle_draw_pos(sim.vehicles[id]))
			draw_string(font, vp + Vector2(-20, 30), sim.vehicles[id]["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#F0F0F0"))
		if main.open_id == -1:
			return
		# Markierungen je Kettenzeile (Soll): Symptom = Ring, Zwischen = graue Scheibe, Wurzel = Quadrat
		var pts: Array = []
		var used: Array = []
		for r in main.snap_rows:
			var sp: Vector2 = main.to_screen(main.target_world(r["kind"], r["id"], r["pos"]))
			var k := 0
			for u in used:
				if u.distance_to(sp + Vector2(26 * k, -26)) < 8.0:
					k += 1
			var mp: Vector2 = sp + Vector2(26 * k, -26)
			used.append(mp)
			pts.append({"r": r, "p": mp, "anchor": sp})
		for i in range(pts.size() - 1):
			draw_dashed_line(pts[i]["p"], pts[i + 1]["p"], Color(1, 1, 1, 0.55), 2.0, 6.0)
		if main.snap_chain.get("is_deadlock", false):
			var wz: Array = pts.filter(func(x): return x["r"]["key"] == "R_WARTET_ZUG")
			if wz.size() >= 3:
				draw_dashed_line(wz[-1]["p"], wz[0]["p"], Color(1, 1, 1, 0.55), 2.0, 6.0)
		for e in pts:
			var r: Dictionary = e["r"]
			var mp: Vector2 = e["p"]
			var big: bool = r["index"] == main.selected_row
			var rad := 16.0 if big else 12.0
			draw_line(e["anchor"], mp, Color(1, 1, 1, 0.35), 1.0)
			var txt_col := Color("#1A1A1A")
			if r["wurzel"]:
				draw_rect(Rect2(mp - Vector2(rad, rad), Vector2(2 * rad, 2 * rad)), Color("#F0F0F0"))
			elif r["index"] == 1:
				draw_circle(mp, rad, Color("#2B2B2B"))
				draw_circle(mp, rad, Color("#F0F0F0"), false, 2.0)
				txt_col = Color("#F0F0F0")
			else:
				draw_circle(mp, rad, Color("#A8A8A8"))
			draw_string(font, mp + Vector2(-rad, 5), str(r["index"]), HORIZONTAL_ALIGNMENT_CENTER, 2 * rad, 14, txt_col)
		# Kontur am Zielobjekt: weiß 3 px, pulsiert 2x nach Zeilenklick
		if not main.contour.is_empty():
			var c: Dictionary = main.contour
			var cp: Vector2 = main.to_screen(main.target_world(c["kind"], c["id"], c["pos"]))
			var grow: float = 6.0 * main.pulse
			if c["wurzel"]:
				var s := 22.0 + grow
				draw_rect(Rect2(cp - Vector2(s, s), Vector2(2 * s, 2 * s)), Color.WHITE, false, 3.0)
			else:
				draw_circle(cp, 18.0 + grow, Color.WHITE, false, 3.0)
