# F-10 Zwischenstand mit Prüfsumme (Felix, Tag 2, 01.12.)

Hinweis: Dieser Stand wurde im selben Arbeitslauf wie F-11 erzeugt; die Zahlen stammen aus den Läufen im Ordner `core/` (Sandbox, Editor-Binary Linux, 2 vCPU Xeon 2,8 GHz).

**Stand:** `core/sim_world.gd` ist auf SoA umgebaut (Fahrzeuge, Positionen, flache Routen, Blockhalter als PackedArrays). Der Graph enthält nur noch die statische Struktur. Die Diagnose liest über Zugriffsfunktionen. Regeln und Prüfsummenformel sind unverändert zum Spike.

**Tests:** `run_smoke.sh` liefert Exit 0. test_runner und f06_smoke sind grün, es gibt 0 SCRIPT ERROR. Die Ausgabe des alten Testteils (S1–K6) ist bis auf die Laufzeitzeile zeichengleich zum Sprint-2-Spike, auch die gedruckten Prüfsummen. Daniels D-04-Lauf und der B8-Replay liefern dieselbe Ausgabe wie im Spike.

**Teständerung (einzige):** In K3 steht `c.set_vehicle_speed(2, 3000)` statt `c.vehicles[2]["speed"] = 3000`. Grund: `vehicles` ist jetzt eine Lesesicht.

## Prüfsummen Bench-Welt (bench_world.gd, Seed 1001 + n, nach 300 + 3000 Ticks)

| Größe | Prüfsumme (3 Läufe identisch) | Spike-Kern gleiche Welt |
|---|---|---|
| 1k | 4674943293165125399 | gleich (K10 / Bench) |
| 5k | -2133718692161873935 | gleich (aequivalenz_gross, 33 Vergleiche) |
| 10k | 6365397789658686807 | gleich (aequivalenz_gross, 33 Vergleiche) |

Die Deadlock-Ereignisse in der Bench-Welt sind gleich zum Spike: 5k hat 3, 10k hat 11, jeweils mit gleichen Mitgliedern und Ticks (`core/aequivalenz_gross_output.txt`).

**Offen nach Tag 2:** die Zielrechner-Messung (Szene in `zielrechner_bench/`) und der Release-Export (F-12).
