---
name: mt-art
description: 3D-Artist-Handwerk fuer Mega Tycoon - Kenney/Quaternius-Kits, Kitbash, Import-Faktoren, Pivot, Silhouette, Vertexfarbe/Palette, Fern-LOD-Meshes, Lizenzen. Verwenden beim Modellieren, Importieren, Pruefen oder Beschaffen von Low-Poly-Assets.
---

# Artist (TEAM-02) - Mega Tycoon

Rolle: Sophie als Artist. Ich beschaffe, baue und normiere Low-Poly-Assets so, dass sie ohne Nacharbeit in die Prefab-Pipeline passen.

Kennzeichen:
- [Q] Quelle geoeffnet und gelesen (URL angegeben)
- [~] Fachwissen ohne geoeffnete Quelle
- [M] im Repo belegt (Dateiangabe)
- [Annahme] nicht belegt
Konsens = mehrere Quellen. Streit = Widerspruch. Einzelmeinung = eine Quelle.

---------------------------------------------------------------------
# TEIL A - Allgemeines Fachwissen
---------------------------------------------------------------------

## A1. Arbeitsprinzipien

1. Silhouette zuerst. Ein Asset muss in 1/10 Groesse als Schattenriss erkennbar sein. [Q] Mitchell TF2 (advances.realtimerendering.com/s2007/Mitchell-IllustrativeRenderingInTF2), Dorfromantik (80.lv). Konsens.
2. Wenig Material, viele Teile. Eine Farbpalette oder Vertexfarbe statt vieler Texturen. [Q] Alba (medium.com/@ustwogames: Gradient-Palette ueber UVs, keine Normalmaps), Dorfromantik (Graustufen-Albedo plus max. 5 Vertex-Color-Kanaele). Konsens.
3. Modular denken: festes Raster, einheitlicher Pivot, einheitliche Schnittstellen. [Q] gamedeveloper.com Skyrim-Modular; ianlondon.github.io Modular Level Kit. Konsens.
4. Detail an Fuegestellen statt in Texturen. [Q] mcvuk.com Townscaper. Einzelmeinung (Entwickler).
5. Weniger ist mehr bei Wiederholung: Variation ueber Palette/Skala/Rotation, nicht ueber neue Meshes. [Q] 80.lv Art Fatigue; Firewatch (23 Baummodelle, pcgamer.com). Konsens beider.
6. Erst messen, dann skalieren: Original-Einheit des Kits ablesen, Zielmass aus der Skalentabelle, Faktor rechnen (siehe B1).

## A2. Modulare Kits - Regeln

- Footprint-Raster (z. B. 3-m-Modul, Wandstaerke 0,125 m, Texeldichte-Toleranz +-25 %). [Q] Skyrim-Modular, Ian London. Die Zahlen stammen aus Fantasy-RPG-Kits, nicht aus Top-down-Strategie. Als Prinzip uebernehmen, Zahlen nicht blind.
- Pivot am Boden-Mittelpunkt des Footprints, Ausrichtung entlang +Z oder -Z einheitlich. [Q] Skyrim-Modular (Pivot-Disziplin), Konsens.
- Schnittstellen (Kanten, Hoehen, Dachueberstand) gleich halten, sonst entstehen Luecken im Kitbash.
- Art Fatigue: Wiederholte Details fallen eher auf als Architektur. [Q] 80.lv Art Fatigue. Einzelmeinung.
- 80.lv Low-Poly-Kit-Beispiel (001agt/002mrs): UV-Atlas, 58.427 Dreiecke fuer ein ganzes Kit. [Q] 80.lv/articles/001agt-002mrs-crafting-a-low-poly-model-kit. Einzelfall.

## A3. Farbe am Asset

- Vertexfarbe oder Colormap (kleine Palettentextur, UV auf Farbfeld) sind die zwei Wege. Vertexfarbe: kein UV noetig, Farbe pro Vertex, beliebig mit Shader aenderbar. Colormap: Farbe fuer Gruppen von Flaechen, Export-kompatibel. [~] Konsens.
- Kenney-Kits benutzen meist eine Colormap-Textur oder Flat-Material. [M] kenney_messung.md bestaetigt Mix. Details im Repo pruefen, nicht aus Gedaechtnis.
- Godot: Vertexfarbe als Albedo braucht "Vertex Color Use As Albedo" plus "Is sRGB", sonst falsche Helligkeit. [Q] standard_material_3d-Doku 4.7.
- Palette zuerst in Graustufen pruefen (Wertestruktur). [Q] Dorfromantik 80.lv; Medium Readability.
- Warm/kalt-Schattierung (warm im Licht, kalt im Schatten) vorbereiten, nicht ins Asset backen, wenn der Shader es kann. [Q] TF2-Paper. Konsens.

## A4. Silhouette-Test und Detail-Floor

- Test: Asset in Schwarz auf Weiss, auf 64 Pixel Hoehe skaliert. Erkennbar? Wenn nicht, Form aendern, nicht Farbe.
- Detail-Floor: kleinste Detailgroesse, die man noch modelliert. Fuer Aufsicht-Strategie: unter der Pixelgroesse des Spielzooms entfaellt es. [Q] blog.makko.ai (Detail-Floor als Konzept). Einzelquelle, Zahl muss das Projekt setzen.
- Aufsicht: Daecher und Gesamtform zaehlen mehr als Fassadendetail. [Q] Anno-1800-Artikel (news.ubisoft.com).

## A5. Blender zu Godot (Checkliste)

[Q] Godot-Doku 4.7 import_configuration und model_export_considerations.
1. Einheit Meter, +Y oben beim glTF-Export. Im Godot Apply Root Scale pruefen.
2. Alle Transformationen anwenden (Skala 1, Rotation 0). Sonst falsche Skalen im Import.
3. Vor dem Export triangulieren (Triangulate-Modifier). Sonst Triangulierung durch den Exporter, Ergebnis nicht kontrollierbar.
4. Normale pruefen (Backface-Culling-Test, Face Orientation).
5. Ein Mesh, eine Flaeche, ein Material, wenn das Asset als Prefab-Mesh dienen soll (Projekt-Regel R4, siehe B1).
6. Keine Tangenten fuer Meshes ohne Normalmap.
7. Fern-LOD-Mesh separat bauen, wenn automatisches LOD nicht greift (Low-Poly-Schwelle). [Q] godot Issue 76436 (Calinou-Kommentar). Siehe mt-techart A4.
Nicht abrufbar: Blender-Manual, Khronos-Spec.

## A6. Lizenzen

- Kenney: CC0, keine Namensnennung noetig, Kenney-Logo nicht verwenden. [Q] kenney.nl/support. Konsens.
- licenseorg.com/guide/3d-assets/kenney-assets: bestaetigt CC0, weist darauf hin, dass keine Garantie fuer Rechtefreiheit der enthaltenen Inhalte besteht. [Q] Einzelquelle, Hinweis ernst nehmen. Bei Zweifel Kit-Seite prüfen.
- Quaternius: CC0. [Q] gamefromscratch.com/quaternius-free-3d-assets. Einzelmeinung (Blog), Kit-Seite des Pakets vor Einsatz pruefen.
- opengameart: robots-gesperrt, nicht gelesen. Lizenz dort je Asset unterschiedlich (nicht als CC0 annehmen). [~]
- Fuer Credits trotzdem eine Datei im Repo fuehren (Quelle, Lizenz, Datum), auch wenn CC0 keine Nennung verlangt. [Annahme als Gute-Praxis]

## A7. Haeufige Fehler (Liste)

1. Faktor je Kit statt je Rolle (Haus aus Kit X mit Haus aus Kit Y gleich skaliert, obwohl Ziel-Meter verschieden).
2. Pivot im Mesh-Zentrum.
3. Mehrere Materialien je Prefab (Draw Calls explodieren).
4. Transformationen nicht angewendet.
5. Nicht triangulierte Quads in Godot, dreieckige Artefakte.
6. Detail unterhalb des Detail-Floors modelliert.
7. Texturierte Kits neben Flat-Kits ohne Anpassung.
8. Farbe ins Mesh gebacken, die der Shader steuern soll.
9. Lizenz nicht dokumentiert.

## A8. Quellenliste Teil A (geoeffnet)

1 Mitchell TF2 PDF; 2 Valve Art in Source PDF; 3 medium.com/@xavierck Readability; 4 80.lv Dorfromantik; 5 gamedeveloper.com Dorfromantik; 6 mcvuk.com Townscaper; 7 medium.com/@ustwogames Alba; 8 gamedeveloper.com Skyrim-Modular; 9 ianlondon.github.io Modular Kit; 10 80.lv Art Fatigue; 11 80.lv Stylized production tips; 12 80.lv Low-Poly-Kit (001agt/002mrs); 13 pcgamer.com Firewatch-Baeume; 14 news.ubisoft.com Anno 1800; 15 blog.makko.ai Art Bibles; 16 kenney.nl/support; 17 licenseorg.com Kenney-Assets; 18 gamefromscratch.com Quaternius; 19 Godot-Doku import_configuration; 20 Godot-Doku model_export_considerations; 21 Godot-Doku standard_material_3d; 22 godot Issue 76436; 23 KhronosGroup/glTF Issue 2148 (nur Achsenfigur, marginal).

## A9. Kitbash - Vorgehen [~]

Kitbash = neues Asset aus Teilen vorhandener Kits. Belegte Quelle zum Verfahren: keine geoeffnet (Polycount nicht lesbar). Folgende Schritte sind Standardpraxis:
1. Zielsilhouette zuerst als Skizze oder Schattenriss festlegen.
2. Teile aus EINEM Kit bevorzugen (gleiche Palette, Kantenhaerte).
3. Teile auf gemeinsame Masseinheit bringen (Faktor je Rolle, Teil B1).
4. Zusammenfuegen, ueberfluessige Innenflaechen loeschen (Dreiecke sparen).
5. Alles auf ein Material und eine Flaeche reduzieren (Projekt-Regel R4).
6. Pivot setzen, Transformationen anwenden, triangulieren.
7. Silhouetten- und Graustufen-Test.
8. Quellen und Lizenz notieren.
Typische Kandidaten im Projekt (aus Luecken, B2): Kutsche (Aufbau plus Raeder plus Deichsel), Personenwagen (Wagenkasten plus Raeder). [Annahme: Teilequellen noch nicht gesichtet]

## A10. Dreiecksbudgets - Denkweise

- Budget kommt aus der Szene, nicht aus dem Asset: Anzahl sichtbarer Instanzen mal Dreiecke je Instanz muss ins Gate passen. [Q] Godot gpu_optimization (Prinzip); Zahlen im Projekt B3.
- Faustwerte aus dem Repo: Baum 129 Dreiecke (Empfehlung), Prefab-Typen 900-12.500 Dreiecke, Fern-Mesh 54-302. [M] Teil B.
- Weniger Dreiecke bringen nur etwas, wenn der Engpass Vertex-Last ist. In Compat ist Draw Call und Material meist dominanter. [Q] gpu_optimization, Interpretation [~].
- Innenflaechen, verdeckte Unterseiten, Kappen am Boden loeschen. Das spart ohne Look-Verlust. [~] Konsens.

## A11. Namens- und Ablagekonventionen [Annahme, Gute Praxis]

- Typ_Rolle_Variante (z. B. haus_m_fachwerk_a), kleingeschrieben, ohne Leerzeichen.
- Quelle und Lizenz in einer Begleitdatei oder einem Credits-Dokument.
- Fern-Mesh mit Suffix _fern.
Das Projekt hat eigene Typschluessel in `ProtoPrefabs` (Teil B3). Vor neuen Namen dort nachsehen.

## A12. Review-Fragen vor Abgabe eines Assets

1. Erkennt man es als Schattenriss?
2. Stimmt das Mass gegen die Skalentabelle (innerhalb Charter-Grenzen)?
3. Ist der Pivot am Boden, Rotation 0, Skala 1?
4. Ein Mesh, eine Flaeche, ein Material?
5. Passt die Farbe zur Projektpalette (Graustufen-Test)?
6. Kein Detail unterhalb des Detail-Floors?
7. Fern-Mesh vorhanden, wenn noetig?
8. Lizenz und Quelle dokumentiert?
9. Im Prototyp bei 160 m und 1.200 m angesehen?

## A13. Pferd, Fahrzeug, Figur - Besonderheiten [~]

- Tiere und Fahrzeuge werden im Projekt per Shader animiert (Gang, Rad, Bein). Das Mesh muss die Teile ueber UV2 kennzeichnen (Teil mal 100 plus Drehpunkt). Quelle: Repo (Teil B3). Allgemein: Shader-Animation spart Skelett und Instanzkosten, taugt aber nur fuer einfache Bewegungen.
- Pferd: Bein-Animation ueber Shader erfordert saubere Teilung der Beine (vorne/hinten, links/rechts). Qualitaet haengt von der Quaternius-Vorlage ab. [Annahme]
- Figuren/Kleinkram: in Aufsicht Silhouette und Farbfleck genuegen. Detail-Floor streng anwenden.

## A14. Streit- und Konsensliste

| Aussage | Status | Beleg |
|---|---|---|
| Silhouette zuerst | Konsens | TF2, Dorfromantik |
| Palette/Vertexfarbe statt Texturen im Low-Poly-Stil | Konsens bei Studios, Einzelquellen | Alba, Dorfromantik, Townscaper |
| Detail an Fuegestellen statt Textur | Einzelmeinung | Townscaper |
| Modul-Zahlen (0,125 m Wand, 3 m Raster) | aus Fantasy-RPG, uebertragbar nur als Prinzip | Skyrim, Ian London |
| Variation ueber Palette statt neue Meshes | Konsens (zwei Quellen) | Art Fatigue, Firewatch |
| CC0 bei Kenney | Konsens (Anbieter plus Dritte) | kenney.nl, licenseorg |
| CC0 bei Quaternius | Einzelmeinung (Blog) | gamefromscratch |

---------------------------------------------------------------------
# TEIL B - Wissen fuer Mega Tycoon (nur Belegtes aus dem Repo)
---------------------------------------------------------------------

Repo: /home/claude/mega-tycoon

## B1. Import-Regeln und Faktoren [M]

- Faktor je ROLLE: `faktor_szene = Ziel_m / Modell_u / 25`, `m_pro_u = faktor_szene * 25`. Quer- und Laengsfaktor getrennt (R3). Pivot-Normierung (R6). Ein Prefab = ein Mesh, eine Flaeche, ein Material (R4). [M] sprints/s8/design-sprint/phase2/10_asset_mapping.md, 10_import_faktoren.json
- Faktoren (Auszug): Laubbaum 0,42, Nadelbaum 0,65, Haus 0,12, Lok 0,104, Fuhrwerk Querfaktor 0,65. [M] 10_import_faktoren.json
- Zielmasse (Auszug): Haus S 8x6 m / H 6-7 m, Haus M 12x9 / H 9-11, Hof = 1 Feld (25 m), Fuhrwerk 9,5 x 2,2 m, Postkutsche 12,5 m, Lok+Tender 13,8 m, Zug 69 m. [M] phase2/01_skalen.md
- Fahrzeuge: hoechstens 1,2 x real, mindestens 0,9 x (Charter E1). [M] charter.md

## B2. Kits und Stil [M]

- Kenney-Kits mit ca. 85 % Abdeckung: Fantasy Town, Nature, Train, Survival, Graveyard, Castle, Prototype, Watercraft, Pirate. [M] sprints/s8/design-sprint/asset_audit.md und asset_audit/
- Stilbrueche: Retro Fantasy (texturiert), Hexagon, City/Car. [M] asset_audit.md
- Luecken: Pferd in Qualitaet (Quaternius Farm Animal Pack, CC0), Kutsche, Personenwagen (Kitbash). [M] asset_audit.md
- Kenney-Messung (Masse der Originale): design/art/day4-6/kenney_messung.md. Vor jedem Import dort nachsehen, nicht schaetzen.
- Hilfsmeshes aus eigener Hand: Halde, Meiler, Turmhelm u. a. (ta_welle2.md Abweichungen B1-B10 nennen die gebauten Ersatzformen).

## B3. Prefab-Pipeline [M] (proto_prefabs.gd, ta_welle2.md)

- 55 Typen. `ProtoPrefabs` liefert Mesh, Material, Fern-Mesh und Info.
- Palette: 20 Klassen x 5 Stufen x 4 Zeilen. Variante ueber `INSTANCE_CUSTOM.y`. Farben: Putz D8CDB6, Fachwerk 54402F, Holz 7A5D43, Ziegel 9A5944, Schiefer 5E6268, Reet 8D7A56, Stein A69E8F, Sockel 7E776B.
- Animation (Gang, Rad, Bein, Muehlrad) ueber UV2 (Teil * 100 + Drehpunkt): Asset muss Teile ueber UV2 kennzeichnen, kein Skelett. [M] ta_welle2.md
- Compat: `use_colors = true` plus Weiss, sonst COLOR schwarz. [M] ta_welle2.md
- Fern-LOD `mesh_fern` ab 650 m: 54-302 statt 900-12.500 Dreiecke. [M] ta_welle2.md
- Kleinkram bis 700 m ohne Schatten. [M] ta_welle2.md
- Einfaerberegel: Gebaeude neutral, Kettenfarbe nur in Icon/Plakette/Wimpel. [M] asset_audit.md

## B4. Epochen [M]

- W1-W5, W1 = 1820-1849. Prototyp nur W1. Keine Assets nach 1849 produzieren. [M] 12_regelwerk_v1_1.json
- Daten tragen die Epoche (E4, E8). Assets bleiben austauschbar ueber Prefab-Typ. [M] charter.md

## B5. Typische Fehlerbilder im Projekt [M]

1. Gespann-Ende, Schild-Anker, Wasserrad (Fixpass M2-M4). [M] phase4/fixpass_w2.md
2. Weiler ohne Schild (M8). [M] fixpass_w2.md
3. Marktplatz-Pflaster (M6/Pflaster-Shader). [M] fixpass_w2.md
4. Sichtpruefung M1-M10 (integration_w2.md).

## B6. Arbeitsablauf (Empfehlung, aus Repo-Regeln abgeleitet)

1. Rolle in 10_asset_mapping.md finden, Zielmass in 01_skalen.md nachlesen.
2. Originalmass in kenney_messung.md oder per Import messen.
3. Faktor rechnen und in 10_import_faktoren.json eintragen (nur mit Absprache Technical Artist).
4. Pivot setzen, ein Material, Fern-Mesh wenn ueber 900 Dreiecke.
5. Silhouetten-Test, Graustufen-Test.
6. Sichtprobe in Prototyp-Szene bei 160 m und bei 1.200 m.

---------------------------------------------------------------------
# TEIL C - Eigene Luecken und Lernstand
---------------------------------------------------------------------

## C1. Gelernt

| Thema | Stand | Konfidenz |
|---|---|---|
| Silhouette zuerst, Palette in Graustufen pruefen | mehrere Quellen | hoch |
| Modular: Footprint, Pivot, Schnittstellen | zwei Quellen | hoch |
| Art Fatigue / Variation ueber Palette | zwei Quellen | mittel |
| Blender-Export-Checkliste | Godot-Doku | hoch |
| Vertexfarbe-sRGB-Flag | Godot-Doku | mittel-hoch |
| CC0 Kenney/Quaternius | zwei bis drei Quellen | hoch fuer Kenney, mittel fuer Quaternius |
| Detail-Floor als Konzept | eine Quelle | mittel |

## C2. Weiter unsicher

1. Colormap gegen Vertexfarbe: welche Variante die Kenney-Kits im Projekt tatsaechlich nutzen (Repo pruefen, nicht aus Gedaechtnis). Konfidenz niedrig.
2. Pferd in Qualitaet: ob Quaternius-Modell in Palette und Polygonbudget passt. Nicht gesichtet.
3. Kutsche und Personenwagen: Kitbash-Rezept noch nicht erprobt.
4. Texeldichte: fuer Vertexfarb-Assets nicht relevant, fuer texturierte Retro-Fantasy-Kits ja. Wert +-25 % aus Fremdkontext.
5. Tatsaechliche Quaternius-Lizenz je Paket (Blog sagt CC0, Paketseite nicht gelesen).
6. Rigging/Animation: Projekt animiert ueber Shader (UV2), keine Skelette. Fuer Pferd-Gang (Bein-Animation) Qualitaet unklar.
7. Konkreter Silhouetten-Test-Schwellwert (64 px) ist Faustwert, nicht belegt.

## C3. Naechste Schritte (billigster zuerst)

1. kenney_messung.md und asset_audit.md Zeile fuer Zeile mit 10_asset_mapping.md abgleichen.
2. Eine Rolle (Haus M) komplett durchspielen: Mass, Faktor, Pivot, Palette, Silhouette.
3. Quaternius Farm Animal Pack: Lizenzseite und Dreieckszahl pruefen.
4. Credits-Datei anlegen (nur auf Anweisung, nicht im Rahmen der Fortbildung).

## C4. Priorisierte Lernfragen (Details im LERNBERICHT.md)

1. Kenney-Kit-Faktoren je Rolle und Quer-/Laengsfaktor (Regel klar, Einzelwerte aus Repo).
2. Kitbash fuer Kutsche und Personenwagen (Rezept allgemein, Teilequellen offen).
3. Pferd in Qualitaet: Quaternius Farm Animal Pack (Lizenz Blog, Qualitaet ungesichtet).
4. Silhouetten-Test und Schwellwert (Prinzip klar, Wert Faustwert).
5. Modular-Footprint und Pivot (gelernt, Projekt-Raster nicht nachgeprueft).
6. Vertexfarbe gegen Colormap in den Kenney-Kits (Repo pruefen).
7. Palette-Remap und Graustufen-Test (Prinzip klar).
8. Blender-zu-glTF-Checkliste (Doku gelesen, Blender-Manual nicht abrufbar).
9. Lizenzen und Credits (Kenney geklaert, Quaternius je Paket pruefen).
10. Hilfsmeshes (Halde, Meiler, Turmhelm) und Fern-LOD-Meshes (Repo-Loesungen bekannt).

## C5. Grenzen dieser Fortbildung

- Reddit war nicht lesbar (WebFetch SITE_BLOCKED), nicht umgangen. Keine Reddit-Quelle belegt.
- Polycount nicht abrufbar. Damit fehlt Praktiker-Wissen zu Kitbash und Low-Poly-Konventionen.
- opengameart robots-gesperrt, Tripo client_error.
- Blender-Manual und Khronos-Spec nicht abrufbar (Provenance geblockt). Export-Wissen stammt aus Godot-Doku und Fachwissen.
- Viele Quellen sind Studio-Selbstdarstellung (Einzelmeinung).
- Der Artist-Teil hat nur etwa 18 inhaltlich tragende Quellen, mehrere davon geteilt mit Art Direction.

## D. Lern-Routine (verbindlich, seit 2026-11-03)
**1. Wissenscheck** vor jeder fachlichen Antwort/Entscheidung: Steht sie hier mit Marke [K]/[V]/[R]? Ja: anwenden. Nein, oder nur [E]/[W]/niedrige Konfidenz: weiter mit 2.
**2. Recherche-Trigger** (einer genügt; laut sagen: "Wissenslücke: <Frage>, ich recherchiere"): a) Ich weiß es nicht oder rate. b) Derselbe Kompromiss/Workaround zum 2. Mal ("wieder X statt Y"). c) Eintrag unter Offene Lücken oder [E]/[W]/niedrig, und die Entscheidung hängt daran. d) Skill, Repo, Doku oder Messung widersprechen sich. e) Engine/Tool/Version neuer als der Skill-Stand. f) Basti korrigiert oder eine Entscheidung wird zurückgenommen. g) Teure oder unumkehrbare Entscheidung bei Konfidenz unter mittel. h) Derselbe Fix scheitert 2x.
Rollen-Trigger: Stilfrage ohne Referenz; Asset-Quelle/Lizenz unklar; Proportion wieder nach Augenmaß geschätzt.
Erst prüfen statt recherchieren, wenn billig messbar (Test, Doku-grep, Mini-Versuch). Geschmack klärt Prototyp oder Basti, nicht das Web.
**3. Ablauf**: Frage in einem Satz; Primärquellen zuerst (Doku, Issues, Forum, Postmortems; Reddit blockiert, nicht umgehen); 2 unabhängige Quellen; wenn möglich Eigenversuch [V]; Ergebnis mit Quelle, Datum, Marke. Budget 15 min, mehr nur als Agent. Unbeantwortet: Lücke eintragen, Basti/Team fragen, nie raten.
**4. Insight aufnehmen**, wenn alle vier stimmen: wiederverwendbar (2x gebraucht oder über 1 h Aufwand), belegt, noch nicht drin, kein Tagesstand (der gehört in Repo-Doku). Sofort bei Basti-Korrektur, Fehler im Skill oder Engine-Falle mit Repro, sonst gesammelt zum Sprintende. Eine Zeile mit Marke, Datum, Quelle; Widerspruch ersetzt den alten Eintrag; geschlossene Lücke streichen; Skill bleibt ca. 10.000 Zeichen. Im Account nur per Vorschlagskarte an Basti.
**5. Kompromisslog**: jeden Kompromiss, Workaround, jedes "wusste ich nicht" mit Datum in `sprints/s8/fortbildung/mt-art/LERNLOG.md` zählen; Zähler 2 löst Trigger b aus; Auswertung in der Sprint-Retro.
