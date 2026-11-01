# Daniel (QA), Sprint 7, Block A, D-09 Teil 1

Arbeitskopie: `/tmp/claude-0/gd/sprint7/a/daniel/slice` (nur `tools/`, `tests/`). Spielcode unberührt.

## 1. Werkzeug (play.sh / play_session.gd / play_help.md)

| ID | Lösung |
|---|---|
| T-01 | `move_hq <stadt> [ring\|toast]`: echte Maus, Klick auf HQ-Ring (Default) oder Toast, Klick auf Stadt, Klick auf „HQ hierher umsetzen“. `hq_move` startet nur den Modus. Meldet „HQ ist fest“, wenn Frist (2:00) oder erste Lizenz vorbei. Toast ist nur wenige Echtzeit-Sekunden klickbar (Spiel setzt 8 s), sonst `ring`. Geprüft: Mittelfurt → Steinbach (Toast) → Haberau (Ring), danach „fest“ bei exakt 2:00. |
| T-02 | `wait` rechnet wie `_physics_process`: je Schritt `speed` Ticks, danach HQ-Frist/Meldungen. Ergebnis ist tempounabhängig (Sim ist deterministisch); `state.md` nennt die Echtzeit, die das Warten bei dem Tempo gedauert hätte. Dokumentiert. Zeit steht im Umsetzen-Modus (jetzt mit klarer Meldung). |
| T-03 | `drag_start road\|rail <id>`, `drag_to <id>`, `drag_end`, `dblclick <id>`: Zwischenzustände (Esc mitten im Ziehen, Doppelklick) prüfbar. |
| T-04 | `warehouse` meldet Felder außerhalb 0–511 als solche; neu `camera <x> <y> [zoom]`. |
| T-05 | Hilfe: Zoom größer = weiter weg. |
| T-06 | `--no-shot` (spart ca. 10 s), `--fast` (kürzere Pausen), `--budget=<s>` (Default 100: danach ABBRUCH-Vermerk in state.md/log.md, Exit 3, nie über 120 s), `--bg` (Hintergrundlauf mit `fertig`-Datei, ersetzt eigenes `nohup &`). Messung 31 Befehle mit Bild: 91 s (Sandbox unter Last). |
| T-07 | `list` vor der Gründung: „erst nach Gründung“ statt „nicht nötig (Abnehmer)“ (Quote gibt es ohne HQ nicht). Werkzeugtext, kein Spielfehler. |
| T-08 | durch T-02 erledigt: HQ „jetzt fest“ bei 2:00 statt 2:15. |

Offen: kein Befehl für Mausrad/WASD (bewusst, `camera` bleibt Abkürzung).

## 2. Perf-Baseline

- `tests/perf_s7.gd`: 6 Kameras (Übersicht 4,3 km, Stadt nah 700 m, Stadt Straße 160 m, Mine 420 m, Farm 900 m, Rand max. Zoom) × 0 / 5.000 Lkw, Messung Dreiecke / Draw Calls / Objekte (RenderingServer-Monitore), CSV. Braucht xvfb + opengl3 (headless liefert 0 und wird als FAIL gewertet). Ca. 150–300 s je nach Last (Software-GL).
- Parameter: `--welt=slice|s7` (nur Tabelle und `m_pro_feld` im Zoom; Felix' Schalter muss `--welt=s7` selbst aus den Argumenten lesen, perf_s7 reicht sie durch, weil main.gd die Kommandozeile liest), `--lkw=0,5000`, `--out=`, `--check=<baseline.csv>`.
- S7-Tabelle: Kamerafelder = SP-03-Spike-Meter / 25 m (Stadt 297,248; Mine 178,172; Farm 382,308; Übersicht 264,220). Für S7 gelten zusätzlich die Budgets aus D-09 (Übersicht ≤ 1,0 M Dreiecke und ≤ 300 Draw Calls, Stadt nah ≤ 2,9 M). Kamera/Zoom folgt `zoom = Abstand / (25,6 · m_pro_feld)`; wenn Felix' Kamera anders rechnet, Tabelle/Formel anpassen.
- Baseline: `tests/perf_s7_baseline_slice.csv` (zweimal gemessen, identische Zählwerte, reproduzierbar). Gate: Dreiecke, Draw Calls oder Objekte > +10 % = rot. Suite in `tests/d07_regression.sh` (Abschnitt 2e), für die S7-Welt: `PERF_WELT=s7 PERF_BASELINE=<csv>`.

Baseline-Werte Slice (Dreiecke / Draw Calls):

| Ansicht | 0 Lkw | 5.000 Lkw |
|---|---|---|
| Übersicht | 1,11 M / 355 | 1,39 M / 4.068 |
| Stadt nah | 1,09 M / 236 | 1,35 M / 1.345 |
| Stadt Straße | 0,69 M / 209 | 0,69 M / 270 |
| Mine | 1,09 M / 198 | 1,34 M / 665 |
| Farm | 1,09 M / 282 | 1,35 M / 1.595 |
| Rand max. Zoom | 1,10 M / 321 | 1,38 M / 3.946 |

Befund: Der Slice-Draw-Call-Wert mit 5.000 Lkw (bis 4.068 in der Übersicht, 3.946 am Rand) liegt weit über dem S7-Budget von 300 Draw Calls. Die Lkw werden einzeln gezeichnet (Objekte ≈ Draw Calls). Gilt das auch in der S7-Welt, reißt `--welt=s7` das Draw-Call-Gate ohne weitere Maßnahme (nur die Übersicht ist mit Lkw betroffen; das 300er-Budget gilt für die Übersicht, nicht ausdrücklich mit 5.000 Lkw: Klärung mit Felix/Jonas, ob das Budget mit oder ohne Fuhrpark gemeint ist). Das Gate schlägt für `s7` deshalb bewusst auf beide Lkw-Stufen an, bis das geklärt ist.

## 3. Hinweise
- Tempo der Läufe hängt stark von der Parallellast der anderen Agents ab (2 CPUs); die Zählwerte der Perf-Messung nicht.
- Regression: siehe Bericht unten (Stand beim Schreiben der Notiz).
- Regression `bash tests/d07_regression.sh <godot> /home/claude/mega-tycoon/spikes` aus slice/: GRÜN (13 Suiten inkl. perf_s7, 1489 s unter Last). Gate negativ geprüft: manipulierte Baseline (-15 %) ergibt FAIL, Exit 1.
