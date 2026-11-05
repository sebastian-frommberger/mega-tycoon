# OE-02 Vorbereitung: Was das gemessene k_eff für die Kalibrierung heißt (Tobias, 05.11.2026)

## Stand
- [M] Umlauf Farm → Mühle (505 m), Fuhrwerk 1: **300 / 471 / 741 Ticks** bei k = 1/4/8 (AT-04). k = 1 ist **produktionsbegrenzt** (20 E/min = 10 E je 300 Ticks), das Verhältnis 1,57/2,47 unterschätzt k_eff also.
- [R] Fahrzeitbasis 2 × 34 + 200 Ticks Laden/Entladen ≈ 268 Ticks → k_eff ≈ **1,76 (k = 4) / 2,76 (k = 8)**. Die „3,3“ aus tech.md ist widerlegt. Mühle → Lindenfurt (72 Felder) ist nicht gemessen.

## Folgen
1. **k_eff ist keine Konstante, sondern hängt an der Strecke** [R]: k_eff(d) = (2·T_fahrt(d)·k + T_lade) / (2·T_fahrt(d) + T_lade). Die 200 Ticks Laden/Entladen sind tempounabhängig, deshalb geht k_eff bei kurzen Strecken gegen 1 und bei langen gegen k. Gerade das ist die Exploit-Bremse: Ein globales a gleicht kurze Linien voll aus, lange nur teilweise. Ein „richtiges“ a für alle Distanzen gibt es nicht und soll es auch nicht geben (W2).
2. **Bisektionsintervall [1.000; k_eff × 1.000] (W2):** Die Obergrenze braucht eine Definition. Vorschlag: zuerst die Klammer prüfen, d. h. das Netto P50 des Plan-Bots bei a = 1.000 und bei a = k × 1.000 messen. Liegt das Ziel dazwischen, wird bisektiert. Die Obergrenze bleibt aber **das k_eff der längsten Plan-Bot-Linie (gemessen)**, weil ein höheres a das Verhältnis Kosten zu Ertrag von k = 1 wiederherstellt und damit den Exploit zurückholt (design.md §2.4).
3. **X1 entscheidet vor a:** Jeder a-Kandidat muss X1 halten (Netto je E maximal bei 40–80 Feldern, bei 150 Feldern ≤ 80 %). Ist X1 bei a = 1.000 schon rot, kalibrieren wir Fix/Kap (FZ-01) vor a.
4. **E5/E6 (AT-04, Option a/b/c)** ändern nur die Darstellung. Solange `v_nom` gleich bleibt, gilt das gemessene Umlaufmaß weiter. Ändert eine Option `v_nom`, wird M0 wiederholt.

## Messplan Loop-Bot (QT-03, mit Daniel)
**Größen je Linie und Lauf:** Umlauf (Abstand der Lieferungen, `v_runs`), Fahrticks je Richtung, Umschlag (`v_timer`), Warten (`v_lwait`), Ladung bei Abfahrt / Kapazität, E/min geliefert, Ertrag je E, F_zeit (Mehl), Kosten je E (Fahr + Fix), Netto je E und je Fuhrwerk-Minute. Je Lauf dazu: Kasse je Periode, Kredit, Bankrott j/n + Minute, Minute E-1…F2, Ereignisse 1–8, größte Lücke.

| Stufe | Was | k | Raster | n |
|---|---|---|---|---|
| M0 | k_eff(d) **fahrzeitbegrenzt**: `testlinie()`, Quelle mit vollem Bestand (Vorbefüllung im Code nicht geprüft, Felix), 1 Fuhrwerk | 1, 4, 6, 8 | d ∈ {10, 20, 40, 60, 80, 100, 150} | 1 je Zelle (deterministisch) + 1 Wiederholung, Prüfsumme gleich |
| M1 | X1 Distanz-Sweep, Mehl und Getreide, ohne Sättigung, Flotte 1…N bis Netto je E fällt | 4, 8 (6 bei D2-Rückfall) | wie M0 | wie M0 |
| M2 | X2 Umweg Pfad/Luftlinie 1,0 gegen 1,6 | 4, 8 | d = 60 | wie M0 |
| M3 | a-Bisektion: Plan-Bot auf der Welt, Ziel F2 bei Minute 25 ± 5 und Netto P50 (Min 30) k = 4 gegen 8 ± 15 % | 4, 8 | a-Schritte bis Intervall ≤ 50 ‰ [E] | 20 je Schritt; Endpunkt 300 (Wilson) |
| M4 | X3 Gegenprobe Erlenbach-Nachfrage 999 | gewähltes k | – | 20 |

**Reihenfolge:** Laufzeit von n = 20 zuerst messen (R2), dann auf n = 300 hochrechnen; bei > 6 h n = 150 und ein offenes Intervall nennen. M0 → M1/M2 → (Fix/Kap) → M3 → OE-04 (X für F2) → F2-Minute erneut prüfen (Zirkularität, OE-01 OFFEN 2). Ergebnis in `economy_proto.json` mit Messdatum, n und k. **Nicht vorab gerechnet:** a-Wert, k_eff für Lindenfurt, Netto je k.
