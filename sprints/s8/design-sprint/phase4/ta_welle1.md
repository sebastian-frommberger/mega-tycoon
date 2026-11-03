# TA Welle 1: Gelände, Wasser, Boden, Bäume, Import (Phase 4, Prototyp „Welt“, schlank, 03.11.2026)
Rolle: Technical Artist (TEAM-02). Grundlage: `VERTRAG.md`, `shared/ausschnitt_vorgabe.json`, `16_prototyp_plan_v1_1.md` §2/§3, `08_landschaft.md`, `09_wasser_shader.md`, `10_import_faktoren.json`, `15_regelwerk_v1_1.md` C.
Engine geprüft: Godot 4.7.2 (`--check-only`, Läufe headless und `xvfb-run … --rendering-driver opengl3`). Bestehendes (Slice, S7-Welt, Sim, Tests) ist **nicht verändert**, es gibt nur neue Dateien.

## 1 Dateien
| Datei | Inhalt |
|---|---|
| `tools_proto/ta_export.py` | Ausschnitt-Export ds_v2 → Prototyp, deterministisch (zweimal gelaufen, md5 gleich), Laufzeit ca. 5 s. `--orte <proto_orte.json> --nur-boden` berechnet nur Acker und Bodenkarte neu |
| `slice/world/data/proto/proto_hoehe.r16` | 161 × 145 Knoten, uint16 LE × 0,05 m, mit Stempeln (See, Teiche, Bachrinne) |
| `…/proto_fein.r16`, `proto_fein_maske.u8` | **zusätzlich:** 5-m-Feinraster (801 × 721 Knoten) und Feldmaske (809 Felder fein). Damit sind See, Teiche und Bach ohne 25-m-Zacken möglich |
| `…/proto_fluss.u8` | 160 × 144, Bits 1 Rinne, 2 Aue (wie Quelle), **neu** 4 stehendes Wasser, 8 Bachfeld, 16 Gehölzsaum |
| `…/proto_boden.png` | 160 × 144 RGBA: RGB = Klassenfarbe aus 08 (sRGB), A = Klasse × 20 + 10 |
| `…/proto_acker_maske.u8` | 0 kein / 1 hell / 2 dunkel (eigene Ebene, neu berechenbar) |
| `…/proto_bach.json`, `proto_see.json` | Bach (5-m-Punkte mit Wasserspiegel), See, **muehlteich**, **dorfteich** (inkl. `muehle_vorschlag_m`) |
| `…/proto_meta.json` | Fenster, Formate, Dreiecksteilung, Flusspegel je Spalte, Klassen, Kennzahlen, md5 aller Dateien und der Quelle |
| `slice/world/proto_terrain.gd` (+ `.gdshader`) | `class_name ProtoTerrain`, API laut Vertrag (siehe §5) |
| `slice/world/proto_wasser.gd`, `proto_water.gdshader` | Wasser-Meshes. Der Shader ist eine Kopie von `phase2/code_ws_c/water.gdshader` (unverändert, `m_pro_einheit` = 1) |
| `slice/world/proto_baum.gdshader` | Baum-Material (Vertexfarbe × Instanzfarbe) |
| `tools_proto/ta_import_faktoren.py` → `…/proto_prefab_bauanleitung.json` | Prefab-Bauanleitung: 38 Rollen, 9 Zusammenbauten |
| `slice/world/proto_prefab_bau.gd` | Prefab-Bauer: Skalierung, Pivot, AABB messen, prüfen, Haus S, Fuhrwerk |
| `slice/tests/proto_terrain_shots.gd`, `proto_terrain_test.gd`, `ta_import_test.gd` | Bilder und Zählwerte, Prüfungen ProtoTerrain (15/15 grün), Import (6/6 grün) |
| `_out/bilder/*.png`, `_out/*.txt` | Bilder (A und B), Testausgaben |

md5 (`proto_meta.json`): hoehe `0e259200…`, fein `76e56c7c…`, fluss `c85c4f25…`, boden `91d1dfdd…`, acker `5a3a9b92…`, bach `230fdae3…`, see `2f06853a…`. Quelle: hoehe_s7 `cbcc488e…` (= ds_v2-Meta).

## 2 Kennzahlen
| Kennzahl | Wert | Soll |
|---|---|---|
| Ladezeit `ProtoTerrain.bauen` | **0,48–0,84 s** (Spitze 1,7 s, wenn die Maschine parallel ausgelastet war). Davon Gelände 0,2, Wasser 0,15, Bäume 0,11 s | ≤ 3 s |
| Übersicht (5,2 km) / Kern (2,9 km) | **106k Dreiecke / 22 DC** (Bäume ab 1,8 km ausgeblendet) | ≤ 1,0 M / ≤ 300 |
| Mittel (900 m, See + Bach) | 490k / 31 DC | – |
| Perf-Worst-Case (Wald, 1,4 km, flach) | 452k–592k / 29–31 DC | Gate gilt für die Übersicht, Nah-Deckel ≤ 6.000 Bäume |
| Nah: See 160 m / Bach 220 m / Mühlteich 260 m / Dorfteich 120 m | 242k / 169k / 126k / 252k, 9–13 DC | – |
| Gelände | 87.078 Dreiecke (16 Chunks + Schürze), davon 809 Felder im 5-m-Raster | – |
| Wasser | 19.090 Dreiecke, 5 Meshes (Fluss, See, Mühlteich, Dorfteich, Bach) | – |
| Bäume | 11.500 Instanzen (Kern + 500 m), 70 MultiMeshes (500-m-Chunks × 2 Arten), Laub 114 / Nadel 230 Dreiecke, alle zusammen 1,49 M | Übersicht ≤ 120k: erfüllt (0 sichtbar) |
| **Flussbreite** (Wasserlinie, quer zur Laufrichtung) | Kern **92–112 m, Median 100**; ganzer Ausschnitt 91–124 m | 60–100 m, Band 60–120 |
| Flusspegel | West 37,1 / Kernmitte 39,9 / Ost 42,6 m, Rinnensohle Kernmitte 36,4 m | Vorgabe „ca. 36,4“ = Sohle (§4) |
| See | Ø 494 m (19,2 ha), Pegel 44,8 m, 4 m tief, Schelf 70 m, Uferböschung 40 m | 400–600 m |
| Mühlteich / Dorfteich | Ø ≈ 87 m (0,60 ha), Pegel 47,8 m / Ø ≈ 26 m (525 m²), Pegel 49,1 m | 50–150 / 15–30 m |
| Wasserflächen gesamt | Fluss 41,9 ha, See 19,2 ha, Teiche 0,65 ha; Wasseranteil Ausschnitt 4,0 % (Kern 11,7 %) | Flusstal 3–5 % |
| Bach | 956 m lang, 5 m breit, Gefälle Ø 60 ‰ (Kuppenhang 30 %, Talstrecke 7–10 ‰), Rinne 1,2 m / ±10 m, Saum 2,5–17,5 m je Seite | 4–6 m + Saum 10–20 |
| Neigung Kern (Landfelder) | < 2 %: 73,1 · 2–6 %: 14,0 · 6–15 %: 3,8 · 15–30 %: 6,6 · 30–60 %: 2,0 · > 60 %: 0,5 %, Median 8,5 ‰ | (Talaue) |
| Höhe | Kern 35,0–117,9 m, Ausschnitt 33,6–154,0 m | Kern 35–118 |
| Boden Kern | Auenboden 36,5 · Wiese 19,9 · Wald 17,4 · Wasser 11,7 · Acker 6,8 · Sumpf 4,1 · Ufer 3,1 · Fels 0,4 % | – |
| Boden Ausschnitt | Wiese 33,8 · Wald 30,6 · Auenboden 21,4 · Heide 4,5 · Wasser 4,0 · Acker 2,3 · Sumpf 2,0 % | 08: Wiese 39 / Wald 30 |
| Import-Test | Haus S 9,3 × 6,4 m, H 6,5 · Wagen 5,0 × 2,17 · Gespann 9,5 m · Laubbaum 18,0 m · Nadelbaum 25,0 m · Lok 7,62 m, H 4,3 — alles im Band | ±25 % bzw. 0,9–1,2 × real |

Das Perf-Gate bezieht sich hier nur auf ProtoTerrain allein. Häuser und Wege der Stadt-Rolle kommen noch dazu. Reserve in der Übersicht: ca. 890k Dreiecke und 278 DC.

## 3 Bilder (`_out/bilder/`, Variante B jeweils `_b`)
`proto_uebersicht` (ganze Karte) · `proto_kern` · `proto_mittel` (See, Bach, Mühlteich, Dorfteich, Acker um den Platzhalter-Ort) · `proto_see_nah` (G2: Ufer bei 160 m ohne Stufen, weiche Kante) · `proto_bach_nah` (Band + Erlensaum bis zur Mündung) · `proto_muehlteich` (Damm Nord, Bach rein und raus) · `proto_dorfteich` · `proto_perf_wald` · `proto_boden_vorschau.png` (Bodenkarte mit Schummerung, weißer Rahmen = Kern).

Look-Befund: Das Wald-Wiesen-Mosaik trägt in Übersicht und Kern auch ohne Bäume (Kronentupfen im Shader). Der See ist rund, aber nicht kreisrund (Uferrauschen ±7 %), sein Ufer ist weich, Zacken gibt es keine (**G2 grün aus TA-Sicht**). Der Fluss zeigt weiter die bekannten 25-m-Uferzacken (K35). Bei sehr flachem Blick (30°) zeigt der Wasser-Shader ein kachelndes Glanzmuster, das ist Sophies Einwand aus 09. Bei 45–60° fällt das nicht auf.

## 4 Annahmen und Abweichungen (bewusst)
| # | Thema | Entscheidung TA | Grund |
|---|---|---|---|
| A1 | Einheit | Szene in **Metern** (1 Einheit = 1 m), Wasser-Shader `m_pro_einheit = 1`. Import-Bauanleitung liefert `skala_m_pro_u` (= faktor_szene × 25) | Vertrag: „Koordinaten überall in Metern“ |
| A2 | Feinraster | Zusätzlich zu den Vertragsdateien gibt es ein 5-m-Raster nur für Stempel-Felder. `hoehe_at` nutzt es dort automatisch. Grobknoten = Feinknoten [5i, 5j], am Rand der Feinmaske unverändert (vom Skript geprüft) | 25-m-Raster kann weder einen 25-m-Teich noch einen 5-m-Bach abbilden |
| A3 | Risse | Grobfelder neben Feinfeldern als Fächer mit den Kantenknoten gebaut (keine T-Kreuzungen) | Der erste Lauf zeigte Pixelrisse (Himmel) |
| A4 | Flusspegel | Pegel je Feldspalte = Rinnensohle + 3,5 m (wie `water_s7.gd`), geglättet, monoton. Vorgabe „36,4 m“ ist die **Sohle** in der Kernmitte, der Wasserspiegel liegt dort bei 39,9 m | Generator: Sohle = lv − 3,5 |
| A5 | Flussbreite | Ist 92–112 m (Median 100), oberes Ende des Bands 60–120. Wasserlinie liegt im 25-m-Raster 5–10 m außerhalb der Generator-Halbbreite | 25-m-Böschung; Korrektur = Uferböschung 40 m im Generator (K35) |
| A6 | See-Böschung | Ring 40 m auf ≥ Pegel + 0,8 m. Nordufer liegt dadurch 0,8–1,5 m über der Flussaue (44 m), der See ist leicht „aufgesetzt“ | Pegel 44,8 m fest vorgegeben, Aue nördlich tiefer |
| A7 | Mühlteich | Mitte (1612,5 / 1150), r 45 m, auf dem flachsten Bachabschnitt (Gefälle ~1 %), Bach fließt hindurch, Damm Nord (Pegel + 0,5), 1 m Absturz hinter dem Damm. `muehle_vorschlag_m` (1600,5 / 1088) = Damm-Ostseite | Mühle braucht Gefälle am Teich-Auslauf |
| A8 | Dorfteich / Platzhalter-Dorf | Dorfteich (1400 / 1325), r 12,5 m. Ackergürtel um ein **Platzhalter-Dorf** (1400 / 1350, r 150 m) zwischen See und Bach, 140 m vom Seeufer. Die Stadt-Rolle kann das Dorf woanders hinlegen und mit `--orte proto_orte.json --nur-boden` Acker und Bodenkarte neu rechnen (getestet) | Fischer ≤ 1,5 km, Pfad zum Dorf kurz |
| A9 | Aue | Auenboden = < 500 m zum Fluss und flach. **Nicht** Quelle-Bit 2: Das ist Lenas Mühlen-Band (300–1.500 m Flussabstand), keine Überflutungsaue. Folge: Kern 36 % Auenboden (ist Talaue) | sonst 51 % „Aue“ im Kern |
| A10 | Heide | 08 verlangt 180–520 m, hier ist alles < 154 m. Gelockert auf trockene Kuppen > 85 m (nur Rand, 4,5 %) | sonst 0 % |
| A11 | Wald-Mosaik | 2 Rauschlagen (Wellen 400 / 125 m) + Hangbonus, Ziel 38 % außerhalb des 250-m-Flussstreifens, Auwald 15 % im Streifen, Feldgehölze ~5 je km², kein Wald < Ortsradius + 250 m | TF3-Referenz, 08: Flecken 100–800 m |
| A12 | Baumdichte | Wald innen 4 / Rand 2,5 je Feld (08: 6–8 / 3–4), Aue 0,25, Wiese 0,1, Sumpf 1, Ufer 0,6, Nadelanteil 15 %, Sichtweite 1,8 km (08: 2,5 km), Bäume nur Kern + 500 m | mit 08-Dichte Worst Case 950k Dreiecke |
| A13 | Bodenkarte | Farben direkt im PNG (Klassen-ID im Alpha) statt 08-Kanalkodierung (R Acker, G Heide, B Sumpf, A Wald) | 1 Sampler, keine prozedurale Doppelregel; zur Laufzeit beschreibbar wie 08-A |
| A14 | Ufer | Ufer-Klasse nur am Fluss. Ufersaum an See und Teichen macht der Shader nach Höhe über dem Pegel (4 Gewässer als Uniform) | 25-m-Uferfelder sahen am runden See wie Achtecke aus |
| A15 | Bach-Sohle | aus dem Gelände **vor** den Stempeln, monoton fallend, Stauwurzel 80 m vor dem Mühlteich auf Teichhöhe, neben dem See ≥ Seepegel + 0,3 | Teichmulde zog sonst die ganze Unterstrecke unter den See |
| A16 | Import-Beispiele | Fantasy Town, Prototype und Watercraft-Ruderboot liegen nicht in der Arbeitskopie (nur Previews). Haus S und Fuhrwerk sind Platzhalter-Boxen in exakter Kenney-bbox. Bäume (`props/kenney`) und Lok (`assets/kenney/Train Kit`) sind echte Modelle | Modelle fehlen lokal |
| A17 | Bodenkarte laden | `FileAccess` + `Image.load_png_from_buffer` (wie die `.r16`). Godot legt automatisch `proto_boden.png.import` an, das wird nicht benutzt | Export: Ordner `world/data/proto/*` muss in den Export-Filter (Felix) |

## 5 API für Felix und die Stadt-Rolle
`ProtoTerrain.bauen(parent, "res://world/data/proto") -> ProtoTerrain` · `hoehe_at(x, z)` (exakt die gerenderten Dreiecke) · `boden_at(x, z)` (Klassen-ID, Liste in `proto_meta.json`) · `fluss_bits_at(x, z)` · `fluss_pegel_at(x)` · `ist_wasser(x, z)` (Fluss, See, Teich; Bach blockiert nicht) · `baeume_freistellen([Vector3(x, z, r), …]) -> int` (Orte, Wege, Hofstellen freischlagen, baut nur die MultiMeshes neu) · `wasser_variante_b(bool)` (A/B für A8) · `stats` (Dreiecke, Meshes, ms) · `gewaesser` (Mitte, r, Pegel). `proto_see.json` enthält `muehlteich`, `dorfteich` und `see`, jeweils mit Mitte, Radius, Pegel und Uferrauschen.

## 6 Was Welle 2 (TA + Sophie) braucht bzw. bekommt
1. **Modelle:** Fantasy Town (wall*, roof-high, planks, poles, cart, cart-high, watermill), Prototype `animal-horse`, Watercraft `boat-row-small` aus Bastis Kenney-Ordner nach `res://props/kenney_proto/<kit>/` kopieren (`res_ziel` in der Bauanleitung), dann `--import`. Danach liefert `ProtoPrefabBau.baue(rolle)` statt der Platzhalter die Modelle. Je Rolle 1 Mesh zusammenfassen und als `.tres` speichern (R4).
2. **Steg / Fischerhütte / Boot:** Seeufer-Höhe = 44,8 m (Pegel) + 0,0…0,8 m Böschung. Guter Stegplatz: Südufer bei (1212 / 1262), von dort ~210 m zum Platzhalter-Dorf. Boot schwimmt bei y = 44,8. Bootsschleife im See: Kreis r ≤ 180 m um (1212,5 / 1012,5), Tiefe dort ≥ 3 m.
3. **Floß als Kulisse:** Fluss fließt nach **Westen**, 0,6 m/s im Shader. Pegel über `fluss_pegel_at(x)`. Floß auf y = Pegel, Kurs = Flussmitte je Spalte (ist in `proto_wasser.gd` intern berechnet, bei Bedarf als API herausziehen).
4. **Mühle:** `muehle_vorschlag_m` am Mühlteich-Damm. Im Damm fehlt das Bachband auf ~10 m (Wasser 0,5 m unter Gelände). Dort gehören Wehr und Rad hin.
5. Gespann- und Rad-Shader: Im Compatibility-Renderer war `COLOR` im MultiMesh ohne `use_colors` schwarz (Vertexfarbe wird mit der Instanzfarbe multipliziert). Darum färbt der Baum-Shader jetzt über `use_colors`. Ob `INSTANCE_CUSTOM` ankommt, ist damit noch nicht geklärt. Für Gangphase und Haltung (Felix, `INSTANCE_CUSTOM`) früh mit einem Minimaltest prüfen.

## 7 Offene Punkte
| # | Punkt | Vorschlag |
|---|---|---|
| O1 | S7-Plateaus im Ausschnitt: Haberau-Stadtplateau 118 m (Südrand Kern, steiler Ring, Bach entspringt an dessen Flanke) und Industrie-Plateau farm_2 61 m mit Kreisböschung bei (1875 / 1325). Wirkt konstruiert (08 Nebenbefund) | Welle 2/3: im Export glätten (nur Ring, Plateau bleibt), wenn AD/Jonas zustimmen. Vertrag sagt „Ausschnitt fest“, darum nicht angefasst |
| O2 | Fluss-Uferzacken 25 m (K35) | Feinraster auch im Flusskorridor (+~1.000 Felder, +50k Dreiecke) oder Böschung 40 m im Generator |
| O3 | Dorfteich im 5-m-Raster sichtbar polygonal (26 m Ø, 16-Eck) | 2,5-m-Raster nur für Teiche < 40 m oder Spline-Mesh |
| O4 | Bach-Rinne nah kaum als Graben lesbar (5-m-Raster), der Saum trägt die Lesbarkeit. Ab ~1 km ist der Bach eine Haarlinie | Zeichenlinie ab 1 km (09 Frage 2) |
| O5 | Kanten der Waldflecken im Kern bei 2–3 km noch leicht treppig (25-m-Bodenkarte) | 2 × Auflösung der Bodenkarte (320 × 288) oder Distanzfeld im Alpha |
| O6 | Ackerstreifen-Richtung je Gewann zufällig, nicht hangparallel | mit Stadt-Rolle: Gewannrichtung aus Wegen/Hang |
| O7 | Wasser-Glanzmuster bei flachem Blick | Flowmap/Normal-Map-Tausch in `wellen_grad()` (Sophie) |
| O8 | Ladezeit schwankt mit Maschinenlast (0,5–1,7 s) | Bau in WorkerThreadPool wie `terrain_s7.gd`, falls Felix' Szene enger wird |

## 8 Aufrufe
```
python3 -I tools_proto/ta_export.py                    # Daten (deterministisch)
python3 -I tools_proto/ta_import_faktoren.py           # Bauanleitung
godot --headless --path slice --import
godot --headless --path slice -s res://tests/proto_terrain_test.gd
godot --headless --path slice -s res://tests/ta_import_test.gd
xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --path slice -s res://tests/proto_terrain_shots.gd -- _out/bilder [b]
```
