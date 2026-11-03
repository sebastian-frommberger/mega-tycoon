# Felix, Phase 4 Welle 1: Szene, Straßenband, Epochen-Loader, Messsuite (schlank)

Stand 03.11.2026, Arbeitskopie `p4/felix/`, Godot 4.7.2 (API gegen `doc472`-Dump und `--check-only` geprüft). Grundlagen: VERTRAG.md, 16_prototyp_plan_v1_1 (§3 Welle 1, §5), 15_regelwerk_v1_1 (A, B), 12_regelwerk_v1_1.json.

## 1 Was gebaut ist

| Datei | Inhalt |
|---|---|
| `slice/proto/prototyp_welt.tscn/.gd` | Eigene Szene (alles im Code, 1 Einheit = 1 m, lokale Koordinaten laut Vertrag). Gelände über `res://world/proto_terrain.gd` (TA), solange es fehlt `proto_terrain_stub.gd`; bei Ladefehler der TA-Datei automatisch Stub. Daten je Datei aus `world/data/proto/`, sonst `proto/testdaten/`. Kamera wie im Spiel (FOV 50, Neigung 36°→62° nach Abstand, Kurve aus `s7_world.pitch_for`, ≥ 8 m über Gelände), Zoom 40 m–3 km, WASD/Pfeile, Q/E, Mausrad, Ziehen. Presets 1 Übersicht · 2 Dorf · 3 Markt · 4 Fluss (seitlich auf die Brücke) · 5 See, Ziele aus `proto_orte.json`, Brücke, `proto_see.json`. Schalter V Wasser A/B (Hook `set_wasser_modus` + Signal), G Easing an/aus (Hook + Signal für Welle 2), M Modelle aus (Zeichentest), H HUD, Esc Menü. HUD mit gezählten und Live-Dreiecken/Draw Calls. |
| `slice/proto/proto_strassenband.gd` + `proto_strasse.gdshader` | Band je Weg (ein Mesh), Glättung: Treppen-Mittelpunkte → Douglas-Peucker (9 m) → Kreisbögen mit Kurvenradius des Typs (Dorfstraße 25, Chaussee 50, aus JSON), Alternative Catmull-Rom. Querschnitt Chaussee 6 m Fahrbahn / 11 m Trasse mit Bankett und Graben, Dorfstraße 6, Gasse 5, Feldweg 3,5, Schürze gegen Geländekanten. Material ohne Kacheln: UV.x Querlage, UV.y Bogenlänge, Körnung triplanar prozedural, Kiesspur in der Mitte, Randsteine. Kreuzungsstück (Knotenfläche) an jedem Wegende, das auf einem anderen Weg liegt (fester Punkt im durchgehenden Weg). Steinbogenbrücke automatisch, wo die Fahrlinie ≥ 10 m über Rinne (Bit 1) läuft, oder bei `typ: "bruecke"`: Deck, Brüstungen, Pfeiler, Segmentbögen aus Boxen, Rampen ≤ 8 %. **Fahrlinie** je Weg (Schnittstelle im Dateikopf): `strecke_punkt(s)`, `strecke_richtung`, `strecke_gier`, `strecke_kruemmung`, `spur_punkt(s, versatz)`, `naechstes_s`, `anker/anker_s`, `sim_auf_s(kante, anteil)`, `r_min`; Tabelle je 1 m, O(1). |
| `slice/proto/proto_platzhalter.gd` | Boxen in Zielmaßen (Häuser mit Satteldach, Kirchen mit Turm, Bäume Stamm + Krone), Maßquelle je Typ: haustypen → skalen → Import-Faktoren → M14-Zusatz; MultiMesh je Typ, Farbe nach Kategorie. |
| `slice/proto/proto_terrain_stub.gd` | Vertrags-API ohne `class_name` (kein Konflikt beim Merge), flach 40 m, nur Rinnenknoten 34,5 m, Wasser 36,4 m; `hoehe_at` linear auf den Mesh-Dreiecken. |
| `slice/proto/proto_epochen.gd` | Epochen-Datenhülle: Epoche aus `epochen.stufen` (von ≤ Jahr ≤ bis), Hebel = alle `startjahr_hebel`-Stufen ≤ Jahr aufsteigend überlagert. Kein Jahr im Code. Startjahr per `-- --startjahr=JJJJ`. |
| `slice/world/data/proto/regelwerk.json`, `import_faktoren.json` | Kopien von `phase3b/12_regelwerk_v1_1.json` (md5 bbf1ea8b…) und `phase2/10_import_faktoren.json`. Eigentümer bleibt die Doku. Liegen unter `world/data/*`, damit ein Export sie enthält. |
| `slice/proto/testdaten/*` + `tools_proto/felix_testdaten.py` | Testdaten im Vertragsformat (Orte, 474 Instanzen, 7 Wege, Fluss-Maske aus ws_c ds_v2, See/Bach aus der Vorgabe), deterministisch (Seed 7). Gelten nur, bis TA/Stadt liefern. |
| `slice/tests/proto_epochen_test.gd` | P7 (17 Prüfungen) |
| `slice/tests/proto_strassenband_test.gd` | Band/Fahrlinie/Brücke/Kreuzung mit synthetischen Daten (36) |
| `slice/tests/proto_welt_test.gd` | Szene, Daten, Kamera, Presets, Schalter (22) |
| `slice/tests/proto_mass.gd` | Messsuite → `phase4/proto_mass.csv` (Objekt;Soll;Ist;Abw. %;OK;Quelle) |
| `slice/tests/proto_shots.gd` | Bilder der 5 Presets (xvfb) |
| `phase4/proto_sim_anbindung.md` | Analyse Sim-Anbindung + Easing-Bedarf |

**Geänderte Bestandsdatei:** nur `slice/start_menu.gd` (+6 Zeilen): Konstante `PROTO`, Argument `--proto` springt in die Szene, Taste P, Hinweis „· P Prototyp Welt“ an der Weltzeile. `main.gd`, Slice, S7-Welt, Sim, Tests unverändert.

## 2 Kennzahlen (Stub-Gelände, Testdaten)

| Messung | Wert | Gate |
|---|---|---|
| Ladezeit `_ready` | 150 ms headless (Wand inkl. 1. Frame 0,3 s headless, 0,9 s xvfb) | ≤ 3 s |
| Übersicht 3 km (live, xvfb opengl3) | 75 k Dreiecke / 48 DC (davon Stub-Boden 46 k) | ≤ 1,0 M / 300 |
| Markt 350 m | 89 k Dreiecke / 38 DC | ≤ 2,9 M |
| Modelle aus | 64 k / 17 DC | – |
| Straßenband | 7 Wege ≈ 6,4 km, ≈ 18 k Dreiecke, 4 Knoten (3 Kreuzungen, 1 Stoß), 2 Brücken à 7 Bögen | – |
| Messsuite | 77 Zeilen, 76 OK, **1 rot: `personenwagen` 6,9 m = 1,21 × real 5,7 m** | ±25 %, Fz 0,9–1,2× |

## 3 Testergebnis

| Suite | Ergebnis |
|---|---|
| proto_epochen_test | 17/17 OK |
| proto_strassenband_test | 36/36 OK |
| proto_welt_test | 22/22 OK |
| proto_mass | 76/77 OK, 1 Befund im Regelwerk (s. 4) |
| s7_start_test (wegen start_menu.gd) | 31/31 OK |
| d07_regression (21 Suiten) | GRÜN, 0 FAIL (Abschnitt 6) |

## 4 Annahmen und Abweichungen

| # | Punkt | Entscheidung Felix |
|---|---|---|
| 1 | Stub „flach“ | flach 40 m, aber Rinnenknoten abgesenkt, sonst ist die Brücke nicht prüfbar. TA-Gelände ersetzt das. |
| 2 | Ortsstraßen-Abweichung 8 m | Douglas-Peucker mit 9 m: die halbe Feldstufe einer Sim-Treppe liegt 8,84 m neben der Diagonale. |
| 3 | **Zielkonflikt** R 25 m ↔ 8-m-Regel | Eine 90°-Ecke mit R 25 m hat den Scheitel 10,4 m neben der Feldmitte (bleibt im Eckfeld). Ich halte den Radius (Fahrdynamik, E4). Klärung AD/SLD. |
| 4 | Radius Gasse/Feldweg | nicht im Regelwerk: Gasse 10 m, Feldweg 15 m angenommen. |
| 5 | Brücke | Deck = max(Ufer, Pegel + 4,5 m lichte Höhe + 1 m); Rampen ≥ 1 Feld, steilste Stelle ≤ 8 % (Annahme); Deckbreite Fahrbahn + 2,6 m. Bach (< 10 m Wasserlauf) = Durchlass. |
| 6 | Kirche/Kapelle | Schiff-Traufe ≈ 0,3 × Turm, Turm am Ende der Längsachse (Platzhalter). |
| 7 | Steg/Fischerhütte | Maße aus 16 §5 M14, Höhen angenommen. |
| 8 | Regelwerk-Befund | `fahrzeuge_dm.personenwagen` l 69 dm vs real_l 57 dm = 1,21× (> 1,2×). Gleicher Wert in `10_import_faktoren.json` (6,9 m). Suite zeigt es rot, nicht von mir „bewusst“ gesetzt: Entscheidung AD (Wagen auf 6,8 m oder Regel). |
| 9 | Meta-Format TA | `proto_meta.json` noch unbekannt; Szene liest defensiv `ursprung_m`, `felder`, `m_pro_feld`, `fluss_pegel_m`, sonst Vorgabe (−1000/−1000, 160 × 144, 25 m, 36,4 m). |
| 10 | Bitte an TA | `hoehe_at` sollte die Mesh-Dreiecke abbilden (nicht bilinear), sonst taucht das Band an steilen Kanten 0,5–1,5 m ein (am Stub gesehen und behoben). Optional `set_wasser_modus("A"/"B")` und `dreiecke()`. |

## 5 Offene Punkte für Welle 2

- Sim-Anbindung nach Empfehlung B (`proto_sim_anbindung.md`): ProtoSim-Adapter mit eigenem `SimWorld` + `Economy`, Graph aus `fl.anker`, 0,5 PT + 0,25 PT Test.
- Easing-Probe hängt an `easing_geaendert` und an der Fahrlinie; eigenes MultiMesh je Frame (keine Engine-Interpolation), Haltung über `INSTANCE_CUSTOM`.
- Kreuzung ist eine runde Knotenfläche; Fahrlinien enden am Knoten, Übergänge zwischen Wegen baut der Adapter über gemeinsame Anker.
- Testdaten löschen bzw. ignorieren, sobald `world/data/proto/` die Stadt-/TA-Dateien hat (die Szene nimmt sie dann automatisch).
- `prototyp_welt.tscn` hat noch keine `uid` (nicht erfunden); Godot vergibt sie beim ersten Speichern im Editor.

## 6 Regression
`tests/d07_regression.sh` (Spikes aus der Arbeitskopie) nach allen Änderungen: **GRÜN**, 24 Zeilen OK, 0 FAIL, 1361 s (u. a. slice_test 74/74 soa+alt, parity 8/8, d08_bankrott 10/10, s7_start 31/31, perf_s7 Gate +10 % OK, statische Prüfungen OK). Die Regressionssuiten selbst sind unverändert.
