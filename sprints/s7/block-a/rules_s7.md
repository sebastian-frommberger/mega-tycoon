# rules_s7: Lage-Regeln und Stadtstufen (Lena, S7 Block A)

Daten: `rules_s7.json`. Einheit: 1 Feld = 25 m, 40 Felder = 1 km. Zahlen immer Felder (Sim) mit Metern daneben. Ketten und Ökonomie bleiben in Feldern, nur die Anzeige ist Meter.

## Industrie (Regeln 1-8)
Je aktivem Typ 3-6 Instanzen, gesamt >= 20 (7 aktive Typen = 21-42). Jede Industrie hält >= 12 Felder (300 m) Abstand zu jeder anderen und steht nie in der Stadtfläche (Abstand >= Stadtradius + 6 Felder).

| Regel | Inhalt (Felder / m) | Begründung und Bezug |
|---|---|---|
| R1 Farm | Ebene oder Aue (>= 50 % Aue), Umfeld < 3 %, 0-250 m Höhe, 12+ Felder (300 m) vom Flussbett, 30-160 Felder (0,75-4 km) von der nächsten Stadt | Farmen liegen im Flusstal, nie am Hang. TF2: Stadt-Industrie-Distanzen 1-4 km, RE: Felder in der Ebene. |
| R2 Mühle | Flussnähe (<= 8 Felder) oder Stadtrand, Umfeld < 3 %, 40-80 Felder (1-2 km) von der nächsten Stadt | Mühle am Wasser oder am Ort, nah genug für Mehl, fern genug vom Dorfkern. Wie RE-Mühlen am Fluss. |
| R3 Kohle/Erz | Gebirgsfuß (Umfeld 8-20 %, 120-600 m), 40-160 Felder (1-4 km) von jeder Stadt, Kohle und Erz 36-60 Felder (0,9-1,5 km) auseinander | Bergbau steht, wo das Gebirge anfängt. Kohle-Erz-Abstand ist durch Stahlwerk-Band (15-30) nach oben begrenzt. TF2: Rohstoffe abseits der Städte. |
| R4 Stahlwerk/Kraftwerk | Ebene im Vorland (Umfeld < 4 %), nie im Gebirge/Meer, Stahlwerk 30-160, Kraftwerk 30-120 Felder von der Stadt | Schwerindustrie braucht Platz im Flachland nahe der Kohle (Band 15-30 Felder, Kraftwerk-Stahlwerk <= 25 wegen Energie-Radius). |
| R5 Werkzeugfabrik | Ebene oder Stadtrand, 30-80 Felder (0,75-2 km) von einer Stadt ab Kleinstadt, höchstens 1 je Stadt | Abnehmer sitzt an der Stadt, wie in TF2 Endfabriken. |
| R6 Holz | Waldrand, Hang < 12 %, 30-120 Felder; **in S7 inaktiv**, Zielanzahl 3-6 ab S8 | Backlog: Holz/Sägewerk später. Regel steht, damit der Generator den Typ kennt. |
| R7 gleicher Typ | >= 160 Felder (4 km) Abstand, höchstens 2 gleiche Typen in 200 Felder (5 km) Radius | TF2-Verteilung statt Bergbau-Ecke, Basti-Punkt 6. |
| R8 Zulieferer je Stadt | >= 2 verschiedene Typen in 240 Felder (6 km), höchstens 5 verschiedene Typen in 80 Felder (2 km), Gini der Typ-Anzahlen < 0,5 | Keine "Weizenstadt" und keine "Bergbaustadt", Basti-Punkt 6, Gegenentwurf zur Stadt-Spezialisierung. |

**Ketten-Luftlinien** (heutige Bänder, Felder): Farm-Mühle 18-30 (Fern 31-80), Mühle-Stadt 40-130, Kohle-Kraftwerk 18-30, Kraftwerk-Stahl 15-25, Erz-Stahl 18-30, Kohle-Stahl 15-30, Stahl-Werkzeug 30-42, Werkzeug-Stadt 30-260. Grenzen sind die Messwerte aus `slice_map` und `economy_slice` plus rund 30 %. Daraus folgt: Kohle, Erz, Stahl, Kraftwerk, Werkzeug bilden ein **Revier**, Mühle und Farm ein **Agrarpaar**. 3-6 davon ergeben die Typ-Anzahlen.

## Städte (je Stufe)
| Stufe | Radius Soll (±15 %) | erlaubt | Ausfransung | Gebäude min | Anzahl |
|---|---|---|---|---|---|
| Dorf | 9 Felder / 225 m | 8-10 / 200-250 m | 4-12 / 100-300 m | 80 | 5-7 |
| Kleinstadt | 18 / 450 m | 16-20 / 400-500 m | 12-28 / 300-700 m | 400 | 3-4 |
| Stadt | 32 / 800 m | 28-36 / 700-900 m | 20-40 / 500-1000 m | 1200 | 1-2 |

Radien aus SP-03 (RE-artig: Raster 72 m, Ausfransung entlang der Ausfallstraßen). Dorf-Radius deckt SP-03 200-250 m, Stadt skaliert mit Fläche (800/450)² x 400. Dichte 2.500-6.000 EW/km², die Nachfrageformel bleibt unberührt. Perf-Fallback Stadt: 26 Felder / 650 m, 800 Gebäude (nur wenn das Perf-Gate reißt).
- **Plateau:** Kern (Radius der Stufe) < 3 %, Ausfransung < 6 %, Höhe 0-300 m, Kern frei von Fluss.
- **Mindestabstand Zentrum-Zentrum:** Stadt-Stadt 200 Felder (5 km), Stadt-Kleinstadt 140 (3,5 km), Kleinstadt-Kleinstadt 120 (3 km), Dorf zu jeder Stufe 60 (1,5 km). Nächste Stadt höchstens 240 (6 km). Das entspricht der TF2-Abstandslogik 3-5 km.

## Abweichungen vom Entwurf (bitte lesen)
1. **R8 "nie alle" gilt im 2-km-Umkreis, nicht im 6-km-Umkreis.** Die Karte ist 12,8 km breit, im 6-km-Kreis sieht fast jede Stadt alle 7 Typen (Stichprobe: 0 von 300 Karten ohne Verstoß). Gini nur über vorhandene Typen: Mit Nullen wäre "2 Typen" automatisch Gini > 0,5.
2. **Mühle/Stahlwerk/Kohle-Distanzen folgen den Ketten-Bändern**, nicht den TF2-Zahlen aus dem Skizzenentwurf (Mühle 2-5 km von der Farm, Stahlwerk 2-5 km von der Kohle): Sie würden alle Ketten um das 5-10-fache dehnen.
3. **Kohle-Erz-Abstand 36-60 Felder statt 1,5 km (60) Minimum**, weil das Stahlwerk beide in 15-30 Feldern erreichen muss.
4. **Werkzeugfabrik ab Kleinstadt statt 8.000 EW**, bei 1-2 Städten der Stufe Stadt wären 3-6 Fabriken nicht platzierbar.
5. **Gelände-Klasse Gebirgsfuß (8-20 %) wird vor dem Stempeln gemessen**, die Plateau-Bedingung < 3 % gilt danach (Footprint 150 m).
6. Offen: HQ-Startkette braucht evtl. >= 1 Rohstoff im HQ-Radius (45-55 Felder), nicht erzwungen (an Tobias).

Machbarkeit: Stichproben-Generator auf flacher Karte erfüllt R1-R7 und alle Kettenbänder, R8 bei rund 33 % der Versuche (Retry im Seed-Strom reicht). Auf der echten Heightmap ist das nicht geprüft.
