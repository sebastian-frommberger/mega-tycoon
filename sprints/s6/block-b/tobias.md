# Tobias Brandt, Sprint 6 Block B: T-14b und T-14 Nachmessung (Modellrechnung)

## T-14b
- `tobias/slice/data/hq_vorschau.json` (8 Städte, je <= 6 Zeilen), erzeugt von `tobias/slice/tools/hq_vorschau_gen.py` (`python3 -I tools/hq_vorschau_gen.py`). Quelle: slice_map.json md5 d99eb305afc23db4832bcb7ce6c857e0 (unverändert), economy_slice.json (nur gelesen).
- Rechenregeln: Luftlinie Stadtmitte-Objekt, kaufmännisch gerundet; Holzfäller nicht lizenzpflichtig; Radius inklusiv; Nachfrage = Einwohner/100 x Stufenmult. (Dorf 2000 Promille aus JSON); Lizenzfaktor = Größenfaktor (0,90/1,00/1,20, Lenas Annahme, nicht im JSON) x (0,70 im Radius, sonst 1 + 0,03 x Felder über Radius); Terrain per Raster 0,25 Felder.
- Abweichungen gegenüber Lenas Platzhaltern:
  - Karte geändert (Werkzeug SW, Mühle 43,9): Kohlberg Werkzeugfabrik 40 statt ~40 und Absatz Mittelfurt 204 Felder; Mittelfurt Farm 43 (statt 44), Mühle 44 (statt ~45), Werkzeug 204; Steinbach 3. Eintrag Kohle 284 statt Werkzeugfabrik 140, Mühle 139 statt 133; Eichwald Lizenz x4,0 (Mühle 170) statt x2,1, nächste Mühle 170/Kohle 182/Farm 197; Weidenau x4,1 (Werkzeugfabrik 173) statt x4,7; Lindach und Weidenau, Seehafen je ein 3. Eintrag (Werkzeugfabrik).
  - Formales: Lizenz-Klammer nennt überall die nächste Industrie (Haberau Farm statt Mühle, Kohlberg Kraftwerk); Wald ab 3 % überall genannt (neu bei Haberau 8 %, Kohlberg 9 %); Steinbach Gebirge "nördlich" (Schwerpunkt) statt "Ost", Format vereinheitlicht; Seehafen Meer 33 % (Raster) statt 32 %; Trenner ";" statt ","; "(größter Absatz)" bleibt bei Mittelfurt.
  - Hinweis "Im Slice nicht balanciert." jetzt bei allen 5 unbalancierten Städten (Satz für Lena), Seehafen ohne doppeltes "Kein Rohstoff im Radius".
  - Haberau-Absatz bleibt 150 (Stadt zu Stadt; Mühle zu Mittelfurt wären 126).

## T-14 Nachmessung (6.000 $, Kredit-Mix, 300 Läufe, Seeds 1-300 / 301-600)
Skript `tobias_t14/t14b_nachmessung.py`, Log `tobias_t14/t14b_log.txt`. Eingaben: Stahl->Werkzeug 60, Mühle->Mittelfurt 43,9, Farm->Mühle 28 (Setzung wie T-14), Haberau wie T-14. Werkzeug->Mittelfurt 204 wirkt im Modell nicht (Werkzeugabsatz nicht simuliert).
| Standort | Bankrott | M7 Median (Quartile) | Urteil |
|---|---|---|---|
| Mittelfurt | 14,0 / 15,0 % | 52 / 52 min (45-62) | Bankrott ja; M7 nur Toleranzband (bis 57,5), über 50 |
| Haberau | 10,7 / 13,3 % | 49 / 48 min | ja / ja (Rand unten bei Bankrott) |
| Kohlberg | 12,0 / 14,0 % | 24 / 24 min (19-34) | Bankrott ja; M7 AUSSERHALB (Soll >= 29,8) |
- Kohlberg: Je länger Stahl->Werkzeug, desto höher der Ertrag je Einheit, desto früher M7. Sweep Stahl->Werkzeug 30/35/40/45/50/55/60: M7 43/37/33/29/28/26/24 min, Bankrott 10-12 %. Ziel 35-50 bei <= 35 Feldern, Toleranz bis <= 42.
- Mittelfurt Kontrolle mit Farm->Mühle 78 wie auf der Karte: Bankrott 19,3 %, M7 43 min, im Band.
## Empfehlung
Werkzeugfabrik näher an Stahlwerk (Kantenlänge <= 40, besser 35; z. B. nahe Kohlberg-Süd, Radius bleibt eingehalten), oder Kohlberg-M7 als Abweichung akzeptieren (Setzung durch Jonas). Kapital nicht anfassen.
