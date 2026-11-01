# D-07 Regression, Sprint 5 (2026-11-01, Godot 4.7.2.stable.official.ed1daf0bf, Sandbox)

| Suite | Ergebnis | Detail |
|---|---|---|
| run_tests.sh (slice_test soa, slice_test alt, parity_test, 0 SCRIPT ERROR) | OK | slice_test (soa) 70/70 Prüfungen OK, Laufzeit 8.2 s (Sandbox);slice_test (alt) 70/70 Prüfungen OK, Laufzeit 8.6 s (Sandbox);parity_test      8/8 Paritätsprüfungen OK;s11_test         14/14 Prüfun |
| d07_abnahme --only=ui | OK | 30/30 Abnahmeprüfungen OK, Laufzeit 18.8 s (Sandbox)  |
| d07_abnahme --only=kredit | OK | 16/16 Abnahmeprüfungen OK, Laufzeit 7.6 s (Sandbox)  |
| d07_abnahme --only=parity | OK | 12/12 Abnahmeprüfungen OK, Laufzeit 7.4 s (Sandbox)  |
| d07_abnahme --only=lager | OK | 2/2 Abnahmeprüfungen OK, Laufzeit 6.3 s (Sandbox)  |
| Spike sim-core (run_smoke.sh) | OK | test_runner Exit 0, f06_smoke Exit 0, SCRIPT ERROR Zeilen: 0 |
| Spike f04-signal (run_smoke.sh) | OK | test_runner Exit 0, f06_smoke Exit 0, SCRIPT ERROR Zeilen: 0 |
| Statische Prüfungen (JSON, Icons >= 24, keine Modal-Klassen, Tween-Konstanten, Export-Filter) | OK | JSON gültig: ja;Icons: 27 (Soll >= 24), Dateien fehlen: [];Modal-Klassen im Code: keine;Übergangskonstanten: Hover 100 ms, Slide 150 ms (Soll <= 150);Export include_filter deckt ui/assets und data/*.json ab: True; |

Gesamt: GRÜN, Laufzeit 132 s. Logs: tests/d07_logs/. Keine FPS-/Zielrechner-Aussage (Sandbox, headless).
