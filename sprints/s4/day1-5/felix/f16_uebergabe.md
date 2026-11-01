# F-16 Übergabe (Felix, Sandbox-Stand) – an Tobias (T-12/H-01), Daniel (Tests), Aylin (Button)

Code: `core/economy.gd` (Modul), `core/eco_world.gd` (Aufbau-Helfer), `core/eco_tests.gd` (E0–E8 im `test_runner`), Hooks in `core/sim_world.gd`. Daten: `core/data/` = Kopie T-06 (`economy_slice.json`, `economy_constants.json`, `vehicles.json`), Schemas in `core/schema/`.

## API (1 Klick = 1 Aufruf)
- `eco.load_from(slice, consts)` → `ok`/`errors` (Float im JSON, fehlender Schlüssel, Slice ≠ Konstanten = Ladefehler)
- `eco.attach(sim)`, `add_industry_site(node, "muehle")`, `add_city_site(node, "kleinstadt_a")`, `add_warehouse_site(node)`
- `eco.start_company(archetyp, hq_node, hq_stufe)` → Kasse = Startkapital (Agrar 4.500 $, Bergbau 7.000 $)
- `eco.licence_quote(site)` → `kosten_cent`, `zu_zahlen_cent`, `gratis`, `laufzeit_ticks`, `ertrag_pro_monat_cent` (+ Ziel, Distanz, Quelle Welt/JSON), `kaufbar`
- `eco.buy_licence(site)` → `ok` / `fehler` (`schon_lizenziert`, `guthaben_reicht_nicht`, `keine_firma`)
- `eco.speed_steps(n_fahrzeuge)` → JSON-Stufen + 8× nur bis `MAX_VEHICLES_AT_8X = 5000`
- `eco.ledger` (Buchungen mit Ursprung, Felder, F_zeit, F_sätt), `cash_cent`, `revenue_total`

## Annahmen (nicht im JSON, bitte bestätigen oder ins JSON)
1. Verarbeitung 1:1 je Eingangsgut, Durchsatz = `factory_throughput_l1`.
2. `abnahme_max` je Periode, Überschuss bleibt auf dem Lkw. Lager nimmt bis `warehouse_capacity` an.
3. Gratis-Lizenz gilt für die erste gekaufte Lizenz (auch Verarbeiter). Tobias' Modell schließt den Verarbeiter aus.
4. Sättigung als Grenzpreis je Einheit (Versorgungsgrad der n-ten Einheit in der Periode).
5. 8× steht nicht in `game_speed_stufen` (0/1/2/4), daher als Konstante im Code.
6. Produktion je Öko-Tick (10 Ticks) mit Restakkumulator: Tobias' offene F-09-Frage 1 ist damit entschieden.

## Nicht in F-16 (offen)
- **Sichtbarer Button „Lizenz kaufen“** fehlt (nur API, keine UI im Prototyp verdrahtet).
- **Fahrzeugkosten (fix/variabel), Lager-Unterhalt, Baukosten fehlen.** Ohne sie gibt es keinen Bankrott. T-12 (Ziel 10–30 % Bankrott) kann mit diesem Stand allein nicht kalibrieren. Beispiel E1: K1 bringt 9.918 $ in 10 Spielminuten bei 4.500 $ Start.
- Kredit (S5), Firmenkauf, Skills (B_skill = 0), Arbeit/Pendler-Faktor, geteilte/exklusive Lizenz, Wachstum.

## Kern-Änderungen (Prüfsummen ohne Ökonomie unverändert)
`r_stop` je Routenschritt (schneller Pfad auch für Lkw mit Halten) und `_producers` (statt Schleife über alle Lager je Tick). Ohne die zweite Änderung kosteten 11.000 Stationen in der 10k-Bench ca. 1,3 ms je Tick. `ref/` fehlte in `spikes/sim-core/`, kopiert aus `sprints/s3/day1-3/felix/core/ref/`.
