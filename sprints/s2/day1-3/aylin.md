# Aylin – Sprint 2, Tag 1–3
## Daily Tag 1 (16.11.)
Gestern: Refinement-Beschluss und Konzept gelesen (A-05 2,5 T, Pairing 17.11. vormittags). Heute: Datenvertrag v0.1 und Textvorlagen entworfen, Fragenliste für Felix vorbereitet. Blocker: von Felix liegt nichts vor.
## Daily Tag 2 (17.11.)
Gestern: Datenvertrag v0.1. Heute: Pairing ist für den Vormittag geplant. Ein Ergebnis liegt mir nicht vor (`felix.md` fehlt, `felix/spike/` leer), deshalb trage ich keine Bestätigung ein. Mini-Entwurf als Text geschrieben. Blocker: Pairing-Ergebnis.
## Daily Tag 3 (18.11.)
Gestern: Mini-Entwurf. Heute: Testskript, Messprotokoll und Fragebogen entworfen. Blocker: Lenas Fehlerdokumentation (19.11.), Felix' Antworten.
## Ergebnisse
- **A-05:** in Arbeit, Restaufwand etwa 0,75 T. Vorhanden: `aylin/diagnose_datenvertrag.md`, `aylin/textvorlagen_testfehler.md`, `aylin/mini_entwurf.md`. Akzeptanzkriterium **teilweise**: Spezifikation und Vorlagen für die 3 Fehler liegen vor. **Nicht erfüllt:** "Felix bestätigt je Feld liefert/fehlt", denn es gab kein Pairing-Ergebnis. **Nicht erfüllt:** Figma, es existiert nur die Textbeschreibung (Nachbau, Zugriff fehlt, 0,5 T).
- **L-06 (Anteil Aylin: Testskript, Fragebogen):** in Arbeit. `aylin/testskript_entwurf.md` mit Aufgabentext, Zählregel, Messprotokoll, Fragebogen, Auswertungsschema, Plan B. Nicht mit Lena und Daniel abgestimmt, nicht pilotiert. Frist 18.11. nur als Entwurf erreicht.
- **A-06 (Grund-Strings):** nicht begonnen, Fälligkeit 23.11.
- Textzeilen: 17 Beispielzeilen mit Skript gezählt, längste 52 Zeichen. Kontrastwerte gerechnet. Keine Messung mit Testern.
## Annahmen und offene Fragen an andere (mit Namen)
- **Felix (Annahme):** liefert Ort, Ursachentyp, Kette mit Koordinaten (laut seinem Konzept). Offen: Koordinatenformat, Lagerfüllung/Lkw-Anzahl, UI-Klick-Log, Stillstand mindestens 120 s, Schnappschuss. 10 Fragen in der Pairing-Checkliste.
- **Lena:** Fehler, Namen und Zahlen sind Platzhalter bis 19.11. Pflichtelemente der Zählregel und Definition Veteran/Einsteiger bestätigen.
- **Jonas/Lena:** Titel im Test einheitlich "Zug X steht" (sonst nennt der Deadlock-Titel die Ursache) und Vorschlag als Text im Test?
- **Tobias:** Bleiben die Ursachenkategorien Ladung, Infrastruktur, Geld, Nachfrage?
- **Katrin/Daniel:** Rekrutierung nach Screening, Einwilligungstext, Protokollformat.
## Risiko für das Sprintziel
Die Messgröße ist leicht zu erreichen, weil die Kette in der Wurzelursache endet. Ein Bestehen belegt dann Lesbarkeit der drei Fälle, nicht die Tragfähigkeit der Diagnose. Ohne Pairing-Ergebnis kann sich der Vertrag nach F-04 noch ändern, das gefährdet den Testbuild am 24.11.
