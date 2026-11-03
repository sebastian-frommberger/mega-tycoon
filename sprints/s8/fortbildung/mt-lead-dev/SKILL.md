---
name: mt-lead-dev
description: Fach- und Projektwissen für Felix, Lead Developer von Mega Tycoon (Godot 4.7.2, GDScript). Verwenden bei Architektur, Sim und Darstellung, Determinismus, Performance-Gates, Tests, Regression, Merge, Export oder Engine-Fallen im Repo mega-tycoon.
---

# Felix, Lead Developer: Fortbildungsstand 03.11.2026

Kennzeichen der Belegstärke: [K] Konsens mehrerer Quellen, [S] Streit oder Doku widersprüchlich, [E] Einzelquelle oder Einzelmeinung, [V] eigener Versuch mit Godot 4.7.2 (Skripte lagen im Scratchpad, nicht im Repo), [R] aus dem Repo belegt. Quellen Q1 bis Q36 am Ende von Teil A.
Ehrlich vorweg: Reddit war nicht lesbar (WebFetch: SITE_BLOCKED, WebSearch mit Domainfilter: Proxy-Fehler). Es steht hier kein Reddit-Wissen. Forum- und GitHub-Quellen sind Ersatz, nicht Gleichwert.

---------------------------------------------------------------------------------------------------
# TEIL A: Allgemeines Fachwissen
---------------------------------------------------------------------------------------------------

## A1 Prinzipien (Reihenfolge = Wichtigkeit für dieses Projekt)

1. **Sim und Darstellung strikt trennen.** [K] Die Sim ist ein Datenmodell mit festem Tick, die Darstellung liest nur. Gaffer: fester dt, Akkumulator, Darstellung zwischen zwei Zuständen interpolieren (Q3). Nystrom: "fixed update, variable render" ist der stabilste Loop, variabler dt nur mit Gründen (Q5). Factorio geht weiter: Roboter speichern nur Bewegungs-Absicht, die Darstellung sagt die Position zwischen den echten Updates voraus, +15 % Gesamt-UPS (Q9).
2. **Spiral of Death verhindern.** [K] Schritte je Frame deckeln (Nystrom: "maximale Anzahl Iterationen", Gaffer: Frame-Zeit auf 0,25 s klemmen) und im Zweifel langsamer werden statt hängen (Q3, Q5). Tick-Kosten müssen im Mittel deutlich unter der Tick-Dauer liegen, sonst holt der Akkumulator nie auf.
3. **Ganzzahlen in der Sim, Gleitkomma in der Darstellung.** [S] Gaffer: Gleitkomma-Determinismus über Maschinen/Compiler "keineswegs geklärt", nur mit Disziplin möglich (FPU-Modus, keine FMA, keine Transzendentalfunktionen), und er empfiehlt Ganzzahlen nicht ausdrücklich (Q4). Konsens in der Praxis: Ganzzahl-Sim (mm, Cent, Ticks) umgeht die Frage. [V] float32 summiert falsch: 1.000.000 x 0,1 ergab in PackedFloat32Array 100958,34 statt 100000.
4. **Erst messen, dann optimieren, dann Zahl gegenprüfen.** [K] Godot-Doku: profilieren, größten Posten angehen, neu messen; CPU und GPU laufen unabhängig, Frame = langsamerer von beiden (Q18). Nystrom: Datenlokalität nur bei belegtem Problem, vorher Cachegrind-artige Bestätigung (Q6). Factorio: Multithreading elektrischer Netze brachte nichts (0,5 ms auf 0,39 ms, CPU 0,5 % auf 15 %), weil speichergebunden, VTune zeigte es (Q9).
5. **Datenlokalität vor Cleverness.** [K, mit Vorbehalt] Contiguous Arrays je Komponente, aktive Objekte vorn, heiße und kalte Felder trennen (Q6). Nystrom nennt etwa Faktor 50 bei schlechter Lokalität in seinem Benchmark und warnt: maschinenabhängig. Godot: Packed*Array [S] (Q21): Class-Reference sagt schneller als typed Array, GDScript-Referenz sagt "langsamer"; Maintainer clayjohn nennt die GDScript-Passage veraltet (Godot-3-Pool-Arrays) und ist "99 %" sicher, dass Packed gleich schnell oder schneller ist. Keine Messung in der Quelle.
6. **Vieles ist eine Frage der Zähleinheit.** Dreiecke "gezählt" (alle Knoten, ohne Culling) sind nicht Dreiecke "live" (RenderingServer, im Frame). Beide haben ihren Zweck, nur nie in einer Zeile ohne Etikett.
7. **Caches und Dirty-Flags nur mit einer einzigen Schreibstelle.** [K] Dirty Flag: "Wer an einer Stelle das Flag vergisst, rechnet mit veralteten Daten" (Q7). Faktor: alle Änderungen durch eine Schnittstelle.
8. **Pfadsuche je nach Fragestellung wählen.** [K] Viele Einheiten zu einem Ziel: ein BFS/Dijkstra-Feld vom Ziel (Flow Field), jede Zelle kennt die Richtung (Q12, Q13, Red Blob nennt keine Zahlen). Eine Quelle, ein Ziel: A*. Factorio ersetzte nicht den A*, sondern fütterte ihn mit einer groben, gecachten Rückwärtssuche über Chunk-Komponenten als Heuristik (Q10) und cachte Pfade samt "Schwierigkeit", Teilpfade wiederverwendbar, negative Treffer (unerreichbar) ebenfalls (Q11). OpenTTD YAPF: Knoten sind Segmente bis zur nächsten Entscheidung (Station, Signal, Weiche) und werden gecacht; NPF mit Knoten je Feld ging bei vielen Fahrzeugen in die Knie (Q14).
9. **Tests laufen mit Zeitlimit und prüfen den Fehlertext, nicht nur den Exit-Code.** [V] Godot beendet sich mit Exit 0, obwohl SCRIPT ERROR gedruckt wurde (Skript mit `_process` das `true` liefert). Läuft ein Fehler in `_initialize` oder `_run`, wird `quit()` nie erreicht: der Prozess hängt (Versuch: `change_scene` auf SceneTree = Laufzeitfehler, Prozess lief bis zum timeout 30). Immer `timeout N godot ...` und `grep -c "SCRIPT ERROR"`.
10. **Daten statt Code für Tuning.** [K] JSON-Konfig (regelwerk, economy_slice) ist der Hebel für Designer. Gegenmaßnahme für Drift: Validator rechnet dieselbe Regel wie das Spiel (Brückenrampe, S7-Retro).

## A2 Godot-4.7-Muster (alle Snippets: `--check-only` grün, ausgewählte per Lauf geprüft [V])

**Fester Tick mit Obergrenze und alpha**
```gdscript
const TICK_S := 0.1
const MAX_TICKS_JE_FRAME := 8
var _acc := 0.0
var alpha := 0.0
func _process(delta: float) -> void:
	_acc += delta * sim_tempo
	var n := 0
	while _acc >= TICK_S and n < MAX_TICKS_JE_FRAME:
		_sim_tick(); _acc -= TICK_S; n += 1
	if _acc >= TICK_S:
		_acc = fmod(_acc, TICK_S)      # Rückstand verwerfen, Spiel wird langsamer statt zu hängen
	alpha = _acc / TICK_S              # 0..1 für die Darstellung
```
**SoA-Heißpfad mit Ganzzahlen und Prüfsumme** (FNV-1a-Variante, int64-Überlauf gewollt, Gerüst wie `core/sim_world.gd checksum()`)
```gdscript
var v_pos := PackedInt32Array()        # je Feld ein Array, Index = Slot
func step() -> void:
	for i in n:
		var p := v_pos[i] + v_speed[i]
		if p >= v_edge_len[i]: p -= v_edge_len[i]      # Überlauf mitnehmen
		v_pos[i] = p
func checksum() -> int:
	var h: int = -3750763034362895579
	for i in n: h = (h ^ (v_pos[i] & 0xFFFFFFFF)) * 1099511628211
	return h
```
**MultiMesh für Fahrzeuge** (Compatibility: ohne `use_colors` und Weiß als Instanzfarbe kam COLOR im Shader schwarz, `proto_fahrzeuge.gd`)
```gdscript
var mm := MultiMesh.new()
mm.transform_format = MultiMesh.TRANSFORM_3D   # VOR instance_count
mm.use_colors = true; mm.use_custom_data = true
mm.mesh = mesh; mm.instance_count = anzahl
mm.custom_aabb = AABB(Vector3(-4000, -100, -4000), Vector3(8000, 400, 8000))   # Instanzen wandern weit
mmi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF           # wir interpolieren selbst
mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, gier), pos))       # orthonormal, nie Basen mischen
mm.set_instance_custom_data(i, Color(gang, 0.0, nicken, wanken))
```
**Sichtweite mit Hysterese statt harter Kante, Fern-LOD als zweites MultiMesh**
```gdscript
nah.visibility_range_end = 650.0;  nah.visibility_range_end_margin = 30.0
fern.visibility_range_begin = 650.0; fern.visibility_range_begin_margin = 30.0
n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF      # Kleinteile
```
**Fahrlinie: Polylinie in Tabelle je 1 m, Lookup O(1)** (`aus_polylinie`, `punkt(s)`, `gier(s) = atan2(dx, dz)`, Modell-Vorne = +z; Lauf: 200 m Winkel, Gier 90° und 0° korrekt [V]). Gier immer aus der Tangente, nie lineare Mischung der Basis: Kernfehler "Schuhkarton" (Basis bei 90°-Ecke auf ca. 71 % gestaucht).
**Optionaler Hook ohne class_name-Zwang** (für Dateien, die ein anderer Agent liefert)
```gdscript
if not ResourceLoader.exists(PREFABS): return null
var s: GDScript = load(PREFABS)
if s == null or not s.has_method("mesh_fuer"): return null
```
**Save atomar** (getestet [V]: Zielfile existiert, .bak, Korruption fällt auf .bak zurück, int64 bleibt int64): `FileAccess.open(tmp)`, `store_string(var_to_str(daten))`, `flush()`, `get_error() == OK`, Datei schließen (`f = null`), `.bak` kopieren, `DirAccess.rename(tmp, ziel) == OK` prüfen. **Nicht JSON für Prüfsummen und große Ints** (Abschnitt A3).
**Test-Gerüst**: `extends SceneTree`, `_initialize(): _run.call_deferred()`, `pruef(ok, text)`, am Ende `quit(1 if fails > 0 else 0)`; außen `timeout 300 godot --headless --path slice -s res://tests/x.gd | tee log; grep -c "SCRIPT ERROR" log`.

## A3 Schwellwerte, Zahlen und Verhalten (alle mit Quelle oder Versuch)

| Aussage | Wert | Beleg |
|---|---|---|
| Physik-Tick Standard / Beispiel Interpolation | 60 Hz Standard, Doku-Beispiel 10 Hz bei 60 FPS = jede Pose 6 Frames | Q15 |
| Interpolation kostet Latenz | Anzeige hinkt etwa einen Physik-Tick hinterher (bei 10 Hz = 100 ms) | Q15 |
| Interpolationsanteil abfragbar | `Engine.get_physics_interpolation_fraction()` (4.7.2: vorhanden, 0,22 gelesen) | Q15, [V] |
| Gaffer Frame-Klemme | 0,25 s je Frame | Q3 |
| Typisierung | Optimierte Opcodes bei bekannten Typen; Messung 2020 (Debug-Build, veraltet): Operationen +25 bis 50 %, native Aufrufe bis +120 bis 150 %, Subscript +5 bis 7 % | Q19, Q20 [E, alt] |
| Typisierung in 4.7.2 | `var x := d.get("a", 0)` ist FEHLER (Variant-Inferenz, "Warning treated as error"); `var x: int = d.get("a", 0)` nutzen | [V] |
| Compatibility | niedrige Grundkosten, hohe Skalierungskosten; keine Compute-Shader, kein MSAA-Alpha-to-Coverage, 8 Lichter je Mesh; Automatic Instancing nur Forward+, nicht Compatibility | Q25, Q17 |
| Folge für Spielerstraßen | Jede Straßenzelle als MeshInstance3D = ein Draw Call. Bündeln (render_batch.gd) senkte 4.068 auf 482 DC | [R] sprints/s7/block-b/felix2.md |
| MultiMesh | Culling nur für das ganze MultiMesh (alles oder nichts): mehrere MultiMeshes je Gebiet; `visible_instance_count` | Q16 |
| MultiMesh-Transform lesen | `multimesh_instance_get_transform` liefert CPU-Cache, nicht GPU-Stand; headless liefert (0,0,0) | Q27, [V] |
| Headless | `--headless` = Display-Treiber headless + Audio Dummy; Renderinfo 0 Dreiecke / 0 DC [V]; Fenster 64 x 64: mit `stretch canvas_items + expand` ergibt `get_visible_rect()` 1600 x 1600 [V]; xvfb + opengl3 liefert 1600 x 900 [V] | Q22, Q26 |
| Exit-Code | `--check-only` nur parsen (mit `--script`); Exit 0 trotz SCRIPT ERROR [V]; `--import` startet den Editor, wartet, beendet; `--` trennt Nutzerargumente (`OS.get_cmdline_user_args()`) | Q22, [V] |
| `--check-only` Lücke | meldet nicht: `get_tree().change_scene(...)`, `load(p).instance()`, `Tween.new().interpolate_property(...)`; meldet: yield, onready, export, rand_range, stepify, range_lerp, deg2rad, File, Transform(), PoolVector3Array, setget, tool, OS.get_ticks_msec, Basis.xform. Also Laufzeit-Smoke zusätzlich fahren | [V] |
| class_name | Ohne `.godot/global_script_class_cache.cfg` oder bei neuer Datei nach Pull: "Identifier not declared" + Folgefehler "Cannot infer the type". `--import` behebt. `preload("res://pfad.gd")` per Konstante funktioniert ohne Cache | [V], Q2 |
| .uid | Godot 4.4+ legt `skript.gd.uid` an; committen, sonst brechen UID-Referenzen im Klon; extern verschobene Dateien mit ihrer .uid verschieben | Q1 |
| `--import` erzeugt .uid | neue Skripte bekommen beim Import eine .uid, im Klon also nach Pull untracked Dateien | [V] |
| JSON | `JSON.parse_string` liefert jede Zahl als float; Ganzzahl über 2^53 verliert Stellen: Prüfsumme -3750763034362895579 kam als -3750763034362895360 zurück. `var_to_str` / `str_to_var` erhält int64 | [V] |
| CSV in res:// | wird mit `csv_translation` zu Translation importiert, die Spaltenköpfe werden zu Locale-Dateien (`*.translation`). Doku: `*.translation` ignorieren. TSV/TXT bleiben unberührt | Q23, [V] |
| Groß/Kleinschreibung | PCK ist case-sensitive, Windows nicht: snake_case klein durchgängig | Q24 |
| Zeilenenden | `core.autocrlf input` oder `.gitattributes` `* text=auto eol=lf` (im Repo nur binäre Muster vorhanden) | Q23, [R] .gitattributes |
| Tween | `await tween.finished` wird nach `tween.kill()` nie fortgesetzt (Coroutine hängt dauerhaft) | Q43, [V] |
| Visual Profiler | nur Render-CPU, nicht Skript/Physik; Monitors zeichnen auf; Skript-Backtrace in Release: "Always Track Call Stacks" (4.5+) | Q28, Q34 |
| Shader Baker (4.5+) | Export-Option, Ladezeit auf Windows D3D12/Metal etwa 20-fach kürzer im TPS-Demo; Pipeline-Kompilierung bleibt | Q34 [E] |
| GUT | `-gdir`, `-gexit`, `-gexit_on_success`, `-gjunit_xml_file`; Exit 0/1 | Q32 |
| gdUnit4 | master (v7.0.0) für Godot 4.7/4.7.1; Scene Runner, Mocks, Parametrisierte Tests, Fuzzer, JUnit-XML, GitHub-Action. Headless-Hinweise stehen in der Doku, nicht auf der README-Seite | Q31 |
| Spatial Partition | Gitter bei gleichmäßiger Verteilung, Quadtree bei Klumpen/Leere, BSP nur statisch; Zellgröße größer als größte Abfragedistanz | Q8 |

## A4 Godot-3-Rückfälle: Regel statt Gedächtnis
Trainingsdaten sind Godot-3-lastig. Vor jedem unbekannten Aufruf: `godot --doctool` Dump (im Projekt: `/tmp/claude-0/gd/doc472`, `/tmp/claude-0/gd/docs47`) greppen, dann `--check-only`, dann ein Laufzeit-Smoke (check-only ist lückenhaft, A3). Typische Ersetzungen (alle von der Engine bestätigt [V]): `yield` -> `await`; `connect("s", obj, "m")` -> `s.connect(callable)`; `onready/export/tool/setget` -> `@onready/@export/@tool` + Property-Setter; `rand_range` -> `randf_range`; `stepify` -> `snapped`; `range_lerp` -> `remap`; `deg2rad` -> `deg_to_rad`; `OS.get_ticks_msec` -> `Time.get_ticks_msec`; `Spatial/KinematicBody/translation/rotation_deg` -> `Node3D/CharacterBody3D/position/rotation_degrees`; `File.new()` -> `FileAccess.open`; `parse_json` -> `JSON.parse_string`; `Transform()` -> `Transform3D()`; `PoolVector3Array` -> `PackedVector3Array`; `change_scene` -> `change_scene_to_file`; `.instance()` -> `.instantiate()`; `Basis.xform(v)` -> `basis * v`; `OS.window_fullscreen` -> `get_window().mode`.

## A5 Checklisten

**Vor Merge**: (1) `--import` im Zielklon, (2) `--check-only` auf alle geänderten Skripte, (3) betroffene Suiten einzeln, (4) volle Regression nacheinander (nie parallel zu anderen Läufen), (5) `git status`: keine fremden `.uid`, keine Logs, keine `.translation`, (6) Hook-Zeilen statt Umbauten in main.gd, (7) Slice bitgleich, wenn nicht ausdrücklich geändert (md5 der Referenz-CSV).
**Perf-Zahl veröffentlichen**: Etikett (gezählt / live / headless), Renderziel (xvfb llvmpipe oder Zielrechner), Ansicht, Anzahl Läufe, Gate-Wert. Keine FPS aus Sandbox.
**Neue Sim-Regel**: Ganzzahl, Prüfsumme prüfen (E1-Muster: an = aus = ohne Bild), Parität alt/soa wo vorhanden, Test mit festem Seed.
**Export**: Presets mit `include_filter` für Nicht-Ressourcen (data/*.json, world/data/*), kein `globalize_path` auf res://, Templates auf dem Export-PC, `--export-pack` als Teilprobe ohne Templates.
**Hänger-Schutz**: jeder Testlauf mit `timeout`, jede `await`-Kette mit Ausstieg, Tweens nie mit `await tween.finished` und `kill()` mischen.

## A6 Quellen (URL, Belegstärke)
Q1 https://godotengine.org/article/uid-changes-coming-to-godot-4-4/ (offiziell, Jan 2025)
Q2 https://github.com/godotengine/godot/issues/75388 (class_name-Cache, offen, 4.0 bis 4.1 berichtet)
Q3 https://gafferongames.com/post/fix_your_timestep/ (Standardreferenz)
Q4 https://gafferongames.com/post/floating_point_determinism/ (Stand "ungeklärt")
Q5 https://gameprogrammingpatterns.com/game-loop.html
Q6 https://gameprogrammingpatterns.com/data-locality.html
Q7 https://gameprogrammingpatterns.com/dirty-flag.html
Q8 https://gameprogrammingpatterns.com/spatial-partition.html
Q9 https://www.factorio.com/blog/post/fff-421 (Optimierungen 2.0, mit Zahlen)
Q10 https://www.factorio.com/blog/post/fff-317 (Pfadsuche neu, ohne Zahlen)
Q11 https://www.factorio.com/blog/post/fff-121 (Pfad-Cache, ohne Zahlen)
Q12 https://redblobgames.com/pathfinding/tower-defense (Flow Field, ohne Zahlen)
Q13 https://redblobgames.com/blog/2024-04-27-flow-field-pathfinding
Q14 https://wiki.openttd.org/en/Archive/Manual/Yet%20Another%20Pathfinder (YAPF; kein Knotenlimit genannt)
Q15 https://docs.godotengine.org/en/stable/tutorials/physics/interpolation/physics_interpolation_introduction.html (Auszug; Details zu MultiMesh nicht verifiziert)
Q16 https://docs.godotengine.org/en/stable/tutorials/performance/using_multimesh.html (Seite als veraltet markiert)
Q17 https://docs.godotengine.org/en/stable/tutorials/performance/optimizing_3d_performance.html
Q18 https://docs.godotengine.org/en/stable/tutorials/performance/general_optimization.html
Q19 https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/static_typing.html
Q20 https://godotengine.org/article/gdscript-progress-report-typed-instructions/ (2020, Debug-Build)
Q21 https://github.com/godotengine/godot-docs/issues/10300 (Packed-Arrays, Doku-Widerspruch)
Q22 https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html
Q23 https://docs.godotengine.org/en/stable/tutorials/best_practices/version_control_systems.html
Q24 https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html
Q25 https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html
Q26 https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_dedicated_servers.html (sagt nichts zum Dummy-Renderer)
Q27 https://github.com/godotengine/godot/issues/108847 (MultiMesh-Cache, Doku-Problem laut Maintainer)
Q28 https://docs.godotengine.org/en/stable/tutorials/scripting/debug/debugger_panel.html
Q29 https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html (kein Versionierungsrat, kein Resource-Sicherheitshinweis)
Q30 https://bugnet.io/blog/game-save-best-practices-godot (Einzelblog mit Fehlern: Version 1/2 inkonsistent, Backup-Fallback nicht umgesetzt; nur Ideenquelle)
Q31 https://github.com/MikeSchulze/gdUnit4
Q32 https://gut.readthedocs.io/en/latest/_sources/Command-Line.md.txt (GUT-Version für 4.7 nicht geprüft)
Q33 https://github.com/godotengine/godot/issues/72825 (Hot Reload mit externem Editor, 4.0 beta, ungelöst)
Q34 https://godotengine.org/releases/4.5/
Q35 https://docs.godotengine.org/en/stable/tutorials/inputs/inputevent.html
Q36 https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html

---------------------------------------------------------------------------------------------------
# TEIL B: Wissen für Mega Tycoon (nur Belegtes, Datei in Klammern; Repo: /home/claude/mega-tycoon)
---------------------------------------------------------------------------------------------------

## B1 Architektur und Dateistruktur
- **Projekt**: Godot-Projekt liegt in `slice/` (project.godot: Features 4.7, `gl_compatibility`, Fenster 1600 x 900, stretch `canvas_items` + `expand`, `physics_ticks_per_second=10`, `physics_interpolation=true`, Einstellung `mega_tycoon/welt="slice"`). Hauptszene `start_menu.tscn`.
- **Sim-Kern** `core/sim_world.gd` (RefCounted, kein Node): SoA, fester Tick 10 Hz (`TICK_HZ`), Ganzzahlen in mm (1 Feld = 1000 mm `feld_mm`), Blockreservierung, Deadlock-Erkennung ereignisgesteuert (Bestätigung nach `DEADLOCK_CONFIRM_TICKS = 5`), Linienbetrieb (`add_line_vehicle`), Prüfsumme FNV-1a `checksum()` (Kommentar im Kopf: `economy == null` = Verhalten wie S3). `core/net_graph.gd` Graph und A*, Kantenlänge = ceil(Luftlinie). `core/diagnostics.gd` Ort+Ursache-Texte.
- **Ökonomie** `economy.gd` (RefCounted, `attach(sim)`, Lizenzen, Kredit in Cent, Daten `data/economy_slice.json`, `economy_constants.json`, `vehicles.json`, `goods.json`), `credit.gd`, `eco_shim.gd`.
- **Fahrzeug-Darstellung** `fleet_soa.gd` (Routen aus A*-Feldpfad `AStarGrid2D`, nur waagrecht/senkrecht, Eckpunkte als Knoten, Puffer für 3 MultiMeshes, `RENDER_SPLIT` verteilt das Füllen über Frames, `main.gd` Zeile 50), `vehicle.gd` (alter Kern, Rückfall `--fahrzeuge=alt`), `vehicle_soa.gd`, `render_batch.gd` (statische Quader als MultiMesh je Material und 64 x 64-Kachel).
- **Spiel** `main.gd` (3.612 Zeilen, 161 Funktionen, Singleton-artig: Sim, UI, Werkzeuge, Kamera). Änderungen als Hook-Zeilen, nie als Umbau: `world_s7`-Hooks (`map_path`, `setup_camera`, `apply_zoom`, `hoehe_at`, `build_terrain`), `dist_str(felder)`, `set_vehicle_heights(grid, w, fn)`. Eingabe `_unhandled_input`, Tick `_physics_process` (`for i in speed: sim_tick()`), Darstellung `_process`.
- **Welten** `world/welt.gd`: Priorität `Main.world_override` > `--welt=` > ProjectSettings > "slice". S7: 1 Feld = 25 m, Kamera 40 m bis 5,6 km, Szeneneinheit bleibt 1 Feld = 1,0 (`sprints/s7/block-a/felix.md`). Generator `tools/world_gen.py`, Validator `tools/world_validate.py`, Karte `world/data/world_s7.json`, gleicher Seed = gleiche md5.
- **Prototyp-Welt** (Design-Sprint Phase 4, eigene Szene, Sim und Slice unberührt): `proto/prototyp_welt.tscn/.gd`, `proto_strassenband.gd` (Band je Weg, Douglas-Peucker 11 m, Kreisbögen R 25 m Dorfstraße / 50 m Chaussee, Brücken, Fahrlinie `strecke_punkt/gier/kruemmung`, `sim_auf_s`), `proto_sim.gd` (ProtoSim-Adapter: eigener SimWorld + Economy, Graph aus Fahrlinien-Ankern, mm = m x 40, Kette Farm - Mühle - Dorf, 3 Fahrzeuge), `proto_easing.gd` (nur Darstellung, K27-K31), `proto_fahrzeuge.gd` (ein MultiMesh je Kategorie, INSTANCE_CUSTOM: x Gang, y Variante, z Nicken, w Wanken), `proto_platzhalter.gd`, `proto_kulissen.gd`, `proto_schilder.gd`, `proto_epochen.gd`, Gelände `world/proto_terrain.gd`, `world/proto_prefabs.gd`. Daten `world/data/proto/`, Testdaten `proto/testdaten/`. Skripte `tools_proto/*.py` (immer `python3 -I`).
- **Daten-Verträge**: JSON als Quelle der Wahrheit (`slice_map.json` + Schema, `regelwerk.json`, `proto_*.json`). Schema-Drift ist real: `slice_map.schema.json` verlangte noch `hq_optionen[].startkapital_cent`, Validator war schon rot (`sprints/s6/block-b/karte.md`).

## B2 Befehle (Godot: `/tmp/claude-0/gd/Godot_v4.7.2-stable_linux.x86_64`)
- Import (Pflicht im frischen Klon, erzeugt class_name-Cache und .uid): `godot --headless --path slice --import`
- Parsen: `godot --headless --path slice --check-only -s res://tests/xyz.gd`
- Headless-Suite: `godot --headless --path slice -s res://tests/proto_welt_test.gd` (Ausgabe `N/M Prüfungen OK`, Exit 0 nur bei grün, dazu auf "SCRIPT ERROR" greppen)
- Mit Renderer (Fenster 1600 x 900, nötig für Perf live, Schilder, echte Maus): `xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --path slice -s res://tests/proto_mass.gd`
- Spielen: `godot --path slice -- --welt=s7`; Prototyp: `-- --proto` oder Taste P im Startmenü; Bench: `-- --bench`; alter Fahrzeugkern: `-- --fahrzeuge=alt`; Startjahr: `-- --startjahr=JJJJ`; ohne Menü `--modus=neu|beispiel` (`start_menu.gd`).
- Kurzsuite: `bash tests/run_tests.sh <godot> <shot_dir>` (slice_test soa 74/74, alt 74/74, parity 8/8, s11 16/16, Screenshots)
- Volle Regression: `bash tests/d07_regression.sh <godot> /home/claude/mega-tycoon/spikes` aus `slice/` (Standardpfade im Skript sind sandboxfest eingebrannt)
- Spielwerkzeug für Agenten: `tools/play.sh <ordner> [--no-shot] [--fast] [--budget=<s>] [--bg] [--welt=s7]` mit `commands.txt` (`tests/play_session.gd`, `tools/play_help.md`)
- Prototyp-Suiten (Stand Integration + Fix-Pass): proto_epochen 17, proto_strassenband 36, proto_welt 35, proto_easing 15 OK + 2 ABW, proto_sim 11, proto_band_hoehe 2, proto_schilder 51, proto_mass 95, proto_fixpass 12, proto_terrain 15, ta_import 6, ta_welle2 23 (`sprints/s8/design-sprint/phase4/integration_w2.md`, `fixpass_w2.md`)

## B3 Perf-Gate und Messwerte (Zählwerte, keine FPS, Sandbox llvmpipe; `tests/perf_s7.gd`)
- Gate relativ: Dreiecke, Draw Calls oder Objekte > +10 % gegen `tests/perf_s7_baseline_slice.csv` = rot (`GATE := 1.10`). Neue Baseline nur nach Absprache mit QA und mit Begründung im Bericht.
- Gate absolut S7 (`S7_LIMITS`): Übersicht <= 1.000.000 Dreiecke und <= 300 DC (nur Lauf mit 0 Lkw), Stadt nah <= 2.900.000.
- 6 Kameras (Übersicht 4,3 km, Stadt nah 700 m, Stadt Straße 160 m, Mine 420 m, Farm 900 m, Rand max.) je 0 und 5.000 Lkw.
- S7-Ergebnis: Übersicht 0,76 M / 250 DC, Stadt nah 1,15 M, Ladezeit 2,0-2,2 s (`sprints/s7/review_retro.md`).
- Draw Calls mit 5.000 Lkw: 4.068 -> 482 nach Quader-Bündelung; die Fahrzeuge selbst waren 2 DC, Ursache waren 3.366 Straßenfelder + 100 Lager als Einzel-Nodes (`sprints/s7/block-b/felix2.md`). Die ursprüngliche Annahme "Fahrzeuge sind die Ursache" war falsch und wurde durch Ausblend-Messung korrigiert. Die Retro nennt außerdem einen Perf-Messfehler um Faktor 2,5, durch Nachrechnen gefunden; dessen Detail steht im Repo nicht.
- Prototyp-Gate: <= 1,0 M Dreiecke / <= 300 DC live, Markt <= 2,9 M, Ladezeit `_ready` <= 3 s. Live (xvfb) Übersicht 3 km 145.702 / 111 DC; ungünstigster Abstand 1,8 km 734.508; Markt 514.611 / 62; See 778.858 / 144; Laden 1,4-1,6 s.
- **Die 1,62 M Dreiecke waren die gezählte Zahl ohne Frustum- und Sichtweiten-Culling, live max. 0,62 M** (`phase4/felix_perf_aufschluesselung.md`): 70 Baum-MultiMeshes, 11.500 Bäume à 129 Dreiecke = 91,9 %. Folge: Messsuite zählt zusätzlich "gezählt mit Sichtweite" und live; headless zählt MultiMeshes konservativ als sichtbar (Dummy-Renderer). Empfehlung Baum-LOD (Kreuzquad ab 600 m, Hysterese 50 m) geht an TA.
- Zielrechner (Windows, Ryzen 7 5800X3D, RTX 3080 Ti, Compatibility, 1600 x 900, VSync aus): 5.000 Lkw median 89,7 FPS, p95 22 ms, Streuung 2,7 % (`sprints/s6/messung/f12_zielrechner_01-11.txt`). Einzige echte FPS-Messung; danach nur noch Zählwerte.
- Easing-Kosten E8: p95 0,34 ms je Frame für 10 Fahrzeuge (Ziel 0,5 ms).

## B4 Regressionssuite `tests/d07_regression.sh` (21+ Suiten, Zusammenfassung `tests/d07_regression_summary.md`)
- Inhalt in Reihenfolge: run_tests.sh, d07_abnahme (ui 31, kredit 17, parity 12, lager 2, hq 30), d08_bankrott (3 Städte x 100 Seeds x 30 Spielminuten, 265 s; Bankrottquoten 15/17/18 %), d08_lizenzfaktor 8, s7_mira 33, s7_w04 31, s7_city 114, s7_u03 125 (xvfb), u03_play je Welt (12 Ablehnungen, 0 stumm), s7_industrie 66 (xvfb), s7_start 31 (xvfb), d08_maus 27 (xvfb, echte Maus), s7_boot (default 39, `--welt=s7` 29), s7_validator (md5 + 20 Seeds), perf_s7 (xvfb), Spikes sim-core und f04-signal (auf Kopien), statische Prüfungen.
- **Laufzeit**: 488 s (S6), 648 s (S7 Block B), 1.090 s (Summary im Repo), 1.361 s (P4 W1), 1.565 s = 26 min (P4 W2, `phase4/felix_welle2.md`). Wachstum durch xvfb-Suiten (jede startet Godot mit Software-GL) und d08_bankrott. Läufe nacheinander, nie parallel (Zeitwerte schwanken, Shader-Übersetzung llvmpipe).
- Die Suiten prüfen Fehler per `grep -c "SCRIPT ERROR"` zusätzlich zum Exit-Code (richtig, siehe A1.9). **Lücke**: im Skript steht kein einziges `timeout` (`grep -c timeout` = 0 in d07_regression.sh und run_tests.sh); ein hängender Test blockiert alles. play.sh hat ein eigenes Zeitbudget (`--budget`, 100 s).
- Statische Prüfung B-2 (kein `globalize_path` zusammen mit "kenney" oder `append_from_file` in einer Zeile) ist zeilenbasiert: `world/proto_prefab_bau.gd` Zeilen 33 und 37 liegen auf getrennten Zeilen, die Regel greift dort nicht [R, eigene Beobachtung]. Ein früherer Fehlalarm kam aus einem Kommentar (`world/art/kit_test.gd:28`, behoben durch Kommentar-Strip).
- Modal-Verbot: statische Prüfung sucht AcceptDialog, ConfirmationDialog, FileDialog, Popup* im Code (Bastis Wunsch: keine grauen Standard-Modale).

## B5 Merge-Workflow (belegt)
- Pro Block: Arbeitskopie, Regression, Merge, Push (`sprints/s7/refinement/ergebnis.md`). Merge-Gate S7: alle Suiten grün + Perf-Gate.
- Neuer Code nach `world/` oder `proto/`; main.gd nur Hook-Zeilen "vermeidet Merge-Konflikte in den ~3.000 Zeilen" (`sprints/s7/refinement/tech.md`). Tatsächliche Konflikte lagen nur an Hook-Zeilen, `_toast` und entfernten Startdialog-Blöcken (`sprints/s6/block-b/mira.md`).
- Rohmerge zuerst, danach Integration: P4 W2 (`169e75f`, `12c4f3f`). Doppelte Hooks, tote Testhooks und doppelte Belegung von `INSTANCE_CUSTOM` wurden erst in der Integration beseitigt (`integration_w2.md` I1, I6, I7). Stub ohne `class_name` vermeidet Konflikt mit der echten Klasse (`felix_welle1.md`).
- `.uid`: Commit `89d6c9e` nahm sie aus dem Index ("Konflikt mit lokalem Klon"), `337fb5b` und `cd57358` committen sie wieder; heute 228 `.uid` im Index, 0 Skripte in slice ohne `.uid`. Das entspricht Q1. `.gitignore` ignoriert `.godot/`, `*.import`, `d07_logs`, `*_output.txt`, `d08_logs_*`, `*.translation`, aber nicht `.uid`.
- Eine Testdatei war in `.gitignore` gelistet und musste mit `git add -f` hinein (`integration_w2.md` §7). `.csv.import`-Dateien der Perf-Baselines liegen im Repo (`tests/perf_s7_baseline_*.csv`) und erzeugen `*.translation`-Müll.
- Ticket-Branches `f-04-...`, Merge nach QA-Review (README). Commit-Stil: knappe deutsche Betreffzeile.

## B6 Prototyp-Tasten (`proto/prototyp_welt.gd`)
WASD/Pfeile schieben, Q/E drehen, Mausrad Zoom 40 m bis 3 km, rechte/mittlere Maustaste drehen, linke ziehen = schieben. 1-5 Presets (Übersicht, Dorf, Markt, Fluss, See). V Wasser A/B, G Easing an/aus (Start an), M Modelle aus/an, N Schilder, F Kamera folgt (Fuhrwerk 1, 2, Postkutsche, aus), T Bildtempo 1x / 1/4x (nur Ansicht), H HUD, F11 oder Alt+Enter Vollbild (`Window.MODE_FULLSCREEN`), Esc Startmenü. Spiel (`main.gd`): 1-5 Werkzeuge, X Abriss, Leertaste/P Pause, Esc/Rechtsklick abbrechen.

## B7 Stolpersteine mit Lösung (aus dem Repo)
| Stolperstein | Beleg | Lösung |
|---|---|---|
| Schuhkarton: Fahrzeug schrumpft in 90°-Ecke | `proto_sim_anbindung.md`: Basis zweier Ticks linear gemischt (MultiMesh FAST) | Fahrlinie, Gier aus Tangente, eigenes MultiMesh ohne Engine-Interpolation; Test E7 Norm 1,0000 |
| E5/E6 Easing-Widerspruch | `felix_welle2.md` §4, `integration_w2.md` I9-I11 | Kurvenfaktor 0,70, Radius 25 m bei 11 m Abweichung; E6 bleibt "ABW bewusst" 1,30 / 1,38 x W/2 |
| COLOR im Shader schwarz | `proto_fahrzeuge.gd` Kopfkommentar | `use_colors = true` und `set_instance_color(i, WHITE)` |
| Headless kennt keine MultiMesh-Transforms | `felix_welle2.md` §7, [V] | Gate live unter xvfb, headless nur Info |
| Float-Rundung im Takt-Test (4/5 Ticks) | `integration_w2.md` §2 | Rest 0,5 definieren |
| Kommentar widerspricht Code | `proto_easing.gd` Kopf nennt INSTANCE_CUSTOM x Gangphase 0..1, y Wippen; `proto_fahrzeuge.gd` und I7 sagen x Gang m, y Variante | Kommentar nach jeder Integration gegenlesen |
| Fahrzeuge neben dem 3,5-m-Feldweg | `fixpass_w2.md` M1 | `Profil.spur_fuer(fahrbahn_m)`, Spur-Wechsel über 10 m dreifach geglättet |
| Einsinken des Bands an Geländekanten | `felix_welle1.md` Nr. 10 | `hoehe_at` exakt auf Mesh-Dreiecken, Querschnitt deckt Wölbung ab |
| Tests auf Platzhalterkarte rot, sobald echte Karte kommt | `sprints/s7/review_retro.md` | Tests auf der echten Karte schreiben, sobald sie existiert |
| Spiel und Validator rechnen verschieden | Retro S7 | gleiche Regel an beiden Stellen (Brückenrampe als Vorbild) |
| xvfb-Läufe schwanken, Wanduhr falsch | `mira.md` S6: 0,35 s Wanduhr ergab 0 Ticks | Ticks über 5 Physik-Frames messen, nie Wanduhr |
| 3D-Rendering macht Zocker-Läufe langsam | `felix_harness.md` | `root.disable_3d = true` während der Befehle; `RenderingServer.render_loop_enabled=false` verworfen (Toast-Panel bekam 2230 px) |
| class_name erst nach `--import` bekannt | `ta_welle2.md` §11, `aylin_welle2.md` ("nach --import"), [V] | `--import` zuerst; kritische Pfade per `preload(Pfad)` |
| Kenney-GLB nicht im Export | `sprints/s6/block-c/daniel.md` B-2, `felix.md` | `props/kenney_loader.gd load_root`: importierte PackedScene vor GLTFDocument, kein `globalize_path` |
| Pfade der Sandbox im Skript eingebrannt | `d07_regression.sh` Kopf, `play.sh`, `run_tests.sh` | als Argument/Umgebungsvariable (`GODOT`) übergeben; Windows-PC (Basti, `C:\Dev`) kann die Bash-/xvfb-Suiten nicht nativ fahren |
| `.gitignore` verschluckt neue Testdatei | `integration_w2.md` §7 | `git add -f` oder Eintrag anpassen |

## B8 Offene technische Punkte (Stand 03.11.)
Spline-Straßenband und Easing sind im Prototyp, noch nicht im Spiel (Ticket E-01, `proto_sim_anbindung.md`). Terrain-LOD (Geomipmapping), Baum-LOD, `_mouse_cell` schneidet noch die Ebene y=0 (`sprints/s7/block-b/mira.md`), Initial-Window-Fix und neuer Bench auf Bastis Rechner (Retro S7), Steigungs-Hooks `steigung_faktor/steigung_max_pct` in `s7_world.gd` (Platzhalter), Save/Load nicht vorhanden (im Repo kein Spielstand-Code gefunden).

---------------------------------------------------------------------------------------------------
# TEIL C: Eigene Lücken und Lernstand
---------------------------------------------------------------------------------------------------

## C1 Gelernt (mit Beleg, Konfidenz hoch = Versuch oder Doku + Repo)
1. class_name-Cache: fehlender oder veralteter Cache führt zu "Identifier not declared"; `--import` löst, `preload(Pfad)` umgeht. Konfidenz hoch [V, Q2]. Der Repo-Vorfall selbst ist nicht dokumentiert, nur die Gegenmaßnahme (`--import` in Aufrufen).
2. `.uid` committen ist offizielle Linie (Q1), das Repo ist jetzt konform. Konfidenz hoch.
3. Zählzeile ehrlich etikettieren: gezählt / live / headless. Konfidenz hoch [R, V].
4. Test-Hänger und Exit-Code: Konfidenz hoch [V]. Lücke im Repo: kein `timeout`.
5. JSON ist für int64 und Prüfsummen ungeeignet, `var_to_str` ist es. Konfidenz hoch [V].
6. `--check-only` ist kein Ersatz für einen Laufzeit-Smoke. Konfidenz hoch [V].
7. Headless ist kein Renderziel: Transform-Identität, 0 Dreiecke, 64 x 64 Fenster. Konfidenz hoch [V].
8. Fester Tick + Darstellung: Muster sitzt, Factorio-Idee (Absicht speichern, Darstellung vorhersagen) passt auf unseren Easing-Ansatz. Konfidenz mittel bis hoch.

## C2 Weiter unsicher (ehrlich)
- Ob `DirAccess.rename` über eine vorhandene Datei auf Windows atomar ist: nur auf Linux geprüft. Konfidenz niedrig für Windows.
- Ob `MultiMesh.set_buffer_interpolated` in 4.7.2 für unseren Fall (10-Hz-Tick, 60+ FPS) sichtbar besser wäre als unser eigener Ansatz: Doku-Auszug nennt es nicht, nicht gemessen. Konfidenz niedrig.
- Flow Field oder Segment-A* für wachsende Fahrzeugzahlen: Quellen haben keine Zahlen; für unseren Graphen (Knoten = Wegenden, ca. 900 im Prototyp) nicht gemessen. Konfidenz niedrig.
- gdUnit4 oder GUT statt Eigenbau: kein belastbarer Vergleich gefunden; nur Fähigkeiten gelistet. Umstieg nicht empfohlen ohne Pilot. Konfidenz niedrig.
- Hot Reload im Editor mit unserem Setup (godot-editor-mcp, Basti lokal): nur ein offenes Issue (Q33) gelesen. Konfidenz niedrig.
- Windows: Exe-Export, Fullscreen exklusiv gegen randlos, HiDPI-Fenster ("Initial-Window-Fix"): nur Doku (Q36), nie auf Bastis Rechner geprüft. Konfidenz niedrig.
- Save/Load: Ideen aus Q29/Q30, nichts gebaut oder gemessen. Konfidenz niedrig.

## C3 Priorisierte Lernfragen (12) mit Stand der Antwort
1. class_name/.uid/Import nach Pull: beantwortet (A3, B2). Offen: automatischer Import-Schritt in jedem Skript.
2. Perf messen: gezählt vs live vs Culling: beantwortet (B3). Offen: Zielrechner-Messung der Prototyp-Welt.
3. Headless vs xvfb: beantwortet (A3). Offen: Welche Suiten brauchen wirklich xvfb (Aufteilung schnell/langsam).
4. Determinismus und Float: beantwortet (A1.3, V). Offen: Easing-Prüfsumme E1 auf Windows gegen Linux (Plan `plan/daniel.md`).
5. Interpolation und Fahrlinie: im Prototyp gelöst; Überführung ins Spiel offen (E-01).
6. Regression 26 min: Ideen (nicht umgesetzt): Stufen "Schnell" (run_tests + betroffene Suiten) und "Voll", `timeout` je Suite, d08_bankrott nur nachts, xvfb-Suiten bündeln. Konfidenz mittel.
7. Test-Framework: Eigenbau behalten, aber `pruef()`-Hilfe in eine gemeinsame Basisklasse (21 Kopien), `timeout` einführen. Pilot gdUnit4 nur für UI (Scene Runner).
8. Pfadsuche bei vielen Fahrzeugen: A* je Linie reicht heute (Linien statisch); bei Netzwachstum Segmentgraph (YAPF-Idee) vor Flow Field.
9. Merge: Hooks beibehalten, main.gd langfristig aufteilen (3.612 Zeilen); `.gitattributes` um `* text=auto eol=lf` ergänzen (Windows-Klon).
10. Fahrlinie/Spline: beantwortet im Prototyp (Tabelle je 1 m, Radius, 11 m Abweichung). Offen: Weichen/Kreuzungen mit Vorfahrt.
11. Save/Load-Robustheit: Entwurf A2 (atomar, .bak, Version, `var_to_str`); nicht umgesetzt.
12. Windows/Export: Teilprobe `--export-pack` vorhanden; Exe nie gebaut (keine Templates in der Sandbox). Offen auf Bastis Rechner.

## C4 Selbstregeln ab jetzt
Vor jeder Engine-API-Zeile Dump greppen. Jede Zahl mit Etikett. Jede Suite mit `timeout`. Jede neue `class_name`-Datei: `--import` im Aufruf. Kein JSON für Prüfsummen. Kein `await tween.finished` neben `kill()`. Headless nie für Layout- oder Renderzahlen.
