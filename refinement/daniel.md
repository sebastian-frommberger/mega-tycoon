# Refinement S2 – Daniel Richter (QA)

## Meine Tickets

**D-04 Signal-Spike gegen 6 Deadlock-Szenarien** – Spike (Testlauf)
- Leitfrage: Erkennt `get_wait_chain` echte Deadlocks zuverlässig und nennt die richtige Wurzelursache?
- AK: 6 Szenarien (Gegenverkehr eingleisig, Kreisverkehr voll, Lager-Einfahrt, Weiche ohne Signal, Ausweichgleis zu kurz, Repath-Welle) je 3 Seeds gelaufen · Protokoll je Lauf: erkannt ja/nein, Ticks bis Erkennung, Wurzelursache = erwartet ja/nein · Schwelle für Gate: ≥ 5/6 erkannt in ≤ 50 Ticks (5 s), 0 Fehlalarme in 10 min Normalbetrieb · Jeder Fehlschlag als Replay + Tick im Tracker.
- Timebox: 2,5 Tage · Abh.: F-04-Build bis 17.11., Erwartungstexte aus A-05.

**D-05 Benchmark auf Zielhardware** – Spike (Messung)
- Leitfrage: Hält der Sim-Kern 4 ms/Tick und Render 2 ms bei 10.000 Fahrzeugen?
- AK: 1.000/5.000/10.000 Fahrzeuge × 1×/8× auf GTX 1660/6 Kerne/16 GB, je 3 Läufe à 5 min · Median + p95 Sim-ms, Render-ms, Frame-Zeit tabelliert · Abweichung zu Felix' CI-Zahlen ≤ 10 %, sonst begründet · Protokoll bis 25.11. als Gate-Anlage.
- Timebox: 1,5 Tage · Abh.: F-05-Szenen, Testrechner von Katrin bis 16.11.

**L-06 (mein Anteil): Beobachtung und Protokoll** – Spike (Playtest)
- Leitfrage: Findet ein Spieler mit dem Feed die Ursache?
- AK: Beobachtungsbogen mit Stoppuhr ab Klick auf Meldung, Fehlklicks, Abbruch · ≥ 5 Tester durch, Rohdaten-Tabelle am Testtag · Ergebnis gegen die eine Messgröße unten ausgewertet.
- Timebox: 2 Tage · Abh.: F-06 bis 23.11., K-06.

**T-06 (mein Anteil): Exploit-Katalog Testfall-Format**
- AK: Jeder Exploit hat Setup, Befehlsfolge, erwartetes Ergebnis als Zahl („Ertrag = 0 $“) · mind. 6 Einträge · ≥ 3 davon mit Startspielstand reproduzierbar.
- Timebox: 0,5 Tage · Abh.: Tobias' Balance-Targets.

## Einwände

1. **L-06/K-06/A-04 – drei verschiedene Playtests.** Lena: 5 Fehler, ≤ 3 min. Aylin: 5 Aufgaben. Katrin: 6 Tester am 24.–25.11. Mein Plan: < 30 s. So kann keiner abnehmen. → *Eine* Messgröße: „≥ 4 von 6 Testern finden die Wurzelursache von mind. 2 der 3 eingebauten Fehler in < 60 s nach Klick auf die Meldung.“ Drei Fehler, weil F-06 nur drei baut. Termin 25.11.
2. **F-04 – „5 automatisierte Szenariotests“** – grün heißt was? → „5 Szenarien laufen headless, Exit-Code 0, Zyklus in ≤ 50 Ticks erkannt, `get_wait_chain` liefert erwarteten Wurzelursache-Typ.“ Drei davon decken sich mit meinen, also Felix automatisiert 3, ich teste den Rest manuell.
3. **S-03 – „weicher Übergang ohne Popping“** ist Geschmack. → „Kamerafahrt 50→1.000 m in 5 s: kein Frame > 33 ms, 3 von 4 Reviewern sehen kein Popping im Video.“
4. **L-05 – „wird die Stadtwahl verstanden, entsteht der Kaufwunsch“.** → „In ≥ 2 von 3 Runden begründet der Spieler seine Stadtwahl mit einer Kette; Startkapital reicht in 3/3 Runden für 3 Lizenzen; ≥ 2/3 äußern den Kaufwunsch vor Minute 20.“
5. **J-05 – „Ampel und max. 3 Auflagen“** ohne Kriterium. → „Je Pfeiler vorher eine prüfbare Frage festgelegt; Rot = Frage mit Nein beantwortet; Ampel mit Begründung bis 25.11.“
6. **T-07 – „< 5 % Abweichung“** – wovon? → „Geld, Gewinn/Linie, Einwohner nach 60 Spielminuten, 3 Seeds, jede Größe < 5 % zur Tabelle.“

## Meine Kapazität und Forderung

| Ticket | Tage |
|---|---|
| D-04 | 2,5 |
| D-05 | 1,5 |
| L-06 | 2 |
| T-06 | 0,5 |
| Farbsehschwäche-Check auf S-05 | 1 |
| QA-Bewertung Gate | 0,5 |
| **Summe** | **8** |

Was ich fordere:
- **Felix entlasten, sonst platzt das Sprintziel.** F-08 Terrain und F-09 Datenformate nach S3. F-07 Bau-Spike nur noch 2 Tage mit Leitfrage „Lässt sich 45° mit Undo/Abriss bauen, ja/nein“. T-07 geht ohne SimWorld-Schnittstelle nicht, also auch nach S3.
- **Harte Termine:** Spike-Build 17.11., Testbuild 23.11., Testrechner 16.11. Kommt der Spike später, schrumpft D-04 auf 3 Szenarien.
- **Kein Ticket ins Sprint-Backlog ohne Zahl im Akzeptanzkriterium.** Wenn das Kriterium „verstanden“, „fühlt sich an“ oder „Ampel“ heißt, bleibt das Ticket draußen, bis wir die Zahl haben.
