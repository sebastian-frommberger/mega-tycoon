# T-04 Sättigung und Stadtwachstum – Finalstand nach D4 (Tobias Brandt, 19.11.2026)

**Etikett: UNGETESTET. Prüfung im Grey-Box-Prototyp ab Januar.** Alles hier ist Rechnung (`day1-3/tobias/t04_wachstum.py`, unverändert; Kontrolllauf 19.11. mit denselben Funktionen, Zahlen unten). Keine Spielerdaten. D4 fixiert Variante B; die Zielzeiten 12/80 min folgen aus +2 %/Monat und sind durch die Rechnung nicht „bestätigt“ (Katrin, Belegprüfung 7).

## Fixierte Parameter (D4)

| Parameter | Wert | Herkunft |
|---|---|---|
| Variante | **B – Personen und Arbeitsplätze nur als Zuschlag** | D4 |
| Basisrate | **1,8 % je Spielmonat** (1 Monat = 1 Spielminute, Annahme aus city.md) | Eichung T-04, von Lena bestätigt |
| Band (nur Warenversorgung G, Mittel der Kategorien) | G ≥ 0,8: Basisrate · 0,5–0,8: ¼ Basisrate (0,45 %) · 0,3–0,5: 0 · < 0,3: −¼ Basisrate (−0,45 %) | city.md-Schwellen, Rate skaliert |
| Zuschlag | Rate × (1 + 0,25 × X), X = 0,625 × P + 0,375 × J, nur bei positivem Band; **maximal +25 %** | Gewichtsverhältnis 0,25 : 0,15 aus city.md |
| Stufen-Tor | bei 95 % der nächsten Schwelle Halt, bis die neue Kategorie ≥ 25 % versorgt ist. **Agrar-Start: Tor für „Bau“ erst beim Übergang Kleinstadt → Stadt; HQ-Karte garantiert eine Bau-Rohstoffquelle im Radius** | city.md; D13 |
| +0,5 %/Monat bei Fabrik im Pendlerradius (industry.md) | **gestrichen.** Arbeitsplätze wirken nur über J in X | D4 (Doppelzählung, Widersprüche 13) |
| Sättigung F_sätt | 1,0 bis 100 % · linear auf 0,4 bei 150 % · 0,1 darüber | tobias.md, unverändert |

Für Variante A (W = 0,6 G + 0,25 P + 0,15 J) bleibt nur die Dokumentation in `day1-3/tobias/t04_ergebnis.md`; sie ist nicht mehr Referenz.

## Kontrollrechnung mit den fixierten Werten (Start 800 Einw.)

| Spielertyp | Dorf → Kleinstadt (Ziel 12) | Kleinstadt → Stadt (Ziel 80) | im Rahmen ±15 % |
|---|---|---|---|
| Höchstversorgung (G=1, P=1, J=1) | 11 min | 72 min | ja |
| gut abgedeckt (G=1, P=0,7, J=0,6) | 11 min | 78 min | ja |
| Güter + Bus im Zentrum (P=0,4, J=0,2) | 12 min | 84 min | ja |
| nur Güter (P=0, J=0) | 13 min | 90 min | ja (+12,5 %, 2,5 Punkte unter der Grenze) |

Agrar-Start bei 900 Einwohnern ohne Dorf-Tor (D13): Dorf → Kleinstadt in 5–6 min, Kleinstadt → Stadt 73–91 min je nach Spielertyp. Zum Vergleich mit dem alten Tor und 3 min Wartezeit: 8–9 min. D13 nimmt also 3 Minuten Tor-Risiko aus dem Agrar-Onboarding, aber **erst die Grey-Box zeigt, ob jemand in 6 Minuten überhaupt eine Kette baut** (Lenas Zielzeit Agrar: 6 min, Setzung).

## Was weiterhin offen ist (nicht T-04, PO/GDD)

- Reiner Personenspieler: Stadt wächst in B ohne Warenversorgung nicht (G < 0,3 → −0,45 %/Monat). Entscheidung Jonas bis GDD.
- Ob +25 % für Veteranen spürbar genug ist: ungetestet, Grey-Box.
- Aylin: Stadt-Panel-Zeile muss den Zuschlag nennen („+1,8 %/Monat, Nahrung 95 %, Bau 70 %, +12 % durch Bus und Arbeitsplätze“).

## Akzeptanzkriterium

Zeitreihe mit ≤ 15 % Abweichung: **ja für Variante B in allen vier Spielertypen (Rechnung, geeicht)**, als CSV (`day1-3/tobias/t04_zeitreihe_B_*.csv`), kein Google Sheet. „Personen nur als Bonus“ gerechnet und durch D4 entschieden. Kein Messwert, kein Gate-Kriterium.
