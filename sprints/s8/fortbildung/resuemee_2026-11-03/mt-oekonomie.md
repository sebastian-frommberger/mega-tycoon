# Tobias (Ökonomie und Balancing): Resümee (Stand 03.11.2026)

Pfade relativ zu `/home/claude/mega-tycoon/`. Marken: [Beleg] = Datei oder URL genannt, [Eindruck] = meine Wertung.

## 1. Wie ich Spiel und Konzept heute sehe
**Kern:** Ertrag = Einheiten × Preis × Distanz (Knick bei 60 Feldern, Mindestdistanz 6) × Zeitfaktor × Sättigung; Orte fragen nach, was Sim-EW × Stufe hergibt; Geld ist knapp, weil Kredit teuer ist und nach 10 Minuten unter dem Rahmen zwangsverkauft wird (`slice/data/economy_constants.json`, `slice/economy.gd`) [Beleg].

**Was trägt:** Auf der 8-Orte-Slice-Karte liegt die Bankrottquote bei 14,3 / 18,3 / 14,0 % (n = 300, T-15) bzw. 17,8 % (n = 2.700, KI 16–19 %) und damit im Band 10–30 % [Beleg: `sprints/s7/block-b/tobias.md`; `sprints/s8/design-sprint/phase4/tobias_welle1.md` §1]. Zug:Lkw liegt bei 2,9:1.

**Was noch Papier ist:** Schwierigkeitsstufen (Presets sind nur geschätzt), SK-01-Zahlen (Platzhalter), Zinsniveau (nie gegen Referenzen verglichen), alles ab Minute 60, die Wirtschaft der 1820-Welt. Der Bot (`slice/tests/d08_bankrott.gd`) spielt nur die Slice-Karte. [Eindruck] Ich habe ein gut geeichtes Modell für die falsche Karte.

## 2. Entwicklungsverlauf aus meiner Sicht
- **S3/S4:** T-11 Bankrott 7 % gegen Ziel 10–30 %; H-01 12 %; B-03 Mutationstest 280/280 [Beleg: S3/S4-Notizen].
- **S5:** T-12 Agrar ×1,88, T-13 Kredit-Balancing (Commits im Repo).
- **S6:** T-14/T-14b: Startkapital 6.000 $ für alle, Lok-Fix 300 → 90 $/min, Bankrott 10,7–15 %. Kohlberg erreicht M7 nach 33/24 min, also außerhalb des Bands, daraus die Werkzeugfabrik-Position (D24) [Beleg: `sprints/s6/block-a/tobias.md`, `block-b/tobias.md`]. **Wendepunkt:** Zocker-Tagebuch: Exploit E1 (Mittelfurt-Mehlkette, M7 in ca. 20 min), Kredit mit 1 %/min wirkungslos [Beleg: `sprints/s6/zocken/tagebuch_tobias.md`].
- **S7:** T-15/T-16 als Reparatur: Lizenzzuschlag 30 → 120 ‰, Kreditsperre bis Minute 12, Zins 1 → 3 %/min, Lok-Fix 90 → 170 $/min, Waggon 10 → 6 E. M7 im Modell 30,4 min (Messung 36,0 min) [Beleg: `sprints/s7/block-a/tobias.md`, `block-b/tobias.md`].
- **S8:** `tobias_welle1.md`: Auf der Weltkarte der Welle 1 liegen 59 % der Orte unter ca. 15 Nachfrage/min; Bankrott bei solchen Senken 27–35 %. Abhilfe Faktor 1,25/1,5 oder Mindestnachfrage 18/min; beides ungetestet.

## 3. Was gut lief (belegt)
- Zocker-Tagebuch als Messinstrument: Es fand E1 früher als jeder Test (`tagebuch_tobias.md`).
- Konfidenzintervalle statt Einzelzahlen: n = 300 bzw. 2.700 mit Intervall, gepaarte Seeds (`block-b/tobias.md`, `tobias_welle1.md`).
- Mutationstest B-03 (280/280) und die Sättigungstabelle, die ich neu gerechnet habe: stimmt (1,0 bis 100 %, linear auf 0,4 bei 150 %, danach 0,1) [Beleg: `economy_constants.json`, `economy.gd` Z. 353].
- Ehrlicher Bot-Vorbehalt: Der Bot ist bei kleinen Senken pessimistisch, das steht im Bericht (`tobias_welle1.md`).

## 4. Was nicht gut lief, wiederkehrende Kompromisse
| Muster | Zähler | Beleg |
|---|---|---|
| Kalibrierung auf der alten Slice-Karte | 5 (T-14, T-14b, T-15, T-16, S8-Welle 1) | `tobias.md` S6/S7; `tobias_welle1.md` §2.1 |
| Parameter ohne Messung gesetzt (Platzhalter) | 3 (SK-01, G-01-Fragen, Presets) | `sk01_skilltree_v0.md`; `g01_progression.md` §6; `04_schwierigkeit.md` |
| Stichprobe zu klein (9, 100, 150 statt 300) | 3 | S6/S7-Tobias-Notizen; n = 100 gibt ±7 pp |
| Bot mit angepassten KALIB-Faktoren | 2 | `slice/tests/d08_bankrott.gd`, T-16 |
| Kreditregel geändert | 3 | T-13, T-15, `04_schwierigkeit.md` |
| Hebel Zug/Lkw verschoben | 3 (Lok 300 → 90 → 170, Waggon 10 → 6) | S6/S7 |
| Modell und Spiel driften | 4 (M7 33–36 gegen 20 min; T-15 30,4 gegen 36,0) | `tagebuch_tobias.md`, `block-a/tobias.md` |
[Eindruck] Das fünfte Mal Kalibrierung auf der Slice-Karte ist kein Zufall, sondern ein Prozessfehler: Der Bot kennt die Welt nicht, für die er die Zahlen liefern soll. Die Retro-Aktion „Tests auf der echten Karte“ steht seit `sprints/s7/review_retro.md` offen.

## 5. Wo das Spiel scheitern könnte (nach Wahrscheinlichkeit)
1. **Hoch: Kalibrierung gilt nicht für die Weltkarte.** 59 % kleine Senken, Bankrott 27–35 % statt 15–18 % (Normal). [Beleg: `tobias_welle1.md`]
2. **Mittel-hoch: Kredit zu hart.** 3 % je Spielmonat ≈ 36 % p.a. (siehe 7.3). Gewollter Druck, aber 12–36-fach über den Referenzen; die Messung sagt nur, dass der Bot dran scheitert, nicht ob Menschen es wollen. [Eindruck]
3. **Mittel: Sättigung springt bei 150 %** (0,4 → 0,1), nirgends als gewollt dokumentiert.
4. **Mittel: Zug bleibt dominant.** Zug:Lkw 2,9:1 stabil, im Anfangsfenster 4,9:1 [Beleg: `block-b/tobias.md`]. Skillpunkte und Epochen können das verschieben.
5. **Mittel: Presets Leicht/Schwer sind Schätzungen.** Bankrottziele Leicht ≤ 5 %, Schwer 30–40 % nicht gemessen.
6. **Niedrig: Wirtschaftsjahr und Laufzeit.** 206 Jahre × 12 min ≈ 41 h; Kassenkurve über so lange Partien ist nicht modelliert.

## 6. Meine drei wichtigsten Empfehlungen für Sprint 8
1. **Bot auf Generator-Welt (ca. 3 PT: Tobias 2, Felix 1).** Bankrott-Test mit 15–21 Orten aus dem Welle-1-Generator, Mindestnachfrage 18/min oder ×1,25/×1,5 als Variante, n = 300 je Variante, in die Regressionstests. Kriterium: Normal 15–18 %.
2. **Presets und Zins prüfen (ca. 2 PT).** Leicht/Normal/Schwer in 500-$-Schritten messen (je n ≥ 300) und den Zins gegen die Referenzen in Jahreswerten ansehen; Basti entscheidet am Ergebnis, nicht am Gefühl.
3. **Skillpunkt-Quote und Sättigungskurve (ca. 2 PT: Tobias 1,5, Lena 0,5).** Punkte je Meilenstein und G-01-Etappe festlegen (Quelle ist entschieden, Zahlen fehlen) und die Kante bei 150 % entweder glätten oder ausdrücklich als Regel notieren.

## 7. Recherchen dieser Runde und Lernlog
**7.1 Auszahlungsformel (Referenz OpenTTD).** Quelle: OpenTTD-Quellcode `economy.cpp` (Github OpenTTD/OpenTTD). `MIN_TIME_FACTOR` 31, `MAX_TIME_FACTOR` 255, `time_factor = max(255 − periods_over_1 − periods_over_2, 31)`, Ertrag `BigMulS(dist × time_factor × num_pieces, current_payment, 21)`. Ergebnis: Form meiner Formel stimmt; OpenTTD-Minimum 31/255 ≈ 12 % gegen unseren f_zeit-Minimum 0,3. Konfidenz hoch (Primärquelle), Abweichung ist Absicht, nicht Fehler.

**7.2 Bankrottregel.** Quelle: `economy.cpp` `CompanyCheckBankrupt` und `company_cmd.cpp`. Zähler steigt, wenn `money − loan < −max_loan`; Monat 4 Warnung, Monat 7 Übernahmeangebot, ab Monat 10 für die menschliche Einzelspieler-Firma nur Hinweis (sie spielt weiter), sonst Löschung. Ergebnis: Unser Zwangsverkauf nach 10 Spielmonaten entspricht strukturell Monat 10; die Warnung bei 90 s weicht von Monat 4 ab. Konfidenz mittel-hoch (Primärquelle, eine). Der Abruf `tt-wiki.net/wiki/Bankruptcy` wurde vom System blockiert, nicht umgangen.

**7.3 Zins im Vergleich.** Eigene Rechnung: 30 ‰ je Periode, 12 Perioden je Jahr ergibt ≈ 36 % p.a. (ohne Zinseszins 36 %). Skill nennt 2–4 % p.a. (OpenTTD, S14) und ca. 1 % (TF2, S9) ohne Einheitenvergleich. Gegenüber ROI ≈ 10 %/min etwa 2–5-fach schwerer. Konfidenz mittel (Rechnung belegt, Referenzzahlen aus dem Skill nicht neu geprüft).

**7.4 Holzkohle-Ausbeute (Skill A8, [S] 6,75 Zentner/Rm).** Quellen: [Albiez 1976, Bergbaumuseum](https://www.bergbaumuseum.de/) (PDF „Köhler im Schwarzwald“, anschnitt 3/1976): ca. 5 Zentner Holz auf ca. 1 Zentner Kohle; Münstertal 50 Rm geben ca. 5 t (0,1 t je Rm). [DBU AZ 00683](https://opac.dbu.de/ab/DBU-Abschlussbericht-AZ-00683.pdf): 2.500 t Einsatz, 500 t Kohle je Jahr (≈ 20 %, meine Division). Ergebnis: ca. 20 % nach Masse, ca. 100 kg je Raummeter; 6,75 Zentner (ca. 340 kg) je Rm ist unplausibel. Hypothese niedrig: Teichers Wert gilt je Klafter. Mahlleistung der Mühle nicht recherchiert. Konfidenz mittel (zwei Quellen, Einheiten uneinheitlich).

**Hinweis:** Zusammenfassungen kamen über ein kleines Modell, nicht wörtlich geprüft. Nicht erreichbar oder nicht nutzbar: tt-wiki.net (blockiert), tt-forums (Anubis), Reddit (gesperrt, nicht umgangen).

| Datum | Situation | Kompromiss / Lücke | Zähler |
|---|---|---|---|
| 2026-11-03 | Kalibrierung | Slice-Karte statt Zielkarte | 5 |
| 2026-11-03 | Parameter | Platzhalter ohne Messung | 3 |
| 2026-11-03 | Stichprobe | n zu klein | 3 |
| 2026-11-03 | Skill gegen Repo | Skillpunkt-Quelle entschieden (S7), Skill sagt „offen“ | 1 |
| 2026-11-03 | Zins | Einheiten nie verglichen, jetzt ≈ 36 % p.a. | 1 |
| 2026-11-03 | Holzkohle | [S]-Wert widerlegt (ca. 20 % Masse) | 1 |

## 8. Vorschläge für Skill-Änderungen (nur Vorschläge)
- A2: „Formel verifiziert gegen `economy.cpp`; OpenTTD-Zeitfaktor-Minimum 31/255“ [Beleg: GitHub OpenTTD].
- A4: Bankrottregel Monat 4/7/10 aufnehmen; Zins immer in %/Jahr und %/Spielmonat nennen, mit Vergleich 36 % p.a. gegen 2–4 %.
- A8: Holzkohle „≈ 20 % Masse, ca. 100 kg je Raummeter“ statt 6,75 Zentner/Rm [Beleg: Albiez 1976, DBU AZ 00683]; [S] streichen.
- B11: „Skillpunkt-Entscheid existiert: Meilensteine und Etappen, keine Transport-XP“ [Beleg: `sprints/s7/refinement/ergebnis.md`].
- A9 neuer Fehler: „Bot auf anderer Karte kalibriert als Zielkarte“ mit Zähler 5.
- Lernroutine: Bei Zählerstand 3 eines Musters Prozessänderung statt weiterer Kalibrierung auslösen.
