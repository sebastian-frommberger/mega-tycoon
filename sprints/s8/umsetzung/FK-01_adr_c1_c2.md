# ADR FK-01: Firmenkauf C1 in S8, C2 nur Spec; Besitzerfeld `s_owner`

Stand 05.11.2026, Tobias (Owner Ökonomie), Lena (Design), zur Abnahme an Jonas (0,25) und Felix (0,25). Status: **vorgeschlagen, revidierbar bis S9-Refinement**. Marken: [M] Code, [R] gerechnet/aus design.md, [E] Schätzung. Grundlage: `ergebnis.md` D-F, W3, W8, FK-01/02/04; `design.md` §A.

## Entscheidung
1. **C1 = Industrie kaufen** (Lizenz → Besitz) wird in S8 gebaut (FK-02, `economy.gd`, Schreiber Tobias). Dazu gehört ein Werksausbau der Mühle auf **Werksstufe 2** (40 E/min, 2.000 $).
2. **C2 = bankrotte Rivalenfirma kaufen** gibt es in S8 nur als Spezifikation (FK-04, eine Seite). Gebaut wird C2 frühestens in S9 (≈ 4 T [R]), und nur zusammen mit einem Skript-Rivalen.
3. **Konkurrenz als Spielfigur** nicht vor S10 (W8).
4. **Rückfall W3:** Ist FK-02 bei Gate C nicht grün, setzt `economy_proto.json` den Durchsatz der Mühle fest auf 40. Das kostet nichts, aber es gibt dann keinen Kaufmoment.

**Begründung:** C1 braucht weder KI noch Konkurrenz. Es macht den Mühlendeckel (20 E/min, `economy.gd` Z. 450 „ANNAHME Stufe 1“ [M]) zur Entscheidung um Minute 14–25. C2 braucht Besitz an Fahrzeugen und Lizenzen und einen Rivalen, und beides fehlt (`economy.gd` kennt eine Kasse, `line_events` ohne Firma [M]).

## Begriffe (gegen die Dreifachbelegung von „Stufe“, W3)
| Begriff | Bedeutung | Werte | Code/Daten |
|---|---|---|---|
| **Kaufstufe C1/C2** | Welche Art Firmenkauf | C1 Industrie kaufen (S8), C2 Rivalenfirma kaufen (S9+) | nur Doku/Tickets, kein Feld |
| **Werksstufe 1/2** | Durchsatz-/Produktionsstufe eines Betriebs | 1 = 20, 2 = 40 E/min (3 = 70, 4 = 110 nur Daten, `factory_max_level_slice_stufe` 2) | `s_werksstufe[site]` (neu), `fabrik.factory_throughput_l*` [M] |
| **Konkurrenzstufe** | Ausbaustand der Konkurrenz im Spiel | 0 keine (S8), 1 Skript-Rivale (mit C2, S9), 2 Spielfigur (S10+) | Preset-Feld, später |

Nicht mehr verwenden: „Stufe“ ohne Zusatz. `hq_stufe`/HQ-Ausbau (ms_7) bleibt eigener Begriff „HQ-Stufe“. **OFFEN:** Das Preset-Verhalten der KI (passiv/aktiv/aggressiv, K36–K40) ist **nicht** die Konkurrenzstufe. Vorschlag: es „Konkurrenzverhalten“ zu nennen, Entscheidung Lena.

## Feldliste (Spec für FK-02, ≤ 1 Seite)
| Feld | Typ, Default | Bedeutung | Regel |
|---|---|---|---|
| `s_owner[site]` | `PackedInt32Array`, 0 | Besitzer je Standort | **0 frei, 1 Spieler, ≥ 2 reserviert** (Rivale/KI, C2 ab S9). In S8 schreibt nur `buy_site` den Wert 1. Andere Werte ≥ 2 → Fehler `besitzer_reserviert` |
| `s_werksstufe[site]` | `PackedInt32Array`, 1 | Werksstufe 1/2 | Ausbau nur bei `s_owner == 1`. `s_rate` = `factory_throughput_l<stufe>`. Ersetzt die feste L1-Zuweisung (Z. 450) |
| `s_lic_paid[site]` | `PackedInt64Array`, 0 | Gezahlte Lizenzgebühren je Standort (Kauf + Verlängerungen) | Grundlage der Anrechnung 50 % (`buy_licence_credit_share_promille` 500). Heute gibt es nur das globale `licence_paid_total` (Z. 138) [M] |
| `owned_count` | int, 0 | Anzahl gekaufter Werke | Preisaufschlag +25 % je weiteres Werk [E] |

**Kaufpreis** (FK-02, Test je Fall):
`preis = kaufpreis_stufe1_cent × s_werksstufe × (1000 + 30 × max(0, d − hq_radius)) / 1000 × (1000 + 250 × owned_count) / 1000 × (1000 − 200 × erster_kauf) / 1000 − s_lic_paid × 500 / 1000`, eine Division am Ende („halb auf“). Quellen: `kauf.buy_surcharge_per_field_promille` 30, `buy_discount_first_promille` 200 (einmalig, ms_5b), Anrechnung 500 [M]; +25 % [E]. Die Mühle Erlenbach kostet ≈ 1.600 $ [R, design.md]. **OFFEN:** Unklar ist die Reihenfolge von Rabatt und Anrechnung, und ob der Faktor „× Stufe“ die Werksstufe ist (`buy_price_stufe_mult_flag`, Bedeutung nicht dokumentiert).

**Regeln:**
- `buy_site(site)`: Erlaubt nur, wenn `s_kind == K_INDUSTRIE`, `s_owner == 0` und `cash_cent >= preis` (`buy_only_from_balance_flag` [M]). Im Minus gesperrt (`kredit.sperre_firmenkauf_im_minus`, `credit_blocked_ids` firmenkauf [M]). Danach `s_owner = 1`, `owned_count += 1`.
- **Lizenz nach Kauf:** `s_lic_until[site] = -1` setzen und in `load_gate` (Z. 713) `licence_valid(site) or s_owner[site] == 1` prüfen. **Kein `-2`-Wert** (Annahme in design.md §A.2): `licence_valid` prüft `> tick`, also wäre −2 „ungültig“, und `_renew_licences` prüft `!= -1 and <= t`. −2 gälte dort als abgelaufen und würde beim nächsten Lauf kostenpflichtig verlängert, und `_update_next_expiry` nähme −2 als frühesten Ablauf [M].
- **Werksmarge** 15 % (`works_margin_promille` 150) auf Erträge aus Losen mit Ursprung = eigenes Werk (`lot[1]`). **Unterhalt** 20 $/Periode × Werksstufe (`company_upkeep_per_level_cent_pro_periode` 2000) über `konto` (Felix).
- **Prüfsumme:** `s_owner` und `s_werksstufe` gehen nur in `checksum()` ein, **wenn ≠ Default** (z. B. `if s_owner[site] != 0: h = (h ^ (site << 8 | owner)) * prime`). Ein bedingungsloses `h ^ 0` ändert die Prüfsumme und bricht die Bitgleichheit des Slice [R].
- **Kein Besitzfeld** an Fahrzeugen, Linien oder Lizenzen in S8 (erst C2).

## C2 (nur Rahmen für FK-04)
Ein Skript-Rivale hält die Lizenz an Farm 2 (`s_owner = 2`) und bietet bei Minute ≈ 30 die Insolvenz an. Preis = Restwert der Fahrzeuge (W20) + Lizenzrestlaufzeit anteilig + Werk zum Buchwert × 0,5. Der geerbte Kredit kommt zum eigenen dazu. Liegt die Summe über dem Rahmen von 2.000 $, ist der Kauf gesperrt (mit Text). Zeitfenster 3 min [R, design.md §A.3]. Formeln und Bot-Testfall folgen in FK-04.

## Revision
Revidierbar bis S9-Refinement (Jonas). **Auslöser:** Gate C ohne grünes FK-02 (dann gilt Rückfall W3, und C1 rutscht nach S9). Oder der Bot zeigt einen Schneeball: Netto verdoppelt sich in < 10 min nach dem 1. Kauf (FK-02).
