extends RefCounted
## U-01 Theme v1 (Sophie Martin / Aylin Kaya / Mira Lenz). Diorama-Look: Tischkarten aus Papier auf dem
## Modell, Holzleisten für HUD und Werkzeug, Bernstein (S-08 marker) nur für Aktionen.
## Das Theme wird im Code gebaut (volle Kontrolle, keine erfundenen uid://) und von ui/tools/make_theme.gd
## zusätzlich als res://ui/theme/mega_theme.tres gespeichert (für den Editor).
## Schriften: max. 2 (Kenney Future für Titel/Zahlen/Knöpfe, Poppins Medium für Text), 4 Größen.

const FONT_TITLE := "res://ui/assets/fonts/kenney_future.ttf"
const FONT_BODY := "res://ui/assets/fonts/poppins_medium.ttf"   # Poppins (OFL 1.1): Kenney Future ist nur Versalien, als Fließtext zu schwer lesbar

## Größenstufen (Sophie: Titel 24, Wert 18, Label 14; dazu 32 nur für den Startdialog)
const SIZE_HERO := 32
const SIZE_TITLE := 24
const SIZE_VALUE := 18
const SIZE_LABEL := 14

## Farb-Token. Kontrast (WCAG 2.x, gerechnet, nicht gemessen): ink/paper 13.6, muted/paper 6.0,
## ink/amber 9.9, cream/wood 10.2, cream_muted/wood 7.1, cream/danger 6.0.
const C := {
	"paper": Color("#F4EBD6"), "paper2": Color("#E8DCC0"), "paper3": Color("#DCCDAE"),
	"line": Color("#CDBB98"), "line_dark": Color("#B9A27F"),
	"ink": Color("#2A1F16"), "muted": Color("#6A5442"),
	"wood": Color("#4A3326"), "wood2": Color("#5E4231"), "wood3": Color("#7A5A44"),
	"cream": Color("#F8EFD9"), "cream_muted": Color("#D9C7A6"),
	"amber": Color("#FFC21A"), "amber_hover": Color("#FFD452"), "amber_press": Color("#E8A800"), "amber_edge": Color("#B98100"),
	"danger": Color("#A8392A"), "danger_hover": Color("#BF4634"), "danger_press": Color("#8E2F22"), "danger_edge": Color("#6E2016"),
	"disabled_bg": Color("#DDD2BA"), "disabled_fg": Color("#8A7A66"), "disabled_edge": Color("#C9BC9F"),
	"ok_text": Color("#24683F"), "warn_text": Color("#8F5300"), "bad_text": Color("#A8392A"),
	"saum": Color("#0F1720"),
	"status_ok": Color("#48E08A"), "status_warn": Color("#FFA640"), "status_bad": Color("#FF988A"),
	"callout": Color("#FFF1C7"),
}

static var _fonts := {}


static func font(path: String) -> Font:
	if _fonts.has(path):
		return _fonts[path]
	var f: FontFile = null
	if ResourceLoader.exists(path):
		f = load(path)
	else:
		f = FontFile.new()
		f.load_dynamic_font(path)
	f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	f.hinting = TextServer.HINTING_LIGHT
	f.allow_system_fallback = true
	_fonts[path] = f
	return f


static func sb(bg: Color, radius := 8, border := 0, border_col := Color.TRANSPARENT, margin := Vector4(12, 8, 12, 8)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.set_border_width_all(border)
	s.border_color = border_col
	s.content_margin_left = margin.x
	s.content_margin_top = margin.y
	s.content_margin_right = margin.z
	s.content_margin_bottom = margin.w
	s.anti_aliasing = true
	s.corner_detail = 8
	return s


static func _shadow(s: StyleBoxFlat, size := 12, alpha := 0.32, offset := Vector2(0, 4)) -> StyleBoxFlat:
	s.shadow_color = Color(0.06, 0.04, 0.02, alpha)
	s.shadow_size = size
	s.shadow_offset = offset
	return s


## Knopf mit „Tiefe“ (Kenney depth-Look): unterer Rand dunkler; pressed = Rand weg, Inhalt 2 px tiefer.
static func _depth(bg: Color, edge: Color, radius: int, pressed := false, margin := Vector4(16, 8, 16, 8)) -> StyleBoxFlat:
	var s := sb(bg, radius, 0, edge, margin)
	s.border_width_bottom = 1 if pressed else 4
	s.border_color = edge
	if pressed:
		s.content_margin_top = margin.y + 3
		s.content_margin_bottom = margin.w
	return s


static func _button_type(t: Theme, type: String, normal: StyleBox, hover: StyleBox, pressed: StyleBox, disabled: StyleBox,
		fg: Color, fg_hover: Color, fg_pressed: Color, size := SIZE_VALUE, fnt := FONT_TITLE) -> void:
	t.set_type_variation(type, "Button")
	t.set_stylebox("normal", type, normal)
	t.set_stylebox("hover", type, hover)
	t.set_stylebox("pressed", type, pressed)
	t.set_stylebox("hover_pressed", type, pressed)
	t.set_stylebox("disabled", type, disabled)
	t.set_stylebox("focus", type, StyleBoxEmpty.new())
	t.set_color("font_color", type, fg)
	t.set_color("font_hover_color", type, fg_hover)
	t.set_color("font_pressed_color", type, fg_pressed)
	t.set_color("font_hover_pressed_color", type, fg_pressed)
	t.set_color("font_focus_color", type, fg)
	t.set_color("font_disabled_color", type, C["disabled_fg"])
	t.set_color("icon_normal_color", type, fg)
	t.set_color("icon_hover_color", type, fg_hover)
	t.set_color("icon_pressed_color", type, fg_pressed)
	t.set_color("icon_hover_pressed_color", type, fg_pressed)
	t.set_color("icon_focus_color", type, fg)
	t.set_color("icon_disabled_color", type, C["disabled_fg"])
	t.set_font("font", type, font(fnt))
	t.set_font_size("font_size", type, size)
	t.set_constant("h_separation", type, 10)
	t.set_constant("icon_max_width", type, 28)
	t.set_constant("outline_size", type, 0)


static func _label_type(t: Theme, type: String, size: int, col: Color, fnt: String) -> void:
	t.set_type_variation(type, "Label")
	t.set_font("font", type, font(fnt))
	t.set_font_size("font_size", type, size)
	t.set_color("font_color", type, col)
	t.set_constant("outline_size", type, 0)


static func _panel_type(t: Theme, type: String, s: StyleBox) -> void:
	t.set_type_variation(type, "PanelContainer")
	t.set_stylebox("panel", type, s)


static func build() -> Theme:
	var t := Theme.new()
	t.default_font = font(FONT_BODY)
	t.default_font_size = SIZE_LABEL

	# ---------------- Labels (Typo-Hierarchie)
	t.set_font("font", "Label", font(FONT_BODY))
	t.set_font_size("font_size", "Label", SIZE_LABEL)
	t.set_color("font_color", "Label", C["ink"])
	t.set_constant("line_spacing", "Label", 2)
	_label_type(t, "LabelHero", SIZE_HERO, C["ink"], FONT_TITLE)
	_label_type(t, "LabelTitle", SIZE_TITLE, C["ink"], FONT_TITLE)
	_label_type(t, "LabelValue", SIZE_VALUE, C["ink"], FONT_TITLE)
	_label_type(t, "LabelBody", SIZE_VALUE, C["ink"], FONT_BODY)
	_label_type(t, "LabelMuted", SIZE_LABEL, C["muted"], FONT_BODY)
	_label_type(t, "LabelCaps", SIZE_LABEL, C["muted"], FONT_TITLE)
	_label_type(t, "LabelOk", SIZE_LABEL, C["ok_text"], FONT_BODY)
	_label_type(t, "LabelWarn", SIZE_LABEL, C["warn_text"], FONT_BODY)
	_label_type(t, "LabelBad", SIZE_LABEL, C["bad_text"], FONT_BODY)
	_label_type(t, "LabelWoodTitle", SIZE_TITLE, C["cream"], FONT_TITLE)
	_label_type(t, "LabelHud", SIZE_VALUE, C["cream"], FONT_TITLE)
	_label_type(t, "LabelHudSmall", SIZE_LABEL, C["cream_muted"], FONT_BODY)
	_label_type(t, "LabelBadge", SIZE_LABEL, C["cream"], FONT_TITLE)
	_label_type(t, "LabelToast", SIZE_VALUE, C["cream"], FONT_BODY)
	_label_type(t, "LabelNext", SIZE_LABEL, C["warn_text"], FONT_BODY)
	_label_type(t, "LabelHeroWood", SIZE_HERO, C["cream"], FONT_TITLE)
	_label_type(t, "LabelAmber", SIZE_LABEL, C["amber"], FONT_TITLE)

	# ---------------- Panels
	_panel_type(t, "PanelDock", _shadow(sb(Color(C["paper"], 0.97), 12, 1, C["line"], Vector4(0, 0, 0, 0)), 18, 0.35, Vector2(0, 6)))
	var head := sb(C["wood"], 12, 0, Color.TRANSPARENT, Vector4(16, 12, 10, 12))
	head.corner_radius_bottom_left = 0
	head.corner_radius_bottom_right = 0
	_panel_type(t, "PanelHeader", head)
	_panel_type(t, "PanelCard", _shadow(sb(Color(C["paper"], 0.95), 12, 1, C["line"], Vector4(16, 14, 16, 14)), 14, 0.30))
	var hud := sb(Color(C["wood"], 0.95), 0, 0, Color.TRANSPARENT, Vector4(16, 6, 16, 6))
	hud.border_width_bottom = 3
	hud.border_color = C["wood3"]
	_panel_type(t, "PanelHud", _shadow(hud, 10, 0.35, Vector2(0, 3)))
	_panel_type(t, "PanelToolbar", _shadow(sb(Color(C["wood"], 0.95), 14, 2, C["wood3"], Vector4(10, 10, 10, 10)), 14, 0.35))
	var lic := sb(C["paper2"], 8, 0, C["amber"], Vector4(14, 10, 12, 12))
	lic.border_width_left = 5
	_panel_type(t, "PanelLicence", lic)
	var cal := sb(C["callout"], 8, 0, C["amber_press"], Vector4(12, 8, 10, 10))
	cal.border_width_left = 4
	_panel_type(t, "PanelCallout", cal)
	_panel_type(t, "PanelToast", _shadow(sb(Color(C["wood"], 0.96), 22, 2, C["amber"], Vector4(20, 10, 22, 10)), 12, 0.35))
	_panel_type(t, "PanelHint", _shadow(sb(Color(C["wood"], 0.90), 16, 0, Color.TRANSPARENT, Vector4(16, 7, 16, 8)), 8, 0.25))
	_panel_type(t, "PanelBadge", sb(Color(C["ink"], 0.55), 5, 0, Color.TRANSPARENT, Vector4(5, 1, 5, 1)))
	_panel_type(t, "PanelChip", sb(Color(1, 1, 1, 0.07), 8, 0, Color.TRANSPARENT, Vector4(10, 4, 12, 4)))
	_panel_type(t, "PanelIconDisc", sb(C["amber"], 40, 3, C["amber_edge"], Vector4(14, 14, 14, 14)))
	_panel_type(t, "PanelBanner", _shadow(sb(Color(C["paper"], 0.97), 12, 3, C["danger"], Vector4(20, 16, 20, 16)), 16, 0.4))
	t.set_stylebox("panel", "PanelContainer", sb(Color(C["paper"], 0.95), 10, 1, C["line"]))

	# ---------------- Buttons
	var r := 8
	_button_type(t, "ButtonPrimary",
		_depth(C["amber"], C["amber_edge"], r), _depth(C["amber_hover"], C["amber_edge"], r),
		_depth(C["amber_press"], C["amber_edge"], r, true), _depth(C["disabled_bg"], C["disabled_edge"], r),
		C["ink"], C["ink"], C["ink"])
	var sec_n := _depth(C["paper2"], C["line_dark"], r)
	var sec_h := _depth(Color("#F3E7CB"), C["amber_edge"], r)
	var sec_p := _depth(C["paper3"], C["line_dark"], r, true)
	_button_type(t, "ButtonSecondary", sec_n, sec_h, sec_p, _depth(C["disabled_bg"], C["disabled_edge"], r),
		C["ink"], C["ink"], C["ink"], SIZE_LABEL)
	_button_type(t, "ButtonDanger",
		_depth(C["danger"], C["danger_edge"], r), _depth(C["danger_hover"], C["danger_edge"], r),
		_depth(C["danger_press"], C["danger_edge"], r, true), _depth(C["disabled_bg"], C["disabled_edge"], r),
		Color("#FFF6E8"), Color("#FFFFFF"), Color("#FFF6E8"), SIZE_LABEL)
	var gm := Vector4(10, 6, 10, 6)
	_button_type(t, "ButtonGhost", sb(Color(0, 0, 0, 0), 6, 0, Color.TRANSPARENT, gm), sb(Color(C["paper3"], 0.7), 6, 0, Color.TRANSPARENT, gm),
		sb(C["paper3"], 6, 0, Color.TRANSPARENT, gm), sb(Color(0, 0, 0, 0), 6, 0, Color.TRANSPARENT, gm),
		C["muted"], C["ink"], C["ink"], SIZE_LABEL, FONT_BODY)
	# Werkzeug (auf Holz): Toggle; gedrückt = aktives Werkzeug in Bernstein
	var tm := Vector4(10, 8, 10, 8)
	_button_type(t, "ButtonTool", sb(C["wood2"], 10, 2, C["wood3"], tm), sb(Color("#6E4F3A"), 10, 2, C["amber"], tm),
		sb(C["amber"], 10, 2, C["amber_edge"], tm), sb(Color(C["wood2"], 0.5), 10, 2, Color(C["wood3"], 0.5), tm),
		C["cream"], C["cream"], C["ink"], SIZE_LABEL)
	t.set_constant("icon_max_width", "ButtonTool", 34)
	var sm := Vector4(10, 5, 10, 5)
	_button_type(t, "ButtonTempo", sb(C["wood2"], 6, 1, C["wood3"], sm), sb(Color("#6E4F3A"), 6, 1, C["amber"], sm),
		sb(C["amber"], 6, 1, C["amber_edge"], sm), sb(Color(C["wood2"], 0.45), 6, 1, Color(C["wood3"], 0.4), sm),
		C["cream"], C["cream"], C["ink"], SIZE_LABEL)
	t.set_constant("icon_max_width", "ButtonTempo", 18)
	var cm := Vector4(6, 6, 6, 6)
	_button_type(t, "ButtonClose", sb(Color(0, 0, 0, 0), 6, 0, Color.TRANSPARENT, cm), sb(Color(1, 1, 1, 0.16), 6, 0, Color.TRANSPARENT, cm),
		sb(Color(0, 0, 0, 0.25), 6, 0, Color.TRANSPARENT, cm), sb(Color(0, 0, 0, 0), 6, 0, Color.TRANSPARENT, cm),
		C["cream_muted"], C["cream"], C["cream"])
	t.set_constant("icon_max_width", "ButtonClose", 18)
	var tile_m := Vector4(18, 18, 18, 18)
	var tile_n := _shadow(sb(C["paper"], 14, 2, C["line"], tile_m), 8, 0.18, Vector2(0, 3))
	var tile_h := _shadow(sb(Color("#FFF8E6"), 14, 3, C["amber"], tile_m), 14, 0.28, Vector2(0, 5))
	var tile_p := sb(Color("#F1E3C3"), 14, 3, C["amber_press"], tile_m)
	_button_type(t, "ButtonTile", tile_n, tile_h, tile_p, sb(C["disabled_bg"], 14, 2, C["disabled_edge"], tile_m),
		C["ink"], C["ink"], C["ink"])
	var row_m := Vector4(8, 6, 8, 6)
	_button_type(t, "ButtonRow", sb(Color(0, 0, 0, 0), 6, 0, Color.TRANSPARENT, row_m), sb(Color(C["paper3"], 0.65), 6, 0, Color.TRANSPARENT, row_m),
		sb(C["paper3"], 6, 0, Color.TRANSPARENT, row_m), sb(Color(0, 0, 0, 0), 6, 0, Color.TRANSPARENT, row_m),
		C["ink"], C["ink"], C["ink"], SIZE_LABEL, FONT_BODY)
	var tab_m := Vector4(14, 6, 14, 6)
	var tab_n := sb(C["paper2"], 8, 0, Color.TRANSPARENT, tab_m)
	tab_n.corner_radius_bottom_left = 0
	tab_n.corner_radius_bottom_right = 0
	var tab_h := tab_n.duplicate()
	tab_h.bg_color = Color("#F3E7CB")
	var tab_p := tab_n.duplicate()
	tab_p.bg_color = C["paper"]
	tab_p.border_width_top = 3
	tab_p.border_color = C["amber"]
	var tab_d := tab_n.duplicate()
	tab_d.bg_color = C["disabled_bg"]
	_button_type(t, "ButtonTab", tab_n, tab_h, tab_p, tab_d, C["muted"], C["ink"], C["ink"], SIZE_LABEL)
	var chip_m := Vector4(12, 4, 12, 4)
	_button_type(t, "ButtonChip", sb(C["paper"], 14, 2, C["line_dark"], chip_m), sb(Color("#FFF8E6"), 14, 2, C["amber"], chip_m),
		sb(C["amber"], 14, 2, C["amber_edge"], chip_m), sb(C["disabled_bg"], 14, 2, C["disabled_edge"], chip_m),
		C["ink"], C["ink"], C["ink"], SIZE_LABEL, FONT_BODY)
	# Standard-Button = sekundär
	for k in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		t.set_stylebox(k, "Button", t.get_stylebox(k, "ButtonSecondary"))
	t.set_font("font", "Button", font(FONT_TITLE))
	t.set_font_size("font_size", "Button", SIZE_LABEL)
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		t.set_color(k, "Button", C["ink"])
	t.set_color("font_disabled_color", "Button", C["disabled_fg"])

	# ---------------- Fortschritt, Trenner, Tooltip
	t.set_stylebox("background", "ProgressBar", sb(C["paper3"], 5, 1, C["line_dark"], Vector4(0, 0, 0, 0)))
	t.set_stylebox("fill", "ProgressBar", sb(C["status_ok"], 5, 1, C["saum"], Vector4(0, 0, 0, 0)))
	t.set_type_variation("ProgressWarn", "ProgressBar")
	t.set_stylebox("fill", "ProgressWarn", sb(C["status_warn"], 5, 1, C["saum"], Vector4(0, 0, 0, 0)))
	t.set_font("font", "ProgressBar", font(FONT_BODY))
	t.set_font_size("font_size", "ProgressBar", SIZE_LABEL)
	var line := StyleBoxLine.new()
	line.color = C["line"]
	line.thickness = 2
	t.set_stylebox("separator", "HSeparator", line)
	t.set_constant("separation", "HSeparator", 14)
	t.set_stylebox("panel", "TooltipPanel", _shadow(sb(Color(C["wood"], 0.97), 8, 1, C["wood3"], Vector4(10, 6, 10, 7)), 8, 0.3))
	t.set_color("font_color", "TooltipLabel", C["cream"])
	t.set_font("font", "TooltipLabel", font(FONT_BODY))
	t.set_font_size("font_size", "TooltipLabel", SIZE_LABEL)
	t.set_constant("separation", "VBoxContainer", 6)
	t.set_constant("separation", "HBoxContainer", 8)
	return t
