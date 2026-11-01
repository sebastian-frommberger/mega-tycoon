# Tobias – Sprint 2, Tag 1–3
(Tageseinträge ordnen die Arbeitspakete den Tagen zu; alles ist Modellrechnung.)

## Daily Tag 1 (16.11.)
Gestern: Brief, Plan, Refinement und Konzepte (hq, city, industry) gelesen. Heute: T-05-Modell gebaut (4 Archetypen, Lizenz-/Kauf-Simulation), Widerspruch in Zahlen gefasst. Blocker: Lenas HQ-Startwerte und Gewichte fehlen, Annahmen aus hq.md/city.md.

## Daily Tag 2 (17.11.)
Gestern: Modell läuft, 20 Startfälle mit Break-even. Heute: Optionen A/B/C zum Widerspruch gerechnet, Soft-Lock-Test, Decision Record. Blocker: Lenas Dateien trotz Frist heute nicht da.

## Daily Tag 3 (18.11.)
Gestern: Decision Record als Entwurf. Heute: T-04-Wachstumssimulation, Variante B kalibriert, Dokumente geschrieben. Blocker: Bestätigung von Lena und Jonas für die neue Startkapital-Skala steht aus.

## Ergebnisse
- **T-05: fertig als Vorschlag, Abnahme offen.** `tobias/t05_ergebnis.md`, `t05_decision_record.md`, `t05_*.csv`, `t05_modell.py`. Tabelle mit Break-even inkl. 50 % Anrechnung und 15 % Marge: **ja**. Startfall mit Lizenzroute vorn: **ja, 4/4** (Agrar Mühle im Kleinmarkt >120 min, Hafen 61 min, Bergbau 35 min, Handel 56 min). Widerspruch als Decision Record: **ja, aber unbestätigt**. "Zahlen am 19.11. bei Lena": **offen**.
- **T-04: fertig, Kriterium teilweise.** `t04_ergebnis.md`, `t04_wachstum.py`, `t04_zeitreihe.png`, `t04_*.csv`. Abweichung ≤15 %: **ja für Variante A bei W ≥ 0,8** (12 min / 81 min), **nein für Güterspieler** (45 / 323 min). Variante "Personen nur als Bonus" gerechnet, Empfehlung steht: ja. Zeitreihe liegt als CSV vor, nicht als Google Sheet.

Kernbefunde: Das Startkapital taktet kaum, eine Kette bringt 437–959 $/min. Kaufrabatt −20 % plus Anrechnung macht "erst Lizenz, dann Kauf" billiger als Direktkauf (0,87×). Besitz von Rohstoffbetrieben lohnt nicht.

## Annahmen und offene Fragen an andere (mit Namen)
- **Annahme:** HQ-Werte aus hq.md, Gewichte 0,6/0,25/0,15 aus city.md. Gegenprüfung am Ende: `lena/…` existiert weiterhin nicht. Weitere Annahmen: Kaufpreisbasis je Firma, Ketten/Distanzen, KI ab Minute 15, Marge auch auf eigene Fahrzeuge.
- **Lena:** Startkapital 4.500–7.000 $ statt 20–30k bestätigen? Erfahrenen Start (60k) und Archetyp-Ausgleich neu begründen. Kaufangebot-Gate M5b festlegen. Gewichte W oder Variante B entscheiden.
- **Jonas:** Passt das kleine Startkapital zum Casual-Gefühl? Fallback ist Option C (Satz streichen, Zahlen lassen).
- **Felix:** Kreditrahmen ab Minute 0 gegen Soft-Lock machbar?

## Risiko für das Sprintziel
Die Gate-Zeile "Lizenz/Kauf-Leiter konsistent" hängt an Lenas Bestätigung im Paper-Test; ohne ihre echten HQ-Werte kann sich meine Skala verschieben. Die Rechnung stützt sich auf selbst gesetzte Preisbasen und ist ungetestet gegen echte Spieler.
