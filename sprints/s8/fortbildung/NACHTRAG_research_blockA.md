# Nachtrag: Bericht Research Block A (Godot 4 Tycoon, Compatibility, 2026-11-03)

Der Bericht deckt sich in den Kernpunkten mit unseren Skills (MultiMesh in Chunks, fester Tick, Interpolation, `.uid` committen, Headless ist kein Renderbenchmark, Hysterese statt Fade). Reddit war auch dort nicht abrufbar. Neue oder zu prüfende Punkte, jeweils nur mit der Quelle des Berichts (überwiegend Doku, Issues, Blogs):

1. Compatibility packt MultiMesh-Instanzfarbe und Custom-Data in 16 Bit statt 32. Betrifft `INSTANCE_CUSTOM` (Gang, Variante, Nicken, Wanken): Präzision prüfen. Rolle: Tech Art, Lead Dev. Status: zu messen [V].
2. Visibility Range, Fade Mode "Disabled" (Hysterese) ist am billigsten; "Self"/"Dependencies" erzwingen transparentes Rendering. Passt zu unserer Baum-LOD-Hysterese (50 m).
3. Compatibility-Licht: 8 Omni + 8 Spot je Mesh; ein MultiMesh zählt als ein Objekt. Bug #107070 (Lichtauswahl). Laternen und Fenster als emissive Materialien. Rolle: Tech Art, Art Director.
4. Bewegte Vertices (Wellen, Wippen) brauchen `extra_cull_margin`, sonst fehlt Licht am AABB-Rand. Zu prüfen für Wasser und Fahrzeug-Gait.
5. Opakes Wasser: Tiefenfärbung aus Terrainhöhe (Heightmap/Ground-Map) statt Depth-Texture; passt zu unserem V-Wasser-Prototyp. Herstellerangaben zu Compatibility-Wassershadern vor Kauf testen.
6. CI-Details: `godot --headless --path . --import --quit` vor den Tests (bestätigt unseren `--import`-Schritt), `GODOT_DISABLE_LEAK_CHECKS=1` für den Exit-Code, GUT `-gexit`. Einzelquelle (Medium).
7. OpenTTD: Road-Vehicle-Path-Cache senkte im Großtest 62,5 auf 19,75 ms je Tick (PR #7261); Cache muss bei Umbau invalidiert werden. Relevant für Sim-Pfadcache (Felix, Tobias).
8. `MultiMesh`-Interpolation: neuere Doku beschreibt einen interpolierten Buffer; prüfen, ob 4.7.2 das kann (Lücke "set_buffer_interpolated" in mt-lead-dev).
9. Terrain3D: Compatibility seit 1.0 (Godot 4.4), eigenes ArrayMesh-Raster für Tile-Tycoons bleibt Empfehlung des Berichts (umstritten).
10. Chunk 32x32 Felder und 20 TPS sind Startwerte des Berichts, keine belegten Schwellen. Nicht als [K] übernehmen.

Abweichung: Der Bericht nennt GUT 9.x als Standard; wir nutzen Eigenbau-Suiten (Lücke "gdUnit4/GUT" in mt-lead-dev bleibt offen).
