# L-08 Slice-Regeln Vertical Slice, v2 (Lena Hoffmann, Stand Sprint 4, Tag 1–5)

**v2 gegenüber v1 (03.12.2026):** (1) Ausbau Fabrikstufe 2 = 2.000 $ (D19, v1 hatte 6.000 $). (2) Hafen und Handel nicht im Slice (D18), nur als Daten mit Flag. (3) Kredit ist im Slice aus und kommt in Sprint 5 (Refinement S4, F-16 „kein Kredit“). (4) Neue Regel L-10 (Abschnitt 5a): Holz/Bau-Lücke per Regel, keine neue Quelle. (5) Ketten K1–K3 bestätigt (D17), Bergbau-Untergrenze 6.000 $ bestätigt (D20).

Nur unsere Unterschiede zum Genre (D15). Zahlen aus `t05_final.md`, `t04_final.md`, D1/D4/D12/D13, `tobias.md`, `industry.md`, `hq.md`; nichts ist an Spielern gemessen. **Annahme** = Setzung ohne Beleg. Werte gelten als Startwerte für `T-06` (JSON, Keys snake_case).

## Einseiter: der Loop

1. **HQ:** Stadt wählen (Karte pausiert), HQ gratis setzen, Einflussradius 40–55 Felder erscheint (M1a).
2. **Lizenz:** 10 % des Kaufpreises für 30 Spielminuten, 1 Gratis-Lizenz. Laden nur mit Lizenz oder Besitz (M1b).
3. **Lieferung:** Straße und 2–3 Lkw bauen, Rohstoff zum Verarbeiter, Endprodukt zum Abnehmer (M2, M3). Ertrag gibt es nur beim Endabnehmer, Herkunftsstempel bleibt beim Umladen.
4. **Kauf:** Läuft die Kette, bietet das Spiel den Kauf an (50 % der Lizenzgebühren angerechnet, Werksmarge 15 %). Kauf nur aus Guthaben, ab M5b.
5. **Ausbau:** Fabrikstufe 2, Lager als Hub für 2 Quellen (M5), Zug mit Signal (M6), HQ-Stufe 2 nach 35–50 min (M7).
6. **Druck:** Sättigung senkt den Preis ab 100 % Versorgung. Neue Mehreinnahmen kommen nur aus neuen Abnehmern oder wachsenden Städten (Variante B, 1,8 %/Monat). Die Stadt wächst im Slice allein über Nahrung; das Tor zur Stadt öffnet Stahl aus K3 (L-10).
7. **Sicherheitsnetz:** im Slice **keines**. Der Kreditrahmen (2.000 $, 1 %/min, sperrt den Firmenkauf) ist als Regel beschrieben, aber ab Sprint 5 aktiv (`credit_active_in_slice` = aus). Wer überbaut, kann bankrott gehen; das ist die gewollte Bankrottrate 10–30 % (Ziel Sprint 4).

**Die 3 Ketten des Slice** (bestätigt D17): (K1) Getreide → Mühle → Mehl → Stadt. (K2) Kohle → Kraftwerk (Strom). (K3) Erz + Kohle → Stahlwerk → Stahl → Werkzeugfabrik (Abnehmer **Annahme**, 40 E/min, nimmt Stahl ab und erzeugt im Slice kein Werkzeug). Kohle teilt sich auf K2 und K3: das ist die Entscheidung der Slice-Karte. Holz/Sägewerk, Vieh, Hafen und Fluss sind nicht im Slice (Entscheidung 27.11.: 3 Ketten). Folge: Im Slice spielbar sind die Archetypen **Agrar** (K1) und **Bergbau** (K2/K3). **Hafen und Handel sind nicht im Slice (D18)**; ihre Startwerte bleiben nur als Daten mit Flag `archetyp_port_im_slice`/`archetyp_trade_im_slice` = aus. Die fehlende Holz-/Bau-Kategorie löst L-10 (Abschnitt 5a) per Regel.

## 1. HQ-Start und Archetypen

| Regel | Wert | Key |
|---|---|---|
| HQ-Gründung kostenlos, Stadtrand | 0 $ | `hq_found_cost` = 0 |
| Einflussradius Dorf/Kleinstadt/Stadt/Metropole | 55/50/45/40 Felder | `hq_radius_village`, `_town`, `_city`, `_metro` |
| Startkapital (D1, Option A, revidierbar) | Agrar 4.500, Bergbau 7.000 $; Hafen 4.500 und Handel 5.000 $ nur als Daten, **nicht im Slice (D18)** | `start_capital_agrar`, `_mining`, `_port`, `_trade` |
| Bergbau-Untergrenze (D20: bleibt 6.000 $, kein 6.500 $) | 6.000 $ | `start_capital_floor_mining` |
| Gratis-Lizenz, 1 Skillpunkt | 1 / 1 | `free_licence_count`, `start_skillpoints` |
| Startkarte garantiert Bau-Rohstoffquelle im Radius (D13) | Flag bleibt an, im Slice wirkungslos (keine Bau-Kategorie, L-10); gilt in der Sandbox | `hq_guarantee_build_source` |

Die Startkapital-Zahlen in `hq.md` (15.000–30.000 $) sind durch D1 ersetzt.

## 2. Lizenz und Kauf, Kredit (im Slice aus)

| Regel | Wert | Key |
|---|---|---|
| Lizenzpreis | 10 % des Kaufpreises, Auto-Verlängerung an | `licence_cost_share` = 0.10, `licence_auto_renew` |
| Laufzeit in Spielminuten (D1) | 30 | `licence_duration_min` |
| Radius-Rabatt / Aufschlag außerhalb | −30 % / +3 % je Feld | `licence_discount_in_radius`, `licence_surcharge_per_field` |
| Geteilt / exklusiv | max. 2 Nehmer, Output 50/50 / ×2,5 | `licence_shared_max`, `licence_exclusive_mult` |
| Kaufpreis | 1.000–4.000 $ × Stufe, +3 %/Feld außerhalb | `buy_price_base`, `buy_surcharge_per_field` |
| Anrechnung Lizenzgebühren auf Kauf | 50 % | `buy_licence_credit_share` = 0.50 |
| Kaufrabatt, einmalig bei M5b (D1) | −20 % | `buy_discount_first` = 0.20 |
| Werksmarge auf fremden Transportertrag | 15 %, Unterhalt 20 $/min × Stufe | `works_margin`, `company_upkeep_per_level` |
| Kreditrahmen (Regel, im Slice **nicht aktiv**, Sprint 5), Zins je Spielminute | 2.000 $, 1 % auf gezogenen Betrag | `credit_limit`, `credit_interest_per_min` |
| Kredit im Slice aktiv | aus; Sprint 5 | `credit_active_in_slice` |
| Kredit-Sperre | Firmenkauf, Firmen- und HQ-Ausbau nur aus Guthaben; Straße, Fahrzeuge, Lager, Verlängerung dürfen ins Minus | `credit_blocks_company_buy` |
| Zwangsverkauf nach Min. unter Rahmen | 10 (nicht im Slice, Sandbox ohne) | `credit_forced_sale_after_min` |

Ohne Kredit gibt es im Slice keinen Puffer: Straße, Fahrzeuge, Lager, Verlängerung und Firmenkauf gehen nur aus Guthaben, ein Konto unter 0 $ ist Bankrott (Messregel Tobias). Gate-Satz (Tobias, Modell, v1 mit Kredit gerechnet): Kauf liegt beim Verarbeiter im Standardfall nach 17 min (Agrar) bis 56 min (Handel) vorn. Bei Agrar trägt die Lizenzroute nur Rohstoff und Kleinmarkt (F4, F5).

## 3. Ertrag nur beim Endabnehmer, mit Herkunftsstempel

Formel: `E = M × P_gut × D_eff × F_zeit × F_sätt × (1 + B_skill)`. Kein Ertrag für Lager, Umladen, Umwege (schließt Lager-Pingpong aus).

| Regel | Wert | Key |
|---|---|---|
| Endabnehmer | Verarbeiter (Eingangsgut) oder Stadt | `yield_only_at_end_customer` |
| Stempel (Ursprungsfirma, Abfahrtszeit), bleibt im Lager | an | `origin_stamp` |
| Distanz: Luftlinie, linear bis 60, danach halbe Steigung; unter 6 Feldern 0 | 60 / 0,5 / 6 | `dist_knee_fields`, `dist_slope_beyond`, `dist_min_fields` |
| Frische (Mehl): Frist/Verfall | 60 s / 120 s | `fresh_grace_s`, `fresh_decay_s` |
| Massengut (Getreide, Kohle, Erz, Stahl): Frist/Verfall | 300 s / 600 s | `bulk_grace_s`, `bulk_decay_s` |
| `F_zeit` Untergrenze, Skillbonus-Deckel | 0,3 / +0,40 | `f_time_min`, `skill_bonus_cap` |
| Preise je Einheit und Feld | Getreide 0,40 · Mehl 1,00 · Kohle 0,40 · Erz 0,45 · Stahl 1,00 · Werkzeug 2,00 | `price_grain`, `_flour`, `_coal`, `_ore`, `_steel`, `_tools` |

## 4. Sättigung

| Regel | Wert | Key |
|---|---|---|
| Bedarf je Kategorie | Einwohner / 100 je min | `demand_per_100_inhabitants` = 1 |
| `F_sätt` bis 100 % | 1,0 | `sat_full_until` = 1.0 |
| 100 → 150 % linear auf, darüber | 0,4, darüber 0,1 | `sat_floor_at_150`, `sat_over_150` |
| Warenkorb Slice (L-10) | Dorf Nahrung · Kleinstadt Nahrung (Bau entfällt) · Stadt Nahrung + Stahl (Stahl ersetzt Werkzeug als Tor-Kategorie). Genre-Korb der Sandbox: Kleinstadt + Bau, Stadt + Werkzeug | `basket_by_stage` |

Kein Genre-Standard: Sättigung gilt je Stadt und Kategorie, nicht je Linie.

## 5. Stadtwachstum Variante B (D4) – UNGETESTET, Grey-Box Januar

| Regel | Wert | Key |
|---|---|---|
| Basisrate je Spielmonat (1 Monat = 1 min) | 1,8 % | `growth_base_rate` = 0.018 |
| Band nach Warenversorgung G | ≥ 0,8 voll · 0,5–0,8 ¼ · 0,3–0,5 null · < 0,3 −¼ | `growth_band_hi/_mid/_low`, `growth_mid_factor` = 0.25, `growth_neg_factor` = −0.25 |
| Zuschlag nur bei positivem Band, `X = 0,625 P + 0,375 J` | Rate × (1 + 0,25 X), max. +25 % | `growth_bonus_weight`, `growth_bonus_cap` = 0.25 |
| Stufen-Tor: Halt bei 95 % der Schwelle bis neue Kategorie ≥ 25 % versorgt (im Slice Stahl, L-10); nur Kleinstadt → Stadt (D13) | 0,95 / 0,25 | `gate_halt_share`, `gate_min_supply`, `gate_from_stage` |
| +0,5-%-Fabrikregel | gestrichen | – |

Zielzeiten laut Rechnung: Dorf → Kleinstadt 11–13 min, Kleinstadt → Stadt 72–90 min (Basis Eintritt bei 1.000 Einwohnern, mit L-10, Abschnitt 5a). Das sind Rechenwerte, keine Messung. Offen (Jonas): reiner Personenspieler wächst ohne Waren nicht.

## 5a. L-10: Holz-/Bau-Lücke per Regel (neu, Sprint 4)

Problem (T-11): Der Slice hat keine Holzkette (D18). Die Kleinstadt verlangte Nahrung und Bau, Bau bleibt 0, G ≤ 0,5, die Stadt wächst im ¼-Band (45 bp): Kleinstadt → Stadt braucht 154 min statt 72–90. **Keine neue Quelle**, nur Regel:

| Regel | Wert | Key |
|---|---|---|
| (a) Bau-Kategorie im Slice-Korb inaktiv; G = Nahrungsversorgung | aus | `slice_build_category_active` = aus |
| (b) Tor Kleinstadt → Stadt öffnet über ein K3-Endprodukt statt Bau/Werkzeug: Halt bei 95 %, bis die Stadt zu ≥ 25 % mit Stahl versorgt ist | Stahl, 25 % | `gate_unlock_good`, `gate_min_supply` |
| (c) Stahl zählt nur für das Tor, nicht in G, ohne Wachstumsbonus; sein Ertrag bleibt der Preis nach Abschnitt 3 | an | `gate_good_in_growth_supply` = aus |

**Begründung:** (1) Allein über G lösbar wäre die Lücke nur mit Stahl als Baustoff-Ersatz. Dann bliebe ein Agrar-Spieler ohne K3 im ¼-Band, also genau im Problem. Darum Stahl nur als Tor (b), Wachstum nur Nahrung (a). (2) Das Tor bleibt aus D13 (nur Kleinstadt → Stadt) und hält K3 relevant: Mehl bringt die Stadt bis 95 %, Stahl öffnet sie. Referenz: Anno 1800 (Bedarfsstufen, neue Stufe braucht neues Gut). (3) „Werkzeug“ kann das Tor im Slice nicht öffnen, die Werkzeugfabrik ist reiner Abnehmer.

**Rechenwerte (keine Messung):** Aufstieg von 1.000 auf 5.000 Einwohner bei 1,8 %/Monat ohne Bonus: ln 5 / ln 1,018 = 90 min; mit Maximalbonus +25 % (2,25 %): 72 min. Das ist das Fenster **72–90 min** (Basis: Eintritt in die Kleinstadt bei 1.000). Der Start der Slice-Kleinstadt bei 2.500 Einwohnern: 2.500 → 5.000 in 39 min (31 min mit Bonus), vorher 154 min im ¼-Band. Voraussetzung: Nahrungsversorgung ≥ 80 %, bei 5.000 Einwohnern 40 Mehl/min (Fabrikstufe 2, zwei Farmen). Reicht das Mehl nicht, fällt G ins ¼-Band (50–80 %) oder ins Nullband (30–50 %, Stillstand): gewollter Druck, aber kein Fehler im Tor.

## 6. Fabrikstufen

| Regel | Wert | Key |
|---|---|---|
| Durchsatz Stufe 1/2 (Slice nur bis 2) | 20 / 40 E/min | `factory_throughput_l1`, `_l2` |
| Ausbaukosten auf Stufe 2 (D19, korrigiert; v1 6.000 $ war eine Fehlzuordnung) | 2.000 $ (Stufe 3: 6.000 $, Stufe 4: 15.000 $, beide nicht im Slice) | `factory_upgrade_cost_l2`, `_l3`, `_l4` |
| Arbeit: ohne Pendler / volle Abdeckung | 80 % / 110 %, drosselt, stoppt nie | `labour_base`, `labour_full` |
| Gesamtdeckel Produktion (Energie, Pendler, Skills) | ×1,6 | `production_mult_cap` |

Zuordnung laut Quelle `hq_startwerte.md` (2.000 / 6.000 / 15.000 $ für Stufe 2 / 3 / 4), bestätigt in D19.

## 7. Lager als Hub

| Regel | Wert | Key |
|---|---|---|
| Kauf / Unterhalt | 800 $ / 30 $ je min | `warehouse_cost`, `warehouse_upkeep` |
| Kapazität, Rampen | 200 Einh., 2 Rampen × 2 E/s | `warehouse_capacity`, `warehouse_ramps`, `warehouse_ramp_rate` |
| Eigener Ertrag | keiner | `warehouse_yield` = 0 |
| Umschlagzeit zählt in `F_zeit` | an | `transfer_counts_in_f_time` |
| Lkw sammelt (< 25 Felder), Zug Hauptstrecke; Kreuzung ab 25 Feldern und 20 E/min | 25 / 20 | `truck_zug_cross_fields`, `_units` |
| Lager für Slice-Meilenstein | 2 Quellen | `ms5_sources_min` = 2 |

## 8. Energie-Radius (im Slice, über K2)

| Regel | Wert | Key |
|---|---|---|
| Grundversorgung | immer 100 % | `power_base` = 1.0 |
| Beliefertes Kraftwerk: Radius, max. Bonus (anteilig zur Versorgung) | 25 Felder, +25 % Menge | `power_radius`, `power_bonus_max` |
| Überlappung: Maximum statt Summe, nur Menge, nie Preis | an | `power_overlap_mode` = "max" |

## 9. Meilensteine 1a–7

| M | Bedingung | Belohnung | Key |
|---|---|---|---|
| 1a | HQ gegründet | Einflussradius | `ms_1a` |
| 1b | Erste Lizenz im Einfluss | +1 Skillpunkt | `ms_1b_skillpoints` = 1 |
| 2 | Lkw-Linie zum Verarbeiter | +1 Punkt Straße | `ms_2_skillpoints` = 1 |
| 3 | Endprodukt an Abnehmer (Stadt, Export, nächste Stufe; D13) | Stadt-Panel | `ms_3` |
| 4 | Busline in einer Stadt | Ast Stadtverkehr | `ms_4` |
| 5 | Lager mit 2 Quellen | Zug frei | `ms5_sources_min` |
| 5b | Erste Firma gekauft | −20 % nächster Kauf, einmalig | `buy_discount_first` |
| 6 | Zugstrecke mit Signal | Doppelgleis-Tool | `ms_6` |
| 7 | HQ-Stufe 2 nach 35–50 min; Gewinnschwelle erst mit Ausbaupfad (M1) | HQ-Stufe 2: 12.000 $, +10 Felder | `ms7_target_min_low` = 35, `_high` = 50, `hq_l2_cost` = 12000 |

Meilenstein 8 und KI-Spediteur: nicht im Slice.

## Genre-Standard übernommen

| Bereich | Verhalten | Referenz |
|---|---|---|
| Bauen | Straße/Gleis per Ziehen, 45°-Snap, Ghost mit Kosten (Ghost Weiß = baubar, D10) | Railway Empire |
| Fahrzeugkauf | Kauf aus Guthaben, sofort einsatzbereit | OpenTTD |
| Linien | Haltestellen verketten, Fahrzeuge zuweisen | Transport Fever 2 |
| Signale | Blocksignal und Auto-Signal; Weiche ohne Signal, Pfadsignale nicht im Slice | OpenTTD |
| Kontextdialog | Klick auf Objekt öffnet Panel | Cities: Skylines |
| Zeit | Pause, 1×/2×/4×, Kartenerkundung vor Start | Cities: Skylines |
| Abriss | Rückerstattung 50 % (F-13), kein Soft-Lock | OpenTTD |
| Haltestelle | Einzugsradius Bus 5, Bahnhof 10 Felder | Transport Fever 2 |
| Bedarfsstufen | Warenkorb wächst mit Stadtstufe | Anno 1800 |

## Erledigt und offen

Erledigt: Ketten K1–K3 (D17), Hafen/Handel raus (D18), Ausbaukosten (D19), Bergbau 6.000 $ (D20), Kredit nach Sprint 5, Holz-Lücke (L-10).

Offen:
1. Werkzeugfabrik 40 E/min und Kraftwerks-Abnahme bleiben Annahmen.
2. Die Slice-Kleinstadt startet bei 2.500 Einwohnern; das Fenster 72–90 min gilt ab 1.000. Soll das Ziel für die Slice-Karte gelten, müsste die Start-Einwohnerzahl in der Karte (S-10) auf rund 1.000 sinken (Folge: Sättigung im ersten Loop, Tobias rechnet nach). Entscheidung Jonas/Lena nach Grey-Box.
3. Reiner Personenspieler wächst ohne Nahrung nicht (Jonas, offen aus v1).
4. Kredit ab Sprint 5: Messregel Bankrott und Zins neu rechnen.
