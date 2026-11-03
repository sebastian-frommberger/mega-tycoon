# Lernbericht Felix (Lead Developer), 03.11.2026

Gehört zu `/tmp/claude-0/gd/skills/mt-lead-dev/SKILL.md`. Dort stehen Wissen und Quellenliste Q1 bis Q36. Hier: wie ich vorgegangen bin, was ich fand, was offen ist.

## 1 Selbstanalyse (Repo nur gelesen, nichts geändert)
Gelesen: `slice/project.godot`, `core/` (sim_world, net_graph), `fleet_soa.gd`, `render_batch.gd`, `main.gd` (Stichproben), `proto/*`, `tests/d07_regression.sh` plus Summary, `run_tests.sh`, `perf_s7.gd`, `tools/play.sh`, `export_presets.cfg`, `.gitignore`, `.gitattributes`, Sprint-Berichte s5 bis s8 (Felix-Dateien, `felix_perf_aufschluesselung.md`, `proto_sim_anbindung.md`, `integration_w2.md`, `fixpass_w2.md`), Git-Log (74 Commits).

Gefundene Lücken und Unsicherheiten, nach Gewicht:
1. **Regressionsskripte ohne `timeout`** (0 Treffer in `d07_regression.sh` und `run_tests.sh`). Ein hängender Test blockiert die ganze Suite, und Godot hängt tatsächlich, wenn in `_initialize` ein Fehler auftritt (Versuch). Dauer 488 s bis 1.565 s (26 min).
2. **Perf-Zahlen ohne Etikett**: 1,62 M Dreiecke waren "gezählt ohne Culling", live höchstens 0,62 bis 0,73 M. Die Fehlannahme "Fahrzeuge sind die Draw-Call-Ursache" wurde erst durch Ausblend-Messung widerlegt (3.366 Straßenfelder waren es).
3. **.uid-Flip-Flop** (`89d6c9e` entfernt, `337fb5b`/`cd57358` fügen wieder ein). Heute konform mit der offiziellen Linie (Q1), aber ohne dokumentierte Regel.
4. **class_name-Cache nach Pull**: im Repo nur als Gegenmaßnahme (`--import`) sichtbar, nie als Vorfall dokumentiert. Ich habe es nachgestellt.
5. **Statische B-2-Prüfung zeilenbasiert**: `world/proto_prefab_bau.gd` Z.33 und Z.37 (`globalize_path("res://")`, `append_from_file`) rutschen durch. Nur Rückfallpfad, Exportrisiko gering aber real.
6. **Veralteter Kommentar** in `proto_easing.gd` (INSTANCE_CUSTOM-Belegung) gegen `integration_w2.md` I7.
7. **Kein Save/Load**, kein Spielstandcode gefunden. Kein gdUnit4/GUT, aber 21+ Suiten mit eigener `pruef()`-Hilfe (Duplikate).
8. **Windows**: Skripte haben Sandbox-Pfade (`/tmp/claude-0/gd/...`) eingebrannt; xvfb-Suiten laufen nicht nativ auf Bastis PC (`C:\Dev`). `.gitattributes` enthält nur binäre Muster, keine Zeilenenden-Regel.
9. **E5/E6-Easing-Widerspruch** bewusst offen (E6 "ABW": 1,30 / 1,38 x W/2).

## 2 Eigenversuche (Godot 4.7.2, alles im Scratchpad, Repo unberührt)
| Versuch | Ergebnis |
|---|---|
| class_name ohne/mit veraltetem Cache | "Identifier not declared"; `--import` behebt; `preload(Pfad)` geht ohne Cache; `--import` erzeugt `.uid` |
| `--check-only` und Godot-3-Rückfälle | meldet yield, onready, export, rand_range, stepify, range_lerp, deg2rad, File, Transform(), Pool*Array, setget, tool, OS.get_ticks_msec, Basis.xform; meldet NICHT `change_scene`, `.instance()`, `Tween.new().interpolate_property` |
| Fehler in `_initialize` eines SceneTree-Skripts | Prozess hängt (nur `timeout` rettet); Exit 0 trotz SCRIPT ERROR bei sauberem Ende |
| `var x := d.get(...)` | Fehler in 4.7.2 (Variant-Inferenz), `var x: int = ...` nötig |
| Headless | Fenster 64 x 64, `visible_rect` 1600 x 1600 (bei expand), 0 Dreiecke/DC, MultiMesh-Transform = Identität; xvfb liefert 1600 x 900 |
| JSON und int64 | Prüfsumme -3750763034362895579 kommt als ...895360 zurück; `var_to_str`/`str_to_var` exakt |
| float32 | 1e6 x 0,1 in PackedFloat32Array = 100958 statt 100000 |
| Tween | `await tween.finished` nach `kill()` hängt dauerhaft |
| CSV in res:// | `csv_translation`-Import erzeugt `.translation`-Müll; TSV/TXT nicht |
| Save | atomar (tmp, flush, .bak, rename), Version-Migration, Fallback auf .bak bei Korruption: Linux ok, Windows nicht geprüft |
| Fahrlinie | Tabelle je 1 m, Länge 200 m, Gier 90° und 0° korrekt |
Nicht nachgestellt (nur Repo-Doku): INSTANCE_CUSTOM-Belegung, `use_colors`-Schwarz-Fall (MultiMesh braucht echten Renderer).

## 3 Recherche
WebSearch (extended für Pfadsuche, Determinismus, Save, Tests) und WebFetch. Etwa 40 Seiten mit Inhalt, 36 davon in der Quellenliste des Skills.
- **Konsens** (mehrere unabhängige Quellen): fester Tick plus Interpolation (Gaffer, Nystrom, Godot-Doku); Schritte je Frame deckeln; Flow Field für viele Einheiten zu einem Ziel (Red Blob, beide Seiten); `.uid` committen (Godot-Artikel plus Doku); MultiMesh-Culling nur als Ganzes (Doku, Issue 108847); erst messen, dann optimieren (Godot-Doku, Nystrom, Factorio).
- **Streit/ungeklärt**: Gleitkomma-Determinismus über Maschinen (Gaffer: "keineswegs geklärt"); Packed*Array gegen typed Array (Doku widersprüchlich, Issue 10300, Maintainer 99 % sicher ohne Messung).
- **Einzelmeinung/dünn**: bugnet.io Save-Artikel (Fehler im Text, nur Ideenquelle); Transport-Fever-3-Devblog (Vorschau); Xbox-Textleitlinie (offiziell, aber anderes Maß); Typisierungs-Benchmark 2020 (Debug-Build, veraltet).
- **Zahlen mit URL**: Factorio FFF-421 (Roboport 1 ms auf 0,025 ms, Kombinatoren 14,9-fach, Netz-Multithreading 0,5 auf 0,39 ms gescheitert, +15 %), Nystrom (Cache-Zeile 64 bis 128 Byte, etwa 50-fach im eigenen Benchmark), Gaffer (0,25 s Klemme), OpenTTD YAPF (Signalstrafen 500/-100/5), Godot Physics-Interpolation (10 Hz bei 60 FPS), Godot 4.5 (Shader Baker 20-fach).
- **Nicht erreicht**: Reddit (SITE_BLOCKED, Proxy-Fehler, nicht umgangen); Forum-Thread zu headless nach Redirect (PROVENANCE_REQUIRED, ungelesen); mehrere Doku-Seiten nur teilweise (MultiMesh-Teil der Interpolation, 3D-Text); GDC "Juice It" nur Mitgliederseite.

## 4 Gelernt (hoch)
class_name-Cache und `--import`; `--check-only`-Grenzen; Hänger-Schutz mit `timeout`; JSON-int64; Etikettierung von Perf-Zahlen; Headless ist kein Renderziel; Factorio-Denkweise (Absicht speichern, Darstellung vorhersagen) passt auf unser Easing.

## 5 Offen (ehrlich)
Windows-Atomarität von `DirAccess.rename`; `MultiMesh.set_buffer_interpolated` gegen unseren Eigenansatz; Flow Field gegen Segment-A* bei Netzwachstum (keine Zahlen); gdUnit4/GUT-Pilot; Hot Reload mit godot-editor-mcp; Exe-Export, exklusives Vollbild, HiDPI auf Bastis PC; Save/Load nur Entwurf. Perf-Messfehler "Faktor 2,5" aus der S7-Retro ist im Repo nicht detailliert.

## 6 Konkrete Vorschläge (nicht umgesetzt, Repo unverändert)
1. `timeout` je Suite in `d07_regression.sh` und `run_tests.sh`.
2. Regression in Stufen "Schnell" und "Voll" teilen, d08_bankrott separat.
3. `.gitattributes` um `* text=auto eol=lf` ergänzen; `.uid`-Regel in die README.
4. B-2-Prüfung dateiweise statt zeilenweise.
5. Gemeinsame Test-Basisklasse für `pruef()`.
6. `--import` als ersten Schritt in jedem Test-Aufruf.
