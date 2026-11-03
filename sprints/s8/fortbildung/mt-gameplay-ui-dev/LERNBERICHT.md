# Lernbericht Mira (Gameplay und UI), 03.11.2026

Gehört zu `/tmp/claude-0/gd/skills/mt-gameplay-ui-dev/SKILL.md`. Quellenliste dort (A6). Hier: Vorgehen, Funde, Offenes.

## 1 Selbstanalyse (Repo nur gelesen, nichts geändert)
Gelesen: `ui/ui_kit.gd`, `ui/ui_fx.gd`, `ui/theme/theme_builder.gd`, `ui/fehlertexte.gd`, `bankrott_warnung.gd`, `hq_placement.gd`, `industry_markers.gd`, `props/label_declutter.gd`, `proto/proto_schilder.gd`, `proto/prototyp_welt.gd` (Tasten), `main.gd` (Eingabe, Toast, Refresh), `start_menu.gd`, `tools/play.sh`, `d08_maus.gd`, Sprint-Berichte Mira s5 bis s8 und Felix-Harness.

Gefundene Lücken, nach Gewicht:
1. **Disabled-Kontrast**: Primärknopf wurde von 2,8:1 auf 4,8:1 gehoben (`theme_builder.gd:187`), der allgemeine Stil `disabled_fg #8A7A66` auf `#DDD2BA` liegt rechnerisch bei 2,77:1.
2. **Schriftgrößen gegen Leitwert**: `MIN_FONT_PX = 12` (Canvas-Pixel) gegen Xbox-Leitwert 18 px bei 1080p. Maß nicht identisch, aber 12 Canvas-Pixel sind bei 1080p reale 14,4 px.
3. **Skalierungs-Irrtum in `proto_schilder.gd`**: `_scale = vp.y / 900` liest die sichtbare Fläche in Canvas-Pixeln (bei 16:9 immer 900), wirkt also nur bei anderem Seitenverhältnis. Die echte Auflösungsskalierung macht der Stretch. Versuch unter xvfb bestätigt (siehe 2).
4. **Rohe Tastencodes** (`Input.is_key_pressed(KEY_*)`) statt InputMap: nicht umbelegbar. Kein Fokus-Pfad (Prototyp nur Maus und Tastatur).
5. **Toast**: ein einziges `toast_label`, jede Meldung überschreibt die vorige (`main.gd:1591`). Neu-Messung per `call_deferred`.
6. **Picking**: `_mouse_cell` schneidet die Ebene y=0, mit Gelände offen (`s7/block-b/mira.md`).
7. **Texte fest im Code** (`FT`), `tr()` nicht benutzt; Platzhalterreihenfolge ist die Falle bei späterer Lokalisierung.
8. **Kein UI-Test-Framework** außer Eigenbau mit echter Maus unter xvfb (gut: prüft `mouse_filter` tatsächlich).
Vergangene Fehler im Repo, die Mira-Wissen belegen: BUG-1 (Refresh verschluckt Klicks, `main.gd:1780`), BUG-3 ("2×" erscheint als "2H" in Kenney Future, `glyph_font`), BUG-5 (Disabled-Kontrast), HQ-Ring schluckte Industrie-Klicks, Ring-Animation restartete bei jedem Hover-Ende.

## 2 Eigenversuche (Godot 4.7.2)
| Versuch | Ergebnis |
|---|---|
| Fenstergrößen unter xvfb, Projekt 1600 x 900, canvas_items + expand | 1920 x 1080: visible 1600 x 900, Faktor 1,2; 1600 x 1000: 1600 x 1000, Faktor 1,0; 2560 x 1080: 2133 x 900, Faktor 1,2 |
| Headless | Fenster 64 x 64, `visible_rect` 1600 x 1600 |
| `await tween.finished` nach `kill()` | Coroutine hängt für immer; Callback-Muster funktioniert |
| Control-Größe direkt nach `add_child` (verschachtelte Container) | in 4.7.2 sofort korrekt; Forum-Bericht (4.2.1) nicht reproduziert, deshalb nicht als Falle geführt |
| `geld()` mit Cent | 123456700 -> "1.234.567 $", -370000 -> "-3.700 $", -37 -> "0 $" |
| Declutter (`Rect2.intersects`) und Stufen-Hysterese | gelaufen, Werte wie erwartet |
| `content_scale_factor` auf Root | setzen und lesen funktioniert (1,5); Wirkung auf unser Layout ungeprüft |
| InputMap mit `physical_keycode`, Fullscreen-Modi, Theme-Variation, Picking per Ray-March | kompiliert und (soweit headless möglich) gelaufen |
| SceneTree-Skript: `root.get_window()` in `_initialize` | liefert null (Fehler, dann hängt der Prozess); `root.content_scale_factor` direkt nutzen |

## 3 Recherche
Godot-Doku (InputEvent, Containers, Theme-Variationen, Navigation, Multiple Resolutions, i18n), Godot-Forum und GitHub (Tween-Hang, Control-Größe), Release-Notizen 4.5 (AccessKit), Microsoft Xbox Accessibility 101, Transport-Fever-3-Devblog, WCAG-Normwissen.
- **Konsens**: Eingabereihenfolge und `mouse_filter` (Doku eindeutig); `grab_focus` nötig für Tastaturnavigation; benannte Platzhalter und `tr_n`; Kontrast 4,5:1 und 3:1.
- **Streit/ungeklärt**: Stretch-Modus für UI-lastige 3D-Spiele (Doku gibt keine Empfehlung); Control-Größe nach `add_child` (Forum behauptet Problem, mein Versuch nicht).
- **Einzelmeinung**: Transport-Fever-3-Devblog (Vorschau); Xbox-Wert 18 px (offiziell, anderes Maß); Tween-Hang ist ein Forum-Bericht (4.5.1), von mir bestätigt.
- **Nicht erreicht**: Reddit (blockiert, nicht umgangen); GDC "Juice It or Lose It" nur dünne Mitgliederseite, daher nichts daraus verwertet; Forum-Thread zur Control-Größe nur als Frage sichtbar; zu Tooltips, Informationshierarchie und Toast-Queue fand ich keine belastbare Quelle, dort steht nur Praxiswissen.

## 4 Gelernt (hoch)
`mouse_filter` und Eingabereihenfolge erklären Klick-Verlust; Tween-Hang und Callback-Muster; Headless ist für Layout falsch; Stretch liefert die Auflösungsskalierung, nicht `vp.y/900`; Geld-Format mit Vorzeichen braucht eigenen Pfad; Overlay-Schilder mit Rect2-Declutter und Hysterese sind tragfähig.

## 5 Offen (ehrlich)
Ist 12 Canvas-Pixel lesbar genug (Test auf Bastis Monitor)? Fokus-Navigation und Screenreader (AccessKit experimentell) nicht erprobt. gdUnit4-Scene-Runner nicht erprobt, kein Vergleich gefunden. Exklusives Vollbild und HiDPI auf Windows nur Doku. Tooltip-Strategie und Toast-Queue ohne Quelle. Schilder bei 4K und 16:10 noch nicht per Screenshot bestätigt.

## 6 Konkrete Vorschläge (nicht umgesetzt, Repo unverändert)
1. Disabled-Stil allgemein auf >= 4,5:1 (z. B. `#665443` wie beim Primärknopf) prüfen lassen.
2. Kamera- und Werkzeugtasten in InputMap überführen (`physical_keycode`).
3. Schilder-Skalierung: Kommentar im Dateikopf korrigieren oder `content_scale_factor`-Option anbieten.
4. Toast-Queue (zwei Meldungen in 4 s) mit Test.
5. Ersten Fokus-Pfad für Startmenü und Panels (`grab_focus`, sichtbarer Fokusrahmen).
6. Terrain-Ray-March in `_mouse_cell`, sobald S7-Gelände greift.
