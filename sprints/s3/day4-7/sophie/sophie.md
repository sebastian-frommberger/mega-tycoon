# Sophie Martin, Art Lead: S-07 und S-09 (Tag 4–7)

## S-07 Kenney-Import: fertig, Akzeptanz erfüllt
Dateien: `kenney_faktoren.json`, `kenney_loader.gd` (class `KenneyLoader`), Probeprojekt `s07/proj/` (probe.gd/tscn), Screenshots `s07_probeszene_uebersicht.png`, `s07_probeszene_nah.png`, Messung `s07_masse_roh.csv`, `s07_abweichung.csv`.
- 3 Kits: Nature ×8, City Kit Industrial ×10, Watercraft ×10 (Fahrzeuge, Train Kit, Gleise nicht enthalten). Faktoren als `faktor_promille` (F-09: keine Floats). Pivot: Nature +0,05 Einheiten (sonst 0,4 m im Boden), Industrial XZ unverändert (Raster), Schiff/Bäume XZ zentriert.
- **Abweichung zum Leitobjekt** (Godot 4.7.2, opengl3, xvfb): Baum Höhe −8,9 %, Halle Länge +4,2 %, Schiff +5,5 %, alle ≤10 %. Baum liegt knapp; 8,5 statt 8 wäre −3 %, aber Krone dann +7 % über dem Band.
- Loader: Import-Pfad und Laufzeitpfad (GLTFDocument) liefern identische Maße; MultiMesh-Test 100 Bäume ohne Fehler (keine Performance-Aussage).
- Voraussetzung: `Textures/colormap.png` neben der GLB, ein Import-Lauf, damit `class_name` registriert ist.

## S-09 Karten-Entwurf: fertig
Dateien in `s09/`: `slice_map.json`, `slice_map.schema.json`, `validate_slice_map.py`, `slice_map.png` plus zwei Detail-PNGs, Skripte `build_slice_map.py`, `render_slice_map.py`.
- Ketten nach Lenas L-08 (Datei lag vor): K1 Getreide→Mühle→Stadt, K2 Kohle→Kraftwerk, K3 Erz+Kohle→Stahl→Werkzeugfabrik. 6 Städte, 13 Industrien, Fluss, Küste, 2 Gebirge, 5 Wälder. Nischen ca. 25 Felder: Kohle→Stahl 25, Farm 2→Mühle 27.
- HQ-Optionen: Agrar (Haberau), Bergbau (Kohlberg) im Slice; Handel (Mittelfurt), Hafen (Seehafen) vorhanden, laut L-08 nicht im Slice. Jede mit Bau-Rohstoffquelle im Radius (D13).
- **Validierung:** Tobias' `validate.py` (jsonschema und Fallback) 0 Fehler, 5 Negativfälle erkannt. Ein Kartenschema gibt es bei Tobias nicht; `slice_map.schema.json` ist mein Entwurf auf seinen `common`-Typen, seine Abzeichnung fehlt.

## Offene Fragen
1. Tobias: Kartenschema übernehmen? Neues Suffix `_anzahl` (Einwohner).
2. Jonas: Kartengröße 512 Felder ist Annahme, spielbarer Kern nur ca. 250×290 Felder.
3. Werkzeugfabrik und Lage der Hafen-/Handel-Ketten bleiben Annahme (L-08).
4. Xvfb-Lauf meldet einmal `ERR_CANT_OPEN` (nicht untersucht, Ausgabe unbeeinträchtigt).
