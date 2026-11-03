# Lernbericht Artist (Sophie, TEAM-02) - Mega Tycoon

Stand: 2026-11-03. Skill: /tmp/claude-0/gd/skills/mt-art/SKILL.md. Repo unveraendert, kein Commit.

## 1. Selbstanalyse - wo Wissen fehlte (read-only im Repo)

Gelesen: asset_audit.md und asset_audit/, phase2/10_asset_mapping.md und 10_import_faktoren.json, ta_welle2.md (Prefab-API, Abweichungen B1-B10), fixpass_w2.md, kenney_messung.md, proto_prefabs.gd.

Befunde:
- Faktoren je Rolle sind sauber hergeleitet, aber ohne Vergleich mit Modular-Kit-Praxis.
- Luecken (Pferd, Kutsche, Personenwagen) sind benannt, aber keine Kitbash-Rezepte.
- Farbweg (Vertexfarbe gegen Colormap) je Kit nicht belegt gelesen.
- Lizenzlage Kenney/Quaternius bisher nur behauptet (CC0), nicht mit Quellen unterlegt.
- Fern-Meshes wurden von Hand gebaut. Hintergrund (Vertex-Schwelle des Mesh-LOD) war nicht bekannt.

## 2. Priorisierte Lernfragen (10)

| Nr | Frage | Prioritaet | Status |
|---|---|---|---|
| 1 | Kenney-Faktoren je Rolle, Quer-/Laengsfaktor | hoch | Regel klar |
| 2 | Kitbash fuer Kutsche und Personenwagen | hoch | allgemeines Rezept, Teile offen |
| 3 | Pferd in Qualitaet (Quaternius Farm Animal Pack) | hoch | Lizenz Blog, Qualitaet ungesichtet |
| 4 | Silhouetten-Test und Schwellwert | hoch | Prinzip klar, Wert Faustwert |
| 5 | Modular-Footprint und Pivot | mittel | gelernt, Projekt-Raster nicht nachgeprueft |
| 6 | Vertexfarbe gegen Colormap in den Kits | mittel | Repo pruefen |
| 7 | Palette-Remap, Graustufen-Test | mittel | Prinzip klar |
| 8 | Blender zu glTF zu Godot | mittel | Doku gelesen |
| 9 | Lizenzen und Credits | mittel | Kenney geklaert, Quaternius je Paket pruefen |
| 10 | Hilfsmeshes und Fern-LOD-Meshes | niedrig | Repo-Loesungen bekannt |

## 3. Quellen (geoeffnet) mit Einstufung

1. https://advances.realtimerendering.com/s2007/Mitchell-IllustrativeRenderingInTF2(Siggraph07 Course Notes).pdf - Silhouette, Konsens
2. https://cdn.fastly.steamstatic.com/apps/valve/2008/GameFest08_ArtInSource.pdf - Valve
3. https://medium.com/@xavierck/character-readability-in-team-fortress-2-and-overwatch-68c41d454465 - Einzelmeinung
4. https://80.lv/articles/how-dorfromantik-expands-its-cozy-world-through-minimalist-design - Studio
5. https://www.gamedeveloper.com/disciplines/sparking-joy-through-tile-placement-in-idyllic-village-builder-i-dorfromantik-i- - Studio
6. https://www.mcvuk.com/business-news/when-we-made-townscaper/ - Studio, Einzelmeinung
7. https://medium.com/@ustwogames (Alba: Gradient-Palette ueber UVs, keine Normalmaps) - Studio
8. https://www.gamedeveloper.com/design/skyrim-s-modular-approach-to-level-design - Studio, Fantasy-RPG-Kontext
9. https://ianlondon.github.io/posts/modular-level-kit-geometry - Praktiker
10. https://80.lv/articles/building-huge-open-worlds-modularity-kits-art-fatigue - Einzelmeinung
11. https://80.lv/articles/stylized-production-tips-and-tricks - Einzelmeinung
12. https://80.lv/articles/001agt-002mrs-crafting-a-low-poly-model-kit (UV-Atlas, 58.427 Dreiecke) - Einzelfall
13. https://www.pcgamer.com/why-less-is-more-when-it-comes-to-firewatchs-beautiful-trees - Studio
14. https://news.ubisoft.com/en-us/article/355243/Create-The-Unknown-How-Anno-1800-Put-A-Creative-Spin-on-the-Industrial-Revolution - Studio
15. https://blog.makko.ai/what-public-game-art-bibles-say/ - Einzelquelle
16. https://kenney.nl/support - Anbieter, CC0, Kenney-Logo nicht verwenden
17. https://licenseorg.com/guide/3d-assets/kenney-assets - Dritte, bestaetigt CC0, keine Garantie
18. https://gamefromscratch.com/quaternius-free-3d-assets/ - Blog, CC0, Einzelmeinung
19. Godot-Doku 4.7 import_configuration (RST, GitHub godot-docs) - Primaerquelle
20. Godot-Doku 4.7 model_export_considerations - Primaerquelle
21. Godot-Doku 4.7 standard_material_3d (Vertex Color, Is sRGB) - Primaerquelle
22. https://github.com/godotengine/godot/issues/76436 (Vertex-Schwelle Mesh-LOD) - Einzelmeinung
23. https://github.com/KhronosGroup/glTF/issues/2148 - nur Achsenfigur, marginal

Gezaehlt: 23, davon tragend etwa 19. Mindestziel 15 erreicht.

## 4. Konsens, Streit, Einzelmeinung

Konsens: Silhouette zuerst; Palette/Vertexfarbe fuer Low-Poly; Modular braucht Raster und Pivot; Variation ueber Palette; Kenney CC0 (Anbieter plus Dritte).
Streit/offen: Kitbash-Praxis (Polycount nicht lesbar); Texeldichte-Toleranz +-25 % aus Fantasy-RPG-Kontext, fuer Vertexfarb-Assets bedeutungslos.
Einzelmeinung: Townscaper (Detail an Fuegestellen), Quaternius-CC0 (Blog), 58.427-Dreiecke-Kit.

## 5. Was gelernt wurde (Kernpunkte)

1. Silhouette und Palette in Graustufen zuerst pruefen, bevor Detail modelliert wird.
2. Modular: Footprint-Raster, Pivot am Boden, einheitliche Schnittstellen. Zahlen aus Skyrim nur als Prinzip.
3. Blender-Export: Transformationen anwenden, triangulieren, Meter und +Y. Vertexfarbe in Godot mit "Is sRGB".
4. Kenney CC0 ohne Namensnennung, Kenney-Logo nicht benutzen. Quaternius CC0 laut Blog, Paketseite vor Einsatz pruefen. Credits-Datei trotzdem Gute Praxis.
5. Automatisches Mesh-LOD greift bei sehr Low-Poly-Meshes laut Issue-Kommentar nicht. Das Projekt-eigene Fern-Mesh ist daher plausibel.
6. Faktor je ROLLE, ein Prefab = ein Mesh/eine Flaeche/ein Material, Pivot normiert. Im Repo bestaetigt, mit Review-Checkliste (A12) operationalisiert.

## 6. Offen und Konfidenz

- Kitbash-Rezepte fuer Kutsche/Personenwagen: Konfidenz niedrig (Standardpraxis, Teile nicht gesichtet).
- Pferd: Konfidenz niedrig (Qualitaet, Polygonzahl, Beinaufteilung fuer Shader-Animation ungeprueft).
- Vertexfarbe gegen Colormap im Projekt: nicht aus dem Repo nachgelesen, Konfidenz niedrig.
- Silhouetten-Schwellwert 64 px: Faustwert.
- Quaternius-Lizenz je Paket: Konfidenz mittel.

## 7. Ehrliche Einschraenkungen

- Reddit: WebFetch SITE_BLOCKED, nicht umgangen. Keine Reddit-Quelle belegt.
- Polycount nicht abrufbar (client_error): Praktikerwissen zu Kitbash und Low-Poly-Konventionen fehlt.
- opengameart robots-gesperrt, Tripo client_error. Lizenzen dort nicht geprueft.
- Blender-Manual und Khronos-Spec nicht abrufbar (Provenance geblockt). Export-Wissen stammt aus Godot-Doku und Fachwissen.
- GDC-Vortraege nur als Landing-Pages.
- Viele Quellen sind Studio-Selbstdarstellung. Kein eigener Modellierversuch in dieser Fortbildung, keine Assets gebaut.
