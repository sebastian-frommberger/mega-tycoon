# Decision Record DR-T05-01: "3 Lizenzen oder knapp 1 Kauf" gegen Startkapital 15.000-30.000 $ und Kaufpreise 1.000-4.000 $ x Stufe

Autor: Tobias Brandt · Status: **Vorschlag, Bestaetigung durch Lena (HQ-Startwerte, L-05) und Jonas (Casual-Start) steht aus, Termin 19.11.** · Grundlage: `t05_modell.py`, `t05_optionen.csv`, `t05_startkapital_neu.csv`. Alle Zahlen sind Modellrechnungen mit den Annahmen aus `t05_ergebnis.md`. Die HQ-Werte stammen aus `concept/hq.md` (Annahme, Lenas Dateien lagen nicht vor).

## Kontext: der Widerspruch in Zahlen

`industry.md` sagt: "Das Startkapital reicht fuer 3 Lizenzen oder knapp 1 Kauf." Gerechnet mit den festen Regeln (Lizenz 10 % des Kaufpreises je 30 min, im Radius -30 %):

| Groesse | Agrar | Hafen | Bergbau | Handel |
|---|---|---|---|---|
| Kaufpreis Verarbeiter (Annahme innerhalb 1.000-4.000 $) | 2.000 $ | 2.000 $ | 4.000 $ | 2.500 $ |
| 3 Lizenzen (Rohstoff + 2 x Verarbeiterpreis) | 350 $ | 350 $ | 686 $ | 434 $ |
| 3 Lizenzen in Kaeufen | 0,18 | 0,18 | 0,17 | 0,17 |
| Startkapital laut hq.md | 30.000 $ | 25.000 $ | 25.000 $ | 20.000 $ |
| Startkapital in Kaeufen des Verarbeiters | 15,0 | 12,5 | 6,3 | 8,0 |
| Startkapital in Startpaketen (Strasse + 2 Lkw, 1.325-1.664 $) | 21,9 | 17,1 | 15,0 | 15,1 |
| Startkapital in Minuten Einkommen der ersten Kette | 35,5 | 39,9 | 32,0 | 50,1 |

Der Satz ist also doppelt falsch: 3 Lizenzen kosten nur 17-18 % eines Kaufs (nicht "ein Kauf"), und das hq-Kapital reicht fuer 6-15 Kaeufe, nicht fuer "knapp einen". Damit "3 Lizenzen = 1 Kauf" stimmt, muesste jede Lizenz 33 % des Kaufpreises je Laufzeit kosten (statt 7 % im Radius, 10 % ausserhalb). Das widerspricht dem festen Wert 10 %.

## Optionen

| | Startkapital | Kaufpreis Verarb. | Startkapital in Kaeufen | Startkapital in min Einkommen | Break-even Kauf vs. Lizenz (min, Standardfall F1) | Ausbau Stufe 2 (2.000 $) in Kaufpreisen | Auffaelligkeit |
|---|---|---|---|---|---|---|---|
| **A** Startkapital senken (Vorschlag) | 4.500 / 4.500 / 7.000 / 5.000 $ | 2.000-4.000 $ | 1,75-2,25 | 5,3-12,5 | 17 / 22 / 35 / 56 | 0,5-1,0 | Rest nach Direktkauf + Startpaket 1.040-1.336 $ (0,7-0,9 Startpakete) |
| **B** Kaufpreise x6, hq-Kapital | 20.000-30.000 $ | 12.000-24.000 $ | 1,04-2,5 | 32-50 | 83 / 99 / 151 / 199 | 0,08-0,17 | Bergbau: Kauf (24.000 $) + Startpaket mit 25.000 $ nicht bezahlbar, Linie nie voll |
| **C** nichts aendern, Satz streichen | 20.000-30.000 $ | 2.000-4.000 $ | 6,3-15 | 32-50 | 17 / 22 / 35 / 56 | 0,5-1,0 | Kauf + Ausbau + zweite Firma in Minute 1 bezahlbar |

## Entscheidung (Vorschlag): Option A

**Startkapital = Kaufpreis Verarbeiter + 1,5 x Startpaket + Lizenz Rohstoff, aufgerundet auf 500 $:** Agrar 4.500 $, Hafen 4.500 $, Bergbau 7.000 $, Handel 5.000 $ (statt 30.000 / 25.000 / 25.000 / 20.000 $). Kaufpreise 1.000-4.000 $ x Stufe, Lizenz 10 %, Anrechnung 50 %, Werksmarge 15 % bleiben unveraendert.

**Neuer Satz fuer industry.md/hq.md:** "Das Startkapital deckt das Startpaket (Strasse + 2 Lkw) plus 3 Lizenzen mit einem Puffer von 1,2-1,4 Kaufpreisen. Wer stattdessen sofort den Verarbeiter kauft, hat danach noch 0,7-0,9 Startpakete." Beides ist messbar (`t05_startkapital_neu.csv`).

## Begruendung

1. **Nur A macht die Ladder-Aussage zum Messwert.** Mit A bleiben nach Startpaket und 3 Lizenzen 1,16-1,39 Kaufpreise uebrig, nach Direktkauf des Verarbeiters 0,71-0,89 Startpakete. In C und B stimmt kein Teil des Satzes (siehe Kontexttabelle).
2. **B zerstoert die Besitz-Stufe.** Bei Kaufpreis x6 liegt der Break-even bei 83-199 min, also hinter Meilenstein 7 (35-50 min). "Veteranen kaufen frueh, weil die Werksmarge Zinseszins ist" waere falsch. Zusaetzlich wird der Ausbau auf Stufe 2 (2.000 $) mit 8-17 % eines Kaufpreises billiger als jeder Kauf, und Bergbau laeuft bei hq-Kapital in einen Soft-Lock.
3. **C laesst 32-50 Minuten Einkommen ungenutzt liegen.** Kauf, Ausbau und zweite Firma sind in Minute 1 bezahlbar; der Kontostand setzt dann keine Reihenfolge mehr.
4. **A ist nicht zu knapp.** Das Startpaket hat 50 % Marge (1,5 x). In der Kauf-Route laeuft die Linie ab Minute 1, ohne Soft-Lock (`C_kein_softlock_K0 = 1` fuer alle vier). Knappere Werte (K_V + 0,6 x Startpaket) erzeugen in 2 von 4 Archetypen einen Soft-Lock (Hafen -1.600 $, Bergbau -1.916 $ Bargeld nach 90 min, `t05_softlock_test.csv`).

## Ehrliche Einschraenkungen

- **Der Kontostand taktet das Tempo kaum.** Eine laufende Stufe-1-Kette bringt 437-959 $/min. In allen drei Optionen ist ein Kauf ab Minute 1 bezahlbar. Option A ist keine Pacing-Entscheidung, sondern macht die Aussage wahr und vermeidet Leerlaufkapital. Wenn Lena oder Jonas das Kapital aus Casual-Gruenden hoch halten wollen, ist C akzeptabel (Folge: Satz streichen und Leiter allein ueber Break-even und das Kaufangebot-Gate M5b steuern).
- **Archetyp-Reihenfolge dreht sich:** hq.md gibt Agrar das meiste Kapital, aus der Rechnung hat Bergbau den hoechsten Bedarf (teuerstes Stahlwerk). Lenas Ausgleichslogik ("Kapital gleicht Fahrgaeste aus") muss neu begruendet werden.
- Die Kaufpreisbasis je Firma ist meine Setzung. Aendert sie sich um +-30 %, aendert sich das Startkapital proportional (Formel in `derive_C_neu`).
- "Kaufwunsch vor Minute 25" (L-05) wird vom Kontostand nicht erzeugt (Kauf ab Minute 1 bezahlbar), sondern vom angezeigten Mehrertrag (Verarbeiter 44-120 $/min = 11-15 % der Linie) und vom Angebots-Gate.

## Folgeentscheidungen (Empfehlung)

1. **Kaufrabatt -20 % nicht als Dauerregel** (nur 1 x als Belohnung M5b, wie hq.md bereits formuliert). Sonst ist "Lizenz, nach 30 min kaufen" mit 0,87 x Kaufpreis billiger als Direktkauf (ohne Rabatt 1,07).
2. **Kreditrahmen ab Minute 0** (mindestens 1 Lkw = 400 $), damit kein Soft-Lock entsteht.
3. **Kaufangebot-Gate** festlegen (Lena, M5b): z. B. nach 10 min profitabler Belieferung. Offen, nicht von mir entschieden.
4. **Erfahrener Start (60.000 $)** und hq-Preise fuer HQ-Ausbau (12.000 / 30.000 $) gegen die neue Skala pruefen (Lena).
