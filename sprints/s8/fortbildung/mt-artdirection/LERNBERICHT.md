# Lernbericht Art Direction (Sophie, TEAM-02) - Mega Tycoon

Stand: 2026-11-03. Skill: /tmp/claude-0/gd/skills/mt-artdirection/SKILL.md. Repo unveraendert, kein Commit.

## 1. Selbstanalyse - wo Wissen fehlte (read-only im Repo)

Gelesen: charter.md, phase2 01_skalen/02_designprinzipien/08_landschaft/09_wasser, phase3/14_prototyp_plan, phase3b/16_prototyp_plan_v1_1, referenzen.md und referenz_bilder, design/art/day1-3 und day4-6 (S-03, S-05, kenney_messung), concept/sophie.md, concept/leitplanken.md, sprints/s6/zocken/sophie_sp03.md.

Befunde:
- Look-Gates G1-G3 existieren, G3 (Kontrast 3:1) ist laut Aylin NICHT erfuellt (14 Paare 1,1-3,0:1). Es gab keine Methode, wie ein Wasser/Boden-Kontrast sinnvoll gesetzt wird.
- Lesbarkeit im Fernzoom nur gerechnet (4.000 m, 70 Grad), nie getestet.
- Epochen-Look: nur W1 geplant, Strategie fuer W2-W5 (aufstocken oder austauschen) fehlt.
- Stilmix Kenney/Quaternius: Stilbrueche benannt (Retro Fantasy, Hexagon, City/Car), aber keine Pruefmethode.
- Rechenunklarheit: Repo nennt 4,8 m/px bei 5,6 km, die 4.000-m-Grenze ist auf 720p gerechnet. Beides passt nicht zur selben Aufloesung (4,8 m/px entspricht 1080 px, nicht 720).

## 2. Priorisierte Lernfragen (11)

| Nr | Frage | Prioritaet | Status |
|---|---|---|---|
| 1 | Massstabsdoktrin E1 gegen Lesbarkeit: wie viel Zeichen, wie wenig Groesse? | hoch | Prinzip klar, Menge offen |
| 2 | Zoomstufen und Fernlesbarkeit: Methode? | hoch | Pixelrechnung, Spielertest offen |
| 3 | Epochen-Look: aufstocken oder austauschen? | hoch | offen (Mischform Annahme) |
| 4 | Look-Abnahme-Kriterien G1-G3 messbar machen | hoch | Methode gelernt, Werte teils offen |
| 5 | Wertestruktur-Test (Graustufen/Blur) | hoch | gelernt, nicht angewandt |
| 6 | Palette und Saettigung (35 %) gegen Quellen pruefen | mittel | offen |
| 7 | Stilmix Kenney/Quaternius, Stilprobe | mittel | offen |
| 8 | Referenzen mit Aussage (uebernehme X, ignoriere Y) | mittel | Prinzip klar |
| 9 | Art-Bible mit Tie-Breaker und Detail-Floor | mittel | Struktur gelernt |
| 10 | Farbsehschwaeche | mittel | Fachwissen, Simulation offen |
| 11 | FOV 40 gegen 50, Nebel als Look-Parameter | niedrig | Begruendung offen |

## 3. Quellen (geoeffnet) mit Einstufung

1. https://advances.realtimerendering.com/s2007/Mitchell-IllustrativeRenderingInTF2(Siggraph07 Course Notes).pdf - Primaerquelle, Konsens im Feld (Silhouette, warm/kalt, Fresnel-Rim, Tiefennebel)
2. https://cdn.fastly.steamstatic.com/apps/valve/2008/GameFest08_ArtInSource.pdf - Primaerquelle Valve (Wert/Farbe/Silhouette, Team ueber Farbtemperatur)
3. https://medium.com/@xavierck/character-readability-in-team-fortress-2-and-overwatch-68c41d454465 - Einzelmeinung eines Autors (Desaturieren, Blur-Test)
4. https://blog.camposanto.com/post/112703721804 - Studio-Post (Firewatch), duenn
5. https://www.pcgamer.com/why-less-is-more-when-it-comes-to-firewatchs-beautiful-trees - Studio-Selbstdarstellung
6. https://80.lv/articles/how-dorfromantik-expands-its-cozy-world-through-minimalist-design - Studio (Graustufen-Albedo, max. 5 Vertex-Color-Kanaele)
7. https://www.gamedeveloper.com/disciplines/sparking-joy-through-tile-placement-in-idyllic-village-builder-i-dorfromantik-i- - Studio
8. https://www.mcvuk.com/business-news/when-we-made-townscaper/ - Studio (Regenbogenpalette, Detail an Fuegestellen)
9. https://80.lv/articles/using-wave-function-collapse-algorithm-for-dioramas - Einzelmeinung
10. https://news.ubisoft.com/en-us/article/355243/Create-The-Unknown-How-Anno-1800-Put-A-Creative-Spin-on-the-Industrial-Revolution - Studio (Aufsicht: Daecher/Verwitterung)
11. https://www.pcgamer.com/tactical-advantage-how-visuals-can-affect-strategy-games - Presse
12. https://blog.makko.ai/what-public-game-art-bibles-say/ - Analyse oeffentlicher Art-Bibles (Tie-Breaker, Detail-Floor), Einzelquelle
13. https://medium.com/@ustwogames (Alba) - Studio
14. https://www.gamedeveloper.com/design/skyrim-s-modular-approach-to-level-design - Studio
15. https://ianlondon.github.io/posts/modular-level-kit-geometry - Praktiker
16. https://80.lv/articles/building-huge-open-worlds-modularity-kits-art-fatigue - Einzelmeinung
17. https://80.lv/articles/stylized-production-tips-and-tricks - Einzelmeinung
18. stephenberryart.com Gurney-Rezension - qualitativ, duenn
19. transportfever3.com Dev-Blog (Infrastruktur) - keine Masse, duenn
20. admin-forum.paradoxplaza.com Victoria-3-Diary - kein Zoom/LOD-Inhalt, duenn
Repo-Belege zusaetzlich: RE-Referenzbilder, TF3-Bilder (referenz_bilder/README.md), S-03, S-05, concept/sophie.md.

Verwertbar tragend: etwa 17 (Nr. 1-3, 5-17). Nr. 4, 18-20 duenn. Mindestziel 15 knapp erreicht, aber viele Quellen sind Studio-Selbstdarstellung.

## 4. Konsens, Streit, Einzelmeinung

Konsens: Silhouette/Wert/Farbe-Reihenfolge; gedaempftes Gelaende plus gesaettigte Akzente; Graustufen-Test.
Streit/offen: Epochen aufstocken oder austauschen (keine Quelle); Stilmix (keine Quelle); ob 3:1 fuer Wasser/Boden sinnvoll ist (Projektfrage).
Einzelmeinung: Makko-Art-Bible-Muster; Anno (Daecher zaehlen); Townscaper (Detail an Fuegestellen); Art-Fatigue-Artikel.

## 5. Was gelernt wurde (Kernpunkte)

1. Look ist pruefbar: Silhouette, Wert (Graustufen/Blur), Palette, Detail-Floor. Abnahme ohne Messwert ist keine Abnahme.
2. Funktionales gesaettigt, Gelaende gedaempft. Passt zum Projektwert Saettigung hoechstens 35 % fuer Gelaende.
3. Aufsicht: Daecher und grossflaechige Verwitterung tragen den Eindruck (Anno).
4. Art-Bible genuegt in drei Seiten, wenn sie Tie-Breaker, Detail-Floor und Referenzen mit Aussage enthaelt.
5. Pixelrechnung macht Lesbarkeit pruefbar. Repo-Rechnung hat eine Aufloesungs-Unstimmigkeit (720 gegen 1080 px).
6. Variation ueber Palette und Varianten, nicht ueber neue Meshes (Art Fatigue, Firewatch).

## 6. Offen und Konfidenz

- Epochen-Look: Konfidenz niedrig. Empfehlung "Mischform" ist Annahme.
- Stilmix: Konfidenz niedrig. Stilprobe noetig.
- Fernlesbarkeit bei 4.000 m: nur Rechnung. Konfidenz niedrig.
- Farbsehschwaeche (ca. 8 % der Maenner), WCAG 3:1, CIEDE2000: Fachwissen ohne geoeffnete Quelle, Konfidenz mittel.
- Wasser/Boden-Kontrast: Streitfall, nicht entschieden.

## 7. Ehrliche Einschraenkungen

- Reddit: WebFetch SITE_BLOCKED, nicht umgangen (ein curl-Versuch mit anderem User-Agent wurde als Umgehung abgelehnt und nicht wiederholt). Keine Reddit-Quelle belegt.
- GDC Vault und YouTube nur Landing-Pages: Monument Valley, Firewatch-GDC, Dorfromantik-GDC nicht gelesen.
- Polycount nicht abrufbar (client_error). Damit fehlt Praktikerdebatte zu Stilmix und Referenzpraxis.
- HOI4-Diary (Browser-Validierung), Victoria-3-Diary und TF3-Dev-Blog liefern keinen Zoom-/Lesbarkeitsinhalt. Wie Anno/TF3/HOI4 Zoomstufen konkret staffeln, ist daher nicht belegt.
- Viele Quellen sind Studio-Selbstdarstellung, keine Studien. Uebertragbarkeit von Figuren-Shootern (TF2) auf Aufsicht-Strategie nur sinngemaess.
- Valve-Pipeline-Papier ist von 2008, TF2-Paper von 2007.
