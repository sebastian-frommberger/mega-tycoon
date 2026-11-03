---
name: mt-gameplay-ui-dev
description: Fach- und Projektwissen für Mira, Gameplay- und UI-Entwicklerin von Mega Tycoon (Godot 4.7.2, GDScript). Verwenden bei Eingabe, UI in Code, Theme, Skalierung, Weltschilder, Tooltips, Texten, Tweens, Picking und UI-Tests im Repo mega-tycoon.
---

# Mira, Gameplay und UI: Fortbildungsstand 03.11.2026

Kennzeichen der Belegstärke: [K] Konsens mehrerer Quellen, [S] Streit oder Doku widersprüchlich, [E] Einzelquelle, [V] eigener Versuch mit Godot 4.7.2 (Skripte im Scratchpad, nicht im Repo), [R] aus dem Repo belegt. Quellen am Ende von Teil A.
Ehrlich vorweg: Reddit war nicht lesbar (WebFetch SITE_BLOCKED, Suche mit Domainfilter Proxy-Fehler), es steht hier kein Reddit-Wissen. Ersatz: Godot-Doku, Forum, GitHub, Microsoft-Xbox-Leitfaden, Transport-Fever-Devblog. GDC-"Juice It or Lose It" war nur als dünne, nicht frei lesbare Seite erreichbar und wird hier nicht zitiert.

---------------------------------------------------------------------------------------------------
# TEIL A: Allgemeines Fachwissen
---------------------------------------------------------------------------------------------------

## A1 Prinzipien (Reihenfolge = Wichtigkeit für ein Aufbauspiel mit Maus und Tastatur)

1. **Jede Ablehnung nennt Ursache und Lösung, in der Sprache der Spielenden.** Kein Fehlercode, kein "Aktion nicht möglich". Muster: "Zu wenig Geld: dir fehlen 1.200 $." Das ist Projektregel (FT in `ui/fehlertexte.gd`) und in jedem Tycoon Standard. [K, Praxis; keine Zahlenquelle]
2. **Zeige die begrenzende Größe, nicht nur das Ergebnis.** Transport Fever 3 (Devblog zum Tycoon-Modus) beschreibt Ebenen, Vorbelegungen und die Anzeige, was eine Linie limitiert. [E, Q41, Preview-Quelle, keine Messung] Für uns: Ein Fahrzeug, das steht, bekommt den Grund am Fahrzeug (Deadlock, kein Gut, kein Geld), nicht in einer Log-Zeile.
3. **UI hat eine Eingabereihenfolge, und die entscheidet über "Klick geht verloren".** Reihenfolge: `_input`, dann GUI (Control, `mouse_filter`), dann `_shortcut_input`, `_unhandled_key_input`, `_unhandled_input`. Spielwelt-Klicks gehören nach `_unhandled_input`, damit Panels sie schlucken können. [K, Q35] `mouse_filter` hat drei Werte: STOP (Standard bei Button, Panel; schluckt), PASS (reicht weiter, nachdem das Control es gesehen hat), IGNORE (unsichtbar für die Maus). Reine Layout-Container und Overlays, die nicht klicken sollen, auf IGNORE. Ein PanelContainer mit STOP über der Welt ist die häufigste Ursache "Welt reagiert nicht".
4. **Aktionen statt Tastencodes.** InputMap-Aktionen mit `physical_keycode` (Position, layoutunabhängig) für WASD/Steuerung, `keycode` für Zeichen-Kürzel. Doku-Linie [K, Q35]. Rohe `KEY_*`-Abfragen sind lauffähig, aber nicht umbelegbar und nicht prüfbar.
5. **Controls berechnen ihre Größe verzögert.** Container sortieren Kinder am Ende des Frames. Wer direkt nach `add_child` `size` oder `get_minimum_size()` liest, kann Zwischenwerte sehen. In 4.7.2 [V] war die Größe in meinem Test (verschachtelte Container) sofort richtig, der Forumsbericht (4.2.1, Q45) ließ sich für Container nicht reproduzieren. Regel: `await get_tree().process_frame` oder `resized`/`minimum_size_changed` nutzen, wenn danach positioniert wird (Toast, Tooltip, Schild). Keinen Fehler behaupten, den ich nicht reproduzieren konnte.
6. **Skalierung ist eine Entscheidung, nicht ein Haken.** `stretch/mode`: `disabled` (Pixel gleich, UI klein bei hoher Auflösung), `canvas_items` (UI skaliert mit, Text bleibt scharf, vektorfreundlich), `viewport` (Pixelkunst). `aspect expand` gibt mehr Platz statt Balken. Die Doku gibt keine feste Empfehlung für UI-lastige 3D-Spiele [S, Q36]. Bei `canvas_items` bleibt 3D unberührt und scharf, Schriftgröße in Pixeln bezieht sich auf die Basisauflösung (hier 1600 x 900).
7. **Kleinste Schrift ist eine Zugänglichkeitsfrage.** Microsoft Xbox Accessibility Guideline 101: PC mit 1080p mindestens 18 px Fließtext-Höhe, Skalierung bis 200 % anbieten [E aber offizielle Leitlinie, Q40]. Achtung: gemessen als Textkörperhöhe auf der Zielauflösung, nicht gleich `font_size` in Godot. Unser `MIN_FONT_PX = 12` bei Fensterhöhe 900 liegt wahrscheinlich darunter (nicht direkt vergleichbar, offen, C2).
8. **Kontrast wird gerechnet, nicht geschätzt.** WCAG-Verhältnis (L1+0,05)/(L2+0,05) mit relativer Luminanz; Fließtext 4,5:1, großer Text und Bedienelemente 3:1 (WCAG 2.x, Normwissen). Deaktiviert ist ausgenommen, aber kontrastarm = "kaputt" für Spielende; Repo: Primärknopf von 2,8:1 auf 4,8:1 gehoben, allgemeiner Disabled-Stil rechnerisch 2,77:1.
9. **Animationen unterbrechen sich selbst.** Vor jedem neuen Tween den alten töten. Nie `await tween.finished` auf einem Tween, der gekillt werden kann: die Coroutine läuft nie weiter [V, Q43]. Callback (`tween_callback` oder `finished.connect`) statt `await`.
10. **Zeitabhängiges UI nie mit Wanduhr testen.** Nach Physik-Frames zählen (Repo-Erfahrung S6: 0,35 s Wanduhr ergab 0 Ticks unter xvfb).
11. **Fokus-Navigation ist Pflicht, sobald jemand ohne Maus spielt.** Controls bekommen Fokus nur mit `focus_mode` (ALL für Buttons); `grab_focus()` setzt den Start; Nachbarn über `focus_neighbor_*` oder automatisch nach Lage [K, Q39]. Das Spiel ist heute Maus plus Tastatur; Fokus ist ein bekannter Rest.
12. **Lokalisierung vorbereiten, auch wenn nur Deutsch ausgeliefert wird.** `tr()` mit Schlüssel, benannte Platzhalter (`"{n} Fahrzeuge"` mit `.format({"n": x})`, nie `%s`-Reihenfolge), Pluralformen über `tr_n`, `auto_translate_mode` für Controls [K, Q42]. Für uns heute Festtext in `FT`; die Reihenfolge-Falle ist der echte Gewinn.

## A2 Godot-4.7-Muster (alle: `--check-only` grün; markierte Läufe geprüft [V])

**Eingabe: InputMap im Code, Welt-Eingabe in `_unhandled_input`**
```gdscript
func _ready() -> void:
	_aktion("kamera_links", KEY_A)
func _aktion(name: StringName, taste: Key) -> void:
	if not InputMap.has_action(name):
		InputMap.add_action(name)
		var e := InputEventKey.new()
		e.physical_keycode = taste
		InputMap.action_add_event(name, e)
func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		_welt_klick(ev.position)
		get_viewport().set_input_as_handled()
```
**Vollbild: Fenstermodus setzen, nicht `OS.window_fullscreen`** (Godot 3). Randlos: `Window.MODE_FULLSCREEN`; exklusiv: `Window.MODE_EXCLUSIVE_FULLSCREEN` (Doku: für ganzzahlige Skalierung exklusiv, Q36)
```gdscript
var w := get_window()
w.mode = Window.MODE_WINDOWED if w.mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
```
**Weltschild als Bildschirm-Overlay** (Pixelgröße unabhängig von Entfernung; FOV-Korrektur im Repo über `label_kscale`)
```gdscript
var cam := get_viewport().get_camera_3d()
if cam.is_position_behind(pos):
	lbl.visible = false; return
var p := cam.unproject_position(pos)
var vr := get_viewport().get_visible_rect()
p = p.clamp(vr.position + Vector2(RAND_PX, RAND_PX), vr.end - lbl.size - Vector2(RAND_PX, RAND_PX))
lbl.position = p - lbl.size * 0.5
```
Declutter: Liste belegter `Rect2`; ein Schild wird nur gezeichnet, wenn `rect.intersects(b)` für kein belegtes `b` gilt, Priorität nach Wichtigkeit sortiert, Hysterese gegen Flackern (8 % im Repo). Wichtig: `get_visible_rect()` unter `--headless` ist 1600 x 1600 bei `canvas_items + expand` und das Fenster 64 x 64 [V]; Tests auf Position/Größe nur unter xvfb.
**Theme-Variante in Code, Fokus sichtbar**
```gdscript
var t := Theme.new()
t.set_type_variation("PrimaerButton", "Button")           # Kind-Typ erbt von Button
var sb := StyleBoxFlat.new(); sb.bg_color = Color("#2f6b4f"); sb.set_corner_radius_all(6)
t.set_stylebox("normal", "PrimaerButton", sb)
var fokus := sb.duplicate() as StyleBoxFlat; fokus.border_color = Color.WHITE; fokus.set_border_width_all(2)
t.set_stylebox("focus", "PrimaerButton", fokus)
btn.theme_type_variation = &"PrimaerButton"; btn.focus_mode = Control.FOCUS_ALL
```
**Tween mit Abbruch des Vorgängers, Callback statt await** [V]
```gdscript
var _tw: Tween
func zeige(c: Control) -> void:
	if _tw: _tw.kill()
	_tw = create_tween()
	_tw.tween_property(c, "modulate:a", 1.0, 0.15)
	_tw.tween_callback(func(): c.mouse_filter = Control.MOUSE_FILTER_STOP)
```
**Text mit benannten Platzhaltern und Geld in Cent** [V: 123456700 ergibt "1.234.567 $", -370000 ergibt "-3.700 $", -37 Cent ergibt "0 $" (Rundung auf ganze Dollar, kein Minus)]
```gdscript
func geld(cent: int) -> String:
	var d := roundi(float(cent) / 100.0)
	var s := str(absi(d))
	var out := ""
	for i in s.length():
		if i > 0 and (s.length() - i) % 3 == 0:
			out += "."
		out += s[i]
	return ("-" if d < 0 else "") + out + " $"
var text := "Dir fehlen {fehlt}.".format({"fehlt": geld(fehlt_cent)})
```
**Declutter und Stufen mit Hysterese** [V: Lauf gegen die Prozentwerte aus `proto_schilder.gd`]
```gdscript
func stufe(alt: int, m: float) -> int:       # 0 Fern, 1 Voll, 2 Nah
	var fern := 1500.0 * (0.92 if alt == 0 else 1.0 + (0.08 if alt == 1 else 0.0))
	var nah := 400.0 * (1.08 if alt == 2 else 1.0 - (0.08 if alt == 1 else 0.0))
	return 0 if m >= fern else (2 if m < nah else 1)
func frei(r: Rect2, belegt: Array[Rect2]) -> bool:
	for b in belegt:
		if r.intersects(b): return false
	return true
```
**Picking auf Gelände statt Ebene y=0** (ray-march; Ebene allein trifft Berge falsch) [V]
```gdscript
func pick_terrain(cam: Camera3D, sp: Vector2, hoehe: Callable) -> Vector3:
	var o := cam.project_ray_origin(sp); var d := cam.project_ray_normal(sp)
	var t := 0.0
	while t < 6000.0:
		var p := o + d * t
		if p.y <= hoehe.call(p.x, p.z):
			return p                       # danach 5 Schritte Intervall halbieren für Genauigkeit
		t += 4.0
	return Vector3.INF
```
**Test unter xvfb mit echter Maus** (Repo-Muster `tests/d08_maus.gd`, `tools/play.sh`): Zeiger per `warp_mouse` auf die per Kamera projizierte Zielposition setzen, Mausereignis per `push_input` einspeisen, 2 Frames warten, Zustand prüfen (Beschreibung: `sprints/s6/block-c/daniel.md` Z.27). Kein `Button.pressed.emit()` als Ersatz, sonst wird `mouse_filter` nie geprüft. Headless hat keine Mausposition.

## A3 Schwellwerte und Verhalten

| Aussage | Wert | Beleg |
|---|---|---|
| Reihenfolge der Eingabe | `_input`, GUI, `_shortcut_input`, `_unhandled_key_input`, `_unhandled_input` | Q35 |
| mouse_filter | STOP / PASS / IGNORE; STOP ist Standard der meisten Controls | Q35, Q37 |
| Mindestgröße Fließtext PC | 18 px (1080p), Skalierung bis 200 % | Q40 [E] |
| Kontrast | 4,5:1 normal, 3:1 groß/Bedienelement | WCAG 2.x [K] |
| Container | Kinder werden vom Container positioniert; eigene `position` am Kind wird überschrieben; Größen-Flags `SIZE_EXPAND`/`SIZE_FILL`, `custom_minimum_size` | Q37 |
| Theme-Variation | Typ mit Basistyp, in Theme-Editor/Code; nicht an Instanz kopieren | Q38 |
| Fokus | `grab_focus` nötig, sonst kein Startfokus; Tab/Pfeile/Enter | Q39 |
| Skalierung | `canvas_items` skaliert UI mit Fenstergröße; HiDPI: kleines Startfenster ist bekannter Fallstrick | Q36 |
| Vollbild | MODE_FULLSCREEN randlos; MODE_EXCLUSIVE_FULLSCREEN für Integer-Scaling | Q36, [V] kompiliert |
| Headless | Fenster 64 x 64; visible_rect 1600 x 1600 bei expand; unter xvfb 1600 x 900 | [V] |
| Tween | `await tween.finished` nach `kill()` hängt ewig; `create_tween` bindet an den Knoten | Q43, [V] |
| Screenreader (4.5+) | AccessKit-Unterstützung für Controls, experimentell | Q34 [E] |
| Übersetzung | benannte Platzhalter, `tr_n`, `auto_translate_mode` | Q42 |

## A4 Godot-3-Rückfälle speziell für UI
`rect_position/rect_size/rect_min_size` -> `position/size/custom_minimum_size`; `margin_*` -> `offset_*`; `add_constant_override` -> `add_theme_constant_override`; `add_color_override` -> `add_theme_color_override`; `get_stylebox` -> `get_theme_stylebox`; `connect("pressed", self, "_f")` -> `pressed.connect(_f)`; `yield(get_tree().create_timer(1), "timeout")` -> `await get_tree().create_timer(1.0).timeout`; `Tween` als Knoten -> `create_tween()`; `focus_mode` Werte jetzt `Control.FOCUS_ALL`; `Control.grow_horizontal` statt Anchor-Rechnung in `_process`; `OS.window_size` -> `get_window().size`; `Input.is_action_just_pressed` bleibt. Kontrolle immer `godot --headless --check-only`, dazu Laufzeit-Smoke (check-only übersieht `Tween.new().interpolate_property` und `get_tree().change_scene`, [V]).

## A5 Checklisten
**Neues Panel**: (1) Wurzel `mouse_filter` bewusst, (2) Größen über `custom_minimum_size` und Container, nicht über Pixelpositionen, (3) Fokus-Start und Reihenfolge, (4) alle Texte aus FT/Konstanten mit Platzhaltern, du-Form, Ursache plus Lösung, (5) Kontrast aller Zustände (normal, hover, pressed, disabled, focus) gerechnet, (6) Tween töten beim Schließen, (7) Esc schließt, Rechtsklick bricht ab, (8) Test mit echter Maus unter xvfb.
**Schild/Marker**: Tiers (Fern, Voll, Nah) mit Hysterese, Rand-Klemme, Declutter, Mindestschrift, Skalierung mit Fensterhöhe, `visible=false` hinter der Kamera.
**Ablehnung/Toast**: Text 90 Zeichen max, Ursache plus Lösung, Dauer an Textlänge koppeln, ein Toast zur Zeit (Queue wäre Ausbau), nach Neu-Messung positionieren.
**Eingabe**: Aktion, nicht Taste; `_unhandled_input`; `set_input_as_handled()` nur wenn wirklich verbraucht; Text-Eingabefelder nehmen Tasten zuerst, also Kürzel prüfen, ob ein LineEdit Fokus hat.
**Vor Abgabe**: `--check-only`, Suite, Screenshot unter xvfb (1600 x 900 und 1280 x 720), Auflösungstest bei 3840 x 2160 wenn möglich.

## A7 Skalierungsrechnung (eigener Versuch unter xvfb, Projekt 1600 x 900, `canvas_items` + `expand`) [V]
| Fenster | `get_visible_rect()` | Stretch-Faktor | Folge |
|---|---|---|---|
| 1920 x 1080 | 1600 x 900 | 1,2 | alle Canvas-Pixel werden 1,2-fach gezeichnet |
| 1600 x 1000 (16:10) | 1600 x 1000 | 1,0 | mehr Platz in der Höhe, kein Zoom |
| 2560 x 1080 (21:9) | 2133 x 900 | 1,2 | mehr Platz in der Breite |
Daraus folgt (eigene Rechnung, keine Quelle): Schriftgrößen im Theme (14/18/24/32) sind Canvas-Pixel. Reale Höhe bei 1080p: 16,8 / 21,6 / 28,8 / 38,4 px. Xbox-Leitwert 18 px bei 1080p entspricht also 15 Canvas-Pixeln. `MIN_FONT_PX = 12` ergibt bei 1080p reale 14,4 px, bei 900p 12 px, also unter dem Leitwert (Maß nicht identisch, C2). Wer eine UI-Skalierung 100 bis 200 % anbieten will, setzt `get_tree().root.content_scale_factor` (Eigenschaft in 4.7.2 gesetzt und gelesen: 1,5 [V], Wirkung auf unser Layout nicht geprüft) statt Schriftgrößen einzeln zu ändern.
Achtung Schilder: `_scale = clampf(vp.y / 900.0, 0.85, 1.5)` (`proto_schilder.gd:479`) liest `get_visible_rect()` in Canvas-Pixeln. Das ist bei 16:9 immer 900, also 1,0, egal ob 900p oder 4K; die echte Auflösungsskalierung macht der Stretch. Der Faktor wirkt nur bei anderem Seitenverhältnis (16:10 ergibt 1,11). Der Kommentar "wächst mit der Auflösung" im Kopf der Datei ist damit nur für das Seitenverhältnis richtig [Eigenrechnung, zu bestätigen mit Screenshot bei 4K].

## A6 Quellen
Q15 https://docs.godotengine.org/en/stable/tutorials/physics/interpolation/physics_interpolation_introduction.html
Q34 https://godotengine.org/releases/4.5/ (AccessKit, experimentell)
Q35 https://docs.godotengine.org/en/stable/tutorials/inputs/inputevent.html (offiziell, Reihenfolge und mouse_filter)
Q36 https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html (keine feste Empfehlung für UI-lastige 3D)
Q37 https://docs.godotengine.org/en/stable/tutorials/ui/gui_containers.html
Q38 https://docs.godotengine.org/en/stable/tutorials/ui/gui_theme_type_variations.html
Q39 https://docs.godotengine.org/en/stable/tutorials/ui/gui_navigation.html
Q40 https://devdocs.xbox.com/build/game-principles/accessibility/xag-deep-dives/xag-101-text-display.md (18 px, 200 %, anderes Maß als font_size)
Q41 https://www.transportfever3.com/news/dev-blog-episode-4-tycoon/ (Einzelquelle, Vorschau)
Q42 https://docs.godotengine.org/en/stable/tutorials/i18n/internationalizing_games.html
Q43 https://forum.godotengine.org/t/coroutines-hangs-on-tween-finished-if-tween-kill-is-called/131958 (Godot 4.5.1, bestätigt durch Eigenversuch)
Q45 Forum-Thread zur Control-Größe nach add_child (nur Frage sichtbar, nicht belastbar)
Q44 https://gdcvault.com/play/1016487/Juice-It-or-Lose (dünn, Mitgliederinhalt; nicht verwertet)
Zusätzlich geteilt mit Felix: Q22 (Kommandozeile), Q23 bis Q26.

---------------------------------------------------------------------------------------------------
# TEIL B: Wissen für Mega Tycoon (nur Belegtes, Datei in Klammern; Repo: /home/claude/mega-tycoon)
---------------------------------------------------------------------------------------------------

## B1 UI-Architektur
- **Alles in Code gebaut**, keine .tscn-UI-Szenen für Spielpanels: `ui/ui_kit.gd` (Fabrik für Buttons, Panels, Labels), `ui/theme/theme_builder.gd` (Theme in Code: 2 Fonts, 4 Größen 32/24/18/14, Farb-Tokens, Kontrastwerte), `ui/ui_fx.gd` (Hover 0,10 s, Slide 0,15 s; hängt sich über `node_added`-Hook an neue Knoten), `ui/fehlertexte.gd` (Klasse FT: Texte max 90 Zeichen, Ursache plus Lösung, du-Form).
- **Fachpanels**: `bankrott_warnung.gd`, `hq_placement.gd`, `industry_markers.gd`, `props/label_declutter.gd`, `proto/proto_schilder.gd`. Das Spielpanel selbst lebt in `main.gd` (Refresh `_refresh_panel` alle 0,25 s, Toast `_toast`).
- Fonts: Kenney Future und Poppins; Glyph "×" fehlt in Kenney Future, daher `glyph_font`-Fallback auf Poppins (`ui/ui_kit.gd:57-87`, `sprints/s5/day11/mira.md` BUG-3).
- **Schilder** (`proto_schilder.gd`): Bildschirm-Overlay, Tiers Fern >= 1.500 m (nur Ort), Voll 400 bis 1.500 m, Nah < 400 m; Hysterese 8 %; `RAND_PX = 8`; `MIN_FONT_PX = 12`; Skalierung 0,85 bis 1,5; `ui_scale = Fensterhöhe / 900`. Die Pixel-Skala der Label-Größe ist FOV-korrigiert (H1, `label_kscale` in `props/label_declutter.gd` Z.21); Overlay statt Label3D ist meine Lesart, nicht ausdrücklich im Repo begründet.
- **Modal-Verbot**: Bastis Wunsch "keine grauen Standard-Dialoge". `d07_regression.sh` prüft statisch auf `AcceptDialog`, `ConfirmationDialog`, `FileDialog`, `Popup*` ("Modal-Klassen im Code: keine").

## B2 Eingabe
- Spiel (`main.gd`, `_unhandled_input`): 1 bis 5 Werkzeuge (`TOOL_NAMES`), X Abriss, Leertaste oder P Pause, Esc und Rechtsklick abbrechen, Mausrad Zoom (Faktor 0,9 und 1,1). Kamera WASD über `Input.is_key_pressed(KEY_*)`: rohe Tastencodes, keine InputMap (läuft, ist aber nicht umbelegbar).
- Prototyp (`proto/prototyp_welt.gd`): WASD/Pfeile, Q/E, Mausrad 40 m bis 3 km, rechte und mittlere Taste drehen, linke ziehen = schieben; 1 bis 5 Presets; V Wasser A/B; G Easing; M Modelle; N Schilder; F Folgekamera (Fuhrwerk 1, 2, Postkutsche, aus); T Tempo 1x/0,25x; H HUD; F11 oder Alt+Enter Vollbild; Esc Menü.
- Start: `--welt=s7`, `--proto`, `--bench`, `--fahrzeuge=alt`, `--startjahr=JJJJ`, `--modus=neu|beispiel`; Taste P im Startmenü startet den Prototyp (`start_menu.gd`).
- Picking: `_mouse_cell` schneidet nur die Ebene y=0; mit Gelände (S7) offen (`sprints/s7/block-b/mira.md`). Der Prototyp nutzt `hoehe_at` auf Mesh-Dreiecken.

## B3 Tests für UI (Eigenbau, kein GUT/gdUnit4)
- Headless: `d07_abnahme` (ui 31), `s7_mira` 33, `s7_w04` 31, `s7_city` 114.
- xvfb mit echter Maus: `d08_maus` 27, `s7_u03_test` 125, `s7_industrie_test` 66, `s7_start` 31, `proto_schilder` 51.
- Spielwerkzeug für Agenten: `tools/play.sh <ordner> [--no-shot] [--fast] [--budget=<s>] [--bg] [--welt=s7]` mit `commands.txt`, Screenshots in den Ordner; Anleitung `tools/play_help.md`.
- Aufruf unter xvfb: `xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --path slice -s res://tests/d08_maus.gd`.
- Ticks messen über Physik-Frames, nie Wanduhr (S6-Erfahrung).

## B4 Stolpersteine mit Lösung (aus dem Repo)
| Stolperstein | Beleg | Lösung |
|---|---|---|
| BUG-1 (D-07): gehaltener Klick verschluckt vom 0,25-s-Refresh | `main.gd:1780` (Kommentar) | Sichtbarkeit erst am Ende von `_refresh_panel` setzen |
| "×" fehlt in Kenney Future (Tempo "2×" erschien als "2H") | `sprints/s5/day11/mira.md` BUG-3, `ui/ui_kit.gd:57-87` | `glyph_font` setzt Poppins bei × und bei "HQ" (`s6/block-c/mira.md` B-7) |
| Disabled-Kontrast 2,8:1 beim Primärknopf | `ui/theme/theme_builder.gd:187` (BUG-5) | `ButtonPrimary` auf #665443 = 4,8:1. Allgemeiner Stil `disabled_fg` #8A7A66 auf #DDD2BA rechne ich zu 2,77:1 [V]: nicht angepasst |
| Toast: ein einziges `toast_label`, jede Meldung überschreibt die vorige; Höhe nach Umbruch falsch gemessen | `main.gd:1591-1605` | `_fit_toast.call_deferred()` misst nach dem Umbruch neu; Queue wäre Ausbau |
| HQ-Ring schluckte Industrie-Klicks (Farm 3 auf dem Ring) | `sprints/s6/zocken/felix_harness.md` Z.18 | `_hits_ring_or_hq`: Feld auf/neben einer Nicht-Stadt-Baute löst nie Umsetzen aus (`s7/block-a/mira.md` Z.16) |
| Ring-Animation startete bei jedem Hover-Ende neu | `sprints/s6/zocken/mira_ringfix.md` | `_ring_city` merkt die Stadt des stehenden Rings; Animation nur bei Stadtwechsel |
| Label-Pixelgröße hängt am FOV | `props/label_declutter.gd:21` (H1) | `label_kscale()` FOV-korrigiert; Prototyp-Schilder sind Bildschirm-Overlay |
| Prototyp nur mit Maus und Tastatur | `prototyp_welt.gd` | kein Fokus-Pfad, offen (C2) |
| Picking trifft Ebene y=0 | `sprints/s7/block-b/mira.md` | Terrain-Ray-March (A2) vormerken |
| Toast-Panel bekommt 2.230 px Höhe und fängt Klicks, wenn `RenderingServer.render_loop_enabled=false` | `sprints/s6/zocken/felix_harness.md` Z.14 | verworfen; `root.disable_3d = true` während der Befehle |
| Startfenster-Größe (HiDPI) | `sprints/s7/review_retro.md` Z.18: "Initial-Window-Fix" nach S8 verschoben; Doku Q36 nennt HiDPI-Fallstrick | offen |
| Text im Code widerspricht Layout | `proto_easing.gd` Kopfkommentar | Kommentar nach Integration gegenlesen (INSTANCE_CUSTOM) |

## B5 Offene UI-Punkte (Stand 03.11.)
Fokus-Navigation, Mindest-Schriftgröße gegen Xbox-Leitwert, allgemeiner Disabled-Kontrast (2,77:1), Toast-Queue, Picking mit Gelände, Initial-Window-Fix, `tr()`-Anbindung (heute Festtexte), Tooltip-Strategie (keine Quelle gelesen, die Zahlen liefert).

---------------------------------------------------------------------------------------------------
# TEIL C: Eigene Lücken und Lernstand
---------------------------------------------------------------------------------------------------

## C1 Gelernt (Konfidenz hoch = Versuch oder Doku plus Repo)
1. Eingabe-Reihenfolge und `mouse_filter` als Klick-Schlucker erklärt BUG-1-artige Fehler. Konfidenz hoch [Q35].
2. Tween-Hänger nach `kill()` per Versuch bestätigt, Callback als Muster. Konfidenz hoch [V, Q43].
3. Headless ist für Layout falsch (64 x 64, 1600 x 1600). Layout-Tests nur unter xvfb. Konfidenz hoch [V].
4. Controls-Größe direkt nach `add_child`: nicht reproduziert, deshalb nicht als Falle geführt. Konfidenz mittel.
5. Negative Cent-Beträge im Geld-Format ergeben "0 $" (Beispiel -37): Darstellung von Schulden braucht eigenen Pfad. Konfidenz hoch [V].
6. Overlay-Schilder sind richtig für 3D-Skalierung; Declutter per `Rect2`-Liste mit Hysterese ist ein tragfähiges Muster. Konfidenz mittel bis hoch.

## C2 Weiter unsicher (ehrlich)
- Ob 12 px bei 900 px Höhe lesbar genug ist: der Xbox-Wert (18 px) ist ein anderes Maß. Nicht entschieden, braucht Test auf Bastis Monitor. Konfidenz niedrig.
- Ob `stretch canvas_items + expand` für ein UI-lastiges 3D-Spiel richtig ist: Doku ohne Empfehlung. Konfidenz mittel (läuft, 1600 x 900).
- gdUnit4 Scene Runner für UI statt Eigenbau: Fähigkeiten gelistet (Q31), kein Vergleich gefunden, nicht erprobt. Konfidenz niedrig.
- Accessibility (AccessKit, Q34): experimentell, nicht erprobt.
- Tooltip-Design, Informationshierarchie und Toast-Queue: keine belastbare Quelle gefunden, nur Praxisregeln. Konfidenz niedrig.
- Fullscreen exklusiv gegen randlos auf Windows und HiDPI-Fenster: nur Doku, nie auf Bastis Rechner geprüft.

## C3 Priorisierte Lernfragen (10) mit Stand
1. Eingabefluss und mouse_filter: beantwortet (A1.3). Offen: Audit aller Panels auf Wurzel-`mouse_filter`.
2. InputMap statt `KEY_*`: beantwortet (A2). Offen: Umbau Kamera/Tools, Taste-Umbelegung im Menü.
3. Container-Timing: Versuch ohne Fehler; Regel `process_frame` vor Positionierung bleibt als Vorsicht.
4. Stretch/Skalierung/Vollbild/HiDPI: Doku gelesen, Headless-Falle [V]; Initial-Window-Fix offen.
5. Weltschilder: Overlay, Declutter, Hysterese beantwortet; Fern-Tiers mit Epochen noch offen.
6. Theme/Type Variations/Glyphen/Kontrast/Mindestschrift: Muster da (A2), Zahlen gegen Xbox offen.
7. Tween/Animation: beantwortet (kill plus Callback).
8. UI-Tests: Eigenbau mit echter Maus ist gut; Pilot gdUnit4 offen.
9. Texte/Lokalisierung: Platzhalter-Muster gelernt; Umstellung auf `tr()` nicht begonnen.
10. Tooltips, Hierarchie, Modalverbot, Tastaturfokus, Toast-Queue: nur Praxiswissen. Camera/Picking: Terrain-Ray-March skizziert, nicht im Spiel.

## C4 Selbstregeln ab jetzt
Jede neue Control-Wurzel mit bewusstem `mouse_filter`. Kein `await` auf Tweens, die ich töten kann. Layout- und Größentests nur unter xvfb. Jede UI-Zahl (Kontrast, Schrift) mit Rechnung statt Gefühl. Jede API-Zeile gegen den Dump greppen, danach `--check-only` und Laufzeit-Smoke.

## B6 Prüfpfad für eine UI-Änderung im Repo (aus den Skripten abgeleitet)
1. `godot --headless --path slice --import` (nur nach Pull mit neuen `class_name`-Dateien nötig), dann `--check-only -s res://<datei>.gd`.
2. Headless-Suite der Fläche: `-s res://tests/d07_abnahme.gd` (UI-Teil), `s7_mira_test.gd`, `s7_w04_test.gd`.
3. Für Mausweg, Layout und Schilder: xvfb-Suite (`d08_maus.gd`, `s7_u03_test.gd`, `proto_schilder_test` bzw. die Schilder-Suite des Prototyps), dann `tools/play.sh` mit `commands.txt` für Screenshots.
4. Statische Prüfung in `d07_regression.sh` (keine Modal-Klassen, Icons >= 24 px, Tween-Konstanten) läuft nur in der vollen Regression, nicht in der Kurzsuite.
5. Neue Texte in `FT`; Test gegen 90 Zeichen und gegen Überlauf bei 1600 px (`s6/refinement/tech.md`).

## C5 Was ich messen lasse, bevor ich es behaupte
Schilder bei 4K und 16:10 per Screenshot (A7), Panels mit 200 %-Skalierung, Fokusreihenfolge im Startmenü, Kontrast von hover/pressed/focus je Knopftyp (nur Primär-disabled ist belegt), Toast-Verhalten bei zwei Meldungen innerhalb von 4 s (Überschreiben ist im Code sichtbar, Wirkung für Spielende nicht getestet).
