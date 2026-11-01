# Felix, Sprint 6 Tag 1–3 (Arbeitskopie /tmp/claude-0/gd/sprint6/a/felix/, nicht im Repo)

Godot 4.7.2 headless. Alle Zeiten sind Sandbox-Zeiten und nur relativ zu lesen, keine FPS-Aussage für den Zielrechner.

## 1. F-21a Spike-Lager-Fix
- **Ursache:** `spikes/sim-core/economy.gd:746` `acc = mini(q, warehouse_cap - st_stock[k])`. Liegt der Bestand über der Kapazität (`seed_stock`, z. B. bench_world mit 100 Mio. E), wird acc negativ. Dann gibt `on_unload` einen Wert < 0 zurück, Ladung und Lose des Lkw wachsen über seine Kapazität (gleicher Bug wie B-xx im Slice).
- **Fix:** `acc = clampi(warehouse_cap - sim.st_stock[k], 0, q)`, wörtlich wie im Slice, mit Kommentar.
- **Regressionstest:** `eco_tests.gd` E9, 20 Läufe. Zulieferer mit 10/40/70 E, jeder 2. Lauf mit Abholer, 5 Läufe mit Bestand über Kapazität, 5 Grenzläufe knapp unter Kapazität (Lieferung größer als der Restplatz, das Lager muss genau auf 200 voll werden). Je Tick wird geprüft: Bestand ≤ max(Kapazität, Vortick), ohne Seed ≤ Kapazität, Ladung jedes Lkw im Bereich 0..Kapazität. **Ohne Fix rot** (15/20, alle Seed-Läufe: z. B. Lkw-Ladung 63 bei Kapazität 10), **mit Fix 20/20**.
- **md5** (`build_md5_f16.txt` aktualisiert, alte Fassung als `build_md5_f16_vor_f21a.txt`):
  - economy.gd `60697a14a73ce1e11a922babaf4aa040` → `bb12c3c3704f062d4ad8e2c5484f7293`
  - eco_tests.gd `44ec4612fd53150d0ce2cac39f8d6684` → `b14b99645f3ad9377f3a9af7d1ec5278`
  - Alle übrigen Einträge unverändert, `md5sum -c` grün.
- **Ergebnis:** Spike-Smoke sim-core grün (test_runner Exit 0, f06_smoke Exit 0, 0 SCRIPT ERROR; K8/K10 Äquivalenz und Determinismus grün). Parität soa/alt im Slice: d07 C11 10/10 Seeds, parity_test 8/8. Kein Bench-Vergleich (laut Ticket).

## 2. Zielrechner-p95 (F-12-Auflage)
- **Messung:** `slice/tests/prof_s6.gd` (neu) misst die Frame-Bausteine nach dem Bench-Setup (5.000 Lkw, SoA). Dazu lief bench.gd mit Zeitmessung in `_physics_process` und `_process` (instrumentierte Wegwerf-Kopie im Scratchpad).
- **Ursache:** Die Spitzen sind die **Tick-Frames** (10 Hz Physik). In diesen Frames laufen `sim_tick` und `_render_vehicles` zusammen. Davon ist `sim_tick` ~3,5 ms, der Aufbau der MultiMesh-Puffer für 5.000 Lkw aber **~20,5 ms** (Sandbox). Bei ~90 FPS ist jedes ~9. Frame ein Tick-Frame (≈ 11 % > 5 %), deshalb bestimmt dieser Frame die p95 allein. GC spielt keine Rolle. Zwei Nebenbefunde:
  - `_refresh_lines` (1×/s) brauchte 36 ms. Grund: Gewinn und Lieferungen wurden für alle 102 Linien gerechnet, obwohl nur 8 Zeilen sichtbar sind. Das ist eine 1-%-Spitze.
  - `_update_hud` brauchte 4 ms in **jedem** Frame, weil `fleet_size()` jedes Mal alle 5.000 Fahrzeuge zählte.
- **Fix (rein Darstellung, Sim und Parität unberührt):**
  1. `fleet_soa.gd`: Puffer-Aufbau mit Packed-Cache (vid, rindex, Typ) statt 3 × 5.000 Objekt-Property-Zugriffen: 20,5 → 13,7 ms.
  2. `fleet_soa.gd` render_begin/step/finish und `main.RENDER_SPLIT`: Der Puffer für den Tick-Zustand wird in höchstens 4 Portionen über die Frames bis zum nächsten Tick gefüllt. Ein Rest wird beim nächsten Tick synchron erledigt. Der Sim-Zustand ändert sich nur im Tick, die Bilder sind also exakt, erscheinen aber **einen Tick (100 ms) später**. Das ist der Preis. Abschalten mit `RENDER_SPLIT := false`.
  3. `main.fleet_size()` cached (Invalidierung bei Kauf/Verkauf), `_refresh_lines` rechnet nur die sichtbaren 8 Zeilen.
- **Wirkung (Sandbox, nur relativ):**
  - Tick-Frame-Skript (Physik) Median 21,5 → 6,5 ms.
  - Bench headless p95 33–37 → 19 ms.
  - TIME_PROCESS Median ~50 → ~15 ms (enthält jetzt die Render-Portionen).
  - render_step je Frame ~3,2 ms.
  - refresh_lines 36 → 3,5 ms, update_hud 4,0 → 0,3 ms.
  - Erwartung Zielrechner: p95 deutlich unter 22 ms. **Gilt erst nach Bastis nächstem Bench-Lauf** (neue .exe nötig).
- **Rest-Vorschlag, falls es nicht reicht:** `RENDER_STEP_PARTS` je nach FPS anpassen oder den Puffer-Aufbau in C++/GDExtension verlagern (R2). Die sim_tick-Arbeit nicht verteilen, weil sonst die Parität gefährdet ist.
- Hinweis: main.gd wächst um 17 Zeilen (Hooks, Cache). PO-Regel „kein Umbau von main.gd vor F-20“: Es ist kein Umbau, die Logik liegt in fleet_soa.gd.

## 3. F-20-Vorbereitung (D22) und T-14-Übernahme (Coordinator-Nachträge)
- **economy.gd:**
  - Neue Funktion `start_company_at(hq_node_id, hq_stage_id)`: Kapital nur aus `hq.start_capital_cent`. Diese Funktion ruft Miras hq_placement.gd auf.
  - `start_company(archetyp, …)` ist nur noch ein Wrapper bis F-20 (Archetyp als Etikett für main.ARCH-Hinweise, ohne Einfluss auf Kapital oder Radius).
  - Gegenprobe `_same("hq.start_capital_cent", "startkapital_cent")` und `_same("kredit.credit_step_cent", "kredit.schritt_cent")`.
  - `city_demand` mit `saettigung.demand_mult_promille_je_stufe` (über s_stage, ein Dorf, das zur Kleinstadt wächst, fällt also auf ×1 zurück).
- **JSON (slice/data):**
  - economy_slice: `hq.start_capital_cent` = 600000. Entfernt: `start_capital_{agrar,mining,port,trade}_cent`, `start_capital_floor_mining_cent`, `archetyp_*_im_slice_flag`, `meta.archetypen_im_slice_ids`.
  - `fahrzeug_ref.startpaket_lkw_anzahl` = 2, `kredit.credit_step_cent` = 50000, `saettigung.demand_mult_promille_je_stufe` {dorf 2000, kleinstadt/stadt/metropole 1000}, freeze_stand_text ergänzt.
  - economy_constants: `startkapital_cent` = 600000 (Zahl), `kredit.schritt_cent` = 50000.
  - vehicles: `lok_e1.fix_cent_pro_periode` 30000 → 9000.
  - Key-Name wie bei Tobias.
- **credit.gd:** `step_cent` aus `kredit.credit_step_cent`, Rückfall 500 $ nur bei fehlendem Key (d07-B3-Test-JSON). main.gd nutzt `credit.step_cent`.
- **main.gd:** start_game und Startkachel lesen das eine Kapital und Lkw-Paket. Die Kartenprüfung vergleicht kein Archetyp-Kapital mehr. `slice_map.json` enthält noch `hq_optionen[].startkapital_cent`, das wird ignoriert. **Sophie/Coordinator:** beim Merge entfernen.
- Nicht angefasst: slice_map.json, UI, Karte.
- **Tests:** slice_test-Einstieg angepasst (Kapital = JSON = constants, kein Archetyp-Kapital, Bergbau gleiches Kapital und Lkw-Paket wie Agrar). Neu: Kreditschritt aus dem JSON, Nachfrage = EW × Satz × Multiplikator für alle Städte (mit Dorf ×1 nachweislich rot).

## Regression (`tests/d07_regression.sh`, Spikes aus der Arbeitskopie)
- Grün:
  - parity_test 8/8, s11 14/14
  - d07_abnahme ui 30/30, kredit 16/16, parity 12/12 (C11 10/10 Seeds), lager 2/2
  - Spikes sim-core und f04-signal
  - Statische Prüfungen
  - 4 Screenshots
  - **0 SCRIPT ERROR**
- **Rot: slice_test soa und alt je 71/72.** Grund ist die Prüfung „T-12: Agrar-Kasse nach 30 min ×1,5–2,0 des Starts“, jetzt ×2,27.
  - Ursache gemessen: Dorfnachfrage ×2 (mit Dorf ×1 wären es ×1,66, S5 vorher ×1,88). Das 6.000-$-Kapital ist nicht die Ursache.
  - Die Prüfung habe ich **nicht abgeschwächt**. Das ist ein Balance-Ziel aus T-12 (Archetyp Agrar, 4.500 $), das mit dem T-14-Paket kollidiert.
  - **Entscheidung nötig (Tobias/Jonas):** T-12-Band für 6.000 $ und Dorf ×2 neu setzen (die T-14-Kriterien Bankrott und M7 ersetzen es) oder Dorf-Multiplikator kleiner.
