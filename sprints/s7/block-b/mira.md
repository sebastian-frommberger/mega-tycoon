# Mira – S7 Block B: W-04 Straßen/Gleise (S7) + U-03 Fehlertexte (beide Welten)

Arbeitskopie: `/tmp/claude-0/gd/sprint7/b/mira/slice`. Godot 4.7.2.

## Dateien
- neu `world/road_tiles.gd`: Autotile-Renderer (nur `--welt=s7`). Sophies Regel aus `road_tiles.json`: Maske N1/E2/S4/W8, 5/10 = gestreckte Gerade, sonst Knoten B×B + Arm je offene Seite bis zur Feldkante. Stadtstraße 12 m, eigene Straßen = Landstraße 9,75 m (Fahrbahn 7,5 m). Wasser = `road-bridge`, Deck bündig mit der Fahrbahn. Gleis: Train Kit, Spur 1,435 m, 2 Stücke je Feld, 90°-Kurve = corner-large auf R ½ Feld. Anschluss-Bits aus dem Bau-Pfad: die Straße endet an der Farm, nicht eine Kachel davor. Eine MultiMesh je Modell (≤ 9 Draw Calls). Vorschau als schmales Band + rote „Fehlstelle“ in voller Feldbreite.
- neu `world/bau_s7.gd`: Hang-Preis/Steigungssperre. **Schnittstelle für Felix** (alles optional in `s7_world.gd`): `hoehe_at(cell, grid)` (gibt es), `steigung_faktor(pct) -> float` (Platzhalter 1,0), `steigung_max_pct() -> float` (Platzhalter: keine Sperre). Steigung je Feld = max |Δh| / 25 m zu den Pfad-Nachbarn. Kacheln liegen auf `hoehe_at`/25 (Stufen am Hang bis Spline S8).
- neu `ui/fehlertexte.gd`: alle Texte aus Aylins Liste als Funktionen (B1–B17, S1–S3, L1–L15, K1/K2, U1/U4/U6/U10), Zahlen nur aus Spielwerten, Distanzen über `dist_str`.
- neu `ui/bankrott_warnung.gd`: K1-Prognose aus der Kassenänderung innerhalb `sim_tick` (Käufe/Bau zählen nicht), Fenster 2 min, Warnung bei ≤ 90 s (Puffer zu 60 s), 1×/min, größter Posten (Linie netto, Fahrzeuge ohne Linie, Gleisunterhalt, Lager, Zins). Nur lesend.
- `main.gd` (~120 Zeilen netto, Hooks): Preloads, `road_tiles`-Hook nach `_build_map`, S7 ohne Stadtstraßen-Quader, Quader in S7 unsichtbar (Platzhalter für `demolish`), Texte → FT, B9/B10/B7/L5/L10 nicht mehr stumm, Klick ohne Ziehen baut keinen 1-Feld-Stummel, S2 „nicht anschließbar“, Cursor-Kopf U12 + B12 gelb, Skillpunkt-Zeile raus (Toast bei M1b), Linienliste in ScrollContainer (Fenster-Refresh, kein „… weitere“), K2 im Overlay.
- `hq_placement.gd`: Radiuszeile über `main.dist_str` (Slice-Text = Vorschau-Daten, getestet), Ringlabels „Name · 625 m“, U6.
- T-15 (Tobias, Nachtrag Coordinator): Kredit-Sperre aus `kredit.credit_available_from_ticks`: [+] grau mit Tooltip „Kredit ab Minute 12 verfügbar (noch m:ss)“, Klick darauf meldet das, „Kasse reicht nicht“ (B8/B16/L6/L8/Panel/K1) ohne Kredit-Rat bzw. mit Freigabeminute. Minute und Rest aus JSON/Spielzeit.
- Tests: neu `tests/s7_w04_test.gd` (30), `tests/s7_u03_test.gd` (125, beide Welten, xvfb 1600×900), `tests/u03_bau_fehler.txt` + `tests/u03_play_check.sh` (play.sh, 12 Bau-Fehlerfälle, je Welt). Angepasst (Prüfung gleich streng): `slice_test` („je Spielminute“, „nicht durch die Stadt“, Ghost-Grund = Plan-Grund), `s7_mira_test` (B1-Text, S1-Text, L11-Text). `d07_regression.sh` Abschnitt 2c3.
- Werkzeug: `play_session.gd` Ziele als Feld `x,y` (auch jenseits des Rands), Befehl `demolish a b`; `play.sh` reicht `--welt=*` durch; `play_help.md` ergänzt (Daniel bitte beim Merge mitnehmen).

## Messwerte
- Straße : Block (700-m-Ansicht): 12 m : 88 m = 1 : 7,3 (Mittelfurt, Kohlberg, Seehafen; Haberau ist zu klein für zwei Parallelen).
- Lücken/Stoß: Geometrieprüfung aller Instanzen – jede offene Kante bis 0,5 Feld in voller Breite, geschlossene nicht über den Knoten, gleiche Höhe; 0 Quader sichtbar. Brückendeck = Fahrbahnoberkante (< 0,002).
- Hang-Preis (Stub 5 % → ×1,20): Vorschau = Σ Feldpreis × 1,20, Text „Hang: Bau ×1,20 teurer. Gesamt …“. 20 % bei Sperre 12 % → B11 rot mit „Zu steil: 20 % Steigung, erlaubt 12 %“.
- K1: 5 Lkw ohne Linie → Warnung 90 s vor Bankrott, Posten „5 Fahrzeuge ohne Linie (−450 $/min)“ = 5 × 90 $; Prognose 1:30 = echte Restzeit. Kein Fehlalarm mit Gewinnlinie (10 min).
- Kopfleiste bei 1.234.567 $ / 30 Fz / 999:59: Chips bis 1.246 px, Tempo ab 1.295 px, kein Label abgeschnitten.
- Kacheln Haberau-Umfeld: 701 Geraden, 53 Kreuzungen … (≤ 9 MultiMeshes).

## Screenshots (`shots/`, angesehen)
w04_kreuzung_nah (Stadtkreuzung 140 m), w04_kacheln_frei (Kreuzung/T/Kurven/Enden), w04_700m, w04_bruecke, w04_gleis, w04_vorschau_fehler (diagonal über Fluss: Band, rote Fehlstelle, „Straße: 15 Felder (375 m) · 150 $“ + B1), w04_vorschau_ok. Aufruf: `xvfb-run … -s res://tests/w04_shots.gd -- <dir>`.

## Offen / Hinweise
- Felix: Hooks `steigung_faktor`/`steigung_max_pct` in `s7_world.gd` ergänzen, dann wirken Preis und Sperre ohne weitere Änderung. `_mouse_cell` schneidet noch die Ebene y=0 (mit Terrain anpassen).
- Häuser in S7 sind noch Slice-Quader (W-03 Sophie); sie wirken neben 12-m-Straßen riesig (Bild kreuzung_nah).
- Gleis: Weiche/Kreuzung fehlt im Kit (Arme übereinander); Gleisstück auf 12,5 m gestreckt (×1,3).
- U8 („Nächster Schritt“ nur offene Teile mit Preis) und U9 (Kettentext) nicht umgesetzt: U9 steckt im Generator `hq_vorschau_gen.py`/`hq_vorschau.json` (Tobias, d08_lizenzfaktor), U8 braucht dynamische m3-Hinweise → Block C.
- K1-Text mit Posten-Namen bis ~120 Zeichen (Liste: 90 ohne Namen) – Aylin bitte abnehmen.
- Regression: siehe unten.

## Regression (Stand Übergabe)
`bash tests/d07_regression.sh <godot> /home/claude/mega-tycoon/spikes` läuft im Hintergrund, Ausgabe in `/tmp/claude-0/gd/sprint7/b/mira/regression.txt`, Zusammenfassung in `slice/tests/d07_regression_summary.md`. Bei Übergabe: run_tests.sh grün (slice_test soa/alt 72/72, parity 8/8). Einzeln vorher grün: s7_w04 30/30, s7_u03 125/125 (xvfb), s7_mira 33/33, u03_play slice + s7 (je 12 Ablehnungen, 0 stumm). Endergebnis noch offen.
- d07_abnahme H20 prüfte den alten Ringtext „Umsetzen möglich, noch“ – auf U6-Text umgestellt (exakter Vergleich mit FT.u6_ring), --only=hq 30/30.
