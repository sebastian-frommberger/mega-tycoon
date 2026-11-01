# Felix, Sprint 5 Tag 11: Bugfix nach D-07 (BUG-7, BUG-8)

Arbeitskopie `day11/felix/slice/`. Repo und Spikes unverändert.

## BUG-7 (Parität, Lager-zu-Lager +8 ¢ bei soa)
- **Ursache:** nicht Lager-Umschlag und nicht die Zahl der Fahrten, sondern Float-Drift im alten Kern. `vehicle.gd` zählte die Teilfelder für die Fahrtkosten in `field_acc` als float (`+= 0.6` je Tick). Nach vielen Pendelfahrten stand der Rest bei 0,9999999999999 statt 1,0, das letzte Feld (8 ¢ = `variabel_cent_pro_feld`) wurde also nie bezahlt. Der SoA-Kern rechnet in ganzen mm und bucht es korrekt. Sichtbar wird das nur auf der Lager-Linie, weil der Lkw dort nach dem Leeren des Startbestands für immer an der Quelle steht (Rest bleibt konstant). Belegt per Debug-Ausgabe: Seeds 1/4/7, alt 191/527/239 Felder, soa 192/528/240.
- **Fix:** `vehicle.gd` zählt die Teilfelder jetzt in ganzen mm (`field_acc` int, `speed_mm`, `feld_mm`), Überlauf bei Ankunft als `roundi(Überlauf × feld_mm)`, genau wie `sim_world._line_move`. `main.gd` setzt `speed_mm` jetzt für beide Kerne und `feld_mm` für den alten. `prog` bleibt float (Anzeige/Bench). Damit ist der alte Kern korrigiert, soa bleibt unverändert.
- **Ergebnis:** Parität 10/10 und zusätzlich mit `D07_TICKS_ADD` = 137 / 1001 / 3333 jeweils 10/10.

## BUG-8 (Zins nicht zeitgewichtet)
- **Fix:** `credit.gd` berechnet den Zins auf den durchschnittlichen offenen Betrag der Periode: rdiv(Σ offen × Ticks × Zins‰, 1000 × periode_ticks). Integriert wird nur bei Aufnahme, Tilgung und am Periodenende, es gibt also keinen Aufwand je Tick. Über eine ganze Periode bleibt der Festzins bitgenau gleich, und der Zinssatz kommt weiter aus dem JSON. `repay(eco, tick)` bekommt dafür den Tick (der Aufruf in `main.gd` ist angepasst). `interest_due` liefert im selben Tick bei mehreren Aufrufen denselben Wert.
- **Begründung:** Das war die kleinste Lösung, die in beide Richtungen fair ist. B10 (2.000 $ für 597 Ticks) kostet jetzt 19,90 $ statt 0 $. B11 (Aufnahme 1 Tick vor Periodenende) kostet 1 ¢ statt eines vollen Periodenzinses. Mit dem Höchststand der Periode wäre B10 zwar zu, aber B11 bliebe überteuert.
- **Hinweis für Daniel:** Die NOTE-Zeile in B11 („Volle Periodenzins (0 $)…“) steht in seinem Test fest und erscheint weiter, weil interest_paid > 0 ist. Inhaltlich ist sie überholt. Ich habe den Test nicht geändert.

## Spike sim-core/economy.gd (nicht geändert)
- Der Lager-Fix B-xx fehlt dort weiterhin: `acc = mini(q, warehouse_cap - st_stock[k])` statt `clampi(…, 0, q)` wie im Slice (economy.gd:746). Ich habe ihn nicht übernommen, weil das riskant wäre. Der Spike ist eingefrorene Referenz (`build_md5_f16.txt` enthält economy.gd), und `bench_world.gd` füllt mit `seed_stock` 100 Mio. Einheiten auf. Die Regression soll außerdem gerade zeigen, dass der Slice die Spikes nicht berührt. Das sollte bewusst als eigenes Ticket mit neuer md5 und erneutem Bench-Lauf übernommen werden.

## Geänderte Dateien (slice/)
- `vehicle.gd` (BUG-7)
- `main.gd` (BUG-7: speed_mm/feld_mm beim Fahrzeugkauf. BUG-8: Tick an `credit.repay`)
- `credit.gd` (BUG-8)

## Test
`bash tests/d07_regression.sh <godot> …/day11/felix/spikes`: **GRÜN, 8/8 Suiten**. slice_test soa 70/70, alt 70/70, parity_test 8/8, s11 14/14, Abnahme ui 30/30, kredit 16/16, parity 12/12, lager 2/2, beide Spikes grün, statische Prüfungen OK. 0 SCRIPT ERROR. Laufzeit 148 s (Sandbox, headless, keine FPS-Aussage).
