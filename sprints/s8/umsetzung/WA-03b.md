# WA-03b Relief: Licht, Himmelslicht, Hangschummerung, Höhentönung (TA, S8 Block B, 05.11.2026)

**Ergebnis:** Hang-D im Bandmittel 8 % steigt von **10,5 % auf 20,1 %** (1,91 × Baseline, Ziel ≥ 12 % und ≥ 15,8 %). Das Licht allein, ohne Shader, liefert 16,4 % (1,56 ×). Die ebene Wiese wird **1,8 % dunkler** (erlaubt ≤ 10 %), 0 % Pixel geclippt, 0 % schwarz. `regress_fast` ist grün, die Slice-md5 ist unverändert. Commit `c8a01bc` auf `s8-ta3` (nach FZ-09).
Messung: `slice/tests/wa02_bodenmetrik.sh` (xvfb, opengl3, llvmpipe, 1600×900, Pause, `time_scale 0`). Die Werte sind relativ, keine absolute Leuchtdichte. Die Baseline auf `8b87248` habe ich neu gemessen. Sie ist bis auf die Lbin-Zeilen gleich mit `baseline_boden/hang_leuchtdichte.csv` und damit deterministisch. Der Endlauf ist gleich mit dem Justierlauf `v4_final`.

## Was
- `world/proto_licht.gd`:
  - Sonne `(-27, -135, 0)`, vorher `(-42, 38, 0)`. Das Licht kommt jetzt aus NW. Vorher kam es aus SE, und bei Blick nach Norden (Preset 1, Gier 0) wirkte das Relief invertiert. NW ist die kartografische Konvention (Licht oben links).
  - Energie 0,69, vorher 0,52.
  - Umgebung Quelle **Himmel, Anteil 0,5**, Farbanteil Energie 0,31, vorher Farbe 0,36.
  - Neu: `sonnenrichtung_xz()` und `terrain_parameter(mat)`.
- `world/proto_terrain.gdshader`: Neue Uniforms `schummer_*` und `toenung_*`, Standard 0 = aus (Rückfall, A/B). 0 zusätzliche Texturzugriffe.
  - Schummerung `col *= 1 + s·dot(n.xz, −sonne)/max(|n.xz|, 0,15)`: Ebenen bleiben unverändert.
  - Höhentönung aus `w_pos.y`: Tal 40 m satter, Kuppe 110 m trockener. Die Wasserklasse ist ausgenommen.
- `world/proto_terrain.gd`: 1 Zeile, `ProtoLicht.terrain_parameter(m)` in `_material()`.
- `tests/proto_licht_test.gd`: Die ALT-Werte sind **bewusst** auf die SOLL-Werte angehoben (Datum, alte Werte stehen im Kopf). Neu geprüft wird, ob die Shader-Richtung zur Szenen-Sonne passt und ob die Shader-Werte gesetzt sind. Ergebnis: 19 OK.
- `prototyp_welt.gd` (Mira) und `main.gd` sind unberührt.

## Justierung (alle gemessen, Sonne −27/−135)
| Lauf | Sonne | Umgebung | Schumm. | Tönung | D(8 %) | D(5 %) | L eben | Δ L eben |
|---|---|---|---|---|---|---|---|---|
| Baseline (−42/38) | 0,52 | Farbe 0,36 | – | – | 10,5 % | 6,6 % | 0,2835 | – |
| v0_farbe | 0,69 | Farbe 0,40 | 0 | 0 | 16,4 % | 10,3 % | 0,2833 | −0,1 % |
| v0_licht | 0,69 | Himmel 1,0 (E 0,40) | 0 | 0 | 15,3 % | 9,6 % | 0,3109 | +9,7 % |
| v1_licht | 0,70 | Himmel 1,0 (E 0,33) | 0 | 0 | 15,3 % | 9,6 % | 0,3133 | +10,5 % |
| v2_schummer | 0,69 | Farbe 0,40 | 0,04 | 0 | 27,8 % | 17,4 % | 0,2837 | +0,1 % |
| v2_toenung | 0,69 | Farbe 0,40 | 0 | 0,06 | 17,4 % | 10,9 % | 0,2809 | −0,9 % |
| v3_sky05 | 0,69 | Himmel 0,5 (E 0,40) | 0 | 0 | 15,9 % | 10,0 % | 0,2975 | +4,9 % |
| **v4_licht** | 0,69 | Himmel 0,5 (E 0,31) | 0 | 0 | **16,4 %** | 10,3 % | 0,2806 | −1,0 % |
| **v4_final (= Commit)** | 0,69 | Himmel 0,5 (E 0,31) | 0,01 | 0,06 | **20,1 %** | 12,6 % | 0,2784 | **−1,8 %** |

Befunde:
1. **`ambient_light_energy` wirkt bei Himmelsanteil 1,0 nicht** (0,40 → 0,33: Umgebungsterm 0,159 → 0,160). Gemessen [V]. Das Himmelslicht hob die Ebene um +9,7 % und brachte kein zusätzliches Relief. Bei 5–15 % Neigung ändert sich der Himmelseinfall kaum. Deshalb Anteil 0,5: Damit bleibt der Helligkeitsausgleich steuerbar, und Fassaden und Senkrechte bekommen trotzdem richtungsabhängiges Himmelslicht. Diese Wirkung auf Gebäude habe ich **nicht gemessen**.
2. **Die Schummerung wirkt im Bild ≈ 2,6 × stärker als gerechnet.** Mit 0,04 kamen +11,4 pp statt erwarteter ≈ 4 pp. Vermutete Ursache: Der Shader nimmt lokale Mesh-Normalen, die Messung Neigungen über ±25 m. Deshalb 0,01. Schummerung und Tönung zusammen bringen +3,7 pp. **Die 12 %/15,8 % kommen schon aus dem Licht** (16,4 %), nicht aus dem Shader-Trick.
3. Die Rechnung aus WA-03.md (Lambert) lag daneben. Das lineare Fitmodell der WA-02-Messung (L = a + b·cos Einfall, a = 0,116, b = 0,251) hat v0_farbe dagegen gut vorhergesagt: vorhergesagt 17 % / 0,28, gemessen 16,4 % / 0,2833.

## Nebenmessungen, Endlauf gegen Baseline (`bodenmetrik.csv`)
- Treppe gepoolt 17,7 % → 17,5 %, Ufer 29,1 % → 29,1 %.
- Detail-Streuung bei 40/120 m praktisch gleich (0,28–0,47 % → 0,29–0,47 %).
- Kachel-Nebenpeak w120_a 0,012 → 0,109, w40_b 0,005 → 0,041. Das liegt unter dem Ziel ≤ 0,25, ist aber gestiegen. Ursache nicht untersucht, vermutlich die Schummerung auf dem Mesh-Raster.
- CPU-ms/Frame je Stelle −3,6 % bis +4,8 % (Justierlauf v4_final). Das liegt in der Lauf-zu-Lauf-Spanne (WA-02: ≤ 6,6 %) und gilt nur relativ. Die Live-Dreiecke ändern sich an einigen Stellen (p2 615.887 → 573.227, acker_1 344.182 → 276.028), vermutlich über die Schattenkaskaden der neuen Sonnenrichtung. Nicht untersucht.
- Hangrichtungen relativ zur Sonne liegen jetzt auf der Sonnenseite (Sektoren [108, 0, 0, 11124, 44964, 43416, 900, 0]). Der Fit bleibt der Beleg, R² 0,24 → 0,47.

## Sichtprüfung (ein Bild, kein Look-Urteil)
Vorher/Nachher Preset 1: `/tmp/claude-0/wa03b/vergleich_p1.png` (oben vorher, unten nachher). Alle Shots: `/tmp/claude-0/wa03b/{base,final}/img/`. Auffällig: **Sonnenglanz auf dem Fluss am linken Bildrand.** Die Sonne steht jetzt vor der Kamera (Blick N, Licht aus NW). Das ist nicht gemessen und nicht bewertet. **Sophie (Look-Abnahme)** soll entscheiden, ob das Wasser-Specular gedämpft werden soll. Schattenkanten und Acne bei flacher Sonne (Presets 2/3) habe ich nicht angesehen.

## Nicht gemacht / offen
- Look-Abnahme Sophie (0,25 T) mit Vorher/Nachher-Tafel der 5 Presets. BT-2 erst danach.
- Personenprobe (höchster Punkt/tiefste Senke) erst in L1.
- SSAO-A/B ist nicht Teil davon (Skill-Lücke 1).
- `--sonne=` im Messskript dreht nur die Sonne. Die Schummer-Richtung bleibt dann auf der Konstante. Für Versuche müsste `ProtoLicht.terrain_parameter(mat, rot)` mitgerufen werden.

## Befehle
```
cd slice; G=/tmp/claude-0/gd/Godot_v4.7.2-stable_linux.x86_64
G=$G bash tests/wa02_bodenmetrik.sh /tmp/claude-0/wa03b/final       # Hang-D, L eben, Treppe, Frametime
timeout 300 $G --headless --path . -s res://tests/proto_licht_test.gd  # 19 OK
bash tests/regress_fast.sh $G                                           # GRÜN, 137 s
$G --headless --path . -s res://tests/d08_bankrott.gd -- --n=20 --csv=/tmp/claude-0/wa03b/d08.csv   # md5 5cce648a53c1c2f3246147abcaca0988
```
Justierskript (nicht im Repo): `/tmp/claude-0/wa03b/lauf.sh`, Ergebnisse `/tmp/claude-0/wa03b/ergebnisse.txt`.
