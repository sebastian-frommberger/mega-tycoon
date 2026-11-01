# D-07 Regression, Sprint 5 (2026-11-01, Godot 4.7.2.stable.official.ed1daf0bf, Sandbox)

| Suite | Ergebnis | Detail |
|---|---|---|
| run_tests.sh (slice_test soa, slice_test alt, parity_test, 0 SCRIPT ERROR) | OK | slice_test (soa) 72/72 Prüfungen OK, Laufzeit 9.2 s (Sandbox);slice_test (alt) 72/72 Prüfungen OK, Laufzeit 8.9 s (Sandbox);parity_test      8/8 Paritätsprüfungen OK;s11_test         16/16 Prüfun |
| d07_abnahme --only=ui | OK | 31/31 Abnahmeprüfungen OK, Laufzeit 19.1 s (Sandbox)  |
| d07_abnahme --only=kredit | OK | 16/16 Abnahmeprüfungen OK, Laufzeit 8.3 s (Sandbox)  |
| d07_abnahme --only=parity | OK | 12/12 Abnahmeprüfungen OK, Laufzeit 7.8 s (Sandbox)  |
| d07_abnahme --only=lager | OK | 2/2 Abnahmeprüfungen OK, Laufzeit 6.4 s (Sandbox)  |
| d07_abnahme --only=hq | OK | 30/30 Abnahmeprüfungen OK, Laufzeit 1.7 s (Sandbox)  |
| d08_bankrott (100 Seeds je Stadt) | OK | 10/10 Prüfungen OK, Laufzeit 181.3 s (Sandbox) mittelfurt 2/100 = 2 %;haberau 35/100 = 35 %;kohlberg 38/100 = 38 %;  |
| d08_lizenzfaktor (Vorschau gegen Spielpreis) | OK | 8/8 Vorschau-Lizenzfaktoren stimmen mit dem Spielpreis überein |
| d08_maus (echte Maus, xvfb) | OK | 22/22 Prüfungen OK  |
| Spike sim-core (run_smoke.sh) | OK | test_runner Exit 0, f06_smoke Exit 0, SCRIPT ERROR Zeilen: 0 |
| Spike f04-signal (run_smoke.sh) | OK | test_runner Exit 0, f06_smoke Exit 0, SCRIPT ERROR Zeilen: 0 |
| Statische Prüfungen (JSON, Icons >= 24, keine Modal-Klassen, Tween-Konstanten, Export-Filter) | OK | JSON gültig: ja;Icons: 27 (Soll >= 24), Dateien fehlen: [];Modal-Klassen im Code: keine;Übergangskonstanten: Hover 100 ms, Slide 150 ms (Soll <= 150);Export include_filter deckt ui/assets und data/*.json ab: True;B-2:  |

Gesamt: GRÜN, Laufzeit 480 s. Logs: tests/d07_logs/. Keine FPS-/Zielrechner-Aussage (Sandbox, headless).
