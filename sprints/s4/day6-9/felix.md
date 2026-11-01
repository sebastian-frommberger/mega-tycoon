# Felix – Sprint 4, Tag 6–9: F-14 Grey-Box-Slice, F-12 vorbereitet

**Stand:** `felix/slice/` (Godot 4.7.2) baut auf dem Prototyp auf (UI, Bau-Tool, Lkw/Zug, Lager, Abriss). Karte 512² aus `slice_map.json` (8 Städte, K1–K3, Wasser und Gebirge), Farben S-08. Ökonomie über `economy.gd` (unverändert, md5 gleich) und T-06-JSON (Tobias' neueste Fassung). Fahrzeugkauf und Unterhalt aus `vehicles.json`, kein Kredit, Kasse < 0 $ = Bankrott. Startdialog Agrar/Bergbau, Klick-Panel mit „Lizenz kaufen“ (Preis, Ertrag/Monat), Ziele oben rechts mit „Nächster Schritt“ und gelbem Marker.

**Entscheidung:** R1 fährt mit den Prototyp-Fahrzeugen, nicht mit dem SoA-Kern. Ein Shim (`eco_shim.gd`) gibt `economy.gd` die Kern-Schnittstelle. SoA erst, wenn Zahlen über 5.000 nötig sind.

**Tests** (`slice/tests/run_tests.sh`, Sandbox): 38/38 OK, Exit 0, 0 Script-Fehler.

| Test | Ergebnis |
|---|---|
| Karte | 135–300 ms (Ziel ≤ 3 s), 0 fehlende IDs |
| Durchlauf Agrar 30 min | 117 von 119 Lieferungen mit Gewinn, 3. nach 1:08; Kasse 3.700 → 13.137 $ |
| Bergbau Kohle → Kraftwerk | 59 mit Gewinn |
| Lager-Pingpong | 410 Einheiten, 0 $ |
| Nur Lkw kaufen | Bankrott nach 0:05 (13 Lkw) bzw. 7:20 (5 Lkw) |

Screenshots: `felix/shots/`.

**F-12:** `export_presets.cfg` (Release, eine .exe, plus Bench-Preset mit Feature `bench`), PCK-Export geprüft. Schritte: `felix/f12_export.md`.

**Ehrlich offen:**
- Die echte .exe ist nicht gebaut (keine Windows-Templates hier). GPU-FPS unbekannt: Software-Rendering 1 FPS sagt nichts. Headless (nur CPU) 107–118 FPS, aber Spitzen bis 48 ms bei jedem Sim-Tick.
- Die Physik-Interpolation der Fahrzeuge ist nicht per Auge geprüft.
- Annahmen ohne JSON: Startpaket-Lkw gratis, Gleis 40 $/Feld, Brücke ×6, Berg ×3, Zug = Lok + 4 Waggons.
- Agrar verdreifacht die Kasse in 30 min. Für T-12 eher zu leicht.
- „≤ 10 min ohne Anleitung“ ist nur im Skript belegt, nicht mit einem Menschen.
- Fehler in `economy.gd`: Bestand über der Lagerkapazität (nur über `seed_stock`) macht die Annahme negativ. Nicht behoben.
