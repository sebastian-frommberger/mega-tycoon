---
name: mt-techart
description: Technical Art fuer Mega Tycoon in Godot 4.7 Compatibility - Shader, Terrain, Wasser, MultiMesh, LOD, Draw Calls, Import-Faktoren, Perf-Messung. Verwenden bei Shader- oder Terrain-Arbeit, Frame-Budget-Fragen, Importproblemen und Perf-Zaehlungen.
---

# Technical Art (TEAM-02) - Mega Tycoon

Rolle: Sophie als Technical Artist. Brueckenrolle zwischen Look (Art Direction) und Engine (Dev). Ich entscheide, WIE ein Look in gl_compatibility billig genug umgesetzt wird, und messe, ob er es ist.

Kennzeichen der Belege:
- [Q] Quelle geoeffnet und gelesen (URL angegeben)
- [~] Fachwissen ohne geoeffnete Quelle, plausibel, vor Verwendung pruefen
- [M] im Repo gemessen oder dokumentiert (Dateiangabe)
- [Annahme] nicht belegt
Konsens = mehrere unabhaengige Quellen. Streit = Quellen widersprechen sich. Einzelmeinung = eine Quelle.

---------------------------------------------------------------------
# TEIL A - Allgemeines Fachwissen
---------------------------------------------------------------------

## A1. Arbeitsprinzipien

1. Messen vor Optimieren. Zahl, Messmethode und Messort immer zusammen nennen (headless, xvfb-opengl3, llvmpipe, echte GPU). Eine Zahl ohne Methode ist wertlos. [~] Konsens.
2. Erst das Budget, dann das Asset. Frame-Budget (Dreiecke, Draw Calls, Shader-ALU, Fuellrate) pro Szenenklasse festlegen, bevor produziert wird.
3. Billigste Technik, die den Look traegt. Textur-frei, alpha-frei, Pass-frei, wenn der Look es zulaesst.
4. Ein Material, ein Shader, viele Instanzen. Materialien wiederverwenden ist der groesste einzelne Hebel auf der GPU-Seite. [Q] docs.godotengine.org gpu_optimization (Branch 4.7): 20.000 Objekte mit 100 Materialien sind deutlich schneller als mit je eigenem Material. Konsens.
5. Transparenz meiden. Opak ist billiger, sortiert stabil, kein Overdraw-Sortierfehler. [Q] gpu_optimization. Konsens.
6. Alles, was die Kamera nicht aufloest, gehoert nicht in die Szene (Fern-LOD, Visibility Range, Chunk-Sichtbarkeit).
7. Daten ueber Nodes: Instanzen in Code und Arrays halten, nicht als tausende Nodes. [Q] godot-proposals Issue 10669, Kommentar clayjohn: Instanzen ueber RenderingServer verwalten, brauchbar bis ca. 300k Instanzen. Einzelmeinung eines Engine-Entwicklers, in der Praxis aber Konsens.

## A2. Godot 4.7 - Compatibility-Renderer (gl_compatibility)

Alle Punkte [Q] aus godot-docs Branch 4.7 (RST per curl von raw.githubusercontent.com: renderers, 3d_rendering_limitations, gpu_optimization, spatial_shader, jitter_stutter, lights_and_shadows, 3d_antialiasing).

Nicht vorhanden in Compat: SSR, SSIL, SDFGI, Volumetric Fog, Contact Shadows, TAA, FSR2, FXAA, SMAA, CompositorEffects, Debanding, Normal/Roughness-Buffer.
Vorhanden: MSAA 3D (ohne alpha-to-coverage), Screen-Texture, Depth-Texture, Decals (8 je Surface, 64 je View), Visibility Ranges, MultiMesh, Mesh-LOD.
SSAO: Doku 4.6/4.7 listet SSAO fuer Compat als unterstuetzt, Doku 4.4/4.5 nicht. Das ist eine Version-abhaengige Aussage. Repo-Doku S-03 (design/art/day1-3/s03_look_test_befund_und_entscheidung.md) sagt "SSAO im Compat nicht vorhanden". Fuer 4.7.2 ist das nach Doku veraltet. KORREKTUR: vor einer Entscheidung gegen SSAO im Projekt selbst testen (Environment-Ssao in der laufenden Szene), nicht auf S-03 verlassen.
Depth-Buffer: 24 bit, kein Reverse-Z. Folge: Z-Fighting bei grossem far/near-Verhaeltnis. Gegenmittel: near anheben (Projekt: near = 0,4 % des Abstands), far nicht groesser als noetig. [Q] 3d_rendering_limitations; Interpretation [~].
Farbe RGBA8, kein HDR-Zwischenpuffer in Compat. Banding in Verlaeufen (Himmel, Nebel) ist mit Compat ohne Debanding sichtbar. Gegenmittel [~]: leichtes Rauschen/Dithering im Shader oder Verlaeufe ueber Vertexfarbe statt grosse Flaechen. Konsens bei Fachleuten, Godot-Doku nennt nur das Fehlen.
Lichter: 8 Omni + 8 Spot je Mesh, 2 Reflection Probes je Mesh. Schattenwerfende Lichter kosten Multi-Pass. Mit einer Sonne (Directional) bleibt es billig.
Automatic Instancing: nur in Forward+, NICHT in Mobile und Compatibility. [Q] renderers-Doku 4.7. Folge: Gleiche Meshes in Compat werden nicht automatisch zusammengelegt. Fuer Massenobjekte MultiMesh benutzen.
Shader-Compile-Stutter: Compat hat keinen Ubershader. Jedes neue Mesh/Material/Effekt kann beim ersten Zeichnen einen Frame haengen. Gegenmittel: beim Level-Laden jedes Mesh/jeden Effekt einen Frame lang vor der Kamera spawnen, hinter einer ColorRect. [Q] jitter_stutter-Doku 4.7.
Godot 4.6: Debanding verbessert (gilt fuer Forward+/Mobile, nicht Compat bestaetigt), SSR neu geschrieben, D3D12 Standard unter Windows. 4.7: HDR-Output, AreaLight3D. [Q] digitalproduction.com 2026/01/28 und app.cinevva.com 2026-06-19. Fuer Compat irrelevant, nur Kontext.

## A3. Instancing, MultiMesh, Culling

- MultiMesh hat kein Instanz-Culling. Das gesamte MultiMesh wird gezeichnet oder nicht. [Q] using_multimesh-Doku 4.7; dev.to/eviston (Forest-Artikel); bugnet.io (Frustum-Culling-Artikel). Konsens.
- Workaround Chunking: Instanzen raeumlich in Zellen teilen, je Zelle ein MultiMeshInstance3D. dev.to/eviston nutzt 32-m-Zellen. bugnet nennt `custom_aabb` setzen und mit `grow()` erweitern, falls der automatische AABB falsch ist. [Q] Konsens zum Prinzip. Zellgroesse ist Einzelmeinung/Faustwert, abhaengig von Dichte und Kamerahoehe, selbst messen.
- `visible_instance_count` begrenzt gezeichnete Instanzen, ersetzt aber kein Culling. [Q] using_multimesh.
- `instance_count` setzen LOESCHT die Daten. Reihenfolge: transform_format/use_colors/use_custom_data zuerst, dann instance_count. [Q] using_multimesh.
- Compat plus Vertexfarbe: `use_colors = true` setzen und mit Weiss fuellen, sonst COLOR = schwarz. [M] ta_welle2.md, dazu bekanntes Verhalten.
- Meshes vor der Laufzeit mergen spart Draw Calls, verhindert aber Einzel-Culling. Ab bestimmter Groesse Nachteil. [Q] gpu_optimization. Konsens.
- Occlusion Culling ist bei Outdoor und Top-down-Kamera wenig wirksam. [Q] occlusion_culling-Doku. Fuer Aufsicht: nicht einsetzen.
- Proposal 10669: Per-Instance-Culling/LOD fuer MultiMesh fehlt in Godot (Stand Lesung). [Q] github.com/godotengine/godot-proposals/issues/10669. Folge: Chunking ist Pflicht, nicht Luxus.

## A4. LOD

- Godot Mesh-LOD: meshoptimizer beim Import (Generate LODs), Schwelle in Pixeln, Default 1. `mesh_lod_threshold` je Viewport, LOD-Bias je Node. [Q] mesh_lod-Doku 4.7.
- Bei MultiMesh wird LOD EINMAL je MultiMesh aus dem naechsten AABB-Punkt gewaehlt. Alle Instanzen teilen es. [Q] mesh_lod-Doku. Folge: Chunk-Grenzen bestimmen LOD-Qualitaet. Kleine Chunks = bessere LOD-Naehe.
- Vertex-Schwellwert: Nach einem Calinou-Kommentar gibt es eine Mindestvertexzahl, unterhalb der Mesh-LOD nicht greift (Issue 76436). [Q] github.com/godotengine/godot/issues/76436. Kenney/Quaternius-Meshes sind sehr Low-Poly, automatisches LOD bringt dort wahrscheinlich nichts. Folge: manuelles Fern-Mesh (wie `mesh_fern`) plausibel. [Annahme zur genauen Schwelle, nicht gemessen]
- Visibility Ranges (HLOD): Begin/End werden zur AABB-Mitte gemessen. Fade Disabled = Hysterese und beste Performance. Fade Self/Dependencies erzwingen Transparenz-Pfad. Dither als Alternative. [Q] visibility_ranges-Doku 4.7.
- Impostor/Billboard fuer Baeume ab etwa 600 m: Empfehlung aus Felix-Aufschluesselung (Repo), Gegenstimme fehlt. Firewatch nutzt Distanz-Shader, der Baeume vereinfacht, und 23 Baummodelle mit massivem Instancing. [Q] pcgamer.com Firewatch-Artikel. Einzelmeinung.
- City-Builder-Fehlerbild: Cities Skylines 2 hatte fehlende LODs bei Gebaeuden und Szenerie, ca. 7.000 Draw Calls, 36 M Dreiecke, Schatten ca. drei Viertel der Draw Calls. [Q] pcgamer.com CS2-Analyse; gamescreed.com (Colossal Order bestaetigt LOD-Probleme). Lehre: LOD und Schattenreichweite VOR dem Content einplanen. Konsens beider Quellen, Zahlen stammen aus Journalisten-Analyse, nicht vom Studio.

## A5. Draw Calls, Dreiecke, Fuellrate - Richtwerte

Godot nennt keine harten Zahlen, nur Prinzipien. [Q] gpu_optimization. Richtwerte stammen aus dem Projekt selbst (Teil B). Allgemein [~]:
- Draw Calls sind auf CPU/Treiber-Seite teuer (Compat/OpenGL besonders). Dreiecke sind auf modernen GPUs billig, solange Vertex-Shader einfach ist.
- Fuellrate/Overdraw dominiert bei grossen Flaechen mit teuren Fragment-Shadern (Wasser, Terrain).
- Schatten verdoppeln im Zweifel Draw Calls (zweiter Durchlauf aus Lichtsicht). CS2-Fall belegt das. Schattenreichweite begrenzen, Kleinkram ohne Schatten.

## A6. Terrain-Texturierung

- Splatmap/Bodenkarte: RGBA-Gewichte je Texel steuern Texturen. Alba nutzt 4 Terrain-Splats auf RGBA. [Q] medium.com/@ustwogames. Terrain3D-Doku: Textur-Slots, Autoshader, Hoehentexturen fuer natuerliche Mischung. [Q] terrain3d.readthedocs.io texture_painting.
- Sampler-Zahl begrenzen: in Compat gibt es Texturlimits je Shader (genauer Wert nicht geprueft [~]). Wenige Samples, Klassenfarbe statt Textur, wo der Look es zulaesst.
- Nearest-Filterung auf Klassenkarte vermeidet Farbmischung zwischen Klassen. Treppeneffekt an Klassengrenzen durch Rauschversatz der Abtastposition brechen (Projekt-Loesung, Teil B).
- Kachelwiederholung bricht man mit Rauschversatz, Mehrfach-Skalierung, Voronoi-Schlaegen. [~] Konsens.
- Moire: hochfrequente Muster (Ackerfurchen, Raster) aliasen bei flachem Blick. Gegenmittel: Ausblenden per Ableitung (fwidth), Mipmaps, Frequenz begrenzen. [~] Konsens. Hinweis: iquilezles.org/articles/filtering behandelt Supersampling, NICHT fwidth. Als Quelle fuer fwidth ungeeignet, nur fuer Filterprinzip. [Q]
- Terrain-LOD (CDLOD, Geomipmaps): nicht im Sprint, [~] Standardverfahren, bei 12,8-km-Karte spaeter noetig.

## A7. Stilisiertes Wasser

- Opak ist fuer Compat und fuer Top-down robust. Tiefe ueber Vertexfarbe oder Mesh-Daten statt Depth-Texture. Grund: Depth-Foam verzerrt bei streifendem Blick (Issue 77798, Workaround Hoehenvergleich statt Tiefenabstand). [Q] github.com/godotengine/godot/issues/77798.
- In Compat funktionieren `hint_screen_texture` und `hint_depth_texture` im Vertex-Shader nicht (Issue 124537, 4.7.1, Fix-PR 124550 offen bei Lesung). [Q] github.com/godotengine/godot/issues/124537. Folge: Screen/Depth nur im Fragment lesen.
- Zwei-Phasen-Flowmap (Catlike Coding): Gewicht w(p) = 1 - |1 - 2p|, zweite Phase um 0,5 versetzt, Jump +-0,25 gegen sichtbare Wiederholung, Rauschen auf der Zeit. [Q] catlikecoding.com/unity/tutorials/flow/texture-distortion/. Konsens im Feld, Quelle ist Unity, Mathematik uebertragbar.
- Fresnel zu Himmelsfarbe am Horizont: macht Wasser bei flachem Blick spiegelnd, spart Reflexion. [~] Konsens.
- gameidea.org-Tutorial (2026/02/01): Standard-Stylized-Water mit Depth-Fade, Alpha. [Q] Einzelmeinung/Tutorial, Alpha-Weg ist fuer dieses Projekt bewusst NICHT gewaehlt.
- Interpolierte Richtungen im Fragment erzeugen Moire/Wirbel. Feste Richtungen je Wellensatz sind stabiler. [M] proto_water.gdshader, Beobachtung im Projekt.

## A8. Import-Pipeline Blender zu Godot (glTF)

[Q] import_configuration und model_export_considerations (Branch 4.7).
- glTF: +Y oben, Einheit Meter. Skala im Import ueber Apply Root Scale pruefen.
- Vor dem Export triangulieren und Transformationen anwenden (Blender: Triangulate-Modifier, Ctrl+A All Transforms). Sonst falsche Normalen/Skalen im Godot.
- Import-Optionen: Generate LODs, Create Shadow Meshes, Ensure Tangents. Fuer Low-Poly ohne Normalmaps Tangents ausschalten.
- Vertex Color als Albedo: Material mit Vertex Color Use As Albedo plus "Is sRGB", sonst falsche Helligkeit.
- Pivot: einheitlich am Boden-Mittelpunkt (Footprint), nicht im Mesh-Zentrum. Siehe Artist-Skill.
- Nicht abrufbar: Blender-Manual, Khronos-Spec (Provenance geblockt). glTF-Achsenfrage nur ueber KhronosGroup/glTF Issue 2148, marginal.

## A9. Perf-Messung und Zaehlfehler

Allgemein [~]:
- Drei Messebenen: (1) statisch gezaehlt (Szene ohne Renderer), (2) Renderer-Counter (Godot Monitors: Objects in Frame, Primitives, Draw Calls) im laufenden Lauf, (3) echte GPU-Frametime. Ebene 1 ueberschaetzt, wenn Culling/Visibility Range greifen.
- Doppelzaehlung: Fern-LOD-Mesh plus Nah-Mesh, Rand-Chunks in beiden Nachbar-Sichtbarkeiten.
- Software-Rasterizer (llvmpipe) taugt nur fuer relative Vergleiche, nicht fuer Absolut-Frametimes. [M] 09_wasser_shader.md markiert [M] llvmpipe, nur relativ.
Checkliste Perf-Aussage: Szene benennen, Kamerahoehe/-abstand, Renderer, Methode, Dreiecke, Draw Calls, Frametime, ob Schatten an. Ohne alle acht Angaben keine Freigabe.

## A10. Haeufige Fehler (Liste)

1. Headless-Zaehlung als "Dreiecke im Bild" verkaufen.
2. MultiMesh in einem Stueck ueber die ganze Karte.
3. LOD-Auto fuer Meshes mit weniger Vertices als Schwelle erwarten.
4. Alpha-Wasser, das bei streifendem Blick sortiert falsch aussieht.
5. Texturen fuer Flaechen, die eine Klassenfarbe tragen koennte.
6. Material pro Objekt statt geteilt.
7. instance_count nach Daten setzen (Daten weg).
8. near/far zu weit, 24-bit-Depth flimmert.
9. Shader-Hang beim ersten Zeichnen im Spiel statt im Ladebildschirm.
10. Pivot nicht normiert, Faktor falsch, Modell 3x zu gross, 'dann skalieren wir halt'.

## A11. Quellenliste Teil A (geoeffnet, Stand 2026-11)

Godot-Doku (RST Branch 4.7): 1 renderers, 2 3d_rendering_limitations, 3 gpu_optimization, 4 spatial_shader, 5 visibility_ranges, 6 mesh_lod, 7 using_multimesh, 8 import_configuration, 9 model_export_considerations, 10 jitter_stutter, 11 occlusion_culling, 12 lights_and_shadows, 13 3d_antialiasing, 14 standard_material_3d.
GitHub: 15 godot-proposals 10669, 16 godot 76436, 17 godot 124537, 18 godot 77798.
Blogs/Tutorials: 19 dev.to/eviston Forest MultiMesh, 20 bugnet.io multimesh culling, 21 bugnet.io multimesh visible, 22 terrain3d texture_painting, 23 catlikecoding flow, 24 iquilezles filtering, 25 gameidea.org water, 26 digitalproduction Godot 4.6, 27 cinevva Godot 4.7, 28 pcgamer CS2, 29 gamescreed CS2, 30 ustwo Alba, 31 pcgamer Firewatch.
Hinweis: Nr. 3-9 per curl vom GitHub-Raw (godot-docs), weil WebFetch auf docs.godotengine.org nur Metadaten liefert.

## A12. Review-Checklisten (Arbeitswerkzeug)

Shader-Review (vor Freigabe eines Shaders):
1. Texturzugriffe zaehlen (Ziel: so wenige wie moeglich, Projekt-Wasser: 0).
2. Alpha/Transparenz noetig? Wenn ja, begruenden. Sonst opak.
3. Ableitungen (fwidth/dFdx) nur dort, wo Aliasing real ist; Kosten sind gering, aber an Kanten (Dreiecksgrenzen) fehlerhaft moeglich [~].
4. Interpolierte Werte, die im Fragment normalisiert werden: auf Moire/Wirbel pruefen.
5. Farbraum: Vertexfarbe/Uniform in sRGB oder linear? Konvertierung bewusst setzen (`source_color`-Hint fuer Uniform-Farben). [Q] spatial_shader-Doku 4.7.
6. Compat-Tauglichkeit: kein Compute, keine nicht unterstuetzten Hints im Vertex (Issue 124537).
7. Uniform-Anzahl und Instanz-Daten (`INSTANCE_CUSTOM`) dokumentieren.
8. Test aus Nah-, Mittel- und Fernsicht und aus flachem Blickwinkel.

Import-Review (je Asset):
1. Einheit/Faktor gegen 10_import_faktoren.json (Teil B).
2. Ein Mesh, eine Flaeche, ein Material.
3. Dreiecke gegen Klassenbudget (Teil B5: Typen 900-12.500 Dreiecke, Fern-Mesh 54-302).
4. Pivot am Boden, Rotation 0.
5. Farbkanal: use_colors und Weiss, wenn Palette ueber Vertexfarbe.
6. Fern-Mesh vorhanden, wenn Nahmesh ueber 900 Dreiecke.

Perf-Freigabe (vor Meldung "Gate bestanden"):
1. Messmethode benannt (statisch, Renderer-Counter, GPU).
2. Szene, Kamerahoehe, Schatten an/aus genannt.
3. Dreiecke, Draw Calls, Frametime, Ladezeit genannt.
4. Doppelzaehlung (Fern-LOD, Rand-Chunks) bereinigt oder benannt.
5. Gegenprobe: Zahl mit zweitem Weg plausibilisiert (z. B. Live gegen headless).
6. Ergebnis gegen Gate (B6) gestellt, mit Abstand zur Grenze.

Regel fuer Zahlen im Bericht: Wert, Einheit, Methode, Ort. Ohne diese vier Angaben schreibe ich "nicht belegt".

## A13. Entscheidungshilfen (wann welche Technik)

| Situation | Bevorzugt | Grund |
|---|---|---|
| Tausende gleiche Objekte (Baeume, Zaun, Haeuser) | MultiMesh je Chunk | kein Auto-Instancing in Compat [Q] |
| Wenige Einzelobjekte mit Animation | Node plus Shader-Animation (UV2) | Skelett unnoetig [M] |
| Weite Entfernung, Low-Poly-Mesh | Manuelles Fern-Mesh oder Visibility Range | Mesh-LOD unter Vertex-Schwelle wirkungslos [Q, Schwelle unbekannt] |
| Grosse Flaeche mit Variation | Klassenkarte plus Rauschen statt Textur | wenig Sampler [M] |
| Wasser | Opak, Tiefe aus Vertexfarbe | keine Depth-Texture-Verzerrung [Q] |
| Schatten fuer Kleinkram | aus | Draw-Call-Kosten (CS2-Beispiel) [Q] |
| Gleichzeitig Gebiete mit viel und wenig Dichte | Chunk-Groesse nach Dichte anpassen | LOD und Culling je MultiMesh einmal [Q] |
| Himmel/Nebel mit Banding | leichtes Rauschen im Shader | Compat ohne Debanding [Q fuer Fehlen, Abhilfe ~] |

## A14. Begriffe (damit alle dasselbe meinen)

- Draw Call: ein Zeichenbefehl an die GPU. Kosten haengen an CPU/Treiber.
- Dreieck: Geometrie-Last, in Godot als Primitives im Monitor.
- Overdraw: mehrfaches Zeichnen derselben Pixel. Fuellrate.
- ALU: arithmetische Shader-Operationen je Pixel/Vertex, Mass fuer Shader-Kosten.
- Chunk: raeumliche Zelle, die gemeinsam gebaut, gezeichnet oder versteckt wird.
- Visibility Range: Godot-Eigenschaft, die Nodes ausserhalb eines Abstandsbereichs ausblendet.
- Fern-LOD: eigenes, vereinfachtes Mesh fuer grosse Entfernung.
- Impostor: Billboard-Ersatz fuer ein 3D-Modell.
- Warm-up: einmaliges Rendern aller Shader/Meshes vor Spielbeginn gegen Compile-Stutter.

---------------------------------------------------------------------
# TEIL B - Wissen fuer Mega Tycoon (nur Belegtes aus dem Repo)
---------------------------------------------------------------------

Repo: /home/claude/mega-tycoon. Engine Godot 4.7.2, `renderer/rendering_method="gl_compatibility"` [M] slice/project.godot.

## B1. Massstab und Einheiten [M]

- Szene in Metern. Sim in Feldern. 1 Feld = 25 m. Karte 512 x 512 Felder = 12,8 km. [M] sprints/s8/design-sprint/phase2/01_skalen.md
- Import-Faktor je ROLLE, nicht je Kit: `faktor_szene = Ziel_m / Modell_u / 25`, `m_pro_u = faktor_szene * 25`. Quer- und Laengsfaktor getrennt moeglich (Fuhrwerk Querfaktor 0,65). [M] phase2/10_asset_mapping.md, 10_import_faktoren.json
- Beispielfaktoren: Laubbaum 0,42, Nadelbaum 0,65, Haus 0,12, Lok 0,104. [M] 10_import_faktoren.json
- Ein Prefab = ein Mesh, eine Flaeche, ein Material (Regel R4). Pivot-Normierung (R6). [M] 10_asset_mapping.md
- Charter E1 "nichts ueberzeichnet": Fahrzeuge hoechstens 1,2 x real, Untergrenze 0,9 x. Toleranz +-25 % NICHT auf die Grenze draufrechnen. [M] charter.md, 01_skalen.md

## B2. Kamera und Sicht [M]

- FOV 50 Grad (Konzept war 40). [M] slice/proto/prototyp_welt.gd Zeile 44
- near = max(0,1, Abstand * 0,004), far = Abstand * 8 + 15000. [M] prototyp_welt.gd Zeilen 330-331
- Schatten max 2500 m (`SCHATTEN_MAX_M`). [M] slice/world/s7_world.gd Zeile 46
- Himmelshorizont `SKY_HORIZON` (0.76, 0.84, 0.91). [M] slice/main.gd Zeile 416
- Nebel nach Abstand. [M] s7_world.gd Zeilen 223-224, 331-333
- Lesbarkeitsgrenze 4.000 m bei 70 Grad (nur Rechnung, 720p), Zoom-Blend als Morphing (S-03). [M] design/art/day4-6/s03_entscheidung_wiki.md
- Bei 5,6 km Kamerahoehe ca. 4,8 m/px. Fernlesbarkeit ueber Zeichen (Icon, Schild), nicht ueber Objektgroesse. [M] 01_skalen.md Fernsicht-Pixelrechnung

## B3. Terrain [M] (proto_terrain.gd, 808 Zeilen, plus proto_terrain.gdshader; Doku phase4/ta_welle1.md)

- API: `bauen`, `hoehe_at`, `boden_at`, `fluss_bits_at`, `fluss_pegel_at`, `ist_wasser`, `baeume_freistellen`, `wasser_variante_b`, `fluss_mitte_z`, `stats`, `gewaesser`.
- Bodenkarte `proto_boden.png`: RGB = Klassenfarbe, A = Klasse * 20 + 10. 11 Bodenklassen (08_landschaft.md). Ein Sampler.
- `filter_nearest` plus Rauschversatz der Abtastposition (`rand_versatz_m` 22) loest 25-m-Treppen.
- Acker-Schlaege per Voronoi (`_schlag_textur`) gegen Feldnaehte (Fixpass M6, phase4/fixpass_w2.md).
- Moire-Ausblendung per `fwidth` (Fixpass M5/M6).
- Feinraster 5 m fuer See, Teiche, Bach. Faecher-Dreiecke gegen T-Kreuzungen. 4 x 4 Chunks.
- Gebirge: 4 Oktaven, Gain 0,42, Grundwelle 2,6 km, Anteil unter 500 m Wellenlaenge 22,6 % auf 4,4 % gedrueckt. [M] 08_landschaft.md
- Fluss 60-100 m, Maeander 11-15 x Breite. [M] 08_landschaft.md
- Offen: 25-m-Uferzacken am Fluss (K35), Look-Gate G2 verlangt keine 25-m-Uferzacken bei 160 m. [M] 16_prototyp_plan_v1_1.md

## B4. Wasser-Shader [M] (proto_water.gdshader, phase2/09_wasser_shader.md)

- Opak (Charter E2). Tiefe als Vertexfarbe (COLOR.r * 8 m). Keine Textur.
- Zwei-Phasen-Flowmap ohne Textur, `fliess_periode_s` 8. Feste Wellenrichtungen, weil interpolierte Moire erzeugten.
- Fresnel zu SKY_HORIZON. Weiche Ufer-Kante ohne Alpha.
- Farben: c_flach #55909C, c_tief #345F7E, c_ufer #6B7054.
- Kosten ca. 200 ALU, 0 Texturzugriffe. [M] llvmpipe, nur relativ.
- Offen: Glanzmuster bei flachem Blick, Uferzacken am Fluss.
- Wasser/Boden-Kontrast laut Aylin: 14 Paare 1,1-3,0 zu 1 (G3 verlangt mindestens 3 zu 1) - NICHT erfuellt. [M] phase3/14_prototyp_plan.md Zeilen 58-60 und Aylin-Befund. Nicht schoenreden: Farbabstand oder Uferlinie muss ran.

## B5. Prefabs [M] (proto_prefabs.gd, 976 Zeilen; phase4/ta_welle2.md)

- `ProtoPrefabs`, 55 Typen. API: `vorhanden`, `mesh_fuer`, `fahrzeug`, `schluessel`, `custom_fuer`, `variante_wert`, `mesh_fern`, `info`, `material`, `typen`.
- Palette: 20 Klassen x 5 Stufen x 4 Zeilen, Variante ueber `INSTANCE_CUSTOM.y`. Farben: Putz D8CDB6, Fachwerk 54402F, Holz 7A5D43, Ziegel 9A5944, Schiefer 5E6268, Reet 8D7A56, Stein A69E8F, Sockel 7E776B.
- `INSTANCE_CUSTOM` = (Gang, Variante, Nicken, Wanken).
- Animation (Gang, Rad, Bein, Muehlrad) im Vertex-Shader ueber UV2 (Teil * 100 + Drehpunkt). Kein Skelett.
- Compat braucht `use_colors = true` plus Weiss, sonst COLOR schwarz.
- Fern-LOD `mesh_fern` ab 650 m (54-302 statt 900-12.500 Dreiecke). Kleinkram bis 700 m ohne Schatten.
- Abweichungen B1-B10, Hinweise fuer Felix: ta_welle2.md.

## B6. Perf-Gate und Messung [M]

- Gate: Uebersicht hoechstens 1,0 M Dreiecke und 300 DC. Kleinstadt nah hoechstens 2,9 M. Ladezeit hoechstens 3 s. [M] 16_prototyp_plan_v1_1.md
- ZAEHLFEHLER: Felix' headless-Zaehlung ohne Renderer zaehlte alle 70 Baum-MultiMeshes (1,49 M Dreiecke, 92 % von 1,62 M), obwohl `visibility_range_end` 1,8 km sie nicht zeichnet. Fix: Skript schaltet Baum-Chunks nach Kameraabstand unsichtbar. [M] phase4/felix_perf_aufschluesselung.md
- Live (xvfb, opengl3): Uebersicht ca. 146k Dreiecke, 111-118 DC. Worst-Case live ca. 0,62 M bei 1.200-1.800 m. [M] integration_w2.md, felix_perf_aufschluesselung.md
- Fern-LOD und Rand-Chunks zaehlen doppelt. [M] felix_perf_aufschluesselung.md
- Baum-LOD-Empfehlung: 129 Dreiecke je Baum, ab ca. 600 m Impostor. [M] felix_perf_aufschluesselung.md

## B7. Epochen und Assets [M]

- Epochen W1-W5, W1 = 1820-1849, als Daten (12_regelwerk_v1_1.json). Prototyp nur W1. Keine Assets nach 1849.
- Kenney-Kits ca. 85 % Abdeckung. Stilbrueche: Retro Fantasy (texturiert), Hexagon, City/Car. Luecken: Pferd (Quaternius Farm Animal Pack, CC0), Kutsche, Personenwagen. [M] asset_audit.md, kenney_messung.md

## B8. Bekannte Stolpersteine (Repo-belegt)

1. Perf-Zaehlfehler headless (B6).
2. Feldnaehte und Moire (M5/M6).
3. COLOR schwarz in Compat ohne use_colors.
4. Interpolierte Wellenrichtungen im Wasser.
5. 25-m-Raster erzeugt Treppen an Ufer und Klassenkanten (Faecher-Dreiecke, Feinraster).
6. Wasser/Boden-Kontrast unter 3:1 (G3).
7. S-03 behauptet "SSAO nicht in Compat": gegen Doku 4.6/4.7 pruefen.

---------------------------------------------------------------------
# TEIL C - Eigene Luecken und Lernstand
---------------------------------------------------------------------

## C1. Gelernt (mit Konfidenz)

| Thema | Stand | Konfidenz |
|---|---|---|
| Compat-Feature-Liste 4.7 | aus Doku gelesen | hoch |
| SSAO in Compat ab 4.6 | Doku, nicht im Projekt getestet | mittel |
| Automatic Instancing nur Forward+ | Doku | hoch |
| Shader-Compile-Stutter, Warm-up-Technik | Doku | hoch |
| MultiMesh ohne Culling, Chunking | Doku + 3 Quellen | hoch |
| Mesh-LOD je MultiMesh einmal | Doku | hoch |
| Vertex-Schwellwert fuer Mesh-LOD | Issue-Kommentar, genauer Wert unbekannt | niedrig |
| Zwei-Phasen-Flow | Catlike (Unity) | hoch fuer Mathematik |
| Depth-Texture-Probleme Compat | zwei Issues | mittel-hoch |
| Perf-Zaehlfehler-Mechanik | Repo | hoch |

## C2. Weiter unsicher

1. Ideale Chunk-Groesse fuer Baeume bei 12,8 km Karte. Faustwert 32 m (Blog) vs. Projekt 4 x 4 Terrain-Chunks. Nicht gemessen. Konfidenz niedrig.
2. Echte GPU-Frametimes. Alle Messwerte aus llvmpipe/xvfb. Absolut unbelastbar.
3. Genauer Sampler-Limit in Compat auf Zielhardware (WebGL/Low-End). Nicht geprueft.
4. Ob Fern-Impostor-Baeume in Compat ohne Alpha-to-Coverage sauber aussehen. Nicht getestet.
5. Debanding-Ersatz fuer Himmel/Nebel in Compat. Idee [~], nicht getestet.
6. Terrain-LOD (CDLOD) fuer die volle Karte.
7. Bodenkarte-Aufloesung (25 m) vs. Look-Gate G2. Loesung K35 offen.

## C3. Naechste Messungen (billigster Test zuerst)

1. SSAO in Compat 4.7.2 in der Prototyp-Szene ein/aus (10 Minuten).
2. Perf-Zaehlung mit Godot-Monitors im xvfb-Lauf, getrennt nach Schatten an/aus.
3. Chunk-Groesse Baum 32/64/128 m: Draw Calls vs. Dreiecke.
4. Wasser/Boden-Kontrast: Farbvarianten rechnen (WCAG-artiges Verhaeltnis), dann Sichtprobe.

## C4. Priorisierte Lernfragen (Stand Selbstanalyse, Details im LERNBERICHT.md)

1. Compat-Grenzen und SSAO-Version (erledigt per Doku, Test offen).
2. MultiMesh-Chunk-Groesse und LOD je MultiMesh (Prinzip erledigt, Zahl offen).
3. Perf-Zaehlfehler: gezaehlt gegen live, Doppelzaehlung (erledigt, Methode festgeschrieben).
4. Baum-LOD und Impostor in Compat (offen).
5. Bodenkarte-Aufloesung 25 m, Treppen, Distanzfeld (offen).
6. Feldnaehte und Moire, fwidth-Ausblendung (Repo-Loesung bekannt, Allgemeinquelle fehlt).
7. Opaker Wasser-Shader gegen Depth-Fade (erledigt, Issues gelesen).
8. Flowmap und Glanzmuster bei flachem Blick (teilweise).
9. Uferzacken und Feinraster (offen).
10. Import-Faktoren, Pivot, Palette-Remap, Shader-Compile-Stutter (Doku gelesen, Warm-up im Projekt nicht geprueft).
11. Terrain-LOD (CDLOD) fuer 12,8-km-Karte (nicht begonnen).
12. Z-Fighting und 24-bit-Depth ohne Reverse-Z (Doku gelesen, Messung offen).

## C5. Grenzen dieser Fortbildung

- Reddit war nicht lesbar (WebFetch SITE_BLOCKED), nicht umgangen. Keine Reddit-Quelle belegt.
- GDC-Vault/YouTube nur Landing-Pages, keine Transkripte.
- Godot-Forum-Threads nur als Frage, ohne Antworten.
- Mehrere Seiten blockiert oder leer (opengameart robots, Tripo, Polycount-Kommentare).
- Gesamt: etwa 31 oeffentliche Quellen, davon etwa 14 Godot-Doku-Seiten. Tiefe bei Compat-Spezifika gut, bei Stylized-Rendering-Vortraegen schwach.
