# HQ-Startwerte je Archetyp (Lieferung an Tobias, Frist 17.11.)

Lena Hoffmann · Stand: Entwurf, **Bestätigung durch Tobias und Jonas offen** · Alles hier ist Rechnung oder Setzung, nichts ist an Spielern gemessen.

**Wie diese Datei entstanden ist.** Tobias hat T-05 und T-04 mit Annahmen aus `concept/hq.md` und `city.md` gerechnet, weil meine Datei fehlte. Ich übernehme seine Neuskala nicht blind, sondern habe sie mit seinem Modell (`tobias/t05_modell.py`, unverändert importiert) nachgerechnet. Die Einkommen der ersten Kette (844 / 627 / 781 / 399 $/min) und die Soft-Lock-Befunde habe ich reproduziert. Ketten, Distanzen und Kaufpreise je Firma sind Tobias' Setzungen. Ich nutze dieselben, damit es eine Zahlenbasis gibt.

## 1. Tabelle der Startwerte

| | **Agrar** | **Hafen** | **Bergbau** | **Handelsknoten** |
|---|---|---|---|---|
| Stadt | Dorf, 900 Einw., Fluss/Ebene | Kleinstadt, 3.200 Einw., Küste | Kleinstadt, 2.500 Einw., Gebirgsrand | Stadt, 12.000 Einw., Fluss + Kreuzung |
| Bedarf Nahrung der HQ-Stadt (Einw./100) | 9 E/min | 32 E/min | 25 E/min | 120 E/min |
| Baufaktor (hq.md × Lage, wie im Modell) | 0,90 (1,0 × Ebene −10 %) | 1,20 | 1,44 (1,2 × Gebirge +20 %) | 1,50 |
| **Startkapital, Empfehlung** | **4.500 $** | **4.500 $** | **7.000 $** | **5.000 $** |
| Startkapital, **Rahmen** (Unter–Obergrenze) | 3.500 – 5.000 $ | 3.500 – 5.000 $ | 6.000 – 7.500 $ | 4.000 – 5.500 $ |
| Startindustrien (Rohstoff → Verarbeiter) | Getreidefarm → Mühle (dazu Viehhof im Radius) | Holzfäller → Sägewerk (Hafen: Export-Lizenz gratis, nur 2 Industrien) | Erzmine + Kohlemine → Stahlwerk | Viehhof → Schlachthof (dazu Forst/Sägewerk im Radius) |
| Kaufpreis Rohstoff / Verarbeiter | 1.000 / 2.000 $ | 1.000 / 2.000 $ | 1.800 / 4.000 $ | 1.200 / 2.500 $ |
| Lizenz je 30 min (im Radius, −30 %) Rohstoff / Verarb. | 70 / 140 $ | 70 / 140 $ | 126 / 280 $ | 84 / 175 $ |
| Startpaket (Straße + 2 Lkw) | 1.367 $ | 1.460 $ | 1.664 $ | 1.325 $ |
| Kettenlängen (Felder) Rohstoff→Verarb. / Verarb.→Abnehmer | 18 / 45 | 15 / 40 | 20 / 40 | 20 / 15 |
| Einkommen der ersten Kette, Stufe 1 (Rechnung) | 844 $/min | 627 $/min | 781 $/min | 399 $/min |
| **Lizenz-Zeitfenster** (Lizenzroute vorn bis Minute, Standardfall / KI teilt ab Min. 15) | 0–17 / 0–18 | 0–22 / 0–31 | 0–35 / 0–61 | 0–56 / > 120 |
| **Zielzeit bis erste Gewinnkette** (Zielwert, Annahme) | 6 min | 8 min | 10 min | 8 min |
| Wachstum der HQ-Stadt bis zur nächsten Stufe (Rechnung T-04, Variante A, Höchstversorgung) | Dorf → Kleinstadt in 6 min | Kleinstadt → Stadt in 23 min | Kleinstadt → Stadt in 36 min | schon Stadt, Großstadt ≫ 3 h |

Quellen der Zahlen: Startkapital, Preise, Startpaket, Break-even: `tobias/t05_ergebnis.md`, `t05_startkapital_neu.csv`. Einkommen: `t05_startkapital_pinch.csv`, von mir mit `t05_modell.py` reproduziert. Wachstum: `t04_startpunkte_archetypen.csv`.

## 2. Startkapital: Herleitung und Rahmen

**Formel (Tobias):** Startkapital = Kaufpreis Verarbeiter + f × Startpaket + Lizenz Rohstoff, aufgerundet auf 500 $. Empfehlung f = 1,5. Das gibt 4.500 / 4.500 / 7.000 / 5.000 $.

**Rahmen aus meiner Nachrechnung** (Kauf-Route: Verarbeiter in Minute 0 kaufen, Startpaket bauen, Modell ohne Bauzeit):

| Archetyp | Untergrenze: kleinstes getestetes Kapital mit „Linie voll ab Minute 1“ | darunter | Empfehlung (f = 1,5) | Obergrenze (f = 2,0) |
|---|---|---|---|---|
| Agrar | 3.500 $ | 3.000 $: Linie voll erst Minute 14 | 4.500 $ | 5.000 $ |
| Hafen | 3.500 $ | 3.000 $: Linie nie voll, Bargeld nach 90 min −1.600 $ (Soft-Lock) | 4.500 $ | 5.000 $ |
| Bergbau | 6.000 $ | 5.500 $: Linie voll erst Minute 4 | 7.000 $ | 7.500 $ |
| Handelsknoten | 4.000 $ | 3.500 $: Linie voll erst Minute 5 | 5.000 $ | 5.500 $ |

**Warum eine Obergrenze:** Über f = 2,0 bleibt nach 3 Lizenzen und Startpaket mehr als ein Kaufpreis ungebunden, und der Satz „3 Lizenzen oder knapp 1 Kauf“ stimmt nicht mehr. Die Obergrenze ist eine Setzung, kein Modellergebnis.

**Lesart des Satzes aus industry.md** (Tobias, Option A, von mir übernommen): „Das Startkapital deckt das Startpaket plus 3 Lizenzen mit einem Puffer von 1,2 bis 1,4 Kaufpreisen. Wer stattdessen sofort den Verarbeiter kauft, hat danach noch 0,7 bis 0,9 Startpakete.“ Das ist nachrechenbar (`t05_startkapital_neu.csv`).

**Entscheidung (Entwurf):** Ich übernehme Option A, weil sie als einzige den Satz zum Messwert macht. Die Alternative C (Satz streichen, Kapital 20–30 k $ lassen) ist akzeptabel, wenn Jonas das Casual-Gefühl höher gewichtet. Dann steuern Break-even und das Kaufangebot-Gate (Abschnitt 4) die Leiter allein.

**Ehrlicher Befund aus Tobias' Rechnung, den ich teile:** Das Startkapital taktet das Spiel kaum, denn eine laufende Kette bringt 399–844 $/min, und ein Kauf ist ab Minute 1 bezahlbar, egal ob 4.500 oder 30.000 $ am Start liegen. Option A ist keine Pacing-Entscheidung.

**Folge für die Ausgleichslogik in hq.md** („Kapital, Fahrgäste und Rohstoffnähe gleichen sich aus“): Das Kapital folgt jetzt dem Kaufpreis des Verarbeiters, nicht der Schwäche des Archetyps. Bergbau bekommt am meisten Kapital und Agrar am wenigsten, in hq.md war es umgekehrt. Der Ausgleich muss über Ausbau und Fahrgäste kommen und ist nicht belegt (Abschnitt 5).

## 3. Startindustrien

| Archetyp | Start-Kette (Gratis-Lizenz auf dem Nicht-Ziel) | Weitere im Radius (2–4 Industrien laut hq.md) | Hinweis |
|---|---|---|---|
| Agrar | Getreidefarm → Mühle → Mehl (Nahrung) | Viehhof (Fleisch als Substitut, +10 % gemischt) | Dorf-Warenkorb nur Nahrung, die Stadt selbst ist als Abnehmer zu klein (9 E/min). Tobias nimmt die Nachbar-Kleinstadt (25 E/min) als Abnehmer. |
| Hafen | Holzfäller → Sägewerk → Bretter (Bau) | Hafen-Export zum Fixpreis, 20 E/min Deckel | Tobias setzt den Export-Preis = P_gut × 40 Felder (Annahme). Nur 2 Industrien im Radius ist der Malus. |
| Bergbau | Erzmine → Stahlwerk → Stahl | Kohlemine (Input des Stahlwerks, alternativ Kraftwerk) | Das Stahlwerk braucht Erz **und** Kohle. Tobias' Modell kennt nur den Erz-Zufluss (siehe Widersprüche, Punkt 11). |
| Handelsknoten | Viehhof → Schlachthof → Fleisch (Frischegut) | Forst/Sägewerk | Hauptstärke sind 80 Fahrtwünsche/min, im T-05-Modell nicht gerechnet. |

## 4. Lizenz-Zeitfenster und Kaufwunsch

Lizenz: 10 % des Kaufpreises, im Radius −30 %, Laufzeit 30 Spielminuten, Verlängerung zum gleichen Preis, beim Kauf 50 % der gezahlten Gebühren angerechnet.

**Lizenz-Zeitfenster = Zeitraum, in dem die Lizenzroute (Cash) vor dem Kauf liegt.** Standardfall (Verarbeiter im Radius, KI aus): Agrar bis 17, Hafen bis 22, Bergbau bis 35, Handel bis 56 min (Tobias, `t05_ergebnis.md` Tabelle 2). Mit geteilter Lizenz durch die KI ab Minute 15 verlängert sich das auf 18 / 31 / 61 / > 120 min.

**Zwei Konsequenzen für L-05:**
1. In Agrar und Hafen rechnet sich der Kauf vor dem Ende der ersten Laufzeit (Minute 30), Bergbau und Handel erst später. Das L-05-Kriterium „≥ 2 von 3 äußern den Kaufwunsch vor Minute 25“ misst deshalb in Bergbau und Handel den Wunsch, nicht die Wirtschaftlichkeit. Das steht im Testprotokoll.
2. Tobias zeigt: Kaufrabatt −20 % plus 50 % Anrechnung macht „erst Lizenz, nach 30 min kaufen“ billiger als Direktkauf (0,87 × Kaufpreis statt 1,00). Ich schließe mich seiner Empfehlung an: Der Rabatt gilt nur 1 × als Belohnung für Meilenstein 5b, nicht als Dauerregel.

**Kaufangebot-Gate (Meilenstein 5b), mein Vorschlag, von Tobias offen gelassen:** Das Spiel bietet den Kauf an, wenn die lizenzierte Firma 10 Spielminuten lang profitabel beliefert wurde. Der Wert 10 ist eine Setzung. Im Paper-Test wird er getestet (siehe `paper_prototyp_plan.md`).

## 5. Zielzeit bis erste Gewinnkette

**Definition:** Zeit von „HQ gesetzt“ bis zur ersten Lieferung an einen Endabnehmer, bei der die Kette nach Fixkosten (Lkw, Lizenz) im Plus liegt. Das entspricht Meilenstein 3, in Bergbau mit der Anpassung aus Widersprüche Punkt 4.

**Werte (Zielwerte, Annahme):** Agrar 6 min, Hafen 8 min, Bergbau 10 min, Handelsknoten 8 min, Toleranz ±15 % wie bei den anderen Zielzeiten. Sie sind **nicht gerechnet**. Das Modell kennt keine Spielerzeit zum Bauen und liefert nur „Linie voll ab Minute 1“. Die Staffelung folgt dem Baufaktor (0,90 / 1,20 / 1,44 / 1,50) und der Kettenlänge, nicht einer Messung. Prüfbar werden die Werte erst im Paper-Test (nur Reihenfolge und Schritte, keine echte Bauzeit) und im Grey-Box-Prototyp (ab Januar).

**Prüfung gegen Meilenstein 7 („5.000 $/min in 35–50 min“, hq.md):** Die erste Kette bringt 399–844 $/min. 5.000 $/min entsprechen 5,9 (Agrar), 8,0 (Hafen), 6,4 (Bergbau) und 12,5 (Handel) Ketten der Stufe 1. Das T-05/T-04-Modell enthält keinen Ausbaupfad (Stufe 2–4, 2.000 / 6.000 / 15.000 $), deshalb lässt sich die Zielzeit 35–50 min nicht bestätigen. Auffällig ist die Spanne: Handel liegt bei der ersten Kette um den Faktor 2,1 unter Agrar, die Zielvorgabe „±15 % Abstand zwischen Archetypen“ hält das nicht, solange der Personenverkehr des Handelsknotens nicht gerechnet ist. **Offen, Tobias.**

## 6. Bitten und offene Fragen (mit Namen)

- **Tobias:** Startkapital-Neuskala bestätigen oder Option C wählen. Ausbaupfad Stufe 1–4 in T-04/T-05 ergänzen, damit Meilenstein 7 prüfbar wird. Bergbau mit Kohle-Input rechnen.
- **Jonas:** Casual-Gefühl bei 4.500 $ statt 30.000 $, und die Entscheidung A oder C.
- **Felix:** Kreditrahmen ab Minute 0 (mindestens 1 Lkw = 400 $) gegen Soft-Lock machbar?
- **Lena (eigene Folgearbeit):** Ausgleichslogik in `hq.md` neu begründen. Erfahrener Start (60.000 $) und HQ-Ausbau (12.000 / 30.000 $), Niederlassung (15.000 $ + 150 $/min) gegen die neue Skala prüfen. Zusammenhang siehe `widersprueche.md`.
