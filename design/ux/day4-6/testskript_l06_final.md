# Testskript Diagnose-Playtest L-06, Stand "final zur Gegenzeichnung" (v1.0)

Autorin: Aylin Kaya · Stand 20.11.2026 · Owner Lena · Durchführung Daniel · Testtag 25.11. (Build 24.11., 10 Uhr) · ersetzt `day1-3/aylin/testskript_entwurf.md`.

**Abgleich, ehrlich:** Abgeglichen mit `day4-6/lena/l06_fehler_final.md` (final aus Design-Sicht, 19.11.), `day1-3/lena/playtest_szenario.md` (Abschnitte 3 bis 7) und `day1-3/daniel/l06_protokollvorlage.md` (Abschnitte 1 bis 5, 8). Von Daniel gibt es für Tag 4–6 nur D-04- und Farbcheck-Dateien, keine neue Protokollvorlage und keine `daniel.md`. Wo die beiden mir widersprachen, habe ich ihre Regel übernommen und es unten markiert. "Final" heißt: inhaltlich abgeschlossen; Lena und Daniel müssen gegenzeichnen (Abschnitt 11). **Kein Pilot, keine Tester, keine Messwerte.** Das Ticket wartet auf echte Durchführung.

## 1. Messgröße (D2, wörtlich) und Pflicht-Nebenmessungen

**Hauptmessung (G1):** ≥ 4 von 6 Testern finden die Wurzelursache von mindestens 2 der 3 Fehler in < 60,0 s nach Klick auf die Meldung. Es zählt nur die laut benannte Wurzelursache, nicht das Symptom. Genau 60,0 s zählt nicht (Lena, Daniel).

**Was der Test belegt (D2, G1 neu):** "Kette in 3 bekannten Fällen lesbar". Nicht "Diagnose trägt", nicht "USP belegt". Der Bericht nennt Wilson-Intervall und Deckeneffekt in einem Satz.

**Pflicht-Nebenmessungen (D2), je Tester × Fehler, alle aus Klick-Log plus Video:**

| Nr | Nebenmessung | Definition | Quelle |
|---|---|---|---|
| N-A | **Zeilenklicks** | Anzahl `zeile_klick` zwischen `t_klick` und `t_nennung` | Klick-Log |
| N-B | **Nur-letzte-Zeile-Leser** | Lenas Definition (Owner): Treffer mit `zeilenklicks ≤ 1` **und** Nennung = Wortlaut der letzten Zeile. Ich ergänze eine zweite Spalte `zeilen_vorgelesen` (j/n: Tester hat eine Zeile 1 bis n−1 laut gelesen oder wiedergegeben, Beobachterurteil), damit ein Tester, der alles liest, ohne zu klicken, und dann die letzte Zeile zitiert, nicht als Nur-letzte-Zeile-Leser zählt. Im Bericht stehen beide Zahlen. Ausgewiesen als Anteil der Treffer. | Klick-Log + Video |
| N-C | **Median der Zeit** | Median von `dauer_s` über alle Treffer, dazu getrennt je Fehler und je Gruppe | Protokoll |
| N-D | Zeit bis Klick | Aufgabenende → `t_klick`, Befund zur Auffindbarkeit, nicht zur Kette (Daniel) | Video + Log |
| N-E | "Was würdest du bauen?" | Antwort wörtlich, **ungezählt** (D2, Pfeiler 5). Lena legt sie ins Interview; ich stelle sie direkt nach jeder Nennung (ohne Zeit), weil die Antwort nach 20 Minuten nicht mehr fehlerbezogen ist. Lena entscheidet. | Protokoll |

N-B ist ein Beobachtungs-Proxy, kein Blickmaß. Das steht so im Bericht.

## 2. Rahmen

| Punkt | Festlegung |
|---|---|
| Tester | 6 (3 Veteranen ≥ 20 h in Transport Fever, OpenTTD, Railway Empire oder Transport Tycoon; 3 Einsteiger: mind. monatlich digitale Spiele, keine Genre-Erfahrung) plus 2 Reserve. Keine Teammitglieder, Szenario nie gesehen. Rekrutierung Katrin, möglichst extern (Daniel). Lena hat die Definition übernommen. |
| Rollen | Daniel moderiert, Hauptbeobachter, Stoppuhr 1 · Aylin Zweitbeobachterin hinter dem Tester, Stoppuhr 2 · Lena nicht im Raum, schlichtet am Video ohne Zeitkenntnis · Katrin Raum, OBS · Jonas stumm |
| Aufzeichnung | OBS Bildschirm und Mikrofon, `T<nr>_<datum>.mkv`; Klick-Log `klicklog_T<nr>.csv` (Spezifikation `f06_panel_spezifikation.md`) |
| Build | F-06 mit Hash (Freeze 24.11., 10 Uhr), drei getrennte Teilnetze, Stillstände ≥ 120 s alt beim Start, zwei Kontrollzüge ohne Meldung, Feed offen, grau, **Vorschlag ausgeblendet (D11)**, Titel alle `T_STEHT` (D11) |
| Variante | `A` echter Build · `B` Plan B (Saves, statischer Feed) → Deckel Gelb (D7), steht im Kopf jedes Bogens |
| Dauer | 35 bis 40 min je Tester, 45-min-Slots nach Daniels Zeitplan |
| Pilot | 24.11. nach dem Smoke-Test mit einer Person außerhalb des Teams; zählt nicht, prüft Skript, OBS, Klick-Log, Stoppuhren. **Nicht durchgeführt.** |

### Reihenfolge (ausbalanciert, von Daniel und Lena übernommen)

| Tester | Gruppe | Reihenfolge |
|---|---|---|
| T1 | Veteran | F1, F2, F3 |
| T2 | Veteran | F2, F3, F1 |
| T3 | Veteran | F3, F1, F2 |
| T4 | Einsteiger | F1, F3, F2 |
| T5 | Einsteiger | F3, F2, F1 |
| T6 | Einsteiger | F2, F1, F3 |

Zuordnung der Personen per Los, Katrin hält die Liste.

## 3. Ablauf (min)

0–5 Begrüßung, Einwilligung (Text: Katrin, B6) · 5–8 Papier-Beispiel · 8–20 Aufgaben A1–A3 (je max. 2 min + Nachfragen) · 20–25 Fragebogen · 25–35 Interview, Dank.

## 4. Moderationsskript (wörtlich)

**Begrüßung:** "Danke, dass du da bist. Wir testen ein Spiel, nicht dich. Du kannst nichts falsch machen. Wir nehmen Bildschirm und Ton auf, damit wir auswerten können. Das Video sehen nur wir. Du kannst jederzeit abbrechen. Einverstanden?" (mündlich auf Band und schriftlich; Text nicht juristisch geprüft, Katrin)

**Think-aloud:** "Bitte sprich laut aus, was du siehst und denkst. Wenn du glaubst, die Ursache zu kennen, sage: 'Das ist die Ursache' und dann in einem Satz, was es ist. Sag am Ende klar: Das ist die Ursache."

**Papier-Beispiel:** Ausdruck eines Panels mit einer fremden Kette ("Zug 1 steht seit 0:50 min", Wurzel "Straße Nord ist gesperrt"). Zeigen: Meldung anklicken, Liste lesen, Zeile anklicken, Kamera springt. Nicht erklären: Abschnitt, Signal, Wurzelursache. Keine der drei Testketten vorlesen.

**Neutrale Zwischenfragen (nur diese):** "Was siehst du gerade?" (nach 15 s Schweigen) · "Was denkst du?" Keine Hinweise, kein "genau", kein "schau mal auf die Kette" (Daniel: jeder inhaltliche Hinweis = Nichttreffer).

## 5. Aufgaben

Identischer Wortlaut, nur der Zug wechselt: "In deinem Netz steht **Zug <Nr>** schon seit einigen Minuten. Du bist die Verkehrsleiterin. Finde heraus, **warum er steht**. Öffne dafür die Meldung zu diesem Zug. Sage laut, sobald du die Ursache kennst."

F1 = Zug 4, F2 = Zug 5, F3 = Zug 10 (Platzhalter, Lena Abschnitt 2).

- `t_klick` = erster Klick auf die Meldung des genannten Zugs (Klick-Log `meldung_geoeffnet`, Video als Zweitquelle).
- Nach der Nennung, ohne Zeit: N-E "Was würdest du jetzt als Erstes bauen oder ändern?"
- Abbruch nach 120 s ohne festgelegte Antwort: "Danke, wir gehen zur nächsten Aufgabe." Nennung zwischen 60 und 120 s = "zu spät", zählt nicht.
- Die Aufgabe nennt weder "Kette", "Wurzelursache" noch "Abschnitt".

## 6. Zählregel (Lena, Abschnitt 2 ihres Szenarios; von mir übernommen)

| Fehler | Pflichtelemente | `WURZEL` | `SYMPTOM` (zählt nicht) | Grenzfall → Lena am Video |
|---|---|---|---|---|
| F1 | Eingleisigkeit **und** Gegenzug, oder "Ausweichgleis fehlt" | "Nur ein Gleis und Zug 2 kommt entgegen." | "wartet am Signal", "Abschnitt besetzt", "Zug 2 steht im Weg" | "Die Strecke ist zu eng." |
| F2 | **Kreis muss benannt werden:** "im Kreis", "gegenseitig", "aufeinander", "keiner kann zuerst" | "Die blockieren sich alle gegenseitig." | "5 wartet auf 8, 8 auf 6" ohne Schluss; alle 4 Zeilen vorgelesen ohne Kreis-Schluss | – |
| F3 | zu wenig Zulieferung **oder** nur 1 Lkw liefert | "Nur ein Lkw beliefert das Lager." | "Zug 7 wartet auf Ladung", "Lager ist leer" | "Lager leer, weil Produktion fehlt" = `FALSCH` |

**Änderung gegenüber meinem Entwurf:** Bei F2 reichen zwei Kettenglieder nicht mehr, der Kreis-Schluss muss genannt werden (Lena, B9). Ich stimme zu: zwei Glieder sind Zwischenglieder.

Weitere Regeln (unverändert, Daniel/Lena): erste festgelegte Aussage zählt · Aufzählung ohne Festlegung zählt nicht · Vorlesen der letzten Zeile zählt, wenn als Ursache gesetzt · Moderatorhilfe = Nichttreffer · zwei Beobachter unabhängig · teilweise richtig = `FALSCH` · technisch ausgefallener Fehler wird nicht nachgetestet.

## 7. Messprotokoll (CSV-Kopf, Single Source; Daniels Bogen ist die Papierform)

```
tester;gruppe;variante;reihenfolge_pos;fehler;t_klick_ms;t_nennung_ms;dauer_s;zeit_bis_klick_s;aussage_woertlich;bewertung_b1;bewertung_b2;bewertung_final;treffer_unter_60s;zeilenklicks;zeilen_vor_nennung;nur_letzte_zeile;zeilen_vorgelesen;fehlklicks;hilfe_noetig;fehlerklasse;seq;sicherheit;bauen_woertlich;gueltig
```

Neu gegenüber v0.1: `variante` (Lena), `zeit_bis_klick_s` (Daniel), `bewertung_b1/b2/final` (zwei Beobachter, Schlichtung), `zeilen_vor_nennung` (Liste der geklickten Zeilenindizes vor `t_nennung`, z. B. `1,2,4`), `nur_letzte_zeile` (j/n, Lenas Regel), `zeilen_vorgelesen` (j/n, Beobachter), `bauen_woertlich` (N-E), `gueltig`. Entfernt: `naechster_schritt_woertlich` (durch `bauen_woertlich` ersetzt).

| Feld | Quelle |
|---|---|
| `t_klick_ms`, `zeilenklicks`, `zeilen_vor_nennung`, `fehlklicks` | Klick-Log (Spezifikation in `f06_panel_spezifikation.md`, Abschnitt 5) |
| `t_nennung_ms` | Video, erstes Wort der zählenden Aussage; Stoppuhren als Zweitquelle; Abweichung > 3 s → Videozeit |
| `bewertung_*` | `WURZEL` / `SYMPTOM` / `FALSCH` / `KEINE` |
| `fehlerklasse` | bei Nichttreffer: `NICHT_GEOEFFNET` · `KETTE_NICHT_GELESEN` · `KETTE_FALSCH_VERSTANDEN` · `WORT_UNVERSTAENDLICH` · `SPRUNG_VERWIRRT` · `ZU_SPAET` · `SONSTIGE` |
| fehlende Zeit | `NA`, Nichttreffer, nichts wird geschätzt |

## 8. Fragebogen

Screening (Katrin, vor Einladung): S1 Spielhäufigkeit · S2 ≥ 20 h in welchen der Genre-Titel · S3 Spielebranche (Ausschluss).

Nach jeder Aufgabe: N1 "Wie einfach oder schwierig war es, die Ursache herauszufinden?" (1–7) · N2 "Wie sicher bist du, dass die genannte Ursache stimmt?" (1–5).

Am Ende (1–5): F1 "Ich wusste jederzeit, warum ein Fahrzeug stand." · F2 "Die Liste unter 'Warum?' war leicht zu lesen." · F3 "Ich habe verstanden, welches Objekt auf der Karte zu welcher Zeile gehört." · F4 "Der Sprung der Kamera hat mir geholfen." · F5 "Alle Wörter in den Meldungen waren mir verständlich." · F7 "In einem echten Spiel würde ich mich auf diese Meldungen verlassen." **F6 (Vorschlag) gestrichen (D11, Lena).**

Interview: O1 unklare Zeile oder Wort zeigen · O2 was fehlte, um sicher zu sein · O3 was hättest du ohne Meldungen getan · O4 (Veteranen) wie im Lieblingsspiel, wie lange.

## 9. Auswertung (Lena, Aylin und Daniel zuarbeitend)

1. Tabelle Tester × Fehler: Treffer, `dauer_s`, `nur_letzte_zeile`, `zeilenklicks`.
2. Gate-Zeile: Anzahl Tester mit ≥ 2 Treffern, Schwelle 4/6; Variante A oder B.
3. Pflicht-Nebenmessungen N-A bis N-C ausgewiesen, je Fehler und je Gruppe.
4. Ein Satz mit Wilson-95-%-Intervall (4/6 → 30 bis 90 %, Rechnung, keine Messung) und Deckeneffekt.
5. Drei Top-Erkenntnisse mit Beleg (Protokollzeile, Zitat, Zeitmarke) und je einer Änderung am Entwurf.
6. Fragebogen als Median, keine Mittelwerte, keine Signifikanztests.

## 10. Plan B (Entscheidung 20.11. im Daily)

Steht F-04 nicht (Lenas Auslöser: Exit 0 **und** Übergabe an Daniel **und** Feldvertrag abgeglichen), läuft der Test mit Lenas drei Saves und statischem Feed nach `diagnose_datenvertrag_v1.md`. Skript, Zählregel, Protokoll und Fragebogen bleiben identisch, `variante = B`, Gelb-Deckel. Aylin baut den Fake-Feed aus dem Puffer. Stand 20.11. aus den Dateien: Exit 0 ja (`day4-6/felix/spike/test_output.txt`, mit D9-Feldern und Validator); Übergabe an Daniel belegt durch `day4-6/daniel/build_md5.txt` und `d04_lauf_ausgabe.txt`; Feldvertrag von mir abgeglichen (Vertrag v1), von Felix nicht per Datei bestätigt. Nach Lenas Definition ist der Auslöser für Plan B damit **nicht** gegeben; ich würde Variante A fahren.

## 11. Gegenzeichnung und Offenes

| Wer | Punkt | Stand |
|---|---|---|
| Lena | CSV-Kopf Abschnitt 7, Spalte `zeilen_vorgelesen`, Zeitpunkt von N-E, Wortlaut `R_LADUNG` "(12 von 40)", kanonischer Ort nach Felix' Regel | offen; Zählregel, F2 mit 4 Zügen, F6 gestrichen sind durch ihre Datei bestätigt |
| Daniel | Bogen gegen CSV-Kopf v1.0 abgleichen (neue Spalten), Fehlerklasse `ZU_SPAET`, Smoke-Test-Punkt "Klick-Log schreibt `meldung_geoeffnet`" | offen |
| Felix | Klick-Log und Panel nach `f06_panel_spezifikation.md`; Streckennamen und Zugnamen in der F-06-Szene | offen; `n_lkw`, Streckenlänge, Gleiszahl, kanonischer Ort sind im Spike vom 19.11. da |
| Katrin | 6 + 2 Tester bestätigt, Einwilligungstext, Raum, OBS, Zielrechner | offen, nicht belegt |
| Jonas | Zählung Plan-B-Stufe B1 (Lena nimmt "synthetisch" an, D7 bestätigt das) | durch D7 erledigt |
