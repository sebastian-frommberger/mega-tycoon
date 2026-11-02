# 10 Asset-Mapping: Kenney-Modell je Rolle, Importfaktor, Lücken (Technical Artist TEAM-02, Design Sprint „Welt“, 02.11.2026)
Zweck: Jede Spielrolle (Gebäude, Industrie, Fahrzeug, Natur, Infrastruktur) bekommt ein konkretes Kenney-Modell, einen Importfaktor auf das Zielmaß aus `01_skalen.md`, eine Lücken- und Hilfsmesh-Liste und eine Einfärberegel.
Status: Skizze, Phase 2. Daten: `10_import_faktoren.json` (38 Rollen). Bounding-Boxen **neu gemessen** am 02.11. mit `asset_audit_bbox.py` auf Bastis Gerät (13 Kits, 1.451 Modelle, 0 Fehler, read-only). Kennung: [M] gemessen, [~] Fachwissen ungeprüft, [Annahme] Setzung TEAM-02.

## Regeln
| # | Regel |
|---|---|
| R1 | **Faktor je Rolle, nicht je Kit.** `faktor_szene = Zielmaß_m / Modellmaß_u / 25` (1 Szeneneinheit = 1 Feld = 25 m). Der Kit-Faktor aus dem Audit (Tab. 1) gilt nur für **Baukasten-Module** (Fantasy Town 0,12 = 3 m je Modul, Train 0,104, Survival 0,096). Kenney skaliert innerhalb eines Kits nicht einheitlich: Bäume im Nature Kit brauchen das 2,3- bis 5-Fache des Kit-Faktors (gemessen). |
| R2 | **Bezugsachse = die Maßangabe mit der kleinsten Toleranz.** Gebäude: Modulhöhe 3 m. Fahrzeuge: Länge, außer das Modell ist gedrungen (Lok). Dann gilt die Höhe, damit kein Maß über 1,2 × real geht. |
| R3 | **Querfaktor** (nur x, also Breite) ist erlaubt, wenn Kenney-Proportionen die 1,2-Grenze reißen und die Räder in der y-z-Ebene liegen (bleiben rund): Fuhrwerk/Kutsche 0,65, Flussbrücke 0,47. Kein Querfaktor bei Gebäuden. |
| R4 | **Ein Prefab = ein Mesh.** Modulare Häuser und Industrie-Kitbashes werden beim Import gemergt (`ArrayMesh` mit 1 Fläche, Kenney-Colormap als gemeinsamer Atlas) und als MultiMesh gesetzt. Ziel: ≤ 1 DC je Prefab-Typ und Sichtweitenstufe. |
| R5 | **Fernproxy:** ab 1,4 km (S7-Regel) Haus = Quader mit Satteldach (12 Dreiecke) in Dachfarbe. Industrie behält die Landmarke (Turm, Esse, Flügel) als eigenes Proxy-Mesh. |
| R6 | **Pivot normieren:** Grundfläche zentriert, y = 0 am Boden (Fantasy-Wände stehen am Rand, Nature-Teile mittig, Mühlen-Teile mit y_min −0,9 bis −1,56 u [M]). |

## Mapping je Rolle
Pfade relativ zu `Kenney Game Assets All-in-1 3.7.0/3D assets/<Kit>/Models/GLB format/` (Nature Kit: `GLTF format/`, Dateien sind `.glb`). Maße in Metern nach Faktor [M].

### Gebäude
| Rolle | Modell(e) | Faktor | Maß im Spiel | Ziel (01) | Bausatz / Hilfsmesh |
|---|---|---|---|---|---|
| Haus S (Kate) | Fantasy Town `wall-wood`, `wall-wood-window-shutters`, `wall-wood-door`, `roof-high`, `roof-high-gable-end` | 0,12 | 9 × 6 m, H 6,5 m (1 Gesch. + Dach 3,5 m) | 8×6, H 6–7 | 3 × 2 Module, ~ 900 Dreiecke |
| Haus M (Bauern-/Handwerkerhaus) | `wall` (EG Stein) + `wall-wood` (OG) + `roof-high` + `chimney` | 0,12 | 12 × 9 m, H 9,5 m | 12×9, H 9–11 | 4 × 3 Module × 2 Gesch., ~ 2.000 Dreiecke |
| Scheune/Stall | `wall-wood-block`, `wall-wood-doorway-square-wide`, `roof-high` | 0,12 | 18 × 9 m, H 8 m (1,5 Gesch.) | 18×10, H 8–10 | 6 × 3 Module |
| Hofstelle | Haus M + Scheune + Fantasy `fence` + Graveyard `hay-bale` + Survival `barrel` | 0,12 / 0,105 / 0,105 | 25 × 25 m | 1 Feld | Prefab aus 3 Teilen + Streuobjekte als MultiMesh |
| Haus L (Bürgerhaus) | `wall` 3 Gesch., `wall-window-glass`, `roof-high-window`, `balcony-wall` | 0,12 | 12 × 15 m, Traufe 9 m, First 12,5 m | 12×14, Traufe 12 | 4 × 5 × 3; Traufe am unteren Rand (−25 %), 4. Geschoss nur für XL |
| Haus XL (Mietshaus, ab 1840) | wie L, 4–5 Gesch. | 0,12 | 15 × 12, H 15–18 m | 16×12, H 16–18 | Epochenparameter |
| Dorfkirche | Schiff: `wall` 7 × 3, `wall-window-round`, `roof-high`; Turm: `wall` 2 × 2 × 9 Lagen + `roof-point` (y × 4) | 0,12; Helm y 0,48 | Schiff 21 × 9 m, Turm 6 × 6 × 27 m + Helm 6 m = 33 m | 20×10, Turm 30 | Hilfsmesh Turmhelm (gestreckter `roof-point`) |
| Stadtkirche | wie oben, Turm 3 × 3 × 13 Lagen | 0,12 | Turm 39 + 8 m Helm = 47 m | Turm 45–55 | Castle `tower-square-*` als Alternative (Palette umfärben) |
| Bahnhof früh | Empfangsgebäude = Haus L 10 × 4 × 2; Bahnsteig `planks` (y-Faktor 0,5); Dach `overhang` + `pillar-wood` | 0,12 | 30 × 12 m; Bahnsteig 110 × 4 m | 30×12; 110×4 | Bahnsteig als 1 gestrecktes Mesh |
| Brunnen/Markt | Fantasy `fountain-round`, `stall-red/-green`, `lantern` | 0,12 | Brunnen Ø 6 m | Marktbrunnen 4–6 | – |

### Industrie (Gebäude neutral, siehe Einfärberegel)
| Rolle (Sim-Slot) | Modell(e) | Faktor | Maß | Ziel (01 D) | Lücke / Hilfsmesh |
|---|---|---|---|---|---|
| Wassermühle | Haus M 4 × 4 + Fantasy `watermill` (Rad) | 0,12 (Rad 0,111) | 12 × 12 m, Rad Ø 5,0 m | 12×12, Rad 5 | Mühlteich/Graben über Wasser-Shader (09) |
| Windmühle (Holländer) | Turm aus `wall-rounded` (x/z × 2,67, also 8 m Ø, 5 Lagen = 15 m) + `roof-point` + Fantasy `windmill` (Flügel) | Turm 0,12 / 0,32; Flügel **0,257** | H ≈ 25 m, Flügel Ø 20 m | H 20–25, Flügel 20 | Flügel brauchen den 2,1-fachen Kit-Faktor [M]. Alternative Hexagon `unit-mill` ×1,25 (fertig, Stilbruch) |
| Schmiede | Haus M 3 × 3 + `chimney-base` + `chimney-top` + Survival `workbench-anvil`, `workbench-grind` | 0,12 / Amboss 0,099 | 9 × 9 m, Amboss 0,8 m | 9×7 / 10×8 | – |
| Eisenhütte (Stahl-Slot) | Hochofen: `wall` (Stein) 3 × 3 × 5 Lagen + `chimney-base/-top`; Gießhaus `wall` 8 × 4; Kohlplatz Nature `log_stack` | 0,12 / Holz 0,225 | Ofen 9 × 9 × 15 m, Esse 18 m; Gießhaus 24 × 12 m | Ofen 10×10, Esse 15–20 | Erzhaufen/Halde = Hilfsmesh (Kegelstumpf) |
| Mine/Stollen (Kohle, Erz) | Nature `cliff_blockCave_stone` (Stollenmund) + `cliff_block_stone`; Kaue Haus M 5 × 3; Haspel aus Fantasy `poles`, `poles-horizontal`, `planks`; Train `railroad-straight` + `train-carriage-dirt` | Klippe 0,40, Rest 0,12 / 0,104 | Stollenmund 10 m Block, Kaue 15 × 9 m, Haspel 12 m | Kaue 15×10, Haspel 10–15, Gelände 75–125 m | **Halde** (Ø 30–60 m, H 5–15 m) als Hilfsmesh: Kegelstumpf 24 Segmente, Farbe Schotter `#A39D90` |
| Tiefbauzeche (ab 1840) | wie Mine + Turm aus Castle `tower-square-base/-mid` (Malakow) | Castle 0,24 → Breite 6 m, 5 Lagen | Turm 30 m | 25–35 | Castle-Palette umfärben |
| Gutshof/Getreidefarm | 2–3 Hofstellen als Vierseithof + Acker über die Bodenkarte (08) + Nature `crops_wheatStageB` nah | 0,12 / Getreide 0,105 | Hof 40 × 40 m, Halm 1,4 m | Hof 40, Schläge 150–300 m | Ackerfläche ist Boden, kein Mesh |
| Sägewerk | Wassermühle + offener Schuppen (`pillar-wood` + `roof-flat`) + Nature `log_stack`, `log_stackLarge` + Survival `resource-planks` + Train `train-carriage-lumber` | 0,12 / Holz 0,225 | Schuppen 18 × 9 m, Holzstoß 4 m | – | – |
| Manufaktur (Werkzeug-Slot) | `wall` 13 × 4 × 3 Gesch. + `roof-gable` + Dachreiter (`roof-point` auf 1 × 1 Turm) | 0,12 | 39 × 12 m, H 12 m | 40×12, 3 Gesch. | ab 1850 Schornstein: `chimney` gestapelt × 10 (30 m) |
| Köhlerei (Kraftwerk-Slot 1820) | Meiler = Hilfsmesh (Halbkugel Ø 9 m, Erdfarbe) + Nature `log_stackLarge` + Survival `campfire-pit` + Hütte Haus S | 0,225 / 0,12 | Meiler Ø 9 m | Ø 8–10 | Rauchsäule als Partikel/Billboard |
| Lager | Scheune 6 × 4 + Survival `box-large`, `barrel` | 0,12 / 0,105 | 18 × 12 m | – | – |

### Fahrzeuge (≤ 1,2 × real)
| Rolle | Modell(e) | Faktor | Maß L × B × H | Ziel (01 C) | Hinweis |
|---|---|---|---|---|---|
| Fuhrwerk (statt Lkw) | Fantasy `cart` + 2 × Prototype `animal-horse` + Deichsel (Fantasy `poles`, 1 Stange) | Wagen 0,149, **Querfaktor x 0,65**; Pferd 0,115 | Wagen 5,0 × 2,2 × 2,0; Gespann ≈ 9,5 m | 9,5 × 2,2 | ohne Querfaktor 3,3 m breit (×1,6) |
| Kutsche/Postkutsche (statt Bus) | Fantasy `cart-high` + Verdeck aus `roof-gable` (gestreckt) + 4 Pferde | 0,158, Querfaktor 0,65 | 5,5 × 2,3 × 3,4; Gespann 12,5 m | 12,5 × 2,2 | Lücke: kein geschlossener Wagenkasten |
| Pferd (Reiter, Treidelpferd) | Prototype `animal-horse` | 0,115 | 2,9 × 0,9 × 2,6 | 3,0 × 0,8 | sehr abstrakt (Würfel-Look) → Zukauf |
| Dampflok | Train `train-locomotive-a` (b, c als Varianten) | **0,104** (Bezug Höhe) | 6,7 × 3,7 × 4,3 | 9 (Länge) | Kenney gedrungen. Länge 9 m würde 5,7 m Höhe bedeuten (× 1,55) → Bezug Höhe, Länge −25 % (Bandrand) |
| Tender | Train `train-carriage-coal`, nur z gekürzt | z 0,071 | 4,8 × 3,1 × 4,2 | 4,8 | Hilfsmesh |
| Güterwagen | Train `train-carriage-coal`, `-dirt` (Erz), `-wood`, `-lumber`, `-flatbed`, `-box` | 0,102 | 6,9 × 3,1 × 4,2 (mit Ladung) | 6,9 | = Kit-Faktor (−2 %) |
| Personenwagen | Train `train-carriage-box` | 0,102 | 6,9 × 3,1 × 3,3 | 6,9 | Fenster als Farbstreifen (Material), Lücke |
| Gleis | Train `railroad-straight`, `-corner-*`, `-curve` | 0,104 | Segment 10,4 m | Spur 1,435 | bestehend |
| Ruderboot/Kahn | Watercraft `boat-row-small` | 0,066 | 4,5 m | 4–5 | Treidelkahn 28 m und Raddampfer: Lücke |

### Natur und Kleinteile
| Rolle | Modell | Faktor | Maß | Ziel | Hinweis |
|---|---|---|---|---|---|
| Laubbaum | Nature `tree_default` (+ `_dark`, `_fall`) | **0,42** | H 18 m, Krone 8 m | 15–25 | S7: 0,8 → 34 m |
| Eiche/Solitär | `tree_oak` | 0,65 | H 20, Krone 10–12 m | 15–25 | |
| Nadelbaum | `tree_pineDefaultA`, `tree_pineTallA` | 0,65 / 0,73 | H 25 / 28 m | 20–30 | |
| Obstbaum | Fantasy `tree`, `tree-crooked` | 0,116 | H 7 m | 6–8 | = Kit-Faktor |
| Busch/Hecke | Nature `plant_bushLarge`; Fantasy `hedge`, `hedge-large` | 0,33 / 0,12 | 2 m | 1,5–3 | Feldrain, Ufergehölz |
| Findling | Nature `rock_largeA–F` | 0,118 | 3 m | 2–4 | |
| Felsnadel | Nature `rock_tallA–J` | 0,40 | 10 m | 8–12 | nur Fels-Biom |
| Felsgruppe | Pirate `rocks-a/b/c` | 0,094 | 12 m | 10–15 | Palette umfärben |
| Klippe/Geländestufe | Nature `cliff_block_stone`, `cliff_*_stone` | 0,40 | 10 m Block | – | Steinbruch, Stollenmund |
| Bachbrücke (Stein) | Nature `bridge_stoneRound` | 0,31 (x auf Wegbreite) | Spann 8 m | 8 | im Feld, kein Brückenfeld |
| Flussbrücke (Steinbogen) | Castle `bridge-straight-pillar` (Pfeiler) + `bridge-straight` | 0,645, Querfaktor 0,47, y × 0,5 | Bogen 15 m, Breite 7 m, H 9,5 m | Bögen 15 | 4–7 Bögen je Fluss; Castle-Palette → Nature-Stein |
| Holzbrücke | Nature `bridge_wood`, `bridge_woodNarrow` | 0,31 | Joch 8 m | 8 | Weg |
| Lattenzaun | Fantasy `fence`, `fence-gate`, `fence-curved` | 0,116 | H 1,1 m, 2,9 m Feld | 1–1,2 | = Kit-Faktor |
| Koppelzaun | Nature `fence_simple`, `fence_planks` | 0,128 | H 1,1, 3,2 m | 1–1,2 | |
| Trockenmauer | Graveyard `stone-wall`, `stone-wall-curve` | 0,072 | H 1,3 m | 1–1,5 | Kirchhof, Weinberg |
| Heuhaufen | Graveyard `hay-bale`, `hay-bale-bundled` | 0,105 | 1,6 m | 1,2–2 | Ballen gab es 1820 nicht: Platzhalter |
| Holzstoß | Nature `log_stack`, `log_stackLarge` | 0,225 | 4 m | 3–5 | |
| Fass, Kiste | Survival `barrel`, `box-large` | 0,105 | Fass 0,9 m | 0,8–1 | |
| Passant | Graveyard `character-keeper` | 0,081 | 1,75 m | 1,75 | nur ≤ 300 m |
| Laterne | Graveyard `lightpost-single` | 0,095 | 3 m | 3 | nur Stadt |
| Getreide | Nature `crops_wheatStageA/B`, `crops_cornStageA–D` | 0,105 | 1,4 m | 1,2–1,5 | MultiMesh ≤ 500 m, sonst Bodenfarbe |

## Hilfsmesh-Bausteine (aus Modulen oder prozedural)
| Baustein | Bauweise | Dreiecke | Für |
|---|---|---|---|
| Hausprefabs S/M/L/XL × 3 Varianten × 3 Farbtöne | Fantasy-Module gemergt (R4) | 0,9k / 2k / 3,5k / 5k | Stadtmodell (05) |
| Turmhelm | `roof-point` y × 4 | 44 | Kirche, Dachreiter |
| Windmühlenturm | `wall-rounded` × 5, x/z 2,67 | 680 | Windmühle |
| Halde | Kegelstumpf, 24 Segmente, Rauschen im Rand | 96 | Mine, Zeche, Hütte |
| Meiler | Halbkugel, 16 × 6 | 192 | Köhlerei |
| Tender | Kohlewagen z-gekürzt | 1.184 | Zug |
| Gespann | Wagen + Pferde + Deichsel gemergt, 1 MultiMesh-Mesh | ~1.200 | Fuhrwerk, Kutsche |
| Ufergehölz-Band | Nature-Büsche/Bäume entlang Spline | – | Bach (01: Lesbarkeit über Saum) |
| Bahnsteig | `planks` gestreckt + Kante | 100 | Bahnhof |

## Einfärberegel
| Was | Regel |
|---|---|
| Wohn- und Industriegebäude | **Neutral**: gemeinsame Hauspalette (Putz hell/ocker, Fachwerk dunkelbraun, Stein grau-beige, Dach Ziegelrot/Schiefer/Stroh) über den Colormap-Atlas bzw. `KIT_TINT`/`roof_palette.gdshader` [S7]. Industrie nimmt **keine** Kettenfarbe an. |
| Kettenfarbe | nur Icon, Name, Plakette (Marker S-08) und optional ein 1-m-Fahnenwimpel (Fantasy `banner-*`, eingefärbt), nie Wand, Dach oder Fläche (Basti Punkt 5). |
| Werksgelände | echter Inhalt statt Farbfläche: Halde, Holzplatz, Teich, Acker (08 Bodenkarte). Kein eingefärbtes Pad. |
| Fremdpaletten | Castle (blau/beige), Graveyard (violett-grau), Pirate, Hexagon (gesättigt): beim Import auf die Nature-/Fantasy-Palette umgemappt (Colormap-Tausch oder Material-Override). Retro Fantasy (texturiert) und City/Car Kits nicht verwenden. |
| Fahrzeuge | neutral (Holz, Eisen). Linienfarbe nur als Wimpel/Plane oder Icon. |

## Lücken
| Lücke | Behelf jetzt | Schwere |
|---|---|---|
| Pferd in Qualität (Würfel-Prototyp) | Prototype `animal-horse` | hoch: Fuhrwerk ist das Hauptfahrzeug 1820 |
| geschlossene Kutsche, Planwagen | `cart-high` + `roof-gable` | mittel |
| früher Personenwagen | `train-carriage-box` + Fensterstreifen | mittel |
| Tender | gekürzter Kohlewagen | gering |
| Treidelkahn, Raddampfer | – | mittel (nur wenn Wasserweg kommt) |
| fertige Fachwerk-Häuser, Kirche | Kitbash (2–3 Tage, Audit) | mittel |
| Halde, Meiler, Hochofen | Hilfsmesh/Kitbash | gering |
| Heuhaufen/-schober 1820 | Graveyard-Ballen | gering |

## Empfehlung weiteres CC0-Pack (nur Empfehlung, nichts geladen)
1. **Quaternius „LowPoly Animated Farm Animal Pack“** (CC0, Pferd, Kuh, Schaf, Schwein, animiert; Link im Asset-Audit belegt). Schließt die schwerste Lücke (Pferd) und belebt Höfe und Weiden. **Empfehlung Nr. 1.**
2. Prüfen [~, nicht verifiziert]: Quaternius „Medieval Village Pack“ mit fertigen Häusern, Mühle und Schmiede im Low-Poly-Stil (CC0 laut Erinnerung, Inhalt und Lizenz vor dem Download prüfen). Das würde den Kitbash-Aufwand für Häuser senken. Stilprobe neben Fantasy Town ist Pflicht.

Gegenposition **Sophie (Art):** Quaternius-Tiere sind weicher modelliert als Kenney (runder, mehr Polygone) und brechen den kantigen Look. **Antwort:** Tiere sind klein (3 m) und nur nah sichtbar. Flach eingefärbt (ohne Textur) passen sie. Stilprobe vor der Übernahme.
Gegenposition **Felix (Technik):** Querfaktoren (R3) machen den Import pro Modell individuell und fehleranfällig. **Antwort:** Alle Faktoren stehen als Daten in `10_import_faktoren.json`. Ein Import-Skript liest sie, Handarbeit fällt weg.
Gegenposition **Mira (UI):** Bei realer Größe (Fuhrwerk 9,5 m) ist ein Fahrzeug ab 2 km 2 px groß. **Antwort:** Das ist mit 01 (Frage 1) an Basti gegeben: Zeichen/Icon in der Ferne, Mesh real.

## Offene Fragen an Basti
1. **Pferde-Pack:** Holst du das Quaternius Farm Animal Pack (CC0)? Ohne Pferd in Qualität bleibt das Fuhrwerk der schwächste Baustein.
2. **Lok:** Die Kenney-Lok ist gedrungen. Lieber 6,7 m lang und maßhaltig in der Höhe (Vorschlag), oder 9 m lang und dafür 5,7 m hoch (wirkt spielzeughaft)?
3. **Fertighäuser:** Ist Kitbashing aus Fantasy Town (2–3 Tage, volle Kontrolle) in Ordnung, oder soll vorher ein Fertighaus-Pack geprüft werden?
