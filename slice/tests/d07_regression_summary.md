# D-07 Regression, Sprint 5 (2026-11-02, Godot 4.7.2.stable.official.ed1daf0bf, Sandbox)

| Suite | Ergebnis | Detail |
|---|---|---|
| run_tests.sh (slice_test soa, slice_test alt, parity_test, 0 SCRIPT ERROR) | OK | slice_test (soa) 74/74 Prüfungen OK, Laufzeit 11.3 s (Sandbox);slice_test (alt) 74/74 Prüfungen OK, Laufzeit 11.4 s (Sandbox);parity_test      8/8 Paritätsprüfungen OK;s11_test         16/16 Prüf |
| d07_abnahme --only=ui | OK | 31/31 Abnahmeprüfungen OK, Laufzeit 20.1 s (Sandbox)  |
| d07_abnahme --only=kredit | OK | 17/17 Abnahmeprüfungen OK, Laufzeit 12.6 s (Sandbox)  |
| d07_abnahme --only=parity | OK | 12/12 Abnahmeprüfungen OK, Laufzeit 9.8 s (Sandbox)  |
| d07_abnahme --only=lager | OK | 2/2 Abnahmeprüfungen OK, Laufzeit 10.1 s (Sandbox)  |
| d07_abnahme --only=hq | OK | 30/30 Abnahmeprüfungen OK, Laufzeit 1.9 s (Sandbox)  |
| d08_bankrott (100 Seeds je Stadt) | OK | 10/10 Prüfungen OK, Laufzeit 236.4 s (Sandbox) mittelfurt 2/100 = 2 %;haberau 38/100 = 38 %;kohlberg 39/100 = 39 %;  |
| d08_lizenzfaktor (Vorschau gegen Spielpreis) | OK | 8/8 Vorschau-Lizenzfaktoren stimmen mit dem Spielpreis überein |
| s7_mira (Z-01 + B-xx Regression) | OK | == 33/33 Prüfungen OK  |
| d08_maus (echte Maus, xvfb) | OK | 27/27 Prüfungen OK  |
| s7_boot (default) | OK | 31/31 Prüfungen OK, Laufzeit 0.8 s (Sandbox)  |
| s7_boot (arg: --welt=s7) | OK | 26/26 Prüfungen OK, Laufzeit 0.5 s (Sandbox)  |
| perf_s7 (slice, 6 Kameras x 0/5.000 Lkw, Gate +10 %) | OK | perf_s7 Prüfungen OK (12 Messwerte, Gate +10 %)  |
| Spike sim-core (run_smoke.sh) | OK | test_runner Exit 0, f06_smoke Exit 0, SCRIPT ERROR Zeilen: 0 |
| Spike f04-signal (run_smoke.sh) | OK | test_runner Exit 0, f06_smoke Exit 0, SCRIPT ERROR Zeilen: 0 |
| Statische Prüfungen (JSON, Icons >= 24, keine Modal-Klassen, Tween-Konstanten, Export-Filter) | OK | JSON gültig: ja;Icons: 27 (Soll >= 24), Dateien fehlen: [];Modal-Klassen im Code: keine;Übergangskonstanten: Hover 100 ms, Slide 150 ms (Soll <= 150);Export include_filter deckt ui/assets und data/*.json ab: True;B-2:  |

Gesamt: GRÜN, Laufzeit 869 s. Logs: tests/d07_logs/. Keine FPS-/Zielrechner-Aussage (Sandbox, headless).
