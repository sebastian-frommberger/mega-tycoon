# F-09 JSON-Festkomma-Konvention – Entwurf v0 (Tobias Brandt, 23.11.2026)

**Status: Entwurf, Felix' Abzeichnung OFFEN** (Review in seiner Fragestunde, 30 min, Termin nicht bestätigt). Leitfrage des Tickets: Trägt Cent/Ticks die VS-Ketten? Antwort unten: ja für Güter, Fahrzeuge und Konstanten; drei Punkte brauchen Felix' Entscheidung.

Dateien: `schema/common.schema.json`, `goods.schema.json`, `vehicles.schema.json`, `economy_constants.schema.json` (JSON Schema Draft 2020-12) · Beispieldaten `data/goods.json`, `vehicles.json`, `economy_constants.json` (VS-Ketten E1: Getreide→Mehl, Vieh→Fleisch, Holz→Bretter, Erz+Kohle→Stahl→Werkzeug) · `validate.py` (jsonschema 4.26.0 vorhanden; eigener Fallback-Validator für dieselbe Teilmenge, `--fallback`; Negativtest `--selftest`, 8 Fälle, beide Engines) · `run_validate.log`: **Exit 0** in allen drei Läufen, auf dieser Sandbox.

## 1. Regeln

| Größe | Einheit | Suffix | Typ | Beispiel |
|---|---|---|---|---|
| Geld | Cent | `_cent` | integer ≥ 0 (Konto: signed) | Lkw 400 $ → `kauf_cent: 40000` |
| Zeit | Sim-Ticks, 1 Tick = 100 ms (10 Hz, felix.md) | `_ticks` | integer ≥ 0 | Lizenz 30 Spielminuten → `laufzeit_ticks: 18000` |
| Raten | je **Periode** = `zeit.periode_ticks` = 600 Ticks = 1 Spielminute | `_pro_periode` | integer | Lkw 90 $/min → `fix_cent_pro_periode: 9000` |
| Anteile, Faktoren | Promille | `_promille` | integer 0–1000 (Faktoren bis 100000) | Lizenz 10 % → `anteil_promille: 100` |
| Wachstumsraten | Basispunkte (0,01 %) | `_bp` | integer, signed | 1,8 %/Monat → `basisrate_bp_pro_monat: 180`, ¼ davon → 45 |
| Strecken | Felder (Spiellogik) / mm (Sim-Position, felix.md) | `_felder`, `_mm` | integer | 1 Feld = `raum.feld_mm` = 1000 mm (**ANNAHME**, Felix) |
| Tempo | mm je Tick | `_mm_pro_tick` | integer | 6 Felder/s → 600 |
| Mengen | Einheiten | `_einheiten` | integer | Stufe 1 = 20 Einheiten je Periode |
| Kleine Raten | Hundertstel je Tick | `_x100` | integer | Rampe 2 E/s = 0,2/Tick → 20 |
| IDs | `^[a-z][a-z0-9_]{1,31}$` | – | string | `lkw_e1` |

- **Keine Gleitkommazahl in Datendateien.** Der Validator lehnt jede `float` ab, auch `1.0`.
- **Obergrenze 2^53−1** für jede Zahl: Godots `JSON.parse` liest Zahlen als `float64`, danach `int(...)`. Darüber verliert der Import Stellen. Konto in der Sim bleibt `int64`, aber Werte, die als JSON ein- oder ausgehen (Saves, Telemetrie), müssen unter 2^53 bleiben. 2^53 Cent ≈ 90 Billionen $, reicht.
- **Rundung „halb auf“, eine Division am Ende:** `ergebnis = (zaehler + nenner/2) div nenner`, negative Beträge symmetrisch (Betrag runden, Vorzeichen zurück). Alle Multiplikationen vor der Division. Beispiel Ertrag: `einheiten × preis_cent × d_eff_x1000 × f_zeit_promille × f_saett_promille / 10^9`; 10 Mehl über 45 Felder = 45.000 Cent, exakt. Lizenz Mühle: `200000 × 100 × 700 / 10^6 = 14.000 Cent`. Kredit-Zins: `46000 × 10 / 1000 = 460 Cent`. Die vier Proben laufen in `validate.py` (`rechenprobe`).
- **Schema-Version** `schema_version: 1` in jeder Datei; Schemaänderung = Version hoch, Loader prüft.
- `additionalProperties: false` überall: ein Tippfehler im Feldnamen (`kauf_dollar`) ist ein Validierungsfehler, kein stiller Default.
- Zwei Felder sind per Schema auf D-Entscheidungen festgenagelt: `kauf.rabatt_m5b_einmalig` muss `true` sein (D1), `wachstum.etikett` muss `"ungetestet"` sein (D4) und `wachstum.variante` `"B"`. Wer das ändert, ändert bewusst das Schema.

## 2. Was in den Beispieldaten steht (Quelle: tobias.md, T-05 final, T-04 final, D1, D4)

- Güter: 10 Einträge E1 mit `preis_cent_pro_einheit_feld` (0,40 $ → 40 … Werkzeug 200), Kategorie, Massengut, Substitut (Mehl ↔ Fleisch), Frische nur bei Fleisch (`frische_verfall_ticks: 3600` = 6 min, **ANNAHME**, Zahl offen).
- Fahrzeuge: Lkw, Dampflok (+Waggon), Raddampfer mit Hafen-Infrastruktur; Lebensdauer in Ticks (Lkw 15 Jahre = 108.000 Ticks bei 1 Jahr = 12 Spielmonate = 7.200 Ticks, **ANNAHME**: Spieljahr = 12 Spielminuten), Alterung +5 %/Jahr = 500 bp.
- Konstanten: Lizenz (100 ‰, 18.000 Ticks, −300 ‰ im Radius, +30 ‰/Feld außerhalb, Hinweis 1.800 Ticks vor Ablauf, 1 Gratis), Kauf (Anrechnung 500 ‰, Marge 150 ‰, Unterhalt 2.000 Cent/Periode/Stufe, Rabatt 200 ‰ einmalig, Verkauf 700 ‰, Firmenwert 600 ‰ + 12 Monate), Kredit (200.000 Cent, ab Tick 0, 10 ‰/Periode, Sperren, Zwangsverkauf nach 6.000 Ticks), Ertrag (Mindestdistanz 6, Knick 60, jenseits 500 ‰), Sättigung (1000/1500/400/100 ‰), Ausbau 4 Stufen, Startkapital (D1) in Cent, Wachstum B (180 bp, Band 180/45/0/−45, Zuschlag max 250 ‰, Anteile 625/375, Tor 950/250 ‰), Bau (Straße 1.000 Cent/Feld, Lager).

## 3. Offene Punkte für Felix (Abzeichnung)

1. **Raten je Periode (600 Ticks) oder je Ökonomie-Tick (10 Ticks)?** Ich habe Periode gewählt, weil 20 E/min je Öko-Tick 0,333… wäre. Alternative: Milli-Einheiten je Öko-Tick (333, Fehler 0,1 %/min). Deine Sim muss dann je Öko-Tick `rate_pro_periode × oeko_tick_ticks / periode_ticks` mit Restakkumulator rechnen (Bresenham-artig), damit über 60 Öko-Ticks exakt 20 Einheiten entstehen. Vorschlag steht, Entscheidung bei dir.
2. **`feld_mm = 1000`** ist meine Setzung. Wenn deine Kantenlänge in anderen Einheiten liegt, ändert sich nur diese Konstante und `tempo_mm_pro_tick`.
3. **2^53-Grenze**: bestätigst du, dass der Loader `int()` auf jedes Feld anwendet und Saves/Telemetrie ebenfalls durch JSON gehen? Sonst kann die Grenze auf `int64` steigen.
4. Nicht in diesem Ticket (Refinement: F-09 Rest nach S3): `chains.json`, `industries.json`, `cities.json`, CI-Einbindung des Validators. Die Schemas hier sind so gebaut, dass `chains` nur Güter-IDs referenziert.

## 4. Akzeptanzkriterien F-09

| Kriterium | Stand |
|---|---|
| Schema für goods, vehicles, economy_constants | **ja**, 3 Schemas + common |
| VS-Beispieldatei validiert lokal gegen das Schema, Exit 0 | **ja**, `run_validate.log` (jsonschema und Fallback, plus 8 Negativfälle erkannt), Sandbox-Lauf |
| Felix hat die Festkomma-Konvention im Review abgezeichnet | **nein, offen.** Review nicht terminiert; seine 30 min sind durch F-05/F-04-Übergabe belegt (Annahme, kein Tag-4–6-Bericht von Felix vorhanden). |
