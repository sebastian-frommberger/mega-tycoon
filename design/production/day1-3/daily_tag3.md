# Daily Tag 3, Mittwoch 18.11.2026: Stand, Blocker, Konflikte, Entscheidungen

Moderation: Katrin Vogel (SM) · Entscheidung: Jonas Weber (PO) · Grundlage: die sieben Übersichten (`felix.md` bis `jonas.md`) und die Detaildateien, soweit für Prüfung nötig. Ich habe nichts gemessen. Alle Zahlen stammen aus den Berichten oder sind als **(K)** = Schätzung Katrin gekennzeichnet (Plan-Tage aus `refinement/ergebnis.md` minus berichteter Fortschritt, nicht von den Personen gemeldet).

**Ampel (Risiko für das Sprintziel):** Grün = im Plan, keine offene Bedingung mit Wirkung aufs Ziel. Gelb = erreichbar, wenn eine benannte Bedingung bis zu einem Termin eintritt. Rot = Akzeptanzkriterium in der beschlossenen Form nicht erreichbar oder Zusage bereits gebrochen.

## 1. Auf einen Blick

- Tag 3 von 10 ist durch. **Gemessen am Zielobjekt ist bisher nichts**: 0 von 6 Testern (+2 Reserve), 0 von 18 Benchmark-Läufen, 0 zählende D-04-Läufe, 0 von 3 L-05-Runden, 0 Personen im S-03-Test, 0 Menschen mit Rot-Grün-Schwäche geprüft.
- Vorhanden sind Entwürfe, Rechnungen, Prüfpläne und ein Spike-Code mit eigenen Tests. Das ist solide Vorarbeit, aber noch kein Gate-Beleg.
- Die zwei größten Lücken liegen bei mir: **Zielrechner** (Zusage 16.11., in keinem Bericht bestätigt) und **Tester-Rekrutierung** (nichts belegt). Daneben fiel das **Pairing Felix/Aylin am 17.11.** aus, obwohl es eine feste Ausnahme in meiner Moderation war.
- D-04 ist in der beschlossenen Form nicht erreichbar (zwei der drei Szenarien sind im Spike nicht baubar).

## 2. Stand je Ticket

| Ticket | Owner | Status | Rest (T) | Risiko | Beleg und Kernaussage |
|---|---|---|---|---|---|
| F-04 | Felix | in Arbeit (Code und Tests fertig, Übergabe offen) | 0,5 (Felix) | Gelb | `felix/spike/test_output.txt`, von Daniel zweimal nachgelaufen (Exit 0, identisch). Übergabe 19.11. offen. Feldvertrag mit Aylin offen, `root_pos` nicht kanonisch (siehe 3, Nr. 3). Grenzen: nur gerade Kanten, 1 Block Vorausreservierung. |
| A-05 | Aylin | in Arbeit | 0,75 (Aylin) | Gelb | Datenvertrag v0.1, Textvorlagen, Mini-Entwurf als Text liegen vor. Nicht erfüllt: „Felix bestätigt je Feld“ (Pairing ohne Ergebnis), Figma (Zugang fehlt). Ursache-Codes weichen ab. |
| L-06 | Lena (Aylin, Daniel, Katrin) | in Arbeit (nur Entwürfe: Szenario, Skript, Protokoll; kein Build, kein Tester, kein Pilot) | ≈ 5,75 von 8 PT (K) | Gelb | Lena 2,0 + Aylin 1,25 + Daniel 1,5 + Katrin 1,0. Fehlerliste unabgestimmt, Rekrutierung nicht belegt, F-06 nicht begonnen. |
| T-05 | Tobias | fertig als Rechnung, Abnahme offen | ≈ 0,25 (K) | Gelb | `tobias/t05_ergebnis.md`, `t05_decision_record.md`. Decision Record wartet auf PO. „Zahlen 19.11. bei Lena“ offen. Ausbaupfad und Kohle-Zufluss (Lenas Bitte) sind nicht im Ticket. |
| T-04 | Tobias | fertig (Rechnung), Kriterium teilweise | 0 | Grün | `t04_ergebnis.md`. Nicht im Gate-Kern. Ergebnis als CSV, nicht als Sheet. |
| S-03 | Sophie | in Arbeit | 1,0 (Sophie) | Gelb | Szene läuft. Frame ≤ 33 ms nicht belegt (Software-Renderer, ≈ 290 ms), Popping und 4/6 Kollegen nicht geprüft. Entscheidung nur vorläufig, nicht im Wiki. |
| S-05 | Sophie | in Arbeit (Kanban, nicht Commitment) | 0,5 (Sophie) | Grün | `s05/palette_v1.csv`, gerechnet, kein Betroffener. Nicht im Testbuild (so beschlossen). |
| D-04 | Daniel | in Arbeit (Plan fertig, Ausführung ab 19.11.) | 2,0 (Daniel) | **Rot** | „≥ 5/6 in ≤ 50 Ticks“ ist mit dem Spike nicht erreichbar; Schwelle 50 Ticks unterscheidet nichts. Vorabprüfung zählt nicht (von Daniel selbst so markiert). |
| J-05 | Jonas | in Arbeit (Fragen und Gate-Eingang fertig, Review ab 25.11.) | ≈ 2,5 (K) | Gelb | `jonas/pillar_fragen.md`, `gate_kriterien.md`. Pfeiler 3 und 4 ohne Test, Schwellen unbestätigt. Widerspruch bei G1 (siehe E6). |
| K-07 | Katrin | in Arbeit | ≈ 1,5 (K) plus 1,5 Zielrechner/Ausschreibungen | **Rot** | Gerüst heute (`k07_gate_geruest.md`). Zielrechner-Zusage 16.11. gebrochen bzw. unbelegt. Poker nicht terminiert. |

Weitere Tickets ohne Bericht oder ohne Start:

| Ticket | Stand | Risiko |
|---|---|---|
| F-05 (Felix 20.11., Daniel 23.11.) | nicht begonnen. Hängt an Zielrechner, Release-Export, Prüfsumme, Pacing. | Gelb |
| F-06 (Felix 23.–24.11., 1 T) | nicht begonnen. Seit dem Refinement sind Anforderungen dazugekommen (Klick-Log, Replay mit Klick, drei getrennte Teilnetze, Stillstand ≥ 120 s als Schnappschuss, Namenstabelle, Zusatzfelder Streckenlänge, Gleiszahl, Füllstand, `n_lkw`). **Niemand hat das geschätzt.** | Gelb |
| L-05 (Lena) | Vorbereitung läuft (Rest bis Durchführung 0,75 T), nichts gedruckt, Tester nicht belegt. | Gelb |
| F-08 (24.11.) | Eingänge fehlen (F-05-Zahlen, S-03-Entscheid, float32-Check, den kein Bericht erwähnt). | Gelb |
| F-09 (Tobias, ab 23.11.), A-06 (Aylin, 23.11.) | nicht begonnen, im Plan. | Grün |
| S-06a Asset-Liste (Sophie, 24.11., Gate-Input) | in keinem Bericht erwähnt. | Gelb |
| F-07 Stretch | faktisch nicht erreichbar (siehe E7). | Rot |

## 3. Belegprüfung: gemeldet, aber vom Beleg nicht getragen

| Nr | Meldung | Was der Beleg trägt | Folge fürs Gate |
|---|---|---|---|
| 1 | Felix: „Deadlock in ≤ 50 Ticks erkannt, gemessen 4 Ticks“ | Die 4 sind `DEADLOCK_CONFIRM_TICKS = 5` (Parameter), die Sim ist deterministisch, Erwartungswerte und Runner sind von Felix. Das belegt „die Fälle werden erkannt“, nicht „schnell“. | Voraussetzung (V), kein G3-Messwert. G3 prüft Abdeckung, nicht Tempo. |
| 2 | Felix: „Kontrolle 10 min, 0 Meldungen“ | Nur sein Layout K1 (2 Züge, 1.140 Warte-Ticks). Daniels Vorabläufe nutzten dasselbe K1. | Kein unabhängiger Fehlalarm-Beleg. Daniels eigenes Normalnetz nötig. |
| 3 | Felix: „Wurzelursache plus Koordinaten: ja“ | Für seine Tests ja. Aber `root_pos` ist je angefragtem Fahrzeug verschieden (200 m Abstand beim Gegenverkehr) und stimmt nicht mit dem letzten Kettenglied überein (Daniel B1, B2). Aylins Validator (`kette[-1] == ursache`) würde die Meldung ablehnen. | „Klick springt zum Ort“ (F-06, L-06) ist so nicht eindeutig. Kanonischer Ort je Deadlock fehlt. |
| 4 | Daniel: Vorabprüfung „12 Läufe richtig, 0 Fehlalarme“ | Er markiert sie selbst als nicht zählend. Wichtig: die „3 Seeds“ haben keine Varianz (Sim ohne Zufall), es sind Wiederholungen. | G4 „9/9 mit 3 Seeds“ wäre eine Tautologie. Formulierung ändern, nicht als Seed-Test verkaufen. |
| 5 | Tobias: T-05 „fertig, 4/4 Startfälle“ | (a) Startkapital ist per Formel so gesetzt, dass der Satz „3 Lizenzen oder knapp 1 Kauf“ stimmt: Konsistenz durch Konstruktion. Tobias selbst: der Kontostand taktet kaum, Kaufwunsch entsteht nicht durch Kapital. (b) Bei Agrar tragen F4 (Getreidefarm) und F5 (Dorf-Markt 9 E/min) die 4/4, dort lohnt Kaufen nie. Beim Verarbeiter im Standardfall liegt der Kauf nach 17–22 min vorn. (c) Schwelle „> 30 min“, Preisbasen, KI-Anteil 40 % sind Setzungen. | G5 stützt sich auf R (Rechnung). Trennschärfe liefert erst L-05. |
| 6 | Lena: „HQ-Startwerte geliefert“, „nachgerechnet“ | Entwurf. Die Nachrechnung importiert Tobias' Modell unverändert und reproduziert nur dessen Zahlen. Das ist keine zweite unabhängige Quelle. Lena vermerkt außerdem, dass die Tageseinträge Arbeitsreihenfolge sind, keine Kalendertage. | „Frist 17.11. eingehalten“ ist nicht belegbar. Zahlen nicht doppelt zählen. |
| 7 | Tobias: T-04 „≤ 15 % erfüllt“ | Die Zielzeiten 12 und 80 min folgen exakt aus +2 %/Monat (ln-Rechnung). Variante A trifft sie dort per Konstruktion, Variante B ist laut Tobias und Lena auf die Ziele geeicht. Echte Befunde: Klippe bei W = 0,8, Tor-Empfindlichkeit, Güterspieler 45/323 min. | Kein Gate-Kriterium. Nicht als „Zielzeiten bestätigt“ zitieren. |
| 8 | Sophie: S-03-Entscheidung „Blend ja, Grenze 4000 m“ | Pixel-Differenz-Proxy (kein Reviewer), eigener Blick auf Screenshots, 3 Objekte, 720p. Sophie berichtet das sauber. | G6 höchstens Gelb, G7 offen. |
| 9 | Jonas: J-05 „fertig“ | Fragen fertig. Schwellen sind PO-Vorschläge ohne Bestätigung von Felix, Daniel, Tobias. Pfeiler 3 und 4 ohne Test. Widerspruch G1 (Rot bei „kein echter Build“) gegen Pillar-Datei (Plan B höchstens Gelb). | Siehe E6. |
| 10 | Berichte widersprechen sich | Daniel: „Sophies Palette fehlt“, Sophie: `palette_v1.csv` plus Gegenprobe mit Daniels Skript (Datei vorhanden, geprüft). Tobias: „Lenas Dateien fehlen“, Lena: Dateien da. Aylin und Felix sahen gegenseitig nichts. | Synchronisationslücke, kein Fortschrittsnachweis. Daniel startet den Farbcheck am 19.11. |
| 11 | Daniels Zeitplan D-04 | „21.11.“ ist ein Samstag. Der Fehlalarm-Test gehört auf den 20.11. | Termin korrigieren. |
| 12 | Meine Zusagen (Zielrechner, Tester, Interviews) | In keinem Bericht belegt. Daniel (Tag 1) und Sophie (Tag 3) nennen sie ausdrücklich als fehlend. | Gilt als nicht erfüllt, bis ich einen Beleg liefere. |

## 4. Blockerliste

| Nr | Blocker | Betrifft | Verantwortlich | Termin |
|---|---|---|---|---|
| B1 | Pairing Felix/Aylin ohne Ergebnis: Feldvertrag und Ursache-Mapping. Ich lege es neu: Do 19.11., 10:00, 60 min, Ergebnis = unterschriebene Feldtabelle „liefert/fehlt“ und Mapping | F-04, A-05, F-06, L-06 | Katrin (Termin), Felix und Aylin (Ergebnis) | 19.11., 12:00 |
| B2 | Spike-Übergabe an Daniel (Ordner, Aufruf, Seed-/Szenario-Wünsche S1, S2, S4) | D-04, L-06 | Felix | 19.11., 12:00 |
| B3 | Zielrechner nicht bestätigt (Details in 7) | F-05, S-03, G2, G7 | Katrin | Zusage 19.11., 12:00; einsatzbereit 20.11., 18:00 |
| B4 | Tester L-06: 6 + 2 Reserve extern, nicht bestätigt | L-06 | Katrin | 20.11. |
| B5 | Tester L-05 (3 Nicht-Designer) | L-05, G5 | Katrin mit Lena | 19.11., 18:00 |
| B6 | Einwilligungstext (Bild, Ton, Bildschirm, freiwillige Angabe Farbsehschwäche) | L-06, L-05, S-05 | Katrin | 19.11. |
| B7 | Entscheidung Startkapital A/C, damit Lena die Karten setzen kann | L-05, G5 | Jonas | 19.11. |
| B8 | Entscheidung D-04-Szenarien (Q1 von Daniel) | G3, D-04 | Jonas mit Felix, Daniel | 19.11. |
| B9 | Fehlerliste und Zählregel F2 (Kreis muss benannt werden) abstimmen | L-06 | Lena, Aylin, Daniel | 19.11. (Lenas Frist) |
| B10 | F-06-Umfang schätzen: Muss-Liste Aylin plus Lenas Build-Anforderungen. Wenn > 1 T, sagt Felix es im Daily | F-06, L-06 | Felix | 19.11., Fragestunde 14–15 |
| B11 | Zusatzfelder für F1 und F3: Streckenlänge, Gleiszahl, Füllstand ist/soll, `n_lkw`. Ohne sie ist die Wurzelzeile von Fehler 3 nicht erzeugbar (siehe Konflikt K1) | L-06 | Felix | 19.11. |
| B12 | Figma-Zugang für Aylin, sonst AK „Figma“ durch „Textspezifikation“ ersetzen (PO) | A-05 | Katrin (Zugang), Jonas (AK) | 19.11. |
| B13 | Release-Export-Templates 4.4.1 und Messbegriff (pro Tick oder pro Frame) | F-05 | Felix, Daniel | 20.11. |
| B14 | Ghost-Farbe (weiß oder blau) | A-06, S-05 | Aylin, Sophie | 20.11. (vor A-06 am 23.11.) |

## 5. Abhängigkeitskonflikte

| Nr | Konflikt | Auswirkung | Vorschlag zur Auflösung |
|---|---|---|---|
| K1 | **Ursache-Codes:** Felix `DEADLOCK`, `WARTEN_AUF_LADUNG`, `EINGLEISIG_GEGENVERKEHR` (plus `BLOCK_BELEGT_UNTERWEGS`, `KEINE`), kein Typ Ladung/Infrastruktur. Aylin `KREIS_BLOCKIERUNG`, `ZULIEFERUNG_ZU_GERING`, Typ `INFRASTRUKTUR`/`LADUNG`. Bei Fehler 3 ist es mehr als ein Name: Felix' Kette endet am Lager („wartet auf Ladung“). Lenas Zählregel wertet „Das Lager ist leer“ als Symptom, die Wurzel („zu wenig Zulieferer, nur 1 Lkw“) braucht `fuell_ist/soll` und `n_lkw`. | Ohne Zusatzfelder ist Fehler 3 für Tester nicht lösbar, das wäre ein Build-Fehler, kein Testergebnis. | Felix' Codes bleiben (sie stehen in der Mutationsprobe), Aylin mappt in der UI, Typ wird in der UI abgeleitet. Felix liefert die vier Zusatzfelder. Alles im Pairing B1. |
| K2 | **`root_pos` gegen letztes Kettenglied** (Daniel B1, B2). | Sprung zum Ort uneindeutig, Validator lehnt ab. | Kanonischer Ort je Deadlock (z. B. Block, den die Soll-Kette nennt) und `kette[-1] == ursache` festlegen. Pairing B1. |
| K3 | **Ghost-Farben:** Aylin „weiß = baubar“, Sophie „blau = baubar“, Blau ist aber auch „Hinweis“ (S-05). | A-06 am 23.11., später F-07. | Aylins Weiß übernehmen (Sophie bietet es an). Daniel prüft Weiß gegen Konsum-Weiß `#F2F2F2` und Stadtfläche im Farbcheck. Entscheidung 20.11. |
| K4 | **Tobias rechnete ohne Lenas Dateien**, Lena rechnet dann Tobias' Modell nach. | Scheinbare Übereinstimmung (siehe Belegprüfung 5, 6). Reale Differenzen bleiben: 3 bezahlte Lizenzen ohne Gratis-Lizenz, Meilenstein 3 im Bergbau, Kohle-Zufluss, Ausbaupfad (Meilenstein 7 mit 5.000 $/min ist nicht belegbar, das sind 6–12 Ketten). | Abgleich Lena/Tobias am 19.11. mit fester Liste der echten Differenzen. Ausbaupfad nicht in diesem Sprint (PO-Entscheid E1). |
| K5 | **D-04 gegen Spike:** „Weiche ohne Signal“, „Ausweichgleis zu kurz“ nicht baubar. | G3 nicht erreichbar. | E3. |
| K6 | **Fehlerlisten:** alte 5 Fehler in `plan/lena.md`, `plan/felix.md`, Quellenzeile `l06_protokollvorlage.md`. | Tester und Build könnten verschiedene Fehler meinen. | Gültig ist `lena/playtest_szenario.md` Abschnitt 2 (deckungsgleich mit F-04 S1 bis S3). Daniel streicht die Quellenzeile. |
| K7 | **Lena/Aylin:** Zählregel F2 (Kreis muss benannt werden, nicht nur zwei Glieder), Titel einheitlich „Zug X steht“, Vorschlag im Test ausgeblendet. | Messgröße hängt an diesen Regeln. | Lenas Fassung als Entwurf übernehmen, Aylin und Daniel bestätigen am 19.11. |
| K8 | **G2-Definition:** Overview (mein Dokument) p95 ≤ 6 ms, Daniel schlägt 8 ms als Warnschwelle vor, Felix' Konzept 8 ms pro Frame bei 8×. Offen: Sim-ms pro Tick oder pro Frame, Release-Export oder Editor-Build. | G2 könnte am 25.11. verhandelt statt gelesen werden. | Festlegung: Ampel nur über Median pro Tick bei 10k × 1× (Jonas). p95 Pflichtangabe, Warnschwelle 6 ms (Overview), 8× pro Frame nur berichtet. Nur Release-Export zählt, sonst „obere Schranke“. Felix und Jonas bestätigen am 19.11. |
| K9 | **Eintrittsdatum Gameplay-Programmierung:** Lena fordert Bestätigung „Start spätestens 30.11.2026“ bis 20.11., Felix 04.01.2027, mein Overview 01.02.2027 (spätestens 01.03.). | Grey-Box-Onboarding (08.01.) hängt daran. | Siehe 7, Interviews. |

## 6. Entscheidungsvorlagen für Jonas (PO)

Alle Empfehlungen sind meine. Entschieden ist nichts. Ziel: Entscheidungsrunde Do 19.11., 10:30, 30 min (Jonas, Lena, Tobias, Felix, Daniel, Katrin).

### E1 Startkapital-Skala (DR-T05-01)
- **Frage:** Option A (Startkapital 4.500 / 4.500 / 7.000 / 5.000 $, Satz neu gefasst) oder Option C (20–30 k $ lassen, Satz streichen). Option B (Preise × 6) ist verworfen: Break-even 83–199 min, Bergbau läuft in einen Soft-Lock.
- **Lage:** Eine Kette bringt 399–959 $/min, der Kontostand taktet das Tempo kaum (Tobias, Lena teilen das). A ist keine Pacing-Entscheidung, sondern macht den Satz wahr. Risiken: knappere Werte erzeugen Soft-Lock (Kreditrahmen ab Minute 0 nötig), die Ausgleichslogik in `hq.md` dreht sich um, 60-k-Erfahrenenstart und HQ-Ausbau müssen neu skaliert werden, das Casual-Gefühl bei kleinem Kapital ist ungetestet. Das L-05-Kriterium „Kapital reicht für 3 Lizenzen“ (350–686 $) ist unter A wie C praktisch garantiert und trennt nicht. Aussagekräftig ist nur der Kaufwunsch vor Minute 25, und den regen Ereignis- und Angebotskarten der Spielleitung an.
- **Empfehlung:** A als **Testannahme für L-05**, schriftlich „revidierbar nach L-05“. Gleich mit entscheiden: Kaufrabatt −20 % nur einmalig bei Meilenstein 5b, Kreditrahmen ab Minute 0 als Regel (kein Sprintcode), Lizenzlaufzeit im VS in Spielminuten. Skalierung 60 k und HQ-Ausbau als M1-Ticket nach dem Gate. C bleibt Rückfall, wenn L-05 das Casual-Gefühl bricht. Begründung: kostet nichts, ist mit Spielgeld prüfbar, Lena hat das Material schon darauf ausgelegt.
- **Ohne Entscheidung:** Lena druckt nicht, L-05 rutscht auf 24.11., G5 nicht vor 26.11. belegbar.

### E2 Messgröße L-06 und ihre Aussagekraft
- **Frage:** Messgröße („≥ 4 von 6 finden Wurzelursache von ≥ 2 der 3 Fehler in < 60 s“) ändern, ergänzen oder wörtlich lassen, und wie der Gate-Text sie liest.
- **Lage:** Drei Autoren (Aylin, Lena, Daniel) nennen unabhängig den Deckeneffekt: Die Kette endet in der Wurzelursache, Vorlesen der letzten Zeile zählt. n = 6: Lenas Rechnung (von mir bei q = 0,5 und 0,6 nachgerechnet) gibt P(Test besteht) = 34 % bei einer Trefferrate von 50 % je Fehler, 64 % bei 60 %. Das Wilson-Intervall für 4/6 reicht von 30 bis 90 %. Der Test trennt grob (q ≤ 0,3 fällt fast sicher durch, q ≥ 0,8 besteht fast sicher), im mittleren Bereich ist er ein Münzwurf.
- **Optionen:** (a) wörtlich lassen, Einschränkungen im Bericht; (b) Kontrollbedingung mit Kette ohne letzte Zeile (Mehraufwand F-06, nicht tragbar); (c) Nebenmessungen auswerten: Zeilenklicks, Anteil „Nur-letzte-Zeile-Leser“, Median der Zeiten (schon im Protokoll, kostet nichts).
- **Empfehlung:** (a) plus (c). G1 umbenennen von „Diagnose trägt“ in „Kette ist in 3 bekannten Fällen lesbar“. Der Bericht nennt Ergebnis, Intervall und Deckeneffekt in einem Satz. 3/6 bleibt Gelb. Kein „USP belegt“, auch nicht bei 6/6.
- **Ohne Entscheidung:** Das Ergebnis vom 26.11. wird im Gate als USP-Nachweis gelesen.

### E3 D-04-Szenarien 2 und 3 verschieben
- **Frage:** „Weiche ohne Signal“ und „Ausweichgleis zu kurz“ sind im Spike nicht baubar (keine Zuglänge, Signale immer automatisch). „≥ 5/6“ ist nicht erreichbar, G3 bliebe nach Jonas' Regel „offen“.
- **Optionen (Daniel Q1):** (a) Felix ergänzt Zuglänge und Signal-weglassen: keine Kapazität, F-06 und F-05 gehen vor. (b) D-04 prüft das Darstellbare, G3 wird neu gefasst. (c) Die zwei Szenarien kommen als M1-Auflage.
- **Empfehlung:** (b) plus (c). G3 neu: „Alle darstellbaren Szenarien (3 aus F-04, dazu Ring 6 Züge, Gegenverkehr mit Auffahrer, drittes legt Daniel am 19.11. fest) erkannt mit richtigem Typ, Objekt und Ort, und 0 Fehlalarme in 10 min mit Daniels eigenem Normalnetz.“ Das Gate nennt ausdrücklich „nicht geprüft“: Weiche ohne Signal, Ausweichgleis zu kurz, gekrümmte Netze, Pfadsignale, mehr als 6 Fahrzeuge. G4 spricht von „Wiederholungen“, nicht von Seeds. Nebeneffekt: entlastet Daniel um ca. 0,5 T.
- **Ohne Entscheidung:** G3 ist am 27.11. nicht lesbar, die Regel zwingt zum Vertagen.

### E4 Güterspieler-Wachstum, Variante B
- **Lage:** In Variante A braucht ein reiner Güterspieler 45 statt 12 und 323 statt 80 min (rund 4 × Ziel). In B (Basis 1,8 %/Monat, Zuschlag bis +25 % für Personen und Arbeitsplätze) liegen alle Typen im Rahmen (größte Abweichung +13,8 %, Personen bringen −20 %). B ist auf die Ziele geeicht (Tobias, Lena), das Ergebnis folgt aus der Eichung. Lenas Alternative 1,9 % / +15 % hat mehr Abstand (+7,5 %), aber nur −13 % Personenvorteil. Offen: reiner Personenspieler wächst nicht, Agrar-Tor bei 950 Einwohnern (rund Minute 3, Bretter fehlen), Doppelzählung der Arbeitsplätze.
- **Empfehlung:** B ja, Eichung 1,8 % / +25 % (damit Personenverkehr sichtbar zählt, Leitplanke „Personen und Güter“), Etikett „ungetestet, Prüfung im Grey-Box ab Januar“. Die +0,5-%-Regel aus `industry.md` streichen. Reiner Personenspieler und Agrar-Tor sind zwei eigene PO-Entscheidungen bis zum GDD, nicht fürs Sprintziel. Keine weitere Sprintzeit auf T-04.

### E5 Kartengröße und Rückfall (F-08, 24.11.)
- **Lage:** S-03 (Rechnung, keine GPU-Messung, keine Reviewer, 3 Objekte, 720p): 1.024² braucht für die Gesamtansicht ca. 7,4 km Höhe, die Stadt ist dort 37 px groß. 512² passt ab ca. 3,7 km und bleibt lesbar. F-05 hat keine Zahl. Der float32-Check steht in keinem Bericht. Mein Overview empfiehlt VS = 512², Sophies Konzept will mindestens 1.024².
- **Empfehlung:** Heute nicht entscheiden. Vorgabe für den 24.11.: **Ziel im VS 512²**, 1.024² erst M2 nach Terrain-Chunk-Test. Rückfall als Regel statt Zahl: „Wenn F-05 Median ≤ 4 ms nur bis 5k, dann Karte so, dass im VS höchstens 5k Fahrzeuge nötig sind.“ Eine Kantenlänge unter 512² hat niemand gerechnet, ich setze keine. Eingänge: F-05-Zahlen (23.11. abends), S-03-Grenze, float32-Check (Felix, 15 min). G6 ist bei teilweise belegter S-03-Grenze höchstens Gelb.

### E6 Messwert-Regeln und Go-Regel
- **Messwert-Regel (Jonas' Annahme 1):** Ich bestätige und ergänze. Synthetisch = Fake-Feed, präparierte Saves ohne F-04, Rechenmodelle, Entwicklerrechner, Selbsttests des Autors. Zusätzlich: Felix' Runner und Daniels Vorabläufe sind Voraussetzung, kein Messwert. Als Zielrechner gilt nur ein dedizierter Rechner (kein Entwicklerrechner). F-05 zählt nur als Release-Export, sonst „obere Schranke“. Lenas Stufe B1 (geskriptete Darstellung echter `get_wait_chain()`-Daten) fällt unter synthetisch.
- **Widerspruch G1:** `gate_kriterien.md` setzt Rot bei „kein echter Build“, `pillar_fragen.md` und Lena setzen Plan B auf „höchstens Gelb“. Nach der Entscheidungsregel wäre Plan B damit ein No-Go. **Empfehlung:** Plan B = Gelb-Deckel, nicht Rot.
- **Go-Regel:** „Höchstens 2 Gelb“ ist auf dem realistischen Pfad knapp (G5, G6 und evtl. G1 oder G7 sind wahrscheinlich Gelb). Drei Gelb ist in der Regel weder Go noch No-Go. **Empfehlung:** Go = kein Rot, alle Messwerte vorhanden, höchstens 2 Gelb in G1 bis G3, übrige Gelb nur mit Auflage, Owner und Termin. Fehlt ein Messwert: Vertagen mit Datum, nicht schönrechnen.

### E7 F-07 Stretch streichen
- **Lage:** Felix' Puffer (1 T) ist durch die ungeschätzten Zusatzforderungen an F-06, F-05 und D-04 aufgebraucht. F-07 startet am 25.11., dem L-06-Testtag, an dem Felix für Build-Probleme erreichbar sein muss. Jonas wäre Autor und Tester.
- **Empfehlung:** Streichen. G8 wird vorab „nicht nachgewiesen“ mit Auflage „Bau-Spike als erstes M1-Ticket, vor Content“ (steht so in Jonas' Tabelle). Pfeiler 2 bleibt im Gate ehrlich ungeprüft.

## 7. Meine Zusagen: was ich heute tue, was offen ist

Die folgenden Schritte sind **geplant, noch nicht ausgeführt und ohne Beleg**. Nach Ausführung trage ich Datum und Beleg im Daily 19.11. ein.

### Zielrechner (zugesagt 16.11., unbestätigt)
- **Stand:** Kein Bericht bestätigt ihn. Daniel (Tag 1): Daten fehlen. Daniels Messprotokoll: „nicht bestätigt“. Sophie (Tag 3): keine GPU. Zuständigkeit war unscharf: `plan/felix.md` fordert den Rechner von Daniel bis 13.11., `ergebnis.md` von mir am 16.11. Ich übernehme ausdrücklich.
- **Anforderung präzisiert:** Ein dedizierter Rechner, GTX-1660-Klasse, 6 Kerne, 16 GB, saubere Installation, Godot 4.4.1 plus Export-Templates, Energieprofil Höchstleistung. „6 Kerne“ allein macht die Messung nicht vergleichbar: das CPU-Modell wird festgelegt (Klasse der GTX-1660-Zeit, z. B. Ryzen 5 3600 oder Core i5-9400F, nur Orientierung, kein Beschluss) und im Messprotokoll eingetragen. F-05 ist headless und hängt an der CPU, S-03 an der GPU. Beides auf einem Rechner.
- **Heute:** (1) Im Daily fragen, welche Rechner im Team oder privat passen (bis 12:00). (2) Falls keiner: Leih-, Miet- und Gebrauchtangebot einholen, Kosten gegen den Budgetrahmen. Die Budget- und Burn-Rate-Rechnung ist heute fällig, ihr Stand ist nicht belegt. (3) Entscheidung wer, wo, ab wann: 19.11., 12:00. (4) Zugang für Daniel und Sophie, Ready-Check mit Daniel am 20.11., 18:00.
- **Trigger:** Kein bestätigter Rechner am 19.11., 18:00: Jonas wird im Daily 20.11. informiert, G2 wird als „vertagt“ geplant. Messungen auf anderer Hardware sind „Schranke, zählt nicht“.
- **Offen:** Quelle, Kosten, CPU-Modell, Export-Templates, Fernzugriff.

### Rekrutierung Tester
- **Bedarf, zusammengerechnet:** L-06: 6 + 2 Reserve extern (3 Veteranen mit ≥ 20 h im Genre, 3 Einsteiger, nicht aus der Spielebranche) plus 1 Pilot am 24.11. (zählt nicht), Testtag 25.11., sechs 45-min-Slots. L-05: 3 Nicht-Designer, extern bevorzugt (Lena, Daniel: Kollegen kennen das Konzept). S-03: 6 Kollegen ohne Art-Beteiligung plus 4 Reviewer für das Video, intern. S-05: 1–2 Personen mit Rot-Grün-Schwäche. Extern gesamt ca. 12–14 Personen in 5 Arbeitstagen.
- **Heute:** (1) Screening aus Aylins Skript (S1 bis S3) um Verfügbarkeit 24./25.11. und eine freiwillige Frage zur Farbsehschwäche erweitern. Die Angabe ist Gesundheitsdatum: nur mit ausdrücklicher Einwilligung, im Protokoll nur „ja/nein“, ohne Namen. (2) Kanäle: Studio-Umfeld für Einsteiger, Genre-Communities (Foren, Discord) für Veteranen. Aufwandsentschädigung: Betrag steht nicht fest, hängt am Budget. (3) Einwilligungstext bis 19.11. (4) S-03: Block Do 19.11., 16:00–17:00, sechs Kollegen je 10 min, davon vier als Reviewer. Teilnehmer werden bestimmt, nicht bestätigt. (5) Aylin kann Screening- und Einwilligungstext gegenlesen (sie hat laut Kapazität freie Zeit).
- **Termine:** 19.11. Einladungen raus, L-05-Tester 18:00, 20.11. L-06-Tester 6 + 2 bestätigt. L-05-Runden realistisch ab 23.11., weil E1 und der Druck davor liegen. Wenn es nicht zu schaffen ist, sagt Lena das im Daily 20.11. und nicht erst am 23.11.
- **Los:** Zuordnung zu T1 bis T6 per Los, ich halte die Liste (Daniels Vorschlag).
- **Offen:** Es gibt keine Kandidatenliste, die Kanäle sind ungeprüft, Reserve-Quote ist Daniels Vorschlag, den ich bestätige (6 + 2). Weniger als 6 bestätigt am 20.11.: Testtag auf 26.11., Auswertung 27.11. früh, PO informieren. Interne Tester zählen nicht als Veteranen.
- **Farbsehschwäche:** Ich frage heute alle im Team freiwillig. Wer sich meldet, entscheidet selbst, ob er mitmacht. Ergänzend im Screening. Termin: 15 min mit Sophies Palette nach Abschluss von S-05 (ca. 20.11.), spätestens 25.11.

### Interviews Gameplay-Programmierung (bis 20.11. terminieren)
- **Lesart:** „Terminieren bis 20.11.“ heißt: Termine stehen, nicht: Interviews gelaufen. Der Prozess läuft laut meinem Plan bis 18.12. (Interviews und Probeaufgaben), Zusagen bis 08.01.
- **Stand:** Ausschreibung sollte laut Plan am 11.11. online sein (`plan/felix.md` nennt 06.11.). Aus den Sprintdateien ist weder der Online-Stand noch eine Bewerberzahl ablesbar. Ich trage keinen Stand ein, den ich nicht belegen kann.
- **Heute:** (1) Bewerbereingang sichten, Zahl und Shortlist festhalten. (2) Felix' Zeitfenster abstimmen: 0,5 T im Sprint, Fragestunde 14–15 bleibt geschützt, 25.11. Standby für den Playtest. Vorschlag: 26.11. nachmittags und 30.11. bis 04.12. (3) Probeaufgabe mit Felix finalisieren (Godot 4, GDScript). (4) Freelancer-Brücke ab 11.01. anstoßen.
- **Konflikt K9:** Lenas „Start spätestens 30.11.2026“ ist nicht erreichbar, und wir führen die 3-monatige Kündigungsfrist selbst als hohes Risiko. Planungsbasis bleibt 01.02.2027 (spätestens 01.03.) mit Freelancer ab 11.01. Felix' 04.01. ist nur mit einem Kandidaten ohne Kündigungsfrist machbar. Lena plant das Grey-Box-Onboarding (08.01.) mit Felix oder der Brücke, nicht mit der Neueinstellung. Entscheidung Jonas.
- **Zusätzlich offen:** 3D-Artist-Freigabe (Jonas, 20.11.), Freelancer-3D-Vertrag (30.11.).

## 8. Aktionen bis zum Daily Do 19.11.

| Wer | Aktion |
|---|---|
| Katrin | Zielrechner-Entscheid, Rekrutierung starten, Einwilligungstext, Pairing 10:00 buchen, Entscheidungsrunde 10:30 buchen, S-03-Block 16:00 buchen, Figma-Zugang klären, Nachfrist-Termin Mi 02.12. im Kalender sperren |
| Felix | Übergabe an Daniel, Pairing mit Aylin, F-06-Schätzung, Zusatzfelder, kanonischer Ort, G2-Definition bestätigen |
| Aylin | Pairing, Mapping-Tabelle, Zählregel F2 mit Lena und Daniel bestätigen |
| Lena | Fehlerliste final, Abgleich mit Tobias, L-05-Karten setzen (nach E1) |
| Tobias | Abgleich mit Lena, freie Kapazität anbieten (siehe `sprintziel_check.md`) |
| Daniel | Eingangsprüfung Spike (0,5 T), D4-S1, Farbcheck mit `palette_v1.csv`, Fehlalarm-Test auf 20.11. legen, die 3 darstellbaren D-04-Szenarien festlegen |
| Sophie | S-06a Stand melden, GPU-Lauf einplanen sobald Rechner da, Ghost-Farbe mit Aylin |
| Jonas | E1 bis E7, Schwellen G1 bis G8 bestätigen lassen |
