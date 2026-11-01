# W-01 Maßstab + Schalter `--welt=s7` (Felix, S7 Block A)

## Architektur
- **Zwei Welten, ein main.gd.** `slice` bleibt Default und bitgleich. `s7` ist opt-in. Die Weltwahl und der Maßstab liegen in `world/welt.gd` (statisch, ohne Zustand). Die Hooks der S7-Welt liegen in `world/s7_world.gd` und werden nur bei `welt == "s7"` instanziiert (`main.world_s7`, sonst `null`).
- **Maßstab:** Die Szeneneinheit bleibt auf beiden Karten **1 Feld = 1,0**. `m_pro_feld` (Slice 10, S7 25) gilt nur für Texte und Kamerawerte. Die Sim bleibt in Feldern (`feld_mm` 1000, Tempo in mm/Tick je Feld unverändert). Umrechnung: `Welt.scene_to_meter` / `meter_to_scene` (12-m-Haus = 0,48 Szeneneinheiten). Sophies Spike-Meter teilt man durch 25.
- **Kamera-Klemme S7:** Abstand = zoom × |(0,20,16)| = zoom × 25,61 Felder. 40 m–5,6 km ergibt zoom 0,0625–8,746. Geklemmt wird in `_apply_zoom` (Hook) und im Mausrad (`zoom_min`/`zoom_max`). Damit greift die Klemme auch bei `focus()`. near/far hängen am Abstand (near 0,4 %, far 8 × Abstand + 15 km, wie SP-03). Neigung (51°) und FOV bleiben in Block A wie im Slice. Die Neigungskurve 36°→62° kommt mit dem Terrain.
- **Karte S7 Block A:** flache 512²-Ebene (`main._setup_ground`, 12,8 km), gleiche Daten (`data/slice_map.json`). `s7_world.map_path()` lädt automatisch `world/data/world_s7.json`, sobald W-06 sie schreibt. `hoehe_at()`, `build_terrain()` und `HEIGHTMAP` sind die Andockstellen für Block B.
- **km-Texte nur in der S7-Welt.** Begründung: Akzeptanz „Slice bitgleich“ gilt auch für Texte. Tests und play.sh lesen Texte wie „N Felder“. Der Slice-Maßstab (10 m) ist ohnehin nur ein Kartenhinweis, und der Slice wird eingefroren. `main.dist_str(felder)` liefert im Slice exakt `"%d Felder"`, in S7 `"450 m"` / `"3,15 km"` / `"12,8 km"`. Umgestellt sind: Luftlinie im Lizenz-Tooltip, Brücke max., Bau-/Abriss-Toast, Bau-Cursor, Linien-Toast, Linienliste.
- **Nicht umgestellt (bewusst, Folgepunkte):** `hq_placement.gd` „Radius %d Felder“ (Miras Datei, B-xx parallel, kann `main.dist_str` nutzen), Preis „/Feld“ im Werkzeug-Tooltip (Preiseinheit, keine Distanz), `ui/styleguide.gd` (Beispieltext). Label-LOD-Schwellen (zoom > 9 = fern) erreicht S7 nie, weil max. 8,75. Die Schwellen in Metern sind ein Thema für W-05 (Icons ab 2 km).
- **`diagnostics.FELD_MM`** 10000 → 1000 (= `raum.feld_mm`). `strecke_felder` war im Slice ×10 zu klein. Im Slice nutzt das niemand außer Diagnose-Texten, die Sim bleibt unberührt. Die Spike-Kopie `spikes/sim-core` behält 10000, weil ihr eigener Test 400000 mm = 40 Felder erwartet.

## Dateien
- neu `slice/world/welt.gd`: Weltwahl (`pick`), `CFG` je Welt, Zoom↔Meter, `dist_text`/`meter_text`.
- neu `slice/world/s7_world.gd`: Hooks `map_path`, `setup_camera`, `apply_zoom`, `camera_distance_m`, `hoehe_at`, `build_terrain`.
- neu `slice/tests/s7_boot.gd`: 31 Prüfungen (Default) bzw. 26 (`-- --welt=s7`). Eingetragen in `tests/d07_regression.sh` (Abschnitt 2e, zwei Läufe).
- `slice/main.gd`: rund 25 Zeilen Hooks (2 preload, 6 Variablen, Weltwahl in `_load_data`, Kartenpfad, Kamera-/Zoom-Hook, Terrain-Hook, `dist_str` + 8 Textstellen, 2 × Mausrad-Klemme über Variablen).
- `slice/project.godot`: Abschnitt `[mega_tycoon] welt="slice"`.
- `slice/core/diagnostics.gd`: `FELD_MM`.

## So schaltet Basti um
1. **Kommandozeile:** `godot --path slice -- --welt=s7` (Export-Exe: `MegaTycoon.exe -- --welt=s7`). Bench zusätzlich: `-- --welt=s7 --bench`.
2. **Editor (F5):** Projekt → Projekteinstellungen → oben rechts „Erweiterte Einstellungen“ an → Abschnitt **Mega Tycoon → Welt** auf `s7` stellen. Zurück auf `slice` vor dem Commit (s7_boot prüft, dass committet `slice` steht). Alternativ ohne Änderung an project.godot: Projekteinstellungen → Editor → Run → *Main Run Args* = `-- --welt=s7`.
3. **Tests/Code:** `preload("res://main.gd").world_override = "s7"` vor `instantiate()`.
Priorität: world_override > Kommandozeile > ProjectSettings > Default `slice`.

## Nachweis (Sandbox, 01.11.)
- Slice ohne Schalter, Vergleich unveränderte Kopie gegen Arbeitskopie: md5 d08_bankrott-CSV (100 Seeds × 3 Städte) identisch `43caf9dd…`. slice_test soa/alt (72/72) und parity_test (8/8) sind ohne Zeitzeilen md5-gleich.
- `bash tests/d07_regression.sh <godot> /tmp/claude-0/gd/sprint7/a/felix/spikes`: **GRÜN, 15/15** (13 bisher + s7_boot default 31/31 + s7_boot `--welt=s7` 26/26), Abnahme-Parität 12/12, d08_bankrott 10/10, d08_maus 27/27, 1396 s.
