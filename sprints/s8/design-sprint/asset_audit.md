# Asset-Audit Kenney All-in-1 3.7.0 – Design Sprint Welt (02.11.2026)

Asset-Team / Technical Artist. Grundlage: Inventar S2, Bastis Feedback vom 02.11., Messung aller 5.073 GLB/GLTF-Modelle (49 Kits mit 3D-Modellen) direkt auf Bastis Rechner. Gemessen wurden die Bounding-Box aus dem JSON-Chunk (POSITION min/max, Knoten-TRS) und die Dreiecke. Es gab 0 Fehler, auf dem Gerät wurde nichts verändert.
Dateien: `asset_audit_kits.csv` (Maßstab je Kit), `asset_audit_bbox.py` (Messskript, reproduzierbar), `asset_audit_bilder/contact_sheet_kits.png` (Kenney-Samples und Previews).

**Wichtigster Befund:** Die Kits haben **völlig verschiedene Einheiten**. Eine Kit-Einheit (u) entspricht bei den City Kits etwa 10 m, beim Train Kit 2,6 m, beim Fantasy Town Kit 3 m und beim Car Kit 1,8 m. Werden alle Kits mit demselben Faktor gesetzt, ist der Lkw (3 u) so lang wie drei Häuser und die Lok 26 m lang. Das ist die Ursache für Bastis Punkte 2 und 3. Lösung: Jedes Kit bekommt einen eigenen Importfaktor (Tabelle 1) und wird so auf echte Meter gebracht. Eine Lesbarkeits-Überhöhung kommt danach je Objektklasse hinzu, nicht je Kit.

## 1. Kit-Übersicht und Maßstab

Spielmaß: 1 Szeneneinheit = 1 Feld = 25 m (S7, `welt.gd`). **Faktor = Meter pro Kit-Einheit / 25.** Die Meter pro Einheit sind aus Referenzobjekten geschätzt, Genauigkeit etwa ±20 %.

| Kit | Modelle | Ref.-Objekt | m/u | Faktor | Tris Median/Max | Eignung 1800–1830 |
|---|---|---|---|---|---|---|
| **Fantasy Town Kit** | 167 | Wandmodul 1 u = 1 Geschoss | 3,0 | 0,12 | 96 / 1.628 | **Kern-Kit** Dorf/Stadt, Fachwerk, Mühlrad, Karren |
| **Train Kit** | 103 | Schwelle 1 u ≈ 2,6 m | 2,6 | 0,104 | 416 / 1.944 | Dampfloks a–c, Güterwagen gut |
| **Nature Kit** (+Classic) | 329 + 232 | Zaun 0,34 u ≈ 1,1 m | 3,2 | 0,128 (Bodentiles 1,0) | 76 / 720 | **Kern-Kit** Bäume, Klippen, Flüsse, Felder |
| Survival Kit | 80 | Zaun 0,52 u ≈ 1,2 m | 2,4 | 0,096 | 124 / 758 | Details: Amboss, Fässer, Holz, Stein |
| Graveyard Kit | 91 | Figur 0,86 u = 1,75 m | 2,0 | 0,08 | 256 / 1.141 | Mauern, Heuballen, Laternen, Friedhof |
| Castle Kit | 76 | Mauer 1,3 u ≈ 8 m | 6,0 | 0,24 | 166 / 1.598 | Stadtmauer, Türme, Steinbrücke |
| Hexagon Kit | 72 | unit-house 0,36 u ≈ 9 m | 25 | **1,0** | 163 / 1.208 | Mini-Häuser/-Mühle, schon im Spielmaß |
| Prototype Kit | 145 | animal-horse 1 u ≈ 2,4 m | 2,4 | 0,096 | 64 / 860 | **einziges Pferd** (sehr einfach) |
| Pirate Kit | 72 | ship-large 13 u ≈ 30 m | 2,3 | 0,092 | 281 / 2.282 | Segelschiffe, Türme, Felsen, Kräne |
| Watercraft Pack | 46 | Ruderboot 2,4 u ≈ 4 m | 1,7 | 0,068 | 235 / 2.796 | Ruder-/Fischer-/Segelboot, Rest modern |
| Retro Fantasy Kit | 105 | Wandmodul 1 u | 3,0 | 0,12 | 64 / 656 | Fachwerk, aber **texturiert** (Stilbruch) |
| City Kit Suburban/Comm./Ind. | 40/41/25 | Straßentile 1 u | 10 | 0,40 | 785 / 5.246 | modern, nur Fernsicht/Spätepoche |
| City Kit Roads | 95 | road 1 u ≈ 10 m | 10 | 0,40 | 112 / 1.636 | Asphalt, modern |
| Car Kit | 50 | Limousine 2,5 u = 4,5 m | 1,8 | 0,072 | 1.190 / 3.124 | Epoche falsch, teuerste Kleinobjekte |
| Mini Forest | 22 | Figur 0,82 u | 2,1 | 0,085 | 251 / 847 | Bäume, Steine, Zelte |

Für die Epoche nicht relevant sind Space, Blaster, Food, Furniture, Marble, Coaster, Minigolf, Racing, Toy Car, Weapon, Holiday, Brick, die Dungeon-, Cave- und Space-Module sowie Tower Defense. Modular Buildings, Building Kit, Retro Urban und Road Pack sind modern. Das Factory Kit taugt nur für Details wie Zahnräder und Trichter.

**Zielmaße (echte Meter → Szeneneinheiten):** Bauernhaus 9×9 m, Firsthöhe 7 m (0,36×0,36, h 0,28). Handwerkerhaus 9×12 m, 10 m (0,48 lang). Bürgerhaus 12×12 m, 13 m. Mietshaus 12×24 m, 15 m. Fuhrwerk mit 2 Pferden ≈ 8 m (0,32). Frühe Dampflok mit Tender ≈ 10 m. Wagen 6–7 m. Landstraße 5–6 m (0,2–0,24 je Feld). Bäume 10–20 m. Windmühle 15–18 m.
Wahre Größe ist bei Kamera 40 m gut lesbar, bei 1–5 km aber praktisch unsichtbar. **Vorschlag für die Scale-Rolle:** Die Überhöhung je Klasse fest regeln, zum Beispiel Fahrzeuge ×1,5, Häuser ×1,0, Industrie ×1,0, Bäume ×1,2. Die Rangfolge Fahrzeug < Haus < Industrie bleibt dabei immer erhalten.

## 2. Zuordnung zu unseren Bedarfen

Die Größenangaben sind gemessene Kit-Einheiten, umgerechnet in Meter nach dem Kit-Faktor aus Abschnitt 1.

| Bedarf | Bestes Modell | Alternativen | Größe im Spiel |
|---|---|---|---|
| **Haus S Bauernhaus** | Fantasy Town modular: `wall-wood*` 3×3 Module + `roof-high*`, 1 Geschoss | Hexagon `unit-house` (fertig, 9 m, 80 Tris); Survival `structure-roof` als Schuppen | 9×9×7 m, Faktor 0,12 |
| **Haus M Handwerker** | Fantasy Town: EG `wall` (Stein) + OG `wall-wood`, 3×4 Module, `roof-gable`, `chimney` | Hexagon `unit-mansion` (15 m lang) | 9×12×10 m |
| **Haus L Bürgerhaus** | Fantasy Town 3 Geschosse, 4×4, `roof-high-window`, `balcony-wall` | Retro Fantasy `wall-paint*` (Stilbruch); Suburban `building-type-*` nur für Spätepoche, Faktor 0,4 | 12×12×13 m |
| **Haus XL Mietshaus** | Fantasy Town 3–4 Geschosse, 4×8 Module, `wall-window-*` | City Commercial (modern) | 12×24×15 m |
| **Dorf-/Stadtbausteine** | Fantasy Town `road*` (Pflaster, 1 u = 3 m, auch `road-bend` 3 u), `stairs-*`, `fountain-round(-detail)` (6 m), `stall-*` (Markt), `lantern`, `banner-*` | Castle-Kit-Mauern/-Türme als Stadtmauer (Faktor 0,24); Graveyard für den Kirchhof | – |
| **Fuhrwerk (statt Lkw)** | Fantasy Town `cart` / `cart-high` (1,3–1,4 u ≈ 4 m) + Prototype `animal-horse` (≈ 2,4 m), als Szene kombiniert | Survival `resource-*` bzw. Nature `log_stack` als Ladung | ≈ 6–8 m |
| **Kutsche** | nicht vorhanden; Behelf `cart-high` + 2 Pferde | Zukauf (Abschnitt 3) | – |
| **Dampflok** | Train `train-locomotive-a/b/c` (2,6–2,8 u ≈ 7 m, 416–1.900 Tris) | `train-locomotive-passenger-a/b` | 7 m, Faktor 0,104 |
| **Güterwagen** | Train `train-carriage-coal`, `-dirt` (Erz), `-wood`, `-lumber`, `-flatbed(-wood)`, `-box` (alle 2,7 u ≈ 7 m) | `-tank` (Fass/Bier denkbar); Container nicht verwenden | 7 m |
| **Personenwagen** | keiner vorhanden (Inventar S2 irrt); Behelf `train-carriage-box` oder `train-tram-classic` | Zukauf | – |
| **Gleis** | Train `railroad-straight` (4 u ≈ 10 m), `-corner-small/large`, `-curve`, `track`/`spline-track` | wird schon genutzt | – |
| **Mühle** | Fantasy Town `windmill` (nur Flügel, 3,1 u ≈ 9 m) auf Turm aus `wall-rounded` + `roof-point`; `watermill(-wide)` (Rad, 5,4 m) an Fachwerkhaus | Hexagon `unit-mill` (fertig, 17 m hoch); Hexagon `building-mill`/`-watermill` (mit Hex-Sockel) | Turm 15 m |
| **Schmiede / Hütte** | Fantasy-Town-Haus + `chimney-base/-top` + Survival `workbench-anvil`, `workbench-grind` | Hexagon `building-smelter` (Hex); später City Industrial + `chimney-large` | – |
| **Zeche / Mine** | Nature `cliff_blockCave_stone` als Stollenmund + Gleis + `train-carriage-dirt`/`-coal`, Fördergerüst aus Fantasy `poles`/`planks` bzw. Retro Fantasy `structure*`, `pulley-crate` | Hexagon `building-mine` (Hex) | – |
| **Kraftwerk-Ersatz** | Epoche hat keins. Vorschlag: Köhlerei/Kalkofen aus Nature `log_stackLarge`, Survival `campfire-pit`, Fantasy `chimney` | City Industrial `building-l` + `chimney-large` als Spätepoche | – |
| **Farm / Feld** | Nature `crops_wheatStageA/B`, `crops_cornStageA–D`, `crop_carrot/turnip/pumpkin`, Classic `wheat` (als MultiMesh auf Bodenfarbe), Fantasy `fence*` | Hexagon `building-farm`/`-sheep`; Graveyard `hay-bale(-bundled)` | Halm 1–4 m, Faktor 0,128 |
| **Lager** | Großes Fantasy-Town-Haus (`wall-wood-doorway-square-wide`) + Survival `box-large`, `barrel` + Retro Fantasy `barrels`, `detail-crate*` | Pirate `crate`, `barrel` (×0,5 skalieren, sehr groß) | – |
| **Bahnhof** | Fantasy `planks` (Bahnsteig) + `pillar-wood` + `overhang` + `roof-flat`; Empfangsgebäude als Haus M/L | Retro Fantasy `wood-floor*`, `structure*` | – |
| **Werkzeugfabrik / Manufaktur** | Haus XL + `chimney` + Factory Kit `cog-*` als Schild + Survival `tool-*` | City Industrial `building-c/-m` (Spätepoche) | – |
| **Sägewerk** (Bonus) | `watermill` + Nature `log_stack*` + Survival `resource-planks` + Train `carriage-lumber` | – | – |
| **Brücken** | Straße: Nature `bridge_side_stone(Round)` + `bridge_center_stone(Round)` modular (1 u ≈ 3 m, auf Straßenbreite strecken). Fuß/Feld: `bridge_wood(Narrow)` | Castle `bridge-straight(-pillar)` (Steinbogen); Classic `bridge_arch`; City Roads `road-bridge` + `bridge-pillar` (modern, heute im Spiel) | Spannweite je Segment 3–6 m, Pfeiler wiederholen |
| **Flussstücke** | Nature Classic `ground_dirtRiver*` (15, mit Ufer, Wasserfläche separat) | Nature `ground_river*` (14, flacher); Classic `cliffBrown_waterfallTop/Mid` für Wasserfälle; Hexagon `river-*` (Hex, unbrauchbar) | **Tile = 1 Feld (Faktor 1,0)**: Flussbreite = Anteil der Rinne im Tile (nicht gemessen, im Spiel prüfen); breite Flüsse über das Gelände-Mesh |
| **Boden-/Geländetiles** | Kein Tile-Ansatz; Bodenvariation über Terrain-Vertexfarben. Als Streu-Decals: Pirate `patch-grass(-foliage)`/`patch-sand` (≈ 12–18 m), Survival `patch-grass(-large)`, Nature `ground_path*` (Feldwege) | Castle `ground-hills`; Retro Urban `grass-hill` | – |
| **Felsen / Klippen** | Nature `cliff_*_stone` / `_rock` (56: block, half, quarter, slope, steps, corner, cave), Classic `cliffBrown_*` / `cliffGrey_*` (36) für Geländekanten | Pirate `rocks-a/b/c` (≈ 10 m Findlinge), Nature `rock_large*`, `stone_*` (60), Castle `rocks-large` | Klippenblock 3 m → für Geländestufen ×2–3 |
| **Bäume / Wald** | Nature `tree_default/oak/fat/plateau` (Laub), `tree_pine*` (≈ 25 Nadelbäume), `_fall`/`_dark`-Varianten; als MultiMesh | Fantasy `tree(-high)(-crooked/-round)` (7–9 m), Survival `tree(-autumn)(-tall)`, Graveyard `pine(-crooked)`, Castle `tree-large`; Hexagon `unit-tree` für Fernsicht | 5 m nativ → ×2–3 auf 10–15 m |
| **Vegetation** | Nature `plant_bush*`, `grass*`, `flower_*` (9), `mushroom_*`, `stump_*`, `log*` | Fantasy `hedge(-large)(-curved/-gate)` | – |
| **Zäune / Mauern** | Fantasy `fence`, `-gate`, `-curved`, `-broken`; Nature `fence_simple/planks/…` (12); Graveyard `stone-wall*`, `brick-wall*`, `iron-fence*` | Survival `fence(-fortified)`; Castle `wall*` (Stadtmauer); Suburban `fence-*` (moderner Gartenzaun) | Zaun 1,1 m |
| **Belebte Blöcke** | Gärten: Nature `crop_*` + `fence_*` + `plant_bush`. Schuppen: Survival `structure(-roof)`. Brunnen: Fantasy `fountain-*`. Höfe: Survival `barrel`, `box`, `resource-wood`, Graveyard `hay-bale`, `bench`, `lightpost-*`. Markt: Fantasy `stall-*`. Wäsche/Fahnen: `banner-*` | Retro Fantasy `pulley-crate`, `ladder`; Graveyard-Figuren (`character-keeper`) als Passanten | Details 0,3–3 m. Pro Haus 3–6 Streuobjekte als MultiMesh |

**Aufwand:** Fertige Häuser im Epochenstil gibt es nur als Hexagon-`unit-*` (3 Typen, sehr klein und simpel). Fantasy Town ist **modular**. Wir brauchen also etwa 10–14 vormontierte Haus-Prefabs (S/M/L/XL × 2–3 Varianten × Farbtöne) und 8–10 Industrie-Kitbashes als eigene `.tscn`. Schätzung: 2–3 Tage Technical Art. Sie sollten bei der Montage zu einem Mesh gemergt werden (siehe Risiken).

## 3. Lücken und Zukaufempfehlung

| Lücke | Im Paket? | Empfehlung (belegt) |
|---|---|---|
| Pferde-/Nutztiere in Qualität | nur Prototype `animal-horse` (sehr abstrakt); Cube Pets sind würfelig und nicht kompatibel | **Quaternius „LowPoly Animated Farm Animal Pack“**: CC0, u. a. Pferd, Kuh, Schaf, Schwein, animiert, Blend/OBJ/FBX. https://opengameart.org/content/lowpoly-animated-farm-animal-pack |
| Fachwerk-/Dorfhäuser mit mehr Varianten | Fantasy Town genügt für den Start | **Quaternius „Medieval Village MegaKit“**: CC0, 300+ modulare Teile (Wände, Dächer, Fenster, Türen), glTF/FBX/OBJ. Standard teils frei, Pro/Source kostenpflichtig, auch im Godot Asset Store. https://quaternius.com/packs/medievalvillagemegakit.html. Auch modular, also kein Fertighaus-Ersatz; Stil auf Fantasy Town vorab prüfen |
| Kutsche, Postkutsche, Planwagen | fehlt | Kein CC0-Modell verifiziert. Treffer (CGTrader, Superhive) sind kostenpflichtig oder haben unklare Lizenz und Stil. Empfehlung: Kitbash aus `cart-high` + Plane (Fantasy `roof-*`) + 2 Pferde |
| Personenwagen frühe Bahn | fehlt | Kitbash aus `train-carriage-box` (Fenster als Decal) oder Zukauf. Keine CC0-Quelle geprüft |
| Fertige Industrie-Ikonen (Hochofen, Fördergerüst) | fehlt | Kitbash (Abschnitt 2). Poly Pizza wurde nicht geprüft, Vorschlag für eine Folgerecherche |

Fazit: **Zukauf ist für den Prototyp nicht nötig.** Fantasy Town + Nature + Train + Survival/Graveyard decken etwa 85 % ab. Der einzige echte Mehrwert ist das Farm-Animal-Pack für Pferde.

## 4. Risiken

- **Lizenz:** Alle 49 Kit-Lizenzdateien sind CC0 (geprüft). Quaternius-Packs sind laut Seiten ebenfalls CC0. Fremdquellen (CGTrader u. a.) sind meist nicht CC0, dort jedes Modell einzeln prüfen.
- **Stilbruch:** Fantasy Town, Nature, Survival, Graveyard, Castle und Train nutzen denselben Kenney-Colormap-Look (flach, Atlas), das passt zusammen. **Retro Fantasy** ist texturiert (Stein-/Holz-Pixeltextur) und bricht klar. Ebenso **Hexagon-Gebäude** (Hex-Sockel, sehr gesättigt) und **City/Car-Kits** (Moderne). Paletten unterscheiden sich: Fantasy rot/grün, Graveyard violett-grau, Castle blau/beige. Abhilfe: gemeinsame Farbkorrektur über ein Material-Override oder einen Colormap-Tausch je Kit, siehe Bastis Punkt 5 (neutralere Industrien).
- **Maßstab:** Faktoren sind aus Referenzobjekten geschätzt (±20 %) und müssen im Spiel nebeneinander geprüft werden: Haus, Fuhrwerk, Lok, Baum, Straße auf einem Feld. Die Pivots sind uneinheitlich (Fantasy-Wände stehen am Rand, Nature-Tiles in der Mitte), also beim Import normieren.
- **Polygone:** Die Kits sind sehr leicht (Median 64–416 Tris). Teuer sind nur Car Kit (Ø 1.190), City Industrial (Ø 1.162) und Commercial (max 5.246). Ein modulares Fantasy-Haus hat 20–40 Teile, also 2–4k Tris, aber auch 20–40 Draw Calls. **Bei der Montage mergen** (eine Mesh-Datei je Prefab) und Bäume, Felder und Streuobjekte als MultiMesh setzen. Bei 300 Häusern ≈ 1 Mio. Tris ist das unkritisch, wenn gemergt und mit LOD bzw. Sichtweitenbegrenzung.
- **Modularität:** Wir verlassen uns auf eigene Prefabs. Das Stadtwachstum (S→L) braucht zu jeder Stufe ein passendes Prefab, Aufwand siehe Abschnitt 2.
