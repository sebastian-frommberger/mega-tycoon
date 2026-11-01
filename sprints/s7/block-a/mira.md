# Mira – S7 Block A: Z-01 + B-xx

Arbeitskopie: `slice/`. Geänderte Dateien: `main.gd`, `hq_placement.gd`, `economy.gd` (3 Zeilen), `tests/d07_regression.sh` (1 Block), neu `tests/s7_mira_test.gd`.

## Z-01 Stadtanschluss (main.gd, nur plan_track-Umfeld)
- `plan_track` → Dock-Logik, alter Rumpf heißt `_plan_cells(a, b, cells, rail, check_money)`.
- Endet/beginnt ein Drag auf einer Stadt: Weg wird immer vom Außenende zur Stadt gerechnet (hin = rück, gleiche Felder). Erstes Stadtfeld ist eine mit dem Zentrum verbundene Stadtstraße → Ende dort (Gleis: ein Feld davor). Sonst `_city_dock`: Randfelder neben verbundenen Stadtstraßen, nach Abstand sortiert, je Feld 3 Formen (Drag-Form, L waagrecht-zuerst, L senkrecht-zuerst, damit Brücken gerade queren), erstes baubares gewinnt, max. 24 Vollplanungen (Sandbox ≤ 26 ms je Mausfeld).
- Fund: Der Fluss teilt Mittelfurt; Straßen westlich sind nicht mit dem Zentrum verbunden (`_city_reach`, gecacht). Ohne das wäre „gebaut, aber keine Straßenverbindung“.
- Vorschau: Marker-Säule (`mat_marker`, Node `DockMarker`) auf dem Anschlusspunkt, Cursor-Zeile „Anschluss am Stadtrand X“, Bau-Toast „… · angeschlossen am Stadtrand X“.
- Stadt mitten im Weg: „Stadt im Weg: X. Strecke um die Stadt herumführen oder am Stadtrand enden lassen.“
- Brückentext neu: „Brücke geht nur geradeaus über das Wasser. In zwei Teilen bauen: erst bis ans Ufer, dann gerade hinüber.“ (kein Routing-Umbau; Diagonale Farm 2 → Mühle 1 bleibt W-04/Knickpfad).
- Wirkt auf jede Karte, die `cell_to_building`/`city_streets` wie der Slice befüllt. Felix: S7-Welt muss Stadtstraßen in `city_streets` und Stadtzellen in `custom_cells` eintragen, dann greift es ohne Zusatz.
- Bestehende Tests (Ecke → erste Stadtstraße) bleiben bitgleich: der Kürzungsfall liefert dieselben Felder.

## B-xx
1. Ring-Klick (hq_placement `_hits_ring_or_hq`): Feld auf/neben (8er-Nachbarschaft) einer Nicht-Stadt-Baute → nie Umsetzen. Neu: Ring-Label-Feld trifft (±5 × ±1,5 Felder). HQ, freie Ringfelder, Toast wie bisher. play_help.md „Bekannte Falle“ ist damit veraltet (Daniel: Zeile streichen).
2. Ziele: **Typgenau, Text „eine Getreidefarm“**, Pfeil/Hinweis zeigt weiter die nächste Empfehlung („Am nächsten: Getreidefarm 2 … Jede andere Getreidefarm zählt auch.“). Begründung: Das Ziel lehrt die Handlung (Lizenz → Straße → Linie), nicht ein Objekt. Objektgenau sperrt Spieler, die mit Grund ausweichen (Aylin musste wegen der Fluss-Diagonale auf Farm 1), und erzeugt den Eindruck „Spiel erkennt meine Farm nicht“. Gleichzeitig muss der Text wahr sein: Kohlberg „Lkw-Linie Kohlemine → Kraftwerk“ hakt jetzt nur mit Kohlemine → Kraftwerk, nicht mit Farm 3 → Mühle 2. Ziele 1–3 prüfen `b.typ` (Fallback ohne Kette: jeder Typ).
3. Lizenz-Toast: `economy.lic_events` (Verlängerung ok/abgelaufen mit Betrag), main leert in `sim_tick` → Toast „Lizenz Mühle 1 verlängert: -140 $, gilt weitere 30:00 Spielzeit.“ bzw. „… abgelaufen: Verlängerung kostet X, Kasse reicht nicht.“ Tobias: Liste nicht in die Prüfsumme, bitte beim Merge in economy.gd mitnehmen.
4. „-0 $“: `money_str` setzt kein Minus, wenn ganze Dollar 0 sind. Bankrott-Overlay zeigt Cent („Kasse -0,37 $“), damit es nicht „0 $“ neben „unter 0 $ ist das Ende“ sagt; Kasse oben „0 $“.

## Tests
- `tests/s7_mira_test.gd` (in d07_regression als „s7_mira“): Z-01 Straße/Gleis hin + rück für Mühle 1/Mühle 2 → Mittelfurt, Mühle 1 → Haberau, Marker + Label, gleiche Felder hin/rück, Brückentext; B-1 Mittelfurt/Farm 3 und Kohlberg/Kohlemine + Gegenprobe Label/HQ; B-2 Haberau Farm 1, Kohlberg falsche/richtige Linie; B-3 Toast mit Betrag; B-4 money_str und Overlay. 33/33.
- play.sh Aylins Route (`/tmp/claude-0/gd/sprint7/a/mira/play_aylin/commands.txt`): Haberau, Farm 2 (über Farm 1), Mühle 1, `road muehle_1 mittelfurt` (161 Felder, 1.810 $), Mehl-Lkw → M3 um 5:51, 7/7 Ziele, Kasse 5.461 $ bei 11:00.

## Offen / für andere
- Diagonale über Fluss (Aylin Bug 1) bleibt W-04.
- Mühle 1 → Mittelfurt kostet 1.810 $ (Umweg um den abgetrennten Westteil): Tobias/Lena prüfen, ob das als Balance passt.

## Regression
`bash tests/d07_regression.sh <godot> /home/claude/mega-tycoon/spikes` aus slice/: **GRÜN, 14/14 Suiten** (13 + s7_mira), 1396 s. d08_bankrott Haberau 34 % statt 35 % (1 Seed): Der Bot baut jetzt Stadtstraßen-Strecken, die vorher an Häusern scheiterten (Z-01). Prüfung 10/10 grün, Tobias T-16 informiert.
