# Sophie, S7 Block A (Vorbereitung W-02/W-03/W-04)

Arbeitskopie: /tmp/claude-0/gd/sprint7/a/sophie/slice. Nur neue Dateien; kein Eingriff in main.gd oder Spielcode. Godot 4.7.2.

## Dateien
- props/kenney_city/roads/ (16 GLB + Pfeiler, Textures, LICENSE_kenney_city_kit_roads.txt), rail/ (2 GLB, Lizenzhinweis CC0), buildings/suburban + commercial (je eigene Textures + LICENSE.txt; 21 + 16 Haeuser, 2 Baeume). GLBs ohne .import (Editor beim ersten Oeffnen); Testszenen laden per GLTFDocument.
- world/art/road_tiles.json (Strassen + Gleise), building_sets.json, terrain.gdshader, roof_palette.gdshader.
- Hilfen/Tests: measure_kit.gd, roads_sheet.gd, terrain_test.tscn/.gd + terrain_shots.gd, kit_test.gd + kit_shots.gd.

## Masse (Kenney-Einheit -> Meter)
- Strassenkachel 1x1 Einheit, ganze Breite = Strasse inkl. Gehweg (je Seite ca. 11,5 %), Asphalt+Rinne ca. 77 %. Stadtstrasse x12 = 12 m (Fahrbahn 9,2 m), Landstrasse x9,75 (Fahrbahn 7,5 m).
- Feld 25 m: Maske 5/10 = eine gestreckte Gerade 25,1 x 12 m; sonst Knotenkachel 12x12 in Feldmitte + je offener Seite ein Arm 6,5 x 12 m. Landstrasse Arm 7,6 m.
- Autotile 16 Masken (N=1,E=2,S=4,W=8), Rotation geprueft in kit_test (Kreuzung, T, Kurven, Enden schliessen ohne Luecke). Native Lage: Gerade E-W, Kurve W+S, T offen W/E/S, Ende offen E, Bruecke N-S.
- Bruecke road-bridge (Deck 0,52 Einh. = 6,2 m bei x12; Pfeiler strecken auf Lichte >= 9 m). Kreisverkehr 3x3 Einh. nur Dekor.
- Gleis: Spur nativ 0,6 Einh. -> Skala 2,39 = 1,435 m; Stueck 9,57 m lang, 2,39 m breit (Soll Krone 3,8 m: Abweichung), Kurve R 9,6 m nur Platzhalter. Weiche/Kreuzung fehlen im Train Kit -> S8 Spline oder eigenes Mesh. Gleisabstand 5 m per Versatz.
- Haeuser x9 (SP-03): Suburban EFH 11,7x9,3 m, 6,6-10,3 m hoch; Commercial 7,6-18,7 m breit, 8-28 m hoch. Zonen: Rand 11 Modelle (mittel 1.162 Dreiecke), Mitte 14 (1.428), Kern 9 (3.073); Hochhaeuser (skyscraper) erst Grossstadt. Kern/Mitte-Commercial ab Kleinstadt, Dorf nur Suburban.
- Dreiecke Strasse je Kachel: gerade 44, Ende 42, Kurve 260, T 84, Kreuzung 116, Bruecke 240. Mini-Stadt-Test (kit_test, 2 Haeuser je Block + Netz): 71.039 Dreiecke.

## Shader
- terrain.gdshader: Welt-Y/Normale -> Gras, Aue (Band ueber Wasser, flach), Fels (Steigung ab 0,42 oder hoch), Schnee (Linie 780 m, nicht an Steilwaenden), Rinne = unter wasser_hoehe plus Ufersaum; optional fluss_maske (R Rinne, G Aue). Farben = palette_s08 (gras, berg_stein, berg_schnee, wasser), Variation +-5 %; Marker/Ghost-Kontrast bleibt ueber den Saum (>= 3,9:1 auf allen Flaechen; Marker allein nur 1,5-2,9:1, Saum Pflicht!). Noch offen: Aue-Farbe ist abgeleitet, nicht in der Palette.
- Bekannte Schwaeche: Rinnenkante aus Heightmap-Interpolation bei 25 m Zellen treppig (siehe terrain_fluss.png). Abhilfe: fluss_maske-Textur oder feineres Gitter an der Rinne (W-02).
- roof_palette.gdshader: SP-03 KIT_SHADER als Datei, Dachfarbe = palette stadt_haus_ziegel, Streuung je Haus per Hash der Instanzposition (geht mit MultiMesh), remap=0 fuer Strassen/Baeume. Tints je Kit siehe Kopf der Datei.

## Screenshots (shots/)
roads_sheet, terrain_uebersicht, terrain_gebirge, terrain_fluss, terrain_fluss_nah, kit_autotile, kit_haeuser. Terrain-Test: 6,4 km, 66.049 Vertices, Hoehe bis ~1.000 m (Gebirge NW), Fluss durchgehend.
Aufruf: xvfb-run -a godot --path . --rendering-driver opengl3 -s res://world/art/<terrain|kit>_shots.gd -- <outdir>

## Offen / Hinweise an Felix
- Train Kit hatte im Repo keine Lizenzdatei (CC0 vermerkt, bitte gegen Original pruefen).
- Nach Editor-Import die GLBs mit .import committen; Szenen sollen Material per roof_palette.gdshader setzen (ein ShaderMaterial je Atlas).
