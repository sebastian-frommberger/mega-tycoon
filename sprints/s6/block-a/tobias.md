# T-14 Tobias Brandt, Sprint 6 (Modellrechnung, Verhalten und Karte sind Setzungen)

Skripte in `tobias/`: `t14_run.py` (Hauptlauf), `t14_marge.py`, `t14_dominanz.py`, `t14_zug.py` (auf t13_sim.py aus S5). Logs in `tobias/belege/`. Daten: `tobias/daten_basis/` (S5-Freeze-JSON mit credit_step_cent). Keine Godot-Dateien und kein Repo angefasst.

## 1. Werte-Tabelle (final, wartet nur auf Sophies echte Karte)
| Wert | Alt | Neu |
|---|---|---|
| Startkapital, alle Standorte | 4.500 / 5.000 / 7.000 $ je Archetyp | 6.000 $ = 600000 Cent |
| Lok-Fixkosten | 300 $/min | 90 $/min = 9000 Cent/Periode |
| Gratis-Startlkw | 2 (agrar) / 3 (bergbau) | 2 für alle (siehe Annahme 3) |

### JSON-Diff (exakte Keys)
`economy_slice.json`
- `hq.start_capital_cent` NEU = 600000
- `hq.start_capital_agrar_cent`, `start_capital_mining_cent`, `start_capital_port_cent`, `start_capital_trade_cent`, `start_capital_floor_mining_cent` ENTFALLEN
- `hq.archetyp_agrar_im_slice_flag`, `archetyp_mining_im_slice_flag`, `archetyp_port_im_slice_flag`, `archetyp_trade_im_slice_flag` ENTFALLEN (D22, kein Archetyp)
- `meta.archetypen_im_slice_ids` ENTFALLEN
- `fahrzeug_ref.startpaket_lkw_anzahl` NEU = 2; `startpaket_lkw_agrar_anzahl`, `startpaket_lkw_mining_anzahl` ENTFALLEN
- `meta.freeze_stand_text` neu schreiben (T-12 v1.1 plus T-14), Aenderung nur mit Ticket

`economy_constants.json`
- `startkapital_cent` von Objekt {agrar, hafen, bergbau, handelsknoten} zu Zahl = 600000 (Gegenprobe `_same("hq.start_capital_cent", "startkapital_cent")` in economy.gd:256/257 anpassen, Felix)

`vehicles.json`
- `fahrzeuge[id=lok_e1].fix_cent_pro_periode` 30000 -> 9000 (Lkw bleibt 9000, Waggon 0)

Schlüssel-Name `hq.start_capital_cent` ist mein Vorschlag nach Konvention (Cent-Suffix); Felix passt den Code-Key an, falls er anders heisst.

## 2. Ergebnisse je Standort (6.000 $, Kredit-Mix 35/45/15/5, Pfade Lizenz/Lager-Hub, 300 Läufe, Paket: Dorf x2, Werkzeugfabrik 40, Mühle Mittelfurt 45)
| Standort | Bankrott Min 30 (Seeds 1-300 / 301-600) | M7 Median (Quartile) | Ziel 10-30 % | M7 35-50 ±15 % (29,8-57,5) |
|---|---|---|---|---|
| Mittelfurt | 13,7 % / 15,0 % | 51 min (45-61) | ja | ja |
| Haberau | 10,7 % / 13,3 % | 49 min (43-60) | ja, knapp am unteren Rand | ja |
| Kohlberg | 12,0 % / 14,0 % | 33 min (23-49) | ja | ja, nur im Toleranzband (unter 35); zweiter Block 30 min |

Alle 900 Läufe: 12,1 % (Block 2: 14,1 %). Ohne Paket (Karte Ist): Haberau 19 % / 76 min, Kohlberg 32 % / 14 min, Mittelfurt 13 % / 59 min, also ohne S-12 nicht im Ziel.

Mühle Mittelfurt auf 44 (Lena L-12, Radius inklusive): Bankrott 14,0 %, M7 51 min, Kasse Min 30 7.050 $. Praktisch gleich wie 45, 40-55 Felder bewegen M7 nur 48-54 min.

Toleranz gegen Sophies Verschiebung (`belege/t14_log_marge.txt`): Werkzeugfabrik 35/40/45/50 F.: M7 37/33/29/28 min, Bankrott 10-12 %. Bei 45 oder mehr fällt Kohlberg unter das Toleranzband (29,8). Obergrenze: ≤ 42 Felder. Dorf-Nachfrage x1,5/x2/x2,5: M7 57/49/45, Bankrott 13,7/10,7/10,3 %. Bei x1,5 ist der Rand erreicht.

Kapital-Sensitivität (5.000 / 6.000 / 7.000 $, Bankrott / M7): Haberau 12/11/7 % / 52/49/45; Kohlberg 15/12/9 % / 34/33/31; Mittelfurt 22/14/11 % / 55/51/47. 6.000 $ liegt für alle drei im Band, 7.000 $ würde Haberau unter 10 % drücken.

Zug (Lok-Fix 90 $/min, `belege/t14_log_zug.txt`): Break-even bei 25 Feldern F* = 33 E/min (H=60), 26 bei 40 F., 21 bei 60 F. Ziel "≤ 33 bei 25 Feldern" erreicht, auf der Grenze. Bei Abschreibung über 30 statt 60 min liegt F* bei 51 (Randbedingung, siehe Annahmen). Bei 20 E/min bleibt der Lkw billiger, der Zug lohnt erst ab ca. 33 E/min, also mit 2+ Quellen.

Dominanz Haberau x2 (Lena, `belege/t14_log_dominanz.txt`): nicht dominant. Haberau: Bankrott 10,7 %, M7 49 min, Gewinn Min 60 Median 13.966 $. Mittelfurt (44): 14,0 %, 51 min, 13.217 $. Gleiche Seeds: Haberau ist nur in 55 % der Läufe früher bei M7 als Mittelfurt, praktisch Gleichstand. Kohlberg (40) ist in 80 % der Läufe schneller (M7 33 min, Gewinn 22.863 $), aber das ist der gewollte Bergbau-Kernpfad mit Stahlkette und höherer Fabrikinvestition. Haberau mit Absatz nach Mittelfurt (150 F.) ist der stärkste Haberau-Pfad (Gewinn 22.624 $, M7 39 min), kostet aber 27,7 % Bankrott, also Risiko gegen Ertrag, kein Gratis-Vorteil.

## 3. Satz für Lena
"Balanciert und mit 300 Läufen gemessen sind nur Mittelfurt, Haberau und Kohlberg; die übrigen fünf Standorte (u. a. Seehafen und Weidenau) sind im Slice nicht balanciert, 6.000 $ gilt trotzdem für alle."

## 4. Annahmen und Befunde
1. Karte: Luftlinie wie in S5 plus Sophies Paketwerte; Sim-Strecken streuen ±25 % je Lauf. Sobald T-14b die echten Werte aus der eingefrorenen Karte liefert (Tag 4), Lauf wiederholen (`python3 -I t14_run.py`, ca. 2 min).
2. Kredit-Verhalten (nie 35 / bei Bedarf 45 / voll 15 / Hebel 5 %), Spielertypen und Pfade Lizenz/Lager-Hub: Setzungen aus T-13, Firmenkauf R1-frei. Ein Basti-Playtest fehlt.
3. Archetyp-Rest im JSON: Der Gratis-Startlkw hängt noch am Archetyp (2/3). Test: 2 für alle ergibt Bankrott 10,7 / 12,7 / 13,7 % (Haberau/Kohlberg/Mittelfurt), 3 für alle 8,3 / 12,0 / 12,0 %, also Haberau unter 10 %. Daher 2.
4. Die Slice-Kopie `economy_slice.json` und `economy_constants.json` in `slice/data` hat `credit_step_cent` (bzw. `kredit.schritt_cent`) nicht, S5 hatte ihn im t06/data-Freeze. Credit.gd hat 500 $ hartcodiert (`STEP_CENT`). Meine Läufe nutzen 500 $. Felix prüfen, ob das Freeze-JSON oder die Kopie gilt.
5. Haberau liegt am unteren Bandrand (10,7 %); Kohlberg M7 am unteren Toleranzrand (33 min). Kein Standort fällt aus dem Band, kein Hebel nötig. Falls Sophie die Werkzeugfabrik weiter als 42 Felder setzt, M7 Kohlberg fällt unter 30 min; Kapital nicht erhöhen (7.000 $ gibt Haberau 7 %).
