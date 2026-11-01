# Sprint 3 (30.11.–11.12.) – Jonas Weber (PO), Moderation Katrin Vogel

## 1. Sprintziel
Bis 11.12. läuft der Windows-Export am Zielrechner mit SoA-Kern, Deadlock-Prüfung und 10.000 Fahrzeugen bei ≤4,0 ms/Tick (p99 ≤6 ms, 3 Läufe bit-identisch); Bau per Ziehen funktioniert; Slice-Regeln liegen als validiertes JSON vor.
**Stretch:** Undo einstufig (0,5 T), S-09-Karte im Testbuild.

## 2. Tickets
| ID | Ticket | Owner | Tage | Akzeptanz | Folge |
|---|---|---|---|---|---|
| F-12 | Export + Messung | Felix, Daniel | 1,0 + 1,0 | 30 min, 10k, 0 Abstürze, Mittel ≤4 ms, 1-%-Low ≥60 FPS (Spike-SoA-Stand) | 1., bis 02.12. |
| F-10 | SoA-Kern | Felix | 4,0 | ≤4,0 ms, p99 ≤6 ms, 5.000 Ticks; Prüfsumme-Zwischenstand Tag 2 | nach F-12 |
| F-11 | Deadlock-Hook | Felix | 1,0 | Wende-Deadlock erkannt, 10 von 10 Fällen | in F-10 |
| F-13 | Bau-Tool, Abriss 50 % | Felix | 1,5 | Ziehen, 45°-Snap, Ghost, Kosten; 0 Geld-Exploits in 10 Fällen | nach F-10 |
| F-09b | Minimal-Validator | Tobias | 0,5 | CI prüft 100 % Kernschema, ≤60 s | vor S-09 |
| L-07 | Testmaterial + Bogen | Lena, Aylin | 1,5 + 1,0 | Basti startet ohne Rückfrage | 01.12. |
| L-09 | Auswertung L-06/L-05 | Lena, Aylin | 2,0 + 1,0 | Bericht ≤2 Seiten | 02.12. 12 Uhr |
| L-08 | Slice-Regeln | Lena | 2,0 | ≤4 Seiten, jede Regel mit Zahl; Einseiter 03.12. | vor T-06 |
| T-06 | Ökonomie-Datenmodell | Tobias | 3,0 | 100 % L-08-Regeln als valides JSON | nach 03.12. |
| T-11 | Balancing-Läufe | Tobias | 1,5 | 100 Läufe: Bankrott 10–30 %, Exploit ≤1,5× | nach T-06 |
| T-07 | Exploit-Katalog | Tobias, Daniel | 0,5 + 0,5 | ≥10 Exploits mit Gegenregel | parallel |
| A-07 | Feldliste Dialog | Aylin | 0,5 | ≤1 Seite, 4 Typen, ≤8 Felder | 04.12. |
| A-08 | Diagnose Spec + Dummy | Aylin | 1,5 | 5 Blockaden mit Ort, Ursache, Aktion; 5 von 6 handeln ≤30 s | nach L-09 |
| A-09 neu | Leiter + HQ-Start | Aylin | 2,0 | ≤7 Screens; 5 von 6 kaufen ≤3 min | nach L-08 |
| S-07 | Kenney-Import | Sophie | 1,5 | 3 Kits, Abweichung ≤10 % | Branch |
| S-08 | Look: Lesbarkeit | Sophie | 1,5 | Kontrast ≥3:1; 5 von 6 erkennen ≤5 s | nach 02.12. |
| S-09 neu | Karten-Entwurf 512² | Sophie | 2,0 | 3 Ketten, ≥4 Städte, JSON 100 % valide | nach F-09b |
| D-06 | CI-Automatisierung | Daniel | 2,0 | Lauf ≤10 min, 1 MCP-Messlauf | parallel |
| J-06 | Slice-Ziel D15 | Jonas | 1,0 | ≥10 Einträge | 04.12. |
| K-08 | Gate 02.12. | Katrin | 1,5 | 4 von 4 Nachweise | 02.12. |

## 3. Geschoben/gestrichen
- F-14, F-13-Undo, A-07/A-08-Bau (neu F-15), Skilltree, F-09b-Rest: S4 (Felix voll).
- S-08 Licht/Stimmung: nach Gate. Tobias +1 T, Sophies Eigenassets: gestrichen.
- Lenas Tester-Kriterium (5 von 6 in 10 min): S4, Loop erst dann baubar.

## 4. Streitprotokoll
1. **S-08:** Sophie 2–3 T; Daniel nach Gate; Lena raus. Entscheid: 1,5 T Lesbarkeit nach 02.12. Daniel und Aylin.
2. **T-06 vs. L-08:** Tobias Werte zuerst, Lena/Felix Regeln. Entscheid: Einseiter 03.12., Sitzung, dann T-06. Lena, Felix.
3. **F-13:** Felix 2 T mit Undo; Daniel Abriss ≤50 %; Sophie ohne beides. Entscheid: Abriss 50 %, Undo S4. Daniel, Sophie teilweise.
4. **F-11:** Tobias nach Kalibrierung. Entscheid: Hook in F-10, 1,0 T, Exploit-Fälle parallel. Felix.
5. **A-07:** Brief 2 T, alle 0,5 T. Entscheid 0,5 T (D15). Konsens.
6. **F-14:** Felix S4; Sophie, Tobias, Lena jetzt. Entscheid S4, S-09 als Vorlage. Felix.

## 5. Kapazität (T)
| Person | Tickets | Puffer |
|---|---|---|
| Felix | 7,5 (inkl. F-09b-Abzeichnung 0,25) | 0,5 |
| Daniel | 6,5 (inkl. Abnahmen F-10/F-13 2,5, Probelauf 0,5) | 1,5 |
| Lena | 6,5 (inkl. Sitzung 0,5) | 1,5 |
| Tobias | 6,5 (inkl. Gate-Zuarbeit 1,0) | 1,5 |
| Aylin | 6,5 (inkl. F-13-Abnahme 0,5) | 1,5 |
| Sophie | 6,0 (inkl. Zuarbeit 1,0) | 2,0 |
| Jonas, Katrin | je 6,0 | 2,0 |

## 6. Basti bis 02.12.
- L-06 (6 Tester) und L-05 (3 Runden) selbst durchführen; Termine bis 30.11. mit Katrin.
- Build und Bogen 01.12. abholen; Ergebnis bis 02.12. 12 Uhr an Lena.
- Zielrechner für 30-min-Dauerlauf freihalten; F-08-Record gegenzeichnen.

## Nachtrag 01.11. – Entscheidung D16 des Auftraggebers
Keine Tester-Rekrutierung, keine Testtermine. Basti testet selbst und gibt direkt Feedback. Gate 02.12. hängt nicht mehr an L-06/L-05 mit externen Testern; G1/G5 = Auftraggeber-Feedback (qualitativ). L-07 erledigt (Leitfaden für Bastis Sessions), L-09 entfällt → Lena +2 T, Aylin +1 T frei (Vorschlag: Lena L-08 früher, Aylin A-08 Bau-Vorbereitung). Vor Bastis Session: Zeitangaben im F-06-Build angleichen, Orte/Abschnitte auf der Karte beschriften (Felix, klein).
