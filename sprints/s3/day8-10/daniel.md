# Daniel Richter, Abnahmen Sprint 3 Tag 8–9

| Ticket | Abnahme |
|---|---|
| **F-13 Bau-Tool** | **mit Auflagen** |
| **T-06 Datenmodell** | **mit Auflagen** |
| **T-07 Exploit-Katalog** (mein Anteil) | **ja**, 20 Exploits, 17 mit Gegenregel, 15 mit Test (`daniel/t07_exploit_katalog.md`); Tobias' Datei fehlt |
| **F-06-Testbuild** | **ja** |

**F-13:** Felix' `f13_test.gd` selbst gelaufen: 38/38, Exit 0. Eigener Test `d_f13_abnahme.gd`: 50 Prüfungen, 48 grün, 2 rot (beides Befunde, unten). Geprüft: Brücke mit/ohne (diagonal, Start/Ziel im Wasser, 9 und 16 Felder), Stadtgebiet, Geldgrenze (Kosten−0,5/Kosten/+0,5, Brücke), Abriss unter Fahrzeug (Lkw und Zug), Außerhalb-Kosten, 400 Zufalls-Drags. **0 Geld-Exploits** in 12 Fällen von Felix plus meinen Fällen: erfüllt. Nicht geprüft: echter Mausdrag von Hand (nur programmatisch, headless).
**T-06:** `python3 -I validate.py` Exit 0, beide Engines, Selbsttest ok. 16 eigene Negativfälle (negativer Preis, fehlender Key, Float, String, null, 2^53, Doppel-Key, kaputtes JSON) alle erkannt. Mutationstest: 81 von 275 Key-Löschungen **unerkannt** (nur die 143 abgeglichenen Keys sind geschützt), 6 Anteils-Keys auf 150 % unerkannt. Auflage: `required` je Abschnitt, Obergrenze 1000 für Anteile.
**F-06:** `run_smoke.sh` Exit 0, 97 + 58 Prüfungen, 0 Fehler, 0 SCRIPT ERROR, Replay-Prüfsumme identisch, 2 Läufe.

**Neue Bugs**
- **B-01 Mittel:** Linie lässt sich nicht entfernen, Meldung „erst Linie entfernen“ unerfüllbar, Abriss dauerhaft gesperrt.
- **B-02 Niedrig:** Gleis auf Stadtstraße: 0 $, kein Gleisfeld, Züge fahren trotzdem. Entscheidung Felix/Jonas.
- **B-03 Mittel:** T-06-Schema-Lücken (oben).
- **B-04 Niedrig:** Ghost weiß auf Gras, Kontrast ca. 1,5:1 gemessen am Screenshot, Ziel S-08 ≥ 3:1.
- **Info Hoch für T-11:** Im Prototyp laufen Lager-Pingpong (15.440 $ statt 2.800 $ in 600 s) und Umweg (Pfadlänge bezahlt) ungebremst; Slice-Regeln dort nicht umgesetzt.
