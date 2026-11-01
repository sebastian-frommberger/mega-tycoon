# F-05 Benchmark: Messprotokoll und Nachmessung (Stand 23.11.2026)

Daniel Richter, QA (Messung) · Grundlage `day1-3/daniel/benchmark_pruefplan.md`, D7, Felix' `day4-6/felix/f05_benchmark.md`.
Rohdaten: `f05_daniel_bench_results.csv` (9 Läufe Spike-Sim), `f05_daniel_bench_log.txt`, `f05_daniel_bench_soa_log.txt` (9 Läufe SoA). Messhaken-Vorarbeit: `daniel_f05_messhaken.gd`, `f05_funktionsprobe_platzhalter.csv` (vor Eingang von Felix' Szene, nur Funktionsprobe).

> **Sandbox-Hinweis (Pflicht):** Alle Zahlen hier stammen aus einer Sandbox mit **2 vCPU Intel Xeon 2,8 GHz (geteilte Cloud-VM), 8 GB RAM, keine GPU**, Godot 4.4.1 **Editor-Binary headless, kein Release-Export**. Das ist **nicht** der Zielrechner (GTX-1660-Klasse, 6 Kerne, 16 GB, unbestätigt). Nach D7 zählt nichts davon für G2 (Belegstufe V). **G2 bleibt offen.** Felix und ich haben auf **derselben** Sandbox gemessen; die Nachmessung prüft Reproduzierbarkeit, nicht Hardware-Unabhängigkeit.

## 1. Was ich ausgeführt habe

- Felix' Übergabe-Stand, md5 identisch zu seiner `build_md5.txt`.
- `bench_runner.gd -- --vehicles=1000,5000,10000 --speeds=1 --ticks=3000 --warmup=300 --runs=3` (nur 1×: pro Tick misst 8× dasselbe, weil der Runner ungebremst läuft; das Frame-Budget bei 8× ist nach D7 nur Bericht und folgt aus 8 × Tick).
- `bench_soa.gd -- --ticks=3000 --warmup=300 --runs=3`.
- Reihenfolge wie Felix (Runde 1 über alle Größen, dann 2, dann 3). Gesamt 1.180 s Wanduhr. Felix' Benchmark lief nicht gleichzeitig (geprüft, kein zweiter Godot-Prozess).

## 2. Vergleich mit Felix' Zahlen (Spike-Sim, Median Sim-ms pro Tick)

| Konf. | Daniel: Mediane L1/L2/L3 | Daniel: Median der Mediane | Felix: Median der Mediane | Abweichung | Daniel: schlechtester p95 | Felix: schlechtester p95 | Prüfsumme gleich Felix |
|---|---|---|---|---|---|---|---|
| 1k/1× | 4,61 / 5,38 / 5,88 | **5,38** (Streuung 28 %) | 4,75 (51 %) | +13 % | 9,30 | 9,67 | ja (`4674943293165125399`) |
| 5k/1× | 34,98 / 33,92 / 34,27 | **34,27** (3 %) | 34,06 (3 %) | +0,6 % | 47,50 | 46,37 | ja (`-2133718692161873935`) |
| 10k/1× | 69,81 / 71,83 / 75,44 | **71,83** (8 %) | 67,38 (6 %) | +6,6 % | 101,15 | 98,22 | ja (`6365397789658686807`) |

**SoA-Bewegungskern (ohne Deadlock-Prüfung, ohne Lager):**

| Konf. | Daniel Median der Mediane | Felix | Daniel schlechtester p95 | Felix |
|---|---|---|---|---|
| 1k | 0,195 ms (Streuung 17 %) | 0,20 | 0,43 | 0,42 |
| 5k | 1,05 ms (3 %) | 1,06 | 2,63 | 2,07 |
| 10k | **2,26 ms** (12 %) | 2,18 | **4,97** | 4,73 |

**Befund:** Felix' Zahlen sind auf derselben Sandbox **reproduzierbar**: gleiche Arbeit (Prüfsummen identisch, Zustandsverteilung bei Tick 2.000 identisch), Mediane bei 5k/10k innerhalb von 7 %. Bei 1k ist die Messung in beiden Läufen nach meiner 10-%-Regel **instabil** (Streuung 28 % bzw. 51 %), ebenso SoA 1k und 10k bei mir (17 % / 12 %). Mein 10k-Spike-Wert liegt durchgehend etwas höher (Rauschen der geteilten VM, nicht untersucht). Laut Regel wären je 2 Zusatzläufe fällig; ich habe sie nicht gemacht, weil die Größenordnung (17-fach über Budget) davon nicht abhängt und die Werte ohnehin nicht zählen.

## 3. Bewertung gegen G2 (nur Lesart, keine Ampel)

- **Spike-Sim:** 10k/1× Median 67–72 ms, 5k 34 ms. Auf dem Zielrechner wäre das nur dann ≤ 4 ms, wenn er rund 17-mal schneller wäre als die Sandbox; das halte ich für ausgeschlossen (die Sim läuft einkernig). Erwartung **Rot** für die Spike-Sim, wie Felix.
- **SoA-Kern:** 10k Median 2,3 ms, p95 knapp unter 5 ms (über 4 ms, unter Warnschwelle 6 ms). Das ist ein **Teil** des Sim-Kerns (ohne Deadlock-Prüfung, Ökonomie, Routing). Ob er als G2-Beleg zählt, entscheidet Jonas; aus QA-Sicht höchstens „Teil-Beleg“, nicht Grün.
- **Für das Gate:** G2 bleibt **offen**, bis beide Runner auf dem Zielrechner als Release-Export gelaufen sind (Felix braucht dafür eine Hauptszene, 0,1 T, und Export-Templates). Ohne Zielrechner bis 24.11. greift D8 „Vertagen“.

## 4. Messgröße (D7) – festgezurrt für den Zielrechner

| Größe | Festlegung |
|---|---|
| Ampelwert | Median Sim-ms pro Tick, 10k × 1×, 3 Läufe à 3.000 Ticks (+300 Warm-up; Abweichung von „5 min Wanduhr“ von Felix dokumentiert, ich akzeptiere sie: 3.000 Ticks = 5 min Spielzeit), Release-Export, gegen 4 ms |
| Pflicht | p95 je Lauf (Nearest-Rank), Warnschwelle 6 ms |
| Nur Bericht | 8× als Frame-Wert (8 × Tick), 1k, 5k (5k entscheidet Gelb nach D5) |
| Gültigkeit | Prüfsummen müssen den Sandbox-Werten oben entsprechen; sonst andere Welt, ungültig |
| Streuung | > 10 % zwischen den Medianen → 2 Zusatzläufe |
| Umgebung im Protokoll | CPU-Modell, Takt, Export-Typ, Kommandozeile, md5 der Skripte, Datum/Uhrzeit |

## 5. Offen

| An | Was |
|---|---|
| Katrin | Zielrechner mit CPU-Modell und Zugang; ohne ihn bleibt G2 offen |
| Felix | Hauptszene für den Release-Export (0,1 T), Export-Templates 4.4.1 |
| Jonas | Zählt SoA als Teil-Beleg? Umgang mit instabilen 1k-Werten (Vorschlag: nur Bericht) |
