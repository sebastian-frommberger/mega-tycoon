# Baseline S8 (QT-01a)

**Stand:** Branch `s8` = `fbe6a2f` (3caae99 + WA-03a), unverändert gemessen im Worktree `s8-qt01`, keine Codeänderung vor der Messung. Godot 4.7.2.stable (`ed1daf0bf`), headless, Sandbox mit 2 vCPU. **Messart: gemessen, Wanduhr, 1 Lauf je Suite** (keine Streuung erhoben, Sekunden sind Richtwerte für die Timeouts, kein Gate). Suiten liefen nacheinander; andere Agenten nutzten die Maschine zeitweise mit (Loadavg 1 min während der Messung: Mittel 1,9, Max 2,7 ab dem gültigen Lauf; davor bis 3,6). Zielrechner-/FPS-Aussage: keine.

**Ergebnis: alle Bestandssuiten grün auf unverändertem Stand, kein Abbruchgrund.**

## Gesamtlauf und Proto-Suiten

| Suite | Exit | Laufzeit s | Commit-Hash | Prüfungen |
|---|---|---|---|---|
| d07_regression.sh (24 Zeilen, ohne Proto-Suiten) | 0 | 523.7 | fbe6a2f | 24 von 24 Zeilen OK |
| proto_sim_test | 0 | 1.6 | fbe6a2f | Prüfungen OK: 11 |
| proto_easing_test | 0 | 6.3 | fbe6a2f | Prüfungen OK: 15 |
| proto_band_hoehe_test | 0 | 1.2 | fbe6a2f | Prüfungen OK: 2 |
| proto_fixpass_test | 0 | 1.2 | fbe6a2f | 12 OK, 0 FAIL |
| proto_schilder_test | 0 | 1.3 | fbe6a2f | 51 OK, 0 FAIL |
| proto_terrain_test | 0 | 0.7 | fbe6a2f | GRUEN (0 Fehler) |
| proto_epochen_test | 0 | 0.3 | fbe6a2f | Prüfungen OK: 17 |
| proto_strassenband_test | 0 | 0.3 | fbe6a2f | Prüfungen OK: 36 |
| proto_welt_test | 0 | 1.2 | fbe6a2f | Prüfungen OK: 35 |
| proto_mass | 0 | 1.5 | fbe6a2f | Messzeilen: 95, FAIL: 0 |
| ta_import_test | 0 | 0.2 | fbe6a2f | GRUEN (0 Fehler) |
| d08_bankrott --n=20 (CSV unten) | 0 | 22.0 | fbe6a2f | 7/7 Prüfungen OK |

## Bausteine der schnellen Stufe (einzeln gemessen, Grundlage der Timeouts)

| Suite | Exit | Laufzeit s | Commit-Hash |
|---|---|---|---|
| slice_test (soa) | 0 | 5.6 | fbe6a2f |
| slice_test (alt) | 0 | 5.6 | fbe6a2f |
| parity_test | 0 | 5.6 | fbe6a2f |
| s11_test | 0 | 0.7 | fbe6a2f |
| d07_abnahme --only=ui | 0 | 16.3 | fbe6a2f |
| d07_abnahme --only=kredit | 0 | 5.3 | fbe6a2f |
| d07_abnahme --only=parity | 0 | 4.8 | fbe6a2f |
| d07_abnahme --only=lager | 0 | 4.3 | fbe6a2f |
| d07_abnahme --only=hq | 0 | 2.0 | fbe6a2f |
| d08_lizenzfaktor | 0 | 1.4 | fbe6a2f |
| s7_boot (Default) | 0 | 2.2 | fbe6a2f |
| s7_boot (--welt=s7) | 0 | 1.7 | fbe6a2f |
| run_tests.sh gesamt (inkl. Screenshot-Lauf unter xvfb) | 0 | 28.1 | fbe6a2f |

Maschinenlesbar: `laufzeiten.txt` (Name, Sekunden). `regress_fast.sh` leitet daraus `timeout = max(60 s, 3 x Wert)` je Godot-Aufruf ab.

## d08-Referenz

- `d08_n20.csv` (60 Zeilen: 3 Städte x 20 Seeds), `d08_n20.md5` = `5cce648a53c1c2f3246147abcaca0988`. Befehl: `"$G" --headless --path . -s res://tests/d08_bankrott.gd -- --n=20 --csv=../sprints/s8/umsetzung/baseline/d08_n20.csv`.
- Determinismus: zweiter Lauf (22,2 s) schrieb eine bytegleiche CSV (gleiche md5). Ein Diff gegen diese Datei ist damit ein Befund für AT-01, kein Rauschen.
- d08 n=100 (Teil von d07): Mittelfurt 15 %, Haberau 17 %, Kohlberg 18 % (Korridor gegen MODELL ±5 Pp, 10/10 grün), 106 s.
- Parameter, die d08_bankrott wirklich nimmt: `--n=`, `--stadt=`, `--csv=` (und Umgebungsvariablen D08_KN/KH/KB).

## Befunde bei der Messung

1. **Erster d07-Lauf verworfen.** Er lief mit einem veralteten Klassencache (`.godot/` im Worktree war vor dem Fast-Forward auf WA-03a erzeugt, `ProtoLicht` unbekannt). Er war grün (747 s unter Loadavg ca. 3,9), die Baseline stammt aus dem sauberen Wiederholungslauf nach `--import` (524 s). Wer neue `class_name`-Dateien zieht, braucht `"$G" --headless --path slice --import`, sonst scheitern Proto-Suiten.
2. **Eine Suite ohne Timeout hängt endlos**, wenn ein Parse-Fehler in `_run` auftritt: `proto_sim_test` lief mit dem veralteten Cache über 10 Minuten bei 0 % CPU (SCRIPT ERROR, kein `quit`). Das ist der Anlass für `timeout` je Aufruf (QT-01b).
3. `proto_easing_test` überschreibt standardmäßig die getrackte Datei `sprints/s8/design-sprint/phase4/proto_easing.csv` (ändert dabei eine Zahl in einer Zeile), `proto_mass` schreibt Standard nach `.../phase4/proto_mass.csv`. In der Baseline: Ausgabe nach `--csv=` außerhalb, die geänderte Datei per `git checkout --` zurückgesetzt.
4. In `d07_regression.sh` (Zeile 1 und Spikes) steht der Text „SCRIPT ERROR“ in den Zeilennamen, ein naives `grep SCRIPT ERROR` über das Gesamtlog schlägt dort falsch an.
5. Nicht gemessen: Perf-Zählwerte als Baseline-Aussage (perf_s7 läuft in d07 und war grün, die Werte stehen in `d07_regression_summary.md`), Streuung der Laufzeiten, Zielrechner.

`d07_regression_summary.md` in diesem Ordner ist die Zusammenfassung des gültigen Laufs (24 Zeilen).
