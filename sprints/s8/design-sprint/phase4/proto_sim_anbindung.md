# Sim-Anbindung der Prototyp-Welt (Felix, Phase 4 Welle 1, Analyse für Welle 2)

Frage: Wie läuft die echte Sim-Kette Farm → Mühle → Dorf (Fuhrwerk statt Lkw) in `prototyp_welt.tscn`, ohne Slice, S7-Welt oder Sim zu verändern? Und was braucht die Easing-Probe (15 Teil B) aus `fleet_soa.gd` / `render_batch.gd`?

## 1 Befund im Code [M]

| Stelle | Befund | Bedeutung für den Prototyp |
|---|---|---|
| `core/sim_world.gd` | RefCounted, kein Node, kein Rendering. API: `add_node(id, pos_mm)`, `graph.add_edge`, `add_line_vehicle`, `step()`, `checksum()` | läuft ohne `main.gd` |
| `core/net_graph.gd add_edge` | Kantenlänge = `ceil(Luftlinie)` der Knotenpositionen | beliebige (auch schräge) Kanten möglich, nicht nur Feld-Treppen |
| `economy.gd` | RefCounted; `attach(sim)`, `add_industry_site(node, id)`, `add_city_site(node, id)`, `start_company_at`, `buy_licence`; Ids müssen in `data/economy_slice.json` stehen | Kette mit den Slice-Ids (`farm_1`, `muehle_1`, Stadt-Id) ohne `main.gd` aufbaubar |
| `fleet_soa.gd` | `route_from_cells` (Feldpfad → Eckknoten), `fill_buffers` (Position linear auf der Kante, Richtung = Kante), `after_step(m)` braucht `m.charge`/`m.on_delivery` | Routenbau und Puffer hängen an `main`; für den Prototyp nur als Vorlage, nicht direkt |
| `render_batch.gd` | nur statische Quader | für Easing ohne Bedeutung |
| `main.gd` | A* nur waagrecht/senkrecht (`DIAGONAL_MODE_NEVER`), 3 MultiMeshes mit `set_buffer_interpolated`, `physics_interpolation_quality` ungesetzt (= FAST) | Ursache „Schuhkarton“: Basis linear zwischen zwei Ticks gemischt → in der 90°-Ecke ≈ 71 % Länge |
| ws_c ds_v2 (Ausschnitt-Quelle) | Kette k1 `farm_2` (lokal 1888/1338 m) → `muehle_2` (1263/963 m) → `rotheim` (Dorf, 1788/−513 m) liegt komplett im Ausschnitt | Geografie passt, aber `muehle_2` liegt im See-Stempel (Mitte 1213/1013, r 250): die Stadt-Rolle setzt die Mühle an den Bach, der Adapter nimmt die Positionen aus `proto_instanzen.json`, nicht aus `world_s7.json` |
| `slice/world/data/world_s7.json` (S7 im Spiel) | anderes Profil als ds_v2 (Höhen-md5 verschieden, andere Städte) | S7-Sim und Prototyp-Geografie decken sich nicht |

## 2 Optionen

| # | Weg | Aufwand Welle 2 | Risiko | Bewertung |
|---|---|---|---|---|
| **B** | **ProtoSim-Adapter** `slice/proto/proto_sim.gd`: eigener `SimWorld` + `Economy` (gleiche Klassen, gleiche JSON), Graph aus den Fahrlinien-Ankern des Straßenbands, Sites an Gutshof/Mühle/Dorf aus `proto_instanzen.json`, 2 Fuhrwerk-Linien, Tick 10 Hz in `_physics_process` der Szene | **0,5 PT** Adapter + 0,25 PT Test (Prüfsumme Easing an/aus) | gering: kein Bestandscode geändert; Ökonomie-Ids an `economy_slice.json` gebunden (Annahme: `farm_1`/`muehle_1`/Stadt-Id wiederverwenden) | **Empfehlung** |
| A | Prototyp als reine Darstellung über `main.tscn` + `beispielnetz.gd` (S7-Welt unsichtbar im Hintergrund, Positionen affin in Prototyp-Meter umgerechnet) | 1,0 PT | hoch: S7-Karte ≠ ds_v2-Ausschnitt, Routen liegen nicht auf den Prototyp-Straßen, Easing müsste gegen falsche Wege arbeiten; `main` lädt UI, Gelände, Städte (Ladezeit, Draw Calls) | nein |
| C | Welt-Adapter in `main.gd` (dritte Welt „proto“ in `world/welt.gd`) | 2,0 PT | hoch: Eingriff in `main.gd`/`welt.gd`, 21 Suiten betroffen, widerspricht „Slice/S7 unberührt“ | nein (frühestens S8, wenn die Prototyp-Welt Spielwelt wird) |
| D | Sim als Overlay in Feldern (Prototyp-Karte auf 25-m-Felder gerastert, A* wie im Spiel) | 1,0 PT | mittel: Treppenrouten statt Straßenband, Fahrlinie ≠ Sim-Kante, genau das Problem aus 15 §B1 | nein |

## 3 Empfehlung B im Detail

1. **Graph:** je Weg die Anker `fl.anker[k]` (Eingabepunkte + eingefügte Kreuzungspunkte, siehe `proto_strassenband.gd`) als Sim-Knoten, Position in mm über `eco.feld_mm` (1000 je Feld, 1 Feld = 25 m), Kanten k → k+1. Gemeinsame Anker zweier Wege (Kreuzung) = ein Knoten. Kantenlänge = Luftlinie (net_graph), also ≈ Bogenlänge der Fahrlinie zwischen den Ankern (Abweichung nur in den Bögen, < 2 %).
2. **Zuordnung Kante → Fahrlinie:** Tabelle `(knoten_a, knoten_b) → (weg, k, vorwärts)`. Bild-Position = `fl.sim_auf_s(k, v_pos / r_len)` (vorwärts) bzw. `1 − …` (rückwärts). Pendel-Umkehr dreht die Route im Kern in place (`_reverse_route`), daher immer über `r_from/r_to` nachschlagen, nie über den Routenindex.
3. **Kette:** Sites `add_industry_site(n_gutshof, "farm_1")`, `add_industry_site(n_muehle, "muehle_1")`, `add_city_site(n_dorf, <Stadt-Id>)`; `start_company_at`, Lizenzen über `buy_licence`; 2 Linien (Farm → Mühle, Mühle → Dorf) mit den Werten von `lkw_e1` aus `vehicles.json` (Fuhrwerk ersetzt Lkw, Regelwerk `fahrzeuge_dm.fuhrwerk_2_pferde.ersetzt = lkw`; Tempo 600 mm/Tick = 0,6 F/Tick = 15 m/Tick); nur das Bild ist ein Fuhrwerk. Ablauf wie `beispielnetz.gd`, nur ohne `main`.
4. **Prüfsumme:** `sim.checksum()` + `eco.checksum()` nach N Ticks mit Easing an/aus gleich (E1). Die Sim liest nichts aus der Darstellung (K27).
5. **Sim-Tempo bleibt (E9):** 15 m/Tick = 150 m/s bei 1×; eine 1-km-Fahrt dauert ≈ 7 s. Das ist so entschieden, das Easing macht es nur glatt.

## 4 Was die Easing-Probe braucht (15 Teil B, Ursache „Schuhkarton“)

| Bedarf | Quelle heute | Lösung im Prototyp |
|---|---|---|
| Fahrlinie mit Bogenlänge, Gier, Krümmung | fehlt (Kante = Gerade) | `proto_strassenband.gd` Fahrlinie: `strecke_punkt/gier/kruemmung/spur_punkt`, Tabelle 1 m, O(1) |
| Sim-Kante ↔ Spline-Abschnitt (K28) | – | `fl.anker_s`, `fl.sim_auf_s(k, anteil)` (längentreu-proportional) |
| monotoner Fahrstrecken-Zähler je Fahrzeug (B4 Schritt 2) | `v_idx`, `v_pos`, `r_len` (SoA) | im Adapter je Tick: Δs aus (Kante, v_pos) gegen Vortick; Routenwechsel = erlaubter Sprung |
| Fenster W (Ringpuffer, laufende Summe) | – | je Fahrzeug PackedFloat32Array W × 1, Werte aus `fahrzeug_easing` (JSON) |
| Kurvenzonen (K30) | – | aus `strecke_kruemmung` der Fahrlinie vorberechnet (Zonentabelle je Weg) |
| Transform je Frame ohne lineare Basis-Mischung | `main` nutzt `set_buffer_interpolated` (FAST) → 71 % Stauchung | eigenes MultiMesh, `physics_interpolation_mode` aus, Transform je Frame aus Position + Gier (orthonormal, E7 prüfbar); `physics_interpolation_quality` HIGH nur für den Fern-Pfad (Member in 4.7.2 vorhanden, geprüft) |
| Haltung (Rollen, Nicken, Wippen, Gangphase) | – | `MultiMesh.use_custom_data = true`, `INSTANCE_CUSTOM` im Shader (Member in 4.7.2 vorhanden) |
| Höhe | `fleet_soa.h_grid`/`h_fn` (Feldraster) | y direkt aus `strecke_punkt` (liegt auf Band und Brückendeck) |
| `render_batch.gd` | nur statische Quader | nicht nötig |

`fleet_soa.gd` bleibt unverändert; der Adapter liest dieselben SoA-Felder (`v_rstart`, `v_idx`, `v_pos`, `r_from`, `r_to`, `r_len`, `v_state`) wie `_fill_range`. Wird das Verfahren in S8 ins Spiel übernommen (Ticket E-01), ersetzt die Fahrlinien-Abbildung dort die lineare Kanten-Interpolation in `_fill_range`.

## 5 Risiken

| Risiko | Wirkung | Gegenmaßnahme |
|---|---|---|
| Stadt-Wege nicht als zusammenhängendes Netz (Endpunkte nicht auf anderen Wegen) | Sim findet keine Route Farm → Mühle → Dorf | Knoten-Fang 4 m bzw. halbe Trasse (Straßenband); Adapter prüft Erreichbarkeit beim Laden und meldet fehlende Verbindung |
| Ökonomie-Ids an Slice-JSON gebunden | Gutshof/Mühle/Dorf heißen intern `farm_1`/`muehle_1`/Slice-Stadt | nur Prototyp, im HUD mit Prototyp-Namen beschriften |
| Ladeknoten liegen neben der Straße | Fuhrwerk fährt nicht bis ans Gebäude | Stichweg im Adapter (Gebäude → nächster Anker), wie `_city_dock` im Spiel |
| Zeitbudget E8 (≤ 0,5 ms bei 10 Fahrzeugen) | – | O(1) je Fahrzeug, 10 Fahrzeuge; Messung in Welle 2 |
