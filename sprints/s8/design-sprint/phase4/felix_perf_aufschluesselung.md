# Perf-Aufschlüsselung Prototyp-Welt (Felix → TA, Welle 2, früh)

Stand 03.11.2026, Arbeitskopie `p4/w2/felix/` = Merge Welle 1 (TA-Gelände, Stadt-Daten, 1.049 Instanzen, 15 Wege). Godot 4.7.2.
Werkzeuge: `slice/tests/proto_perf_gruppen.gd` (je Node-Gruppe, gezählt + live-Differenz), `slice/tests/proto_perf_abstand.gd` (live über Kamera-Abstand). Live = xvfb, opengl3, 1600×900, RenderingServer `TOTAL_PRIMITIVES/DRAW_CALLS_IN_FRAME` (inkl. Schattenpass).

## 1 Kernbefund

Die **1,62 M sind die gezählte Zahl** (Mesh-Daten aller sichtbaren Knoten, **ohne** Frustum- und Sichtweiten-Culling), keine Live-Zahl. Live liegt die Szene in jedem Abstand unter dem Gate: Maximum **≈ 0,62 M / 136 DC** bei 1.200–1.800 m Abstand. Trotzdem gilt: **92 % aller Dreiecke sind Bäume** (TA), live im ungünstigsten Abstand 78 %.

## 2 Gezählt je Gruppe (Preset 1, ohne Culling = obere Schranke)

| Gruppe | Dreiecke | Anteil | DC | Instanzen | Sichtweite |
|---|---:|---:|---:|---:|---:|
| ProtoTerrain/Baeume (70 MultiMeshes, 500-m-Chunks × laub/nadel) | 1.487.668 | 91,9 % | 70 | 11.500 (≈ 129 Dreiecke/Baum) | 1.800 m |
| ProtoTerrain/Gelaende (4 × 4 Chunks) | 85.856 | 5,3 % | 16 | – | – |
| ProtoTerrain/Wasser | 19.090 | 1,2 % | 5 | – | – |
| Modelle (Felix-Platzhalter, 34 Typen, MultiMesh je Typ) | 17.496 | 1,1 % | 34 | 1.049 | – (Welle 1) |
| davon zaun_latte / obstbaum / laubbaum / eiche | 4.476 / 2.928 / 2.640 / 2.568 | | | 373 / 122 / 110 / 107 | |
| Wege (15 Bänder, 12 Knoten, 1 Brücke) | ≈ 7.300 | 0,5 % | 28 | – | – |
| ProtoTerrain/Schuerze | 1.222 | 0,1 % | 1 | – | – |
| **Summe** | **1.618.628** | | **154** | | |

## 3 Live über Kamera-Abstand (Kernmitte, Neigung wie Spiel)

| Abstand | live Dreiecke | DC | davon Bäume |
|---:|---:|---:|---:|
| 3.000 m (Preset 1) | 131.462 | 86 | 0 (Sichtweite 1.800 m greift) |
| 2.500 m | 145.312 | 106 | 0 |
| 2.000 m | 317.864 | 121 | 179.542 |
| **1.800 m** | **615.844** | 129 | **477.522** |
| 1.500 m | 481.172 | 131 | 342.850 |
| **1.200 m** | **606.044** | 136 | **473.500** |
| 900 m | 575.348 | 122 | 455.370 |
| 600 m | 489.998 | 93 | 378.868 |
| 350 m (≈ Markt) | 299.856 | 66 | 186.436 |

Live-Differenz je Gruppe (ausgeblendet): Preset 1: Terrain 106 k / 22 DC, Modelle 17 k / 34 DC, Wege 7 k / 28 DC. Preset 3 Markt: Bäume 218 k, Terrain gesamt 233 k / 17 DC, Modelle 26 k / 37 DC, Wege 3 k / 4 DC.

## 4 Empfehlung an TA (Bäume, Gelände)

1. **Baum-LOD statt einer Sichtweite:** 129 Dreiecke/Baum × 11.500. Ab ≈ 600 m ein Kronen-Impostor/Kreuzquad (2–4 Dreiecke) oder Kenney-Baum mit Kronen-Decimate (≈ 30 Dreiecke) als zweites MultiMesh je Chunk mit `visibility_range_begin`/`_end` (Hysterese 50 m). Wirkung im ungünstigsten Abstand: 0,48 M → ≈ 0,1 M.
2. **Sichtweite allein hilft nicht gegen das Gezählt-Gate**, weil die Zählung ohne Culling rechnet. Ich zähle ab Welle 2 in der Messsuite zusätzlich „gezählt mit Sichtweite“ (Knoten, deren AABB weiter als `visibility_range_end` von der Kamera liegt, fallen raus) und live; Gate-Zeile = live, wo ein Renderziel da ist, sonst gezählt mit Sichtweite.
3. Waldboden-Dichte 4/Feld (Klasse 6) ist der Hauptposten; Waldrand 2,5. Innen 2/Feld + Kronentupfen im Bodenmaterial würde ≈ 40 % sparen.
4. Gelände 86 k ist unkritisch; Chunks 4 × 4 passen. Kein Handlungsbedarf.

## 5 Was Felix in seinem Code setzt (Welle 2)

- Kleinteile (zaun_latte, fass, heuhaufen, holzstapel, passant, amboss, netzgestell, brunnen): `visibility_range_end` 700 m.
- Platzhalter-Bäume der Stadt (obstbaum, laubbaum, eiche): 1.800 m wie TA.
- Flächen (flaeche_*): ein Mesh je Typ, am Gelände anliegend, 1 DC je Typ, Sichtweite 2.500 m.
- Fahrzeuge (Easing): 1 MultiMesh je Kategorie, 2 DC.

## 6 Nachtrag nach Felix-Änderungen (Welle 2, live, xvfb, `proto_mass.gd`)

| Ansicht | live Dreiecke | DC |
|---|---:|---:|
| Übersicht 3 km | 118.584 | 78 |
| Übersicht 1,8 km (ungünstigst) | 715.710 | – |
| Übersicht 1,2 km | 605.652 | – |
| Dorf | 393.190 | 98 |
| Markt | 269.542 | 60 |
| Fluss | 189.702 | 69 |
| See | 725.282 | 105 |

Gate (≤ 1,0 M / ≤ 300 DC) live überall eingehalten; Spitzen kommen von den Bäumen (TA). Neu in meinem Code: Flächen 5 DC, Fahrzeuge 2 DC, Kleinteile ab 700 m aus. Die Messsuite nimmt als Gate-Zahl live (xvfb) bzw. headless „gezählt mit Sichtweite“ (headless zählt MultiMeshes konservativ als sichtbar, weil der Dummy-Renderer keine Instanz-Transforms hält).
