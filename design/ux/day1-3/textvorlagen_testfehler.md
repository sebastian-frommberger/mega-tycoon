# Textvorlagen für die 3 Testfehler (A-05)

Autorin: Aylin Kaya · Entwurf. **Annahme:** Namen, Nummern und Zahlen sind Platzhalter, bis Lenas Fehlerdokumentation (bis 19.11.) vorliegt. Sie stammen teils aus `concept/aylin.md`. Die Fehler 1 bis 3 benutzen bewusst unterschiedliche Zug- und Signalnummern, damit Tester nichts vermischen.

## Schreibregeln

- Spielersprache: aktiv, ein Gedanke pro Zeile, "weil" oder "dann" statt Fachwort.
- Keine IDs oder Codes im Text. Statt "Block" steht "Abschnitt", statt "Reservierung" steht "besetzt". "Deadlock" steht nur im Glossar-Tooltip.
- Jede Kettenzeile höchstens 60 Zeichen, höchstens 2 Zeilen (Panel 400 px bei 1080p, rund 45 Zeichen je Zeile). Geprüft mit Skript, siehe unten.
- Zeit als `m:ss min`. Zahlen mit Einheit.
- Genau eine Zeile trägt das Label **Wurzelursache**, immer die letzte.

## Platzhalter

`{zug}` Zugname · `{zug2}` zweiter Zug · `{signal}` Signalnummer · `{abs}` Abschnittsnummer · `{dauer}` Stillstandsdauer · `{strecke}` Streckenname · `{felder}` Länge in Feldern · `{lager}` Lagername · `{ist}`/`{soll}` Füllstand · `{n}` Anzahl Lkw oder Züge · `{ort}` Ortsname

## Vorlagen

| ID | Text | Verwendung |
|---|---|---|
| `T_STEHT` | `{zug} steht seit {dauer}` | Meldungstitel und Kettenzeile 1 |
| `T_ORT` | `bei {ort}` | Untertitel der Meldung |
| `R_SIGNAL` | `Wartet am Signal {signal}: Abschnitt {abs} ist besetzt` | Zwischenglied |
| `R_HALTER` | `{zug2} besetzt Abschnitt {abs}` | Zwischenglied |
| `R_HALTER_GEGEN` | `{zug2} besetzt Abschnitt {abs} und fährt entgegen` | Zwischenglied |
| `R_WARTET_ZUG` | `{zug} wartet auf {zug2}, der Abschnitt {abs} besetzt` | Zwischenglied im Kreis |
| `R_LADUNG` | `{zug} wartet in {lager} auf Ladung ({ist}/{soll})` | Zwischenglied |
| `W_EINGLEISIG` | `{strecke} hat nur ein Gleis ({felder} Felder)` | Wurzel Fehler 1 |
| `W_KREIS` | `Alle {n} warten aufeinander, keiner kann zuerst fahren` | Wurzel Fehler 2 |
| `W_ZULIEFERUNG` | `{lager} bekommt zu wenig Ware: nur {n} Lkw liefern` | Wurzel Fehler 3 |
| `V_AUSWEICH` | `Ausweichgleis auf {strecke} bauen` | Vorschlag |
| `V_KREUZUNG` | `Signal vor der Kreuzung setzen` | Vorschlag |
| `V_ZUG_UMLEITEN` | `{zug} umleiten` | Vorschlag |
| `V_LKW` | `Lkw für {lager} hinzufügen` | Vorschlag |
| `V_MINDESTLADUNG` | `Mindestbeladung für {zug} senken` | Vorschlag |

**Entscheidung für den Test, bitte bestätigen (Lena, Jonas):** Alle drei Meldungstitel nutzen `T_STEHT`, auch der Kreis. Im Produkt würde der Deadlock-Titel lauten "Zug 5, 8 und 6 blockieren sich gegenseitig". Das nennt die Wurzelursache schon im Titel, und Fehler 2 wäre in Sekunden "gefunden", ohne die Kette zu lesen. Der Test misst die Kette, nicht den Titel. Die Produktvariante steht in der Tabelle unten, damit sie nicht verloren geht.

## Fehler 1: Gegenverkehr eingleisig

| Teil | Text |
|---|---|
| Meldung | **Zug 4 steht seit 2:10 min** · bei Strecke Mühlbach–Kornfeld |
| Kette 1 | Zug 4 steht seit 2:10 min |
| Kette 2 | Wartet am Signal 12: Abschnitt 13 ist besetzt |
| Kette 3 | Zug 2 besetzt Abschnitt 13 und fährt entgegen |
| Kette 4 (Wurzel) | Mühlbach–Kornfeld hat nur ein Gleis (14 Felder) |
| Vorschlag | Ausweichgleis auf Mühlbach–Kornfeld bauen |

Erwartete Wurzelursache: Strecke ist eingleisig, ein Gegenzug blockiert sie, ein Ausweichgleis fehlt. Typ INFRASTRUKTUR, Code `EINGLEISIG_GEGENVERKEHR`.

## Fehler 2: Deadlock-Kreis (Beispiel mit 3 Zügen)

| Teil | Text |
|---|---|
| Meldung | **Zug 5 steht seit 1:40 min** · bei Kreuzung Südfeld |
| Kette 1 | Zug 5 steht seit 1:40 min |
| Kette 2 | Zug 5 wartet auf Zug 8, der Abschnitt 32 besetzt |
| Kette 3 | Zug 8 wartet auf Zug 6, der Abschnitt 33 besetzt |
| Kette 4 | Zug 6 wartet auf Zug 5, der Abschnitt 31 besetzt |
| Kette 5 (Wurzel) | Alle 3 warten aufeinander, keiner kann zuerst fahren |
| Vorschlag | Signal vor der Kreuzung setzen · Zug 6 umleiten |

Erwartete Wurzelursache: Die Züge blockieren sich im Kreis, jeder wartet auf den nächsten. Typ INFRASTRUKTUR, Code `KREIS_BLOCKIERUNG`, `kette_kreis=true`. Auf der Karte schließt die Linie zwischen den Markierungen den Kreis. **Annahme:** ein Kreis aus 3 Zügen an einer Kreuzung. Wenn Lena oder Felix 2 Züge auf einer Strecke bauen, ändert sich nur `{n}` und die Zeilenzahl.

Produktvariante Titel (nicht im Test): "Zug 5, 8 und 6 blockieren sich gegenseitig".

## Fehler 3: Warten auf Ladung

| Teil | Text |
|---|---|
| Meldung | **Zug 10 steht seit 2:10 min** · bei Hafen-Ost |
| Kette 1 | Zug 10 steht seit 2:10 min |
| Kette 2 | Wartet am Signal 21: Abschnitt 22 ist besetzt |
| Kette 3 | Zug 7 besetzt Abschnitt 22 |
| Kette 4 | Zug 7 wartet in Hafen-Ost auf Ladung (12/40) |
| Kette 5 (Wurzel) | Hafen-Ost bekommt zu wenig Ware: nur 1 Lkw liefern |
| Vorschlag | Lkw für Hafen-Ost hinzufügen · Mindestbeladung für Zug 7 senken |

Erwartete Wurzelursache: Das Lager wird nur von einem Lkw beliefert, darum füllt es sich zu langsam. "Zug 7 wartet auf Ladung" ist ein Zwischenglied, nicht die Wurzel. Typ LADUNG, Code `ZULIEFERUNG_ZU_GERING`.

## Glossar-Tooltips (Hover, einmal erklärt, nicht im Standardtext)

| Wort | Erklärung |
|---|---|
| Abschnitt | Streckenstück zwischen zwei Signalen. In einem Abschnitt darf nur ein Zug fahren. |
| Signal | Hält einen Zug an, bis der Abschnitt dahinter frei ist. |

## Längenprüfung

Alle 17 ausgefüllten Beispielzeilen (Ketten und Vorschläge) wurden mit einem Skript gezählt: längste Zeile 52 Zeichen, keine über 60. Das gilt nur für die Beispielwerte. Längere Namen aus Lenas Szenario müssen nachgeprüft werden.
