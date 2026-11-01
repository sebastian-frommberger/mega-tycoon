# Mira, S6 Tag 10: Bugfixes aus D-08 (Arbeitskopie mira/slice)

Regression `bash tests/d07_regression.sh <godot> /home/claude/mega-tycoon/spikes`: GRÜN, Exit 0, 492 s, 0 SCRIPT ERROR (d08_lizenzfaktor 8/8 jetzt normale Suite, d08_maus 22/22).
main.gd, props/, label_declutter nicht angefasst.

| Bug | Änderung |
|---|---|
| B-1 | `tools/hq_vorschau_gen.py`: Faktor wie `economy._licence_cost` (Rabatt/Aufschlag aus economy_slice.json, Distanz wie `economy._felder` mit feld_mm aus Karte), kein Größenfaktor. Lizenzierbar = `ausgang_gut_id` in economy_slice.json. Faktor- und „Nächste“-Liste nur lizenzierbar. Neu: haberau/kohlberg(Stahlwerk)/mittelfurt 0,70, steinbach 1,78, eichwald 4,45, lindach 3,52 (Erzmine), weidenau 5,32 (Stahlwerk), seehafen 5,44. `hq_vorschau.json` md5 **29b63e8df52e6f862867df081c55839d** (alt 953b00d3). |
| B-4 | `data/slice_map.json` Z. 675 `k3`→`k1` (nur diese Zeile). md5 **48278cd3a0c2adb8be81634ee17c29f4** (alt 718e062c = D24). Wer auf D24-md5 prüft (Validator, Doku Jonas/karte.md), muss nachziehen. |
| B-3 | `hq_placement.gd`: `_focus_start` – Wagnis: Kamera auf HQ; `start_targets` Wagnis: nächster Rohstoff mit Ausgangsgut, ohne Endabnehmer-Bonus (Steinbach Farm 3 → Mühle 2, Seehafen Farm 2). |
| B-9 | Generator: Wagnis-Zeile „Nächste Lizenzen: …“ statt Satzwiederholung; Feld `wagnis: true` in JSON, `is_wagnis` liest es (Alttext als Rückfall). |
| B-10 | Umsetzen-Modus: Kamera auf Übersicht (OVERVIEW_CELL/ZOOM); Esc/Rechtsklick stellt die vorherige Ansicht wieder her; nach Umsetzen Fokus auf neues HQ. |
| B-7 | `ui/ui_kit.gd glyph_font`: Poppins auch bei „HQ“ (Knopf „HQ hier gründen“/„umsetzen“, Shot hover_mittelfurt). |
| Pause (Lena) | **Kein Spielbug.** Spiel setzt nach Gründung Tempo 1 (M7/H16), Uhr läuft (L-12). Daniels `d08_maus` rief vor den `gegruendet_*`-Shots `m.set_speed(0)` → Screenshot zeigt Pause. Entfernt; neue Prüfung M14 (Tempo 1, Ticks laufen) für 3 Städte. |
| B-14 | slice_test Reporttext 18 E/min. |

Tests: d07_regression.sh 2c zählt d08_lizenzfaktor normal (record, SCRIPT-ERROR-Check). d08_maus: M11b jetzt echte Prüfung (Übersicht + MOVING), M14 Zeit läuft, M15 Wagnis-Kamera/Ziel; Ticks werden über 5 Physik-Frames gemessen (xvfb rendert langsam, 0,35 s Wanduhr gab 0 Ticks).
Shots: /tmp/claude-0/gd/sprint6/c/mira/shots/ (gegruendet_steinbach, hover_mittelfurt + Rest aus d08_maus).
Offen/Hinweis: Mittelfurt-Vorschau nennt weiter „Kette 3: Werkzeugfabrik außerhalb des Radius (259 Felder)“ (Absatz-Info, nicht Lizenz) – Lena/Jonas entscheiden, ob raus. Ring-Label „noch 1:53“ vs. Toast „2:00“ im Shot = Zeit läuft, ok.
Zu übernehmen: hq_placement.gd, ui/ui_kit.gd, tools/hq_vorschau_gen.py, data/hq_vorschau.json, data/slice_map.json, tests/d07_regression.sh, tests/d08_maus.gd, tests/slice_test.gd. Keine .uid, keine Logs.
