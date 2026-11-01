# Refinement S4: Positionen Felix und Daniel

## Felix Novak (Programmierer, 7 T)

Ich bin allein. Die Kandidatenliste hat bei mir über 12 T, ich nehme 7 und garantiere dafür Qualität.

- F-14 Grey-Box-Slice: 3,5 T (statt 4). Das geht nur, wenn Sophie das JSON bis Tag 2 eingefroren hat (S-10 zuerst).
- F-16 Ökonomie-Kern: 2,5 T. Kein Kredit-Feintuning, nur Lizenz und Kauf plus Kredit als einfacher Zins.
- F-12 Release-Export: 1 T, bleibt. Er ist das Risiko-Frühwarnsystem.
- F-17 8×-Tempo: 0 T extra. Ich setze "8× nur bis 5k Einheiten" als Konstante innerhalb F-16. Der Sim-Thread ist raus.

Raus aus meiner Liste:
- F-15 Kontextdialog und Kauf-Flow gehen komplett nach S5. Dort ist der Gameplay-Programmierer da. Für R1 reicht ein Platzhalter-Button.
- A-08 Diagnose-Meldung: raus.
- B-01..04: nur B-03 (required-Listen), und Tobias macht es allein im Schema.

Einwand gegen D-06 (Daniel, 2 T): CI braucht mein Setup, und das sind versteckte 1–2 T für mich. Ohne CI-Server reicht ein Skript im Repo. Dann ist es machbar.

Akzeptanzkriterium F-14: Die Slice-Karte lädt aus dem S-09-JSON in ≤ 3 s auf Bastis PC. Alle Städte und Industrien aus dem JSON sind vorhanden (0 fehlende IDs im Log). Keine Region belegt mehr als 40 % der Fläche.

## Daniel Richter (QA, 7 T)

Mein Interesse: Am 15.01. steht ein Build vor Basti, der gemessen und getestet ist. Ohne externe Tester (D16) bin ich die einzige Absicherung.

- F-12 Release-Export und Messung: 1,5 T (statt 0,5). Drei Läufe, Ergebnisdatei neben der .exe, ein einziger Doppelklick von Basti. Das ist mein wichtigstes Ticket.
- F-16 Testfälle: 1,5 T. Ertrag nur beim Endabnehmer, Sättigung und Herkunftsstempel müssen mit festen Zahlen prüfbar sein.
- D-06 verkleinert: 1,5 T (statt 2). Ein Messskript pro Sprint statt CI-Server.
- F-14 Smoke-Test der Karte: 1 T.
- J-07 Testplan für Basti (zusammen mit Jonas): 1 T.
- Puffer für Regression und Retest: 0,5 T.

Raus: CI-Server, UI-Automatisierung.

Einwand gegen F-15 (Kontextdialog, 4 T): Es gibt kein messbares Abnahmekriterium, und ein Godot-UI-Flow lässt sich ohne Automatisierung nicht regressionssicher prüfen. Das ist ein Risiko für den R1-Review. Ich bin dafür, es in S5 zu schieben.

Akzeptanzkriterium F-12: Die Bench-.exe läuft in 3 von 3 Läufen ohne Absturz durch. Der Median liegt bei ≥ 60 FPS mit 5.000 Einheiten bei 1×-Tempo. Die Streuung zwischen den Läufen beträgt ≤ 10 %.
