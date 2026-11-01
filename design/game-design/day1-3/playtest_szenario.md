# L-06 Diagnose-Playtest: Szenario, Zählregel, Messprotokoll, Plan B

Lena Hoffmann · Stand: Entwurf zur Freigabe (Frist laut Ticket 19.11.) · **Nichts hier ist gemessen.** Es gibt keine Tester-Daten und noch keinen F-06-Build. Alle Namen und Zahlen der Fehler sind Platzhalter, bis Felix' Build sie festschreibt (siehe Abschnitt 3).

Quellen, gegen die ich geprüft habe: `felix/spike/scenarios.gd` und `test_output.txt` (S1, S2, S3), `aylin/textvorlagen_testfehler.md`, `aylin/testskript_entwurf.md`, `aylin/diagnose_datenvertrag.md`, `daniel/l06_protokollvorlage.md`, `jonas/gate_kriterien.md`.

## 1. Was der Test misst und was nicht

**Messgröße (Beschluss, wörtlich):** ≥ 4 von 6 Testern finden die Wurzelursache von mind. 2 der 3 Fehler in < 60 s nach Klick auf die Meldung. Es zählt nur die laut benannte Wurzelursache, nicht das Symptom.

| Begriff | Definition |
|---|---|
| Treffer (Tester × Fehler) | Wurzelursache laut und als Antwort benannt (Pflichtelemente, Abschnitt 2) **und** `t_nennung − t_klick < 60,0 s`. Genau 60,0 s zählt nicht. |
| Tester besteht | ≥ 2 Treffer bei 3 Fehlern |
| Test besteht | ≥ 4 von 6 gültigen Testern bestehen |
| Gate G1 (Jonas) | Grün ≥ 4/6, Gelb 3/6, Rot ≤ 2/6, < 6 gültige Tester oder kein echter Build. Mit Plan B höchstens Gelb. |

**Grenzen, die in der Auswertung wörtlich stehen müssen:**
1. **Deckeneffekt.** Die Kette endet in der Wurzelursache. Wer die letzte Zeile vorliest und als Ursache setzt, hat sie nach Zählregel gefunden. Ein Bestehen belegt dann: die Kette ist für diese 3 bekannten Fälle lesbar. Es belegt nicht: Diagnose trägt in echten Netzen.
2. **n = 6.** 4 von 6 ist keine Aussage über die Spielerschaft (Rechnung in Abschnitt 5, nicht gemessen).
3. **Der Test prüft nicht, ob die Sim die Kette richtig berechnet.** Das prüfen F-04 und D-04.
4. **Felix' Spike unterscheidet keine Ursachentypen Geld/Nachfrage und kennt kein `n_lkw`.** Das erfüllt F3 nur, wenn die Zahl der Zulieferer geliefert wird (Abschnitt 3).

## 2. Die drei Fehler (Entwurf, deckungsgleich mit F-04 S1 bis S3)

Entscheidung gegenüber meinem alten Plan: Die fünf Fehler aus `plan/lena.md` sind durch den Beschluss auf drei reduziert. Es gelten die Fehler, die Felix' Spike headless erzeugt. Dadurch misst G1 etwas, das F-04 liefert.

| | F1 Gegenverkehr eingleisig | F2 Deadlock-Kreis | F3 Warten auf Ladung |
|---|---|---|---|
| Quelle im Spike | S1 (Strecke A–D, Zug A→D gegen Zug D→A, kein Ausweichgleis) | S2 (Gleisquadrat, 4 Züge im Uhrzeigersinn) | S3 (Lager ohne Nachschub, Zug 2 steht hinter dem wartenden Zug 1) |
| Testname (Platzhalter) | Zug 4, Gegenzug Zug 2, Strecke Mühlbach–Kornfeld | Zug 5, 8, 6, 9, Kreuzung Südfeld | Zug 10, davor Zug 7, Lager Hafen-Ost |
| Symptom (Meldungstitel) | „Zug 4 steht seit 2:10 min“ | „Zug 5 steht seit 1:40 min“ | „Zug 10 steht seit 2:10 min“ |
| **Wurzelursache** | Die Strecke hat nur ein Gleis, ein Gegenzug blockiert sie, ein Ausweichgleis fehlt | Die 4 Züge warten im Kreis aufeinander, keiner kann zuerst fahren | Das Lager bekommt zu wenig Ware, nur 1 Lkw liefert |
| Typ / Code (Aylin, Felix) | INFRASTRUKTUR / `EINGLEISIG_GEGENVERKEHR` | INFRASTRUKTUR / `KREIS_BLOCKIERUNG` (Felix: `DEADLOCK`) | LADUNG / `ZULIEFERUNG_ZU_GERING` (Felix: `WARTEN_AUF_LADUNG`) |
| Soll-Kette (Zeilen, letzte = Wurzel) | 4 Zeilen: steht · wartet am Signal 12, Abschnitt 13 besetzt · Zug 2 besetzt Abschnitt 13 und fährt entgegen · **Mühlbach–Kornfeld hat nur ein Gleis** | 6 Zeilen: steht · 5 wartet auf 8 · 8 wartet auf 6 · 6 wartet auf 9 · 9 wartet auf 5 · **Alle 4 warten aufeinander** | 5 Zeilen: steht · wartet am Signal 21 · Zug 7 besetzt Abschnitt 22 · Zug 7 wartet auf Ladung (12/40) · **Hafen-Ost bekommt zu wenig Ware: nur 1 Lkw liefert** |
| Zielzeit | < 60 s nach Klick (Messgrenze) | < 60 s | < 60 s |

**Zielzeit.** Die 60 s sind die Messgrenze des Beschlusses. Eine kürzere Erwartung (z. B. 30 s) wäre ein erfundener Messwert, deshalb setze ich keine. Der Pilot am 24.11. liefert erste Zeiten und zählt nicht.

**Änderung gegenüber Aylins Entwurf:** F2 hat 4 statt 3 Züge, weil Felix' S2 4 Züge baut (Kette 12 Glieder). Nur `{n}` und die Zahl der Kettenzeilen ändern sich (6 statt 5), die Zeichenprüfung (≤ 60 Zeichen) gilt weiter.

### Zählregel: Pflichtelemente, Symptom, Zwischenglied

Die Zählregel stammt aus dem Refinement (nur die benannte Wurzelursache zählt). Die Pflichtelemente sind Aylins Entwurf, von mir geschärft.

| Fehler | Pflichtelemente der Aussage | Wertung `WURZEL` | Wertung `SYMPTOM` (zählt nicht) | Grenzfall (Beobachter melden, Lena entscheidet am Video ohne Zeit) |
|---|---|---|---|---|
| F1 | Eingleisigkeit **und** Gegenzug, oder „Ausweichgleis fehlt“ | „Da ist nur ein Gleis und Zug 2 kommt entgegen.“ · „Es fehlt ein Ausweichgleis.“ | „Zug 4 wartet am Signal.“ · „Abschnitt ist besetzt.“ · „Zug 2 steht im Weg.“ | „Die Strecke ist zu eng.“ (richtige Richtung, kein Pflichtelement) → zählt nicht, mit Wortlaut notiert |
| F2 | Es muss ein **Kreis** benannt werden: „im Kreis“, „gegenseitig“, „aufeinander“, „keiner kann zuerst“ | „Die blockieren sich alle gegenseitig.“ · „Jeder wartet auf den nächsten, im Kreis.“ | „Zug 5 wartet auf Zug 8.“ · „5 wartet auf 8, 8 auf 6“ ohne den Schluss | Tester liest alle 4 Zeilen vor und schließt den Kreis nicht → `SYMPTOM` |
| F3 | Zu wenig Zulieferung **oder** nur 1 Lkw liefert | „Das Lager bekommt zu wenig Ware.“ · „Nur ein Lkw beliefert das Lager.“ | „Zug 7 wartet auf Ladung.“ · „Das Lager ist leer.“ | „Das Lager ist leer, weil die Produktion fehlt.“ (falsche Ursache) → `FALSCH` |

**Änderung gegenüber Aylin (Abschnitt 6 ihres Skripts):** Bei F2 reichen „mindestens zwei Glieder des Kreises“ nicht, es muss der Schluss des Kreises genannt werden. Zwei Glieder allein sind eine Kette ohne Ursache, das ist ein Zwischenglied. Aylin und Daniel bestätigen oder widersprechen (offen).

Weitere Regeln, unverändert aus Aylin und Daniel: erste festgelegte Aussage zählt, keine Aufzählung ohne Festlegung, Vorlesen der letzten Kettenzeile zählt, Moderator-Hilfe macht den Fehler zum Nichttreffer, Abbruch nach 120 s, zwei Beobachter bewerten unabhängig.

## 3. Anforderungen an Szenario und Build (Eingang für F-06)

Das Szenario ist eine Testkarte, auf der alle drei Stillstände schon bestehen, sauber getrennt.

1. **Drei getrennte Teilnetze** (je Fehler eines), damit ein Fehler den anderen nicht beeinflusst und jede Aufgabe für sich lösbar ist.
2. **Alle drei Stillstände sind beim Start schon ≥ 120 s alt** (geskriptetes `seit_tick`) und bleiben als Schnappschuss stehen. Die Meldung ändert sich nicht, während der Tester liest (Aylin, Grundregel 2). Das macht die Messung stabil.
3. **Zwei Kontrollzüge** fahren auf dem Ausweichgleis-Layout K1 aus Felix' Spike, ohne Meldung. Sie beweisen 0 Fehlalarme und verhindern, dass „alles steht“ die Aufgabe verrät.
4. **Feed zeigt genau drei Meldungen.** Titel alle gleich gebaut (`T_STEHT`), damit der Titel keine Ursache nennt.
5. **Vorschlag im Test ausgeblendet** (mein Vorschlag an Aylin und Jonas, offen): „Ausweichgleis bauen“ nennt die Wurzelursache von F1 und „Lkw hinzufügen“ die von F3. Felix liefert ohnehin nur `suggestion_id`, keinen berechneten Vorschlag. Konsequenz: Frage F6 im Fragebogen entfällt, die Nachfrage N3 („Was würdest du als Erstes tun?“) bleibt.
6. **Daten, die Felix für die Wurzelzeilen liefern muss** (der Spike hat sie nicht): F1 Streckenlänge und Gleiszahl; F3 Füllstand `ist/soll` und `n_lkw` der Zulieferer. Fehlt ein Wert, ist die Wurzelzeile nicht erzeugbar, und der Fehler ist für Tester unlösbar. Das ist ein Build-Fehler und wird im Smoke-Test geprüft (Daniel: „Wurzelzeile im Build vorhanden“).
7. **Namen aus der Tabelle in Abschnitt 2** gelten im Build. Die Zugnummern der Fehler sind verschieden (4, 5, 10), damit Tester nichts vermischen. Felix' Spike nennt die Fahrzeuge „Zug 1/2“ und „Lkw 1/2“, das wird im Szenarioaufbau umbenannt.
8. **Reihenfolge der Fehler** je Tester wie in Aylins Tabelle (6 Permutationen, T1 bis T6).
9. **Sicherung:** jede Session als Replay, UI-Klick-Log mit `t_klick_ms` (Aylin, Mini-Entwurf).

## 4. Messprotokoll

Das Protokoll liegt bereits vor und ist untereinander abgeglichen: Aylin `testskript_entwurf.md` Abschnitt 7 (CSV-Kopf, 18 Zeilen) und Daniel `l06_protokollvorlage.md` Abschnitte 3 bis 5 (Stoppuhr, Bogen, Rohdaten). Ich dupliziere es nicht. **Meine Bestätigung als Szenario-Owner (Entwurf, wartet auf Gegenzeichnung):**

| Punkt | Festlegung |
|---|---|
| Startzeit | Klick auf die Meldung des genannten Zuges (UI-Log, Video als Zweitquelle) |
| Stopp | erstes Wort der zählenden Aussage |
| Wertung | `WURZEL` / `SYMPTOM` / `FALSCH` / `KEINE` nach Tabelle in Abschnitt 2, zwei Beobachter unabhängig |
| Abweichung | Lena am Video, ohne die Zeit zu kennen |
| Ergänzung 1 | Spalte `variante` = `A` (echter Build) oder `B` (Plan B), damit die Gate-Einordnung (B höchstens Gelb) aus den Daten folgt |
| Ergänzung 2 | Spalte `kette_zeilen_gelesen` (Anzahl Klicks auf Kettenzeilen) wird zusammen mit `dauer_s` ausgewertet, um den Deckeneffekt sichtbar zu machen |
| Fehlt eine Zeit | `NA`, zählt als Nichttreffer, nichts wird geschätzt |
| Ungültige Sitzung | Absturz, Build-Fehler, Tester kannte das Szenario: Tester zählt nicht, Reserve (Daniel) |
| Tester | 3 Veteranen (≥ 20 h in Transport Fever, OpenTTD, Railway Empire oder Transport Tycoon, von mir bestätigt), 3 Einsteiger (mind. monatlich digitale Spiele, keine Genre-Erfahrung), keine Teammitglieder |

## 5. Auswertung und Aussagekraft

Auswertung (ich, Aylin und Daniel arbeiten zu): Tabelle Tester × Fehler (Treffer, `dauer_s`), Gate-Zeile (Anzahl bestandener Tester, Schwelle 4 von 6), Treffer je Fehler und je Gruppe, Median von `dauer_s` bei Treffern, Fehlerklassen der Nichttreffer, drei Top-Erkenntnisse mit Beleg (Protokollzeile, Zitat, Zeitmarke), Fragebogen als Median.

**Wie viel sagt „4 von 6“?** Rechnung, keine Messung. Annahme: jeder Fehler wird mit Wahrscheinlichkeit q gefunden, die drei Fehler und die Tester sind unabhängig. Dann gilt P(Tester besteht) = 3q² − 2q³ und P(Test besteht) = P(Binomial(6; P) ≥ 4).

| q (Trefferrate je Fehler) | P(Tester besteht) | P(Test besteht, ≥ 4/6) | P(≥ 3/6) |
|---|---|---|---|
| 0,3 | 0,22 | 0,02 | 0,12 |
| 0,5 | 0,50 | 0,34 | 0,66 |
| 0,6 | 0,65 | 0,64 | 0,88 |
| 0,7 | 0,78 | 0,88 | 0,98 |
| 0,8 | 0,90 | 0,98 | 1,00 |
| 0,9 | 0,97 | 1,00 | 1,00 |

Lesart: Wenn die Kette in der Praxis nur die Hälfte der Fälle löst, besteht der Test trotzdem mit 34 % Wahrscheinlichkeit. Er trennt grob (q ≤ 0,3 fällt fast sicher durch, q ≥ 0,8 besteht fast sicher), ist aber im Bereich um 0,5 bis 0,6 ein Münzwurf. Wilson-95-%-Intervalle für den beobachteten Anteil bestandener Tester: 3/6 → 19 bis 81 %, 4/6 → 30 bis 90 %, 5/6 → 44 bis 97 %, 6/6 → 61 bis 100 %.

**Konsequenz für die Empfehlung an das Gate:** Die Empfehlung nennt Ergebnis, Intervall und Deckeneffekt in einem Satz und behauptet nicht, die Diagnose „trage“. Ein Ergebnis von 6/6 mit Median unter 30 s und fast nur Letzte-Zeile-Lesern wird als „lesbar“ berichtet.

## 6. Plan B: präparierte Saves und Fake-Feed

**Auslöser (Entscheidung im Daily am 20.11., Beschluss):** „F-04 steht“ heißt hier: (a) 3 Szenarien headless Exit 0, (b) Spike-Build ist am 19.11. an Daniel übergeben, (c) der Feldvertrag mit Aylin ist abgeglichen. **Stand nach den Dateien vom 18.11.:** (a) erfüllt (`test_output.txt`), (b) und (c) offen. Ich bereite Plan B deshalb vor, ohne den Auslöser vorwegzunehmen.

| Stufe | Wann | Inhalt | Gate-Wirkung |
|---|---|---|---|
| A | F-04 steht, F-06 am 24.11., 10 Uhr abgenommen | echter Build, Kette aus `get_wait_chain()` | Grün/Gelb/Rot nach G1 |
| B | F-04 steht am 20.11. nicht, oder F-06 am 24.11. nicht abgenommen | 3 präparierte Saves, Kette als statische Daten nach Aylins Datenvertrag, gleiche UI, gleicher Aufgabentext, gleiche Zählregel, gleicher Fragebogen | **höchstens Gelb** (Jonas: Fake-Feed zählt als synthetisch) |

**Inhalt der Saves (je Fehler ein Save, Stand eingefroren bei Tick, an dem der Stillstand ≥ 120 s alt ist):**

| Save | Layout | Feed-Daten | Quelle |
|---|---|---|---|
| `f1_eingleisig` | Strecke Mühlbach–Kornfeld mit 3 Kanten (Felix S1), Zug 4 und Zug 2 stehen sich gegenüber, ein Signal je Seite | 1 Meldung, 4 Kettenglieder, `kette_kreis=false`, `ursache.code=EINGLEISIG_GEGENVERKEHR` | `felix/spike/test_output.txt` (S1 Kette und `root_pos`) |
| `f2_kreis` | Gleisquadrat Südfeld, 4 Züge besetzen je einen Abschnitt | 1 Meldung, 5 Glieder + Schluss, `kette_kreis=true`, `kette_kreis_zurueck_zu=0` | `test_output.txt` S2 (12 Kettenglieder werden zu 4 Zug-Gliedern verdichtet) |
| `f3_ladung` | Lager Hafen-Ost, 1 Lkw als Zulieferer, Zug 7 am Lager, Zug 10 am Signal dahinter | 1 Meldung, 5 Glieder, `params.fuell_ist=12`, `fuell_soll=40`, `n_lkw=1` | Beispiel in `aylin/diagnose_datenvertrag.md` |

**Regeln, damit Plan B nicht schummelt:** Positionen und Meldung sind identisch zu dem, was der echte Build zeigen würde. Die Sim ist pausiert, es bewegt sich nur die Kamera. Der Feed hat die gleiche Zahl an Zeilen und Wörtern. Im Ergebnisbericht steht auf der ersten Seite „Plan B, Kette nicht live berechnet“.

**Aufwand:** 0,5 T bei mir (Saves) plus Aylins Puffer für den Fake-Feed (Refinement: Aylin springt ein). **Frage an Jonas, offen:** Zählt eine geskriptete Darstellung echter `get_wait_chain()`-Daten (Stufe B1) als Messwert oder fällt sie ebenfalls unter „synthetisch“? Ich nehme „fällt darunter“ an.

## 7. Entscheidungsvorschläge an die Beteiligten (noch nicht abgestimmt)

- **Aylin:** Fehlerliste, Namen und Zählregel wie oben. Titel im Test gleich (`T_STEHT`, Zustimmung zu deinem Vorschlag). Vorschlag im Test ausgeblendet, F6 entfällt. F2 mit 4 Zügen. Veteranen-Definition bestätigt.
- **Daniel:** Soll-Tabelle in deinem Abschnitt 6 durch Abschnitt 2 hier ersetzen. Zum Widerspruch in deiner Quellenliste: Gültig ist die Liste aus Felix' Spike (Gegenverkehr, Kreis, Ladung). Zu D-04: „Weiche ohne Signal“ und „Ausweichgleis zu kurz“ sind im Spike nicht baubar. Vorschlag: D-04 prüft F1 und F2 aus diesem Dokument je 3 Seeds, das dritte Szenario ist F2 mit 3 statt 4 Zügen. Ob die Gate-Zahl „≥ 5/6“ so bleibt, entscheiden Jonas und Katrin.
- **Felix:** Dein Gegenverkehr als Zyklus aus zwei Gegenrichtungs-Waiten passt zu F1. Bitte zusätzlich liefern: Streckenlänge und Gleiszahl (F1), Füllstand und `n_lkw` (F3), Fehlerzustand mindestens 120 s sichtbar, Zugnamen gemäß Abschnitt 2.
- **Jonas:** Zählung von Plan-B-Varianten (Abschnitt 6) und Bestätigung der Veteranen-/Einsteiger-Definition.
