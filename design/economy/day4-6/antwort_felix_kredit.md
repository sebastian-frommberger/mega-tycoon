# Antwort an Felix: Kreditrahmen ab Minute 0 – welche Regel? (Tobias, 20.11.2026)

Deine Frage aus Tag 1–3 („Kreditrahmen ab Minute 0 gegen Soft-Lock machbar?“) hat D1 in eine Regel verwandelt. Hier die Regel mit Zahlen. **Kein Sprintcode** (Katrin E1: Regel ja, Umsetzung M1). Für L-05 spielt die Spielleitung die Bank. Alle Zahlen sind Modellrechnung (`t05_final_kredit_test.csv`, Raster Höhe 0 / 1.000 / 2.000 / 3.000 $, Zins 0 / 1 / 2 %/min).

## Regel (Vorschlag, 5 Sätze)

1. **Höhe: 2.000 $ fest**, für alle Archetypen, ab Minute 0, ohne Freischaltung. Der Kontostand darf bis −2.000 $ fallen.
2. **Zins: 1 % je Spielminute auf den gezogenen Betrag**, täglich (je Ökonomie-Tick) belastet. Voll gezogen sind das 20 $/min, genau ein Firmen-Unterhalt der Stufe 1. Kein Zins auf Guthaben.
3. **Sperre: Firmenkauf, Firmen-Ausbau und HQ-Ausbau nur aus Guthaben** (Kontostand ≥ Preis). Straße, Gleis, Fahrzeuge, Lager und Lizenzverlängerungen dürfen den Rahmen nutzen. Lizenzen laufen auch im Minus weiter (sonst zerstört der Kredit die Kette, die ihn zurückzahlt).
4. **Rahmen erschöpft:** Ist der Kontostand < −2.000 $ (durch Fixkosten), werden fällige Fixkosten weiter gebucht, aber keine neuen Ausgaben erlaubt; nach 10 Spielminuten unter −2.000 $ folgt das Ereignis „Zwangsverkauf einer Firma“ (lena.md). Nicht im VS, Sandbox ohne Bankrott.
5. **Anzeige:** Kontostand negativ in Rot, Zeile „Kredit 460 / 2.000 $, 5 $/min“ im HQ-Panel; eine Diagnose-Meldung „Konto im Minus, Kauf gesperrt“ beim ersten Zug. Text an Aylin, nicht in diesem Sprint.

## Warum diese Zahlen

| Fall (Kauf-Route, Verarbeiter in Minute 0) | ohne Kredit | mit 1.000 $ / 1 % | mit 2.000 $ / 1 % |
|---|---|---|---|
| Hafen knapp (3.000 $) | Soft-Lock, −1.600 $ nach 90 min | Linie voll min 1, 460 $ gezogen, 5 $ Zins | gleich |
| Bergbau knapp (5.500 $, mit Kohle) | Soft-Lock, −1.884 $ | min 1, 864 $ gezogen, 9 $ Zins | gleich |
| Bergbau Untergrenze Lena (6.000 $) | Linie voll erst min 6 | min 1, 364 $, 4 $ Zins | gleich |
| Agrar / Handel knapp | Linie voll min 14 / min 5 | min 1, 367 / 325 $ | gleich |
| Empfehlung D1 (4.500 / 4.500 / 7.000 / 5.000 $) | kein Kredit nötig | 0 $ gezogen | 0 $ gezogen |

- **1.000 $ reicht rechnerisch** (größter Zug 864 $). 2.000 $ wähle ich, weil das Modell keine Bauzeit und keine Fehlplanung kennt: ein Umweg von 20 Feldern im Gebirge kostet 288 $ Straße, ein dritter Lkw 400 $. 2.000 $ ≈ 1 Startpaket, 0,5–1 Kaufpreis.
- **1 %/min** ist so gewählt, dass Dauerschulden spürbar, aber nicht tödlich sind: 20 $/min gegen 400–850 $/min Einkommen einer laufenden Kette. 0 % macht den Kredit zu Gratis-Startkapital (dann könnte man das Startkapital gleich um 2.000 $ erhöhen). 2 %/min ändert in der Rechnung nichts (Zinsen 6–18 $ statt 3–9 $), weil die Kette in Minute 1 zurückzahlt; es würde erst bei langem Minus wirken.
- **Sperre auf Firmenkauf** ist der Kern: Ohne sie finanziert der Kredit den Kauf und die Leiter (Lizenz → Kauf) verliert ihren Grund. Mit ihr bleibt die Reihenfolge „erst Kette, dann Besitz“ erhalten, und Soft-Lock ist trotzdem ausgeschlossen.

## Für die Sim (dein Teil, M1)

- Konto als `int64` in Cent (F-09). Kreditrahmen `kredit_rahmen_cent = 200000`, Zins `kredit_zins_promille_pro_oeko_tick`: 1 %/Spielminute bei 1 Hz Ökonomie-Tick (10 Sim-Ticks) = 10 ‰ je 60 Ökonomie-Ticks → als Promille je Ökonomie-Tick 0,1667 nicht ganzzahlig. Vorschlag: Zins **je Spielminute** buchen (alle 60 Ökonomie-Ticks, 10 ‰ auf den gezogenen Betrag, Rundung halb auf). So steht es in `f09/economy_constants.json`.
- Befehl `kaufe_firma` prüft `konto_cent >= preis_cent`, nicht `konto_cent + rahmen`. Fahrzeugkauf prüft `konto_cent + rahmen >= preis_cent`.
- Prüffall: Hafen 3.000 $ Startkapital, Sägewerk sofort kaufen → ohne Rahmen bleibt die Linie unvollständig, mit Rahmen voll in Minute 1, Kredit in Minute 1 zurück. Erwartete Zinsen 5 $ (500 Cent).

## Offen

- Ob der Rahmen pro Archetyp skalieren soll (Bergbau 2.500 $?): nein, solange die Startkapital-Untergrenze bei Bergbau 6.500 $ wird (Vorschlag an Lena). Sonst ja.
- Entscheidung Jonas: Sperre auch für Lizenz-**Neu**abschluss im Minus? Ich sage nein (Lizenzen sind billig, 70–280 $), die Regel bleibt einfacher.
