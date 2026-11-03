# Lernbericht Technical Art (Sophie, TEAM-02) - Mega Tycoon

Stand: 2026-11-03. Skill: /tmp/claude-0/gd/skills/mt-techart/SKILL.md. Repo unveraendert, kein Commit.

## 1. Selbstanalyse - wo Wissen fehlte (read-only im Repo)

Gelesen: design/art, sprints/s8/design-sprint (charter, asset_audit, phase2 01/08/09/10, phase3, phase3b, phase4 ta_welle1/2, fixpass_w2, integration_w2, felix_perf_aufschluesselung), slice/world/proto_terrain.gd, proto_prefabs.gd, alle *.gdshader, prototyp_welt.gd, s7_world.gd, project.godot.

Befunde:
- Entscheidungen im Repo stuetzen sich teils auf Annahmen ohne Quelle (S-03: "SSAO im Compat nicht vorhanden").
- Perf-Zahlen stammen aus llvmpipe/xvfb. Aussagekraft nur relativ.
- Ein Perf-Zaehlfehler (headless ohne Culling) blieb unbemerkt, bis Felix aufschluesselte.
- Mesh-LOD, Chunking und Visibility Range wurden nach Gefuehl eingesetzt, ohne Doku-Beleg.
- Wasser-Shader: Entscheidung "opak, Tiefe aus Vertexfarbe" war richtig, aber ohne Kenntnis der Compat-Depth-Texture-Issues begruendet.

## 2. Priorisierte Lernfragen (12)

| Nr | Frage | Prioritaet | Status |
|---|---|---|---|
| 1 | Was kann gl_compatibility in 4.7, was nicht (SSAO, Instancing, AA, Banding)? | hoch | beantwortet (Doku), Test offen |
| 2 | MultiMesh: Culling, Chunk-Groesse, LOD je MultiMesh? | hoch | Prinzip beantwortet, Zahl offen |
| 3 | Wie zaehlt man Dreiecke/Draw Calls ohne Zaehlfehler? | hoch | Methode festgeschrieben |
| 4 | Baum-LOD und Impostor in Compat? | hoch | offen |
| 5 | Bodenkarte 25 m: Treppen, Distanzfeld, Aufloesung? | mittel | offen |
| 6 | Feldnaehte/Moire: allgemeine Gegenmittel? | mittel | Fachwissen, keine Primaerquelle |
| 7 | Opaker Wasser gegen Depth-Fade? | mittel | beantwortet (Issues) |
| 8 | Flowmap, Two-Phase, Glanzmuster? | mittel | Mathematik beantwortet, Glanz offen |
| 9 | Uferzacken, Feinraster? | mittel | offen |
| 10 | Import-Faktoren, Pivot, Palette-Remap, Compile-Stutter? | mittel | Doku gelesen |
| 11 | Terrain-LOD (CDLOD) fuer 12,8 km? | niedrig | nicht begonnen |
| 12 | Z-Fighting bei 24-bit-Depth ohne Reverse-Z? | niedrig | Doku gelesen, Messung offen |

## 3. Quellen (geoeffnet) mit Einstufung

Godot-Doku (Branch 4.7, RST per curl von raw.githubusercontent.com/godotengine/godot-docs, weil WebFetch auf docs.godotengine.org nur Metadaten lieferte):
1. renderers (Compat-Featureliste, Automatic Instancing nur Forward+, SSAO ab 4.6) - Konsens/Primaerquelle
2. 3d_rendering_limitations (Depth 24 bit, kein Reverse-Z) - Primaerquelle
3. gpu_optimization (Materialien teilen, Transparenz meiden, Merge-Nachteil) - Primaerquelle
4. spatial_shader - Primaerquelle
5. visibility_ranges (Fade, Hysterese) - Primaerquelle
6. mesh_lod (Threshold, LOD je MultiMesh einmal) - Primaerquelle
7. using_multimesh (kein Culling, instance_count loescht Daten) - Primaerquelle
8. import_configuration - Primaerquelle
9. model_export_considerations (triangulieren, Transform anwenden) - Primaerquelle
10. jitter_stutter (Compile-Stutter, Warm-up) - Primaerquelle
11. occlusion_culling (Outdoor wenig wirksam) - Primaerquelle
12. lights_and_shadows - Primaerquelle
13. 3d_antialiasing (MSAA ja, TAA/FXAA/SMAA nein in Compat) - Primaerquelle
14. standard_material_3d - Primaerquelle

GitHub:
15. https://github.com/godotengine/godot-proposals/issues/10669 (Per-Instance-Culling fehlt, clayjohn: RenderingServer bis ca. 300k) - Einzelmeinung eines Entwicklers
16. https://github.com/godotengine/godot/issues/76436 (Vertex-Schwellwert LOD, Calinou) - Einzelmeinung, genauer Wert unbekannt
17. https://github.com/godotengine/godot/issues/124537 (Compat: Screen/Depth-Hint im Vertex-Shader, 4.7.1, Fix-PR 124550 offen) - Bugreport
18. https://github.com/godotengine/godot/issues/77798 (Depth-Foam verzerrt bei streifendem Blick) - Bugreport

Blogs, Tutorials, Presse:
19. https://dev.to/eviston/how-to-build-a-forest-in-godot-4-that-doesnt-kill-your-fps-multimesh-lod-and-visibility-ranges-1oi6 (32-m-Zellen) - Einzelmeinung
20. https://bugnet.io/blog/fix-godot-multimesh-frustum-culling-disabled-instances (custom_aabb, grow) - Einzelmeinung
21. https://bugnet.io/blog/fix-godot-multimesh-instance-not-visible - Einzelmeinung
22. https://terrain3d.readthedocs.io/en/latest/docs/texture_painting.html - Dokumentation eines Addons
23. https://catlikecoding.com/unity/tutorials/flow/texture-distortion/ (Two-Phase-Flow) - Konsens im Feld, Unity-Kontext
24. https://iquilezles.org/articles/filtering - behandelt Supersampling, NICHT fwidth (Gegenprobe: ungeeignet fuer fwidth-Beleg)
25. https://gameidea.org/2026/02/01/creating-a-stylized-3d-water-shader/ - Tutorial, Alpha-Weg
26. https://digitalproduction.com/2026/01/28/godot-4-6-arrives-with-major-cg-friendly-updates/ - Pressebericht
27. https://app.cinevva.com/de/news/2026-06-19-godot-4-7-released - Pressebericht
28. pcgamer.com CS2-Technikanalyse (ca. 7.000 DC, 36 M Dreiecke, Schatten ca. 3/4 der DC) - Journalistenanalyse
29. gamescreed.com CS2 (Colossal Order bestaetigt LOD-Probleme) - Presse
30. https://medium.com/@ustwogames (Alba: 4 Terrain-Splats auf RGBA) - Studio-Selbstdarstellung
31. pcgamer.com Firewatch-Baeume (Distanz-Shader, 23 Modelle) - Studio-Selbstdarstellung

Gezaehlt: 31 geoeffnete Quellen, davon 14 Godot-Doku. Mindestziel 15 erreicht.

## 4. Konsens, Streit, Einzelmeinung

Konsens: Materialien teilen; Transparenz meiden; MultiMesh braucht Chunking; Compat-Featureliste; Two-Phase-Flow-Mathematik; Compile-Stutter durch Warm-up.
Streit: Chunk-Groesse (32 m im Blog gegen Projekt-Terrain-Chunks, nicht vergleichbar); ob Mesh-LOD fuer Low-Poly nutzt (Calinou: Schwelle, Praxis ungeprueft).
Einzelmeinung: clayjohns 300k-Grenze; CS2-Prozentzahlen; Firewatch-Distanz-Shader.

## 5. Was gelernt wurde (Kernpunkte)

1. Automatic Instancing existiert in Compat nicht. MultiMesh ist Pflicht fuer Massenobjekte.
2. MultiMesh hat kein Instanz-Culling und waehlt LOD einmal je MultiMesh. Chunk-Grenzen sind Look- und Perf-Entscheidung.
3. S-03 "SSAO im Compat nicht vorhanden" ist fuer 4.6/4.7 laut Doku veraltet. Vor Verwerfen im Projekt testen.
4. Compat hat kein Debanding, 24-bit-Depth ohne Reverse-Z, RGBA8: Banding und Z-Fighting sind Compat-typisch.
5. Compat hat keinen Ubershader. Warm-up beim Laden ist die dokumentierte Gegenmassnahme.
6. Perf-Zahlen immer mit Methode/Ort. Headless ohne Renderer ueberschaetzt (Baum-MultiMeshes 92 % der Zaehlung).

## 6. Offen und Konfidenz

- SSAO-Test im Projekt: nicht gemacht. Konfidenz in "SSAO geht in 4.7.2 Compat": mittel.
- Echte GPU-Frametimes: nie gemessen (llvmpipe). Konfidenz in Absolutwerten: niedrig.
- Chunk-Groesse Baeume, Impostor-Qualitaet, Terrain-LOD: nicht gemessen.
- fwidth-Ausblendung: Repo-Loesung bekannt, keine geoeffnete Primaerquelle.

## 7. Ehrliche Einschraenkungen

- Reddit: WebFetch SITE_BLOCKED. Ein curl-Versuch mit anderem User-Agent wurde vom Permission-System als Umgehung abgelehnt. Nicht weiter versucht, keine Spiegel benutzt. Keine Reddit-Quelle belegt.
- GDC Vault und YouTube: nur Landing-Pages, keine Transkripte. Stylized-Rendering-Vortraege (z. B. Firewatch, Dorfromantik) nicht gelesen.
- Godot-Forum-Threads: nur Fragen, keine Antworten lesbar.
- Nicht abrufbar (Provenance geblockt): godotengine.org/releases/4.7 und 4.6, Blender-Manual, meshoptimizer-GitHub, Khronos-Spec.
- Zusammenfassungen durch Fetch-Modelle sind teils unzuverlaessig (iquilezles behandelt kein fwidth). Nur belegt, was die Quelle wirklich sagt, sonst [~].
- Alle Perf-Zahlen im Skill stammen aus Repo-Dokumenten (llvmpipe/xvfb), nicht aus eigener Messung.
