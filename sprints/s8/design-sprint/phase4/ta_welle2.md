# TA + Sophie, Welle 2: Prefabs, Fahrzeuge, See-Nutzung, Floß, Korrekturen (Phase 4, Prototyp „Welt“, schlank, 03.11.2026)
Rolle: Technical Artist (TEAM-02) mit Sophie (Art). Arbeitskopie `p4/w2/ta/`. Grundlage: `VERTRAG.md` (inkl. Nachtrag Kits, Welle 2), `16_prototyp_plan_v1_1.md` §2/§5, `10_import_faktoren.json`, `12_regelwerk_v1_1.json`, `stadt_welle1.md`, `felix_welle1.md`, `referenz_bilder/README.md`.
Engine geprüft: Godot 4.7.2 (`--check-only`, API gegen `doc472`: `MultiMesh.use_custom_data`, `Mesh.surface_set_material`, `MeshInstance3D.get_active_material`, `Image.decompress`). Läufe headless und `xvfb-run … --rendering-driver opengl3`. `INSTANCE_CUSTOM` kommt im Compatibility-Renderer an (Test-Bild `prefab_gang`, `prefab_varianten`).

## 1 Dateien
| Datei | Inhalt |
|---|---|
| `slice/world/proto_prefabs.gd` | `class_name ProtoPrefabs`, API laut Vertrag: `vorhanden(typ)`, `mesh_fuer(typ)`, `fahrzeug(kategorie)`; dazu `schluessel(instanz)`, `custom_fuer(instanz)`, `variante_wert(0..3)`, `mesh_fern(typ)` (Fern-LOD), `info(typ)`, `material()`, `typen()`. 55 Typen, alle als **ein Mesh, eine Fläche, ein gemeinsames Material** |
| `slice/world/proto_prefab.gdshader` | gemeinsamer Shader: Palette (UV.x = Klasse × Helligkeit, Zeile = Variante aus `INSTANCE_CUSTOM.y`), Rad-/Beinanimation (UV2 = Teil + Drehpunkt), Mühlrad (TIME), Haltung (Nicken/Wanken aus `INSTANCE_CUSTOM.z/w`) |
| `slice/proto/proto_kulissen.gd` | `class_name ProtoKulissen`: Steg, Ruderboot am Steg (dümpelt), Schleifenboot, Floß mit Holzlände. `bauen(parent, terrain)`, `zeit_setzen(t)`, `messwerte()`, `TYPEN_SELBST = ["steg", "ruderboot"]` |
| `slice/props/kenney_proto/<kit>/` | 89 Modelle (2,6 MB) aus Fantasy Town, Prototype (`animal-horse`), Watercraft, Pirate, Train, Survival, Graveyard, Castle, Nature, je mit `Textures/colormap.png` und `License.txt` (CC0), importiert |
| `slice/world/proto_terrain.gd` (geändert) | Freistellen aus Stadt-Daten beim Bau, Baum-Sichtweite per Skript (zählbar ohne Renderer), `fluss_mitte_z(x)`, `baum_dreiecke_sichtbar()` |
| `tools_proto/ta_export.py` (geändert) | Dorfteich aus `proto_orte.json` (1512 / 818), S7-Plateaus glätten (Ring), Lauf mit `--orte` (Acker um die echten Orte) |
| `slice/world/data/proto/*` (TA) | neu exportiert: `proto_hoehe.r16` `4a69966a…`, `proto_fein.r16` `0b05f755…`, `proto_boden.png`, `proto_acker_maske.u8`, `proto_see.json`, `proto_bach.json` `fcd989b3…`, `proto_meta.json` (+ `plateaus_w2`). Deterministisch (zweimal gelaufen, md5 gleich) |
| `phase3b/12_regelwerk_v1_1.json` + Kopie `world/data/proto/regelwerk.json` | `personenwagen.l` 69 → **68** (PO), `dampflok.l` 76 → **90**, `zug_lok_tender_8_wagen.l` 676 → 682, Import-Abschnitt Lok/Personenwagen |
| `phase2/10_import_faktoren.json` + Kopie | Personenwagen 6,8 m, Lok Längsfaktor 1,341 (9,04 m), Tender 4,76 m, Ruderboot Bezugsachse z + Querfaktor 0,55, Pferd H 2,2 m |
| `slice/tests/ta_welle2_test.gd` | 23 Prüfungen (Prefabs, Fahrzeuge, Gang-Kosten, M14, M15, Floß, Freistellen, Dorfteich, Plateaus): **23/23 OK** |
| `slice/tests/ta_prefab_shots.gd`, `ta_welle2_shots.gd`, `ta_perf_aufschluss.gd`, `ta_kit_sheet.gd` | Galerie + Maßliste, Szenenbilder + Perf, Dreiecke je Knoten, Kontaktbogen (Entwicklung) |
| **Testhooks in Felix-Dateien** (nur Arbeitskopie, Felix' Hook gewinnt beim Merge) | `proto/proto_platzhalter.gd` (ProtoPrefabs statt Box, Varianten, Fern-LOD, Kleinkram ≤ 900 m), `proto/prototyp_welt.gd` (+ `ProtoKulissen.bauen`), `tests/proto_mass.gd` (Prefab-AABB über `ProtoPrefabs`, Nebengebäude-Soll aus `varianten_m[0]`). Originale in `_out/alt_w1/` |

## 2 Aufbau der Prefabs (Sophie: Palette, Look)
- **Fachwerk Fantasy Town:** Wände = Kenney-Wandmodule (1 u = 3 m, je Fassade gerundet auf ganze Module, Breite gestreckt), Etagen mit Tür vorn Mitte, Fenstern nach Muster, Kniestock beim Bauernhof. Dach = eigenes Satteldach (Überstand, Dicke, Firstbalken), Giebel mit Fachwerk (Schwelle, Riegel, Stiel), Kamin aus Kenney `chimney`, Sockel. Kirchen/Stadttor: Steinturm mit Schieferhelm.
- **Umfärben statt Kenney-Bunt:** Jede Kenney-Farbe (Colormap an der UV, bei Nature-Kit die Materialfarbe) bekommt eine Quellklasse (Holz dunkel/hell, Putz, Glas, Rot, Grün, Blau, Signal …), je Bauteil eine Regel auf Sophies Zielklassen. Fachwerk-Regel: dunkle Bretter → Putz, helle Rahmen → Eiche dunkel. Signalfarben (Orange, Gelb, Blau, Pink) gehen auf Holz/Stoff. Gebäude bleiben neutral (Referenz-README): Putz `D8CDB6`, Fachwerk `54402F`, Holz `7A5D43`, Ziegel `9A5944`, Schiefer `5E6268`, Reet `8D7A56`, Stein `A69E8F`, Sockel `7E776B` (20 Klassen × 5 Helligkeitsstufen × 4 Varianten).
- **Varianten ohne Draw Calls:** 4 Palettenzeilen (Putz warm/hell/ocker/grau, Ziegel drei Töne + **Schiefer**, Pferde braun/dunkel/Falbe/Rappe). Zeile = `INSTANCE_CUSTOM.y` (`ProtoPrefabs.custom_fuer(instanz)`, deterministisch aus Lage). Bild `prefab_varianten`.
- **Typen:** kate (Reet), bauernhof, grosshof, handwerkerhaus (giebelständig), buergerhaus (3 Etagen), gasthaus, schmiede (großer Kamin, Tor), pfarrhaus, schule, rathaus (Arkaden + Dachreiter), speicher, kirche_dorf, kirche_stadt, kapelle, stadttor, scheune / nebengebaeude (+ `/scheune_18x10`, `/stall_12x8`, `/schuppen_6x4`), gutshof (Vierseithof: Herrenhaus Nord, Scheune West, Stall Ost, Torwand Süd), wassermuehle + wassermuehle_rad (Kenney `watermill`, dreht), fischerhuette (Bretter, Reet), netzgestell, steg, anlegestelle, ruderboot, floss, obstbaum, laubbaum, eiche, heuhaufen (eigener Haufen, keine Ballen 1820), holzstapel, zaun_latte, zaun_feld, fass, amboss, brunnen, passant, pferd, fuhrwerk_wagen, kutsche_wagen, fuhrwerk_2_pferde, postkutsche_4_pferde, dampflok, tender, personenwagen, gueterwagen, flaeche_* (1 × 1 m).
- **Fern-LOD** `mesh_fern(typ)`: gleiche Kubatur, Fassaden als Flächen, ohne Kamin: 54–302 statt 900–12.500 Dreiecke. Im Testhook ab 650 m (visibility_range, gleiche Transformationen und Varianten).

## 3 Fahrzeuge und Gang-/Radphase
| Kategorie | Aufbau | L × B × H (m) | Soll |
|---|---|---|---|
| `fuhrwerk` | Fantasy Town `cart` (5,0 m, Querfaktor 0,65) + zweite Achse aus den Kenney-Rädern, Deichsel, 2 Pferde (`animal-horse`, Kopf −x → +90°, 2,9 × 0,9 × 2,2) | **8,94** × 2,17 × 2,18 | 8–9 m, B ≤ 2,2 |
| `postkutsche` | `cart-high` (Kasten 5,0 m) + Dach/Gepäck, 2. Achse, **4 Pferde** (2 × 2) | **11,84** × 2,14 × 3,40 | 10–12 m |
| `dampflok` | Train Kit Lok (H 4,3 m, Längsfaktor 1,341 → 9,04 m) + Kohlewagen als Tender (4,76 m) | **13,80** × 3,70 × 4,30 | 13,8 = 1,19 × 11,6 |
| `personenwagen` | `train-carriage-box` 6,8 m + Dach + Fensterband (Kenney-Kasten ist offen) | **6,80** × 3,10 × 3,42 | PO 6,8 |
| `gueterwagen`, `ruderboot`, `floss` | Kohlewagen 6,9 m · Ruderboot 4,5 m (z-Achse) · 7 Stämme 8 m + Ladung | 6,9 · 4,5 · 9,1 × 2,9 | 0,9–1,2 × real |

**Wahl 4 Pferde (Postkutsche):** Eilpost um 1820 fährt vierspännig, und auf der Karte unterscheidet sich die Kutsche so schon am Umriss vom Fuhrwerk (2). Mit 4 Pferden liegt sie mit 11,8 m in 10–12 m. Mit 2 Pferden wären es 8,9 m, also fast gleich lang wie das Fuhrwerk.

**Gang (Vertrag `fahrzeug()["gang"]`):** `INSTANCE_CUSTOM = Color(fmod(strecke_m, 240), ProtoPrefabs.variante_wert(0..3), nicken_rad, wanken_rad)`; MultiMesh `use_custom_data = true` (Compatibility zusätzlich `use_colors = true`, Farbe Weiß). Räder drehen um ihre Achse (Radius = Höhe des Drehpunkts, 0,87 / 0,68 m). Pferdebeine pendeln diagonal (Trab, Doppelschritt 2,6 m, ±24°), Rumpf wippt 5 cm. Je Periode (240 m) werden Rad- und Schrittzahl auf ganze Umläufe gerundet, deshalb springt beim Umbruch nichts. Bei gang = 0 stehen Beine und Rumpf ruhig. Kosten: CPU **0,001 ms je Frame** für 10 Fahrzeuge (`set_instance_custom_data`), im Shader 1 sin/cos je Ecke für die rund 1.600 Ecken je Gespann. Das ist weit unter 0,1 ms. Easing, Fahrlinie und Haltung berechnet Felix.

## 4 See-Nutzung und Floß (M14/M15)
- **Lage:** Die Stadt-Rolle hat Steg, Hütte und Boot am **NO-Ufer** gesetzt (`_meta.see_nutzung`, Steg-Wurzel 1374,9 / 838,4, Ende 1357,8 / 856,7, Hütte 1387 / 825). ProtoKulissen übernimmt diese Lage. Der TA-Vorschlag „Südufer 1212 / 1262“ bleibt nur als Rückfall, wenn die Daten fehlen. So liegt die Nutzung 321 m vom Dorf, der Weg ist kurz.
- **Pfad:** `proto_wege.json` enthält den `fischerpfad` (Feldweg, 105 m, beginnt 10 m vor der Hütte, Anschluss an die Chaussee 3,7 m). Ein Zusatzauftrag an die Stadt-Rolle und `proto_wege_see.json` sind darum **nicht nötig**.
- Steg 25 × 2 m (Kenney-Planken, Pfähle je 2,5 m, Deck 0,7 m über Pegel 44,8, Ende 0,9 m tief). Ruderboot 4,5 m 2,3 m neben dem Stegkopf, es dümpelt (Hub 5 cm, Rollen 2°, Stampfen 1,4°, Gieren 3°). Zweites Boot: Kreis r 110 m um (1182,5 / 1032,5), 300 s Umlauf, im Uhrzeigersinn, min. Wassertiefe 4,0 m.
- **Floß (E15):** 7 Stämme à 8 m (Survival `tree-log`), 2 Querhölzer, Stammladung 3 + 2 + 1, Steuerruder. Es treibt von x 2450 (Randlandschaft Ost) mit 1,5 m/s flussabwärts nach Westen. Kurs = Flussmitte + 12 m, y = `fluss_pegel_at(x)` − 0,18, min. Tiefe 3,4 m. An der **Holzlände** (Anlegesteg 10 × 3 m am Südufer bei x 1600, unterhalb Erlenbach) legt es in 25 s an und dreht sich dabei, liegt 40 s und taucht ab. Dann erscheint es oben wieder (je 5 s). Periode 642 s.
| Messzeile | Soll | Ist | OK |
|---|---|---|---|
| M14 See Ø | 400–600 m | 494 m | ja |
| M14 Steg | 25 × 2 m ±25 % | 25,0 × 2,0 m | ja |
| M14 Fischerhütte | 8 × 6 m ±25 % | 8,7 × 7,0 m (mit Dachüberstand) | ja |
| M14 Ruderboot | 4,5 m, 0,9–1,2 × | 4,50 m | ja |
| M15 Nutzung ≤ 500 m vom Ufer, Pfad zum Ort | Pflicht | Hütte 6 m vom Ufer, Fischerpfad → Chaussee → Erlenbach | ja |
| Floß | ca. 8 × 3 m | 9,1 × 2,9 m (mit Ruder) | ja |

## 5 Korrekturen aus Welle 1
| Punkt | Ergebnis |
|---|---|
| Acker um die echten Orte | Vollexport mit `--orte proto_orte.json` (Acker an Erlenbach, Hasenwinkel, Lindenfurt). Kern: Acker 14,8 % (vorher 6,8 % um den Platzhalter), Wald 14,6 % |
| Dorfteich | nach **(1512 / 818)** verlegt (aus `proto_orte.json` gewaesser), Pegel 45,25 m, 425 m². Der alte Platzhalter-Teich (1400 / 1325) ist weg |
| Bach-Gehölzsaum | `ProtoTerrain` stellt beim Bau automatisch frei: Gebäude (Diagonale/2 + 4 m), Mühle 28 m, Steg/Hütte 16 m, Wege (Breite/2 + 4 m, Chaussee + 6 m), Brücken 22 m, Bachbrücke 20 m. 81 Bäume entfernt, 0 Bäume < 15 m an der Bachbrücke und < 20 m an der Mühle |
| **Perf-Ursache 1,6 M** | Die Zahl stammt aus Felix' **Zählung ohne Renderer**: Sie zählt alle 70 Baum-MultiMeshes (1,49 M Dreiecke), die der Renderer per `visibility_range_end` 1,8 km gar nicht zeichnet. In allen 5 Presets war sie deshalb gleich. Gelände (87k) und Wasser (19k) waren nie das Problem |
| Gegenmaßnahmen | (1) Baum-Chunks werden per Skript nach Kameraabstand **unsichtbar geschaltet** (gleiche 1,8 km), damit stimmen Zählung und Bild überein. (2) Freistellen + neue Bodenkarte: 9.936 statt 11.500 Bäume. (3) Gebäude-Fern-LOD ab 650 m. (4) Kleinkram (Zaun, Passant, Fass …) nur bis 900 m, ohne Schatten |
| S7-Plateaus | Ring geglättet, Plateau bleibt: Haberau 118 m (Südrand, 2.515 Knoten, Ring 851 Knoten, max. ±8 m) und farm_2 61 m (Gut Kuppenhof, 113 Knoten, Ring 144, Kante gerundet, Gutshof-Fläche bleibt 61,0 m eben). Mühlteich und See geschützt, Rinnen nicht zugeschüttet (≤ 4 m je Schritt). **Kern max. Neigung 83,5 → 61,3 %**, Anteil > 30 %: 2,44 → 2,09 %, > 60 %: 0,5 → 0,0 % |

## 6 Perf und Ladezeit (nach dem Einbau, xvfb opengl3, Felix' Szene mit Testhooks)
| Ansicht | live Dreiecke / DC | gezählt (headless-Methode) | Gate |
|---|---|---|---|
| 1 Übersicht 3 km | **181k / 83** | 552k / 106 | ≤ 1,0 M / ≤ 300: ja |
| 2 Dorf 450 m | 549k / 91 | 1,54 M | – |
| 3 Markt 350 m | 509k / 48 | 1,48 M | ≤ 2,9 M: ja |
| 4 Fluss / 5 See | 799k / 61 · 788k / 110 | 1,6–1,8 M | – |
| See-Übersicht 520 m (schlechtester Fall) | 952k / 99 | 1,80 M | – |
| Ladezeit `_ready` | 1,4–2,1 s (davon Prefab-Bau 0,55–0,96 s, Gelände 1,0 s) | | ≤ 3 s: ja |
| Messsuite `proto_mass` (Prefab-AABB) | **82/82 OK**, headless und xvfb | | grün |
Alle Prefabs zusammen haben 96k Dreiecke (55 Typen). Die teuersten sind Gutshof (12,5k), Kirche Stadt (9,4k), Speicher (6,8k) und Bürgerhaus (4,8k). In der Nähe tragen die Bäume den größten Teil: ca. 1,0 M gezählt, live 0,3–0,6 M.

## 7 Bilder (`p4/w2/ta/_out/bilder/`, Auswahl als `phase4/bilder/ta_*.png`)
`w2_uebersicht`, `w2_dorf`, `w2_dorf_nah`, `w2_markt`, `w2_markt_nah`, `w2_fluss_floss`, `w2_floss_laende`, `w2_see_steg`, `w2_see_uebersicht`, `w2_muehle`, `w2_gutshof`, `w2_dorfteich`, `w2_bachbruecke` (Zählwerte in `w2_perf.txt`), dazu die Galerie `prefab_haeuser`, `prefab_sonder`, `prefab_gross`, `prefab_fahrzeuge`, `prefab_klein`, `prefab_varianten`, `prefab_gang` (10 Fuhrwerke mit verschiedenen Gangphasen).
Look-Befund: Das Fachwerk liest sich in Dorf und Markt als dunkle Balken auf Kalkputz. Dächer zeigen Ziegel in drei Tönen und etwa ein Viertel Schiefer, die Katen tragen Reet. Kein Gebäude hat eine Signalfarbe. Der Putz wirkt bei hellem Licht fast weiß. Wenn das AD zu hell ist, kann Sophie `PALETTE[K_PUTZ]` eine Stufe dunkler setzen, das ist eine Zeile.

## 8 Abweichungen und Annahmen
| # | Thema | Entscheidung | Grund |
|---|---|---|---|
| B1 | Steg-Lage | NO-Ufer laut Stadt statt Südufer (1212 / 1262) | Instanzen gehören der Stadt, Dorf liegt im NO, Pfad existiert |
| B2 | Lok-Länge | Lok 9,04 m statt 7,6 m (K10), Tender 4,76 m | Auftrag W2: Lok + Tender 13,8 m = 1,19 × real. Rückfall K10: 7,6 + 4,8 = 12,4 m |
| B3 | Dächer | eigenes Satteldach statt Kenney `roof-high` | Kenney-Dachteile sind für 1–2 Module Tiefe gebaut, unsere Tiefen sind 4–15 m |
| B4 | Obstbaum | Nature `tree_default` (7 m, runde Krone) statt Fantasy `tree` | Der Fantasy-Baum ist eine Tanne |
| B5 | Heuhaufen | eigener Haufen statt Graveyard `hay-bale` | Ballen gab es 1820 nicht |
| B6 | Pferd | y-Faktor 2,45 statt 2,88 m/u (H 2,2 m statt 2,56) | Kenney-Pferd ist zu hoch |
| B7 | Personenwagen | Dach + Fensterband als Hilfsmesh | `train-carriage-box` ist ein offener Kasten |
| B8 | Maße inkl. Dachüberstand | Grundriss-AABB 0,7–0,9 m größer als die Wand (Kate 8,8 × 7,2) | im Toleranzband ±25 % |
| B9 | Felix-Dateien | Testhooks in `proto_platzhalter.gd`, `prototyp_welt.gd`, `proto_mass.gd` | Nur so sind Messung und Bilder mit Prefabs möglich; Felix übernimmt seinen eigenen Hook |
| B10 | Bodenanteile | Heide im Ausschnitt 7,9 % (vorher 4,5 %) | Heide-Regel nutzt den Abstand zu den Orten, die echten Orte liegen anders als der Platzhalter |

## 9 Was Felix für den Einbau wissen muss
1. Instanzen nach `ProtoPrefabs.schluessel(it)` gruppieren (Nebengebäude haben 3 Varianten-Meshes). Je Schlüssel ein MultiMesh mit `mesh = ProtoPrefabs.mesh_fuer(key)`, `use_custom_data = true`, `use_colors = true` + `Color.WHITE`, Custom-Daten `ProtoPrefabs.custom_fuer(it)`. **Kein `material_override`**, das Material steckt in der Fläche. Ursprung = Bodenmitte, Front +z, Fußpunkt wie bisher.
2. `flaeche_*`: Einheitsmesh 1 × 1 m, die Basis mit `b` (x) und `t` (z) skalieren.
3. `steg` und `ruderboot` aus den Instanzen **nicht** bauen (`ProtoKulissen.TYPEN_SELBST`). Stattdessen `ProtoKulissen.bauen(modelle_root, terrain)` aufrufen, das braucht `fluss_mitte_z` aus dem TA-Gelände.
4. Fern-LOD: zweites MultiMesh mit `mesh_fern(key)`, Nah `visibility_range_end = 650`, Fern `visibility_range_begin = 650` (Liste `ProtoPrefabs.FERN_TYPEN`). Kleinkram bis 900 m und ohne Schatten. Die headless-Zählung zählt beide LOD-Stufen, das sind ca. +6k.
5. Fahrzeuge: `ProtoPrefabs.fahrzeug("fuhrwerk" | "postkutsche")` liefert `mesh`, `laenge_m`, `breite_m` und `gang`. Je Frame `set_instance_custom_data(i, Color(fmod(s_m, 240.0), ProtoPrefabs.variante_wert(v), nicken, wanken))`. Die Haltung kann auch über die Transform-Basis laufen, dann z/w = 0. `dampflok` (13,8 m Lok + Tender) und `personenwagen` sind statische Messobjekte.
6. `proto_mass.gd`: Die Prefab-AABB kommt über `ProtoPrefabs` (siehe Hook), Nebengebäude-Soll aus `varianten_m[0]`. Mit diesen beiden Zeilen ist die Suite grün.
7. Zählung ohne Renderer: Baum-Chunks schaltet `ProtoTerrain` jetzt sichtbar/unsichtbar. Die Zählung ist damit pro Preset verschieden und ehrlich, wenn nach `setze_preset` mindestens 1 Frame läuft.

## 10 Offene Punkte
| # | Punkt | Vorschlag |
|---|---|---|
| P1 | Prefab-Bau zur Laufzeit 0,55–0,96 s (55 Typen) | Meshes als `.res` backen (Material nach dem Laden neu setzen), wenn die Ladezeit auf Bastis Rechner knapp wird |
| P2 | Bäume in der Nähe tragen ~1 M gezählte Dreiecke (live 0,3–0,6 M) | Nadelbaum vereinfachen (230 → ~60), Wald-Dichte-Deckel; beides erst nach Daniels Messung |
| P3 | Gutsweg-Steigung und Stadt-Validator mit den geglätteten Plateaus | Stadt-Rolle: `stadt_validate.py` gegen TA-Höhen laufen lassen (liest heute ws_c direkt) |
| P4 | Wasserrad steht an der Hauswand, nicht im Mühlgraben (Stadt-Lage 1610 / 1090) | Stadt/TA: Rad 3 m Richtung Bach rücken, Mühlgraben als Rinne (Welle 3) |
| P5 | Floß taucht an der Lände ab statt flussauf getreidelt zu werden | reicht als Kulisse; wenn AD widerspricht: Rücktrift außerhalb des Kerns verstecken |
| P6 | Putz bei hellem Licht fast weiß | AD-Sichtprüfung in Welle 4, ggf. Putz eine Stufe dunkler |
| P7 | Regression (21 Suiten) nicht neu gelaufen | Änderungen betreffen nur Prototyp-Dateien; Daniel (Welle 3) |

## 11 Aufrufe
```
python3 -I tools_proto/ta_export.py --orte slice/world/data/proto/proto_orte.json   # Daten (deterministisch)
python3 -I tools_proto/ta_import_faktoren.py
godot --headless --path slice --import
godot --headless --path slice -s res://tests/ta_welle2_test.gd                        # 23/23
godot --headless --path slice -s res://tests/proto_terrain_test.gd                    # 15/15
godot --headless --path slice -s res://tests/proto_mass.gd -- --csv=<pfad>             # 82/82
xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --path slice -s res://tests/ta_welle2_shots.gd -- _out/bilder
xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --path slice -s res://tests/ta_prefab_shots.gd -- _out/bilder
```
