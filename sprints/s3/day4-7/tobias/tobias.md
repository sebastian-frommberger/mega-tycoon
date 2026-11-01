# Tobias Brandt, Übersicht Tag 4–7

**T-06 Ökonomie-Datenmodell: fertig.** `t06/data/economy_slice.json` (Schema `economy_slice.schema.json`, Cent/Ticks/Promille, jeder Schlüssel trägt seinen Einheitensuffix). Abgleichliste `t06/abgleich.csv`: alle 92 L-08-Keys plus 51 Regeln ohne Key (Genre, Ketten, Flags) auf JSON-Pfade; der Validator liest die Keys selbst aus L-08 und bricht ab, wenn einer fehlt.
**Beleg:** `t06/run_validate.log`, `validate.py` Exit 0 mit jsonschema und Fallback, 16 Negativfälle in beiden Engines erkannt, Konsistenzprüfung gegen `economy_constants.json`.

**T-11 Balancing: fertig, Ziel verfehlt.** 100 Läufe, Bankrott bis Minute 30: **7 %** (Ziel 10–30 %), alle durch überkaufte Lkw. Kein Exploit über 1,5× Referenz (max. 0,94). Ohne Endabnehmer-/Luftlinienregel lägen Lager-Pingpong (1,53) und Umweg (1,67) darüber. Belege: `t11_laeufe.csv`, `t11_exploits.csv`, `t11_kalibrierung.csv`, `t11_bericht.md`.

**Einschränkungen:** Spielerverhalten ist gesetzt, Modellspieler reagieren nicht. Kauf-Freischaltung nach erster Lieferung (L-08 nennt „ab M5b“ zirkulär). Der T-07-Katalog liegt nicht als Datei vor, 8 Exploits aus L-08 abgeleitet. Kraftwerk, Werkzeugfabrik, Kohlemine-Kaufpreis sind Annahmen (`annahme_flag`). Werksmarge nach Lesart t05.

**Offene Fragen:**
1. Holz/Bau fehlt im Slice, Kleinstadt-Wachstum bleibt im ¼-Band (154 statt 72–90 min). Jonas/Lena.
2. K2 senkt den Umsatz (886 auf 708 $/min). Slice-Karte entscheidet, ob Kohle geteilt wird.
3. Rohstoffquellen-Ausbau fehlt, Fabrikstufe 2 bleibt sonst leer.
4. Kalibrierung: Straße ×5 oder Kapital ×0,6 (10–11 %) erst nach Grey-Box.
