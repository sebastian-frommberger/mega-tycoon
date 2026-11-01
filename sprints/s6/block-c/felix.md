# Felix – Sprint 6, Tag 10: Bugfixes aus D-08 (B-2, B-5, B-6)

Arbeitskopie: `/tmp/claude-0/gd/sprint6/c/felix/slice`. Godot 4.7.2, Sandbox. Nicht angefasst: hq_placement.gd, tools/hq_vorschau_gen.py, data/hq_vorschau.json, data/slice_map.json, Meilenstein-Hinweise in main.gd (Mira).

## B-2 Kenney-GLBs im Export (hoch) – behoben
- `props/kenney_loader.gd`: neue `load_root(path)`: zuerst `load("res://props/kenney/x.glb")` als PackedScene (importierte `.scn` aus `.godot/imported`, kommt per `all_resources` ins PCK), Rückfall `GLTFDocument.append_from_file("res://...")` (ohne globalize_path), sonst null -> Quader. `last_source[path]` = import/gltf/fehlt.
- `tree_mesh()` und `props/industry_props.gd:_model()` laufen über `load_root`. Kein `globalize_path` mehr im Spielcode.
- include_filter **nicht** geändert (nicht nötig, die rohen .glb landen nicht im PCK; nur `.import` + `.scn`).
- Import vs. GLTF verglichen (Wegwerf-Skript): alle 7 Modelle gleiche Flächen, Materialnamen (woodBark/leafsGreen usw., Stamm-Erkennung greift), Texturen, AABB.
- `bench.gd`: Logzeile „Bäume: Kenney (import/import)“ bzw. „Bäume: Quader (…)“ in Konsole und Ergebnisdatei.
- **Echt geprüft:** `--export-pack "Windows Desktop Bench" test.pck` (geht ohne Templates, 879 KB, enthält `tree_*.glb-*.scn`, keine rohen .glb), dann in leerem Ordner `godot --headless --main-pack test.pck -- --bench --bench-sec=1 --bench-units=200`: „BENCH Bäume: Kenney (import/import)“, Ergebnisdatei geschrieben. Gilt für die Windows-PCK-Inhalte auf Linux-Engine; eine echte .exe wurde nicht gebaut (keine Templates). Industrie-Props im PCK nicht separat geloggt, nutzen denselben Weg.
- Regression-Statik: „OFFEN B-2“-Hinweis ersetzt durch harte Prüfung „kein globalize_path für Kenney/append_from_file im Spielcode“.

## B-5 Bäume ohne Schatten – behoben
- `main.gd` Waldaufbau: `_multimesh_mesh(..., false)`. Look-Last weiter nur auf Zielrechner messbar.

## B-6 Zielpfeil deckt Label – behoben
- Ursache: `main._place_map_labels` blendet Labels unter dem Pfeil aus, danach (process_priority 100) schiebt `label_declutter.gd` Labels nach unten, teils unter den Pfeil.
- Fix: Pfeil-Prüfung aus `_place_map_labels` in `main.hide_labels_under_goal_markers()` ausgelagert (Rechtecke in `_goal_mark_rects`, Label-Rechteck aus aktuellem Offset). Aufruf am Ende von `_place_map_labels` und am Ende von `label_declutter._process` (3 Zeilen bei Sophie). Pfeil hat damit das letzte Wort.
- u02b_shots (xvfb, 1600x900): Scan 100 Ansichten 0 Treffer, 0 FAIL. Shots: `/tmp/claude-0/gd/sprint6/c/felix/u02b/`.
- Nicht angefasst: Kohlberg-Cluster Labels über Props/einander (B-6 Teil 2, Stretch).

## Regression
- `bash tests/d07_regression.sh <godot> /home/claude/mega-tycoon/spikes` aus slice/: **GRÜN**, 488 s, 0 SCRIPT ERROR (Treffer nur die Zählzeilen „SCRIPT ERROR Zeilen: 0“). Statik „B-2: Kenney-GLB über globalize_path: keine“. d08_lizenzfaktor bleibt „OFFEN B-1“ (zählt nicht, nicht mein Ticket).
- Geänderte Dateien: main.gd (B-5 eine Zeile, B-6 Funktion `hide_labels_under_goal_markers` + Member), props/kenney_loader.gd, props/industry_props.gd, props/label_declutter.gd (3 Zeilen), bench.gd, tests/d07_regression.sh (Statik B-2). export_presets.cfg unverändert.
- Für Sophie: Declutter ruft jetzt am Ende main.hide_labels_under_goal_markers(); bei Umbau des Declutters bitte behalten.
