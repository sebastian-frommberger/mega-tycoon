# F-10/F-11 Messung am Zielrechner (Bastis PC, Ryzen 7 5800X3D, Windows, Godot 4.7.2, Editor-Build)

| Lauf | 10k Median | p95 | p99 | Max | Deadlock-Prüfung Median |
|---|---|---|---|---|---|
| 5.000 Ticks, Lauf 1 | 2,318 ms | 3,069 | 3,837 | 4,227 | 0,058 ms |
| 5.000 Ticks, Lauf 2 | 2,312 ms | 2,877 | 3,635 | 4,672 | 0,057 ms |
| 5.000 Ticks, Lauf 3 | 2,271 ms | 2,732 | 3,292 | 4,080 | 0,056 ms |
| 3.000 Ticks, Lauf 1–3 | 2,28–2,34 ms | 2,79–3,16 | 3,37–3,81 | – | – |

- Akzeptanzkriterium F-10 (≤ 4,0 ms Median, p99 ≤ 6 ms über 5.000 Ticks, 10k): ERFÜLLT im Editor-Build. Release-Export fehlt noch (F-12).
- Determinismus: Prüfsummen je Größe in 3 Läufen identisch. Zusätzlich identisch zur Linux-Sandbox (3.000 Ticks: 1k 4674943293165125399, 5k -2133718692161873935, 10k 6365397789658686807) → plattformübergreifend deterministisch.
- F-11: Deadlock-Prüfung ereignisgesteuert kostet bei 10k 0,06 ms (vorher ~4,4 ms im Spike).
- 8x: Frame (8 Ticks) bei 10k ~19 ms Median → über 8-ms-Budget; Vorschlag nötig (z. B. 8x nur bis 5k oder Sim auf eigenem Thread).
Rohdaten: bench_core_out.txt, bench_core_t5000_out.txt. Gemessen vom Koordinator über Godot-MCP.
