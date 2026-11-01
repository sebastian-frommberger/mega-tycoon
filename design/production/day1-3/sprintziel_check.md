# Sprintziel-Check, Stand Mi 18.11.2026 (Tag 3 von 10)

Katrin Vogel · Grundlage: die sieben Tag-1–3-Übersichten, `refinement/ergebnis.md`, `jonas/gate_kriterien.md`. **(K)** = meine Schätzung, nicht von den Personen gemeldet. Keine Wahrscheinlichkeiten und keine Messwerte erfunden; wo ich Spielraum in Tagen nenne, ist er aus dem Kalender gerechnet.

## Kurzfassung

Das Sprintziel verlangt drei Ergebnisse, die am 26.11. **vorliegen**: Playtest-Auswertung, Benchmark-Entscheidung, Lizenz/Kauf-Leiter. Heute ist keines davon gemessen. Alle drei können am 26.11. als Dokument vorliegen, aber nur unter Bedingungen, die heute nicht gesichert sind. Als „alle Gate-Kriterien grün“ ist das Ziel nicht erreichbar. Mein Vorschlag: Gate-Termin und Ziel halten, Scope jetzt kürzen, fünf Entscheidungen morgen treffen, zwei feste Entscheidungspunkte (20.11., 24.11. 12:00) mit vorab vereinbarter Folge, und einen Nachfrist-Termin am 02.12. reservieren.

## 1. Zahlen

**Kalender.** 10 Arbeitstage (16.–27.11.), 3 vorbei. Bis zum Sprintziel (26.11.) bleiben 6 Arbeitstage: 19., 20., 23., 24., 25., 26.11. Der 27.11. ist Gate-Tag.

**Gemessen am Zielobjekt (Stand heute):**

| Messung | Soll | Heute |
|---|---|---|
| L-06 Tester | 6 (+2 Reserve) | 0, Rekrutierung nicht belegt |
| F-05 Benchmark-Läufe | 18 (6 Konfigurationen × 3) | 0, keine Szene, kein Zielrechner |
| D-04 zählende Läufe | 9 manuell (+3 aus F-04) | 0 (Vorabläufe zählen nicht) |
| L-05 Runden | 3 | 0, Material nicht gedruckt |
| S-03 Personen | 6 Kollegen, 4 Reviewer | 0, Frame-Zeit auf GPU nicht gemessen |
| S-05 Betroffene | 1–2 | 0 |

Vorhanden: Spike-Code mit eigenen Tests (Voraussetzung, kein Messwert), Rechnungen (T-04, T-05), Entwürfe (Szenario, Skript, Protokolle), Prüfpläne (F-05, D-04, Farbcheck).

**Kapazität.** Plan laut `ergebnis.md`: 8 Personen × 8 T = 64 T, davon 51,75 T verplant und 12,25 T Puffer. Berichteter Fortschritt (K): ca. 18,5 T geleistet (36 % bei 30 % Zeit), überwiegend Vorbereitung. Bis 26.11. stehen je Person 6 Arbeitstage zur Verfügung, bei der Planungsregel 80 % sind das 4,8 T.

| Person | Rest Plan-Arbeit bis 26.11. (K) | verfügbar (6 AT × 0,8) | Saldo | Herleitung und Anmerkung |
|---|---|---|---|---|
| Felix | 3,5 | 4,8 | +1,3 | F-04 0,5 · F-05 1 · F-06 1 · Reviews 0,25 · Poker 0,25 · Interviews 0,5. **Ungeschätzte Zusatzforderungen** an F-06, F-05, D-04 sind darin nicht enthalten, der Saldo ist faktisch ≤ 0. |
| Lena | 4,75 | 4,8 | +0,05 | L-06 2,0 · L-05 1,75 · Plan-B-Saves 0,5 · Gate-Input 0,5. Voll ausgelastet, die 24-Punkte-Widerspruchsliste war nicht eingeplant. |
| Tobias | 2,75 | 4,8 | +2,05 | F-09 1,5 · Economy-Vorlage 0,5 · L-05-Support 0,5 · Abgleich 0,25 (Summe 2,75). **Freie Kapazität.** |
| Aylin | 3,0 | 4,8 | +1,8 | A-05 0,75 · L-06 1,25 · A-06 0,5 · UX-Vorlage 0,5. Plan-B-Fake-Feed ginge auf den Saldo. |
| Daniel | 5,2 | 4,8 | **−0,4** | D-04 2,0 · F-05 1,0 · L-06 1,5 · Farbcheck 0,2 · Gate-Bewertung 0,5. Am 23.11. liegen F-05-Messung und D-04-Auswertung auf demselben Tag, am 25.11. der ganze Testtag. |
| Sophie | 3,5 | 4,8 | +1,3 | S-03 1,0 · S-05 0,5 · S-06a 1,0 (nicht berichtet) · S-06b 1,0 (Kanban). |
| Katrin | 5,4 | 4,8 | **−0,6** | K-07 1,5 · L-06 1,0 · Zielrechner/Ausschreibungen 1,5 · SM 1,4. Budget, Einwilligung, Rekrutierung L-05 und S-03 sind nicht eingeplant. |
| Jonas | 5,15 | 4,8 | **−0,35** | J-05 2,5 · F-08 0,25 · PO 1,4 · Beobachtung 0,5 · Gate 0,5. Dazu die Entscheidungen aus `daily_tag3.md`. |
| **Summe** | **33,25** | **38,4** | **+5,15** | Gesamt knapp im Plan, aber falsch verteilt: Daniel, Katrin, Jonas sind über, Tobias, Aylin, Sophie, Felix (auf dem Papier) haben Luft. |

Lesehilfe: Die Tabelle zeigt die Verteilung, nicht Genauigkeit. Die Rest-Werte sind Schätzungen.

## 2. Kritische Pfade

**Pfad 1: Playtest-Auswertung (Sprintziel Teil 1).** F-04-Übergabe 19.11. → Feldvertrag und Mapping 19.11. → Plan-A/B-Entscheidung 20.11. → F-06 23.–24.11., Build 24.11. 10 Uhr → Smoke-Test und Pilot 24.11. → Testtag 25.11. (sechs Slots) → Auswertung 26.11. **Puffer vor dem Testtag: 0 Tage.** Wandert der Build um mehr als einen halben Tag, rutscht der Testtag auf den 26.11. und die Auswertung auf den Gate-Tag. Für einen Nachtest ist kein Platz. Zusatz: F-06 trägt jetzt mehr als beschlossen und ist nicht neu geschätzt.

**Pfad 2: Benchmark-Entscheidung (Teil 2).** Szene 20.11. → Zielrechner einsatzbereit 20.11., 18:00 → Messung 23.11. → F-08 am 24.11. → Entscheidung 25.11. **Puffer: 1 bis 2 Tage**, aber nur mit Zielrechner. Rutscht F-04, wird F-05 laut Beschluss auf den 10k-Lauf gekürzt. Dann gibt es nur Grün (Median ≤ 4 ms bei 10k) oder „nicht entscheidbar“, weil Gelb die 5k-Messung braucht. Ein Rot ohne tragfähigen Alternativplan mit Kostenrahmen ist laut Jonas No-Go. **Kein Sprint-Ticket bereitet diesen Alternativplan vor**, ein Rot würde also auch durch eine Planungslücke zum No-Go.

**Pfad 3: Lizenz/Kauf-Leiter (Teil 3).** E1 am 19.11. → L-05-Material (0,75 T) → 3 externe Tester → Runden 23.–24.11. → Auswertung 25.11. **Puffer: 1 Tag.** Hängt an Lenas voller Auslastung und an einer Rekrutierung, die nicht begonnen ist.

Alle drei Pfade konkurrieren um Daniel (23.–25.11.), Lena, Aylin und mich.

## 3. Einschätzung je Ergebnis am 26.11.

| Ergebnis | Liegt am 26.11. vor? | Bedingung | Was es dann belegt | Was nicht |
|---|---|---|---|---|
| Playtest-Auswertung | Ja, wenn F-04-Übergabe 19.11., Build 24.11. 10 Uhr und 6 externe Tester bestätigt (20.11.). Sonst Plan B (Entscheid 20.11.), dann höchstens Gelb. | F-06-Umfang geschätzt, Fehler 3 lösbar (Zusatzfelder), Raum, Rechner, OBS | Die Kette ist in 3 bekannten Fällen für 6 Personen lesbar | Dass die Diagnose in echten Netzen trägt (Deckeneffekt, n = 6, Münzwurf im mittleren Bereich) |
| Benchmark-Entscheidung | Ja, wenn Zielrechner bis 20.11. und Felix' Szene am 20.11. mit Prüfsumme und Pacing. Sonst „vertagt“. | Release-Export oder „obere Schranke“, Definition pro Tick | Median und p95 des Sim-Kerns auf definierter Hardware für das Layout der Szene | Verhalten bei Repath, Pfadsignalen, Render-ms (nach S3 geschoben) |
| Lizenz/Kauf-Leiter | Als Rechnung ja. Als „konsistent und in L-05 bestätigt“ nur mit E1, 3 Runden und Auswertung. | PO-Entscheid, Material, Tester | Die Preisregeln sind in sich schlüssig (per Konstruktion) | Dass Spieler den Kauf wollen, dass kleines Kapital sich casual anfühlt |

## 4. Gate-Prognose nach Jonas' Regeln

| Kriterium | Realistischer Bestwert | Anmerkung |
|---|---|---|
| G1 Diagnose | Grün oder Gelb, mit Plan B höchstens Gelb | Aussage „lesbar in 3 Fällen“ |
| G2 Sim-Kern | offen, Grün möglich | hängt am Zielrechner |
| G3 Deadlock | wie beschlossen nicht erreichbar, nach Umdefinition (E3) Grün möglich | Schwelle 50 Ticks unterscheidet nichts |
| G4 Ursache | Grün möglich, aber ohne Varianz | Wiederholungen statt Seeds |
| G5 Leiter | Gelb wahrscheinlich, Grün nur bei 4/4, L-05 erfüllt, DR bestätigt | L-05-Kriterium Kapital trennt nicht |
| G6 Kartengröße | Gelb wahrscheinlich | S-03-Grenze nur teilweise belegt |
| G7 Look-Test | Gelb oder Rot wahrscheinlich | zwei von drei Teilkriterien ohne Messung, Frame-Zeit braucht GPU |
| G8 Bau-Gefühl | „nicht nachgewiesen“ | F-07 nicht erreichbar |
| G9 VS-Backlog | offen | Poker nicht terminiert, S-06a nicht berichtet |

Folge: Nach der Regel „Go: höchstens 2 Gelb“ ist ein Go auf dem realistischen Pfad knapp. Die Regel muss vor dem 27.11. geklärt sein (E6), sonst wird sie im Gate verhandelt.

## 5. Optionen

| Option | Inhalt | Bewertung |
|---|---|---|
| **A: Ziel und Gate-Termin halten, Scope jetzt kürzen** | Siehe Abschnitt 6 | **Empfohlen.** Ziel bleibt erreichbar (als Dokument mit ehrlicher Belegstufe), Kürzungen kosten kein Gate-Kriterium, das heute erreichbar wäre. |
| B: Gate sofort auf den 02.12. verschieben | Alle Pfade bekämen 3–4 Tage Puffer | Nicht jetzt. M1 startet am 30.11., die 3D-Freelancer ab 30.11. Ein Gate nach dem M1-Start macht „Go“ zur Formsache, und wir verlören den Druck, die Zielrechner- und Rekrutierungslücke diese Woche zu schließen. |
| C: Gate halten, Playtest nur als Plan B | Niedrigster Aufwand | Nicht empfohlen. Endet bei Gelb, belegt nur die Oberfläche, und Plan B kostet trotzdem ca. 0,5 T bei Lena. |
| D (Rückfall, mit Auslöser): Gate verschieben, wenn Auslöser eintritt | Siehe unten | **Als Option vorbereiten, nicht ausrufen.** |

**Auslöser für D (vorab vereinbart):**
- **Daily 20.11.:** Sind mindestens zwei von drei Punkten offen (Zielrechner nicht bestätigt, weniger als 6 Tester bestätigt, F-04-Übergabe oder Feldvertrag fehlt), beantrage ich beim PO die Verschiebung auf Mi 02.12. (Slot wird heute im Kalender gesperrt).
- **Di 24.11., 12:00:** Liegt der Build mit Hash und bestandenem Smoke-Test bis 12:00 nicht vor, geht der Testtag auf den 26.11., die Auswertung auf den 27.11. vormittags, und der PO entscheidet am 27.11. zwischen Go, No-Go und Vertagen auf den 02.12.
- „Vertagen“ ist laut Jonas' Regel ein zulässiges, benanntes Gate-Ergebnis. Wir verschieben nicht stillschweigend.

## 6. Was ich dem PO jetzt vorschlage

1. **Ziel und 27.11. halten**, mit den zwei Entscheidungspunkten und dem reservierten 02.12.
2. **Scope kürzen:**
   - F-07 Stretch streichen, G8 vorab „nicht nachgewiesen“ (E7).
   - D-04 auf darstellbare Szenarien reduzieren, G3 neu fassen (E3). Entlastet Daniel um ca. 0,5 T.
   - F-06 auf Aylins Muss-Liste plus die vier Build-Anforderungen von Lena begrenzen (Klick-Log, getrennte Teilnetze, Schnappschuss ≥ 120 s, Zusatzfelder). Soll und Kann fliegen. Felix schätzt das am 19.11.
   - Lenas 24 Widersprüche: nur die sieben gate-relevanten (Nr. 1, 4, 5, 7, 12, 21, 23) im Sprint, der Rest ins GDD-Backlog.
   - S-03: kein 2-Minuten-Video und kein Wiki-Feinschliff, nur GPU-Lauf und Kollegentest.
   - Ausbaupfad Stufe 1–4 (Lenas Bitte an Tobias) nicht in diesem Sprint.
3. **Fünf Entscheidungen morgen, 10:30:** Startkapital, Messgröße und G1-Lesart, D-04, Variante B, Kartengröße-Eingänge. Dazu Messwert-Regeln und Go-Regel (E6).
4. **Gate-Sprache:** Jedes Kriterium trägt eine Belegstufe (M gemessen, V Voraussetzung, R Rechnung, O offen). „Liegt vor“ heißt „liegt mit Ampel und Belegstufe vor“. G1 heißt „Kette in 3 Fällen lesbar“, nicht „Diagnose trägt“.
5. **Kapazität umverteilen:**
   - Tobias (+2,05 T) übernimmt die Protokollführung in den L-05-Runden (0,5 T), Satz und Druck der L-05-Karten mit Lena (0,25 T) und die Rekrutierung der 3 L-05-Tester über sein Netz (0,25 T).
   - Aylin (+1,8 T) schreibt Screening- und Einwilligungstext gegen, hält den Fake-Feed für Plan B bereit und baut Figma nach, sobald der Zugang da ist.
   - Daniel wird durch E3 entlastet. Katrin trägt OBS und Raum und holt die Planning-Poker-Vorbereitung vor. Jonas bekommt die Entscheidungen gebündelt in einer Runde.
6. **1-Seiten-Alternativplan für G2 Rot** (GDExtension, Kostenrahmen): Katrin 0,25 T, Felix 30 min am 20.11. Nur als Skelett, damit ein Rot kein No-Go aus Planungslücke wird. Der PO entscheidet, ob er diesen Aufwand will. Ich empfehle ja.
7. **Meine Verpflichtung:** Zielrechner, Testerlisten und Interview-Termine bekommen ein Datum, im Daily 19.11. und 20.11. stehen sie mit Beleg oder als Rot. Ich melde Rot selbst, bevor es jemand anderes tun muss.

## 7. Annahmen und Grenzen dieser Einschätzung

- Die Rest-Werte (K) setzen voraus, dass die Plan-Tage in `ergebnis.md` stimmen und berichteter Fortschritt linear angerechnet wird. Sie beantworten „wer ist über, wer hat Luft“, nicht „wie viel genau“.
- Ich habe nur Dateien gelesen und nichts ausgeführt. Daniels Nachlauf des F-04-Runners ist die einzige unabhängige Prüfung eines Beleges im Sprint.
- Tageseinträge von Lena und Tobias sind laut ihnen Arbeitsreihenfolge, keine Kalendertage. Aussagen wie „Datei lag am 17.11. nicht vor“ sind deshalb teilweise ein Artefakt paralleler Arbeit. Das Synchronisationsproblem bleibt trotzdem real.
- Ob die Studio-Ressourcen (Rechner, Budget für Aufwandsentschädigung, Bewerberlage) reichen, kenne ich aus den Dateien nicht. Das ist der größte blinde Fleck dieser Einschätzung und liegt bei mir.
