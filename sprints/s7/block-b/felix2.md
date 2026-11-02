# Felix 2 (Rendering), Sprint 7, Block B: Draw Calls mit 5.000 Lkw

Arbeitskopie: `/tmp/claude-0/gd/sprint7/b/felix2/slice` (Vorher-Stand zum Vergleich: `.../felix2/vorher` = Repo-Slice).

## 1. Befund korrigiert: die Fahrzeuge waren nicht die Ursache
- Lkw/Züge/Ladung werden seit S5/S6 schon über 3 MultiMeshInstance3D gezeichnet (`main._vehicle_mm`, Puffer aus `fleet_soa`). Messung mit Ausblenden (Übersicht, Bench 5.000 Lkw):
  - alles: 4.066 DC
  - ohne Straßenfelder: 700 DC (−3.366)
  - zusätzlich ohne Fahrzeug-MultiMeshes: 698 DC (Fahrzeuge = **2 DC**)
  - zusätzlich ohne die 100 Lager: 406 DC (Lager ≈ 292 DC: 2 Quader je Lager + Schatten)
- Ursache: Der Bench (`bench.gd`, auch von perf_s7 genutzt) legt für 5.000 Lkw 50 Korridore an, also **3.366 Straßenfelder und 100 Lager**. `build_track` erzeugt je Feld einen eigenen MeshInstance3D (mit eigener BoxMesh), jedes Lager 2 MeshInstance3D. „Objekte ≈ Draw Calls“ stimmt, es sind aber Straßenfelder, keine Lkw.
- Folge: Eine reine Fahrzeug-Umstellung hätte 0 DC gespart. Ich habe das Ziel des PO-Entscheids (DC in der Übersicht) über die Bündelung der statischen Quader erreicht. **Abweichung vom Auftragstext, bitte bestätigen.**

## 2. Umsetzung (rein Darstellung)
- **Neu `render_batch.gd`:** gebündelte Quader, eine MultiMesh je (Material, Schatten, Kachel 64×64 Felder). Einheitswürfel, Größe in der Instanz-Basis. Geteilte Materialien. `add_box(id, pos, size, mat, shadow)`, `remove(id)` (Tausch mit der letzten Instanz), `mat_for(color)`. Kacheln erhalten das Culling in der Nahsicht.
- **main.gd (klein, lokal):**
  - `build_track`: `render_batch.add_box(["road"|"rail", c], …)` statt MeshInstance3D, gleiche Maße/Materialien/Schatten aus. `roads[c]`/`rails[c]` = `true` statt Node (nur `has()`/`size()` werden genutzt; `demolish` ruft `render_batch.remove`).
  - `build_warehouse`: `w.box_batch = render_batch`.
  - Höhen-Hook (siehe 3).
  - Diff ~66 Zeilen inkl. Kommentare.
- **building.gd:** `box_batch` (gesetzt = Lager-Quader gehen in den Batch, Schatten an wie vorher). Industrien/Städte unverändert.
- **fleet_soa.gd:** nur der Höhen-Hook in `_fill_range`. RENDER_SPLIT unverändert kompatibel (gleiche Puffer, gleiche Portionen).
- Kein Fahrzeug-Picking im Slice vorhanden (gesucht). Klicks auf Straßen/Lager laufen über Felder (`cell_to_building`, `roads.has`) und sind unberührt.
- Sim-Kerne soa/alt, Netz, A*, Parität: unberührt.

## 3. Hook für Felix (Fable): Fahrzeughöhe
- `main.set_vehicle_heights(grid: PackedFloat32Array, w: int, fn := Callable())`.
- `grid[z * w + x]` = Höhe je Feld (Szeneneinheit wie position.y). Leer = 0. Wirkt in beiden Kernen (soa über `fleet.h_grid/h_w/h_fn`, alt in `main._render_vehicles`), auch wenn vor dem Kern gesetzt.
- `fn(x, z) -> float` nur als Rückfall ohne Gitter (wird je Fahrzeug und Tick aufgerufen, langsam).
- Mit Höhe 0 sind die Puffer bitgleich zu vorher.
- **Hinweis für Fable:** Straßen/Lager haben noch keine Terrainhöhe. Für Straßenfelder ist `lift` in `build_track` die Stelle (fließt in `add_box`-pos).

## 4. Messung perf_s7 (Slice, Dreiecke / Draw Calls / Objekte)

| Ansicht | 5.000 Lkw vorher | 5.000 Lkw nachher |
|---|---|---|
| Übersicht | 1,39 M / 4.068 / 4.833 | 1,39 M / **482** / 1.258 |
| Stadt nah | 1,35 M / 1.345 / 2.110 | 1,35 M / 338 / 1.114 |
| Stadt Straße | 0,69 M / 270 / 1.035 | 0,69 M / 264 / 1.040 |
| Mine | 1,34 M / 665 / 1.430 | 1,35 M / 285 / 1.061 |
| Farm | 1,35 M / 1.595 / 2.360 | 1,36 M / 363 / 1.139 |
| Rand max. Zoom | 1,38 M / 3.946 / 4.711 | 1,38 M / 428 / 1.204 |

- Ziel Übersicht ≤ 300 + Grundlast (355 ohne Lkw) = 655: **482**, erfüllt (Fuhrpark-Anteil 127 DC, davon 2 Fahrzeuge, Rest Lager-Labels/Kacheln).
- 0 Lkw: Draw Calls und Dreiecke unverändert. Objekte +44 gegenüber Daniels Baseline (787 → 831): das gibt es **schon im Vorher-Stand** (Repo-Slice gemessen, gleiche 831), also nicht durch diese Änderung. Liegt im Gate.
- Dreiecke +0,5 % in Stadt nah/Farm (Kachel-MultiMesh culled gröber als Einzelfelder). Liegt im Gate.
- Gegen die alte Baseline lief perf_s7 grün. **Neue Baseline** `tests/perf_s7_baseline_slice.csv` = Nachher-Werte, Gate weiter +10 %.

## 5. Optik
- Bilder unter `/tmp/claude-0/gd/sprint7/b/felix2/shots/` (`nah|mittel|uebersicht_{vorher,nachher}.png`, Bench 5.000 Lkw, xvfb + opengl3).
- Pixelvergleich:
  - nah und mittel: max. Abweichung 1/255, kein Pixel > 8.
  - Übersicht: 1.555 Pixel abweichend, nur im animierten Zielpfeil/HQ-Marker (zeitabhängig, sin(t)). Straßen und Lager sind identisch.

## 6. Für Mira / Merge
- `build_track` und `demolish` geändert (je ein Block). Baut die Bau-Vorschau neue Straßen-Nodes oder liest `roads[c]` als Node, bitte auf `render_batch` bzw. `roads.has(c)` umstellen.
- md5: main.gd `aaad961d8be90db79640eada98584132`, building.gd `d9d7011c0885d13cd5d484fe1a70a0c4`, fleet_soa.gd `fe828da2d6b887351a07ddc094f6016a`, render_batch.gd `d8ef321b5dede3eed568a8f2a1d9168d`, perf_s7_baseline_slice.csv `c4d4a007111f294189bed5507aede6b4`.

## 7. Offen
- `--welt=s7` nicht gemessen (Fables Welt im Bau). Im Slice sind Stadtstraßen/Deko schon MultiMesh: nach der Umstellung bleiben nur 5 MeshInstance3D direkt unter main. Spielerstraßen gehen in der S7-Welt über denselben `build_track`, das wirkt also dort mit.
- Industrie-Props (Kenney) sind weiter Einzel-Nodes. Ohne Lkw liegt die Last im Budget-Rahmen der Grundlast.

## Regression
`bash tests/d07_regression.sh <godot> /home/claude/mega-tycoon/spikes` aus slice/ (648 s): **15/16 Suiten OK, 1 FAIL, Gesamt ROT.**
- OK: run_tests (slice_test soa/alt je 72/72, parity 8/8, s11 16/16), d07_abnahme ui/kredit/parity/lager/hq, d08_bankrott, d08_lizenzfaktor, s7_mira, d08_maus, s7_boot (beide), **perf_s7 mit neuer Baseline**, Spikes sim-core und f04-signal.
- FAIL: Statische Prüfung B-2 meldet `world/art/kit_test.gd:28`. Das ist ein **Fehlalarm aus einer fremden Datei** (world/art, steht auch so im Repo-Slice): Die Zeile enthält `append_from_file` und den Kommentar „# B-2: res://-Pfad, kein globalize_path“. Die Regex in d07_regression.sh prüft nur auf das Wort, deshalb schlägt sie an. Ich habe die Datei nicht angefasst, weil sie nicht von mir ist.
- **Fix-Vorschlag (Besitzer world/art oder Daniel):** das Wort aus dem Kommentar nehmen oder die Prüfung Kommentare ignorieren lassen.
- Mit meinen Dateien hat der FAIL nichts zu tun.
