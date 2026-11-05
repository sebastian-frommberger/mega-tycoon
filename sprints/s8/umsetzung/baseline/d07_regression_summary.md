# D-07 Regression, Sprint 5 (2026-11-05, Godot 4.7.2.stable.official.ed1daf0bf, Sandbox)

| Suite | Ergebnis | Detail |
|---|---|---|
| run_tests.sh (slice_test soa, slice_test alt, parity_test, 0 SCRIPT ERROR) | OK | slice_test (soa) 74/74 Prüfungen OK, Laufzeit 5.5 s (Sandbox);slice_test (alt) 74/74 Prüfungen OK, Laufzeit 5.3 s (Sandbox);parity_test      8/8 Paritätsprüfungen OK;s11_test         16/16 Prüfun |
| d07_abnahme --only=ui | OK | 31/31 Abnahmeprüfungen OK, Laufzeit 15.6 s (Sandbox)  |
| d07_abnahme --only=kredit | OK | 17/17 Abnahmeprüfungen OK, Laufzeit 4.6 s (Sandbox)  |
| d07_abnahme --only=parity | OK | 12/12 Abnahmeprüfungen OK, Laufzeit 4.4 s (Sandbox)  |
| d07_abnahme --only=lager | OK | 2/2 Abnahmeprüfungen OK, Laufzeit 4.3 s (Sandbox)  |
| d07_abnahme --only=hq | OK | 30/30 Abnahmeprüfungen OK, Laufzeit 1.5 s (Sandbox)  |
| d08_bankrott (100 Seeds je Stadt) | OK | 10/10 Prüfungen OK, Laufzeit 106.1 s (Sandbox) mittelfurt 15/100 = 15 %;haberau 17/100 = 17 %;kohlberg 18/100 = 18 %;  |
| d08_lizenzfaktor (Vorschau gegen Spielpreis) | OK | 8/8 Vorschau-Lizenzfaktoren stimmen mit dem Spielpreis überein |
| s7_mira (Z-01 + B-xx Regression) | OK | == 33/33 Prüfungen OK  |
| s7_w04 (Kacheln, Autotile, Brücke, Hang-Preis, Straße:Block) | OK | 31/31 Prüfungen OK  |
| s7_city (W-03 Städte: Radius, Ausfransung, Gebäude, Zonen, Leerfläche, Bäume, Nachfrage) | OK | 114/114 Prüfungen OK  |
| s7_u03 (Fehlertexte beide Welten, Vorwarnung, Kopfleiste, Linienliste; xvfb) | OK | 125/125 Prüfungen OK  |
| u03_play slice (play.sh alle Bau-Fehlerfälle, 0 stumm) | OK | u03_play welt=slice: 12 Ablehnungen, davon stumm 0 (Soll 12 / 0), play.sh Exit 0 |
| u03_play s7 (play.sh alle Bau-Fehlerfälle, 0 stumm) | OK | u03_play welt=s7: 12 Ablehnungen, davon stumm 0 (Soll 12 / 0), play.sh Exit 0 |
| s7_industrie (W-05 Fläche+Icon+Name, 4 km ≥ 24 px, kein Überlappen, Status, U8; xvfb) | OK | 66/66 Prüfungen OK  |
| s7_start (Startmenü, Beispielnetz slice+s7, Einnahmen, kein Menü in Tests; xvfb) | OK | 31/31 Prüfungen OK  |
| d08_maus (echte Maus, xvfb) | OK | 27/27 Prüfungen OK  |
| s7_boot (default) | OK | 39/39 Prüfungen OK, Laufzeit 1.9 s (Sandbox)  |
| s7_boot (arg: --welt=s7) | OK | 29/29 Prüfungen OK, Laufzeit 1.2 s (Sandbox)  |
| s7_validator (Generator md5, Validator, 20 Seeds) | OK | Determinismus: Seed 7 neu erzeugt, 0 von 6 Dateien abweichend (Soll 0);Karte world/data: VALIDIERUNG OK (0 Verstoesse);20 Seeds: 20/20 OK (0 Verstöße, lösbar); |
| perf_s7 (slice, 6 Kameras x 0/5.000 Lkw, Gate +10 %) | OK | perf_s7 Prüfungen OK (12 Messwerte, Gate +10 %)  |
| Spike sim-core (run_smoke.sh) | OK | test_runner Exit 0, f06_smoke Exit 0, SCRIPT ERROR Zeilen: 0 |
| Spike f04-signal (run_smoke.sh) | OK | test_runner Exit 0, f06_smoke Exit 0, SCRIPT ERROR Zeilen: 0 |
| Statische Prüfungen (JSON, Icons >= 24, keine Modal-Klassen, Tween-Konstanten, Export-Filter) | OK | JSON gültig: ja;Icons: 33 (Soll >= 24), Dateien fehlen: [];Modal-Klassen im Code: keine;Übergangskonstanten: Hover 100 ms, Slide 150 ms (Soll <= 150);Export include_filter deckt ui/assets und data/*.json ab: True;B-2:  |

Gesamt: GRÜN, Laufzeit 524 s. Logs: tests/d07_logs/. Keine FPS-/Zielrechner-Aussage (Sandbox, headless).
