# Bastis Feedback nach dem ersten Rundgang durch die S7-Welt (02.11.2026, 21:11)

Bilder in `bilder/` (01 Lkw-Block neben Häusern, 02 Straßenstücke mit Fugen, 03 Zickzack-Straße, 04 Industrien nah, 05 Gebirge, 06 Fluss/Farm/Mühle, 07 Bahnhofsgebäude, 08 Wohnblock Weidenau, 09 Stadt aus der Ferne).

## Wortlaut (unverändert)
* Die Straßenführung ist noch recht seltsam. Außerdem schließen die Tiles nicht bündig miteinander ab.
* Die Proportionen sind noch sehr off. Der schwarze Block soll ja glaube ich ein LKW sein und der ist gigantisch im Vergleich zu den Häusern.
* Die Industrien sind völlig zu groß geraten im Vergleich zu Häusern und Straßen.
* Die Städte wirken wie bereits gesagt zu geometrisch und auch in den Häuserquadraten ist einfach nichts los. Hier sollte vielleicht insgesamt überlegt werden:
  * Welche „Größen“ von Häusern gibt bzw. wie viele Menschen wohnen in so einem Haus. Daraus würde sich auch gut die Anzahl ableiten lassen. Auch sollte bedacht werden, dass Städte in diesen Spielen häufig einfach automatisch wachsen und z. B. größere Häuser aus kleinen entstehen oder auch Straßen von „der Stadt-KI“ angelegt werden.
* Die Industrien finde ich mit den farbigen Icons gut lesbar, müsste aber nicht komplett auf die Industrie angewandt werden (also rotes Icon, klar, aber das Gebäude muss jetzt nicht auch komplett rot sein).
* Die Berge wirken erst einmal recht schön und organisch, aber dann doch wieder zu organisch. Da vielleicht ein bisschen das Noise im Seed runterdrehen (nehmen an so wurde das gemacht?).
* Die Städte sind insgesamt zu groß. Nehmen wir an, wir starten im frühen 19. Jahrhundert, dann haben wir i. d. R. eher kleinere Dörfer.
* Die Anordnung wirkt nach wie vor sehr stark konstruiert und etwas zu stark zusammengewachsen.
* Das Gelände ist noch sehr uniform, kaum wahrnehmbare Unterschiede im Boden oder auch in Höhen und Tiefen.
* Das Wasser ist vielleicht unterproportional.

Vorschlag Basti: eine Art **Design Sprint mit zusätzlichen Rollen**: Design Principles, Definition von Scale, insgesamt Design-Regeln der Welt, „was es eben für so ein Spiel festgelegt wird“.

## Einordnung (Jonas/Katrin)
| # | Punkt | Art | Ursache im Stand S7 | Wohin |
|---|---|---|---|---|
| 1 | Straßenführung seltsam, Kacheln nicht bündig | Fehler | Gezogene Diagonalen werden zu Zickzack-Treppen (Daniel M5), Kachelkanten/Bordsteine schließen an den Übergängen nicht ab | W-04b (Wegführung glätten, Kachelnähte) |
| 2 | Lkw-Block riesig | Fehler | Fahrzeug-Meshes noch im Maßstab des alten Slice (10 m/Feld), Welt ist 25 m/Feld | Scale-Pass |
| 3 | Industrien zu groß | Fehler + Regel | Modelle im alten Maßstab, Signalfläche 150–300 m (Spike-Wert) | Scale-Pass, Industrie-Footprint-Tabelle |
| 4 | Städte geometrisch, Blöcke leer | Design | Generator: ein Raster, gleiche Rautenform, Blöcke nur teilweise bebaut | Stadtmodell (Haustypen, Einwohner je Haus, Wachstum, Stadt-KI) |
| 5 | Industrie nicht komplett farbig | Look | Signalflächen/Pads tönen das ganze Gebäude | Marker: nur Icon und Name farbig, Fläche neutral |
| 6 | Berge zu organisch | Parameter | Rauschen im Generator (`tools/world_gen.py`) | Landschaftsregeln, Parameter runter |
| 7 | Städte insgesamt zu groß (frühes 19. Jh.) | Design | Radien/Einwohner aus Spike SP-03 und Railway Empire | Epoche und Skalen-Tabelle |
| 8 | Anordnung konstruiert, zu zusammengewachsen | Design | Lage-Regeln erzeugen Reviere und Pärchen (Daniel M1) | Verteilungsregeln |
| 9 | Gelände uniform | Design | Einheitsgrün, wenig Relief außer Nordwesten | Biome/Bodenvariation, Reliefstufen |
| 10 | Wasser unterproportional | Parameter | Flussbreite ≤ 8 Felder an Brücken, sonst schmal | Landschaftsregeln |

## Offene Folgen aus der Epochenannahme „frühes 19. Jahrhundert“
Betrifft Fahrzeuge (Lkw existiert nicht, Fuhrwerk statt Lkw), Gebäudestile (Kenney City Kit ist modern, Bahnhofsbild 07 zeigt moderne Gewerbebauten), Industrien (Mühle, Schmiede statt Werkzeugfabrik/Kraftwerk), Skalen (Dorf 100–300 Einwohner, Stadt 2.000–10.000). Das ist keine Detailfrage, sondern eine Grundsatzentscheidung für das Design-Regelwerk.
