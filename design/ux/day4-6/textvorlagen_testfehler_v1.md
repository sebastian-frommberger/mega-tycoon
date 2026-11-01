# Textvorlagen für die 3 Testfehler, v1 (A-05, nach D11)

Autorin: Aylin Kaya · Stand 19.11.2026 · ersetzt `day1-3/aylin/textvorlagen_testfehler.md`.

Was sich gegenüber v0.1 ändert:
1. **D11:** Alle drei Meldungstitel sind `T_STEHT` ("Zug X steht seit …"). Der Produkttitel für den Kreis ist nur dokumentiert (Abschnitt 5), nicht im Build.
2. **D11:** Der Vorschlag ist im Testbuild **ausgeblendet**. Die `V_*`-Vorlagen bleiben für das Produkt stehen; Fragebogen-Frage F6 entfällt (siehe Testskript).
3. **D9:** Die Schlüssel sind reine Textschlüssel der UI, zugeordnet über `root_cause` (siehe `diagnose_datenvertrag_v1.md`, Abschnitt 3). Es gibt keine eigenen Ursache-Codes mehr.
4. **Lena:** Fehler 2 hat 4 Züge (Felix' S2), 6 Zeilen.
5. Streckenlänge bleibt in **Feldern**: Felix liefert seit 19.11. `params.strecke_felder` (1 Feld = 10 m, `FELD_MM`). Gezählt wird die umkämpfte Strecke, nicht die ganze eingleisige Strecke.
6. `R_LADUNG` schreibt "(12 von 40)" statt Lenas "(12/40)", weil `fuell_soll` die Abfahrmenge des Zugs ist und ein Schrägstrich wie ein Bruch oder Datum gelesen werden kann. Wortänderung, Lena zeichnet gegen.

Namen und Zahlen sind weiterhin Platzhalter aus Lenas Tabelle (Abschnitt 2 ihres Szenarios), bis der F-06-Build sie festschreibt.

## 1. Schreibregeln (unverändert)

Spielersprache, ein Gedanke pro Zeile · keine IDs oder Codes im Text · "Abschnitt" statt "Block", "besetzt" statt "Reservierung", "Deadlock" nur im Tooltip · je Kettenzeile höchstens 60 Zeichen, höchstens 2 Zeilen im 400-px-Panel · Zeit als `m:ss min` · genau eine Zeile trägt das Label **Wurzelursache**, immer die letzte.

## 2. Platzhalter

`{zug}` Zugname · `{zug2}` zweiter Zug · `{signal}` Signalnummer · `{abs}` Abschnittsnummer · `{dauer}` Stillstandsdauer · `{strecke}` Streckenname · `{felder}` Länge in Feldern · `{lager}` Lagername · `{ist}`/`{soll}` Füllstand und Abfahrmenge · `{n}` Anzahl Lkw oder Züge · `{ort}` Ortsname

## 3. Vorlagen

| Schlüssel | Text | Verwendung | Im Testbuild |
|---|---|---|---|
| `T_STEHT` | `{zug} steht seit {dauer}` | Meldungstitel (alle drei Fehler, D11) und Kettenzeile 1 | ja |
| `T_ORT` | `bei {ort}` | Untertitel | ja |
| `R_SIGNAL` | `Wartet am Signal {signal}: Abschnitt {abs} ist besetzt` | Zwischenglied | ja |
| `R_HALTER` | `{zug2} besetzt Abschnitt {abs}` | Zwischenglied | ja |
| `R_HALTER_GEGEN` | `{zug2} besetzt Abschnitt {abs} und fährt entgegen` | Zwischenglied, Gegenrichtung | ja |
| `R_WARTET_ZUG` | `{zug} wartet auf {zug2}, der Abschnitt {abs} besetzt` | Zwischenglied im Kreis | ja |
| `R_LADUNG` | `{zug} wartet in {lager} auf Ladung ({ist} von {soll})` | Zwischenglied | ja |
| `W_EINGLEISIG` | `{strecke} hat nur ein Gleis ({felder} Felder)` | Wurzel, `EINGLEISIG_GEGENVERKEHR` | ja |
| `W_KREIS` | `Alle {n} warten aufeinander, keiner kann zuerst fahren` | Wurzel, `DEADLOCK` | ja |
| `W_ZULIEFERUNG` | `{lager} bekommt zu wenig Ware: nur {n} Lkw liefern` | Wurzel, `WARTEN_AUF_LADUNG` | ja |
| `K_ZURUECK` | `< zurück zu Zeile 1` | Hinweiszeile unter der Kette im Kreis, nicht klickbar | ja |
| `V_AUSWEICH` | `Ausweichgleis auf {strecke} bauen` | Vorschlag Produkt | **nein (D11)** |
| `V_KREUZUNG` | `Signal vor der Kreuzung setzen` | Vorschlag Produkt | **nein** |
| `V_ZUG_UMLEITEN` | `{zug} umleiten` | Vorschlag Produkt | **nein** |
| `V_LKW` | `Lkw für {lager} hinzufügen` | Vorschlag Produkt | **nein** |
| `V_MINDESTLADUNG` | `Mindestbeladung für {zug} senken` | Vorschlag Produkt | **nein** |
| `E_LEER` | `Keine Probleme.` | leerer Feed | ja (Vorsorge) |

Bei `{n} = 1` in `W_ZULIEFERUNG` heißt es "nur 1 Lkw liefert" (Singular-Regel in der UI, kein zweiter Schlüssel).

## 4. Die drei Fehler, ausgefüllt (Platzhalterwerte)

### Fehler 1: Gegenverkehr eingleisig (`EINGLEISIG_GEGENVERKEHR`)

| Teil | Text |
|---|---|
| Meldung | **Zug 4 steht seit 2:10 min** · bei Strecke Mühlbach–Kornfeld |
| 1 | Zug 4 steht seit 2:10 min |
| 2 | Wartet am Signal 12: Abschnitt 13 ist besetzt |
| 3 | Zug 2 besetzt Abschnitt 13 und fährt entgegen |
| 4 (Wurzel) | Mühlbach–Kornfeld hat nur ein Gleis (14 Felder) |

Sprungziel der Wurzelzeile: `root_pos` = Mitte der umkämpften Abschnitte (Felix `cycle_root`). "14 Felder" ist Lenas Platzhalter; der Spike S1 liefert 40.

### Fehler 2: Deadlock-Kreis, 4 Züge (`DEADLOCK`)

| Teil | Text |
|---|---|
| Meldung | **Zug 5 steht seit 1:40 min** · bei Kreuzung Südfeld |
| 1 | Zug 5 steht seit 1:40 min |
| 2 | Zug 5 wartet auf Zug 8, der Abschnitt 32 besetzt |
| 3 | Zug 8 wartet auf Zug 6, der Abschnitt 33 besetzt |
| 4 | Zug 6 wartet auf Zug 9, der Abschnitt 34 besetzt |
| 5 | Zug 9 wartet auf Zug 5, der Abschnitt 31 besetzt |
| 6 (Wurzel) | Alle 4 warten aufeinander, keiner kann zuerst fahren |
| darunter | < zurück zu Zeile 1 |

Die Kartenlinie schließt den Kreis zwischen den vier Markierungen.

### Fehler 3: Warten auf Ladung (`WARTEN_AUF_LADUNG`)

| Teil | Text |
|---|---|
| Meldung | **Zug 10 steht seit 2:10 min** · bei Hafen-Ost |
| 1 | Zug 10 steht seit 2:10 min |
| 2 | Wartet am Signal 21: Abschnitt 22 ist besetzt |
| 3 | Zug 7 besetzt Abschnitt 22 |
| 4 | Zug 7 wartet in Hafen-Ost auf Ladung (12 von 40) |
| 5 (Wurzel) | Hafen-Ost bekommt zu wenig Ware: nur 1 Lkw liefert |

Die Wurzelzeile braucht `n_lkw`; der Spike liefert es seit 19.11. (`params.n_lkw`, S3 mit echtem Lkw-Zulieferer).

## 5. Nur dokumentiert, nicht im Test (D11)

| Fehler | Produkttitel |
|---|---|
| 2 | "Zug 5, 8, 6 und 9 blockieren sich gegenseitig" |
| 1, 3 | wie `T_STEHT`, im Produkt mit Schweregrad-Form (S-05) |

Der Vorschlag erscheint im Produkt als eigener Block unter der Kette, mit den `V_*`-Vorlagen aus Abschnitt 3.

## 6. Glossar-Tooltips (Hover, unverändert)

| Wort | Erklärung |
|---|---|
| Abschnitt | Streckenstück zwischen zwei Signalen. In einem Abschnitt darf nur ein Zug fahren. |
| Signal | Hält einen Zug an, bis der Abschnitt dahinter frei ist. |

## 7. Längenprüfung

Alle 16 ausgefüllten Zeilen aus Abschnitt 4 wurden am 19.11. mit einem Skript gezählt (`laengen_check.py` daneben): längste Zeile 52 Zeichen ("Alle 4 warten aufeinander, keiner kann zuerst fahren"), keine über 60. Das gilt nur für die Platzhalterwerte; längere Namen aus dem Build müssen nachgeprüft werden. Eine Prüfung im Spiel-Panel mit echter Schrift gab es nicht.
