extends Control
## Startmenü (Basti, S7): Projekt-Hauptszene vor main.tscn. Zwei Karten: „Neues Spiel“ (HQ frei platzieren wie bisher)
## und „Beispielnetz ansehen“ (laufendes Netz, world/beispielnetz.gd). Modus geht über Main.start_mode an main.gd.
## Tasten: 1 / 2 wählen und starten, Enter startet die markierte Karte, W wechselt die Welt (slice ↔ s7).
## Kein Dialog (D21), alles im Theme (ui/theme) und UI-Kit (ui/ui_kit.gd).
## Ohne Menü: Tests laden main.tscn bzw. laufen mit -s (sehen dieses Menü nie); Bench (Feature „bench“ oder --bench)
## und --modus=neu|beispiel springen direkt ins Spiel. --welt=s7 wählt die Welt vor (Menü zeigt sie unten an).

const MainScript := preload("res://main.gd")
const WorldSel := preload("res://world/welt.gd")
const ThemeBuilder := preload("res://ui/theme/theme_builder.gd")
const Kit := preload("res://ui/ui_kit.gd")
const MAIN := "res://main.tscn"
const KARTEN := [
	["neu", "1", "Neues Spiel", "Gründe dein Unternehmen, wo du willst.", "hq"],
	["beispiel", "2", "Beispielnetz ansehen", "Ein laufendes Netz: sieh, wie Farm, Mühle und Stadt zusammenhängen.", "lkw"],
]

var welt := ""
var markiert := 0
var karten: Array = []          # Button je Karte
var welt_label: Label


func _ready() -> void:
	var args := OS.get_cmdline_user_args() + OS.get_cmdline_args()
	welt = WorldSel.pick(MainScript.world_override, args)
	var direkt := ""
	if OS.has_feature("bench") or args.has("--bench"):
		direkt = "neu"
	for a in args:
		if a == "--modus=neu" or a == "--modus=beispiel":
			direkt = a.substr(8)
	if direkt != "":
		starte.call_deferred(direkt)
		return
	_baue()


func _baue() -> void:
	theme = ThemeBuilder.build()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = ThemeBuilder.C["wood"]
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var col := Kit.vbox(28)
	center.add_child(col)
	var titel := Kit.label("MEGA TYCOON", "LabelHero")
	titel.add_theme_color_override("font_color", ThemeBuilder.C["amber"])
	titel.add_theme_font_size_override("font_size", 48)
	titel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(titel)
	var reihe := Kit.hbox(24)
	reihe.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(reihe)
	for i in KARTEN.size():
		var k: Array = KARTEN[i]
		var b := Button.new()
		b.name = "Karte_" + k[0]
		b.theme_type_variation = "ButtonTile"
		b.custom_minimum_size = Vector2(470, 190)
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.tooltip_text = "%s (Taste %s)" % [k[2], k[1]]
		b.pressed.connect(starte.bind(k[0]))
		b.mouse_entered.connect(func(): _markiere(i))
		var inhalt := Kit.vbox(10, [
			Kit.hbox(10, [Kit.icon(k[4], 32, ThemeBuilder.C["amber_edge"]), Kit.label(k[2], "LabelTitle")]),
			Kit.label(k[3], "LabelBody", true),
			Kit.label("Taste %s" % k[1], "LabelMuted"),
		])
		var rand := Kit.margin(22, 20, 22, 18)
		rand.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		rand.add_child(inhalt)
		_maus_durch(rand)
		b.add_child(rand)
		reihe.add_child(b)
		karten.append(b)
	welt_label = Kit.label("", "LabelMuted")
	welt_label.add_theme_color_override("font_color", ThemeBuilder.C["cream_muted"])
	welt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(welt_label)
	_zeige_welt()
	_markiere(0)


func _maus_durch(n: Node) -> void:
	if n is Control:
		(n as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in n.get_children():
		_maus_durch(c)


func _zeige_welt() -> void:
	var nm := "Slice (Standard)" if welt == "slice" else "S7 (neue Karte, 1 Feld = 25 m)"
	welt_label.text = "Welt: %s  ·  W wechselt  ·  Start mit Argument -- --welt=s7 wählt S7 vor" % nm


## Markierte Karte (Enter) hervorheben: gleiche Darstellung wie Hover (amber Rand).
func _markiere(i: int) -> void:
	markiert = i
	for j in karten.size():
		var b: Button = karten[j]
		if j == i:
			b.add_theme_stylebox_override("normal", b.get_theme_stylebox("hover"))
		else:
			b.remove_theme_stylebox_override("normal")


func _unhandled_input(ev: InputEvent) -> void:
	if not (ev is InputEventKey) or not ev.pressed or ev.echo or karten.is_empty():
		return
	if not ev.keycode in [KEY_1, KEY_KP_1, KEY_2, KEY_KP_2, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_LEFT, KEY_RIGHT, KEY_TAB, KEY_W]:
		return
	get_viewport().set_input_as_handled()      # vor starte(): danach ist das Menü nicht mehr im Baum
	match ev.keycode:
		KEY_1, KEY_KP_1:
			starte("neu")
		KEY_2, KEY_KP_2:
			starte("beispiel")
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			starte(KARTEN[markiert][0])
		KEY_LEFT, KEY_RIGHT, KEY_TAB:
			_markiere(1 - markiert)
		KEY_W:
			welt = "s7" if welt == "slice" else "slice"
			_zeige_welt()


## Modus an main.gd übergeben und die Spielszene laden. Die Welt geht über Main.world_override (wie in den Tests).
func starte(modus: String) -> void:
	MainScript.start_mode = modus
	MainScript.world_override = welt
	get_tree().change_scene_to_file(MAIN)
