# Aylin – Sprint 2, Tag 4–6
## Daily Tag 4 (19.11.)
Gestern: Testskript-Entwurf. Heute: Pairing-Termin 10:00; `felix/pairing_antworten.md` lag nicht vor, deshalb Vertrag v1 aus Felix' Spike-Code und D9 abgeleitet, Textvorlagen auf D11 umgestellt. Blocker: Felix' Bestätigung je Feld fehlt weiterhin.
## Daily Tag 5 (20.11.)
Gestern: Vertrag v1. Heute: Testskript L-06 gegen Lenas Szenario und Daniels Protokoll abgeglichen, D2-Nebenmessungen eingebaut, F-06-Panel als Textspezifikation (D14). Blocker: keine Tag-4–6-Dateien von Lena, Daniel, Felix; Gegenzeichnung offen.
## Daily Tag 6 (23.11.)
Gestern: Wochenende. Heute: A-06 Bau-UX-Vorgaben für das M1-Ticket. Blocker: keiner für mich; Felix' Rückmeldung zu `n_lkw` und kanonischem Ort entscheidet über F3.

## Ergebnisse
- **A-05: fertig als Text, Bestätigung offen.** `aylin/diagnose_datenvertrag_v1.md`, `aylin/textvorlagen_testfehler_v1.md` (+ `laengen_check.py`, 16 Zeilen, längste 56 Zeichen), `aylin/f06_panel_spezifikation.md`. AK "Textspezifikation" (D14): **ja**. AK "Felix bestätigt je Feld liefert/fehlt": **nein**; die Stand-Spalte ist aus dem Code gelesen. Befund: `fuell_ist/soll` geliefert (als `stock`/`needed`), `gleiszahl` geliefert (`single`), **`n_lkw` fehlt** (Spike hat keine Lkw-Zulieferung, nur `produce_every`), Streckenlänge nur je Kante, `root_pos` nicht kanonisch (S1: zwei Orte für einen Zyklus, verstößt gegen D9). Vorschlag kleinste Block-ID, Validator V3 auf `pos`.
- **L-06 (Testskript, Fragebogen): fertig zur Gegenzeichnung, nicht pilotiert.** `aylin/testskript_l06_final.md`. Lenas Zählregel F2 (Kreis benennen), 4 Züge, F6 gestrichen, `variante`-Spalte übernommen; D2-Nebenmessungen Zeilenklicks, Nur-letzte-Zeile-Leser (Log + Think-aloud-Proxy), Median, "Was würdest du bauen?" ungezählt. AK: **teilweise**; Pilot und Tester fehlen, Ticket wartet auf echte Durchführung.
- **A-06: fertig.** `aylin/a06_bau_ux_vorgaben.md`: 10 Grund-Strings, Ghost Weiß = baubar, Blau nur Hinweis (D10). AK: **ja** für Strings und Ghost-Regel; ΔE-Prüfung (Daniel) liegt mir nicht vor.

## Annahmen und offene Fragen an andere (mit Namen)
- **Felix (bis 20.11., 12:00 laut D9, nicht erfolgt):** Stand-Spalte bestätigen; kanonischer Ort nach Vertrag Abschnitt 4; `n_lkw`, `streckenlaenge_mm`, Streckennamen, Testnamen in F-06; Muss-Umfang Panel in 1 T, Streichliste Abschnitt 7; Klick-Log-Format.
- **Lena:** Entstehungsregel Ladungsmeldung ab 60 s; Rückfall ohne `n_lkw` (Vertrag Abschnitt 5) ändert Zählregel F3; N-B-Definition; CSV-Kopf v1.0.
- **Daniel:** Bogen an neue Spalten anpassen; Smoke-Test-Punkte (`vertragsfehler`-Zeilen, `meldung_geoeffnet`); ΔE Weiß/Stadtfläche.
- **Sophie:** Zoomstufe für den Kamerasprung; Markierungsformen gegen S-05.
- **Katrin:** Tester 6 + 2, Einwilligung, OBS, Zielrechner: nichts belegt.
- Annahmen: Meter statt "Felder" in `W_EINGLEISIG`; `needed` = Abfahrmenge des Zugs; Sprung-Zoom "200-m-Abschnitt im Bild".

## Risiko für das Sprintziel
Ohne `n_lkw` und kanonischen Ort ist Fehler 3 im Build nicht lösbar und der Sprung bei Fehler 1 nicht eindeutig; beides hängt an Felix' F-06-Tag, der schon ohne diese Punkte knapp ist. Der Test selbst hat weiterhin keinen Piloten, keine Tester und keinen Zielrechner, und der Deckeneffekt macht ein Bestehen zum Beleg für Lesbarkeit, nicht für die Diagnose.
