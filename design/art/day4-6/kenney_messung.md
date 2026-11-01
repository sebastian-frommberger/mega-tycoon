# Kenney-Proben: Messung Dreiecke, Maßstab, Godot-Import

Sophie Martin, Art Lead · 23.11.2026 · Grundlage: 18 GLB-Proben in `sprint2/kenney_samples/` (Inventar nennt 19, geliefert sind 18) plus 4 Texturatlanten · Werkzeuge: `kenney/glb_messung.py` (eigener GLB-Parser, Standardbibliothek), Godot 4.4.1 Probeszene `kenney/probeszene/` (xvfb, Software-Renderer, nur für Import und Screenshots, keine Performance-Aussage).

**Gemessen** (nicht geschätzt): Dreiecke je Modell, Bounding-Box in Modell-Einheiten und nach Skalierung, Materialien/Texturen, Godot-Import. **Nicht gemessen:** GPU-Kosten, alle Modelle, die nicht in den Proben sind (Signale, Bahnhof, Bus, Factory Kit, Road Pack, spline-track).

## 1. Dreiecke und Maße (Rohdaten `kenney/glb_messung.csv`)

Einheit = Modell-Einheit (Kits sind nicht in Metern, siehe 2). Budget = unser Ziel aus S-06a, Referenz Lkw = 300 Tris.

| Kit | Modell | Tris | Prim. | Maße x·y·z (Einh.) | Budget | Faktor zum Budget |
|---|---|---|---|---|---|---|
| Car Kit | truck | **2.082** | 5 | 1,50·1,30·2,95 | 300 | **6,9×** |
| Car Kit | truck-flat | **2.488** | 5 | 1,50·1,30·2,75 | 300 | **8,3×** |
| Car Kit | tractor | 2.044 | 5 | 1,34·1,60·2,20 | 300 | 6,8× |
| Train Kit | train-locomotive-a (Dampf) | 1.666 | 6 | 1,43·1,66·2,60 | 600 | 2,8× |
| Train Kit | train-diesel-a | 1.742 | 3 | 1,20·1,60·2,40 | 600 | 2,9× |
| Train Kit | train-carriage-coal | 1.184 | 4 | 1,20·1,65·2,70 | 250 | 4,7× |
| Train Kit | train-carriage-lumber | 1.170 | 4 | 1,10·1,16·2,70 | 250 | 4,7× |
| Train Kit | train-carriage-tank | 1.146 | 3 | 1,39·1,75·2,70 | 250 | 4,6× |
| Train Kit | railroad-straight | 376 | 1 | 1,00·0,10·4,00 (Pivot y −1) | 16/Segment | Kachel, nicht vergleichbar |
| Train Kit | railroad-corner-large | 568 | 1 | 4,49·0,10·4,49 | – | Kachel |
| Industrial | building-a | 2.046 | 1 | 2,08·1,47·1,24 | 2.500 (Industrie-Kern) | passt als Anbau |
| Industrial | building-f | 1.552 | 1 | 1,79·1,92·1,28 | – | passt |
| Industrial | chimney-large | 212 | 1 | 1,00·1,70·1,00 | 500 (Anbauteil) | passt |
| Industrial | detail-tank | 236 | 1 | 0,85·0,42·0,52 | – | passt |
| Nature Kit | tree_default | **114** | 2 | 0,76·1,71·0,65 | 100 | 1,1× |
| Nature Kit | tree_pineDefaultA | 230 | 2 | 0,53·1,55·0,53 | 100 | 2,3× |
| Nature Kit | rock_largeA | **80** | 2 | 0,78·0,26·1,02 | 200 | passt |
| Watercraft | ship-cargo-a | 1.060 | 4 | 3,92·3,38·10,55 | 1.200 | passt |

Materialien: Car, Train, Industrial, Watercraft haben je **ein** Material mit einem Atlas `colormap.png`, aber **vier verschiedene Atlanten** (MD5 unterschiedlich). Nature Kit: zwei Materialien per Vertex-/Materialfarbe, keine Textur. Für unseren Ein-Atlas-Ansatz müssen die vier Kit-Atlanten entweder zusammengelegt oder die UVs auf Palette-Swatches umgelegt werden.

Die Fahrzeug-Tris stecken zum großen Teil in den Rädern (Lkw: 5 Primitives = Karosserie + 4 Räder). Eine Reduktion auf 300 Tris heißt Räder als Achtkant und Karosserie neu, das ist faktisch ein Neubau.

## 2. Maßstab gegen 1 Feld = 10 m

Die Kits sind **untereinander nicht maßstäblich**. Ich habe je Kit den Faktor so gewählt, dass die Maßstabsregel für das Leitobjekt erfüllt ist (Lkw = 1 Feld lang; Halle ca. 2 Felder; Baum 1–2 Felder hoch; Frachtschiff ca. 100 m):

| Kit | Faktor | Ergebnis (Godot-AABB nach Skalierung, `probeszene_masse_godot.csv`) | Befund |
|---|---|---|---|
| Car Kit | ×3,4 | truck 5,1 · 4,4 · **10,0 m** | Länge stimmt, **Breite 5,1 m = halbes Feld**, doppelt so breit wie ein echter Lkw (2,5 m). Auf einer 2-spurigen 10-m-Straße füllt er die Spur exakt. Spielzeug-Proportion, passt zum Diorama, kollidiert mit nichts Hartem, sieht aber neben einem 300-Tris-Eigenbau mit Realproportion anders aus. Entweder alle Fahrzeuge Kenney-Proportion oder keines |
| Train Kit (Fahrzeuge) | ×3,7 | Wagen 4,1–5,1 · 4,3–6,5 · **10,0 m**, Lok 5,3 · 6,1 · 9,6 m | 1 Wagen = 1 Feld, Zug 8–20 Felder stimmt. Breite 4,4–5,1 m = Gleisbreite 0,5 Feld. Lok 6,1 m hoch = so hoch wie ein Wohnhaus (6–12 m) |
| Train Kit (Gleis) | ×3,7 | railroad-straight 3,7 · 0,4 · **14,8 m** | **Passt nicht ins 10-m-Raster** (14,8 m Kachel). Mit ×2,5 passt die Länge (10 m), dann ist das Gleis 2,5 m breit und die Wagen (4,4 m) hängen über. Fazit: Gleiskacheln nur als visueller Platzhalter, nie als Raster-Modul. Pivot liegt 1 Einheit unter dem Gleis (Schotterbett) |
| Industrial | ×10 | building-a 20,8 · 14,7 · 12,4 m, chimney 10 · 17 · 10 m | Halle = 2×1 Felder, Schornstein 17 m. Als Anbauten für Stufe 2–3 brauchbar. Ein Industrie-Kern 8×8 Felder (80 m) ist damit nicht abgedeckt, nur Kombination aus 4–6 Hallen |
| Nature Kit | ×8 | tree_default 6,0 · 13,7 m, pine 4,3 · 12,4 m, rock 6,3 · 2,1 · 8,1 m | Baum 1,4 Felder hoch, Krone 0,6 Felder: **trifft die Maßstabsregel exakt** (Krone 0,4–0,6, Höhe 1–2 Felder) |
| Watercraft | ×10 | ship-cargo-a 39 · 34 · 105 m | Küstenschiff, 10 Felder lang. Im Slice als Einzelobjekt tragbar |

Screenshots: `kenney/probeszene/shot_uebersicht.png`, `shot_fahrzeuge.png`, `shot_gebaeude.png` (alle Proben mit Faktor nebeneinander, 10-m-Raster, Graubox-Lkw 10 × 2,5 × 3 m als Referenz links). Das Schiff steht am rechten Bildrand und ist dort perspektivisch verzerrt, das ist die Kamera, nicht das Modell.

## 3. Godot-Import (4.4.1, headless `--import`)

Alle 18 GLB importieren ohne Fehler, Y-up, Pivot am Boden (Fahrzeuge, Gebäude, Bäume) bzw. 1 Einheit unter dem Gleis. Texturen werden nur gefunden, wenn `Textures/colormap.png` relativ neben der GLB liegt; flach kopierte Modelle erscheinen weiß (erster Lauf). Nature Kit braucht keine Textur. Kein Modell hat LOD-Stufen oder Kollisionsformen.

## 4. Folgen für S-06a (in der CSV-Spalte `kenney_abdeckung` übernommen)

| Asset | Vorher (Inventar) | Jetzt (gemessen) |
|---|---|---|
| Bäume V1, Felsen V3 | „final denkbar“ | **bestätigt:** 114/230/80 Tris, Maßstab trifft die Regel. Nur Farbe auf Palette v1 umlegen. Artist 2,0 → 1,0 PT |
| Lkw F1 | „final denkbar, Tris prüfen“ | **nur Platzhalter.** 2.082–2.488 Tris = 7–8× Budget; bei 10.000 Instanzen 20–25 M Tris allein für Fahrzeuge. Retopo kostet so viel wie ein Neubau. Artist 2,0 → 1,5 PT (Kenney als Referenz für Proportion und als Spike-Mesh) |
| Lok F2, Wagen F3 | „final denkbar“ | **nur Platzhalter.** 1.666 / 1.150–1.180 Tris = 2,8× / 4,7× Budget. Zusätzlich: Ladegut ist Teil des Meshes (Kohle, Holz, Tank), Felix' Instanzfarben-Pfad greift nicht. Artist 1,5+2,0 → 1,0+1,5 PT |
| Industrie-Anbauten I5, I12 | „teilweise“ | **bestätigt:** Hallen 1.552–2.046 Tris, Schornstein 212, als Stufe-2/3-Anbauten im Budget. Kerne (Hochofen, Förderturm, Kühlturm, Mühle, Silo) bleiben eigen |
| Gleis N2 | „Profil ableitbar?“ | **nein.** Kachel 1,0 × 4,0 Einheiten, kein Raster-Treffer, kein Profil. Nur als Bild im Spike |
| Schiff F6 | „ja“ | **bestätigt:** 1.060 Tris, 105 m bei ×10 |

Summen S-06a mit Kenney (Proben gemessen, Rest geschätzt): Artist 67,5 → **49,0 PT** (KERN 36,0), Sophie 48,0 → 45,5 PT, gesamt 117,5 → 96,5 PT. Die Ersparnis liegt bei Vegetation, Anbauten, Schiff und bei allem, was als Platzhalter den Artist-Start entlastet, **nicht** bei den Fahrzeugen.

## 5. Empfehlung (Entscheidung Jonas)

1. **Spikes und Grey-Box: Kenney ja, sofort.** Industrial-Hallen, Schornsteine, Bäume, Fahrzeuge als Platzhalter mit den Faktoren aus Abschnitt 2. Änderung der Refinement-Regel wie in `s06a_assetliste.md` §4 vorgeschlagen; Zusatzbedingung aus der Messung: **F-05 misst mit Quadern oder 300-Tris-Meshes, nicht mit Kenney-Fahrzeugen** (sonst misst der Benchmark 7× unser Budget).
2. **Final im Slice: Bäume, Felsen, Industrie-Anbauten, Schornsteine, Schiff.** Bedingung: Atlas auf Palette v1 umgelegt, Faktor je Kit im Import-Preset festgeschrieben, Maßstabsband-Abgleich (G1) für jedes Modell.
3. **Nicht final: Fahrzeuge und Gleise.** Fahrzeuge wegen Tris, Gleise wegen Raster und Spline-Netz. Stadtgebäude (Suburban/Commercial) sind nicht in den Proben, bleiben „Grey-Box ja, final offen“.
4. Proportion ist eine Stilentscheidung, die ich nicht allein treffe: Kenney-Fahrzeuge sind doppelt so breit wie real. Wenn wir die Spielzeug-Proportion übernehmen, muss der Eigenbau sie auch haben. Ich schlage vor: **Eigenbau mit Breite 0,35 Feld (3,5 m), Höhe bis 0,4 Feld**, also leicht überzeichnet, nicht Kenney-breit. Das sichert, dass 2 Lkw auf einer 1-Feld-Straße nebeneinander passen.

## 6. Offene Prüfaufgaben (Modelle fehlen in den Proben)

Signale, Bahnhof (existiert er?), Bus/Van, `spline-track`, Factory-Kit-Förderband, Road-Pack-Kreuzung, City Kit Suburban Haus, Modular Buildings Etage: je Tris und Maße mit `glb_messung.py` (5 min je Datei, Aufruf im Dokumentkopf). Audio- und Icon-Pakete nicht gesichtet.
