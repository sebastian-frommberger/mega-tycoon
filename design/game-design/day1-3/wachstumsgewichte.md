# Wachstumsgewichte Güter / Personen / Jobs (Lieferung an Tobias, Frist 17.11.)

Lena Hoffmann · Stand: Entwurf, **Bestätigung durch Tobias und Jonas offen** · Rechnung auf Basis von `tobias/t04_ergebnis.md` und `t04_wachstum.py`, von mir mit `calc`-Skripten nachgerechnet (Ergebnisse gleich bis auf ±1 min, siehe Abschnitt 2). Keine Spielerdaten.

## 1. Frage und Empfehlung

`city.md` setzt W = 0,6 × Waren + 0,25 × Personen + 0,15 × Arbeitsplätze und fragt offen, ob das für reine Güterspieler zu strafend ist. Das Ticket T-04 verlangt Zielzeiten Dorf → Kleinstadt ≈ 12 min und Kleinstadt → Stadt ≈ 80 min mit ≤ 15 % Abweichung.

**Empfehlung (ein Satz):** Variante B einführen. Die Warenversorgung G bestimmt allein das Wachstumsband (Schwellen unverändert), Personenabdeckung P und Arbeitsplätze J geben einen Zuschlag bis +25 % auf die Rate, Basisrate 1,8 % statt 2 % pro Spielmonat. Die Gewichte bleiben im Verhältnis 0,25 : 0,15, das heißt P 62,5 % und J 37,5 % des Zuschlags.

**Die Gewichte, die ich an Tobias liefere:**

| Größe | Variante B (Empfehlung) | Variante A (Rückfall, wie `city.md`) |
|---|---|---|
| Güter (Warenversorgung G, Mittel der Kategorien) | bestimmt das Band: G ≥ 0,8 → Basisrate 1,8 %; 0,5–0,8 → ¼ der Basisrate; 0,3–0,5 → 0; < 0,3 → −¼ der Basisrate | Gewicht 0,60 |
| Personen (P) | Zuschlag-Anteil 0,625 | Gewicht 0,25 |
| Arbeitsplätze (J) | Zuschlag-Anteil 0,375 | Gewicht 0,15 |
| Zuschlag | Rate × (1 + 0,25 × X), X = 0,625 P + 0,375 J, nur wenn das Band positiv ist | entfällt |
| Stufen-Tor | unverändert: bei 95 % der nächsten Schwelle Halt, bis die neue Kategorie ≥ 25 % versorgt ist | unverändert |

## 2. Rechnung gegen die Zielzeiten

Zielzeiten 12 / 80 min, Rahmen ±15 %: erlaubt sind 10,2–13,8 min und 68–92 min. Start bei 800 Einwohnern (Dorf → Kleinstadt 800 → 1.000, Kleinstadt → Stadt 1.000 → 5.000), Wachstum multiplikativ je Monat, 1 Monat = 1 min (Annahme aus `city.md`). Werte aus Tobias' `t04_ergebnis.md`.

| Spielertyp | A: Dorf→Kleinstadt / →Stadt | B: Dorf→Kleinstadt / →Stadt | B im Rahmen? |
|---|---|---|---|
| Höchstversorgung (G=1, P=1, J=1) | 12 / 81 min | 11 / 72 min | ja |
| gut abgedeckt (G=1, P=0,7, J=0,6) | 12 / 81 min | 11 / 78 min | ja |
| Güter + Bus im Zentrum (G=1, P=0,4, J=0,2) | 45 / 323 min | 12 / 84 min | ja |
| nur Güter (G=1, P=0, J=0) | 45 / 323 min | 13 / 90 min | ja (+13 % beim zweiten Wert, 2 Punkte unter der Grenze) |

**Befund:** In A fällt ein reiner Güterspieler auf W = 0,60 und damit in das Band 0,5–0,8 (0,5 %/Monat). Er braucht rund 4 × die Zielzeit. Das ist die Klippe bei W = 0,8: Mit G = 1 braucht A mindestens 0,25 P + 0,15 J ≥ 0,20. B behebt das, weil das Band nur an G hängt.

**Eigene Nachrechnung (Kontrolle, nicht Ersatz):** Eine zweite Eichung liegt ebenfalls im Rahmen und hat mehr Abstand zur Grenze.

| Eichung | Höchst | nur Güter | größte Abweichung | Vorteil Personen (Zeit bis Stadt, nur Güter vs. Höchst) |
|---|---|---|---|---|
| Tobias: 1,8 % und +25 % | 11 / 73 min | 13 / 91 min | +13,8 % | −20 % |
| Alternativ: 1,9 % und +15 % | 11 / 75 min | 12 / 86 min | +7,5 % | −13 % |
| Ohne Zuschlag: 2,0 %, +0 % | 12 / 82 min | 12 / 82 min | +2,5 % | 0 % |

Tobias' Eichung (≤ 1 min Abweichung zu seiner Tabelle, vermutlich Rundung am Tor) lässt Personenverkehr spürbar zählen (−20 %). Die Alternative ist robuster gegen Messfehler. **Ich schlage Tobias' Eichung vor**, weil sonst der Personenverkehr als Spielelement (Leitplanken: Personen UND Güter) kaum Wirkung auf das Stadtwachstum hat. Das ist eine Setzung auf Grundlage von Zielzeiten, die selbst nur aus +2 %/Monat folgen (ln 1,25 / ln 1,02 = 11,3 min, ln 5 / ln 1,02 = 81,3 min). Die Rechnung bestätigt die Zielzeiten nur gegen Tor, Warenkorbwechsel und Verzug und prüft kein Spielgefühl.

## 3. Was daraus folgt

1. **Start der Archetypen.** Die „12 min“ gelten nur für einen Start bei 800 Einwohnern. Agrar-Dorf (900) braucht bis zur Kleinstadt 6 min, Hafen (3.200) 23 min und Bergbau (2.500) 36 min bis zur Stadt (`t04_startpunkte_archetypen.csv`, Variante A, Höchstversorgung). Für B nur Güter: Bergbau 39, Hafen 26 min.
2. **Stufen-Tor am Dorf ist empfindlich.** Bei 95 % der Schwelle wartet die Stadt, bis die neue Kategorie zu 25 % geliefert ist. Jede Minute Wartezeit am Tor kostet +8,3 % der 12-min-Zeit (T-04). **Konflikt mit dem Agrar-Start:** Der Agrar-Start hat nur Nahrung (Mehl, Fleisch) in Reichweite, das Tor für „Bau“ liegt aber schon bei 950 Einwohnern (rund Minute 3 ab 900). Ohne Bretter in Reichweite steht das Dorf. Siehe Widersprüche, Punkt 12.
3. **Doppelzählung der Arbeitsplätze.** `industry.md` gibt +0,5 %/Monat Wachstum für eine Stadt mit Fabrik im Pendlerradius (≥ 50 % Pendlerdeckung). In W steckt dieselbe Größe schon als J. **Vorschlag:** die Regel aus `industry.md` streichen, Arbeitsplätze wirken nur über X.
4. **Reiner Personenspieler.** In B wächst eine Stadt ohne Warenversorgung nicht (G < 0,3 → −¼ der Basisrate), egal wie viele Fahrgäste befördert werden. Für den Skill-Ast „Stadtverkehr“ ist das eine Entscheidung: Er verdient über Tickets, lässt die Stadt aber nicht wachsen. **Offene Frage an Jonas.**
5. **Sättigung (T-04):** F_sätt 1,0 / 0,4 / 0,1 gibt den höchsten Ertrag bei genau 100 % Versorgung. Überliefern lohnt nicht (110 %: 0,97, 150 %: 0,60, 200 %: 0,20 relativ). Das passt zu „Wachstum braucht Versorgung, nicht Überschuss“.

## 4. Grenzen

- B ist **auf die Ziele geeicht**. Das Ergebnis „alle Typen im Rahmen“ folgt aus der Eichung. Es ist keine unabhängige Bestätigung.
- Versorgung wird vorgegeben und nicht aus Lieferketten berechnet. Ruf, Lärm, Verschmutzung, Platzmangel fehlen.
- Ob +25 % sich für Veteranen gut anfühlt, ist ungetestet. Prüfbar erst im Grey-Box-Prototyp.

## 5. Bitten

- **Tobias:** Variante B mit 1,8 % / +25 % bestätigen oder die Alternative nehmen. Tor-Regel für den Agrar-Start (900 Einw.) rechnen.
- **Jonas:** Personenverkehr nur als Bonus akzeptieren? Entscheidung zum reinen Personenspieler (Punkt 4).
- **Aylin:** Das Stadt-Panel zeigt „+1,8 %/Monat, weil Nahrung 95 %, Bau 70 %“ (`city.md`). Bei B muss die Zeile auch den Zuschlag nennen („+12 % durch Bus und Arbeitsplätze“). Text liegt bei ihr.
