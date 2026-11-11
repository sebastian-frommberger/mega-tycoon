# Straßen- und Gleisbau in der Demo: Befund

Stand 11.11., Branch `s8-demo`. Kein Umbau, nur Befund mit je einem Vorschlag.

**Wie gemessen:** `slice/tests/demo_bau_befund.gd` spielt den Bau über den echten Eingabeweg durch: Mausbewegung, Mausklicks und Tasten laufen als Ereignisse durch den Viewport (1600 × 900, xvfb, opengl3), keine Bau-Funktion wird direkt gerufen. Jede Zahl unten stammt aus einer Zeile `BEFUND …` dieses Laufs. Bilder: `demo_shots/bau/`.

```
xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --path slice \
  -s res://tests/demo_bau_befund.gd -- --shots=<ordner>
```

**Nicht gemessen:** wie sich der Bau für einen Menschen an der Maus anfühlt (Tempo, Zielgenauigkeit, Frust). Das Skript zeigt, was das Spiel tut, nicht, was Basti dabei stört. Die Reihenfolge unten ist meine Einschätzung, keine Messung.

## Kurzfassung

Der Bau funktioniert, aber er hat zwei Klickregeln für dieselbe Geste, sagt vor dem ersten Klick nichts, markiert Fehler nicht an der Stelle und verknüpft kreuzende Straßen nicht. Das sind die vier Punkte, die ich zuerst angehen würde (1 bis 4).

| Nr. | Befund | Vorschlag |
|---|---|---|
| 1 | Klick auf ein Ziel baut sofort, Klick ins Freie braucht Enter | eine Regel: Klick setzt Punkte, Enter oder Doppelklick baut |
| 2 | Kreuzende Straßen sind nicht verbunden | an Kreuzungen und auf Kanten einen Knoten einfügen |
| 3 | Vor dem ersten Klick zeigt nichts, wo der Start einrastet | Einrast-Marke unter der Maus, auch ohne gesetzten Punkt |
| 4 | Fehler färbt die ganze Trasse rot, die Stelle bleibt unmarkiert | nur das betroffene Stück rot, Marke an der Stelle |
| 5 | See sperrt mehr, als man sieht | Sperrzone im Baumodus zeigen |
| 6 | Rechtsklick tut nichts, Esc verwirft alles | Rechtsklick nimmt den letzten Punkt zurück |
| 7 | Werkzeug geht nach jedem Bau aus | Werkzeug bleibt an, letzter Endpunkt ist neuer Start |
| 8 | Karte und Banner verdecken 12 % des Bildes | Karte schmal an den Rand, Zahlen an die Maus |
| 9 | Kosten stehen 444 px von der Maus entfernt | Länge und Preis als Schildchen an der Maus |
| 10 | Freies Ende wird ohne Warnung gebaut | Hinweis „verbindet noch nichts“ vor dem Bau |
| 11 | „Enter baut bis hierher“ steht da, Enter tut noch nichts | Text und Knopf an denselben Zustand binden |
| 12 | Vorschau eckig, gebaute Straße geglättet | Vorschau mit derselben Glättung zeichnen |
| 13 | Brücke sieht in der Vorschau aus wie Straße | Brückenstück eigene Farbe, Pfeiler andeuten |

Was gut funktioniert, steht am Ende.

## Die Befunde im Einzelnen

### 1 Zwei Regeln für denselben Klick (B4, B3)

- Maus 60 m neben dem Forsthaus: Ende „frei“. Maus 40 m daneben: Ende „betrieb“. Der Ring am Betrieb hat 18 m Radius, eingerastet wird im Umkreis von 45 m. Man rastet also ein, ohne im Ring zu sein.
- Der Klick auf ein einrastendes Ziel baut **sofort**: −500 $, „Straße gebaut: 487 m für 500 $. Forsthaus Rotwald ist angeschlossen.“ Keine Bestätigung.
- Der Klick ins freie Gelände setzt nur einen Punkt (4 Punkte, Modus bleibt an). Erst Enter baut.

Der Spieler kann nicht vorhersagen, ob sein Klick Geld ausgibt. In einem früheren Lauf dieses Skripts hat ein einzelner Klick auf einen Knoten eine 1.302 m lange Straße für 1.925 $ gebaut, weil noch ein Startpunkt aus einem anderen Bildausschnitt gesetzt war.

**Vorschlag:** Eine Regel wie in Transport Fever 2: Klicks setzen Punkte, gebaut wird mit Enter oder Doppelklick auf den letzten Punkt. Der Einrastkreis wird so groß gezeichnet, wie er wirkt.

Bilder: `b4_neben_dem_betrieb.jpg`, `b4_angeschlossen.jpg`

### 2 Kreuzende Straßen sind nicht verbunden (B10)

Trasse von einem Straßenknoten ins Gelände und dann quer über dieselbe Straße zu einem freien Punkt 80 m dahinter. Gebaut: 282 m für 300 $.

- Der gekreuzte Knoten hat vorher 2 und nachher 2 Anschlüsse.
- Vom neuen Ende zum gekreuzten Knoten sind es über das Netz 366 m statt 80 m.

Die Straßen liegen sichtbar übereinander, abbiegen kann dort kein Fahrzeug. Für den Spieler sieht das wie eine Kreuzung aus.

**Vorschlag:** Beim Bauen an jedem Schnitt mit einer eigenen oder öffentlichen Straße einen Knoten einfügen. Das ist ein Eingriff in den Netzgraphen (`core/net_graph.gd`, Kanten teilen) und berührt den Determinismus-Pfad; vorher Aufwand und Parität prüfen.

Bilder: `b10_kreuzung_vorschau.jpg`, `b10_kreuzung_gebaut.jpg`

### 3 Vor dem ersten Klick zeigt nichts, wo man anfangen kann (B1)

- Das Straßennetz ist dicht mit Knoten besetzt: 0 von 4.776 m liegen weiter als 22 m vom nächsten Knoten. Man kann also praktisch überall auf einer Straße beginnen. Das ist gut.
- Aber: Vor dem ersten Klick ist unter der Maus nichts zu sehen (Vorschau: nein, Hover: nein). Ringe gibt es nur an den 4 Betrieben ohne Anschluss.

Der Spieler erfährt erst nach dem Klick, ob er getroffen hat. Daneben geklickt heißt: Meldung „Die Trasse hängt in der Luft“.

**Vorschlag:** Im Baumodus folgt der Maus eine Einrast-Marke: gefüllter Punkt auf dem Knoten, wenn eingerastet würde, hohler Kreis mit Hinweis, wenn nicht. Dieselbe Marke zeigt freie Straßenenden (B4b: Weiterbauen am freien Ende geht, das Ende trägt aber kein Zeichen).

Bild: `b1_start_mitten_auf_der_strasse.jpg`

### 4 Fehler färben die ganze Trasse, die Stelle bleibt unmarkiert (B8, B2b)

- Gleis mit engem Knick: „Der Knick ist zu eng für ein Gleis (165°, erlaubt 60°). Setze die Punkte in einem weiteren Bogen.“ Der Text ist gut. Die Vorschau färbt aber die ganze Trasse rot.
- Dasselbe beim See (Befund 5): Dort liefert die Sim die Stelle sogar mit (Feld `bei`), die Oberfläche zeigt sie nicht. Steigung habe ich nicht durchgespielt.

**Vorschlag:** Nur das betroffene Teilstück rot, der Rest grün; an der Stelle eine Marke mit dem Grund in zwei Wörtern („zu eng“, „zu steil“, „See“).

Bild: `b8_gleis_knick_zu_eng.jpg`

### 5 Der See sperrt mehr, als man sieht (B2b)

Eine Z-Trasse neben dem Teich wird mit „Hier liegt ein See“ abgelehnt. Die gemeldete Stelle liegt 79 m vom Seemittelpunkt; gesperrt ist ein Kreis von 84 m (Nennradius 75 m plus 12 % Rand). Der gezeichnete See ist kein Kreis. Wo die Sperre beginnt, ist nicht zu sehen.

**Vorschlag:** Im Baumodus die Sperrzone als feine Linie um stehende Gewässer zeichnen. Oder den Rand von 12 % auf das sichtbare Ufer zurücknehmen.

Bild: `b2b_see_sperrzone.jpg`

### 6 Rechtsklick tut nichts, Esc verwirft alles (B6)

3 Punkte gesetzt. Rechtsklick: weiter 3 Punkte, die rechte Taste dreht nur die Kamera. Rücktaste oder Entf nimmt einen Punkt zurück (2). Esc verwirft alle Punkte auf einmal und beendet das Werkzeug, ohne Rückfrage.

**Vorschlag:** Rechtsklick ohne Ziehen nimmt den letzten Punkt zurück, beim letzten Punkt beendet er das Werkzeug (so in Transport Fever 2 und den meisten Aufbauspielen). Ziehen mit rechts dreht weiter die Kamera. Esc bleibt der Not-Aus.

Bild: `b6_vor_abbrechen.jpg`

### 7 Das Werkzeug geht nach jedem Bau aus (B9)

Nach dem Bau: Modus leer, Banner weg. Für jeden weiteren Abschnitt muss B erneut gedrückt werden.

**Vorschlag:** Das Werkzeug bleibt an, der letzte Endpunkt ist der neue Startpunkt. Esc oder Rechtsklick beendet. Das Banner sagt es („Weiterbauen oder Esc“).

### 8 Karte und Banner verdecken Bauland (B12)

Die Karte „Straße bauen“ (620 × 211 px) und das Banner (696 × 63 px) belegen zusammen 12,1 % des Bildes, die Karte unten in der Bildmitte. Ein Klick auf einen Straßenknoten, der unter der Karte liegt, kommt in der Welt nicht an (Punkte danach: 0). Das Banner ist mit dem Umbau vom 11.11. neu dazugekommen und verschärft das.

**Vorschlag:** Die Karte schrumpft auf eine Zeile am unteren Rand oder wandert in die linke Spalte; die Zahlen kommen an die Maus (Befund 9). Das Banner bleibt, es ist die Modusanzeige.

Bild: `b12_karte_verdeckt.jpg`

### 9 Kosten stehen weit weg von der Maus (B11)

Länge und Preis stehen nur in der Karte unten (Mitte bei 850, 795 px). Die Maus arbeitet im Beispiel bei 649, 399 px: 444 px Blickweg. An der Maus steht nichts.

**Vorschlag:** Ein kleines Schild an der Maus: Länge, Preis, bei Brücken die Brückenlänge. Rot mit Grund, wenn es nicht geht.

Bild: `b11_information_weit_weg.jpg`

### 10 Ein freies Ende wird ohne Warnung gebaut (B3)

Enter baut eine Straße, die an nichts endet: 322 m für 325 $, Meldung „Straße gebaut“. Vorher kein Hinweis, dass sie nichts verbindet. Das abschnittsweise Bauen ist gewollt und funktioniert (B4b), nur weiß der Spieler nicht, ob er gerade einen Abschnitt oder einen Fehler baut.

**Vorschlag:** In der Vorschau am freien Ende ein Zeichen und der Satz „Endet frei: verbindet noch nichts“.

Bild: `b3_freies_ende_gebaut.jpg`

### 11 „Enter baut bis hierher“, aber Enter tut nichts (B5b)

Solange der Endpunkt nur unter der Maus liegt und nicht geklickt ist, zeigt die Karte den Satz „Enter baut bis hierher“ und zugleich den Knopf „Bauen · Enter“ in Grau. Enter tut in diesem Moment nichts.

**Vorschlag:** Den Satz erst zeigen, wenn Enter wirkt. Oder Enter übernimmt den Punkt unter der Maus.

Bild: `b5_bruecke_vorschau.jpg`

### 12 Vorschau eckig, gebaute Straße geglättet (B2)

Eine Spitzkehre von 150° wird für Straßen angenommen (322 m, 325 $). Straßen kennen keine Mindestkurve, Gleise 60°. Die Vorschau ist ein eckiger Linienzug, der gebaute Weg wird danach geglättet und liegt anders.

**Vorschlag:** Die Vorschau mit derselben Glättung zeichnen wie der Bau (`proto_strassenband.gd`, Bogenradius 15 m).

Bild: `b2_knick_spitzkehre.jpg`

### 13 Die Brücke sieht in der Vorschau aus wie Straße (B5)

Trasse über den Fluss: 260 m, davon 80 m Brücke, 675 $ (ohne Wasser 275 $, Brückenfelder kosten das Fünffache). In der Vorschau ein Band in einer Farbe; die Brückenlänge steht nur als Zahl in der Karte.

Geprüft und **nicht** bestätigt: dass das Vorschauband im Fluss unter dem Wasserspiegel verschwindet (0 von 16 Stützpunkten im Wasser liegen darunter).

**Vorschlag:** Das Brückenstück in eigener Farbe mit angedeuteten Pfeilern, der Preis der Brücke am Brückenstück.

Bilder: `b5_bruecke_vorschau.jpg`, `b5_bruecke_gebaut.jpg`

## Was funktioniert

- **Kamera beim Bauen (B7):** Ziehen mit der linken Taste (140 px) schiebt die Kamera um 73 m und setzt keinen Punkt (2 → 2). Mausrad zoomt (432 → 491 m). Die Taste D schiebt. Der Baumodus bleibt an, die Vorschau folgt der Maus danach wieder. Einschränkung: Solange die linke Taste gehalten wird, steht die Vorschau still.
- **Start auf der Straße (B1):** praktisch überall möglich, siehe Befund 3.
- **Gleis (B8):** Taste G, 16 Ringe an Betrieben und Orten. Der Klick auf die Kohlegrube rastet 12 m neben dem Klick ein und legt einen Bahnhof an. Gerade zur Hütte: 696 m für 1.400 $, zwei Bahnhöfe.
- **Fehlertexte:** nennen Ursache und nächsten Schritt.
- **Modusanzeige:** Seit dem 11.11. steht in jedem Baumodus das Banner oben mittig und zählt die Punkte mit; Esc beendet jeden Modus (`demo_ui_test.gd`, Prüfung A16).

## Wie es weitergehen könnte

Befunde 1, 3, 4, 6, 7, 9, 10, 11 sind reine Oberfläche (`slice/proto/ui_demo.gd`) und berühren die Sim nicht. Befund 2 greift in den Netzgraphen ein und braucht eine eigene Prüfung auf Parität. Befund 5 und 12 liegen dazwischen.
