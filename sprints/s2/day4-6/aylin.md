# Aylin – Sprint 2, Tag 4–6
## Daily Tag 4 (19.11.)
Gestern: Testskript-Entwurf. Heute: Pairing-Termin 10:00; `felix/pairing_antworten.md` lag nicht vor, aber Felix' Spike vom 19.11. setzt D9 um (URSACHE-Glied, `root_pos` kanonisch, `params` mit `n_lkw`, Streckenlänge, Gleiszahl, Validator). Vertrag v1 daraus gelesen, Textvorlagen auf D11 umgestellt. Blocker: Bestätigung je Feld nur als Code, nicht als Datei.
## Daily Tag 5 (20.11.)
Gestern: Vertrag v1. Heute: Testskript L-06 gegen Lenas `l06_fehler_final.md` und Daniels Protokoll abgeglichen, D2-Nebenmessungen eingebaut, F-06-Panel als Textspezifikation (D14). Blocker: keine `daniel.md`, keine `felix.md` für Tag 4–6; Gegenzeichnung offen.
## Daily Tag 6 (23.11.)
Gestern: Wochenende. Heute: A-06 mit Sophies finaler Palette und Daniels ΔE-Werten. Blocker: keiner.

## Ergebnisse
- **A-05: fertig als Text, Felix-Bestätigung nur per Code.** `aylin/diagnose_datenvertrag_v1.md`, `aylin/textvorlagen_testfehler_v1.md` (+ `laengen_check.py`: 16 Zeilen, längste 52 Zeichen), `aylin/f06_panel_spezifikation.md`. AK "Textspezifikation" (D14): **ja**. AK "Felix bestätigt je Feld": **teilweise**: Stand-Spalte aus `day4-6/felix/spike/` und `test_output.txt` gelesen (0 Pflichtfelder fehlen sim-seitig; `fuell_ist/soll`, `n_lkw`, `strecke_felder`, `gleiszahl`, `wait_since_tick` geliefert, Validator grün in S1, S2, S3, S1b, S2b). Fehlt: Streckennamen, Zugnamen in S1/S2, Klick-Log (alles F-06-Szene).
- **L-06 (Testskript, Fragebogen): fertig zur Gegenzeichnung, nicht pilotiert.** `aylin/testskript_l06_final.md`. Lenas Zählregel (Kreis benennen), 4 Züge, F6 gestrichen, `variante` übernommen; D2-Nebenmessungen Zeilenklicks, Nur-letzte-Zeile-Leser (Lenas Regel plus Spalte `zeilen_vorgelesen`), Median, "Was würdest du bauen?" ungezählt. AK: **teilweise**: Pilot und Tester fehlen, wartet auf echte Durchführung. Plan-B-Auslöser nach Lenas Definition nicht gegeben (Exit 0, Übergabe laut Daniels `build_md5.txt`, Vertrag abgeglichen).
- **A-06: fertig.** `aylin/a06_bau_ux_vorgaben.md`: 10 Grund-Strings, Ghost Weiß `#FFFFFF` = baubar mit dunklem Saum, Blau nur Hinweis (D10). AK: **ja**. Daniels ΔE: Weiß gegen Stadtfläche 17,4 (ok), Kollision nur mit Konsum-Weiß und Ok-Ring.

## Annahmen und offene Fragen an andere (mit Namen)
- **Felix:** Stand-Spalte als Datei bestätigen; Koordinatenachse `pos.y` = Karten-Z; Knotennamen Mühlbach/Kornfeld und Zugnamen in der F-06-Szene; Muss-Umfang Panel in 1 T, Streichliste Abschnitt 7; Klick-Log-Format.
- **Lena:** kanonischer Ort nach Felix' Regel (Mitte der umkämpften Abschnitte, nicht Abschnitt 13/32) in Tabelle 1; Entstehungsregel Ladungsmeldung ab 60 s; `R_LADUNG` "(12 von 40)"; Zeitpunkt von "Was würdest du bauen?"; CSV-Kopf v1.0.
- **Daniel:** Bogen an neue Spalten; Smoke-Test `validate()` leer, Zulieferer-Lkw in der Szene, F3 Zeile 5; keine neue Protokollvorlage gesehen.
- **Sophie:** Zoomstufe für den Kamerasprung; Markierungsformen gegen S-05.
- **Katrin:** Tester 6 + 2, Einwilligung, OBS, Zielrechner: nichts belegt (keine `katrin.md`).
- Annahmen: Ladungsmeldung ab `wait_ticks ≥ 600`; Streckenname aus Knotennamen; Sprung-Zoom "200-m-Abschnitt im Bild"; Lenas Fehlerdatei wurde gegen den alten Spike geschrieben.

## Risiko für das Sprintziel
Die Datenseite ist seit 19.11. nicht mehr das Risiko; das Risiko ist der F-06-Tag (Panel, Klick-Log, Szene mit Namen in 1 T) und der Testtag selbst: kein Pilot, keine bestätigten Tester, kein Zielrechner. Ein Bestehen belegt wegen des Deckeneffekts Lesbarkeit der drei Fälle, mehr nicht.
