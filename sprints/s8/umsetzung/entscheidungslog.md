# Entscheidungslog Sprint 8 (PO Jonas), Annahmen bis Basti entscheidet

| Datum | Entscheidung | Grund | Revidierbar bis/durch |
|---|---|---|---|
| 05.11. | F2-Platzhalter (600 $/min) laeuft bei **Gate C (Ende Tag 12)** ab, nicht Tag 8 | ergebnis.md §6: Gate B = Tag 8, Gate C = Tag 12; Bot-Messwert Minute 30 liegt erst in Block C vor | Tobias |
| 05.11. | FZ-02 Kalender: **Welt-Loop `jahr_ticks` = 1.800 (3 min/Jahr)**, Slice bleibt 7.200. Das Ticket-Wort "Standard 7.200" gilt fuer den Slice | Sprintziel 3 min/Jahr; mit 7.200 kaeme der Frachtwagen erst bei Minute 120 und Ereignis 8 fiele aus dem Loop | Basti/Jonas, S9 |
| 05.11. | AT-04 gemergt, obwohl E5/E6 bei k=4/8 rot: Default k=1 unveraendert, Rot liegt in der Variante. Behebung in FZ-09 (TA) vor OE-02-Kalibrierung | Test E5/E6 war bisher nur bei k=1 gelaufen; Annahme "tempounabhaengig" widerlegt (AT-04.md) | Jonas nach FZ-09 |
| 05.11. | Lindenfurt `ew` bleibt 387, `ew_ort` 2.000 neu; Umstellung offen | proto_schilder_test prueft 387 + Tooltip 2.950 | Aylin/Jonas bei AT-03 |
| 05.11. | Muehle ohne Eingangspuffer-Deckel (Befund OE-01): Ereignis 7 "Puffer voll" in S8 nicht ausloesbar -> Tobias entscheidet in OE-02, ob Deckel (Tobias, economy.gd, Block B) | Befund aus Code, design.md §0.1 gilt nicht | Tobias, Gate B |
