# Daniel Richter (QA): Abnahme F-06 und B8-Fix, 27.11.2026

Alle Läufe selbst ausgeführt (Godot 4.7.2 headless, 2 vCPU, Kopie von `felix/spike/`). Belege in `daniel/`. Die md5 aller 16 Quelldateien stimmen mit `build_md5.txt` überein. Es gibt keinen Export und keinen sha256.

## Ergebnisse
- **Smoke (Protokollvorlage v2, Abschnitt 6): grün.**
  - 51 × OK, 0 × FEHLER, 0 × SCRIPT ERROR.
  - 3/3 Fehler auslösbar, Titel T_STEHT ×3, jede Kette endet in der Wurzelzeile (D9, 15/15 Zeilenklicks).
  - 3.000 Ticks danach bestehen die Fehler weiter, Ketten gültig, 0 Fehlalarme bei den Kontrollzügen.
  - Klick-Log: 8 Spalten, `unix_ms` 13-stellig, Replay-Prüfsumme gleich.
- **B8 behoben.** Replay Tick 3451 liefert eine gültige Kette (vorher SCRIPT ERROR unter 4.4.1). Mein Zusatzlauf: 3 Netze × 6.000 Ticks, jeder Tick, 24.502 Warte-Fahrzeug-Ticks, davon 459 im B8-Zustand: 0 leere, 0 ungültige Ketten, 0 Deadlock-Fehlalarme. Mein altes Harness validierte B8-Fälle nicht, das schließt `daniel_b8_alleticks.gd`.
- **D-04 v2: 6 Szenarien × 3 Varianten × 2 Läufe = 36/36 OK**, plus 6 Normalnetz-Läufe mit 0 Ereignissen.
- **run_smoke.sh:** Exit 0. Die Ausgabe gleicht Felix' Dateien bis auf Laufzeit und Endtick (4353 gegenüber 4352).

## Gate
- **G3: Grün** (6/6, 0 Fehlalarme in 6.000 Ticks, die ich als 10 min setze). Sandbox-Lauf; die Belegstufe setzen Jonas und Katrin.
- **G4: Grün** (9/9, Smoke 3/3, jeweils ≥ 120 s sichtbar).

## Neue Bugs
- Keine Blocker oder Major.
- Gering: Der Smoke prüft „Vorschlag ausgeblendet“ nicht. Im Quelltext fehlt der Vorschlagsblock (Grep ohne Treffer), aber ohne Test.
- Gering: Der Endtick ist nicht deterministisch (kosmetisch, Prüfsumme je Endtick gleich).

## Abnahmeempfehlung F-06: **mit Auflagen**
1. Export mit sha256 am Zielrechner (bisher nur md5 der Quellen).
2. Pilot mit Lena, vorher Vorschlag-Prüfpunkt manuell abhaken.
3. Lena bestätigt die Abweichungen: F3 „1 von 40“ und 37 min Auflösung, F2 mit 4 Zügen, Panel 267 px bei 720p.

Nicht geprüft: Lesbarkeit am Bildschirm, 30-min-Dauerlauf, echte Hardware.
