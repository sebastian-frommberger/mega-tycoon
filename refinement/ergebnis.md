# Refinement Sprint 2 (16.–27.11.2026) – Ergebnis

Moderation: Katrin Vogel (SM) · Entscheidung: Jonas Weber (PO) · verbindlich, kein separates Planning.

## Sprintziel S2

Bis 26.11. liegen die Auswertung des Diagnose-Playtests gegen eine einzige Messgröße, die Benchmark-Entscheidung „Sim-Kern bleibt GDScript ja/nein“ und eine konsistente Lizenz/Kauf-Leiter vor, damit das Gate am 27.11. Go/No-Go entscheiden kann.

**Stretch-Ziel:** Bau-Spike 45° ist von Jonas angespielt, das Urteil ist dokumentiert (F-07, startet nur, wenn F-06 am 24.11. abgenommen ist).

## Sprint-2-Backlog

Priorität für Felix bei Verzug: F-04 > F-06 > F-05 > F-07. Zeitliche Reihenfolge: F-04 (16.–19.11.) → F-05 (20.11.) → F-06 (23.–24.11.) → F-07 (Stretch, 25.–26.11.). Rutscht F-04, bekommt F-06 trotzdem den 23.11., dann wird F-05 auf den 10k-Lauf gekürzt.

| ID | Ticket | Typ | Owner | Timebox (Tage) bzw. SP | Akzeptanzkriterien | Reihenfolge/Abhängigkeit |
|---|---|---|---|---|---|---|
| F-04 | Netz-, Signal- und Diagnose-Spike (enthält F-03 Graph/A*, A-05-Pairing). Leitfrage: Lässt sich jeder Stillstand bis zur Wurzelursache mit Ort zurückverfolgen? | Spike | Felix | 4 T | 3 Szenarien (Gegenverkehr eingleisig, Deadlock-Kreis, Warten auf Ladung) laufen headless mit Exit-Code 0 · Deadlock in ≤ 50 Ticks erkannt, `get_wait_chain()` liefert den erwarteten Wurzelursache-Typ plus Koordinaten · jedes Feld aus A-05 geliefert oder als fehlend markiert · Spike-Build am 19.11. bei Daniel | 1 · 16.–19.11. · braucht A-05-Felder am 17.11. |
| A-05 | Diagnose-Meldung: Datenvertrag + grauer Mini-Entwurf (enthält gekürztes A-04). Leitfrage: Welche Felder braucht eine Meldung für Meldung → Kette → Sprung zur Karte? | Spike | Aylin (Felix 0,5 T in F-04) | 2,5 T | 1-seitige Spezifikation (Ort, Ursache, Vorschlag, Kette) plus Textvorlagen für genau die 3 Testfehler · Felix bestätigt je Feld „liefert/fehlt“ (Pairing 17.11. vormittags) · Figma-Mini-Entwurf (Meldung, Kette als Liste, Sprung) am 18.11. bei Felix | 1 parallel · Eingang für F-06 |
| F-06 | Testbuild Diagnose-Playtest: „Als Tester will ich ein kaputtes Netz untersuchen, damit wir die Auffindbarkeit der Ursache messen.“ | Story | Felix | 2 SP (≈ 1 T) | Gegeben die Testszene mit genau 3 Netzfehlern, wenn ich eine Meldung anklicke, dann zeigt das Panel die Kette als Liste, und ein Klick springt die Kamera zum Ort · jede Session wird als Replay gespeichert · Build am 24.11., 10 Uhr · Daniels Smoke-Test: 3/3 Fehler auslösbar, 0 Abstürze in 30 min | 3 · 23.–24.11. · nach F-04, A-05 · Fallback siehe L-06 |
| F-05 | Benchmark Sim-Kern (enthält D-05). Leitfrage: Bleibt der Sim-Kern bei GDScript? | Spike | Felix (Szene, Entscheidung) · Daniel (Messung) | 2 T (Felix 1 · Daniel 1) | headless 1k/5k/10k Fahrzeuge × 1×/8×, je 3 Läufe à 5 min auf dem Zielrechner (GTX 1660/6 Kerne/16 GB) · Median und p95 Sim-ms tabelliert gegen 4 ms · schriftliche Entscheidung GDScript ja/nein plus Gate-Folie bis 25.11. | 2 · Felix 20.11., Daniel 23.11. · Zielrechner am 16.11. (Katrin) |
| D-04 | Deadlock-Prüfung des Signal-Spikes | Spike | Daniel | 2 T | 3 manuelle Szenarien (Kreisverkehr voll, Weiche ohne Signal, Ausweichgleis zu kurz; 2 davon = Playtest-Fehler) × 3 Seeds, protokolliert: erkannt ja/nein, Ticks, Wurzelursache korrekt · zusammen mit F-04 ≥ 5/6 Szenarien in ≤ 50 Ticks erkannt · 0 Fehlalarme in 10 min Normalbetrieb · jeder Fehlschlag als Replay mit Tick im Tracker | ab 19.11., fertig 23.11. · nach F-04 |
| L-06 | **Diagnose-Playtest, ein Ticket** (enthält K-06 sowie die Anteile von Daniel und Aylin). Rollen: Lena Szenario + Auswertung · Aylin Testskript, Aufgaben, Fragebogen, Co-Beobachtung · Daniel Beobachtungsbogen, Durchführung, Protokoll, Smoke-Test · Katrin Rekrutierung, Raum, OBS · Jonas beobachtet ohne Ticket | Spike | Lena | 8 PT (Lena 3 · Aylin 2 · Daniel 2 · Katrin 1) | **Messgröße: ≥ 4 von 6 Testern finden die Wurzelursache von mind. 2 der 3 Fehler in < 60 s nach Klick auf die Meldung.** Es zählt nur die laut benannte Wurzelursache, nicht das Symptom · 3 Fehler mit Wurzelursache und Zielzeit bis 19.11. dokumentiert · 6 Tester (3 Veteranen, 3 Einsteiger) am 25.11. durch, Rohdaten-Tabelle am selben Tag · Auswertung + Go/No-Go-Empfehlung bis 26.11. | Testskript 18.11., Tester 20.11. · Fallback: Steht F-04 am 20.11. nicht, läuft der Test mit präparierten Saves und geskriptetem Feed (Entscheidung im Daily am 20.11.) |
| T-05 | Startkapital und Lizenz/Kauf-Leiter. Leitfrage: Welches Startkapital je Archetyp ergibt „3 Lizenzen oder knapp 1 Kauf“, ohne dass Kaufen immer besser ist? | Spike | Tobias | 2,5 T | Tabelle für 4 Archetypen mit Break-even inkl. 50 % Anrechnung und 15 % Werksmarge · je Archetyp mind. 1 Startfall, in dem die Lizenzroute im Break-even vor dem Kauf liegt · Widerspruch 15–30k $ vs. 1–4k $ × Stufe als Decision Record aufgelöst · Zahlen am 19.11. bei Lena | 1 · braucht HQ-Startwerte von Lena bis 17.11. |
| L-05 | Paper-Prototyp HQ-Start (enthält L-03 Meilensteine 1a–3) | Spike | Lena | 2 T | 3 Runden à 30 min mit Nicht-Designern · in ≥ 2/3 Runden begründet der Spieler seine Stadtwahl mit einer Kette · das T-05-Startkapital reicht in 3/3 Runden für 3 Lizenzen, ≥ 2/3 äußern den Kaufwunsch vor Minute 25 · Tabelle 1a–3 (Auslöser, Lernziel, Zielzeit) liegt als Testmaterial vor | Runden 20.–24.11. · nach T-05 |
| T-04 | Sättigung und Stadtwachstum simulieren. Leitfrage: Treffen F_sätt 1,0/0,4/0,1 und W 0,6/0,25/0,15 die Zielzeiten ca. 12 / ca. 80 min? | Spike | Tobias | 1,5 T | Zeitreihe im Sheet, Abweichung ≤ 15 % zu 12 und 80 min · Variante „Personen nur als Bonus“ gerechnet, Empfehlung in einem Satz | 2 · Gewichte W von Lena bis 17.11. |
| F-09 | JSON-Festkomma-Konvention. Leitfrage: Trägt Cent/Ticks die VS-Ketten? | Spike | Tobias (Felix 30 min Review) | 1,5 T | Schema für goods, vehicles, economy_constants · VS-Beispieldatei validiert lokal gegen das Schema (Exit 0) · Felix hat die Festkomma-Konvention im Review abgezeichnet | 3 · Review in Felix' Fragestunde, ab 23.11. |
| S-03 | Look-Test Diorama vs. Karte (enthält Kamera 30°→70° und Höhennebel aus S-04). Leitfrage: Bis zu welcher Kartengröße bleibt das Netz ab 800 m als Karte lesbar? | Spike | Sophie | 3,5 T | Testszene selbst gebaut (1 Stadt, 2 Industrien, Strecke, 200 MultiMesh-Quader) · Kamerafahrt 50→1.000 m in 5 s: kein Frame > 33 ms, 3/4 Reviewer sehen im Video kein Popping · 4/6 Kollegen finden Stadt, Industrie und Strecke in der Kartenstufe in < 10 s · Entscheidung Zoom-Blend ja/nein plus Lesbarkeitsgrenze bis 20.11. im Wiki | 1 · Felix 30 min Review `visibility_range` |
| F-08 | Kartengröße entscheiden (statt Terrain-Ticket) | Gate | Jonas (mit Felix, Sophie) | 1-h-Termin (je 0,25 T) | Decision Record mit Zielgröße für den Slice und Rückfallgröße · begründet mit Median/p95 aus F-05 und Lesbarkeitsgrenze aus S-03 · float32-Check dokumentiert | 24.11. · nach S-03 und F-05 |
| S-06a | Asset-Liste Vertical Slice (Gate-Input) | Gate | Sophie | 1 T | jedes VS-Asset mit Polybudget, LOD, Owner, PT (Lkw = 300 Tris als Referenz) · mit Katrin abgestimmt bis 24.11. | Eingang für K-07 |
| A-06 | Bau-UX-Vorgaben für den Bau-Spike | Spike | Aylin | 0,5 T | Liste aller Grund-Strings im Klartext (kein `ERR_*`) · Ghost-Regel baubar/nicht baubar plus Grund am Cursor · am 23.11. bei Felix | Eingangsbedingung für F-07 |
| K-07 | Gate M0 vorbereiten | Gate | Katrin | 2 T | Gate-Dokument mit je einem messbaren Kriterium: L-06-Messgröße, 4 ms (F-05), D-04-Schwelle, Lizenz/Kauf-Leiter konsistent und in L-05 bestätigt, Kartengröße entschieden · VS-Backlog in 2-h-Planning-Poker mit Felix je Epic in T-Shirt-Größen geschätzt · Go/No-Go-Protokoll am 27.11. | 26.11. fertig · nach allen |
| J-05 | Pillar-Review und Go/No-Go-Empfehlung | Gate | Jonas | 2,5 T | je Pfeiler eine prüfbare Ja/Nein-Frage, festgelegt bis 18.11. · Review von F-04, F-05, S-03 (F-07 nur bei Stretch): Rot = Frage mit Nein beantwortet, Ampel mit Begründung bis 25.11. · schriftliche Go/No-Go-Empfehlung bis 26.11. | nach F-04, F-05, S-03, L-06 |
| F-07 | **Stretch:** Bau-Spike 45° (Wegwerfcode, ohne Kurvenglättung, Undo, Abriss, Steigung). Leitfrage: Trägt Ziehen mit Snap Pfeiler 2? | Spike | Felix | 1 T (nur aus Puffer) | Ziehen, Snap und Ghost gültig/ungültig mit den Grund-Strings aus A-06 · Jonas setzt 10 Segmente in < 60 s ohne ungültige Platzierung · Jonas beantwortet die Pfeiler-2-Frage ja/nein, dokumentiert am 26.11. | 4 · Start nur, wenn F-06 am 24.11. abgenommen ist · nach A-06 |

Regeln ab sofort: Fragen an Felix täglich 14–15 Uhr. Feste Ausnahmen sind Aylin am 17.11. vormittags und Sophie mit 30 min. Jedes Ticket mit Spieler-UI hat UX als Eingangsbedingung (Definition of Ready). Ohne Zahl im Akzeptanzkriterium kommt kein Ticket in den Sprint.

## Kanban (Art)

WIP 2 für Sophie. Diese Karten sind nicht Teil des Sprint-Commitments.
- **S-05 Statusfarben + Palette v1:** Formen Kreis/Dreieck/Achteck, Schweregrad-Farben rot/gelb/blau von Aylin übernommen, ein Simulator-Durchgang Deut/Prot/Trit mit Daniels Checkliste, Kollisionsprotokoll. In Arbeit ab 16.11. Blockiert F-06 nicht, der Testbuild bleibt grau.
- **S-06b Silhouetten-Sheet, 6 VS-Industrien:** Blindtest ≥ 90 % mit 5 Personen. In Arbeit, sobald eine WIP-Stelle frei ist.
- **S-05b Güterfarben, 7 Familien:** bleibt in „Briefing“, bis Tobias die Güterliste liefert.
- **S-04b SSAO-Vergleich + Environment `.tres`:** im Backlog, Start nach dem Gate.
- Keine Platzhalter-Meshes für die Spikes. Felix nutzt Würfel und Grauboxen, das Gleisprofil kommt mit dem Spline-Termin in KW 49.

## Geschoben nach S3 / gestrichen

| ID | Entscheidung | Grund |
|---|---|---|
| F-03 | in F-04 aufgegangen; Repath-Welle und verteiltes Caching nach S3 | Für die Gate-Frage reicht Graph + A*. |
| F-08 (Terrain) | Terrain-Arbeit nach S3; im Sprint nur der 1-h-Entscheidungstermin | Das ist eine Entscheidung, kein Bauauftrag. |
| F-09 (Rest) | CI-Validator sowie chains/industries/cities nach S3 | Felix hat nur 30 min. |
| F-05 (Rest) | CI-Zeitreihe, MultiMesh-LOD und Render-ms-Messung nach S3; Daniels Kriterium „≤ 10 % zu CI“ gestrichen | Die Gate-Frage betrifft den Sim-Kern. Ohne CI-Reihe gibt es keinen Vergleichswert. |
| D-05 | in F-05 zusammengelegt | Es ist dieselbe Messung, also eine Messreihe. |
| D-04 (Rest) | Szenario „Repath-Welle“ gestrichen; 3 Szenarien deckt F-04 automatisiert ab | Repath kommt erst in S3. Doppeltes Testen entfällt. |
| K-06 | in L-06 aufgegangen (Logistik 1 T) | Es ist derselbe Test. |
| L-06 (Rest) | Fehler „Stadt übersättigt“ und „Lizenz abgelaufen“ gestrichen, 5 → 3 Fehler | Ökonomie und Lizenzen existieren im Build nicht. |
| L-03 | 1a–3 in L-05 aufgegangen; Leiste v1 mit Aylins Ziele-Panel-Rahmen (0,25 T) nach S3 | Sie baut auf Startkapital-Zahlen, die vor T-05 falsch sind. |
| L-04 | nach S3, dann direkt ins JSON-Schema | Kein Importer da, nicht gate-relevant. |
| T-06 | nach S3 (erstes Economy-Ticket in R1) | Balance-Targets messen ab R1. Exploits sind ohne spielbare Ökonomie nicht reproduzierbar. |
| T-07 | nach S3; dazu SimWorld-Schnittstelle (Felix) als eigenes Ticket, beides als Top-Tickets im Release-Backlog R1 eingetragen | Ohne Schnittstelle wird es ein Wegwerfskript. Fürs Gate reicht das Sheet. |
| A-04 (Rest) | Vergleich Feed vs. Karte (≥ 30 % schneller), Szenarien 4–6 und „Firma kaufbar“ nach S3 | Bei 6 Testern gibt es eine Messgröße, keinen A/B-Test. Der Mini-Entwurf steckt in A-05. |
| A-06 (Rest) | Mockups für Magnet-Radius und Erreichbarkeits-Label in die Bau-Spezifikation M1 | Der Spike braucht nur Strings und die Ghost-Regel. |
| S-04 | Kamera und Nebel in S-03, SSAO/Environment auf Kanban | Der Look-Test sagt ohne Kamera nichts aus. |
| S-05, S-06b | Kanban statt Commitment; Silhouetten der restlichen 5 Typen nach R2 | Das sind Asset-Karten. Die Industrieliste ist nicht final. |
| J-05 (One-Pager) | One-Pager v1 nach S3 | Nicht gate-kritisch. Der PO braucht seine Zeit für das Review. |

## Streitprotokoll

| Thema | Positionen (wer wollte was) | Entscheidung PO | Begründung |
|---|---|---|---|
| Diagnose-Playtest fünffach geplant, Messgröße | Lena: 5 Fehler, 5 Tester, ≤ 3 min, 5 T unverhandelbar. Felix: 3 Fehler, 4/6 < 3 min. Aylin: < 60 s plus Feed-A/B. Daniel: eine Messgröße, < 60 s nach Klick. Katrin: 6 Tester. Sophie: ein Ticket, Owner Lena | Ein Ticket L-06, Owner Lena, 3 Fehler, 6 Tester, Daniels Messgröße. Lenas Wurzelursache-statt-Symptom-Regel ist Zählregel | **Daniel und Sophie setzen sich durch, ebenso Felix bei den 3 Fehlern.** Lena verliert 2 Fehler und 2 T, behält Ownership und Fallback. Aylin verliert den A/B-Vergleich. |
| Felix-Überlast und Bau-Spike im Sprintziel | Felix: 8 T ohne Puffer, F-07 1 T, „angespielt“ im Ziel. Lena: F-07 nur Stretch, 2 T. Daniel: F-07 2 T mit Undo/Abriss | Felix 7 T + 1 T Puffer. F-07 1 T als Stretch aus dem Puffer, ohne Undo/Abriss | **Lena setzt sich beim Ziel durch, Felix bei der Timebox.** Daniels Undo-Leitfrage fliegt raus, weil die Haptik die Gate-Frage ist. Ohne Puffer platzt der Sprint beim ersten Verzug. |
| Reihenfolge Felix | Felix: F-04 > F-06 > F-05 verbindlich. Lena: gleich, Freeze 23.11. Jonas braucht Benchmark für Kartengröße | Priorität wie Felix. Kalender F-04 → F-05 (20.11.) → F-06 (23.–24.11.), Testbuild am 24.11., 10 Uhr | **Felix setzt sich bei Priorität und Termin durch (24. statt 23.11.)**, Lena nicht. Der Benchmark muss vor dem Kartengrößen-Termin liegen. |
| D-04 Termin und Umfang | Daniel: 6 Szenarien, Build 17.11. Felix: frühestens 19.11., Repath raus, er automatisiert 3. Lena: Playtest-Fehler wiederverwenden | Build 19.11., Daniel prüft 3 Szenarien manuell (2 davon Playtest-Fehler), Repath gestrichen, Schwelle ≥ 5/6 in ≤ 50 Ticks | **Felix setzt sich durch, Lena teilweise.** Daniel verliert Termin und Repath, behält seine Schwelle als Gate-Kriterium. |
| Testbuild: Debug-Overlay oder Feed-Struktur | Felix: Overlay mit Kette als Text, 1 T. Aylin: Meldung, Kette als Liste, Sprung zur Karte, grau, plus fester halber Tag am 17.11. Lena: A-04/A-05 nur für die Testfehler | Aylins Struktur im F-06-Rahmen von 1 T. A-04 + A-05 zusammengelegt auf die 3 Testfehler. Pairing 17.11. vormittags | **Aylin setzt sich bei Struktur und Pairing durch.** Lena setzt die Kürzung durch. Ohne Ort und Sprung testen wir ein Log, nicht den USP. |
| Ökonomie im Gate (T-05, T-06, T-07, F-09) | Tobias: T-05 unantastbar, Ökonomie als Gate-Kriterium, T-06 + F-09 in S2. Daniel: F-09 nach S3. Alle: T-07 nach S3 | T-05 Commitment, Gate-Kriterium „Leiter konsistent + in L-05 bestätigt“ aufgenommen. F-09 bleibt (Felix nur 30 min). T-06 und T-07 nach S3 | **Tobias setzt sich bei T-05, Gate und F-09 durch, Daniel nicht.** Tobias verliert T-06: Ohne spielbare Ökonomie sind Exploits nicht prüfbar. |
| Look-Test und Kartengröße | Sophie: S-03 ohne Felix, F-08 erst nach S-03 und gemeinsam, Look als 4. Review-Gegenstand, Zusatz im Sprintziel. Lena: Paintover statt MultiMesh. Felix: Kartengröße über Benchmark + Float-Check | S-03 mit selbst gebauter MultiMesh-Szene. F-08 als gemeinsamer Termin am 24.11. nach S-03 und F-05. S-03 ins Pillar-Review. Kein Zusatz im Sprintziel | **Sophie setzt sich weitgehend durch.** Lena und Felix nicht. Das Sprintziel bleibt auf den Gate-Kern beschränkt. |
| L-05 / L-03 und Art im Commitment | Sophie: L-05 und L-04 nach S3. Tobias: L-03 in L-05. Aylin: L-03 nach S3. Lena: L-05 bleibt, L-03 1 T. Tobias: S-05/S-06 Kanban. Sophie: Asset-Liste im Sprint | L-05 bleibt (kostet Felix null, belegt Tobias' Gate-Kriterium). L-03 geht in L-05 auf. S-05/S-06b Kanban, Asset-Liste S-06a im Sprint | **Lena behält L-05, Tobias setzt L-03 und Kanban durch.** Sophie behält die Asset-Liste als Gate-Input für K-07. |

## Kapazität

Basis: 10 Arbeitstage, davon höchstens 8 T (80 %) inkl. Puffer verplant. Kanban-Zeit zählt mit.

| Person | verplante Tage | Puffer |
|---|---|---|
| Felix | 7,0 (F-04 4 · F-05 1 · F-06 1 · Reviews/Termine F-08, F-09, S-03, A-06 0,25 · Planning-Poker 0,25 · Interviews 0,5) | 1,0 (F-07 Stretch nur hieraus) |
| Lena | 6,5 (L-06 3 · L-05 2 · Startwerte/Gewichte an Tobias 0,5 · Fallback-Saves/Fake-Feed 0,5 · Gate-Input 0,5) | 1,5 |
| Tobias | 6,5 (T-05 2,5 · T-04 1,5 · F-09 1,5 · Economy-Vorlage Gate 0,5 · Support L-05 0,5) | 1,5 |
| Aylin | 5,5 (A-05 2,5 · L-06 2 · A-06 0,5 · UX-Vorlage Gate 0,5) | 2,5 (springt bei F-04-Verzug für den Fake-Feed ein) |
| Daniel | 6,0 (D-04 2 · F-05 Messung 1 · L-06 2 · Farbsehschwäche-Checkliste 0,5 · QA-Bewertung Gate 0,5) | 2,0 (fängt den späten Spike-Build ab) |
| Sophie | 7,0 (Sprint: S-03 3,5 · S-06a 1 · Kanban: S-05 1,5 · S-06b 1) | 1,0 |
| Katrin | 6,5 (K-07 2 · L-06 1 · Zielrechner + Ausschreibungen 1,5 · SM-Tagesgeschäft 2) | 1,5 |
| Jonas | 6,75 (J-05 2,5 · F-08 0,25 · PO-Tagesgeschäft 2 · Beobachtung Playtest 0,5 · Gate 27.11. 0,5 · Pfeiler-Fragen 1) | 1,25 |

Zusagen außerhalb der Tickets: Katrin stellt den Zielrechner am 16.11. bereit und terminiert die Interviews für die Gameplay-Programmierung bis 20.11. Die 3D-Artist-Freigabe entscheidet Jonas am 20.11., bis dahin plant Katrin Freelancer-Überbrückung.
