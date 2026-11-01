# Sprint 6 Backlog (19.–30.01.2027), PO Jonas Weber

**Sprintziel:** Am 30.01. wählt Basti sein HQ selbst per Hover-Vorschau auf der Karte (8 von 8 Städten mit Vorschau, ≤ 5 Klicks bis Spielstart, kein Dialog, kein Archetyp) und startet mit einheitlich 6.000 $; mindestens 3 Standorte haben eine vollständige Kette (heute 2) und der Kredit-Start endet in 10–30 % der Läufe im Bankrott (300 Läufe je Standort). D-07-Regression bleibt 8/8.
**Stretch (nur nach Feature-Freeze Tag 7 und nur aus dem Puffer):** A-08 Diagnose-Toast (Ursache + Ort + 1 Aktion, Aylin 1, Felix 1); Label-Kanten komplett (Sophie 1); Tipp-Aufschlüsselung des Lizenzfaktors (Mira, nur wenn F-20 vor Tag 7 steht).

Alle Zahlen sind Modellrechnung. FPS, Hover-Latenz bei ~2.000 Bäumen, Ladezeit und Look-Last gelten erst nach dem Zielrechner-Messlauf. Tickets, die daran hängen, laufen "mit Auflage Zielrechner" (Daniels Gate).

| ID | Ticket | Owner | T | Akzeptanz | Folge |
|---|---|---|---|---|---|
| L-12 | D22 Regeln final: Wagnis erlaubt, Umsetzen-Regel, Kleinstadt 2.500, Vorschau-Texte | Lena 1,5 | 1,5 | Tag 2 fertig. Je 8 Städte Text für Radius, Kette, Größe, Lizenzfaktor, Gelände. Wagnis-Text sachlich, ohne Rot. Umsetzregel als Zeile im Regelpapier | Blockiert Miras Start |
| F-21a | Spike-Lager-Fix (economy.gd:746) mit Regressionstest, neue md5 | Felix 2,5 | 2,5 | Tag 1–2. Lager ≤ Kapazität in 20 Läufen, Parität soa/alt 10/10, neue md5 dokumentiert. Kein Bench-Vergleich (es gibt kein Vorher) | Voraussetzung für T-14-Messung |
| T-14 | Ein Startkapital 6.000 $, Lok-Fixkosten 90 $/min, Bankrottquote nachmessen | Tobias 3 | 3 | JSON-Werte an Sophie und Felix bis Tag 2. Mittelfurt, Haberau, Kohlberg je 300 Läufe: Bankrott 10–30 %, M7 35–50 min ±15 %. Zug schlägt Lkw ab ≤ 33 E/min bei 25 Feldern. Finale Zahlen Tag 5 | Neu rechnen, falls Basti-Feedback das Band kippt |
| T-14b | Städte-Datenblatt als JSON (8 Städte: Radius, Ketten-Luftlinie, Größe, Lizenzfaktor, Gelände), aus der eingefrorenen Karte erzeugt | Tobias 1 | 1 | Nach Karten-Freeze Tag 4, Übergabe an Mira Tag 5. Ketten-Status ohne neuen Sim-Code | Quelle der Vorschau |
| S-12 | Kartenpaket: Werkzeugfabrik 40 F., Mühle Mittelfurt 45 F., Dorfnachfrage ×2, Karte neu einfrieren | Sophie 1,5, Tobias 0,5 | 2 | Beginnt Tag 1 mit den S5-Werten. Validator Exit 0, check_s10 grün, NO/SW unter Grenze, Fluss-Schnitt-Test grün, ≥ 3 Städte mit vollständiger Kette, Parität 10/10, D-07 8/8. Freeze Karte Tag 4 | Neue md5 |
| F-20 | D22 HQ-Platzierung: Platzierungsmodus, Hover-Vorschau im rechten Panel, Ghost, "HQ hier gründen", Startdialog und Archetyp entfernt | Mira 5, Felix 1,5, Aylin 1 | 7,5 | Neue Datei `hq_placement.gd`, main.gd nur Hooks, netto nicht größer. Kein `archetyp` mehr in start_game/ARCH/start_company, ein Kapital-Key. ≤ 5 Klicks ab Kartenstart. Vorschau ≤ 150 ms ±50, ≤ 6 Zeilen, Panel ≤ 380 px. Ring ≤ 0,4 s, bei Reduced Motion sofort. Zustände Icon + Text, Kontrast ≥ 4,5:1, Esc bricht ab, kein Modal, Zeit pausiert bis zur Gründung. 8 von 8 Städten zeigen die Karte. Umsetzen laut D22-Entscheid unten. Freeze Tag 7 | Pin-Vergleich und Tipp-Aufschlüsselung nach R2. Kürzungsreihenfolge bei Verzug: Geländezeile, Ring-Animation, Wechsel-Politur. Ketten bleiben |
| U-02b | HUD-Rest: Zielpfeil, Linienliste ≤ 340 px (Zeile kürzen), Kopfleiste mit Kasse und ruhiger Zeile "Skillpunkt gespart", Haberau-Label im Nahzoom | Felix 1,5, Aylin 0,5, Sophie 0,5 | 2,5 | Maße nach Spec bei 1600 px, kein Clipping, Zielpfeil frei von Labels, Haberau-Label sichtbar | Label-Kanten allgemein = Stretch |
| S-13 | Look klein: HQ-Gebäude (Ghost weiß, gesetzt farbig) und Industrie-Props für Mittelfurt, Haberau, Kohlberg | Sophie 2,5 | 2,5 | Gras-Kontrast ≥ 3:1 am Marker, Bäume ohne Schatten, 3 Kandidaten sichtbar gefüllt. Wasser/Gelände nicht in S6. Erledigt erst nach Zielrechner-Messlauf | Wasser R2 |
| SK-01 | Skilltree-Konzept v0, nur Papier | Lena 1 | 1 | Start Tag 6. Eine Seite: Slots, Punktefluss ab M1b, max. 3 Beispieläste mit Wirkung in Prozent. Kein Bau, keine Balance | Wartet nicht auf Feedback, kein Wunschzettel |
| L-13 | Aufgabenkarten für Bastis nächsten Durchlauf (HQ setzen, Umsetzen, erste Lieferung) | Lena 1, Aylin 1 | 2 | Karten ab Tag 8 fertig, im Ton von L-11, Wagnis-Standort nur als Option, nicht als Aufgabe | Review Tag 10 |
| D-08 | Abnahmen, Regression erweitern, Zielrechner-Messlauf | Daniel 5, Aylin 1 | 6 | Testeinstieg ohne `start_game("agrar")`, Platzierung per Mausereignis (Hover, Ghost, Abbruch, Umsetzen), Screenshot je Standorttyp, 100-Seed-Bankrottlauf als Regression, 8/8. Messlauf sobald Basti die .exe startet. Freigaben ohne Messung nur "mit Auflage Zielrechner" | Gate R2 |
| J-09 | R1-Feedback einarbeiten, R2-Scope; Lena schreibt die halbe Seite Regelskizze Firmenkauf, falls Basti ja sagt | Jonas 2, Lena 1 | 3 | Protokoll bis Tag 10, Backlog S7 steht | Entscheid Firmenkauf |
| K-10 | Rollenbedarf R2 prüfen, Mira ab S7 auf 8 T | Katrin 1 | 1 | Eine Seite, Ergebnis: kein Tech-Art, Audio vorgemerkt | |

## Geschoben
- **A-08** Diagnose-Toast: Stretch ab Tag 8 (die Ursachenliste ändert sich mit F-20; vorher Wegwerfarbeit). Chip am Fahrzeug R2.
- Pin-Vergleich in der Vorschau, Tipp-Aufschlüsselung des Lizenzfaktors, Label-Kanten allgemein, Aufteilung main.gd (HUD raus) als R2-Ticket.
- Firmenkauf und Betriebsprofile (SP-01): kein Bau in S6, siehe Fragen an Basti.

## Gestrichen
- F-21b 10k-Vorbereitung (nach Messlauf neu beurteilen).
- S-13 Wasser/Gelände (Frame-Budget unbekannt).
- Tech-Art-Rolle.
- Archetyp-Auswahl samt Startdialog (D22), `start_capital_agrar/mining`.

## Streitprotokoll
- **F-20 Umfang (Lena 5 T, Felix 7,5 T, Mira Vollumfang):** Felix bei der Schätzung, Mira beim Umfang. 7,5 T, weil Archetyp-Ausbau und Testumbau echte Arbeit sind. Gekürzt wird bei Pin und Tipp-Aufschlüsselung, nicht bei Ketten: Ohne Ketten ist die Vorschau leer. Felix' Sorge vor neuem Sim-Code entfällt, die Luftlinie kommt aus dem Datenblatt-JSON.
- **Reihenfolge S-12 vor F-20 (Lena, Felix gegen Aylin/Mira):** Lena und Felix. Karte friert Tag 4 ein, Mira startet Tag 3 mit Platzhalterdaten, echtes Datenblatt Tag 5.
- **Wagnis-Standorte (Lena, Aylin für erlauben; Tobias für sperren):** Lena und Aylin. Sperren wäre eine Auswahl durch die Hintertür und widerspricht D22. Tobias' Punkt gilt für den Text: sachlich "im Slice nicht balanciert", und die Aufgabenkarten führen Basti nicht dorthin.
- **S-13 (Sophie 4 T, alle anderen 2,5 T):** 2,5 T, Wasser raus. Sophie setzt sich bei "nicht auf null" und beim HQ-Gebäude durch: Ein Ghost ohne Gebäude ist kein Gründen, Aylins Marker-Variante verliert.
- **A-08 (Aylin dafür, Lena/Tobias/Felix/Mira dagegen):** Stretch. Aylin hat inhaltlich recht, "Lkw steht" ist der größte Lesbarkeitsmangel. Mira hat aber keine Kapazität, und vor Freeze ist die Ursachenliste instabil.
- **SK-01 (Lena dafür, Tobias, Felix, Aylin, Sophie dagegen):** Lena, kleiner. 1 T, nur Papier, Tobias 0, Start Tag 6. Ein Skillpunkt ab M1b ohne Ziel ist ein D22-Bruch, die ruhige Kopfleisten-Zeile (Aylin) überbrückt, das Papier gibt ihr ein Ziel.
- **U-02b (Lena 1 T, Aylin 2 T, Felix 3 T):** 2,5 T. Haberau-Kante gehört rein, weil Haberau ein HQ-Kandidat ist, der Rest der Label-Kanten ist Politur.
- **Spike-Lager-Fix (Felix jetzt, Daniel später):** Felix. Ohne Fix ist die Bankrottmessung verzerrt, das schlägt Daniels fehlendes Bench-Vorher. Neue md5 wird dokumentiert, der Zielrechner-Lauf wird die neue Referenz.
- **T-14-Übergabe (Aylin Tag 2, Lena Tag 3):** Aylin. Kapital- und Fixkosten-JSON Tag 2, finale Bankrottzahlen Tag 5.
- **Messumfang (Design 300 Läufe, Technik 100 Seeds):** beides. 300 je Standort für die Abnahme, 100 Seeds als schnelle Regression.
- **Freeze (Daniel):** Tag 7. Abnahme Tag 8–9, Bugfix Tag 10.
- **Pin-Vergleich (Aylin für, Sophie dagegen):** Sophie. Civ zeigt per Hover, ein zweiter Panel-Slot kostet Layout.
- **Tech-Art (Katrin-Prüfung):** abgelehnt, Sophie trägt die Kenney-Props selbst.

## Meine Entscheidungen zu D22
1. **Wagnis-Standorte: alle 8 erlaubt.** Hinweis ohne Rot und ohne Verbot, z. B. "Kein Rohstoff im Radius. Nächste Farm 121 Felder, Lizenz ×3,9." Seehafen und Weidenau zusätzlich "im Slice nicht balanciert". Gemessen werden nur Mittelfurt, Haberau, Kohlberg.
2. **Umsetzen: ja, bis zum Kauf der ersten Lizenz oder 2 min Spielzeit, was zuerst eintritt.** Kostenlos, ein Klick auf Toast oder Ring. Danach fest, weil sonst die Lizenz im Radius (×0,70) zum Preisexploit wird.
3. **Kleinstadt bleibt bei 2.500.** Das Wachstumsfenster auf 5.000 (39 min) ist gerechnet, bei 1.000 fiele die Nachfrage von 25 auf 10 E/min. Kohlbergs Problem ist die ferne Werkzeugfabrik, und die löst S-12.
4. **Reihenfolge und Freeze:** Tag 1–2 L-12, Lager-Fix, T-14-Start, S-12-Start, Felix' Schnitt in `economy.start_company`. Tag 3 Mira startet F-20. Tag 4 Karten-Freeze. Tag 5 Datenblatt, finale Bankrottzahlen. Tag 6 SK-01 startet. **Tag 7 Feature-Freeze**, Tag 8–9 Abnahme-Lauf, Tag 10 Bugfix und Review. Neuer Code nur in neuen Dateien, kein Umbau von main.gd vor F-20.

## Kapazität (T)

| Person | Kapazität | Plan | Puffer | Belegung |
|---|---|---|---|---|
| Felix | 8 | 5,5 | 2,5 | F-21a 2,5, F-20 1,5, U-02b 1,5 |
| Mira | 6 | 5 | 1 | F-20 5 |
| Aylin | 8 | 3,5 | 4,5 | F-20 1, U-02b 0,5, L-13 1, D-08 1 |
| Sophie | 8 | 4,5 | 3,5 | S-12 1,5, S-13 2,5, U-02b 0,5 |
| Lena | 8 | 4,5 | 3,5 | L-12 1,5, SK-01 1, L-13 1, J-09 1 |
| Tobias | 8 | 4,5 | 3,5 | T-14 3, T-14b 1, S-12 0,5 |
| Daniel | 8 | 5 | 3 | D-08 5 |
| Jonas | 8 | 2 | 6 | J-09 2 |
| Katrin | 8 | 1 | 7 | K-10 1 |

Der Plan liegt bewusst unter 6,5 von 8: Bastis Feedback ist die größte Unbekannte, und Mira ist der Engpass (Tag 3–7 voll auf F-20, keine Parallelisierung möglich). Stretch bedient sich nur aus Aylins, Felix' und Sophies Puffer und nur, wenn Tag 7 gehalten ist.

## Fragen an Basti
1. **Firmenkauf in R2: ja oder nein?** Empfehlung: ja, als Kern von "Firmenaufbau", Bau frühestens S7 und erst, wenn die Bankrottquote im Band 10–30 % steht. Betriebsprofile (SP-01) raus aus R2: Der Skilltree trägt die Spezialisierung nach D22, Profile wären doppelt.
2. **Wann startest du die Bench-.exe auf dem Zielrechner?** Empfehlung: bis Tag 4 (22.01.). Ohne Messlauf bleiben S-13 und die R2-Freigabe "mit Auflage", und Wasser/10k-Vorbereitung lassen sich nicht seriös planen.
3. **Wie hart darf der Start sein: Bankrott in 10–30 % der Läufe oder lieber ≤ 10 %?** Empfehlung: 10–30 % bleiben. Das ist Genre-Standard (D15), und der Kredit macht Fehler spürbar. Wenn dir ein Bankrott in Minute 20 beim Spielen den Spaß nimmt, sag es nach dem Durchlauf, dann rechnet Tobias neu.

## Bastis Antworten (01.11.)
1. Firmenkauf in R2: ja wie empfohlen, Betriebsprofile (SP-01/02) raus aus R2, Spezialisierung über den Skilltree.
2. Bench-.exe: Basti exportiert und startet sie selbst (Preset "Windows Desktop Bench").
3. Bankrottband 10–30 % bleibt.
