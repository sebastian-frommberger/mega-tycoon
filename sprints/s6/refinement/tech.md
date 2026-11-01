# Position TECHNIK und QA (Felix, Mira, Daniel), Refinement Sprint 6

Befund Code: main.gd 3.119 Zeilen, 138 Funktionen. Archetyp ist verdrahtet: ARCH-Konstante, 16 Fundstellen, `start_game(a)`, `_init_milestones` (M3-Text, Quelle/Verarbeiter), Startlkw-Zahl, `economy.start_company(archetyp, …)` und JSON-Keys `start_capital_agrar/mining`. Tests (slice_test, d07_abnahme) rufen `start_game("agrar")`. F-20 ist also Umbau des Spielstarts, kein neues Overlay.

## Kandidaten

| ID | Votum | Tage | Harte Akzeptanz / Risiko |
|---|---|---|---|
| F-20 | rein, aber 7,5 statt 5 T (Mira 5, Felix 1,5, Aylin 1) | 7,5 | Klick auf Karte setzt HQ, Hover zeigt Radius und Ketten, kein Startdialog, kein `archetyp` mehr in start_game/ARCH, Tests grün auf neuem Einstieg, Regression 8/8. Platzierungsmodus kommt in **neue Datei** `hq_placement.gd`, main.gd bekommt nur Hooks und wächst netto nicht |
| L-12 | rein | 1,5 | Vor Miras Start fertig (Tag 2): Umsetzen, Wagnis-Standorte, Kleinstadtgröße |
| T-14 | rein | 3 | Ein Startkapital + Lok-Fixkosten als JSON-Werte, Bankrottquote mit 100 Seeds im Headless-Lauf |
| S-12 | rein | 2 | Karte neu eingefroren, neue md5, Parität bleibt 10/10 |
| U-02b | kleiner: nur Zielpfeil, Kopfleiste, Linienliste-Breite (Label-Kanten raus) | 3 | Aylin-Spec-Maße auf 1600 px, kein Clipping; Label-Kanten ist Poliermaterial |
| A-08 | raus (R2) | 0 | Ein-Klick-Aktion braucht stabile Ursachenliste aus `diagnostics.gd` und UI-Platz, beides hängt an F-20 |
| F-21 | rein, Felix 2,5 | 2,5 | Lager-Fix im Spike nur mit neuer md5 + Bench-Lauf; 10k-Vorbereitung raus |
| S-13 | kleiner: HQ-Gebäude und Props für 3 Kandidaten, Wasser raus | 2,5 | Frame-Budget unbekannt (siehe unten) |
| SK-01 | raus | 0 | Papier, aber bindet Lena/Tobias vor T-14 |
| D-08 | rein | 5 | Platzierungs-Regression plus Zielrechner-Lauf |
| J-09, K-10 | rein | | Puffer für Bastis Feedback |

## Reihenfolge

1. Tag 1-2: L-12 (Lena), T-14 startet, Felix 1 T Schnitt in `economy.start_company` (Archetyp raus, ein Kapital-Key).
2. S-12 (Karte) vor Mira-Test der Vorschau: Die Vorschau zeigt Ketten, die sich durch S-12 ändern (Mühle 45 F.). Sonst Doppelarbeit.
3. F-20 ab Tag 3, Feature-Freeze Sprint-Tag 7, Abnahme-Lauf Tag 8-9, Bugfix-Fenster Tag 10.
4. Kein Refactoring von main.gd vor F-20, aber harte Regel: Neuer Code nur in neuen Dateien. Aufteilung von main.gd (HUD raus, ca. 1.000 Zeilen) als Ticket in R2.

## Widerspruch an andere Disziplinen

- **Design (Lena, Einheit 5 T für F-20):** Die 5 T sind Mira-Annahme „Overlay“. Wegen Archetyp-Ausbau und Testumbau sind es 7,5. Wer 5 T plant, bekommt Hover ohne Regression. Alternative: Hover-Vorschau auf Radius + Stadtgröße kürzen (Ketten-Liste in R2). Mira: lieber voller Umfang mit 6 T, Felix: Kürzen, weil Ketten-Luftlinie neuer Code in der Sim ist.
- **Look (Sophie, S-13 mit Wasser/Gelände, 4 T):** Wasser hat im Slice keine Prüfung gegen Frame-Zeit. Ohne Zielrechner-Messung ist jede neue Mesh-Last blind. Wasser raus bis die .exe läuft. Daniel stützt das.
- **Skilltree (SK-01):** D22 sagt „Spezialisierung über Skilltree“, aber ohne F-20 und Firmenkauf gibt es nichts, woran er hängt. Paper jetzt erzeugt Wunschzettel für R2. Raus.
- **A-08:** Aylin will es wegen Theme-Passung jetzt. Wir: Ursachenliste ändert sich mit Platzierung, Erstellen vor F-20 ist Wegwerfarbeit.
- **Intern uneinig:** Felix will Spike-Lager-Fix jetzt (Risiko Bench-Referenz, eigene md5). Daniel: nein, solange kein Zielrechner-Bench existiert, hat der Vergleich kein Vorher.

## Daniel: was ohne Zielrechner freigebbar ist

- **Ja:** Funktionen (Platzierung per Mausereignis, Regression, Parität soa/alt, Kreditmechanik, Kontrast, Text ohne Überlauf bei 1600 px, Bankrottquote als Simulationslauf, Konfigurationswerte).
- **Nein:** jede Aussage über FPS, 1.000-Lkw-Tick auf echter Hardware, Ladezeit, Speicher, Hover-Latenz bei ~2.000 Bäumen, Look-Last. Diese Tickets werden „mit Auflage Zielrechner“ freigegeben, nicht „ja“.
- Gate: R1-Review und S-13 erst nach Messlauf als erledigt führen. Falls Basti die .exe nicht startet, bleibt R2-Freigabe bedingt.
