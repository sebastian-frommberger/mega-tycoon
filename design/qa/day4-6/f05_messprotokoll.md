# F-05 Benchmark: Messprotokoll (Stand 23.11.2026) – **wartet auf Szene**

Daniel Richter, QA (Messung) · Grundlage `day1-3/daniel/benchmark_pruefplan.md`, angepasst an D7.
**Status: keine F-05-Messung.** In `day4-6/felix/` liegt keine Benchmark-Szene, keine Zahlen von Felix, kein Release-Export. Lauf 1 (20.11.) und Lauf 2/3 (23.11.) haben nicht stattgefunden. Vergleich mit Felix' Zahlen: nicht möglich.

**Sandbox-Hinweis (Pflicht):** Alles in dieser Datei stammt aus einer Sandbox mit 2 vCPU (Intel Xeon 2,8 GHz), 8 GB RAM, **keine GPU**, Software-Renderer, Godot 4.4.1 **Editor-Binary** (kein Release-Export). Das ist nicht der Zielrechner (GTX-1660-Klasse, 6 Kerne, 16 GB; Katrin, unbestätigt). Zahlen von hier zählen nach D7 nicht, auch nicht als „obere Schranke“ mit Gate-Wirkung.

## 1. Messgröße (D7, G2) – festgezurrt

| Größe | Festlegung |
|---|---|
| Ampelwert | **Median Sim-ms pro Tick**, 10.000 Fahrzeuge, 1×, 3 Läufe à 5 min (3.000 Ticks + 300 Warm-up), Release-Export auf Zielrechner, gegen **4 ms** |
| Pflichtangabe | p95 je Lauf (Nearest-Rank), Warnschwelle **6 ms** (nur Bericht, keine Ampel) |
| Nur Bericht | 8× als Sim-ms pro Frame; 1k und 5k (5k entscheidet Gelb: Median ≤ 4 ms nur bis 5k → Rückfallregel D5) |
| Gültigkeit | Fahrzeugzahl konstant im Messfenster; End-Prüfsumme der 3 Läufe identisch; Zustandsstichprobe Tick 100 und 2.000 (Anteil fahrend/wartend) |
| Streuung | Mediane der 3 Läufe > 10 % auseinander → 2 Zusatzläufe, beide Zahlen im Bericht (meine Regel, unbestätigt) |

## 2. Was vorbereitet ist

- **Messhaken `daniel_f05_messhaken.gd`** (im Spike-Ordner lauffähig): misst `Time.get_ticks_usec()` um `SimWorld.step()`, verwirft Warm-up, berechnet N, Median, p95, Max, Mittel, Anteil > 4 ms, schreibt eine CSV-Zeile. Ersatz-Prüfsumme über Zähler (fahrend, wartend, Läufe, Positionssumme, Ereignisse), weil die Sim keine Prüfsumme hat. Felix ersetzt nur `build_scene(n)` durch seinen Szenenaufbau.
- **Protokolltabelle** (leer) wie im Prüfplan Abschnitt 6: 18 Zeilen (6 Konfigurationen × 3 Läufe) plus Zusammenfassung. Spalten: Konf., Lauf, Start, Build-Hash, Export-Typ, CPU-Modell, N, Median, p95, Max, Anteil > 4 ms, Prüfsumme, Zustandsstichprobe, Störung.
- **Reihenfolge:** Runde 1 über alle 6 Konfigurationen in vorab gewürfelter Reihenfolge, dann Runde 2 und 3; ≥ 2 min Pause.

## 3. Funktionsprobe des Hakens (Platzhalter-Szene, **kein Messwert**)

Um den Haken zu prüfen, habe ich ihn mit einer Platzhalter-Szene laufen lassen (Felix' K1-Ausweichgleis-Layout n/2-fach kopiert, alle Fahrzeuge zyklisch, Tag-1–3-Spike-Code), 100 Ticks + 20 Warm-up. Ergebnis in `f05_funktionsprobe_platzhalter.csv`:

| Fahrzeuge | Median ms/Tick | p95 | Max | Anteil > 4 ms |
|---|---|---|---|---|
| 100 | 0,54 | 0,72 | 1,04 | 0 % |
| 1.000 | 4,58 | 7,28 | 8,59 | 87 % |
| 5.000 | 39,7 | 49,5 | 51,2 | 100 % |

**Das ist kein F-05-Ergebnis:** falsche Szene, Sandbox, Editor-Binary, 100 Ticks. Es zeigt nur, dass der Haken Median/p95/Prüfsumme liefert und dass die Kosten im Tag-1–3-Code etwa linear mit der Fahrzeugzahl wachsen (ca. 8 µs je Fahrzeug und Tick auf dieser Maschine). **Risiko-Hinweis an Felix, keine Zahl fürs Gate:** `_detect_deadlocks()` ruft `find_wait_cycles()` jeden Tick für alle Fahrzeuge auf, `step()` sortiert jeden Tick alle IDs (Lesebefunde aus Tag 3). Wenn der Zielrechner nicht um Faktor 10–20 schneller ist als diese Sandbox, ist 10k × 1× ≤ 4 ms mit diesem Code nicht in Reichweite. Das weiß man erst mit seiner Szene und dem Zielrechner.

## 4. Offen (Blocker für die Messung)

| An | Was |
|---|---|
| Felix | Benchmark-Szene mit `build_scene(n)` bzw. eigenem Haken; Release-Export-Templates 4.4.1; Bestätigung, dass Deadlock-Prüfung im Tick bleibt |
| Katrin | Zielrechner mit CPU-Modell, Zugang; ohne ihn bleibt G2 „offen“, nicht Gelb |
| Jonas | 10-%-Streuungsregel und Umgang mit „Editor-Binary statt Export“ (Vorschlag: obere Schranke, keine Ampel) |
