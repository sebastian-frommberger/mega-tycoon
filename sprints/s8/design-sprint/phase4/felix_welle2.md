# Felix, Phase 4 Welle 2: Easing-Probe, ProtoSim-Kette, Fixes, Perf (schlank)

Stand 03.11.2026, Arbeitskopie `p4/w2/felix/` (Merge Welle 1), Godot 4.7.2 (API gegen `doc472`-Dump und `--check-only` geprüft). Grundlagen: VERTRAG.md (Welle 2), 15_regelwerk_v1_1 Teil B, 16_prototyp_plan_v1_1 §2/§5, `proto_sim_anbindung.md`.

## 1 Was gebaut ist

| Datei | Inhalt |
|---|---|
| `slice/proto/proto_sim.gd` (neu) | **ProtoSim-Adapter** (Empfehlung B): eigener `SimWorld` + `Economy` aus dem Bestand (unverändert), Graph aus den Fahrlinien-Ankern (899 Knoten/Kanten, gemeinsame Punkte und Wegenden auf anderen Wegen = 1 Knoten), mm = m × 40 (1 Feld = 25 m = 1000 mm). Kette: Gut Kuppenhof → Industrie `getreidefarm`, Erlenmühle → `muehle`, Erlenbach → `dorf_agrar` (Dorfmitte = Kreuzung nächst Ortsmitte), Lindenfurt → `kleinstadt_a`; Firma mit HQ im Dorf, Lizenzen Farm (gratis) + Mühle (bezahlt) per `buy_licence`. Linien wie im Spiel (Werte `lkw_e1`, Fuhrwerk ersetzt Lkw): Fuhrwerk 1 Getreide Farm → Mühle, Fuhrwerk 2 Mehl Mühle → Dorf, Postkutsche Dorf ↔ Kleinstadt (leer, `leave_empty`). Tick 10 Hz, Fahrkosten wie `main.charge`. Halteknoten = Wegende/Einmündung ≤ 40 m am Gebäude. Rückweg-Fahrlinie wird nach dem Laden nachgereicht (1 je Tick). |
| `slice/proto/proto_easing.gd` (neu) | Easing (nur Darstellung, K27): `Profil` aus `fahrzeug_easing`, `Routenlinie` (Fahrlinie je Linien-Leg aus den Band-Fahrlinien, Bogen an jedem Weg-Übergang, Spur rechts 1,5 m, Gier, Krümmung, Kurvenzone), `Zustand` (Folger + Pose je Fahrzeug). Details §2. |
| `slice/proto/proto_fahrzeuge.gd` + `proto_fahrzeug.gdshader` (neu) | Ein MultiMesh je Kategorie, je Frame gesetzt, `physics_interpolation_mode` OFF, `INSTANCE_CUSTOM` = (Gangphase, Wippen, Rollen, Nicken). Platzhalter Fuhrwerk 9,5 m (Wagen, 4 Räder, 2 Pferde mit Beinen), Postkutsche 12,5 m (4 Pferde). **Hook ProtoPrefabs**: `res://world/proto_prefabs.gd` per Pfad, `fahrzeug(kat).mesh`; ohne Fahrzeug-Shader im Prefab wandert die Haltung in den Transform. |
| `slice/proto/prototyp_welt.gd` | Sim + Fahrzeuge eingebunden (`sim_schritt`: feste 10 Hz × Bildtempo, max. 8 Ticks/Frame), G Easing an/aus (Start: an), **F** Kamera folgt Fuhrwerk 1/2/Kutsche, **T** Bildtempo 1×/¼× (nur Ansicht), V nutzt TA-API `wasser_variante_b`, HUD mit Kette/Ladung/Kasse, Zählung „mit Sichtweite“, Ladezeit je Stufe. |
| `slice/proto/proto_platzhalter.gd` | `flaeche_*` als Bodenflächen (1 Mesh je Typ, Raster 2,5 m, +0,08 m am Gelände, Farbe je Typ), `nebengebaeude` mittlere Variante + Skalierung je Instanz auf b × t, Sichtweiten (Kleinteile 700 m, Bäume 1.800 m, Flächen 2.500 m), **Hook ProtoPrefabs** `vorhanden/mesh_fuer` (Prefab bringt Materialien mit). |
| `slice/proto/proto_strassenband.gd` | Ankerprojektion O(n) statt O(n²) (Wege 590 → 180 ms), Band-Querschnitt deckt Gelände-Wölbung zwischen zwei Querschnitten ab, Treppen bis 55 m Stufe (2:1-Treppen), Feldweg-Radius 25 m (Annahme, E3). |
| `slice/tests/proto_easing_test.gd` (neu) | E1–E8 (Teil A 10 synthetische Routen, Teil B Szene-Kette, Teil C 10 Fahrzeuge) + Variante Kurvenfaktor 0,70 (Info) → `phase4/proto_easing.csv` |
| `slice/tests/proto_sim_test.gd`, `proto_band_hoehe_test.gd`, `proto_perf_gruppen.gd`, `proto_perf_abstand.gd`, `proto_shots_w2.gd` (neu) | Kette, Band vs. Gelände, Perf je Gruppe/Abstand, Bilder `d07_shots/proto_w2/` |
| `slice/tests/proto_mass.gd`, `proto_welt_test.gd` | Flächen/Varianten, ProtoPrefabs-Quelle, Perf-Gate live bzw. gezählt mit Sichtweite, Abstände 1,2/1,8 km; Welt-Test um Sim/F/T/Flächen erweitert |
| `world/data/proto/regelwerk.json` | **nur** `skalen.fahrzeuge_dm.personenwagen.l` 69 → 68 (PO 6,8 m). Doku-JSON und `import_faktoren.json` (`ziel_m` 6,9) bleiben TA. |

**Bestandsdateien in Welle 2: keine geändert** (Slice, S7, Sim, `main.gd`, `start_menu.gd` unberührt).

## 2 Easing-Probe: Verfahren

1. **Fahrlinie statt Kante (K28):** Sim-Kante k ↔ Band-Abschnitt zwischen denselben Ankern, längentreu-proportional; Weg-Übergänge (z. B. Kirchstraße → Hauptstraße) bekommen einen Bogen mit Typ-Radius (≤ 0,45 × Nachbarabschnitt). Gier = Tangente der Spur je Frame, nie lineare Basis-Mischung → **Schuhkarton behoben** (E7: Norm 1,0000; heutiges Bild „aus“ auf denselben Routen: Basisnorm bis 0,000 bei der Wende, 0,71 in 90°-Ecken).
2. **Anfahren/Bremsen (K29):** Folger auf der Fahrstrecke, Rampe v_sim/(W/2 Ticks), Bremsen auf den Halt am Leg-Ende (die Sim hält dort immer ≥ 1 Tick), Aufholen ≤ +10 %, nie vor der Sim. **Abweichung:** kein gleitender Mittelwert; der erreicht den Halt erst W−1 Ticks nach der Sim, E5 verlangt ≤ W/2. Gleiche Rampenlänge, O(1).
3. **Kurvenzone (K30):** Tempofaktor aus Querbeschleunigung (Profilwert) und Gierrate (Spitzenkrümmung ±2 m, Rand 10 %), geglättet; Defizit davor/danach mit ≤ +15 % eingeholt, zeiterhaltende Umparametrisierung p = φ(u). Bildtempo hart begrenzt (E3/E4 haben Vorrang vor Zeiterhalt).
4. **Profilwert E4** je Kategorie = (Kurvenfaktor · v_sim)² / R_Dorfstraße (15 §B5-Beispiel: 272 m/s² Fuhrwerk, 324 m/s² Kutsche), gilt auf allen Wegtypen.
5. **Haltung/Gang:** Rollen ∝ v²κ (≤ 3°/4°), Nicken = Steigung + Bremsnicken (≤ 2°/2,5°), Wippen 0,12/0,18 m mit gedeckelter Frequenz, Gangphase aus der Strecke (Schrittlänge so, dass bei 1,15 v_sim genau 2,5 Hz) → `INSTANCE_CUSTOM`; Rad = 1,2 × Gangphase im Shader.
6. **Wende am Linienende:** die Sim dreht die Route im Stand um; Bild dreht 180° mit ≤ ω_max (≈ 1 s), meist während Laden/Entladen. Einziger zusätzlich erlaubter „Sprung“ (wie Routenwechsel, B4 Schritt 7), in E2/E3 ausgenommen und gezählt.
7. **Easing aus** = heutiges Spiel nachgebildet (Gerade zwischen Sim-Knoten, Basis linear zwischen zwei Ticks).

## 3 Testergebnis

| Suite | Ergebnis |
|---|---|
| proto_easing_test | **13 OK / 4 FAIL** (E5, E6 in A und B, Ursache §4) |
| proto_sim_test (Kette) | 11/11 OK: 6.000 Ticks, 200 Getreide an Mühle, 190 Mehl ans Dorf (1.976 € Ertrag), Kutsche 40 Wenden, deterministisch |
| proto_welt_test | 30/30 OK |
| proto_mass (xvfb, live) | 89/89 OK (Flächen bekannt, nebengebaeude Band 6–18 × 4–10 m, personenwagen 6,8 m, Perf live) |
| proto_band_hoehe_test | 2/2 OK (max. Gelände über Fahrbahn −0,145 m, vorher +0,084 m an 2 Punkten am Bach) |
| proto_strassenband_test / proto_epochen_test | 36/36 / 17/17 OK |
| d07_regression (21 Suiten) | **GRÜN**, 0 FAIL, 1.565 s (Bestand unverändert) |

| # | Prüfung | A: 10 Testrouten | B: Szene-Kette | Variante Kurvenfaktor 0,70 (B) |
|---|---|---|---|---|
| E1 | Prüfsumme an = aus = ohne Bild | **OK** bitgleich | **OK** bitgleich (3.000 Ticks, 20 Lieferungen) | – |
| E2 | kein Positionssprung | **OK** 0,85 × Grenze | **OK** 0,85 × | OK |
| E3 | Gierrate ≤ ω_max | **OK** 0,89 × | **OK** 0,90 × | OK 0,95 × |
| E4 | Querbeschl. ≤ 1,25 × Profilwert | **OK** 0,80 × | **OK** 0,81 × | OK 0,83 × |
| E5 | Halt ≤ 0,1 m, ≤ W/2 | **ROT** max 3,08 × W/2 | **ROT** 1,50 × W/2 | OK 0,92 × |
| E6 | Zeitversatz ≤ W/2 | **ROT** 3,20 × W/2 | **ROT** 1,88 × W/2 | rot 1,20 × (nur Fuhrwerk 2) |
| E7 | keine Stauchung | **OK** 1,0000 | **OK** 1,0000 | OK |
| E8 | ≤ 0,5 ms/Frame, 10 Fz | – | **OK** p95 0,26 ms (Mittel 0,24) | – |

## 4 Befund E5/E6 (Profilwerte widersprechen sich)

Bei 150 m/s und Kurvenfaktor 0,55 auf R 25 m kostet eine 90°-Ecke ≈ 45 m Rückstand (3 Ticks); einholen kann das Bild nur mit +15 % Überhöhung, also auf ≈ 380 m Gerade (6,9 m Gerade je m Bogen). Liegen Ecken dichter (Z-Route 150 m, Mühlweg/Kirchstraße/Hauptstraße), wächst der Versatz über W/2 = 2 Ticks und das Bild kommt bis zu 1,5 × W/2 zu spät am Halt an. Gemessen: mit Kurvenfaktor 0,70 ist E5 in der Szene grün, E6 1,2 × (dann wird ω_max 270°/s auf R 25 m bindend). **Vorschlag an PO/Sophie (entscheidet Wellenende):** (a) E6 in Kurvenzonen ≤ W/2 + halbes Zonendefizit, oder (b) Kurvenfaktor Fuhrwerk/Kutsche 0,70 und Fenster W = 6, oder (c) Überhöhung +30 %. Ohne Entscheidung bleibt die Szene auf den Regelwerkswerten (0,55/0,60); sichtbar ist der Versatz kaum (≤ 0,3 s). Route 7 (Treppe 2:1) bleibt auch mit 0,70 rot: das Band behält dort einen Zickzack (8-m-Regel), Lücke bis zur Treppen-Regel W-04b.

## 5 Fehler aus Welle 1

| Punkt | Ergebnis |
|---|---|
| `flaeche_*` | Bodenflächen, 5 Typen = 5 DC, am Gelände (Test: Abstand 0,08 ± 0,01 m), Messsuite „Typ bekannt (Fläche)“, keine Maß-Soll-Zeile |
| `nebengebaeude` | Soll-Band aus `haustypen.nebengebaeude.varianten_m` (lang 6–18 m, quer 4–10 m); Grundmesh = mittlere Variante 12 × 8, Instanzen auf ihr b × t skaliert (36 × 6×4, 15 × 18×10, 1 × 12×8) |
| `personenwagen` | 6,8 m = 1,19 × real (Kopie `regelwerk.json`); TA zieht Doku-JSON und Import-Faktoren nach |
| `hoehe_at` / Einsinken | TA rechnet exakt auf den Mesh-Dreiecken (Teilung (a,b,c),(b,d,c), Grob 25 m / Fein 5 m). Einsinken 0,5–1,5 m tritt **nicht** auf; nur 2 Punkte +0,08 m am Bachbett (Feinraster zwischen zwei 8-m-Querschnitten) → Querschnitt deckt jetzt die Wölbung bis ± halber Abstand ab |
| **Kurvenradius-Konflikt** (Vorschlag) | Regel: „Die 8-m-Abweichung gilt auf Geraden und Treppen. In Ecken gilt der Typ-Radius; der Bogenscheitel darf R·(√2 − 1) neben der Eckfeld-Mitte liegen (Dorfstraße 10,4 m, Chaussee 20,7 m), der Bogen bleibt im Eckfeld und seinen zwei Nachbarfeldern; Stadt hält dort keine Gebäude.“ Begründung: kleinerer Radius (19 m für 8 m Scheitel) bricht E3/E4 (Gierrate, Querbeschleunigung) bei 150 m/s. |

## 6 Perf

Aufschlüsselung: `phase4/felix_perf_aufschluesselung.md` (an TA). Die 1,62 M sind die gezählte Zahl ohne Culling; **live** (xvfb, RenderingServer): Übersicht 3 km 119 k / 78 DC, ungünstigster Abstand 1,8 km 716 k, 1,2 km 606 k, Dorf 393 k / 98 DC, Markt 270 k, See 725 k / 105 DC → Gate eingehalten. 92 % der gezählten Dreiecke sind TA-Bäume (Baum-LOD empfohlen). Ladezeit `_ready` 1,3–2,2 s headless (Gelände TA ≈ 1,2–1,5 s, Wege 0,18 s, Sim + Fahrzeuge 0,1 s); Wand inkl. erstem Frame unter xvfb 1,9–4,3 s, stark schwankend bei parallel laufenden Agenten (Shader-Übersetzung llvmpipe), kein Zielrechner-Wert.

## 7 Annahmen, offene Punkte, Regression

- Annahmen: Profilwert je Kategorie über R_Dorfstraße; Feldweg-Radius 25 m; Postkutsche ohne Personen-Sim (fährt leer, `leave_empty`); 10 Getreide Startbestand (`seed_stock`), damit sofort gefahren wird; Ökonomie-Ids der Slice (`getreidefarm`, `muehle`, `dorf_agrar`, `kleinstadt_a`); Wende als erlaubter Sprung.
- Kein Abstandshalten (schlank): an der Mühle stehen Fuhrwerk 1 (Entladen) und Fuhrwerk 2 (Laden) übereinander.
- ProtoPrefabs liegt noch nicht im Merge: Hooks in Platzhalter, Fahrzeugen und Messsuite sind per Pfad gebaut und greifen ohne Codeänderung, sobald `res://world/proto_prefabs.gd` da ist.
- `headless` kennt keine MultiMesh-Transforms (Dummy-RenderingServer): gezählt-mit-Sichtweite zählt MultiMeshes dann konservativ als sichtbar; Gate-Messung live unter xvfb.
- Regression: `tests/d07_regression.sh` (Spikes aus der Arbeitskopie) GRÜN, 0 FAIL, 1.565 s; Log `p4/w2/felix_regression_w2.log`, Zusammenfassung `slice/tests/d07_regression_summary.md` (generiert).
