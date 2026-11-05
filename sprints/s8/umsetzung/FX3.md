# FX3 Haken für Bot und Kalibrierung (Felix, S8, 05.11.2026)

Branch `s8-fx3` (von s8 d088078). Alle Werte gemessen, headless Godot 4.7.2, sofern nicht anders markiert.

## 1 Ertragsausgleich a (W2): umgesetzt, grün
- **`economy.gd` (Tobias' Datei, minimaler Diff, 6 Zeilen):**
  - neues Feld `ertrag_a_promille` (Standard 1.000).
  - `apply_proto` liest `tempo_ausgleich_promille` aus `economy_proto.json`.
  - `yield_cent` rechnet nur bei a ≠ 1.000 mit `rdiv(c × a, 1000)` (zweite Rundung, höchstens ±1 ¢). Bei a = 1.000 wird der Zweig nie betreten, deshalb bleibt der Slice bitgleich; er ruft `apply_proto` ohnehin nie.
  - Wirkt auf jede Ertragsbuchung (Stadt, Verarbeiter, Werksmarge) und, weil dieselbe Funktion rechnet, auch auf die OE-05-Anzeige (`saett_luecke`). Fristen (`fz`), Bedarf, Produktion und Lager-Ertrag bleiben unverändert.
- **`proto_sim.gd`:** Nach `apply_proto` überschreibt das Nutzerargument `--a=<Promille>` den Wert (`eco.ertrag_a_promille`).
- **Test:** a = 2.000 gegen 1.000 über 6.000 Ticks. Die 41 Lieferungen sind gleich in Tick, Menge und Gut, ebenso die Einheiten (374 = 374). Der Ertrag je Lieferung ist genau × 2 (max. Abweichung 0 ¢), gesamt 221.361 → 442.722 ¢. a aus JSON = 1.000.
- **Für Daniel:** Der Bot darf seinen eigenen Bonus `a/1000` nicht mehr buchen, sondern muss `--a=` übergeben. Sonst wird a doppelt angerechnet.

## 2 kauf_total: umgesetzt, grün
`firma_kaufen` und `werk_ausbauen` zählen jetzt `bezahlt_cent` in `kauf_total` mit. Test: 60.000 → 413.000 ¢ (Kauf 153.000 + Ausbau 200.000). Der FK-02-Unterhaltstest ist angepasst, er zieht den Kaufpreis nicht mehr doppelt ab. **Für Daniel:** `fk_total` im Bot nicht mehr zu `kauf_total` addieren.

## 3 Ladeplatz-Halt für Orte: NICHT verdrahtet (E4 rot)
Versuch: `orte_registrieren` nimmt für Orte `knoten_halt(ladeplatz)` (wie bei Industrien). Danach habe ich den Code zurückgesetzt, der Commit enthält ihn nicht.
| Variante | E3 B | E4 B | E5 B | E6 B | proto_sim |
|---|---|---|---|---|---|
| heute (s8) | 0,96 | 0,84 ×, 0 Verstöße | 0 (max 1,00 × W/2) | 1,43 (ABW) | 58/58 |
| Ladeplatz Erlenbach + Lindenfurt | 0,96 | **1,01 ×, 18 Verstöße** | 0 (max 0,33) | 1,33 | 57/58 (nur FEST-Prüfsumme neu) |
| nur Erlenbach (Lindenfurt wie heute) | 0,96 | **1,02 ×, 30 Verstöße** | 0 (max 0,33) | 1,33 | – |
Halteknoten nach Umstellung: alle 5 Stellen 9,8 m vom Ladeplatz (Lindenfurt vorher 130 m).
**Befund:** Der schlimmste E4-Punkt ist jeweils die **Postkutsche auf dem Rückweg** (Leg 1, Krümmung 0,0194–0,0196 /m ≈ R 51 m, v = 16,9 m/Tick = 1,13 × v_sim, also in der Überhöhung). Die Fuhrwerke halten die Grenze ein (≤ 0,8 ×). Schon die Erlenbach-Station allein reicht für das Rot; es liegt also an der neuen Anfahrt über die Dorfstraße Nord, nicht an Lindenfurt. E5 wird mit dem Ladeplatz besser (0,33 statt 1,00 × W/2). Ursache **vermutet, nicht geprüft**: Die Überhöhung von +15 % wird auf einer R-50-Kurve nicht weit genug zurückgenommen.
**Optionen (Entscheidung Jonas/TA):**
- (a) Ladeplatz verdrahten und E4 bei FZ-09 (TA, Easing nach k) mitbeheben. Bis dahin ABW mit Datum: 1,01–1,02 × ist knapp über der Grenze.
- (b) Fuhrwerke halten am Ladeplatz, die Postkutsche (W21, nur Kulisse) behält ihren alten Halt. Das braucht zwei Stationen je Ort; Aufwand geschätzt 0,25 T [E].
- (c) Überhöhung in Kurven R ≤ 60 m kappen (`proto_easing.gd`, TA).
- (d) wie heute lassen (Lindenfurt 130 m von der Mitte).
`FEST_PRUEFSUMME` bleibt 1803066295721950847 (unverändert, weil nicht verdrahtet). Beim Verdrahten wäre der neue Wert -8075668807215666416 (gemessen).

## Regression (Commit d85b93d)
`regress_fast.sh` GRÜN, 109 s: proto_sim 58/58, s8_fk02 27/27, easing 19 OK / 2 ABW, static_kasse 0 Verstöße. d08 n = 20 md5 5cce648a53c1c2f3246147abcaca0988 (Slice unverändert).
