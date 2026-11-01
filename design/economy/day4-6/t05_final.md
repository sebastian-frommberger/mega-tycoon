# T-05 Startkapital und Lizenz/Kauf-Leiter – Finalstand nach D1 (Tobias Brandt, 19.11.2026)

Modellrechnung, keine Spielerdaten. Skript `t05_final_modell.py` (deterministisch), Tabellen `t05_final_*.csv`, Lauf `run_t05_final.log`. Nachfolger von `day1-3/tobias/t05_ergebnis.md` und `t05_decision_record.md` (unverändert gelassen). Eingaben jetzt: Lenas `day1-3/lena/hq_startwerte.md` (Tabelle 1, Rahmen), D1, D12, D13.

## 1. Gegenrechnung: Lenas Werte gegen meine Annahmen aus Tag 1–3

Vorweg, ehrlich: Lena hat mein Modell unverändert importiert und meine Setzungen (Ketten, Distanzen, Kaufpreise, Abnehmer) übernommen. Die Übereinstimmung der Zahlen ist deshalb **keine zweite Quelle** (Katrin, Belegprüfung 6). Gegengerechnet habe ich, was bei ihr **anders** steht als bei mir:

| Punkt | Meine Annahme Tag 1–3 | Lena | Wirkung in der Rechnung | Stand |
|---|---|---|---|---|
| Startkapital | 4.500 / 4.500 / 7.000 / 5.000 $ (Formel K_V + 1,5 S0 + L_R) | gleich, plus **Rahmen** 3.500–5.000 / 3.500–5.000 / 6.000–7.500 / 4.000–5.500 $ | Empfehlung bestätigt (D1). Rahmen geprüft, siehe 3. | übernommen |
| Bergbau-Kette | nur Erz → Stahlwerk | **Erz + Kohle** → Stahlwerk (Widersprüche 11) | Startpaket 2.280 statt 1.664 $ (3 Lkw, 55 Felder Straße), dritte bezahlte Lizenz Kohlemine 84 $/30 min (ANNAHME Kaufpreis 1.200 $, 15 Felder, 1:1). Einkommen 806 statt 781 $/min (Kohle-Transport bringt mehr als die Lkw kosten). Break-even Stahlwerk unverändert 35 min. **Formel ergibt jetzt 8.000 statt 7.000 $.** Mit 7.000 $ läuft die Kauf-Route trotzdem ab Minute 1 (Rest 720 $). | 7.000 $ bleibt (D1), Untergrenze siehe 3 |
| Abnehmer Bergbau | Werkzeugfabrik, 40 E/min | gleiche Annahme, als Annahme markiert | keine | D13: M3 = „an Abnehmer geliefert (Stadt, Export, nächste Stufe)“ deckt das; **Annahme bleibt markiert** |
| Hafen | Export-Deckel 20 E/min, Preis P × 40 Felder | gleich, dazu „nur 2 Industrien im Radius“ und Export-Lizenz gratis | keine (Modell kennt nur die Kette) | Export-Lizenz-Preis nicht modelliert |
| Handel | Fahrgäste nicht gerechnet | gleich, benennt 80 Fahrtwünsche/min als Hauptstärke | Handel bleibt mit 399 $/min die schwächste Kette; Spanne 2,1× zu Agrar | offen, nicht im Sprint (D1: Geld/Nachfrage nicht im Sprint) |
| Drei Lizenzen | R + 2 × V (ohne Gratis), 350–686 $ | 3 bezahlte als Bedingung, Gratis zusätzlich (Widersprüche 18) | Bergbau jetzt R + R2 + V = 490 $. Rest nach Startpaket + 3 Lizenzen in Kaufpreisen: 1,39 / 1,34 / **1,06** / 1,30. | Satz anpassen, siehe 2 |
| Gratis-Lizenz | eine Nicht-Ziel-Firma | gleich | keine | – |
| Zielzeit erste Gewinnkette | nicht gesetzt | 6 / 8 / 10 / 8 min, Setzung | nicht prüfbar, Modell hat keine Bauzeit | Lenas Setzung, bleibt so |
| Agrar-Abnehmer | Nachbar-Kleinstadt 25 E/min | gleich, Dorf (9 E/min) zu klein | F5 (nur 9 E/min) ist deshalb das „Dorf-allein“-Szenario | – |
| Kaufrabatt −20 % | Dauerregel als Variante geprüft | nur einmalig (M5b) | D1 bestätigt einmalig. Mit Rabatt und 1 Periode: 0,835 × Kaufpreis, ohne Rabatt 1,035 × (`t05_final_rabatt.csv`). | fixiert |
| Kreditrahmen | Empfehlung „mind. 1 Lkw“ | Empfehlung an Felix | D1: ab Minute 0. Regel in `antwort_felix_kredit.md`, Prüfung in 3. | Vorschlag 2.000 $ |

**Abweichungen zu Tag 1–3 in einem Satz:** Bergbau braucht mit Kohle ein größeres Startpaket (2.280 $) und eine dritte Lizenz; die Formel würde 8.000 $ ergeben, D1 setzt 7.000 $, das reicht knapp (Rest nach Kauf + Startpaket 720 $, 0,3 Startpakete statt 0,7–0,9 bei den anderen). Alle anderen Zahlen sind identisch, weil Lena meine Setzungen übernommen hat.

## 2. Finale Tabelle (Option A, D1)

| Archetyp | Startkapital | Kaufpreis Rohstoff / Verarb. | Lizenz je 30 min R / (R2) / V | 3 Lizenzen | Startpaket | Rest nach Kauf V + Startpaket | Rest nach Startpaket + 3 Lizenzen (in Kaufpreisen) | Einkommen erste Kette |
|---|---|---|---|---|---|---|---|---|
| Agrar | 4.500 $ | 1.000 / 2.000 $ | 70 / – / 140 $ | 350 $ | 1.367 $ (2 Lkw) | 1.133 $ | 2.783 $ (1,39) | 844 $/min |
| Hafen | 4.500 $ | 1.000 / 2.000 $ | 70 / – / 140 $ | 350 $ | 1.460 $ (2 Lkw) | 1.040 $ | 2.690 $ (1,34) | 627 $/min |
| Bergbau | 7.000 $ | 1.800 (Erz), 1.200 (Kohle, ANNAHME) / 4.000 $ | 126 / 84 / 280 $ | 490 $ | 2.280 $ (3 Lkw) | 720 $ | 4.230 $ (1,06) | 806 $/min |
| Handel | 5.000 $ | 1.200 / 2.500 $ | 84 / – / 175 $ | 434 $ | 1.325 $ (2 Lkw) | 1.175 $ | 3.241 $ (1,30) | 399 $/min |

**Neuer Satz für industry.md/hq.md (angepasst):** „Das Startkapital deckt das Startpaket (Straße + 2–3 Lkw) plus 3 Lizenzen mit einem Puffer von **1,1–1,4** Kaufpreisen. Wer stattdessen sofort den Verarbeiter kauft, hat danach noch **0,3–0,9** Startpakete; ein Kreditrahmen von 2.000 $ ab Minute 0 fängt Fehlplanung ab.“

### Break-even Lizenz vs. Kauf (Kapital unbegrenzt, `t05_final_breakeven.csv`)

| Archetyp | F1 Verarb. Standard | F2 KI teilt ab 15 | F3 außerhalb Radius | F4 Rohstoff-Firma | F5 kleiner Markt | Lizenzroute > 30 min vorn |
|---|---|---|---|---|---|---|
| Agrar | 17 | 18 | 22 | >120 | >120 | **F4, F5** (nur Rohstoff/Kleinmarkt) |
| Hafen | 22 | 31 | 28 | >120 | 61 | F2, F4, F5 |
| Bergbau | 35 | 61 | 44 | >120 | >120 | alle |
| Handel | 56 | >120 | 62 | 91 | >120 | alle |

Gate-Teil (R) von G5: **4/4 Archetypen** mit ≥ 1 Startfall, in dem die Lizenzroute vorn liegt. Unverändert gilt Katrins Einwand: Bei Agrar tragen nur F4 (Getreidefarm) und F5 (Dorf-Markt) das Ergebnis; beim Verarbeiter im Standardfall liegt der Kauf nach 17 min vorn. Das steht so im Gate-Protokoll (siehe `g5_bestaetigung.md`).

## 3. Lenas Rahmen und der Kreditrahmen (`t05_final_kredit_test.csv`)

Kauf-Route (Verarbeiter in Minute 0 kaufen, dann Startpaket), ohne Bauzeit:

| Archetyp | Empfehlung | Untergrenze (Lena) ohne Kredit | Untergrenze mit Kredit 2.000 $ / 1 %/min | knapp (K_V + 0,6 S0) ohne Kredit | knapp mit Kredit |
|---|---|---|---|---|---|
| Agrar | 4.500: Linie voll min 1 | 3.500: min 1 | min 1, 0 $ gezogen | 3.000: min 14 | min 1, 367 $ gezogen, 4 $ Zins |
| Hafen | 4.500: min 1 | 3.500: min 1 | min 1, 0 $ | 3.000: **Soft-Lock** (−1.600 $ nach 90 min) | min 1, 460 $, 5 $ Zins |
| Bergbau (mit Kohle) | 7.000: min 1 | 6.000: **min 6** (Kauf + Startpaket 6.280 $ > 6.000) | min 1, 364 $, 4 $ Zins | 5.500: **Soft-Lock** (−1.884 $) | min 1, 864 $, 9 $ Zins |
| Handel | 5.000: min 1 | 4.000: min 1 | min 1, 0 $ | 3.500: min 5 | min 1, 325 $, 3 $ Zins |

Befund: Mit Kohle hält Lenas Bergbau-Untergrenze 6.000 $ das Kriterium „Linie voll ab Minute 1“ nicht mehr ohne Kredit (Minute 6). Mit Kreditrahmen 2.000 $ verschwindet jeder Soft-Lock im Raster, der Kredit ist in Minute 1 zurückgezahlt (Einkommen 400–850 $/min), Zinsen 3–9 $ gesamt. **Empfehlung: Bergbau-Untergrenze auf 6.500 $ anheben oder den Kreditrahmen als Pflichtregel führen; beides ist Lenas Entscheidung für die Karten.** Der Rahmen selbst steht nicht im Modell der ersten Minute, sondern schützt vor Fehlplanung (Umweg, zweite Linie zu früh).

## 4. Decision Record DR-T05-01 – aktualisiert

- **Status:** bestätigt durch **D1 (Jonas, 19.11., 10:30)** als Testannahme für L-05, **revidierbar nach L-05 am 25.11.** Rückfall bleibt Option C (Satz streichen, 20–30 k $).
- **Entscheidung:** Option A, Startkapital 4.500 / 4.500 / 7.000 / 5.000 $. Kaufpreise 1.000–4.000 $ × Stufe, Lizenz 10 % je 30 Spielminuten (Laufzeit in Spielminuten, D1), −30 % im Radius, 50 % Anrechnung, Werksmarge 15 % unverändert.
- **Folgeentscheidungen (jetzt entschieden, D1):** Kaufrabatt −20 % **nur einmalig** bei M5b. **Kreditrahmen ab Minute 0** (Regel: `antwort_felix_kredit.md`, kein Sprintcode). 60-k-Skala und HQ-Ausbau: M1. Leitplanke (D12): Start mit HQ und Lizenzen, Firmenkauf ab M5b.
- **Neu seit Tag 1–3:** Bergbau mit Kohle-Zufluss; Startpaket 2.280 $, Formel ergäbe 8.000 $, 7.000 $ bleibt mit Hinweis „knappster Archetyp, 0,3 Startpakete Rest nach Direktkauf“. Werkzeugfabrik als Bergbau-Abnehmer bleibt **Annahme** (D13 deckt die Lesart, nicht die Zahl 40 E/min).
- **Ehrliche Einschränkungen (unverändert):** Der Kontostand taktet das Tempo kaum (Kauf ab Minute 1 bezahlbar); A macht nur den Satz messbar. 4/4 im Gate stützt sich bei Agrar auf Rohstoff-/Kleinmarkt-Fälle. Preisbasen, KI-Anteil 40 %, Schwelle „> 30 min“, Kohle-Parameter sind Setzungen. Spielerzeit zum Bauen, Fahrgäste, Lager, Zug fehlen. Nichts hiervon ist an Spielern gemessen; die Trennschärfe liefert erst L-05 (Kaufwunsch vor Minute 25).

## 5. Offen

- **Lena:** Bergbau-Untergrenze (6.000 → 6.500 $?) oder Kreditrahmen auf die Karte; Kohlemine als dritte Lizenz auf der Bergbau-Karte; Lesart Werksmarge (Widersprüche 9) bleibt „Zuschlag auf eigenen Transportertrag“.
- **Jonas:** Formel-Abweichung Bergbau (8.000 vs. 7.000 $) zur Kenntnis; keine Änderung von D1 nötig.
- **Felix:** Antwort Kreditrahmen in `antwort_felix_kredit.md` (20.11.).
