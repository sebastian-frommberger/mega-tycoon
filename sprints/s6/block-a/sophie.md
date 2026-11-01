# Sophie, Sprint 6 Tag 1-4: S-12 Kartenpaket

**Arbeitskopie:** `sophie/slice/` (nicht im Repo). Geändert: `data/slice_map.json`, `tests/s11_test.gd` (Erwartung Mühle 43-45 statt 30-40, neue Prüfung Werkzeugfabrik 38-42), neu `tests/s12_shots.gd`. Prüfskripte: `sophie/tools/` (Kopie aus S5, Karte gespiegelt). Vorher-Karte: `sophie/slice_map.before.json`.

## Änderungen an der Karte
| Objekt | vorher | nachher | Abstand |
|---|---|---|---|
| werkzeug_1 | (330,170) NO | **(193,258)** SW | Kohlberg 40,2 (vorher 182), im HQ-Radius 50 |
| muehle_2 | (360,235) | **(354,237)** | Mittelfurt 43,9 (vorher 37,7); Lenas Regel: Radius 45 inklusiv, Mühle ≤ 44 |
Folgekanten in `ketten`: stahl_1 → werkzeug_1 169 → 60; werkzeug_1 → mittelfurt 77 → 204; farm_3 → muehle_2 72 → 78; muehle_2 → mittelfurt 38 → 44. `hq_optionen`: werkzeug_1 bei Kohlberg, farm_3/muehle_2 bei Mittelfurt ergänzt (Altstruktur, löst Lena/Tobias mit Städteliste ab). status.version `S-10+D22+S-12`.
Warum SW statt NW: Werkzeug aus NO nach NW ergäbe NW 30 % (Rand). Mit (193,258) sind alle vier Quadranten genau 25 %.

## Prüfergebnisse (Sandbox)
- Validator: Exit 0. check_s10: Exit 0, NW/NO/SW/SO je 25,0 % (vorher NO 30, SW 20), Stadtabstand 15,7 %, Gelände unverändert.
- Fluss-Schnitt-Test (s11_test): grün, farm_3 (432,232) – Mühle (354,237) kreuzt den Fluss. s11_test 15/15.
- Ketten im HQ-Radius (Abstand ≤ Radius): Haberau (r55) farm_1 35,4, farm_2 18,8, Mühle 25,2; Kohlberg (r50) Kohle 48,8, Erz 44,6, Kraftwerk 27,8, Stahl 30,4, Werkzeug 40,2; Mittelfurt (r45) farm_3 43,5, Mühle 43,9. = **3 Städte** (heute 2).
- D-07 Regression: **8/8 Suiten grün, Exit 0** (slice_test soa 70/70 und alt 70/70, parity_test 8/8, Abnahme parity 12/12, ui 30/30, kredit 16/16, lager 2/2, Spikes). Ein erster Lauf hatte A21 (Panel-Slide 191 ms statt ≤ 150) rot; Timing-Flake unter Last, 3 Einzelläufe 30/30, Wiederholung grün. "Parität 10/10" gibt es als Zahl nicht, die Paritätssuiten sind 8/8 und 12/12.
- Screenshots: `sophie/shots/vorher_|nachher_kohlberg.png, _mittelfurt.png`.

## Neue md5 (Freeze-Kandidat)
`data/slice_map.json` = **6abdceab6e48ecc214cea4f81eeafe2f** (vorher 6728052c4741557df449141a7a5db2ed). Freeze erst mit Tobias' Gegenprüfung Tag 4.

## Für Tobias / Integration (nicht geändert)
- **Dorfnachfrage ×2 liegt nicht in der Karte.** Sie kommt aus `economy_slice.json`: `saettigung.demand_per_100_inhabitants_einheiten_pro_periode` (1, gilt für alle Städte, ×2 würde auch Kohlberg und Mittelfurt verdoppeln) und `staedte[dorf_agrar].einwohner_anzahl` (900). Vorschlag: nur Haberau über `dorf_agrar.einwohner_anzahl` 900 → 1.800 geht nicht, das überschreitet die Kleinstadt-Schwelle 1.000. Sauber wäre ein neuer stufenabhängiger Key (z. B. `demand_mult_dorf_promille` = 2000), den economy.gd liest. Entscheidung Tobias/Felix, ich habe nichts angefasst.
- Kartenkarte und Datenblatt (T-14b): Werkzeug → Mittelfurt ist jetzt 204 Felder (Absatz fern), Stahl → Werkzeug 60. Bankrott/M7 neu messen, Tobias' Paketzahlen (49/33/51 min) galten für 40 Felder, nicht für diese Lage.

## Offen
- Label "Werkzeugfabrik" überlappt den Kohlberg-Stadtlabel leicht im Zoom 9 (Label-Kanten, Stretch).
- Fehlermeldung "ERR_CANT_OPEN" (status < 0) beim xvfb-Lauf, Screenshots entstehen trotzdem; Ursache nicht untersucht.
