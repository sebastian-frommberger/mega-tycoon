# F-12 Export vorbereiten (Felix, Sprint 4 Tag 6–9)

Projekt: `day6-9/felix/slice/` (Godot 4.7.2, Renderer `gl_compatibility`). Zum Übertragen auf Bastis PC: `day6-9/felix/slice_f14.zip` (ohne `.godot/`-Cache, wird beim ersten Öffnen neu importiert).

## Presets in `slice/export_presets.cfg`
| Preset | Ergebnis | Besonderheit |
|---|---|---|
| `Windows Desktop` | `build/MegaTycoonSlice.exe` | Release, `binary_format/embed_pck=true` (eine Datei), x86_64, ohne Konsole |
| `Windows Desktop Bench` | `build/MegaTycoonBench.exe` | wie oben, plus Feature-Tag `bench`: startet direkt die Bench, schreibt `mega_tycoon_bench.txt` neben die .exe und beendet sich |

Beide: `include_filter="data/*.json"` (Karte, Ökonomie, Palette), `exclude_filter="tests/*"`.

## Geprüft in der Sandbox (Linux, keine Windows-Templates)
- `--export-release "Windows Desktop"`: Preset wird erkannt, Abbruch nur wegen fehlendem Template (`windows_release_x86_64.exe`). Erwartet.
- `--export-pack` für beide Presets: PCK enthält `slice_map.json` und `economy_slice.json`, keine Tests. `--main-pack slice.pck` startet (Karte 299 ms, 0 fehlende IDs).
- `--main-pack bench.pck` ohne Argument: Bench startet über das Feature-Tag, 3 Läufe, Datei geschrieben, Exit 0.
- **Nicht geprüft:** die echte .exe, Windows-Pfade, GPU-Treiber. Das passiert erst auf Bastis PC.

## Schritte auf Bastis PC (Koordinator)
1. Godot 4.7.2 (win64) und die **Export-Templates 4.7.2** installieren (Editor → Projekt → Export → „Export-Vorlagen verwalten“ → Herunterladen). Ziel: `%APPDATA%\Godot\export_templates\4.7.2.stable\`.
2. `slice_f14.zip` entpacken, Projekt einmal im Editor öffnen (Import, ca. 10 s).
3. Godot-MCP: Export-Toolset aktivieren (`godot_enable_toolset`, Toolset für Export), dann Preset `Windows Desktop` und danach `Windows Desktop Bench` als **Release** exportieren. Ausgabe landet in `slice/build/`.
   CLI-Ersatz, falls das Toolset fehlt (PowerShell im Projektordner):
   `Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-release "Windows Desktop" build/MegaTycoonSlice.exe`
   `Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-release "Windows Desktop Bench" build/MegaTycoonBench.exe`
4. Basti: `MegaTycoonBench.exe` doppelklicken, ca. 1 min warten (3 s Aufwärmen + 3 × 15 s), Fenster schließt sich selbst. `mega_tycoon_bench.txt` liegt neben der .exe. Für 3 Läufe pro Start reicht ein Doppelklick; F-12 verlangt 3 Starts → dreimal doppelklicken, Datei nach jedem Start umbenennen (sie wird überschrieben).
5. Optional: `MegaTycoonBench.exe -- --bench-out=C:\pfad\datei.txt --bench-sec=30`.

## Was die Bench misst
Slice-Karte 512², 5.000 Lkw (dieselbe `vehicle.gd` und `economy.gd` wie im Spiel) auf 51 Straßen-Korridoren zwischen Lagern, Tempo 1×, VSync aus, Bildrate aus der Wanduhr. Datei enthält: CPU, GPU, Treiber, Renderer, Kartenladezeit, je Lauf Median/Mittel-FPS, Frame-Median, p95, Streuung, und das Urteil „3/3 ≥ 60 FPS“ und „Streuung ≤ 10 %“.
Grenze: Die Bench-Lkw fahren auch leer weiter, damit alle in Bewegung sind; im Spiel warten sie an der Rampe.

## Sandbox-Werte (kein Zielrechner, nur Plausibilität)
- Headless (nur CPU, Frame-Untergrenze 6,9 ms durch den Headless-Schlafmodus): Median 107–118 FPS, p95 35–48 ms. Die Spitzen sind die Sim-Ticks (10 je Sekunde, je ca. 10 ms Sim + 20 ms Puffer für 5.000 Fahrzeuge).
- xvfb mit Software-Rendering (llvmpipe): 1,0 FPS. Das sagt nichts über eine echte GPU.
