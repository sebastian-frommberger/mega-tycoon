# Testskript Diagnose-Playtest (L-06, Entwurf v0.1)

Autorin: Aylin Kaya · Owner des Tickets: Lena · Durchführung: Daniel · Termin: 25.11. (Build 24.11., 10 Uhr) · Entwurf, noch nicht mit Lena und Daniel abgestimmt.

## 1. Messgröße (Beschluss vom Refinement, unverändert)

**≥ 4 von 6 Testern finden die Wurzelursache von mindestens 2 der 3 Fehler in < 60 s nach Klick auf die Meldung.** Es zählt nur die laut benannte Wurzelursache, nicht das Symptom.

- Ein Fehler zählt als **Treffer**, wenn die Wurzelursache korrekt benannt wurde **und** `t_nennung − t_klick < 60 s`.
- Ein Tester **besteht**, wenn er mindestens 2 Treffer hat.
- Der Test **besteht**, wenn mindestens 4 von 6 Testern bestehen.
- Nicht Teil des Gate: Vergleich mit einer Variante ohne Feed (gestrichen).

## 2. Rahmen

| Punkt | Festlegung |
|---|---|
| Tester | 6 Personen, 3 Veteranen, 3 Einsteiger. Rekrutierung: Katrin. |
| Veteran (Annahme, Lena bitte bestätigen) | mindestens 20 h in Transport Fever, OpenTTD, Railway Empire oder Transport Tycoon |
| Einsteiger | spielt mindestens einmal im Monat digitale Spiele, keine Erfahrung im Genre |
| Ausschluss | Teammitglieder, Personen, die den Prototyp kennen |
| Besetzung | Daniel moderiert und stoppt, Aylin beobachtet mit zweiter Stoppuhr, Lena nur Szenario (nicht im Raum), Jonas beobachtet still, Katrin Raum und OBS |
| Aufzeichnung | OBS: Bildschirm und Mikrofon, Dateiname `T<nr>_<datum>.mkv` |
| Build | F-06, drei Fehler, Feed offen, Mini-Entwurf grau, Logdatei der UI-Klicks |
| Dauer | 35 bis 40 Minuten je Tester |
| Pilot | **Vor** dem 25.11. ein Durchlauf mit einer Person, die nicht zum Team gehört. Ergebnis zählt nicht, prüft nur Skript, Aufnahme und Stoppuhr. Vorschlag: 24.11. nach dem Smoke-Test. |

### Reihenfolge der Fehler (ausbalanciert)

Fehler 1 = Gegenverkehr, 2 = Deadlock-Kreis, 3 = Warten auf Ladung. Jede Gruppe sieht jeden Fehler einmal an jeder Position, insgesamt kommen alle 6 Reihenfolgen vor.

| Tester | Gruppe | Reihenfolge |
|---|---|---|
| T1 | Veteran | 1, 2, 3 |
| T2 | Veteran | 2, 3, 1 |
| T3 | Veteran | 3, 1, 2 |
| T4 | Einsteiger | 1, 3, 2 |
| T5 | Einsteiger | 3, 2, 1 |
| T6 | Einsteiger | 2, 1, 3 |

## 3. Ablauf

| Min | Schritt |
|---|---|
| 0 bis 5 | Begrüßung, Einverständnis, Think-aloud erklären |
| 5 bis 8 | Papier-Beispiel (Bedienung zeigen, andere Kette, siehe 4) |
| 8 bis 20 | Aufgaben A1 bis A3 (je höchstens 2 min plus Nachfrage) |
| 20 bis 25 | Fragebogen am Bildschirm oder auf Papier |
| 25 bis 35 | Interview, Dank |

## 4. Moderationsskript (wörtlich vorlesen)

**Begrüßung:** "Danke, dass du da bist. Wir testen ein Spiel, nicht dich. Du kannst nichts falsch machen. Wir nehmen Bildschirm und Ton auf, damit wir auswerten können. Das Video sehen nur wir. Du kannst jederzeit abbrechen. Einverstanden?" (Einverständnis mündlich auf Band und schriftlich unterschrieben. **Die Formulierung ist nicht juristisch geprüft, Katrin klärt DSGVO-Text.**)

**Think-aloud:** "Bitte sprich laut aus, was du siehst und denkst. Wenn du glaubst, die Ursache zu kennen, sage: 'Das ist die Ursache' und dann in einem Satz, was es ist."

**Papier-Beispiel:** Ausdruck eines Panels mit einer anderen Kette (zum Beispiel "Zug 1 steht seit 0:50 min", Wurzel "Straße Nord ist gesperrt"). Zeigen: Meldung anklicken, Liste lesen, Zeile anklicken, Kamera springt. Der Moderator erklärt **nicht**, was Abschnitt, Signal oder Wurzelursache bedeuten und liest keine Beispielkette der drei Testfehler vor. Dazu braucht Felix keinen vierten Fehler.

**Neutrale Zwischenfragen (nur diese):** "Was siehst du gerade?" (nach 15 s Schweigen) · "Was denkst du?" Keine Hinweise, keine Bestätigung, kein "genau".

## 5. Aufgabenformulierung

Der Text ist bei allen drei Aufgaben identisch, nur der Zug wechselt.

| Aufgabe | Wortlaut |
|---|---|
| A1 / A2 / A3 | "In deinem Netz steht **Zug <Nr>** schon seit einigen Minuten. Du bist die Verkehrsleiterin. Finde heraus, **warum er steht**. Öffne dafür die Meldung zu diesem Zug. Sage laut, sobald du die Ursache kennst." |

Zugnummer je Fehler: Fehler 1 = Zug 4, Fehler 2 = Zug 5, Fehler 3 = Zug 10 (Platzhalter, siehe `textvorlagen_testfehler.md`).

- **Start der Zeit** = Klick auf die Meldung des genannten Zugs. Klickt jemand zuerst eine andere Meldung an, zählt der erste Klick auf die richtige Meldung.
- **Nachfrage N3** nach der Nennung (ohne Zeitwertung): "Was würdest du jetzt als Erstes tun?"
- **Abbruch** nach 120 s ohne verbindliche Antwort. Moderator: "Danke, wir gehen zur nächsten Aufgabe." Das ist ein Nichttreffer. Eine Nennung zwischen 60 und 120 s wird festgehalten (zu spät), zählt aber nicht.
- Die Aufgabe nennt weder "Kette", "Wurzelursache" noch "Abschnitt".

## 6. Zählregel: was zählt als Wurzelursache (Entwurf, Lena bestätigt bis 19.11.)

Die Zählregel stammt von Lena (Wurzelursache, nicht Symptom). Die Pflichtelemente sind mein Entwurf.

| Fehler | Pflichtelemente der Aussage | zählt nicht |
|---|---|---|
| 1 Gegenverkehr | Strecke hat nur ein Gleis **und** ein Zug aus der Gegenrichtung blockiert sie (oder "Ausweichgleis fehlt") | "Zug 4 wartet am Signal", "Abschnitt ist besetzt", "Zug 2 steht im Weg" allein |
| 2 Deadlock | Die Züge warten im Kreis aufeinander, keiner kann zuerst fahren (mindestens zwei Glieder des Kreises oder "blockieren sich gegenseitig") | "Zug 5 wartet auf Zug 8" allein |
| 3 Ladung | Das Lager bekommt zu wenig Ware **oder** nur 1 Lkw liefert (Ursache der leeren Ladung) | "Zug 7 wartet auf Ladung" allein |

Regeln für Aussagen:
1. Es zählt die **erste** Aussage, die die Pflichtelemente enthält und als Antwort gesetzt wird ("Das ist die Ursache: ...").
2. Zählt nicht: eine Aufzählung mehrerer Möglichkeiten ohne Festlegung ("vielleicht A oder B").
3. Das Vorlesen der letzten Kettenzeile **zählt**, wenn der Tester sie als Ursache setzt. Der Test misst, ob die Kette zur Ursache führt.
4. Zwei Beobachter bewerten unabhängig (Daniel, Aylin) und tragen Treffer, Symptom, falsch oder keine ein. Bei Abweichung entscheidet Lena mit dem Video, vor der Auswertung und ohne die Zeit zu kennen.

## 7. Messprotokoll

Ein Datensatz je Tester und Fehler (18 Zeilen). Spalten als CSV-Kopf:

```
tester;gruppe;reihenfolge_pos;fehler;t_klick_ms;t_nennung_ms;dauer_s;aussage_woertlich;bewertung;treffer_unter_60s;zeilenklicks;fehlklicks;hilfe_noetig;fehlerklasse;seq;sicherheit;naechster_schritt_woertlich
```

| Feld | Quelle |
|---|---|
| `t_klick_ms` | UI-Log, Abgleich mit Video-Zeitstempel |
| `t_nennung_ms` | Video (Beginn des Satzes "Das ist die Ursache"), Stoppuhr als Zweitquelle |
| `dauer_s` | `t_nennung − t_klick` |
| `bewertung` | `WURZEL` / `SYMPTOM` / `FALSCH` / `KEINE` (zwei Beobachter) |
| `treffer_unter_60s` | `WURZEL` und `dauer_s < 60` |
| `zeilenklicks` | Anzahl Klicks auf Kettenzeilen im Log |
| `fehlklicks` | Klicks nach `t_klick`, die weder Kettenzeile, Meldungskopf noch "Zurück" sind (aus `klick_sonstige`) |
| `hilfe_noetig` | j/n: Moderator hat inhaltlich geholfen, dann Nichttreffer |
| `fehlerklasse` | bei Nichttreffer: `NICHT_GEOEFFNET` · `KETTE_NICHT_GELESEN` · `KETTE_FALSCH_VERSTANDEN` · `WORT_UNVERSTAENDLICH` · `SPRUNG_VERWIRRT` · `SONSTIGE` |

Zeitnahme: Daniel startet seine Stoppuhr am Klick auf die Meldung, Aylin ihre zweite ebenfalls. Weichen die Stoppuhren um mehr als 3 s ab oder fehlt das Log, gilt die Videozeit. Nichts wird nachträglich geschätzt: fehlt eine Zeit, steht `NA` und der Fehler zählt als Nichttreffer.

## 8. Fragebogen

**Screening (Katrin vor der Einladung):**

| Nr | Frage |
|---|---|
| S1 | Wie oft spielst du digitale Spiele? (täglich / wöchentlich / monatlich / seltener) |
| S2 | Welche dieser Spiele hast du mindestens 20 Stunden gespielt? Transport Fever 1 oder 2, OpenTTD, Railway Empire, Transport Tycoon, Cities: Skylines, Factorio, Anno, keines davon |
| S3 | Arbeitest du an einem Spiel oder in der Spielebranche? (Ausschluss bei Ja) |

**Nach jeder Aufgabe (schriftlich, 2 Fragen):**

| Nr | Frage | Skala |
|---|---|---|
| N1 | Wie einfach oder schwierig war es, die Ursache herauszufinden? | 1 sehr schwierig bis 7 sehr einfach |
| N2 | Wie sicher bist du, dass die genannte Ursache stimmt? | 1 gar nicht bis 5 völlig sicher |

**Am Ende (stimme gar nicht zu = 1 bis stimme voll zu = 5):**

| Nr | Aussage |
|---|---|
| F1 | Ich wusste jederzeit, warum ein Fahrzeug stand. |
| F2 | Die Liste unter "Warum?" war leicht zu lesen. |
| F3 | Ich habe verstanden, welches Objekt auf der Karte zu welcher Zeile gehört. |
| F4 | Der Sprung der Kamera hat mir geholfen, das Problem zu finden. |
| F5 | Alle Wörter in den Meldungen waren mir verständlich. |
| F6 | Der Vorschlag hat mir geholfen zu entscheiden, was ich tun soll. |
| F7 | In einem echten Spiel würde ich mich auf diese Meldungen verlassen. |

**Interview (mündlich, 10 min):**
- O1 Welche Zeile oder welches Wort war unklar? Zeig es mir.
- O2 Was hat dir gefehlt, um sicher zu sein?
- O3 Was hättest du ohne die Meldungen gemacht, um herauszufinden, warum ein Zug steht?
- O4 (nur Veteranen) Wie hättest du die Ursache in deinem bisherigen Lieblingsspiel gefunden? Wie lange hätte das gedauert?

## 9. Auswertung (Lena, Aylin zuarbeitend)

1. **Tabelle Tester × Fehler** mit Treffer ja/nein und `dauer_s`. Daraus je Tester die Anzahl Treffer und bestanden ja/nein.
2. **Gate-Zeile:** `bestanden = Anzahl Tester mit ≥2 Treffern`, Schwelle 4 von 6. Zusätzlich ausgewiesen: Treffer je Fehler und je Gruppe (Veteranen/Einsteiger), Median von `dauer_s` bei Treffern, Fehlerklassen der Nichttreffer.
3. **Unsicherheit:** Bei 6 Testern ist 4 von 6 keine Aussage über die Spielerschaft. Das Wilson-95-%-Intervall für 4/6 liegt bei 30 % bis 90 % (Rechnung, nicht gemessen). Die Messgröße ist eine Plausibilitätsschwelle fürs Gate. Die Auswertung sagt das ausdrücklich.
4. **Drei Top-Erkenntnisse** mit Beleg (Zeile aus dem Protokoll, Zitat, Zeitmarke im Video) und einer Änderung am Entwurf.
5. Fragebogenwerte als Median je Aussage, keine Mittelwerte, keine Signifikanztests.

## 10. Risiken für die Aussagekraft

| Risiko | Maßnahme |
|---|---|
| **Deckeneffekt:** Die Kette endet in der Wurzelursache. Wer die letzte Zeile liest, hat sie in unter 30 s. Dann wird "≥4 von 6" fast sicher erreicht und sagt nur, dass man lesen kann. | Median und Fehlerklassen mit auswerten. Wenn alle bestehen, ist die Aussage: lesbar für diese Fälle, nicht: Diagnose trägt für echte Netze. |
| Titel verrät die Ursache (Deadlock) | Alle drei Titel im Test gleich gebaut (`T_STEHT`), siehe Textvorlagen. Entscheidung Lena/Jonas offen. |
| Vorschlag verrät die Ursache | Zählregel verlangt die Ursache. Vorschlagstext nicht gewertet. Entscheidung Lena/Jonas offen. |
| Lerneffekt über drei Aufgaben | Reihenfolge ausbalanciert (Abschnitt 2). Mit 6 Testern nur grob. |
| Fachwörter für Einsteiger | Texte nutzen "Abschnitt", nicht "Block". Frage F5 und Fehlerklasse `WORT_UNVERSTAENDLICH` zeigen das. |
| Stillstand löst sich während des Tests auf | Schnappschuss im Build. Fehler müssen mindestens 120 s sichtbar bleiben, Frage 10 an Felix. |
| Beobachter beeinflussen | Nur neutrale Fragen. Aylin sitzt hinter dem Tester, nicht daneben. |

## 11. Plan B (Fallback am 20.11.)

Steht F-04 nicht, läuft der Test mit präparierten Saves und geskriptetem Feed (Lena, Daniel). Dann ändern sich nur Quelle und Zeitpunkt der Kette. Der Feed-Mini-Entwurf bleibt gleich, die Daten sind statisch nach dem Vertrag. Messgröße, Aufgabentext, Zählregel und Fragebogen bleiben identisch. In der Auswertung steht dann klar, dass die Kette nicht live berechnet war. Aylin (Puffer 2,5 T) baut den Fake-Feed mit Felix' Tabellenformat, falls nötig.

## 12. Offen (mit Namen)

1. **Lena:** Fehlerdokumentation bis 19.11., Pflichtelemente (Abschnitt 6) und Definition Veteran/Einsteiger bestätigen.
2. **Felix:** UI-Klick-Log (Mini-Entwurf), Stillstandsdauer ≥ 120 s, Schnappschuss.
3. **Daniel:** Beobachtungsbogen auf das CSV-Format abgleichen, Stoppuhr-Regel.
4. **Katrin:** Rekrutierung nach Screening, Einwilligungstext, Raum und OBS.
5. **Jonas:** Titel und Vorschlag im Test (siehe Textvorlagen und Mini-Entwurf).
