# FX4 Ladeplatz-Halt, Option (b) (Felix, S8, 05.11.2026)

**Ergebnis: grün, verdrahtet.** Branch `s8-fx4` (von s8 48d3220). Alle Werte gemessen, headless Godot 4.7.2.

## Was (`proto/proto_sim.gd`)
- `orte_registrieren`: Die Wirtschafts-Station eines Ortes (Site, Fuhrwerke, HQ) liegt jetzt am **Ladeplatz** (`knoten_halt(ladeplatz)`, WA-08). Der alte Ortsknoten (nächste Kreuzung im Radius r_m) bleibt als `stationen[...].knoten_mitte` und `_reg.m_<rolle>` erhalten.
- **Die Postkutsche (Kulisse, W21) hält weiter an den Ortsknoten.** Sie fährt über eigene Halte-Slots (`_halt_station`, ohne Ökonomie und ohne Eintrag in `stationen`).
- Das HQ liegt an der Dorf-Station, also am Ladeplatz. Ein erster Versuch mit dem HQ am Ortsknoten machte `proto_ui_welt_test` rot („HQ Erlenbach: Fuhrhalterei“), weil `ui_welt.ist_hq` die Position der Site vergleicht. Deshalb liegt das HQ an der Site. Die Prüfsumme der festen Kette ist in beiden Fällen gleich.
- Halteknoten: alle 5 Stellen 9,8 m vom Ladeplatz (Mühle 0 m, Durchgang). Lindenfurt lag vorher 130 m von der Ortsmitte entfernt.

## proto_easing_test Teil B (vorher s8 48d3220 → nachher)
| k | E3 | E4 | E5 max × W/2 | E6 max × W/2 | Gesamt nachher |
|---|---|---|---|---|---|
| 1 | 0,96 → 0,96 | 0,84 → 0,84 (0 Verstöße) | 1,00 → **0,33** | 1,43 (ABW) → **0,91 (OK)** | 20 OK, 0 FAIL, 1 ABW |
| 4 | 0,29 → 0,29 | 0,80 → 0,80 | 0,33 → 0,33 | 3,15 → 2,04 (ABW) | 19 OK, 0 FAIL, 2 ABW |
| 8 | 0,14 → 0,14 | 0,80 → 0,80 | 0,33 → 0,33 | 6,75 → 4,08 (ABW) | 19 OK, 0 FAIL, 2 ABW |
| 20 | 0,06 → 0,06 | 0,80 → 0,80 | 0,33 → 0,33 | 17,46 → 10,20 (ABW) | 19 OK, 0 FAIL, 2 ABW |
E4 ist bei allen k grün, 0 Verstöße. Das Rot aus FX3 (1,01–1,02×) kam von der Postkutsche auf der neuen Anfahrt; mit Option (b) fällt es weg. E6 bei k ≥ 4 bleibt ABW (FZ-09, TA), wird aber kleiner.

## FEST_PRUEFSUMME neu
`1078369192135197259` (vorher `1803066295721950847`, WA-08/10). Begründung: Die Dorf-Station der festen Kette liegt jetzt am Ladeplatz (Knoten 408 statt Ortsknoten). Fuhrwerk 2 fährt dadurch eine andere Strecke, und die Kutsche nutzt eigene Halte-Slots. Determinismus bleibt grün.

## Regression
`regress_fast.sh` GRÜN, 133 s: proto_sim 58/58, proto_ui_welt 161/161, s8_fk02 27/27, easing 20 OK / 1 ABW, static_kasse 0 Verstöße. d08 n = 20 md5 5cce648a53c1c2f3246147abcaca0988 (Slice unverändert).
