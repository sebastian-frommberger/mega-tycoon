# Sprint 2, Tag 4–6 (19., 20., 23.11.2026) – Briefing

Gleiche Regeln wie /tmp/claude-0/gd/sprint2/brief.md (lies es zuerst). Zusätzlich verbindlich: /tmp/claude-0/gd/sprint2/decisions_19-11.md (14 PO-Entscheidungen D1–D14) und /tmp/claude-0/gd/sprint2/day1-3/jonas/gate_kriterien.md (G1–G9, Go-Regel).
Dein Stand aus Tag 1–3: /tmp/claude-0/gd/sprint2/day1-3/<vorname>.md und <vorname>/. Die Übersichten der anderen liegen daneben; Katrins Daily in day1-3/katrin/daily_tag3.md.
Ergebnisse von Tag 4–6 anderer Personen: /tmp/claude-0/gd/sprint2/day4-6/<vorname>.md und <vorname>/ (nur lesen, falls vorhanden; sonst Annahme kennzeichnen).

Kalender: 19.11. (Do), 20.11. (Fr), 23.11. (Mo). 21./22. sind Wochenende, dort wird nicht gearbeitet.

Feste Termine:
- 19.11.: Spike-Build F-04 an Daniel; Zahlen T-05 an Lena; 3 Fehler L-06 dokumentiert; Felix/Aylin-Pairing nachgeholt (ausgefallen am 17.11.)
- 20.11.: Benchmark F-05 Lauf 1 (Felix, Daniel); Entscheidungspunkt 1: steht F-04? sonst Plan B; L-05 Paper-Prototyp Runde 1; S-03 Entscheidung Zoom-Blend und Lesbarkeitsgrenze im Wiki; Katrin: 6 Tester bestätigt?, Zielrechner da?, Interviews terminiert
- 23.11.: Benchmark Lauf 2/3 und Auswertung (Felix, Daniel); D-04 fertig; A-06 bei Felix (nur noch als Info, F-07 ist gestrichen – D6); float32-Check (Felix, D5); F-09 Start (Tobias)

Wichtige Konsequenzen aus den Entscheidungen:
- D3: D-04 prüft 6 darstellbare Szenarien (3 aus F-04 + Ring mit 6 Zügen + Gegenverkehr mit Auffahrer + eines von Daniel), Tick-Schwelle gestrichen, 0 Fehlalarme auf Daniels eigenem Normalnetz.
- D9: Ein Namensraum für Ursache-Codes = Felix' Sim-Enum. Felix liefert zusätzlich fuell_ist/fuell_soll, n_lkw, Streckenlänge, Gleiszahl; kanonischer Ort = letztes Kettenglied. Aylin leitet ihre UI-Typen per Tabelle ab.
- D10/D11: Ghost Weiß = baubar; Testmeldungstitel "Zug X steht seit …", Vorschlag im Test ausgeblendet.
- D5: Kartenziel Vertical Slice 512², Rückfallregel über ≤ 5k Fahrzeuge; Felix macht float32-Check bis 23.11.
- D6: F-07 gestrichen. Felix' Puffer bleibt Puffer.
- D7: Benchmark G2 = Median Sim-ms pro Tick, 10k Fahrzeuge bei 1×, Release-Export, p95 Pflicht mit Warnschwelle 6 ms.
- D1: Startkapital 4.500/4.500/7.000/5.000 $ als Testannahme für L-05.
- D12/D13: Leitplanken-Satz geändert, Meilensteine 3 und 7 neu gefasst, Agrar-Stufen-Tor verschoben; Lena pflegt das in lena.md Phase 1 ein.

Harte Regel zu Messwerten: Es gibt keine echten Tester, keine echten Kollegen und keinen Zielrechner mit GPU in dieser Umgebung (Sandbox: 2 vCPU, keine GPU, Software-Renderer). Alles, was du misst, ist auf dieser Sandbox gemessen und so zu kennzeichnen. Playtest- und Kollegen-Ergebnisse können nicht erzeugt werden; stattdessen: Material fertig machen, Pilot mit dir selbst als Tester nur als "Pilot, zählt nicht", und das Ticket als "wartet auf echte Durchführung" markieren. Keine erfundenen Zahlen, auch nicht "plausible".

Schreibe deine Ergebnisse nach /tmp/claude-0/gd/sprint2/day4-6/<vorname>/ und die Übersicht /tmp/claude-0/gd/sprint2/day4-6/<vorname>.md (max. 450 Wörter) mit: Daily Tag 4 (19.11.), Tag 5 (20.11.), Tag 6 (23.11.) je Gestern/Heute/Blocker; Ergebnisse je Ticket (Status, Dateien, Akzeptanzkriterium erfüllt ja/teilweise/nein mit Beleg); Annahmen und offene Fragen an andere; Risiko für das Sprintziel. Keine Schönfärberei.
