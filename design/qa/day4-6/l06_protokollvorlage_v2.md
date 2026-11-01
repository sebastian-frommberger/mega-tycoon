# L-06 Protokollvorlage v2 (angepasst an D2, D7, D11, K6/K7) – Diagnose-Playtest 25.11.2026

Daniel Richter, QA · Stand 20.11.2026 · ersetzt `day1-3/daniel/l06_protokollvorlage.md` (v1). **Test nicht durchgeführt, keine Tester-Daten, kein Pilot.** Nur die Änderungen gegenüber v1 sind hier ausformuliert; Rollen, Stoppuhr-Regel, Reihenfolge-Tabelle (Aylins 6 Permutationen), Zeitplan und Störregeln gelten unverändert aus v1.

## 1. Messgröße und Gate-Lesart (D2)

Wörtlich, unverändert: **≥ 4 von 6 Testern finden die Wurzelursache von mind. 2 der 3 Fehler in < 60 s nach Klick auf die Meldung.**
Gate G1 heißt jetzt **„Kette in 3 bekannten Fällen lesbar“** (nicht „Diagnose trägt“, nicht „USP belegt“, auch nicht bei 6/6). Grün ≥ 4/6 · Gelb 3/6 · Rot ≤ 2/6 · **< 6 gültige Tester = offen, nicht Rot** · **Plan B (Fake-Feed/Saves) = Deckel Gelb, auch bei 6/6** (D7, ersetzt v1 „Rot bei keinem echten Build“).

**Berichtssatz (Pflicht, D2):** Der Bericht nennt Ergebnis, Wilson-Intervall und Deckeneffekt **in einem Satz**, Muster: „x von 6 Testern bestanden (Wilson 95 %: a–b %); die Kette endet in der Wurzelursache, ein Bestehen belegt Lesbarkeit der Kette in diesen drei Fällen, nicht Diagnose in echten Netzen.“ Wilson-Intervalle für n = 6 (vorab gerechnet, keine Messung): 2/6 → 10–70 %, 3/6 → 19–81 %, 4/6 → 30–90 %, 5/6 → 44–97 %, 6/6 → 61–100 %.

## 2. Pflicht-Nebenmessungen (D2) – je Tester × Fehler, aus Aylins CSV-Kopf

| Nebenmessung | Definition (Zählregel) | Quelle | Auswertung |
|---|---|---|---|
| **Zeilenklicks** `zeilenklicks` | Zahl der Klicks auf Kettenzeilen zwischen `t_klick` und `t_nennung` (bzw. bis Abbruch). Klick auf Meldungskopf oder „Zurück“ zählt nicht | UI-Klick-Log (Felix, F-06: `t_klick_ms`, Zeilen-IDs); ohne Log: Beobachter 1 zählt, Beobachter 2 kontrolliert am Video | Median und Spanne je Fehler; Anteil Tester mit 0 Zeilenklicks |
| **Nur-letzte-Zeile-Leser** `nur_letzte_zeile` (ja/nein) | **ja**, wenn die erste festgelegte Aussage inhaltlich die letzte Kettenzeile wiedergibt (Wortlaut oder Sinn) **und** der Tester vorher keine andere Zeile angeklickt hat (`zeilenklicks` auf andere Zeilen = 0) **und** `dauer_s` < 20 s. Alle drei Bedingungen; sonst nein. Beobachter notieren den Verdacht, Lena entscheidet am Video ohne Zeit | Beobachtungsbogen + Log + Video | Anteil je Fehler und gesamt. **Steht im Berichtssatz**, wenn > 50 % der Treffer so entstehen („fast nur Letzte-Zeile-Leser“, Lena) |
| **Median-Zeit** | Median von `dauer_s` über alle Treffer (`bewertung = WURZEL`), zusätzlich je Fehler und je Gruppe (Veteran/Einsteiger). Kein Mittelwert | CSV | Mit Spanne (min–max) berichten |
| Zeit bis Klick (aus v1) | Aufgabenende → Klick auf Meldung | Bogen | Auffindbarkeit, nicht Teil der Messgröße |
| Fehlklicks (aus v1, Aylins Definition) | Klicks nach `t_klick`, die weder Kettenzeile, Meldungskopf noch „Zurück“ sind | Log | an Aylin |

Die 20-s-Grenze in „Nur-letzte-Zeile-Leser“ ist **meine Setzung** (Aylin: „wer die letzte Zeile liest, hat sie in unter 30 s“), Lena/Aylin bestätigen oder ändern sie vor dem Pilot.

## 3. Titel, Vorschlag, Zählregel (D11, K7)

- **Alle drei Meldungstitel sind `T_STEHT`** („{zug} steht seit {dauer}“), auch beim Kreis. Der Produkttitel („Zug 5, 8 und 6 blockieren sich gegenseitig“) ist in Aylins Textvorlagen dokumentiert und **nicht im Test**. Smoke-Prüfpunkt 24.11.: alle drei Titel im Build nach `T_STEHT`.
- **Vorschlag im Test ausgeblendet** (Panel ohne „Ausweichgleis bauen“ / „Lkw hinzufügen“). Fragebogen-Frage F6 entfällt, Nachfrage N3 „Was würdest du als Erstes tun?“ bleibt, **ungezählt** (D2: „Was würdest du bauen?“, nur Notiz an Aylin/Jonas). Smoke-Prüfpunkt: Vorschlag nicht sichtbar.
- **Zählregel F2 (Lena, K7): bestätigt.** Für den Kreis muss der **Schluss des Kreises** benannt werden („im Kreis“, „gegenseitig“, „aufeinander“, „keiner kann zuerst“). Zwei Glieder allein („5 wartet auf 8, 8 auf 6“) = `SYMPTOM`. Vorlesen aller Zeilen ohne den Schluss = `SYMPTOM`. Ich übernehme Lenas Tabelle (`lena/playtest_szenario.md`, Abschnitt 2) wörtlich in den Bogen.
- **Quellenzeile aus v1 gestrichen (K6):** gültig ist allein Lenas Fehlerliste F1–F3 (deckungsgleich mit F-04 S1–S3). Die alten 5-Fehler-Listen aus `plan/` gelten nicht.
- Ursache-Codes im Protokoll nach D9: Felix' Enum (`EINGLEISIG_GEGENVERKEHR`, `DEADLOCK`, `WARTEN_AUF_LADUNG`); Aylins Textschlüssel nur in der UI.

## 4. Beobachtungsbogen – geänderte und neue Felder (Fehlerblock)

| Feld | neu/geändert |
|---|---|
| Titel im Build = `T_STEHT`, Vorschlag ausgeblendet (vor Sitzung geprüft) | neu, ja/nein |
| Zeilenklicks (Zahl, Zeilen-IDs in Reihenfolge) | neu |
| Erste Aussage = letzte Kettenzeile? (ja/nein/unklar) | neu |
| Verdacht Nur-letzte-Zeile-Leser (ja/nein) | neu, Entscheidung Lena am Video |
| `dauer_s` | wie v1 (Stoppzeit ab Klick) |
| Antwort auf N3 „Was würdest du als Erstes tun?“ | wie v1, ungezählt |

CSV-Kopf (Aylin, Single Source) wird um zwei Spalten ergänzt: `zeilen_ids_seq` (Klickfolge) und `nur_letzte_zeile` (ja/nein/unklar). Aylin bestätigt.

## 5. Auswertungstabelle (leer, nur mit echten Zeilen zu füllen)

| Kennzahl | Wert | Bemerkung |
|---|---|---|
| gültige Tester | _ / 6 | < 6 → G1 offen |
| Tester bestanden (≥ 2/3) | _ / 6 (Vet _/3, Einst _/3) | Ampel G1; Plan B → Deckel Gelb |
| Wilson 95 % für bestanden/6 | _ – _ % | vorab gerechnete Tabelle (Abschnitt 1) |
| Treffer je Fehler F1/F2/F3 | _ / _ / _ | |
| Median `dauer_s` (Treffer), gesamt / je Fehler / je Gruppe | _ s | mit Spanne |
| Zeilenklicks: Median je Fehler, Anteil 0 Klicks | _ | |
| Anteil Nur-letzte-Zeile-Leser (an Treffern) | _ % | in den Berichtssatz, wenn > 50 % |
| Fehlerklassen der Nichttreffer (Aylin) | | |
| B8-Vorfälle (Kette leer/Fehler nach Klick) | _ | neuer Prüfpunkt aus D-04, siehe `d04_protokoll.md` |

## 6. Smoke-Test 24.11. – Prüfpunkte ergänzt

Zu v1 (3/3 Fehler auslösbar, 0 Abstürze in 30 min, Kette endet bei Soll-Wurzel, Klick + Sprung zum Ort, Replay) kommen: Titel `T_STEHT` ×3, Vorschlag ausgeblendet, `kette[-1].pos == ursache.pos` (D9, am Übergabe-Stand 19.11. in D-04 erfüllt, 15/15), Zusatzfelder `fuell_ist/soll`, `n_lkw`, Streckenlänge, Gleiszahl in F1/F3 sichtbar, Klick-Log mit `t_klick_ms` und Zeilen-IDs, **Kettenabfrage in jedem Tick stabil (B8: Abbruch, wenn ein Kettenglied auf einen im selben Tick freigegebenen Block wartet; am Übergabe-Stand noch vorhanden, Replay `daniel_b8_replay.gd`)**.

## 7. Offen
- **Lena, Aylin:** 20-s-Regel und Drei-Bedingungen-Definition für Nur-letzte-Zeile-Leser; CSV-Spalten `zeilen_ids_seq`, `nur_letzte_zeile`.
- **Felix:** Klick-Log mit Zeilen-IDs (sonst Zählung nur per Video), B8-Fix vor dem Freeze (laut Felix jetzt 24.11., 12:00 statt 10:00). Zeilenzahl: Felix liefert die Rohkette (3 Glieder je wartendem Fahrzeug); „Zeilenklick“ bezieht sich auf die **UI-Zeile** nach Aylins Zusammenfassung, nicht auf Rohglieder.
- **Katrin:** 6 + 2 Tester, Zielrechner, OBS; Stand 20.11. unbekannt (keine Datei in `day4-6/`).
