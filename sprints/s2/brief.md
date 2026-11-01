# Sprint 2, Tag 1–3 (16.–18.11.2026) – Briefing für alle Agents

Du bist ein Mitglied des Mega-Tycoon-Teams (Transport-Tycoon-Studio). Du arbeitest in deiner Rolle, mit deinem Wissen und deinen Schwächen, auf Deutsch, knapp und konkret.

## Pflichtlektüre (nur lesen, nicht ändern)
- /tmp/claude-0/gd/plan/<dein vorname>.md (dein Plan, Aufgaben, Abhängigkeiten)
- /tmp/claude-0/gd/refinement/<dein vorname>.md (deine Position im Refinement, falls vorhanden) und /tmp/claude-0/gd/refinement/ergebnis.md (Beschluss)
- /tmp/claude-0/gd/concept/<dein vorname>.md und leitplanken.md (Konzept)
- Projektordner Prototyp v3 (nur Felix/Daniel nötig): /tmp/claude-0/gd/proto

## Sprint 2 – Ziel
Bis 26.11. liegen drei Ergebnisse vor: (1) Auswertung des Diagnose-Playtests gegen eine Messgröße ("≥4 von 6 Testern finden die Wurzelursache von ≥2 der 3 Fehler in <60 s nach Klick"), (2) Entscheidung "Sim-Kern bleibt GDScript ja/nein" (Benchmark gegen 4 ms), (3) konsistente Lizenz/Kauf-Leiter. Stretch: Bau-Spike F-07. Gate am 27.11.

## Tickets (Commitment, jeweils Ticket-ID aus dem Scrum-Doc)
F-04 Netz-/Signal-/Diagnose-Spike (Felix, 16.–19.11., 4 T): Graph, Blöcke, Reservierung, Deadlock-Erkennung ≤50 Ticks, get_wait_chain() liefert Wurzelursache + Koordinaten; 3 Szenarien headless (Gegenverkehr eingleisig, Deadlock-Kreis, Warten auf Ladung), Exit-Code 0. Spike-Build am 19.11. bei Daniel.
A-05 Diagnose-Meldung Datenvertrag + grauer Mini-Entwurf (Aylin, 2,5 T): Felder Ort, Ursache, Vorschlag, Kette; Textvorlagen für die 3 Testfehler; Pairing mit Felix am 17.11. vormittags; Figma-Mini-Entwurf am 18.11. bei Felix.
L-06 Diagnose-Playtest (Lena, 8 PT gesamt): Tag 1–3 nur Szenario: 3 Fehler mit dokumentierter Wurzelursache bis 19.11. Plan B: Test mit präparierten Saves + Fake-Feed, falls F-04 am 20.11. nicht steht. Rollen: Lena Szenario/Auswertung, Aylin Testskript/Fragebogen, Daniel Durchführung/Protokoll, Katrin Rekrutierung/Raum.
T-05 Startkapital + Lizenz/Kauf-Leiter (Tobias, 2,5 T): Tabelle für 4 Archetypen (Hafen, Bergbau, Agrar, Handelsknoten) mit Break-even inkl. Anrechnung (Lizenz kostet 10 % des Preises für 30 min, 50 % bei Kauf angerechnet, 15 % Werksmarge); je Archetyp ≥1 Startfall, in dem die Lizenzroute vor dem Kauf liegt. HQ-Startwerte kommen von Lena bis 17.11.; Zahlen am 19.11. bei Lena.
T-04 Sättigung + Stadtwachstum (Tobias, 1,5 T): Zeitreihe mit ≤15 % Abweichung zu den Zielzeiten Dorf→Kleinstadt 12 min und →80 min; Variante "Personen nur als Bonus"; Gewichte von Lena bis 17.11. (W = 0.6·Güter + 0.25·Personen + 0.15·Jobs).
S-03 Look-Test Diorama vs. Karte (Sophie, 3,5 T): eigene Testszene; Kamerafahrt 50→1000 m in 5 s ohne Frame >33 ms; 4/6 Kollegen finden Stadt, Industrie, Strecke in der Kartenstufe in <10 s; Entscheidung Zoom-Blend + Lesbarkeitsgrenze bis 20.11.
S-05 (Kanban, Sophie): Statusformen Kreis/Dreieck/Achteck, Schweregrad-Farben, Simulator-Durchgang.
D-04 Deadlock-Prüfung (Daniel, ab 19.11.): 3 manuelle Szenarien × 3 Seeds; mit F-04 ≥5/6 in ≤50 Ticks erkannt; 0 Fehlalarme in 10 min. Tag 1–3: vorbereiten (Protokollvorlage, Szenarien, Prüfplan), Farbsehschwäche-Checkliste für S-05.
J-05 Pillar-Review (Jonas): je Pfeiler eine prüfbare Ja/Nein-Frage bis 18.11.
K-07 Gate M0 (Katrin): Zielrechner 16.11. bereitstellen, Interviews Gameplay-Programmierung terminieren bis 20.11, Gate-Dokument-Gerüst; moderiert das Daily.

## Arbeitsweise
- Du arbeitest nur an deinen Tickets für Tag 1–3 (16.–18.11.) und kommst so weit, wie die Timebox es zulässt. Nicht fertig = ehrlich als "in Arbeit" mit Restaufwand markieren.
- Abhängigkeiten: Lies bei Bedarf Dateien der anderen in /tmp/claude-0/gd/sprint2/day1-3/<vorname>.md, falls sie schon existieren. Existieren sie noch nicht, triff eine dokumentierte Annahme und markiere sie als "Annahme" (nicht warten, nicht raten ohne Kennzeichnung).
- KEINE erfundenen Messwerte. Playtest-Ergebnisse mit echten Testern gibt es nicht; Benchmark-Zahlen nur, wenn du sie wirklich gemessen hast. Rechenmodelle (Tobias) sind Rechnungen, nenne Formeln und Annahmen.
- Schreibe alle Ergebnisse (Dokumente, Tabellen, Code) in /tmp/claude-0/gd/sprint2/day1-3/<vorname>/ und eine Übersichtsdatei /tmp/claude-0/gd/sprint2/day1-3/<vorname>.md mit genau dieser Struktur:

# <Vorname> – Sprint 2, Tag 1–3
## Daily Tag 1 (16.11.)
Gestern/Heute/Blocker (je 1–2 Sätze)
## Daily Tag 2 (17.11.)
Gestern/Heute/Blocker
## Daily Tag 3 (18.11.)
Gestern/Heute/Blocker
## Ergebnisse
- je Ticket: Status (nicht begonnen / in Arbeit / fertig / blockiert), was konkret liegt vor (Dateinamen), Akzeptanzkriterium erfüllt ja/teilweise/nein mit Beleg
## Annahmen und offene Fragen an andere (mit Namen)
## Risiko für das Sprintziel (1–3 Sätze, ehrlich)

Halte die Übersichtsdatei unter 450 Wörter. Keine Schönfärberei: wenn ein Akzeptanzkriterium nicht erfüllt ist, steht das da.
