# T-04 Saettigung und Stadtwachstum -- Ergebnis (Tobias Brandt)

Modellrechnung, keine Spielerdaten. Skript `t04_wachstum.py` (deterministisch, kein Zufall), Zeitreihen als CSV (`t04_zeitreihe_*.csv`, Minutenwerte), Diagramm `t04_zeitreihe.png`. **Annahme:** Lenas Gewichte-Datei (`lena/wachstumsgewichte.md`) lag bei Abschluss nicht vor; verwendet sind W = 0,6 x Waren + 0,25 x Personen + 0,15 x Arbeitsplaetze und die Schwellen aus `concept/city.md`. Weitere Annahmen: Start 800 Einwohner (Dorf), Waren-Versorgung G = Mittel der Kategorien, Personenabdeckung P und Arbeitsplaetze J je Spielertyp konstant, 1 Spielmonat = 1 min, Wachstum multiplikativ je Monat.

## Ergebnis gegen die Zielzeiten (12 min Dorf > Kleinstadt, 80 min Kleinstadt > Stadt)

| Variante / Spielertyp | Dorf > Kleinstadt | Abw. | Kleinstadt > Stadt | Abw. | Rahmen +-15 % |
|---|---|---|---|---|---|
| **A** (W 0,6/0,25/0,15), Hoechstversorgung (G=1, P=1, J=1, W=1,0) | 12 min | 0 % | 81 min | +1,3 % | **ja** |
| A, gut abgedeckt (G=1, P=0,7, J=0,6, W=0,87) | 12 min | 0 % | 81 min | +1,3 % | **ja** |
| A, Gueter + Bus im Zentrum (P=0,4, J=0,2, W=0,73) | 45 min | +275 % | 323 min | +304 % | nein |
| A, nur Gueter (P=0, J=0, W=0,60) | 45 min | +275 % | 323 min | +304 % | nein |
| **B** Personen nur als Bonus (Basis 1,8 %/Monat, bis +25 %), Hoechstversorgung | 11 min | -8 % | 72 min | -10 % | ja |
| B, gut abgedeckt | 11 min | -8 % | 78 min | -3 % | ja |
| B, Gueter + Bus im Zentrum | 12 min | 0 % | 84 min | +5 % | ja |
| B, nur Gueter | 13 min | +8 % | 90 min | +13 % | ja |

**Akzeptanzkriterium (Zeitreihe, Abweichung <= 15 %): erfuellt fuer Variante A im Hoechstversorgungs- und im Zielzustand "gut abgedeckt" (0 % / 1,3 %), nicht fuer andere Spielertypen.** Die Zielzeiten 12 und 80 min folgen direkt aus +2 %/Monat (ln(1,25)/ln(1,02) = 11,3, ln(5)/ln(1,02) = 81,3), sind also in A die Rate bei W >= 0,8 und nichts anderes; die Rechnung bestaetigt sie nur gegen Tor, Warenkorbwechsel und Versorgungsverzug.

## Befunde

1. **Klippe bei W = 0,8.** Mit G = 1 braucht A mindestens 0,25 P + 0,15 J >= 0,20 (z. B. P = 0,8 allein oder P = 0,5 und J = 0,5). Knapp darunter faellt die Rate von 2 % auf 0,5 %: P = 0,6, J = 0 gibt 45 statt 12 min (Landkarte: `t04_wachstumslandkarte.csv`). Ein reiner Gueterspieler hat W = 0,6 und kommt nie ueber +0,5 %: 45 und 323 min. Stetige Interpolation der Rate zwischen W = 0,5 und 0,8 mildert das (Variante "A-stetig", `t04_ergebnis_alle_varianten.csv`), loest den Gueterspieler aber nicht (23 / 162 min).
2. **Stufen-Tor am Dorf ist empfindlich.** Jede Minute Wartezeit am Tor bei 95 % der Schwelle kostet +8,3 % der 12-min-Zeit; die 15-%-Toleranz ist nach 1 min ueberschritten. Das zweite Tor kostet nur +1,25 %/min (Toleranz 12 min). Die Kategorie Bau muss also vor Minute 9 (950 Einwohner) zu >= 25 % geliefert werden (`t04_tor_und_anlauf.csv`).
3. **Versorgungsverzug und Anlauf spielen nur knapp unter W = 0,8 eine Rolle.** Im Zielzustand "gut abgedeckt" bleibt der Rahmen bei Anlauf der neuen Kategorie bis 10 min (+8,8 %) und bei Verzug bis 4 min; bei 8 min Verzug rutscht Dorf > Kleinstadt auf 14 min (+16,7 %).
4. **Archetypen starten nicht bei 800:** Agrar-Dorf (900 Einw.) braucht bis Kleinstadt 6 min, Bergbau (2.500) 36 min, Hafen (3.200) 23 min bis Stadt (`t04_startpunkte_archetypen.csv`). Die "12 min" gelten nur fuer einen Start bei 800.
5. **Saettigung:** F_sätt 1,0 / 0,4 / 0,1 gibt den hoechsten Ertrag genau bei 100 % Versorgung (relativ 1,00); bei 110 % 0,97, 125 % 0,88, 150 % 0,60, 200 % 0,20 (`t04_saettigung_kurve.csv`). Ueberliefern lohnt nie; das passt zur Regel "Wachstum braucht Versorgung, nicht Ueberschuss".

## Variante "Personen nur als Bonus" (Offene Frage 2, city.md)

Definition: Das Band (2 % / 0,5 % / 0 / -0,5 %) haengt nur an G; Personen und Arbeitsplaetze geben einen Zuschlag X = 0,625 P + 0,375 J (Verhaeltnis 0,25 : 0,15) bis +25 % auf die Rate. Basisrate 1,8 % statt 2 % und Bonus +25 % sind **meine Eichung** (Raster `t04_kalibrierung_variante_B.csv`): hoechster Bonus, bei dem Gueterspieler, "gut abgedeckt" und Hoechstversorgung alle innerhalb +-15 % der Zielzeiten liegen. Ungeeicht (2 %, +25 %) liegen Hoechstversorgung und "gut abgedeckt" ausserhalb (10 min, -17 %).

**Empfehlung (ein Satz):** Variante B einfuehren (Personenabdeckung als Bonus bis +25 % Wachstum, Basis 1,8 %/Monat), weil in A ein reiner Gueterspieler 45 statt 12 bzw. 323 statt 80 Minuten braucht (rund 4 x Zielzeit), in B dagegen Gueter-, Misch- und Vollversorger alle innerhalb von 15 % der Zielzeiten bleiben und Personenverkehr trotzdem einen messbaren Vorteil bringt (bis -20 %).

## Grenzen

Reine Wachstumsrechnung: Versorgung wird vorgegeben, nicht aus Lieferketten berechnet (Sprung F_sätt -> Ertrag -> Ausbau fehlt). Spielerverhalten (wann Bau geliefert wird) ist als Wartezeit parametriert, nicht gemessen. Ruf, Laerm, Verschmutzung und Platzmangel sind nicht modelliert. Kalibrierung von B passt Parameter an die Ziele an; ob +25 % sich fuer Veteranen gut anfuehlt, ist ungetestet.
