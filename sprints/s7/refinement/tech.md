# Position TECHNIK + QA – Refinement S7 (Felix, Mira, Daniel)

**Kernaussage:** Die Sim rechnet schon heute in Feldern (`speed = tempo_mm_pro_tick / feld_mm`, Ökonomie in Feldern). 25 m/Feld ist daher **nur eine Darstellungsfrage**: Ökonomie, Bench, Parität und d08 bleiben gleich. Die neue Welt kommt als **zweite Karte hinter einem Schalter**. Der Slice bleibt Default, bis die Regression auf beiden Karten grün ist.

## Architektur neue Welt
- **Maßstab:** `feld_mm` bleibt 1000 (abstrakte Einheit). Neu kommt `m_pro_feld = 25` (nur Render und Texte). Die Szeneneinheit bleibt 1 Feld, Sophies Spike-Meter werden durch 25 geteilt. Tempo, Distanzen und Felderzahlen bleiben gleich, Muehle→Mittelfurt sind damit 3,15 km. Altlast: `diagnostics.FELD_MM = 10000` wird angeglichen.
- **Terrain:** Die Heightmap wird **offline gebacken** (16-bit-PNG 513² + Rand 279²), Chunks laufen im WorkerThreadPool. **Höhe in der Sim: ja, minimal.** Dazu kommen `hoehe[idx]` sowie Steigung → Baukostenfaktor und eine Sperre für „zu steil“. `terrain_at` wird aus Steigung und Flussmaske abgeleitet, so laufen alle Bau-Pfade weiter. **Kein Steigungstempo** (das sichert die Parität). Die Fahrzeughöhe kommt je Feld vorberechnet aus der Trasse und wird nicht pro Frame gesampelt (p95 bei 5.000 Lkw).
- **Trassen:** Die Sim bleibt bei **1 Trasse pro Feld**. Gezeichnet wird ein Spline-Band über den Feldpfad (Straße 7,5/12 m, Gleis 3,8 m). Parallele Gleise in Nachbarfeldern rückt das Rendering auf 5 m zusammen. Echte Mehrgleisigkeit je Feld kommt in S8+.
- **Kartengenerator:** `tools/world_gen.py` erzeugt aus Seed + Regeln die Heightmap, `world_s7.json` (gleiches Schema) und einen Validator. Der Validator prüft: Ketten-Luftlinien in den heutigen Bändern, Nische 25, Industrie auf erlaubtem Gelände, Fluss ≤ 8 Felder überbrückbar, keine Startstadt ohne Kette.
- **Schalter:** `--welt=s7` (Muster wie `--fahrzeuge=alt`). Neuer Code kommt in `world/` (terrain, track_mesh, city_gen), main.gd erhält nur Hooks, das vermeidet Merge-Konflikte in den ~3.000 Zeilen.

## Kandidaten (Tech-Sicht)
| ID | Urteil | T (F/M/D) | Akzeptanz | Risiko |
|---|---|---|---|---|
| W-01 | kleiner | F 1,5 | Kamera 40 m–5,6 km geklemmt, Regression alt unverändert | Fahrzeuge wirken bei Nahzoom schnell |
| W-02 | rein | F 2 | Steigung kostet, Brücke über Fluss, Ladezeit siehe Budget | Flussufer eckig |
| W-03 | kleiner | M 0 | 1 Stadt voll (Kohlberg), Rest per Generator-Parameter | Sophie-Engpass |
| W-04 | rein | F 1, M 3 | **Z-01 behoben (Block A, beide Karten)**, Spline-Trassen, Kreuzungen, Fehlertext statt stumm | Spline auf 25-m-Pfad zackig, Glättung nötig |
| W-05 | kleiner | M 1 | Industrie-Icons in der Übersicht, Regeln als Daten | Bänder halten nicht → Balance offen |
| W-06 | rein | F 2 | gleiche Ausgabe bei gleichem Seed, Validator in Regression | Python-Laufzeit |
| B-xx | rein | M 1,5 | 4 Bugs mit Test | – |
| U-03 | kleiner | M 1,5 | Bau-Fehler nie stumm, Bankrott-Vorwarnung mit Ursache | – |
| A-08 | raus | – | geht in U-03 auf | – |
| D-09 | rein | D 7 | s. Messplan, plus play.sh T-01/T-02/T-06 | Zielrechner nachts nicht verfügbar |
| F-22, SK-02 | raus → S8 | – | – | – |

Summe: Felix 7,5 + 0,5 Puffer, Mira 8, Daniel 8.

## Blöcke (je Merge, Regression, Push)
1. **A (T1–2):** Schalter + Schema (F), Z-01 + B-xx (M), Perf-Baseline Slice + play.sh (D). Ergebnis: Quick Wins im Default-Slice.
2. **B (T3–5):** Generator/Validator + Höhe in der Sim (F, Tobias), Bake (Sophie), Spline-Trassen auf beiden Karten + U-03 (M), Smoke-Suite neue Welt (D).
3. **C (T6–8):** Stadt/Industrie/Rand/LOD (Sophie, Lena), Icons (M), Ladezeit/Threads (F), Perf-Gate (D). Screenshots je Block an Daniel.
4. **D (T9–10):** Abnahme. Default-Wechsel **nur**, wenn beide Suiten grün sind und das Perf-Gate hält, sonst bleibt `--welt=s7` opt-in für Basti.

## Perf-Budget + Messplan (Daniel)
| Größe | Budget | heute |
|---|---|---|
| Dreiecke Übersicht / Stadt nah | ≤ 1,0 M / ≤ 1,8 M | Spike 0,6 / 2,9 M |
| Draw Calls | ≤ 300 | 185–313 |
| Ladezeit | ≤ 3 s Zielrechner (F-12), ≤ 6 s Sandbox | Spike 15–33 s |
| FPS 5.000 Lkw | Median ≥ 60, p95 ≤ 25 ms | 89,7 (ohne Look) |

Messung: `tests/perf_s7.gd` misst 6 feste Kameras (SP-03-Ansichten) × 2 Karten × 0/5.000 Lkw und schreibt CSV (Primitive, Draw Calls, VRAM, Ladezeit). Bei Budget +10 % schlägt die Regression fehl. FPS misst nur Basti am Morgen mit `bench.gd` (D16), nachts zählen Primitive und Draw Calls als Proxy.

## Widersprüche
1. **Sophie:** Mehrere Gleise pro Feld und 5-m-Abstand in der Sim lehnen wir ab, nur als Render-Trick. Ein Netzmodell-Umbau sprengt S7.
2. **Sophie/Tobias:** Tempo und Distanzen nicht real umrechnen. Wenn Basti nach dem Test „zu schnell“ sagt, wird das ein Tuning-Ticket in S8 (nur vehicles.json, dann d08 neu).
3. **Daniel/D-09:** Die Regression **erweitern statt umstellen**. d08_bankrott/lizenzfaktor laufen in S7 nur auf dem Slice.
4. **Lena (W-05):** Lage-Logik nur innerhalb der heutigen Distanzbänder, sonst ist T-14 wieder offen.
5. **TEAM-02:** befürwortet. Sophies ~14 PT kann Felix nicht abfangen.

## Firmenkauf in S7?
**Nein.** Er berührt economy, credit, Bankrott-Bot und UI (6 T), und Mira und Felix sind voll. Außerdem ändern sich die Industrien mit der neuen Karte. Er kommt in S8 auf stabiler Welt.
