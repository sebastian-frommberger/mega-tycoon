# Daniel – Sprint 2, Tag 1–3
## Daily Tag 1 (16.11.)
Gestern: Refinement-Beschluss und Gate-Kriterien gelesen. Heute: Prototyp v3 auf Testbarkeit geprüft (headless, ID-Abfrage, Prüfsumme), Lückenliste geschrieben. Blocker: Zielrechner-Daten von Katrin liegen mir nicht vor.
## Daily Tag 2 (17.11.)
Gestern: Testbarkeitsliste fertig. Heute: Prüfpläne D-04 und F-05, Protokollvorlage L-06. Blocker: Spike-Build erst 19.11., Lenas Fehlerliste fehlt.
## Daily Tag 3 (18.11.)
Gestern: Pläne im Entwurf. Heute: Farbcheck-Skript, Abgleich mit Aylins Testskript, Felix' Spike-Code gelesen und vorab geprüft. Blocker: Sophies Palette fehlt.

## Ergebnisse
- **D-04 Vorbereitung: in Arbeit, Plan fertig, Ausführung nicht begonnen** (ab 19.11., Restaufwand 2 T). `daniel/d04_prueffplan.md`, `d04_vorabpruefung.gd`. Akzeptanzkriterium **nein, noch nicht prüfbar.** Vorabprüfung am Spike-Code (zählt nicht fürs Gate): 12 Deadlock-Läufe richtig erkannt (je 4 Ticks, richtige Ursache), 0 Fehlalarme in 3 × 6.000 Ticks Normalbetrieb. **Aber:** „Weiche ohne Signal“ und „Ausweichgleis zu kurz“ sind im Spike nicht baubar, „≥ 5/6“ ist damit so nicht erreichbar.
- **L-06 Protokollvorlage und Testplan: fertig (Entwurf), Test nicht durchgeführt.** `l06_protokollvorlage.md`, abgeglichen mit Aylins Skript. Messgröße wörtlich, Zählregel, Stoppuhr ab Klick. Keine Tester-Daten.
- **Farbcheckliste S-05: in Arbeit.** `farbcheckliste.md`, `farbcheck.py` (CIEDE2000 gegen Referenzwerte validiert). Erster Durchlauf blockiert, Palette fehlt (Sophie).
- **F-05 Prüfplan: fertig, keine Messung.** `benchmark_pruefplan.md`. Zielrechner unbestätigt, Szene fehlt.
- **Prototyp-Testbarkeit: fertig.** `testbarkeit_proto.md`: kein Tick, keine ID-Abfrage, keine Prüfsumme, kein Seed, kein Replay. Mit `--fixed-fps` wiederholbar.
- **Felix' F-04 nachgelaufen:** 2 Läufe Exit 0, identisch zu seiner Ausgabe.

## Annahmen und offene Fragen an andere (mit Namen)
- **Felix:** Schwelle „≤ 50 Ticks“ ist wirkungslos (Parameter = 4 Ticks). `root_pos` ist je Fahrzeug verschieden und passt nicht zum letzten Kettenglied. Prüfsumme, Seed-Eingang, Release-Export für F-05?
- **Lena, Katrin, Jonas:** D-04-Szenarien 2 und 3 verschieben, ergänzen oder weglassen (Daily 19.11.)? G3 bleibt sonst offen.
- **Lena:** verbindliche Fehlerliste, Pflichtelemente bis 19.11.
- **Sophie, Aylin:** Palette als CSV; Ghost-Farben widersprechen sich in beiden Konzepten.
- **Katrin:** Zielrechner-Daten, 8 statt 6 Tester.
- Annahmen: 3/3 Seeds = „Szenario erkannt“; Grenzwert ΔE ≥ 10; p95 als Warnwert.

## Risiko für das Sprintziel (1–3 Sätze, ehrlich)
Das D-04-Gate (≥ 5/6) ist mit dem Spike in dieser Form nicht erreichbar, solange zwei Szenarien nicht darstellbar sind. Für L-06 und F-05 fehlen Testbuild, Zielrechner und Szene, es existieren nur Pläne, keine Messwerte.
