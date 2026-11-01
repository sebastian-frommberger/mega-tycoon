# L-06: Die drei Testfehler, final (19.11.2026)

Lena Hoffmann · Status: **final aus Design-Sicht, Gegenzeichnung Aylin/Daniel offen** · Ersetzt Abschnitt 2 von `day1-3/lena/playtest_szenario.md`. Rest dieser Datei (Messprotokoll, Plan B, Rechnung zu n = 6) gilt weiter.

**Eingangslage:** D2 (Messgröße wörtlich, G1 = „Kette in 3 bekannten Fällen lesbar“), D9 (ein Namensraum = Felix' Enum, Zusatzfelder, kanonischer Ort), D11 (Titel `T_STEHT`, Vorschlag ausgeblendet). **Annahme, markiert:** `day4-6/felix/spike/` ist am 19.11. byte-identisch mit `day1-3/felix/spike/` (diff leer), eine `day4-6/felix.md` gibt es nicht. Die Felder aus D9 (`fuell_ist/soll`, `n_lkw`, Streckenlänge, Gleiszahl in `params`, `ursache.pos == kette[-1].pos`) sind also **beschlossen, aber nicht geliefert**. Ich dokumentiere gegen den Beschluss und vermerke je Feld, was der Spike heute schon hat.

**Nichts hier ist gemessen.** Keine Tester, kein F-06-Build.

## 1. Übersicht

| | F1 | F2 | F3 |
|---|---|---|---|
| Name | Gegenverkehr eingleisig | Deadlock-Kreis | Warten auf Ladung |
| Spike-Szenario | S1 (A–B–C–D, Zug 1 A→D, Zug 2 D→A, 3 Kanten à 200 m) | S2 (Gleisquadrat, 4 Züge im Uhrzeigersinn) | S3 (Lager ohne Nachschub, Lkw 1 am Lager, Lkw 2 dahinter) |
| `ursache.code` (D9, Felix' Enum) | `EINGLEISIG_GEGENVERKEHR` | `DEADLOCK` | `WARTEN_AUF_LADUNG` |
| UI-Typ (Aylin, per Tabelle aus `code`) | INFRASTRUKTUR | INFRASTRUKTUR | LADUNG |
| **Testtitel (D11, `T_STEHT`)** | **Zug 4 steht seit 2:10 min** | **Zug 5 steht seit 1:40 min** | **Zug 10 steht seit 2:10 min** |
| Untertitel (`T_ORT`) | bei Strecke Mühlbach–Kornfeld | bei Kreuzung Südfeld | bei Hafen-Ost |
| Produkttitel (dokumentiert, **nicht im Test**) | „Zug 4 und Zug 2 blockieren sich auf Mühlbach–Kornfeld“ | „Zug 5, 8, 6 und 9 blockieren sich gegenseitig“ | „Zug 10 wartet, weil Hafen-Ost zu wenig Ware bekommt“ |
| Vorschlag | im Test ausgeblendet (D11), `suggestion_id` bleibt im Log | ausgeblendet | ausgeblendet |
| Kanonischer Ort (D9) | Block B–C (Abschnitt 13), `ursache.pos == kette[-1].pos` | Block, den der Halter des angeklickten Zuges hält (Abschnitt 32), `== kette[-1].pos` | Lagerknoten Hafen-Ost, `== kette[-1].pos` |
| Stillstand beim Start | ≥ 120 s, geskriptet (`seit_tick`), Schnappschuss | ≥ 120 s | ≥ 120 s |
| Zielzeit | < 60 s nach Klick (Messgrenze, keine eigene Erwartung) | < 60 s | < 60 s |

Zugnummern 4, 5, 10 bleiben verschieden (nichts vermischen). Felix' Spike nennt die Fahrzeuge „Zug 1/2“, „Zug 0–3“ und „Lkw 1/2“; die Umbenennung passiert im Szenarioaufbau von F-06 (Namenstabelle, Schlüssel `objekt_id`, Aylins Pairing-Frage 5).

## 2. Je Fehler: Wurzelursache, Kette, Felder, Zählregel

### F1 Gegenverkehr eingleisig

**Wurzelursache:** Die Strecke Mühlbach–Kornfeld hat nur ein Gleis, ein Gegenzug (Zug 2) hält den Abschnitt, ein Ausweichgleis fehlt. Der Spike klassifiziert genau das: Zyklus, in dem jedes Mitglied auf einen `single`-Block wartet, dessen `holder_fwd` entgegengesetzt ist (`classify_cycle`).

**Soll-Kette (4 Zeilen, letzte = Wurzel), Aylins Vorlagen:**
1. `T_STEHT` Zug 4 steht seit 2:10 min
2. `R_SIGNAL` Wartet am Signal 12: Abschnitt 13 ist besetzt
3. `R_HALTER_GEGEN` Zug 2 besetzt Abschnitt 13 und fährt entgegen
4. `W_EINGLEISIG` **Mühlbach–Kornfeld hat nur ein Gleis (14 Felder)**

Felix' Rohkette hat 6 Glieder (Fahrzeug, Signal, Block, Fahrzeug, Signal, Block); die UI verdichtet auf 4 Zeilen. Zeile 4 braucht die Streckenlänge und die Gleiszahl.

| Feld für die Wurzelzeile | D9 | Stand im Spike (19.11.) |
|---|---|---|
| Streckenlänge (`params.laenge_felder`) | Felix liefert in `params` | `edges[id].length` in mm vorhanden, Umrechnung in Felder fehlt (Annahme: 1 Feld = Kantenmaß der Karte, Felix legt fest) |
| Gleiszahl (`params.gleise`) | Felix liefert | `blocks[id].single` (bool) vorhanden, als Zahl 1/2 ausgeben |
| Kanonischer Ort | `ursache.pos == kette[-1].pos` | **nicht erfüllt:** `root_pos` ist je angefragtem Zug verschieden (Zug 1 → (500000,0), Zug 2 → (300000,0)), Katrins K2. Nach D9 gilt der Block, den der Halter des angeklickten Zuges hält, also für Zug 4 der Abschnitt 13. |

**Zählregel F1:** Pflichtelemente Eingleisigkeit **und** Gegenzug, oder „Ausweichgleis fehlt“. `WURZEL`: „Da ist nur ein Gleis und Zug 2 kommt entgegen“, „Es fehlt ein Ausweichgleis“. `SYMPTOM`: „Zug 4 wartet am Signal“, „Abschnitt ist besetzt“, „Zug 2 steht im Weg“. Grenzfall „Die Strecke ist zu eng“ zählt nicht, Wortlaut notieren.

### F2 Deadlock-Kreis

**Wurzelursache:** Vier Züge (5, 8, 6, 9) halten je einen Abschnitt des Gleisquadrats Südfeld und warten auf den nächsten. Keiner kann zuerst fahren. Der Spike erkennt den Zyklus (Mitglieder [0,1,2,3], Kette 12 Glieder) und klassifiziert `DEADLOCK`, weil nicht alle Mitglieder auf Gegenrichtung warten.

**Soll-Kette (6 Zeilen):**
1. `T_STEHT` Zug 5 steht seit 1:40 min
2. `R_WARTET_ZUG` Zug 5 wartet auf Zug 8, der Abschnitt 32 besetzt
3. `R_WARTET_ZUG` Zug 8 wartet auf Zug 6, der Abschnitt 33 besetzt
4. `R_WARTET_ZUG` Zug 6 wartet auf Zug 9, der Abschnitt 34 besetzt
5. `R_WARTET_ZUG` Zug 9 wartet auf Zug 5, der Abschnitt 31 besetzt
6. `W_KREIS` **Alle 4 warten aufeinander, keiner kann zuerst fahren**

`kette_kreis = true`, `kette_kreis_zurueck_zu = 1`. Aylins Vorlage hatte 3 Züge (Annahme bei ihr); es gelten 4, weil S2 vier baut. Nur `{n}` und die Zeilenzahl ändern sich, Zeichenlimit 60 bleibt eingehalten (längste Zeile 52 Zeichen, Aylins Prüfung; die neuen Zeilen 4 und 5 haben dieselbe Vorlage).

| Feld | D9 | Stand im Spike |
|---|---|---|
| Zyklusmitglieder | liefert (`cycle`) | vorhanden |
| Kanonischer Ort | `ursache.pos == kette[-1].pos` | `root_pos` = Block des Zyklus-Einstiegs, hängt vom angeklickten Zug ab. Für den Test ist nur Zug 5 anklickbar, damit ist der Ort eindeutig (Abschnitt 32). Für D-04 (G4, 9 Wiederholungen) muss Felix die Regel aus D9 im Code umsetzen. **Annahme: offen.** |

**Zählregel F2 (D11 bestätigt den Entwurf):** Der **Kreis muss benannt werden**: „im Kreis“, „gegenseitig“, „aufeinander“, „keiner kann zuerst“, „blockieren sich alle“. Zwei Glieder allein („5 wartet auf 8, 8 auf 6“) ohne Schluss sind `SYMPTOM`. Vorlesen der letzten Zeile zählt (Deckeneffekt, steht im Bericht). Der Titel enthält nach D11 keine Ursache mehr; ohne diese Regel wäre F2 mit dem Produkttitel in Sekunden „gefunden“.

### F3 Warten auf Ladung

**Wurzelursache:** Das Lager Hafen-Ost bekommt zu wenig Ware, weil nur **1 Lkw** es beliefert (Füllstand 12/40). Zug 7 wartet deshalb auf Ladung, Zug 10 steht hinter ihm am Signal 21. „Zug 7 wartet auf Ladung“ und „Lager ist leer“ sind Zwischenglieder.

**Soll-Kette (5 Zeilen):**
1. `T_STEHT` Zug 10 steht seit 2:10 min
2. `R_SIGNAL` Wartet am Signal 21: Abschnitt 22 ist besetzt
3. `R_HALTER` Zug 7 besetzt Abschnitt 22
4. `R_LADUNG` Zug 7 wartet in Hafen-Ost auf Ladung (12/40)
5. `W_ZULIEFERUNG` **Hafen-Ost bekommt zu wenig Ware: nur 1 Lkw liefert**

**Lösbarkeit mit `fuell_ist/soll` und `n_lkw` (Auftrag):** Zeile 4 ist aus `fuell_ist = 12`, `fuell_soll = 40` erzeugbar; Zeile 5 aus `n_lkw = 1`. Ohne `n_lkw` gibt es keine Zeile 5, die Kette endet bei Zeile 4, und die Zählregel wertet alles, was der Tester sagen kann, als `SYMPTOM`. Dann ist F3 per Konstruktion unlösbar, also ein Build-Fehler (Smoke-Test-Prüfpunkt bei Daniel: „Wurzelzeile im Build vorhanden“). Mit beiden Feldern ist F3 lösbar: Der Tester kann Zeile 5 vorlesen oder aus 12/40 plus „1 Lkw“ schließen.

| Feld | D9 | Stand im Spike |
|---|---|---|
| `fuell_ist` | Felix liefert | vorhanden als `stock` im LAGER-Glied |
| `fuell_soll` | Felix liefert | vorhanden als `needed` (= `cargo_cap` des wartenden Fahrzeugs, 10 im Spike). Im Test 40: Felix setzt `cargo_cap` im Szenario oder liefert einen Soll-Füllstand des Lagers. **Annahme: `needed` reicht.** |
| `n_lkw` | Felix liefert | **fehlt.** Der Spike kennt keine Zulieferer, nur `produce_every`/`produce_amount`. Für F-06 reicht ein geskripteter Wert je Lager (`n_lkw = 1`), eine echte Zählung von Linien ist nicht nötig. Das ist der kleinste Weg; Felix entscheidet. |
| Kanonischer Ort | Lagerknoten | erfüllt (`root_pos` = Lagerknoten, Kette endet dort) |

Hinweis für den Szenarioaufbau: In S3 sind die wartenden Fahrzeuge Lkw. Im Testszenario sind Zug 7 und Zug 10 Züge, der Zulieferer ist ein Lkw. Die Sim unterscheidet das nicht (Fahrzeug ist Fahrzeug), nur Namen und Modell ändern sich.

**Zählregel F3:** Pflichtelemente: zu wenig Zulieferung **oder** nur 1 Lkw liefert. `WURZEL`: „Das Lager bekommt zu wenig Ware“, „Nur ein Lkw beliefert das Lager“. `SYMPTOM`: „Zug 7 wartet auf Ladung“, „Das Lager ist leer“. `FALSCH`: „Das Lager ist leer, weil die Produktion fehlt“ (nennt eine Ursache, die nicht gilt).

## 3. Gemeinsame Regeln (unverändert bestätigt)

Erste festgelegte Aussage zählt · Aufzählung ohne Festlegung zählt nicht · Vorlesen der letzten Kettenzeile zählt · Moderator-Hilfe macht den Fehler zum Nichttreffer · Abbruch nach 120 s · zwei Beobachter unabhängig, Abweichung entscheide ich am Video ohne Kenntnis der Zeit · genau 60,0 s zählt nicht. Nebenmessungen nach D2 Pflicht: `zeilenklicks`, Anteil Nur-letzte-Zeile-Leser (Definition: `zeilenklicks ≤ 1` und Nennung = Wortlaut der letzten Zeile), Median `dauer_s` bei Treffern.

Fragebogen: F6 („Vorschlag hat mir geholfen“) entfällt (Vorschlag ausgeblendet, D11). Aylins ungezählte Frage „Was würdest du bauen?“ (D2) kommt ins Interview.

## 4. Was ich von anderen brauche

- **Felix (bis 20.11., 12:00, D9-Frist):** `n_lkw` je Lager (geskriptet reicht), `fuell_soll` = 40 im Testszenario, Streckenlänge in Feldern und Gleiszahl in `params`, kanonischer Ort bei F1/F2 nach D9 im Code. Stillstände ≥ 120 s in F-06.
- **Aylin:** Vorlage F2 auf 4 Züge, Kette 6 Zeilen; Produkttitel aus Abschnitt 1 übernehmen; Validator V3 auf `pos` (D9).
- **Daniel:** Soll-Tabelle in `l06_protokollvorlage.md` Abschnitt 6 durch Abschnitt 2 hier ersetzen; Smoke-Prüfpunkt „Zeile 5 bei F3 vorhanden“.
