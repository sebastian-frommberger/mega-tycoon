# T-11 Kurzbericht Balancing-Läufe (Tobias Brandt, Stand 04.12.2026)

Modellrechnung auf `t06/data/economy_slice.json`, keine Spielerdaten. Skript `t11_modell.py` (Seeds 1–100, Exploits 1001–1010), Ausgaben `t11_laeufe.csv`, `t11_exploits.csv`, `t11_kalibrierung.csv`, Lauf `run_t11.log`. Die Spielertypen (45 sorgfältig, 41 normal, 14 hastig), Bauverzögerung, Wegfaktor, Extra-Lkw und Fehlverbindung sind **Setzungen**; die Modellspieler reagieren nicht auf Verluste. Das Ergebnis gilt nur für diese Annahmen.

## 1. Bankrott bis Minute 30 (Ziel 10–30 %): verfehlt, 7 von 100

Bankrott = Konto unter −Kreditrahmen oder 5 Minuten Konto < 0 bei Netto ≤ 0. Bis Minute 60 sind es 10. Alle 7 sind Überinvestition in Lkw (90 $/min Fixkosten je Lkw gegen 700–900 $/min Einnahmen), keiner kommt vom Startkapital.

| Schnitt | Bankrott | n |
|---|---|---|
| Agrar / Bergbau | 3 / 4 | 50 / 50 |
| Lizenz / Direktkauf / Lager-Hub | 1 / 2 / 4 | 34 / 34 / 32 |
| sorgfältig / normal / hastig | 0 / 2 / 5 | 45 / 41 / 14 |

Der Lager-Hub ist riskanter (800 $ plus Unterhalt plus zweite Quelle), bringt aber im Modell keinen Mehrgewinn: Rohstoffquellen liefern fest 20 E/min, also bleibt Stufe 2 (40 E/min) ohne dritte Quelle leer.

## 2. Exploits: keiner über 1,5× Referenzgewinn (mit Regeln)

Referenz = Median Gewinn bei Minute 30 der sorgfältigen Läufe je Archetyp (Agrar 21.636 $, Bergbau 16.172 $). Der T-07-Katalog liegt mir als Datei nicht vor, ich habe 8 Versuche aus den L-08-Regeln abgeleitet (Lücke zu den ≥ 10 aus T-07).

| Exploit | Verhältnis mit Regeln | Gegenprobe Regel aus |
|---|---|---|
| X01 Lager-Pingpong | 0,92 | **1,53** |
| X02 Umweg-Rundweg | 0,94 | **1,67** |
| X03 Stempel-Reset | 0,21 | 1,01 |
| X04 Lizenz-Hopping (Min. 60) | 0,57 / 0,51 | – |
| X05 Kauf-Verkauf | −0,05 / −0,14 (je Zyklus −1.119 / −2.239 $) | – |
| X06 Kredit-Hebel | 0,27 / −0,39 | – |
| X07 Kurzstrecken-Spam | 0,63 | – |
| X08 Sättigung auf 2 Städte | 0,91 | – |

Ohne „Ertrag nur beim Endabnehmer“ und Luftlinie wären X01 und X02 über der Grenze. Beide Regeln sind tragend. X05 bleibt auch mit dem einmaligen −20 % ein Verlust, weil Verkauf nur 42 % des Kaufpreises zurückbringt.

## 3. Kalibrierung (je 100 Läufe, `t11_kalibrierung.csv`)

| Variante | Bankrott | Median Gewinn |
|---|---|---|
| Basis | 7 % | 15.850 $ |
| Spielermix 50 % hastig | 17 % | 8.072 $ |
| Straße ×5 | 10 % | 12.540 $ |
| Startkapital ×0,6 | 11 % | 15.074 $ |
| Preise ×0,5 | 20 % | 792 $ |
| Preise ×0,5 und Kapital ×0,6 | 30 % | 1.228 $ |
| Lkw-Fixkosten ×3 | 47 % | −1.812 $ |

Vorschläge: (1) Den Zielkorridor nicht über Preise oder Lkw-Fixkosten erzwingen, beide kippen den Median-Gewinn auf null oder darunter; der Median müsste bei 15.000 $ (30 min) bleiben. (2) Grey-Box im Januar zeigt erst, wie viele Spieler überbauen: Straße ×5 oder Startkapital ×0,6 bringen 10–11 % bei fast unverändertem Gewinn und sind die schonendsten Hebel. (3) Vor der Kalibrierung klären, ob Verluste sichtbar genug sind (Warnung bei Netto < 0), sonst misst „Bankrott“ nur die UI.

## 4. Befunde zu L-08 (aus dem Modell)

- **K2 lohnt nicht:** Kohle zum Kraftwerk (20 Felder, 0,40 $) bringt weniger als Kohle im Stahlwerk (zählt für Stahl zu 1,00 $ je Feld); mit 25 % Kohle auf K2 sinkt der Umsatz im Beispiel von 886 auf 708 $/min. Der Energiebonus (+25 % Menge anteilig) gleicht das nicht aus.
- **Bau-Kategorie ohne Holz:** Die Kleinstadt braucht Nahrung und Bau, der Slice hat keine Holzkette (D18), `hq_guarantee_build_source` kann also nicht greifen. G liegt bei 0,5, das Band ¼ gilt (45 bp), Kleinstadt → Stadt braucht rechnerisch 154 min (L-08: 72–90 min).
- **Dorf → Kleinstadt:** 900 → 1.000 Einwohner dauert bei 1,8 % 5,9 min, nicht 11–13 min wie in L-08 (deckt sich mit `t04_final.md`, 5–6 min).
- **Stufe 2 der Verarbeiter** ist ohne zweite Rohstoffquelle wertlos, Rohstoffquellen-Ausbau fehlt in L-08.
