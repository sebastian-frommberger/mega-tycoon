# Felix, S6: U-02b HUD-Rest

Arbeitskopie: /tmp/claude-0/gd/sprint6/b/felix/slice (nicht im Repo). Shots: /tmp/claude-0/gd/sprint6/b/felix/shots/vorher und /nachher (gleiche Dateinamen u02b_1 bis u02b_6). Mess- und Shot-Skript: tests/u02b_shots.gd (neu, prüft bei 1600×900; `--nur-kohlberg` für die feste Zielpfeil-Ansicht).

## Ergebnis (gemessen, u02b_shots.gd)
| Prüfung | Vorher | Nachher |
|---|---|---|
| Linienliste (Karte) | 391 px | 340 px |
| Papierkorb-Klickziel | 38×30 | 38×30 |
| Kopfleiste Mindestbreite / Panel | 1575 / 1607 px (7 px abgeschnitten) | 1566 / 1600 px, 62 px hoch |
| Controls außerhalb 1600×900 | 1 (Kopfleiste) | 0 |
| Haberau-Label Nahzoom 2,2 | ausgeblendet | sichtbar (vor und nach dem Aufbau) |
| Zielpfeil-Scan (20 Gebäude × 5 Zoomstufen) | 28 Überlappungen, z. B. Kohlberg z2,2 ← Stahlwerk | 0 |
| Skillpunkt-Zeile | fehlt | „1 Skillpunkt gespart“ ab M1b |

Regression `bash tests/d07_regression.sh <godot> /home/claude/mega-tycoon/spikes`: GRÜN, Exit 0, 0 SCRIPT ERROR (slice 72/72 soa+alt, Parität 8/8, s11 15/15, Abnahme ui 30/30, kredit 16/16, parity 12/12, lager 2/2, beide Spikes, Statik).

## Änderungen (nur main.gd, nur HUD-Funktionen, keine Umbenennung, keine Verschiebung)
- `_setup_hud`: Label „TEMPO“ entfernt (U-02-Spec Fix 2). Neu nach Kasse/Kredit: ruhige Zeile `hud_vals["skill"]` (LabelHudSmall, kein Chip, kein Icon, Tooltip), unsichtbar bis M1b.
- `_update_hud`: Skillpunkt = 1, sobald Ziel-Index 1 (erste Lizenz = M1b nach D22 §1) erledigt ist. Nur Anzeige. Kredit-Wert zeigt nur den offenen Betrag; der Rahmen steht als „max. 2.000 $“ im Tooltip (`_credit_chip`, U-02-Spec „Kredit“). Das hat die Breite für die Skillpunkt-Zeile freigemacht (Kredit-Chip 296 auf 198 px).
- `_make_line_row` / `_refresh_lines`: Zeile zweizeilig (oben Name + Papierkorb, unten Kennzahlen + Gewinn rechtsbündig). Text gekürzt auf „×1 · 28 Felder · 10 Lief.“, die Warnung steht vorn („keine Lizenz! · …“), Name und Kennzahlen mit Ellipse statt Spaltenwachstum. Dict-Schlüssel unverändert.
- `_place_map_labels`: (a) Label stößt von oben an eine Leiste unten (Hinweis-/Werkzeugleiste): wird um höchstens eine Labelhöhe nach oben verschoben statt ausgeblendet. (b) Zielpfeile haben Vorrang: Labels, die das Pfeil-Rechteck berühren (inkl. Wipp-Bereich, kein Flackern), werden ausgeblendet (Spec: Überlappung, niedrigere Priorität aus).

## Für Miras F-20-Merge
- Diff-Blöcke in main.gd: `_setup_hud`, `_place_map_labels`, `_credit_chip`, `_refresh_lines`, `_make_line_row`, `_update_hud`. Startdialog, `start_game`, Meilenstein-Logik, slice_map.json und Props sind nicht angefasst.
- Kopplung: Die Skillpunkt-Zeile liest `milestones[1]["done"]`. Wenn F-20 die Zielliste umbaut, muss Index 1 weiter „erste Lizenz“ (M1b) sein, sonst eine Zeile in `_update_hud` anpassen.
- Das Godot-Import hat in der Arbeitskopie `.uid`-Dateien zu einigen Skripten erzeugt. Die sind generiert, also beim Übernehmen nicht mitnehmen.
- tests/u02b_shots.gd steigt noch über `start_game("agrar")` ein und muss nach F-20 auf den neuen Testeinstieg (D-08) umgestellt werden.

## Offen / bewusst nicht gemacht
- Tempo-Schalter bleiben 56 px breit (die Spec nennt 44, mit Icon + „8×“ passt das nicht). Pause-Trennstrich nicht gebaut.
- Die Label-Rechtecke sind weiter eine Näherung (0,58 × Schriftgröße je Zeichen). Label-Label-Überlappung (z. B. Mühle 2 / Mittelfurt) bleibt Stretch „Label-Kanten allgemein“.
- Das verschobene Haberau-Label rückt bis zu einer Labelhöhe an die Häuser heran. Das sollen Sophie und Aylin am Shot u02b_1 abnehmen.
