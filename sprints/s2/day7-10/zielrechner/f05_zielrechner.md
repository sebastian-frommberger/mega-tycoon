# F-05 Messung auf dem Zielrechner (Bastis PC), 24./25.11. (real: 01.11.2026)

Hardware: AMD Ryzen 7 5800X3D (8 Kerne/16 Threads), Windows, Godot 4.7.2-stable official, Editor-Build (Play aus dem Editor über Godot-MCP, kein Release-Export). Szene: Felix' Bench-Runner bzw. SoA-Runner (Tag-7-Stand), als Node-Szene in prototype/_bench verpackt; Welt identisch (Zustandsverteilung T2000 identisch zur Sandbox: 1k 936/64, 10k-SoA 9260/740). 3.000 Ticks + 300 Warm-up, 3 Runden, Tempo 1x (pro Tick identisch zu 8x). Prüfsummen liegen nur in user://-CSV (nicht auslesbar) – Abweichung vom Prüfplan.

| Konfiguration | Lauf 1 Median / p95 | Lauf 2 | Lauf 3 | Bewertung gegen G2 (Median ≤ 4 ms, p95-Warnschwelle 6 ms) |
|---|---|---|---|---|
| Spike 1k | 2,94 / 3,80 ms | 2,06 / 2,29 | 2,06 / 2,28 | ok |
| Spike 5k | 11,47 / 29,08 ms | 10,85 / 12,55 | 10,87 / 13,42 | Rot |
| Spike 10k | 25,58 / 52,87 ms | 22,62 / 34,67 | 22,16 / 29,36 | Rot |
| SoA 1k | 0,19 / 0,20 ms | 0,19 / 0,20 | 0,19 / 0,20 | ok |
| SoA 5k | 0,95 / 1,01 ms | 0,95 / 1,00 | 0,95 / 1,11 | ok |
| SoA 10k | 1,90 / 1,99 ms | 1,90 / 2,00 | 1,90 / 2,06 | ok (ohne Deadlock-Prüfung) |

Einordnung:
- Erster echter Messwert am Zielrechner. Belegstufe: Messung (M) am Zielrechner, aber Editor-Build statt Release-Export → Auflage.
- Spike-Kern (Objekte/Dictionaries) ist auch auf schneller Hardware 5–6x über Budget: Rot.
- SoA-Kern hält 10k mit 1,9 ms Median und ~2 ms p95 klar unter 4 ms, extrem stabil. Fehlt: Deadlock-Prüfung (im Spike ~4,4 ms bei 10k, also ebenfalls auf SoA umzubauen oder ereignisgesteuert).
- Lauf 1 je Größe ist langsamer (Warm-up/JIT-Cache), Läufe 2–3 stabil (<3 % Abweichung).
- 8x: Frame = 8 Ticks → SoA 10k ~15 ms/Frame bei 8x → reißt 8 ms/Frame-Budget, wie in der Sandbox.
Gemessen vom Koordinator über Godot-MCP; Rohdaten: bench_runner_out.txt, bench_soa_out.txt.
