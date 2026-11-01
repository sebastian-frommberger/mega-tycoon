extends Control
## U-01 Styleguide (ui/styleguide.tscn): alle Komponenten des Themes mit ihren vier Zuständen
## (normal/hover/pressed/disabled), Typo-Stufen, Farb-Token mit Kontrast, Statusformen, Icon-Kit (U-01b),
## Panels. Hover/Pressed werden für die Übersicht per Stylebox-Override eingefroren; die echten
## Übergänge (≤ 150 ms) und der Klick-Sound laufen über ui_fx.gd, wenn man die Szene startet.

const TB := preload("res://ui/theme/theme_builder.gd")
const Kit := preload("res://ui/ui_kit.gd")
const UiFx := preload("res://ui/ui_fx.gd")

const STATES := ["normal", "hover", "pressed", "disabled"]

var th: Theme
var scroll: ScrollContainer
var component_count := 0
var state_cells := 0


func _ready() -> void:
	th = TB.build()
	theme = th
	add_child(UiFx.new())
	var bg := ColorRect.new()
	bg.color = Color("#5F7A4C")       # Gras-Ton der Karte (S-08 gras, abgedunkelt): Panels liegen „auf dem Modell“
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var outer := Kit.margin(28, 24, 28, 28)
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(outer)
	var page := Kit.vbox(18)
	outer.add_child(page)
	page.add_child(_header())
	page.add_child(_components())
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 18)
	flow.add_theme_constant_override("v_separation", 18)
	flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(flow)
	for c in [_typography(), _colors(), _status_and_progress(), _icons(), _panels()]:
		c.custom_minimum_size = Vector2(c.get_meta("w", 500 if c.get_meta("wide", false) else 340), 0)
		c.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		flow.add_child(c)
	print("STYLEGUIDE komponenten=%d zustaende_je=4 zellen=%d" % [component_count, state_cells])


func scroll_to_bottom() -> void:
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)


func _card(title: String, sub := "") -> Array:
	var p := Kit.panel("PanelCard")
	var v := Kit.vbox(10)
	p.add_child(v)
	var h := Kit.hbox(10, [Kit.label(title, "LabelValue")])
	if sub != "":
		h.add_child(Kit.spacer())
		h.add_child(Kit.label(sub, "LabelMuted"))
	v.add_child(h)
	return [p, v]


func _header() -> Control:
	var p := Kit.panel("PanelHeader")
	var hb := TB.sb(TB.C["wood"], 12, 0, Color.TRANSPARENT, Vector4(24, 16, 24, 16))
	hb.border_width_bottom = 4
	hb.border_color = TB.C["amber"]
	p.add_theme_stylebox_override("panel", hb)
	var h := Kit.hbox(16)
	p.add_child(h)
	h.add_child(Kit.label("MEGA TYCOON", "LabelHeroWood"))
	var v := Kit.vbox(0, [Kit.label("UI-Styleguide v1 · U-01 / U-01b · Sprint 5", "LabelHud"),
		Kit.label("Diorama-Look: Tischkarten aus Papier, Holzleisten, Bernstein nur für Aktionen. Kenney Future + Poppins, 4 Größen, Übergänge 100–150 ms.", "LabelHudSmall")])
	h.add_child(v)
	return p


# ------------------------------------------------------------ Komponenten × Zustände

func _components() -> Control:
	var c := _card("Komponenten × Zustände", "Hover/Pressed eingefroren · live: Szene starten")
	var v: VBoxContainer = c[1]
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 12)
	v.add_child(grid)
	grid.add_child(Kit.label("Komponente", "LabelCaps"))
	for s in STATES:
		grid.add_child(Kit.label(s.to_upper(), "LabelCaps"))
	var rows := [
		["Primär", "ButtonPrimary", func(): return Kit.button("Kaufen", "ButtonPrimary", "geld"), false],
		["Lizenzknopf", "ButtonPrimary", _lic_button, false],
		["Sekundär", "ButtonSecondary", func(): return Kit.button("Linie anlegen", "ButtonSecondary", "lkw"), false],
		["Gefährlich", "ButtonDanger", func(): return Kit.button("Auflösen", "ButtonDanger", "abriss"), false],
		["Ghost / Text", "ButtonGhost", func(): return Kit.button("Details", "ButtonGhost", "info"), false],
		["Werkzeug", "ButtonTool", _tool_button, true],
		["Tempo", "ButtonTempo", func(): return Kit.button("2×", "ButtonTempo", "tempo"), true],
		["Schließen", "ButtonClose", func(): return Kit.button("", "ButtonClose", "schliessen"), true],
		["Archetyp-Kachel", "ButtonTile", func(): return _mini_tile(), false],
		["Listenzeile", "ButtonRow", func(): return _row_button(), false],
		["Tab", "ButtonTab", func(): return Kit.button("Industrie", "ButtonTab"), false],
		["Chip / Filter", "ButtonChip", func(): return Kit.button("Lkw", "ButtonChip", "lkw"), false],
	]
	for r in rows:
		component_count += 1
		grid.add_child(Kit.vbox(0, [Kit.label(r[0], ""), Kit.label(r[1], "LabelMuted")]))
		for s in STATES:
			var b: Button = r[2].call()
			b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			Kit.force_state(b, s, th)
			state_cells += 1
			if r[3]:
				var wood := Kit.panel("PanelToolbar")
				var wb: StyleBoxFlat = th.get_stylebox("panel", "PanelToolbar").duplicate()
				wb.shadow_size = 0
				wb.set_content_margin_all(8)
				wood.add_theme_stylebox_override("panel", wb)
				wood.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
				wood.add_child(b)
				grid.add_child(wood)
			else:
				grid.add_child(b)
	v.add_child(Kit.label("%d Komponenten × 4 Zustände = %d Zellen. Klick-Sound (Kenney click-a, −14 dB) an jedem Button über ui_fx.gd." % [component_count, state_cells], "LabelMuted", true))
	return c[0]


func _lic_button() -> Button:
	var b := Kit.price_button("lizenz", "Lizenz kaufen · 140 $", "Ertrag ca. 224 $/Monat")
	b.custom_minimum_size = Vector2(290, 62)
	return b


func _tool_button() -> Button:
	var b := Kit.button("Straße", "ButtonTool", "strasse")
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.custom_minimum_size = Vector2(78, 70)
	var bd := Kit.badge("1")
	bd.position = Vector2(5, 4)
	b.add_child(bd)
	return b


func _mini_tile() -> Button:
	var b := Kit.button("", "ButtonTile")
	b.custom_minimum_size = Vector2(170, 76)
	var m := Kit.margin(12, 10, 12, 10)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	b.add_child(m)
	var disc := Kit.panel("PanelIconDisc")
	disc.add_theme_stylebox_override("panel", TB.sb(TB.C["amber"], 22, 2, TB.C["amber_edge"], Vector4(7, 7, 7, 7)))
	disc.add_child(Kit.icon("farm", 24, TB.C["ink"]))
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := Kit.hbox(10, [disc, Kit.vbox(0, [Kit.label("Agrar", "LabelValue"), Kit.label("4.500 $", "LabelMuted")])])
	m.add_child(h)
	return b


func _row_button() -> Button:
	var b := Kit.button("", "ButtonRow")
	b.custom_minimum_size = Vector2(170, 44)
	var m := Kit.margin(8, 4, 8, 4)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	b.add_child(m)
	m.add_child(Kit.hbox(8, [Kit.icon("lkw", 18, TB.C["muted"]), Kit.vbox(-2, [Kit.label("Farm › Mühle", ""), Kit.label("×2 · 28 Felder", "LabelMuted")]),
		Kit.spacer(), Kit.label("+93 $", "LabelOk")]))
	return b


# ------------------------------------------------------------ Typo, Farben, Status, Icons, Panels

func _typography() -> Control:
	var c := _card("Typografie", "2 Schriften · 4 Größen")
	c[0].set_meta("wide", true)
	var v: VBoxContainer = c[1]
	for e in [["LabelHero", "Startdialog 32"], ["LabelTitle", "Titel 24"], ["LabelValue", "Wert 18 · 4.500 $"],
			["LabelBody", "Text 18 Poppins"], ["", "Label 14 Poppins – Fließtext und Listen"], ["LabelMuted", "Muted 14 – Schlüssel, Hinweise"],
			["LabelCaps", "CAPS 14 – Abschnittstitel"]]:
		var l := Kit.label(e[1], e[0])
		v.add_child(Kit.hbox(12, [Kit.label(e[0] if e[0] != "" else "Label", "LabelMuted"), Kit.spacer(), l]))
		v.get_child(v.get_child_count() - 1).get_child(0).custom_minimum_size = Vector2(110, 0)
	return c[0]


func _colors() -> Control:
	var c := _card("Farb-Token", "Kontrast WCAG 2.x, gerechnet")
	c[0].set_meta("wide", true)
	var v: VBoxContainer = c[1]
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 16)
	g.add_theme_constant_override("v_separation", 8)
	v.add_child(g)
	for e in [["paper", "Papier", "ink 13,6:1"], ["wood", "Holz", "cream 10,2:1"], ["amber", "Bernstein (S-08 marker)", "ink 9,9:1"],
			["danger", "Gefahr", "cream 6,0:1"], ["muted", "Muted", "auf Papier 6,0:1"], ["status_ok", "status_ok", "Form + Saum"],
			["status_warn", "status_warn", "Form + Saum"], ["status_bad", "status_bad", "Form + Saum"]]:
		var sw := Kit.panel("PanelBadge")
		sw.add_theme_stylebox_override("panel", TB.sb(TB.C[e[0]], 6, 2, TB.C["saum"] if e[0].begins_with("status") else TB.C["line_dark"], Vector4(0, 0, 0, 0)))
		sw.custom_minimum_size = Vector2(36, 28)
		g.add_child(Kit.hbox(8, [sw, Kit.vbox(-2, [Kit.label(e[1], ""), Kit.label("%s · %s" % [TB.C[e[0]].to_html(false).to_upper(), e[2]], "LabelMuted")])]))
	return c[0]


func _status_and_progress() -> Control:
	var c := _card("Status & Fortschritt", "nie nur Farbe")
	var v: VBoxContainer = c[1]
	v.add_child(Kit.hbox(20, [Kit.hbox(8, [Kit.status("ok", 16), Kit.label("läuft", "")]), Kit.hbox(8, [Kit.status("warn", 16), Kit.label("Achtung", "")]),
		Kit.hbox(8, [Kit.status("bad", 16), Kit.label("steht", "")]), Kit.hbox(8, [Kit.status("none", 16), Kit.label("offen", "")])]))
	var lic := Kit.panel("PanelLicence")
	var lv := Kit.vbox(6)
	lic.add_child(lv)
	lv.add_child(Kit.hbox(8, [Kit.icon("lizenz", 18, TB.C["amber_edge"]), Kit.label("LIZENZ AKTIV", "LabelCaps")]))
	lv.add_child(Kit.label("Lizenz aktiv – noch 18:20 · verlängert sich automatisch", "", true))
	var pb := ProgressBar.new()
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(0, 12)
	pb.max_value = 1800
	pb.value = 1100
	lv.add_child(pb)
	var pw := ProgressBar.new()
	pw.theme_type_variation = "ProgressWarn"
	pw.show_percentage = false
	pw.custom_minimum_size = Vector2(0, 12)
	pw.max_value = 1800
	pw.value = 250
	lv.add_child(Kit.hbox(8, [Kit.label("< 5 min:", "LabelMuted"), pw]))
	pw.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(lic)
	return c[0]


func _icons() -> Control:
	var f := FileAccess.open(Kit.ICONS_JSON, FileAccess.READ)
	var d: Dictionary = JSON.parse_string(f.get_as_text())
	var icons: Dictionary = d["icons"]
	var c := _card("Icon-Kit U-01b", "%d Icons" % icons.size())
	c[0].set_meta("wide", true)
	c[0].set_meta("w", 620)
	var v: VBoxContainer = c[1]
	var g := GridContainer.new()
	g.columns = 6
	g.add_theme_constant_override("h_separation", 6)
	g.add_theme_constant_override("v_separation", 8)
	v.add_child(g)
	for k in icons:
		var cell := Kit.vbox(2)
		var disc := Kit.panel("PanelBadge")
		disc.add_theme_stylebox_override("panel", TB.sb(TB.C["wood"], 8, 0, Color.TRANSPARENT, Vector4(10, 8, 10, 8)))
		disc.add_child(Kit.icon(k, 26, TB.C["cream"]))
		disc.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		cell.add_child(disc)
		var l := Kit.label(k, "LabelMuted")
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.custom_minimum_size = Vector2(92, 0)
		l.clip_text = true
		cell.add_child(l)
		g.add_child(cell)
	return c[0]


func _panels() -> Control:
	var c := _card("Panels & Meldungen", "")
	c[0].set_meta("wide", true)
	var v: VBoxContainer = c[1]
	var cal := Kit.panel("PanelCallout")
	cal.add_child(Kit.vbox(2, [Kit.hbox(6, [Kit.icon("ziel", 16, TB.C["amber_edge"]), Kit.label("NÄCHSTER SCHRITT", "LabelCaps")]),
		Kit.label("Klick auf Getreidefarm 1 und dann im Panel auf „Lizenz kaufen“.", "", true)]))
	v.add_child(cal)
	var toast := Kit.panel("PanelToast")
	toast.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	toast.add_child(Kit.hbox(10, [Kit.icon("info", 20, TB.C["amber"]), Kit.label("Toast: Lizenz Mühle aktiv, 30:00", "LabelToast")]))
	v.add_child(toast)
	var hint := Kit.panel("PanelHint")
	hint.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var hl := Kit.label("Hinweis-Leiste über dem Werkzeug", "LabelHudSmall")
	hl.add_theme_color_override("font_color", TB.C["cream"])
	hint.add_child(hl)
	var tip := PanelContainer.new()
	tip.add_theme_stylebox_override("panel", th.get_stylebox("panel", "TooltipPanel"))
	var tl := Kit.label("Tooltip: Langtext nur hier", "LabelHudSmall")
	tl.add_theme_color_override("font_color", TB.C["cream"])
	tip.add_child(tl)
	tip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	v.add_child(Kit.hbox(12, [hint, tip]))
	v.add_child(Kit.label("Bewegung: Hover-Skalierung 100 ms ease-out · Press 0,97 · Panel-Slide + Fade 150 ms ease-out (Schließen 120 ms) · Klick-Sound leise.", "LabelMuted", true))
	return c[0]
