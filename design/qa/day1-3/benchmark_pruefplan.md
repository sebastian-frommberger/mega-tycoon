# F-05 Benchmark-Prüfplan: Sim-Kern, bleibt GDScript?

Daniel Richter, QA (Messung) · Felix baut Szene und entscheidet · Messung am **23.11.2026** (Felix' Szene: 20.11.)
Status: **Prüfplan fertig, keine Messung.** Es gibt keine Benchmark-Szene (Felix' `felix.md`: „F-05 nicht begonnen“; `felix/spike/` enthält nur den F-04-Code) und keine Bestätigung des Zielrechners. Dieses Dokument enthält **keine Messwerte**. Meine Sandbox (2 vCPU Xeon, 7 GB RAM, keine GPU) ist nicht der Zielrechner. Zahlen von dort würden nicht gezählt (Jonas, Messwert-Regel).

## 1. Gate-Frage und Schwellen

Beschluss: headless 1k/5k/10k Fahrzeuge × 1×/8×, je 3 Läufe à 5 min auf dem Zielrechner (GTX 1660 / 6 Kerne / 16 GB), Median und p95 Sim-ms gegen **4 ms**. Entscheidung „GDScript ja/nein“ und Gate-Folie bis 25.11. (Felix).

Jonas' Gate G2:

| Ampel | Bedingung |
|---|---|
| Grün | Median ≤ 4 ms bei 10k Fahrzeugen (1×) |
| Gelb | Median ≤ 4 ms nur bis 5k, Kartengröße-Rückfall aus F-08 greift |
| Rot | Median > 4 ms bei 5k |

Meine Ergänzungen (zur Bestätigung durch Felix, Jonas bis 19.11.):
- **p95 wird berichtet und ist Warnsignal, steht nicht in der Ampel.** Median ≤ 4 ms bei p95 von z. B. 12 ms bedeutet Ruckler. Vorschlag: p95 > 8 ms bei 1× wird im Gate als Risiko genannt. Die 8 ms folgen aus Felix' Konzept (Sim höchstens 8 ms pro Frame bei 8×). Das ist ein Vorschlag, keine Beschlusslage.
- **Lauf-Streuung:** Weichen die drei Mediane einer Konfiguration um mehr als 10 % voneinander ab, gilt die Messung als instabil, ich ergänze 2 Läufe und nenne beide Zahlen. Die 10 % sind meine Annahme.

## 2. Messmatrix

| # | Fahrzeuge | Geschwindigkeit | Läufe | Dauer je Lauf | Messzeit gesamt |
|---|---|---|---|---|---|
| 1 | 1.000 | 1× | 3 | 5 min + 30 s Warm-up | 16,5 min |
| 2 | 1.000 | 8× | 3 | 5 min + 30 s | 16,5 min |
| 3 | 5.000 | 1× | 3 | 5 min + 30 s | 16,5 min |
| 4 | 5.000 | 8× | 3 | 5 min + 30 s | 16,5 min |
| 5 | 10.000 | 1× | 3 | 5 min + 30 s | 16,5 min |
| 6 | 10.000 | 8× | 3 | 5 min + 30 s | 16,5 min |

18 Läufe, rund 99 min reine Laufzeit (Wanduhr), dazu Pausen und Umbau: einplanen **1 Tag (Daniels 1 T)**.

**Reihenfolge:** Kein Block „erst 3× Konfiguration 1“. Stattdessen Runde 1 über alle sechs Konfigurationen in zufälliger, vorab festgelegter Reihenfolge, dann Runde 2, dann Runde 3. Das verteilt Erwärmung, Boost-Takt und Hintergrundlast gleichmäßig. Mindestens 2 min Pause zwischen Läufen.

## 3. Was gemessen wird und wie

- **Sim-ms pro Tick:** Zeit in `SimWorld.tick()` (Felix' Schnittstelle laut technischem Konzept), gemessen mit `Time.get_ticks_usec()` direkt davor und danach. **Nicht** enthalten: Rendering, UI, Logausgabe, Dateischreiben.
- **Sim-ms pro Frame** (nur 8×): Summe aller Ticks eines Frames, gegen 8 ms (Felix' Konzept).
- **Speicherung:** alle Einzelwerte im Speicher (Array), Ausgabe als Datei **nach** dem Lauf. Kein `print()` pro Tick im Messfenster.
- **Warm-up:** die ersten 30 s Wanduhrzeit werden verworfen und separat gespeichert (Sichtbarkeit von JIT-/Cache-Effekten, GDScript hat keinen JIT, aber Allokation und Cache wärmen sich auf).
- **Kennzahlen je Lauf:** Anzahl Ticks N, Median, p95 (Nearest-Rank: Wert an Position ⌈0,95·N⌉ der sortierten Liste), Maximum, Mittelwert, Anteil Ticks > 4 ms.
- **Kennzahlen je Konfiguration:** Median der drei Laufmediane, schlechtester p95 der drei Läufe, Min/Max der Mediane.
- **Pacing (Vorschlag an Felix, Annahme P1):** Frame-Loop mit festem 60-fps-Takt, Akkumulator liefert bei 1× 10 Ticks/s und bei 8× 80 Ticks/s. 5 min ≈ 3.000 Ticks (1×) bzw. 24.000 Ticks (8×). Läuft die Sim stattdessen „so schnell wie möglich“, ist 1× gleich 8× pro Tick und der Unterschied nur im Frame-Wert sichtbar. Dann steht das im Protokoll.
- **Ausreißer:** werden **nicht** entfernt. Ein Lauf mit nachweisbarer Störung (andere Last, Absturz, Thermik) wird wiederholt, der verworfene Lauf bleibt mit Grund im Protokoll.

## 4. Gültigkeit der Läufe (Prüfsumme)

Alle drei Läufe einer Konfiguration müssen **dieselbe Arbeit** leisten. Prüfung:
- Fahrzeugzahl konstant über den Lauf (kein Spawn/Despawn im Messfenster).
- Seed fest (Vorschlag 1001 / 5001 / 10001, vorher festgelegt); Fahrzeugmix und Netz je Größe identisch.
- **End-Prüfsumme des Sim-Zustands** nach Ablauf identisch in allen drei Läufen. Das setzt voraus, dass die Sim eine Prüfsumme liefert (technisches Konzept: Prüfsumme pro Tick, F-04/F-05 fordern sie aber nicht ausdrücklich). Ohne Prüfsumme: Vergleich einfacher Zähler (Fahrzeuge in Bewegung, wartend, gelieferte Einheiten). Weicht eine Konfiguration ab, ist die Messung ungültig.
- **Last-Beschreibung im Protokoll:** Anteil fahrend/wartend/ladend, durchschnittliche Routenlänge. Ein Benchmark mit 10.000 stehenden Fahrzeugen sagt nichts. Ich fordere vor der Messung von Felix eine Stichprobe (Tick 100 und Tick 2.000: Zustandsverteilung).

## 5. Messumgebung (Zielrechner)

Vor dem ersten Lauf zu protokollieren und einzufrieren:

| Punkt | Eintrag |
|---|---|
| Rechner (Name, CPU-Modell, Kernzahl/Threads, RAM, GPU, Treiber, Betriebssystem) | _(Katrin liefert 16.11.; **nicht bestätigt**)_ |
| Entspricht der Zielhardware GTX 1660 / 6 Kerne / 16 GB? | ja / nein, Abweichung |
| Energieprofil „Höchstleistung“, CPU-Governor `performance` (Linux) | |
| Hintergrundprogramme beendet, Updates/Indexer aus, kein Browser | |
| Godot-Version | 4.4.1 stable (Binary: `/tmp/claude-0/gd/Godot_v4.4.1-stable_linux.x86_64`) |
| **Build-Typ** | Editor-Binary / Debug-Export / **Release-Export** (siehe unten) |
| Kommandozeile (wörtlich) | |
| Git-Hash der Szene | |
| Datum, Uhrzeit, Raumtemperatur/CPU-Temperatur wenn auslesbar | |

**Build-Typ ist eine Messfalle.** Das mitgelieferte Godot-Binary ist ein Editor-Build, kein Release-Export. GDScript läuft im Release-Export-Template anders als im Editor- bzw. Debug-Build. Als Gate-Wert gilt **nur ein Release-Export** (oder, falls keine Export-Templates vorliegen, der Editor-Build mit klarem Vermerk „obere Schranke, ungeprüft gegen Release“). Ob Export-Templates 4.4.1 auf dem Zielrechner verfügbar sind, ist offen. Frage an Felix.

## 6. Protokolltabelle (leer, wird nur mit echten Messwerten gefüllt)

Je Lauf (18 Zeilen):

| Konf. | Lauf | Start | Build-ID | N Ticks | Median (ms) | p95 (ms) | Max (ms) | Anteil > 4 ms | End-Prüfsumme | Störung? |
|---|---|---|---|---|---|---|---|---|---|---|
| 1k/1× | 1 | | | | | | | | | |
| … | | | | | | | | | | |

Zusammenfassung für die Gate-Folie:

| Fahrzeuge | Tempo | Median der 3 Mediane (ms) | schlechtester p95 (ms) | Streuung Mediane (min–max) | gegen 4 ms | Lauf gültig |
|---|---|---|---|---|---|---|
| 1.000 | 1× | | | | | |
| 1.000 | 8× | | | | | |
| 5.000 | 1× | | | | | |
| 5.000 | 8× | | | | | |
| 10.000 | 1× | | | | | |
| 10.000 | 8× | | | | | |

## 7. Auswertung und Entscheidung

- Daniel liefert Zahlen, Felix entscheidet („GDScript ja/nein“, Gate-Folie), Jonas wertet G2 aus.
- **Grenzfälle:** Median knapp unter 4 ms bei hohem p95, oder Median über 4 ms bei 10k, aber unter 4 ms bei 5k: das ist Gelb und kommt mit Zahlen auf die Folie, nicht mit „sieht gut aus“.
- Fehlt der Zielrechner oder ein Lauf, ist das Kriterium weder Grün noch Gelb, die Entscheidung wird vertagt (Jonas).
- **Gekürzter Plan:** Rutscht F-04, wird F-05 laut Beschluss auf den 10k-Lauf gekürzt. Dann messe ich 10k × 1× und 10k × 8× (6 Läufe, ca. 33 min) und schreibe „5k und 1k nicht gemessen“ auf die Folie. Daraus folgt kein Gelb-Kriterium, weil die 5k-Bedingung unbelegt bleibt.

## 8. Voraussetzungen und offene Fragen

| An | Frage |
|---|---|
| Katrin | Zielrechner: Wann genau bereit, Zugang, Daten (siehe 5)? Bestätigung der Hardware. |
| Felix | Szene am 20.11. mit `SimWorld.tick()`-Messhaken, Pacing P1, End-Prüfsumme, Last-Stichprobe, konstante Fahrzeugzahl |
| Felix | Release-Export auf dem Zielrechner möglich? Export-Templates 4.4.1 vorhanden? |
| Felix, Jonas | p95-Warnschwelle (8 ms) und 10-%-Streuungsregel akzeptiert? |
| Felix | Gilt die 4-ms-Schwelle bei 8× pro Tick oder pro Frame? Beschluss sagt „Sim-ms gegen 4 ms“, das Konzept nennt 8 ms pro Frame bei 8×. Ich messe beides und berichte beides. |
| Sophie | Lkw 300 Tris sind Render-Polybudget und beeinflussen die reine Sim-Messung nicht. Nur Hinweis, Render-ms sind laut Beschluss nach S3 geschoben. |

Nicht Teil von F-05 (laut Beschluss nach S3): CI-Zeitreihe, MultiMesh-LOD, Render-ms, Repath-Welle. Daniels früheres Kriterium „≤ 10 % zur CI“ ist gestrichen.

## 9. Hinweise zur Messbarkeit am vorhandenen Spike-Code (gelesen, **nicht gemessen**)

Felix' `SimWorld` (`felix/spike/sim_world.gd`) ist ein reiner Datenkern ohne Nodes, mit `step()` als Tick, `tick_count` und IDs. Das ist die Schnittstelle, die ich für den Messhaken brauche (Zeitmessung um `step()`). Beim Lesen fallen Stellen auf, die bei 10.000 Fahrzeugen ins Gewicht fallen könnten. Das sind Lesebefunde, keine Messungen, und gehören Felix:
- `step()` sortiert pro Tick `vehicles.keys()` (Neuaufbau und Sortierung der ID-Liste je Tick).
- `find_wait_cycles()` läuft pro Fahrzeug eine Kette entlang und prüft mit `Array.has` auf bereits Besuchtes; `_detect_deadlocks()` ruft das **jeden** Tick für alle Fahrzeuge auf, auch wenn keines wartet.
- Fahrzeuge sind Dictionaries mit String-Schlüsseln (`v["state"]`, `v["pos"]` …), Zugriff pro Feld.
- Die Sim hat **keine Prüfsumme** und keinen PRNG. Für Abschnitt 4 (End-Prüfsumme) muss Felix sie ergänzen oder ich vergleiche Zähler.
- Der Spike kennt Züge und Lkw auf geraden Kanten mit Blockreservierung. Ein Benchmark mit 10.000 Fahrzeugen braucht ein Netz, das 10.000 Fahrzeuge ohne ständiges Warten trägt (Last-Beschreibung, Abschnitt 4), sonst misst er überwiegend die Deadlock-Prüfung.
Ob der Benchmark die Deadlock-Prüfung mitzählen soll (sie gehört zum Tick), ist eine Frage an Felix. Ich messe sie mit, solange sie in `step()` liegt, und weise sie getrennt aus, wenn Felix den Haken setzt.
