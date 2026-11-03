# Felix (Lead Developer): Resümee (Stand 03.11.2026)

Quellen: Repo `/home/claude/mega-tycoon` (Pfade relativ), Web-URLs im Abschnitt 7. Marken: [Beleg] nachgelesen oder gemessen, [Eindruck] meine Einschätzung, [H] Hypothese.

## 1. Wie ich Spiel und Konzept heute sehe

Technisch trägt der **Sim-Kern**: Structure-of-Arrays, fester Tick mit 10 Hz, ausschließlich Ganzzahlen (mm, Cent), FNV-1a-Prüfsumme für Determinismus, ereignisgesteuerte Deadlock-Prüfung, A*. [Beleg: `slice/core/`, `phase4/felix_welle2.md`: Kette 6.000 Ticks deterministisch] Die Darstellung ist davon getrennt (Fahrlinie statt Kante, Easing nur Optik, K27).

Noch Papier: **Speichern und Laden fehlen**, es wurde nie eine Windows-exe gebaut, die Zielrechner-Messung steht aus, und die Diagnose (`slice/core/diagnostics.gd`) ist nicht in der Oberfläche verdrahtet. [Beleg: Grep, Retros s6/s7] Ein Spiel, das man nicht speichern kann, ist kein Spiel, sondern eine Demo.

## 2. Entwicklungsverlauf aus meiner Sicht

- S2 bis S3: Sim-Kern, Wirtschaft, Slice. [Beleg: `plan/felix.md`, Reviews]
- S4: `MultiMesh.set_buffer_interpolated` im Slice eingebaut (`slice/main.gd` Z. 3484/3485, Qualität FAST). [Beleg]
- S6: Platzhalter-Karte wird durch echte Karte ersetzt, Tests werden rot (1. Mal). [Beleg: Retro s6]
- S7: Welt `--welt=s7` (1 Feld = 25 m), Regressionssuite `tests/d07_regression.sh`; Perf-Zahlen ohne Etikett (Draw Calls, P4 1,62 M) irreführend. [Beleg: `phase4/felix_perf_aufschluesselung.md`]
- S8 Welle 1/2: Prototyp-Welt, ProtoSim (eigener `SimWorld`, 899 Knoten), Easing-Probe **13 OK / 4 FAIL** (E5, E6), `proto_sim_test` 11/11, `proto_welt_test` 30/30, `proto_mass` 89/89. [Beleg: `phase4/felix_welle2.md` §3]
- Zahl: `main.gd` 3.612 Zeilen; 76 Commits in drei Tagen (01. bis 03.11.). [Beleg]

## 3. Was gut lief (belegt)

1. Determinismus ist getestet, nicht behauptet: 200 Getreide an der Mühle, 190 Mehl im Dorf, 40 Wenden, reproduzierbar. [Beleg: `proto_sim_test`]
2. Welle 2 hat **keine Bestandsdatei geändert** (Slice, S7, Sim, `main.gd` unberührt). [Beleg: `felix_welle2.md` §1]
3. Messungen mit Folge: Ankerprojektion O(n) statt O(n²) senkte Wege von 590 auf 180 ms; Band-Höhenfehler von +0,084 m auf -0,145 m (Gelände unter Fahrbahn). [Beleg: `proto_band_hoehe_test`]
4. Ehrliche Abweichung dokumentiert: gleitender Mittelwert verworfen, weil er den Halt W-1 Ticks zu spät erreicht (E5). [Beleg: §2 Punkt 2]

## 4. Was nicht gut lief, wiederkehrende Kompromisse (mit Zähler)

| Kompromiss | Zähler | Beleg |
|---|---|---|
| Perf-Zahlen ohne Etikett (Messung vs. Schätzung, Szene vs. Gesamtwelt) | 2 (S7 Draw Calls, P4 1,62 M) | `felix_perf_aufschluesselung.md` |
| Tests auf Platzhalter-Karte, rot bei echter Karte | 2 (S6, S7) | Retros |
| Doku-Drift Code gegen Doku | mindestens 3 | u. a. `proto_schilder.gd` Z. 16 |
| Windows-exe und Zielrechner-Messung vertagt | mehrfach, exe nie gebaut | Retros, `tools/` |
| A-08 Diagnose verschoben (mein Teil: Verdrahtung `diagnostics.gd`) | 4 | Sprint-Reviews |
| Regression ohne Zeitlimit | 1 Fund: d07-Lauf dauert ca. 26 Minuten, `tools/play.sh` enthält 0 Mal "timeout" | `tests/d07_regression.sh`, `tools/play.sh` |

## 5. Wo das Spiel oder das Konzept aus meiner Sicht scheitern könnte

1. **Hoch:** Kein Speichern/Laden und keine exe. Das erste echte Spielerlebnis bei Dritten scheitert an Technik, nicht an Design. [Eindruck, gestützt auf Repo-Stand]
2. **Hoch:** Perf-Annahmen sind für die Zielhardware ungemessen. Alle Zahlen stammen von der Entwicklungsmaschine; die Compatibility-Renderer-Grenzen (MultiMesh-Daten als Half Float) sind nicht ausgetestet. [Beleg: Messdokumente; Eindruck für Folge]
3. **Mittel:** Speicherformat und Windows-Dateisystem: `DirAccess.rename` ist unter Windows **nicht atomar**, ein Absturz beim Speichern kann den Spielstand zerstören. [Beleg, siehe 7]
4. **Mittel:** `main.gd` mit 3.612 Zeilen; Merge- und Regressionsrisiko steigt. [Eindruck]
5. **Niedrig bis mittel:** Zahlenbereich Half Float: bei Positionen um 128 bis 256 m beträgt die Auflösung rechnerisch 0,125 m. Sichtbar nur, wenn Positionen in `INSTANCE_CUSTOM` statt im Transform liegen. [H, eigene Rechnung]

## 6. Meine drei wichtigsten Empfehlungen an Basti für Sprint 8

1. **Speichern/Laden, mit sicherem Schreiben** (in Temp-Datei schreiben, Sicherung der alten Datei behalten, dann umbenennen; kein Vertrauen auf atomares Rename). Aufwand: 1,5 bis 2 Tage inklusive Test. Ohne das kein Playtest mit Dritten.
2. **Eine Windows-Exe bauen und auf einem schwächeren Zielrechner messen**, mit beschrifteten Zahlen (Einheit, Szene, Messart). Aufwand: 1 Tag, davon ein Teil Wartezeit. Ersetzt alle bisherigen unbeschrifteten Perf-Angaben.
3. **Regression mit Zeitlimit und Aufteilung** (schnelle Suite unter 5 Minuten für jeden Commit, lange Suite nachts, `timeout` in `tools/play.sh`). Aufwand: 0,5 Tag. Spart jeden Tag Wartezeit bei 76 Commits in drei Tagen.

## 7. Recherchen dieser Runde

**R1 Atomares Speichern unter Windows.** Frage: Ist `DirAccess.rename` atomar? Quellen: [`dir_access_windows.cpp` (master)](https://raw.githubusercontent.com/godotengine/godot/master/drivers/windows/dir_access_windows.cpp) und ein [Mirror einer älteren Version](https://remotebranch.eu/Stowage/godot/src/commit/8cde69f5f2fa78ebd7651186eb8bd3abae9dfdd5/drivers/windows/dir_access_windows.cpp). Ergebnis: Das Ziel wird zuerst entfernt, dann `MoveFileW`; nicht atomar. Der **Skill hat das falsch geführt**. Sicherheit: hoch, zwei Codestände. [Beleg]

**R2 MultiMesh-Daten im Compatibility-Renderer.** Quelle: [`mesh_storage.cpp` (master)](https://raw.githubusercontent.com/godotengine/godot/master/drivers/gles3/storage/mesh_storage.cpp). Ergebnis: Farbe und Custom-Daten werden als Half Float gespeichert. Sicherheit: hoch für die Aussage; die 0,125-m-Folgerung ist meine Rechnung [H]. Zusatzbefund aus `doc472`-Dump: `set_buffer_interpolated(buffer_curr, buffer_prev)` existiert, `physics_interpolation_quality` kennt FAST (Standard) und HIGH. Mein Skill (C2) führte das als offene Frage; der Slice nutzt es seit S4. Nur HIGH ist ungetestet. [Beleg]

**R3 Godot-Stretch (zur Gegenprobe für Mira).** [Godot-Doku multiple_resolutions](https://raw.githubusercontent.com/godotengine/godot-docs/master/tutorials/rendering/multiple_resolutions.rst): `canvas_items` für Nicht-Pixel-Art. Sicherheit: hoch. [Beleg]

**Offen:** "21 Kopien `pruef()`" im Skill ist ungenau; im Repo finden sich etwa 25 Dateien mit eigenem Helfer (18x `func ok(`, 3x `func pruef`). [Beleg: Grep] Kein Web-Thema.

Lernlog-Zeilen (2026-11-03):
- Situation: Skill behauptete atomares Rename. Lücke: Code der Engine nicht gelesen. Gegenmaßnahme: Plattformverhalten aus Quelltext belegen, nicht aus Gewohnheit.
- Situation: `set_buffer_interpolated` als "offen" geführt, obwohl im Einsatz. Gegenmaßnahme: vor Skill-Eintrag im Repo grepen.
- Situation: Perf-Zahlen ohne Etikett, 2. Fall. Gegenmaßnahme: Jede Zahl mit Einheit, Szene, gemessen oder geschätzt.
- Situation: Regression 26 Minuten ohne Timeout. Gegenmaßnahme: Zeitlimit und Suite-Aufteilung.

## 8. Vorschläge für Skill-Änderungen (nur Vorschläge, nichts geschrieben)

1. `sprints/s8/fortbildung/mt-lead-dev/SKILL.md`, Abschnitt Atomares Speichern: ersetzen durch "Windows-`rename` entfernt das Ziel zuerst, nicht atomar; Temp-Datei, Backup behalten, dann umbenennen", Marker **[K]**. Quelle: R1 (zwei Codestände).
2. Abschnitt C2: `set_buffer_interpolated` von "offen" auf "im Slice seit S4, FAST", Marker **[R]**; HIGH bleibt **[H]**. Quelle: `slice/main.gd` Z. 3484/3485, R2.
3. Neuer Punkt: "Compatibility-Renderer: MultiMesh-Farbe und Custom-Daten sind Half Float; Auflösung bei 128 bis 256 ca. 0,125", Marker **[H]** für die Zahl. Quelle: R2.
4. "21 Kopien `pruef()`" korrigieren auf "ca. 25 Dateien mit eigenem Helfer", Marker **[R]**. Quelle: Grep im Repo.
5. Neue Regel "Jede Messzahl mit Einheit, Szene, Messart; Regression braucht Zeitlimit", Marker **[R]**. Quelle: `felix_perf_aufschluesselung.md`, `tools/play.sh`.
