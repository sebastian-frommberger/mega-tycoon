# Felix – Sprint 3, Tag 1–3

**F-10 SoA-Kern: umgesetzt, Sandbox grün, Zielrechner offen.** Der Kern ist `felix/core/sim_world.gd`. Fahrzeuge, Positionen, Routen und Blockhalter liegen in PackedArrays. Regeln und Prüfsumme sind wie im Spike, `vehicles`, `stations` und `graph.blocks` bleiben als Lesesichten. Einzige Teständerung: K3 schreibt über `set_vehicle_speed()`.

**F-11: umgesetzt.** Die Deadlock-Prüfung läuft nur, wenn ein Fahrzeug neu zu warten beginnt oder ein Block mit Wartenden den Halter wechselt. Der Wende-Deadlock meldet Code DEADLOCK (D9).

## Tests (`core/run_smoke.sh`: Exit 0)
- S1–K6 (Diagnose, kanonischer Ort, B8): Ausgabe zeichengleich zum Spike. f06_smoke ist grün, Daniels D-04-Lauf liefert dieselbe Ausgabe.
- K7 Wende-Deadlock: 10 von 10 Fällen erkannt, jeweils 4 Ticks nach Bildung. Gegenprobe ohne Meldung.
- K8: SoA-Kern = Spike-Kern (`core/ref/`) in 22 Szenarien, Bench 1k, 5k und 10k. Prüfsumme, Ereignisse und Ketten sind gleich. Die Ereignisprüfung liefert in jedem Tick dasselbe wie der Vollscan.
- Determinismus: Die Prüfsumme ist in 3 Läufen identisch (`f10_zwischenstand.md`).

## Sandbox (2 vCPU Xeon, Editor-Binary – kein G2-Wert)
`core/bench_core.gd`: 3.000 + 300 Ticks, Deadlock-Prüfung eingeschlossen, Werte der Läufe 1/2/3:

| | Median ms | p99 ms | 8x-Frame Median ms |
|---|---|---|---|
| 1k | 0,30/0,19/0,32 | 0,57/0,43/0,48 | 1,6–2,7 |
| 5k | 1,19/1,93/1,07 | 2,36/2,90/2,22 | 8,7–15,6 |
| 10k | 3,35/3,85/2,31 | 5,71/5,29/5,22 | 18,6–30,2 |

- Die Deadlock-Prüfung kostet bei 10k im Median 0,08–0,11 ms; der Vollscan im Spike lag bei etwa 4,4 ms.
- `bench_soa` ohne Regeln braucht in derselben Sandbox bei 10k 1,81/1,95/2,22 ms. Der volle Kern kostet also etwa das 1,2- bis 1,9-Fache. Die Sandbox streut stark.
- Bei 8x Tempo wird das 8-ms-Budget weiterhin gerissen.

## Zielrechner (Koordinator)
Den Inhalt von `felix/zielrechner_bench/` nach `res://_bench/` kopieren. Die Dateien heißen `*_soa.gd`, die alten Bench-Dateien bleiben unberührt.
1. `bench_core.tscn` starten. Ausgabe: `res://_bench/bench_core_out.txt`.
2. Optional für die 5.000-Ticks-Akzeptanz: `bench_core_t5000.tscn` starten.

Prüfen:
- 10k: Median ≤4,0 ms, p99 ≤6 ms.
- Prüfsummen gleich den Sandbox-Werten (sie stehen jetzt in der Textdatei).
- T2000 bei 10k: 9260/740.

Gemessen wird im Editor-Build; der Release-Export ist Teil von F-12.
