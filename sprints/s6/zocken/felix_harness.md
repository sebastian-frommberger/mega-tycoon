# Felix – Zocker-Session-Werkzeug (S6)

Arbeitskopie `zocken/felix/slice` (Stand 95c36cb), nur `tests/` und `tools/` geändert.

## Neu
- `tests/play_session.gd` – spielt `<ordner>/commands.txt` ab, schreibt `shot.png`, `state.md`, `log.md` (+`run.txt`).
- `tools/play.sh <ordner> [godot]` – Wrapper (xvfb 1600×900, opengl3, importiert bei Bedarf).
- `tools/play_help.md` – Spieleranleitung, alle Befehle, Beispiel.
- Beispiel: `zocken/beispiel/` (Haberau, Lizenz farm_1, Straße, Lkw-Linie, 10 min, Panel Mühle 1). Weitere Testsitzungen: `zocken/felix/t3` (Mittelfurt, 3 Lkw, Lager, Gleis zu teuer, Linie auflösen, Pause, 30 min, Kredit), `zocken/felix/t4` (Lkw auf der Straße im Bild).

## Technik
- Echte UI-Wege für alles außer `wait` und `camera`: warp_mouse + push_input (wie d08_maus), Werkzeugleiste, Panel-Knopf, HQ-Knopf, Papierkorb, Kredit-/Tempo-Knöpfe, Esc. Treffer wird über `main._mouse_cell()` geprüft (±2 px Suche), Kamera schwenkt nur, wenn das Ziel nicht frei im Bild liegt.
- Determinismus: `main.set_physics_process(false)`, Sim nur in `wait` über `run_ticks` (10er-Schritte, Toast-Polling). Zweimal gleicher Lauf = identische state.md; Lauf mit voller 3D-Darstellung = identischer Spielstand.
- Tempo: während der Befehle `root.disable_3d = true` (Software-GL ~0,5 s/Frame sonst), UI läuft weiter echt; 3D erst fürs Schlussbild. Beispiel 22 s statt 63 s; `wait 30` ≈ 2 s. (`RenderingServer.render_loop_enabled=false` verworfen: Toast-Panel bekommt dann 2230 px Höhe und fängt Klicks.) `PLAY_RENDER=1` = volle Darstellung, `PLAY_DEBUG=1` = Klick-Diagnose.
- Fahrzeug-Puffer fürs Bild: `_render_vehicles()` 3× mit Frames dazwischen (RENDER_SPLIT).

## Funde fürs Team (Spiel, nicht geändert)
1. **HQ-Ring schluckt Industrie-Klicks:** HQ Mittelfurt (Radius 45) – Getreidefarm 3 (= erstes Ziel „Lizenz für Getreidefarm 3“) liegt auf dem Ring (d ≈ 44). Klick auf die Farm-Mitte bzw. Straßenziehen ab der Farm startet in den ersten 2 min „HQ umsetzen“ statt Panel/Bau (`hq_placement._hits_ring_or_hq`, RING_HIT_FELDER). Spieler hängt bis Esc + Warten.
2. **Ziel-Text vs. Erfüllung:** HQ Haberau: Ziele nennen „Getreidefarm 2“, Lizenz/Straße/Linie mit Getreidefarm 1 hakt sie trotzdem ab (Prüfung „irgendein Rohstoff“). Text und Zielpfeil passen dann nicht zum Spielzug.
3. Lkw aus Übersichtszoom kaum erkennbar (dunkler Klotz auf grauer Straße), nur Kosmetik.

## Regression
d07_regression.sh nach den Änderungen: GRÜN (alle 13 Suiten, 630 s, Sandbox). Hinweis: Beispiel-Lauf solo ~22 s, parallel zur Regression ~30 s.
