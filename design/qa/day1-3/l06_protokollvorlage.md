# L-06 Protokollvorlage und Testplan: Diagnose-Playtest

Daniel Richter, QA (Beobachtungsbogen, Durchführung, Protokoll, Smoke-Test) · Durchführung **25.11.2026**
Status: **Vorlage und Testplan fertig, Test nicht durchgeführt.** Es gibt keine Tester-Daten. Alle Felder unten sind Platzhalter.
Abhängig von: Lena (3 Fehler mit Wurzelursache bis 19.11.), Aylin (Testskript, Aufgabentexte, Fragebogen), Felix (Build F-06 am 24.11., 10 Uhr), Katrin (6 Tester, Raum, OBS).

## 1. Messgröße (wörtlich aus L-06)

> **≥ 4 von 6 Testern finden die Wurzelursache von mind. 2 der 3 Fehler in < 60 s nach Klick auf die Meldung.** Es zählt nur die laut benannte Wurzelursache, nicht das Symptom.

Gate-Einordnung (Jonas, G1 und Pfeiler 1): **Grün ≥ 4/6 · Gelb 3/6 · Rot ≤ 2/6, weniger als 6 gültige Tester oder kein echter Build.** Mit Plan B (Fake-Feed) höchstens Gelb.

### Zählregel (Entscheidung je Tester × Fehler)

Ein Fehler zählt für einen Tester als **gefunden**, wenn alle vier Punkte stimmen:
1. Die Stoppuhr lief **ab Klick auf die Meldung** (siehe 3). Nicht ab Aufgabenstellung, nicht ab Szenariostart.
2. Der Tester nennt die Wurzelursache **laut** und als Antwort („Ich glaube, die Ursache ist …“). Gedachtes, Zeigen ohne Worte oder Kamerafahrt zählen nicht.
3. Die Aussage nennt **Objekt und Ursache** wie in Lenas Soll-Tabelle (6). Ein Symptom („Zug 4 steht“, „da ist ein Stau“) ist keine Wurzelursache und stoppt die Uhr nicht.
4. Die Zeit zwischen Klick und der **ersten** Aussage, die Punkt 2 und 3 erfüllt, beträgt **< 60,0 s**. Genau 60,0 s zählt nicht.

Weitere Regeln:
- **Hilfe des Moderators** (jeder inhaltliche Hinweis, auch „schau mal auf die Kette“) macht den Fehler für diesen Tester zu **nicht gefunden**. Neutrale Sätze („Was siehst du?“, „Denk laut“) sind erlaubt und im Skript festgelegt.
- **Mehrere Vermutungen:** Es zählt die erste Aussage, die der Tester als Antwort markiert. Wer in 60 s eine Liste von 4 Ursachen aufzählt, hat nichts gefunden, außer er legt sich fest. Das Skript fordert vor Beginn: „Sag am Ende klar: Das ist die Ursache.“
- **Teilweise richtig** (richtiges Objekt, falsche Ursache oder umgekehrt) = nicht gefunden. Der Fall wird mit Wortlaut notiert, damit Lena und Aylin ihn kennen.
- **Tester besteht**, wenn er ≥ 2 der 3 Fehler als gefunden hat.
- **Test bestanden**, wenn ≥ 4 von 6 Testern bestehen.
- **Ungültige Sitzung** (Absturz, Build-Fehler, Tester kannte das Szenario): Tester zählt nicht. Ersatztester aus der Reserve. Ohne 6 gültige Tester bleibt G1 offen bzw. Rot (Jonas), es wird nicht hochgerechnet.
- Ein Tester, bei dem ein einzelner Fehler technisch ausfiel, wird **nicht** nachgetestet (Lerneffekt). Er besteht nur, wenn die übrigen zwei Fehler gefunden sind. Sonst nicht bestanden, mit Vermerk „technisch ausgefallen“.

## 2. Rollen am Testtag

Abgeglichen mit Aylins `testskript_entwurf.md` (v0.1). Wo wir uns unterschieden, habe ich ihre Regel übernommen, damit es **eine** Regel gibt.

| Rolle | Person | Aufgabe |
|---|---|---|
| Moderation, Hauptbeobachter, Stoppuhr | Daniel | Skript sprechen, nur neutrale Nachfragen, Bogen, Stoppuhr, vorläufiger Zählentscheid |
| Zweitbeobachter, zweite Stoppuhr | Aylin | sitzt hinter dem Tester, eigener Bogen, unabhängige Bewertung |
| Szenario, Auswertung, Schlichtung bei Abweichung | Lena | nicht im Raum; bewertet strittige Fälle am Video, ohne die Zeit zu kennen |
| Raum, OBS, Tester | Katrin | Aufnahme mit Bildschirm, Ton, Zeitstempel |
| Beobachtung ohne Ticket | Jonas | stumm |

Meine frühere Annahme „Aylin moderiert“ ist damit erledigt (Refinement: Daniel Durchführung, Aylin Co-Beobachtung).

## 3. Stoppuhr-Regel

- **Start:** exakt beim Klick auf die Meldung im Feed (A-05/F-06). Ich starte die Uhr auf das Klickgeräusch bzw. den sichtbaren Panelwechsel, der Zweitbeobachter ebenfalls.
- **Lesezeit vor dem Klick** zählt nicht, wird aber als Nebenmessung notiert (Zeit Aufgabenende → Klick). Wartet ein Tester > 60 s, ist das ein Befund zur Auffindbarkeit der Meldung, nicht zur Kette.
- **Stopp:** beim ersten Wort der zählenden Aussage (Zählregel 1.2 und 1.3). Bei Unsicherheit entscheidet die Aufnahme.
- **Ablauf nach 60 s:** Die Uhr läuft weiter bis **120 s** (Aylins Abbruchregel, Obergrenze gegen Frust). Danach sagt der Moderator „Danke, wir gehen zur nächsten Aufgabe“. Der Fehler gilt ab 60,0 s als „nicht gefunden“. Eine Nennung zwischen 60 und 120 s wird als „zu spät“ festgehalten und zählt nicht.
- **Abgleich:** Weichen die beiden Uhren um **mehr als 3 s** ab (Aylins Wert), fehlt das UI-Log oder weicht die Bewertung ab, gilt die **Videozeit**. Bei abweichender Bewertung (WURZEL gegen SYMPTOM) bewertet Lena am Video, ohne die Zeit zu kennen. Nichts wird nachträglich geschätzt: fehlt eine Zeit, steht `NA`, der Fehler zählt als nicht gefunden.
- **Startpunkt belegt durch das UI-Klick-Log** des Builds (`t_klick_ms`, Aylins Mini-Entwurf; Felix bestätigt noch). Dann ist nur das Stoppen Beobachtung. Ohne Log: Videozeit.

## 4. Beobachtungsbogen (ein Blatt je Tester, 3 Fehlerblöcke)

**Kopf**

| Feld | Eintrag |
|---|---|
| Tester-ID (T1 bis T6, R1 bis R2 Reserve) | |
| Gruppe | Veteran / Einsteiger |
| Datum, Uhrzeit, Raum | |
| Build-ID und Hash (Freeze 24.11., 10 Uhr) | |
| Variante | A echter Build (F-04) · B Plan B Fake-Feed |
| Beobachter 1 / 2 | |
| Reihenfolge der Fehler (7) | |
| Kein Vorwissen bestätigt (nicht im Projektteam, Szenario nie gesehen) | ja / nein |
| OBS läuft, Datei | |

**Fehlerblock (je Fehler 1 bis 3, identische Felder)**

| Feld | Beobachter 1 | Beobachter 2 |
|---|---|---|
| Fehler-ID und Soll-Wurzelursache (aus 6) | | |
| Aufgabe gelesen (Uhrzeit) | | |
| **Klick auf Meldung** (Uhrzeit/Stoppuhr 0) | | |
| Zeit bis Klick (Nebenmessung, s) | | |
| Wortlaut der ersten festgelegten Aussage (wörtlich) | | |
| Stoppzeit (s, eine Nachkommastelle) | | |
| Aussage = Wurzelursache laut Soll? ja / nein / teilweise | | |
| **Gefunden (< 60,0 s und Wurzelursache)?** ja / nein | | |
| Fehlklicks nach dem Meldungsklick (Zahl) | | |
| Kette aufgeklappt / Sprung zur Karte benutzt (ja/nein) | | |
| Moderator-Hinweis nötig (ja/nein, wann, Wortlaut) | | |
| Abbruch durch Tester (ja/nein, bei s) | | |
| Zeit bis Fund nach 60 s (Zusatz, s) | | |
| Auffälligkeiten, Zitate, Verwechslungen | | |

Fehlklick = Klick auf Objekt, Zeile oder Marker, der nicht zur Kette der Soll-Wurzelursache gehört, nach dem Meldungsklick. Zählt nicht für die Messgröße, geht an Aylin.

**Abschluss je Tester**

| Feld | Eintrag |
|---|---|
| Fehler gefunden (0 bis 3) | |
| **Tester besteht (≥ 2 von 3)** | ja / nein |
| Sitzung gültig? | ja / nein, Grund |
| Absturz oder Fehler im Build (Tick, Beschreibung) | |
| Antwort auf „Was würdest du bauen?“ (nur Notiz, Jonas' Pfeiler 5, zählt nicht) | |
| Fragebogen (Aylin) abgegeben | ja / nein |

## 5. Rohdaten-Tabelle (am Testtag, eine Zeile je Tester × Fehler)

| Tester | Gruppe | Fehler | Reihenfolge-Pos. | Zeit bis Klick (s) | Stoppzeit ab Klick (s) | Aussage Wurzelursache ok | Gefunden < 60 s | Fehlklicks | Hinweis nötig | Abbruch | Gültig | Notiz |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| T1 | | F1 | | | | | | | | | | |
| T1 | | F2 | | | | | | | | | | |
| T1 | | F3 | | | | | | | | | | |
| T2 bis T6 | gleiches Schema, je 3 Zeilen | | | | | | | | | | | |

**Abgleich mit Aylins CSV (Single Source für die Datei):** Die Rohdaten werden als CSV mit Aylins Kopf geführt, mein Bogen ist die Papierform dazu:
`tester;gruppe;reihenfolge_pos;fehler;t_klick_ms;t_nennung_ms;dauer_s;aussage_woertlich;bewertung;treffer_unter_60s;zeilenklicks;fehlklicks;hilfe_noetig;fehlerklasse;seq;sicherheit;naechster_schritt_woertlich`

| Meine Spalte | Ihr Feld | Abweichung |
|---|---|---|
| Stoppzeit ab Klick | `dauer_s` = `t_nennung − t_klick` | gleiche Größe; `t_klick` aus UI-Log, `t_nennung` Beginn des Satzes „Das ist die Ursache“ |
| Aussage Wurzelursache ok (ja/nein/teilweise) | `bewertung` ∈ `WURZEL`/`SYMPTOM`/`FALSCH`/`KEINE` | meine „teilweise“ = `FALSCH`; „nein“ ohne Ursachenaussage = `SYMPTOM` oder `KEINE` |
| Gefunden < 60 s | `treffer_unter_60s` = `WURZEL` und `dauer_s < 60` | identisch |
| Fehlklicks | `fehlklicks` (Klicks nach `t_klick`, die weder Kettenzeile, Meldungskopf noch „Zurück“ sind) | ihre Definition ist enger und aus dem Log ableitbar; sie gilt statt meiner |
| Moderator-Hinweis | `hilfe_noetig` | identisch |
| Abbruch | `fehlerklasse` / Abbruch nach 120 s | `fehlerklasse` ist bei ihr feiner (`NICHT_GEOEFFNET` … `SONSTIGE`) |
| fehlt bei mir | `zeilenklicks`, `seq`, `sicherheit`, `naechster_schritt_woertlich` | übernehme ich |

Auswertung (nur aus echten Zeilen):

| Kennzahl | Wert |
|---|---|
| gültige Tester | _ von 6 |
| Tester, die bestehen | _ von 6 (Veteranen _/3, Einsteiger _/3) |
| Fehler 1 / 2 / 3: Anzahl gefunden | _ / _ / _ von 6 |
| Median Stoppzeit der gefundenen Fälle | _ s |
| **Gate G1** | Grün ≥ 4 · Gelb 3 · Rot ≤ 2 |

Hinweis zur Aussagekraft: n = 6. Ein Ergebnis von 4/6 hat ein 95-%-Konfidenzintervall (Wilson, gerechnet, nicht gemessen) von grob 30 % bis 90 %. Das Ergebnis sagt „Diagnose ist plausibel auffindbar“, keine Statistik (so auch Jonas' Vermerk zu Pfeiler 1).

## 6. Soll-Wurzelursachen (Lena bestätigt bis 19.11.)

**Arbeitsstand (Annahme):** Aylin (`textvorlagen_testfehler.md`) und Felix (`test_output.txt`) benutzen dieselben drei Fehler. Ich übernehme sie vorläufig. Lenas Dokumentation lag beim Schreiben nicht vor.

| Fehler | Kurzbeschreibung | Soll-Wurzelursache (Aylins Pflichtelemente, Entwurf) | zählt nicht allein | Zielzeit |
|---|---|---|---|---|
| F1 | Gegenverkehr eingleisig (Zug 4, Platzhalter) | Strecke hat nur ein Gleis **und** ein Gegenzug blockiert sie, oder „Ausweichgleis fehlt“ | „wartet am Signal“, „Abschnitt besetzt“, „Zug 2 steht im Weg“ | < 60 s |
| F2 | Deadlock-Kreis (Zug 5, Platzhalter) | Züge warten im Kreis aufeinander, keiner kann zuerst fahren (mindestens zwei Glieder oder „blockieren sich gegenseitig“) | „Zug 5 wartet auf Zug 8“ | < 60 s |
| F3 | Warten auf Ladung (Zug 10, Platzhalter) | Lager bekommt zu wenig Ware **oder** nur 1 Lkw liefert | „Zug 7 wartet auf Ladung“ | < 60 s |

**Widerspruch in den Quellen, offen bis Lena bestätigt:** Lenas Plan nannte „Deadlock eingleisig · fehlendes Signal vor Bahnhof · Lager mit nur 1 Zulieferer“, Felix' Plan „fehlendes Ausweichgleis · Deadlock · unterversorgtes Lager“. Aylins und Felix' aktuelle Stände stimmen untereinander überein. Ohne Lenas Freigabe bleiben die Sollwerte im Bogen Entwurf.

**Zwei Risiken aus Aylins Entwurf, die ich teile:** (1) Deckeneffekt: Die Kette endet in der Wurzelursache, wer die letzte Zeile liest, hat sie in wenigen Sekunden. Nach ihrer Regel 3 zählt das Vorlesen der letzten Zeile, wenn der Tester sie als Ursache setzt. Ein Ergebnis „6 von 6“ belegt dann „die Kette ist lesbar“, nicht „Diagnose trägt in echten Netzen“. Median und Fehlerklassen gehören in die Auswertung. (2) Der Titel „Zug 5 steht seit 1:40 min“ ist bei allen drei Fehlern gleich gebaut (kein „blockieren sich gegenseitig“ im Titel). Entscheidung Lena/Jonas offen.

Die Soll-Wurzelursache muss im Build tatsächlich als Ende der Kette stehen. Wenn der Feed bei einem Fehler nur das Symptom liefert, ist der Fehler nicht lösbar. Das wäre ein Build-Fehler, kein Tester-Fehler. Prüfpunkt im Smoke-Test.

## 7. Reihenfolge der Fehler (Gegengewicht)

Es gilt **Aylins Tabelle** (`testskript_entwurf.md`, Abschnitt 2), damit es nur eine gibt. Sie enthält alle 6 Permutationen, und in jeder Gruppe steht jeder Fehler einmal an jeder Position:

| Tester | Gruppe | Reihenfolge |
|---|---|---|
| T1 | Veteran | 1, 2, 3 |
| T2 | Veteran | 2, 3, 1 |
| T3 | Veteran | 3, 1, 2 |
| T4 | Einsteiger | 1, 3, 2 |
| T5 | Einsteiger | 3, 2, 1 |
| T6 | Einsteiger | 2, 1, 3 |

Zuordnung der Personen zu T1 bis T6 durch Los vor dem Test, Katrin hält die Liste. Meine frühere Tabelle ist gestrichen.

## 8. Testplan 25.11.

**Vorbedingungen (Gate für den Testtag)**

| Prüfpunkt | Wer | Frist |
|---|---|---|
| 3 Fehler mit Wurzelursache und Zielzeit dokumentiert (Tabelle 6) | Lena | 19.11. |
| Testskript, Aufgabentexte, Fragebogen | Aylin | 18.11. (Skript), Tester 20.11. |
| Build F-06 mit Hash eingefroren | Felix | 24.11., 10 Uhr |
| **Smoke-Test:** 3 von 3 Fehlern auslösbar, 0 Abstürze in 30 min, Kette endet bei jedem Fehler bei der Soll-Wurzelursache, Klick auf Meldung und Sprung zum Ort funktionieren, Replay wird geschrieben | Daniel | 24.11. nachmittags |
| 6 Tester + 2 Reserve bestätigt (3 Veteranen, 3 Einsteiger, nicht im Projektteam) | Katrin | 20.11. |
| Raum, Zielrechner oder gleichwertiger Rechner, OBS-Test | Katrin | 24.11. |
| Entscheidung Variante A oder B (Fake-Feed) | Daily | 20.11. |

Hinweis: Das Studio ist klein. Interne Tester kennen das Konzept, das verzerrt vor allem Einsteiger. Rekrutierung nach Möglichkeit extern oder aus anderen Teams. Das ist Katrins Entscheidung. Ich vermerke es als Risiko im Gate.

**Zeitplan (Vorschlag, 6 Sitzungen)**

| Zeit | Inhalt |
|---|---|
| 09:00 | Aufbau, Smoke-Check, Build-Hash prüfen |
| 09:30 bis 10:15 | T1 |
| 10:30 bis 11:15 | T2 |
| 11:30 bis 12:15 | T3 |
| 13:15 bis 14:00 | T4 |
| 14:15 bis 15:00 | T5 |
| 15:15 bis 16:00 | T6 |
| 16:15 | Rohdaten-Tabelle zusammenführen, Zählentscheide beider Beobachter abgleichen |

Ablauf je Tester nach Aylins Skript (35 bis 40 min netto, im 45-min-Slot mit Wechsel): 0 bis 5 min Begrüßung und Einwilligung, 5 bis 8 min Papier-Beispiel (andere Kette, nichts von den drei Fehlern), 8 bis 20 min Aufgaben A1 bis A3 (je höchstens 2 min plus Nachfrage), 20 bis 25 min Fragebogen, 25 bis 35 min Interview. Meine frühere Aufteilung ist damit ersetzt.

**Pilot:** ein Durchlauf mit einer Person außerhalb des Teams am 24.11. nach dem Smoke-Test (Aylins Vorschlag, ich unterstütze ihn). Das Ergebnis zählt nicht, er prüft Skript, Aufnahme, UI-Log und Stoppuhr.

**Abbruch- und Störregeln**
- Absturz während einer Messung: Fehler für diesen Tester nicht werten, Absturz mit Tick und Replay im Tracker (S1). Kein Wiederholen desselben Fehlers.
- Zwei Abstürze am Testtag: Test unterbrechen, Build prüfen, Entscheidung im Daily. Ausgefallene Sitzungen holen Reserve-Tester nach.
- Moderator gibt versehentlich einen Hinweis: sofort notieren, Fehler für diesen Tester nicht gefunden.
- Tester bricht ab: Sitzung ungültig, außer 2 Fehler wurden bereits gefunden (dann besteht er).

**Plan B (Fake-Feed, präparierte Saves)** wenn F-04 am 20.11. nicht steht: Bogen und Messgröße bleiben gleich. In den Kopf kommt „Variante B“. Das Ergebnis testet nur die Lesbarkeit der Diagnose, nicht die Signallogik, und zählt laut Jonas höchstens Gelb. Die Kette im Fake-Feed darf nicht von einem Spieler gelöst werden können, indem er die Simulation beobachtet. Es muss sich so verhalten wie der echte Feed.

## 9. Offene Fragen

- **Lena:** verbindliche Fehlerliste (siehe 6) und Pflichtelemente je Fehler bis 19.11. bestätigen. Außerdem die Veteranen-Definition aus Aylins Entwurf (mindestens 20 h Genre).
- **Aylin:** Aufgabentext ist bei dir neutral („finde heraus, warum er steht“), das passt zu meinem Bogen. Offen: Titel gleich gebaut bei allen drei Fehlern (Lena/Jonas entscheiden).
- **Felix:** UI-Klick-Log mit `t_klick_ms` (Aylins Mini-Entwurf) und Replay mit Klick-Ereignis. Beides steht nicht in F-06-Akzeptanzkriterium, ist aber nötig, um den Stoppuhr-Startpunkt zu belegen. Stillstand muss ≥ 120 s sichtbar bleiben (Aylins Frage 10).
- **Katrin:** Rekrutierung, Reserve (8 statt 6), externe Tester möglich?
