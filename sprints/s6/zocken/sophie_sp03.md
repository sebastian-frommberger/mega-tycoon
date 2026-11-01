# SP-03 Maßstab, Terrain, Kartenrand (Spike für S7)

Sophie (Art/Level), 01.11. · Auslöser: Bastis Feedback vom 01.11. (`sprints/s7/basti_feedback_01-11.md`, Punkte 1, 2, 3, 5, 7, 8, 9) · Spike, **kein Merge in den Slice**.

Ergebnis in einem Satz: **Vorschlag 1 Feld = 25 m bei unverändert 512² Feldern (12,8 km spielbar) plus 7,5 km Landschaftsrand.** Straßen, Gleise und Häuser bekommen reale Breiten, die Kleinstadt wächst von heute ~140 m auf ~1 km Durchmesser. Der Prototyp zeigt, dass das in gl_compatibility darstellbar ist. Er zeigt auch zwei harte Kostenpunkte: Bäume/Häuser brauchen LOD, und die Terrain-Erzeugung braucht 15–33 s in GDScript.

## 1. Recherche: Maßstäbe aus TF2 und Railway Empire

| Größe | Transport Fever 2 | Railway Empire 1/2 | Quelle |
|---|---|---|---|
| Kartengröße | Klein 8 km, Mittel 12 km, Groß 14 km, Sehr groß 16 km (1:2 = 11×22, 1:3 = 9×27 km), experimentell „Megalomaniac“ 24 km | 2 Kontinentkarten mit zusammen „über 13 Mio km²“ spielbarer Fläche, dazu Regionalkarten, also **stark gestauchte Geografie** | [GOG-Forum Kartengrößen](https://gog.com/forum/transport_fever_2/mapsize), [Steam: Heightmap-Pixelgrößen 1025–6145 px](https://steamcommunity.com/app/1066780/discussions/0/1737762134384214961), [Kalypso RE2 FAQ](https://www.kalypsomedia.com/post/railway-empire-2-faq-1) |
| Heightmap | 1:1-Karten 1025² bis 6145² px; bei 16 km/4097 px ergibt das **ca. 4 m je Pixel** (eigene Rechnung) | – | ebd. |
| Stadtstraße | `town_medium_new`: Fahrbahn 8 m (2×4 m) + Gehweg 2×4 m, **ca. 16 m gesamt**. Wiki-Beispiel: Fahrbahn 10 m + Gehweg 2×3 m. Spuren 3–5 m | keine Angabe | [transportfever.net „Vanilla Straßen Maße“](https://www.transportfever.net/thread/13864-vanilla-stra%C3%9Fen-ma%C3%9Fe/), [TF2-Wiki Tracks and Streets](https://wiki.transportfever2.com/doku.php?id=modding%3Atracksstreets) |
| Gleis | Spur 1,435 m, `shapeWidth` 4,0 m, **Gleisabstand 5,0 m** | – | TF2-Wiki ebd., [transportfever.net Gleisabstand](https://www.transportfever.net/thread/15798-bridge-pillar-snapping-for-non-standard-track-width/) |
| Bahnhof | max. 520 m lang (13 × 40 m), 25 Gleise | – | [Steam-Diskussion Bahnhofsgrenzen](https://steamcommunity.com/app/1066780/discussions/0/2569816492273870522) |
| Maßstabsprinzip | weitgehend 1:1 (Fahrzeuge, Straßen und Häuser real; Karte ist ein realer Ausschnitt) | **mehrere Maßstäbe gleichzeitig**: Züge und Häuser sind größer gezeichnet als die Karte, Tempo hängt vom Zoom ab | [Steam RE2 „trains too fast“](https://steamcommunity.com/app/1644320/discussions/1/3842179871518143510) |
| Stadtausdehnung, Distanz Stadt–Industrie | **nicht belegt gefunden.** Aus den Kartengrößen abgeleitet (Annahme): Städte 3–5 km auseinander, Industrien 1,5–4 km von der nächsten Stadt, Kleinstadt 0,6–1 km Durchmesser | aus der Referenz abgelesen (Referenz 2): Blöcke ca. 50–80 m, Straßen deutlich schmaler als Blöcke, Bahnhof am Rand | Ableitung, keine Quelle |

**Folgerung:** RE ist Stilvorlage (dichte Blockcluster, feine Linien in der Übersicht, Bahnhof am Stadtrand), aber kein Maßstab. RE staucht die Karte und vergrößert die Objekte. Harte Zahlen liefert TF2, daran orientiert sich der Vorschlag.

## 2. Maßstab-Vorschlag Mega Tycoon

| Größe | Heute (Slice) | Vorschlag | Begründung |
|---|---|---|---|
| Meter je Feld | 10 m (Szene, `slice_map.karte.hinweis`) | **25 m** | Stadtstraße 12 m und Doppelgleis 10 m passen in ein Feld; 512² Felder bleiben → A*-Gitter, Datenformat und Bench unverändert |
| Karte spielbar | 5,12 km | **12,8 km** | zwischen TF2 Mittel (12 km) und Groß (14 km) |
| Karte mit Rand | 5,12 km, dahinter Himmel (`vorher_uebersicht.png`) | **27,8 km** (7,5 km Rand je Seite) | Messung: bei max. Zoom trifft der Blick höchstens 6,75 km außerhalb auf Boden, kein Fehltreffer (48 Ecken- und Richtungsfälle) |
| Stadtstraße | Box 9,6 m über die volle Feldbreite | **12 m** inkl. Gehweg (Fahrbahn ca. 9 m) | Kenney-Kachel ×12; schmaler als TF2 (16 m), weil Kleinstädte |
| Landstraße | wie Stadtstraße | **7,5 m** Asphalt + 2×1,2 m Bankett | TF2-Spurbreite 3–4 m |
| Gleis | Box 5 m | Spur **1,435 m**, Schotterkrone 3,8 m, Fuß 5,2 m, Gleisabstand **5 m** | TF2-Werte |
| Haus (EFH) | Quader 7–9 m Grundfläche, bis ~80 m hoch | **12×9 m, 7–10 m hoch** (Kenney Suburban ×9) | real |
| Stadthaus/Geschäft | – | 8–19 m breit, 8–15 m hoch (Commercial ×9, Hochhäuser l–n erst ab Großstadt) | real |
| Industriehalle | – | 20×15 m (Industrial ×10), Förderturm 36 m | wie `kenney_messung.md` |
| Baum | 1,4 Felder | 11–18 m (Nature ×8) | unverändert, passt |
| Stadtraster | Straße jedes 4. Feld (40 m) | **72 m** (Block 60 m + Straße 12 m) ≈ 3 Felder | Referenz 2 |
| Stadtradius Dorf (500–900 EW) | 4 Felder = 40 m | **200–250 m** (8–10 Felder) | Dichte ca. 3.000–4.000 EW/km² wie deutsche Kleinstädte (Annahme) |
| Kleinstadt (2.500–3.200) | 7 Felder = 70 m | **450 m** (18 Felder), lockerer Rand +300–700 m entlang Ausfallstraßen | im Prototyp gebaut: 87 Knoten, 536 Gebäude |
| Stadt (12.000) | 16 Felder = 160 m | **800 m** (32 Felder) | |
| Großstadt (>30.000) | – | **1.300 m** (52 Felder) | |
| Kamera | Zoom 0,4–26 (Abstand ca. 10 m–6,6 km), Neigung fix 51°, FOV 75° | Abstand **40 m–5,6 km** (Höhe ca. 24 m–4,9 km), Neigung **36° nah → 62° fern**, FOV 50°, Zielpunkt auf die spielbare Fläche geklemmt | Nahzoom flacher wie in RE; fern steiler, damit der Rand begrenzt bleibt |

### Was das für die Sim bedeutet (offene Fragen, bewusst nicht umgerechnet)

- **Felix/Tobias:** `raum.feld_mm = 1000` steht neben dem Kartenhinweis „1 Feld = 10 m Szene“. Was ist die physikalische Bedeutung von `feld_mm` und `tempo_mm_pro_tick`? Bei 25 m je Feld ändern sich die Fahrzeiten je Feld. Wer legt die neuen Tempo- und Tick-Werte fest?
- **Tobias:** Ökonomie-Distanzen stehen in Feldern (`mindestdistanz_felder 6`, `d_eff_knick_felder 60`, Lizenz-Zuschlag pro Feld). Bleiben die Felderzahlen und wird nur die Meterlänge größer, oder werden sie neu skaliert? Slice-Positionen ×2,5 ergeben zum Beispiel Kohlberg–Mittelfurt ≈ 5,8 km und Kohlberg–Kohlemine ≈ 1,2 km. Das liegt im TF2-Band, das Basti gut findet.
- **Felix:** Pro Feld liegen künftig mehrere Gleise oder Gleis und Straße nebeneinander (12 m Straße, 5 m Gleisabstand in einem 25-m-Feld). Wie bildet das Netzmodell das ab? Trassen sollen als Spline über den Feldpfad gezeichnet werden, nicht mehr als Kacheln.
- **Felix:** Terrain wird Sim-relevant: Höhe je Feld, Steigung (Kosten/Tempo), Flussfelder (Brücke), Bergfelder (Tunnel oder gesperrt). Heute gibt es nur `terrain_at` mit drei Typen.
- **Lena/Tobias:** Industrie-Lage-Logik (Feedback 6). Der Prototyp setzt die Mine an den Gebirgsfuß und die Farm in die flache Flussaue, als Beispiel für „Lage statt Zufall“. Die Verteilung selbst gehört nicht zu SP-03.
- **Lena:** Stadtradien je Stufe sind ein Vorschlag. Passt das zur Einwohner- und Nachfrageformel?

## 3. Prototyp

`slice/spikes_s7/scale_terrain.tscn` + `scale_terrain.gd`, Assets kopiert nach `spikes_s7/assets/`, Shots per `spikes_s7/sp03_shots.gd`, Vorher per `spikes_s7/sp03_vorher.gd` (beide `xvfb-run … --rendering-driver opengl3 -s res://spikes_s7/<skript>.gd -- <outdir>`). Einheit 1 m, nur Darstellung, keine Sim.

**Terrain-Ansatz:** Höhenfunktion aus FastNoiseLite: Hügel (fBm, 2,6 km Wellenlänge, ±55 m), Gebirgsmassiv NW (Ridged-Noise bis ~970 m, Lage wie `gelaende.gebirge_nw`), Flusstal (Fluss als Funktion x = f(z) mit zwei Mäander-Sinus; Distanz analytisch statt Polylinien-Suche; Tal 1,5 km breit, Rinne ~45 m, Gefälle 1,4 ‰), Stadt-, Minen- und Farm-Plateaus durch Abflachen. Trassen: Catmull-Rom-Spline (10-m-Punkte), Höhe geglättet (±300 m), über Fluss mindestens 9 m Lichte. Das Gelände wird entlang der Trasse „gestempelt“ (Einschnitt/Damm, 10–55 m Übergang), danach wird die Flussrinne neu gegraben, so entstehen Brücken von selbst (Pfeiler alle 30 m). Innen 25-m-Raster in 8×8 Chunks (Vertex-Farben nach Höhe, Neigung, Wald-Noise, Flussnähe), außen 100-m-Raster in 4 Kacheln, 6 m abgesenkt unter der Innenfläche, Schürzen am Kartenrand gegen Risse.

**Rand-Lösung (TF2-artig):** Die Welt läuft 7,5 km über die spielbare Fläche hinaus. Ab 0,3 km steigt ein Gebirgsring an (bis ~1.400 m), der Fluss läuft durch. Die Kamera klemmt den **Zielpunkt** auf 0..12,8 km und den Abstand auf ≤ 5,6 km. Die Neigung steigt mit dem Abstand, damit der obere Bildrand nicht zum Horizont kippt. Tiefennebel folgt dem Zoom (Beginn 1,3 × Abstand + 0,6 km, Ende 4 × Abstand + 9 km), near/far skalieren mit (0,4 % bzw. 8 × Abstand + 15 km). `border_check()` schießt die vier Bildecken-Strahlen gegen das Gelände: max. 6.752 m außerhalb, 0 Fehltreffer.

**Stadt:** Raster 72 m, um 12° gedreht, Knoten in Radius × (0,8 ± 0,4 Noise) → ausgefranster Rand, Hauptachsen bis 1,15 R. Kenney-Roads-Kacheln ×12; Kachelwahl automatisch aus der Geometrie (offene Seite = kein Bordstein in der Kantenmitte). Bebauung als Blockrand: Kern Commercial dicht, Mitte Suburban, Rand locker mit Gartenbäumen, einzelne Parkblöcke. Außerhalb des Rasters Einzelhäuser entlang der Ausfallstraßen, Dichte nimmt bis +700 m ab. Bahnhof (Bahnsteig 220 m, Dach, Empfangsgebäude) am Südrand parallel zum Raster. **Palette:** Ein kleiner Shader färbt Kenney-Türkis-Dächer ziegelrot, weißen Putz warm und Straßen dunkler (ein ShaderMaterial je Atlas).

**Industrie:** Kohlemine am Fuß des Massivs (Hallen, Schornstein, Förderturm-Box, Abraumhalde, Gleis- und Straßenanschluss), Gut Haberau in der Aue östlich des Flusses (Hof + 11 Felder à 200×140 m, folgen dem Gelände), Straße über eine Brücke zur Stadt.

### Screenshots (`/tmp/claude-0/gd/sprint6/zocken/sophie/shots/`)

| Datei | Inhalt |
|---|---|
| `sp03_uebersicht.png` | Übersicht 4,3 km, 61°, vergleichbar Referenz 1 |
| `sp03_stadt_nah.png` | Kohlberg aus 700 m, 40°, vergleichbar Referenz 2 |
| `sp03_stadt_strasse.png` | Straßenniveau 160 m: Kenney-Kacheln, Blockrand, Palette |
| `sp03_mine.png` | Kohlemine am Gebirgsfuß aus 420 m (Hallen, Schornstein, Förderturm, Halde, Gleisanschluss) |
| `sp03_farm.png` | Gut Haberau in der Flussaue aus 900 m (Felder 200×140 m, Straße, Gleis im Hintergrund) |
| `sp03_rand_max_nw.png`, `sp03_rand_max_ost.png` | maximales Herauszoomen an der NW-Ecke bzw. am Ostrand: Gebirge statt Kante |
| `vorher_uebersicht.png`, `vorher_stadt_nah.png` | aktueller Slice mit **gleicher Kamera in Metern** (FOV 50, gleiche Neigung und Abstand) |
| `vorher_rand_max.png` | Slice bei seinem max. Zoom (26) an der NW-Ecke: Kartenkante + Himmel |
| `sp03_perf.txt` | Performance-Monitor je Ansicht + Randprüfung |

## 4. Kosten (Performance-Monitor, xvfb/llvmpipe; FPS hier ohne Aussage, Draw Calls und Primitive schon)

| Ansicht | Draw Calls | Primitive (Dreiecke) im Frame |
|---|---|---|
| Übersicht 4,3 km | 114 | 0,60 M |
| Stadt nah 700 m | 173 | 2,87 M |
| Straßenniveau 160 m | 171 | 2,21 M |
| Mine 420 m / Farm 900 m | 49 / 52 | 2,01 M / 2,28 M |
| Rand max. Zoom | 10–17 | 0,17–0,19 M (Schatten ab 3 km aus) |
| *Vorher Slice (Vergleich)* | *185–313* | *1,09–1,10 M* |

Szene gesamt: 370 k Terrain-Vertices (Innen 263 k + Außen 77 k + Bänder), 6,2 M Dreiecke, wenn alles sichtbar wäre. 38 k Instanzen in 105 MultiMeshes, davon 28,5 k Bäume (≈ 4,8 M Dreiecke = 78 %) und 536 Stadtgebäude à 0,8–2,5 k Dreiecke (≈ 0,8 M). VRAM-Monitor 41 MB. Erzeugung **15–33 s** (GDScript, CPU-gebunden, je nach Last der Testmaschine; Ladeziel F-12 ist ≤ 3 s).

**Risiken gl_compatibility:**
1. **Dreiecke durch Vegetation und Häuser:** Ohne LOD liegt Stadt nah bei 2,9 M Dreiecken plus Schatten-Pass. Auf dem Zielrechner vermutlich tragbar (heute 1,1 M bei 89,7 FPS), mit 5.000 Lkw und mehreren Städten aber nicht. Nötig: Baum-Impostor oder Low-Poly-Krone ab ~800 m, Kenney `low-detail-building-*` (90–380 Dreiecke) als LOD ab ~600 m, Sichtweite je Chunk (im Spike: Bäume 4,2 km, Schwellen 0,9 km).
2. **MultiMesh ohne Instanz-Culling:** Ein Chunk (3,2 km) wird ganz gezeichnet, sobald er angeschnitten ist. Feinere Chunks bedeuten mehr Draw Calls, Abwägung beim Messen auf dem Zielrechner.
3. **Tiefenpuffer 24 bit bei 28 km Welt:** Mit near = 0,4 % des Abstands sieht man im Spike kein Z-Fighting. Die Trassenbänder liegen 0,1–0,55 m über dem Gelände; bei max. Zoom ist das knapp, Polygon-Offset oder Decal-Pass im Auge behalten.
4. **Schatten:** Directional mit 2 Splits über bis zu 3,5 km wird weich bzw. blockig. Ab ~3 km Schatten abschalten oder nur Terrain-Selbstschatten per Vertex-AO.
5. **Erzeugungszeit:** 15–33 s GDScript. Heightmap offline backen (16-bit-PNG 513², Außenrand 279²) und Chunks in Threads bauen, oder GDExtension. Sonst ist F-12 (≤ 3 s) verletzt.
6. **Flussauflösung:** Eine 45-m-Rinne auf einem 25-m-Raster ist grob. Das Wasserband kaschiert das, Uferkanten bleiben eckig. Lösung: lokale Verfeinerung oder Ufer-Mesh entlang des Splines.
7. Tiefennebel funktioniert in gl_compatibility (verifiziert), volumetrischer Nebel nicht (nicht gebraucht).

### Befunde aus den Bildern

- **Echter Maßstab macht Industrie klein.** Eine 20-m-Halle ist aus 1 km kaum zu sehen; `sp03_mine.png` ist erst aus 420 m lesbar. RE löst das durch Überzeichnung, TF2 durch große Werksgelände. Für uns heißt das: Industrie-Grundflächen von 150–300 m (Halde, Felder, Gleisanlagen als Signal) plus Icons/Labels in der Übersicht. Das ist eine Art- und Design-Frage, keine Technikfrage.
- **Felder lesen sich wie in RE** (`sp03_farm.png`): Die Farm erkennt man aus der Ferne an den Feldern, nicht am Hof.
- **Stadt:** Sie breitet sich jetzt wie in RE aus (Raster, Kern, ausgefranster Rand, Bahnhof am Rand, `sp03_stadt_nah.png`). Die Blockinnenflächen sind aber noch zu leer (keine Hinterhäuser, Höfe, Gärten), und die Kenney-Proportion bleibt spielzeughaft.
- **Offene Look-Mängel:**
  - Waldränder sind stufig (25-m-Vertexfarben).
  - Die Naht zwischen Innenraster (25 m) und Außenraster (100 m) ist am Ostrand sichtbar (`sp03_rand_max_ost.png`).
  - Die Nordhänge im Massiv sind zu dunkel (Ambient).
  - Das Gleis an der Mine versinkt stellenweise im Plateau-Übergang.
  - Die Übersicht ist deutlich ärmer an Textur als RE, wo überall Baumtupfen zu sehen sind.
  - Alles lösbar, aber Arbeit für S7.

## 5. Aufwandsschätzung S7 (Personentage, grob)

| Paket | Sophie | Felix | Tobias/Lena |
|---|---|---|---|
| Heightmap-Terrain im Slice (Datenformat `slice_map` + Generator/Bake, Chunks, Farben) | 3,0 | 1,0 (Höhe/Steigung in Sim, `terrain_at`) | – |
| Fluss als Rinne + Wasserband + Brücken | 1,5 | 0,5 (Brückenfelder) | – |
| Kartenrand + Kamera (Klemmung, Neigungskurve, Nebel, near/far) | 1,5 | – | – |
| Trassen als Spline-Band über Feldpfad (Straße, Gleis, Schwellen, Böschungsstempel), ersetzt Box-Kacheln | 3,0 | 1,0 (Pfad → Spline, Mehrgleisigkeit) | – |
| Stadtgenerator neu (Raster, Blockrand, Rand, Bahnhof, Palette-Shader) | 3,0 | – | 0,5 (Radien/Stufen bestätigen) |
| LOD/Performance (Baum-Impostor, Gebäude-LOD, Messung Zielrechner mit Daniel) | 2,0 | 0,5 | – |
| Umrechnung Sim auf 25 m (Tempo, Distanzen, Kosten) | – | offen | offen |
| **Summe** | **≈ 14 PT** | **≈ 4 PT + Umrechnung** | **≈ 0,5 PT + Umrechnung** |

Der Ring-Bug (Feedback 4) und die Industrie-Verteilung (Feedback 6) sind nicht enthalten.

## 6. Offene Fragen

- **Felix:** Bedeutung von `feld_mm`/`tempo_mm_pro_tick` und wer auf 25 m umstellt. Mehrere Trassen pro Feld. Terrain/Steigung in der Sim. Ladezeit: Bake oder GDExtension?
- **Tobias:** Ökonomie-Distanzen in Feldern beibehalten oder neu skalieren? Fahrzeiten und Erträge bei ×2,5 längeren Wegen.
- **Lena:** Stadtradien/Einwohner je Stufe. Lage-Regeln für Industrie (Mine am Gebirgsfuß, Farm in der Aue, Holz am Waldrand) als Datenfeld in `slice_map`?
- **Jonas/Basti:** Ist 12,8 km Spielfläche groß genug (TF2 Groß = 14 km)? Alternative: 20 m je Feld mit 640² Feldern (12,8 km) oder 25 m mit 640² (16 km), beides kostet A*-Speicher und Bench neu.
- **Art (ich):** Kenney-Houses sind für Massen-Instanzen zu schwer (0,8–2,5 k Dreiecke). Eigenes Low-Poly-Hausset oder Kenney low-detail als Standard?
