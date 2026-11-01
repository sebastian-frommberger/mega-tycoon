extends RefCounted
## U-01 Komponenten-Fabrik: Icons (icons.json), Labels nach Typo-Stufe, Knöpfe nach Typ, Statusformen.
## Alle UI-Teile von main.gd und styleguide.gd entstehen hier, damit es nur eine Stelle für den Look gibt.

const TB := preload("res://ui/theme/theme_builder.gd")
const StatusShape := preload("res://ui/status_shape.gd")
const ICONS_JSON := "res://ui/icons.json"

static var _icon_map := {}
static var _icon_cache := {}


static func icon_tex(name: String) -> Texture2D:
	if _icon_cache.has(name):
		return _icon_cache[name]
	if _icon_map.is_empty():
		var f := FileAccess.open(ICONS_JSON, FileAccess.READ)
		if f:
			var d = JSON.parse_string(f.get_as_text())
			if d is Dictionary:
				_icon_map = d
	var entry: Dictionary = _icon_map.get("icons", {}).get(name, {})
	var tex: Texture2D = null
	if not entry.is_empty():
		var path: String = _icon_map.get("pfad", "res://ui/assets/icons/") + entry["datei"]
		if ResourceLoader.exists(path):
			tex = load(path)
		else:
			var img := Image.load_from_file(path)
			if img:
				img.generate_mipmaps()
				tex = ImageTexture.create_from_image(img)
	if tex == null:
		push_warning("Icon fehlt: " + name)
	_icon_cache[name] = tex
	return tex


static func icon(name: String, px := 20, col := Color.WHITE) -> TextureRect:
	var r := TextureRect.new()
	r.texture = icon_tex(name)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = Vector2(px, px)
	r.modulate = col
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return r


## Kenney-Schriften haben kein →, ●, ✔, –, ≈: hier auf vorhandene Zeichen abbilden.
static func txt(s: String) -> String:
	return s.replace("→", "›").replace("–", "—").replace("−", "-").replace("≈", "ca.").replace("✔ ", "").replace("⚠ ", "")


## D-07 BUG-3: Kenney Future hat kein × (zeigte „H“, auch ein „x“ sieht dort aus wie H). Steht ein × im Text eines Knopfes oder
## Kenney-Labels, setzt dieses Control stattdessen Poppins (hat ×) als Schrift; sonst bleibt alles im Theme.
const KENNEY_LABEL_TYPES := ["LabelHero", "LabelTitle", "LabelValue", "LabelCaps", "LabelWoodTitle", "LabelHud", "LabelBadge", "LabelHeroWood", "LabelAmber"]

static func txt_kenney(s: String) -> String:
	return txt(s)


## S6 B-7: „HQ“ liest sich in Kenney Future wie „HO“, daher auch dort Poppins.
static func glyph_font(c: Control, s: String) -> void:
	if s.contains("×") or s.contains("HQ"):
		c.add_theme_font_override("font", TB.font(TB.FONT_BODY))


static func label(text: String, type := "", wrap := false) -> Label:
	var l := Label.new()
	l.text = txt(text)
	if type in KENNEY_LABEL_TYPES:
		glyph_font(l, l.text)
	if type != "":
		l.theme_type_variation = type
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func button(text: String, type := "ButtonSecondary", icon_name := "", cb := Callable()) -> Button:
	var b := Button.new()
	b.text = txt(text)
	glyph_font(b, b.text)
	b.theme_type_variation = type
	b.focus_mode = Control.FOCUS_NONE
	if icon_name != "":
		b.icon = icon_tex(icon_name)
		b.expand_icon = false
	if cb.is_valid():
		b.pressed.connect(cb)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if type == "ButtonClose":
		b.custom_minimum_size = Vector2(32, 32)       # D-07 BUG-6: Schließen-X Klickziel >= 24 px (32 px)
	return b


## Primärknopf mit zwei Zeilen (Aktion + Preis in Kenney Future 18, Nutzen in Poppins 14), z. B. Lizenzknopf.
## Button.text trägt die volle Aussage (Tests, Tooltip, Barrierefreiheit), gezeichnet wird der Inhalt.
static func price_button(icon_name: String, l1: String, l2: String, cb := Callable()) -> Button:
	var b := button("", "ButtonPrimary", "", cb)
	b.custom_minimum_size = Vector2(0, 62)
	b.clip_text = true
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color", "font_disabled_color"]:
		b.add_theme_color_override(k, Color(0, 0, 0, 0))
	var m := margin(16, 8, 14, 10)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	b.add_child(m)
	var ic := icon(icon_name, 28, TB.C["ink"])
	var a := label("", "LabelValue")
	var c := label("", "")
	var v := vbox(0, [a, c])
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	m.add_child(hbox(12, [ic, v]))
	b.set_meta("pb", [ic, a, c])
	set_price_button(b, icon_name, l1, l2, false)
	return b


static func set_price_button(b: Button, icon_name: String, l1: String, l2: String, disabled: bool) -> void:
	var parts: Array = b.get_meta("pb")
	b.disabled = disabled
	b.text = txt(l1 + "\n" + l2)
	parts[0].texture = icon_tex(icon_name)
	parts[1].text = txt(l1)
	glyph_font(parts[1], parts[1].text)
	parts[2].text = txt(l2)
	var col: Color = TB.C["disabled_price"] if disabled else TB.C["ink"]
	parts[0].modulate = col
	parts[1].add_theme_color_override("font_color", col)
	parts[2].add_theme_color_override("font_color", col)
	# D-07 BUG-5: Knopf wächst mit dem Inhalt (Icon 28 + 12 + Ränder 30 + Luft), ragt nie aus der Fläche
	var f := TB.font(TB.FONT_TITLE)
	var need := 28.0 + 12.0 + 30.0 + 6.0 + maxf(f.get_string_size(parts[1].text, HORIZONTAL_ALIGNMENT_LEFT, -1, TB.SIZE_VALUE).x, TB.font(TB.FONT_BODY).get_string_size(parts[2].text, HORIZONTAL_ALIGNMENT_LEFT, -1, TB.SIZE_LABEL).x)
	b.custom_minimum_size.x = maxf(b.custom_minimum_size.x, need)


static func status(kind: String, px := 14) -> Control:
	return StatusShape.new(kind, px)


static func hbox(sep := 8, children: Array = []) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in children:
		h.add_child(c)
	return h


static func vbox(sep := 6, children: Array = []) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in children:
		v.add_child(c)
	return v


static func panel(type: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.theme_type_variation = type
	return p


static func margin(l: int, t: int, r: int, b: int) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", l)
	m.add_theme_constant_override("margin_top", t)
	m.add_theme_constant_override("margin_right", r)
	m.add_theme_constant_override("margin_bottom", b)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return m


static func spacer() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


## Hotkey-Plakette („1“, „X“) für Werkzeugknöpfe.
static func badge(text: String) -> PanelContainer:
	var p := panel("PanelBadge")
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := label(text, "LabelBadge")
	l.add_theme_font_size_override("font_size", 11)
	p.add_child(l)
	return p


## Ein Knopf zeigt für den Styleguide dauerhaft einen Zustand (normal/hover/pressed/disabled).
static func force_state(b: Button, state: String, th: Theme) -> void:
	var type: String = b.theme_type_variation if b.theme_type_variation != "" else "Button"
	match state:
		"disabled":
			b.disabled = true
			if b.has_meta("pb"):
				set_price_button(b, "lizenz", (b.get_meta("pb")[1] as Label).text, (b.get_meta("pb")[2] as Label).text, true)
			elif b.get_child_count() > 0:
				b.modulate = Color(1, 1, 1, 0.6)     # Knöpfe mit eigenem Inhalt (Kachel, Zeile) sichtbar dämpfen
		"hover", "pressed":
			var key := "hover" if state == "hover" else "pressed"
			var sbx: StyleBox = th.get_stylebox(key, type)
			b.add_theme_stylebox_override("normal", sbx)
			b.add_theme_stylebox_override("hover", sbx)
			b.add_theme_stylebox_override("pressed", sbx)
			var col_key := "font_hover_color" if state == "hover" else "font_pressed_color"
			var col: Color = th.get_color(col_key, type)
			if not b.has_meta("pb"):          # D-07 BUG-5: Preisknopf zeichnet Text über eigene Labels; Button.text bleibt unsichtbar (sonst doppelt)
				for k in ["font_color", "font_hover_color", "font_pressed_color"]:
					b.add_theme_color_override(k, col)
			for k in ["icon_normal_color", "icon_hover_color", "icon_pressed_color"]:
				b.add_theme_color_override(k, col)
