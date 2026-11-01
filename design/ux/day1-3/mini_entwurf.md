# Grauer Mini-Entwurf: Meldung, Kette als Liste, Sprung zur Karte (A-05)

Autorin: Aylin Kaya · Entwurf v0.1 · Kein Figma verfügbar. **Dieses Dokument ist die Quelle**, es ist so beschrieben, dass Felix es in Godot-Control-Nodes nachbauen kann. Eine Figma-Version ist Restaufwand von 0,5 T, sobald Zugang besteht. Daten: `diagnose_datenvertrag.md`, Texte: `textvorlagen_testfehler.md`.

Zweck: Der Playtest soll die **Auffindbarkeit der Ursache** messen, nicht ein Debug-Log. Darum drei Dinge, die ein Log nicht kann: Meldung als Einstieg, Kette als anklickbare Liste, Sprung der Kamera zum Ort.

## Priorität (Felix hat 1 T für F-06)

| Stufe | Inhalt |
|---|---|
| **Muss** | Meldungsliste, Klick öffnet die Kette als Liste, Klick auf Kopf oder Zeile springt die Kamera zum Ort, aktuelles Objekt auf der Karte mit Kontur markiert, UI-Klick-Log |
| **Soll** | Nummerierte Markierungen an allen Kettengliedern auf der Karte, gestrichelte Linie dazwischen, Vorschlag als Text, Knopf "Zurück zur Übersicht" |
| **Kann** | Rest der Karte abdunkeln, Klick auf den stehenden Zug in der Welt öffnet dessen Meldung |

Muss-Teil ohne Soll ist testbar. Die Reihenfolge zum Streichen ist von unten nach oben.

## Grau-Palette und Maße (Annahme, bis der Styleguide mit Sophie existiert)

Raster 8 px. Kein Farbton, keine Statusfarben: S-05 liefert sie später, der Testbuild bleibt grau.

| Token | Wert | Nutzung |
|---|---|---|
| `bg_panel` | `#2B2B2B` | Panelfläche |
| `bg_row` | `#383838` | Meldungszeile |
| `bg_row_hover` | `#454545` | Hover |
| `bg_selected` | `#F0F0F0` mit Text `#1A1A1A` | gewählte Kettenzeile |
| `border_selected` | `#F0F0F0`, 2 px | geöffnete Meldung |
| `text_main` / `text_dim` | `#F0F0F0` / `#A8A8A8` | Haupt- und Nebentext |
| `root_mark` | `#F0F0F0` Fläche, Text `#1A1A1A` | Wurzelursache |

Kontraste nach WCAG-Formel gerechnet (nicht im Spiel gemessen): `text_main` auf `bg_panel` 12,4:1, `text_main` auf `bg_row` 10,3:1, `text_dim` auf `bg_row` 4,9:1 (knapp über 4,5, der Untertitel darf nicht auf hellerem Grund stehen), gewählte Zeile 15,3:1. Schrift: Standardschrift der Engine, **16 px Fließtext bei 1080p**, Meldungstitel 18 px fett, Untertitel 14 px. Bei 720p nie unter 14 px.

## Bildschirm 1920×1080

```
 0                                                              1920
 +----------------------------------------------------------------+
 |                                                                |
 |            K A R T E  (Vollbild, Spielwelt)                    |
 |                                                  +-----------+ |
 |        (4) o----(3) o- - -(2) o- - -(1) O        |  FEED     | |
 |             Markierungen und Linie               |  Panel    | |
 |             nur bei geöffneter Meldung           |  400 x    | |
 |                                                  |  bis 1008 | |
 |                                                  +-----------+ |
 +----------------------------------------------------------------+
   Feed: x 1496 bis 1896, y 72 bis 1008, Rand 24 px zum Bildrand
```

**1280×720:** Panel 320 px breit (x 936 bis 1256, y 48 bis 672), Schrift nicht kleiner als 14 px. Mindestens 41 Zeichen je Zeile, 60 Zeichen brechen auf 2 Zeilen um.

## Zustand 1: Liste (nichts gewählt)

```
+------------------------------------------+
| MELDUNGEN                          3  [-]|  Kopf, 48 px hoch
+------------------------------------------+
| #  Zug 4 steht seit 2:10 min          >  |  Zeile 72 px
|    bei Strecke Mühlbach–Kornfeld         |
+------------------------------------------+
| #  Zug 5 steht seit 1:40 min          >  |
|    bei Kreuzung Südfeld                  |
+------------------------------------------+
| #  Zug 10 steht seit 2:10 min         >  |
|    bei Hafen-Ost                         |
+------------------------------------------+
```

- `#` ist ein grauer Block 12×12 px (Schweregrad-Platz, im Test für alle gleich).
- Titel 18 px fett, Untertitel 14 px `text_dim`. Pfeil `>` zeigt "aufklappbar".
- Der Feed ist im Test **offen** gestartet. Das Auffinden des Feeds ist nicht Teil der Messung.
- Leerer Feed: Text "Keine Probleme." (nur Vorsorge, im Test nicht sichtbar).
- Die Reihenfolge in der Liste ist fest (nach `meldung_id`), nicht nach Fehlertyp sortiert, damit die Position nichts verrät.

## Zustand 2: Meldung geöffnet, Kette als Liste

```
+------------------------------------------+
| MELDUNGEN                          3  [-]|
+==========================================+  Rahmen 2 px = geöffnet
| #  Zug 4 steht seit 2:10 min          v  |
|    bei Strecke Mühlbach–Kornfeld         |
|  +------------------------------------+  |
|  | WARUM?                  Stand 12:04|  |  Stand = Spielzeit des Schnappschusses
|  | 1  Zug 4 steht seit 2:10 min     > |  |  Zeile min. 40 px, ganze Zeile klickbar
|  | 2  Wartet am Signal 12: Abschnitt  |  |
|  |    13 ist besetzt                > |  |
|  | 3  Zug 2 besetzt Abschnitt 13 und  |  |
|  |    fährt entgegen                > |  |
|  | 4  [WURZELURSACHE]                 |  |  letzte Zeile, hell hinterlegt
|  |    Mühlbach–Kornfeld hat nur ein   |  |
|  |    Gleis (14 Felder)             > |  |
|  +------------------------------------+  |
|  | VORSCHLAG                          |  |
|  | - Ausweichgleis auf Mühlbach–      |  |
|  |   Kornfeld bauen                   |  |
|  +------------------------------------+  |
|  [ Zurück zur Übersicht ]                |  Knopf, 40 px hoch
+------------------------------------------+
| #  Zug 5 steht seit 1:40 min          >  |
```

Regeln:
1. Es ist immer höchstens **eine** Meldung offen. Öffnen einer anderen schließt die erste.
2. Die Kette erscheint sofort beim Öffnen, keine zweite Klickstufe. Der Sprung ist der erste Schritt, nicht ein Zwischenschritt.
3. Zeilen sind nummeriert (1 bis n). Die Nummer erscheint auch auf der Karte (Zustand 3).
4. Die Wurzelzeile trägt das Label `WURZELURSACHE` und hebt sich durch helle Fläche ab. Im Kreis (Fehler 2) steht unter Zeile n ein Hinweis `< zurück zu 1` als Textzeile in `text_dim`, kein eigener Klick.
5. Vorschlag ist im Test **reiner Text**, nicht klickbar (Annahme, Frage an Lena/Jonas unten).
6. Mehr als 6 Zeilen: das Panel scrollt innen, Kopf und "Zurück" bleiben sichtbar.

## Zustand 3: Zeile gewählt, Karte

```
 Karte (Ausschnitt):

        (1) O- - - - (2) o- - - - (3) o- - - - [4]
        Zug 4        Signal 12    Zug 2       Strecke
        (Kontur)     (Kontur)     (Kontur)    Mühlbach–Kornfeld
                                              (gewählt: dicker Rand,
                                               Kamera hier)
```

- **Markierungen** (Soll): kleine Scheiben 24 px mit der Zeilennummer an jedem Kettenglied. Symptom = Ring (innen leer), Zwischenglied = graue Scheibe, Wurzel = Quadrat mit gerundeten Ecken. Formen sind nur Platzhalter und müssen mit Sophies S-05-Formen (Kreis/Dreieck/Achteck für Zustand) nicht kollidieren.
- **Linie** (Soll): gestrichelt, 2 px, in Kettenreihenfolge. Im Kreis schließt sie zurück zu Glied 1.
- **Gewähltes Objekt** (Muss): weiße Kontur 3 px, pulsiert zweimal.
- Rest der Karte abdunkeln auf 40 % (Kann).
- Markierungen bleiben sichtbar, solange die Meldung offen ist. Schließen der Meldung entfernt sie.
- Markierungen werden nicht von Gebäuden verdeckt: sie liegen in der obersten Ebene mit Mindestgröße unabhängig vom Zoom.

## Interaktion

| Auslöser | Reaktion |
|---|---|
| Klick auf Meldungskopf (geschlossen) | Meldung öffnet, Kette sichtbar, Kamera fährt zu `ort.pos` (Glied 1), Glied 1 mit Kontur und Markierung |
| Klick auf Meldungskopf (offen) | Meldung schließt, Markierungen weg, Kamera bleibt |
| Klick auf Kettenzeile i | Zeile invertiert (`bg_selected`), Kamera fährt zu `kette[i].pos`, Objekt mit Kontur, Markierung i hervorgehoben (groß 32 px) |
| Klick auf "Zurück zur Übersicht" | Kamera fährt zur Position vor dem ersten Sprung, Meldung schließt |
| Hover Zeile | `bg_row_hover`, Cursor Hand |
| Klick Zeile ohne `pos` | Zeile bleibt, ohne Pfeil, Vertragsfehler ins Log (soll nicht vorkommen) |
| Klick auf [-] | Feed klappt zu: Zähler "3" im Kopf bleibt als Badge am Rand |

**Kamerafahrt (Annahme):** 0,6 s weiche Bewegung, Zoom auf die Stufe, in der Abschnitte sichtbar sind (Regel der Zoomstufen von Sophie steht aus). Die Fahrt darf einen Klick auf eine andere Zeile unterbrechen.

## UI-Klick-Log (Muss, für die Messung)

Eine Zeile je Ereignis, Zeitstempel in ms seit Szenenstart plus Sim-Tick: `meldung_geoeffnet(id)` · `zeile_klick(meldung, index)` · `sprung_zurueck` · `meldung_geschlossen` · `klick_sonstige(ziel)`, dabei ist `ziel` = `karte_leer`, `karte_objekt(id)` oder `ui(name)`. Der Replay allein reicht nicht, er enthält nur Sim-Befehle. Das Log liefert `t_klick` für die Messgröße (Quelle für den Abgleich mit der Video-Zeit).

## Nachbau-Vorschlag Godot (nur Knotentypen)

```
FeedPanel (PanelContainer)
  VBoxContainer
    Kopf (HBoxContainer): Label "MELDUNGEN", Label Zähler, Button [-]
    ScrollContainer
      Liste (VBoxContainer)
        MeldungItem (Szene, je Meldung)
          VBoxContainer
            KopfButton (Button, toggle_mode): zwei Labels Titel + Untertitel
            Detail (VBoxContainer, standardmäßig unsichtbar)
              KettePanel (PanelContainer) -> VBoxContainer
                ZeilenButton (Button) je Glied
              VorschlagPanel (PanelContainer) -> Label je Vorschlag
              ZurueckButton (Button)
KartenMarkierungen (Node3D): je Glied ein Billboard mit Zahl, plus Linie
```

Die Szenenstruktur ist ein Vorschlag, die Umsetzung entscheidet Felix.

## Offene Fragen zum Entwurf

1. **Felix:** Kamerasprung und Konturmarkierung in 1 T machbar? Was fällt zuerst raus (siehe Prioritätstabelle)?
2. **Lena und Jonas:** Vorschlag als Text im Test zeigen? Er kann die Ursache verraten ("Ausweichgleis bauen"). Ich empfehle zu zeigen, weil "Ort, Ursache, Vorschlag" zum USP gehört, und die Zählregel verlangt die benannte Ursache, nicht den Vorschlag.
3. **Sophie:** Kollidieren die Markierungsformen mit S-05?
4. **Daniel:** Reicht das Log-Format für die Protokollvorlage (D-04, L-06)?
