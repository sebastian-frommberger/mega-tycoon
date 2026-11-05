# L1 Auswertung (Vorlage, nicht für Basti)

Aylin, QT-07. Auswertung binnen 0,5 T nach Eingang. Eingang am: ______ · Stand von Bastis Build (Hash aus F12-JSON oder `git rev-parse --short HEAD`): ______ · Gate A grün am: ______

## 1 Tempo A/B (Entscheidung D2 für Jonas, Frist Tag 5)
Mittel = Mittelwert aller Fahrten. m/s = 505 ÷ Mittel. Soll [R] aus AT-04: Hinfahrt 505 m, 136 Ticks (k=4) bzw. 271 Ticks (k=8), 10 Ticks/s bei 1×, Easing und Stoppuhr-Streuung (HUD alle 0,25 s, Reaktion ± 0,5 s) nicht eingerechnet.

| Variante | k | Fahrt 1 s | Fahrt 2 s | Mittel s | m/s | km/h | Soll s [R] | Gefühl (Basti) |
|---|---|---|---|---|---|---|---|---|
| A | 4 | | | | | | 13,6 ± 2 | |
| B | 8 | | | | | | 27,1 ± 3 | |
| C | 20 | | | | | | 68 ± 7 | |

- **Plausibilität:** B ÷ A liegt bei etwa 2 (1,6 bis 2,4). Sonst lief eine Variante nicht mit dem gedachten k (bei fehlendem Argument k = 1: 3,4 s). HUD zeigt k noch nicht (Annahme A7 in AT-14): im Zweifel nachfragen.
- **Einordnung [R]:** Schritt eines Pferdes ca. 5 km/h = 1,4 m/s, also rund 6 min für 505 m. A entspricht ca. 135 km/h, B ca. 68 km/h im Bild. Beide sind ein Vielfaches vom echten Tempo (Zwei Uhren rafft). Weil Basti 1× „viel zu schnell“ fand, gibt es Variante C mit k = 20 (ca. 27 km/h; k muss 600 ganzzahlig teilen, k = 16 geht nicht). Sie steht nicht in `varianten [4, 6, 8]`, E5 ist schon bei k = 4/8 rot und bei höherem k vermutlich schlechter (AT-04): Entscheid Jonas/TA, nicht automatisch. Auch bei höherem k verschiebt sich das Verhältnis Fahrzeit/Ladezeit weiter (OE-02).
- **Regel:** A besser → k = 4 · B besser → k = 8 · C besser → k = 20 (Rückfrage an Felix/TA wegen E5, Ertragsausgleich a größer) · „teils/zwischen“ oder keine Antwort bis Tag 5 → k = 6 (Jonas, ergebnis D2) · beide zu schnell oder zu langsam → Rückfrage, Variante nachlegen.

**Ergebnis k:** ______ (Quelle: Basti, Datum, Karte L1)

## 2 Hügel und Senken (RL-1, Ziel 3 von 3)
Soll [M] aus `proto_hoehe.r16`, 7 × 7 Felder geglättet, lokale Meter (+x Ost, +z Süd), Kern 0–2.000 × 0–1.600 m (Kern 35–117 m):

| Stelle | Lage (x / z) | Höhe m | Beschreibung |
|---|---|---|---|
| H1 | 1.675 / 1.500 | 95 | Kuppe am Südrand, ca. 300 m südwestlich Gut Kuppenhof, ca. 410 m südlich der Mühle |
| H2 | 1.250 / 1.500 | 61 | Höhe am Südrand, westlich von H1 |
| H3 | 100 / 1.500 | 56 | Südwestecke |
| S1 | 100 / 375 · 525 / 625 · 950 / 625 | 38–39 | Talboden des Flusses im Westen und in der Mitte (Wasser), im Kern die einzige größere Senke |
| Rand | 2.925 / 1.900 · −950 / 2.025 | 141 · 128 | Höhen außerhalb des Kerns, nur bei weitem Auszug sichtbar |

Treffer [E]: Position (F12-JSON Ziel x/z) innerhalb 400 m einer Soll-Stelle, oder Beschreibung stimmt mit Richtung und Art überein. Gefunden: ___ von 3 · Basti sicher/geraten: ___ · **Ziel 3 von 3** (RL-1). Unter 3 → Lichtstärke/Schummerung nachziehen (WA-03), erst dann Amplitude (RL-2, S9). Messart: n = 1, Basti kennt die Welt.

## 3 Gelände-Prüfung (RL-0)
Gelände: ______ → `TA` ok · `Stub (flach)` oder `Stub (TA-Fehler)` = **Bug, höchste Priorität an Felix** (Pfad/Import auf Windows), L1 insgesamt nur eingeschränkt auswertbar. Zeile „Daten:“ `Testdaten` statt `Vertrag` ebenfalls an Felix.

## 4 Stellen (BT-0, Ziel ≥ 5)
Anzahl: ___. Kategorie je Stelle (Boden · Ufer · Gebäude · Allee · Relief · anderes) und Ticket: Boden → WA-04, Ufer → WA-05, Gebäude → WA-10, Allee → WA-11, Gewässer → WA-12. F12-Paare (PNG + JSON) in `sprints/s8/feedback_<Datum>/stellen/` ablegen, sie sind die Baseline für Vorher/Nachher in L2 (WA-06). Unter 5: 8 eigene Standorte (5 Presets, Markt-Ufer, 2 Ackerränder), Basti bewertet in L2.

## 5 Start, Pause, Tempo
Startweg geklappt: ja / teils / nein (Knopf, Taste P) · Pause: ___ · 1×/2×/4× sichtbar verschieden: ___. **Hinweis:** 4× = 40 ± 1 Ticks/s ist bisher nur headless und mit simulierten Frames belegt (AT-05, „auf Bastis Rechner mit GPU: nicht gemessen“). Bastis Antwort ist die erste Messung auf echter Hardware.

## 6 Ergebnisblock für Jonas (Kopie in `ergebnis`/Entscheidungslog)
k = ___ · Hügel ___ / 3 · Gelände ___ · Stellen ___ · Probleme P0 / P1: ______ · Offene Rückfragen an Basti: ______

## 7 Voraussetzungen vor Tag 4 (Prüfliste)
- [ ] Gate A grün; Test-Build mit Knopf, Pause/Tempo, `--tempo_k`, Licht neu.
- [ ] Branch `s8` mit diesem Stand **auf GitHub hochgeladen** (laut Blocker-Check steht dort nur der Stand vom Sprintstart; ergebnis §7 nennt den Push erst für Tag 15).
- [ ] F12 „Stelle merken“ (WA-02) im Build, sonst Karte und WA-01 auf „Screenshot“ umstellen.
- [ ] Anzeige des k im HUD (AT-14 A7), sonst Plausibilitätsprüfung nur über die Zeiten.
- [ ] Pfad der Godot-Datei von Basti erfragen; Verknüpfungen nicht auf Windows getestet.
