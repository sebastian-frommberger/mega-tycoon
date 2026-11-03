# Integration Welle 2 (Felix, Lead Dev): Prefabs, Kulissen, Schilder, Easing (schlank)

Stand 03.11.2026, Arbeitskopie `p4/int/` (Basis: main `169e75f` Rohmerge W2), Godot 4.7.2 (API gegen `doc472`, `--check-only` für alle `proto_*`/`ta_*`-Skripte ohne Fehler). Grundlagen: VERTRAG.md (Welle 2), `ta_welle2.md`, `felix_welle2.md`, `aylin_welle2.md`, `felix_perf_aufschluesselung.md`.

## 1 Entscheidungen

| # | Thema | Entscheidung | Grund |
|---|---|---|---|
| I1 | Platzhalter + Prefabs | **Eine** Bau-Funktion: Gruppierung nach `ProtoPrefabs.schluessel(it)` (Typ bzw. `nebengebaeude/<variante>`), Mesh = `ProtoPrefabs.mesh_fuer(key)`, MultiMesh mit `use_custom_data` + `use_colors` (Weiß), Custom = `custom_fuer(it)`, **kein** `material_override`. Fern-LOD (`mesh_fern`, `FERN_TYPEN`) ab 650 m (Rand 30 m) als zweites MultiMesh (`mmis_fern`). Box-Mesh bleibt Fallback für Typen ohne Prefab. | TA-API direkt (class_name), Felix' Pfad-Hooks (`prefab_script`, `PREFABS`) und TAs Testhooks entfernt: keine doppelten oder toten Hooks |
| I2 | Flächen `flaeche_*` | Felix' `_flaeche_bauen` (Raster ≤ 2,5 m am Gelände, +0,08 m, b × t je Instanz), nicht TAs 1 × 1-m-Prefab | Folgt dem Hang; das flache Einheitsquad würde am Hang schweben/einschneiden |
| I3 | Varianten | Prefab-Varianten-Mesh je Schlüssel, unskaliert; Skalierung auf b × t nur noch für Box-Fallback | Alle 52 Nebengebäude haben `variante`; TA-Mesh ist schon maßhaltig (inkl. Dachüberstand) |
| I4 | Sichtweiten | Felix' Listen bleiben: Kleinteile 700 m ohne Schatten, Stadtbäume 1,8 km, Flächen 2,5 km; dazu Fern-LOD 650 m | TA schlug 900 m für Kleinkram vor; 700 m ist strenger und war schon gemessen |
| I5 | Steg, Ruderboot | aus den Instanzen übersprungen (`ProtoKulissen.TYPEN_SELBST`), `ProtoKulissen.bauen(modelle_root, terrain, dir)` in `_baue_modelle` | Pegel-Lage und Dümpeln kommen von TA |
| I6 | Fahrzeug-Shader | **Ein** Shader: `world/proto_prefab.gdshader` (TA). `proto/proto_fahrzeug.gdshader` und Felix' Box-Fahrzeuge gelöscht; `proto_fahrzeuge.gd` nutzt nur `ProtoPrefabs.fahrzeug(kat)` | Doppelte Belegung von `INSTANCE_CUSTOM` beseitigt |
| I7 | Belegung `INSTANCE_CUSTOM` (Fahrzeuge) | **x** Gang = `fmod(Gangphase × 2,6 m, 240)`; **y** Variante `variante_wert(i % 4)`; **z** Nicken rad (Drehung um +x, + = Bug senkt sich; Easing liefert −nick); **w** Wanken rad (um +z, + = linke Modellseite hebt sich). Wippen des Gespanns (Regelwerk `wippen_cm`) geht als Höhe 0…12 cm in den Transform (hebt, sinkt nie ein). Transform sonst nur Position + Gier (E7). | Gangphase mit Felix' Frequenzdeckel (≤ 2,5 Hz bei 1,15 v_sim) statt echter Strecke: bei 150 m/s Sim-Tempo würden Beine sonst mit ~58 Hz zappeln. Räder laufen über TAs Radius-Rundung mit (≈ 1,2 U/s ≤ `rad_u_s_max` 3). |
| I8 | Schilder | `ProtoSchilder.bauen(self, cam, orte, terrain)` direkt nach `_baue_kamera()`; Taste **N** Schilder an/aus (Signal `schilder_geaendert`, HUD-Zeile), kein Modal | Hook laut Aylin §2; Plaketten Gutshof/Mühle aus `proto_orte.json["industrie"]`, Gebäude neutral |
| I9 | Kurvenfaktor | Fuhrwerk und Postkutsche **0,70** (vorher 0,55 / 0,60) in `world/data/proto/regelwerk.json` und `phase3b/12_regelwerk_v1_1.json` | Felix' Vorschlag §4, PO |
| I10 | Kurvenradius-Regel (PO) | **Radius 25 m, Abweichung bis 11 m von der Feldmitte** (statt 8 m) für Fahrlinie und Straßenband: `strasse_gleis_bild.ortsstrasse_abweichung.m_max` 8 → 11 (beide JSON), Default in `proto_strassenband.gd` 11 m; Douglas-Peucker-Toleranz = max(m_max, 9 m) = 11 m. Bogenscheitel 90°-Ecke 10,4 m ≤ 11 m (Test). | Entscheidung PO; löst den Zickzack der 2:1-Treppe (Route 7: E6 2,74 → 1,21 × W/2, E5 A grün) |
| I11 | E6 > W/2 | bleibt bei 0,70; E6 als **„ABW bewusst“** offen in `proto_easing.csv` (Toleranz 1,3 × W/2 benannt; A 1,30 hält, B 1,38 überschritten). E5 (Halt) bleibt hartes Gate. | Auftrag: Abweichung offenlegen statt Werte drehen; sichtbar ≤ 0,28 s |
| I12 | Perf-Zwischenabstände headless | Übersicht 1,8 / 1,2 km sind headless nur Info („obere Schranke“), Gate gilt live (xvfb) | Dummy-Renderer hält keine MultiMesh-Transforms; Nah- + Fern-LOD und Rand-Chunks zählen doppelt (1,14 / 1,60 M gezählt gegen 0,73 / 0,60 M live) |

**Annahmen:** Hasenwinkel ist Weiler → Schild nach Aylins Regel nur ≤ 500 m (Bild `int_hasenwinkel_nah`), in Presets 1–5 nicht sichtbar. Variante der Fahrzeuge = Index im Fuhrpark. `proto_mass` misst Fuhrwerk/Postkutsche über `ProtoPrefabs.fahrzeug(kat)` (das fahrende Mesh), Nebengebäude-Varianten je Schlüssel gegen ihren `varianten_m`-Eintrag (Maße aus dem Namen `…_18x10`). Regression d07 (21 Suiten) nicht neu gelaufen: kein Bestandscode geändert.

## 2 Tests (gemergter Stand, headless; `proto_mass` zusätzlich xvfb/opengl3)

| Suite | Ergebnis |
|---|---|
| proto_terrain_test | GRÜN 15/15 |
| ta_import_test | GRÜN 6/6 |
| ta_welle2_test | 23/23 |
| proto_epochen_test | 17/17 |
| proto_strassenband_test | 36/36 (90°-Ecke: R 25 m, Scheitel 10,4 m ≤ 11 m) |
| proto_welt_test | 35/35 (neu: Schlüssel/Prefabs/Fern-LOD, Kulissen, Schilder 3 Orte + 2 Plaketten, Taste N; Sim-Takt-Prüfung mit definiertem Rest 0,5, vorher Float-Rundung 4/5 Ticks) |
| proto_easing_test | 15 OK, 0 FAIL, **2 ABW** (E6 A/B, siehe §3) |
| proto_sim_test | 11/11 |
| proto_band_hoehe_test | 2/2 |
| proto_schilder_test | 51/51 |
| proto_mass headless | 95/95 (Prefab-AABB, 3 Nebengebäude-Varianten, Perf gezählt) |
| proto_mass xvfb opengl3 | 95/95 (Perf live) → `phase4/proto_mass.csv` |

Aufruf: `p4/int/_out/run_proto_tests.sh` (alle Suiten, Logs `_out/logs/`), xvfb: `xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --path slice -s res://tests/proto_mass.gd`.

## 3 Easing E5/E6 (Kurvenfaktor 0,70, R 25 m / 11 m)

| # | A: 10 Testrouten | B: Szene-Kette | Info: alte Werte 0,55/0,60 (A / B) |
|---|---|---|---|
| E1 Prüfsumme an = aus | OK bitgleich | OK (3.000 Ticks, 20 Lieferungen) | – |
| E2 kein Sprung | OK 0,85 × | OK 0,85 × | 0,85 / 0,85 |
| E3 Gierrate | OK 0,95 × | OK 0,95 × | 0,89 / 0,89 |
| E4 Querbeschl. | OK 0,80 × | OK 0,84 × | 0,80 / 0,80 |
| E5 Halt ≤ W/2 | **OK 1,00 ×** (0 Verstöße) | **OK 1,00 ×** | rot 3,08 / 1,58 |
| E6 Versatz ≤ W/2 | **ABW 1,30 ×** (hält 1,3) | **ABW 1,38 ×** (Fuhrwerk 2 Mehl; Fuhrwerk 1 0,82, Kutsche 0,91) | rot 3,20 / 2,08 |
| E7 Stauchung | OK 1,0000 | OK 1,0000 | – |
| E8 Kosten 10 Fz | – | OK p95 0,34 ms | – |

**Abweichung E6 (bewusst):** 0,70 bleibt. Grund: Rückstand nach dichten Eckfolgen (Mühlweg – Kirchstraße – Hauptstraße); die Überhöhung +15 % holt ihn erst nach ≈ 380 m Gerade ein. Sichtbar ≤ 0,28 s, der Halt (E5) ist pünktlich. Gegenprobe mit 8 m statt 11 m: B 1,20 ×, aber A 2,74 × (Route 7 Zickzack) und E5 A rot. Die 11-m-Regel verbessert also A und kostet B 0,18 ×. Optionen für Welle 3 (PO): Überhöhung +30 % oder Fenster W = 6 für Fuhrwerk.

## 4 Perf (live, xvfb opengl3, 1600 × 900, mit Schildern, Prefabs, Fern-LOD, Kulissen, 3 Fahrzeugen)

| Ansicht | live Dreiecke / DC | gezählt ohne Culling | Gate |
|---|---|---|---|
| 1 Übersicht 3 km | **145.702 / 111** | 565.902 | ≤ 1,0 M / ≤ 300: **ja** |
| Übersicht 1,8 km / 1,2 km | 734.508 / 599.827 | – | ≤ 1,0 M: ja |
| 2 Dorf 450 m | 574.123 / 107 | 1,56 M | Info |
| 3 Markt 350 m | 514.611 / 62 | 1,50 M | ≤ 2,9 M: ja |
| 4 Fluss 170 m · 5 See 750 m | 823.052 / 71 · 778.858 / 144 | 1,66 M · 1,44 M | Info |
| Laden `_ready` / mit 1. Frame | 1.446–1.640 ms / 1.798–1.987 ms (xvfb) | headless 1.268 ms | ≤ 3 s: **ja** |

Davon Prefab-Bau ≈ 0,4–0,5 s (`baue_modelle`), Schilder 5 ms. Spitzen kommen weiter von den Bäumen (TA P2).

## 5 Bilder (`p4/int/_out/bilder/`, Skript `slice/tests/proto_shots_int.gd`, Zählwerte `int_perf.txt`)

`int_preset_1_uebersicht`, `int_preset_2_dorf`, `int_preset_3_markt`, `int_preset_4_fluss`, `int_preset_5_see` (Schilder an, Sim auf Tick 113, Fuhrwerk 1 beladen unterwegs), `int_fuhrwerk_nah` (Fuhrwerk auf dem Gutsweg), `int_postkutsche_nah` (Kutsche an der Kreuzung Erlenbach), `int_floss_nah` (Floß treibend, x ≈ 1880), `int_hasenwinkel_nah` (Weiler-Schild), `int_muehle_nah` (Plakette Erlenmühle), `int_preset_2_schilder_aus` (Taste N).

## 6 Mängel (Sichtprüfung der Bilder)

| # | Mangel | Bild | Zuständig / Vorschlag |
|---|---|---|---|
| M1 | Fuhrwerk fährt mit 1,5 m Spurversatz auf dem 3,5-m-Feldweg: rechte Räder laufen neben dem Band | `int_fuhrwerk_nah` | Felix W3: Spur = min(1,5; (Fahrbahn − Breite)/2), an Weg-Übergängen überblenden (E2 beachten) |
| M2 | Halt am Wegende: Gespann ragt am Gutshof über das Bandende ins Feld, Weg endet vor dem Hoftor | Lauf 1 von `int_fuhrwerk_nah` (Tick 70) | Stadt: Gutsweg bis ins Tor; Felix: Haltepunkt = Bandende − halbe Länge |
| M3 | Lindenfurt-Schild in der Nahstufe ≈ 170 px über dem Markt, Zeigerpunkt sitzt am Anker (40 m über Grund) in der Wiese, nicht am Markt | `int_preset_3_markt` | Aylin: Zeiger bis zum Bodenpunkt ziehen oder Anker nah auf 15 m |
| M4 | Erlenbach-Schild am rechten Bildrand abgeschnitten („Erlenba…“) | `int_preset_5_see` | Aylin: Schild in den Bildschirm klemmen (Rand 8 px) |
| M5 | Wasserrad der Mühle nicht am Bach sichtbar (steht an der Hauswand) | `int_muehle_nah` | TA/Stadt P4 (Welle 3) |
| M6 | Ackerstreifen wechseln an Kachelgrenzen hart die Richtung (sichtbare Nähte) | `int_preset_3_markt`, `int_muehle_nah` | TA: Streifenrichtung je Schlag statt je Kachel |
| M7 | Flussufer unten links treppig (Raster-Kante) | `int_preset_3_markt` | TA: Uferlinie glätten |
| M8 | Marktplatz und Höfe als einfarbige Flächen ohne Textur (Pflaster fehlt) | `int_preset_3_markt` | Sophie/TA: Pflaster/Hof-Material (Felix' Flächen nehmen ein Material) |
| M9 | Zäune als einzelne kurze Lattenstücke, teils an der Straßenkante, nicht durchgehend | `int_preset_2_dorf`, `int_postkutsche_nah` | Stadt: Zaunzüge statt Einzelstücke |
| M10 | Ladung des Fuhrwerks nicht sichtbar (Kasten leer trotz 10 Getreide) | `int_fuhrwerk_nah` | TA: Ladungs-Teil im Prefab, Sichtbarkeit über Custom (frei: keiner) |
| – | Kein Z-Fighting, keine schwebenden Häuser, keine fehlenden Texturen an Prefabs gefunden; Floß liegt im Wasser, Kutsche/Fuhrwerk auf dem Band, Flächen unter den Häusern | alle | – |

## 7 Geänderte Dateien (gegen main)

`slice/proto/proto_platzhalter.gd`, `slice/proto/prototyp_welt.gd`, `slice/proto/proto_fahrzeuge.gd`, `slice/proto/proto_easing.gd`, `slice/proto/proto_strassenband.gd`, gelöscht `slice/proto/proto_fahrzeug.gdshader` (+ `.uid`), `slice/tests/proto_mass.gd`, `slice/tests/proto_welt_test.gd`, `slice/tests/proto_easing_test.gd`, `slice/tests/proto_strassenband_test.gd`, neu `slice/tests/proto_shots_int.gd` (+ `.uid`; Achtung: `.gitignore` listet die Datei, beim Commit mit `-f` hinzufügen oder Eintrag entfernen), `slice/world/data/proto/regelwerk.json`, `sprints/s8/design-sprint/phase3b/12_regelwerk_v1_1.json`, `sprints/s8/design-sprint/phase4/proto_easing.csv`, `proto_mass.csv`, `integration_w2.md` (neu).
